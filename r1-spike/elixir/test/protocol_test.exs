defmodule LokaR1.ProtocolTest do
  @moduledoc "The README runner protocol: error codes, edge rules, codec edges and the stdio process."
  use ExUnit.Case, async: true
  import Fixtures, only: [call: 1]
  alias LokaR1.{Codec, Runner, Tiny, World}

  @invalid %{"error" => "invalid_protocol"}
  @activate %{"id" => "a", "actor" => "hero", "action" => "activate"}

  defp world(commands, extra \\ %{}),
    do:
      call(
        Map.merge(%{"fn" => "world.run", "world" => "tiny-event", "commands" => commands}, extra)
      )

  defp invoke(options), do: %{"op" => "invoke", "request" => @activate, "options" => options}

  describe "invalid_protocol" do
    test "unparseable lines, blank lines and invalid UTF-8" do
      for line <- [
            "",
            " ",
            "garbage",
            "{",
            "{\"fn\":\"rng.next\",\"state\":[1,2,3,4]} x",
            <<0xFF>>,
            "\"\xED\xA0\x80\"",
            "\uFEFF{}"
          ] do
        assert Runner.handle_line(line) == ~s({"error":"invalid_protocol"}), inspect(line)
      end
    end

    test "a trailing carriage return is JSON whitespace" do
      assert Runner.handle_line(~s({"fn":"rng.next","state":[1,2,3,4]}\r)) =~ ~s("raw":11520)
    end

    test "unknown fn, extra or missing arguments, and wrong argument shapes" do
      requests = [
        [],
        %{},
        %{"fn" => "nope"},
        %{"fn" => "rng.next"},
        %{"fn" => "rng.next", "state" => [1, 2, 3, 4], "extra" => 1},
        %{"fn" => "rng.uniform", "state" => [1, 2, 3, 4], "bound" => 10},
        %{"fn" => "int.divide", "a" => 1},
        %{"fn" => "json.canonical", "text" => 1},
        %{"fn" => "world.run", "world" => "tiny", "commands" => []},
        %{"fn" => "world.run", "world" => "tiny-event", "commands" => %{}},
        %{"fn" => "world.run", "world" => "tiny-event"},
        %{"fn" => "world.run", "world" => "tiny-event", "commands" => [], "initial" => []},
        %{"fn" => "world.run", "world" => "tiny-event", "commands" => [], "extra" => 1},
        %{"fn" => "composition.evaluate", "limits" => %{}, "initial" => %{}, "root" => []},
        %{
          "fn" => "composition.evaluate",
          "limits" => [],
          "initial" => %{},
          "root" => [],
          "rules" => []
        },
        %{
          "fn" => "composition.evaluate",
          "limits" => %{},
          "initial" => %{},
          "root" => [],
          "rules" => [],
          "x" => 1
        }
      ]

      for request <- requests, do: assert(call(request) == @invalid, inspect(request))
    end

    test "composition limits must be profile names with positive integer values" do
      for limits <- [
            %{"nope" => 1},
            %{"events" => 0},
            %{"events" => -1},
            %{"events" => true},
            %{"events" => nil}
          ] do
        request = %{
          "fn" => "composition.evaluate",
          "limits" => limits,
          "initial" => %{},
          "root" => [],
          "rules" => []
        }

        assert call(request) == @invalid, inspect(limits)
      end
    end

    test "a world memory the Python model would raise on" do
      initial = %{Tiny.initial() | "room" => "attic"}

      move = %{
        "op" => "invoke",
        "request" =>
          %{@activate | "action" => "move"} |> Map.put("input", %{"direction" => "north"})
      }

      assert world([move], %{"initial" => initial}) == @invalid
    end
  end

  describe "world.run step errors change nothing" do
    setup do
      [first] = world([%{"op" => "invoke", "request" => @activate}])
      %{host: first["state"]}
    end

    test "each code", %{host: host} do
      cases = [
        {invoke([]), "invalid_options"},
        {invoke(%{"x" => 1}), "invalid_options"},
        {invoke(%{"fault" => 1}), "invalid_options"},
        {invoke(%{"fault" => nil}), "invalid_options"},
        {invoke(%{"authorized" => 1}), "invalid_options"},
        {invoke(%{"authorized" => nil}), "invalid_options"},
        {invoke(%{"fault" => "typo"}), "unknown_fault"},
        {invoke(%{"fault" => "typo", "authorized" => false}), "unknown_fault"},
        {%{"op" => "settle", "committed" => 1}, "invalid_commit_disposition"},
        {%{"op" => "settle", "committed" => nil}, "invalid_commit_disposition"},
        {%{"op" => "settle", "committed" => true}, "no_pending_transaction"},
        {%{"op" => "settle", "committed" => false}, "no_pending_transaction"},
        {%{"op" => "nope"}, "invalid_command"},
        {%{"op" => "invoke"}, "invalid_command"},
        {%{"op" => "invoke", "request" => @activate, "extra" => 1}, "invalid_command"},
        {%{"op" => "recover", "extra" => 1}, "invalid_command"},
        {%{"op" => "settle"}, "invalid_command"},
        {%{"request" => @activate}, "invalid_command"},
        {%{"op" => 1}, "invalid_command"},
        {[], "invalid_command"},
        {"recover", "invalid_command"},
        {nil, "invalid_command"}
      ]

      activate = %{"op" => "invoke", "request" => @activate}

      for {command, code} <- cases do
        [_, record] = world([activate, command])

        assert record == %{
                 "result" => nil,
                 "error" => code,
                 "events" => [],
                 "delta" => %{},
                 "state" => host
               },
               inspect(command)
      end
    end

    test "invalid_commit_disposition is checked before no_pending_transaction" do
      [record] = world([%{"op" => "settle", "committed" => "yes"}])
      assert record["error"] == "invalid_commit_disposition"
    end
  end

  describe "world.run" do
    test "an empty command list" do
      assert world([]) == []
    end

    test "a missing authorized means authorized; false is unauthorized" do
      [a] = world([invoke(%{})])
      assert a["result"]["code"] == "activated"
      [b] = world([invoke(%{"authorized" => false})])
      assert b["result"]["code"] == "unauthorized"
    end

    test "records carry events and delta, and settle's result is null" do
      pending = invoke(%{"fault" => "commit_pending"})

      [a, b, c, d] =
        world([
          pending,
          %{"op" => "settle", "committed" => true},
          %{"op" => "recover"},
          %{"op" => "invoke", "request" => @activate}
        ])

      assert a["result"]["code"] == "commit_pending" and a["delta"] == %{} and
               a["state"]["in_doubt"]

      assert a["state"]["pending"]["id"] == "a"

      assert b["result"] == nil and b["error"] == nil and
               b["state"]["durable"]["quest"] == "active"

      assert c["delta"] == %{"quest" => "active", "revision" => 1} and c["events"] == []
      assert d["result"]["delivery"] == "replay"
    end

    test "the intent digest is SHA-256 of the canonical actor/action/targets/input" do
      {:ok, digest} = World.intent(@activate)
      canonical = ~s({"action":"activate","actor":"hero","input":{},"targets":[]})
      assert digest == Base.encode16(:crypto.hash(:sha256, canonical), case: :lower)
    end
  end

  describe "pure functions" do
    test "composition advance_target null is the same as absent" do
      base = %{
        "fn" => "composition.evaluate",
        "limits" => %{},
        "initial" => %{
          "clock" => 6,
          "active" => [],
          "facts" => %{},
          "locations" => %{},
          "capacities" => %{},
          "jobs" => %{}
        },
        "root" => [],
        "rules" => []
      }

      assert call(Map.put(base, "advance_target", nil)) == call(base)
      assert call(base)["code"] == "ok"
    end

    test "composition shape errors in initial, root or rules are invalid_plan" do
      base = %{
        "fn" => "composition.evaluate",
        "limits" => %{},
        "initial" => %{},
        "root" => [],
        "rules" => []
      }

      for {k, v} <- [
            {"initial", []},
            {"initial", %{}},
            {"root", %{}},
            {"rules", "x"},
            {"rules", [1]}
          ] do
        assert %{"kind" => "fault", "code" => "invalid_plan"} = call(Map.put(base, k, v)),
               inspect({k, v})
      end
    end

    test "rng and division errors" do
      assert call(%{"fn" => "rng.next", "state" => [0, 0, 0, 0]}) == %{
               "error" => "invalid_rng_state"
             }

      assert call(%{"fn" => "rng.next", "state" => [1, 2, 3, 4_294_967_296]}) == %{
               "error" => "invalid_rng_state"
             }

      assert call(%{
               "fn" => "rng.uniform",
               "state" => [0, 0, 0, 0],
               "bound" => 0,
               "max_draws" => -1
             }) == %{"error" => "invalid_bound"}

      assert call(%{
               "fn" => "rng.uniform",
               "state" => [0, 0, 0, 0],
               "bound" => 2,
               "max_draws" => -1
             }) == %{"error" => "invalid_rng_budget"}

      assert call(%{
               "fn" => "rng.uniform",
               "state" => [1, 2, 3, 4],
               "bound" => 2,
               "max_draws" => 0
             }) == %{"error" => "rng_budget_exhausted"}

      assert call(%{
               "fn" => "rng.uniform",
               "state" => [1, 2, 3, 4],
               "bound" => 4_294_967_296,
               "max_draws" => 1
             }) == %{"value" => 11520, "state" => [7, 0, 1026, 12288]}

      assert call(%{"fn" => "int.divide", "a" => 1, "b" => 0}) == %{"error" => "divide_by_zero"}

      assert call(%{"fn" => "int.divide", "a" => true, "b" => 1}) == %{
               "error" => "integer_out_of_range"
             }

      assert call(%{"fn" => "int.divide", "a" => 1, "b" => false}) == %{
               "error" => "integer_out_of_range"
             }
    end
  end

  describe "codec" do
    test "rejects what the profile rejects" do
      for text <- [
            ~s({"a":1,"\\u0061":2}),
            ~s({"é":1}),
            ~s({"\\u00e9":1}),
            ~s("\\udc00"),
            ~s("\\ud800x"),
            ~s("\\ud800\\u0041"),
            "\"\x01\"",
            "01",
            "-",
            "1.",
            "1.0",
            "-0.0",
            "1E2",
            "9007199254740992",
            "-9007199254740992",
            "NaN",
            "-Infinity",
            "[1,]",
            "{\"a\":1,}",
            "tru",
            "'a'",
            "\"\\x\"",
            "\"\\u12\""
          ] do
        assert Codec.decode(text) == :error, text
      end
    end

    test "accepts and canonicalizes" do
      for {text, canonical} <- [
            {"-0", "0"},
            {" [ 9007199254740991 , -9007199254740991 ]\r\n",
             "[9007199254740991,-9007199254740991]"},
            {~s("\\ud83d\\ude00\\/"), "\"😀/\""},
            {~s({"b":[],"a":{"d":null,"c":true}}), ~s({"a":{"c":true,"d":null},"b":[]})},
            {~s("\\b\\t\\n\\f\\r\\u0001\\u001f\\u007f\\"\\\\\\u2028"),
             "\"\\b\\t\\n\\f\\r\\u0001\\u001f\x7f\\\"\\\\\u2028\""}
          ] do
        assert {:ok, value} = Codec.decode(text)
        assert Codec.encode(value) == canonical
      end
    end
  end

  describe "mix r1.runner" do
    @tag timeout: 120_000
    test "answers each line before stdin closes, with nothing else on stdout" do
      mix = System.find_executable("mix")

      port =
        Port.open({:spawn_executable, mix}, [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          args: ["r1.runner"],
          cd: File.cwd!()
        ])

      Port.command(port, ~s({"fn":"rng.next","state":[1,2,3,4]}\n))
      assert receive_line(port, "") == ~s({"raw":11520,"state":[7,0,1026,12288]}\n)
      Port.command(port, "\n")
      assert receive_line(port, "") == ~s({"error":"invalid_protocol"}\n)
      Port.close(port)
    end
  end

  defp receive_line(port, acc) do
    receive do
      {^port, {:data, data}} ->
        acc = acc <> data
        if String.ends_with?(acc, "\n"), do: acc, else: receive_line(port, acc)
    after
      60_000 -> flunk("no response line; got #{inspect(acc)}")
    end
  end
end
