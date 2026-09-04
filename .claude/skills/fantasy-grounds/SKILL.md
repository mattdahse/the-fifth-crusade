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

**Do not hand-write a record's skeleton. Scaffold it.** The prose is the work and no script
writes it, but the boilerplate is not, and the boilerplate is where the mistakes happen — one NPC
means five markdown files whose ids all have to agree plus two art files whose names must match,
and nothing about writing that by hand is more reliable than generating it.

```bash
python fg/new.py npc corwin-skell --name "Corwin Skell" --cr 1
python fg/new.py encounter the-locust-sworn --name "The Locust-Sworn" --map manor
python fg/new.py ability grab --name "Grab (Ex)"
python fg/new.py map the-manor --image images/the-manor.webp
python fg/new.py quest the-dolvans-alive --name "The Dolvans Alive" --xp 800
```

`new.py` stamps every marker, the section headings the conventions ask for, and the cross-links,
then names the art still missing. It never overwrites. `npc` writes the NPC, its portrait record
and its gear parcel in one go.

**And check every map by looking at it, not by reading it.**

```bash
python fg/verify.py --grid
```

`verify.py` decodes the built module's occluders and token placements back to pixels and draws
them on the plates in `build/verify/`. **A round trip cannot catch a convention error** — decoding
with the same helper that encoded is self-consistent by construction — so this re-implements the
decode from FG's convention on purpose, and disagrees with the build when the build is wrong. It
is what caught the mirrored y-axis, a squatter standing in a lit hearth, a spearman on a table,
and a breach thirty pixels from its occluder gap.

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

#### Check the bestiaries before generating art for a standard monster

A creature out of a published bestiary usually **already has official art**, and generating a
replacement is wasted effort and a worse match for the rest of the table's monsters. Look first:

```bash
python - <<'EOF'
import zipfile, glob, os, re
base = os.path.expandvars(r'%APPDATA%') + r'/SmiteWorks/Fantasy Grounds/modules'
for p in glob.glob(base + '/*.mod'):
    hits = [n for n in zipfile.ZipFile(p).namelist() if re.search(r'darkmantle', n, re.I)]
    if hits: print(os.path.basename(p), hits)
EOF
```

`PFRPG - Bestiary, Paizo (AI).mod` alone carries hundreds of `images/<Name>.webp` and
`tokens/<Name> Token.webp`. Point at them with FG's cross-module syntax rather than copying:

```markdown
<!-- token: tokens/Darkmantle Token.webp@PFRPG - Bestiary, Paizo (AI) -->
<!-- portrait: images/Darkmantle.webp@PFRPG - Bestiary, Paizo (AI) -->
```

The build recognises a path containing `@` as another module's asset: it does not look for the
file on disk, does not copy it, and does not append our own module name. **Reference, do not
repackage** — the art belongs to that module and FG is built to share it. The cost is that the
module must be loaded at the table, which for a bestiary it will be.

Art is only worth generating for **NPCs of our own invention**, which is most of them.

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

**A drawn map can still be unwalkable, and drawing it does not show that.** Run
`python fg/passable.py` as well: it rasterises the occluders, erodes the open space by half a
token, and asks whether the placed tokens can still reach one another. A traced boundary sits on
the edge of the *lit* floor, which is inside the real walkable space, and at cell resolution it is
a saw-tooth whose every tooth eats into the corridor — so a tunnel that looks a square and a half
wide on the plate can come out too narrow for FG to slide a token down, and the overlay picture
will look perfectly correct because the walls *are* on the right features.

The fix is **`--grow`** on `trace-occluders.py` (default 2, use 3 for a tight cave): it dilates the
open mask before tracing so the wall line sits back in the rock. Two results from `passable.py`
are legitimate rather than bugs — a token deliberately standing **in** a doorway, and a room that
is **meant** to be sealed.

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

**A description travels with the object, so it describes the object.** What it is, what it is made
of, what state it is in. Not how many of them there were, not where they were found, not who owned
it or what that implies — the parcel splits into separate items on a sheet and the second potion
does not know it had a twin. So this is wrong:

> *Two of them, wrapped in rag so they would not knock together. Not cult supplies — these are the
> kind a man keeps for his family.*

and this is right:

> *A stoppered glass vial of cloudy red liquid, about two swallows, wrapped in a strip of rag.*

**The flavour is not thrown away, it is moved** into a `>` read-aloud block on the room's book
page, where it is said once, at the moment the box is opened, by the person who should be saying
it. Provenance is a property of the scene, not of the thing.

**Almost everything has weight**, including a key (0.1) and a folded paper (0.1). A weightless item
silently breaks encumbrance for whoever picks it up, so the build **warns** on any item that ends
with no weight from either the markdown or the SRD. Fractions are fine and are usually the answer.

### If a thing can be found, opened, or broken, it has a DC

A room page that says *there is a hidden compartment* and stops has handed the GM a ruling to
invent at the table. Every object in the fiction that a player can interact with gets its numbers
written down next to it, in the room's book page rather than on the item:

- **Hidden** — a Perception DC, and usually a *second, lower* one for a party that has already
  earned a reason to look. Hesk's neck key makes the counter board DC 12 instead of DC 18.
- **Locked** — a Disable Device DC. Say where the key is in the same breath, because a DC 30 lock
  on a 1st-level adventure is a signpost to the key and not a puzzle.
- **Breakable** — hardness, hit points, and a Break DC. Also say **how loud it is and how long it
  takes**, which is the part that actually makes forcing it a decision.
- **Blocked or heavy** — a Strength DC, whether two characters can help, and what a tool is worth.
- **Creatures and hazards** — the CMD to escape a grapple, the Handle Animal DC to quiet a dog,
  the Climb DC and the height of the fall.

Write the alternative route every time. A DC with no second path is a wall; a DC with a key, a
prisoner who will talk, or ten loud minutes behind it is a choice.

### Quests — `fg/quests/*.md`

A quest record carries `<xp type="number">`, and **FG awards it when the GM drags the record onto
the party sheet**. That is the whole reason to have them, and it dictates the shape: **one quest
per objective, not one per adventure.** Matt's own campaign does it this way — *Defeat Tiefling
Army, 600* and *Establish Outpost, 10,000* are separate records — because the objectives are
earned at different moments and a single lump sum cannot be handed out in pieces.

So an adventure's briefing quest carries `xp: 0` and links the awards; each award is its own
record with its own XP, its own **Completion** section saying exactly what has to be true, and a
link from the room page where it is decided:

```markdown
<!-- id: the_dolvans_alive -->
<!-- level: 1 -->
<!-- giver: Mira Thistledance -->
<!-- xp: 800 -->
```

**Wherever a page says a thing is worth XP, link the quest that pays it.** A number in prose is
something the GM has to remember and then award by hand; a link is something they drag. Scaffold
them — `python fg/new.py quest the-dolvans-alive --name "..." --xp 800`.

**Objective XP is about 27% of an adventure's total**, held to deliberately in both adventures so
far — 2,200 of 8,000 in the Southshore, 1,925 of 7,000 at the manor. Below that the campaign's
stated values are just talk; much above it and the objectives outweigh the encounters, which reads
as the GM paying for compliance. Most of the awards should reward a **decision** rather than a
kill, and no more than one of them should be the job the party was actually hired for.

Check the arithmetic against the medium track before writing the numbers down, and **say in the
book what the total does** — whether it levels the party or deliberately stops short.

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
**Shortcut pins** put the room's page one click away on the map itself:

```markdown
<!-- shortcut: book:23_the_childrens_room @ 1320,135 | B4. The Children's Room -->
```

`kind:id @ x,y | Label`, in the same top-left pixels as the occluders, with any link kind plus
`book:` for a reference-manual page. The label defaults to the record's own title.

**A pin is its own LAYER.** It is not a node on the image, and there is no `<shortcuts>` element:

```xml
<layer>
  <name>A1. The Yard</name>          <!-- the pin's label -->
  <id>1</id>                          <!-- sequential; the image layer is 0 -->
  <parentid>-1</parentid>             <!-- the image layer is -2 -->
  <type>shortcut</type>
  <shortcut>
    <class>referencemanualpage</class>
    <record>reference.refmanualdata.id-00004</record>
  </shortcut>
  <matrix>1,0,0,0,0,1,0,0,0,0,1,0,-201,92,0,1</matrix>
</layer>
```

Four traps in that, every one of which cost a build:

- The position is a **4x4 transform matrix**, not an x/y pair. The translation is the last row.
- The field is **`<record>`**, not `<recordname>` as a `<link>` uses.
- The **window class is not the link class for the same record**. A reference-manual page links
  as `story_book_page_advanced` and pins as **`referencemanualpage`**.
- Coordinates are the **OCCLUDER** convention — centre origin, **y UP**. A pin is a layer and
  measures like the other things in layers.

`<linkscale>` on the image (a sibling of `<layers>`) sets how big FG draws the icons; 1.95 is what
FG chose for an 80px-grid plate, and without it they are too small to hit.

**This format was copied, not derived.** The first attempt reasoned it out from
`ImageManager.onImageShortcutDrop` falling through to `onImageTokenDrop` and concluded pins use
the token convention. That reasoning was sound and the answer was wrong: **every field name, the
class, the node structure and the axis were all different from the guess, and FG showed nothing
at all rather than showing it wrongly.** Nothing in the live campaign or any installed module
ships a pin, so there was no worked example — and the fix was to ask Matt to drop one pin in his
campaign and read `campaigns/<name>/moduledb/<Module>.xml`, which is where a pin on a *module*
map is cached. Thirty seconds of his time against an unbounded number of my guesses.

**When a format cannot be read off real data, that is the finding.** Say so and ask for one
example, rather than shipping a plausible guess.

`verify.py` draws pins in magenta with their labels. Placing them is still a matter of looking at
the picture: on a rectilinear building the room walls give the coordinates, but on a traced cave
the only way to land a pin in the right chamber is to look at the overlay.

- Occluders are the expensive part of map prep and the reason this pipeline is worth having.
  They must be **calibrated against the real plate** — you cannot write them before the art
  exists, only after. Author the map record first, generate the art, then measure.

### The book — `fg/book/*.md`

The module ships a **reference manual**: the two-pane Book window a published adventure has, with
chapters down the side. One markdown file is one page.

```markdown
# B4. The Children's Room

<!-- chapter: The Southshore Job -->
<!-- section: The House -->
<!-- order: 4 -->
```

Chapters and sections are created in the order they are first seen; `order:` sorts pages within a
section. **Give every room its own page**, and put `@link` blocks in it for the encounter, the
treasure, the map and the NPCs that belong to that room — the links work exactly as they do in a
story record, so the book becomes the thing a GM actually runs from.

It is **two structures that have to agree**: `reference.refmanualindex` is the navigation and
`reference.refmanualdata` holds the pages, and the index points at the data by record path
(`reference.refmanualdata.id-00007`). A page missing from the index does not appear; an index entry
pointing at a missing page opens blank. The build generates both, and the search keywords, from
the same source.

`<reference>` can only appear **once**, so the manual and the special abilities are accumulated and
emitted together — and it has to be emitted **before `</root>`**, which is not where the rest of
the section-building code lives.

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

**`>` is read-aloud, and read-aloud is player-facing.** `<frame>` is the speech-bubble box a
published adventure uses for the text the GM reads out, and **CoreRPG defines exactly one frame** —
there is no GM-note variant to move to. So a `>` block holding advice about how to run the scene
is advice in a box that looks like it should be read to the table, which is how *"Put the tokens
down and do not spring them"* ended up framed on the children's-room page.

Read-aloud is **what the players perceive**, in the present tense. It does not say *the party*, it
does not cite XP, and it does not tell anyone how to run anything. GM advice is a **plain
paragraph with a bold lead-in** — that is already how the rest of these pages read, and it is
visually distinct enough without a frame. The build **warns** when GM voice appears inside a `>`
block.
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
- `bible/06-in-world-calendar.md` — **the dates, and they bite.**

**Drezen was taken on the 13th of Neth, 4713 — this year, weeks before the campaign present.**
Before that it had been in demon hands for seventy years. So anything written about a person's
life *in Drezen* has a hard ceiling of about two months: no long-established businesses under the
crusade, no crusade relief queues eighteen months back, no watch that has been keeping records.

What that ceiling does **not** cover is Kenabres, which was a crusader city for decades until it
was broken open this Arodus, or the Marchlands, or anyone who lived in Drezen *under the
occupation* — a scrap dealer who kept trading through it is not a continuity error, he is a
collaborator, and that is a better character anyway.

Check a date against the calendar before writing it. A tally book with eleven honest years in it
sounds like texture and is a claim about who held the city.

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

1. **Scaffold** the record — `python fg/new.py <kind> <slug>` — then write the prose into it.
2. Check names and continuity against the bible and the chronicle.
3. `pwsh -File ./build-fg.ps1 -Install`
4. **Read the warnings.** The build makes 28 of them and they are the cheapest review available:
   a skipped map, an unresolved id, a weapon with no damage, a GM note in a player-facing item
   description, prose in an encounter that FG will discard.
5. **`python fg/verify.py --grid`** and look at the pictures, for anything with a map.
6. Have Matt close and reopen the module in FG.
7. Commit and push — the source is only safe once it is on `origin/main`.
