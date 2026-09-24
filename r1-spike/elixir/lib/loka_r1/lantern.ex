defmodule LokaR1.Lantern do
  @moduledoc "`LanternModel._decide` of `checks/lantern_model.py`: events are `[code]` on acceptance."
  import LokaR1.Py, only: [get: 2, eq: 2, num: 1, truthy?: 1, raise!: 1]
  import LokaR1.Tiny, only: [reject: 2, exit: 3]

  @fields %{
    "look" => [],
    "activate" => [],
    "move" => ["direction"],
    "take" => [],
    "drop" => [],
    "talk" => [],
    "choose" => ["choice_id", "continuation_id"],
    "close_choice" => [],
    "wait" => ["until"]
  }
  @exits %{
    "landing" => %{"north" => "green"},
    "green" => %{"south" => "landing", "east" => "reed_bank"},
    "reed_bank" => %{"west" => "green", "east" => "shelter"},
    "shelter" => %{"west" => "reed_bank"}
  }

  def initial do
    %{
      "revision" => 0,
      "room" => "landing",
      "lantern" => "shelter",
      "quest" => "absent",
      "choice" => nil,
      "search_plan" => "undecided",
      "clock" => 6,
      "bram_room" => "landing",
      "rng" => [1, 2, 3, 4],
      "narration" => [],
      "milestone" => nil
    }
  end

  def decide(s, request) do
    action = request["action"]
    payload = Map.get(request, "input", %{})

    case @fields do
      %{^action => fields} when map_size(payload) == length(fields) ->
        if Enum.all?(fields, &Map.has_key?(payload, &1)),
          do: act(action, s, payload, request),
          else: reject(s, "invalid_input")

      _ ->
        reject(s, "invalid_input")
    end
  end

  defp accept(s, code), do: LokaR1.Tiny.accept(s, code, [code])

  defp act("look", s, _, _), do: {s, "observed", [], true}

  defp act("activate", s, _, _) do
    cond do
      not eq(get(s, "quest"), "absent") or not eq(get(s, "room"), get(s, "bram_room")) ->
        reject(s, "not_eligible")

      eq(get(s, "lantern"), "hero") ->
        accept(Map.put(s, "quest", "active"), "activated_with_possession")

      true ->
        accept(Map.put(s, "quest", "active"), "activated")
    end
  end

  defp act("move", s, %{"direction" => direction}, _) do
    cond do
      not is_binary(direction) -> reject(s, "invalid_input")
      dest = exit(@exits, get(s, "room"), direction) -> accept(%{s | "room" => dest}, "moved")
      true -> reject(s, "exit_unavailable")
    end
  end

  defp act("take", s, _, _) do
    if eq(get(s, "lantern"), get(s, "room")),
      do: accept(Map.put(s, "lantern", "hero"), "taken"),
      else: reject(s, "not_present")
  end

  defp act("drop", s, _, _) do
    if eq(get(s, "lantern"), "hero"),
      do: accept(Map.put(s, "lantern", get(s, "room")), "dropped"),
      else: reject(s, "not_owned")
  end

  defp act("talk", s, _, request) do
    cond do
      not eq(get(s, "quest"), "active") or not eq(get(s, "room"), get(s, "bram_room")) ->
        reject(s, "not_eligible")

      not eq(get(s, "lantern"), "hero") ->
        reject(s, "not_owned")

      true ->
        # Reopening a still-pending choice does not mint a new occurrence.
        choice = get(s, "choice")
        choice = if truthy?(choice), do: choice, else: "proof-choice:" <> request["id"]
        accept(Map.put(s, "choice", choice), "choice_opened")
    end
  end

  defp act("choose", s, %{"choice_id" => choice_id, "continuation_id" => continuation}, _) do
    cond do
      get(s, "choice") == nil or not eq(continuation, get(s, "choice")) or
          choice_id not in ["carry", "leave"] ->
        reject(s, "invalid_choice")

      not eq(get(s, "lantern"), "hero") ->
        reject(s, "not_owned")

      not eq(get(s, "room"), get(s, "bram_room")) ->
        reject(s, "not_present")

      true ->
        occurrence = get(s, "choice")
        narration = get(s, "narration")
        if not is_list(narration), do: raise!(:attribute_error)
        if not is_binary(occurrence), do: raise!(:type_error)

        line = %{
          "id" => occurrence <> ":outcome",
          "text_key" => "proof." <> choice_id,
          "bindings" => %{"actor" => "hero", "bram" => "bram", "lantern" => "lantern"}
        }

        s =
          Map.merge(s, %{
            "quest" => "resolved",
            "choice" => nil,
            "search_plan" => if(choice_id == "carry", do: "player_led", else: "party_led"),
            "narration" => narration ++ [line],
            "milestone" => %{
              "key" => "proof.terminal",
              "occurrence" => occurrence,
              "outcome" => choice_id
            }
          })

        s = if choice_id == "leave", do: Map.put(s, "lantern", "bram"), else: s
        accept(s, "resolved_" <> choice_id)
    end
  end

  defp act("close_choice", s, _, _) do
    if get(s, "choice") == nil,
      do: reject(s, "invalid_choice"),
      else: accept(Map.put(s, "choice", nil), "choice_closed")
  end

  defp act("wait", s, %{"until" => until}, _) do
    if not is_integer(until) or not (num(get(s, "clock")) < until and until <= 23) do
      reject(s, "invalid_time")
    else
      s =
        Map.merge(s, %{
          "clock" => until,
          "bram_room" => if(until < 19, do: "landing", else: "green")
        })

      accept(s, "waited")
    end
  end
end
