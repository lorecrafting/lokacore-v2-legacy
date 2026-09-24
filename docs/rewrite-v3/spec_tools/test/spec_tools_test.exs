defmodule LokaSpec.NumericTest do
  use ExUnit.Case, async: true
  alias LokaSpec.{Codec, Numeric, Readiness}

  defp vectors,
    do: Readiness.read_json(Path.join(Readiness.root(), "conformance/numeric-vectors.json"))

  test "frozen RNG outputs AND every next state" do
    data = vectors()

    Enum.reduce(data["rng_steps"], data["initial_rng"], fn row, state ->
      assert {row["raw"], row["state"]} === Numeric.next(state)
      row["state"]
    end)
  end

  test "frozen signed division, remainder and numeric bounds" do
    for row <- vectors()["division"],
        do: assert({row["q"], row["r"]} === Numeric.divide(row["a"], row["b"]))

    for {a, b} <- [{1, 0}, {true, 1}, {9_007_199_254_740_992, 1}, {1, false}, {1.0, 1}] do
      assert_raise ArgumentError, fn -> Numeric.divide(a, b) end
    end

    for a <- -50..50, b <- -10..10, b != 0 do
      {q, r} = Numeric.divide(a, b)
      assert a == q * b + r
      assert abs(r) < abs(b)
      assert r == 0 or r < 0 == a < 0
    end
  end

  test "frozen strict JSON and canonical vectors" do
    for raw <- vectors()["invalid_json"],
        do: assert_raise(ArgumentError, fn -> Codec.decode(raw) end)

    for row <- vectors()["canonical"],
        do: assert(Codec.encode(Codec.decode(row["input"])) == row["expected"])

    assert Codec.encode(%{"s" => <<8, 9, 10, 12, 13, 1, 34, 92>>}) ==
             ~S({"s":"\b\t\n\f\r\u0001\"\\"})
  end

  test "typed equality, ASCII key order, scalar Unicode and no normalization" do
    refute Codec.encode(%{"v" => true}) == Codec.encode(%{"v" => 1})

    assert Codec.encode(%{"z" => 1, "A" => 2, "a" => [false, nil]}) ==
             ~S({"A":2,"a":[false,null],"z":1})

    assert Codec.decode(~S("\ud83d\ude00")) == "😀"
    refute Codec.encode("é") == Codec.encode("é")

    for value <- [%{"幻" => 1}, %{key: 1}, 1.0, 9_007_199_254_740_992, <<255>>, {:not, :json}] do
      assert_raise ArgumentError, fn -> Codec.encode(value) end
    end
  end

  test "malformed JSON fails with controlled diagnostics, including nested duplicate keys" do
    for raw <- [
          "",
          "[] []",
          "1x",
          "01",
          "1e0",
          "null\v",
          <<255>>,
          ~S({"x":{"a":1,"a":1}}),
          ~S("\udc00"),
          ~S({"é":1}),
          "[",
          nil
        ] do
      assert_raise ArgumentError, fn -> Codec.decode(raw) end
    end
  end

  test "RNG state, bound and budget diagnostics include zero budget" do
    for words <- [
          nil,
          1,
          true,
          "1234",
          %{},
          [0, 0, 0, 0],
          [1, 2, 3],
          [-1, 2, 3, 4],
          [true, 2, 3, 4],
          [4_294_967_296, 2, 3, 4]
        ] do
      assert_raise ArgumentError, "invalid_rng_state", fn -> Numeric.next(words) end
      assert_raise ArgumentError, "invalid_rng_state", fn -> Numeric.uniform(words, 10, 0) end
    end

    for bound <- [0, -1, true, 4_294_967_297],
        do:
          assert_raise(ArgumentError, "invalid_bound", fn ->
            Numeric.uniform([1, 2, 3, 4], bound)
          end)

    for budget <- [nil, true, -1, "1"],
        do:
          assert_raise(ArgumentError, "invalid_rng_budget", fn ->
            Numeric.uniform([1, 2, 3, 4], 10, budget)
          end)

    assert_raise ArgumentError, "rng_budget_exhausted", fn ->
      Numeric.uniform([1, 2, 3, 4], 10, 0)
    end

    assert {0, [7, 0, 1026, 12_288]} == Numeric.uniform([1, 2, 3, 4], 1)
    assert {11_520, [7, 0, 1026, 12_288]} == Numeric.uniform([1, 2, 3, 4], 4_294_967_296)
  end

  test "controlled rejected draw advances state, consumes budget, and cannot be modulo-clamped" do
    source = fn
      [1, 2, 3, 4] -> {4_294_967_295, [1, 1, 1, 1]}
      [1, 1, 1, 1] -> {5, [2, 2, 2, 2]}
    end

    assert {5, [2, 2, 2, 2]} == Numeric.uniform([1, 2, 3, 4], 10, 2, source)

    assert_raise ArgumentError, "rng_budget_exhausted", fn ->
      Numeric.uniform([1, 2, 3, 4], 10, 1, source)
    end
  end

  test "frozen input bytes are preserved independently of replacement outputs" do
    hashes = Readiness.read_json(Path.join(Readiness.root(), "spec_tools/preserved-inputs.json"))

    for {path, expected} <- hashes,
        do: assert(Codec.sha256(File.read!(Path.join(Readiness.root(), path))) == expected)
  end

  test "tooling is isolated and exact stable runtime pins are actually in use" do
    assert Mix.Project.config()[:deps] == []
    assert System.version() == "1.20.4"
    assert :erlang.system_info(:otp_release) == ~c"28"

    otp =
      Path.join([to_string(:code.root_dir()), "releases", "28", "OTP_VERSION"])
      |> File.read!()
      |> String.trim()

    assert otp == "28.4"
  end
end

defmodule LokaSpec.ReadinessTest do
  use ExUnit.Case, async: false
  alias LokaSpec.{Codec, Readiness}

  setup do
    root =
      Path.join(System.tmp_dir!(), "loka-spec-synthetic-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root}
  end

  # All these records are SYNTHETIC TEST DATA, never experiment evidence.
  defp retain(root, path, raw) do
    dest = Path.join(root, path)
    File.mkdir_p!(Path.dirname(dest))
    File.write!(dest, raw)
    %{"path" => path, "sha256" => Codec.sha256(raw)}
  end

  defp synthetic(root) do
    data =
      Readiness.template()
      |> Map.merge(%{
        "status" => "setup_reviewed",
        "accepted_spec_commit" => "0123456789abcdef0123456789abcdef01234567",
        "candidate_author_ids" => ["synthetic-author"]
      })

    devices =
      Map.new(data["devices"], fn {platform, fields} ->
        device = Map.new(fields, fn {key, _} -> {key, "synthetic-test-only"} end)

        override =
          if platform == "ios",
            do: %{
              "qualification_class" => "iphone-11",
              "installed_ram_gb" => 4,
              "os_version" => "16.4"
            },
            else: %{
              "qualification_class" => "galaxy-a14-4gb",
              "installed_ram_gb" => 4,
              "os_version" => "10"
            }

        {platform, Map.merge(device, Map.put(override, "architecture", "arm64"))}
      end)

    data =
      Map.merge(data, %{
        "devices" => devices,
        "server" => %{
          "model" => "synthetic M1 fixture",
          "os_build" => "synthetic",
          "cores" => 8,
          "ram_gb" => 16
        },
        "toolchain" => Map.new(data["toolchain"], fn {key, _} -> {key, "1.2.3"} end),
        "toolchain_lock" =>
          retain(root, "test-only-lock.txt", "synthetic lock, not dependencies"),
        "inputs" =>
          Enum.map(
            Readiness.inputs(),
            &retain(root, &1, File.read!(Path.join(Readiness.root(), &1)))
          )
      })

    r0 = %{
      "accepted_spec_commit" => data["accepted_spec_commit"],
      "disposition" => "accepted",
      "reviewer_id" => "synthetic-owner",
      "normative_files" => Readiness.normative(),
      "amendment_authority" => "synthetic-only",
      "cutover_destination" => "synthetic-only"
    }

    data = Map.put(data, "r0_acceptance", retain(root, "r0.json", Codec.encode(r0)))

    review = %{
      "accepted_spec_commit" => data["accepted_spec_commit"],
      "disposition" => "approved",
      "reviewer_id" => "synthetic-reviewer",
      "independent_of_candidate_authorship" => true,
      "subject_author_ids" => ["synthetic-subject-author"],
      "independent_of_subject_authorship" => true
    }

    data =
      Map.put(
        data,
        "oracle_review",
        retain(root, "oracle.json", Codec.encode(Map.put(review, "inputs", data["inputs"])))
      )

    Map.put(
      data,
      "setup_review",
      retain(
        root,
        "setup.json",
        Codec.encode(Map.put(review, "setup_digest", Readiness.setup_digest(data)))
      )
    )
  end

  defp edit_receipt(data, root, name, change) do
    row = data[name]
    record = Readiness.read_json(Path.join(root, row["path"])) |> change.()
    Map.put(data, name, retain(root, row["path"], Codec.encode(record)))
  end

  defp staged(root, stage, deferred \\ true) do
    data = synthetic(root)

    data =
      if deferred do
        data
        |> Map.put("devices", Readiness.template()["devices"])
        |> Map.put(
          "toolchain",
          Map.new(data["toolchain"], fn {key, value} ->
            {key, if(key in ~w(typescript node elixir otp), do: value, else: nil)}
          end)
        )
        |> put_in(["server", "ram_gb"], 8)
      else
        data
      end

    edit_receipt(data, root, "setup_review", fn review ->
      Map.put(review, "setup_digest", Readiness.setup_digest(data, stage))
    end)
  end

  test "A1 defers native inventory but A2 remains the strict default", %{root: root} do
    data = staged(root, "A1")
    assert :ok == Readiness.validate(data, root, "A1")
    assert {:error, _} = Readiness.validate(data, root)
    assert {:error, _} = Readiness.validate(data, root, "A2")
    assert {:error, _} = Readiness.validate(data, root, "A3")
  end

  test "stage-bound setup approval cannot be relabeled even with complete inventory", %{
    root: root
  } do
    for {reviewed, requested} <- [{"A1", "A2"}, {"A2", "A1"}] do
      data = staged(root, reviewed, false)
      assert :ok == Readiness.validate(data, root, reviewed)
      assert {:error, reason} = Readiness.validate(data, root, requested)
      assert reason =~ "exact configuration"
    end
  end

  test "A1 keeps runtime, retained evidence and author separation requirements", %{root: root} do
    for tool <- ~w(typescript node elixir otp) do
      data = staged(root, "A1") |> put_in(["toolchain", tool], nil)
      assert {:error, _} = Readiness.validate(data, root, "A1")
    end

    for field <- ~w(r0_acceptance oracle_review setup_review toolchain_lock) do
      data = staged(root, "A1") |> put_in([field, "sha256"], String.duplicate("f", 64))
      assert {:error, _} = Readiness.validate(data, root, "A1")
    end

    for field <- ~w(oracle_review setup_review) do
      data = staged(root, "A1")

      data =
        edit_receipt(data, root, field, &Map.put(&1, "reviewer_id", "synthetic-subject-author"))

      assert {:error, reason} = Readiness.validate(data, root, "A1")
      assert reason =~ "subject-author"
    end
  end

  test "deferred inventory stays typed and native A2 retains the amended exact class", %{
    root: root
  } do
    for {path, value} <- [
          {["devices", "ios", "installed_ram_gb"], true},
          {["devices", "ios", "sku"], %{}},
          {["toolchain", "xcode"], "latest"}
        ] do
      data = staged(root, "A1") |> put_in(path, value)
      assert {:error, _} = Readiness.validate(data, root, "A1")
    end

    for {path, value} <- [
          {["devices", "ios", "qualification_class"], "iphone-se-2"},
          {["devices", "ios", "installed_ram_gb"], 3},
          {["toolchain", "xcode"], nil}
        ] do
      data = staged(root, "A2", false) |> put_in(path, value)
      assert {:error, _} = Readiness.validate(data, root, "A2")
    end
  end

  test "stage digest domain is exact; template rejects both stages, real setup is A1 only" do
    data = Readiness.template()
    raw = data |> Map.drop(~w(status setup_review)) |> Codec.encode()
    assert Readiness.setup_digest(data) == Codec.sha256(raw)
    assert Readiness.setup_digest(data, "A1") == Codec.sha256("loka-r1-a1-setup-v1\0" <> raw)

    template =
      Readiness.read_json(
        Path.join(Readiness.root(), "conformance/r1-run-manifest.template.json")
      )

    for stage <- ~w(A1 A2),
        do: assert({:error, _} = Readiness.validate(template, Readiness.root(), stage))

    # The real setup holds genuine A1 approvals (2026-09-23); it must still fail A2.
    real = Readiness.read_json(Path.join(Readiness.root(), "prep/after-pr-10/setup.pending.json"))
    assert :ok = Readiness.validate(real, Readiness.root(), "A1")
    assert {:error, _} = Readiness.validate(real, Readiness.root(), "A2")
  end

  @tag :comparison
  test "both language CLIs agree on A1, A2 and cross-stage receipt rejection", %{root: root} do
    for {reviewed, requested, deferred} <- [
          {"A1", "A1", true},
          {"A1", "A2", true},
          {"A1", "A2", false},
          {"A2", "A1", false},
          {"A2", "A2", false}
        ] do
      data = staged(root, reviewed, deferred)
      path = Path.join(root, "stage-manifest.json")
      File.write!(path, Codec.encode(data))

      args = [
        Path.join(Readiness.root(), "checks/readiness.py"),
        "--require-ready",
        path,
        "--evidence-root",
        root,
        "--stage",
        requested
      ]

      {_, exit} = System.cmd("python3", args, stderr_to_stdout: true)
      assert exit == 0 == (Readiness.validate(data, root, requested) == :ok)
    end
  end

  # F1/F2 controls bind each changed synthetic record afresh. A failure must be
  # field validation, not an accidentally stale setup-review digest.
  defp correction_cases do
    devices =
      for platform <- ~w(ios android),
          {field, value, valid} <- [
            {"qualification_class",
             if(platform == "ios", do: "iphone-11", else: "galaxy-a14-4gb"), true},
            {"installed_ram_gb", 4, true},
            {"architecture", "arm64", true},
            {"os_version", if(platform == "ios", do: "16.4", else: "10"), true},
            {"model", "owner-reported partial inventory", true},
            {"qualification_class", "iphone-se-2", false},
            {"installed_ram_gb", 3, false},
            {"installed_ram_gb", true, false},
            {"architecture", "x86_64", false},
            {"os_version", "latest", false},
            {"os_version", "9", false},
            {"os_version", "16.x", false},
            {"os_version", 17, false},
            {"os_version", "１７.０", false}
          ],
          do: {"A1", ["devices", platform, field], value, valid}

    versions =
      for stage <- ~w(A1 A2),
          {tool, version} <- [
            {"node", "24.21.0"},
            {"typescript", "6.0.3"},
            {"elixir", "1.20.4"},
            {"otp", "28.4"}
          ],
          do: {stage, ["toolchain", tool], version, true}

    invalid =
      for stage <- ~w(A1 A2),
          tool <- ~w(node typescript elixir otp),
          value <- [
            "latest",
            "^24.21.0",
            "1.2.x",
            "1.2.3-rc1",
            "1..2",
            String.duplicate("a", 40),
            String.duplicate("1", 40),
            "",
            nil,
            28,
            "２８.４"
          ],
          do: {stage, ["toolchain", tool], value, false}

    partial =
      for stage <- ~w(A1 A2),
          {tool, value} <- [
            {"node", "24"},
            {"typescript", "6"},
            {"elixir", "1.20"},
            {"otp", "28"},
            {"node", "01.2.3"},
            {"elixir", "1.2.3+a..b"},
            {"otp", "28.4**"},
            {"otp", "28.4+patched"}
          ],
          do: {stage, ["toolchain", tool], value, false}

    devices ++
      versions ++
      invalid ++
      partial ++
      [
        {"A1", ["devices", "ios", "os_version"], "16.3.9", false},
        {"A1", ["toolchain", "otp"], "28.4.1", true},
        {"A2", ["toolchain", "otp"], "28.4.1.2", true},
        {"A1", ["toolchain", "elixir"], "1.20.4+build.7", true}
      ]
  end

  defp corrected_record(root, stage, path, value) do
    data = staged(root, stage, stage == "A1") |> put_in(path, value)

    edit_receipt(data, root, "setup_review", fn review ->
      Map.put(review, "setup_digest", Readiness.setup_digest(data, stage))
    end)
  end

  test "F1 F2 supplied semantics and complete runtime identities survive rebinding", %{root: root} do
    for {stage, path, value, valid} <- correction_cases() do
      data = corrected_record(root, stage, path, value)

      assert Readiness.validate(data, root, stage) == :ok == valid,
             inspect({stage, path, value, valid})
    end
  end

  test "F3 unsupported explicit stages have controlled diagnostics in both modes" do
    for stage <- ~w(A3 a1),
        mode <- [["--check-template"], ["--require-ready", "not-read-for-invalid-stage"]] do
      assert_raise Mix.Error, ~r/NOT READY: unsupported readiness stage/, fn ->
        Mix.Tasks.Loka.Readiness.run(mode ++ ["--stage", stage])
      end
    end
  end

  @tag :comparison
  test "F1 F2 corrected re-bound matrix agrees with the Python CLI", %{root: root} do
    for {stage, path, value, valid} <- correction_cases() do
      data = corrected_record(root, stage, path, value)
      manifest = Path.join(root, "correction-manifest.json")
      File.write!(manifest, Codec.encode(data))

      {output, exit} =
        System.cmd(
          "python3",
          [
            Path.join(Readiness.root(), "checks/readiness.py"),
            "--require-ready",
            manifest,
            "--evidence-root",
            root,
            "--stage",
            stage
          ],
          stderr_to_stdout: true
        )

      assert exit == if(valid, do: 0, else: 1), output
      assert Readiness.validate(data, root, stage) == :ok == valid
    end
  end

  defp changes do
    [
      {["accepted_spec_commit"], nil},
      {["schema_version"], true},
      {["candidate"], "B"},
      {["devices", "android", "sku"], nil},
      {["devices", "ios", "qualification_class"], "newer-phone"},
      {["devices", "ios", "os_version"], "15.0"},
      {["devices", "ios", "installed_ram_gb"], true},
      {["devices", "android", "architecture"], "x86_64"},
      {["server", "ram_gb"], 8},
      {["server", "cores"], true},
      {["toolchain", "expo"], "latest"},
      {["toolchain", "node"], "22.x"},
      {["toolchain", "hermes"], "1.2.3-beta.1"},
      {["candidate_author_ids"], ["synthetic-reviewer"]},
      {["candidate_author_ids"], ["a", "a"]},
      {["oracle_review", "path"], nil},
      {["toolchain_lock", "path"], "../outside"},
      {["toolchain_lock", "path"], "/outside"}
    ]
  end

  test "template is exact typed JSON and stays NOT READY" do
    assert :ok ==
             Readiness.check_template(
               Readiness.read_json(
                 Path.join(Readiness.root(), "conformance/r1-run-manifest.template.json")
               )
             )

    assert {:error, _} =
             Readiness.check_template(Map.put(Readiness.template(), "schema_version", true))

    assert {:error, reason} = Readiness.validate(Readiness.template(), Readiness.root())
    assert reason =~ "pending"
  end

  test "complete synthetic records test structure only", %{root: root} do
    assert :ok == Readiness.validate(synthetic(root), root)
  end

  test "every prior preparation mutation remains rejected", %{root: root} do
    data = synthetic(root)

    for {path, value} <- changes(),
        do: assert({:error, _} = Readiness.validate(put_in(data, path, value), root))

    for changed <- [
          Map.put(data, "measured_p95", 1),
          Map.delete(data, "server"),
          Map.put(data, "inputs", tl(data["inputs"])),
          Map.put(data, "inputs", Enum.reverse(data["inputs"]))
        ] do
      assert {:error, _} = Readiness.validate(changed, root)
    end
  end

  test "malformed evidence and normative set fail without crashes", %{root: root} do
    data = synthetic(root)

    for value <- [nil, 7, [], "not-a-record"] do
      assert {:error, _} =
               Readiness.validate(Map.put(data, "inputs", [value | tl(data["inputs"])]), root)
    end

    for files <- [[%{"not" => "a path"}], [], ["01-core-principles.md", "01-core-principles.md"]] do
      changed = edit_receipt(data, root, "r0_acceptance", &Map.put(&1, "normative_files", files))
      assert {:error, reason} = Readiness.validate(changed, root)
      assert reason =~ "R0 acceptance"
    end
  end

  test "hash tamper, missing file, empty lock and setup rebinding fail", %{root: root} do
    data = synthetic(root)
    File.write!(Path.join(root, hd(Readiness.inputs())), "tampered")
    assert {:error, reason} = Readiness.validate(data, root)
    assert reason =~ "hash mismatch"
    data = synthetic(root)
    assert {:error, reason} = Readiness.validate(put_in(data, ["server", "cores"], 9), root)
    assert reason =~ "configuration"
    empty = Map.put(data, "toolchain_lock", retain(root, "empty.txt", " \n"))
    assert {:error, reason} = Readiness.validate(empty, root)
    assert reason =~ "empty"
    File.rm!(Path.join(root, "test-only-lock.txt"))
    assert {:error, _} = Readiness.validate(data, root)
  end

  test "rehashed receipts cannot change accepted commit, outcome, author separation or oracle inputs",
       %{root: root} do
    for name <- ~w(oracle_review setup_review),
        {key, value} <- [
          {"reviewer_id", "synthetic-author"},
          {"disposition", "pending"},
          {"accepted_spec_commit", String.duplicate("b", 40)},
          {"independent_of_candidate_authorship", 1},
          {"subject_author_ids", ["synthetic-reviewer"]},
          {"subject_author_ids", []},
          {"subject_author_ids", [true]},
          {"subject_author_ids", ["a", "a"]},
          {"independent_of_subject_authorship", 1}
        ] do
      data = synthetic(root) |> edit_receipt(root, name, &Map.put(&1, key, value))
      assert {:error, _} = Readiness.validate(data, root)
    end

    data =
      synthetic(root)
      |> edit_receipt(root, "oracle_review", &Map.update!(&1, "inputs", fn rows -> tl(rows) end))

    assert {:error, reason} = Readiness.validate(data, root)
    assert reason =~ "exact inputs"
  end

  test "setup digest has no self-reference and does bind configuration" do
    data = Readiness.template()
    digest = Readiness.setup_digest(data)

    assert digest ==
             Readiness.setup_digest(
               Map.put(data, "setup_review", %{"path" => "later", "sha256" => "excluded"})
             )

    assert digest == Readiness.setup_digest(Map.put(data, "status", "setup_reviewed"))

    refute digest ==
             Readiness.setup_digest(put_in(data, ["devices", "ios", "model"], "different"))
  end

  test "evidence paths resolve symlinks before containment and cap allocations", %{root: root} do
    data = synthetic(root)
    File.ln_s!("test-only-lock.txt", Path.join(root, "inside-link"))

    assert Readiness.retained(%{data["toolchain_lock"] | "path" => "inside-link"}, root) ==
             "synthetic lock, not dependencies"

    File.ln_s!(System.tmp_dir!(), Path.join(root, "escape"))

    assert_raise ArgumentError, fn ->
      Readiness.retained(%{data["toolchain_lock"] | "path" => "escape"}, root)
    end

    File.ln_s!("cycle", Path.join(root, "cycle"))

    assert {:error, _} =
             Readiness.validate(put_in(data, ["toolchain_lock", "path"], "cycle"), root)

    oversized = retain(root, "large", String.duplicate("x", 8 * 1024 * 1024 + 1))

    assert_raise ArgumentError, "evidence file exceeds preparation bound", fn ->
      Readiness.retained(oversized, root)
    end
  end

  test "CLI preserves a controlled negative gate" do
    assert_raise Mix.Error, ~r/NOT READY:.*pending/, fn ->
      Mix.Tasks.Loka.Readiness.run([
        "--require-ready",
        Path.join(Readiness.root(), "conformance/r1-run-manifest.template.json")
      ])
    end

    assert_raise Mix.Error, fn -> Mix.Tasks.Loka.Readiness.run(["--unexpected"]) end
  end

  @tag :comparison
  test "transitional Python and Elixir readiness agree on valid and malformed bundles", %{
    root: root
  } do
    data = synthetic(root)

    candidates = [
      data,
      Readiness.template(),
      Map.put(data, "measured_p95", 1),
      Map.put(data, "inputs", tl(data["inputs"]))
      | Enum.map(changes(), fn {path, value} -> put_in(data, path, value) end)
    ]

    for candidate <- candidates do
      path = Path.join(root, "manifest.json")
      File.write!(path, Codec.encode(candidate))

      args = [
        Path.join(Readiness.root(), "checks/readiness.py"),
        "--require-ready",
        path,
        "--evidence-root",
        root
      ]

      {_, exit} = System.cmd("python3", args, stderr_to_stdout: true)
      assert exit == 0 == (Readiness.validate(candidate, root) == :ok)
    end
  end
end
