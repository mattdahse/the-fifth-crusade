# The Fifth Crusade — Visual Style Guide

The chronicle has one house look. Every image made for it — chapter illustrations,
scenes, portraits, group shots — is rendered in this style so the archive reads as a
single illustrated work rather than a scrapbook of clashing generators.

**The definitive exemplar is [`../images/arueshalae.png`](../images/arueshalae.png)**
(the winged archer on a ruined skyline). When in doubt, match that image.

---

## The look, in one line

> Cinematic, painterly fantasy realism — a lone figure lit by a single cold light
> source against a desolate, storm-lit Worldwound, muted earthy colors broken by one
> luminous accent.

## The rules

**Medium.** Painterly digital illustration with real brush texture and grain. Semi-
realistic — grounded anatomy and real weight, not photographs and not stylized.
**Never** anime, cel-shaded, cartoon, 3-D render, comic-book ink, or flat vector.

**Light.** Low-key and dramatic. One dominant light — moonlight, a breaking sun, a
holy or starlit glow — placed behind or to the side of the figure so it rims them and
throws the rest into shadow. Deep shadows are welcome; avoid bright, even, front-on
lighting.

**Palette.** Muted and earthy: browns, blacks, ash-greys, deep oxblood reds, worn
leather. Desaturated overall, then **one** luminous accent that carries the image —
star-white, pale gold, or cold blue. Resist rainbow saturation.

**Composition.** A single subject, full-body or three-quarter, standing with quiet
gravity and a serious, weathered expression. Portrait orientation, roughly 3:4.
Subject reads clearly against the background.

**World.** Backgrounds are the Worldwound and the crusader marches — crumbling cities,
broken walls, blasted heath, overcast and turbulent skies, drifting haze and embers.
Desolate, atmospheric, lived-in. No clean modern surfaces, no anachronisms.

**Finish.** High detail on faces, leather, and metal; visible fabric and armor texture;
soft atmospheric depth behind. No text, no watermark, no signature, no UI, no border.

## Reusable prompt scaffold

> Cinematic painterly fantasy illustration, semi-realistic. **[SUBJECT — pull the
> likeness anchors from `characters/CANON.md`]**, **[action / pose]**, in **[setting
> drawn from the Worldwound: ruined city, broken rampart, blasted marsh]**. Dramatic
> low-key lighting, strong backlight / rim light from **[single source: moonlight /
> breaking sun / starlit glow]**, muted earthy palette of browns and blacks with a
> single luminous **[star-white / gold / cold-blue]** accent. Overcast turbulent sky,
> atmospheric haze and drifting embers. Rich brush texture, grounded anatomy, serious
> weathered expression. Portrait orientation ~3:4, high detail.
>
> **Negative:** anime, cartoon, cel-shaded, 3-D render, comic ink, flat vector,
> bright even lighting, oversaturated, glossy, modern clothing or objects, text,
> watermark, signature, border, extra limbs, deformed hands.

## The iron rule: canonical likeness

When the image depicts a character listed in [`../characters/CANON.md`](../characters/CANON.md),
**supply that character's canonical portrait to the image tool as a reference image**
and preserve their likeness anchors. Never regenerate a known character from a text
description alone — they must be recognizable from picture to picture. If a scene has
several canon characters, provide every available reference. New (unlisted) characters
are rendered fresh in this style and, once settled, added to the registry.

**Before writing the prompt, open the portrait.** Read the actual `characters/*.png`
and verify the `CANON.md` row against it — never write a likeness from memory or from
the row alone. A wrong anchor propagates silently into published art.

**Take the face from `CANON.md`, but the *gear* from the era.** A character's kit changes
as the story advances — early Book I is battered and poorly-equipped, not the later
gilded look. Read [`05-kit-and-timeline.md`](05-kit-and-timeline.md) for the era block that
matches the scene, and put its explicit negatives (e.g. `no golden plate, no glowing sword`
for early Harlock) in the prompt's `Avoid:` line.

**Take named items from the artifact list, not from the name.** A named object's *appearance*
is canon exactly as a face is. Read the *How they look* entries in
[`03-lore-and-locations.md`](03-lore-and-locations.md#artifacts--relics) before writing any prompt that
puts a relic in someone's hand, and carry that entry's `Avoid:` clauses into your own. Left to
itself the model illustrates the **word**, not the object — a *chime of opening* came out as a
church bell with a clapper, a *rod of cancellation* as a little dark wand, and the *Wardstone
fragment* as a gem in a birdcage instead of a suitcase-sized block behind spiked iron. If you
illustrate an item that has no entry yet, get its description from Matt and **add the entry**.

**Write the corrections as negatives, not just positives.** The model fills any silence
with its own defaults, and its defaults skew toward sexualized armor on women and
orc caricature (tusks, underbite) on half-orcs. Put the explicit "no …" clauses in the
prompt body *and* the `Avoid:` line. See CANON.md's *Known drift* section.

**QA the render against the portraits** feature by feature before publishing, and
regenerate rather than shipping a drifted likeness.

## Combat & action scenes — prevent the spin in the prompt, then QA

Action scenes fail in ways portraits don't, and the **same faults recur in the *first*
iteration of almost every combat image**, whoever the subject is. Most are cheaper to
**prevent in the first prompt** than to fix over rounds of review — the four faults below cost
several passes on *the-poison-garden* precisely because the opening prompt left them unsaid or
self-contradictory. Write these into the prompt up front, then QA the render against the same
list.

**Write it into the prompt (first pass):**

- **Pick ONE instant and commit to it.** The worst offender is describing a shot as both
  drawn *and* loosed — "*she looses an arrow … the string still humming … an arrow streaking
  from the bow*" produces a nocked arrow **and** a stray in-flight one, because both are
  implied. Choose: *held at full draw* — "at full draw, holding the shot, a single arrow nocked
  and NOT released, nothing in flight" — **or** *the release* — "the instant of release: the one
  arrow now in flight, the string sprung forward, the draw hand open." Never blend the two.
- **State the confrontation geometry.** Don't just place the enemy "in the mid-ground" — say the
  hero and enemy are **squared off across the frame, the hero in profile / three-quarter aiming
  directly at the enemy, which sits within the line of fire**, and explicitly *not* oriented
  toward the viewer with the enemy behind them.
- **Describe the bowstring (archers).** Left unsaid, the model drops or mangles it. Spell it out
  every time: "a single continuous bowstring forming a drawn 'V' — top limb → the draw hand
  anchored at the cheek (through the nocked arrow) → bottom limb — clearly visible passing in
  front of the face."
- **Choose the frame for the scene, not by default.** A single hero mid-action fits the house
  3:4. But **two combatants who must face off fight a portrait frame** — a horizontal standoff
  wants width. Decide up front: a **wider / landscape frame** for an even side-view standoff, or
  a deliberate **over-the-shoulder** (one combatant's back to us, the other over their shoulder)
  if you must hold 3:4. (This is the one sanctioned exception to the "portrait ~3:4" default —
  see *the-poison-garden*, deliberately landscape.)

**Then QA the render (backstop):**

- **Every combatant faces the clash, not the camera** — the hero's body, weapon, and gaze on the
  enemy, and the enemy in the line of attack (not behind the hero). In a *multi*-combatant scene
  the **enemies** drift to face the viewer too, leaving the hero swinging at empty air between
  forward-posed monsters — turn *every* figure inward toward the point of the fight, and have the
  blow land **on** the target (see *the-worm-wearers-at-the-threshold*, which took several passes
  on exactly this).
- **One shot, not many** — drawn-and-held **or** one loosed shot in flight, never both. (An arrow
  that appears to extend far *forward* of the bow at full draw is usually a second, loosed arrow
  overlapping the nocked one — look twice. Generalizes: no spell both mid-cast and already-landed.)
- **Bowstrings obey physics** — one continuous line, top limb → anchor at the cheek/jaw → bottom
  limb, visible in front of the face; never vanishing behind the head or stopping at the brow.
- **Weapon reach and grip** — hands actually grip the haft/grip; blade length is plausible and
  doesn't pass bloodlessly through the wielder; a thrust or swing connects where the light says.

These bite hardest on **archers — Lupenor above all**: aim-at-viewer, extra-arrow, and
broken-string faults tend to show up *together* on a first pass, so prompt against all three
from the start.
