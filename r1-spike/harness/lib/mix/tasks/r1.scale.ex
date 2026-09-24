defmodule Mix.Tasks.R1.Scale do
  @shortdoc "Write the quick R1-A3 scale inputs (one line per model: tiny, medium, stress)"
  @moduledoc """
      mix r1.scale --out PATH [--seed N]

  See `LokaR1Harness.Scale`. Default seed 20260924.
  """
  use Mix.Task

  alias LokaR1Harness.{Canonical, Scale}

  @impl true
  def run(argv) do
    {opts, [], []} = OptionParser.parse(argv, strict: [out: :string, seed: :integer])
    out = opts[:out] || Mix.raise("--out PATH is required")
    seed = opts[:seed] || 20_260_924
    inputs = Enum.map(Scale.models(), &Scale.input(&1, seed))
    File.write!(out, Enum.map(inputs, &[Canonical.encode(&1), ?\n]))

    for i <- inputs do
      bytes = byte_size(Canonical.encode(i["initial"]))
      Mix.shell().info("#{i["model"]}: initial_state_canonical_bytes=#{bytes}")
    end

    Mix.shell().info("r1.scale version=#{Scale.version()} seed=#{seed} out=#{out}")
  end
end
