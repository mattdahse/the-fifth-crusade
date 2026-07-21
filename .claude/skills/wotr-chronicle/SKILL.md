---
name: wotr-chronicle
description: Compose and publish recaps for Matt's Pathfinder Wrath of the Righteous campaign archive, and keep its Cast, Secrets, and player-email draft in sync. Use whenever Matt pastes a WotR/Pathfinder session transcript, describes a session from memory, asks for a recap / chronicle update / "Chapter X", asks to update the cast or add a secret, or refers to the campaign or its characters (Harlock, Varic, Lupenor, Rabiah, Chirrik, Cornelia). Triggers include "transcript", "recap", "session summary", "chronicle update", "Chapter X", "add to the cast", "new secret", "Wrath of the Righteous", "WotR", or any pasted multi-paragraph game-session log set in Kenabres, Drezen, the Worldwound, or the Marchlands. Trigger even if the skill is not named — a pasted session log is enough.
---

# WotR Chronicle → Repo & Site

The campaign's **source of truth is the git repository** at `C:\Users\alast\drezen-archive`
(public GitHub Pages site: **https://mattdahse.github.io/the-fifth-crusade/**). Google Drive is a
retired backup. Maintaining the archive after a session means up to **four** jobs — do all that apply:

1. **Chronicle** — write the session's chapter and publish it.
2. **Cast** — add any new persons of importance (allies, enemies, notable NPCs); mark the dead.
3. **Secrets** — check the Fantasy Grounds Player Notes for anything new worth harvesting.
4. **Player draft** — leave a Gmail *draft* to the players linking the latest session.

## Repository layout

- `source/book-1-the-worldwound-incursion.md`, `book-2-the-sword-of-valor.md`, `book-3-demons-heresy.md` — the chronicle, one book per Adventure Path volume. **Book III is ongoing; new sessions go there.** Books I and II are complete (each closed with an `<!-- epilogue -->` chapter).
- `secrets/*.md` — a **parallel corpus** of in-world documents (the "Secrets" tab), grouped by filename prefix: `dream-`, `follower-`, `letter-`, `lore-`, `staunton-vhane-journal-`.
- `index.html` — the reader app. **The Cast is hand-authored here** (the `CAST` array), NOT built from source.
- `bible/00-style-and-prompt-guide.md`, `02-dramatis-personae.md`, `03-lore-and-locations.md` — authoring reference; Matt curates these.
- `build.ps1` — compiles `source/*.md` + `secrets/*.md` → `data.js`. Run after any source/secrets change.
- Chapters are **not numbered in the markdown**; the build assigns each book's Roman numeral by position (last = `Epilogue`). Each chapter's **real-world play date** is read from its subtitle line (`*<Month Day, Year> session — …*`) and shown on the site. Recordings are **not surfaced** (Matt finds them in Fathom by date); a `<!-- fathom: id -->` line is optional dormant metadata. If a subtitle can't carry a full date, add `<!-- date: Month Day, Year -->`.

**Encoding (Windows PowerShell):** always read/write with `[IO.File]::ReadAllText/WriteAllText` (UTF-8), never `Get-Content -Raw` (PS 5.1 reads ANSI and mangles em-dashes). Never type an em-dash literal into a `.ps1` — use `[char]0x2014`.

## Inputs

- **A session transcript** pasted in chat, **or Matt's description** from memory, **or** just "do the recap" (figure out the next chapter from the chronicle). Sometimes with a chapter number/direction.
- The session's **real-world play date** — put it in the subtitle. If unknown, check Matt's Google Calendar: the recurring event is **"Pathfinder"** (`fullText:"Pathfinder"`, roughly biweekly Fri/Sat); read the session date from there.

## Workflow — 1. The chapter

**Load first (always):** `bible/00-style-and-prompt-guide.md` (voice — read every time); `bible/02-dramatis-personae.md` (names/spellings); `bible/03-lore-and-locations.md` (named relics/places); and the **end of `source/book-3-demons-heresy.md`** to match the current voice and continuity.

**Scope:** new chapter (append to Book III), continuation (rewrite the prior ending to flow in), or ambiguous (ask Matt — don't guess boundaries).

**Extract beats:** combat turning points, mythic uses, crits, deaths/resurrections; roleplay decisions, vows, faction moves; discoveries (NPCs, items, lore); trials and level-ups as *story beats*. **In-game names only** in prose.

**Draft in house style** (match existing chapters; plain title, no chapter number):
```
## **<Title>**

*<Month Day, Year> session — <in-game setting/date>*

### **<Subsection>**
<prose with **bold names** and ***italic spells/relics***>
…
*— Session of <Month Day, Year> —*
```
Translate all mechanics into narrative — no OOC, dice, or rules talk. Then **append** it to the end of Book III (or, for a backfill, insert it by date — see below).

## Workflow — 2. The Cast (`index.html`)

Scan the recap for **new persons of importance** and update the `CAST` array in `index.html`:
- **New allies / persons of importance** → the `Allies & Powers` section, *or* a hero's follower sub-section if they join that cadre (`Harlock's Order — Iomedae's Preservers`, `Lupenor's Market — the Celest House`, `Rabiah's Redeemers — the Street Patrol`, `Varic's Temple — the Temple of United Faith`).
- **New enemies** → the `Adversaries` section.
- **Deaths / reveals** → update the person's entry; add the string `'dead'` as a third array element to render a ☠ (e.g. `['Name','role','dead']`). Also revise an entry when a character's nature is revealed.

Entry shape: `['Name','one-line role']`. **CRITICAL:** these are single-quoted JS strings — every apostrophe *inside* a string must be a **curly ’** (U+2019), never a straight `'`, or the page breaks silently. Curly quotes “ ” and em-dashes — are fine. The Cast is served straight from `index.html` (no rebuild needed for Cast-only edits), but a bad quote won't show up in the raw-HTML checks — re-read the edited entries to confirm.

**Portraits.** A cast member with a canonical portrait shows a thumbnail on the Cast gallery (and a click-to-enlarge lightbox). The likeness lives in `characters/` and is wired via the `PORTRAITS` map in `index.html` (`'<Cast Name>': 'characters/<file>.png'`, keyed by the exact cast name). To give a character a portrait, see **Illustrations** below and follow `characters/CANON.md`. A cast entry with no portrait simply renders as text — portraits are optional.

## Workflow — 3. Secrets (Fantasy Grounds Player Notes)

The players' in-world writing lives in the local FG campaign: `%APPDATA%\SmiteWorks\Fantasy Grounds\campaigns\Wrath of the Righteous - AZ\db.xml`, under the `<notes>` node. After a session, **check for new notes** (journals, letters, lore, dreams, ballads, follower accounts) not already represented in `secrets/`, and harvest anything worth keeping.

Extract: read db.xml with `[IO.File]::ReadAllText`, pull the `<notes>…</notes>` block, `[xml]` it, iterate children (`$n.name`, `$n.text.InnerXml`). Convert FG formattedtext → markdown (`<h>`→`###`, `<p>`→paragraph, `<b>/<i>`→`**`/`*`, `<list>/<li>`→bullets, strip the rest, HtmlDecode). Write each as `secrets/<prefix>-<slug>.md` with `# Title`, an italic `*attribution*` line, then the body. **Unify spellings to canon** (see below). Rebuild. If it's unclear whether a note is "new" or belongs in Secrets, list what you found and ask Matt.

## Workflow — 4. Build, publish, and draft the player email

1. Rebuild: `powershell -ExecutionPolicy Bypass -File C:\Users\alast\drezen-archive\build.ps1`
2. Commit & push (outward-facing publish — proceed, it's the skill's purpose, and tell Matt it's live):
   `git -C C:\Users\alast\drezen-archive commit -am "Add <title>"` then `git -C C:\Users\alast\drezen-archive push`. Pages redeploys in ~1 min; verify with `Invoke-WebRequest` against the live URL.
3. **Leave a Gmail draft** to the players linking the latest session — use the Gmail `create_draft` tool. **Draft only; never send** (Matt reviews and sends). Recipients (from the sent recaps): `madcat451@gmail.com` (Marco/Varic), `tstory@rocketmail.com` (Steve/Rabiah), `fenrisdahse@gmail.com` (Fenris/Lupenor), `burticvs@hotmail.com` (Burt/Harlock) — plus `dk2player@gmail.com` if he's a current player (confirm with Matt or the calendar invite). Keep it short: subject like `Pathfinder recap — <Chapter Title> (<date>)`, a one- or two-line teaser, and the site link. To deep-link the new chapter, use `https://mattdahse.github.io/the-fifth-crusade/#/read/ch<order>` where `<order>` is the new chapter's global position (= total chapter count after the build); otherwise link the site root and name the chapter.

## Illustrations & the house art style

The archive is illustrated. Two files govern all of it:
- **`bible/04-visual-style-guide.md`** — the one house look for every generated image (derived from the definitive exemplar `images/arueshalae.png`): cinematic painterly fantasy realism, single cold light source, muted earthy palette with one luminous accent, desolate Worldwound settings. Read it before generating any art.
- **`characters/CANON.md`** — the canonical portrait registry: one authoritative likeness per named character, in `characters/<kebab-name>.png`, with the "likeness anchors" that must never drift.

**The iron rule when generating art (via the `chatgpt-image-gen` skill or any image tool):**

**Step 0 — PRE-FLIGHT, never skip.** Before writing a single word of the prompt, **`Read` the actual `characters/*.png` for every character in the scene** and check the `CANON.md` row against what you see. Do NOT write the prompt from the row alone, and never from memory. This step exists because it was skipped once: the row said Harlock had "small lower tusks" (he has none — clean human jaw) and described Arueshalae's armor as a "leather harness" (it's a fully-covered, long-sleeved leather jacket). Both errors went straight into the prompt and into the published art. If the PNG and the row disagree, **fix the row first**, then prompt.

1. Render in the house style from `04-visual-style-guide.md` (use its prompt scaffold).
2. **Attach the canonical portraits as reference images.** They cannot be attached programmatically — see *Attaching references* below — but they are worth the manual step for any scene with a canon character. Text anchors alone are a fallback, not the standard.
3. **State the corrections as explicit negatives.** Positive description is not enough; image models supply their own defaults for anything left unsaid. Copy the relevant lines from `CANON.md`'s "Known drift" section into the prompt body *and* the `Avoid:` line — e.g. "no tusks, no underbite, clean strong human-like jaw"; "fully covered, modest, practical armor — not a bikini, harness, bare midriff or cleavage."
4. **QA against the references before publishing.** `Read` the generated PNG and check each character feature-by-feature against their portrait. Regenerate rather than shipping a drifted likeness.
5. A genuinely new character is rendered fresh in the house style; once their look is settled, add them to the registry (save `characters/<name>.png`, add a row to `CANON.md`, and — if they're in the Cast — a `PORTRAITS` entry in `index.html`).

**Attaching references (the working procedure).** Every automated channel for getting local image bytes into ChatGPT is blocked: `fetch`/`<img>` from a localhost server dies on Chrome's Private Network Access; OS-clipboard + Ctrl-V doesn't trigger a real paste via CDP; `file_upload` needs a ref from `find`/`read_page`, which time out on chatgpt.com; `upload_image` can't reach captured screenshots. A synthetic `ClipboardEvent` carrying a `File` **does** work — ChatGPT attaches it — but building that `File` requires the base64 in-page, and transcribing ~20k chars by hand corrupts it. So:
1. Copy the needed `characters/*.png` to `~/Downloads` with obvious names (`REF-1-<name>.png`, …).
2. Paste the prompt into the composer (it can sit there un-sent), naming them in order as `REFERENCE 1 = …`, `REFERENCE 2 = …`.
3. Ask Matt to drag those files into the composer and either send, or say "dropped" so you send. It costs him ten seconds and is far cheaper than the alternatives.

**Inline images in a chapter or secret.** Both readers render a standalone markdown image as a captioned figure. Put the file in `images/` (scene art) and, on its own line/paragraph, write `![Caption text](images/<file>.png)`. The alt text is the caption (may hold *italics*/**bold**); an empty caption gives a bare image. `build.ps1` keeps the caption in the search index. A chapter-opening illustration goes between the subtitle line and the first `###`.

## Present results

- One-paragraph summary: book + chapter number, session/date covered, that it's live (link the site).
- What changed in the **Cast** and **Secrets**, if anything.
- That the **player draft** is ready in Gmail for Matt to review and send.
- **Suggested bible updates** (do not silently overwrite `bible/*`): new NPCs/items/locations for `02-dramatis-personae.md` / `03-lore-and-locations.md`, applied only if Matt asks.
- Open questions (uncertain rules calls, unclear intentions, name spellings worth confirming).

## Backfilling a missing or out-of-order session

- **Place it by its real date and book.** Book I = Kenabres through the Gray Garrison; Book II = the march to Drezen through its rebuilding; Book III = the crusade beyond. **Insert** it *between the two chapters that bracket its date* (inside a completed book, insert it **before that book's `<!-- epilogue -->` chapter**), not at the end.
- **Ordering is automatic** — the build renumbers by position; never hand-edit numbers or put a numeral in the header. Cross-reference Matt's FG "Campaign Events" notes (in db.xml) against the chapter dates to spot sessions that never got a chapter.
- **Source is the description + the bible + the FG note.** With no transcript, match the surrounding era's canon and flag anything you had to invent for Matt to confirm.

## Canon spellings (unify FG/transcript drift)

Gray Garrison, Kenabres, Drezen, Aponavisius, Staunton Vhane, Soul Shear, Lupenor Celest, Irabeth Tirabade, Aron Kir, Chirrik, Jaruunicka, Arueshalae, Rothin Vald, Elara Dawnstrider, Solemn Hour, Battle Hymn, Khorramzadeh, Radiance. (FG notes and transcripts often drift: Grey Garrison, Kenabras, Aponavicious, Staunton Vane, Lupinor, Celeste, Irebeth, Aaron Keirr, Chyrrik, Soulshear, Rothen (→ Rothin), Alara Dawnstar (→ Elara Dawnstrider) — fix all of these.)

## Conventions & edge cases

- **Radiance** — Harlock's intelligent sword of Iomedae is effectively an NPC; its warmth/cooling/silence maps to his inner state.
- **Character death** — give it weight; a resurrection is its own beat, not a hand-wave. Reflect it in the Cast with the `'dead'` flag.
- **Mythic trials / level-ups** — frame as story turning points, not mechanical milestones.
- **Continuation across two sessions** — combine into one chapter; put both play dates in the subtitle (e.g. "October 10 & 25, 2025").
- **Player-perspective "vision" pieces** (follower accounts like Aldwin Brightblade, Silas Thorne, Tam; the mythic dreams) now live in **Secrets** as `follower-*` / `dream-*` files — harvest them there, don't fold them into chapters.

## Optional Google Drive mirror

Drive is no longer authoritative. If Matt wants a Drive copy of a chapter, create it with the Drive `create_file` tool (`contentMimeType: text/markdown`), but the repo remains the source of truth.
