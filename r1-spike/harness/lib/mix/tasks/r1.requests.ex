defmodule Mix.Tasks.R1.Requests do
  @shortdoc "Write the on-device differential input: regression sequences plus fixture rows"
  @moduledoc """
      mix r1.requests --out PATH [--regression-file PATH]

  Writes one runner request per line: each regression seed's sequence
  (`Generator.sequence/1`, byte for byte what `r1.diff` sends), then one request
  per row of the frozen fixtures, read in place after checking their SHA-256
  against `spec_tools/preserved-inputs.json`. The phone runs these lines on
  Hermes and the M1 compares its response lines with the Elixir runner's.
  """
  use Mix.Task

  alias LokaR1Harness.{Canonical, Generator}

  @v3 "../../docs/rewrite-v3"

  @impl true
  def run(argv) do
    {opts, [], []} = OptionParser.parse(argv, strict: [out: :string, regression_file: :string])
    out = opts[:out] || Mix.raise("--out PATH is required")

    %{"seeds" => seeds} =
      JSON.decode!(File.read!(opts[:regression_file] || "regression-seeds.json"))

    lines =
      Enum.flat_map(seeds, fn s -> Enum.map(Generator.sequence(s), &Generator.line/1) end) ++
        Enum.map(fixture_requests(), &Canonical.encode/1)

    File.write!(out, Enum.map(lines, &[&1, ?\n]))

    Mix.shell().info(
      "r1.requests generator=#{Generator.version()} seeds=#{length(seeds)} lines=#{length(lines)} out=#{out}"
    )
  end

  defp fixture(name) do
    path = "conformance/" <> name
    bytes = File.read!(Path.join(@v3, path))
    want = JSON.decode!(File.read!(Path.join(@v3, "spec_tools/preserved-inputs.json")))[path]
    got = Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)
    got == want || Mix.raise("#{path}: sha256 #{got} != preserved #{want}")
    JSON.decode!(bytes)
  end

  defp fixture_requests do
    v = fixture("numeric-vectors.json")
    adverse = fixture("adverse-cases.json")
    traces = fixture("lantern-traces.json")["traces"]

    rng =
      Enum.map_reduce(v["rng_steps"], v["initial_rng"], fn row, state ->
        {%{"fn" => "rng.next", "state" => state}, row["state"]}
      end)
      |> elem(0)

    rng ++
      Enum.map(v["division"], &%{"fn" => "int.divide", "a" => &1["a"], "b" => &1["b"]}) ++
      Enum.map(v["invalid_json"], &%{"fn" => "json.canonical", "text" => &1}) ++
      Enum.map(v["canonical"], &%{"fn" => "json.canonical", "text" => &1["input"]}) ++
      Enum.map(
        adverse["uniform"],
        &(Map.take(&1, ["state", "bound", "max_draws"]) |> Map.put("fn", "rng.uniform"))
      ) ++
      Enum.map(fixture("cases.json")["cases"], &world("tiny-" <> &1["credit"], &1["steps"])) ++
      Enum.map(adverse["tiny"], &world("tiny-" <> &1["credit"], &1["steps"], &1["initial_state"])) ++
      Enum.map(traces, &world("lantern", &1["steps"])) ++
      Enum.map(adverse["lantern"], fn c ->
        %{"trace" => t, "from" => from, "to" => to} = c["prefix"]
        prefix = Enum.find(traces, &(&1["id"] == t))["steps"] |> Enum.slice(from..(to - 1)//1)
        world("lantern", Enum.map(prefix, &Map.take(&1, ["request"])) ++ c["steps"])
      end) ++
      Enum.map(
        fixture("composition-cases.json")["cases"] ++ adverse["composition"],
        &composition/1
      )
  end

  defp world(name, steps, initial \\ nil) do
    req = %{"fn" => "world.run", "world" => name, "commands" => Enum.map(steps, &command/1)}
    if initial, do: Map.put(req, "initial", initial), else: req
  end

  # A fixture step ({request, options?} or {op, ...}) as a runner command.
  defp command(%{"op" => "recover"}), do: %{"op" => "recover"}
  defp command(%{"op" => "settle", "committed" => c}), do: %{"op" => "settle", "committed" => c}

  defp command(step),
    do: Map.merge(%{"op" => "invoke", "request" => step["request"]}, Map.take(step, ["options"]))

  defp composition(c) do
    req = %{
      "fn" => "composition.evaluate",
      "limits" => c["limits"] || %{},
      "initial" => c["initial"],
      "root" => c["root"],
      "rules" => c["rules"]
    }

    if Map.has_key?(c, "advance_target"),
      do: Map.put(req, "advance_target", c["advance_target"]),
      else: req
  end
end
