defmodule LokaR1Server.Host do
  @moduledoc """
  The durable host: one GenServer per world instance, the only writer of that
  instance's rows. It runs the model host's commands (`LokaR1.World`) against the
  unchanged kernel decide function, but `durable`, `receipts` and `pending` live
  in SQLite: every accepted attempt (including failed rolls and terminal
  rejections that the model receipts) is one `BEGIN IMMEDIATE`..`COMMIT`, and the
  step record's `durable`, `receipts` and `pending` are read back from the file.

  `memory`, `in_doubt` and `published` are process memory. After a real fault the
  host rebuilds them from SQLite alone: `memory` is the durable state, `in_doubt`
  is whether a pending record exists, and `published` starts empty (the outbox is
  not durable in R1).

  A fault schedule `%{"step" => n, "point" => p, "kind" => k}` (see the README's
  A2 contract) fires when command `n` (0-based) reaches point `p`.
  """
  use GenServer, restart: :temporary

  alias LokaR1.{Codec, Py, World}
  alias LokaR1Server.Store

  defmodule InjectedFault do
    defexception [:point]
    @impl true
    def message(%{point: point}), do: "injected fault at #{point}"
  end

  @faults ~w(before_commit commit_pending after_commit_before_memory after_memory_before_response)

  @typedoc "A step record: `%{\"result\", \"error\", \"events\", \"delta\", \"state\"}`."
  @type step_record :: map()

  @doc """
  Starts a host under `LokaR1Server.Hosts`. Options: `:db` (path), `:id`,
  `:world`, `:initial` (creates the instance; omit it to rebuild an existing one
  from storage), `:fault` (schedule or nil), `:diag` (path of a JSONL file that
  gets one line per decision attempt, or nil).
  """
  @spec start(keyword()) :: {:ok, pid()} | {:error, term()}
  def start(opts), do: DynamicSupervisor.start_child(LokaR1Server.Hosts, {__MODULE__, opts})

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  @doc "Runs one `world.run` command. `:py_error` where the Python model would raise."
  @spec step(pid(), term()) :: {:ok, step_record()} | :py_error
  def step(pid, command), do: GenServer.call(pid, {:step, command}, :infinity)

  @doc "The current HOST value, reconciling from storage first if the host is fenced."
  @spec host(pid()) :: map()
  def host(pid), do: GenServer.call(pid, :host, :infinity)

  @doc "Stops the host; with `drop: true` it first deletes the instance's rows."
  @spec stop(pid(), keyword()) :: :ok
  def stop(pid, opts \\ []) do
    if opts[:drop], do: GenServer.call(pid, :drop, :infinity)
    GenServer.stop(pid)
  end

  # ---- server ---------------------------------------------------------------

  @impl true
  def init(opts) do
    s = %{
      db: Keyword.fetch!(opts, :db),
      id: Keyword.fetch!(opts, :id),
      world: Keyword.fetch!(opts, :world),
      fault: opts[:fault],
      diag: opts[:diag],
      step: 0,
      fenced: false
    }

    {decide, _} = World.world(s.world)
    s = Map.merge(s, %{decide: decide, conn: Store.open(s.db)})

    case opts[:initial] do
      nil ->
        {:ok, rebuild(s)}

      initial ->
        :ok = Store.create(s.conn, s.id, s.world, initial)
        {:ok, Map.merge(s, %{memory: initial, in_doubt: false, published: []})}
    end
  end

  @impl true
  def handle_call({:step, command}, _from, s) do
    s = reconcile(s)
    before = {s.memory, length(s.published)}

    {reply, s} =
      try do
        {result, error, s} = command(command, s)
        {{:ok, record(result, error, before, s)}, s}
      rescue
        Py.Error ->
          {:py_error, rebuild(rollback(s))}

        _e in [InjectedFault, Store.Error] ->
          s = rebuild(rollback(s))
          {{:ok, record(fault_response(s, command), nil, before, s)}, s}
      end

    {:reply, reply, %{s | step: s.step + 1}}
  end

  def handle_call(:host, _from, s) do
    s = reconcile(s)
    {:reply, view(s), s}
  end

  def handle_call(:drop, _from, s) do
    :ok = Store.drop(s.conn, s.id)
    {:reply, :ok, s}
  end

  @impl true
  def terminate(_reason, s), do: Store.close(s.conn)

  # ---- commands (the shapes of LokaR1.World) ------------------------------------

  defp command(%{"op" => "invoke", "request" => request} = c, s) when map_size(c) == 2,
    do: invoke(s, request, nil, true)

  defp command(%{"op" => "invoke", "request" => request, "options" => options} = c, s)
       when map_size(c) == 3 do
    case options(options) do
      {:ok, fault, authorized} -> invoke(s, request, fault, authorized)
      {:error, code} -> {nil, code, s}
    end
  end

  defp command(%{"op" => "recover"} = c, s) when map_size(c) == 1, do: recover(s)

  defp command(%{"op" => "settle", "committed" => committed} = c, s) when map_size(c) == 2,
    do: settle(s, committed)

  defp command(_, s), do: {nil, "invalid_command", s}

  defp options(options) when is_map(options) do
    fault = Map.get(options, "fault")
    authorized = Map.get(options, "authorized", true)

    cond do
      Map.keys(options) -- ["fault", "authorized"] != [] -> {:error, "invalid_options"}
      Map.has_key?(options, "fault") and not is_binary(fault) -> {:error, "invalid_options"}
      not is_boolean(authorized) -> {:error, "invalid_options"}
      fault != nil and fault not in @faults -> {:error, "unknown_fault"}
      true -> {:ok, fault, authorized}
    end
  end

  defp options(_), do: {:error, "invalid_options"}

  defp response(kind, code, revision, delivery \\ "new"),
    do: %{"kind" => kind, "code" => code, "revision" => revision, "delivery" => delivery}

  defp revision(s), do: Py.get(s.memory, "revision")

  defp invoke(s, request, fault, authorized) do
    with true <- is_map(request),
         {:ok, digest} <- World.intent(request) do
      admit(s, request, request["id"], digest, fault, authorized)
    else
      _ -> {response("rejected", "invalid_envelope", revision(s)), nil, s}
    end
  end

  defp admit(s, request, identity, digest, fault, authorized) do
    reject = &{response("rejected", &1, revision(s)), nil, s}

    cond do
      not authorized or request["actor"] != "hero" ->
        reject.("unauthorized")

      s.in_doubt ->
        {response("retryable", "commit_pending", revision(s)), nil, s}

      prior = Store.receipt(s.conn, s.id, identity) ->
        if prior["intent"] != digest,
          do: reject.("integrity_conflict"),
          else: {%{prior["result"] | "delivery" => "replay"}, nil, s}

      stale?(request, s) ->
        result = response("rejected", "stale_view", revision(s))

        transaction(s, fn ->
          Store.put_receipt(s.conn, s.id, identity, receipt(digest, result))
        end)

        {result, nil, s}

      true ->
        decide(s, request, identity, digest, fault)
    end
  end

  defp stale?(request, s) do
    Map.has_key?(request, "view") and
      case Py.str(revision(s)) do
        nil -> true
        v -> request["view"] !== "view:" <> v
      end
  end

  defp receipt(digest, result), do: %{"intent" => digest, "result" => result}

  defp decide(s, request, identity, digest, fault) do
    diagnose(s, identity)
    point(s, "pre_decision")
    {proposed, code, events, accepted} = s.decide.(s.memory, request)
    kind = if accepted, do: "accepted", else: "rejected"
    receipt = receipt(digest, response(kind, code, Py.get(proposed, "revision")))
    point(s, "post_decision_pre_commit")

    case fault do
      "before_commit" ->
        # A real transaction with real writes, then a definite ROLLBACK.
        Store.exec!(s.conn, "BEGIN IMMEDIATE")
        write(s, identity, proposed, receipt)
        Store.exec!(s.conn, "ROLLBACK")
        {response("retryable", "rolled_back", revision(s)), nil, s}

      "commit_pending" ->
        pending = %{"id" => identity, "proposed" => proposed, "receipt" => receipt}
        transaction(s, fn -> Store.put_pending(s.conn, s.id, pending) end)
        {response("retryable", "commit_pending", revision(s)), nil, %{s | in_doubt: true}}

      _ ->
        s = commit(s, identity, proposed, receipt)
        adopt(s, fault, proposed, events, receipt["result"])
    end
  end

  defp commit(s, identity, proposed, receipt) do
    Store.exec!(s.conn, "BEGIN IMMEDIATE")
    write(s, identity, proposed, receipt)

    if scheduled?(s, "in_persistence", "commit_unknown") do
      # COMMIT is issued and its answer thrown away: fence until reconciled.
      _ = Exqlite.Sqlite3.execute(s.conn, "COMMIT")
      %{s | fenced: true, in_doubt: true}
    else
      Store.exec!(s.conn, "COMMIT")
      point(s, "post_commit_pre_adoption")
      s
    end
  end

  defp adopt(%{fenced: true} = s, _, _, _, _),
    do: {response("retryable", "commit_unknown", revision(s)), nil, s}

  defp adopt(s, "after_commit_before_memory", _, _, _),
    do: {response("retryable", "commit_unknown", revision(s)), nil, %{s | in_doubt: true}}

  defp adopt(s, fault, proposed, events, result) do
    s = %{s | memory: proposed, published: s.published ++ events}
    point(s, "post_adoption_pre_response")

    result =
      if fault == "after_memory_before_response",
        do: response("retryable", "response_lost", revision(s)),
        else: result

    point(s, "post_response_pre_presentation")
    {result, nil, s}
  end

  # The first write of every attempt is the durable state; `in_persistence` sits
  # between it and the receipt row.
  defp write(s, identity, proposed, receipt) do
    Store.put_durable(s.conn, s.id, proposed)
    point(s, "in_persistence")
    Store.put_receipt(s.conn, s.id, identity, receipt)
  end

  defp transaction(s, fun) do
    Store.exec!(s.conn, "BEGIN IMMEDIATE")
    fun.()
    Store.exec!(s.conn, "COMMIT")
  end

  defp recover(s) do
    {_, durable, pending} = Store.instance(s.conn, s.id)

    if pending == nil do
      s = %{s | memory: durable, in_doubt: false}
      {response("recovered", "recovered", revision(s)), nil, s}
    else
      {response("retryable", "commit_pending", revision(s)), nil, s}
    end
  end

  defp settle(s, committed) when not is_boolean(committed),
    do: {nil, "invalid_commit_disposition", s}

  defp settle(s, committed) do
    case Store.instance(s.conn, s.id) do
      {_, _, nil} ->
        {nil, "no_pending_transaction", s}

      {_, _, pending} ->
        transaction(s, fn ->
          if committed do
            Store.put_durable(s.conn, s.id, pending["proposed"])
            Store.put_receipt(s.conn, s.id, pending["id"], pending["receipt"])
          end

          Store.put_pending(s.conn, s.id, nil)
        end)

        {nil, nil, s}
    end
  end

  # ---- faults and recovery ----------------------------------------------------

  defp scheduled?(%{fault: %{"step" => n, "point" => p, "kind" => k}, step: n}, p, k), do: true
  defp scheduled?(_, _, _), do: false

  defp point(%{fault: %{"step" => n, "point" => p, "kind" => kind}, step: n} = s, p) do
    case kind do
      "raise" -> raise InjectedFault, point: p
      "kill" -> :erlang.halt(137, flush: false)
      "io_error" when p == "in_persistence" -> Store.fill!(s.conn)
      _ -> :ok
    end
  end

  defp point(_, _), do: :ok

  # One line per decision attempt, written before the kernel runs, so an abrupt
  # death leaves a durable record of what the host was doing.
  defp diagnose(%{diag: nil}, _), do: :ok

  defp diagnose(s, identity) do
    {_, durable, pending} = Store.instance(s.conn, s.id)

    line = %{
      "step" => s.step,
      "id" => identity,
      "durable_sha256" => sha256(durable),
      "pending" => pending != nil,
      "receipts" => map_size(Store.receipts(s.conn, s.id))
    }

    File.write!(s.diag, [Codec.encode(line), ?\n], [:append])
  end

  @doc false
  def sha256(value), do: Base.encode16(:crypto.hash(:sha256, Codec.encode(value)), case: :lower)

  defp rollback(s) do
    if Store.in_transaction?(s.conn), do: Store.exec!(s.conn, "ROLLBACK")
    s
  end

  # The fault step's answer, after the host has rebuilt from storage. Faults fire
  # only on a fresh identity, so whether the attempt committed is whether its
  # receipt row exists now: read from the file, not remembered.
  defp fault_response(s, %{"request" => %{"id" => identity}}) do
    committed = Store.receipt(s.conn, s.id, identity) != nil
    response("retryable", if(committed, do: "response_lost", else: "rolled_back"), revision(s))
  end

  # A failed settle or recover write: the transaction was rolled back.
  defp fault_response(s, _command), do: response("retryable", "rolled_back", revision(s))

  defp reconcile(%{fenced: true} = s), do: rebuild(s)
  defp reconcile(s), do: s

  # Authority from SQLite alone, on a fresh connection.
  defp rebuild(s) do
    if Map.has_key?(s, :conn), do: Store.close(s.conn)
    conn = Store.open(s.db)
    {world, durable, pending} = Store.instance(conn, s.id)
    ^world = s.world

    Map.merge(s, %{
      conn: conn,
      memory: durable,
      in_doubt: pending != nil,
      published: [],
      fenced: false
    })
  end

  # ---- step record --------------------------------------------------------------

  defp view(s) do
    {_, durable, pending} = Store.instance(s.conn, s.id)

    %{
      "memory" => s.memory,
      "durable" => durable,
      "receipts" => Store.receipts(s.conn, s.id),
      "pending" => pending,
      "in_doubt" => s.in_doubt,
      "published" => s.published
    }
  end

  defp record(result, error, {old, published_before}, s) do
    host = view(s)

    %{
      "result" => result,
      "error" => error,
      "events" => Enum.drop(s.published, published_before),
      "delta" => for({k, v} <- s.memory, Map.fetch(old, k) !== {:ok, v}, into: %{}, do: {k, v}),
      "state" => host
    }
  end
end
