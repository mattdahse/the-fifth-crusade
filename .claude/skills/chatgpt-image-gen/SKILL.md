---
name: chatgpt-image-gen
description: Generate chronicle artwork by driving Matt's own logged-in ChatGPT tab in the browser and saving the renders as WebP into images/. Use whenever the task is to illustrate a chapter, add a scene image, give a character a canonical portrait, or regenerate or revise existing art — e.g. "illustrate chapter X", "add images to this chapter", "give <character> a face", "regenerate that picture", "the lances are wrong, try again". Reach for this BEFORE hand-rolling browser automation against ChatGPT: it encodes the non-obvious workarounds (composer clearing, reference-vs-render disambiguation, renderer wedging, CDP timeouts) that otherwise take many painful passes to rediscover.
---

# Chronicle art via ChatGPT in the browser

Art for this archive is generated through **Matt's own logged-in ChatGPT tab**, not an image API.
ChatGPT hands back a full-res PNG; that PNG is **converted to WebP q82** and saved into `images/`
(scene art) or `characters/` (canonical portraits), wired into the markdown, rebuilt, and pushed.
**The archive stores WebP and only WebP** — see step F for why, and never commit the PNG.

This file covers the **mechanics**. The **look** is governed by two files in this repo, and you read
them first, every time:

- `bible/04-visual-style-guide.md` — the house look, the prompt scaffold, and the combat/eyeline rules.
- `characters/CANON.md` — the canonical likeness of every named character, and the "Known drift"
  list of things the model invents unless you forbid them explicitly.
- `bible/05-kit-and-timeline.md` — what a character is *wearing* at this point in the story.
  Face from `CANON.md`, gear from here.

**Step 0 — pre-flight, never skip.** Before writing a word of prompt, `Read` the actual
`characters/*.webp` for everyone in the scene and check it against their `CANON.md` row. Do not write
a likeness from the row alone, and never from memory. If the portrait and the row disagree, fix the
row first.

---

## Works the same on the Macs and the PC

The archive is maintained from three stations (two Macs and a PC). Everything below is written to
run at any of them. Two rules make that true:

- **Never hardcode an absolute path.** Use repo-relative paths for repo files, and `~/Downloads`
  for the browser's download folder. Where a shell command differs by platform, both forms are given.
- **The browser extension must be on the SAME machine as your file tools.** This is the single
  biggest cross-platform failure, and it is silent: downloads land on whatever machine the browser
  is running on. If your file tools are on the Mac but the extension answering you is Chrome on the
  PC, the PNG downloads to the PC and the Mac reports `NOT FOUND`.

  Always start with `list_connected_browsers` and select the device with **`isLocal: true`**:

  ```
  list_connected_browsers   →  pick the entry with isLocal: true
  select_browser(deviceId)
  ```

  If more than one browser is connected, **ask Matt which one** — do not pick silently. If the only
  connected browser is not local, stop and say so; there is no way to retrieve the file afterwards.

Do not attempt to log in, solve a CAPTCHA, or accept a dialog on Matt's behalf. If you hit one, stop
and tell him.

---

## The loop, one image at a time

### A. Fresh chat

`navigate(TAB, "https://chatgpt.com/")`, then wait ~3s. A fresh chat per image avoids state bleed
and keeps the DOM light.

### B. Stage the reference portraits

References **cannot be attached programmatically** — `file_upload` needs a ref from `find`/`read_page`,
and both reliably time out on chatgpt.com. So stage the files where Matt can drag them in one motion,
then ask him to.

```bash
# macOS / Linux
rm -f ~/Downloads/REF-*.webp
cp characters/harlock.webp ~/Downloads/REF-1-harlock.webp
cp characters/rabiah.webp  ~/Downloads/REF-2-rabiah.webp
ls -l ~/Downloads/REF-*.webp
```

```powershell
# Windows / PowerShell
Remove-Item "$HOME\Downloads\REF-*.webp" -Force -ErrorAction SilentlyContinue
Copy-Item characters\harlock.webp "$HOME\Downloads\REF-1-harlock.webp" -Force
Copy-Item characters\rabiah.webp  "$HOME\Downloads\REF-2-rabiah.webp" -Force
Get-ChildItem "$HOME\Downloads\REF-*.webp" | Select-Object Name,Length
```

*(`$HOME` works in PowerShell 7 on every platform, which is what Matt runs everywhere — prefer it to
`$env:USERPROFILE`.)*

**Label references by what they depict, not by number**, because drop order is not guaranteed:

> The GREEN-SKINNED HALF-ORC MAN = Harlock. Take his FACE ONLY — ignore his armour.
> The RED-HAIRED GIRL IN GREEN = Rabiah.

### C. Paste the prompt — and clear the composer properly first

The composer is a **ProseMirror contenteditable** whose React state ignores typed text and
`execCommand('insertText')`; the send button stays disabled. You must dispatch a real paste event.

**Two traps that cost real time:**

1. **ChatGPT persists the composer draft across reloads.** Navigating to a fresh chat does *not*
   clear it.
2. **A clear that does not actually clear makes the paste APPEND.** The paste event always inserts
   at the selection; if the old draft is still there, you send two or three copies of the prompt.

> **⚠️ THE "SELF-SUBMITTING PASTE" WAS NEVER REAL — DO NOT REINTRODUCE IT.** This file used to warn
> at length that a pasted prompt could submit itself, that a draft carrying attachments could fire on
> its own, and that references therefore had to be attached *before* the prompt was pasted. **None of
> that happens.** *(Corrected by Matt, Aug 2026.)* Every observation behind it was the same
> misreading: **Matt pressed the send button himself**, and the next verification call found the
> message already sent and concluded the composer had fired unprompted. The workflow was then rebuilt
> around a phantom, which cost him an extra drag step on every single image.
>
> **If you ever find a message sent that you did not send, assume Matt sent it.** Ask him before
> writing anything down. A misattributed platform bug hardens into a rule and every later image pays
> for it.

**So make clearing its own step, and VERIFY the slate is clean before you paste.** Navigate, then
clear and check in one call, and only paste once all three of these read empty:

```js
const pm = document.querySelector('div.ProseMirror'); pm.focus();
const sel = window.getSelection(); sel.removeAllRanges();
const r = document.createRange(); r.selectNodeContents(pm); sel.addRange(r);
document.execCommand('delete');
({ pmLen: pm.textContent.length,                                        // want 0
   msgs: document.querySelectorAll('[data-message-author-role]').length, // want 0
   attachments: document.querySelectorAll('form img, [data-testid*="attachment"]').length }) // want 0
```

If `msgs` is non-zero you are not on a fresh chat. If `attachments` is non-zero, a draft's references
are still loaded and a paste may fire them off — clear it and re-verify before going further.

The clear that works is an **explicit Range over the ProseMirror node's contents**, then `delete`:

```js
const pm = document.querySelector('div.ProseMirror'); pm.focus();
const sel = window.getSelection(); sel.removeAllRanges();
const r = document.createRange(); r.selectNodeContents(pm); sel.addRange(r);
document.execCommand('delete');
const t = `Please generate this image directly. Aspect ratio 3:2. <FULL PROMPT + Avoid: line>`;
const dt = new DataTransfer(); dt.setData('text/plain', t);
pm.dispatchEvent(new ClipboardEvent('paste', {clipboardData: dt, bubbles: true, cancelable: true}));
({len: pm.textContent.length, want: t.length})
```

*(This reverses what this file said before July 2026. `execCommand('selectAll')` followed by
`execCommand('delete')` — previously documented as the fix — now silently leaves the draft in place,
and the next paste appends to it. Caught on the Chapter XV art: a 5,338-char draft plus a 7,251-char
prompt verified at 12,504. The Range form still clears to 0. If **both** forms ever fail, fall back
to a real gesture: click the composer, then `key` `cmd+a` / `ctrl+a` followed by `Delete`.)*

Then **verify in a separate call** that exactly one copy landed before sending:

```js
const pm = document.querySelector('div.ProseMirror');
const btn = document.querySelector('#composer-submit-button, button[data-testid="send-button"], button[aria-label*="Send"]');
({len: pm.textContent.length, disabled: btn ? btn.disabled : null})
```

If `len` is a multiple of your prompt length, you have duplicates — clear and repaste.

**Prefix every prompt with `Please generate this image directly.`** Many accounts default to a
reasoning model that otherwise stalls in a long "Thinking" loop. **Put the aspect ratio in the text**
(`Aspect ratio 3:2.`); there is no reliable UI control for it.

### THE HANDOFF — paste the prompt, then get out of the way

**This is the settled workflow. Follow it exactly.**

1. Navigate to a fresh chat and verify the composer is clean (`pmLen`, `msgs`, `attachments` all 0).
2. **Paste the prompt.** Verify exactly one copy landed.
3. **Stop. Tell Matt the prompt is in, and name the staged `REF-*.webp` files he needs to drag.**
   He attaches the references **and presses send himself.**
4. **Wait.** Do not poll the tab, do not click send, do not "check whether it started." **Matt tells
   you when the image has resolved.** Only then do you go to step D/E and pull the render down.

**Why the handoff and not automation:** references cannot be attached programmatically —
`file_upload` needs a ref from `find`/`read_page`, and both reliably time out on chatgpt.com. Since
he has to touch the keyboard anyway, he sends too. One handoff, one hand-back, no polling in between.

**When a scene needs NO references** — an establishing shot, a rite, a landscape, anonymous crowds —
there is nothing to drag, so send it yourself rather than making him wait. **Do not click the send
button by coordinate: it silently no-ops.** The button reports as found, enabled, and correctly
positioned, the click returns success, and the composer still holds the prompt. Call the DOM method
instead:

**Do it in a SEPARATE call from the paste.** Immediately after pasting, `#composer-submit-button`
is often still `null` — React has not mounted it yet — and `.click()` on null throws, leaving the
prompt sitting unsent. Paste, verify the length, then send in the next call. Scoping the lookup to
the composer's `<form>` is more robust than a bare document query:

```js
const btn = document.querySelector('form #composer-submit-button');
btn.click();
await new Promise(r => setTimeout(r, 2000));
({composerLen: document.querySelector('div.ProseMirror').textContent.length,
  msgCount: document.querySelectorAll('[data-message-author-role]').length})
```

A `composerLen` of 0 means it went. (Unlike the download anchor in step E, this needs no user
gesture — the gesture requirement is specific to `a.download`, not to ordinary buttons.)

**A render can take well over a minute, and finishing is not instant.** `gen` going false does not
mean the image is in the DOM yet; on the Chapter XVI edits the new render appeared a good twenty
seconds after the generating indicator cleared. If `gen` is false but the byte count still matches
the previous render, scroll to the bottom and wait one more cycle before concluding it failed.

### D. Wait for the render

Poll with **short** `computer{action:"wait", duration:10}` steps (`duration` is capped at 10), then
check state in a separate small call.

> **Never `await` a long sleep inside `javascript_tool`.** The CDP bridge times out at ~45 seconds,
> so an in-page `setTimeout` of 45s fails the call *and* can leave the paste half-applied. Keep every
> in-page sleep under ~3s and do the waiting with the `wait` action instead. A CDP timeout after a
> long in-page sleep is your own doing, not a wedged tab — check the composer before assuming damage.

```js
const gen = [...document.querySelectorAll('button')].some(b => /stop answering/i.test(b.getAttribute('aria-label') || ''));
const a = [...document.querySelectorAll('img')].filter(i => i.naturalWidth > 700 && !i.closest('[data-message-author-role="user"]'));
({gen, n: a.length})
```

Done when `gen` is false and an assistant image is present. A finished image often appears as 3–4
overlapping DOM nodes (progressive layers); that is normal, not multiple renders.

### E. Download the full-res PNG

**Two traps:** the image `src` is redacted to your tools as `[BLOCKED: Cookie/query string data]`
(but an in-page `fetch` still works), and a script-initiated `a.click()` only fires once per page
before user-activation is consumed. So build a *visible* anchor and click it with a real gesture.

**Critically — exclude the reference images.** Matt's attached portraits are `<img>` elements too,
and they frequently share the render's exact dimensions (several `characters/*.webp` are 1086×1448,
which is also a common 3:4 output size). Filtering by size alone *will* eventually download a
reference portrait back over your scene art. Filter by message role:

**`cand[cand.length - 1]` is NOT reliably the newest.** In a chat with several renders the DOM
virtualizes and reorders, and the last candidate is often an *earlier* image — you will silently
re-download a render you already have. It cost a full round of confusion on the Chapter XVI
death scene. **Verify by blob size** (each render has a distinct byte count; you already know the
size of the one you saved last), or sort by document position and take the lowest:

```js
// Find the newest by picking the one whose bytes you have NOT seen before.
const seen = 2492722;                                    // blobSize of the render you already saved
const imgs = [...document.querySelectorAll('img')].filter(i => i.naturalWidth > 700);
let img = null, blob = null;
for (const x of imgs) {
  const b = await (await fetch(x.currentSrc || x.src)).blob();
  if (b.size !== seen) { img = x; blob = b; break; }      // the new one
}
```

**Also note:** Matt's dropped reference portraits are large images too, and on a fresh chat they
sort *first*. Filtering on `naturalWidth > 700` alone will happily hand you `rabiah.webp` back.
Keep the `[data-message-author-role="user"]` exclusion, and sanity-check the byte count against the
`REF-*.webp` sizes before moving the file.

```js
const cand = [...document.querySelectorAll('img')]
  .filter(i => i.naturalWidth > 700 && !i.closest('[data-message-author-role="user"]'));
const img = cand[cand.length - 1];                       // ONLY safe on a single-render chat
const b = await (await fetch(img.currentSrc || img.src)).blob();
const url = URL.createObjectURL(b);
document.getElementById('__dl')?.remove();
const a = document.createElement('a');
a.id = '__dl'; a.href = url; a.download = 'the-scene-name.png'; a.textContent = 'CLAUDEDLBUTTON';
a.style.cssText = 'position:fixed;top:20px;left:20px;z-index:2147483647;background:#e11;color:#fff;font-size:22px;padding:18px 26px;font-weight:bold;border-radius:8px;';
document.documentElement.appendChild(a);                  // documentElement survives React re-renders
const r = a.getBoundingClientRect();
({blobSize: b.size, x: Math.round(r.left + r.width/2), y: Math.round(r.top + r.height/2)})
```

Then click it by coordinate: `computer{action:"left_click", tabId:TAB, coordinate:[x,y]}`.
**Do not use `find`** to locate it — `find` and `read_page` wait for `document_idle`, which ChatGPT's
streaming SPA often never reaches, so they die on a ~45s timeout even when the page is perfectly
healthy.

> ### ⚠️ CLICK COORDINATES ARE SCREENSHOT PIXELS, NOT CSS PIXELS — SCALE THEM
>
> `getBoundingClientRect()` returns **CSS pixels**, but `computer{left_click}` takes coordinates in
> **screenshot pixel space**, and on a normal display these are NOT the same. Measured Aug 2026:
> viewport `window.innerWidth` **1920**, screenshot width **1568** → every coordinate must be
> multiplied by **0.8167**. Feed a raw rect coordinate to a click and you land ~230px to the right of
> what you aimed at.
>
> ```js
> const ratio = SCREENSHOT_WIDTH / window.innerWidth;   // e.g. 1568/1920 = 0.8167
> const r = el.getBoundingClientRect();
> ({ x: Math.round((r.left + r.width/2) * ratio),
>    y: Math.round((r.top  + r.height/2) * ratio) })
> ```
>
> **Why this never bit us before:** the download anchor built above is deliberately enormous
> (~250×60 CSS px), so a click aimed with unscaled coordinates still landed inside it. **The anchor's
> size is load-bearing, not decorative — do not shrink it.** The error only surfaced when clicking a
> small native control, which missed completely and hit empty page.
>
> Take the screenshot width from the `computer{action:"screenshot"}` result rather than assuming
> 1568; it depends on the window.

Note the returned `blobSize`; you verify against it in the next step.

### F. Verify the bytes, then CONVERT TO WEBP into the repo

ChatGPT hands you a PNG, and a PNG is **not** what the archive stores. Verify the download first,
**while it is still a PNG and still has the byte count you measured**, then convert.

```bash
# macOS / Linux
sleep 1
wc -c < ~/Downloads/the-scene-name.png          # must equal blobSize
cwebp -q 82 -m 6 ~/Downloads/the-scene-name.png -o images/the-scene-name.webp
rm ~/Downloads/the-scene-name.png
ls -l images/the-scene-name.webp
```

```powershell
# Windows / PowerShell
Start-Sleep -Milliseconds 1200
(Get-Item "$HOME\Downloads\the-scene-name.png").Length     # must equal blobSize
cwebp -q 82 -m 6 "$HOME\Downloads\the-scene-name.png" -o images\the-scene-name.webp
Remove-Item "$HOME\Downloads\the-scene-name.png" -Force
(Get-Item images\the-scene-name.webp).Length
```

**Check the PNG's size against `blobSize` BEFORE converting.** If it does not match, you downloaded a
different file — most likely a stale download of the same name, or a reference portrait. Also
sanity-check that it is not the byte size of any `REF-*.webp` you staged.

**Never commit the PNG.** The whole library is WebP q82 — 407 MB of PNG was overrunning the GitHub
Pages deploy and timing it out, and the conversion took the published site to 28 MB. *(Aug 2026: two
consecutive deploys failed at `deployment_queued` before this was found.)* A single stray 3 MB PNG
will not break anything on its own, but the rule is the library stays one format. **Portraits saved
into `characters/` follow the identical step.**

**q82 is the settled quality and it is visually lossless on this art** — Matt approved it against a
1:1 crop of a dusk-sky gradient, the worst case for banding. Do not lower it to save bytes and do not
raise it without asking.

### G. QA against canon, then wire it in

`Read` the saved WebP — the Read tool opens WebP natively, so this needs no decode step — and check
each named figure feature-by-feature against their portrait, plus the style guide's combat checklist.
Regenerate rather than shipping a drifted likeness.

Then place it in the markdown on its own paragraph — `![Caption text](images/<file>.webp)` — rebuild
with `pwsh -File ./build.ps1`, and commit. Record any accepted drift in the commit message so the
decision is findable later.

---

## Revising an image: REGENERATE FROM SCRATCH — do not edit in place

**This is Matt's standing instruction, and it overrides the convenience of an edit.** When he asks
for a change, open a **fresh chat**, re-stage the references, and rebuild the whole prompt with the
correction folded in. Do not send a follow-up "edit this image" message in the existing chat.

**Why:** ChatGPT's in-place edit re-encodes the image and **costs resolution and quality every
pass.** The frame comes back softer and mushier than the one it was derived from, and the loss
compounds with each edit. A regeneration is a clean render at full quality. Matt would rather re-roll
the composition and lose a good one than publish a degraded version of it.

*(This file previously recommended the opposite. It was wrong: it optimized for preserving the
composition and never accounted for the quality cost. Corrected on Matt's direction, July 2026,
mid-way through the Chapter XVI art — the ceiling-crawl revision of `the-light-that-found-him`.)*

**So when a render comes back with notes:**

1. Fold every note into the *original* prompt text, at the place it belongs — don't append a
   corrections paragraph. If a pose was misread, rewrite the pose description from scratch and be
   mechanical about the anatomy (see *Prompt craft* below); restating it the same way will fail the
   same way.
2. Add the specific failure to that prompt's `Avoid:` line, phrased as the thing you got: the
   ceiling-crawl came back as *lying on his back with his spine against the ceiling*, so
   `the vampire lying on his back against the ceiling, his belly facing down toward the viewer`
   went into Avoid verbatim.
3. Fresh chat, re-stage refs, ask Matt to drop them, send.

**If the SAME object fails THREE times, stop rewriting it and RESTAGE the scene so the failure is
structurally impossible.** Two re-rolls of a description is the honest budget; past that you are
not fixing a prompt, you are hoping. The tell is that the faults *move around* while staying the
same kind of fault — an extra hand here, a fused arrowhead there, a string wandering off frame —
which means the model cannot hold that assembly of parts at that scale, and no amount of adjective
will teach it to.

Ask instead: **what is the smallest change to the staging that deletes the hard object?** Usually
it is shifting the depicted instant a beat earlier or later, or separating two things that were
touching. *(Aug 2026, `the-clash-beneath-the-fortress-gate`: three rolls of "undrawn bow with a
nocked arrow, plus a second person's hands grabbing the same arm" produced a fist grip, then extra
hands and an arrowhead welded to the bow limb, then another extra hand and the same welded
arrowhead. The fix was not a fourth description — it was moving the moment one beat earlier, to
Lenne pulling the arrow **clear of her quiver** before nocking it. Bow alone in one hand, arrow
alone in the other, nothing touching the string, and the whole failure mode gone.)*

**Two RIGHT hands on one person is its own failure, and the fix is to remove a hand from the
frame.** When a character grips something with one hand and holds gear in the other, the model
frequently paints both as the same chirality — thumb on the wrong side — and the grip then reads
as anatomically impossible. Naming handedness helps a little; **giving them only one visible hand
helps completely.** Sling the bow across their back, drop the other arm below the frame edge, or
put the spare gear on a belt. *(Aug 2026, `the-clash-beneath-the-fortress-gate`: Lupenor grabbed a
wrist with one hand and held her longbow in the other, and both came back as right hands. Slinging
the bow deleted the problem.)*

**Enumerate ambiguous parts by count and job.** Where limbs multiplied, say plainly how many there
are and what each one does — *"between them there are exactly four hands: hers on the bow, hers on
the arrow, his on her wrist, his on his own sword"* — rather than only listing `extra hands` in
`Avoid:`.

**Bank the correction somewhere durable before you regenerate.** If a note is about a character's
gear or likeness rather than this one frame — "from this point forward he wears full plate" — it
belongs in `bible/05-kit-and-timeline.md` (new era block) or `characters/CANON.md`, not just in the
next prompt. Otherwise the same note gets given again three images later.

---

## Prompt craft — what actually changes the output

- **Describe a pose mechanically, not by its name.** Vocabulary fails; anatomy lands. "Lances
  couched" came back upright twice and shoulder-carried once. What finally worked was the joint
  positions: *"the butt clamped against the rider's right side, just below the armpit; the hand
  gripping at mid-chest; the shaft crossing diagonally over the horse's neck and out past the left
  side of its head; the point lower than the grip."* The same holds for bowstrings, salutes and grips.
- **Pick ONE instant and commit.** Describing a shot as both drawn and loosed yields a nocked arrow
  *and* a stray in flight. Never blend.
- **Do NOT stack negatives onto a single object in the prompt body — it shatters the object.**
  Negatives belong in `Avoid:`. When a correction is folded back in, the tempting move is to armour
  the offending object with clause after clause — *not drawn, not bent, no "V", the string slack,
  the string straight, not a fist, not a whole hand* — and the result is worse than the fault you
  were fixing. The model appears to try to satisfy every clause at once and **fuses them into a
  chimera**: it grows extra hands to hold all the described grips, welds the arrow's head onto the
  bow limb, and runs the string off the top of the frame. *(Aug 2026, second roll of
  `the-clash-beneath-the-fortress-gate`: a six-bullet bow block produced exactly all three.)*
  **The fix is to shorten, not to add.** Describe the object once, positively, in two or three
  plain sentences; pin any dimension that ran away (*"the string stays close alongside the stave
  and entirely inside the frame"*); state the count of ambiguous parts (*"exactly two hands: left
  on the bow, right at the string; nothing else touches it"*); and move every "not" to `Avoid:`.
- **Every figure needs an eyeline and an inner state**, named explicitly, or you get a neutral
  camera-aware face pasted into the scene. See the style guide — this is mandatory, not advisory.
- **State the corrections as negatives too.** The model fills every silence with its defaults, and
  its defaults skew toward sexualized armour on women and orc caricature on half-orcs. Copy the
  relevant lines out of `CANON.md`'s *Known drift* into the prompt body **and** the `Avoid:` line.
  The exception: never put words like `sexualized` or `bare midriff` near a prompt depicting a
  child — classifiers do not parse negation and will refuse the whole prompt. Describe a child's
  clothing positively instead.
- **A referenced character will not recede.** Attach someone's portrait and the model promotes them —
  lighting, centring and clearing space around them. If a named character must be incidental, compose
  so prominence is impossible: camera behind them, cropped by the frame edge, occluded by bodies, or
  out of frame entirely with the caption carrying that they were present.
- **A first-person POV shot** is the honest framing when only one character can perceive something
  (a paladin's *detect evil*, say). It also inverts the usual eyeline rule: everyone facing that
  character is now correctly facing the camera.

---

## When it hangs

Most failures are one problem in different masks: **the tab's renderer is wedged.** Conversation tabs
holding several generated images get heavy enough that the renderer stops servicing script and image
decode, and then `fetch`, `javascript_tool` and screenshots all hang at once. This reads like a
server refusal and almost never is.

**Discriminate first:**
- Things **hang** (calls time out, `fetch` never returns) → wedged renderer; work the ladder.
- Things **fail fast** (403/404, a clear JS error) → a stale signed URL; re-query the DOM fresh.

**The ladder — stop at the first rung that works:**

1. **A brand-new tab.** `tabs_create_mcp` → `navigate` to `https://chatgpt.com/` → work there. A fresh
   tab means a fresh renderer, and you get your one free script-initiated `a.click()` back. This is
   the highest-yield fix by a wide margin. **Expect to need it after roughly half a dozen images in
   one session** — mid-run wedging is normal, not exceptional. Close the old heavy tab afterwards.
2. **Ask Matt to save the image by hand** — hover it, click its download icon, tell you when it's
   saved. Ten seconds of his time beats twenty minutes of flailing, and it is a legitimate
   resolution, not a failure.

**Stop rules:** two attempts per step, maximum. Never reload the same tab more than twice — the wedge
belongs to the tab, and reloading feels like diagnosis while being pure spin. Budget the whole ladder
at about five minutes.

**Known dead ends:** canvas `drawImage`/`toDataURL` throws on a tainted cross-origin canvas and will
never work; `img.complete` reflects decode state, not reachability, so judge by whether `fetch`
returns; re-running an identical failed call changes nothing until you change tabs.

---

## Selector drift

The selectors here are a snapshot of ChatGPT's web UI and *will* move. The method is durable; the
selectors are not. If a step stops working, dump the live DOM with `javascript_tool` (e.g.
`[...document.querySelectorAll('button[aria-label]')].map(b => b.getAttribute('aria-label'))`) and
update the selector — don't assume the skill is broken. Prefer `javascript_tool` for this;
`read_page` times out on this site.

Current snapshot: composer `div.ProseMirror`; send `#composer-submit-button` /
`button[data-testid="send-button"]` / `button[aria-label*="Send"]`; generating indicator a button
whose `aria-label` matches `/stop answering/i`; generated image an `<img>` with `naturalWidth > 700`
that is **not** inside `[data-message-author-role="user"]`.

**Interface refresh, Aug 2026 — checked, and the pipeline survived it.** ChatGPT shipped a new
composer and Matt expected it to break things. It mostly didn't:

- **All the selectors above still resolve**, `#composer-submit-button` included.
- **⚠️ SUPERSEDED — LONG PROMPTS ARE NOW CONVERTED TO A FILE ATTACHMENT.** This bullet used to say
  the feared change had not happened and long prompts still pasted as inline text. **It has happened.**
  Past roughly **9,500–10,000 characters**, a pasted prompt is silently turned into an attached text
  file instead of composer text. **The failure is silent and looks exactly like a paste that did
  nothing:** `div.ProseMirror.textContent.length` reads **0**, so a `pmLen` check reports an empty
  composer while the prompt is in fact sitting right there as a file.
  - **Do not "fix" this by chunking the paste.** Splitting a long prompt across two or three
    sequential pastes leaves you unable to verify what actually landed, and the pieces can interleave
    with the ProseMirror selection in ways that are tedious to unpick. Keep it to one paste.
    *(This bullet previously claimed a later chunk would submit the message on its own. It does not —
    see the self-submit correction in step C. Matt had pressed send.)*
  - **`[data-testid*="attachment"]` does NOT catch it** — the old attachment probe was written for
    dropped images. Detect the file form explicitly, e.g.
    `document.querySelectorAll('form [class*="file"], form [data-testid*="file"]').length`, or simply
    treat *"pmLen is 0 immediately after a paste that returned a large `want`"* as **"it became a
    file,"** never as "the paste failed."
  - **Either keep the prompt under ~9,500 characters and paste it in ONE operation, or accept the
    file attachment deliberately** — a prompt-as-file still works, it is just harder to inspect and
    impossible to verify with `pmLen`. Trimming is usually the better trade, and prompts this long
    are mostly redundant belt-and-braces anyway.
- **New: a "Chat / Work" toggle** at the top of a fresh chat. Irrelevant to this workflow so far.
- **New: a reasoning selector in the composer bar**, showing the current setting as its label
  (`High` when observed). It is a `button[aria-haspopup="menu"]` whose text is the level; clicking it
  opens `[role="menuitem"]` entries — observed: **Instant 5.5 / Medium / High / GPT-5.6 Sol**. This is
  the control behind the older note that some accounts stall in a long "Thinking" loop; `Please
  generate this image directly.` has continued to work fine on **High**, so leave it alone by default.
  If renders start stalling, **Instant** is the thing to try — but it is Matt's account setting, so
  ask before changing it.
- **The one real breakage was the click-coordinate scaling**, documented in step E above. It surfaced
  precisely because this new composer control is small; every previous click had been at the oversized
  download anchor, which was absorbing the error.
