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
own block in the source. Consecutive `@link` lines become one list:

```markdown
**The reward.**

@link parcel: sarkorian_house
@link battle: sarkorian_house
@link quest: halfway_house
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

Note the same node-vs-type split as the `<library>` block: `class` is the record type,
`recordname` is the node path. Links inside one module need no `@Module Name` suffix.

## Diagnosing a module that loads but shows nothing

In order, cheapest first:

1. **Reopen the record window.** An FG record window that was open across a module reload
   keeps showing the values it was opened with. A stale window cost a full debugging round
   here: a quest kept reading "Level 0" with an empty description long after the module on
   disk had both, because that one window had never been closed. Close it and reopen from
   the list before believing anything it says.
2. **`console.log`** in the FG data root — confirms the module loaded and timestamps it
   (`MEASURE: MODULE LOAD - … - <name>`). If your build time is later than that line, FG
   loaded an older file.
3. **Hash the installed `.mod`** against `build/` to prove which file FG actually has.
4. **Check the recordtype table above** — this is the usual answer.
5. **Compare against a real module.** `MachineFrequency.mod` is the reference adventure
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
# Hookhand Acolyte

*Ivory Labyrinth adept; the one who keeps the others in line.*

<!-- id: hookhand_acolyte -->
<!-- token: tokens/hookhand-acolyte.png -->

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
# The Sarkorian House

<!-- id: sarkorian_house -->
<!-- level: 1 -->
<!-- map: sarkorian_house -->

## Foes

- 2x labyrinth_squatter
- 1x hookhand_acolyte
```

Only lines matching exactly `- N x some_id` are read as foes, so scaling notes and prose in the
same file are safe.

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

### Maps — `fg/maps/*.md`

```markdown
<!-- image: images/the-sarkorian-house.jpg -->
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
- **Occluders are line-of-sight walls**, given as space-separated `x,y` points in image pixel
  coordinates. `occluder:` blocks sight and movement; `occluder-open:` marks terrain that can be
  crossed but still occludes (rubble, low walls) — it gets `<terrain />` and `<allow_move />`.
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

Battlemaps follow a **hybrid** rule, decided Sept 2026:

- **Interiors, rooms, dungeons, generic terrain** — build from the owned asset packs. Installed
  and worth knowing: `Shockbolt GMW Kit.mod` (1,334 backgrounds, brushes and tiles),
  `TorstansArtPack.mod` (571), `Combat_Battlemaps.mod` (finished battlemaps — the simplest case,
  just a `<bitmap>` and a name), `SmiteWorks Assets.mod`.
- **Worldwound-specific things no pack contains** — the Gray Road's scree walls, abyssal
  pimples, a lava shore, a Sarkorian ruin — generate through the **`chatgpt-image-gen`** skill.

Whatever the source, a battlemap plate carries **no text of its own**: no titles, no room
numbers, no labels. Same rule as the archive's region plates, for the same reason.

**Tokens.** NPC tokens go in `fg/art/tokens/`. For anyone who already has a portrait in
`characters/*.webp`, take the likeness from there and from `characters/CANON.md` — never from
memory, exactly as `chatgpt-image-gen` Step 0 requires. Matt has been cutting these by hand;
`campaign/tokens/` in the live campaign holds the Marchlands Expedition set as worked examples.

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
