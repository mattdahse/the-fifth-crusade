# Art for The Marchlands Commission

What each asset is, and the prompt that makes it. Generated through the
[`chatgpt-image-gen`](../../.claude/skills/chatgpt-image-gen/SKILL.md) skill, in Matt's own
logged-in ChatGPT tab, following the house look in
[`../../bible/04-visual-style-guide.md`](../../bible/04-visual-style-guide.md).

Save every render as a **2048 × 2048 PNG** into `fg/art/tokens/`, matching the Marchlands
Expedition tokens already in the campaign (`Fenna Tusk.png`, `cobb_harwick.png` and the rest) —
square painted portrait busts with an environmental background, used by FG for both `<picture>`
and `<token>`. FG crops them to a circle on the map, so **keep the head well clear of the
edges and out of the corners.**

These are campaign NPCs, not chronicle cast, so they are deliberately **not** in
[`../../characters/CANON.md`](../../characters/CANON.md) and must not go on the site's Cast
gallery. Their likeness anchors live here instead.

---

## Status

| Asset | File | State |
|---|---|---|
| The Sarkorian House battlemap | `images/the-sarkorian-house.jpg` | **done** — blockout, drawn by [`make-sarkorian-house.py`](make-sarkorian-house.py) |
| Labyrinth Squatter token | `tokens/labyrinth-squatter.png` | **pending** |
| Hookhand Acolyte token | `tokens/hookhand-acolyte.png` | **pending** |

---

## Labyrinth Squatter

**Likeness anchors (keep constant).** Human man of about forty, weathered and unshaven,
close-cropped hair going grey at the temples, a broken nose set badly. Battered **scale mail**
gone brown with rust and neglect over a filthy quilted gambeson, a small dented **buckler**
strapped to the left forearm, a plain **handaxe**. Around his throat on a leather thong hangs a
**hooked iron disc stamped with a maze** — the Ivory Labyrinth's mark, and the one thing about
him that is deliberate. Not a fanatic and not a soldier: a man who came north for pay and
stayed because there was nowhere to go back to.

> THIS IS A PAINTING, NOT A PHOTOGRAPH. A traditional narrative OIL PAINTING on canvas: visible
> directional brush strokes throughout, loaded paint and impasto in the lights, soft scumbled
> painted edges, visible canvas weave, colour mixed on a palette rather than sampled from life.
> Every surface should read as pigment. Render the background in looser, broader brushwork than
> the figure.
>
> Cinematic painterly fantasy illustration, semi-realistic. Square composition, head-and-chest
> portrait bust, the figure centred with clear space around the head and nothing important in
> the corners. A weathered human man of about forty, unshaven, close-cropped hair greying at the
> temples, a badly-set broken nose. He wears rusted brown scale mail over a filthy quilted
> gambeson, a small dented buckler on his left forearm, and a hooked iron disc stamped with a
> maze hanging at his throat on a leather thong. He holds a plain handaxe low, not raised.
> Behind him, a ruined stone longhouse on the lip of a dry valley under an overcast, turbulent
> sky, drifting ash. Dramatic low-key lighting, cold rim light from a breaking sun behind his
> left shoulder, muted earthy palette of browns, rust and ash-grey with a single cold-blue
> accent in the sky. He is looking off to the side at something approaching down the road,
> weighing whether this is worth dying for — jaw set, weight shifted back onto the rear foot,
> the axe hand tightening. High detail on face, leather and pitted metal.
>
> **Avoid:** a photograph, photorealistic rendering, photoreal skin, photographic grain, a film
> still, DSLR photography, lens bokeh, shallow depth-of-field blur, lens flare, visible skin
> pores, hyperreal skin texture, anime, cartoon, cel-shaded, 3-D render, comic ink, flat vector,
> bright even lighting, oversaturated, glossy, clean or polished armour, heraldry, a tabard,
> modern clothing or objects, text, watermark, signature, border, a frame, extra limbs, deformed
> hands, a calm or blank expression, looking at the viewer.

## Hookhand Acolyte

**Likeness anchors (keep constant).** Human woman in her thirties, dark hair scraped back hard
and pinned, a lean and watchful face, pale eyes. Plain **studded leather** over dark wool, a
**heavy mace** at her belt. **An iron hook is lashed over her left hand** with cord that has
worn grooves into the wrist — she took the name Hookhand on being given a warband, and the hook
is a poor weapon and a very good argument. **The hook is her signature and must always be
present and visible.**

> THIS IS A PAINTING, NOT A PHOTOGRAPH. A traditional narrative OIL PAINTING on canvas: visible
> directional brush strokes throughout, loaded paint and impasto in the lights, soft scumbled
> painted edges, visible canvas weave, colour mixed on a palette rather than sampled from life.
> Every surface should read as pigment. Render the background in looser, broader brushwork than
> the figure.
>
> Cinematic painterly fantasy illustration, semi-realistic. Square composition, head-and-chest
> portrait bust, the figure centred with clear space around the head and nothing important in
> the corners. A lean, watchful human woman in her thirties with pale eyes and dark hair scraped
> back hard and pinned. She wears plain studded leather over dark wool with a heavy mace at her
> belt. AN IRON HOOK IS LASHED OVER HER LEFT HAND with cord worn into grooves at the wrist, and
> she holds that hand slightly raised and forward where it can be seen. Behind her, the smoky
> interior of a ruined stone longhouse, a cold hearth, a slate roof over broken beams. Dramatic
> low-key lighting from a single low fire below and to one side, muted earthy palette of browns,
> soot-black and dark wool with a single warm amber accent from the fire. She is looking
> directly at someone just off frame who has said something she does not believe — chin lowered,
> one brow raised, the hooked hand come up an inch without her deciding to. High detail on face,
> worn leather and dull iron.
>
> **Avoid:** a photograph, photorealistic rendering, photoreal skin, photographic grain, a film
> still, DSLR photography, lens bokeh, shallow depth-of-field blur, lens flare, visible skin
> pores, hyperreal skin texture, anime, cartoon, cel-shaded, 3-D render, comic ink, flat vector,
> bright even lighting, oversaturated, glossy, a hooded robe, a witch's hat, ornate vestments,
> obvious demonic horns, modern clothing or objects, text, watermark, signature, border, a
> frame, extra limbs, deformed hands, a missing hook, a calm or blank expression, looking at the
> viewer with a neutral face.

---

## Replacing the battlemap with painted art

The blockout is playable, so this is polish rather than a blocker. If it is done, the geometry
is **fixed** and the occluders in [`../maps/the-sarkorian-house.md`](../maps/the-sarkorian-house.md)
are written against it: ten squares by eight at 50 px each, the house at x 150–650 and y 150–550,
a cross-wall at x 400 with a one-square doorway at y 330–380, and the whole north edge a rubble
spill rather than a wall.

Attach the blockout and name its job explicitly — *"THIS IS THE FLOOR PLAN AND IT IS FIXED;
repaint it, move nothing"* — the same discipline the region plates need, and for the same
reason: asked for geometry and staging at once, the model keeps the staging and redraws the
geometry. A battlemap carries **no text, no grid, no room numbers and no compass**; FG draws the
grid itself.
