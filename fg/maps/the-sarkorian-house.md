# Ruined House

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

Fantasy Grounds itself stores occluders relative to the **centre** of the plate and with **y
pointing up**, so `build-fg.ps1` measures the image and emits `x - W/2`, `H/2 - y`. Author in
pixels; never write FG's coordinates here by hand.

The house is centred vertically on this plate, so a y-axis mistake mirrors the outer walls onto
themselves and hides itself. The door and the cross-wall gap are the only things that show it.

<!-- occluder: 300,300 300,1100 -->
<!-- occluder: 300,1100 1300,1100 -->
<!-- occluder: 1300,1100 1300,800 -->
<!-- occluder-door: 1300,800 1300,700 -->
<!-- occluder: 1300,700 1300,300 -->
<!-- occluder: 800,300 800,660 -->
<!-- occluder: 800,760 800,1100 -->

## Notes

- The **front door** is in the east wall, facing the road, and is the way in that does not
  involve climbing. It ships **closed**: FG draws it as a door the GM or a player can open, and
  it blocks sight until someone does. Shut, it is the reason the party can knock, listen, or come
  over the rubble instead.
- The **north wall** is a rubble spill and carries **no occluder at all**. It is difficult
  terrain, which is a GM ruling and not something FG models with occluders, and it does not block
  line of sight — so an occluder there would be wrong in both directions. Sight and movement both
  pass freely over the north edge.
- The **doorway** in the cross-wall is the one-square gap between the two wall segments. It has
  no door left in it.
- **Two ways in, which is the point.** Off the road through the front door, or round the north
  over the rubble. A single entrance funnels every approach into one plan.
- The **hearth** in the south-east corner is cold and has been cold for seventy years. There is
  something under the ash.
- The **roof** matters. A fight here is fought indoors, which is why the acolyte's
  *burning hands* is dangerous and why nobody's ranged weapon has the room it wants.
