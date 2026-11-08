# Spellbook (Prepared Spells Only)

A Fantasy Grounds extension for the PFRPG and 3.5E rulesets. A prepared caster picks the day's
spells in a spellbook window, and **only the prepared spells go on the Actions tab.**

## Why it exists

Varic kept every cleric spell he might prepare on his Actions tab so he could choose from them.
In November 2026 that came to about 250 spells at levels 0 to 6, with 25 prepared. That one spell
class was 747 KB of his 1.24 MB character sheet. Every spell on the tab is a full copy, with its
parsed actions and effects. FG builds a window for each one, syncs it to every client, and checks
it again whenever the sheet changes. The Actions tab's Combat mode only hides unprepared spells,
so it doesn't help.

## Using it

Right-click a prepared spell class on the Actions tab (the class header, e.g. *Cleric*) and choose
**Spellbook...**. The window lists every spell on the class's lists from every loaded module:

- **Lists**: the spell lists to read, comma-separated. This defaults to the class name (`cleric`).
  An oracle with access to cleric spells would use `oracle, cleric`. In the 3.5E spell module,
  domains are listed in the level line too (`good, sun`).
- **Skip**: modules to leave out, by part of their name. This defaults to `3.5E`, so the old 3.5E
  spell module doesn't add a second copy of everything.
- **Level filter**: all levels, one level, or *Prepared* (only what's prepared or kept).
- **Slot line**: `1: 5/6` means 5 prepared of 6 slots. A `!` means that level is over its slots.
- For each spell: a link to the library record, its level, its source module, **how many to
  prepare**, and **Keep**.
- **Drop** any spell from the Spells list or a module onto the list to add it by hand. It lands at
  the level the filter is showing, else its level for your lists, else its lowest level. Spells
  added by hand stay through a Rebuild.

Then press:

- **Prepare** puts the chosen spells on the Actions tab with their prepared counts and removes
  the spells it added that are no longer wanted. It adds spells through the ruleset's own
  `SpellManager.addSpell`, which is what a drag from the Spells list runs, so actions and effects
  are parsed the same way. A chat line reports what changed and names any spell whose module is
  no longer loaded.
- **Rebuild** reads the lists again, after you load a new module or change *Lists* or *Skip*.
  Counts and Keep are kept.
- **Tidy** is the one-time handover for a sheet that already holds everything. It deletes
  unprepared spells the spellbook can add back, after a confirmation that lists them. It then
  marks the remaining spells the spellbook knows as its own.

Each time the window opens, its counts are read from the Actions tab, so prepared counts edited
directly on the sheet are respected. Changes in the window take effect only when you press Prepare.

## What it will and won't remove

- A spell **Prepare** added (marked `mc_book` on the sheet) is removed when it's no longer wanted.
- Any other spell on the Actions tab is **never removed by Prepare**, only set to 0 prepared. That
  covers custom spells, spells from lists the book doesn't read, and anything already on the sheet
  before Tidy.
- **Keep** means "always on the Actions tab", prepared or not. **Tick Keep before Tidy on any
  spell whose actions were edited by hand** (adjusted damage, mythic riders, added effects).
  Otherwise the edited copy is removed and a fresh one comes back from the module later.
- Spontaneous, points and ability classes get no menu item. A sorcerer's known spells stay on
  the sheet as they are.

## Where the data lives

The spellbook is stored on the character, at `<character>.mc_spellbook.<spell class id>`: the
*Lists* and *Skip* settings, a path back to the class, and one small entry per spell (name,
level, link, source, count, keep). Each entry is
about 150 bytes, against about 3 KB for a spell on the Actions tab. The window is only built
while it's open. The extension runs on whoever opens it: a player on their own character, or the
GM on anyone's. Players get it automatically once the host enables it.

## Why the book isn't under the spell class, and the sheet blinks

The 3.5E ruleset (which PFRPG uses) watches the character's whole `spellset` with an
`onChildUpdate` handler. Every write anywhere under it, at any depth, refreshes every action of
every spell on the open sheet. On Varic that's about 900 action windows per write. v1.0.0 kept the
book under the spell class, so building it (about 1,700 writes) froze FG for minutes, and the
client had to be force-quit. From v1.0.1:

- The book lives on the character, outside `spellset`. Opening the window and editing counts
  writes nothing under the spellset. A leftover v1.0.0 book under the class is deleted on open.
- **Prepare** and **Tidy** have to write under the spellset, so they close the character sheet on
  your machine while they run and reopen it after (that's the blink). They also skip writes that
  change nothing.
- Another machine with that sheet open still refreshes on each change it receives. Tidy deletes
  a couple of hundred spells in one go, so ask the player to close Varic's sheet first (or have
  them run Tidy on their own client, with the GM's copy of the sheet closed).

## Building and testing

```
pwsh -File ./build-ext.ps1 -Name spellbook -Install
python fg-ext/spellbook/test/test_spellbook.py [path/to/unpacked/PF-SRD-Spells/client.xml]
```

The build writes `build/MC-Spellbook.ext` and, with `-Install`, copies it into the Fantasy Grounds
extensions folder. Enable it in the campaign's extension list at launch.

The test runs the extension's real Lua (through `lupa`) against a mock of FG's database, with
campaign and module roots. It covers:

- parsing level lines: Paizo's full class names, the SRD's `Sor/Wiz` abbreviations, multi-word
  classes, 3.5E domains
- matching names (`Cure Light Wounds, Mass` is the same spell as `Mass Cure Light Wounds`)
- the campaign's own copy of a spell winning over a module's, and skipping a module
- syncing counts from the sheet
- Tidy with Keep
- Prepare adding and removing spells, and running it twice
- spells added by hand, a prepared spell whose module is missing, and a class with no list
- cost: opening the book writes nothing under the spellset, and Prepare and Tidy run with the
  sheet closed, then reopen it

Given an unpacked spell module's `client.xml`, it also builds a cleric book from the real data:
236 of the PF SRD's 623 spells.

It can't cover FG's own window code. The first real test is opening the spellbook on Varic's
Cleric class in the client.
