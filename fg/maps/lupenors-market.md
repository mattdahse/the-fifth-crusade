# Lupenor's Market

<!-- id: lupenors_market -->
<!-- image: images/lupenors-market.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 50 -->
<!-- scale: one square - five feet -->

**Not a market square: a street that turned into a market** because people started selling in
it. Half its houses are still empty after seventy years of demon rule, and the traders have spilled
out of the rest and into the road. Carts are parked with tarps thrown over poles, rugs are laid on
the cobbles with wares on them, lean-tos lean against house fronts, and people hawk out of sacks
standing on crates that are not theirs. Nobody has a pitch. **The one rule is that a cart can get
down the middle**, so a single crooked lane is left clear, and everything else is claimed.

**Lupenor's trading house** is the one sound building, with a whole roof and a new door; the
Outfitter's Counter is in its yard behind, off the map. A **public pump** stands where the street
widens. **Ways out:** both ends of the street, half-choked with carts, and a few narrow **alleys**
between the houses.

**The plate** is a 1536 × 1024 generation, trimmed 12 px top and bottom and reflect-padded 32 px
each side to **1600 × 1000**: **32 × 20 squares at 50 px, 160 × 100 ft**, with half the width and
height both whole squares. **The grid is Matt's, set at the table.** It was first shipped at 100 px,
read off the pump trough and the handcarts, and at that scale the houses along the street were ten
feet wide. At 50 px they are house-sized, and the street has room for the centipede fight and for
Jory's run.

**Walls are the painted house fronts.** At 50 px every alley is wider than a square and the first
row of street squares is clear of the fronts, so nothing has to be set back from the art to make
the grid work. The four **alley mouths** are open — two on each side, roughly x 400–495 and
1105–1200 on the north, 505–575 and 1100–1170 on the south — and the trading house's front door
is an `occluder-door`, widened from its painted 45 px to 55 so a token fits through. **The
clutter is open**: tarps, lean-tos, carts and rugs do not block sight at head height, and moving
through them is difficult terrain, which the story record says rather than the map.

The narrow slot between the ruined house and the trading house (top, about x 845) is two feet wide
and deliberately walled. Check any change with `python fg/verify.py --map lupenors_market` and
`python fg/passable.py --map lupenors_market`.

## Occluders

<!-- occluder: 0,195 400,195 400,0 -->
<!-- occluder: 495,0 495,200 880,200 880,245 995,245 -->
<!-- occluder-door: 995,245 1050,245 -->
<!-- occluder: 1050,245 1105,245 1105,0 -->
<!-- occluder: 1200,0 1200,195 1600,195 -->
<!-- occluder: 0,660 200,660 200,745 505,745 505,1000 -->
<!-- occluder: 575,1000 575,740 830,740 830,705 900,705 900,775 1100,775 1100,1000 -->
<!-- occluder: 1170,1000 1170,700 1400,700 1400,610 1600,610 -->

<!-- shortcut: book:00_c_the_market_street @ 720,470 | M1. The Market Street -->
<!-- shortcut: book:00_d_the_back_room @ 1020,160 | M2. The Back Room -->
