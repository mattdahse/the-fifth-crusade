# The Undercroft

<!-- id: undercroft -->
<!-- image: images/the-undercroft.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 64 -->
<!-- scale: one square - five feet -->

Under the scrap shop: a built cellar, a dug tunnel, a natural cavern the cult did not make, and a
cave in the cliff face with a rope in it. Read right to left; that is the direction the party
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
5. **The cliff cave**, far left, open to the air, with a coil of rope beside an iron spike.
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
<!-- occluder: 1125,595 1075,575 1075,625 1025,565 955,565 865,605 825,605 815,575 785,565 715,615 685,605 675,635 655,615 635,675 655,715 615,735 655,775 635,795 655,815 615,815 585,845 595,865 575,845 545,855 535,895 515,875 465,895 415,865 425,805 365,755 335,765 305,715 325,685 355,695 315,625 335,605 315,535 255,545 215,525 155,565 55,565 55,475 65,495 85,485 155,525 345,485 385,415 355,325 375,315 385,385 415,365 385,245 415,245 435,185 485,185 505,205 555,185 585,215 585,245 555,265 575,295 635,255 625,285 575,305 605,355 595,445 635,485 655,455 715,495 775,465 845,485 865,465 835,435 865,435 875,475 915,455 1005,495 1055,465 1085,485 1175,485 -->

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
  point and the rope is the only way down.
