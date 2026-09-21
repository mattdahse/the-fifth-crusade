# The Low Road

<!-- id: low_road -->
<!-- image: images/the-low-road.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 50 -->
<!-- scale: one square - five feet -->

The slave tunnels under the South Bank, from the Dolvans' cellar in the east to the cliff ledge
in the west: sixty squares by forty, 300 feet by 200. Read it right to left, which is the way the
party travels, and the way the runaways did.

**One plate, painted in four overlapping quarters and stitched.** The floor plan is
[`../art/make-low-road.py`](../art/make-low-road.py), a seeded blockout on a 50 px grid; each
quarter was repainted from it with the order to move nothing, and
[`../art/stitch-tiles.py`](../art/stitch-tiles.py) registered the four back onto the plan (none
had drifted more than 3 px) and joined them along the cheapest seams through the overlaps. The
seams cross only rock and four straight tunnels. The one local fix is where the crawl meets the
midden, which the renders left a hand's width short.

## The spaces

- **C1 The cellar**, far right: the Dolvans' built cellar, stair up in the north-east corner, the
  stone door in its west wall.
- **C2 The lodging**: the relief detail's tunnel, bedrolls and a cold fire.
- **C3 The knot**: the slaves' junction chamber, a chalk maze on the floor, the bell-cord.
- **C4 The grain store** and **C5 the packing room**, north of the knot.
- **C12 The dressing room**, off the lodging.
- **C6 The old ways**, south: three branches, to the Tanner's ladder (east), the nest and the Well
  House shaft (south-east), and **C7 the fall** (south-west).
- **C8 The midden**, south-west, reached by the midden link from the old ways, and by **the
  crawl** from the cavern.
- **C9 The gate**: the crate barricade across the hall, one square open at its south end.
- **C10 The counting room** and **C11 the strongroom**, north of the hall; **C13 the chapel**, south.
- **C14 The cavern** and **C15 the ledge**, far left, open to the air.

## Shortcuts

<!-- shortcut: book:29_the_low_road @ 1975,470 | The Low Road -->
<!-- shortcut: book:30_the_cellar @ 2775,600 | C1. The Cellar -->
<!-- shortcut: book:31_the_lodging @ 2400,600 | C2. The Lodging -->
<!-- shortcut: book:32_the_knot @ 1975,680 | C3. The Knot -->
<!-- shortcut: book:33_the_grain_store @ 2000,180 | C4. The Grain Store -->
<!-- shortcut: book:34_the_packing_room @ 2450,180 | C5. The Packing Room -->
<!-- shortcut: book:35_the_old_ways @ 1925,1250 | C6. The Old Ways -->
<!-- shortcut: book:36_the_fall @ 1750,1750 | C7. The Fall -->
<!-- shortcut: book:37_the_midden @ 950,1475 | C8. The Midden -->
<!-- shortcut: book:38_the_gate @ 1640,600 | C9. The Gate -->
<!-- shortcut: book:39_the_counting_room @ 1175,330 | C10. The Counting Room -->
<!-- shortcut: book:40_the_strongroom @ 1275,130 | C11. The Strongroom -->
<!-- shortcut: book:41_the_dressing_room @ 2425,430 | C12. The Dressing Room -->
<!-- shortcut: book:42_the_chapel @ 1175,800 | C13. The Chapel -->
<!-- shortcut: book:43_the_cavern @ 625,500 | C14. The Cavern -->
<!-- shortcut: book:44_the_ledge @ 230,625 | C15. The Ledge -->

## Occluders

Traced from the blockout's own walkable mask (`low-road-floor.png`, written by the blockout
script) rather than from the painting, which sits within 3 px of it. Two rings: the outer wall,
and the island of rock the loop of cavern, hall, old ways, midden and crawl encloses, which
without its own ring would let a token see from the chapel to the midden through solid stone.

```
python fg/art/make-low-road.py OUT
python fg/art/trace-occluders.py OUT/low-road-floor.png --channel lum --threshold 128 --cell 10     --blur 2 --grow 2 --epsilon 10 --min-cells 50 --exclude 0,0,95,2000
```

The island is the rock inside the loop, flood-filled free of the outer rock and eroded 20 px (the
same two cells `--grow` pushes the outer wall back), then traced with `--grow 0`.

<!-- occluder: 85,535 105,515 165,495 255,495 335,535 395,525 415,405 465,355 455,245 495,165 535,125 615,95 665,95 755,125 815,185 885,385 875,465 845,495 855,515 1125,515 1125,465 1005,465 985,445 985,205 1005,185 1175,185 1185,65 1205,45 1345,45 1365,65 1365,445 1345,465 1235,465 1225,505 1775,515 1795,405 1815,385 1925,395 1945,345 1935,315 1845,325 1785,285 1775,115 1785,75 1815,45 2165,45 2215,85 2215,115 2235,135 2275,135 2285,75 2315,45 2525,35 2585,45 2625,85 2615,275 2575,315 2315,315 2285,285 2285,235 2265,215 2225,215 2215,285 2185,315 2075,315 2065,375 2115,385 2165,425 2175,515 2255,505 2235,485 2235,375 2265,345 2595,345 2615,365 2615,515 2635,505 2635,405 2655,385 2895,385 2915,405 2915,795 2895,815 2655,815 2635,795 2635,705 2575,685 2175,695 2165,785 2145,805 2035,815 2005,825 1985,855 1985,1165 2025,1175 2115,1145 2215,1135 2395,1205 2445,1205 2495,1235 2765,1185 2815,1245 2785,1305 2585,1345 2555,1365 2305,1315 2225,1265 2115,1275 2055,1305 2145,1405 2275,1485 2485,1485 2515,1515 2515,1655 2695,1785 2695,1815 2665,1845 2645,1845 2525,1755 2405,1755 2345,1775 2265,1765 2235,1725 2245,1605 2075,1505 1965,1375 1945,1385 1905,1535 1875,1585 1895,1715 1895,1895 1875,1915 1705,1925 1625,1915 1605,1895 1615,1605 1635,1585 1725,1585 1795,1485 1785,1445 1715,1495 1315,1495 1295,1525 1295,1575 1325,1635 1325,1675 1285,1735 1195,1785 1125,1785 1085,1755 1045,1775 925,1785 795,1755 765,1735 725,1755 665,1755 585,1695 565,1605 605,1545 605,1375 555,1205 555,875 435,715 355,715 295,755 105,745 85,725 -->
<!-- occluder-open: 85,725 85,535 -->
<!-- occluder: 1445,695 1755,695 1775,725 1785,815 1845,835 1855,1205 1665,1345 1285,1345 1275,1305 1175,1205 1085,1185 1045,1155 905,1155 865,1175 815,1175 755,1145 665,1155 665,935 745,925 825,885 875,825 895,705 975,705 965,905 995,935 1215,935 1355,925 1375,905 1385,705 1445,695 -->

The wall between the strongroom and the counting room is shared in the mask, so it is written by
hand, with the strongroom door locked (the Keeper has the key, somewhere on a ring of fourteen).

<!-- occluder: 1180,200 1245,200 -->
<!-- occluder-door-locked: 1245,200 1305,200 -->
<!-- occluder: 1305,200 1365,200 -->

The counting room door, and the stone door into the Dolvans' cellar, locked as Matt left it:

<!-- occluder-door: 1125,478 1225,478 -->
<!-- occluder-door-locked: 2640,500 2640,712 -->

The gate: crates stacked across the hall, climbable, blocking sight, with the one-square gap at
the south end that the Horn stands in.

<!-- occluder-open: 1690,495 1690,622 -->

## Notes

- **The cave mouth is an open edge**, crossable and occluding, as on the old undercroft plate: the
  ladder goes over it and nobody walks off it by accident.
- **The Tanner's ladder** (C6, east end) and **the Well House shaft** (south-east) go up to the
  street. They are exits, not walls; neither is drawn.
- **The midden pit** is floor, and difficult terrain. The Bishop lives in it.
