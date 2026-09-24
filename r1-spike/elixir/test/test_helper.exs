defmodule Fixtures do
  @moduledoc "Reads the frozen conformance inputs in place, after checking their SHA-256."
  alias LokaR1.{Codec, Runner}

  @root Path.expand("../../../docs/rewrite-v3", __DIR__)

  def root, do: @root

  def load!(rel) do
    bytes = File.read!(Path.join(@root, rel))

    {:ok, preserved} =
      Codec.decode(File.read!(Path.join(@root, "spec_tools/preserved-inputs.json")))

    expected = Map.fetch!(preserved, rel)
    actual = Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)
    if actual != expected, do: raise("#{rel}: sha256 #{actual}, preserved #{expected}")
    {:ok, data} = Codec.decode(bytes)
    data
  end

  @doc "One request through the runner's line protocol, decoded."
  def call(request) do
    {:ok, response} = Codec.decode(Runner.handle_line(Codec.encode(request)))
    response
  end

  @doc "A fixture step (cases.json / adverse shape) as a runner command."
  def command(%{"op" => "recover"}), do: %{"op" => "recover"}
  def command(%{"op" => "settle", "committed" => c}), do: %{"op" => "settle", "committed" => c}

  def command(%{"request" => request} = step) do
    Map.merge(%{"op" => "invoke", "request" => request}, Map.take(step, ["options"]))
  end

  @doc """
  Differences between step records and fixture steps: result, memory, durable
  (defaulting to the memory), published where given, and the README's own
  events/delta definitions against the previous record.
  """
  def mismatches(records, steps, _before) when length(records) != length(steps),
    do: [{:length, records, length(steps)}]

  def mismatches(records, steps, before) do
    records
    |> Enum.zip(steps)
    |> Enum.with_index()
    |> Enum.flat_map_reduce(before, fn {{record, step}, i}, prev ->
      host = record["state"]
      events = Enum.drop(host["published"], length(prev["published"]))

      delta =
        for {k, v} <- host["memory"],
            Map.fetch(prev["memory"], k) != {:ok, v},
            into: %{},
            do: {k, v}

      checks = [
        result: {record["result"], step["result"]},
        error: {record["error"], nil},
        memory: {host["memory"], step["state"]},
        durable: {host["durable"], Map.get(step, "durable", step["state"])},
        published: {host["published"], Map.get(step, "published", host["published"])},
        events: {record["events"], events},
        delta: {record["delta"], delta}
      ]

      bad = for {field, {got, want}} <- checks, got != want, do: {i, field, got, want}
      {bad, host}
    end)
    |> elem(0)
  end
end

ExUnit.start()
