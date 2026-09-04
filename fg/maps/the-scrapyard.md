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

**The house** has four rooms and two ways in. The **street door** is in the south wall of the
shop, off Cinder Row. The **yard door** is in the west wall, into the living room - the family's
own back door, and the one the party will use if it comes over the fence or through the gate
rather than walking in off the street.

1. **The kitchen**, north-west — stove and hanging pots.
2. **The children's room**, north-east — two straw beds and a crib. This is the room.
3. **The living room**, the middle band — table, benches, a hearth in the east wall, and the
   **trapdoor** in the floor.
4. **The shop**, the whole south end — counters and sorted metal, with the street door.

## Shortcuts

Pins the GM clicks to open the room's page in the book. Top-left image pixels, same space as
the occluders - the build converts them to FG's own (centre origin, y DOWN, which is the token
convention and NOT the occluder one).

<!-- shortcut: book:10_the_yard @ 580,450 | A1. The Yard -->
<!-- shortcut: book:11_the_kennel @ 250,800 | A2. The Kennel -->
<!-- shortcut: book:22_the_kitchen @ 1080,135 | B3. The Kitchen -->
<!-- shortcut: book:23_the_childrens_room @ 1320,135 | B4. The Children's Room -->
<!-- shortcut: book:21_the_living_room @ 1220,400 | B2. The Living Room -->
<!-- shortcut: book:20_the_shop @ 1220,720 | B1. The Shop -->

## Occluders

Top-left image pixels. The fence and the house walls are straight, so these are written by hand.
Verify with `python fg/verify.py --map scrapyard`.

<!-- occluder: 160,0 975,0 -->
<!-- occluder: 160,0 160,360 -->
<!-- occluder: 160,610 160,930 -->
<!-- occluder: 160,930 975,930 -->
<!-- occluder: 985,0 985,352 -->
<!-- occluder-door: 985,352 985,418 -->
<!-- occluder: 985,418 985,900 -->
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
