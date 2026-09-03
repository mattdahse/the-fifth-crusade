# Art for The Marchlands Commission

What each asset is, and the prompt that makes it. Generated through the
[`chatgpt-image-gen`](../../.claude/skills/chatgpt-image-gen/SKILL.md) skill, in Matt's own
logged-in ChatGPT tab, following the house look in
[`../../bible/04-visual-style-guide.md`](../../bible/04-visual-style-guide.md).

### Tokens are read at 40 pixels, not 512

**The archive's house look does not survive token size.** It is built on muted earth — browns,
rust, ash-grey, low-key light — and that is right for a chapter plate the reader studies. Cropped
to a circle and drawn at roughly one grid square on a shared screen, it collapses into
indistinguishable brown-on-brown squares. Two NPCs painted this way are the same token.

So tokens are held to a different standard from the rest of the archive's art:

- **High contrast, and value first.** The subject must separate from its background by *value*,
  not by hue or detail. Squint at the render: if the head does not read as a distinct shape at
  thumbnail size, the token has failed regardless of how good the painting is.
- **A distinct silhouette and a distinct dominant colour per creature**, so two tokens on the
  same map are told apart at a glance rather than by reading names.
- **Simplify the background.** Darker and plainer than a portrait would have it — the background
  exists to push the subject forward, not to describe the scene.
- **Push the key light.** A brighter rim or a stronger light on the head is worth more at token
  size than any amount of texture.

**In-game art may be brighter and more vivid than the site's house style, and that is fine.** The
two are allowed to diverge. Where a campaign asset needs to appear on the site, the in-game
painting is used as a **reference to generate site-style art from**, not published directly. That
keeps the table legible and the chronicle's look intact, instead of compromising both.

---

Tokens are cut from the full-size portrait by
[`make-token.py`](make-token.py), which applies that adjustment — contrast, saturation, a lift,
and a vignette that darkens the corners the circle crop eats anyway — and writes the 512 WebP:

```
python fg/art/make-token.py "portraits/*.webp"
```

It is a rescue and not a substitute: it cannot separate two portraits painted in the same
palette, which is why the rule above applies at generation time.

Save every render as a **512 × 512 WebP at quality 85** into `fg/art/tokens/` — square painted
portrait busts with an environmental background, used by FG for both `<picture>` and `<token>`.
FG crops them to a circle on the map, so **keep the head well clear of the edges and out of the
corners.** ChatGPT returns these at 1254 × 1254; **downscale, never upscale** — enlarging past the
render adds bytes and no detail.

**Small on purpose: some of the table is on low-end hardware.** What costs a player's machine is
the *decoded texture*, not the file. A 2048 × 2048 token holds ~16 MB of video memory however
small its file compresses to; at 512 it holds 1 MB. The older Marchlands Expedition tokens
(`Fenna Tusk.png`, `cobb_harwick.png` and the rest) are 2048 PNGs at 6–8 MB each, about 80 MB of
tokens in one campaign — that is the mistake this campaign does not repeat. FG draws a token at
roughly one grid square and the portrait window at a few hundred pixels, so 512 is already
generous. WebP over PNG because a painted bust has no flat colour for PNG to exploit: the same
plate is 486 KB as a PNG and 51 KB as a WebP, indistinguishable at token size. FG reads WebP —
the live campaign already serves both tokens and images from `.webp`.

These are campaign NPCs, not chronicle cast, so they are deliberately **not** in
[`../../characters/CANON.md`](../../characters/CANON.md) and must not go on the site's Cast
gallery. Their likeness anchors live here instead.

---

## Status

| Asset | File | State |
|---|---|---|
| The Sarkorian House battlemap | `images/the-sarkorian-house.jpg` | **done** — blockout at 1600 × 1400, drawn by [`make-sarkorian-house.py`](make-sarkorian-house.py) |
| The Cellar battlemap | `images/the-cellar.webp` | **done** — generated at 1536 × 1024, cropped and extended to 1560 × 1080 for the grid |
| Labyrinth Squatter token | `tokens/labyrinth-squatter.webp` | **done** — 512 × 512, 51 KB |
| Hookhand Acolyte token | `tokens/hookhand-acolyte.webp` | **done** — 512 × 512, 39 KB |

---

## Labyrinth Squatter

**Likeness anchors (keep constant).** Human man of about forty, weathered and unshaven,
close-cropped hair going grey at the temples, a broken nose set badly. Battered **scale mail**
gone brown with rust and neglect over a filthy quilted gambeson, a small dented **buckler**
strapped to the left forearm, a plain **handaxe**. Around his throat on a leather thong hangs a
**hooked iron disc stamped with a maze** — the Ivory Labyrinth's mark, and the one thing about
him that is deliberate. It stays: the squatters are Baphomet's men, sent here to count crusader
traffic, and the woman who now commands them serves a different lord entirely. The two are
allies, which is why nobody questioned it. Not a fanatic and not a soldier: a man who came north for pay and
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
**heavy mace** at her belt. She serves **Deskari**, and her mark is a small **bronze locust with
spread wings** — but it is pinned *inside* the breast of her coat and is deliberately **not
visible** in any portrait. She wears no badge and no colours; that is the character. Do not add a
holy symbol to her art. **An iron hook is lashed over her left hand** with cord that has
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
are written against it: a 1600 × 1400 plate, ten squares by eight at 100 px each, the house at
x 300–1300 and y 300–1100, a cross-wall at x 800 with a one-square doorway at y 660–760, and the
whole north edge a rubble spill rather than a wall.

Attach the blockout and name its job explicitly — *"THIS IS THE FLOOR PLAN AND IT IS FIXED;
repaint it, move nothing"* — the same discipline the region plates need, and for the same
reason: asked for geometry and staging at once, the model keeps the staging and redraws the
geometry. A battlemap carries **no text, no grid, no room numbers and no compass**; FG draws the
grid itself.

---

## The Cellar battlemap

Generated rather than drawn, which is the **reverse** of the order used for the Sarkorian House
and deliberate. A blockout first is right when geometry has to be agreed before art exists, or
when art is replacing a plate whose walls are already load-bearing. It is the wrong way round for
an organic space: a script drawing a bored tunnel and a nest chamber in polygons produces walls
that self-intersect at every bend and read as machine-made. Generate the space, then measure it.

Measuring is [`trace-occluders.py`](trace-occluders.py), which thresholds the plate and walks the
boundary of the open floor. Use `--channel warm` (red minus blue): dug earth is warm and cut rock
is neutral, whereas in plain brightness they overlap badly — a shadowed stretch of this tunnel is
*darker* than the rock beside it. The exact invocation is recorded in
[`../maps/the-cellar.md`](../maps/the-cellar.md) so a re-render can be retraced without
rediscovering the settings.

Two things a generated plate costs you, both handled in `the-cellar.md`: the walls do not land on
a round multiple of the square, so the plate is cropped and edge-extended until they do; and the
map is 3:2, so the grid pitch is **60 px** here rather than the house's 100.

> [the full prompt, as sent]
>
> A TOP-DOWN TABLETOP RPG BATTLEMAP, viewed from directly overhead, orthographic, no perspective.
> Painted in oils, visible brushwork, a muted earthy palette — browns, soot-black, ash-grey, cold
> stone.
>
> On the RIGHT half, a SQUARE stone cellar room with heavy mortared block walls on all four sides
> and a flagstone floor. In its SOUTH-EAST CORNER — the BOTTOM-RIGHT corner of the room — a short
> flight of stone steps leads UP and out of frame, with a square opening in the ceiling above
> them. This is the way down from the ruined house above, and it MUST be in the bottom-right
> corner of the room, not the top. Along the room's NORTH wall, collapsed wooden shelving and a
> few broken barrels. In the middle of the cellar's WEST wall a low STONE DOOR, HALF BURIED behind
> a spill of fallen masonry heaped against that wall, so the door is only partly visible behind
> and between the broken stone.
>
> Leading WEST from that door, a rough TUNNEL bored through dark earth and rock — not built, not
> bricked, gnawed. About as wide as the door, curving and wandering rather than straight, its
> walls irregular and organic. On the LEFT the tunnel opens into a larger roughly ROUND NEST
> CHAMBER dug out of the earth, its floor fouled with a midden of chitin fragments, husks, dry
> pale egg clutches heaped against the walls, and dark stains. A few smaller side burrows lead off
> it and stop.
>
> The cellar reads as worked stone and is the lightest thing in the picture. The tunnel and nest
> read as raw dug earth, darker and warmer. The solid rock between them is the darkest value,
> nearly black. Lit evenly and flatly from above as a map.
>
> **Avoid:** stairs in any corner other than the bottom-right, a grid, grid lines, squares, hexes,
> text, letters, numbers, labels, a legend, a compass, a scale bar, a title, a border, a frame,
> parchment, torn paper edges, a vignette, an isometric or three-quarter or perspective view, a
> side view, a photograph, a 3-D render, cartoon, cel-shaded, flat vector, bright saturated
> colours, visible miniatures or tokens or figures, any living creatures, any people.

**Naming the corner twice was necessary.** The first render put the stair in the north-east
however the layout was phrased; repeating the constraint as *bottom-right* in plain terms, and
again in the avoid list, is what fixed it. Screen directions beat compass directions when the
model is placing something.
