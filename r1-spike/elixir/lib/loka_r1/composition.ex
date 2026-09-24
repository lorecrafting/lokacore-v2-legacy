defmodule LokaR1.Composition do
  @moduledoc """
  `CompositionModel.evaluate` of `checks/composition_model.py`: one isolated
  proposal, all-or-nothing. A fault returns the unchanged input state.

  As in the model, a KeyError or TypeError (a missing key, an unhashable value,
  a non-numeric comparison) is the fault `invalid_plan`. State containers the
  model indexes (`facts`, `locations`, `capacities`, `jobs`, `active`) must have
  their JSON type when used, otherwise `invalid_plan` (see NOTES.md).
  """
  import LokaR1.Py, only: [get: 2, num: 1, in_set?: 2, raise!: 1]
  alias LokaR1.{Codec, Py}

  @fields %{
    "fact.set" => ~w(fact op value),
    "fact.add" => ~w(amount fact op),
    "event.emit" => ~w(event op payload),
    "subscription.activate" => ~w(op rule),
    "item.transfer" => ~w(destination item op source),
    "job.schedule" => ~w(due id op)
  }
  @facts %{"flag" => {0, 2}, "seen" => {0, 2}, "count" => {-2_147_483_648, 2_147_483_647}}
  @custom ~w(proof.signal proof.followup)

  @doc "Evaluate a plan. `advance_target` is `nil` for none."
  def evaluate(limits, initial, root, rules, advance_target) do
    run(limits, initial, root, rules, advance_target)
  rescue
    Py.Error -> fault("invalid_plan", initial)
  catch
    {:fault, code} -> fault(code, initial)
  end

  defp fault(code, initial),
    do: %{
      "kind" => "fault",
      "code" => code,
      "state" => initial,
      "events" => [],
      "deliveries" => []
    }

  defp fault!(code), do: throw({:fault, code})

  defp obj!(v) when is_map(v), do: v
  defp obj!(_), do: raise!(:type_error)

  defp run(limits, state, root, rules, at) do
    if at != nil and (not is_integer(at) or at < num(get(state, "clock"))),
      do: fault!("invalid_time")

    if not is_list(root) or not is_list(rules), do: fault!("invalid_plan")

    ids = Enum.map(rules, &get(&1, "id"))

    if not Enum.all?(ids, &(is_binary(&1) and &1 =~ ~r/\A[a-z][a-z0-9_-]*\z/)) or
         length(Enum.uniq(ids)) != length(ids),
       do: fault!("invalid_registry")

    ordered = Enum.sort_by(rules, & &1["id"])
    Enum.each(ordered, &check_rule(&1, ids))

    active = get(state, "active")
    if not is_list(active), do: raise!(:type_error)
    if Enum.any?(active, &(is_list(&1) or is_map(&1))), do: raise!(:type_error)
    if Enum.any?(active, &(&1 not in ids)), do: fault!("unknown_subscription")

    Enum.each(root, &check_op(&1, ids))

    c = %{
      state: state,
      limits: limits,
      at: at,
      ordered: ordered,
      events: [],
      deliveries: [],
      queue: :queue.new(),
      writers: %{},
      used: %{}
    }

    c = c |> sequence(root, "root", 0) |> drain()
    state = c.state
    locations = obj!(get(state, "locations"))

    c =
      locations
      |> Map.keys()
      |> Enum.sort()
      |> Enum.reduce(c, fn item, c -> walk(c, locations, item, MapSet.new()) end)

    c =
      state
      |> get("capacities")
      |> obj!()
      # ponytail: key order, not Python's insertion order; same for canonical requests.
      |> Enum.sort()
      |> Enum.reduce(c, fn {container, capacity}, c ->
        c = spend(c, "query_steps", map_size(locations))
        held = Enum.count(Map.values(locations), &(&1 === container))
        if held > num(capacity), do: fault!("capacity_exceeded")
        c
      end)

    result = %{
      "kind" => "accepted",
      "code" => "ok",
      "state" => state,
      "events" => c.events,
      "deliveries" => c.deliveries
    }

    if byte_size(Codec.encode(result)) > limit(c, "output_bytes"),
      do: fault!("budget_output_bytes")

    result
  end

  # ---- plan validation -----------------------------------------------------------

  defp check_rule(rule, ids) do
    if Enum.sort(Map.keys(rule)) != ~w(event guard id ops) or
         not in_set?(rule["event"], ["engine.item_transferred" | @custom]),
       do: fault!("invalid_rule")

    guard = rule["guard"]

    if guard != nil do
      cond do
        not is_map(guard) ->
          fault!("unknown_policy")

        Enum.sort(Map.keys(guard)) != ~w(equals key source) ->
          fault!("unknown_policy")

        not in_set?(guard["source"], ~w(overlay event)) ->
          fault!("unknown_policy")

        not is_binary(guard["key"]) ->
          fault!("unknown_policy")

        guard["source"] == "overlay" and not Map.has_key?(@facts, guard["key"]) ->
          fault!("unknown_policy")

        true ->
          :ok
      end
    end

    if not is_list(rule["ops"]), do: fault!("invalid_plan")
    Enum.each(rule["ops"], &check_op(&1, ids))
  end

  defp check_op(op, ids) do
    if not is_map(op) or not in_set?(Map.get(op, "op"), Map.keys(@fields)),
      do: fault!("unknown_operation")

    kind = op["op"]
    if Enum.sort(Map.keys(op)) != @fields[kind], do: fault!("invalid_operation")

    case kind do
      "fact." <> _ ->
        if not in_set?(op["fact"], Map.keys(@facts)), do: fault!("unknown_fact")
        if kind == "fact.add" and op["fact"] != "count", do: fault!("invalid_operation")
        value = if kind == "fact.set", do: op["value"], else: op["amount"]
        if not is_integer(value), do: fault!("invalid_value")

      "event.emit" ->
        if not in_set?(op["event"], @custom), do: fault!("forbidden_event")
        if not is_map(op["payload"]), do: fault!("invalid_event")

      "subscription.activate" ->
        if not in_set?(op["rule"], ids), do: fault!("unknown_subscription")

      "item.transfer" ->
        if not Enum.all?(~w(item source destination), &(is_binary(op[&1]) and op[&1] != "")),
          do: fault!("invalid_target")

      "job.schedule" ->
        if not (is_binary(op["id"]) and op["id"] != "" and is_integer(op["due"])),
          do: fault!("invalid_job")
    end
  end

  # ---- evaluation ------------------------------------------------------------------

  defp limit(c, key), do: num(c.limits[key])

  defp spend(c, key, count \\ 1) do
    used = Map.get(c.used, key, 0) + count
    if used > limit(c, key), do: fault!("budget_" <> key)
    %{c | used: Map.put(c.used, key, used)}
  end

  defp write(c, target, group) do
    case c.writers do
      %{^target => other} when other != group -> fault!("conflicting_write")
      _ -> %{c | writers: Map.put(c.writers, target, group)}
    end
  end

  defp put_state(c, key, value), do: %{c | state: Map.put(c.state, key, value)}

  defp emit(c, name, payload, depth) do
    c = spend(c, "events")
    if depth > limit(c, "reaction_depth"), do: fault!("budget_reaction_depth")

    event = %{
      "type" => name,
      "payload" => payload,
      "position" => length(c.events) + 1,
      "time" => get(c.state, "clock")
    }

    # Lifecycle eligibility is snapshotted at EMISSION, not delivery.
    eligible =
      Enum.filter(c.ordered, &(&1["event"] == name and &1["id"] in get(c.state, "active")))

    c = spend(c, "query_steps", length(c.ordered))
    events = c.events ++ [event]
    c = %{c | events: events, queue: :queue.in({event, eligible, depth}, c.queue)}

    if byte_size(Codec.encode(events)) > limit(c, "output_bytes"),
      do: fault!("budget_output_bytes")

    c
  end

  defp sequence(c, ops, group, depth),
    do: Enum.reduce(ops, c, &operation(spend(&2, "operations"), &1, group, depth))

  defp operation(c, %{"op" => "fact." <> _ = kind, "fact" => name} = op, group, _depth) do
    c = write(c, {"fact", name}, group)

    value =
      if kind == "fact.set",
        do: op["value"],
        else: num(get(get(c.state, "facts"), name)) + op["amount"]

    {low, high} = @facts[name]
    if value < low or value > high, do: fault!("resource_bounds")
    put_state(c, "facts", Map.put(obj!(get(c.state, "facts")), name, value))
  end

  defp operation(c, %{"op" => "event.emit"} = op, _group, depth),
    do: emit(c, op["event"], op["payload"], depth)

  defp operation(c, %{"op" => "subscription.activate", "rule" => rule}, group, _depth) do
    c = write(c, {"subscription", rule}, group)
    active = get(c.state, "active")
    if rule in active, do: c, else: put_state(c, "active", Enum.sort([rule | active]))
  end

  defp operation(c, %{"op" => "item.transfer", "item" => item} = op, group, depth) do
    c = write(c, {"item", item}, group)
    locations = obj!(get(c.state, "locations"))
    if Map.get(locations, item) !== op["source"], do: fault!("not_owned")

    if op["destination"] not in ["hero", "room"] and
         not Map.has_key?(locations, op["destination"]),
       do: fault!("unknown_destination")

    c = put_state(c, "locations", Map.put(locations, item, op["destination"]))
    payload = %{"item" => item, "from" => op["source"], "to" => op["destination"]}
    emit(c, "engine.item_transferred", payload, depth)
  end

  defp operation(c, %{"op" => "job.schedule", "id" => id, "due" => due}, group, _depth) do
    c = write(c, {"job", id}, group)
    clock = num(get(c.state, "clock"))
    barrier = if c.at == nil, do: clock, else: max(clock, c.at)
    if due <= barrier, do: fault!("nonfuture_job")
    jobs = obj!(get(c.state, "jobs"))
    if Map.has_key?(jobs, id), do: fault!("duplicate_job")
    c = spend(c, "created_jobs")
    jobs = Map.put(jobs, id, due)
    if map_size(jobs) > limit(c, "pending_jobs"), do: fault!("budget_pending_jobs")
    put_state(c, "jobs", jobs)
  end

  defp drain(c) do
    case :queue.out(c.queue) do
      {:empty, _} ->
        c

      {{:value, {event, eligible, depth}}, queue} ->
        %{c | queue: queue}
        |> then(&Enum.reduce(eligible, &1, fn rule, c -> deliver(c, event, rule, depth) end))
        |> drain()
    end
  end

  defp deliver(c, event, rule, depth) do
    c = spend(c, "deliveries")
    guard = rule["guard"]
    c = if guard, do: spend(c, "query_steps"), else: c

    if guard && not guard_holds?(c, event, guard) do
      c
    else
      tag = "#{event["position"]}:#{rule["id"]}"
      c = %{c | deliveries: c.deliveries ++ [tag]}
      sequence(c, rule["ops"], "delivery:" <> tag, depth + 1)
    end
  end

  defp guard_holds?(c, event, %{"source" => source, "key" => key, "equals" => equals}) do
    source = if source == "overlay", do: obj!(get(c.state, "facts")), else: event["payload"]
    Map.has_key?(source, key) and source[key] === equals
  end

  defp walk(c, locations, cursor, visited) do
    if is_list(cursor) or is_map(cursor), do: raise!(:type_error)

    if is_binary(cursor) and Map.has_key?(locations, cursor) do
      c = spend(c, "query_steps")
      if MapSet.member?(visited, cursor), do: fault!("containment_cycle")
      walk(c, locations, locations[cursor], MapSet.put(visited, cursor))
    else
      c
    end
  end
end
