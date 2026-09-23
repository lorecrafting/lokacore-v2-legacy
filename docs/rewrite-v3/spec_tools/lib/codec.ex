defmodule LokaSpec.Codec do
  @moduledoc "Specification fixture codec, not a production cartridge decoder."
  @type value :: nil | boolean() | integer() | String.t() | [value()] | %{String.t() => value()}
  @safe 9_007_199_254_740_991

  @spec encode(value()) :: binary()
  def encode(value), do: value |> encode_value() |> IO.iodata_to_binary()

  @spec decode(binary()) :: value()
  def decode(raw) when is_binary(raw) do
    callbacks = %{
      null: nil,
      float: fn _ -> raise ArgumentError, "unsupported_number" end,
      object_start: fn _ -> %{} end,
      object_push: fn key, value, acc ->
        if Map.has_key?(acc, key), do: raise(ArgumentError, "duplicate_key")
        Map.put(acc, key, value)
      end,
      object_finish: fn acc, old -> {acc, old} end
    }

    {value, _, rest} = :json.decode(raw, nil, callbacks)
    unless Regex.match?(~r/\A[ \t\r\n]*\z/, rest), do: raise(ArgumentError, "trailing_json")
    encode(value)
    value
  rescue
    error in ArgumentError -> reraise error, __STACKTRACE__
    _error in ErlangError -> raise ArgumentError, "invalid_json"
  end

  def decode(_), do: raise(ArgumentError, "invalid_json_input")

  @spec sha256(binary()) :: String.t()
  def sha256(raw), do: :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)

  defp encode_value(nil), do: "null"
  defp encode_value(true), do: "true"
  defp encode_value(false), do: "false"
  defp encode_value(n) when is_integer(n) and abs(n) <= @safe, do: Integer.to_string(n)
  defp encode_value(n) when is_integer(n), do: raise(ArgumentError, "integer_out_of_range")

  defp encode_value(s) when is_binary(s) do
    unless String.valid?(s), do: raise(ArgumentError, "invalid_unicode")
    ["\"", for(<<c::utf8 <- s>>, do: escape(c)), "\""]
  end

  defp encode_value(list) when is_list(list) do
    ["[", Enum.intersperse(Enum.map(list, &encode_value/1), ","), "]"]
  end

  defp encode_value(map) when is_map(map) and not is_struct(map) do
    keys = Map.keys(map)

    unless Enum.all?(keys, fn key ->
             is_binary(key) and Enum.all?(:binary.bin_to_list(key), &(&1 < 128))
           end),
           do: raise(ArgumentError, "non_ascii_key")

    members =
      Enum.map(Enum.sort(keys), fn key -> [encode_value(key), ":", encode_value(map[key])] end)

    ["{", Enum.intersperse(members, ","), "}"]
  end

  defp encode_value(_), do: raise(ArgumentError, "unsupported_canonical_value")
  defp escape(34), do: "\\\""
  defp escape(92), do: "\\\\"
  defp escape(8), do: "\\b"
  defp escape(9), do: "\\t"
  defp escape(10), do: "\\n"
  defp escape(12), do: "\\f"
  defp escape(13), do: "\\r"

  defp escape(c) when c < 32,
    do: "\\u" <> String.pad_leading(Integer.to_string(c, 16) |> String.downcase(), 4, "0")

  defp escape(c), do: <<c::utf8>>
end

defmodule LokaSpec.Numeric do
  @moduledoc "Fixed-profile numeric specification helpers; no gameplay runtime."
  import Bitwise
  @safe 9_007_199_254_740_991
  @u32 0xFFFFFFFF
  @type rng :: [non_neg_integer()]

  @spec divide(integer(), integer()) :: {integer(), integer()}
  def divide(a, b) do
    unless is_integer(a) and is_integer(b) and abs(a) <= @safe and abs(b) <= @safe,
      do: raise(ArgumentError, "integer_out_of_range")

    if b == 0, do: raise(ArgumentError, "divide_by_zero")
    {div(a, b), rem(a, b)}
  end

  @spec next(rng()) :: {non_neg_integer(), rng()}
  def next(words) do
    valid_state!(words)
    [a, b, c, d] = words
    # xoshiro128** 1.1, Blackman/Vigna; attribution and profile in numeric-profile.md.
    result = band(rotl(band(b * 5, @u32), 7) * 9, @u32)
    t = band(b <<< 9, @u32)
    c = bxor(c, a)
    d = bxor(d, b)
    {result, [bxor(a, d), bxor(b, c), bxor(c, t), rotl(d, 11)]}
  end

  @spec uniform(rng(), pos_integer(), non_neg_integer(), (rng() -> {non_neg_integer(), rng()})) ::
          {non_neg_integer(), rng()}
  def uniform(words, bound, budget \\ 1024, source \\ &next/1) do
    unless is_integer(bound) and bound >= 1 and bound <= @u32 + 1,
      do: raise(ArgumentError, "invalid_bound")

    unless is_integer(budget) and budget >= 0, do: raise(ArgumentError, "invalid_rng_budget")
    valid_state!(words)
    draw(words, bound, @u32 + 1 - rem(@u32 + 1, bound), budget, source)
  end

  defp draw(_, _, _, 0, _), do: raise(ArgumentError, "rng_budget_exhausted")

  defp draw(words, bound, limit, budget, source) do
    {raw, next_words} = source.(words)

    if raw < limit,
      do: {rem(raw, bound), next_words},
      else: draw(next_words, bound, limit, budget - 1, source)
  end

  defp valid_state!(words) do
    unless is_list(words) and length(words) == 4 and
             Enum.all?(words, &(is_integer(&1) and &1 >= 0 and &1 <= @u32)) and
             Enum.any?(words, &(&1 != 0)),
           do: raise(ArgumentError, "invalid_rng_state")
  end

  defp rotl(v, n), do: band(bor(v <<< n, v >>> (32 - n)), @u32)
end
