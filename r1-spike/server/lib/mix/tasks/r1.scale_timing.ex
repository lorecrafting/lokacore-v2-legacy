defmodule Mix.Tasks.R1.ScaleTiming do
  @shortdoc "Quick R1-A3: time the durable server step at Tiny/Medium/Stress"
  @moduledoc """
      mix r1.scale_timing --in SCALE_JSONL --out DIR

  One model per input line (from `mix r1.scale` in `harness/`). Writes
  `a3-samples.csv` (measured steps) and `a3-run.json` to DIR. See
  `LokaR1Server.Scale`.
  """
  use Mix.Task

  alias LokaR1Server.Scale

  @impl true
  def run(argv) do
    {opts, [], []} = OptionParser.parse(argv, strict: [in: :string, out: :string])
    out = opts[:out] || Mix.raise("--out DIR is required")
    File.mkdir_p!(out)
    Mix.Task.run("app.start")
    start = System.monotonic_time(:millisecond)

    {rows, models} =
      (opts[:in] || Mix.raise("--in PATH is required"))
      |> File.stream!()
      |> Enum.map(fn line ->
        {:ok, input} = LokaR1.Codec.decode(String.trim_trailing(line, "\n"))
        db = Path.join(out, "a3-#{input["model"]}.db")
        Enum.each([db, db <> "-wal", db <> "-shm"], &File.rm/1)
        {rows, facts} = Scale.run_model(db, input, "m1-server")
        Enum.each([db, db <> "-wal", db <> "-shm"], &File.rm/1)
        Mix.shell().info("LOKA_A3_MODEL " <> LokaR1.Codec.encode(facts))
        {rows, facts}
      end)
      |> Enum.unzip()

    File.write!(
      Path.join(out, "a3-samples.csv"),
      Enum.map([Scale.header() | Enum.concat(rows)], &[&1, ?\n])
    )

    run = %{
      "host" => "m1-server",
      "wall_ms" => System.monotonic_time(:millisecond) - start,
      "models" => models,
      "runtime" => %{
        "otp_release" => to_string(:erlang.system_info(:otp_release)),
        "erts" => to_string(:erlang.system_info(:version)),
        "elixir" => System.version(),
        "schedulers" => :erlang.system_info(:schedulers_online),
        "sqlite" => LokaR1Server.Store.identity() |> Map.take(~w(sqlite_version sqlite_source_id))
      }
    }

    File.write!(Path.join(out, "a3-run.json"), [LokaR1.Codec.encode(run), ?\n])
  end
end
