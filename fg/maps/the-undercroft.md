# The Undercroft

<!-- id: undercroft -->
<!-- image: images/the-undercroft.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 64 -->
<!-- scale: one square - five feet -->

Under the scrap shop: a built cellar, a dug tunnel, a natural cavern the cult did not make, and a
cave in the cliff face with the ladder in it. Read right to left; that is the direction the party
travels.

**This plate needed no cropping.** 1536 x 1024 divides exactly by 64 both ways, and so does half
of each, so the grid lands true from either anchor without a pixel being moved.

## The spaces

1. **The cellar**, far right - mortared stone, plank floor, crates and barrels, a shelf rack
   against the west wall, and the foot of the stair up into the shop in its north-east corner.
   The only built room down here.
2. **The secret door** is behind that rack, in the west wall. Finding it is a search of the
   shelving; Alia or Hesk will simply say where it is.
3. **The tunnel** - dug, timber-propped, three squares wide, and lived in: bedrolls along the
   walls, a crate for a table, a burnt-out fire ring. Six initiates sleep here.
4. **The cavern** - natural, irregular, far wider than the tunnel, with fallen rock and
   stalagmites. The cult did not dig it and does not like it. Six darkmantles are on the ceiling.
5. **The cliff cave**, far left, open to the air, with a rope ladder spiked to the lip and heaped
   on the floor beside it.
   Lowered, it puts a climber on the ground outside Drezen's wall.

## Occluders

The cellar is built and straight, so its walls are written by hand. The cavity - tunnel, cavern
and cliff passage - is one traced polyline, opened at the east end so the tunnel is not sealed
off from the cellar.

<!-- occluder: 1262,305 1508,305 -->
<!-- occluder: 1508,305 1508,703 -->
<!-- occluder: 1508,703 1262,703 -->
<!-- occluder: 1262,703 1262,565 -->
<!-- occluder-door: 1262,565 1262,485 -->
<!-- occluder: 1262,485 1262,305 -->
<!-- occluder: 1105,625 1075,655 1025,595 965,595 925,645 875,625 795,655 745,615 665,675 685,715 655,745 695,825 665,855 625,845 595,895 535,925 445,915 385,865 395,815 365,785 335,795 275,715 305,655 285,625 295,575 215,555 155,595 65,605 25,565 25,475 55,445 155,495 265,475 305,415 335,445 355,415 325,325 365,285 355,245 435,155 555,155 615,215 615,245 635,225 665,255 605,325 635,355 625,405 645,435 735,465 835,405 895,435 1015,405 1085,455 1155,425 -->

To retrace after a change to the plate:

```
python fg/art/trace-occluders.py images/the-undercroft.webp --channel warm --threshold 27   --exclude 1210,240,1536,780 --cell 10 --blur 5 --min-cells 250 --epsilon 13   --open-at 1180,430,1245,650 --preview
```

**Threshold 27, not 14.** The cliff air at the left edge is bright and slightly warm - about +19
on red-minus-blue, against the floor's +38 and the rock's +2 - so a low threshold traces the sky
as floor. Raising it past 20 separates all three cleanly.

## Notes

- **The secret door ships closed**, and the initiates behind it are not expecting anyone. Opening
  it quietly is possible, and a party that manages it starts the tunnel fight on its own terms.
- **The cliff cave mouth is a closed edge.** Nobody walks out of it by accident - the drop is the
  point and the ladder is the only way down. It is heaped on the floor, not hanging, so the cliff
  face shows nothing until somebody kicks it over.
