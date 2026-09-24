defmodule LokaR1.World do
  @moduledoc """
  The receipt/transaction model of `checks/contract_model.py` over the runner's
  HOST value. `step/3` is pure: it takes a world's decide function, the whole
  HOST and one command, and returns `{step_record, host}`.

  A decide function is `(memory, request) -> {proposed, code, events, accepted?}`.
  Where the Python model would raise (for example a memory value of the wrong
  type), the decide function raises `LokaR1.Py.Error`; the runner turns that
  into `invalid_protocol` for the whole request.
  """
  alias LokaR1.{Codec, Lantern, Py, Tiny}

  @faults ~w(before_commit commit_pending after_commit_before_memory after_memory_before_response)
  @envelope_keys ~w(id actor action targets input view session route seq)

  @doc "`{decide, initial_memory}` for a runner world name, or `:error`."
  def world("tiny-event"), do: {&Tiny.decide("event", &1, &2), Tiny.initial()}
  def world("tiny-state"), do: {&Tiny.decide("state", &1, &2), Tiny.initial()}
  def world("lantern"), do: {&Lantern.decide/2, Lantern.initial()}
  def world(_), do: :error

  def new(memory) do
    %{
      "memory" => memory,
      "durable" => memory,
      "receipts" => %{},
      "pending" => nil,
      "in_doubt" => false,
      "published" => []
    }
  end

  def step(decide, host, command) do
    case command(command) do
      {:error, code} ->
        {record(nil, code, host, host), host}

      {:ok, fun} ->
        case fun.(decide, host) do
          {:error, code} -> {record(nil, code, host, host), host}
          {result, new_host} -> {record(result, nil, host, new_host), new_host}
        end
    end
  end

  # ---- command shape --------------------------------------------------------

  defp command(%{"op" => "invoke", "request" => request} = c) when map_size(c) == 2,
    do: {:ok, &invoke(&1, &2, request, nil, true)}

  defp command(%{"op" => "invoke", "request" => request, "options" => options} = c)
       when map_size(c) == 3 do
    with {:ok, fault, authorized} <- options(options) do
      {:ok, &invoke(&1, &2, request, fault, authorized)}
    end
  end

  defp command(%{"op" => "recover"} = c) when map_size(c) == 1, do: {:ok, &recover/2}

  defp command(%{"op" => "settle", "committed" => committed} = c) when map_size(c) == 2,
    do: {:ok, &settle(&1, &2, committed)}

  defp command(_), do: {:error, "invalid_command"}

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

  # ---- the model ------------------------------------------------------------

  defp response(kind, code, revision, delivery \\ "new"),
    do: %{"kind" => kind, "code" => code, "revision" => revision, "delivery" => delivery}

  defp revision(host), do: Py.get(host["memory"], "revision")

  defp invoke(_decide, host, request, _fault, _authorized) when not is_map(request),
    do: {response("rejected", "invalid_envelope", revision(host)), host}

  defp invoke(decide, host, request, fault, authorized) do
    identity = request["id"]

    case intent(request) do
      :error ->
        {response("rejected", "invalid_envelope", revision(host)), host}

      {:ok, digest} ->
        prior = host["receipts"][identity]

        cond do
          not authorized or request["actor"] != "hero" ->
            {response("rejected", "unauthorized", revision(host)), host}

          host["in_doubt"] ->
            {response("retryable", "commit_pending", revision(host)), host}

          prior != nil and prior["intent"] != digest ->
            {response("rejected", "integrity_conflict", revision(host)), host}

          prior != nil ->
            {%{prior["result"] | "delivery" => "replay"}, host}

          stale?(request, host) ->
            result = response("rejected", "stale_view", revision(host))
            receipt = %{"intent" => digest, "result" => result}
            {result, put_in(host, ["receipts", identity], receipt)}

          true ->
            commit(decide, host, request, identity, digest, fault)
        end
    end
  end

  # "view" in request and request["view"] != f"view:{revision}". A list or dict
  # revision has no modelled str(), so no view matches it.
  defp stale?(request, host) do
    Map.has_key?(request, "view") and
      case Py.str(revision(host)) do
        nil -> true
        s -> request["view"] !== "view:" <> s
      end
  end

  defp commit(decide, host, request, identity, digest, fault) do
    {proposed, code, events, accepted} = decide.(host["memory"], request)

    result =
      response(if(accepted, do: "accepted", else: "rejected"), code, Py.get(proposed, "revision"))

    receipt = %{"intent" => digest, "result" => result}

    case fault do
      "before_commit" ->
        {response("retryable", "rolled_back", revision(host)), host}

      "commit_pending" ->
        host = %{
          host
          | "in_doubt" => true,
            "pending" => %{"id" => identity, "proposed" => proposed, "receipt" => receipt}
        }

        {response("retryable", "commit_pending", revision(host)), host}

      _ ->
        host = %{
          host
          | "durable" => proposed,
            "receipts" => Map.put(host["receipts"], identity, receipt)
        }

        if fault == "after_commit_before_memory" do
          host = %{host | "in_doubt" => true}
          {response("retryable", "commit_unknown", revision(host)), host}
        else
          host = %{host | "memory" => proposed, "published" => host["published"] ++ events}

          if fault == "after_memory_before_response",
            do: {response("retryable", "response_lost", revision(host)), host},
            else: {result, host}
        end
    end
  end

  @doc "The receipt intent digest, or `:error` for an invalid envelope."
  def intent(request) do
    targets = Map.get(request, "targets", [])
    input = Map.get(request, "input", %{})

    valid =
      Map.keys(request) -- @envelope_keys == [] and
        Enum.all?(~w(id actor action), &(is_binary(request[&1]) and request[&1] != "")) and
        is_list(targets) and Enum.all?(targets, &is_binary/1) and is_map(input)

    if valid do
      value = %{
        "actor" => request["actor"],
        "action" => request["action"],
        "targets" => targets,
        "input" => input
      }

      {:ok, Base.encode16(:crypto.hash(:sha256, Codec.encode(value)), case: :lower)}
    else
      :error
    end
  end

  defp recover(_decide, %{"pending" => nil} = host) do
    host = %{host | "memory" => host["durable"], "in_doubt" => false}
    {response("recovered", "recovered", revision(host)), host}
  end

  defp recover(_decide, host), do: {response("retryable", "commit_pending", revision(host)), host}

  defp settle(_decide, _host, committed) when not is_boolean(committed),
    do: {:error, "invalid_commit_disposition"}

  defp settle(_decide, %{"pending" => nil}, _committed), do: {:error, "no_pending_transaction"}

  defp settle(_decide, %{"pending" => pending} = host, committed) do
    host =
      if committed,
        do: %{
          host
          | "durable" => pending["proposed"],
            "receipts" => Map.put(host["receipts"], pending["id"], pending["receipt"])
        },
        else: host

    {nil, %{host | "pending" => nil}}
  end

  # ---- step record ------------------------------------------------------------

  defp record(result, error, before, host) do
    old = before["memory"]

    delta =
      for {k, v} <- host["memory"], Map.fetch(old, k) !== {:ok, v}, into: %{}, do: {k, v}

    %{
      "result" => result,
      "error" => error,
      "events" => Enum.drop(host["published"], length(before["published"])),
      "delta" => delta,
      "state" => host
    }
  end
end
