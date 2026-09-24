defmodule LokaR1Server.Faults do
  @moduledoc """
  Real injected faults against the durable host, judged by the model host.

  Each run builds a seeded prefix of plain invokes and one fault attempt with a
  fresh identity, so the attempt always reaches the kernel. `raise`, `io_error`
  and `commit_unknown` run in this VM. `kill` runs the prefix and the fault attempt
  in a child VM that halts at the point (`LokaR1Server.Child`), then recovers in a
  second, fresh child VM on the same database file.

  After the fault the host's HOST must equal the model's for the disposition
  SQLite shows (committed iff the attempt's receipt row exists), passed through
  the model's `recover` and with `published` empty (process memory is gone). The
  next command resends the same attempt and must equal the model's next step.
  """
  alias LokaR1.{Codec, World}
  alias LokaR1Server.Host

  @points ~w(pre_decision post_decision_pre_commit in_persistence post_commit_pre_adoption
             post_adoption_pre_response post_response_pre_presentation)
  # Points at or before which the attempt has not committed.
  @uncommitted ~w(pre_decision post_decision_pre_commit in_persistence)

  @doc "Every applicable `{point, kind}`: `raise` and `kill` everywhere, the other two in persistence."
  @spec matrix() :: [{String.t(), String.t()}]
  def matrix do
    for(p <- @points, k <- ~w(raise kill), do: {p, k}) ++
      [{"in_persistence", "io_error"}, {"in_persistence", "commit_unknown"}]
  end

  @doc "One evidence record for `world` × `seed` × `{point, kind}`, using scratch directory `dir`."
  @spec run(String.t(), pos_integer(), {String.t(), String.t()}, Path.t()) :: map()
  def run(world, seed, {point, kind}, dir) do
    {initial, prefix, attempt} = script(world, seed)
    fault = %{"step" => length(prefix), "point" => point, "kind" => kind}
    tag = "#{world}-#{seed}-#{point}-#{kind}"
    paths = %{db: Path.join(dir, tag <> ".sqlite"), diag: Path.join(dir, tag <> ".diag.jsonl")}
    spec = %{world: world, initial: initial, commands: prefix ++ [attempt], fault: fault}

    observed =
      if kind == "kill", do: in_children(spec, attempt, paths), else: in_vm(spec, attempt, paths)

    record = %{
      "host" => "server",
      "world" => world,
      "seed" => seed,
      "initial_sha256" => Host.sha256(initial),
      "commands" => spec.commands,
      "fault" => fault,
      "diagnostic" => diagnostic(paths.diag, fault["step"])
    }

    judge(Map.merge(record, observed), spec, attempt)
  end

  # ---- running ------------------------------------------------------------------

  defp in_vm(spec, attempt, paths) do
    opts = [db: paths.db, id: "fault", world: spec.world, diag: paths.diag]
    {:ok, pid} = Host.start([initial: spec.initial, fault: spec.fault] ++ opts)
    records = for c <- spec.commands, do: elem(Host.step(pid, c), 1)
    recovered = Host.host(pid)
    {:ok, next} = Host.step(pid, attempt)
    Host.stop(pid)
    %{"fault_step" => List.last(records), "recovered" => recovered, "next" => next}
  end

  defp in_children(spec, attempt, paths) do
    base = %{"db" => paths.db, "diag" => paths.diag, "id" => "fault", "world" => spec.world}

    {_, died} =
      child(
        Map.merge(base, %{
          "phase" => "run",
          "initial" => spec.initial,
          "commands" => spec.commands,
          "fault" => spec.fault
        }),
        paths
      )

    {out, 0} = child(Map.merge(base, %{"phase" => "recover", "next" => attempt}), paths)
    {:ok, %{"recovered" => recovered, "next" => next}} = Codec.decode(out)
    %{"fault_step" => nil, "child_exit" => died, "recovered" => recovered, "next" => next}
  end

  defp child(spec, paths) do
    file = paths.db <> ".spec.json"
    File.write!(file, Codec.encode(spec))
    lib = Path.dirname(to_string(:code.lib_dir(:loka_r1_server)))
    pa = Enum.flat_map(Path.wildcard(Path.join(lib, "*/ebin")), &["-pa", &1])
    elixir = System.find_executable("elixir") || raise "elixir not on PATH"

    System.cmd(elixir, pa ++ ["-e", "LokaR1Server.Child.main()"], env: [{"R1_CHILD_SPEC", file}])
  end

  defp diagnostic(path, step) do
    with {:ok, text} <- File.read(path) do
      text
      |> String.split("\n", trim: true)
      |> Enum.map(&elem(Codec.decode(&1), 1))
      |> Enum.find(&(&1["step"] == step))
    else
      _ -> nil
    end
  end

  # ---- judging ------------------------------------------------------------------

  @doc "Adds `committed`, `expected`, `checks` and `verdict` to an observed record."
  @spec judge(map(), map(), map()) :: map()
  def judge(record, spec, attempt) do
    {decide, _} = World.world(spec.world)
    run = fn host, cmds -> Enum.reduce(cmds, host, &elem(World.step(decide, &2, &1), 1)) end
    before = run.(World.new(spec.initial), Enum.drop(spec.commands, -1))
    committed = Map.has_key?(record["recovered"]["receipts"], attempt["request"]["id"])
    settled = if committed, do: run.(before, [attempt]), else: before
    expected = %{run.(settled, [%{"op" => "recover"}]) | "published" => []}
    {expected_next, _} = World.step(decide, expected, attempt)

    %{"point" => point, "kind" => kind} = spec.fault
    should_commit = kind == "commit_unknown" or point not in @uncommitted

    checks = %{
      "fault_fired" => fired?(record, kind),
      "disposition" => committed == should_commit,
      "recovered_host" => Codec.encode(record["recovered"]) == Codec.encode(expected),
      "next_step" => Codec.encode(record["next"]) == Codec.encode(expected_next)
    }

    Map.merge(record, %{
      "committed" => committed,
      "expected" => %{"committed" => should_commit, "host" => expected, "next" => expected_next},
      "checks" => checks,
      "verdict" => if(Enum.all?(Map.values(checks)), do: "pass", else: "fail")
    })
  end

  # The attempt was admitted (its diagnostic line exists) and the fault showed:
  # the child VM halted with 137, or the host answered with the matching code.
  defp fired?(%{"diagnostic" => nil}, _), do: false
  defp fired?(record, "kill"), do: record["child_exit"] == 137

  defp fired?(%{"fault_step" => %{"result" => result, "state" => host}}, "commit_unknown"),
    do: result["code"] == "commit_unknown" and host["in_doubt"]

  defp fired?(%{"fault_step" => %{"result" => result}} = record, _) do
    committed = Map.has_key?(record["recovered"]["receipts"], "f")
    result["code"] == if(committed, do: "response_lost", else: "rolled_back")
  end

  # ---- scripts ------------------------------------------------------------------

  @pools %{
    "tiny" => [
      {"move", %{"direction" => "north"}},
      {"move", %{"direction" => "south"}},
      {"take", %{}},
      {"drop", %{}},
      {"activate", %{}},
      {"look", %{}},
      {"wait", %{"until" => 20}},
      {"choose", %{"choice_id" => "carry", "continuation_id" => "lantern-offer-1"}}
    ],
    "lantern" => [
      {"move", %{"direction" => "north"}},
      {"move", %{"direction" => "east"}},
      {"move", %{"direction" => "west"}},
      {"move", %{"direction" => "south"}},
      {"take", %{}},
      {"drop", %{}},
      {"activate", %{}},
      {"talk", %{}},
      {"close_choice", %{}},
      {"wait", %{"until" => 20}}
    ]
  }

  @doc """
  `{initial, prefix, attempt}` for a seed. Seeds 1 and 2 walk to the lantern and
  make `take` the fault attempt; in Tiny that is the seeded roll, which passes
  from RNG `[1,2,3,4]` (seed 1) and fails from `[9,8,7,6]` (seed 2). Other seeds
  draw a random RNG state, 0 to 6 prefix invokes and the attempt from the pool.
  """
  @spec script(String.t(), pos_integer()) :: {map(), [map()], map()}
  def script(world, seed) do
    {_, initial} = World.world(world)
    pool = @pools[if(world == "lantern", do: "lantern", else: "tiny")]

    if seed in [1, 2] do
      path = if world == "lantern", do: ~w(north east east), else: ~w(north)
      rng = if seed == 1, do: [1, 2, 3, 4], else: [9, 8, 7, 6]

      prefix =
        for {d, i} <- Enum.with_index(path), do: invoke("c#{i}", "move", %{"direction" => d})

      {%{initial | "rng" => rng}, prefix, invoke("f", "take", %{})}
    else
      :rand.seed(:exsss, {seed, 17, 29})
      rng = for _ <- 1..4, do: :rand.uniform(0xFFFFFFFF)
      pick = fn -> Enum.random(pool) end

      prefix =
        for i <- 0..(:rand.uniform(7) - 2)//1 do
          {action, input} = pick.()
          invoke("c#{i}", action, input)
        end

      {action, input} = pick.()
      {%{initial | "rng" => rng}, prefix, invoke("f", action, input)}
    end
  end

  defp invoke(id, action, input) do
    request = %{"id" => id, "actor" => "hero", "action" => action}
    request = if input == %{}, do: request, else: Map.put(request, "input", input)
    %{"op" => "invoke", "request" => request}
  end
end
