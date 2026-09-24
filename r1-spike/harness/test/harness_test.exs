defmodule LokaR1HarnessTest do
  use ExUnit.Case, async: true
  import Bitwise

  alias LokaR1Harness.{Canonical, Diff, Generator}

  @max_safe 9_007_199_254_740_991
  @fake Path.expand("support/fake_runner.py", __DIR__)

  defp lines(seed), do: Enum.map(Generator.sequence(seed), &Generator.line/1)
  defp seeds(n), do: Generator.fresh_seeds(99, n)

  test "the same seed gives the same lines; different seeds differ" do
    for seed <- [0, 1, 12_345, (1 <<< 48) - 1] do
      assert lines(seed) == lines(seed)
    end

    assert Generator.fresh_seeds(5, 50) == Generator.fresh_seeds(5, 50)
    assert length(Enum.uniq(Enum.map(seeds(200), &lines/1))) == 200
  end

  test "world.run has 1..64 commands and both bounds occur" do
    lengths =
      for seed <- seeds(2000) do
        [{:json, %{"fn" => "world.run", "commands" => cmds}}, _extra] = Generator.sequence(seed)
        length(cmds)
      end

    assert Enum.min(lengths) == 1
    assert Enum.max(lengths) == 64
  end

  test "structured lines are canonical, single-line and keep integers safe" do
    for seed <- seeds(1000), {:json, _} = req <- Generator.sequence(seed) do
      line = Generator.line(req)
      refute line =~ "\n"
      decoded = JSON.decode!(line)
      assert Canonical.encode(decoded) == line
      assert safe?(decoded), line
    end
  end

  defp safe?(n) when is_integer(n), do: abs(n) <= @max_safe
  defp safe?(l) when is_list(l), do: Enum.all?(l, &safe?/1)
  defp safe?(m) when is_map(m), do: Enum.all?(Map.values(m), &safe?/1)
  defp safe?(_), do: true

  test "canonical encoding escapes controls and keeps other text literal" do
    assert Canonical.encode(%{"b" => 1, "a" => ["\b\t\n\f\r\u0001\u001f\u007f", "é😀\"\\"]}) ==
             ~s({"a":["\\b\\t\\n\\f\\r\\u0001\\u001f\u007f","é😀\\"\\\\"],"b":1})
  end

  defp runner(name, args \\ ""), do: {name, "python3 #{@fake} #{args}", "."}

  test "identical runners agree" do
    assert {:pass, stats, nil} =
             Diff.run(
               runners: [runner("a"), runner("b")],
               seeds: Enum.map(seeds(200), &{"t", &1})
             )

    assert stats.requests == 400
  end

  test "responses are compared as raw bytes, so a \\r\\n ending is a mismatch" do
    assert {:mismatch, _, failure} =
             Diff.run(runners: [runner("a"), runner("b", "--crlf")], seeds: [{"t", 1}])

    assert failure["responses"]["b"] == failure["responses"]["a"] <> "\r"
  end

  test "settled edge cases are about 5% of lines and include raw bytes" do
    reqs = Enum.flat_map(seeds(4000), &Generator.sequence/1)
    raw = for {:raw, line} <- reqs, do: line
    assert Enum.any?(raw, &(not String.valid?(&1)))
    assert Enum.any?(raw, &String.ends_with?(&1, "\r"))
    assert "" in raw
    empty = for {:json, %{"fn" => "world.run", "commands" => []}} <- reqs, do: 1
    assert empty != []
  end

  test "a runner that corrupts step 3 is caught and minimized to 4 commands" do
    seeds = Enum.map(seeds(200), &{"t", &1})

    assert {:mismatch, _stats, failure} =
             Diff.run(runners: [runner("a"), runner("b", "--corrupt-step 3")], seeds: seeds)

    assert %{"fn" => "world.run", "commands" => cmds} = JSON.decode!(failure["request"])
    assert length(cmds) > 3
    assert "corrupt:" <> _ = failure["responses"]["b"]

    min = JSON.decode!(failure["minimized"]["request"])
    assert length(min["commands"]) == 4
    assert Enum.all?(min["commands"], &(&1 in cmds))
    assert failure["minimized"]["responses"]["a"] == failure["minimized"]["request"]
  end

  test "mix r1.diff writes the summary and fails on a mismatch" do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    dir = Path.join(System.tmp_dir!(), "r1-diff-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    reg = Path.join(dir, "reg.json")
    File.write!(reg, ~s({"seeds":[1,2]}))
    report = Path.join(dir, "report.json")
    cmd = "python3 #{@fake}"
    base = ~w(--seed 7 --regression-file #{reg} --report #{report} --elixir-dir . --ts-dir .)

    Mix.Tasks.R1.Diff.run(base ++ ["--sequences", "30", "--elixir", cmd, "--ts", cmd])
    summary = JSON.decode!(File.read!(report))
    assert summary["result"] == "pass"
    assert summary["generator_version"] == Generator.version()
    assert summary["regression_seeds"] == [1, 2]
    assert summary["fresh_sequences"] == 30
    assert Enum.sum(Map.values(summary["length_histogram"])) == 32
    assert summary["fn_counts"]["world.run"] >= 32

    assert_raise Mix.Error, fn ->
      Mix.Tasks.R1.Diff.run(
        base ++ ["--sequences", "30", "--elixir", cmd, "--ts", cmd <> " --corrupt-step 0"]
      )
    end

    summary = JSON.decode!(File.read!(report))
    assert summary["result"] == "mismatch"
    assert length(JSON.decode!(summary["failure"]["minimized"]["request"])["commands"]) == 1
  end
end
