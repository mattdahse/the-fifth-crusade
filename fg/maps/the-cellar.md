# The Cellar

<!-- id: cellar -->
<!-- image: images/the-cellar.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 60 -->
<!-- scale: one square — five feet -->

Under the east room of [the Sarkorian House](the-sarkorian-house.md), reached by the hatch in
its floor. A dry stone room the house was built on and the house has outlived, nine squares by
eleven, with a stair up in the south-east corner that comes out through that hatch.

Whoever kept this place kept it well. The shelving along the north wall has come down, but it
came down slowly, and the barrels are still where they fell.

The west wall is not sound. Something has come through it from the other side, and the fallen
masonry heaped against that wall is what is left of the door that used to be there — and what
now hides it.

## The plate

Painted rather than drawn, and the geometry measured off it afterwards. This is the reverse of
the order used for the Sarkorian House, and deliberate: a bored tunnel and a nest chamber are
organic shapes, and a script that draws them in polygons produces walls that self-intersect and
read as machine-made. The occluders below were traced out of the finished plate by
[`../art/trace-occluders.py`](../art/trace-occluders.py), so they follow the art exactly rather
than approximately.

The plate is cropped and extended so the cellar's inside corner lands on a round multiple of the
60-pixel square, and so half the plate's width and height are multiples too. That makes the grid
line up on the walls whichever corner Fantasy Grounds anchors it to.

## Shortcuts

Pins to each space's page in the book. Top-left image pixels; the build converts to FG's own
(centre origin, y up). The bore-hole sits at the north end of the nest chamber, which is where
the shaft up into the sealed room actually is.

<!-- shortcut: book:80_the_cellar @ 1180,400 | F1. The Cellar -->
<!-- shortcut: book:81_the_tunnel @ 790,460 | F2. The Tunnel -->
<!-- shortcut: book:82_the_nest @ 390,620 | F3. The Nest -->
<!-- shortcut: book:83_the_bore_hole @ 170,220 | F4. The Bore-Hole -->


## Occluders

Line-of-sight walls, in **top-left image pixel coordinates**. The build converts them to
Fantasy Grounds' own convention — origin at the image centre, y pointing up — on the way out.

The cellar is worked stone and its walls are written by hand, because they are straight and
their coordinates are exact. The cavity is one traced polyline, open at the doorway so the
tunnel is not sealed off from the room.

<!-- occluder: 900,120 1440,120 1440,785 900,785 900,515 -->
<!-- occluder: 900,415 900,120 -->
<!-- occluder-door: 900,415 900,515 -->
<!-- occluder: 685,525 625,535 585,575 575,665 525,715 575,775 575,825 495,885 435,865 375,795 235,805 165,925 95,915 45,875 65,855 35,825 105,685 5,585 5,385 115,255 85,205 155,115 225,185 445,205 575,315 585,365 685,335 805,375 845,355 875,385 -->

To retrace after a change to the plate:

```
python fg/art/trace-occluders.py images/the-cellar.webp --channel warm --threshold 16 \
  --exclude 850,60,1560,890 --cell 10 --blur 5 --grow 3 --min-cells 200 --epsilon 15 \
  --open-at 820,395,910,545 --preview
```

`--channel warm` is the setting that matters. It thresholds red-minus-blue rather than
brightness, because dug earth is warm and cut rock is neutral while the two overlap badly in
brightness — a shadowed stretch of this tunnel is *darker* than the rock around it, so no
brightness threshold can take in the whole tunnel without also taking in the rock. On the warm
channel the floor sits at +25 to +40 and the rock at 0 to +6, which is not a close call.

`--exclude` keeps the cellar's own stonework out of the trace; without it the bright walls read
as open floor and get traced as a second cavern. `--open-at` breaks the ring at the door, so the
tunnel is not sealed off from the room.

## Notes

- The **door in the west wall** ships closed and is buried behind the rubble spill. Finding it is
  a Perception check against the rubble, not a search of the whole room; opening it means moving
  stone, which is loud, and the things on the other side are listening.
- The **tunnel** is bored, not built — no tool marks, and it is exactly as wide as the thing that
  made it. It does not run straight, so line of sight down it is short and a fight in it happens
  at whatever range the bend allows.
- The **nest chamber** at the west end is the point of the map. Egg clutches are heaped against
  its walls, and there are two side burrows that go nowhere yet.
- **The stair is the only way out that the party knows about.** Anything that wants to cut them
  off goes for the south-east corner.
