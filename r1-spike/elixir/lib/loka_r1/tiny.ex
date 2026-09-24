defmodule LokaR1.Tiny do
  @moduledoc "`ContractModel._decide` of `checks/contract_model.py`, credit policy `event` or `state`."
  import LokaR1.Py, only: [get: 2, eq: 2, num: 1, truthy?: 1, raise!: 1]

  @fields %{
    "look" => [],
    "activate" => [],
    "move" => ["direction"],
    "take" => [],
    "drop" => [],
    "wait" => ["until"],
    "choose" => ["choice_id", "continuation_id"]
  }
  @exits %{"landing" => %{"north" => "green"}, "green" => %{"south" => "landing"}}

  def initial do
    %{
      "revision" => 0,
      "room" => "landing",
      "lantern" => "green",
      "quest" => "absent",
      "arrived" => false,
      "clock" => 6,
      "bram_room" => "landing",
      "job_pending" => true,
      "rng" => [1, 2, 3, 4],
      "choice" => nil,
      "outcome" => nil
    }
  end

  def decide(credit, s, request) do
    action = request["action"]
    payload = Map.get(request, "input", %{})

    case @fields do
      %{^action => fields} when map_size(payload) == length(fields) ->
        if Enum.all?(fields, &Map.has_key?(payload, &1)),
          do: act(action, credit, s, payload),
          else: reject(s, "invalid_input")

      _ ->
        reject(s, "invalid_input")
    end
  end

  def reject(s, code), do: {s, code, [], false}

  @doc "`state[\"revision\"] += 1` and accept."
  def accept(s, code, events),
    do: {Map.put(s, "revision", num(get(s, "revision")) + 1), code, events, true}

  @doc "`exits[state[\"room\"]].get(direction)`; an unknown room is a KeyError."
  def exit(exits, room, direction) do
    if is_list(room) or is_map(room), do: raise!(:type_error)

    case exits do
      %{^room => from} -> from[direction]
      _ -> raise!(:key_error)
    end
  end

  defp act("look", _, s, _), do: {s, "observed", [], true}

  defp act("activate", credit, s, _) do
    if not eq(get(s, "quest"), "absent") or not eq(get(s, "room"), get(s, "bram_room")) do
      reject(s, "not_eligible")
    else
      s = Map.put(s, "quest", "active")

      if credit == "state" and eq(get(s, "lantern"), "hero") do
        s =
          Map.merge(s, %{"quest" => "resolved", "arrived" => true, "choice" => "lantern-offer-1"})

        accept(s, "activated", ["quest_activated", "quest_resolved", "fact_changed"])
      else
        accept(s, "activated", ["quest_activated"])
      end
    end
  end

  defp act("move", _, s, %{"direction" => direction}) do
    cond do
      not is_binary(direction) ->
        reject(s, "invalid_input")

      dest = exit(@exits, get(s, "room"), direction) ->
        accept(%{s | "room" => dest}, "moved", ["entity_entered_room"])

      true ->
        reject(s, "no_exit")
    end
  end

  defp act("take", _, s, _) do
    if not eq(get(s, "lantern"), get(s, "room")) do
      reject(s, "not_present")
    else
      {roll, rng} =
        case LokaR1.Numeric.uniform(get(s, "rng"), 100, 1024) do
          {:ok, roll, rng} -> {roll, rng}
          {:error, _} -> raise!(:value_error)
        end

      s = Map.put(s, "rng", rng)

      cond do
        roll >= 50 ->
          accept(s, "check_failed", ["check_failed"])

        eq(get(s, "quest"), "active") ->
          s =
            Map.merge(s, %{
              "lantern" => "hero",
              "quest" => "resolved",
              "arrived" => true,
              "choice" => "lantern-offer-1"
            })

          accept(s, "taken", ["check_passed", "item_acquired", "quest_resolved", "fact_changed"])

        true ->
          accept(Map.put(s, "lantern", "hero"), "taken", ["check_passed", "item_acquired"])
      end
    end
  end

  defp act("choose", _, s, %{"choice_id" => choice_id, "continuation_id" => continuation}) do
    if get(s, "choice") == nil or not eq(continuation, get(s, "choice")) or
         choice_id not in ["carry", "leave"] do
      reject(s, "invalid_choice")
    else
      accept(%{s | "choice" => nil} |> Map.put("outcome", choice_id), "choice_completed", [
        "choice_completed"
      ])
    end
  end

  defp act("drop", _, s, _) do
    if eq(get(s, "lantern"), "hero"),
      do: accept(Map.put(s, "lantern", get(s, "room")), "dropped", ["item_dropped"]),
      else: reject(s, "not_owned")
  end

  defp act("wait", _, s, %{"until" => until}) do
    if not is_integer(until) or not (num(get(s, "clock")) < until and until <= 48) do
      reject(s, "invalid_time")
    else
      s = Map.put(s, "clock", until)

      if truthy?(get(s, "job_pending")) and until >= 19,
        do:
          accept(Map.merge(s, %{"bram_room" => "green", "job_pending" => false}), "waited", [
            "schedule_completed"
          ]),
        else: accept(s, "waited", [])
    end
  end
end
