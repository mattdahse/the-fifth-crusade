# The Scrapyard

<!-- id: scrapyard -->
<!-- image: images/the-scrapyard.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 80 -->
<!-- scale: one square — five feet -->

Hesk Dolvan's yard and house on Cinder Row. The yard fills the west two-thirds; the house is
the block on the east side, drawn as a cutaway so the rooms are visible.

## The ground

**The yard** is entered by a wide double gate on the west, standing open onto the street. Inside
it is a maze rather than a lot: seven separate heaps of sorted scrap taller than a man, a
handcart, a woodpile and chopping block, a water trough, and a kennel with a staked chain at the
south-west. **Every heap blocks line of sight**, which is what makes the approach interesting and
what lets two dogs work a party that came in through the gate.

**The house** has four rooms and no door into the yard except one, at the south-west corner:

1. **The kitchen**, north-west — stove and hanging pots.
2. **The children's room**, north-east — two straw beds and a crib. This is the room.
3. **The living room**, the middle band — table, benches, a hearth in the east wall, and the
   **trapdoor** in the floor.
4. **The shop**, the whole south end — counters and sorted metal, with the street door.

## Occluders

Top-left image pixels. The fence and the house walls are straight, so these are written by hand.
Verify with `python fg/verify.py --map scrapyard`.

<!-- occluder: 160,0 975,0 -->
<!-- occluder: 160,0 160,360 -->
<!-- occluder: 160,610 160,930 -->
<!-- occluder: 160,930 975,930 -->
<!-- occluder: 985,0 985,850 -->
<!-- occluder-door: 985,850 985,900 -->
<!-- occluder: 985,15 1462,15 -->
<!-- occluder: 1462,15 1462,900 -->
<!-- occluder: 985,900 1165,900 -->
<!-- occluder-door: 1165,900 1255,900 -->
<!-- occluder: 1255,900 1462,900 -->
<!-- occluder: 985,255 1160,255 -->
<!-- occluder-door: 1160,255 1215,255 -->
<!-- occluder: 1215,255 1462,255 -->
<!-- occluder: 985,540 1165,540 -->
<!-- occluder-door: 1165,540 1235,540 -->
<!-- occluder: 1235,540 1462,540 -->
<!-- occluder: 1190,15 1190,255 -->

**The gate is standing open** and carries no occluder — the gap in the west fence between
y 360 and y 610 is the way in.

**The scrap heaps are not occluders.** They are cover and they break sight, but a heap is not a
wall and FG's line-of-sight layer would make them absolute. Rule them as cover at the table; if
you want them hard, the plate is there to trace.
