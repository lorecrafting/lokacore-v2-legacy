defmodule LokaR1.FixturesTest do
  @moduledoc "Every row of the six frozen fixture files, driven through the runner protocol."
  use ExUnit.Case, async: true
  import Fixtures
  alias LokaR1.{Codec, Lantern, Runner, Tiny, World}

  @numeric load!("conformance/numeric-vectors.json")
  @cases load!("conformance/cases.json")
  @profile load!("conformance/composition-profile.json")
  @composition load!("conformance/composition-cases.json")
  @lantern load!("conformance/lantern-traces.json")
  @adverse load!("conformance/adverse-cases.json")

  defp run_world(world, commands, initial \\ nil) do
    request = %{"fn" => "world.run", "world" => world, "commands" => commands}
    call(if initial, do: Map.put(request, "initial", initial), else: request)
  end

  defp tiny_world(credit), do: "tiny-" <> credit

  describe "numeric-vectors.json" do
    test "rng output and next state, chained from the initial state" do
      Enum.reduce(@numeric["rng_steps"], @numeric["initial_rng"], fn row, state ->
        assert call(%{"fn" => "rng.next", "state" => state}) == %{
                 "raw" => row["raw"],
                 "state" => row["state"]
               }

        row["state"]
      end)
    end

    test "signed division" do
      for row <- @numeric["division"] do
        assert call(%{"fn" => "int.divide", "a" => row["a"], "b" => row["b"]}) == %{
                 "q" => row["q"],
                 "r" => row["r"]
               }
      end
    end

    test "invalid_json rows are rejected" do
      assert length(@numeric["invalid_json"]) == 7

      for text <- @numeric["invalid_json"] do
        assert call(%{"fn" => "json.canonical", "text" => text}) == %{"error" => "invalid_json"},
               text
      end
    end

    test "canonical rows" do
      for row <- @numeric["canonical"] do
        assert call(%{"fn" => "json.canonical", "text" => row["input"]}) == %{
                 "canonical" => row["expected"]
               }
      end
    end
  end

  describe "cases.json" do
    test "every case, every step (memory and durable equal the state)" do
      assert @cases["fixture_version"] == 1

      for case <- @cases["cases"] do
        records = run_world(tiny_world(case["credit"]), Enum.map(case["steps"], &command/1))
        assert mismatches(records, case["steps"], World.new(Tiny.initial())) == [], case["id"]
      end
    end
  end

  describe "lantern-traces.json" do
    test "initial state is the Lantern world's" do
      assert @lantern["initial_state"] == Lantern.initial()
    end

    test "both choice traces, every step" do
      for trace <- @lantern["traces"] do
        records = run_world("lantern", Enum.map(trace["steps"], &command/1))

        assert mismatches(records, trace["steps"], World.new(Lantern.initial())) == [],
               trace["id"]
      end
    end
  end

  describe "composition-profile.json and composition-cases.json" do
    test "the runner's default limits are the profile's" do
      assert Runner.profile_limits() == @profile["limits"]
    end

    test "every case" do
      for case <- @composition["cases"] do
        assert evaluate(case) == case["expected"], case["id"]
      end
    end

    test "file order of the registry is not semantic" do
      case = Enum.find(@composition["cases"], &(&1["id"] == "canonical-registry-order"))
      assert evaluate(%{case | "rules" => Enum.reverse(case["rules"])}) == case["expected"]
    end
  end

  defp evaluate(case) do
    request =
      %{"fn" => "composition.evaluate", "limits" => Map.get(case, "limits", %{})}
      |> Map.merge(Map.take(case, ~w(initial root rules advance_target)))

    call(request)
  end

  describe "adverse-cases.json" do
    test "uniform rows" do
      assert length(@adverse["uniform"]) == 11

      for row <- @adverse["uniform"] do
        response =
          call(Map.merge(%{"fn" => "rng.uniform"}, Map.take(row, ~w(state bound max_draws))))

        expected =
          if row["error"],
            do: %{"error" => row["error"]},
            else: %{"value" => row["value"], "state" => row["next_state"]}

        assert response == expected, inspect(row)
      end
    end

    test "tiny cases, with initial states, durable and published" do
      for case <- @adverse["tiny"] do
        initial = Map.get(case, "initial_state", Tiny.initial())

        records =
          run_world(tiny_world(case["credit"]), Enum.map(case["steps"], &command/1), initial)

        assert mismatches(records, case["steps"], World.new(initial)) == [], case["id"]
      end
    end

    test "lantern cases after their trace prefixes" do
      traces = Map.new(@lantern["traces"], &{&1["id"], &1})

      for case <- @adverse["lantern"] do
        %{"trace" => trace, "from" => from, "to" => to} = case["prefix"]

        prefix =
          traces[trace]["steps"]
          |> Enum.slice(from, to - from)
          |> Enum.map(&%{"op" => "invoke", "request" => &1["request"]})

        records = run_world("lantern", prefix ++ Enum.map(case["steps"], &command/1))
        {prefix_records, records} = Enum.split(records, length(prefix))

        before =
          if prefix_records == [],
            do: World.new(Lantern.initial()),
            else: List.last(prefix_records)["state"]

        assert mismatches(records, case["steps"], before) == [], case["id"]
      end
    end

    test "composition cases" do
      for case <- @adverse["composition"] do
        assert evaluate(case) == case["expected"], case["id"]
      end
    end
  end

  describe "mutation sensitivity" do
    test "restoring the RNG after a failed check fails the adverse fixture" do
      case = Enum.find(@adverse["tiny"], &(&1["id"] == "failed-check-commits-next-rng"))

      mutant = fn memory, request ->
        case Tiny.decide("event", memory, request) do
          {s, "check_failed", events, ok} ->
            {%{s | "rng" => memory["rng"]}, "check_failed", events, ok}

          other ->
            other
        end
      end

      honest = &Tiny.decide("event", &1, &2)

      for {decide, expect_clean} <- [{honest, true}, {mutant, false}] do
        host = World.new(case["initial_state"])
        {records, _} = Enum.map_reduce(case["steps"], host, &World.step(decide, &2, command(&1)))
        {:ok, records} = Codec.decode(Codec.encode(records))
        assert mismatches(records, case["steps"], host) == [] == expect_clean
      end
    end
  end
end
