defmodule LokaR1.Codec do
  @moduledoc """
  Strict parser and canonical encoder for the fixture profile
  (`conformance/numeric-profile.md`).

  JSON values map to `nil`, booleans, integers, binaries, lists and maps with
  binary keys. The parser rejects duplicate keys, fractions, exponents,
  NaN/Infinity, integers beyond ±(2^53−1), lone surrogates, non-ASCII keys,
  invalid UTF-8 and trailing data. `-0` parses as `0`.
  """

  @safe 9_007_199_254_740_991

  @spec decode(binary()) :: {:ok, term()} | :error
  def decode(text) when is_binary(text) do
    if String.valid?(text) do
      {value, rest} = value(ws(text))
      if ws(rest) == "", do: {:ok, value}, else: :error
    else
      :error
    end
  catch
    :invalid -> :error
  end

  @spec encode(term()) :: binary()
  def encode(value), do: IO.iodata_to_binary(enc(value))

  # ---- parser -------------------------------------------------------------

  defp ws(<<c, rest::binary>>) when c in [?\s, ?\t, ?\n, ?\r], do: ws(rest)
  defp ws(rest), do: rest

  defp value(<<"{", rest::binary>>), do: object(ws(rest), %{})
  defp value(<<"[", rest::binary>>), do: array(ws(rest), [])
  defp value(<<"\"", rest::binary>>), do: string(rest, [])
  defp value(<<"true", rest::binary>>), do: {true, rest}
  defp value(<<"false", rest::binary>>), do: {false, rest}
  defp value(<<"null", rest::binary>>), do: {nil, rest}
  defp value(<<"-", rest::binary>>), do: number(rest, -1)
  defp value(<<c, _::binary>> = rest) when c in ?0..?9, do: number(rest, 1)
  defp value(_), do: throw(:invalid)

  defp object(<<"}", rest::binary>>, acc) when acc == %{}, do: {acc, rest}

  defp object(<<"\"", rest::binary>>, acc) do
    {key, rest} = string(rest, [])
    if Map.has_key?(acc, key) or not ascii?(key), do: throw(:invalid)

    case ws(rest) do
      <<":", rest::binary>> ->
        {v, rest} = value(ws(rest))
        acc = Map.put(acc, key, v)

        case ws(rest) do
          <<",", rest::binary>> -> object(ws(rest), acc)
          <<"}", rest::binary>> -> {acc, rest}
          _ -> throw(:invalid)
        end

      _ ->
        throw(:invalid)
    end
  end

  defp object(_, _), do: throw(:invalid)

  defp array(<<"]", rest::binary>>, []), do: {[], rest}

  defp array(text, acc) do
    {v, rest} = value(text)

    case ws(rest) do
      <<",", rest::binary>> -> array(ws(rest), [v | acc])
      <<"]", rest::binary>> -> {Enum.reverse([v | acc]), rest}
      _ -> throw(:invalid)
    end
  end

  defp ascii?(key), do: for(<<c <- key>>, reduce: true, do: (ok -> ok and c < 0x80))

  defp string(<<"\"", rest::binary>>, acc), do: {IO.iodata_to_binary(Enum.reverse(acc)), rest}

  defp string(<<"\\u", a, b, c, d, rest::binary>>, acc) do
    case hex(<<a, b, c, d>>) do
      hi when hi in 0xD800..0xDBFF ->
        case rest do
          <<"\\u", e, f, g, h, rest::binary>> ->
            case hex(<<e, f, g, h>>) do
              lo when lo in 0xDC00..0xDFFF ->
                cp = 0x10000 + Bitwise.bsl(hi - 0xD800, 10) + (lo - 0xDC00)
                string(rest, [<<cp::utf8>> | acc])

              _ ->
                throw(:invalid)
            end

          _ ->
            throw(:invalid)
        end

      cp when cp in 0xDC00..0xDFFF ->
        throw(:invalid)

      cp ->
        string(rest, [<<cp::utf8>> | acc])
    end
  end

  defp string(<<"\\", c, rest::binary>>, acc) do
    ch =
      case c do
        ?" -> "\""
        ?\\ -> "\\"
        ?/ -> "/"
        ?b -> "\b"
        ?f -> "\f"
        ?n -> "\n"
        ?r -> "\r"
        ?t -> "\t"
        _ -> throw(:invalid)
      end

    string(rest, [ch | acc])
  end

  defp string(<<c, _::binary>>, _) when c < 0x20, do: throw(:invalid)
  defp string(<<c, rest::binary>>, acc), do: string(rest, [c | acc])
  defp string(<<>>, _), do: throw(:invalid)

  defp hex(digits) do
    if String.match?(digits, ~r/\A[0-9a-fA-F]{4}\z/),
      do: String.to_integer(digits, 16),
      else: throw(:invalid)
  end

  defp number(text, sign) do
    {digits, rest} =
      case text do
        <<"0", rest::binary>> -> {"0", rest}
        <<c, _::binary>> when c in ?1..?9 -> digits(text, [])
        _ -> throw(:invalid)
      end

    case rest do
      <<c, _::binary>> when c in [?., ?e, ?E] -> throw(:invalid)
      _ -> :ok
    end

    n = sign * String.to_integer(digits)
    if abs(n) > @safe, do: throw(:invalid)
    {n, rest}
  end

  defp digits(<<c, rest::binary>>, acc) when c in ?0..?9, do: digits(rest, [c | acc])
  defp digits(rest, acc), do: {acc |> Enum.reverse() |> List.to_string(), rest}

  # ---- canonical encoder --------------------------------------------------

  defp enc(nil), do: "null"
  defp enc(true), do: "true"
  defp enc(false), do: "false"
  defp enc(n) when is_integer(n), do: Integer.to_string(n)
  defp enc(s) when is_binary(s), do: [?", esc(s, []), ?"]
  defp enc(l) when is_list(l), do: [?[, Enum.map_intersperse(l, ?,, &enc/1), ?]]

  defp enc(m) when is_map(m) do
    pairs = m |> Enum.sort() |> Enum.map_intersperse(?,, fn {k, v} -> [enc(k), ?:, enc(v)] end)
    [?{, pairs, ?}]
  end

  defp esc(<<>>, acc), do: Enum.reverse(acc)
  defp esc(<<?", r::binary>>, acc), do: esc(r, ["\\\"" | acc])
  defp esc(<<?\\, r::binary>>, acc), do: esc(r, ["\\\\" | acc])
  defp esc(<<?\b, r::binary>>, acc), do: esc(r, ["\\b" | acc])
  defp esc(<<?\t, r::binary>>, acc), do: esc(r, ["\\t" | acc])
  defp esc(<<?\n, r::binary>>, acc), do: esc(r, ["\\n" | acc])
  defp esc(<<?\f, r::binary>>, acc), do: esc(r, ["\\f" | acc])
  defp esc(<<?\r, r::binary>>, acc), do: esc(r, ["\\r" | acc])

  defp esc(<<c, r::binary>>, acc) when c < 0x20,
    do: esc(r, ["\\u00" <> String.downcase(Base.encode16(<<c>>)) | acc])

  defp esc(<<c, r::binary>>, acc), do: esc(r, [c | acc])
end
