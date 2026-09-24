defmodule LokaR1Server.HostTest do
  @moduledoc "The durable host against the model host, SQLite read-back, and the real faults."
  use ExUnit.Case, async: false
  alias LokaR1.Codec
  alias LokaR1Server.{Faults, Host, Store}

  setup do
    dir = Path.join(System.tmp_dir!(), "r1-server-test-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    %{dir: dir, db: Path.join(dir, "t.sqlite")}
  end

  defp invoke(id, action, extra \\ %{}),
    do: %{
      "op" => "invoke",
      "request" => Map.merge(%{"id" => id, "actor" => "hero", "action" => action}, extra)
    }

  defp with_options(command, options), do: Map.put(command, "options", options)
  defp north(id), do: invoke(id, "move", %{"input" => %{"direction" => "north"}})

  # Every model fault option, settle both ways, recover, replays, integrity
  # conflicts, stale views, rejections, failed rolls and malformed commands.
  defp script,
    do: [
      invoke("x", "look", %{"actor" => "villain"}),
      invoke("s", "look", %{"view" => "view:9"}),
      invoke("s", "look", %{"view" => "view:9"}),
      north("a"),
      north("a"),
      invoke("a", "take"),
      invoke("t1", "take") |> with_options(%{"fault" => "before_commit"}),
      invoke("t1", "take"),
      invoke("t1", "take"),
      invoke("d", "drop") |> with_options(%{"fault" => "commit_pending"}),
      invoke("e", "look"),
      %{"op" => "recover"},
      %{"op" => "settle", "committed" => "yes"},
      %{"op" => "settle", "committed" => true},
      %{"op" => "settle", "committed" => false},
      %{"op" => "recover"},
      invoke("w", "wait", %{"input" => %{"until" => 20}})
      |> with_options(%{"fault" => "after_commit_before_memory"}),
      invoke("w2", "look"),
      %{"op" => "recover"},
      invoke("m", "activate") |> with_options(%{"fault" => "after_memory_before_response"}),
      invoke("m", "activate"),
      invoke("o", "look") |> with_options(%{"fault" => "nope"}),
      invoke("o", "look") |> with_options(%{"authorized" => 1}),
      invoke("o", "look") |> with_options(%{"authorized" => false}),
      %{"op" => "jump"},
      5
    ]

  test "step records are byte-identical to the model host's in every world", %{dir: dir} do
    for world <- ~w(tiny-event tiny-state lantern),
        initial <- [nil, %{"rng" => [9, 8, 7, 6]}] do
      {_, default} = LokaR1.World.world(world)
      request = %{"fn" => "world.run", "world" => world, "commands" => script()}

      request =
        if initial, do: Map.put(request, "initial", Map.merge(default, initial)), else: request

      line = Codec.encode(request)
      db = Path.join(dir, "#{world}-#{initial != nil}.sqlite")
      assert LokaR1Server.Runner.handle_line(line, db, "i") == LokaR1.Runner.handle_line(line)
    end
  end

  test "a model raise answers invalid_protocol, like the model host", %{db: db} do
    bad = Map.put(LokaR1.Tiny.initial(), "room", "nowhere")

    line =
      Codec.encode(%{
        "fn" => "world.run",
        "world" => "tiny-event",
        "initial" => bad,
        "commands" => [north("a")]
      })

    assert LokaR1Server.Runner.handle_line(line, db, "i") == ~s({"error":"invalid_protocol"})
  end

  test "durable, receipts and pending come from SQLite, not process memory", %{db: db} do
    {:ok, pid} = Host.start(db: db, id: "i", world: "tiny-event", initial: LokaR1.Tiny.initial())
    {:ok, _} = Host.step(pid, north("a"))
    conn = Store.open(db)
    Store.exec!(conn, "UPDATE instances SET durable = '{\"planted\":true}' WHERE id = 'i'")
    Store.exec!(conn, "DELETE FROM receipts")
    Store.close(conn)
    {:ok, record} = Host.step(pid, %{"op" => "jump"})
    assert record["state"]["durable"] == %{"planted" => true}
    assert record["state"]["receipts"] == %{}
    Host.stop(pid)
  end

  test "io_error is a real SQLITE_FULL inside the transaction", %{db: db} do
    conn = Store.open(db)
    Store.exec!(conn, "BEGIN IMMEDIATE")
    error = assert_raise Store.Error, fn -> Store.fill!(conn) end
    assert error.reason =~ "full"
    Store.close(conn)
  end

  test "every point and kind passes, and a wrong recovery is caught", %{dir: dir} do
    records = for pk <- Faults.matrix(), do: Faults.run("tiny-event", 1, pk, dir)
    assert length(records) == 14

    for r <- records,
        do: assert(r["verdict"] == "pass", Codec.encode(Map.take(r, ~w(fault checks))))

    # Sensitivity: a recovered host that kept a hidden RNG advance must fail.
    r = Enum.find(records, &(&1["fault"]["kind"] == "io_error"))
    tampered = put_in(r, ["recovered", "durable", "rng"], [7, 0, 1026, 12288])
    {initial, prefix, attempt} = Faults.script("tiny-event", 1)

    spec = %{
      world: "tiny-event",
      initial: initial,
      commands: prefix ++ [attempt],
      fault: r["fault"]
    }

    assert Faults.judge(tampered, spec, attempt)["verdict"] == "fail"
  end
end
