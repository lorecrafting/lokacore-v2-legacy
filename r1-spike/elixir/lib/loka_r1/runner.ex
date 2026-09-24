defmodule LokaR1.Runner do
  @moduledoc """
  The `r1-spike/README.md` runner protocol: one strict-JSON request line in,
  one canonical response line out (without the trailing newline here).
  """
  alias LokaR1.{Codec, Composition, Numeric, World}

  @profile_limits %{
    "operations" => 4096,
    "query_steps" => 32768,
    "events" => 4096,
    "deliveries" => 8192,
    "reaction_depth" => 32,
    "selector_cardinality" => 1024,
    "created_jobs" => 64,
    "pending_jobs" => 1024,
    "due_jobs_per_advance" => 1024,
    "scene_auto_advances" => 64,
    "output_bytes" => 1_048_576
  }

  @doc "The profile limits `composition.evaluate` starts from (checked against the fixture in tests)."
  def profile_limits, do: @profile_limits

  @spec handle_line(binary()) :: binary()
  def handle_line(line) do
    response =
      case Codec.decode(line) do
        {:ok, request} -> handle(request)
        :error -> :invalid
      end

    Codec.encode(if response == :invalid, do: %{"error" => "invalid_protocol"}, else: response)
  rescue
    # The Python model would raise here (for example a memory value of the wrong type).
    LokaR1.Py.Error -> Codec.encode(%{"error" => "invalid_protocol"})
  end

  defp handle(%{"fn" => "world.run", "world" => world, "commands" => commands} = r)
       when is_list(commands) do
    with true <- Map.keys(r) -- ["fn", "world", "commands", "initial"] == [],
         {decide, default} <- World.world(world),
         initial when is_map(initial) <- Map.get(r, "initial", default) do
      {records, _host} =
        Enum.map_reduce(commands, World.new(initial), &World.step(decide, &2, &1))

      records
    else
      _ -> :invalid
    end
  end

  defp handle(%{"fn" => "composition.evaluate", "limits" => limits} = r)
       when is_map(limits) and is_map_key(r, "initial") and is_map_key(r, "root") and
              is_map_key(r, "rules") do
    if Map.keys(r) -- ~w(fn limits initial root rules advance_target) == [] and
         Enum.all?(limits, fn {k, v} ->
           is_map_key(@profile_limits, k) and is_integer(v) and v > 0
         end) do
      limits = Map.merge(@profile_limits, limits)
      Composition.evaluate(limits, r["initial"], r["root"], r["rules"], r["advance_target"])
    else
      :invalid
    end
  end

  defp handle(%{"fn" => "rng.next", "state" => state} = r) when map_size(r) == 2 do
    case Numeric.rng_next(state) do
      {:ok, raw, state} -> %{"raw" => raw, "state" => state}
      {:error, code} -> %{"error" => code}
    end
  end

  defp handle(%{"fn" => "rng.uniform", "state" => s, "bound" => b, "max_draws" => m} = r)
       when map_size(r) == 4 do
    case Numeric.uniform(s, b, m) do
      {:ok, value, state} -> %{"value" => value, "state" => state}
      {:error, code} -> %{"error" => code}
    end
  end

  defp handle(%{"fn" => "int.divide", "a" => a, "b" => b} = r) when map_size(r) == 3 do
    case Numeric.divide(a, b) do
      {:ok, q, rem} -> %{"q" => q, "r" => rem}
      {:error, code} -> %{"error" => code}
    end
  end

  defp handle(%{"fn" => "json.canonical", "text" => text} = r)
       when map_size(r) == 2 and is_binary(text) do
    case Codec.decode(text) do
      {:ok, value} -> %{"canonical" => Codec.encode(value)}
      :error -> %{"error" => "invalid_json"}
    end
  end

  defp handle(_), do: :invalid
end
