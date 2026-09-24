defmodule LokaR1.Numeric do
  @moduledoc """
  xoshiro128** 1.1 (Blackman/Vigna, public domain; adapted per
  `conformance/numeric-profile.md`), bounded uniform draws and signed
  truncating division. Errors are `{:error, code}` with the model's codes.
  """
  import Bitwise

  @u32 0xFFFFFFFF
  @safe 9_007_199_254_740_991

  @spec rng_next(term()) :: {:ok, non_neg_integer(), [non_neg_integer()]} | {:error, binary()}
  def rng_next(words) do
    if valid_state?(words), do: next(words), else: {:error, "invalid_rng_state"}
  end

  defp next([a, b, c, d]) do
    result = rotl(b * 5 &&& @u32, 7) * 9 &&& @u32
    t = b <<< 9 &&& @u32
    c = bxor(c, a)
    d = bxor(d, b)
    b = bxor(b, c)
    a = bxor(a, d)
    c = bxor(c, t)
    d = rotl(d, 11)
    {:ok, result, [a, b, c, d]}
  end

  defp rotl(v, n), do: (v <<< n ||| v >>> (32 - n)) &&& @u32

  defp valid_state?(words) do
    is_list(words) and length(words) == 4 and
      Enum.all?(words, &(is_integer(&1) and &1 in 0..@u32)) and Enum.any?(words, &(&1 != 0))
  end

  @doc "Uniform integer in [0, bound); errors checked in the model's order."
  @spec uniform(term(), term(), term()) :: {:ok, non_neg_integer(), list()} | {:error, binary()}
  def uniform(words, bound, max_draws) do
    cond do
      not (is_integer(bound) and bound in 1..(1 <<< 32)) -> {:error, "invalid_bound"}
      not (is_integer(max_draws) and max_draws >= 0) -> {:error, "invalid_rng_budget"}
      not valid_state?(words) -> {:error, "invalid_rng_state"}
      true -> draw(words, bound, (1 <<< 32) - rem(1 <<< 32, bound), max_draws)
    end
  end

  defp draw(_words, _bound, _limit, 0), do: {:error, "rng_budget_exhausted"}

  defp draw(words, bound, limit, left) do
    {:ok, raw, words} = next(words)
    if raw < limit, do: {:ok, rem(raw, bound), words}, else: draw(words, bound, limit, left - 1)
  end

  @spec divide(term(), term()) :: {:ok, integer(), integer()} | {:error, binary()}
  def divide(a, b) do
    cond do
      not (is_integer(a) and is_integer(b) and abs(a) <= @safe and abs(b) <= @safe) ->
        {:error, "integer_out_of_range"}

      b == 0 ->
        {:error, "divide_by_zero"}

      true ->
        # Elixir's div/rem already truncate toward zero.
        {:ok, div(a, b), rem(a, b)}
    end
  end
end
