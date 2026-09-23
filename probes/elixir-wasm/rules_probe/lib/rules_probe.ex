defmodule RulesProbe do
  @moduledoc """
  A Tiny-sized stand-in for a rules decision: integer-only, deterministic RNG,
  state in, new state out. Not the real kernel; mirrored in assets/rules.js.
  """
  import Bitwise

  @mask 0xFFFFFFFF

  def xorshift(x) do
    x = bxor(x, x <<< 13 &&& @mask)
    x = bxor(x, x >>> 17)
    bxor(x, x <<< 5 &&& @mask)
  end

  def decide(%{"hp" => hp, "x" => x, "y" => y, "rng" => rng, "gold" => gold} = s, action) do
    r = xorshift(rng)

    case action do
      ["move", dx, dy] ->
        %{s | "x" => clamp(x + dx), "y" => clamp(y + dy), "rng" => r}

      ["attack", power] ->
        dmg = div(power * (50 + rem(r, 51)), 100)
        loot = if rem(r, 7) == 0, do: 3, else: 0
        %{s | "hp" => max(hp - div(dmg, 4), 0), "gold" => gold + loot, "rng" => r}
    end
  end

  defp clamp(v), do: v |> max(0) |> min(56)
end

defmodule RulesProbe.Server do
  use GenServer
  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: :rules)
  @impl true
  def init(_), do: {:ok, nil}

  @impl true
  def handle_call(["decide", state, action], _from, s), do: {:reply, RulesProbe.decide(state, action), s}

  # Runs n decisions inside the VM, so kernel cost can be separated from bridge cost.
  def handle_call(["loop", state, n], _from, s) do
    {us, final} =
      :timer.tc(fn ->
        Enum.reduce(1..n, state, fn i, acc ->
          RulesProbe.decide(acc, if(rem(i, 2) == 0, do: ["move", 1, -1], else: ["attack", 12]))
        end)
      end)

    {:reply, [us, final], s}
  end
end

defmodule RulesProbe.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = if Popcorn.Wasm.available?(), do: [RulesProbe.Server, Popcorn.Proxy], else: []
    Supervisor.start_link(children, strategy: :one_for_one, name: RulesProbe.Supervisor)
  end
end
