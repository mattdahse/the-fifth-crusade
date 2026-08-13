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

The **governor's dining hall** in **Drezen**
([`half-out-of-her-chair`](../images/half-out-of-her-chair.webp), Book III Ch. IV): the hall where the
city's commander entertains, **built by the dwarves who raised the fortress** and inherited by the
crusade. **Grand, but emphatically not a palace** — dwarf-work: massive squared masonry in warm
grey-brown stone, heavy square piers carrying low broad round-headed arches down the side walls,
deep-cut geometric relief banding at head height, a high ceiling of stone ribs and dark oak beams,
black iron strapwork and iron sconces on the piers, and a great carved stone hearth further down the
room. One long, heavy, age-polished dark oak table. The service is a governor's: pewter chargers and
beaten silver plate, silver-mounted glass, a silver flagon, a heavy branched candelabrum. **The two
failure modes are both real and opposite** — say "dining hall" alone and it comes back a *roadside
public house* (rough plaster, wooden bowls, clay jugs, a low beamed cottage ceiling); overcorrect and
it comes back a *throne room*. Name the dwarven masonry positively and put both sets of negatives in.
*(Matt's direction, Aug 2026: the first prompt for this scene was written as a cramped eating-house
and was rebuilt before it ever rendered.)* *Avoid:* `a roadside inn, a tavern, a cramped low common
room, rough plaster or timber-framed walls, wooden bowls, clay or earthenware jugs, tin cups, a
gilded palace, gold leaf, marble, stained glass, silk tapestries`.

The compound of **Rabiah's Redeemers** on **PARADISE HILL** in **Drezen**
([`a-lot-to-take-in`](../images/a-lot-to-take-in.webp), Book III Ch. IV): after the liberation each of the
four raised a stronghold on Paradise Hill, and Rabiah's is a ramshackle mini-district of art and culture
where her followers live and work. **It was built by sixty enthusiastic amateurs with no plan and no
authority, and every room shows it** — mismatched salvaged timber plank walls that do not meet square,
crooked ceilings of reused beams sitting at **two different heights** where two builders met in the middle,
doorways with no doors, holes knocked through plank walls into the next room, windows set where windows
have no business being. Nothing is plumb, nothing matches, and the place looks **grown rather than built**.
*The follower account [`follower-tam-redeemers`](../secrets/follower-tam-redeemers.md) is the authority on
its interior logic — the kitchen with three roof heights, the two rooms with a hole knocked between them,
"Tuesday's mistake", the courtyard they created by accident building in a circle.* **Rabiah's own chamber**
lays a second coat over that raw carpentry: **luxury as poor people imagine luxury — never the sober,
tasteful luxury of inherited wealth.** Cheap dyed silks and painted cloth nailed straight onto bare planks
in clashing reds, purples and greens; soft wood painted with gilt rather than truly gilded; a low bed
heaped with far too many mismatched cushions; tassels, a scrap of carpet on bare boards, a mirror of poor
wavy glass, strings of coloured beads. Every flat surface is crowded with **odd gifts from her followers
that she cannot refuse or throw away without hurting somebody's feelings** — carved wooden figures of her,
a clumsy painted portrait hung crooked, painted tiles, clay animals, an amateur bust — all honest,
well-meant and slightly wrong. **Light it with ONE small oil lamp at night**, so the colour sinks into
brown-black shadow and glints only at the edges: the room reads gaudy while the picture stays muted.
*(Matt's direction, Aug 2026.)* *Avoid:* `a stone cell, stone walls, masonry, a barracks, a tent, a tidy or
well-built room, square plumb carpentry, a tasteful or elegant aristocratic interior, marble, gold leaf, a
palace, a bright cheerful colourful image`.

**A **tavern in Drezen** ([`no-one-would-confide-in-him`](../images/no-one-would-confide-in-him.webp),
Book III Ch. IV): **Drezen has no old taverns of its own.** The city was a ruin in demonic hands for
decades, so any drinking house in it is one of two things, and you must pick deliberately: **(a) newly
built** — raw new-sawn pale timber, unseasoned plank walls, fresh joinery, a plank bar laid across
barrels, mismatched salvaged stools and benches, low new-cut roof beams, and nothing yet darkened by
smoke or worn smooth by use (grubby already, but not *old*); or **(b) an old dwarven shell with recent
repairs** — the squared warm grey-brown masonry and low broad round-headed arches of the citadel work,
patched with obvious new timber. The Ch. IV image is **(a)**, in the poor southern quarter near the
timber shrine of **Erastil**. *Avoid* for either: `an ancient smoke-blackened tavern, centuries of patina,
timeworn polished wood, a cosy old-world inn`.

**⚠️ Do NOT reference [`the-ballad-of-the-wardstones-champions`](../images/the-ballad-of-the-wardstones-champions.webp)
for a Drezen interior — that tavern is in KENABRES.** Its heavy dark timber, bottle-stacked bar wall and
iron hanging lanterns belong to an old city that had centuries to accumulate them, and Drezen has had
months. *(Caught by Matt, Aug 2026, when it was staged as a Drezen reference for exactly this scene.)*

**Lupenor's Market** — the open trading square of the **Celest House** district in **Drezen**
([`something-better-than-coin`](../images/something-better-than-coin.webp), Book III Ch. IV, and
[`retroactive-to-yesterday`](../images/retroactive-to-yesterday.webp) for the lane at ground level with
the trading house lit at the far end): the market
**Lupenor Celest** founded with three thousand gold of her own, at the southeastern foot of the walls.
*The follower account [`follower-silas-thorne-market`](../secrets/follower-silas-thorne-market.md) is the
authority on how it works* — sixty-odd registered merchants, permanent stalls twelve feet by eight with
rooms above, a fire-insurance pool, standardized weights, and the three-storey **Celest House** itself
rising over the lane with its windows lit while the clerks work late. **The Drezen rule governs it
absolutely: this market is MONTHS OLD, NOT CENTURIES.** Raw new-sawn pale timber, plank counters laid
across barrels, unseasoned board walls, fresh joinery, canvas and salvaged sailcloth awnings on new-cut
posts, mismatched crates and stools — grubby already from use, but nothing smoke-blackened, worn smooth,
or timeworn. Behind and between it, the squared warm grey-brown **dwarven** masonry of the old city
patched with obvious new timber, and the broken wall beyond. **The crowd is the point of the place**:
crusaders in mismatched campaign kit, porters under sacks, refugees, a bread stall, a tinker's cart,
bolts of cloth — arriving faster than **Drezen** can house them. Light it at **evening**, the hour
Lupenor works her own stalls: a low westering sun straight down the lane, raking through dust and
cook-smoke, with the first oil lamps just kindled — one warm gold accent in an otherwise muted
brown-grey frame. *Avoid:* `an ancient smoke-blackened market, centuries of patina, timeworn polished
wood, a cosy old-world bazaar, a stone-built medieval town square, a bright cheerful sunlit scene`.

**Drezen's WALLS AND GATES** — **the fortifications are INTACT, HELD AND GARRISONED, and this is the
single hardest thing to get out of the model.** The crusade retook this fortress and the walls are the
part it repaired first; the western gate is a working gate that an expedition marches out of, not a
picturesque ruin. Render it positively and concretely: squared warm grey-brown **dwarven** masonry
standing **whole and square**, unbroken battlements with sentries on them, heavy **new-cut timber gate
leaves on black iron hinges standing open**, a raised portcullis, and obvious fresh timber splices and
pale new mortar where siege damage was made good. ⚠️ **The house "crumbling cities, broken walls"
register in *World* above will drag every Drezen exterior back toward ruin unless you fight it in both
directions** — say *intact, whole, sound, repaired, held, garrisoned* in the body **and** put the ruin
words in `Avoid:`. *(Matt's correction, Aug 2026: the western gate came back a ruin on two consecutive
rolls of `the-clash-beneath-the-fortress-gate`.)* *Avoid:* `a ruin, a ruined gate, ruined or crumbling
walls, broken or gap-toothed battlements, a breach in the wall, rubble, collapsed stonework, an
abandoned or derelict gatehouse, ivy or overgrowth on the walls`.
**⚠️ It is the WESTERN gate, and the expedition leaves at DAWN — so the sun is BEHIND THE CAMERA,
never through the arch.** A shot taken from inside the city looks west; the rising sun is in the
east, at the viewer's back. Through the open archway lies the **Ahari riverbed and the wasteland,
still in cold blue pre-dawn shadow under a pale colourless sky**, while the low early light rakes
in over the viewer's shoulder onto the figures and the inner face of the gatehouse. This collides
with the house habit of backlighting the subject: say where the sun is **relative to the camera**,
not merely "behind the figures", or the model obligingly hangs a sunrise in the gateway.
*(Matt, Aug 2026: "the rising sun is seen through the gate. The WESTERN gate. That's bad.")*
*Avoid also:* `a sunrise or sun disk visible through the gateway, a glowing horizon through the
arch, a sunset through the gate, the sun sitting in the archway`.

**The strongholds on Paradise Hill each have a follower account, and that account is the authority on
the place — read it before illustrating there.** Book II's *Paradise Hill* section describes what each
was built to be. Three of the four are now established by the follower-story plates below; **Lupenor**'s
**Celest House** itself — the trading house sited closer to the citadel, as opposed to her market — is
still unillustrated inside.

**THE WESTERN TOWER** — the hall **Harlock** claimed for **Iomedae's Preservers**
([`the-true-preservers`](../images/the-true-preservers.webp); the account is
[`follower-aldwin-brightblade-preservers`](../secrets/follower-aldwin-brightblade-preservers.md)): a
**dwarf-built** hall in a tower of the citadel, defiled through the occupation and **scrubbed out by hand
by the volunteers who then swore their oaths in it** — so it is **INTACT, SOUND, CLEAN AND BARE, never a
wreck**, and the house ruin register must be fought here as everywhere in **Drezen**. Massive squared
warm grey-brown masonry, heavy square piers carrying **low broad round-headed arches**, deep-cut geometric
relief banding at head height, a ceiling of stone ribs lost in darkness. **Bare flagstone floor, dark and
wet from scrubbing, standing water in the joints** — that wet floor is the room's signature, because it
takes the light as a long reflection. Iron sconces on the piers. A low plain stone altar. **Buckets and
scrubbing brushes still pushed against the wall**: the place was cleaned yesterday and the order is a
month old. Light it with **one source and nothing else** — in the investiture that is ***Radiance*** drawn,
gold-white, falling off fast to brown-black. *Avoid:* `a ruined hall, rubble, a collapsed ceiling, broken
walls, a cathedral, stained glass, pointed gothic arches, a church interior, daylight, windows, a second
light source`.

**THE TEMPLE OF SARENRAE's COURTYARD** — **Varic**'s temple in **Drezen**
([`the-first-green-in-seventy-years`](../images/the-first-green-in-seventy-years.webp); the account is
[`follower-dawns-fire-temple`](../secrets/follower-dawns-fire-temple.md)): **eight open ALCOVES for eight
faiths** — low bays with plain round-headed arches — enclosing a courtyard on three sides, **still being
built a month after the liberation**: several bays finished, others open to the sky with rough timber
scaffolding lashed to them, cut stone waiting on the ground, a mortar trough and coils of rope. The
**Drezen months-not-centuries rule governs**: squared warm grey-brown dwarven masonry, freshly cut and
sound, extended with obvious **raw new-sawn pale timber** and pale new mortar; grubby from work, never
weathered or smoke-blackened. **In the middle of the courtyard is ASHA's GARDEN**, and it is canon: a
worked plot some **twenty-five feet by fifteen** of turned earth, darker and damper than the ash-grey dust
around it, bounded on all four sides by a **LOW EDGING FENCE only a few inches high — short new-sawn
boards on edge, squared stakes every few feet, a taut line of twine between the stake tops** — unbroken
but for one gap at the near corner. **The only saturated colour in any picture of this place is the green
growing inside that fence.** It is the first natural growth in **Drezen** in seventy years, so keep the
planting young: rows of **two- or three-inch seedlings** with most of the earth still bare, and never a
mature or lush garden. Light it at **evening**, a low westering sun raking across the courtyard through
hanging dust. *Avoid:* `a lush or full-grown garden, mature crops, flowers, grass, a lawn, weeds, trees,
moss, green anywhere except the seedlings, a cathedral, stained glass, pointed gothic arches, a finished
or grand temple, an ancient weathered building`.

**THE COMPOUND OF RABIAH'S REDEEMERS — the OUTSIDE**
([`bet-you-we-can`](../images/bet-you-we-can.webp) for the yard and the roofline; the interior logic is
[`a-lot-to-take-in`](../images/a-lot-to-take-in.webp) and the account is
[`follower-tam-redeemers`](../secrets/follower-tam-redeemers.md)). Everything in the Paradise Hill entry
above holds outdoors and is, if anything, more obvious from the yard: mismatched salvaged timber plank
walls that do not meet square, **crooked roofs of reused beams sitting at three different heights** where
different builders met in the middle, doorways with no doors, a window where no window belongs, a lean-to
propped against a lean-to. **Cheap bright dyed cloth — reds, purples, yellows — strung between posts at
odd angles overhead.** Nothing is plumb and the place looks **grown rather than built**. The buildings
enclose a **rough courtyard the followers made by accident, by building in a circle**. Light it at night
or dusk **from BELOW and INSIDE** — cooking fires, braziers and hanging lanterns throwing warm gold up
onto faces, the undersides of the strung cloth, and the crooked eaves. ⚠️ **A scene here is a scene about
the SIXTY-ODD FOLLOWERS, and the follower accounts are their stories, not Rabiah's** — put the camera
down among the crowd, let every readable face belong to them, and if **Rabiah** must be present keep her
small, distant and unreadable. *(Matt's direction, Aug 2026, on this very plate: the first staging put the
camera up at roof height with her as the subject and was rebuilt from inside the crowd. **Her portrait was
deliberately not attached** — see *A referenced character will not recede* above; describing her in text
is what let her stay small.)* *Avoid:* `a tidy well-built structure, square plumb carpentry, neat matching
rooflines, a stone building, a castle, a barracks, an ancient weathered timber building, moss or ivy`.

**RABIAH'S SECURE SHELTER** — the conjured stone cottage
([`the-shelter-in-the-rain`](../images/the-shelter-in-the-rain.webp) for the outside,
[`night-terrors`](../images/night-terrors.webp) for the inside; Book III Ch. V). **This is not a
place, it is an OBJECT that recurs** — **Rabiah** conjures it from scrolls, and later with mythic
power, and from this chapter on it is where the expedition sleeps. **The spell makes the SAME
building every time: do not redesign it, and do not let it drift from one chapter to the next.**
One room, twenty feet square, comfortable for eight — and the company habitually packs twenty-odd
people and four horses into it, which is the joke and should always be legible.

**Outside.** A squat single-storey block, roughly a cube. Walls of large squared **cold blue-grey
ashlar laid in regular courses**, the joints tight and dark, the block faces hammer-dressed and
faintly rough, the arrises crisp; **alternating long-and-short quoins at the corners.** A
**low-pitched roof of overlapping grey stone shingles** with a slight overhang. **No windows, no
chimney, no ornament, no carving, no steps** — the walls meet the bare ground directly. One
**rectangular** doorway with a **single massive squared stone lintel** and plain squared jambs —
**not an arch**. In it a heavy **dark-oak plank door, vertical planks, horizontal iron strap bands
and long black iron strap hinges**, opening **inward**, with warm yellow lamplight behind it.
*(The Ch. V prompt asked for seamless mortarless stone and the render came back as coursed ashlar.
**The render governs** — it reads as a real building, which makes the wrongness better, not worse.
Do not "correct" it back to seamless.)*

**The point of it is that it is CRISP, UNWORN AND WRONG FOR WHERE IT STANDS.** No moss, no ivy, no
cracks, no weathering, no subsidence, nothing picturesque: a sound, sharply-cut building sitting on
churned mud in a blasted waste as though set down there whole an hour ago.

**Inside.** One bare room. **Plain, smooth, undifferentiated dark grey-brown stone — the coursing
that shows outside does NOT read inside**, the interior walls are featureless. A flat stone floor.
**No furniture of any kind, no hearth, no window, no fittings** — people sleep on bedrolls laid
straight on the stone. Light it with whatever small source the scene has (a low oil lamp on the
floor works) and let everything past its reach fall to brown-black; the room is only ever seen as
far as the light carries. *The spell also conjures an* ***unseen servant*** *for its duration — it
is invisible and changes nothing about how the room is drawn, but it is why a cook can be set to
work in there.*

*Avoid:* `a thatched roof, a mossy or ivy-covered cottage, a weathered or ancient cottage, a ruined
building, a cosy cottage in a garden, a hut, a cabin, a timber or half-timbered building, a manor, a
tower, a castle, a chimney, glazed windows, shutters, a hearth or fireplace, furniture, an arched
doorway, a cottage that comfortably fits the crowd`.

The **MOLTEN SCAR** — the open chamber in the **Marchlands** where **Harlock** was taken at fifteen and
where the company kills **Vorimeraak** ([`the-same-ritual`](../images/the-same-ritual.webp), Book III Ch. VII).
⚠️ **Do not confuse this with the "Ritual Chamber" entry below** — that is a different room entirely, under the
ice. This one is **open to the sky**. Its plan is fixed by Matt's encounter map and must not be redrawn: a
**broad, irregular, lobed LAKE OF MOLTEN ROCK** filling the floor of a bowl ringed by **near-black cliffs**;
**flat-topped ISLANDS of cooled dark grey stone** standing out of it with **craggy stepped sides** — a broad
rubble-strewn one toward the north-west, a **larger one on the eastern side** (where the ritual is worked and
where **Abner Suthi** dies), a tongue of rock reaching in from the **southern** shore,
and a small isolated rock to the north-east; and on the **south-western shore, on dry ground outside the lava**,
a **DENSE FIELD OF PALE BLUE-WHITE CRYSTAL** — dozens of great angular spires, many taller than a man, tilted
and interlocking into a thicket like a forest of ice. *(It is one of these that yields the uncut diamond.)*
⚠️ **VORIMERAAK DIES HERE, ON DRY LAND IN THE CRYSTAL FIELD — not on an island, not over the lava, and not in
the air.** The fight carries off the lava onto this shore and **Harlock** kills her standing on the rock among
the spires. *(Matt's ruling, Aug 2026. The chronicle originally had him kill her on the wing and her body fall
into the lava; that was wrong and the prose has been corrected. It is also what makes the rest of the chapter
cohere — the party carries her scythe home, which they could not do if she had gone into the magma.)* Any
illustration of that kill puts **both fighters on solid dark rock among the spires**, with the lake behind them
as light rather than as floor.
**The lava is HOT and mostly OPEN and LIQUID** — vivid orange shading to yellow-white in the hottest channels,
with only scattered dark plates of cooled skin drifting on it. **It is a LAKE, never a river, a stream, a
channel, or a crusted plain with glowing seams** — a lava *stream* is the established look of the **Weeping
Hills**, and these two places must not read alike. **The established camera stands at the BASE of the southern
peninsula looking NORTH**, at a standing person's eye height with a **level** horizon: sky and cliffs across the
upper third, the eastern island centre frame, the lake filling the lower half, the crystal field small at the
far left, dark foreground rock at the lower left. **Light it as a BRIGHT BURNING LAKE SET IN A DARK CHAMBER** —
the lake is the only source and everything else (sky, cliffs, the rock underfoot) stays near-black, catching
the glow only along its edges; figures on the islands are **rim-lit from below**. The picture must never read
uniformly orange. Sky: a low, heavy, turbulent dark grey-brown overcast, never a glowing orange sky.
*Avoid:* `a lava river, a lava stream, a narrow channel of lava, a crusted plain with only glowing seams,
rounded domed or boulder-shaped islands, an orange or glowing sky, a uniformly orange image, an overhead or
bird's-eye view, a tilted horizon`.

*Method note, and it is worth reusing: this chamber was built in THREE PASSES rather than one, at Matt's
suggestion, because four attempts at the whole scene in a single prompt kept trading one fault for another
(geography right / palette wrong, palette right / lava a river). Pass 1 repainted his top-down battle map as
an empty painterly overhead — layout only, style discarded — which settled the plan, the materials and the
palette on a cheap empty frame. Pass 2 fed that back and moved ONLY the camera, to ground level. Pass 3 added
the figures to a room that was already correct. **Each pass changes exactly one thing, and the previous render
is the reference for the next.** The failure mode to watch for is that the model silently ZOOMS IN when you
add figures; the fix that worked was to re-state the approved framing element by element (what occupies the
upper third, where the horizon sits, what is at each edge) rather than saying "don't zoom".*

The **IVORY SANCTUM's entry hall** — the pillared hall behind the false wall at the **Green Gates**, where the
company fights the six minotaurs and meets **Jerribeth** (Book III Ch. XV). Established by three renders:
[`the-floors-were-clean`](../images/the-floors-were-clean.webp) is the authority on the room itself,
[`the-glaive-sized-gaps`](../images/the-glaive-sized-gaps.webp) for the portcullis end, and
[`the-frontline-sorceress`](../images/the-frontline-sorceress.webp) for the room with figures in it. **The point of
this place is that it is BEAUTIFUL, CLEAN, WARM AND IN USE — the opposite of the ruins the chronicle is otherwise
full of**, and the house "crumbling cities, broken walls" register will drag it toward rubble unless you say
*intact, sound, clean, warm, lived-in* in the body and put the ruin words in `Avoid:`. **FLOOR:** white marble,
unnaturally pure and pale, polished, in great slabs — somebody hauled it a very long way. **WALLS:** built entirely
of **SMALL CHIPS OF IVORY AND BONE**, a few inches across, set close together like a mosaic **with NO PICTURE IN
IT** — an endless close-packed mottle from stark bleached white through cream to yellowed old ivory. Light it so
the chips catch a raking beam and throw tiny shadows; that speckled bone skin over every wall is what makes the
room disturbing, and a straight-on view flattens it. **COLUMNS:** heavy marble, square-shouldered, plain-built, in
two rows, too thick to get your arms around; **on each one, carved in relief and gilded, a HORNED GOAT-HEADED
FIGURE SEATED ON A THRONE** — long ridged curling ram's horns, hands on the arms of the throne, a **five-pointed
star inscribed in a circle** behind his head. **They are carved gilded stonework: they do not glow and are not on
fire.** **CEILING:** twenty feet, plain, lost in gloom. **LIGHT:** small oil lamps in iron sconces set at head
height on the columns, each a small warm pool on pale stone, the far end unlit — one warm gold accent in an
otherwise bone-white and brown-black frame. At the west end, the **closed portcullis** of heavy dark iron bars,
with a chest-high **ivory plate bearing the outline of a hand** on each flanking pillar (a right and a left).
North, off to one side, **heavy dark drapes and a broad flight of unlit steps** rising into blackness.
*(Camera note, Matt's direction Aug 2026: shoot it OBLIQUE, turned ~40° off the hall's axis so two or three columns
of the far row stand clear against the far wall. A symmetrical view straight down the colonnade reads as an endless
corridor and shows the walls edge-on — put `a central vanishing point, a tunnel of columns, a nave` in Avoid.)*
*Avoid also:* `a cathedral, stained glass, pointed gothic arches, a church interior, painted murals, frescoes,
tapestries, pictorial mosaics, a figurative scene on the walls, a ruin, rubble, broken columns, daylight, windows`.

**JERRIBETH's BEDCHAMBER**, off the entry hall of the **Ivory Sanctum**
([`the-lady-of-the-house`](../images/the-lady-of-the-house.webp), Book III Ch. XV): warm, soft and expensively
kept, with one thing in it that is not. Walls of the same ivory-and-bone chip mottle as the hall. An **ENORMOUS
canopied bed** filling the background — carved posts, hangings swagged back, a dozen **satin pillows in deep teal,
oxblood and old gold**, a thick plush coverlet spilling onto the floor — and **a short iron chain with a single
manacle hanging from one bedpost**. A **semicircular sunken bath**, still steaming, smelling of lavender. A writing
desk with papers. A tall narrow **full-length mirror** in a dark frame. A slender dark **rod with a decorative
serpent's head** on a side table. And standing in the middle of the floor, **the rack**.
**⚠️ THE RACK IS THE THING THAT GOES WRONG, AND THE FIX IS GEOMETRY, NOT MOOD.** Described by material and
atmosphere — "a heavy contraption halfway between a gurney and a workbench, dark oiled timber, iron fittings, a
crank" — it came back as **the top of a standing chest** *(Matt, Aug 2026)*. What actually works is stating its
proportions and, above all, **that it is OPEN UNDERNEATH**: six feet long and barely two across, plainly built to
the proportions of a person laid flat and not to those of furniture; standing clear of the floor **on four slender
legs, with the floor visible straight through beneath it**; heavy leather straps with iron buckles that **hang
loose off the edges and dangle**, never lying flat on the boards; iron cuffs bolted at head and foot; a ratchet
windlass with a drum, an iron crank and a rope at the head end. A chest is solid to the ground — the daylight under
the legs is the whole difference. *Avoid:* `a chest, a cabinet, a sideboard, a dresser, a solid-sided box, a
workbench, a table with drawers, a piece of furniture standing flat on the floor with no legs, straps lying flat on
the surface`.
*(Keep every blood word out of BOTH halves of the prompt — describe the straps as old, dark and much-used leather
and say nothing more. Naming it as an exclusion is what counts it as content.)*

The **SHRINE OF TORAG** in the warrens beneath **Kenabres**, cleansed and reconsecrated by the company
([`a-safe-haven-restored`](../images/a-safe-haven-restored.webp), Book I): a small, low, windowless
dwarven shrine of heavy squared warm grey-brown masonry, ancient and dusty, its stone flag floor swept
clean in a rough circle where the company camps. The far wall carries a tall arched niche of **deep-cut
interlocking geometric dwarven relief**, and at the centre of it, carved in flat relief, **THE HAMMER OF
TORAG — a plain broad blacksmith's hammer, head and haft, and no other symbol.** Below it a low plain
stone altar with a **shallow round stone basin of still water** (the holy water Varic fills his vials
from). Light it with **two small clay oil lamps on the altar step and nothing else** — the gold rakes up
the carved relief and everything past its reach falls to brown-black. **It is cleansed, sound and quietly
safe, not a wreck** — the whole point of the place is that it is the first shelter the company has had.
*Avoid:* `a ruined rubble-strewn room, a collapsed ceiling, a second light source, daylight`.

Locations with an established look so far: **Rabiah's Secure Shelter** (above), the **Molten Scar** (above),
the three **Paradise Hill** strongholds — the **Western Tower**, the **Temple of Sarenrae's courtyard** and
the **Redeemers' compound** (all above) — the **Corruption Forge**
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

**A GROUP shot needs every figure's HEIGHT stated, in feet and in order — species labels do not
carry it.** Write "a gnome", "a dwarf", "a half-orc" and the model renders them all at roughly one
person-height, then randomises who ends up tallest. The failures are consistent and absurd: the
three-foot gnome comes out taller than the dwarf, and whoever the prompt described first towers
over everyone. *(Aug 2026, first roll of the secure-shelter scene: Brix stood over Durvik, Rabiah
loomed over the whole queue, and Cornelia's horse was pony-sized.)*

**Do all three of these:**
1. **Give each named figure a height in feet** in their line — *"Brix Copperfinch, THREE FEET
   exactly"*, *"Durvik, about four foot six but nearly twice as broad through the chest"*.
2. **Write the tallest-to-shortest order out as a single explicit list**, so the relationships are
   stated and not merely implied by the individual numbers.
3. **Spell out the pairwise comparisons the model reliably inverts** — *"Brix is SHORTER than
   Durvik. Durvik is SHORTER than Rabiah."*

**Pin the animals too.** A horse beside people defaults to pony-sized; say *"full-sized working
horses — the top of the shoulder level with or above a tall man's head."*

**⚠️ A SHORT ADULT RENDERS AS A CHILD UNLESS YOU PIN PROPORTIONS — AND HEIGHT WORDS MAKE IT WORSE.**
Stacking *short* + *smallest* + *slightest* on a figure with no age anchor is read as "young", not
"small", and what comes back is a child. **This bites Rabiah every time**, because she is genuinely
the shortest of the company and the temptation is to say so three ways.
*(Aug 2026, `the-mongrels-of-the-deep`: she came back looking about ten.)*

**The fix is PROPORTION, not height — height was never the problem.** Say all three:
1. **Head-to-body ratio, numerically:** *"her head is small relative to her body, about one-seventh
   of her standing height, with adult limb length and adult shoulder width."*
2. **An adult face, by its features:** *"a defined jawline, visible cheekbones, an adult nose and
   mouth at adult scale, eyes of normal adult size set at the midline of the skull"* — and name the
   child version as the negative: `large round childlike eyes, full round cheeks, a tiny chin, a
   tall rounded forehead`.
3. **Separate shortness from youth explicitly:** *"she is short the way a SMALL ADULT WOMAN is
   short, with adult proportions throughout. Her height is the ONLY small thing about her."*

**Also stand them up.** A short figure crouching or kneeling among standing adults loses the
proportion cues that prove they are grown; give them an upright pose where the full body reads.
And put `a child, a little girl, childlike proportions, an oversized head on a small body` in
`Avoid:` — this is about proportion only, so it carries no classifier risk, but keep every harm or
body word out of that line, as always.

**The cast's settled heights:** Fenna Tusk ~6'0" (tallest of the regulars) · Cobb Harwick ~5'10" ·
Pol Ashden ~5'9" and stooped · **Rabiah ~5'1" — SHORT for a human, and shorter than every adult
human around her; she never towers over anyone** · Durvik Stonesign ~4'6" and immensely broad ·
Cornelia Dewfoot ~4'0" (a child) · Selyse Avelia ~3'6" · Brix Copperfinch **3'0", the shortest
figure in any frame he appears in**.

**Write the corrections as negatives, not just positives.** The model fills any silence
with its own defaults, and its defaults skew toward sexualized armor on women and
orc caricature (tusks, underbite) on half-orcs. Put the explicit "no …" clauses in the
prompt body *and* the `Avoid:` line. See CANON.md's *Known drift* section.

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
- **Say whether the bow is DRAWN or SLACK, and describe the string's shape either way.** "Drawn"
  and "not drawn" are both states the model will otherwise pick for you. A **slack** bow needs
  saying just as explicitly as a drawn one: *"the bow is NOT drawn — the string slack and dead
  straight, a single straight line from top limb tip to bottom limb tip, not pulled back at all."*
- **A drawn bow comes back EMPTY.** This is a *separate* fault from the two-arrow blend already
  listed above, and it survives a prompt that says "one arrow nocked": the model paints the draw
  and forgets the ammunition, leaving a bent bow, a taut string and nothing on it. **Describe the
  nocked arrow as its own object with its own position** — *"a single arrow nocked on the string
  and lying along the left side of the bow, its head projecting past the grip, plainly present."*
- **Give the arrow a stated LENGTH, or it renders as a dart.** Describe an arrow only by what it is
  and where it sits and the model paints a comic little toy shaft a hand's-breadth long. It has no
  default sense of the scale of archery tackle, so **pin the proportion against the bow**: *"a
  full-length arrow, about two-thirds the length of the whole bow, its head reaching well past her
  bow hand and its fletching back at the string."* *(Matt, Aug 2026: "Lenne's arrow is comically
  small.")*
- **Specify the draw hand's FINGERS.** Left unsaid the model closes the whole hand into a fist
  around the string, which is not how a bow is shot and reads wrong to anyone who has held one.
  Say it anatomically: *"the string hooked by the first three fingertips only — index finger above
  the arrow's nock, middle and ring fingers below it, curled at the first joint — the archer's
  pinch."* Put `a closed fist gripping the bowstring, the whole hand wrapped around the string` in
  the Avoid line. *(Matt's correction, Aug 2026, on the first `the-clash-beneath-the-fortress-gate`:
  Lenne came back drawing a fist-gripped, arrowless bow.)*
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
- **Is there actually an arrow on the string?** Check explicitly. A drawn or half-drawn bow with
  nothing nocked is a common and easily-missed miss, and it is the fault that reads most obviously
  wrong to an archer.
- **Check the draw hand** — three fingertips hooked on the string, not a fist. And check the string
  matches the stated state: taut and angled for a draw, dead straight for a slack bow.
- **Weapon reach and grip** — hands actually grip the haft/grip; blade length is plausible and
  doesn't pass bloodlessly through the wielder; a thrust or swing connects where the light says.

These bite hardest on **archers — Lupenor above all**: aim-at-viewer, extra-arrow, and
broken-string faults tend to show up *together* on a first pass, so prompt against all three
from the start.
