# 00a — Chapter One Content Specification: The Missing Child

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Product scope: chapter one.

Review the 57-room content, manifest, quests and scenarios. YAML field shapes remain illustrative until their schema gate.

<details>
<summary>Sections in this document</summary>

- [1. Manifest](#1-manifest)
- [2. Rooms](#2-rooms)
- [3. Activation groups](#3-activation-groups)
- [4. NPCs](#4-npcs)
- [5. Items](#5-items)
- [6. Facts](#6-facts)
- [7. Quests](#7-quests)
- [8. Dialogue](#8-dialogue)
- [9. Scenes](#9-scenes)
- [10. Reactions](#10-reactions)
- [11. Chapter-one certification](#11-chapter-one-certification)
- [12. Hello-world fixture](#12-hello-world-fixture)

</details>
<!-- packet-navigation:end -->

**Status:** Draft 0.1 — exact content for the R10 cartridge, chapter one of The Fox of Ashmere. Prose is placeholder; structure is the deliverable.
**Purpose:** be the thing the compiler compiles. Every room, NPC, item, fact, quest, and scene here is real content the R4 compiler, R5–R8 capabilities, and R9 minimum gates are built against. §12 is the hello-world subset used as the first R4 fixture.
**Reads with:** `00-first-cartridge-design.md` §11 (the ladder), `05-cartridges-content-capabilities.md` (envelope formats), `06-quests-dialogue-actions-scripting.md` (quest and dialogue grammar), `09-cartridge-lab-certification.md` §1a (the gates this content must pass).

YAML below uses the packet's envelope conventions. Field names are illustrative until R3 freezes them; the compiler, not this document, is the schema authority.

## 1. Manifest

```yaml
api_version: loka/v3
id: ashmere_1_the_missing_child
version: 1.0.0
title: The Fox of Ashmere — Chapter One: The Missing Child
campaign: the_fox_of_ashmere
chapter: 1

requires:
  kernel_api: ">=1.0 <2.0"
  content_schema: 1
  rule_ir: 1
  capabilities:
    - movement@1
    - barrier@1
    - containment@1
    - equipment@1
    - inspectable_detail@1
    - description_variant@1
    - target_resolution@1
    - policy@1
    - fact@1
    - resource@1
    - attributes@1
    - position@1
    - skills@1
    - status@1
    - check@1
    - combat@1
    - death@1
    - quest@1
    - dialogue@1
    - scene@1
    - action_recipe@1
    - reaction@1
    - behavior@1
    - schedule@1
    - population@1
    - commerce@1
    - service@1
    - calendar@1
    - tide@1
    - light@1
    - liquid@1
    - readable@1
    - topics@1
    - relationship@1
    - faction@1
    - narration@1
    - sense_cue@1
  client_features:
    - contextual_actions_v1
    - dialogue_choices_v1
    - paper_doll_v1
    - compass_six_v1
    - letter_bank_v1

supported_profiles:
  - offline_private

time_policy: play_time

activation_groups:
  active:
    - chapter_1_base
  inactive:
    - crypt_open        # chapter 2
    - priory_gate_open  # chapter 2
    - kings_road_open   # chapter 3

entry:
  room: rooms/ferry_landing

continuity:
  exports:
    - memory.village_ending
    - memory.fox_fate
    - memory.chapter_1_guild_tilt
  character:
    mode: campaign
    schema: ashmere_character_v1

locales:
  default: en
  available: [en]
```

Every capability listed is portable. No `server_only` capability appears; compilation for `offline_private` rejects any.

## 2. Rooms

Fifty-seven rooms. `z` is the vertical level. Exits list the six directions used; every listed exit has its reciprocal in the target room. Tags drive terrain cost, light, water, and indoor/outdoor rules. Details are InspectableDetails that are targetable but not entities.

### Ashmere (25)

| Key | z | Exits | Tags | Details / notes |
|---|---|---|---|---|
| ferry_landing | 0 | n well_lane, w boathouse, s reed_path | outdoor, dock | mooring post, tide marks (tide variant), notice nailed to post (readable) |
| boathouse | 0 | e ferry_landing, s old_mill | indoor | Bram's ferry (transport → fen_isle_landing, fare 2p), oars, nets |
| old_mill | 0 | n boathouse, s empty_cottage, u mill_loft, d mill_cellar | indoor | millstone, Hob's ledger (readable), grain sacks |
| mill_loft | 1 | d old_mill | indoor, dark | owl, loose board (ch2 ghost quest foreshadow) |
| mill_cellar | -1 | u old_mill | indoor, dark | grain bins, rat holes |
| empty_cottage | 0 | n old_mill, u cottage_loft | indoor | for-sale sign (readable), cold hearth |
| cottage_loft | 1 | d empty_cottage | indoor | bare rafters |
| well_lane | 0 | n village_green, s ferry_landing, w chandler, e drowned_lantern, d well_shaft | outdoor | the well (fill waterskin), bucket, worn steps |
| well_shaft | -1 | u well_lane, d well_bottom, e(H) lantern_cellar | dark | ladder, damp stones, hidden door (PER) |
| well_bottom | -2 | u well_shaft | dark, water | sunken lantern, old coin, carved initials (ch2 foreshadow) |
| chandler | 0 | e well_lane, d chandler_storeroom | indoor, shop | counter, shelves, price board (readable) |
| chandler_storeroom | -1 | u chandler | indoor, dark | crates, oil casks |
| drowned_lantern | 0 | w well_lane, u inn_rooms, d lantern_cellar | indoor, inn | hearth, rumor board (readable), Maud's bar |
| inn_rooms | 1 | d drowned_lantern, u inn_attic | indoor | beds (rest), window over the green |
| inn_attic | 2 | d inn_rooms | indoor, dark | dust, a trunk, hidden exit from inn_rooms (PER) |
| lantern_cellar | -1 | u drowned_lantern, w(H) well_shaft | indoor, dark | ale casks, rat holes, hidden door |
| village_green | 0 | n north_gate, s well_lane, w smithy, e east_gate | outdoor | the old elm, stocks, market cross (variant by child_status and dawn scene) |
| smithy | 0 | e village_green, w orchard | indoor | forge (cold in ch1), anvil, Gareth's tools |
| orchard | 0 | e smithy | outdoor | apple trees (forage, seasonal variant), beehive |
| east_gate | 0 | w village_green | outdoor | gate, flooded road sign (readable; `kings_road_open` adds e kings_road_west) |
| north_gate | 0 | s village_green, n chapel_steps, w elspeth_cottage, e watch_post | outdoor | gate (Barrier: open by day, closed at night unless Tobin trusts you) |
| elspeth_cottage | 0 | e north_gate | indoor | Wren's cot, the lantern (item), hearth |
| watch_post | 0 | w north_gate, e watch_cell, u gate_tower | indoor | Tobin's bench, horn, duty roster (readable) |
| watch_cell | 0 | w watch_post | indoor | locked door (Barrier, key with Tobin), straw |
| gate_tower | 1 | d watch_post | outdoor, view | parapet; scan shows green, gate, chapel steps |

### The Fen (22)

| Key | z | Exits | Tags | Details / notes |
|---|---|---|---|---|
| reed_path | 0 | n ferry_landing, s reed_bank | outdoor, fen | reeds, fox prints (detail, first clue) |
| reed_bank | 0 | n reed_path, w willow_shade, e hound_run, s mire_crossing | outdoor, fen | the tracks (Q2 discovery), Wren's boot (item) |
| willow_shade | 0 | e reed_bank, s drowned_oak | outdoor, fen | willows, herb node: fenwort |
| hound_run | 0 | w reed_bank, e adder_nest, s marsh_light | outdoor, fen | hound population home, gnawed bones |
| adder_nest | 0 | w hound_run | outdoor, fen | adders (ch2 population; empty nest in ch1), herb node: marsh lily |
| drowned_oak | 0 | n willow_shade, e mire_crossing, s black_pool, u oak_branches | outdoor, fen | the oak, crow droppings, herb node: oak moss |
| oak_branches | 1 | d drowned_oak, u oak_crown | outdoor | crow nest (container: scavenged items) |
| oak_crown | 2 | d oak_branches | outdoor, view | scan shows marsh_light; wisp visible by day |
| mire_crossing | 0 | n reed_bank, w drowned_oak, e marsh_light, s fox_hollow | outdoor, fen, water, tide | plank (passable low tide; swim at high) |
| marsh_light | 0 | n hound_run, w mire_crossing, s old_causeway | outdoor, fen, dark | the wisp (NPC, night only), herb node: ghostcap |
| old_causeway | 0 | n marsh_light, e tide_flats | outdoor, fen | stones, carved fox (detail, topic: ward) |
| tide_flats | 0 | w old_causeway | outdoor, fen, water, tide | shells, the fox charm (item, low tide only) |
| black_pool | 0 | n drowned_oak, e fox_hollow, s fishing_shallows, d pool_bottom | outdoor, fen, water | still water, drowned tree |
| pool_bottom | -1 | u black_pool | dark, water | sunken chest (container: silver ring, ch2 material foreshadow) |
| fox_hollow | 0 | n mire_crossing, w black_pool, d fox_den_deep | outdoor, fen | the hollow, fox bones, Vesper (NPC), Wren (NPC) |
| fox_den_deep | -1 | u fox_hollow | dark | the ward stone (detail, topic: bell), Vesper's message (readable) |
| fishing_shallows | 0 | n black_pool | outdoor, fen, water | reeds; items dropped in water surface here next day |
| fen_isle_landing | 0 | e isle_hut, s isle_shrine | outdoor, isle | ferry mooring (transport ↔ boathouse) |
| isle_hut | 0 | w fen_isle_landing, e herb_garden, u hut_loft | indoor | Sedge's hearth, drying racks, brewing pot (ch2) |
| hut_loft | 1 | d isle_hut | indoor, dark | bundled herbs, a fox pelt (topic) |
| herb_garden | 0 | w isle_hut | outdoor | herb nodes: fenwort, marsh lily |
| isle_shrine | 0 | n fen_isle_landing | outdoor, sanctuary | the shrine (respawn point, pray recipe), standing stone (portal inactive in ch1) |

### Thornwick Priory, public rooms (10)

| Key | z | Exits | Tags | Details / notes |
|---|---|---|---|---|
| chapel_steps | 0 | s north_gate, n chapel_nave | outdoor | worn steps, alms bowl |
| chapel_nave | 0 | s chapel_steps, w prior_study, n cloister, u bell_tower | indoor, sanctuary | the fresco (detail, topic: ward), altar (respawn point) ; `crypt_open` adds d crypt |
| prior_study | 0 | e chapel_nave | indoor | Aldric's desk, the tithe ledger (S2 item), bell rope key |
| bell_tower | 1 | d chapel_nave, u belfry | indoor, dark | stair, pigeon feathers |
| belfry | 2 | d bell_tower, u spire | indoor | the bell (detail, ring_bell recipe), the rope |
| spire | 3 | d belfry | outdoor, view | scan shows all of Ashmere z0 and reed_path |
| cloister | 0 | s chapel_nave, w scriptorium, e infirmary | outdoor | herb beds, sundial (time detail) ; `priory_gate_open` adds n priory_gate |
| scriptorium | 0 | e cloister, w kitchen_garden | indoor | books (readables: The Ward of the Fen, Bell Rites), Ash's desk |
| kitchen_garden | 0 | e scriptorium | outdoor | herb node: rue, Hale weeding |
| infirmary | 0 | w cloister | indoor | Wick's cots, bandage roll (item), cure cabinet |

## 3. Activation groups

| Group | Chapter | Adds |
|---|---|---|
| chapter_1_base | 1 | everything above |
| crypt_open | 2 | exit chapel_nave d crypt; rooms crypt, ossuary |
| priory_gate_open | 2 | exit cloister n priory_gate; room priory_gate; Barrow Downs |
| kings_road_open | 3 | exit east_gate e kings_road_west; King's Road and Harrowgate |

The compiler evaluates reachability per manifest-active group set. Rooms in inactive groups are excluded from the chapter's artifact, so chapter one's `orphan_room` check runs over exactly 57 rooms.

## 4. NPCs

Sixteen named NPCs in chapter one. Schedules are hour ranges in world time; profile names are role-state-machine states.

| Key | Name | Home | Schedule | Profiles | Trainer / shop |
|---|---|---|---|---|---|
| bram | Old Bram | ferry_landing | 6–19 landing; 19–23 drowned_lantern; 23–6 boathouse | worried, thankful, grieving | — |
| elspeth | Elspeth | elspeth_cottage | searching: 6–21 village_green, 21–6 cottage; relieved: 7–12 orchard, 12–18 cottage, 18–21 green; grieving: cottage always | searching, relieved, grieving | — |
| wren | Wren | fox_hollow | stays until rescued; follows player during escort; cottage after | with_fox, escorted, home | — |
| aldric | Prior Aldric | prior_study | 6–17 nave/study; 17–19 belfry; 19–6 study | welcoming, cold | spell word: light (ch1 teaches one word only) |
| maud | Widow Maud | drowned_lantern | always | — | inn: food, drink, room |
| peg | Peg Harrow | chandler | 7–19 chandler; 19–7 chandler_storeroom | — | shop: general; trainer: haggle |
| gareth | Gareth | smithy | 8–18 smithy; 18–22 drowned_lantern; 22–8 smithy | — | — (flavor; repair in ch3) |
| tobin | Tobin | watch_post | 6–18 watch_post; 18–6 patrol north_gate → watch_post → village_green → east_gate | — | trainer: swords, dodge |
| hob | Hob | old_mill | 6–18 old_mill; 18–6 mill_loft | — | — (ghost quest in ch2) |
| ada | Goodwife Ada | orchard | 7–17 orchard; 17–7 elspeth_cottage (neighbor) | — | — |
| sedge | Mother Sedge | isle_hut | 6–20 herb_garden/isle_hut; 20–6 isle_hut | wary, warm, hostile | trainer: herbalism, swim |
| wick | Brother Wick | infirmary | 6–21 infirmary; 21–6 cloister | — | trainer: bandage; healer |
| ash | Novice Ash | scriptorium | 6–12 scriptorium; 12–18 cloister; 18–6 scriptorium | — | — |
| hale | Novice Hale | kitchen_garden | 6–18 kitchen_garden; 18–6 cloister | — | — |
| vesper | Vesper | fox_hollow | 20–6 fox_hollow; 6–20 fox_den_deep | guarded, allied, bound | — |
| wisp | the marsh light | marsh_light | 20–6 marsh_light; 6–20 absent (visible from oak_crown only) | — | — |

Two novices in the same room from 12–18 is the target-ambiguity fixture.

> **Open content reconciliation:** the table puts Ash in the cloister at 14:00 but Hale in the kitchen garden, while §11 requires both novices in the cloister at 14:00. Choose a schedule or fixture-time/location correction before certifying that scenario; this housekeeping pass does not change either NPC's intended schedule.

### Populations

| Plan | Bundle | Area | Count | Scope | Respawn | Behavior |
|---|---|---|---|---|---|---|
| fen_hounds | hound + pelt loot | hound_run, reed_bank, mire_crossing, marsh_light at night | 4 (6 at night) | instance | 1 world day | wander bounded to fen; aggressive 20–6; flee below 25% HP; assist pack |
| deer | deer + hide loot | willow_shade, drowned_oak, orchard | 3 | instance | 2 world days | wander; flee on sight |
| crows | crow | drowned_oak, oak_branches, village_green | 4 | instance | 1 world day | wander; scavenge shiny items to oak_branches |
| cellar_rats | rat | lantern_cellar, mill_cellar | 5 | instance | none (S1 clears them) | aggressive when cornered |

## 5. Items

Forty-one definitions. Slots use the 14-slot model; chapter one fills nine of them.

| Key | Kind | Slot / use | Where | Notes |
|---|---|---|---|---|
| lantern | light | light slot | elspeth_cottage | 8 h burn, refills with oil |
| torch | light | light slot | chandler (3p) | 2 h burn |
| lamp_oil | consumable | refill lantern | chandler (2p) | stack |
| waterskin | liquid container | drink | chandler (4p) | fill at well, black_pool |
| ale_mug | liquid container | drink | drowned_lantern (1p) | `drunk` status at 3 |
| bread, smoked_fish, apple | food | eat | maud, orchard | hunger |
| bandage | consumable | bandage recipe | infirmary, chandler (2p) | stops bleeding |
| fenwort, marsh_lily, oak_moss, ghostcap, rue | herb | S9 | nodes | stack; regrow 2 days |
| rusty_sword, iron_sword | weapon | wield | Tobin gives rusty; chandler sells iron (40p) | slash |
| fishing_knife | weapon | wield / off-hand | chandler (8p) | pierce; skinning |
| wooden_shield | shield | off-hand | chandler (15p) | block |
| leather_cap, leather_jerkin, leather_boots, wool_cloak, wool_gloves, wool_leggings | armor | head, body, feet, cloak, hands, legs | chandler | cloak negates `wet` chill |
| fox_charm | unique | neck | tide_flats, low tide | topic: charm; S7 in ch2 |
| wrens_boot | unique quest | carry | reed_bank | Q2 evidence; ambiguity fixture with `leather_boots` |
| tithe_ledger | readable quest | carry | prior_study → S2 | timed courier |
| vespers_message | readable | carry | fox_den_deep | grants topic: ward |
| bell_rope_key | key | unlock belfry rope | aldric gives in Q3 | |
| cellar_key | key | unlock lantern_cellar | maud gives in S1 | |
| watch_cell_key | key | watch_cell | tobin | |
| ferry_token | token | free ferry | bram at trust ≥ 10 | |
| old_coin, silver_ring | valuables | sell / ch2 | well_bottom, pool_bottom | silver material foreshadow |
| ward_of_the_fen, bell_rites | readable books | scriptorium | grants topics: ward, bell | |
| pennies | currency | — | start 20 | integer |

## 6. Facts

All chapter-one facts. Scope is `player` unless the truth belongs to the world.

| Key | Type | Scope | Default | Set by |
|---|---|---|---|---|
| village.arrived | bool | instance | false | Q1 |
| village.child_status | enum missing/rescued/lost | instance | missing | Q2 outcomes |
| chapel.allegiance | enum unknown/prior/fox | instance | unknown | Q3 |
| chapel.bell_rung | bool | instance | false | ring_bell |
| fen.tracks_found | bool | player | false | reed_bank discovery |
| fen.wisp_answered | bool | player | false | S4 |
| fen.night_survived | bool | player | false | S27 |
| inn.cellar_cleared | bool | instance | false | S1 |
| priory.tithe_delivered | enum pending/on_time/late/never | instance | pending | S2 |
| watch.gate_trusts_player | bool | player | false | S3 |
| player.slept_at_lantern | bool | player | false | S10 |
| player.dream_seen | bool | player | false | S10 scene |
| faction.priory_fen | int −10..10 | player | 0 | consequences (single axis in ch1) |
| relationship.bram.trust, .elspeth.trust, .vesper.trust, .sedge.trust | int | player | 0 | consequences |
| memory.village_ending, memory.fox_fate, memory.chapter_1_guild_tilt | export | player | — | dawn scene |

## 7. Quests

Ten quests. Grammar per document 06 §2–§3 and §10.

### Q1 — The Ferryman's Favor

```yaml
kind: quest
key: ferrymans_favor
scope: player
activation: { mode: offered, giver: npcs/bram }
resolution: { mode: automatic }
journal: { title: q.ferryman.title, stages: [q.ferryman.s1, q.ferryman.s2] }
objectives:
  sequence:
    - id: reach_green
      event: { type: entity_entered_room, actor: quest_actor, room: rooms/village_green }
    - id: meet_elspeth
      event: { type: dialogue_node_reached, target: npcs/elspeth, node: tells_name }
outcomes:
  done:
    when: { objectives_complete: true }
    consequences:
      - fact.set: { key: village.arrived, value: true, scope: instance }
      - relationship.adjust: { npc: npcs/bram, subject: quest_actor, trust: 2 }
      - topic.grant: { topic: wren }
```

### Q2 — The Missing Child

```yaml
kind: quest
key: missing_child
scope: player
activation: { mode: automatic, when: { fact_equals: { key: village.arrived, value: true } } }
resolution: { mode: turn_in, targets: [npcs/elspeth, npcs/bram] }
objectives:
  all:
    - id: learn_name
      # Q1 already observed tells_name before activating Q2: current knowledge, not replay.
      state: { fact_equals: { key: village.arrived, value: true } }
    - id: find_tracks
      event: { type: discovered, target: details/reed_bank.tracks }
    - id: cross_mire
      any:
        - event: { type: entity_entered_room, room: rooms/fox_hollow, via: connections/mire_crossing.south }
        - event: { type: check_passed, check: checks/swim_black_pool }
    - id: reach_wren
      any:
        - id: with_light
          all:
            - state: { has_item: items/lantern, lit: true }
            - event: { type: entity_entered_room, room: rooms/fox_hollow }
        - id: in_dark
          all:
            - event: { type: check_passed, check: checks/dark_hollow_per }
            - event: { type: entity_entered_room, room: rooms/fox_hollow }
    - id: vespers_riddle
      event: { type: dialogue_node_reached, target: npcs/vesper, node: riddle_answered }
    - id: decide
      any:
        - id: escort_home
          event: { type: escort_completed, target: npcs/wren, room: rooms/elspeth_cottage }
        - id: carry_message
          event: { type: item_acquired, item: items/vespers_message }
failure:
  - when: { fact_equals: { key: chapel.bell_rung, value: true } }
    before: { objective: reach_wren }
    outcome: lost
outcomes:
  rescued:
    when: { branch_completed: escort_home }
    consequences:
      - fact.set: { key: village.child_status, value: rescued, scope: instance }
      - behavior.select_profile: { target: npcs/elspeth, behavior: role, profile: relieved }
      - relationship.adjust: { npc: npcs/bram, subject: quest_actor, trust: 10 }
      - relationship.adjust: { npc: npcs/elspeth, subject: quest_actor, trust: 10 }
      - event.emit: { type: ashmere/child_returned, scope: instance }
  stays:
    when: { branch_completed: carry_message }
    consequences:
      - fact.set: { key: village.child_status, value: rescued, scope: instance }
      - behavior.select_profile: { target: npcs/wren, behavior: role, profile: with_fox }
      - relationship.adjust: { npc: npcs/vesper, subject: quest_actor, trust: 10 }
      - reputation.adjust: { faction: priory_fen, delta: -3 }
      - topic.grant: { topic: ward }
  lost:
    when: { failed: true }
    consequences:
      - fact.set: { key: village.child_status, value: lost, scope: instance }
      - behavior.select_profile: { target: npcs/elspeth, behavior: role, profile: grieving }
      - behavior.select_profile: { target: npcs/bram, behavior: role, profile: grieving }
```

### Q3 — The Bell of Ashmere

```yaml
kind: quest
key: bell_of_ashmere
scope: player
activation:
  mode: offered
  giver: npcs/aldric
  when: { any: [ { fact_equals: { key: fen.tracks_found, value: true } }, { quest_state: { quest: missing_child, state: resolved } } ] }
resolution: { mode: choice }
objectives:
  all:
    - id: hear_prior
      event: { type: dialogue_node_reached, target: npcs/aldric, node: asks_to_ring }
    - id: climb
      event: { type: entity_entered_room, room: rooms/belfry }
    - id: choose
      any:
        - id: ring
          event: { type: action_completed, action: ring_bell }
        - id: silence
          event: { type: dialogue_node_reached, target: npcs/aldric, node: refuse_bell }
outcomes:
  prior:
    when: { branch_completed: ring }
    consequences:
      - fact.set: { key: chapel.allegiance, value: prior, scope: instance }
      - fact.set: { key: chapel.bell_rung, value: true, scope: instance }
      - behavior.select_profile: { target: npcs/vesper, behavior: role, profile: bound }
      - reputation.adjust: { faction: priory_fen, delta: 4 }
      - scene.start: { scene: scenes/bell_rung }
  fox:
    when: { branch_completed: silence }
    consequences:
      - fact.set: { key: chapel.allegiance, value: fox, scope: instance }
      - behavior.select_profile: { target: npcs/aldric, behavior: role, profile: cold }
      - reputation.adjust: { faction: priory_fen, delta: -4 }
      - scene.start: { scene: scenes/bell_silenced }
```

Chapter one ends when both Q2 and Q3 are resolved: a ReactionRule on the second resolution starts `scenes/dawn_on_the_green`, which exports the memories.

### Side quests

| Key | Activation / resolution | Objectives (operators) | Outcome consequences |
|---|---|---|---|
| S1 mauds_cellar | offered by maud / turn_in maud | `count: 5` of `npc_killed` rat in lantern_cellar | inn.cellar_cleared; storage chest unlocked; maud trust +5; item cellar_key |
| S2 chandlers_debt | offered by peg / turn_in aldric | `within: { until: day 2 hour 18 }` of `item_delivered` tithe_ledger to aldric | on time: priory.tithe_delivered=on_time, faction +2, 10p; late: late, faction −1; expiry: never, peg trust −5 |
| S3 watchmans_rounds | offered by tobin at night / automatic | `escort` tobin through patrol route (`within_distance: 0` for four `entity_entered_room` events) with `survive` | watch.gate_trusts_player; north_gate open at night; tobin teaches swords |
| S4 wisp_in_the_marsh | discovered on entering marsh_light at night with light doused / choice | `state: light_off`, `check_passed: per_wisp`, then dialogue `riddle_answered` (letter-bank word) | fen.wisp_answered; aldric teaches `light` word for free; topic: ward |
| S9 herbs_for_the_infirmary | offered by wick / turn_in wick, repeatable daily | `count: 3` of `item_delivered` fenwort | 3 bandages; faction +1 per turn-in, capped +3 |
| S10 a_room_at_the_lantern | automatic on first rest at inn_rooms / automatic | `event: rested` at inn_rooms | player.slept_at_lantern; scene dream_of_the_fen; export player.dream_seen |
| S27 a_night_in_the_marsh | discovered at hound_run after 20:00 / automatic | `survive: { window: 20:00–06:00, room_tag: fen }` with `optional: shelter at drowned_oak` | fen.night_survived; sedge profile warm; sedge teaches swim; faction −1 (Priory disapproves) |

Every side quest has a declared failure state: S1 none; S2 expiry; S3 tobin dies (Bram gives an alternate turn-in); S4 answering wrong three times (wisp leaves until the next night); S9 none; S10 none; S27 death (ordinary shrine respawn at isle_shrine, quest resets; ghost-walk is chapter two).

## 8. Dialogue

Each named NPC has one dialogue graph. Node counts are targets.

| NPC | Nodes | Topic-gated choices | Skill-gated choices |
|---|---|---|---|
| bram | 22 | wren, fox, bell, ferry | haggle (fare) |
| elspeth | 18 | wren, fox | — |
| wren | 8 | fox, home | — |
| aldric | 20 | bell, ward, fox, fen | — |
| maud | 16 | rumors (fact-driven set of 6), room, cellar | haggle |
| peg | 12 | ledger, prices | haggle |
| tobin | 10 | rounds, gate, hounds | — |
| sedge | 18 | fox, ward, herbs, bell | herbalism |
| wick | 8 | herbs, bandages | — |
| vesper | 14 | riddle (letter bank: answer "lantern"), ward, bell, wren | — |
| wisp | 6 | riddle (answer "tide") | — |
| ash, hale, hob, ada, gareth | 4 each | flavor; ash/hale share the `bell` topic | — |

Topics discoverable in chapter one: wren, fox, bell, ward, ferry, rumors, room, cellar, ledger, prices, rounds, gate, hounds, herbs, bandages, riddle, home, fen, charm. Nineteen. A topic chip appears only once the topic is granted.

## 9. Scenes

| Key | Trigger | Space | Beats | Control |
|---|---|---|---|---|
| rescue_at_the_hollow | Q2 reach_wren | current_world | narrate ×2, dialogue vesper.riddle, choice (escort / carry message), consequence, end | restricted: talk, choose |
| bell_rung | Q3 prior | current_world | narrate ×3 (the bell, the fen answers, the fox stills), await_ack, end | modal |
| bell_silenced | Q3 fox | current_world | narrate ×2, dialogue aldric.cold, await_ack, end | modal |
| dream_of_the_fen | S10 first rest | scoped_overlay over inn_rooms | narrate ×3, present (fen ambience), choice (follow the fox / wake), consequence player.dream_seen, end | presentation_only |
| dawn_on_the_green | Q2 and Q3 both resolved | current_world at village_green | narrate ×3 (variant by child_status × allegiance), await_ack, consequence exports, end | modal |

All five have a checkpoint before every consequence beat and are tested by SCENE-01 and SCENE-02.

The committed terminal consequence of `dawn_on_the_green` reaches the cartridge milestone `prologue_completed` for either intended ending. It does not require all side quests or a preferred ending. The local host durably records a pending progress report with that commit; account synchronization and Realm qualification remain [document 23](23-accounts-progress-admission.md) platform policy. This is a milestone declaration for the R3/R7 schema, not a client credits-screen callback.

## 10. Reactions

| Key | On | When | Apply |
|---|---|---|---|
| mother_reacts | fact_changed village.child_status | — | behavior.select_profile elspeth by value; ambient.enable elspeth_{relieved|grieving} |
| ferryman_reacts | fact_changed village.child_status | — | ambient.enable bram_{thankful|grieving}; narration.emit at ferry_landing |
| rumors_update | fact_changed village.child_status, chapel.allegiance | — | rumor.set maud by (status, allegiance) |
| green_changes | fact_changed village.child_status | — | description_variant.select village_green |
| bell_floods_fen | fact_changed chapel.bell_rung | value true | description_variant.select reed_path, mire_crossing (flooded); population.disable fen_hounds for 2 days; behavior.select_profile sedge hostile |
| fox_silenced_priory | fact_changed chapel.allegiance | value fox | behavior.select_profile aldric cold; policy attach prior_study door: closed to player |
| chapter_end | quest_resolved missing_child, bell_of_ashmere | both resolved | scene.start dawn_on_the_green |
| crows_scavenge | item_dropped in village_green or drowned_oak | item tag shiny | behavior intent crow: carry item to oak_branches |
| night_gate | calendar_hour 18 | — | barrier.set north_gate closed unless watch.gate_trusts_player |
| day_gate | calendar_hour 6 | — | barrier.set north_gate open |

Ten rules. None writes state directly; each requests registered consequences.

## 11. Chapter-one certification

The gates are document 09 §1a. Content-specific fixtures this document commits to:

- both endings reachable by deterministic bot from a fresh save, in under 400 commands each;
- the `lost` outcome reachable only by ringing the bell before reaching Wren;
- two novices in the cloister at 14:00 produce an `ambiguous` result for "novice" in the text drawer and two distinct cards in touch;
- Wren's boot and leather boots in the same inventory produce `ambiguous` for "boot";
- north_gate closed at 18:00 for an untrusted player and open after S3;
- 30-day autonomous run: every scheduled NPC reaches every scheduled room; hound count never exceeds 6; crow nest never holds more than 8 items;
- tide at mire_crossing replays identically across save/restore at every hour;
- app killed during every consequence beat of every scene: no consequence applied twice.

## 12. Hello-world fixture

The smallest compilable subset, used as the first R4 fixture and the R1 spike model. Two rooms, one NPC with a durable two-block schedule, one item guarded by one RNG check, one quest, one dialogue.

```yaml
# cartridge.yaml
api_version: loka/v3
id: ashmere_hello
version: 0.0.1
requires:
  kernel_api: ">=1.0 <2.0"
  content_schema: 1
  rule_ir: 1
  capabilities: [movement@1, containment@1, inspectable_detail@1, description_variant@1, equipment@1, fact@1, policy@1, target_resolution@1, narration@1, quest@1, dialogue@1, topics@1, check@1, behavior@1, schedule@1]
supported_profiles: [offline_private]
time_policy: play_time
entry: { room: rooms/ferry_landing }
locales: { default: en, available: [en] }
```

```yaml
# rooms/ferry_landing.yaml
api_version: loka/v3
kind: room
key: ferry_landing
tags: [outdoor, dock]
components:
  description: { short: room.ferry_landing.short, long: room.ferry_landing.long }
  connections:
    north: { to: rooms/village_green }
  details:
    mooring_post:
      aliases: [post, mooring]
      description: detail.mooring_post
```

```yaml
# rooms/village_green.yaml
api_version: loka/v3
kind: room
key: village_green
tags: [outdoor]
components:
  description:
    short: room.village_green.short
    long: room.village_green.long
    variants:
      - when: { fact_equals: { key: village.arrived, value: true } }
        long: room.village_green.long_arrived
  connections:
    south: { to: rooms/ferry_landing }
```

```yaml
# npcs/bram.yaml
api_version: loka/v3
kind: npc
key: bram
tags: [human, ferryman]
components:
  description: { short: npc.bram.short, long: npc.bram.long }
  location: { room: rooms/ferry_landing }
  dialogue: { ref: dialogues/bram }
  quest_giver: { quests: [quests/hello_favor] }
  schedule:
    profiles:
      default:
        - { hours: "6-19", room: rooms/ferry_landing }
        - { hours: "19-6", room: rooms/village_green }
```

```yaml
# items/lantern.yaml
api_version: loka/v3
kind: item
key: lantern
tags: [light]
components:
  description: { short: item.lantern.short, long: item.lantern.long }
  location: { room: rooms/village_green }
  equipment: { slot: light }
  take:
    check: { kind: luck, chance: 50 }
    on_fail: { narrate: narration.lantern_slips, retry: allowed }
```

```yaml
# facts.yaml
api_version: loka/v3
kind: facts
facts:
  village.arrived: { type: bool, default: false, scope: instance }
```

```yaml
# dialogues/bram.yaml
api_version: loka/v3
kind: dialogue
key: bram
entry: greeting
nodes:
  greeting:
    text: dialogue.bram.greeting
    choices:
      - id: ask_favor
        text: dialogue.bram.ask_favor
        when: { quest_available: { quest: quests/hello_favor } }
        next: offer
      - id: leave
        text: dialogue.common.leave
  offer:
    text: dialogue.bram.offer
    choices:
      - id: accept
        text: dialogue.common.accept
        actions: [ { quest.activate: { quest: quests/hello_favor } } ]
      - id: decline
        text: dialogue.common.decline
```

```yaml
# quests/hello_favor.yaml
api_version: loka/v3
kind: quest
key: hello_favor
scope: player
activation: { mode: offered, giver: npcs/bram }
resolution: { mode: automatic }
objectives:
  all:
    - id: fetch
      event: { type: item_acquired, item: items/lantern }
outcomes:
  done:
    when: { objectives_complete: true }
    consequences:
      - fact.set: { key: village.arrived, value: true, scope: instance }
```

```yaml
# localization/en.yaml
room.ferry_landing.short: Ferry Landing
room.ferry_landing.long: Reeds crowd a slick wooden landing. A mooring post leans into the current.
room.village_green.short: Village Green
room.village_green.long: An old elm shades a patch of trodden grass. A lantern lies in the weeds.
room.village_green.long_arrived: An old elm shades a patch of trodden grass. The village feels smaller now that you have walked it.
detail.mooring_post: Rope has worn a groove into the post. Someone has carved a fox into it.
npc.bram.short: Old Bram
npc.bram.long: A ferryman with rope-scarred hands and a coat that has never been dry.
item.lantern.short: a brass lantern
item.lantern.long: Dented brass, oil sloshing inside. It would light a fen path.
dialogue.bram.greeting: "You'll be wanting the ferry. Or you'll be wanting something else."
dialogue.bram.ask_favor: "Something else. What do you need?"
dialogue.bram.offer: "There's a lantern up on the green. Fetch it down to me and I'll tell you why."
dialogue.common.accept: "I'll fetch it."
dialogue.common.decline: "Not today."
dialogue.common.leave: "Good day."
narration.lantern_slips: The handle turns slick in your fingers and the lantern rolls back into the weeds.
```

The positive fixture activates the quest **before** the acquisition it observes: `look`, `talk bram`, choose `accept`, `north`, `take lantern`, then return/inspect. The seeded take may fail as an admitted attempt; that failure commits its RNG state, and another attempt uses a NEW invocation ID. A matching duplicate replays the original success or failure rather than rejecting or rolling again. `village.arrived` flips once on successful post-activation acquisition and the green's derived description changes.

Separate required cases prove: acquisition before activation gives no event credit; an explicitly state-predicate quest may credit an already-held lantern; changed intent under the same ID conflicts; a stale-view retry after success replays its receipt; definite rollback consumes nothing; uncertain commit is reconciled before retry. `wait` to hour 19 moves Bram through a durable scheduled command, and save/restore preserves jobs and RNG.

`conformance/README.md` defines the executable small-contract examples and the full R1 host-adapter evidence they do NOT yet supply. The R1 golden corpus must include source/prepared definitions, initial snapshot, exact commands, per-step decision/event/state bytes, and RNG states; this prose is not itself a passing golden trace. The two-room fixture remains independent of the larger R6P playable proof and the full 57-room release.
