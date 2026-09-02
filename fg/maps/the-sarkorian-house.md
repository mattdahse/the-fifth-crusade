# The Sarkorian House

<!-- id: sarkorian_house -->
<!-- image: images/the-sarkorian-house.jpg -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 100 -->
<!-- scale: one square — five feet -->

A stone-and-wattle longhouse under a slate roof laid over beams, built to last by people who
did not outlast it. Three walls stand. The fourth — the north — came down long ago and its
rubble makes a low, climbable spill into the main room. Most of the roof is still on, which
is the whole reason the place is worth having.

The valley falls away sharply to the west. The road runs past the east wall.

## The plate

Drawn by [`../art/make-sarkorian-house.py`](../art/make-sarkorian-house.py) rather than
generated — a readable floor plan at **100 px to a five-foot square**, ten squares by eight.
Settling the geometry in code first means painted art can replace the plate later without
moving a single wall, because the occluders below are written against these coordinates.

## Occluders

Line-of-sight walls, written in **top-left image pixel coordinates** — the same coordinates the
blockout script draws in, so a wall can be read straight off `make-sarkorian-house.py`.

Fantasy Grounds itself stores occluders relative to the **centre** of the plate, so `build-fg.ps1`
measures the image and subtracts half its width and height on the way out. Author in pixels;
never write FG's centred coordinates here by hand.

<!-- occluder: 300,300 300,1100 -->
<!-- occluder: 300,1100 1300,1100 -->
<!-- occluder: 1300,1100 1300,300 -->
<!-- occluder: 800,300 800,660 -->
<!-- occluder: 800,760 800,1100 -->
<!-- occluder-open: 300,300 1300,300 -->

## Notes

- The **north wall** is a rubble spill, not a barrier: difficult terrain, and it does not block
  line of sight. It is the last occluder above — the one drawn as passable terrain.
- The **doorway** in the cross-wall is the one-square gap between the two wall segments, and
  it is the only way between the two rooms that does not involve the rubble.
- The **hearth** in the south-east corner is cold and has been cold for seventy years. There is
  something under the ash.
- The **roof** matters. A fight here is fought indoors, which is why the acolyte's
  *burning hands* is dangerous and why nobody's ranged weapon has the room it wants.
