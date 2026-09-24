defmodule Mix.Tasks.R1.Runner do
  @shortdoc "Runs the R1 NDJSON runner on stdin/stdout"
  @moduledoc "Reads one request per line on stdin, writes one canonical response line per request."
  use Mix.Task

  @impl true
  def run(_args) do
    :ok = :io.setopts(:standard_io, binary: true, encoding: :latin1)
    loop()
  end

  defp loop do
    case IO.binread(:stdio, :line) do
      :eof ->
        :ok

      {:error, reason} ->
        Mix.raise("stdin: #{inspect(reason)}")

      line ->
        IO.binwrite(:stdio, [LokaR1.Runner.handle_line(String.trim_trailing(line, "\n")), ?\n])
        loop()
    end
  end
end
