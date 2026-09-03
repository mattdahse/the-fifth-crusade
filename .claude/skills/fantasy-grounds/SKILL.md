---
name: fantasy-grounds
description: Author Fantasy Grounds content for the Marchlands Commission campaign — NPCs, encounters, treasure parcels, quests, maps and adventure text — as markdown under fg/, compiled to a loadable .mod by build-fg.ps1. Use whenever the task is to add or change a monster, statblock, encounter, battle, treasure, loot, parcel, quest, map, battlemap, token, or adventure/GM text for the new low-level campaign, or to read anything out of the live Fantasy Grounds campaign. Triggers include "add an NPC", "build an encounter", "make a treasure parcel", "new quest", "battlemap", "FG module", "Fantasy Grounds", "statblock", or any request to prepare a session for the table.
---

# Fantasy Grounds content for the Marchlands Commission

The new campaign's source of truth is **markdown in this repo**, under `fg/`. A build script
compiles it to a Fantasy Grounds module. Nothing is authored in the FG client, and nothing is
hand-edited in XML.

```
fg/module.md          the module's name, category, author, ruleset
fg/npcs/*.md          statblocks + bio
fg/encounters/*.md    battles (FG calls them <battle>)
fg/parcels/*.md       treasure parcels — coin and items
fg/quests/*.md        the quest log the players see
fg/maps/*.md          map records: grid, scale, occluders
fg/story/*.md         GM-facing adventure text (FG calls this <encounter>)
fg/art/images/*       battlemap plates      -> travels inside the .mod
fg/art/tokens/*       NPC tokens            -> travels inside the .mod
build-fg.ps1          compiles all of it into build/<Module Name>.mod
```

```bash
pwsh -File ./build-fg.ps1 -Install
```

`-Install` copies the built `.mod` into the local Fantasy Grounds modules folder. **FG does not
hot-reload a module** — Matt has to close and reopen it (or restart FG) to see changes.

---

## THE ONE RULE THAT MATTERS

**Never write to a campaign `db.xml`. Ever. Read only.**

Fantasy Grounds holds the entire campaign in memory and rewrites `db.xml` wholesale when it
exits. Anything written to that file underneath a running FG is silently destroyed on exit —
no error, no warning, and the loss is total for that session's work.

Modules are the correct write target: FG loads them additively and never writes them back. That
is why this whole pipeline exists. The only legitimate contact with a campaign `db.xml` is
**reading** it — for reference, for extraction (see `extract-calendar.ps1`), or to learn a format
from a worked example.

The live campaign is at:

```
%APPDATA%/SmiteWorks/Fantasy Grounds/campaigns/Wrath of the Righteous - AZ/db.xml   (PC)
~/Library/Application Support/SmiteWorks/Fantasy Grounds/campaigns/...              (Macs)
```

It is ruleset **PFRPG** (Pathfinder 1e). Match it: a module built for the wrong ruleset loads
but its records open with the wrong sheet.

---

## The `<library>` recordtype is NOT the XML node name

This is the single most expensive thing to rediscover, because **it fails completely
silently**: the module loads, the console logs no error, the list window simply comes up
empty.

The XML node a record lives in and the *record type* the ruleset knows it by are different
strings. CoreRPG's `scripts/data_library.lua` holds the authoritative `aRecords` table:

| Section node in `db.xml` | `recordtype` in `<library>` | Sidebar |
|---|---|---|
| `<encounter>` | **`story`** | World |
| `<treasureparcels>` | **`treasureparcel`** (singular) | — |
| `<quest>` | `quest` | World |
| `<npc>` | `npc` | — |
| `<battle>` | `battle` | — |
| `<image>` | `image` | — |
| `<item>` | `item` | — |
| `<location>` | `location` | World |
| `<notes>` | `note` | World |
| `<tables>` | `table` | — |

Four of them share both names, which is exactly what made the first build so confusing:
`npc`, `battle`, `image` and `quest` listed correctly while `story` and `treasureparcel`
came back as empty windows off the identical code path.

To re-derive this list on any machine, read the ruleset itself:

```python
import zipfile, os, re
pak = os.environ['APPDATA'] + r'/SmiteWorks/Fantasy Grounds/rulesets/CoreRPG.pak'
d = zipfile.ZipFile(pak).read('scripts/data_library.lua').decode('utf-8', 'replace')
seg = d[d.find('aRecords = {'):]
for m in re.finditer(r'\["(\w+)"\] = \{', seg):
    body = seg[m.start():m.start() + 900]
    dm = re.search(r'aDataMap = \{([^}]*)\}', body)
    if dm:
        print(m.group(1), '->', dm.group(1).strip())
```

## `<category>` is a grouping label, not a requirement

An old module (`ks01_ogl_well_met_in_kithtakharos.mod`, 2009) wraps every record in
`<category name="..." mergeid="" baseicon="1" decalicon="0">`. A modern one
(`MachineFrequency.mod` — a full adventure with story, parcels, battles and NPCs) does not,
and puts records directly under the section node. **The wrapper is not what makes a section
list**; the recordtype above is. This build does not emit categories.

Named record ids (`<labyrinth_squatter>` rather than `<id-00001>`) work, and are what make
`npc.labyrinth_squatter@Module Name` a stable cross-reference. Prefer them.

## FG puts a space after every inline element

`<b>Chyrrik</b>, alone` renders on screen as "Chyrrik , alone". The build works around it by
pulling trailing punctuation inside the tag (`<b>Chyrrik,</b>`), which reads correctly. This
matters here more than in most campaigns because the chronicle voice bolds a name in nearly
every sentence.

## Editing a module record can fork it into the campaign

Unlocking a module record in FG and editing it creates a campaign-side copy that **shadows the
module from then on** — further module reloads will not reach it, and the record appears frozen
at whatever the data was when it forked. Symptom: one record type stubbornly shows stale values
while every other type updates correctly.

Confirm by shipping that record under a **new id**: if the list comes back with two entries (one
of them blank, having lost the name the module used to supply), a campaign copy exists. Delete
the stale entry from the list. Prefer reading module records over unlocking them.

## Record links

FG puts links in a block-level `<linklist>`, **never inline inside a `<p>`**, so a link is its
own block in the source. An `@link` written mid-sentence is dropped entirely; the build warns
about it now, because it produces a paragraph that silently loses its link. Consecutive `@link` lines become one list:

```markdown
**The reward.**

@link parcel: nest_midden
@link battle: labyrinth_post
@link quest: hold_the_halfway_house
```

The build resolves each id to that record's title and warns if it points at nothing. Override
the label with `| My own label` after the id.

| `@link` kind | `class` | `recordname` node |
|---|---|---|
| `npc` | `npc` | `npc.<id>` |
| `battle` (or `encounter`) | `battle` | `battle.<id>` |
| `parcel` | `treasureparcel` | `treasureparcels.<id>` |
| `map` (or `image`) | `imagewindow` | `image.<id>` |
| `quest` | `quest` | `quest.<id>` |
| `story` | `encounter` | `encounter.<id>` |
| `ability` | `specialability` | `specialability.<id>` |

Note the same node-vs-type split as the `<library>` block: `class` is the record type,
`recordname` is the node path. Links inside one module need no `@Module Name` suffix.

## The campaign caches the module, and a constant `dataversion` freezes it

FG does not read a module fresh every time. It caches the module's records **per campaign**, in
`campaigns/<name>/moduledb/<Module Name>.xml`, stamps that cache with the module's `dataversion`
from `definition.xml`, and re-imports only when the module's is **newer**.

So a build shipping a hard-coded `dataversion` reaches a campaign exactly **once**. Every edit
after that is invisible: FG keeps serving the cache, reloading the module changes nothing,
restarting FG changes nothing, and the `.mod` on disk is provably correct the entire time. The
symptom is "I have a cached map and reloading doesn't fix it", and every instinct — rebuild,
reinstall, restart — makes no difference, because none of them touch the cache.

`build-fg.ps1` therefore stamps `dataversion` with the **build date** (`yyyyMMdd`, the 8-digit
form every real module uses — do not widen it). `-Install` reports each campaign's cached
version against the one being shipped, and warns when FG will not refresh.

**Two builds on the same day carry the same date**, so a second same-day change hits exactly this
trap. `-ResetModuleCache` deletes the cached copies to force a re-import.

**The cache is not purely derived, so do not delete it casually.** FG also keeps campaign-side
additions there — notably `maplink` / `imagex` / `imagey`, which is *where tokens were dropped on
a map*. Clearing the cache throws that staging away. Prefer letting a newer `dataversion` drive
the re-import; reset only when it will not. And FG rewrites the file on exit like `db.xml`, so
deleting it under a running client accomplishes nothing — `-ResetModuleCache` refuses while FG is
running.

## Diagnosing a module that loads but shows nothing

In order, cheapest first:

1. **Check the campaign's module cache** (above) if the record shows *stale* rather than empty
   data. A constant `dataversion` is the usual cause and no amount of reloading reaches it.
2. **Reopen the record window.** An FG record window that was open across a module reload
   keeps showing the values it was opened with. A stale window cost a full debugging round
   here: a quest kept reading "Level 0" with an empty description long after the module on
   disk had both, because that one window had never been closed. Close it and reopen from
   the list before believing anything it says.
3. **`console.log`** in the FG data root — confirms the module loaded and timestamps it
   (`MEASURE: MODULE LOAD - … - <name>`). If your build time is later than that line, FG
   loaded an older file.
4. **Hash the installed `.mod`** against `build/` to prove which file FG actually has.
5. **Check the recordtype table above** — this is the usual answer.
6. **Compare against a real module.** `MachineFrequency.mod` is the reference adventure
   (story + parcels + battles + npcs) and `ks01_ogl_well_met_in_kithtakharos.mod` the
   reference for older layout. The purchased APs are encrypted `.dat` files in `vault/` and
   cannot be read.

Note that FG's own sidebar reaches these records regardless of the library block: **World →
Story / Quests**, and the Campaign section for parcels. If a library window is empty but the
sidebar list has the records, the bug is in the `<library>` block, not the data.

## Field names that are not what you would guess

| Record | Gotcha |
|---|---|
| **quest** | prose is `<description>`, **not** `<text>`. Needs `<level type="number">` or the sheet reads "Level 0". Has `<gmnotes>`. There is **no** field for the quest-giver — put it in `gmnotes`. |
| **encounter** (story) | prose *is* `<text>`. |
| **npc** | prose is `<text>`; `<token>` and `<picture>` both take `type="token"`. |
| **treasureparcels** (node) | `<coinlist>` and `<itemlist>` use numeric `id-NNNNN` slots; item prose is `<description>`. |

## Reading the format from Matt's own campaign

The live `db.xml` is the best documentation there is, because it holds 13 NPCs, 29 encounters,
14 treasure parcels and 76 maps that already work at this table. **When unsure of a field, go
read a real one** rather than guessing:

```bash
# find the section boundaries, then read a record
grep -n "^	<npc>\|^	</npc>" "$APPDATA/SmiteWorks/Fantasy Grounds/campaigns/Wrath of the Righteous - AZ/db.xml"
```

Gotchas that cost real time, inherited from `extract-calendar.ps1`:

- **`.LocalName`, never `.Name`** when walking FG XML in PowerShell. These elements carry a child
  `<name>` element, and PowerShell's XML adapter resolves `.Name` to that child instead of the
  element's own tag.
- **`[IO.File]::ReadAllText`, never `Get-Content -Raw`** — encoding.
- **Em-dash by code point** (`[char]0x2014`) in any `.ps1`, never typed literally.
- Write UTF-8 **without BOM**: `New-Object System.Text.UTF8Encoding($false)`.

---

## The source formats

### NPCs — `fg/npcs/*.md`

H1 is the display name. A fenced ` ```stats ` block carries the statblock; everything outside it
is the bio, which becomes the NPC's `<text>`.

```markdown
# Ysolde Karn

*Ivory Labyrinth adept; the one who keeps the others in line.*

<!-- id: ysolde_karn -->
<!-- token: tokens/ysolde-karn.webp -->
<!-- portrait: portraits/ysolde-karn.webp -->

```stats
cr: 1
xp: 400
type: Humanoid
subtype: human
alignment: NE
size: Medium
init: 0
senses: Perception +4
ac: 13, touch 10, flat-footed 13 (+3 studded leather)
hp: 11
hd: 2d6+4
fortitudesave: 1
reflexsave: 0
willsave: 4
speed: 30 ft.
atk: heavy mace +1 (1d8)
fullatk: heavy mace +1 (1d8)
strength: 10
dexterity: 11
constitution: 12
intelligence: 10
wisdom: 16
charisma: 12
babgrp: Base Atk +1; CMB +1; CMD 11
feats: Combat Casting, Iron Will
skills: Heal +8, Knowledge (religion) +5, Spellcraft +5
languages: Common, Abyssal
spacereach: 5 ft./5 ft.
specialattacks: adept spells (CL 2nd; concentration +5)
```

Prose body here.
```

#### Every NPC has a token. No exceptions.

Without one FG falls back to a lettered marker, which is unreadable the moment there is more than
one kind of enemy on the map. The build **warns** on an NPC with no `token:`, and warns again if
the file it names is not there. `portrait:` sets `<picture>` — the art the NPC sheet shows —
and should be the full-size painting, not the token; it falls back to the token if omitted.

#### The notes are for running the NPC at the table, not for explaining how it was built

This is the part that is easy to get wrong. The body of an NPC file becomes `<text>`, which is
what the GM actually reads mid-session, so it carries these, in this order:

| Section | What goes in it |
|---|---|
| **Description** | A `>` block — FG renders it as boxed read-aloud text. Chat-style, present tense, what the players see and hear. |
| **Links** | `@link image:` the full-size portrait, `@link parcel:` its gear, plus any NPC, story or map worth one click. |
| **Special abilities** | Poison, grab, breath, anything non-standard — the numbers inline **and** an `@link ability:` to a `specialability` record holding the full rule. Write "None" explicitly when there are none. |
| **Tactics** | What it does in combat. Opening move, when it retreats, what it will not do, what makes it dangerous in this specific room. |
| **Roleplaying** | Backstory only where it changes play. Then the questions that actually come up: **can it be bribed, and with what? What does it want? Is it looking for an excuse to stop fighting, or to turn on the people it works for?** |

**Do not write a provenance section.** Which book a statblock came from, what was de-rated, which
template was applied — none of it belongs in the record. It is not wanted at runtime, and if the
reasoning matters it gets asked about when the NPC is written, not read off the sheet mid-fight.
Say it in the reply instead.

**A gear parcel is what is on the body**, and nothing else — what the party finds on a captured
NPC or a corpse. Two consequences. Anything in it that the NPC would *use* in a fight (armour,
weapons, wands, potions) must also be reflected in the **statblock or the tactics**, because a
parcel is not where a GM looks mid-combat. And a creature that carries nothing gets **no gear
parcel at all**: treasure lying in its lair belongs to the **room**, written into the story
record and linked from there, never hung off the NPC. `nest_midden` is the worked example — it is
linked from the cellar's story text, not from the ants.

#### Special abilities are their own record type

`fg/abilities/*.md` builds a `<specialability>` record (recordtype **`specialability`**, from
3.5E's `data_library_35E.lua`, which PFRPG inherits). That is how the published bestiaries carry
grab, poison, pounce and the rest, and it is what `@link ability:` points at. Write the
creature's *own* numbers into it — a poison DC is specific to the creature that carries it, so a
shared "Poison (Ex)" record from another module is the wrong target.

Portrait and handout images live in **`fg/images/*.md`** with `grid: off`, and their art in
`fg/art/portraits/`. They build as `<image>` records through the same path as maps, because
`<image>` is the only record type an `@link image:` can point at — which means **FG lists them in
the same window as the battlemaps**, since that window lists a recordtype and both are `image`.

`<category>` is what separates them there. A portrait record declares `category: Portraits`; maps
default to `Maps`; the build sorts by category and wraps each run in
`<category name="..." mergeid="">`. This is the one place the category wrapper earns its keep —
it is still not what makes a section list, and the rest of the build does not emit it.

- **`id:`** is the FG record name and is referenced by encounters. Use `snake_case`. Changing it
  breaks every encounter that points at it — the build warns when a reference does not resolve.
- **`xp:`** is not an FG field. The build uses it to total an encounter's XP.
- `cr: 1/3` and friends convert to the decimals FG expects (0.33, 0.5, …).
- Any stat key the build does not recognise is dropped silently, so check the built XML when you
  add a field for the first time.

### Spells

A caster gets a second fenced block. Spells are **looked up by name** from the SRD spell module
and copied in whole, so only the names are written here:

```spells
castertype: prepared
cl: 2
ability: wisdom
label: Adept Spells
1: burning hands, cure light wounds
0: guidance, touch of fatigue
```

- Level lines are `N: spell, spell`. Repeat a prepared spell with `magic missile x2`.
- `castertype` is `prepared` or `spontaneous`; it picks the default label and the NPC's
  `spellmode` (`preparation` / `standard`).
- `ability` names the casting stat. The build reads that score from the `stats` block and
  computes the DC base as `10 + mod` — FG adds the spell level itself, so a Wis 16 adept comes
  out with DC 14 for a 1st-level spell and DC 13 for an orison, without either being written down.
- Slot counts per level default to the number of spells listed.
- **An unknown spell name is a warning, not an error** — it is skipped and the rest still build.
  Check the build output.

**Spell actions must be declared.** The looked-up spell gives you a *cast* action, which only
posts the spell and its save to chat. The damage / heal / effect buttons are hand-modelled data
that FG cannot derive from a spell's prose, so they are declared one line per spell, below the
level lines in the same block:

```
burning hands: damage d4 per cl max 5 fire
cure light wounds: heal d8 plus 1 per cl max 5
guidance: effect Guidance; +1 competence on one attack, save or skill check for 1 minute
touch of fatigue: effect Fatigued for 1 round per cl
```

| Clause | Meaning |
|---|---|
| `damage DICE [per cl] [max N] [TYPE]` | scaling damage; `per cl` sets `dicestat`, `max` caps the dice |
| `heal DICE [plus N per cl] [max N] [self]` | healing; `plus N per cl` is the per-level bonus |
| `effect LABEL [for N round\|minute\|hour\|day [per cl]]` | applies an FG effect for a duration |

Clauses are separated by `;`, and several may sit on one line. A fragment that does **not**
begin with a clause keyword is merged back into the clause before it — FG effect labels
legitimately contain semicolons (`Align Weapon - Good; DMGTYPE: good`), so the separator alone
cannot be trusted.

Derived automatically, so don't write them: `savetype` from the save line, `srnotallowed` from
the SR line, and `onmissdamage: half` — but only on a spell that actually deals damage, since
"Will half (harmless)" on a cure spell is not a half-damage-on-save case.

An unparsed clause is a **warning, not an error**, so read the build output; the spell still
ships with whatever else was understood.

**Where the spells come from.** `PF-SRD-Spells.mod`, falling back to `3.5E-spells.mod`. Two
traps: that module keeps its data in **`client.xml`, not `db.xml`**, and the records sit under
**`<spelldesc>`**. Lookup is by name with all non-alphanumerics stripped, so "Cure Light Wounds"
finds `<curelightwounds>`.

**What gets copied.** Every field FG needs inline — description, components, casting time,
range, duration, effect, save, school, SR, short description — plus an `<actions>` block that
makes the cast button work, with `savetype` derived from the save line (`Reflex half` →
`reflex`) and `srnotallowed` set when the spell ignores spell resistance. Hand-authoring this
is not viable: one spell is roughly forty lines.

**`spellmode` and `spelldisplaymode` are required on the NPC**, not just the spellset. Without
them the set is stored but the Spells tab has no usable casting layout. The build writes them
only for NPCs that actually have spells.

### Encounters — `fg/encounters/*.md`

Foes are a plain list of `N x npc_id`. The build resolves each to the NPC record, totals the XP,
and warns on any id it cannot find.

```markdown
# The Labyrinth Post

<!-- id: labyrinth_post -->
<!-- level: 1 -->
<!-- map: manor -->

## Foes

- 1x ysolde_karn
- 3x labyrinth_squatter
```

A foe line may also say **where its tokens stand**, in top-left pixels of that encounter's map:

```markdown
- 1x ysolde_karn @ 250,300
- 3x labyrinth_squatter @ 500,300; 270,660; 480,700
```

One coordinate pair per token, and the build warns when the count and the number of placements
disagree. It measures the plate named by the encounter's `map:` marker and converts to FG's own
space — origin at the plate's centre, **y pointing up** — the same convention as occluders.

FG stores this as a `<maplink>` on the foe, and the record path has a trap in it:
`image.<mapid>.image`. **The second `.image` is the layer inside the record, not a typo** — a
maplink pointing at `image.<mapid>` alone silently places nothing.

**Place them where they will be when initiative is rolled, not where they live.** A GM who has
surprise wants to drop the encounter and play; a GM who does not will move everyone on round one
anyway. Idle positions serve neither. So the placement is the faction's *posture* the moment the
alarm goes and before anybody knows which way the party is coming — formed at their own doorways,
casters back at the range their spell wants, reach weapons behind the front rank, and anything
guarding something standing on it.

**Verify placements by drawing them back.** Read the maplinks out of the built `.mod`, add half
the plate, and draw a circle at each. It takes seconds and it catches what coordinates alone
cannot: the first pass here put a squatter standing in a lit hearth and Corwin on top of a table.

**An encounter cannot carry prose.** An FG `<battle>` holds *only* name, level, exp and npclist —
there is no text field, verified against thirty battle records in the live campaign. Anything
written in an encounter file is silently discarded, so running notes, tactics and scaling go in a
**story** record and the encounter keeps just its foes. The build warns when it finds prose in an
encounter, because this failure is invisible from inside FG.

### Treasure parcels — `fg/parcels/*.md`

`## Coin` takes `- <amount> <PP|GP|SP|CP>` lines. `## Items` takes one `###` section per item,
each with its own metadata comments and a description body.

```markdown
## Coin

- 22 GP
- 140 SP

## Items

### Hooked Labyrinth Token
<!-- count: 3 -->
<!-- type: Gear -->
<!-- cost: 1 gp -->
<!-- weight: 0.5 -->
<!-- nonid: A hooked iron disc, stamped with a maze -->

What it is, in the chronicle's voice.
```

`nonid:` sets the unidentified name and marks the item unidentified, which is what makes the
players roll for it. Omit it and the item arrives already identified.

**An item's mechanical fields are not optional.** A weapon with no `damage` rolls nothing when a
player clicks it, and armour with no `ac` gives no protection when it is equipped — the record
looks complete in the parcel and does nothing at the table. So mundane gear is **looked up by
name in `PF-SRD-Basic-Rules.mod` and its real fields copied in**, exactly as spells already are.
The SRD keeps equipment in **`client.xml`, not `db.xml`**, under three separate lists —
`reference.weapon`, `reference.armor`, `reference.equipment` — and all three are searched.

- Matching is by name with non-alphanumerics stripped, so `Chain Shirt` finds `Chain shirt`.
- Anything the markdown sets **overrides** the SRD value, which is how a battered scale mail keeps
  its real `ac 5` while costing what a rusted one is worth.
- When the fiction renames a thing, point at the record: `<!-- srd: Mace, heavy -->` on an item
  called *Heavy Mace*, `<!-- srd: Warhammer -->` on a *Slate-Cutter's Maul*.
- `<!-- srd: none -->` opts a genuinely invented item out of the lookup.
- The build **warns** on a `Weapon` with no damage or `Armor` with no `ac`, from either source.
  That warning is the whole point of this section — it is the failure that looks fine in the file.

The fields are copied into our module, so nothing at the table needs the SRD module loaded.

**An item's description is player-facing.** Anything lootable gets looted, and the player reads
the description off their own sheet — so it says what the object *is*, in the world, and nothing
about what it is for. A GM note printed there is a GM note the table reads out loud.

That means no *"show this to the party"*, no *"the players will notice"*, no *"read this out"*.
Those belong in the **story record**, linked to the parcel, where the GM is the only reader. The
build warns on the giveaway phrases. And a **parcel has no prose field at all** — verified against
fourteen in the live campaign, which carry only `coinlist`, `itemlist` and `name` — so a parcel
file's own body text is repository documentation and never reaches FG either way.

The item field that *does* control what a player sees is `nonid:`, which hides the real name until
they identify it. Use that for concealment rather than writing the concealment into the prose.

### Maps — `fg/maps/*.md`

```markdown
<!-- image: images/the-manor.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 50 -->

<!-- occluder: 120,90 640,90 640,470 120,470 120,90 -->
<!-- occluder-open: 300,300 300,380 -->
```

- `image:` is relative to `fg/art/`. **If the file is missing the map is skipped and the build
  says so** — it will not ship a record pointing at nothing.
- `gridtype:` is `square`, `hexrow` or `hexcolumn`. `gridsize` is the grid pitch in **image
  pixels**, so it must be measured against the actual plate.
- **Occluders are line-of-sight walls**, given as space-separated `x,y` points in **top-left
  image pixel coordinates**. `occluder:` blocks sight and movement; `occluder-open:` marks terrain
  that can be crossed but still occludes (rubble, low walls) — it gets `<terrain />` and
  `<allow_move />`.
- **FG stores occluders relative to the image CENTRE, not its top-left corner.** The build measures
  the plate and subtracts half its width and height, so markdown stays in the same pixel space the
  blockout script draws in. This is worth knowing because it fails *plausibly*: written as raw
  pixels the whole LOS layer lands half a plate up and to the left, so walls exist, doors exist,
  and none of it is where the art is — on a 1600 × 1400 plate the house sits entirely off the
  north-west corner. Verified against Matt's own campaign: every map's occluders fit inside
  ±W/2, ±H/2, and `country_manor.png` (2000 × 3000) has x within ±1000 and y within ±1500. The
  y-axis points **UP**: `x' = x - W/2` but `y' = H/2 - y`.
- **The y-direction is the easy half to get wrong, and the expensive half.** Origin-only errors
  throw the layer off the art entirely and are obvious. Get the origin right and the direction
  wrong and the layer *mirrors about the middle of the plate*: it still looks like a floor plan,
  the walls are still walls, and every one of them is on the wrong side of the room. On a plate
  whose building is roughly centred, the outer walls land back on themselves and only the
  asymmetric details — a door, an off-centre gap — are visibly wrong.
- **Do not verify a transform by round-tripping it.** Decoding the built module with the same
  helper that encoded it proves the arithmetic is self-consistent and nothing else; a convention
  error cancels out perfectly and the overlay looks right. This mistake was made here and shipped.
  Validate against something *outside* the pipeline instead: overlay a map FG itself authored onto
  its own plate and check the lines land on real features. Pick an **asymmetric** map — a
  vertically symmetric one looks correct under both conventions.
- **Check a finished LOS layer by drawing it.** Read the occluders back out of the built `.mod`,
  add half the plate, and draw them over the bitmap — that exercises the real emitted numbers
  rather than your arithmetic, and a misalignment is instantly obvious.
- Occluders are the expensive part of map prep and the reason this pipeline is worth having.
  They must be **calibrated against the real plate** — you cannot write them before the art
  exists, only after. Author the map record first, generate the art, then measure.

### Adventure text — `fg/story/*.md`

GM-facing prose. `<!-- order: 1 -->` sets the position in FG's list. This is where the "what is
actually happening" goes, and where the campaign's whole point gets restated: **say out loud
what the party's work changed.**

---

## Prose conversion

Markdown becomes FG `<formattedtext>`. The converter parses **blocks, not lines** — source files
are hard-wrapped for readable diffs, and a paragraph's wrapped lines are rejoined before
conversion. (Converting line-by-line puts every wrapped line in its own `<p>` and, worse, leaves
an emphasis span that straddles a line break permanently open.)

| Markdown | FG |
|---|---|
| paragraph | `<p>` |
| `## Heading` | `<h>` |
| `- item` | `<list><li>` |
| `> quote` | `<frame>` — FG's boxed read-aloud text |
| `**bold**` / `*italic*` | `<b>` / `<i>` |

The build parses the generated `db.xml` as XML before packaging and throws if it is malformed —
a broken module otherwise fails silently inside FG, which is very hard to diagnose.

---

## Art

Prompts, likeness anchors and per-asset status live in
[`fg/art/PROMPTS.md`](../../../fg/art/PROMPTS.md), not here and **not in
`characters/CANON.md`** — campaign NPCs are not chronicle cast and must never reach the site's
Cast gallery.

Generation goes through the **`chatgpt-image-gen`** skill, which needs the Chrome extension
connected. That dependency is external and does fail; when it does, the prompts in
`PROMPTS.md` are written to be pasted by hand, so art is never a hard blocker.

The build copies `fg/art/**` into the module, but **only real asset extensions**
(`.png .jpg .jpeg .webp .gif .bmp .svg .ttf .otf`) — the scripts that draw plates live in
`fg/art/` too and have no business inside a `.mod`.

### Battlemaps — settle the geometry in code first

**Two orders, and the space decides which.** For a built space with straight walls — a house, a
room, a corridor — draw the blockout first: it pins the grid and the occluder coordinates, it is
playable immediately, and painted art can replace it later without moving a wall. For an
**organic** space — a cave, a bored tunnel, a nest — generate the art FIRST and measure the
occluders off it. A script drawing a cave in offset polygons self-intersects at every bend and
looks machine-made, and no amount of tuning fixes that.

When the art comes first, [`fg/art/trace-occluders.py`](../../../fg/art/trace-occluders.py) reads
the walls out of the plate rather than off a picture of it by eye. Notes that cost time to learn:

- **`--channel warm` before anything else.** It thresholds red minus blue instead of brightness.
  Dug earth is warm and cut rock is neutral, so they separate cleanly (+25..+40 against 0..+6 on
  the cellar plate), whereas in brightness they overlap badly — a shadowed stretch of that tunnel
  is *darker* than the rock beside it, so no brightness threshold takes in the whole tunnel
  without also taking in the rock.
- **`--exclude` the built rooms.** Bright worked stone reads as open floor and gets traced as a
  second cavern otherwise. Cover the walls too, not just the room inside them.
- **`--open-at` the doorways.** A traced ring is closed, which seals the cave off from the room it
  connects to. Break it where the door is and let an `occluder-door` carry that gap.
- **Look at `--preview`.** It writes `<plate>-mask.png` beside the plate; blend it over the art
  and check coverage before trusting a single coordinate. The build refuses to ship `*-mask.png`.

**A generated plate does not land on the grid**, so crop and edge-extend it until the room's
inside corner is a round multiple of the square size *and* half the plate's width and height are
too — then the grid lines up whichever corner FG anchors from. `<gridsize>` is a **pair**
(`60,60`); a bare number is not the same thing, and `<gridoffset>` shifts the lines if cropping
is not an option.

**Draw a blockout before commissioning art.** A plain floor plan drawn by a script pins the
grid, the wall positions and the occluder coordinates, and it is playable immediately;
painted art can replace the plate later without moving a wall, because the occluders are
written against those exact coordinates and the script records them.
There is **no live blockout in this repo any more** — the three-wall house it was written for was
replaced by the manor, and both current plates are art-first. The principle stands for the next
built space whose geometry has to be agreed before anyone draws it; write the script seeded, at a
round number of pixels per five-foot square, and have it print the occluder markers it drew
against.

This ordering also dodges the trap the region plates hit: asked for exact geometry and a
staged look at once, an image model keeps the staging and redraws the geometry. Repainting a
fixed blockout gives it only one job. Name that job in the prompt — *"THIS IS THE FLOOR PLAN
AND IT IS FIXED; repaint it, move nothing."*

**Correction to an earlier assumption:** the owned art packs are **tile and brush kits, not
finished maps.** `Shockbolt GMW Kit.mod` (1,334 files) and `TorstansArtPack.mod` (571) are
backgrounds, brushes and tiles meant to be composed in FG's own map editor, which this
pipeline cannot drive. Only `Combat_Battlemaps.mod` ships finished battlemaps, and those are
generic. So "use the art packs for interiors" is not a shortcut — in practice a map is either
a drawn blockout, a hand-composed map in FG, or generated art.

A battlemap plate carries **no text of its own** — no titles, no room numbers, no labels, no
compass, and no grid. FG draws the grid itself.

### Tokens

`fg/art/tokens/*.webp`, referenced by the NPC's `token:` marker:

- **512 × 512 WebP at quality 85**, opaque, square. Do **not** copy the older Marchlands
  Expedition tokens (`Fenna Tusk.png` and the rest): those are 2048 PNGs at 6–8 MB each, and a
  2048 token costs ~16 MB of video memory however well the file compresses. Some of this table
  is on low-end hardware. `fg/art/PROMPTS.md` carries the full reasoning.
- **High contrast, and much higher than the archive's house look.** Muted earth tones collapse
  into identical brown squares at the size FG actually draws a token. Separate the subject from
  the background by *value*, give each creature a distinct silhouette and dominant colour, keep
  the background dark and plain, and push the key light on the head. In-game art is allowed to be
  brighter and more vivid than the site's style; if a campaign asset ever needs to appear on the
  site, use the in-game painting as a **reference to generate site-style art from** rather than
  publishing it directly. `fg/art/PROMPTS.md` carries the full rule.
- A **painted portrait bust** with an environmental background — not a top-down counter.
- FG uses the same file for `<picture>` and `<token>` and **crops it to a circle** on the map,
  so keep the head well clear of the edges and nothing important in the corners.
- **Renaming a token means editing the NPC's `token:` marker too.** The build now warns when a
  marker points at a file that is not there; before that it shipped the broken reference and FG
  silently fell back to a default marker.

For anyone who already has a portrait in `characters/*.webp`, take the likeness from there and
from `characters/CANON.md` — never from memory, exactly as `chatgpt-image-gen` Step 0 requires.
For a new campaign NPC, write the likeness anchors into `PROMPTS.md` first so later art stays
consistent.

Missing tokens are cosmetic: FG falls back to default markers and the encounter still runs.

---

## Setting and continuity

This campaign runs alongside the chronicle, so it is bound by it. Before writing an NPC, a place
or a hook, check what the archive already establishes:

- `bible/02-dramatis-personae.md` — who exists, and the spellings that govern.
- `characters/CANON.md` — likenesses, and the "known drift" list.
- `bible/03-lore-and-locations.md` — places.
- `source/book-*.md` — what actually happened. The chronicle is the authority; if a session
  contradicts it, the chronicle wins until Matt says otherwise.
- `maps/marchlands.md` — the region chart, including places held back with `revealed: no`.

The five cohorts are the quest-givers. Their standing, unsolved problems are canon and are the
engine of the campaign — Elara has recruits and no instructors, Rothin holds an outpost two days
from help, Mira runs the network and pays finder's fees, Cornelia is hunting a leak in Drezen,
and Chyrrik carries every message across the Marchlands alone.

**The campaign's premise, which every adventure should serve:** the mythic four solve problems by
skipping the world — they teleport, they fly, they send. Everyone else still walks. The new party
does the half of the war the heroes have physically outgrown, and the measure of a good session
is that something on the ground is permanently different afterward. Say what changed, out loud,
at the table.

---

## A note on secrecy

`fg/` is in the public repository. That is deliberate — it is the same trade the archive already
makes with `maps/*.md` — but it means **GM content here is secret from the site, not from anyone
reading the source.** Nothing goes in `fg/` that would spoil a player who went looking. If
something genuinely must stay hidden, keep it out of the repo entirely.

---

## Checklist

1. Write or edit the markdown under `fg/`.
2. Check names and continuity against the bible and the chronicle.
3. `pwsh -File ./build-fg.ps1 -Install`
4. **Read the warnings.** A skipped map or an unresolved NPC id is reported, not fatal.
5. Have Matt close and reopen the module in FG.
6. Commit and push — the source is only safe once it is on `origin/main`.
