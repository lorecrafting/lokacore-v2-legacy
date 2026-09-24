defmodule Mix.Tasks.R1.Faults do
  @shortdoc "Runs the real-fault matrix against the durable host and writes JSONL evidence"
  @moduledoc """
      mix r1.faults [--seeds N] [--out PATH]

  For each world, seeds 1..N (default 3) and every `{point, kind}` of
  `LokaR1Server.Faults.matrix/0`, runs one injected fault and writes one evidence
  record per line to PATH (default `faults.jsonl`). Exits non-zero if any record
  fails.
  """
  use Mix.Task

  alias LokaR1Server.Faults

  @impl true
  def run(argv) do
    {opts, [], []} = OptionParser.parse(argv, strict: [seeds: :integer, out: :string])
    Mix.Task.run("app.start")
    dir = Path.join(System.tmp_dir!(), "r1-faults-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    records =
      for world <- ~w(tiny-event tiny-state lantern),
          seed <- 1..Keyword.get(opts, :seeds, 3),
          pk <- Faults.matrix(),
          do: Faults.run(world, seed, pk, dir)

    File.rm_rf!(dir)
    File.write!(opts[:out] || "faults.jsonl", Enum.map(records, &[LokaR1.Codec.encode(&1), ?\n]))

    for {{p, k}, rs} <- Enum.group_by(records, &{&1["fault"]["point"], &1["fault"]["kind"]}) do
      pass = Enum.count(rs, &(&1["verdict"] == "pass"))
      Mix.shell().info("#{p} #{k}: pass=#{pass} fail=#{length(rs) - pass}")
    end

    failed = Enum.reject(records, &(&1["verdict"] == "pass"))
    Mix.shell().info("r1.faults records=#{length(records)} failed=#{length(failed)}")

    if failed != [] do
      Enum.each(
        failed,
        &Mix.shell().error(LokaR1.Codec.encode(Map.take(&1, ~w(world seed fault checks))))
      )

      Mix.raise("r1.faults: #{length(failed)} failing records")
    end
  end
end
