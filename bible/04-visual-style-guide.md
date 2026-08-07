# The Fifth Crusade — Visual Style Guide

The chronicle has one house look. Every image made for it — chapter illustrations,
scenes, portraits, group shots — is rendered in this style so the archive reads as a
single illustrated work rather than a scrapbook of clashing generators.

**The definitive exemplar is [`../images/arueshalae.webp`](../images/arueshalae.webp)**
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

> **⚠️ The word "painterly" alone does NOT stop a photograph, and the failure is easy to
> miss.** Say *"cinematic painterly fantasy illustration, semi-realistic"* and the model will
> quite happily hand back a photoreal frame: correct subject, correct light, correct palette,
> real skin pores, lens bokeh behind the figure. It looks good, so it passes a quick glance —
> and then it sits on the Cast gallery next to the painted portraits looking like a different
> kind of object. *(Aug 2026, Jeskar Hinton's registry portrait: the first roll hit every
> likeness anchor and was still a photograph.)*
>
> **The fix, and it works in one pass:** lead the prompt with the medium as its own block,
> state it as an override, and describe the *physical facts of paint* rather than naming a
> style — **"THIS IS A PAINTING, NOT A PHOTOGRAPH… a traditional narrative OIL PAINTING on
> canvas: visible directional brush strokes throughout, loaded paint and impasto in the
> lights, soft scumbled painted edges, visible canvas weave, colour mixed on a palette rather
> than sampled from life. Every surface should read as pigment."** Then put the camera words
> in `Avoid:` — `a photograph, photorealistic rendering, photoreal skin, photographic grain, a
> film still, DSLR photography, lens bokeh, shallow depth-of-field blur, lens flare, visible
> skin pores, hyperreal skin texture`. It also helps to ask for the **background in looser,
> broader brushwork than the figure**, which forces the whole frame to commit to being paint.

**Light.** Low-key and dramatic. One dominant light — moonlight, a breaking sun, a
holy or starlit glow — placed behind or to the side of the figure so it rims them and
throws the rest into shadow. Deep shadows are welcome; avoid bright, even, front-on
lighting.

**Palette.** Muted and earthy: browns, blacks, ash-greys, deep oxblood reds, worn
leather. Desaturated overall, then **one** luminous accent that carries the image —
star-white, pale gold, or cold blue. Resist rainbow saturation.

**Composition.** A single subject, full-body or three-quarter, standing with quiet
gravity and a serious, weathered expression. Portrait orientation, roughly 3:4.
Subject reads clearly against the background. *That expression is the resting default
for a figure who is merely standing — the moment something is happening to them, give
them the eyeline and inner state the scene calls for instead (see* **Every figure needs
an eyeline and an inner state** *below).*

*Two kinds of scene take a deliberate **landscape** frame instead of the 3:4 default: a
two-combatant standoff (see* **Combat & action scenes** *below), and a **wide establishing /
crowd shot**, where the subject is really the ruined world and the mass of people in it and
the company sits small in the middle distance. For the latter, go landscape ~3:2, let the
frame edges fall away into gloom, and hold the eye with a bright center. Note what this costs:
at that distance the company's faces no longer carry the beat, so **give the company their
eyeline and inner state as silhouette and posture** — a head tipped back, a step halted, a
shoulder set — and let the readable **faces belong to the crowd** they are lit by.*

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
> atmospheric haze and drifting embers. Rich brush texture, grounded anatomy.
> **[EYELINE — what this figure is looking at, named explicitly]**, **[INNER STATE — the
> feeling at this instant, given as two or three physical tells]**. Portrait orientation
> ~3:4, high detail.
>
> **Negative:** anime, cartoon, cel-shaded, 3-D render, comic ink, flat vector,
> bright even lighting, oversaturated, glossy, modern clothing or objects, text,
> watermark, signature, border, extra limbs, deformed hands, a calm or blank expression,
> a neutral face, a posed portrait look, looking at the viewer.

## The iron rule: canonical likeness

When the image depicts a character listed in [`../characters/CANON.md`](../characters/CANON.md),
**supply that character's canonical portrait to the image tool as a reference image**
and preserve their likeness anchors. Never regenerate a known character from a text
description alone — they must be recognizable from picture to picture. If a scene has
several canon characters, provide every available reference. New (unlisted) characters
are rendered fresh in this style and, once settled, added to the registry.

**Before writing the prompt, open the portrait.** Read the actual `characters/*.webp`
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

**A recurring PLACE is canon exactly as a face or a relic is.** The first illustration of a room
settles what that room looks like, and every later image of it must agree. **Before illustrating a
location that has already appeared, find that image, `Read` it, attach it as a reference, and name
it in the prompt as the established look** — telling the model to match its *architecture, materials
and palette* but explicitly **not** its camera position, so the result reads as the same room from a
new angle rather than a re-shot of the old composition. Then write the room's specifics into the
prompt body from what the PNG actually shows; the attached reference alone will not carry them.

*Learned on the **Corruption Forge**. The Ch. XVII image
[`../images/the-cage-over-the-forge.webp`](../images/the-cage-over-the-forge.webp) had already
established it as a long **barrel-vaulted hall** — furnace at the far end with a white-hot arched
mouth at floor level, red rune-carving, and the cage running an **overhead rail and girder** along
the ceiling. The Ch. XVIII prompt was drafted from the chapter text alone and described a **vertical
shaft** with the furnace at the bottom of a well. Nothing in the prose contradicted it; it was simply
a different room, and it would have shipped two irreconcilable views of the same place one chapter
apart. Matt caught it by asking whether the earlier shot should be referenced.*

The **Shrine of Erastil** in Drezen's southern quarter
([`the-shrine-that-was-desecrated`](../images/the-shrine-that-was-desecrated.webp), Book III Ch. IV):
a small, poor building **made ENTIRELY OF WOOD — this is the rule and there is no stone in it at
all**: vertical timber plank walls, a **plank floor**, exposed wooden roof beams, and a **WOODEN
altar** of heavy dark planks. One room seating perhaps thirty, with **several MISMATCHED pews** of
different sizes and builds, plainly made by different hands and standing knocked crooked, no two
parallel. Set into the timber wall **directly behind the altar is a plain closed plank door with iron
hinges**, leading to the priest's private chambers. *(Matt's direction, Aug 2026: the first render
gave it a stone floor and stone altar and was re-rolled.)* **In the desecration scene only**, the
altar carries the Abyssal blood-script, the boards are blood-spattered, a snapped longbow lies before
it, and the carved stag devices behind the altar are hacked through with a dagger — **that damage is
the scene's, not the room's.** By *The Sacred Hunt*, later in the same chapter, **Jeskar Hinton** is
rebuilding it: the desecration is cleaned away and he is making new pews by hand. *Avoid:* `a stone
floor, flagstones, a stone altar, masonry, plaster, stained glass, a vaulted or grand interior, pews
in neat aligned rows`.

The **Weeping Hills** ([`the-weeping-hills`](../images/the-weeping-hills.webp), Book III Ch. IV):
**and the point of this place is that it was GOOD COUNTRY, not a wasteland.** Rolling green upland —
hedged meadows, broadleaf woods, mossy outcrops, an old drystone wall — the sort of generous,
well-watered land **Erastil**'s church chose to entomb a saint in, and **real living green must
survive and be obvious** in the hollows and on the far hills. Through it is torn a **jagged, raw,
ugly FISSURE about two hundred feet deep**, violently out of keeping with the soft land around it,
its edges crumbling and the grass ending dead at the lip. **The despoiling is a GRADIENT radiating
from the crack** — ash-grey scorched ground and bare blackened trees at the rim, sickly yellow-brown
grass further out, healthy green beyond. Down inside runs a **narrow, defined river of lava** with a
dark crusted skin (**not a lava lake and not a broad cracked plain**), and molten stone **seeps from
the fissure walls and runs down in glowing rivulets and hanging teardrops** — the weeping that names
the place. The crack **belches columns of grey-brown smoke and ash** that drag a pall across the sky.
On a green hilltop clear of the wound stands an ancient **mossy cairn topped by a standing stone
carved with a STAG'S HEAD AND ANTLERS** — Erastil's device, never a cross. Light: smothered midday,
a flat ash-choked grey lid, with the lava the **only** warm accent and confined to the crack; the
picture reads **grey-green with a burning line through it**, never orange overall.
*(Matt's direction, Aug 2026: the first render was a wall-to-wall basalt hellscape with no green at
all, and was rebuilt on this concept.)* **Delamere**'s tomb lies in a tunnel off the gorge floor, so
the company returns here. *Avoid:* `a volcanic wasteland, basalt columns filling the frame, a lava
lake, a totally dead world, no vegetation, an orange or red sky, a uniformly orange image`.

Locations with an established look so far: the **Corruption Forge**
([`the-cage-over-the-forge`](../images/the-cage-over-the-forge.webp), and
[`the-ice-that-would-not-lie`](../images/the-ice-that-would-not-lie.webp) for its floor and its salamanders) and
the **Ritual Chamber** ([`the-line-the-ice-drew`](../images/the-line-the-ice-drew.webp)), and the
**Defiled Temple of Sarenrae** below the cliff path — the **Baphomet** shrine at the mouth of the
Ivory Labyrinth ([`the-blinding-flash`](../images/the-blinding-flash.webp), Book III Ch. I): a large
vaulted stone chamber inside the cliff, heavy square pillars and a groin-vaulted ceiling lost in
darkness, ancient masonry whose **Sarenrae** sun-motifs have been hacked off and replaced with
standing idols of a **goat-headed winged demon** — shaggy goat's head, long ridged curling ram's
horns, folded leathery wings — several along the side walls and one enormous idol dominating the
far end, with heavy dark curtains over the side passages and a broad stone stair rising into the
hall from the cave mouth. The **Templars of the Ivory Labyrinth** who hold it wear dark blackened
full plate, richly made and demonic in style, and carry **glaives**. The company goes deeper into
this place in later chapters — match this hall's architecture, materials and palette, but not its
camera position. **⚠️ THIS HALL HAS TWO CANONICAL STATES, AND YOU MUST PICK THE RIGHT ONE.**
**BEFORE** *The Fane Remade* (Book III Ch. II) it is the defiled temple above: dark, dim, blackened
stone, blood-script, goat-headed idols — [`the-blinding-flash`](../images/the-blinding-flash.webp).
**FROM THE MOMENT THE HERALD'S SERVANTS SWEEP THROUGH IT, it is re-hallowed and it never goes back:
every surface becomes WHITE MARBLE SHOT WITH THIN GOLD VEINS, the corruption gone entirely, and the
enormous goat-headed idol at the far end is now an ENORMOUS SERENE SARENRAE** with a radiant sun-disk
— [`the-wall-remade`](../images/the-wall-remade.webp) for the material and
[`the-empty-ropes`](../images/the-empty-ropes.webp) for the transformed hall. For any scene set here
afterwards, attach the *after* images, and if you also attach `the-blinding-flash` for its
architecture, say explicitly that you want **its layout ONLY and not its surfaces** — a dark
reference will drag the render back toward the drab room. *(Caught by Matt, Aug 2026: the first
staging of `the-empty-ropes` had the judgment happening in the old dim temple, one scene after the
place had been made new.)* The switchback stair and the smashed **Sarenrae** relief on the cliff face above
it are established by [`the-broken-sarenrae`](../images/the-broken-sarenrae.webp). Add a line
here the first time any location is illustrated.

**A figure high above the ground needs its SCALE pinned, or it becomes a god.** Put a hero in the
air with other figures far below and the model will quietly render those distant figures at the
*viewer's* eye level. The implied camera then sits on the floor beside them, and the airborne hero
reads not as a person forty feet up but as a colossus filling the sky. The picture looks impressive
and is wrong, and the error is easy to miss until you notice how small the people are.

**State the camera's height and the subject's real size explicitly** — *"the camera is level with
her, forty feet off the floor, NOT down on the ground looking up"* — and say plainly that she is
**an ordinary young woman of ordinary size**, not a giant, a titan or a deity. If the distant
figures are only atmosphere, it is usually safer to **crop them out entirely** than to try to place
them correctly.

*Learned on a scrubbed image of Rabiah aloft over the Corruption Forge: at a glance it read well, but
the salamanders below sat at the viewer's eye level and turned her into an immense sky-god hanging
over the room. The same render also made the box cage cylindrical despite the reference — a reminder
that an attached reference does not enforce a shape unless the prompt also names it.*

**Write the corrections as negatives, not just positives.** The model fills any silence
with its own defaults, and its defaults skew toward sexualized armor on women and
orc caricature (tusks, underbite) on half-orcs. Put the explicit "no …" clauses in the
prompt body *and* the `Avoid:` line. See CANON.md's *Known drift* section.

**Check the corners for a signature — `signature` in the Avoid line does not reliably stop it.**
The model sometimes scrawls a fake artist's mark into a dark corner anyway, and at full-page size it
is easy to miss. **Crop the bottom corners and magnify them before publishing.** If one is there,
the cheap fix is a small crop rather than a re-render: trim proportionally so the frame holds ~3:4
and the composition survives (`what-chyrrik-brought-back` went 1086×1448 → 1060×1413 for this, losing
nothing but dark rock).

**QA the render against the portraits** feature by feature before publishing, and
regenerate rather than shipping a drifted likeness.

## A referenced character will not recede — don't ask them to

**The moment you attach someone's reference portrait, the model treats them as the subject.**
Ask for that same character to be *small, unlit, in shadow, and ignored by the crowd* and you are
fighting the tool: it reads the reference as *this is who matters*, and quietly promotes them —
lighting them, centring them, clearing space around them, or lifting them above the crowd as
though they were standing on a riser. Restating "small" and "unnoticed" in the prompt does not
fix it, and neither does the Avoid line.

**So don't argue with it — compose around it.** When a named character must be incidental, use a
framing where their prominence is *structurally impossible*:

- **Put the camera behind them.** Backs fully to the viewer in the near foreground: they frame the
  shot and cannot dominate it. (See `the-garrison-of-runners`, where the emotion belongs to the
  one face turned toward us.) This also costs no reference at all.
- **Crop them.** Heads and shoulders very close to camera, cut by the frame edge.
- **Occlude them** behind bodies, furniture or doorways, so the crowd physically covers them.
- **Or cut them from the frame entirely** and let the caption carry that they were present.

*Learned on the first `the-ballad-of-the-wardstones-champions`, which asked for the four to stand
small and unnoticed at the back of a roaring tavern. Every one of them came back lit, spaced and
elevated above the crowd — not because the prompt was unclear, but because five attached
references cannot be background.*

## Every figure needs an eyeline and an inner state — this is mandatory

A prompt that says where a figure stands and what they hold, but not **where they are looking**
or **what they feel**, will get back a neutral, camera-aware portrait face dropped into the
scene. The model has no default emotion, so it supplies none — and a blank face in the middle
of an event reads exactly like a character sheet pasted over the artwork. **State both for
every named figure, every time.**

**1. Eyeline — name the thing they are looking at.** Not "she looks intent"; *"her eyes locked
on the point where the prongs meet the crystal."* Name the actual target in the frame. If a
figure has no reason to look anywhere in particular, that is a sign the composition hasn't
decided what the picture is about yet.

**2. Inner state — name the feeling, then give two or three physical tells.** An adjective
alone ("determined", "afraid") mostly doesn't survive into the render. The tells do: *eyes wide,
brows raised and drawn together, lips parted, breath caught, jaw set, shoulders hunched, teeth
gritted, tears standing.* Pick the feeling from **what the chapter says is happening to that
character at that instant**, not from a generic heroic register.

**3. The emotion is the beat, not decoration.** Ask what the moment costs the character and
render *that*. Rabiah breaking the Wardstone is not performing a careful technical operation —
she is destroying a holy thing set in place by a god, and the face has to carry awe and dread
together. Harlock in the chokepoint is not posing; he is being unmade and holding anyway.

**The house "serious, weathered expression" is the resting default for a standing portrait —
not for a character inside an event.** When something is happening in the frame, the event wins.
Don't let the calm default override the beat.

**Put the negatives in every prompt:** `a calm or blank expression, a neutral face, a posed
portrait look, looking at the viewer, looking past the subject of the scene`.

**QA — the pasted-portrait test.** For each named figure, ask: *can I say in one sentence what
they are looking at and what they are feeling?* Then the sharper version: **if you cropped that
face out and used it as a standalone portrait, would you notice anything missing?** If the
answer is no, the face is disengaged and the image needs another pass. This is what went wrong
in the first `the-rod-touches-the-stone` — everything in the frame was correct except that
Rabiah was gazing placidly off past the artifact she was in the act of destroying.

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
