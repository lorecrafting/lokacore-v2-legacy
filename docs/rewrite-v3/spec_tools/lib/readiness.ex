defmodule LokaSpec.Readiness do
  @moduledoc "Retained preparation validation, not authenticated approval or an R1 result."
  alias LokaSpec.Codec
  @type manifest :: %{String.t() => Codec.value()}
  @type result :: :ok | {:error, String.t()}
  @root Path.expand("../..", __DIR__)
  @max_bytes 8 * 1024 * 1024
  @inputs ~w(r1-acceptance-envelope.md conformance/numeric-profile.md conformance/numeric-vectors.json conformance/cases.json conformance/composition-profile.json conformance/composition-cases.json conformance/lantern-traces.json)
  @tools ~w(expo react_native hermes typescript node elixir otp sqlite sqlite_binding xcode ios_sdk android_sdk gradle jdk)
  @a1_tools ~w(typescript node elixir otp)
  @device ~w(qualification_class model sku soc installed_ram_gb os_version os_build architecture availability_record)
  @normative ~w(01-core-principles.md 02-beam-runtime-architecture.md 03-domain-state-persistence.md 04-command-event-effect-protocol.md 05-cartridges-content-capabilities.md 06-quests-dialogue-actions-scripting.md 07-offline-storypacks-to-mmo.md 08-builder-api-ai-factory.md 09-cartridge-lab-certification.md 10-mobile-commerce-release.md 11-security-observability-operations.md 14-implementation-plan.md 15-acceptance-scenarios.md 16-decision-register.md 19-quest-sharing-instancing-capacity.md 21-composable-world-primitives.md 23-accounts-progress-admission.md)

  @spec root() :: String.t()
  def root, do: @root
  @spec inputs() :: [String.t()]
  def inputs, do: @inputs
  @spec normative() :: [String.t()]
  def normative, do: @normative

  @spec template() :: manifest()
  def template do
    %{
      "schema_version" => 1,
      "status" => "preparation_pending",
      "candidate" => "A",
      "accepted_spec_commit" => nil,
      "candidate_author_ids" => [],
      "devices" => Map.new(~w(ios android), &{&1, Map.new(@device, fn k -> {k, nil} end)}),
      "server" => Map.new(~w(model os_build cores ram_gb), &{&1, nil}),
      "toolchain" => Map.new(@tools, &{&1, nil}),
      "toolchain_lock" => empty_reference(),
      "inputs" => Enum.map(@inputs, &%{"path" => &1, "sha256" => nil}),
      "r0_acceptance" => empty_reference(),
      "oracle_review" => empty_reference(),
      "setup_review" => empty_reference()
    }
  end

  @spec check_template(Codec.value()) :: result()
  def check_template(data) do
    controlled(fn ->
      ensure!(
        Codec.encode(data) == Codec.encode(template()),
        "template drift or fabricated preparation entries"
      )
    end)
  end

  @spec setup_digest(manifest(), String.t()) :: String.t()
  def setup_digest(data, stage \\ "A2") do
    ensure!(stage in ~w(A1 A2), "unsupported readiness stage")
    prefix = if stage == "A1", do: "loka-r1-a1-setup-v1\0", else: ""
    raw = data |> Map.drop(~w(status setup_review)) |> Codec.encode()
    Codec.sha256(prefix <> raw)
  end

  @spec validate(Codec.value(), String.t(), String.t()) :: result()
  def validate(data, root, stage \\ "A2") do
    controlled(fn -> validate!(data, root, stage) end)
  end

  @spec read_json(String.t()) :: Codec.value()
  def read_json(path), do: bounded_read!(path) |> Codec.decode()

  @spec retained(manifest(), String.t()) :: binary()
  def retained(entry, root) do
    ensure!(
      keys?(entry, ~w(path sha256)) and nonempty?(entry["path"]) and digest?(entry["sha256"]),
      "missing retained path/hash"
    )

    relative = entry["path"]

    ensure!(
      Path.type(relative) == :relative and ".." not in Path.split(relative),
      "unsafe evidence path"
    )

    real_root = real_path(root)
    path = real_path(Path.join(real_root, relative))

    ensure!(
      String.starts_with?(path, String.trim_trailing(real_root, "/") <> "/"),
      "escaping evidence file"
    )

    ensure!(File.regular?(path), "missing evidence file")
    raw = bounded_read!(path)
    ensure!(Codec.sha256(raw) == entry["sha256"], "retained hash mismatch: " <> relative)
    raw
  end

  defp validate!(data, root, stage) do
    ensure!(stage in ~w(A1 A2), "unsupported readiness stage")
    ensure!(keys?(data, Map.keys(template())), "unknown/missing manifest fields")
    ensure!(data["schema_version"] === 1, "unknown manifest version")

    ensure!(
      data["status"] == "setup_reviewed" and data["candidate"] == "A",
      "preparation pending or unsupported candidate work package"
    )

    ensure!(digest?(data["accepted_spec_commit"], 40), "missing accepted specification commit")
    authors = data["candidate_author_ids"]
    ensure!(identities?(authors), "candidate authors must be identified for review separation")

    ensure!(
      keys?(data["devices"], ~w(ios android)),
      "both physical qualification records required"
    )

    Enum.each(~w(ios android), fn platform ->
      if stage == "A2" do
        device!(data["devices"][platform], platform)
      else
        deferred_device!(data["devices"][platform], platform)
      end
    end)

    server = data["server"]
    ensure!(keys?(server, ~w(model os_build cores ram_gb)), "incomplete server record")

    ensure!(
      nonempty?(server["model"]) and nonempty?(server["os_build"]) and positive?(server["cores"]) and
        positive?(server["ram_gb"]) and (stage == "A1" or server["ram_gb"] >= 16),
      "missing server details or RAM floor"
    )

    ensure!(keys?(data["toolchain"], @tools), "incomplete toolchain")

    Enum.each(@tools, fn name ->
      value = data["toolchain"][name]

      ensure!(
        (stage == "A1" and name not in @a1_tools and is_nil(value)) or
          (is_binary(value) and
             (Regex.match?(~r/\A\d+(?:\.\d+){0,3}(?:\+[a-zA-Z0-9.-]+)?\z/, value) or
                digest?(value, 40))),
        "toolchain must use exact stable version/build: " <> name
      )
    end)

    lock = retained(data["toolchain_lock"], root)
    ensure!(String.trim(lock) != "", "empty toolchain/lock manifest")
    inputs = data["inputs"]

    ensure!(
      is_list(inputs) and length(inputs) == length(@inputs) and Enum.all?(inputs, &is_map/1) and
        Enum.map(inputs, & &1["path"]) == @inputs,
      "fixture/envelope set changed"
    )

    Enum.each(inputs, &retained(&1, root))
    r0 = retained(data["r0_acceptance"], root) |> Codec.decode()

    ensure!(
      is_map(r0) and r0["accepted_spec_commit"] == data["accepted_spec_commit"] and
        r0["disposition"] == "accepted" and nonempty?(r0["reviewer_id"]) and
        identities?(r0["normative_files"]) and
        Enum.all?(@normative, &(&1 in r0["normative_files"])) and
        nonempty?(r0["amendment_authority"]) and nonempty?(r0["cutover_destination"]),
      "missing R0 acceptance/cutover record"
    )

    Enum.each(~w(oracle_review setup_review), fn name ->
      review = retained(data[name], root) |> Codec.decode()

      ensure!(
        is_map(review) and review["accepted_spec_commit"] == data["accepted_spec_commit"] and
          review["disposition"] == "approved" and nonempty?(review["reviewer_id"]) and
          review["reviewer_id"] not in authors and
          review["independent_of_candidate_authorship"] === true,
        "missing independent " <> name
      )

      ensure!(
        identities?(review["subject_author_ids"]) and
          review["reviewer_id"] not in review["subject_author_ids"] and
          review["independent_of_subject_authorship"] === true,
        "missing subject-author separation: " <> name
      )

      if name == "oracle_review" do
        ensure!(
          Codec.encode(review["inputs"]) == Codec.encode(inputs),
          "oracle review does not bind exact inputs"
        )
      else
        ensure!(
          review["setup_digest"] == setup_digest(data, stage),
          "setup review does not bind exact configuration"
        )
      end
    end)

    :ok
  end

  defp deferred_device!(device, platform) do
    ensure!(keys?(device, @device), "incomplete device inventory")

    Enum.each(device, fn {field, value} ->
      valid = if field == "installed_ram_gb", do: positive?(value), else: nonempty?(value)

      ensure!(
        is_nil(value) or valid,
        "malformed deferred device detail: " <> platform <> "/" <> field
      )
    end)
  end

  defp device!(device, platform) do
    ensure!(keys?(device, @device), "incomplete device inventory")

    Enum.each(@device -- ["installed_ram_gb"], fn field ->
      ensure!(nonempty?(device[field]), "missing device detail: " <> platform <> "/" <> field)
    end)

    {ram, class, minimum} =
      if platform == "ios",
        do: {4, "iphone-11", [16, 4, 0]},
        else: {4, "galaxy-a14-4gb", [10, 0, 0]}

    ensure!(
      device["installed_ram_gb"] === ram,
      "qualification RAM class changed without amendment"
    )

    ensure!(
      device["qualification_class"] == class and device["architecture"] == "arm64",
      "qualification class/architecture changed without amendment"
    )

    ensure!(
      Regex.match?(~r/\A\d+(?:\.\d+)*\z/, device["os_version"]),
      "device OS must be exact numeric version"
    )

    version = String.split(device["os_version"], ".") |> Enum.map(&String.to_integer/1)

    ensure!(
      version ++ List.duplicate(0, max(0, 3 - length(version))) >= minimum,
      "device OS below planning policy"
    )
  end

  # Resolve links before the containment check, including linked parent directories.
  # The bundle is locally retained review input, not an active adversarial filesystem.
  defp real_path(path, budget \\ 40) do
    ensure!(budget > 0, "evidence symlink cycle")
    [anchor | parts] = path |> Path.expand() |> Path.split()

    Enum.reduce(parts, anchor, fn part, parent ->
      current = Path.join(parent, part)

      case File.read_link(current) do
        {:ok, target} ->
          real_path(Path.expand(target, Path.dirname(current)), budget - 1)

        {:error, :einval} ->
          current

        {:error, reason} ->
          raise File.Error, reason: reason, action: "resolve evidence", path: current
      end
    end)
  end

  defp bounded_read!(path) do
    ensure!(File.stat!(path).size <= @max_bytes, "evidence file exceeds preparation bound")

    File.open!(path, [:read, :binary], fn device ->
      raw = IO.binread(device, @max_bytes + 1)
      raw = if raw == :eof, do: "", else: raw

      ensure!(
        is_binary(raw) and byte_size(raw) <= @max_bytes,
        "evidence file exceeds preparation bound"
      )

      raw
    end)
  end

  defp controlled(fun) do
    fun.()
    :ok
  rescue
    error in [ArgumentError, File.Error, KeyError, BadMapError] ->
      {:error, Exception.message(error)}
  end

  defp empty_reference, do: %{"path" => nil, "sha256" => nil}
  defp ensure!(true, _), do: :ok
  defp ensure!(_, message), do: raise(ArgumentError, message)
  defp keys?(map, keys), do: is_map(map) and Enum.sort(Map.keys(map)) == Enum.sort(keys)
  defp positive?(n), do: is_integer(n) and n > 0

  defp identities?(xs),
    do:
      is_list(xs) and xs != [] and Enum.all?(xs, &nonempty?/1) and
        length(Enum.uniq(xs)) == length(xs)

  defp nonempty?(s),
    do:
      is_binary(s) and String.trim(s) != "" and
        String.downcase(String.trim(s)) not in ~w(todo tbd unknown none null placeholder)

  defp digest?(s, length \\ 64),
    do:
      is_binary(s) and Regex.match?(Regex.compile!("\\A[0-9a-f]{#{length}}\\z"), s) and
        s != String.duplicate("0", length)
end

defmodule Mix.Tasks.Loka.Readiness do
  use Mix.Task
  alias LokaSpec.Readiness
  @shortdoc "Check preparation artifacts without claiming R0/R1 approval"

  @spec run([String.t()]) :: :ok
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          check_template: :boolean,
          require_ready: :string,
          evidence_root: :string,
          stage: :string
        ]
      )

    modes = Keyword.take(opts, [:check_template, :require_ready])

    if rest != [] or invalid != [] or length(modes) != 1 or
         not (opts[:check_template] === true or is_binary(opts[:require_ready])),
       do: Mix.raise("choose --check-template or --require-ready PATH")

    stage = opts[:stage] || "A2"
    if stage not in ~w(A1 A2), do: Mix.raise("NOT READY: unsupported readiness stage")

    {result, message} =
      if opts[:check_template] == true do
        data =
          Readiness.read_json(
            Path.join(Readiness.root(), "conformance/r1-run-manifest.template.json")
          )

        {Readiness.check_template(data),
         "incomplete template preserved; NOT ready for candidate implementation"}
      else
        data = Readiness.read_json(opts[:require_ready])

        {Readiness.validate(data, opts[:evidence_root] || Readiness.root(), stage),
         "R1-#{stage} preparation records complete; NOT R1 acceptance or authenticated evidence"}
      end

    case result do
      :ok ->
        Mix.shell().info("PASS: " <> message)

        if stage == "A1" and is_binary(opts[:require_ready]),
          do:
            Mix.shell().info(
              "A1 ONLY: no native/physical qualification, A2 authorization or runtime selection"
            )

      {:error, reason} ->
        Mix.raise("NOT READY: " <> reason)
    end
  rescue
    error in [ArgumentError, File.Error] -> Mix.raise("NOT READY: " <> Exception.message(error))
  end
end
