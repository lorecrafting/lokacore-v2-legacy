defmodule Mix.Tasks.R1.SqliteIdentity do
  @shortdoc "Prints the server SQLite engine identity as canonical JSON"
  @moduledoc "`sqlite_version()`, `sqlite_source_id()`, `PRAGMA compile_options` and the exqlite version."
  use Mix.Task

  @impl true
  def run(_argv) do
    Mix.Task.run("app.start")
    exqlite = to_string(Application.spec(:exqlite, :vsn))
    identity = Map.put(LokaR1Server.Store.identity(), "exqlite_version", exqlite)
    IO.puts(LokaR1.Codec.encode(identity))
  end
end
