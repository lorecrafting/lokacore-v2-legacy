defmodule LokaR1.Py do
  @moduledoc """
  The few Python value semantics the models rely on, over decoded JSON.

  Where the Python model would raise, these raise `LokaR1.Py.Error` with the
  Python exception class: `:key_error`, `:type_error` or `:value_error`.
  """

  defmodule Error do
    defexception [:kind]
    @impl true
    def message(%{kind: kind}), do: "python #{kind}"
  end

  def raise!(kind), do: raise(Error, kind: kind)

  @doc "`container[key]` for a string key."
  def get(map, key) when is_map(map) do
    case map do
      %{^key => v} -> v
      _ -> raise!(:key_error)
    end
  end

  def get(_, _), do: raise!(:type_error)

  @doc "Python `==`: booleans equal the integers 1 and 0."
  def eq(a, b) when is_boolean(a) or is_boolean(b), do: num?(a) and num?(b) and num(a) == num(b)

  def eq(a, b) when is_list(a) and is_list(b),
    do: length(a) == length(b) and Enum.all?(Enum.zip_with(a, b, &eq/2))

  def eq(a, b) when is_map(a) and is_map(b),
    do:
      map_size(a) == map_size(b) and
        Enum.all?(a, fn {k, v} -> Map.has_key?(b, k) and eq(v, b[k]) end)

  def eq(a, b), do: a === b

  def truthy?(v), do: v not in [nil, false, 0, "", [], %{}]

  defp num?(v), do: is_integer(v) or is_boolean(v)

  @doc "A value in a numeric comparison or `+`; anything but int/bool is a TypeError."
  def num(true), do: 1
  def num(false), do: 0
  def num(n) when is_integer(n), do: n
  def num(_), do: raise!(:type_error)

  @doc "`x in {str, ...}` for a set of strings: lists and dicts are unhashable."
  def in_set?(v, _set) when is_list(v) or is_map(v), do: raise!(:type_error)
  def in_set?(v, set), do: is_binary(v) and v in set

  @doc """
  `str(value)` for scalars. Lists and dicts return `nil` (their Python repr is
  not modelled); callers compare against strings, so `nil` never matches.
  """
  def str(nil), do: "None"
  def str(true), do: "True"
  def str(false), do: "False"
  def str(n) when is_integer(n), do: Integer.to_string(n)
  def str(s) when is_binary(s), do: s
  # ponytail: no repr for list/dict; differs from Python only if a view equals that exact repr.
  def str(_), do: nil
end
