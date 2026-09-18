# Lupenor's Market

<!-- id: lupenors_market -->
<!-- image: images/lupenors-market.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 100 -->
<!-- scale: one square - five feet -->

**Not a market square: a street that turned into a market** because people started selling in
it. Half its houses are still empty after seventy years of demon rule, and the traders have spilled
out of the rest and into the road. Carts are parked with tarps thrown over poles, rugs are laid on
the cobbles with wares on them, lean-tos lean against house fronts, and people hawk out of sacks
standing on crates that are not theirs. Nobody has a pitch. **The one rule is that a cart can get
down the middle**, so a single crooked lane is left clear, and everything else is claimed.

**Lupenor's trading house** is the one sound building, with a whole roof and a new door; the
Outfitter's Counter is in its yard behind, off the map. A **public pump** stands where the street
widens. **Ways out:** both ends of the street, half-choked with carts, and a few **alleys** between
the houses, none wider than a man.

**The plate** is a 1536 × 1024 generation, trimmed 12 px top and bottom and reflect-padded 32 px
each side to **1600 × 1000**, which makes it 16 × 10 squares at **100 px** (80 × 50 ft) with half the
width and height both whole squares. The scale was set off the objects in the art rather than
chosen: the pump trough is about six feet, the handcarts eight or nine, and the street is twenty
to twenty-five feet between house fronts.

**Walls are the house fronts, set back to fit the grid rather than traced to the pixel.** A token
can only stand in a square whose centre is about 55 px clear of any wall, so every front sits a few
pixels **behind** a grid line (y 190 on the north side, y 705 or 805 on the south) and the first row
of street squares is always usable. That puts the wall line up to 30 px into the eaves in places,
which is the right way to be wrong: a wall drawn on the street's side of a grid line throws away
the whole row of squares in front of it, including the one outside the trading house door.

**The four alleys are exactly one square wide** (x 395-505 and 1095-1205 on the north side,
495-605 and 1095-1205 on the south), centred on a grid column. The art draws them a little
narrower than that, and at their true width no token fits down them, which would make Jory's
escape route a dead end. The trading house's front door is an `occluder-door`. **The clutter is
open**: tarps, lean-tos, carts and rugs do not block sight at head height, and moving through them
is difficult terrain, which the story record says rather than the map.

The narrow slot between the ruined house and the trading house (top, about x 845) is two feet wide
and deliberately walled. Check any change with `python fg/verify.py --map lupenors_market` and
`python fg/passable.py --map lupenors_market`.

## Occluders

<!-- occluder: 0,190 395,190 395,0 -->
<!-- occluder: 505,0 505,190 980,190 -->
<!-- occluder-door: 980,190 1060,190 -->
<!-- occluder: 1060,190 1095,190 1095,0 -->
<!-- occluder: 1205,0 1205,190 1600,190 -->
<!-- occluder: 0,705 195,705 195,805 495,805 495,1000 -->
<!-- occluder: 605,1000 605,805 1095,805 1095,1000 -->
<!-- occluder: 1205,1000 1205,705 1405,705 1405,610 1600,610 -->

<!-- shortcut: book:00_c_the_market_street @ 720,470 | M1. The Market Street -->
<!-- shortcut: book:00_d_the_back_room @ 1020,160 | M2. The Back Room -->
