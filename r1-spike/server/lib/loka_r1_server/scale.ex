defmodule LokaR1Server.Scale do
  @moduledoc """
  Quick R1-A3 timing on the server (owner decision 2026-09-24): the unchanged
  Elixir kernel behind the A2 store (`LokaR1Server.Store`: WAL, `synchronous=FULL`,
  raw `BEGIN IMMEDIATE`/`COMMIT`), at Tiny/Medium/Stress state size. The step is
  the same as `mobile/scale.ts`, so the two CSVs share one summarizer:

  - admission: the receipt row for this request id, and the kernel HOST value
    (memory, that one receipt if any, no pending, empty published);
  - decision: `LokaR1.World.step/3`, in process (no boundary encode/decode);
  - encode: `Codec.encode` of the durable state (only when the revision changed),
    the new receipt and the new events;
  - commit: `BEGIN IMMEDIATE`, UPDATE durable, INSERT receipt, `COMMIT`;
  - projection: adopt the new memory and encode `{result, events, delta}`.

  It runs in the calling process, not behind the A2 host's GenServer call, and
  the outbox isn't durable on the server (as in A2), so events are encoded but
  not written.
  """
  alias LokaR1.{Codec, World}
  alias LokaR1Server.Store

  @header "host,model,i,action,outcome,code,state_write,admission_ms,decision_ms,encode_ms,commit_ms,projection_ms,e2e_ms"
  @checkpoints 20

  @spec header() :: String.t()
  def header, do: @header

  @doc "Runs one model in a fresh database at `db`; returns `{csv_rows, facts}`."
  @spec run_model(Path.t(), map(), String.t()) :: {[String.t()], map()}
  def run_model(db, input, host_name) do
    %{"model" => model, "world" => world_name, "initial" => initial} = input
    {decide, _} = World.world(world_name)
    conn = Store.open(db)
    id = "a3-" <> model
    :ok = Store.create(conn, id, world_name, initial)

    Store.exec!(
      conn,
      "CREATE TABLE IF NOT EXISTS checkpoint (k TEXT PRIMARY KEY, v TEXT NOT NULL)"
    )

    pragmas = %{
      "journal_mode" => hd(hd(Store.exec!(conn, "PRAGMA journal_mode"))),
      "synchronous" => hd(hd(Store.exec!(conn, "PRAGMA synchronous")))
    }

    {_, memory, nil} = Store.instance(conn, id)
    warmup = input["warmup"]

    {rows, memory} =
      input["commands"]
      |> Enum.with_index()
      |> Enum.flat_map_reduce(memory, fn {command, i}, memory ->
        {row, memory} = step(conn, id, decide, memory, command)

        if rem(i + 1, 250) == 0,
          do: IO.puts(:stderr, "LOKA_A3_PROGRESS #{model} #{i + 1}/#{length(input["commands"])}")

        row = [host_name, model, i | row] |> Enum.join(",")
        {if(i >= warmup, do: [row], else: []), memory}
      end)

    pre = Codec.encode(memory)

    checkpoints =
      for _ <- 1..@checkpoints do
        t0 = now()
        Store.exec!(conn, "BEGIN IMMEDIATE")
        Store.exec!(conn, "INSERT OR REPLACE INTO checkpoint VALUES ('state', ?1)", [pre])
        Store.exec!(conn, "COMMIT")
        [[text]] = Store.exec!(conn, "SELECT v FROM checkpoint WHERE k = 'state'")
        {:ok, value} = Codec.decode(text)
        back = Codec.encode(value)
        t1 = now()
        back == pre || raise "#{model}: checkpoint round trip changed the canonical state"
        round((t1 - t0) / 1000)
      end

    [[durable]] = Store.exec!(conn, "SELECT durable FROM instances WHERE id = ?1", [id])
    durable == pre || raise "#{model}: durable row differs from memory at the end"
    [[receipts]] = Store.exec!(conn, "SELECT count(*) FROM receipts WHERE instance = ?1", [id])
    Store.close(conn)

    facts = %{
      "model" => model,
      "version" => input["version"],
      "seed" => input["seed"],
      "steps" => length(input["commands"]),
      "warmup" => warmup,
      "initial_state_bytes" => byte_size(Codec.encode(initial)),
      "final_state_bytes" => byte_size(pre),
      "final_state_sha256" => Base.encode16(:crypto.hash(:sha256, pre), case: :lower),
      "final_narration_entries" => length(memory["narration"]),
      "receipts" => receipts,
      "sqlite" => pragmas,
      "checkpoint_round_trip_us" => checkpoints
    }

    {rows, facts}
  end

  defp step(conn, id, decide, memory, %{"request" => %{"id" => rid} = request} = command) do
    t0 = now()
    prior = Store.receipt(conn, id, rid)
    receipts = if prior, do: %{rid => prior}, else: %{}

    host = %{
      "memory" => memory,
      "durable" => memory,
      "receipts" => receipts,
      "pending" => nil,
      "in_doubt" => false,
      "published" => []
    }

    t1 = now()
    {record, after_host} = World.step(decide, host, command)
    t2 = now()
    fresh = prior == nil and Map.has_key?(after_host["receipts"], rid)
    durable = after_host["durable"]
    state_write = fresh and durable["revision"] != memory["revision"]
    durable_text = if state_write, do: Codec.encode(durable)
    receipt = if fresh, do: after_host["receipts"][rid]
    receipt_result = if fresh, do: Codec.encode(receipt["result"])
    _events = Enum.map(after_host["published"], &Codec.encode/1)
    t3 = now()

    if fresh do
      Store.exec!(conn, "BEGIN IMMEDIATE")

      if durable_text,
        do:
          Store.exec!(conn, "UPDATE instances SET durable = ?2 WHERE id = ?1", [id, durable_text])

      Store.exec!(
        conn,
        "INSERT INTO receipts (instance, id, intent, result) VALUES (?1, ?2, ?3, ?4)",
        [id, rid, receipt["intent"], receipt_result]
      )

      Store.exec!(conn, "COMMIT")
    end

    t4 = now()
    memory = after_host["memory"]
    _response = Codec.encode(Map.take(record, ~w(result events delta)))
    t5 = now()
    result = record["result"]
    outcome = if result["delivery"] == "replay", do: "replayed", else: result["kind"]

    row = [
      request["action"],
      outcome,
      result["code"],
      if(state_write, do: 1, else: 0)
      | Enum.map([t1 - t0, t2 - t1, t3 - t2, t4 - t3, t5 - t4, t5 - t0], &ms/1)
    ]

    {row, memory}
  end

  defp now, do: System.monotonic_time(:nanosecond)
  defp ms(ns), do: :erlang.float_to_binary(ns / 1_000_000, decimals: 4)
end
