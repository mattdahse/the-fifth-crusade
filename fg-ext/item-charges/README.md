# Item Charges (No Recharge)

A Fantasy Grounds extension for the PFRPG and 3.5E rulesets. Equip a wand, staff, scroll or potion
and its spell appears on the Actions tab, in a spell class named after the item. Use it there and
the charge comes off the item. **A long rest never restores it.**

It replaces **Feature: Advanced Item Actions** (rmilmine and bmos, v2.0.7). Do not run both. Both
of Matt's PFRPG campaigns, *The Real Work* and *Wrath of the Righteous - AZ*, are switched over.

## Why it exists

Advanced Item Actions builds each item's spell class as a *points* caster and stores the charges
spent as the class's points used. The ruleset's long rest (`SpellManager.resetSpells`, in
`3.5E/scripts/manager_spell.lua`) sets points used to 0 on every spell class without exception, so
every wand was full again in the morning; unequipping it then wrote the full count back onto the
item. It also never re-synced an equipped item (a function refers to an undefined variable),
watched a misnamed field (`charge` for `charges`), and gave a new wand no actions until somebody
opened its item window to trigger the default of 50.

## How it works

**The item is the only record of the charges.** The spell class is a view of it: its points are
always the item's remaining charges (or count, for potions and scrolls), and its points used are
always 0. When a cast spends a point, the extension takes the charge off the item at once and
resets the class to the new total with nothing used.

A rest sets points used to 0, which it already is, so there is nothing for a rest to restore. The
extension does not fight the ruleset's rest code; it simply never gives it anything to reset.

- **Charges:** neither ruleset has a charges field on items (Advanced Item Actions added one),
  so this extension adds a **Charges** box to the item sheet of identified wands and staves,
  under Caster Level; unlock the item to type in it. If it has never been set, the extension
  reads `[7 charges]`, `(48 charges)`, `[7 charge]` or a trailing ` - 44` in the name, then
  `7 charges` in the description, and writes the number into the box. From then on the box is
  the only answer, even at 0, so a used-up wand is never refilled from its name. (The item is
  marked `mc_charges_set` once the box holds a real count, because opening the window can
  create an empty 0 that must not hide the name's count.) It never invents a default: an item
  with no charges anywhere gets a class at 0 and a message to the GM. Potions and scrolls use
  **Count**.
- **The spell** is found by name: *Wand of Magic Missile*, *Wand (Magic Missile)*, *Potion of
  Lesser Restoration* (Pathfinder's "Restoration, Lesser" is tried too). It searches by name in
  the same places as the ruleset's Spells list (the spell record type's data paths, through
  `DB.getChildrenGlobal`), so any spell the Spells list shows can be found, vault modules such as
  Core Rules included. The campaign's own copy of a spell wins over a module's.
- **Spell level** is the lowest level in the spell's level line ("Brd 3, Sor/Wiz 2" gives 2).
- **Caster level** is the item's **CL** field, else `(CL 5)` in its name, else the minimum for the
  spell's level.
- **Save DC** is fixed at the Pathfinder item rule: 10 + spell level + the minimum casting
  modifier for that level.
- **One charge per use**, whatever the spell's level.
- **Potions act on the drinker.** Their healing and effects are set to target self, and the cast
  carries no save, spell resistance or attack against whoever happens to be targeted. Oils
  ("Oil of ...") are applied to something else and keep normal targeting.
- **The last potion or scroll leaves the inventory** the moment it is spent (the cast counter on
  the Actions tab). Its Actions entry stays behind, empty and marked *(used up)*, so its healing
  or effect can still be rolled; it clears at that character's next turn in the combat tracker,
  on a long rest, or when the campaign next loads. Used-up wands and staves stay in the
  inventory at 0.
- **Leftovers from Advanced Item Actions** (spell classes it made for items) are removed when the
  campaign loads, so the same wand never shows two classes.
- **One spell per item.** A staff with several spells (*Spherewalker's Staff*) has no single
  spell in its name and is reported, not guessed at; give it its spells by hand.
- **Only equipped, identified items** get a class. Unequip, unidentify or delete the item and its
  class goes. Change the charges or the count and the class follows; type into the class's points
  box and the item overrules it.
- **All of it runs on the host.** Players spend points through the ruleset's own power code; the
  change reaches the host and the host does the bookkeeping.

What it does not do: Advanced Item Actions' shield bash and elemental weapon dice, the
use-activated rules for scrolls (Use Magic Device, the caster level check for a scroll above your
level) or anything about who may use which item. Those stay with the table.

## Building and testing

```
pwsh -File ./build-ext.ps1 -Install
python fg-ext/item-charges/test/test_charges.py
```

The build writes `build/MC-Item-Charges.ext` and, with `-Install`, copies it into the Fantasy
Grounds extensions folder. Enable it in the campaign's extension list at launch.

The test runs the extension's real Lua (through `lupa`) against a mock of FG's database, its DB
handlers, the inventory callbacks, and the 3.5E ruleset's own long-rest reset and points spend. It
covers equip, casting, a long rest, unequip and re-equip, running dry, potions and restocking,
scrolls' level, caster level and DC, deletion, the "Restoration, Lesser" name, and an item with no
charges. It cannot cover FG's own window code: the first real test is equipping a wand in the
client and taking a long rest.
