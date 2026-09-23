# 00 — First Cartridge: The Fox of Ashmere

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Product scope: full campaign and chapter ladder.

Read the pitch, then section 11. Full-campaign mechanics and goals are not all chapter-one dependencies.

<details>
<summary>Sections in this document</summary>

- [1. Pitch, player, session](#1-pitch-player-session)
- [2. Setting, factions, cast](#2-setting-factions-cast)
- [3. Map](#3-map)
- [4. Feature list](#4-feature-list)
- [5. Quest list](#5-quest-list)
- [6. Interaction surface](#6-interaction-surface)
- [7. Scope](#7-scope)
- [8. Done means](#8-done-means)
- [9. Build implications](#9-build-implications)
- [10. Open questions](#10-open-questions)
- [11. Release ladder: three chapters, one world](#11-release-ladder-three-chapters-one-world)
- [12. Mechanics not yet in document 21](#12-mechanics-not-yet-in-document-21)
- [13. Launch account continuity](#13-launch-account-continuity)

</details>
<!-- packet-navigation:end -->

**Status:** Draft 0.5 — maximum-density design delivered as a three-chapter ladder (§11). Every classic-MUD mechanic family that fits the setting is in; chapter one is the R10 cartridge. Names and prose are placeholders a writer will replace.
**Purpose:** name the first game and enumerate every mechanic it uses, so R3–R9 build against a real content pull list instead of the abstract catalog. §4 is the full feature list; §11 ladders it across three chapters; §12 lists the mechanics this game needs that document 21 does not yet name.
**Reads with:** `14-implementation-plan.md` (R10 scope), `21-composable-world-primitives.md` (catalog), `19-quest-sharing-instancing-capacity.md` (services), `13-lokacore-feature-inventory.md` (ghost mode, balance sim, script templates to mine).
**Note:** packet examples still use `fox_spirit_of_yunmeng`. That is an illustrative ID; this cartridge is `the_fox_of_ashmere`.

## 1. Pitch, player, session

Ashmere is a ferry village where the King's Road meets the fen. A child has vanished. The ferryman asks you to look. Over eight to twelve hours of play you will explore five areas and 109 places across seven vertical levels, pick a guild, learn a dozen trades, earn or lose standing with three factions, buy a cottage, crawl a barrow, stand trial, ride to market, and decide what the chapel bell is for. The village remembers what you chose.

**Player.** Someone who played a Diku-lineage MUD, an early MMORPG, or a dense roguelike, and now reads on a phone. They expect inventory, equipment, stats, skills, shops, crime, weather, and a world that runs on a clock whether or not they are watching.

**Interface.** Touch first. Every mechanic in this document is playable with taps, drags, and choice chips; nothing requires typing. A text command drawer exists for power users and accessibility and reaches the same ActionSet, but it is never the only way to do something. See §4.10.

**Session shape.** Many sessions of five to twenty minutes. Save on every action. Time policy is `hybrid`: the world clock is `play_time`; smithy, brewing, tanning, mining, and inn-rest jobs use `real_elapsed`, capped at one world day per resume.

**Tone.** Low fantasy, grounded, one strange thing under the surface. A classic MMORPG's first two zones, written by someone who loves fen folklore.

**What it proves.** That Loka hosts the full classic-MUD mechanic set, offline, on a phone, with quests and world systems talking only through typed facts and events.

## 2. Setting, factions, cast

For a hundred years a fey fox named Vesper has warded the fen so the river does not swallow Ashmere. The chapel bell at Thornwick Priory, rung at dusk, thins that ward. Under the Barrow Downs a dead king waits for the ward to fail. Harrowgate, the market town up the King's Road, cares whether the ferry runs and whether the iron mine pays.

**Factions** with reputation tracks −10 to +10: **Priory**, **Fen-folk**, **Crown** (Harrowgate). Reputation gates dialogue, prices, trainer access, guard behavior, arrest thresholds, four side quests, and the endings.

**Ancestries** chosen at start: **fen-born** (+PER, swim, Fen +2), **road-born** (+DEX, haggle, Crown +2), **hill-folk** (+CON, mining, dark-sight), **fey-touched** (+SPI, one spell word, Priory −2).

**Guilds** joined in play: **Warden** (fighter, Orla), **Fen-walker** (ranger, Sedge), **Lantern-bearer** (cleric, Aldric), **Cutpurse** (rogue, the fence), **Hedge-mage** (Sedge or the librarian). One primary guild, one secondary at level 5.

| Role | Name (placeholder) | Area | Mechanics carried |
|---|---|---|---|
| Ferryman, main quest giver | Old Bram | landing / inn at night | schedule, ferry service, relationship |
| Mother | Elspeth | cottage / green | role profiles, relationship, turn-in |
| Missing child | Wren | fox hollow | scoped NPC, escort, follow |
| Prior | Prior Aldric | nave / bell tower at dusk | quest giver, faction, spell-word teacher, resurrection |
| Innkeeper | Widow Maud | Drowned Lantern | inn, food/drink, rumors, hireling broker, storage |
| Chandler | Peg Harrow | chandler | general store, mail/post, delivery quest |
| Smith | Gareth | smithy | repair, forging, smithing trainer |
| Watchman | Tobin | gates, patrol at night | patrol, guard, arrest, escort quest |
| Miller | Hob | old mill | grain, cooking ingredients, ghost quest |
| Orchard keeper | Goodwife Ada | orchard | foraging, cooking, seasonal fruit |
| Hedge witch | Mother Sedge | isle hut | herbalism, brewing, Fen guild, barter only |
| Infirmarian | Brother Wick | infirmary | healer, bandage trainer, poison cure |
| Novices (2) | Ash, Hale | Priory | ambiguity, speech responses, kitchen garden |
| Librarian | Sister Maren | Harrowgate library | readable books, identify, hedge-mage words |
| Guild trainer | Mistress Orla | guildhall | weapons, dodge, parry, bash, kick; attribute training |
| Armorer | Dunstan | armorer | arms/armor shop, compare, sell acceptance |
| Apothecary | Sable | apothecary | potions, recipes, poison vendor |
| Moneylender | Josse | moneylender | bank, debt quest |
| Bounty clerk | Corporal Vane | market square | repeatable bounties, wanted board |
| Fence | Nix | fence alley | buys stolen goods, Cutpurse guild, lockpick trainer |
| Stable master | Hew | stables | horse sale, rental, ride trainer, cart to Ashmere |
| Jailer | Sergeant Brann | watch house / jail | arrest, trial, fines, jail cell |
| Mine foreman | Kell | iron mine | mining trainer, ore quotas, cave-in event |
| Bard | Finch | Gilded Boar | songs (buffs), rumors, riddle contest |
| Hireling | Dagny | Drowned Lantern | follower, group combat, orders, loyalty |
| Fey fox | Vesper | fox hollow | antagonist/ally, riddles, faction, memory |
| Wisp | the marsh light | marsh at night | riddle, perception, discovery |
| Barrow King | Aldous the Unburied | kings chamber | boss phases, unique drops, sealed vault |
| Toll keeper | Marl | kings road bridge | toll, bribe, haggle, sneak-past |

Twenty-nine named NPCs plus populations: fen hounds, deer, crows, marsh adders, barrow wights, cellar rats, mine spiders, a river pike, stray dog, and a hound pup that can be raised.

## 3. Map

109 places across five areas and seven vertical levels, z−3 to z+3. Exits are the six directions only: north, south, east, west, up, down. Every exit is bidirectional; ferry, cart, and the moon portal are transport transitions, not exits. Entry is `ferry_landing` at z0.

Each area is drawn twice: the ground level (z0) as a plan, then every vertical shaft as a column. A room appears in exactly one drawing at its own level; a `|u` or `|d` link between two rooms means they are one exit apart vertically. Horizontal exits between rooms at the same non-zero level are drawn inside the shaft columns.

Legend: `(D)` dark, `(W)` water, `(L)` locked, `(H)` hidden exit, `(T)` trap, `(tide)` passable at low tide only, `(view)` can `scan` far across lower levels.

### Ashmere village (25) — hub

Ground, z0:

```text
                          [chapel_steps]                          (Priory, north)
                                |n
   [elspeth_cottage]-e-[north_gate]-e-[watch_post]-e-[watch_cell](L)
                                |n
   [orchard]-e-[smithy]-e-[village_green]-e-[east_gate]--e-- (King's Road, east)
                                |n
      [chandler]-e-[well_lane]-e-[drowned_lantern]
                                |n
   [boathouse]-e-[ferry_landing]
        |s                      |s
   [old_mill]              [reed_path]                             (Fen, south)
        |s
   [empty_cottage]  (for sale)
```

Vertical shafts:

```text
z+2                                            [inn_attic](H)
                                                    |d
z+1   [gate_tower](view)   [mill_loft](D)      [inn_rooms]        [cottage_loft]
           |d                  |d                   |d                  |d
z 0   [watch_post]         [old_mill]          [drowned_lantern]   [empty_cottage]   [well_lane]   [chandler]
                               |d                   |d                                  |d            |d
z-1                        [mill_cellar](D)    [lantern_cellar]--w(H)--------------[well_shaft](climb)  [chandler_storeroom]
                                                                                        |d
z-2                                                                                 [well_bottom](W,D)
```

The well bottom holds the miller's murder weapon for S13. The lantern cellar's hidden way into the well shaft is how the smugglers moved goods; it is also how a prisoner in the watch cell hears the inn.

### The Fen (22) — wilderness

Ground, z0:

```text
                          [reed_path]                    (Ashmere, north)
                                |s
   [willow_shade]-e-[reed_bank]-e-[hound_run]-e-[adder_nest]
         |s               |s              |s
   [drowned_oak]-e-[mire_crossing](W,tide)-e-[marsh_light](D)
         |s               |s                       |s
   [black_pool](W)-e-[fox_hollow]           [old_causeway]-e-[tide_flats](W,tide)
         |s
   [fishing_shallows](W)

   ferry from boathouse:   [fen_isle_landing]-e-[isle_hut]-e-[herb_garden]
                                  |s
                            [isle_shrine]   (moon portal ↔ standing_stones at full moon)
```

Vertical shafts:

```text
z+2   [oak_crown](view)
           |d
z+1   [oak_branches](crow nest)                     [hut_loft]
           |d                                            |d
z 0   [drowned_oak]     [fox_hollow]    [black_pool]   [isle_hut]
                             |d              |d
z-1                     [fox_den_deep]  [pool_bottom](W,D)
```

Crows carry scavenged items to the oak branches; climbing up is the only way to get them back. The oak crown is the one place the wisp is visible by day. Vesper's true den is below the hollow. The pool bottom holds a sunken chest and a drowning check.

### Thornwick Priory (13)

Ground, z0:

```text
                          [priory_gate](L: village.pass_open)   (Barrow Downs, north)
                                |n
   [kitchen_garden]-e-[scriptorium]-e-[cloister]-e-[infirmary]
                                          |n
                      [prior_study]-e-[chapel_nave]
                                          |n
                                    [chapel_steps]                (Ashmere, south)
```

Vertical shaft:

```text
z+3   [spire](view, rookery)
           |d
z+2   [belfry](the bell, rope)
           |d
z+1   [bell_tower](stair)
           |d
z 0   [chapel_nave]
           |d
z-1   [crypt](D)
           |d
z-2   [ossuary](D)--e(H)--> flooded_gallery  (Barrow Downs, z-2)
```

The bell is rung from the belfry, not the tower. The spire is the highest point in the cartridge; from it `scan` shows the whole village and the fen edge. The ossuary's hidden passage is the stealth route into the barrow that S18 and the Cutpurse guild care about.

### Barrow Downs (17) — dungeon

Ground, z0:

```text
                          [barrow_pass]                  (ending)
                                |n
   [cairn_ridge]-e-[standing_stones]-e-[wight_warren]-e-[wight_pit]
                                |n
                          [barrow_road]                  (Priory, south)
```

Vertical shafts:

```text
z+1   [ridge_top](view)                                                          [high_pass](view, ending overlook)
           |d                                                                          |d
z 0   [cairn_ridge]     [standing_stones]                        [wight_pit]     [barrow_pass]
                              |d                                      |d
z-1                     [barrow_mouth](L)-n-[barrow_passage](T)-e-[pit_floor](D)
                                                  |n
                        [hidden_treasury](H)-e-[bone_gallery]
                                                  |d
z-2                     [lower_gallery](D)-e-[flooded_gallery](W,D)--w(H)--> ossuary (Priory, z-2)
                              |n
                        [kings_chamber]
                              |d
z-3                     [sealed_vault](L: the crown)
```

The barrow has three ways in: the locked mouth under the standing stones, the wight pit (which is how wights pour out on Wight Night), and the ossuary passage. The deeper you go the darker and colder; z−2 applies `chilled` without a cloak, z−3 without the `ward` word.

### King's Road and Harrowgate (32) — market town

Ground, z0:

```text
(east_gate)-e-[kings_road_west]-e-[kings_road_bridge](toll)-e-[kings_road_east]-e-[harrowgate_gate]
                                          |s                                              |s
                                    [mine_road]     [library]-e-[apothecary]-e-[guildhall]-e-[market_square]-e-[moneylender]-e-[fence_alley](H)
                                          |s                                              |s
                                    [iron_mine]                            [stables]-e-[armorer]-e-[gilded_boar]
                                                                                              |s
                                                                                       [watch_house]-e-[jail](L)
```

Vertical shafts, town:

```text
z+2   [observatory](view, moon)
           |d
z+1   [reading_gallery]   [guild_quarters]   [gatehouse](view)   [boar_rooms]   [watch_tower](view)   [hayloft]
           |d                  |d                 |d                  |d              |d                 |d
z 0   [library]           [guildhall]        [harrowgate_gate]   [gilded_boar]   [watch_house]      [stables]   [jail]   [moneylender]   [fence_alley]   [kings_road_bridge]
                                                                      |d                                          |d          |d               |d               |d
z-1                                                              [boar_cellar](stores)                      [dungeon_cells](L)--e(H)--[fence_cellar]   [money_vault](L)   [under_bridge](D, smugglers)
                                                                                                                                       |u
                                                                                                                                  (fence_alley)
```

Vertical shaft, mine:

```text
z 0   [iron_mine]
           |d
z-1   [deep_shaft](D,T: cave-in)
           |d
z-2   [lower_seam](D, spiders, best ore)
           |d
z-3   [flooded_level](W,D, drowned shrine, second fen ring)
```

The observatory's telescope tells you the moon phase and when the portal opens. The jail's escape tunnel surfaces in the fence's cellar; using it makes you wanted by the Crown but earns the Cutpurse guild. Under the bridge is where Marl the toll keeper hides what he skims.

Room count: 25 + 22 + 13 + 17 + 32 = 109. By level: z+3: 1, z+2: 4, z+1: 14, z0: 76, z−1: 14, z−2: 5, z−3: 2.

## 4. Feature list

Everything the game uses, grouped the way a classic-MUD player recognizes it. Each row names where it appears and the v3 primitive it pulls. Phase is where the primitive must first exist. Rows marked **NEW** are not in document 21 yet; see §11.

### 4.1 World and movement

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Rooms with long/short descriptions, brief mode | all 76 | Place | R5 |
| Cardinal + up/down exits, `scan` adjacent rooms | all | Connection + perception | R5 |
| Doors: open/close/knock | inn rooms, prior study, watch cell, jail, barrow mouth, vault | Barrier | R5 |
| Locks, keys, keys that break | six locked things; the cellar key snaps on a failed force | Barrier + has_item + Check | R5 |
| Lockpicking and forcing | lockpick skill or STR force | Check + skill | R7 |
| Hidden exits and secret doors | hidden treasury, fence alley | Connection + PerceptionPolicy | R8 |
| Dark rooms and dark-sight | fen at night, barrow, crypt, deep shaft; hill-folk see in dark | room tag + light resource + ancestry | R8 |
| Water rooms: swim, boat, drowning | mire, pool, shallows, tide flats, flooded gallery; stamina drain, drown at 0 | terrain + skill + Resource | R8 |
| Tides | mire crossing and tide flats passable at low tide only, 6-hour cycle | **NEW** tide window (calendar-derived) | R8 |
| Terrain movement cost | fen 2 stamina, road 1, mine 2, mounted halves | travel cost | R8 |
| Indoor/outdoor, weather exposure | rain outdoors chills; fog lowers PER; cloak negates | room tag + status | R8 |
| Traps: pit, dart, cave-in | barrow passage, deep shaft, mine event | Check + consequence | R8 |
| Climbing and rope | descend into barrow mouth or deep shaft without rope = fall damage | item requirement + Check | R8 |
| Transport: ferry, cart, moon portal | boathouse ↔ isle; stables ↔ Ashmere green; shrine ↔ standing stones at full moon | Service + transition | R8 |
| Mounts | buy or rent a horse; ride on roads; not in fen or mine; horse has HP and hunger | **NEW** mount relation + follow | R8 |
| Map discovery and `where` | minimap fills on visit; `where` lists known NPCs in the area | map discovery | R5 |
| Inspectable details | ~90: fresco, runes, well, notice boards, tide marks, mine seams | InspectableDetail | R5 |
| Description variants | night, weather, tide, season, flood, festival, fact-driven | DescriptionVariant | R8 |
| Sound and smell propagation | bell audible in Ashmere; shout carries one room; smoke from the mill | **NEW** SenseCue propagation | R8 |
| Target ambiguity | two novices; three hounds; two boots; two keys. Touch taps a specific entity so ambiguity only arises in the text drawer, where it returns a candidate list | TargetResolution | R5 |
| Item flow | items dropped in the river surface at fishing shallows next day | ReactionRule on drop + move | R8 |

### 4.2 Time and environment

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| World clock, day/night, dusk | 24 logical hours; dusk at 18 gates the bell | logical clock | R5 |
| Calendar, seasons | 4 seasons of 7 days; orchard fruits in autumn; fen freezes in winter (tide flats always passable) | calendar + variants | R8 |
| Moon phase | full moon: wights stronger, portal opens, wisp visible | derived from calendar | R8 |
| Real-elapsed jobs | smithy, brewing, tanning, mining quota, inn rest | ADR-049 resume input | R6 |
| Weather | clear/rain/fog/storm; storm closes the ferry | seeded weather capability | R8 |
| Regeneration | HP/stamina/spirit per hour; doubled resting; halved hungry | derived resource | R5 |
| Light burn-down | torch 2 h, lantern 8 h, refill oil at chandler | derived temporal state | R8 |
| Shop and service hours | per NPC; bank closed Sundays; ferry no night crossing | schedule | R8 |
| Timed world events | cave-in at the mine on day 6; storm on day 9; Lantern Night after the main story | WorldEventPlan | R8 |
| Cooldowns | bash 3 rounds, spell words 1 hour, bounty daily | derived cooldown | R5 |

### 4.3 Character and progression

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Ancestry and guild | four ancestries, five guilds, secondary guild at level 5 | creation facts + policy | R7 |
| Six stats, trainable | STR, DEX, CON, INT, SPI, PER; train at guildhall for pennies and level | attributes + trainer | R7 |
| Resources | HP, stamina, spirit; hunger, thirst | Resource | R5 |
| Levels 1–15, XP from kills, quests, exploration, first-crafts | level titles per guild | progression | R7 |
| Skills as percentages, learn by use and by training | 22 skills: swords, daggers, clubs, bows, thrown, dodge, parry, bash, kick, disarm, backstab, sneak, hide, pick lock, steal, bandage, swim, climb, haggle, herbalism, brewing, cooking, smithing, tanning, mining, fishing, ride, track, appraise | skills + practice + **NEW** learn-by-doing | R7 |
| Spell words | light, mend, ward, calm, reveal, chill, bind; two words combine (`ward + light` = sanctuary) | skills + Check + **NEW** word combination | R7 |
| Status effects | bleeding, stunned, poisoned, blessed, chilled, drunk, wet, exhausted, cursed, invisible, sanctuary, hasted | status.apply/remove | R5 |
| Hunger and thirst | food/drink; waterskin fills at the well; penalty not death | Resource + consumable | R8 |
| Encumbrance and weight | STR cap; over cap halves regen and blocks swim | carrying capacity | R5 |
| Positions | standing, sitting, resting, sleeping; sleeping NPCs take double damage; resting regen | **NEW** position state | R7 |
| Titles, prestige, quest points | titles from facts/faction; quest points buy trainer discounts | derived + Resource | R7 |
| Achievements and bestiary | exploration %, kills per kind, endings seen | **NEW** collection log | R7 |
| Description, scars, age | editable description; scar per death; age from days played | profile | R12 |
| Quick bar | player pins up to six actions (bash, bandage, potion, recall...) to a thumb bar; text drawer users may also define aliases | client setting, not a capability | R12 |
| Difficulty and ironman | normal / hard / ironman (permadeath) chosen at start | creation facts + death policy | R7 |

### 4.4 Items, inventory, equipment

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Get/drop/give/put/take/fill/pour | everywhere | Containment | R5 |
| Stacking | coins, arrows, herbs, ore, rations | stacking | R5 |
| Equipment slots (14) | head, neck, body, cloak, arms, hands, finger ×2, waist, legs, feet, wield, off-hand, light | Equipment | R5 |
| Dual wield, two-handed | daggers dual; greatclub blocks shield | slot compatibility | R7 |
| Durability, repair, salvage | degrade on use; smithy repairs; salvage broken gear for scrap | Durability + ServiceJob | R8 |
| Item affects | ring of the fen +2 PER; barrow crown chill aura | equipment modifiers | R7 |
| Cursed and no-drop items | crown cannot be removed until blessed | **NEW** curse flag + status | R8 |
| Level and guild restrictions | steel sword level 4; Priory vestment Lantern-bearer only | policy on equip | R7 |
| Consumables | potions, bandages, rations, ale, oil, scrolls, poison vials, bait | Cost/consumption | R5 |
| Liquid containers | waterskin, flask, ale mug; fill at well, pool, tap | **NEW** liquid container | R8 |
| Food spoilage | fish spoils in 1 day; smoked fish never | derived temporal state | R8 |
| Keys and key rings | six keys; key ring stacks them | containment | R5 |
| Unique items | crown, fox charm, Wren's boot, the ledger, the fen ring | uniqueness | R5 |
| Currency and bank | pennies; deposit/withdraw at the moneylender | Resource + service | R8 |
| Material and quality | iron/steel/silver/fey-wood; silver vs wights; quality bands from crafting checks | typed material + result bands | R8 |
| Containers with locks and capacity | chest, coffer, sack, saddlebags; weight limits | Barrier + capacity | R5 |
| Corpses and skinning | corpse holds inventory; skin hounds for pelts; butcher deer | Containment + ActionRecipe | R7 |
| Readable items | ledger, letters, books (multi-page), notice boards, maps, runes | **NEW** readable document | R8 |
| Item identification | unknown potions; `identify` at library or `reveal` word | **NEW** identify/unknown state | R8 |
| Compare and appraise | compare two weapons; appraise skill shows value | GameView projection + skill | R7 |
| Trophies and furniture | mount a wight skull in your cottage | housing + containment | R8 |
| Musical instrument | Finch's lute; bard songs need it | equipment + skill | R8 |
| Fishing rod, pickaxe, lockpicks, rope, torch | tool requirements for skills | ToolRequirement | R8 |

### 4.5 Combat

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Round-based melee on logical time | 3-second rounds while engaged; auto-attack | combat state machine | R7 |
| Hit/dodge/parry/shield block | skill + stat vs defense; shield adds block | Check | R7 |
| Damage types and bands | slash/pierce/blunt/fire/cold/poison; crits; resistances by material and kind | result bands + typed damage | R7 |
| Weapon classes | sword, dagger, club, bow, thrown; ranged from adjacent room | equipment + skill + **NEW** adjacent-room targeting | R7 |
| Armor absorption by location | head/body/shield; called shots (stretch) | derived stat | R7 |
| Special attacks | bash (stun), kick, disarm, trip, backstab (sneaking, ×3), rescue (swap target to you) | ActionRecipes + cooldowns | R7 |
| Flee and wimpy | flee costs stamina; wimpy auto-flees below N% | Action + player setting | R7 |
| Consider | `consider hound` gives odds band | derived projection | R7 |
| Stances | aggressive/normal/defensive shift hit vs dodge | **NEW** stance state | R7 |
| Poisoned weapons and fire | apply adder venom to dagger; torch as weapon burns wights | consumable + material rule | R8 |
| Group combat, hireling orders | Dagny; orders attack/guard/stay/follow/rescue | follow relation + Behavior | R8 |
| Pet | raise a hound pup; grows in 5 days; fights; can die | **NEW** pet lifecycle | R8 |
| Charm and calm | `calm` word stops a hound; `bind` holds a wight one round | status + Behavior override | R7 |
| Aggressive, assist, flee, hunt | hounds at night; watchmen assist; deer flee; wights remember and hunt you across the barrow | Behaviors + **NEW** mob memory/hunt | R8 |
| Boss phases | Barrow King: chill aura, summons at half HP, retreats to vault at quarter | EncounterPlan + state machine | R8 |
| Sanctuary rooms | chapel nave and isle shrine: no combat | room policy | R5 |
| Death: corpse, ghost-walk, resurrection | become a ghost at the last shrine; walk to corpse; touch to return; or pay Aldric to resurrect; ironman ends the save | **NEW** ghost mode (from Lokacore §13) + death policy | R7 |
| XP loss on hard | hard mode loses 10% XP per death | death policy | R7 |
| Mob level and con color | mob levels 1–12; consider bands | progression | R7 |

### 4.6 Economy, services, crime

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Shops: list/buy/sell/value | chandler, armorer, apothecary, stables, inn, bard's songs | Commerce composite | R8 |
| Finite stock, restock, liquidity | armorer 200 pennies, weekly; chandler daily | Stock + RestockPolicy + LiquidityPolicy | R8 |
| Price by faction, haggle, stock | Crown rep, haggle skill, low stock raises price | PricePolicy | R8 |
| Barter | Sedge takes herbs and pelts, no coin | **NEW** barter offer | R8 |
| Bank | deposit/withdraw; balance survives death | account resource, player scope | R8 |
| Toll and bribe | bridge toll 3 pennies; bribe Marl; sneak past at night | CommerceTransaction + Check | R8 |
| Inn: food, drink, room, storage | rent room (rest, dream); rent a storage chest | Commerce + Service | R8 |
| Housing | buy the empty cottage for 500 pennies; chest, trophy wall, bed (rest bonus), lock | **NEW** property ownership + access policy | R8 |
| Smithy: repair, forge | overnight ServiceJob, one slot; forge from ore with smithing check | Service + Recipe | R8 |
| Brewing, cooking, tanning | recipes at Sedge/apothecary, inn kitchen, mill; duration | Recipe + ServiceJob | R8 |
| Mining, fishing, foraging, herbalism | ore seams (regrow 3 days), pike in shallows, fruit, six herb nodes | ResourceNode + RegenerationPolicy + Check | R8 |
| Quotas | foreman pays per ore batch, daily cap | repeatable + count | R7 |
| Trainers | Orla, Sedge, Wick, Aldric, Maren, Nix, Hew, Gareth, Kell | trainer service | R7 |
| Healer and cures | Wick cures poison/chill/curse for donation | Service + status.remove | R8 |
| Ferry, cart, stabling | fares, schedules, storm cancels | Service + transition | R8 |
| Stealing and pickpocket | steal skill; NPCs notice on failure | **NEW** steal action + witness | R8 |
| Fence | Nix buys stolen-flagged goods at half | stolen flag + Commerce | R8 |
| Crime, witnesses, wanted | theft, assault, trespass seen by NPC → `player.wanted` per faction | **NEW** crime/witness/wanted | R8 |
| Arrest, trial, jail, fines | watch arrests wanted players; Brann tries you; fine or 1 world day in jail; escape via lockpick | **NEW** arrest Behavior + jail state machine | R8 |
| Mail | send a letter via Peg to any named NPC; replies arrive next day | **NEW** mail | R8 |
| Notice boards | market board: bounties, wanted, rumors; post your own notice | readable + writable board | R8 |

### 4.7 NPC behavior and living world

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Schedules | 20 NPCs move by hour and season | schedule Behavior | R8 |
| Patrol, guard, arrest | Tobin, Brann, two Harrowgate watchmen | patrol + guard + arrest | R8 |
| Wander with bounds | deer, crows, hounds, adders, spiders, stray dog | wander + area restriction | R8 |
| Scavenge | crows carry shiny items to the drowned oak; stray dog steals food | scavenge Behavior | R8 |
| Needs and drives | NPCs eat at the inn at noon, sleep at night, shelter in storms | **NEW** Drives feeding arbitration | R8 |
| Follow, escort, lead | Dagny, Wren, the pup, the horse | follow relation | R8 |
| Role profiles | Elspeth ×3, Aldric ×2, Bram ×2, Vane ×2 (wanted or not) | state machine + profile | R8 |
| Speech responses | every NPC responds to topics; touch shows "Ask about..." chips for topics the player has discovered, text drawer accepts free `say`; riddles and the fence password use a word-entry field with a letter bank | ReactionRule on speech + **NEW** discovered-topic list | R8 |
| Ambient emotes | per NPC per profile | ambient emitter | R8 |
| Rumors | Maud, Finch; fact-driven; seed six side quests | rumor composite | R8 |
| NPC memory and recognition | Vesper, Aldric, Sedge, Nix remember choices; guards recognize wanted players unless disguised | Memory + **NEW** disguise/recognition | R8 |
| Relationships | trust with Bram, Elspeth, Vesper, Dagny (loyalty) | Relationship | R7 |
| Factions and standing | three tracks; faction-wide greeting variants | Faction + reputation | R7 |
| Populations and respawn | hounds 6, wights 4, deer 3, crows 4, rats 5, adders 3, spiders 4, pike 1 | SpawnBundle + PopulationPlan | R8 |
| Loot tables | per kind; rare fen ring 2% from hounds | weighted loot function | R8 |
| NPC trade with each other | Peg buys herbs from Sedge weekly; stock reflects it | **NEW** NPC commerce job | R8 |
| NPC death permanence | named NPCs stay dead; funeral scene; replacement role for shops (apprentice) | death policy + profile | R8 |
| Reactive world | bell rung → flood variant, hounds flee, Sedge hostile, wights emboldened | ReactionRule chain | R8 |
| World events | mine cave-in (day 6), storm (day 9), Lantern Night (post-story), wight surge (full moon) | WorldEventPlan | R8 |
| Ecology light | hounds hunt deer; fewer deer → hounds wander into the village at night | PopulationPlan interaction | R8 |

### 4.8 Quests and narrative

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Journal with stages, hints, reveal, map links | all quests | journal projection | R7 |
| Activation: offered, automatic, discovered | all used | activation modes | R7 |
| Resolution: turn_in, automatic, choice | all used | resolution modes | R7 |
| Objective operators | all, any, sequence, count, optional, within, branch, event, discovered, fact predicate, scene outcome, **protect**, **survive**, **race** | reducers + **NEW** three operators | R7 |
| Repeatable, daily, quota | bounties, herbs, ore, fish | repeat policy + calendar window | R7 |
| Timed and expiring | chandler's debt; storm warning | within | R7 |
| Chains, prerequisites, exclusives | main chain; Priory vs Fen exclusives; guild quests | prerequisites | R7 |
| Hidden quests | five discovered quests with no giver | discovered activation | R7 |
| Failure states | giver dies, deadline passes, wrong item destroyed | explicit failure rules | R7 |
| Outcomes and consequences | every quest | outcomes + consequence operators | R7 |
| Dialogue graphs | ~500 nodes across 29 NPCs; policy-gated; skill-gated (haggle, PER) | Dialogue | R7 |
| Scenes and cutscenes | rescue, bell, inn dream, funeral, trial, barrow king's fall, Lantern Night, four endings | SceneSequence | R7 |
| Dream sequence | first inn rest; overlay scene; exports memory | SceneSpace overlay | R7 |
| Riddles, passwords | wisp, Vesper, Finch's contest, fence alley | speech ReactionRule + choice | R8 |
| Item-order puzzle | shrine sequence | sequence operator | R7 |
| Tracking | `track wren` follows updating prints through the fen | **NEW** track skill + trail state | R8 |
| Investigation | gather three evidence items to accuse the miller's ghost's killer | count + fact predicates | R7 |
| Escort, protect, survive, race | Tobin's rounds; defend the gate on wight night; survive a night in the marsh; beat Hew's cart to Harrowgate on foot | operators above | R8 |
| Stealth quest | steal the ledger back from the moneylender unseen | sneak/hide + witness | R8 |
| Trial scene | choices with faction and evidence effects | SceneSequence + policy | R7 |
| Continuity export | `memory.village_ending`, `memory.fox_fate`, `memory.barrow_king`, `memory.guild`, `memory.wanted` | continuity ports | R7 |

### 4.9 Social

| Mechanic | In this game | Primitive | Phase |
|---|---|---|---|
| Say, whisper, shout, emote, pose | shout reaches adjacent rooms; pose persists in room description; touch offers a speech sheet with topic chips, socials grid, and free text | speech events + NarrationSpec + **NEW** pose | R7 |
| Socials | 40 with actor/target/observer text, picked from a grid, recent ones first | SocialAction | R8 |
| Orders | to Dagny, pup, horse; order chips appear on the follower's card | Action on follower | R8 |
| Bard songs | Finch teaches three; buff the room for an hour | **NEW** performance ActionRecipe | R8 |
| Recall | returns to last shrine; cooldown 1 day | ActionRecipe + transition | R7 |
| Help | tooltips and a help sheet generated from action metadata | generated help | R5 |

### 4.10 Touch interface

The renderer consumes GameView and emits ActionInvocations. None of this is game logic; all of it is what the player touches.

| Surface | Touch design | Text drawer equivalent |
|---|---|---|
| Room | prose page; entities, details, and exits are tappable inline and as cards below | `look`, `examine x` |
| Movement | six-way compass: N/S/E/W ring plus up/down buttons, disabled when no exit, badge when locked or hidden-found; swipe on the prose page also moves | `n`, `u`, `d` |
| Actions | tap an entity or detail → sheet of 2–6 actions from its ActionSet, highest priority first; long-press = examine | verbs by alias |
| Inventory | grid with weight bar; tap = use/drop/give sheet; drag onto a paper-doll silhouette to equip; drag onto a container card to put | `get`, `drop`, `wear`, `put` |
| Equipment | paper doll with 14 slots; tap slot to swap; compare shown on drag hover | `equipment`, `compare` |
| Combat | auto-attack once engaged; bottom action bar with bash/kick/disarm/flee/bandage/potion and quick-bar pins; stance toggle; target ring shows HP band and consider color; wimpy threshold is a slider in settings | `kill`, `bash`, `flee` |
| Dialogue | choice buttons; "Ask about..." row of discovered topic chips; skill-gated choices shown greyed with the reason | `talk`, `say` |
| Riddles and passwords | word-entry field with a letter bank drawn from the answer plus decoys; free text in the drawer | `say answer` |
| Shops | list with Buy/Sell tabs, price and faction discount shown, Haggle button runs the check once per item per day | `list`, `buy`, `sell`, `haggle` |
| Services | smithy, brewing, tanning, mine quota, ferry, cart: a job card with inputs slots, duration, and a claim button when done | `repair`, `brew`, `board` |
| Crafting and gathering | recipe cards with ingredient checklists; gather is a single tap on a node with a progress ring | `forge`, `mine`, `fish` |
| Skills and stats | sheet with percentage bars; trainer screens show cost and level gate | `skills`, `score`, `practice` |
| Journal | quest cards with stage text, hint reveal, and map pins; tap a pin to center the minimap | `quests`, `journal` |
| Map | minimap of discovered rooms with a z-level stepper; tap a room for its name and known exits; tap `view` rooms to scan lower levels | `map`, `scan`, `where` |
| Scenes | full-screen page with beats, continue button, choices; skip control where the scene allows it | continue |
| Death | ghost view desaturates the page; corpse pin on the map; resurrect button at a shrine | `recall`, touch corpse |
| Trial and jail | choice-driven scene; jail shows a day counter and the lockpick action if you kept the picks | choices |
| Housing | cottage card: furniture slots, chest, trophy wall as drop targets | `put`, `hang` |
| Mail and boards | inbox sheet; board is a scrollable list with a Post button | `read`, `post` |
| Mounts and pets | companion cards with follow/stay/feed/mount buttons | orders |
| Settings | wimpy slider, auto-loot, auto-exit, brief prose, plain-text mode, large type, color theme, haptics, sound | toggles |
| Text drawer | swipe up from the bottom bar; full parser with aliases, abbreviations, ordinals, `all`, quoting; history; tab completion from the current ActionSet | itself |

Rules the touch layer must obey: it never decides legality, it only shows what GameView advertises; hidden buttons are never a security boundary (ACT-09); stale taps get a typed rejection and a refreshed view (ACT-10); every touch action has a text alias so bots and screen readers reach it (ACT-07).

## 5. Quest list

Twenty-eight quests, each chosen to exercise a different shape.

| ID | Name | Type | Giver | Activation / resolution | Key mechanics | Outcomes |
|---|---|---|---|---|---|---|
| Q1 | The Ferryman's Favor | tutorial | Bram | offered / automatic | move, talk, look, tap | `village.arrived` |
| Q2 | The Missing Child | investigation + escort | Elspeth | automatic / turn_in | track, dark, lantern, tide, swim, riddle, escort | `rescued`, `stays`, `lost` |
| Q3 | The Bell of Ashmere | choice | Aldric | offered / choice | dusk, bell recipe, scene | `chapel.allegiance` |
| Q4 | The Barrow King | dungeon boss | Aldric or Sedge | offered / turn_in | lock, trap, hidden room, silver, phases, vault | `barrow.king_status` |
| Q5 | The Fen Ward | ending | automatic | automatic / automatic | Lantern Night, pass scene | endings 1–4 |
| S1 | Maud's Cellar | clear | Maud | offered / turn_in | rats, key, first combat | cellar storage |
| S2 | The Chandler's Debt | courier, timed | Peg | offered / turn_in | ledger, toll, haggle, dusk day 2 | Crown +2 |
| S3 | Watchman's Rounds | escort | Tobin | offered / automatic | patrol, hounds, assist | gate opens at night |
| S4 | Wisp in the Marsh | discovery + riddle | discovered | discovered / choice | dark, douse, PER, speech | reveal word |
| S5 | The Armorer's Test | crafting | Dunstan | offered / turn_in | ore, forge job, durability | steel sword |
| S6 | Bounties | repeatable | Vane | offered / turn_in, daily | count, window, loot | pennies, Crown |
| S7 | Sedge's Bargain | faction exclusive | Sedge | offered / choice | fox charm to Sedge or Aldric | Fen +3 / Priory +3 |
| S8 | The Unburied Ledger | puzzle | discovered | discovered / automatic | hidden room, sequence, readable | fen ring |
| S9 | Herbs for the Infirmary | collection, repeatable | Wick | offered / turn_in | herbalism, regen, count | bandages |
| S10 | A Room at the Lantern | rest + dream | automatic | automatic / automatic | inn, regen, overlay dream | `memory.first_dream` |
| S11 | The Toll Bridge | social | discovered | discovered / choice | speech, bribe, sneak | bridge fact |
| S12 | Dagny's Price | hireling | Maud | offered / turn_in | hire, orders, loyalty, wages | follower |
| S13 | The Miller's Ghost | investigation | discovered at mill at night | discovered / choice | evidence ×3, accuse, trial | `mill.killer` |
| S14 | Ore for the Crown | quota, repeatable | Kell | offered / turn_in, daily | mining, pickaxe, cave-in | Crown +1 |
| S15 | The Cave-In | survive + protect | automatic day 6 | automatic / turn_in | dig out, protect miners, rope | miner lives |
| S16 | A Roof of One's Own | housing | Josse | offered / turn_in | save 500 pennies, buy cottage, furnish | property |
| S17 | The Fence's Password | stealth/guild | Nix | discovered / turn_in | password, steal, fence, hidden exit | Cutpurse guild |
| S18 | Steal Back the Ledger | stealth | Peg | offered / turn_in | sneak, hide, pickpocket, witness, wanted | Crown −3 or clean |
| S19 | Trial at Harrowgate | trial scene | automatic when arrested | automatic / choice | evidence, faction, fine or jail | `player.wanted` cleared |
| S20 | The Pup | pet | discovered at hound run | discovered / automatic | raise, feed, train, fights | pet |
| S21 | Wight Night | protect | automatic at full moon | automatic / automatic | defend north gate, assist, wight surge | Priory +2, gate damage fact |
| S22 | Finch's Riddle Contest | riddle | Finch | offered / choice | speech answers, three rounds | song, pennies |
| S23 | Fish for the Table | fishing, repeatable | Maud | offered / turn_in | rod, bait, spoilage, smoking | recipe |
| S24 | Hew's Race | race | Hew | offered / automatic | beat the cart on foot or horse, terrain cost | horse discount |
| S25 | Words in the Library | magic | Maren | offered / turn_in | readable books, identify, word combination | two words |
| S26 | Sanctuary | faction exclusive | Aldric | offered / choice | bless the crown; Priory vs Fen | `chapel.allegiance` reinforce |
| S27 | A Night in the Marsh | survive | discovered | discovered / automatic | dark, cold, hounds, adders, shelter | Fen +2, track skill |
| S28 | The Sealed Vault | endgame loot | discovered with crown | discovered / automatic | crown key, flooded gallery, cursed item, identify | fen ring pair, `memory.vault` |

Endings from (`child_status`, `allegiance`, `king_status`, `wanted`): child home and fox free; child home, fox bound, king slain; child lost and fen flooded; child a fox-messenger and Ashmere quietly Fen-folk. A wanted player sees the Lantern Night ending from the jail window. All must be reachable in the Lab and each changes the green, the inn's rumors, and Lantern Night.

## 6. Interaction surface

- Every entity and detail advertises two to six touch actions. The text drawer reaches the same ActionSet by alias, abbreviation, ordinal, and `all`.
- ActionRecipes: ring_bell, bandage, pray, place_on_shrine, douse_light, pick_lock, force, search, track, skin, butcher, fish, mine, forage, fill, pour, steal, bribe, sing, recall, mount, dismount, knock, climb, dig.
- Ambiguity fixtures: two novices; three hounds; boot in bag vs ground; two keys; `all.herb`.
- Restricted ActionSets: modal during scenes; intersected in combat; replaced while drunk, while a ghost, while mounted, while in jail.

## 7. Scope

| Places | 109 |
| Named NPCs | 29 |
| Mob kinds | 10, ~35 alive at cap |
| Items | ~180 definitions |
| Equipment slots | 14 |
| Skills | 29 |
| Spell words | 7, with combinations |
| Ancestries / guilds | 4 / 5 |
| Quests | 28 |
| Endings | 4 (+ jail variant) |
| Dialogue nodes | ~500 |
| Facts | ~60 |
| Scenes | 9 |
| World events | 4 |
| Socials | 40 |
| Playtime | 8 to 12 hours |
| Prose | ~70,000 words |

> **Open content reconciliation:** section 5 lists five main quests (Q1-Q5) and 28 side quests (S1-S28), while the full-design summary above says 28 quests. Reconcile the intended campaign total before freezing that inventory. The chapter-one scope remains ten quests.

## 8. Done means

**Read by release:** the full-design goals below span the campaign. Chapter-one acceptance uses §11, document 00a §11, and document 14 R10/R12; later-chapter content and endings are not additional chapter-one requirements.

- R10 gate: full applicable `offline_private` certification plus device smoke in the developer harness.
- 90-day autonomous simulation across four seeds: populations bounded, every scheduled NPC reaches every destination in every season, no reaction loops, currency and items conserved except registered faucets and sinks, no orphan jobs, tide and moon cycles replay identically.
- Fifteen outside testers. At least six finish. At least three distinct endings reached unprompted. At least one tester gets arrested by accident and talks about it.
- Authoring log records hours per room, NPC, quest, and every operation done three or more times by hand. That log is R11's input.

## 9. Build implications

The full chapter-one scope is reaffirmed (2026-09-22). The earlier R6P proof is separate and built on the fresh engine. The calendar figures below are historical estimates, not release commitments; recalibrate using measured engineering and LLM-assisted authoring/review throughput.


This game needs the entire R7 and R8 catalog from document 14 plus the additions in §12. Delivered all at once that is 60 to 100 weeks to first sale; §11 ladders it so chapter one ships in roughly 9 to 14 months and full density arrives by month 18 to 29 with revenue in between.

## 10. Open questions

1. Whether ghost-walk death or resurrection-for-fee is default; ironman is opt-in either way.
2. Crime as fully simulated witnesses versus "any NPC in the room sees it." Proposal says any NPC in the room, with PER-gated exceptions for sneaking.
3. Whether NPC-to-NPC trade is real stock movement or a scheduled restock with flavor. Proposal says real, because it makes the mine quota and the apothecary shelves respond to each other.
4. Who writes 70,000 words.
5. Second language at launch or chapter two.

## 11. Release ladder: three chapters, one world

The full scope above is the destination. It ships as **three cartridges** that are chapters of one campaign, each adding one area group and one tier of mechanics. Every chapter is a complete game with its own ending, its own `offline_private` certificate, and its own store entry. Chapter one is the free showcase; two and three are paid.

Each chapter compiles its **whole map so far** from a shared source tree, so a player in chapter three can walk back to Ashmere. There are no cross-cartridge runtime dependencies (document 05 §13); continuity flows only through declared exports and imports (document 07 §15). A chapter save pins its own release. Starting chapter two imports the campaign character and the chapter-one memories, or uses declared defaults for players who skipped it.

### Map by chapter

| Chapter | Areas | Rooms | Levels |
|---|---|---|---|
| 1 — The Missing Child | Ashmere, the Fen, Priory public rooms (steps, nave, study, tower, belfry, spire, cloister, infirmary, scriptorium, kitchen garden) | 57 | z−2 to z+3 |
| 2 — The Barrow King | + crypt, ossuary, priory gate, all of Barrow Downs | 77 | z−3 to z+3 |
| 3 — The King's Road | + King's Road and Harrowgate, mine | 109 | z−3 to z+3 |

In chapter one the crypt door is sealed, the priory gate is locked, and the east gate road is flooded; chapter two opens the crypt and the priory gate, chapter three the road. Those are ActivationGroups selected by each chapter's manifest, so the shared source needs no per-chapter map edits. Chapter one's exact room, NPC, item, fact, quest, and scene content is specified in `00a-chapter-one-content.md`.

### Mechanics by chapter

Each tier is cumulative. A row's chapter is where the mechanic first appears; it stays available afterward.

| Family | Chapter 1 | Chapter 2 | Chapter 3 |
|---|---|---|---|
| Movement | rooms, six exits, doors, keys, tides, dark rooms and lantern, water rooms (swim only), map discovery, details, variants, sense cues | hidden exits, traps, climbing and rope, moon portal, scan from `view` rooms | mounts, cart, terrain cost, toll bridge |
| Time | day/night, dusk gate, regen, shop hours, cooldowns, light burn-down, inn rest (`play_time` only) | moon phase, weather, `real_elapsed` for brewing and rest, Wight Night event | seasons, cave-in and storm events, Lantern Night finale |
| Character | four ancestries, six stats, HP/stamina/spirit, positions, encumbrance, levels 1–5, six skills (swords, dodge, bandage, swim, herbalism, haggle), learn-by-doing, titles | guilds (Warden, Lantern-bearer, Fen-walker), levels to 10, spell words and combination, stances, collection log, ironman | Cutpurse and Hedge-mage guilds, secondary guild, levels to 15, attribute training, remaining skills (bows, thrown, sneak, hide, pick lock, steal, cooking, smithing, tanning, mining, fishing, ride, track, appraise) |
| Items | containment, stacking, 14 slots, wear/wield, consumables, keys, liquids, unique items, readables, corpses | durability (no repair yet), item affects, cursed items, identify, silver material, skinning, trophies | repair, salvage, forging, quality bands, level and guild restrictions, tools, instruments |
| Combat | melee rounds, hit/dodge/parry, damage bands, flee, wimpy, consider, bleed and poison, bandage, aggressive and flee behaviors, death with corpse and shrine respawn | ghost-walk and resurrection, special attacks (bash, kick, rescue), dual wield, hireling with orders, assist, boss phases, mob memory and hunt, sanctuary rooms, calm and bind words, pets | ranged from adjacent rooms, backstab, disarm, trip, poisoned weapons, torch vs wights, hard-mode XP loss |
| Economy | one shop (chandler), inn food and drink, ferry fare | second shop (priory alms for potions), healer, trainers for the three guilds | armorer, apothecary, bank, haggle, faction pricing, liquidity and restock, stables, smithy jobs, mine quota, NPC-to-NPC trade, housing, mail |
| Crime | none | none | steal, witnesses, wanted, arrest, trial, jail, fence, disguise |
| Living world | schedules, patrol, wander, guard, scavenge, role profiles, speech topics, ambient emotes, rumors, relationships, one faction track (Priory vs Fen-folk as one axis), populations (hounds, deer, crows, rats), loot tables, reactive world | three faction tracks, drives, NPC memory, permanent NPC death with funeral, wights and adders, ecology light | Crown faction, recognition, NPC commerce, spiders and pike, four world events |
| Quests | offered/automatic/discovered, all three resolutions, operators all/any/sequence/count/optional/within/event/discovered/fact/scene, survive, escort, repeatable, timed, failure states, journal, scenes, dream, riddles, continuity export | protect, race, item-order puzzle, investigation, trial-style choice scenes, hidden quests | stealth quest, quota quests, housing quest, courier chain, full trial |
| Touch UI | compass, action sheets, inventory grid, paper doll, dialogue chips, letter-bank riddles, journal, minimap, settings, text drawer | combat action bar and stances, companion cards, z-level stepper, scan view | shop tabs, job cards, recipe cards, housing card, mail inbox, boards |

### Quests by chapter

| Chapter | Main | Side |
|---|---|---|
| 1 | Q1 Ferryman's Favor, Q2 Missing Child, Q3 Bell of Ashmere | S1 Maud's Cellar, S2 Chandler's Debt (courier to the Prior before dusk, day 2), S3 Watchman's Rounds, S4 Wisp in the Marsh, S9 Herbs for the Infirmary, S10 Room at the Lantern, S27 Night in the Marsh |
| 2 | Q4 Barrow King | S7 Sedge's Bargain, S8 Unburied Ledger, S12 Dagny's Price, S13 Miller's Ghost, S20 The Pup, S21 Wight Night, S25 Words in the Scriptorium, S26 Sanctuary, S28 Sealed Vault |
| 3 | Q5 The Fen Ward | S5 Armorer's Test, S6 Bounties, S11 Toll Bridge, S14 Ore for the Crown, S15 Cave-In, S16 Roof of One's Own, S17 Fence's Password, S18 Steal Back the Ledger, S19 Trial at Harrowgate, S22 Riddle Contest, S23 Fish for the Table, S24 Hew's Race |

Chapter endings: chapter one ends at the bell and a dawn scene on the green, two endings by (`child_status`, `allegiance`); chapter two ends with the king's fall and the high pass overlook, adding `king_status`; chapter three ends with Lantern Night and the Fen Ward, adding `wanted`. Chapter two's imports default to `rescued` and `fox` for players who start there; chapter three defaults to `king_slain`.

### What each chapter buys

| Chapter | Engine phases required | New capabilities from §12 | Sizing to release | Product outcome |
|---|---|---|---|---|
| 1 | R5–R9 subset, R10, R12, R13 | tides, positions, learn-by-doing, sense cues, liquids, readables, topics, survive, pose | roughly 9 to 14 months from R1 | free showcase live; store presence; authoring log for R11 |
| 2 | R11 Builder v1 from chapter-one pain; R7/R8 additions | spell words, stances, collection, cursed, identify, ghost mode, adjacent targeting, pets, hunt, drives, protect, race, performance | roughly 4 to 7 months after chapter one | first paid cartridge; second-cartridge evidence for R16 |
| 3 | R8 economy and law additions; R16 factory assists content | mounts, barter, property, steal, law, mail, recognition, NPC commerce, track | roughly 5 to 8 months after chapter two | full mechanic set proven; third cartridge; campaign complete |

Full density arrives around month 18 to 29 instead of month 14 to 23 with no revenue in between, and each chapter's certificate scopes its gates to the capabilities it actually locks (document 09 §20 capability-triggered class). Chapter one is roughly the earlier trimmed proposal with tides, liquids, readables, and topics added because they are cheap derived state and the fen fiction wants them.

### Rules for the ladder

1. Build production mechanics by their first demonstrated need; a small earlier R6P proof may exercise a subset without shrinking chapter one. Doc 14 catalogs are filtered by `release-scope.json`, not read as wholesale prerequisites.
2. Chapter-one saves remain pinned to their release; app/kernel updates honor the published support and recovery policy in document 10 §28. Later chapters import declared continuity rather than silently migrating earlier saves. No unsupported promise of indefinite interpreter support is inferred from this ladder.
3. Shared source is one tree under `cartridges/ashmere/` with per-chapter manifests selecting ActivationGroups; the compiler produces three artifacts with three hashes.
4. R10 means the full chapter one. R16 uses chapters two and three for continuity/growth plus a small unrelated content-only reuse fixture; R9C remains mechanical assurance, not product diversity proof.

## 12. Mechanics not yet in document 21

These rows were marked NEW above. Each needs a capability entry with schema, portability, invariants, and Lab fixtures before R7/R8 can build it.

| Mechanic | Suggested capability | Notes |
|---|---|---|
| Tides | `tide@1`, calendar-derived window on Connection | pure derived state, no ticks |
| Mounts | `mount@1`, follow relation + movement modifier | horse is a RuntimeEntity with needs |
| Sense propagation | `sense_cue@1` | bell, shout, smoke; projection only |
| Learn-by-doing skills | extend `skills@1` with use-increment | deterministic increment per successful check |
| Spell word combination | `spell_words@1` | pair table compiled into cartridge |
| Positions | `position@1` | standing/sitting/resting/sleeping; combat and regen modifiers |
| Collection log / achievements | `collection@1` | player-scoped facts, projection only |
| Quick bar / text aliases | client setting, not a capability | lives in the app, never in authority |
| Discovered-topic list | `topics@1` | player-scoped set of conversation topics learned from dialogue, details, and readables; feeds "Ask about" chips |
| Cursed items | flag on `equipment@1` + `status@1` | unequip policy |
| Liquid containers | `liquid@1` | fill/pour/drink; spoilage via derived time |
| Readable documents | `readable@1` | pages, boards, mail |
| Identify / unknown state | `identity_knowledge@1` | player-scoped knowledge of item definition |
| Adjacent-room targeting | extend TargetSpec scope | bows, thrown, shout |
| Stances | `stance@1` | three states, modifier table |
| Pets | `pet@1` | growth stages via derived time, loyalty, death |
| Mob memory / hunt | `hunt@1` Behavior + Memory | remembers attacker for N hours |
| Ghost mode | `death@1` with ghost policy | restrict ActionSet, corpse touch, resurrection service |
| Barter | extend `commerce@1` with item-for-item offers | no currency path |
| Housing | `property@1` | ownership relation, access policy, furniture containment |
| Steal / pickpocket | `steal@1` | check, witness, stolen flag |
| Crime / witness / wanted / arrest / jail | `law@1` | doc 21 §16 already lists it as a later candidate; this game promotes it |
| Mail | `mail@1` | ServiceJob delivering a readable to an NPC |
| Drives | `drives@1` | doc 21 §27 candidate; feeds Behavior arbitration |
| Disguise / recognition | `recognition@1` | doc 21 §6 candidate |
| NPC-to-NPC commerce | scheduled `commerce@1` job with NPC requester | stock moves between providers |
| Protect / survive / race objectives | extend `quest@1` operators | protect = entity alive at end; survive = actor alive through window; race = arrive before event |
| Track | `track@1` skill + trail facts | trail decays via derived time |
| Pose | extend speech/narration | persists in room projection |
| Performance / songs | `performance@1` ActionRecipe pattern | room-scoped timed status |

## 13. Launch account continuity

The full chapter-one scope remains unchanged. The first public release includes accounts and accepted Story milestone tracking under [document 23](23-accounts-progress-admission.md). Either intended chapter-one ending reaches `prologue_completed` after the terminal dawn consequence. Loka's account remembers accepted completion across devices and later uses designated prologue milestones for Realm onboarding. Account access does not import offline character value, and installed play does not require a live login. Full cloud-save backup is optional; R12A, not R13/R14, owns launch identity/progress.
