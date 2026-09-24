defmodule LokaR1Server.Child do
  @moduledoc """
  Entry point of the separate OS process used for `kill` faults, started as
  `elixir -pa ... -e "LokaR1Server.Child.main()"` with `R1_CHILD_SPEC` naming a
  JSON spec file.

  - `"phase": "run"` creates the instance and runs `commands` with the `fault`
    schedule; a `kill` point halts this VM (exit status 137) mid-command.
  - `"phase": "recover"` is a fresh VM: it rebuilds the host from the database
    file alone, then prints `{"recovered": HOST, "next": step record}` for the
    `next` command.
  """
  alias LokaR1.Codec
  alias LokaR1Server.Host

  @spec main() :: :ok
  def main do
    {:ok, _} = Application.ensure_all_started(:loka_r1_server)
    {:ok, spec} = Codec.decode(File.read!(System.fetch_env!("R1_CHILD_SPEC")))
    opts = [db: spec["db"], id: spec["id"], world: spec["world"], diag: spec["diag"]]

    case spec["phase"] do
      "run" ->
        {:ok, pid} = Host.start([initial: spec["initial"], fault: spec["fault"]] ++ opts)
        Enum.each(spec["commands"], &Host.step(pid, &1))

      "recover" ->
        {:ok, pid} = Host.start(opts)
        recovered = Host.host(pid)
        {:ok, next} = Host.step(pid, spec["next"])
        IO.write(Codec.encode(%{"recovered" => recovered, "next" => next}))
    end
  end
end
