# Campaign Bible — Style & Prompt Guide

*The Liberation of Drezen — A Chronicle of the Crusade Against the Worldwound*

This is the authoring source of truth for the chronicle's **voice**. Read it before drafting any chapter.

## I. Campaign Meta

- **System / AP:** Pathfinder 1e — *Wrath of the Righteous*.
- **Scope:** From the fall of Kenabres (Book I) through the liberation of Drezen and the crusade beyond (Book II).
- **Party moniker:** *Rabiah's Redeemers*.

### The Company (player → character)

- **Marco → Varic Sarian** — half-elf priest of Sarenrae who took up a soldier's training; carried the longsword *Solemn Hour* (passed to him by Lupenor), and after the Scorizscar hunt wields *Battle Hymn*. Hierophant-path mythic.
- **Burt → Harlock Greyforge** — half-orc sworn to Iomedae. *Begins Book I as a devout fighter*; recovers and awakens the sentient longsword *Radiance* and grows into a paladin and Champion-path mythic hero. Founds Iomedae's Preservers.
- **Fenris → Lupenor Celest** — elven slayer, devotee of Desna; scout and archer. Trickster-path mythic. Founds Lupenor's Market in Drezen.
- **Steve → Rabiah** — human sorcerer of the Destined bloodline, marked with the Riftwardens' Seeker's Spiral; the party's battle-mage. Archmage-path mythic.
- **Chyrrik** — a mongrelman scout of Neathholm, met on the road in Book I; a keen-eyed archer who follows the company and later joins it.

*Matt runs the game.*

## II. Tone & Formatting Rules

- **Perspective:** Third-person omniscient, focused on the party's actions.
- **Tone:** Epic, grounded high-fantasy chronicle — reads like a novel or a sourcebook page. Dramatic weight without melodrama or outright comedy.
- **Exclusions:** No out-of-character banter, no dice numbers, no rules/mechanics talk, no table cross-talk. Translate every mechanical outcome into pure narrative (a failed save = a spell taking hold; a crit = a decisive, telling blow).
- **In-game names only** in the prose. Player names live only here in the bible.

### Markdown conventions (match the existing chapters exactly)

- Chapter header: `## **Chapter N — Title**` (Book II) or `## **Title**` (Book I).
- An italic subtitle line: `*<date> session — <in-game framing>*`.
- Immediately below the subtitle, the session's recording: `<!-- fathom: <recording-id> -->` (comma-separate two ids if the chapter spans two sessions). The build strips this comment from the rendered page and turns it into the chapter's "▶ recording" link.
- Body organized into `### **Subsection**` beats.
- **Bold** proper names; ***triple-asterisk italic*** for spells, items, and relics.
- Close with `*— Session of <Month Day, Year> —*`.

### Continuity guardrail

Each chapter continues naturally from the previous one. Derive events only from the session record; do not import later-campaign facts backward (e.g. no mythic power before the Gray Garrison; Harlock is not yet a paladin and Radiance is not yet awakened in the earliest chapters).

## III. Where the truth lives

- **Chronicle source:** `source/book-1-the-road-to-drezen.md`, `source/book-2-the-liberation-of-drezen.md`.
- **Bible:** this file, `bible/02-dramatis-personae.md`, `bible/03-lore-and-locations.md`.
- **Published site:** built from the source markdown via `build.ps1` → `data.js`, served by `index.html` on GitHub Pages.

The end-of-session workflow (read the sources, write the next chapter, rebuild, commit, push) is defined by the `wotr-chronicle` skill.
