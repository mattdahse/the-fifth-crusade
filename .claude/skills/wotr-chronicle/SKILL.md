---
name: wotr-chronicle
description: Compose and publish recaps for Matt's Pathfinder Wrath of the Righteous campaign archive, and keep its Cast, Secrets, in-world calendar, and player-email draft in sync. Use whenever Matt pastes a WotR/Pathfinder session transcript, describes a session from memory, asks for a recap / chronicle update / "Chapter X", asks to update the cast, add a secret, or refresh the campaign calendar/timeline, or refers to the campaign or its characters (Harlock, Varic, Lupenor, Rabiah, Chyrrik, Cornelia). Triggers include "transcript", "recap", "session summary", "chronicle update", "Chapter X", "add to the cast", "new secret", "campaign calendar", "in-world date", "timeline", "Wrath of the Righteous", "WotR", or any pasted multi-paragraph game-session log set in Kenabres, Drezen, the Worldwound, or the Marchlands. Trigger even if the skill is not named — a pasted session log is enough.
---

# WotR Chronicle → Repo & Site

The campaign's **source of truth is the git repository** — the checkout you are running in, which is
`drezen-archive` on each of Matt's three stations (two Macs and a PC). **Never hardcode an absolute
path to it**; use repo-relative paths throughout, so the same instructions work at every station.
Public GitHub Pages site: **https://mattdahse.github.io/the-fifth-crusade/**. Google Drive is a
retired backup. Maintaining the archive after a session means up to **five** jobs — do all that apply:

1. **Chronicle** — write the session's chapter and publish it.
2. **Cast** — add any new persons of importance (allies, enemies, notable NPCs); mark the dead.
3. **Secrets** — check the Fantasy Grounds Player Notes for anything new worth harvesting.
4. **Calendar** — pull the session's new in-world days out of Fantasy Grounds.
5. **Player draft** — leave a Gmail *draft* to the players linking the latest session.

## Repository layout

- `source/book-1-the-worldwound-incursion.md`, `book-2-the-sword-of-valor.md`, `book-3-demons-heresy.md` — the chronicle, one book per Adventure Path volume. **Book III is ongoing; new sessions go there.** Books I and II are complete (each closed with an `<!-- epilogue -->` chapter).
- `secrets/*.md` — a **parallel corpus** of in-world documents (the "Secrets" tab), grouped by filename prefix: `dream-`, `follower-`, `letter-`, `lore-`, `staunton-vhane-journal-`.
- `index.html` — the reader app. **The Cast is hand-authored here** (the `CAST` array), NOT built from source.
- `bible/00-style-and-prompt-guide.md`, `02-dramatis-personae.md`, `03-lore-and-locations.md` — authoring reference; Matt curates these.
- `build.ps1` — compiles `source/*.md` + `secrets/*.md` → `data.js`. Run after any source/secrets change.
- `extract-calendar.ps1` → `bible/06-in-world-calendar.json` — the campaign's in-world dates, pulled from Fantasy Grounds. Paired with `bible/06-in-world-calendar.md`, the hand-written prose calendar. **Neither is published** — they are authoring reference, not site content.
- Chapters are **not numbered in the markdown**; the build assigns each book's Roman numeral by position (last = `Epilogue`). Each chapter's **real-world play date** is read from its subtitle line (`*<Month Day, Year> session — …*`) and shown on the site. Recordings are **not surfaced** on the site (Matt finds them in Fathom by date), but every chapter written from a recording carries a `<!-- fathom: call=<call-id> recording=<recording-id> -->` line — see **Recording metadata** below. If a subtitle can't carry a full date, add `<!-- date: Month Day, Year -->`.

**Encoding:** always read/write with `[IO.File]::ReadAllText/WriteAllText` (UTF-8), never `Get-Content -Raw`. Never type an em-dash literal into a `.ps1` — use `[char]0x2014`. These rules originally guarded against Windows PowerShell 5.1 reading ANSI; keep them anyway, since they're also what makes the build byte-identical across the Macs and the PC.

## Inputs

- **A session transcript** pasted in chat, **or Matt's description** from memory, **or** just "do the recap" (figure out the next chapter from the chronicle). Sometimes with a chapter number/direction.
- The session's **real-world play date** — put it in the subtitle. If unknown, check Matt's Google Calendar: the recurring event is **"Pathfinder"** (`fullText:"Pathfinder"`, roughly biweekly Fri/Sat); read the session date from there.

## Recording metadata — record BOTH ids

Fathom gives a session **two different numbers**, and they are easy to confuse:

- the **call id**, which is what appears in the share URL — `https://fathom.video/calls/650843307`
- the **recording id**, which is what every Fathom tool takes as `recording_id` — `141062294`

Passing a call id to `get_meeting_transcript` fails with *"recording_id not found or access denied"*, which reads like a permissions problem and is not one. Every chapter therefore stores both:

```
<!-- fathom: call=650843307 recording=141062294 -->
```

**Whenever you write or revise a chapter from a recording, make sure its marker carries both.** To get the pair, call `list_meetings` bounded to the play date (`created_after` / `created_before` a day either side) and read `recording_id` and `url` off the Pathfinder entry — the number in `url` is the call id, the `id` field is the recording id. The session is titled variously *Pathfinder*, *Online Pathfinder*, *In Person Pathfinder*, *Hybrid in person/zoom pathfinder* — match on the date, not the title.

The line is inert: `build.ps1` strips any `<!-- fathom … -->` line before rendering, so the format is free to carry whatever is useful and nothing reaches the site.

**Validating an existing chapter against its recording** is the same lookup in reverse: read the marker, use the `recording=` number directly. Transcripts run long — a six-hour session is ~1,900 lines and will not fit one `Read`; pull it in sequential chunks of ~250–300 lines and read all of it before judging the chapter, because the reconciling detail is as likely to be in the last hour as the first.

**Speaker labels in Fathom transcripts are unreliable.** They drift, swap, and attribute a player's line to the DM. Identify who did what from *content* — a Fireball is Rabiah's, a Holy Smite is Varic's, "what I have memorized" means a prepared caster — not from the name on the line.

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

**Portraits.** A cast member with a canonical portrait shows a thumbnail on the Cast gallery (and a click-to-enlarge lightbox). The likeness lives in `characters/` and is wired via the `PORTRAITS` map in `index.html` (`'<Cast Name>': 'characters/<file>.webp'`, keyed by the exact cast name). To give a character a portrait, see **Illustrations** below and follow `characters/CANON.md`. A cast entry with no portrait simply renders as text — portraits are optional.

## Workflow — 3. Secrets (Fantasy Grounds Player Notes)

The players' in-world writing lives in the local FG campaign: `%APPDATA%\SmiteWorks\Fantasy Grounds\campaigns\Wrath of the Righteous - AZ\db.xml`, under the `<notes>` node. After a session, **check for new notes** (journals, letters, lore, dreams, ballads, follower accounts) not already represented in `secrets/`, and harvest anything worth keeping.

Extract: read db.xml with `[IO.File]::ReadAllText`, pull the `<notes>…</notes>` block, `[xml]` it, iterate children (`$n.name`, `$n.text.InnerXml`). Convert FG formattedtext → markdown (`<h>`→`###`, `<p>`→paragraph, `<b>/<i>`→`**`/`*`, `<list>/<li>`→bullets, strip the rest, HtmlDecode). Write each as `secrets/<prefix>-<slug>.md` with `# Title`, an italic `*attribution*` line, then the body. **Unify spellings to canon** (see below). Rebuild. If it's unclear whether a note is "new" or belongs in Secrets, list what you found and ask Matt.

## Workflow — 4. The Calendar (Fantasy Grounds campaign dates)

Matt keeps the crusade's **in-world dates** on the Fantasy Grounds calendar, one log entry per
game day. The archive mirrors them so chapters can be checked against the dates the table actually
kept. **This is reference only — it is not built into `data.js` and not exposed on the site.**

After a session, from the repo root:

```
pwsh -File ./extract-calendar.ps1
```

It finds `db.xml` itself at any of the three stations, rewrites `bible/06-in-world-calendar.json`
(raw and verbatim — **machine-written, never hand-edit it**), and prints the days that are new
since the last run. **Write those new days into `bible/06-in-world-calendar.md` by hand**, in the
chronicle's voice: one bullet per day under its month heading, third-person, **bold** proper
names, ***italic*** relics and spells, no mechanics. The FG log is table shorthand — terse,
misspelled, sometimes a bare supply count — so it is rewritten, not pasted. Unify every name
against **Canon spellings** below.

Where the log and the chronicle genuinely disagree — a death the chapters tell differently, a name
that appears nowhere in `source/` — do **not** quietly pick a winner. Render the line to match the
chronicle and add it to the **Open discrepancies** section at the foot of that file for Matt.

If the extractor reports no new days, Matt simply hasn't advanced the FG calendar yet; say so
rather than inventing dates.

## Workflow — 5. Build, publish, and draft the player email

1. Rebuild, from the repo root: `pwsh -File ./build.ps1`
   (The archive is maintained from three stations — two Macs and a PC — so run it from wherever the checkout lives; `build.ps1` resolves its own paths and never needs an absolute one. Use **PowerShell 7 (`pwsh`)** at every station, not Windows PowerShell 5.1: the two serialize JSON differently and mixing them churns all of `data.js` on every commit.)
2. Commit & push (outward-facing publish — proceed, it's the skill's purpose, and tell Matt it's live):
   `git commit -am "Add <title>"` then `git push`, from the repo root. Pages redeploys in ~1 min; verify against the live URL.
3. **Leave a Gmail draft** to the players linking the latest session — use the Gmail `create_draft` tool. **Draft only; never send** (Matt reviews and sends). Recipients (from the sent recaps): `madcat451@gmail.com` (Marco/Varic), `tstory@rocketmail.com` (Steve/Rabiah), `fenrisdahse@gmail.com` (Fenris/Lupenor), `burticvs@hotmail.com` (Burt/Harlock) — plus `dk2player@gmail.com` if he's a current player (confirm with Matt or the calendar invite). Keep it short: subject like `Pathfinder recap — <Chapter Title> (<date>)`, a one- or two-line teaser, and the site link. To deep-link the new chapter, use `https://mattdahse.github.io/the-fifth-crusade/#/read/ch<order>` where `<order>` is the new chapter's global position (= total chapter count after the build); otherwise link the site root and name the chapter.

## Illustrations & the house art style

The archive is illustrated. Three files govern all of it:
- **`bible/04-visual-style-guide.md`** — the one house look for every generated image (derived from the definitive exemplar `images/arueshalae.webp`): cinematic painterly fantasy realism, single cold light source, muted earthy palette with one luminous accent, desolate Worldwound settings. Read it before generating any art.
- **`characters/CANON.md`** — the canonical portrait registry: one authoritative likeness per named character, in `characters/<kebab-name>.webp`, with the "likeness anchors" (face, build, coloring) that must never drift.
- **`bible/05-kit-and-timeline.md`** — the era-by-era **gear** guide. A character's face is constant (CANON) but their armour/weapons/relics change as the story advances. Read the era block matching the scene and take the kit from there — early Book I is battered and poorly-equipped, **not** the later gilded look (early Harlock has no golden plate and a dimmed, lightless Radiance; early Varic is a humble priest, no gold filigree). Update this file when the company re-equips. ⚠️ **Do not police a "gold circlet" on Varic in any era** — his gold hair and temple braids read as one, and it was a false positive every time it was checked.

**The iron rule when generating art (via the `chatgpt-image-gen` skill or any image tool):**

**Step 0 — PRE-FLIGHT, never skip.** Before writing a single word of the prompt, **`Read` the actual `characters/*.webp` for every character in the scene** and check the `CANON.md` row against what you see. Do NOT write the prompt from the row alone, and never from memory. This step exists because it was skipped once: the row said Harlock had "small lower tusks" (he has none — clean human jaw) and described Arueshalae's armor as a "leather harness" (it's a fully-covered, long-sleeved leather jacket). Both errors went straight into the prompt and into the published art. If the portrait and the row disagree, **fix the row first**, then prompt.

1. Render in the house style from `04-visual-style-guide.md` (use its prompt scaffold).
2. **Attach the canonical portraits as reference images.** They cannot be attached programmatically — see *Attaching references* below — but they are worth the manual step for any scene with a canon character. Text anchors alone are a fallback, not the standard.
3. **State the corrections as explicit negatives.** Positive description is not enough; image models supply their own defaults for anything left unsaid. Copy the relevant lines from `CANON.md`'s "Known drift" section into the prompt body *and* the `Avoid:` line — e.g. "no tusks, no underbite, clean strong human-like jaw"; "fully covered, modest, practical armor — not a bikini, harness, bare midriff or cleavage."
4. **QA against the references before publishing.** `Read` the generated PNG and check each character feature-by-feature against their portrait. Regenerate rather than shipping a drifted likeness.
5. A genuinely new character is rendered fresh in the house style; once their look is settled, add them to the registry (save `characters/<name>.webp`, add a row to `CANON.md`, and — if they're in the Cast — a `PORTRAITS` entry in `index.html`).

**Attaching references (the working procedure).** Every automated channel for getting local image bytes into ChatGPT is blocked: `fetch`/`<img>` from a localhost server dies on Chrome's Private Network Access; OS-clipboard + Ctrl-V doesn't trigger a real paste via CDP; `file_upload` needs a ref from `find`/`read_page`, which time out on chatgpt.com; `upload_image` can't reach captured screenshots. A synthetic `ClipboardEvent` carrying a `File` **does** work — ChatGPT attaches it — but building that `File` requires the base64 in-page, and transcribing ~20k chars by hand corrupts it. So:
1. Copy the needed `characters/*.webp` to `~/Downloads` with obvious names (`REF-1-<name>.webp`, …).
2. Paste the prompt into the composer (it can sit there un-sent), naming them in order as `REFERENCE 1 = …`, `REFERENCE 2 = …`.
3. Ask Matt to drag those files into the composer and either send, or say "dropped" so you send. It costs him ten seconds and is far cheaper than the alternatives.

**Inline images in a chapter or secret.** Both readers render a standalone markdown image as a captioned figure. Put the file in `images/` (scene art) and, on its own line/paragraph, write `![Caption text](images/<file>.webp)`. The alt text is the caption (may hold *italics*/**bold**); an empty caption gives a bare image. `build.ps1` keeps the caption in the search index. A chapter-opening illustration goes between the subtitle line and the first `###`.

## Present results

- One-paragraph summary: book + chapter number, session/date covered, that it's live (link the site).
- What changed in the **Cast**, **Secrets**, and the **Calendar**, if anything — for the calendar, name the in-world days added and any new discrepancy flagged.
- That the **player draft** is ready in Gmail for Matt to review and send.
- **Suggested bible updates** (do not silently overwrite `bible/*`): new NPCs/items/locations for `02-dramatis-personae.md` / `03-lore-and-locations.md`, applied only if Matt asks.
- Open questions (uncertain rules calls, unclear intentions, name spellings worth confirming).

## Backfilling a missing or out-of-order session

- **Place it by its real date and book.** Book I = Kenabres through the Gray Garrison; Book II = the march to Drezen through its rebuilding; Book III = the crusade beyond. **Insert** it *between the two chapters that bracket its date* (inside a completed book, insert it **before that book's `<!-- epilogue -->` chapter**), not at the end.
- **Ordering is automatic** — the build renumbers by position; never hand-edit numbers or put a numeral in the header. Cross-reference Matt's FG "Campaign Events" notes (in db.xml) against the chapter dates to spot sessions that never got a chapter.
- **Source is the description + the bible + the FG note.** With no transcript, match the surrounding era's canon and flag anything you had to invent for Matt to confirm.

## Canon spellings (unify FG/transcript drift)

Gray Garrison, Kenabres, Drezen, Aponavisius, Staunton Vhane, Soul Shear, Lupenor Celest, Irabeth Tirabade, Aron Kir, Chyrrik, Jaruunicka, Arueshalae, Rothin Vald, Elara Dawnstrider, Solemn Hour, Battle Hymn, Khorramzadeh, Radiance. (FG notes and transcripts often drift: Grey Garrison, Kenabras, Aponavicious, Staunton Vane, Lupinor, Celeste, Irebeth, Aaron Keirr, Chyrrik, Soulshear, Rothen (→ Rothin), Alara Dawnstar (→ Elara Dawnstrider) — fix all of these.)

Also settled, and worth watching for because the table itself says both:

- **Derakni** — the horse-sized abyssal locust demon: six legs, scorpion stinger, clawed forelimbs, a mesmerising sonic drone, and a summoned wasp swarm. The table says **Darachne** about as often as Derakni and means the same creature; **Derakni governs everywhere**, and it is *not* spider-bodied — never describe it as one.
- **Jeskar Hinton**, never "Jesker". **Lenne Marsh**, never "Lenny". **Selyse Avelia**, not "Selise Aviala". **Abner Suthi**, never "Avner". **Deren Ashfall**, never "Daren". **Adara Seln**, not "Sein".
- **Vorimeraak** — the mythic vrock of the Molten Scar, and **she is female**, against the transcript's spelling ("Vremorak") and its male pronouns. Settled by Matt, Aug 2026.

## Conventions & edge cases

- **Radiance** — Harlock's intelligent sword of Iomedae is effectively an NPC; its warmth/cooling/silence maps to his inner state.
- **Character death** — give it weight; a resurrection is its own beat, not a hand-wave. Reflect it in the Cast with the `'dead'` flag.
- **Mythic trials / level-ups** — frame as story turning points, not mechanical milestones.
- **Continuation across two sessions** — combine into one chapter; put both play dates in the subtitle (e.g. "October 10 & 25, 2025").
- **Player-perspective "vision" pieces** (follower accounts like Aldwin Brightblade, Silas Thorne, Tam; the mythic dreams) now live in **Secrets** as `follower-*` / `dream-*` files — harvest them there, don't fold them into chapters.

## Optional Google Drive mirror

Drive is no longer authoritative. If Matt wants a Drive copy of a chapter, create it with the Drive `create_file` tool (`contentMimeType: text/markdown`), but the repo remains the source of truth.
