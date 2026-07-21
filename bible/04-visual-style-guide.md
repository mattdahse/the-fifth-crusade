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

**Write the corrections as negatives, not just positives.** The model fills any silence
with its own defaults, and its defaults skew toward sexualized armor on women and
orc caricature (tusks, underbite) on half-orcs. Put the explicit "no …" clauses in the
prompt body *and* the `Avoid:` line. See CANON.md's *Known drift* section.

**QA the render against the portraits** feature by feature before publishing, and
regenerate rather than shipping a drifted likeness.
