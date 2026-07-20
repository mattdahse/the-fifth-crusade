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
secrets/                        ← in-world documents (recovered journals, enemy words) → the Secrets tab
build.ps1                       ← compiles source/*.md + secrets/*.md → data.js
index.html                      ← the reader app (Contents / Cast / Secrets, search)
data.js                         ← BUILD OUTPUT — do not hand-edit
.nojekyll
```

Chapters are **not numbered in the markdown** — the build assigns each book's numbering
by chapter order, so inserting a chapter renumbers the rest automatically. Two markers
travel inline in a chapter block:

- `<!-- fathom: <recording-id> -->` — the session recording (becomes the "▶ recording" link). Omit it for unrecorded sessions.
- `<!-- epilogue -->` — flags the chapter as its book's Epilogue (labeled "Epilogue" instead of a numeral).

## Adding a session

1. Draft the new chapter into the right `source/book-*.md` file (currently Book III), following `bible/00-style-and-prompt-guide.md`. Use a plain `## **Title**` header — no chapter number — and include the `<!-- fathom: … -->` line under the subtitle.
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

## Adding a secret

Secrets are in-world documents shown in their own tab, parallel to the chronicle. Drop a markdown file in `secrets/` — a `# Title` line, an italic `*attribution*` line, then the body (`### Section` headers, `*dates*`, and `> blockquotes` all render). Run `build.ps1`, then commit and push. The build compiles every `secrets/*.md` into `window.SECRETS`.

## Running locally

Put `index.html` and `data.js` in a folder and open `index.html` in any browser — it runs entirely client-side (works from `file://`). No server or dependencies.

*Compiled from session transcripts (Fathom) and the emailed chapter recaps.*
