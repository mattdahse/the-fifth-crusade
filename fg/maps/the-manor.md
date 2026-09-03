# The Sarkorian Manor

<!-- id: manor -->
<!-- image: images/the-manor.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 80 -->
<!-- scale: one square — five feet -->

A Sarkorian manor house that outlasted its village and most of its roof. One storey, six rooms,
walls mostly standing. Two breaches let the weather in and let anybody else in with it, and a
trapdoor in the fourth room goes down to [the cellar](the-cellar.md).

Big enough that no one group can hold all of it, which is the whole reason there are two.

## The rooms

Left to right along the north side, then the hall:

1. **The kitchen** — brick oven, fallen shelving. The west end, and the warmest room left.
2. **The store** — barrels and sacks, mostly emptied.
3. **The pallet room** — two straw beds. The **north breach** opens straight into it, so it is
   the easiest room in the building to walk into uninvited.
4. **The table room** — a rough table and stools, and the **trapdoor** in the floor.
5. **The sealed room** — north-east corner. Its doorway is completely blocked by fallen masonry,
   and it has been blocked a long time. This is the queen's, and she did not come in through the
   door.
6. **The great hall** — the whole south half, with the hearth in the west wall. Every one of the
   north rooms opens into it, which makes it the only ground everybody has to share.

## Occluders

Line-of-sight walls in **top-left image pixel coordinates**, written by hand rather than traced:
the manor is a built space and its walls are straight, so exact coordinates beat a threshold.

<!-- occluder: 80,80 80,892 -->
<!-- occluder: 80,892 1420,892 -->
<!-- occluder: 1420,892 1420,505 -->
<!-- occluder: 1420,365 1420,80 -->
<!-- occluder: 1420,80 925,80 -->
<!-- occluder: 595,80 80,80 -->
<!-- occluder: 383,80 383,452 -->
<!-- occluder: 621,80 621,452 -->
<!-- occluder: 865,80 865,452 -->
<!-- occluder: 1145,80 1145,452 -->
<!-- occluder: 80,452 175,452 -->
<!-- occluder: 262,452 429,452 -->
<!-- occluder: 530,452 705,452 -->
<!-- occluder: 780,452 984,452 -->
<!-- occluder: 1063,452 1420,452 -->

**The two breaches carry no occluder**, which is the point of them: the gap in the north wall
(x 595–925) opens into the pallet room, and the gap in the east wall (y 365–505) opens into the
hall. Sight and movement both pass. They are the reason this building cannot be held by six
people, and the reason the party does not have to come in through a door.

**The sealed room's doorway is solid** — the cross-wall runs unbroken across it, because the
rubble filling it blocks sight and movement both. Clearing it is work, and loud.

## A note on the grid

This plate was generated rather than drawn, so its walls do not sit on round multiples of a
square. The image is cropped so the **north-west inside corner lands exactly on (80, 80)** and
padded so half its width and height are multiples of 80, which makes the grid true at that corner
and along the north rooms. It drifts by up to half a square by the far south-east corner. That is
the honest cost of art-first, and it is worth it here; nudge `gridoffset` if it ever matters.
