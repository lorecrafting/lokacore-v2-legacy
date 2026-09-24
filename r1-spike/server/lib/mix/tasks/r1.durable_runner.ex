defmodule Mix.Tasks.R1.DurableRunner do
  @shortdoc "Runs the R1 NDJSON runner on stdin/stdout with world.run on the durable host"
  @moduledoc """
      mix r1.durable_runner [--db PATH]

  The runner protocol of `r1-spike/README.md`, with `world.run` served by
  `LokaR1Server.Host` over SQLite. The database file defaults to a fresh file in
  the system temp directory, removed on exit.
  """
  use Mix.Task

  @impl true
  def run(argv) do
    {opts, [], []} = OptionParser.parse(argv, strict: [db: :string])
    Mix.Task.run("app.start")

    db =
      opts[:db] ||
        Path.join(System.tmp_dir!(), "r1-durable-#{System.unique_integer([:positive])}.sqlite")

    :ok = :io.setopts(:standard_io, binary: true, encoding: :latin1)

    try do
      loop(db, 0)
    after
      unless opts[:db], do: Enum.each(["", "-wal", "-shm"], &File.rm(db <> &1))
    end
  end

  defp loop(db, n) do
    case IO.binread(:stdio, :line) do
      :eof ->
        :ok

      {:error, reason} ->
        Mix.raise("stdin: #{inspect(reason)}")

      line ->
        line = String.trim_trailing(line, "\n")
        IO.binwrite(:stdio, [LokaR1Server.Runner.handle_line(line, db, "run-#{n}"), ?\n])
        loop(db, n + 1)
    end
  end
end
