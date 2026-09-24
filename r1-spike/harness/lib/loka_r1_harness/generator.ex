defmodule LokaR1Harness.Generator do
  @moduledoc """
  Seeded request generator. Everything draws from an explicit `:rand` state
  (`:exsss`) threaded through the functions; the process-global RNG is never used.

  A sequence is one `world.run` request of 1..64 commands followed by one extra
  request (composition plan, pure function or malformed line). Requests are
  `{:json, term}` (emitted as canonical JSON) or `{:raw, binary}` (deliberately
  malformed or non-canonical lines).

  Bump `@version` whenever the output for a given seed changes.
  """

  import Bitwise
  alias LokaR1Harness.Canonical

  @version "r1-gen-2"
  @max_safe 9_007_199_254_740_991
  @u32 4_294_967_295

  def version, do: @version

  @doc "Per-sequence seeds for the fresh run, drawn from `:exsss` seeded with `base`."
  def fresh_seeds(base, n) do
    {seeds, _} =
      Enum.map_reduce(1..n//1, :rand.seed_s(:exsss, base), fn _, r ->
        :rand.uniform_s(1 <<< 48, r)
      end)

    seeds
  end

  def sequence(seed) do
    r = :rand.seed_s(:exsss, seed)
    {world, r} = world_run(r)
    {extra, _r} = extra(r)
    [world, extra]
  end

  def line({:json, term}), do: Canonical.encode(term)
  def line({:raw, bin}), do: bin

  def fn_name({:json, %{"fn" => f}}), do: f
  def fn_name(_), do: "malformed"

  # ---------------------------------------------------------------- rand helpers

  defp int(r, lo, hi) do
    {x, r} = :rand.uniform_s(hi - lo + 1, r)
    {lo + x - 1, r}
  end

  defp pick(r, list) do
    {i, r} = int(r, 0, length(list) - 1)
    {Enum.at(list, i), r}
  end

  defp chance(r, pct) do
    {x, r} = int(r, 1, 100)
    {x <= pct, r}
  end

  # ------------------------------------------------------------------ world.run

  @tiny_scripts [
    [
      {"activate", %{}},
      {"move", %{"direction" => "north"}},
      {"take", %{}},
      {"take", %{}},
      :choose,
      :wait,
      {"move", %{"direction" => "south"}},
      {"drop", %{}},
      {"look", %{}}
    ],
    [
      {"move", %{"direction" => "north"}},
      {"take", %{}},
      {"take", %{}},
      {"move", %{"direction" => "south"}},
      {"activate", %{}},
      :choose,
      :wait,
      {"look", %{}}
    ],
    [
      :wait19,
      {"move", %{"direction" => "north"}},
      {"activate", %{}},
      {"take", %{}},
      {"take", %{}},
      :choose,
      {"drop", %{}}
    ]
  ]

  @lantern_fetch [
    {"move", %{"direction" => "north"}},
    {"move", %{"direction" => "east"}},
    {"move", %{"direction" => "east"}},
    {"take", %{}},
    {"move", %{"direction" => "west"}},
    {"move", %{"direction" => "west"}}
  ]

  @lantern_scripts [
    @lantern_fetch ++ [:wait19, {"activate", %{}}, {"talk", %{}}, :choose, {"look", %{}}],
    [{"activate", %{}}] ++ @lantern_fetch ++ [:wait19, {"talk", %{}}, {"talk", %{}}, :choose],
    [{"activate", %{}}, :wait19] ++
      @lantern_fetch ++ [{"talk", %{}}, {"close_choice", %{}}, {"talk", %{}}, :choose]
  ]

  @actions %{
    "tiny" => ~w(look activate move take drop wait choose),
    "lantern" => ~w(look activate move take drop talk choose close_choice wait)
  }

  defp world_run(r) do
    {world, r} = pick(r, ["tiny-event", "tiny-state", "lantern"])
    family = if world == "lantern", do: "lantern", else: "tiny"
    {shape, r} = int(r, 1, 10)

    {len, r} =
      case shape do
        1 -> {64, r}
        2 -> int(r, 1, 4)
        _ -> int(r, 1, 64)
      end

    {initial, r} = maybe(r, 35, &initial(&1, family))
    {script, r} = pick(r, if(family == "lantern", do: @lantern_scripts, else: @tiny_scripts))
    # Focused sequences follow the script closely to reach checks, choices and
    # resolutions; the others are noisy.
    {focused, r} = chance(r, 50)

    ctx = %{
      family: family,
      focused: focused,
      script: script,
      step: 0,
      n: 0,
      history: [],
      talks: [],
      rev: if(initial, do: initial["revision"], else: 0),
      clock: if(initial, do: initial["clock"], else: 6),
      pending: false,
      doubt: false
    }

    {cmds, {_ctx, r}} =
      Enum.map_reduce(1..len, {ctx, r}, fn _, {ctx, r} ->
        {cmd, ctx, r} = command(ctx, r)
        {cmd, {ctx, r}}
      end)

    req = %{"fn" => "world.run", "world" => world, "commands" => cmds}
    {{:json, if(initial, do: Map.put(req, "initial", initial), else: req)}, r}
  end

  defp maybe(r, pct, fun) do
    {yes, r} = chance(r, pct)
    if yes, do: fun.(r), else: {nil, r}
  end

  defp command(ctx, r) do
    {roll, r} = int(r, 1, 100)

    cond do
      ctx.pending and roll <= 45 -> settle(ctx, r)
      ctx.pending and roll <= 60 -> recover(ctx, r)
      ctx.doubt and roll <= 40 -> recover(ctx, r)
      roll <= t(ctx, 2, 4) -> recover(ctx, r)
      roll <= t(ctx, 4, 8) -> settle(ctx, r)
      roll <= t(ctx, 5, 10) -> invalid_command(ctx, r)
      true -> invoke(ctx, r)
    end
  end

  defp t(ctx, focused, noisy), do: if(ctx.focused, do: focused, else: noisy)

  defp recover(ctx, r),
    do: {%{"op" => "recover"}, %{ctx | doubt: ctx.pending}, r}

  defp settle(ctx, r) do
    {valid, r} = chance(r, 85)
    {committed, r} = if valid, do: pick(r, [true, false]), else: pick(r, ["true", 1, 0, nil, []])
    ctx = if is_boolean(committed), do: %{ctx | pending: false}, else: ctx
    {%{"op" => "settle", "committed" => committed}, ctx, r}
  end

  @invalid_commands [
    %{"op" => "reset"},
    %{"op" => 5},
    %{},
    %{"op" => "recover", "extra" => true},
    %{"op" => "settle"},
    %{"op" => "settle", "committed" => true, "x" => 1},
    %{"op" => "invoke"},
    %{
      "op" => "invoke",
      "request" => %{"id" => "x", "actor" => "hero", "action" => "look"},
      "options" => %{},
      "extra" => 1
    }
  ]

  defp invalid_command(ctx, r) do
    {cmd, r} = pick(r, @invalid_commands)
    {cmd, ctx, r}
  end

  defp invoke(ctx, r) do
    {kind, r} = int(r, 1, 100)
    has_history = ctx.history != []

    {request, ctx, r} =
      cond do
        has_history and kind <= t(ctx, 6, 14) ->
          {prior, r} = pick(r, ctx.history)
          {prior, ctx, r}

        has_history and kind <= t(ctx, 8, 19) ->
          altered(ctx, r)

        has_history and kind <= t(ctx, 9, 22) ->
          {prior, r} = pick(r, ctx.history)
          {view, r} = pick(r, ["view:0", "view:#{ctx.rev}", "view:#{ctx.rev + 1}"])
          {Map.put(prior, "view", view), ctx, r}

        kind <= t(ctx, 11, 27) ->
          {req, r} = pick(r, bad_envelopes(ctx.n))
          {req, %{ctx | n: ctx.n + 1}, r}

        true ->
          fresh(ctx, r)
      end

    {options, ctx, r} = options(ctx, r)
    cmd = %{"op" => "invoke", "request" => request}
    {if(options == :omit, do: cmd, else: Map.put(cmd, "options", options)), ctx, r}
  end

  defp altered(ctx, r) do
    {prior, r} = pick(r, ctx.history)
    {other, r} = pick(r, @actions[ctx.family])
    {until, r} = int(r, 7, 23)

    {req, r} =
      pick(r, [
        Map.put(prior, "action", other),
        Map.put(prior, "targets", ["bram"]),
        Map.put(prior, "input", %{"until" => until}),
        Map.put(prior, "input", %{"direction" => "west"})
      ])

    {req, ctx, r}
  end

  defp bad_envelopes(n) do
    id = "m#{n}"

    [
      5,
      "look",
      nil,
      [],
      true,
      %{},
      %{"id" => "", "actor" => "hero", "action" => "look"},
      %{"id" => id, "actor" => "hero"},
      %{"id" => id, "actor" => "hero", "action" => 5},
      %{"id" => 7, "actor" => "hero", "action" => "look"},
      %{"id" => id, "actor" => "hero", "action" => "look", "targets" => "lantern"},
      %{"id" => id, "actor" => "hero", "action" => "look", "targets" => [1]},
      %{"id" => id, "actor" => "hero", "action" => "look", "input" => []},
      %{"id" => id, "actor" => "hero", "action" => "look", "extra" => 1},
      %{"id" => id, "actor" => "bram", "action" => "look"},
      %{"id" => id, "actor" => "", "action" => "look"},
      %{"id" => id, "actor" => "hero", "action" => ""}
    ]
  end

  defp fresh(ctx, r) do
    {scripted, r} = chance(r, t(ctx, 90, 60))

    {action, input, ctx, r} =
      if scripted, do: scripted_step(ctx, r), else: random_action(ctx, r)

    id = "r#{ctx.n}"
    req = %{"id" => id, "actor" => "hero", "action" => action}
    {omit_input, r} = chance(r, 40)
    req = if input == %{} and omit_input, do: req, else: Map.put(req, "input", input)

    {req, r} = maybe_put(req, r, 20, "targets", [[], ["lantern"], ["lantern", "bram"]])

    {req, r} =
      maybe_put(req, r, t(ctx, 8, 25), "view", [
        "view:#{ctx.rev}",
        "view:#{ctx.rev}",
        "view:#{ctx.rev}",
        "view:#{ctx.rev - 1}",
        "view:#{ctx.rev + 1}",
        "view:0",
        "view:x",
        "view:-1"
      ])

    {req, r} = maybe_put(req, r, 4, "session", ["s1", ""])
    {req, r} = maybe_put(req, r, 3, "route", ["main"])
    {req, r} = maybe_put(req, r, 3, "seq", [0, 1, @max_safe])

    clock =
      case input do
        %{"until" => u} when is_integer(u) and u <= 48 -> max(ctx.clock, u)
        _ -> ctx.clock
      end

    talks =
      case action do
        "talk" -> [id | ctx.talks]
        "choose" -> []
        _ -> ctx.talks
      end

    ctx = %{
      ctx
      | n: ctx.n + 1,
        rev: if(scripted, do: ctx.rev + 1, else: ctx.rev),
        clock: clock,
        talks: talks,
        history: Enum.take([req | ctx.history], 16)
    }

    {req, ctx, r}
  end

  defp maybe_put(req, r, pct, key, values) do
    {yes, r} = chance(r, pct)

    if yes do
      {v, r} = pick(r, values)
      {Map.put(req, key, v), r}
    else
      {req, r}
    end
  end

  defp scripted_step(ctx, r) do
    step = Enum.at(ctx.script, rem(ctx.step, length(ctx.script)))
    ctx = %{ctx | step: ctx.step + 1}

    case step do
      {action, input} ->
        {action, input, ctx, r}

      :choose ->
        {input, r} = choose_input(ctx, r)
        {"choose", input, ctx, r}

      :wait ->
        {input, r} = wait_input(ctx, r)
        {"wait", input, ctx, r}

      :wait19 ->
        {"wait", %{"until" => if(ctx.clock < 19, do: 19, else: ctx.clock + 1)}, ctx, r}
    end
  end

  defp choose_input(ctx, r) do
    {choice, r} = pick(r, ["carry", "carry", "leave", "leave", "stay"])

    {continuation, r} =
      if ctx.family == "tiny" do
        pick(r, List.duplicate("lantern-offer-1", 6) ++ ["lantern-offer-2"])
      else
        oldest = "proof-choice:" <> (List.last(ctx.talks) || "none")
        latest = "proof-choice:" <> (List.first(ctx.talks) || "none")
        pick(r, [oldest, oldest, oldest, latest, latest, "proof-choice:bogus"])
      end

    {%{"choice_id" => choice, "continuation_id" => continuation}, r}
  end

  defp wait_input(ctx, r) do
    max = if ctx.family == "tiny", do: 48, else: 23
    {step, r} = int(r, 1, 6)

    {until, r} =
      pick(r, [
        ctx.clock + 1,
        ctx.clock + step,
        ctx.clock + step,
        19,
        18,
        max,
        max + 1,
        ctx.clock,
        0,
        -1,
        @max_safe,
        -@max_safe
      ])

    {%{"until" => until}, r}
  end

  defp random_action(ctx, r) do
    {action, r} = pick(r, @actions[ctx.family] ++ ["dance"])
    {good, r} = chance(r, 80)

    {input, r} =
      case action do
        "move" ->
          pick(r, [
            %{"direction" => "north"},
            %{"direction" => "south"},
            %{"direction" => "east"},
            %{"direction" => "west"},
            %{"direction" => "up"}
          ])

        "wait" ->
          wait_input(ctx, r)

        "choose" ->
          choose_input(ctx, r)

        _ ->
          {%{}, r}
      end

    if good do
      {action, input, ctx, r}
    else
      {bad, r} =
        pick(r, [
          Map.put(input, "extra", 1),
          %{"direction" => 5},
          %{"direction" => nil},
          %{"until" => "19"},
          %{"until" => true},
          %{"choice_id" => "carry"},
          %{}
        ])

      {action, bad, ctx, r}
    end
  end

  defp options(ctx, r) do
    {roll, r} = int(r, 1, 100)

    faults =
      ~w(before_commit commit_pending after_commit_before_memory after_memory_before_response)

    cond do
      roll <= t(ctx, 88, 60) ->
        {:omit, ctx, r}

      roll <= 74 ->
        {fault, r} = pick(r, faults)
        {with_auth, r} = chance(r, 15)
        opts = %{"fault" => fault}
        opts = if with_auth, do: Map.put(opts, "authorized", roll < 70), else: opts

        ctx =
          case fault do
            "commit_pending" -> %{ctx | pending: true, doubt: true}
            "after_commit_before_memory" -> %{ctx | doubt: true}
            _ -> ctx
          end

        {opts, ctx, r}

      roll <= 80 ->
        {%{"authorized" => true}, ctx, r}

      roll <= 84 ->
        {%{"authorized" => false}, ctx, r}

      roll <= 86 ->
        {%{}, ctx, r}

      roll <= 92 ->
        {opts, r} =
          pick(r, [
            nil,
            [],
            "x",
            %{"fault" => 1},
            %{"fault" => nil},
            %{"authorized" => "yes"},
            %{"authorized" => nil},
            %{"x" => 1},
            %{"fault" => "explode"},
            %{"fault" => ""}
          ])

        {opts, ctx, r}

      true ->
        {:omit, ctx, r}
    end
  end

  defp rng_words(r) do
    {kind, r} = int(r, 1, 10)

    case kind do
      1 ->
        pick(r, [[@u32, @u32, @u32, @u32], [0, 0, 0, 1], [1, 0, 0, 0], [1, 2, 3, 4]])

      _ ->
        {words, r} = Enum.map_reduce(1..4, r, fn _, r -> int(r, 0, @u32) end)
        {if(words == [0, 0, 0, 0], do: [0, 0, 1, 0], else: words), r}
    end
  end

  defp initial(r, "tiny") do
    {rng, r} = rng_words(r)
    {revision, r} = revision(r)
    {room, r} = pick(r, ["landing", "green"])
    {lantern, r} = pick(r, ["landing", "green", "hero"])
    {quest, r} = pick(r, ["absent", "active", "resolved"])
    {arrived, r} = pick(r, [true, false])
    {clock, r} = pick(r, [6, 6, 7, 12, 18, 19, 30, 47, 48])
    {bram, r} = pick(r, ["landing", "green"])
    {job, r} = pick(r, [true, false])
    {choice, r} = pick(r, [nil, nil, "lantern-offer-1"])
    {outcome, r} = pick(r, [nil, nil, "carry", "leave"])

    {%{
       "revision" => revision,
       "room" => room,
       "lantern" => lantern,
       "quest" => quest,
       "arrived" => arrived,
       "clock" => clock,
       "bram_room" => bram,
       "job_pending" => job,
       "rng" => rng,
       "choice" => choice,
       "outcome" => outcome
     }, r}
  end

  defp initial(r, "lantern") do
    rooms = ["landing", "green", "reed_bank", "shelter"]
    {rng, r} = rng_words(r)
    {revision, r} = revision(r)
    {room, r} = pick(r, rooms)
    {lantern, r} = pick(r, rooms ++ ["hero", "hero", "bram"])
    {quest, r} = pick(r, ["absent", "active", "active", "resolved"])
    {choice, r} = pick(r, [nil, nil, "proof-choice:r0", "proof-choice:old"])
    {plan, r} = pick(r, ["undecided", "player_led", "party_led"])
    {clock, r} = pick(r, [6, 6, 7, 12, 18, 19, 22, 23])
    {bram, r} = pick(r, ["landing", "green"])

    {narration, r} =
      pick(r, [
        [],
        [],
        [
          %{
            "id" => "proof-choice:r0:outcome",
            "text_key" => "proof.carry",
            "bindings" => %{"actor" => "hero", "bram" => "bram", "lantern" => "lantern"}
          }
        ]
      ])

    {milestone, r} =
      pick(r, [
        nil,
        nil,
        %{"key" => "proof.terminal", "occurrence" => "proof-choice:r0", "outcome" => "carry"}
      ])

    {%{
       "revision" => revision,
       "room" => room,
       "lantern" => lantern,
       "quest" => quest,
       "choice" => choice,
       "search_plan" => plan,
       "clock" => clock,
       "bram_room" => bram,
       "rng" => rng,
       "narration" => narration,
       "milestone" => milestone
     }, r}
  end

  # Stays at least 64 below the safe maximum so accepted steps cannot overflow it
  # (see NOTES.md).
  defp revision(r) do
    {kind, r} = int(r, 1, 10)
    if kind == 1, do: {@max_safe - 64, r}, else: int(r, 0, 50)
  end

  # --------------------------------------------------------------- extra request

  defp extra(r) do
    {roll, r} = int(r, 1, 100)

    cond do
      roll <= 45 -> composition(r)
      roll <= 53 -> rng_next(r)
      roll <= 61 -> rng_uniform(r)
      roll <= 69 -> int_divide(r)
      roll <= 84 -> json_canonical(r)
      roll <= 90 -> malformed(r)
      true -> edge(r)
    end
  end

  # ------------------------------------------------ settled edge rules (README)

  @edge_json [
    %{"fn" => "rng.next", "state" => [1, 2, 3, 4], "x" => 1},
    %{"fn" => "int.divide", "a" => 7, "b" => 2, "c" => 0},
    %{"fn" => "json.canonical", "text" => "1", "extra" => nil},
    %{"fn" => "world.run", "world" => "lantern", "commands" => [], "extra" => 1},
    %{"fn" => "world.run", "world" => "tiny-event", "commands" => []},
    %{"fn" => "world.run", "world" => "tiny-state", "commands" => []},
    %{"fn" => "world.run", "world" => "lantern", "commands" => []},
    %{"fn" => "world.run", "world" => "lantern", "commands" => [5, %{"op" => "recover"}]},
    %{"fn" => "world.run", "world" => "tiny-event", "commands" => [nil, "recover", [], true]},
    %{
      "fn" => "world.run",
      "world" => "tiny-state",
      "commands" => [%{"op" => "recover"}, 0, %{"op" => "settle", "committed" => true}]
    },
    %{"fn" => "world.run", "world" => "tiny", "commands" => [%{"op" => "recover"}]},
    %{"fn" => "world.run", "world" => "Lantern", "commands" => [%{"op" => "recover"}]},
    %{"fn" => "world.run", "world" => 5, "commands" => [%{"op" => "recover"}]},
    %{"fn" => "world.run", "world" => nil, "commands" => []},
    %{"fn" => "world.run", "world" => "lantern", "initial" => [], "commands" => []},
    %{"fn" => "world.run", "world" => "tiny-event", "initial" => 5, "commands" => []},
    %{"fn" => "world.run", "world" => "tiny-state", "initial" => nil, "commands" => []},
    %{"fn" => "world.run", "world" => "lantern", "initial" => "x", "commands" => []}
  ]

  @edge_limits [
    %{"operations" => 0},
    %{"operations" => -1},
    %{"reaction_depth" => 0},
    %{"events" => "5"},
    %{"deliveries" => nil},
    %{"nope" => 5},
    %{"selector_cardinality" => 3},
    %{"output_bytes" => true},
    [],
    5,
    nil
  ]

  @invalid_utf8 [
    <<"{\"fn\":\"json.canonical\",\"text\":\"", 0xFF, "\"}">>,
    <<"{\"fn\":\"json.canonical\",\"text\":\"", 0xC0, 0xAF, "\"}">>,
    <<"{\"fn\":\"json.canonical\",\"text\":\"", 0x80, "\"}">>,
    <<"{\"fn\":\"json.canonical\",\"text\":\"", 0xED, 0xA0, 0x80, "\"}">>,
    <<"{\"fn\":\"json.canonical\",\"text\":\"", 0xE6, 0x97, "\"}">>,
    <<"{\"fn\":\"rng.next\",\"state\":[1,2,3,4]}", 0xFF>>,
    <<"{\"fn\":\"rng.next\",\"state\":[1,2,3,4],\"", 0xC3, "\":1}">>
  ]

  defp edge(r) do
    {kind, r} = int(r, 1, 8)

    case kind do
      k when k <= 2 ->
        {req, r} = pick(r, @edge_json)
        {{:json, req}, r}

      3 ->
        {{:json, req}, r} = composition(r)
        {limits, r} = pick(r, @edge_limits)
        {{:json, %{req | "limits" => limits}}, r}

      4 ->
        {{:json, req}, r} = composition(r)

        {req, r} =
          pick(r, [
            Map.put(req, "advance_target", nil),
            Map.put(req, "advance_target", nil),
            %{req | "root" => 5},
            %{req | "rules" => %{}},
            %{req | "initial" => %{}},
            %{req | "initial" => Map.delete(req["initial"], "clock")},
            Map.put(req, "x", 1)
          ])

        {{:json, req}, r}

      5 ->
        {line, r} = pick(r, ["", "\r", " ", "\t", " \r"])
        {{:raw, line}, r}

      6 ->
        {gen, r} = pick(r, [&rng_next/1, &rng_uniform/1, &int_divide/1, &json_canonical/1])
        {req, r} = gen.(r)
        {{:raw, line(req) <> "\r"}, r}

      _ ->
        {line, r} = pick(r, @invalid_utf8)
        {{:raw, line}, r}
    end
  end

  defp rng_state(r) do
    {valid, r} = chance(r, 75)

    if valid do
      rng_words(r)
    else
      pick(r, [
        [0, 0, 0, 0],
        [1, 2, 3],
        [1, 2, 3, 4, 5],
        [-1, 2, 3, 4],
        [@u32 + 1, 1, 1, 1],
        [true, 2, 3, 4],
        [1, 2, 3, nil],
        [1, 2, 3, "4"],
        "1,2,3,4",
        nil,
        %{},
        []
      ])
    end
  end

  defp rng_next(r) do
    {state, r} = rng_state(r)
    {{:json, %{"fn" => "rng.next", "state" => state}}, r}
  end

  defp rng_uniform(r) do
    {state, r} = rng_state(r)
    {random_bound, r} = int(r, 1, @u32 + 1)

    {bound, r} =
      pick(r, [
        random_bound,
        random_bound,
        1,
        2,
        6,
        100,
        100,
        0x80000001,
        0x80000001,
        @u32,
        @u32 + 1,
        0,
        -1,
        @u32 + 2,
        true,
        "100",
        nil
      ])

    {draws, r} = pick(r, [1024, 1024, 1, 1, 2, 3, 0, 10, -1, true, "1", nil])

    {{:json, %{"fn" => "rng.uniform", "state" => state, "bound" => bound, "max_draws" => draws}},
     r}
  end

  defp operand(r) do
    {kind, r} = int(r, 1, 20)

    cond do
      kind <= 8 -> pick(r, [0, 1, -1, 2, -2, 3, -3, 7, -7, @max_safe, -@max_safe, @max_safe - 1])
      kind <= 13 -> int(r, -100, 100)
      kind <= 19 -> int(r, -@max_safe, @max_safe)
      true -> pick(r, [true, false, "1", nil, [1], %{}])
    end
  end

  defp int_divide(r) do
    {a, r} = operand(r)
    {zero, r} = chance(r, 10)
    {b, r} = if zero, do: {0, r}, else: operand(r)
    {{:json, %{"fn" => "int.divide", "a" => a, "b" => b}}, r}
  end

  # ------------------------------------------------------------- json.canonical

  defp json_canonical(r) do
    {valid, r} = chance(r, 45)
    {text, r} = if valid, do: jtext(r, 0), else: bad_json(r)
    {{:json, %{"fn" => "json.canonical", "text" => text}}, r}
  end

  @strings [
    "",
    "a",
    "héllo",
    "日本語",
    "😀",
    "tab\there",
    "quote\"",
    "back\\slash",
    "ctl\u0001x",
    "del\u007f",
    "line\u2028sep",
    "nul\u0000",
    "slash/",
    "nl\nnl"
  ]

  @keys ["a", "b", "z", "A", "_", "a b", "10", "2", "", "key\"q"]

  defp ws(r), do: pick(r, ["", "", "", " ", "\n", "\t ", "\r\n"])

  defp jtext(r, depth) do
    {kind, r} = int(r, 1, if(depth < 3, do: 8, else: 5))
    {pre, r} = ws(r)
    {post, r} = ws(r)

    {body, r} =
      case kind do
        1 ->
          {n, r} = operand(r)
          {Integer.to_string(if(is_integer(n), do: n, else: 3)), r}

        2 ->
          {s, r} = pick(r, @strings)
          jstring(s, r)

        3 ->
          pick(r, ["true", "false", "null", "-0", "0"])

        4 ->
          {n, r} = int(r, -1000, 1000)
          {Integer.to_string(n), r}

        5 ->
          {s, r} = pick(r, @strings)
          jstring(s, r)

        6 ->
          {n, r} = int(r, 0, 3)

          {items, r} =
            Enum.map_reduce(1..n//1, r, fn _, r -> jtext(r, depth + 1) end)

          {"[" <> Enum.join(items, ",") <> "]", r}

        _ ->
          {n, r} = int(r, 0, 3)
          {keys, r} = Enum.map_reduce(1..n//1, r, fn _, r -> pick(r, @keys) end)

          {pairs, r} =
            keys
            |> Enum.uniq()
            |> Enum.map_reduce(r, fn k, r ->
              {ks, r} = jstring(k, r)
              {v, r} = jtext(r, depth + 1)
              {ks <> ":" <> v, r}
            end)

          {"{" <> Enum.join(pairs, ",") <> "}", r}
      end

    {pre <> body <> post, r}
  end

  # A JSON string literal for `s` with randomly chosen (valid) escape styles.
  defp jstring(s, r) do
    {chars, r} =
      s
      |> String.to_charlist()
      |> Enum.map_reduce(r, fn c, r ->
        {style, r} = int(r, 1, 4)
        {jchar(c, style), r}
      end)

    {"\"" <> Enum.join(chars) <> "\"", r}
  end

  defp jchar(?", _), do: "\\\""
  defp jchar(?\\, _), do: "\\\\"
  defp jchar(?/, 1), do: "\\/"
  defp jchar(?\n, 1), do: "\\n"
  defp jchar(?\t, 1), do: "\\t"
  defp jchar(c, style) when c < 0x20 or style == 2, do: u_escape(c, :lower)
  defp jchar(c, 3) when c > 0x7F, do: u_escape(c, :upper)
  defp jchar(c, _), do: <<c::utf8>>

  defp u_escape(c, case) when c > 0xFFFF do
    v = c - 0x10000
    u_escape(0xD800 + (v >>> 10), case) <> u_escape(0xDC00 + (v &&& 0x3FF), case)
  end

  defp u_escape(c, case) do
    hex = c |> Integer.to_string(16) |> String.pad_leading(4, "0")
    "\\u" <> if(case == :lower, do: String.downcase(hex), else: hex)
  end

  @bad_json [
    ~s({"a":1,"a":2}),
    ~s({"a":1,"b":{"c":1,"c":1}}),
    ~s([{"x":true,"x":true}]),
    "1.0",
    "1.5",
    "-0.0",
    "1e3",
    "1E-2",
    "2.5e+10",
    "[0.1]",
    "9007199254740992",
    "-9007199254740992",
    "9007199254740993",
    "123456789012345678901234567890",
    "[9007199254740991,-9007199254740991]",
    "01",
    "-",
    "+1",
    ".5",
    "NaN",
    "Infinity",
    "-Infinity",
    "[NaN]",
    ~S("\ud800"),
    ~S("\udfff"),
    ~S("\udc00\ud800"),
    ~S("a\ud83d"),
    ~S("😀"),
    ~S("😀"),
    ~S({"😀":1}),
    ~s({"é":1}),
    ~S({"é":1}),
    ~S({"A":1}),
    "\"a\u0001b\"",
    "\"tab\there\"",
    "[1,]",
    ~s({"a":1,}),
    "[1,2",
    ~s({"a"),
    "1 2",
    "{} x",
    "",
    "   ",
    "\uFEFF{}",
    "'a'",
    "tru",
    "nul",
    "\u00A01",
    ~S("\x"),
    ~S("\u12"),
    ~S("\U0041"),
    "[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]",
    "{\"a\":[1,{\"b\":null}]}"
  ]

  defp bad_json(r) do
    {core, r} = pick(r, @bad_json)
    {wrap, r} = int(r, 1, 3)

    text =
      case wrap do
        1 -> core
        2 -> "[" <> core <> "]"
        3 -> ~s({"x":) <> core <> "}"
      end

    {text, r}
  end

  # ---------------------------------------------------------------- malformed

  @malformed [
    "{",
    "[]",
    "null",
    "5",
    ~s("rng.next"),
    ~s({}),
    ~s({"fn":"nope"}),
    ~s({"fn":5}),
    ~s({"fn":null,"state":[1,2,3,4]}),
    ~s({"fn":"rng.next"}),
    ~s({"fn":"rng.uniform","state":[1,2,3,4],"bound":6}),
    ~s({"fn":"int.divide","a":1}),
    ~s({"fn":"json.canonical","text":5}),
    ~s({"fn":"json.canonical"}),
    ~s({"fn":"rng.next","fn":"rng.next","state":[1,2,3,4]}),
    ~s({"fn":"int.divide","a":1.0,"b":1}),
    ~s({"fn":"int.divide","a":1e2,"b":1}),
    ~s({"fn":"int.divide","a":9007199254740992,"b":1}),
    ~s({"fn":"int.divide","a":-9007199254740992,"b":1}),
    ~s({"fn":"int.divide","a":NaN,"b":1}),
    ~s({"fn":"int.divide","a":-0,"b":1}),
    ~s({"fn":"rng.next","state":[1,2,3,4],"é":1}),
    ~S({"fn":"json.canonical","text":"\ud800"}),
    ~s({"fn":"world.run","world":"moon","commands":[{"op":"recover"}]}),
    ~s({"fn":"world.run","world":"lantern","commands":5}),
    ~s({"fn":"world.run","world":"lantern"}),
    ~s({"fn":"world.run","commands":[{"op":"recover"}]}),
    ~s({"fn":"composition.evaluate","initial":{},"root":[],"rules":[]}),
    ~s( {"state" : [1, 2, 3, 4], "fn" : "rng.next"}),
    ~s({"fn":"rng.next","state":[1,2,3,4]} ),
    ~s({"b":-7,"a":22,"fn":"int.divide"}),
    ~S({"fn":"json.canonical","text":"A\/é"}),
    ~s({"fn":"rng.next","state":[1,2,3,4]}{}),
    ~s({"fn":"rng.next","state":[1,2,3,4],})
  ]

  defp malformed(r) do
    {line, r} = pick(r, @malformed)
    {{:raw, line}, r}
  end

  # -------------------------------------------------------- composition.evaluate

  @rule_ids ~w(alpha beta chain observe relay)
  @limit_keys ~w(operations query_steps events deliveries reaction_depth created_jobs pending_jobs output_bytes)

  defp composition(r) do
    {initial, r} = comp_initial(r)
    {n_rules, r} = int(r, 0, 4)
    {ids, r} = Enum.map_reduce(1..n_rules//1, r, fn _, r -> rule_id(r) end)
    known = Enum.filter(ids, &is_binary/1)
    {rules, r} = Enum.map_reduce(ids, r, fn id, r -> rule(id, known, initial, r) end)
    {active, r} = active(known, r)
    initial = Map.put(initial, "active", active)
    {n_root, r} = int(r, 0, 6)
    {root, r} = Enum.map_reduce(1..n_root//1, r, fn _, r -> op(known, initial, r) end)
    {limits, r} = limits(r)

    req = %{
      "fn" => "composition.evaluate",
      "limits" => limits,
      "initial" => initial,
      "root" => root,
      "rules" => rules
    }

    {kind, r} = int(r, 1, 10)
    {target, r} = int(r, initial["clock"] - 1, initial["clock"] + 10)

    req =
      cond do
        kind <= 7 -> req
        kind <= 9 -> Map.put(req, "advance_target", target)
        true -> Map.put(req, "advance_target", "soon")
      end

    {{:json, req}, r}
  end

  defp rule_id(r) do
    {bad, r} = chance(r, 5)
    if bad, do: pick(r, ["Bad", "9x", "", 5]), else: pick(r, @rule_ids)
  end

  defp active(known, r) do
    {ids, r} =
      Enum.reduce(known, {[], r}, fn id, {acc, r} ->
        {yes, r} = chance(r, 60)
        {if(yes, do: [id | acc], else: acc), r}
      end)

    {unknown, r} = chance(r, 4)
    {Enum.sort(Enum.uniq(if(unknown, do: ["ghost" | ids], else: ids))), r}
  end

  defp comp_initial(r) do
    {flag, r} = int(r, 0, 2)
    {seen, r} = int(r, 0, 2)
    {count, r} = pick(r, [0, 0, 1, -1, 2_147_483_647, -2_147_483_648, 2_147_483_646])
    {in_bag, r} = chance(r, 20)
    {cap, r} = pick(r, [1, 1, 2, 0])
    {clock, r} = pick(r, [6, 6, 0, 10, 23])
    {jobs, r} = pick(r, [%{}, %{}, %{"j1" => clock + 5}])

    {%{
       "facts" => %{"flag" => flag, "seen" => seen, "count" => count},
       "locations" => %{
         "lantern" => if(in_bag, do: "bag", else: "hero"),
         "stone" => "room",
         "bag" => "hero"
       },
       "capacities" => %{"bag" => cap},
       "active" => [],
       "clock" => clock,
       "jobs" => jobs
     }, r}
  end

  defp rule(id, known, initial, r) do
    {event, r} =
      pick(r, ["proof.signal", "proof.signal", "proof.followup", "engine.item_transferred"])

    {guard, r} = guard(r)
    {n, r} = int(r, 0, 3)
    {ops, r} = Enum.map_reduce(1..n//1, r, fn _, r -> op(known, initial, r) end)
    rule = %{"id" => id, "event" => event, "guard" => guard, "ops" => ops}
    {bad, r} = chance(r, 4)

    if bad do
      pick(r, [
        Map.delete(rule, "guard"),
        Map.put(rule, "extra", 1),
        Map.put(rule, "event", "proof.unknown"),
        Map.put(rule, "ops", %{})
      ])
    else
      {rule, r}
    end
  end

  defp guard(r) do
    {kind, r} = int(r, 1, 10)
    {equals, r} = pick(r, [0, 1, 2, "hero", "bag", true, nil])

    cond do
      kind <= 5 ->
        {nil, r}

      kind <= 7 ->
        {key, r} = pick(r, ["flag", "seen", "count"])
        {%{"source" => "overlay", "key" => key, "equals" => equals}, r}

      kind <= 9 ->
        {key, r} = pick(r, ["value", "item", "to", "from"])
        {%{"source" => "event", "key" => key, "equals" => equals}, r}

      true ->
        pick(r, [
          %{"source" => "world", "key" => "flag", "equals" => 1},
          %{"source" => "overlay", "key" => "mood", "equals" => 1},
          %{"source" => "overlay", "key" => "flag"},
          "always"
        ])
    end
  end

  defp op(known, initial, r) do
    {kind, r} = int(r, 1, 100)
    clock = initial["clock"]
    items = ["lantern", "stone", "bag"]
    places = ["hero", "room", "bag", "lantern"]

    cond do
      kind <= 18 ->
        {fact, r} = pick(r, ["flag", "flag", "seen", "count"])
        {v, r} = pick(r, [0, 1, 2, 2, 3, -1, 2_147_483_647])
        {%{"op" => "fact.set", "fact" => fact, "value" => v}, r}

      kind <= 30 ->
        {fact, r} = pick(r, ["count", "count", "count", "flag"])
        {v, r} = pick(r, [1, 1, -1, 2, 2_147_483_647, -2_147_483_648])
        {%{"op" => "fact.add", "fact" => fact, "amount" => v}, r}

      kind <= 50 ->
        {event, r} =
          pick(r, ["proof.signal", "proof.signal", "proof.followup", "engine.item_transferred"])

        {v, r} = int(r, 0, 2)
        {payload, r} = pick(r, [%{"value" => v}, %{"value" => v}, %{}, %{"item" => "bag"}])
        {%{"op" => "event.emit", "event" => event, "payload" => payload}, r}

      kind <= 60 ->
        {rule, r} = pick(r, known ++ ["ghost"])
        {%{"op" => "subscription.activate", "rule" => rule}, r}

      kind <= 78 ->
        {item, r} = pick(r, items)
        {source, r} = pick(r, ["hero", "hero", "room", "bag", "lantern"])
        {dest, r} = pick(r, places ++ ["moon", ""])
        {%{"op" => "item.transfer", "item" => item, "source" => source, "destination" => dest}, r}

      kind <= 90 ->
        {id, r} = pick(r, ["j1", "j2", "j2", "j3", ""])
        {due, r} = int(r, clock - 1, clock + 30)
        {%{"op" => "job.schedule", "id" => id, "due" => due}, r}

      true ->
        pick(r, [
          %{"op" => "nope"},
          %{"op" => "fact.set", "fact" => "flag"},
          %{"op" => "fact.set", "fact" => "flag", "value" => 1, "x" => 1},
          %{"op" => "fact.set", "fact" => "mood", "value" => 1},
          %{"op" => "fact.set", "fact" => "flag", "value" => "1"},
          %{"op" => "event.emit", "event" => "proof.signal", "payload" => []},
          %{"op" => "job.schedule", "id" => 5, "due" => 99},
          %{"op" => "item.transfer", "item" => 1, "source" => "hero", "destination" => "room"},
          "fact.set"
        ])
    end
  end

  defp limits(r) do
    {n, r} = pick(r, [0, 0, 0, 0, 1, 1, 2, 3])
    {keys, r} = Enum.map_reduce(1..n//1, r, fn _, r -> pick(r, @limit_keys) end)

    Enum.reduce(keys, {%{}, r}, fn key, {acc, r} ->
      {v, r} =
        case key do
          "output_bytes" -> int(r, 50, 2000)
          "query_steps" -> int(r, 1, 60)
          _ -> int(r, 1, 5)
        end

      {Map.put(acc, key, v), r}
    end)
  end
end
