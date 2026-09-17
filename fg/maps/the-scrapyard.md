# The Scrapyard

<!-- id: scrapyard -->
<!-- image: images/the-scrapyard.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 80 -->
<!-- scale: one square — five feet -->

Hesk Dolvan's yard and house on Cinder Row. **Cinder Row itself** runs down the west side,
eight squares of cobbles - room to stage a party outside the gate. The yard fills the middle;
the house is the block on the east side, drawn as a cutaway so the rooms are visible.

The plate was generated with only two squares of street, and widened by
`fg/art/edits/widen-street.py`, which quilts the plate's own cobbles into the new space. That
moved everything 480px east, so any coordinate written before it is 480 short.

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

<!-- shortcut: book:10_the_yard @ 1060,450 | A1. The Yard -->
<!-- shortcut: book:11_the_kennel @ 730,800 | A2. The Kennel -->
<!-- shortcut: book:22_the_kitchen @ 1560,135 | B3. The Kitchen -->
<!-- shortcut: book:23_the_childrens_room @ 1800,135 | B4. The Children's Room -->
<!-- shortcut: book:21_the_living_room @ 1700,400 | B2. The Living Room -->
<!-- shortcut: book:20_the_shop @ 1700,720 | B1. The Shop -->

## Lights

Firelight in the house - the hearth, the stove, and lamps in each room. Top-left pixels, same
space as the occluders. First placed by hand in FG, then written back here so they survive a
module-cache reset.

<!-- light: 1521,668 -->
<!-- light: 1887,677 -->
<!-- light: 1874,364 -->
<!-- light: 1529,499 -->
<!-- light: 1692,63 -->
<!-- light: 1509,115 -->
<!-- light: 1631,112 -->

## Occluders

Top-left image pixels. The fence and the house walls are straight, so these are written by hand.
Verify with `python fg/verify.py --map scrapyard`.

<!-- occluder: 640,0 1455,0 -->
<!-- occluder: 640,0 640,360 -->
<!-- occluder: 640,610 640,930 -->
<!-- occluder: 640,930 1455,930 -->
<!-- occluder: 1465,0 1465,352 -->
<!-- occluder-door: 1465,352 1465,418 -->
<!-- occluder: 1465,418 1465,900 -->
<!-- occluder: 1465,15 1942,15 -->
<!-- occluder: 1942,15 1942,900 -->
<!-- occluder: 1465,900 1645,900 -->
<!-- occluder-door: 1645,900 1735,900 -->
<!-- occluder: 1735,900 1942,900 -->
<!-- occluder: 1465,255 1640,255 -->
<!-- occluder-door: 1640,255 1695,255 -->
<!-- occluder: 1695,255 1942,255 -->
<!-- occluder: 1465,540 1645,540 -->
<!-- occluder-door: 1645,540 1715,540 -->
<!-- occluder: 1715,540 1942,540 -->
<!-- occluder: 1670,15 1670,255 -->

**The gate is standing open** and carries no occluder — the gap in the west fence between
y 360 and y 610 is the way in.

**The scrap heaps are not occluders.** They are cover and they break sight, but a heap is not a
wall and FG's line-of-sight layer would make them absolute. Rule them as cover at the table; if
you want them hard, the plate is there to trace.
