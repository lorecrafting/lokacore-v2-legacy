defmodule LokaR1Server.Runner do
  @moduledoc """
  The README runner protocol with `world.run` served by a durable host: each
  request gets a fresh world instance in the SQLite file `db`, dropped afterwards.
  Every other `fn` is pure and goes to `LokaR1.Runner` unchanged.
  """
  alias LokaR1.{Codec, World}
  alias LokaR1Server.Host

  @spec handle_line(binary(), Path.t(), String.t()) :: binary()
  def handle_line(line, db, id) do
    with {:ok, %{"fn" => "world.run", "world" => world, "commands" => commands} = r}
         when is_list(commands) <- Codec.decode(line),
         true <- Map.keys(r) -- ["fn", "world", "commands", "initial"] == [],
         {_decide, default} <- World.world(world),
         initial when is_map(initial) <- Map.get(r, "initial", default) do
      Codec.encode(run(db, id, world, initial, commands))
    else
      _ -> LokaR1.Runner.handle_line(line)
    end
  end

  defp run(db, id, world, initial, commands) do
    {:ok, pid} = Host.start(db: db, id: id, world: world, initial: initial)

    try do
      Enum.reduce_while(commands, [], fn command, records ->
        case Host.step(pid, command) do
          {:ok, record} -> {:cont, [record | records]}
          :py_error -> {:halt, :py_error}
        end
      end)
    after
      Host.stop(pid, drop: true)
    end
    |> case do
      :py_error -> %{"error" => "invalid_protocol"}
      records -> Enum.reverse(records)
    end
  end
end
