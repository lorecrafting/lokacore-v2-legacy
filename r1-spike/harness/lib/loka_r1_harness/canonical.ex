defmodule LokaR1Harness.Canonical do
  @moduledoc """
  Canonical JSON per conformance/numeric-profile.md: keys in ordinal order, no
  whitespace, literal UTF-8, short escapes for \\b \\t \\n \\f \\r and lower-case
  \\u00xx for the other controls. Maps must have string keys.
  """

  def encode(nil), do: "null"
  def encode(true), do: "true"
  def encode(false), do: "false"
  def encode(n) when is_integer(n), do: Integer.to_string(n)
  def encode(s) when is_binary(s), do: [?", escape(s, ""), ?"] |> IO.iodata_to_binary()

  def encode(list) when is_list(list),
    do: "[" <> Enum.map_join(list, ",", &encode/1) <> "]"

  def encode(map) when is_map(map) do
    body =
      map
      |> Enum.sort_by(fn {k, _} when is_binary(k) -> k end)
      |> Enum.map_join(",", fn {k, v} -> encode(k) <> ":" <> encode(v) end)

    "{" <> body <> "}"
  end

  defp escape(<<>>, acc), do: acc
  defp escape(<<?", rest::binary>>, acc), do: escape(rest, acc <> "\\\"")
  defp escape(<<?\\, rest::binary>>, acc), do: escape(rest, acc <> "\\\\")
  defp escape(<<?\b, rest::binary>>, acc), do: escape(rest, acc <> "\\b")
  defp escape(<<?\t, rest::binary>>, acc), do: escape(rest, acc <> "\\t")
  defp escape(<<?\n, rest::binary>>, acc), do: escape(rest, acc <> "\\n")
  defp escape(<<?\f, rest::binary>>, acc), do: escape(rest, acc <> "\\f")
  defp escape(<<?\r, rest::binary>>, acc), do: escape(rest, acc <> "\\r")

  defp escape(<<c, rest::binary>>, acc) when c < 0x20,
    do: escape(rest, acc <> "\\u00" <> String.downcase(Base.encode16(<<c>>)))

  defp escape(<<c::utf8, rest::binary>>, acc), do: escape(rest, acc <> <<c::utf8>>)
end
