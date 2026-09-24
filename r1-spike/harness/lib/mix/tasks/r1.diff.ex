defmodule Mix.Tasks.R1.Diff do
  @shortdoc "Differential test of the Elixir and TypeScript R1 runners"
  @moduledoc """
      mix r1.diff [--sequences N] [--seed S] [--regression-file PATH] [--report PATH]
                  [--replay SEED] [--elixir CMD] [--elixir-dir DIR] [--ts CMD] [--ts-dir DIR]
                  [--timeout MS]

  Runs the regression seeds, then N fresh sequences whose seeds derive from S
  (`LokaR1Harness.Generator.fresh_seeds/2`). `--replay SEED` runs just that one
  sequence seed. Exits non-zero on any mismatch or runner failure.
  """
  use Mix.Task

  alias LokaR1Harness.{Diff, Generator}

  @switches [
    sequences: :integer,
    seed: :integer,
    regression_file: :string,
    report: :string,
    replay: :integer,
    elixir: :string,
    elixir_dir: :string,
    ts: :string,
    ts_dir: :string,
    timeout: :integer
  ]

  @impl true
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: @switches)
    if rest != [] or invalid != [], do: Mix.raise("bad arguments: #{inspect(rest ++ invalid)}")

    base = opts[:seed] || System.system_time(:microsecond)
    n = Keyword.get(opts, :sequences, 10_000)
    reg_file = opts[:regression_file] || "regression-seeds.json"

    {regression, fresh} =
      case opts[:replay] do
        nil -> {regression_seeds(reg_file), Generator.fresh_seeds(base, n)}
        seed -> {[], [seed]}
      end

    runners = [
      {"elixir", opts[:elixir] || "mix r1.runner", opts[:elixir_dir] || "../elixir"},
      {"ts", opts[:ts] || "node src/runner.ts", opts[:ts_dir] || "../ts"}
    ]

    Mix.shell().info(
      "r1.diff generator=#{Generator.version()} base_seed=#{base} " <>
        "regression=#{length(regression)} fresh=#{length(fresh)}"
    )

    meta = %{
      "base_seed" => base,
      "fresh_seed_derivation" => "rand exsss seeded with base_seed; uniform_s(2^48) per sequence",
      "fresh_sequences" => length(fresh),
      "regression_file" => reg_file,
      "regression_seeds" => regression,
      "replay" => opts[:replay],
      "runners" => Map.new(runners, fn {name, cmd, dir} -> {name, "#{cmd} (in #{dir})"} end)
    }

    write = fn result, stats, failure, ms ->
      summary = Diff.summary(result, stats, failure, Map.put(meta, "elapsed_ms", ms))
      if opts[:report], do: File.write!(opts[:report], Diff.encode(summary) <> "\n")
      summary
    end

    started = System.monotonic_time(:millisecond)
    empty = %{requests: 0, fns: %{}, lengths: %{}}

    {result, stats, failure} =
      Diff.run(
        runners: runners,
        timeout: opts[:timeout],
        seeds:
          Enum.map(regression, &{"regression", &1}) ++
            Enum.map(fresh, &{if(opts[:replay], do: "replay", else: "fresh"), &1}),
        on_mismatch: &write.(:mismatch, empty, &1, nil)
      )

    elapsed = System.monotonic_time(:millisecond) - started
    summary = write.(result, stats, failure, elapsed)

    Mix.shell().info(
      "r1.diff result=#{result} sequences=#{Enum.sum(Map.values(stats.lengths))} " <>
        "requests=#{stats.requests} elapsed_ms=#{elapsed} fn_counts=#{inspect(summary["fn_counts"])}"
    )

    if result != :pass do
      Mix.shell().error(Diff.encode(failure))

      if min = failure["minimized"] do
        Mix.shell().error("seed #{failure["seed"]} minimized request:\n" <> min["request"])
      end

      Mix.raise("r1.diff: #{result}")
    end
  end

  defp regression_seeds(path) do
    %{"seeds" => seeds} = JSON.decode!(File.read!(path))
    Enum.all?(seeds, &is_integer/1) || Mix.raise("#{path}: seeds must be integers")
    seeds
  end
end
