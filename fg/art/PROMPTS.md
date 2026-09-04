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
| Ysolde Karn token | `tokens/ysolde-karn.webp` | **done** — 512 × 512, 39 KB |
| Theep Gvosh portrait | `portraits/theep-gvosh.webp` | **done** — 1024 × 1024, 243 KB |
| Theep Gvosh token | `tokens/theep-gvosh.webp` | **done** — 512 × 512, 72 KB |

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

## Ysolde Karn

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

## Theep Gvosh

**Likeness anchors (keep constant).** Tiefling man, late thirties, an evoker. **Ash-grey skin with
a cold blue undertone** — deliberately *not* the dusky grey-brown of Barrid Isen in the chronicle,
because two horned spellcasters in one archive must not read as the same man. **Short, thick,
forward-curving ram's horns** low on the brow, ridged and chipped at the tips — a compact silhouette
against Barrid's long sweeping-back pair. Scalp shaved to stubble, a hard narrow face, **eyes with
no visible whites, lit from within**. A **slender tail**. He wears no robes worth the name: scorched
dark wool and hard-worn leather, sleeves burned back to the elbow and the forearms bare, a high
collar, a satchel of chalk and slate on a strap. **His spell light is COLD — actinic blue-white**,
and that is his signature. Everything else in this campaign is lit by amber firelight; Theep is the
one asset lit by his own hand in a colour nothing else uses, which is what makes his token findable
on a crowded map.

> THIS IS A PAINTING, NOT A PHOTOGRAPH. A traditional narrative OIL PAINTING on canvas: visible
> directional brush strokes throughout, loaded paint and impasto in the lights, soft scumbled
> painted edges, visible canvas weave, colour mixed on a palette rather than sampled from life.
> Every surface should read as pigment. Render the background in looser, broader brushwork than
> the figure.
>
> Cinematic painterly fantasy illustration, semi-realistic. Square composition, head-and-chest
> portrait bust, the figure centred with clear space around the head and nothing important in the
> corners. A tiefling man in his late thirties, ash-grey skin with a cold blue undertone, a hard
> narrow face, scalp shaved to stubble, and SHORT THICK FORWARD-CURVING RAM'S HORNS low on the
> brow, ridged and chipped at the tips. His eyes have no whites and glow faintly from within. He
> wears scorched dark wool and hard-worn leather with a high collar, the sleeves burned back to
> the elbow leaving the forearms bare and marked. HE IS MID-CAST: one hand raised and open at
> chest height, and the light of the spell gathering in that palm is COLD ACTINIC BLUE-WHITE,
> throwing hard blue light up under his jaw, along the underside of the horns and across the
> collar, with everything it does not touch falling to near black. Behind him, a dark ruined
> interior in loose broad brushwork, almost lost in shadow. Strong low-key value contrast: a
> near-black ground, ash-grey skin, and one brilliant cold light source. He is not shouting and
> not grimacing; he is looking past his own raised hand at something he has already decided to
> destroy, entirely calm about it. High detail on the face, the horns, and the burned leather.
>
> **Avoid:** a photograph, photorealistic rendering, photoreal skin, photographic grain, a film
> still, DSLR photography, lens bokeh, shallow depth-of-field blur, lens flare, visible skin
> pores, hyperreal skin texture, anime, cartoon, cel-shaded, 3-D render, comic ink, flat vector,
> bright even lighting, flat frontal lighting, oversaturated, glossy, a pointed wizard's hat, a
> hooded robe, ornate embroidered vestments, a staff, a floating spellbook, warm orange or amber
> firelight, red or crimson skin, long swept-back horns, a snarling or shouting expression, text,
> watermark, signature, border, a frame, extra limbs, deformed hands, more than two horns.

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

---

## Fixing a plate locally instead of re-rolling it

A generated plate is just pixels once it is downloaded, and Pillow can edit it. That is often the
right move: a re-roll costs a render and, worse, **changes everything** — a plate that was correct
in nine ways comes back different in all nine, and any occluders traced against it are void.

**Local editing works well for:**

- **Moving or removing a small discrete object** — the manor's chimney. Clone neighbouring texture
  over where it was, then put it back where it belongs.
- **Anything geometric**: a doorway, a hatch, a stack, a threshold. These are shapes, and shapes
  can be drawn.
- **Crop, pad, scale and colour** — the grid alignment on every plate here, and the contrast pass
  that makes tokens legible.
- **Composites**, where a feature has to line up with another map. That is arithmetic, and
  arithmetic is exactly what a script is better at than a prompt.

**It does not work for:**

- **New painted content of any size.** A room, a landscape, a face. Drawn geometry reads as drawn
  the moment it is bigger than a few dozen pixels.
- **Anything that has to respect the plate's lighting across a wide area.** A patch borrowed from
  the north slope of a roof will not sit on the south slope.
- **Changing what the picture *is*** — the view angle, the roof being on or off, the composition.
  Those are prompt problems and re-rolling is the honest answer.

**Two traps, both hit while moving that chimney.** Cropping an object off a plate brings its
*surroundings* with it, so pasting the chimney elsewhere pasted a rectangle of ground onto the
slate — draw the replacement rather than copying the original. And drawn geometry is too crisp
against brushwork: a **0.6 px Gaussian blur** over just the edited patch is enough to seat it.

## The approach — terrain map

A wide-area plate for planning the approach: the manor small and **roofed**, in four hundred yards
of country. Ships with `grid: off` and no occluders.

**Three things had to be said very plainly, and the first version got two of them wrong.**

**Say the camera is straight down, and say what that forbids.** "Top-down" alone produced a
gently oblique picture with the side of a ravine wall visible and foundations drawn in
three-quarter. What fixed it was naming the consequence: *nothing shows its side — you can see the
top of a wall, a cliff, a rock or a tree, never its face.* Then repeat it in the avoid line as
`an oblique view, a tilted view, visible cliff faces, visible tree trunks`.

**A building seen from outside has a roof.** The first version drew the manor open, which handed
the players the floor plan before they had crossed the ground. Ask for the roof explicitly — slate,
a ridge line, a chimney, a couple of fallen-through holes — and say *it hides the interior
completely*. This does not contradict the battlemap: the manor keeps its roof and the battlemap is
a cutaway.

**Ask for the chimney where the fire is.** The render put a single stack at the east end of the
ridge; both of the manor's flues — the kitchen's brick oven and the great hall's hearth — are at
the **west** end. A model has no idea what is under a roof it is drawing, so either name the
position in the prompt or fix it afterwards. It was cheaper to fix: the east stack was cloned out
with roof texture and two were drawn back in at the west end, sized to the interior. Mapping is
straightforward — the battlemap's interior spans x 80–1420 and y 80–892, this roof spans
x 897–1060 and y 445–540, so a feature's position is the same fraction along each.

**Varied ground has to be itemised.** Asked for "broken country" a model paints one texture over
the whole plate. List the patches: a copse, thorn clusters, an ash drift, scree fields, dead
grass, bare dust, a stony wash.

**And there is no road, which needs saying three times** — its own paragraph, again in the layout,
and again in the avoid line — because every instinct in an image model is to connect two features
with a track. Whatever road ran through this country was erased generations ago by demons,
Worldwound weather and armies going both ways. *"The road"* in this campaign is the name of a
direction, not a thing anybody can stand on, and the quest record says so outright.

> Please generate this image directly. Aspect ratio 3:2.
>
> A TOP-DOWN TERRAIN MAP for a tabletop RPG. Painted in oils, visible brushwork, muted earthy
> palette.
>
> THE CAMERA IS STRAIGHT DOWN. This is a TRUE ORTHOGRAPHIC BIRD'S-EYE VIEW, looking vertically
> down at the ground like a satellite photograph. NOTHING shows its side. You cannot see the side
> face of a wall, a cliff, a rock or a tree trunk — only their tops. There is no tilt, no lean, no
> oblique angle, no three-quarter view, no isometric projection, and no vanishing point anywhere.
>
> THERE IS NO ROAD ANYWHERE ON THIS MAP. No road, track, path, trail, lane, causeway, paved way or
> wheel ruts. Whatever road once crossed this country was erased generations ago by war, weather
> and armies, and the ground has closed over it. Open broken country with no route marked on it.
>
> LAYOUT, roughly four hundred yards across:
>
> Slightly right of centre and SMALL — about one sixth of the image width — a STONE MANOR seen from
> straight above, so what you see is ITS ROOF AND NOTHING ELSE. Dark grey slate, a simple long
> pitched roof with a straight ridge running its length and a stone chimney at one end. Old and
> patched: two or three small places where slates have fallen through show as dark ragged holes,
> but the roof is substantially intact and it HIDES THE INTERIOR COMPLETELY. No rooms, walls,
> floors, furniture or inside detail. A closed grey roof on the ground.
>
> Along the LEFT edge the ground simply ENDS at a ravine: a pale broken rim line, and beyond it
> flat dark shadow filling the left of the frame. Because the view is straight down you see only
> the rim and the darkness below it — never the rock face.
>
> Scattered across the open ground, the FOUNDATIONS OF A VANISHED VILLAGE: a dozen low rectangles
> of tumbled stone seen from above, knee high, half swallowed by dust and dead grass.
>
> THE TERRAIN MUST BE VARIED, not one flat texture. Well spread out: a COPSE of a dozen leafless
> twisted trees in the upper right, seen from directly above as tangles of bare grey branches;
> several dense CLUSTERS OF SCRAGGLY THORN BUSHES in dark olive and grey-green; open stretches of
> dry pale dust and cracked earth; a broad drift of pale grey ash caught in a hollow; fields of
> loose broken scree and scattered boulders; patches of coarse dead yellow grass; a dry stony
> watercourse winding down from the right into the ravine; a few standing rocks and one lone dead
> tree near the manor.
>
> Lit evenly and flatly from directly above, overcast, no long shadows.
>
> CRITICAL: NO TEXT of any kind — no title, labels, place names, legend, compass or scale bar — and
> NO GRID. No border, no frame, no parchment edge, no vignette. Art fills the frame edge to edge.
>
> **Avoid:** an oblique view, a tilted view, a three-quarter view, an isometric view, a perspective
> view, a side view, visible walls, visible cliff faces, visible tree trunks, seeing inside the
> building, an open roofless building, interior rooms, floors, furniture, a cutaway, a road, a
> track, a path, a trail, a causeway, cart ruts, wheel ruts, a line of worn ground, a bridge,
> flowing water, a lake, green healthy forest, farmland, hedges, fences, tents, camps, banners, a
> grid, text, letters, numbers, labels, a legend, a compass, a scale bar, a border, a frame,
> parchment, a vignette, a photograph, a 3-D render, cartoon, cel-shaded, flat vector, bright
> saturated colours, miniatures, tokens, figures, creatures, people.
