# The Fifth Crusade — Campaign Archive

The **source of truth** for our Pathfinder: *Wrath of the Righteous* campaign —
*A Chronicle of the Crusade Against the Worldwound* — and the searchable site built from it.

**Live site:** https://mattdahse.github.io/the-fifth-crusade/

The chronicle is organized into books that follow the Adventure Path, and chapter
numbering **resets to I at the start of each book**. The final chapter of a completed
book is its **Epilogue** rather than a numbered chapter.

## Repository layout

```
source/                         ← the canonical chronicle (edit these)
  book-1-the-worldwound-incursion.md  Book I   (11 + Epilogue): Kenabres → the Gray Garrison → the mythic dreams
  book-2-the-sword-of-valor.md        Book II  (9 + Epilogue):  the march to Drezen, the siege, the banner reclaimed
  book-3-demons-heresy.md             Book III (ongoing):       the crusade beyond Drezen
bible/                          ← authoring reference (voice, cast, lore)
  00-style-and-prompt-guide.md
  02-dramatis-personae.md
  03-lore-and-locations.md
  06-in-world-calendar.md       the crusade's days in the chronicle's voice → the Timeline tab
  06-in-world-calendar.json     MACHINE-WRITTEN extraction from Fantasy Grounds — never hand-edit
secrets/                        ← in-world documents (recovered journals, enemy words) → the Secrets tab
maps/                           ← one region per file, and the places found on it → the Map tab
build.ps1                       ← compiles source/*.md + secrets/*.md + maps/*.md + the calendar → data.js
extract-calendar.ps1            ← re-extracts bible/06-in-world-calendar.json from Fantasy Grounds
index.html                      ← the reader app (Contents / Cast / Secrets / Timeline / Map, search)
data.js                         ← BUILD OUTPUT — do not hand-edit
.claude/skills/                 ← Claude Code skills, checked in so they travel to every station
  wotr-chronicle/               Compile a session into a chapter, then publish
  chatgpt-image-gen/            Generate chapter art through a logged-in ChatGPT tab
.nojekyll
```

The skills live **in the repo** rather than in a personal `~/.claude` directory so that all three
stations (two Macs and a PC) behave identically. They use repo-relative paths and give both
PowerShell and POSIX forms of any shell step.

Chapters are **not numbered in the markdown** — the build assigns each book's numbering
by chapter order, so inserting a chapter renumbers the rest automatically. Each chapter's
**real-world play date** is read from its subtitle line (`*Month Day, Year session — …*`)
and shown on the site; recordings are **not** surfaced. Inline markers a chapter may carry:

- `<!-- epilogue -->` — flags the chapter as its book's Epilogue (labeled "Epilogue" instead of a numeral).
- `<!-- date: Month Day, Year -->` — explicit play-date override, for a subtitle that carries only an in-world season.
- `<!-- inworld: 19 Neth 4713 to 24 Neth 4713 -->` — the chapter's **in-world span**, which places it on the Timeline. A single day may be given alone (`<!-- inworld: 10 Neth 4713 -->`). Prefix `approx` (`<!-- inworld: approx 17 Arodus 4713 to 18 Arodus 4713 -->`) for a span the Fantasy Grounds log never recorded and which is placed from the chronicle's own narration; those blocks are drawn with a dashed edge. Every chapter needs one — the build warns for any that lacks it.
- `<!-- fathom: <recording-id> -->` — optional dormant metadata; **not rendered** (recordings are found in Fathom by date).

## The Timeline

The fourth tab stacks all 102 days of the crusade — 16th Arodus through 25th Neth, 4713 AR. Each
day carries the journal kept at the table (from `bible/06-in-world-calendar.md`) on its left, and
every chapter is drawn as a block enclosing the days it covers, coloured by book. Spans are allowed
to share a day: where two or three chapters fall on one date the day is divided between their
blocks, so a block can be a fraction of a day and a day can begin in one chapter and end in the
next. Nothing on the Timeline is hand-placed — it is entirely the `<!-- inworld: -->` markers and
the calendar. Weekday names are computed from the cycle the chronicle itself names (Fire Day, the
13th of Rova; Oath Day, the 31st of Lamashan).

## Adding a session

1. Draft the new chapter into the right `source/book-*.md` file (currently Book III), following `bible/00-style-and-prompt-guide.md`. Use a plain `## **Title**` header — no chapter number — and put the real-world play date in the subtitle (`*Month Day, Year session — …*`), which the build reads and displays.
1. Add its `<!-- inworld: … -->` marker so it lands on the Timeline, and write any new days into `bible/06-in-world-calendar.md` (run `pwsh -File ./extract-calendar.ps1` first — it reports which days are new).
2. Rebuild the search index:
   ```powershell
   powershell -ExecutionPolicy Bypass -File build.ps1
   ```
3. Commit and push — GitHub Pages redeploys automatically (~1 minute):
   ```powershell
   git commit -am "Add <title>"
   git push
   ```

The `wotr-chronicle` skill automates steps 1–3 from a raw session transcript.

## The Map

The fifth tab draws a region's art and pins the places the company has been onto it. **Nothing
is baked into the picture.** The plate is a plain image with no text on it at all; every marker,
every name, and every link to a chapter is HTML positioned on top in percentages of the plate.
That is what makes it expandable: a place can be moved, renamed or added by editing a markdown
file, and a new region — an abyssal realm, a city ward, a dungeon level — is a new file in
`maps/` and nothing else. No code changes, and the reader gets a region picker as soon as there
is more than one.

A region file looks like this:

```markdown
# The Marchlands

*The broken country west of Drezen*

<!-- image: images/map-marchlands.webp -->
<!-- order: 1 -->
<!-- scale: one hex — twelve miles, or a hard day's march -->

Any prose here becomes the region's standfirst.

## The Weeping Hills
<!-- at: 56.5, 70.0 -->
<!-- kind: peril -->
<!-- style: pin -->
<!-- chapter: The Stag King's Bride -->

What happened there, in the chronicle's voice. Shown when the marker is tapped.
```

- `at:` — **x, y as percentages of the plate**, so a marker keeps its spot at any size. The
  build warns for any place that lacks one, and skips it.
- `kind:` — picks the glyph and colour, and groups the legend. One of `city`, `temple`, `ruin`,
  `battle`, `lair`, `water`, `peril`, `camp`; anything else falls back to a plain `site` diamond.
- `style:` — `pin` (default) plants a flag whose staff-foot is the coordinate; `icon` lays a
  medallion centred on it. Both hold their size on screen however far the reader zooms in.
- `chapter:` — the chapter's **title**, not its id. Ids are assigned by build order and move when
  a chapter is inserted; titles do not. The build resolves the title to a link and warns if no
  book contains it.

**Finding coordinates:** open the Map tab, hold **Alt** and click the spot. The exact
`<!-- at: x, y -->` line appears at the corner of the plate and is copied to the clipboard —
paste it into the markdown. That readout is the whole authoring tool.

Art for a plate should carry **no text of its own** — no titles, labels, letters or compass
rose — since the labels are drawn over it and need to stay editable and searchable. Save it into
`images/` as `.webp` like every other plate.

## Adding a secret

Secrets are in-world documents shown in their own tab, parallel to the chronicle. Drop a markdown file in `secrets/` — a `# Title` line, an italic `*attribution*` line, then the body (`### Section` headers, `*dates*`, and `> blockquotes` all render). Run `build.ps1`, then commit and push. The build compiles every `secrets/*.md` into `window.SECRETS`.

`data.js` carries five globals: `window.CHAPTERS`, `window.SECRETS`, `window.CALENDAR` (month names and lengths, weekday names, and the weekday anchor), `window.JOURNAL` (one entry per recorded day) and `window.MAPS` (one region per entry, each carrying its places).

## Running locally

Put `index.html` and `data.js` in a folder and open `index.html` in any browser — it runs entirely client-side (works from `file://`). No server or dependencies.

*Compiled from session transcripts (Fathom) and the emailed chapter recaps.*
