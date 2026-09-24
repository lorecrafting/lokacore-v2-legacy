defmodule LokaR1Harness.Scale do
  @moduledoc """
  Quick R1-A3 scale inputs (owner decision 2026-09-24): one Lantern `world.run`
  initial memory per model and one seeded command stream per model.

  The padding is synthetic. Lantern's `narration` is the one memory field the
  kernels carry through every step without reading its entries (the schema only
  requires a list), so Medium and Stress put their synthetic entities, typed
  facts and pending jobs there. Every step then pays the real whole-state
  copy/encode/hash/persist cost, but nothing exercises bounded work: no reaction
  chains, scenes, fan-out or job scheduling semantics.

  Tiny is the unpadded Lantern initial memory. Bump `@version` whenever the
  output for a given seed changes.
  """

  alias LokaR1Harness.Canonical

  @version "r1-scale-1"
  @volumes %{
    "tiny" => {0, 0, 0},
    "medium" => {300, 100, 100},
    "stress" => {1000, 200, 1000}
  }
  @rooms ~w(landing green reed_bank shelter)
  @exits %{
    "landing" => %{"north" => "green"},
    "green" => %{"south" => "landing", "east" => "reed_bank"},
    "reed_bank" => %{"west" => "green", "east" => "shelter"},
    "shelter" => %{"west" => "reed_bank"}
  }
  @words ~w(moss reed lantern damp cedar ember stone river heron mist copper thorn
            hollow salt ash willow bell ferry owl rope tallow flint marsh pine)

  def version, do: @version
  def models, do: ~w(tiny medium stress)

  @doc "`%{version, seed, model, world, volumes, warmup, measured, initial, commands}`."
  def input(model, seed, warmup \\ 1000, measured \\ 2000) do
    {entities, facts, jobs} = Map.fetch!(@volumes, model)
    {pad, _} = padding(:rand.seed_s(:exsss, seed), entities, facts, jobs)
    # Commands draw from their own stream, so every model gets the same commands.
    {commands, _} = commands(:rand.seed_s(:exsss, seed + 1), warmup + measured)

    %{
      "version" => @version,
      "seed" => seed,
      "model" => model,
      "world" => "lantern",
      "volumes" => %{"entities" => entities, "facts" => facts, "jobs" => jobs},
      "warmup" => warmup,
      "measured" => measured,
      "initial" => Map.put(lantern_initial(), "narration", pad),
      "commands" => commands
    }
  end

  @doc "One canonical JSON line per model."
  def lines(seed), do: Enum.map(models(), &Canonical.encode(input(&1, seed)))

  # Lantern's initial memory (lantern_model.py), written here from the contract,
  # not read from a kernel.
  defp lantern_initial do
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

  # ---- padding ------------------------------------------------------------------

  defp padding(r, e, f, j) do
    {es, r} = many(r, e, &entity/2)
    {fs, r} = many(r, f, &fact/2)
    {js, r} = many(r, j, &job(&1, &2, e))
    {es ++ fs ++ js, r}
  end

  defp many(r, 0, _), do: {[], r}
  defp many(r, n, fun), do: Enum.map_reduce(1..n, r, fn i, r -> fun.(i, r) end)

  defp id(kind, i), do: "syn:#{kind}:" <> String.pad_leading(Integer.to_string(i), 4, "0")

  defp entity(i, r) do
    {room, r} = pick(r, @rooms)
    {name, r} = words(r, 2)
    {desc, r} = words(r, 32)
    {tags, r} = Enum.map_reduce(1..4, r, fn _, r -> pick(r, @words) end)
    {stats, r} = Enum.map_reduce(~w(hp str dex int wis level), r, fn k, r -> num(r, k) end)
    {inv, r} = Enum.map_reduce(1..3, r, fn _, r -> int(r, 1, 1000) end)
    {hostile, r} = int(r, 0, 1)
    {rev, r} = int(r, 0, 500)

    {%{
       "id" => id("entity", i),
       "kind" => "synthetic_entity",
       "proto" => "proto:" <> hd(tags),
       "room" => room,
       "name" => name,
       "desc" => desc,
       "tags" => tags,
       "stats" => Map.new(stats),
       "inventory" => Enum.map(inv, &id("entity", &1)),
       "flags" => %{"hostile" => hostile == 1, "visible" => true},
       "rev" => rev
     }, r}
  end

  defp fact(i, r) do
    {subject, r} = int(r, 1, 1000)
    {value, r} = int(r, -1000, 1000)
    {note, r} = words(r, 8)

    {%{
       "id" => id("fact", i),
       "kind" => "synthetic_fact",
       "type" => "int",
       "key" => "fact.#{hd(String.split(note))}.#{i}",
       "subject" => id("entity", subject),
       "value" => value,
       "note" => note
     }, r}
  end

  defp job(i, r, entities) do
    {due, r} = int(r, 6, 23)
    {target, r} = int(r, 1, max(entities, 1))
    {op, r} = pick(r, ~w(tick move spawn expire notify))
    {args, r} = words(r, 6)

    {%{
       "id" => id("job", i),
       "kind" => "synthetic_job",
       "due" => due,
       "op" => op,
       "target" => id("entity", target),
       "args" => args,
       "attempts" => 0,
       "state" => "pending"
     }, r}
  end

  defp num(r, k) do
    {v, r} = int(r, 1, 100)
    {{k, v}, r}
  end

  defp words(r, n) do
    {ws, r} = Enum.map_reduce(1..n, r, fn _, r -> pick(r, @words) end)
    {Enum.join(ws, " "), r}
  end

  # ---- commands -----------------------------------------------------------------

  # Envelope §3 per 1,000 inputs, with the Tiny substitution (five looks and five
  # talks for the reaction and scene inputs, which the Lantern kernel doesn't have):
  # look 305, move 350, take/drop 100 (20 exact duplicate deliveries and 5 altered
  # intents), talk/choose 155 (activate, talk, choose, close_choice; stale views),
  # wait 90. Rooms and the lantern are tracked from the contract's exits so most
  # moves and some takes/drops are legal; the host classifies the actual outcome.
  defp commands(r, n) do
    ctx = %{
      n: 0,
      room: "landing",
      lantern: "shelter",
      clock: 6,
      rev: 0,
      history: [],
      talks: []
    }

    {cmds, {_ctx, r}} =
      Enum.map_reduce(1..n, {ctx, r}, fn _, {ctx, r} ->
        {cls, r} = int(r, 1, 1000)
        {req, ctx, r} = request(cls, ctx, r)
        {%{"op" => "invoke", "request" => req}, {ctx, r}}
      end)

    {cmds, r}
  end

  defp request(c, ctx, r) when c <= 305, do: fresh(ctx, r, "look", %{})

  defp request(c, ctx, r) when c <= 655 do
    {legal, r} = int(r, 1, 100)
    exits = Map.keys(@exits[ctx.room])
    {dir, r} = if legal <= 85, do: pick(r, exits), else: pick(r, ~w(up north south) -- exits)
    dir = dir || "up"
    ctx = if Map.has_key?(@exits[ctx.room], dir), do: %{ctx | room: @exits[ctx.room][dir]}, else: ctx
    fresh(ctx, r, "move", %{"direction" => dir})
  end

  defp request(c, ctx, r) when c <= 675 and ctx.history != [] do
    {prior, r} = pick(r, ctx.history)
    {prior, ctx, r}
  end

  defp request(c, ctx, r) when c <= 680 and ctx.history != [] do
    {prior, r} = pick(r, ctx.history)
    {Map.put(prior, "action", if(prior["action"] == "take", do: "drop", else: "take")), ctx, r}
  end

  defp request(c, ctx, r) when c <= 755 do
    cond do
      ctx.lantern == "hero" -> fresh(%{ctx | lantern: ctx.room}, r, "drop", %{})
      ctx.lantern == ctx.room -> fresh(%{ctx | lantern: "hero"}, r, "take", %{})
      true -> fresh(ctx, r, "take", %{})
    end
  end

  defp request(c, ctx, r) when c <= 910 do
    {k, r} = int(r, 1, 100)

    cond do
      k <= 30 ->
        fresh(ctx, r, "activate", %{})

      k <= 60 ->
        fresh(ctx, r, "talk", %{})

      k <= 70 ->
        fresh(ctx, r, "close_choice", %{})

      true ->
        {choice, r} = pick(r, ~w(carry leave))
        cont = "proof-choice:" <> (List.first(ctx.talks) || "none")
        {req, ctx, r} = fresh(ctx, r, "choose", %{"choice_id" => choice, "continuation_id" => cont})
        {stale, r} = int(r, 1, 100)
        {if(stale <= 20, do: Map.put(req, "view", "view:0"), else: req), ctx, r}
    end
  end

  defp request(_c, ctx, r) do
    until = ctx.clock + 1
    fresh(%{ctx | clock: min(until, 23)}, r, "wait", %{"until" => until})
  end

  defp fresh(ctx, r, action, input) do
    id = "a#{ctx.n}"
    req = %{"id" => id, "actor" => "hero", "action" => action, "input" => input}
    talks = if action == "talk", do: [id | ctx.talks], else: ctx.talks
    history = if action in ~w(take drop), do: Enum.take([req | ctx.history], 16), else: ctx.history
    {req, %{ctx | n: ctx.n + 1, talks: talks, history: history}, r}
  end

  # ---- rand ---------------------------------------------------------------------

  defp int(r, lo, hi) do
    {x, r} = :rand.uniform_s(hi - lo + 1, r)
    {lo + x - 1, r}
  end

  defp pick(r, []), do: {nil, r}

  defp pick(r, list) do
    {i, r} = int(r, 0, length(list) - 1)
    {Enum.at(list, i), r}
  end
end
