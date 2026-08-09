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
- `<!-- fathom: call=<call-id> recording=<recording-id> -->` — dormant metadata; **not rendered**. Fathom numbers a session twice: the **call id** is what appears in the share URL (`fathom.video/calls/650843307`), while the **recording id** (`141062294`) is what the Fathom API and MCP tools take as `recording_id`. Passing the call id to a transcript call fails with what looks like a permissions error and isn't one, so both are stored. Every chapter written from a recording carries the pair.

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
<!-- surface: 13.6,8.5 83.2,5.0 87.8,82.5 8.6,77.4 -->
<!-- hexes: 9.70 x 5.67 -->

Any prose here becomes the region's standfirst.

## Delamere's Tomb
<!-- at: 61.0, 48.5 -->
<!-- letter: G -->
<!-- kind: ruin -->
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
- `letter:` — optional, the place's letter on the table's own key. Shown beside the kind so the
  site and the map at the table can be read against each other.
- `revealed: no` — a place the party has not found yet. The build **drops it from `data.js`
  entirely**, so it is not merely hidden by CSS: it is not in the page, not in the DOM, and not
  readable by anyone poking at the data. The build prints what it held back on every run.
  Delete the marker when the place is found. Note the limit of this: `maps/*.md` is itself in the
  public repository, so the entry is secret from the *site*, not from anyone reading the source.

**The hex layer** is optional, per region, and needs both of these:

- `surface:` — the four corners of the mapped ground, **TL TR BR BL**, in plate percentages. The
  Marchlands plate is a photograph of a table, so its map surface is a quadrilateral in the
  image, not a rectangle. From these four points the site recovers the projection and lays a flat
  hex sheet back down onto it, which is why the hexes grow toward the near edge instead of
  sitting on the picture like a decal. The grid is clipped to this quad, so it never spills onto
  the frame or the tabletop.
- `hexes: C x R` — how many hex columns and rows span that surface. For the Marchlands these come
  from the chart at the table: flat-top hexes, 9.70 columns by 5.67 rows.

A region with no `surface`/`hexes` simply gets no grid and no Hexes toggle. `scale:` is shown
only while the grid is on — a scale line with nothing to count is what made the note wrong in the
first place. To re-derive the numbers for a new plate: measure the hex pitch on the source chart,
then find the plate's four surface corners (Alt-click reads coordinates off any spot).

**Crowding:** names are laid out after the markers are drawn — each is offered its own line, then
one above, then below, until it clears every name already placed. A name with nowhere to go is
dropped rather than printed over its neighbour, and comes back when zooming in makes room. That
means a narrow phone shows fewer names at first sight and all of them as the reader zooms.

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
