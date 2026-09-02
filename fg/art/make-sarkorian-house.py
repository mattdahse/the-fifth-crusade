"""Draw the blockout battlemap for The Sarkorian House.

    python fg/art/make-sarkorian-house.py

This is a plain, readable floor plan rather than generated art. It exists so the
geometry, the grid and the line-of-sight occluders can be settled and tested at the
table first; painted art can replace the plate later without moving a single wall,
because the occluders in fg/maps/the-sarkorian-house.md are written against these
exact coordinates.

Scale: 100 px to a five-foot square, which is what the map record's gridsize says.
The house is ten squares by eight. The plate carries NO text of its own - no room
numbers, no labels, no north arrow, and no grid; FG draws the grid itself.

Legibility is the whole job. Three values, held far apart on purpose:
walls read lightest, the flagstone floor sits clearly above the ground outside,
and the ground outside is the darkest thing on the plate. A player should be able
to tell inside from outside at a glance across a shared screen.
"""
import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

SQ = 100                     # pixels per 5 ft square
W, H = 1600, 1400
# House footprint: 10 squares by 8, aligned to the grid so FG's squares line up.
L, T, R, B = 300, 300, 1300, 1100
XWALL = 800                  # the interior cross-wall
DOOR_T, DOOR_B = 660, 760    # its doorway, one square
# The front door, in the east wall, facing the road. The house has to be enterable
# without climbing the collapsed north end, or the rubble is the only way in and
# every approach funnels through it.
EDOOR_T, EDOOR_B = 700, 800
TH = 24                      # wall half-thickness; reads as masonry, not a line

random.seed(4713)            # deterministic: reruns produce the same plate

GROUND = (46, 42, 36)        # dry valley dirt, the darkest value on the plate
ROAD = (70, 63, 53)          # the western road, past the east wall
FLOOR = (122, 112, 93)       # flagstone
FLOOR2 = (110, 101, 84)
STONE = (156, 147, 128)      # walls: the lightest value on the plate
STONE_D = (78, 72, 62)
RUBBLE = (132, 122, 104)
HEARTH = (36, 32, 28)
SCRUB = (64, 62, 44)

img = Image.new("RGB", (W, H), GROUND)
d = ImageDraw.Draw(img)


# --- ground outside the house: dry, broken valley dirt
for _ in range(34000):
    x, y = random.randrange(W), random.randrange(H)
    v = random.randint(-11, 11)
    d.point((x, y), fill=(GROUND[0] + v, GROUND[1] + v, GROUND[2] + v))

# --- the valley falls away sharply to the west: the ground darkens to the lip
falloff = Image.new("L", (W, H), 0)
fd = ImageDraw.Draw(falloff)
for x in range(0, L - TH):
    # 0 at the house, up to a deep shadow at the western edge of the plate
    fd.line([(x, 0), (x, H)], fill=int(150 * (1 - x / float(L - TH)) ** 1.6))
img = Image.composite(Image.new("RGB", (W, H), (12, 11, 10)), img,
                      falloff.filter(ImageFilter.GaussianBlur(18)))
d = ImageDraw.Draw(img)
# the lip itself - a broken edge of exposed rock
lip = []
for y in range(-20, H + 20, 26):
    lip.append((70 + random.randint(-26, 26), y))
d.line(lip, fill=(96, 90, 78), width=7, joint="curve")

# --- the road runs past the east wall: a dust strip with two cart ruts
d.rectangle([R + TH + 40, -10, R + TH + 250, H + 10], fill=ROAD)
for _ in range(9000):
    x = random.randint(R + TH + 40, R + TH + 250)
    y = random.randrange(H)
    v = random.randint(-13, 13)
    d.point((x, y), fill=(ROAD[0] + v, ROAD[1] + v, ROAD[2] + v))
for rut in (R + TH + 100, R + TH + 190):
    pts = [(rut + random.randint(-6, 6), y) for y in range(-20, H + 20, 40)]
    d.line(pts, fill=(52, 47, 40), width=9, joint="curve")

# --- scrub: dead tufts, thicker away from the trodden ground
for _ in range(240):
    x, y = random.randrange(W), random.randrange(H)
    if L - 90 < x < R + 90 and T - 90 < y < B + 90:
        continue
    for _ in range(random.randint(4, 9)):
        a = random.uniform(0, 6.28)
        ln = random.randint(6, 17)
        d.line([x, y, x + ln * random.uniform(-1, 1), y - ln],
               fill=(SCRUB[0] + random.randint(-12, 12),
                     SCRUB[1] + random.randint(-12, 12),
                     SCRUB[2] + random.randint(-12, 12)), width=2)

# --- flagstone floor inside, laid as irregular slabs
d.rectangle([L, T, R, B], fill=FLOOR)
y = T
while y < B:
    x = L + random.randint(-36, 36)
    row_h = SQ + random.randint(-12, 12)
    while x < R:
        w = SQ + random.randint(-24, 36)
        x0, y0 = max(x, L), y
        x1, y1 = min(x + w - 6, R), min(y + row_h - 6, B)
        if x1 > x0 and y1 > y0:
            v = random.randint(-7, 7)
            base = FLOOR if random.random() < 0.55 else FLOOR2
            d.rectangle([x0, y0, x1, y1],
                        fill=(base[0] + v, base[1] + v, base[2] + v))
        x += w
    y += row_h

# --- the hearth in the south-east corner, cold for seventy years
hx, hy = R - 220, B - 180
d.rectangle([hx, hy, hx + 160, hy + 120], fill=STONE_D)
d.rectangle([hx + 24, hy + 24, hx + 136, hy + 104], fill=HEARTH)
for _ in range(700):                       # seventy years of ash, spilling out
    a = random.gauss(0, 1)
    x = int(hx + 80 + a * 90)
    yy = int(hy + 60 + random.gauss(0, 70))
    if L < x < R and T < yy < B:
        g = random.randint(96, 132)
        d.point((x, yy), fill=(g, g - 6, g - 14))

# --- fallen slates and a broken beam, indoors, near the collapsed north end
for _ in range(110):
    x = random.randint(L + 20, R - 20)
    yy = int(random.gauss(T + 90, 100))
    if not (T < yy < B):
        continue
    w2, h2 = random.randint(16, 44), random.randint(12, 28)
    g = random.randint(86, 112)          # slate: darker than the floor, not a hole
    a = random.uniform(-0.35, 0.35)
    cx, cy = x + w2 / 2.0, yy + h2 / 2.0
    pts = []
    for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        px, py = dx * w2 / 2.0, dy * h2 / 2.0
        pts.append((cx + px * math.cos(a) - py * math.sin(a),
                    cy + px * math.sin(a) + py * math.cos(a)))
    d.polygon(pts, fill=(g, g - 4, g - 11), outline=(g - 26, g - 29, g - 34))
d.line([L + 210, T + 40, L + 470, T + 250], fill=(58, 51, 42), width=26)
d.line([L + 210, T + 40, L + 470, T + 250], fill=(88, 79, 64), width=11)

# --- most of the roof is still on: everything indoors sits a little darker,
#     deepest away from the open north end where the only real light gets in.
roof = Image.new("L", (W, H), 0)
rd = ImageDraw.Draw(roof)
for y in range(T, B + TH + 1):
    rd.line([(L - TH, y), (R + TH, y)],
            fill=int(30 + 70 * min(1.0, (y - T) / float(B - T))))
img = Image.composite(Image.new("RGB", (W, H), (0, 0, 0)), img,
                      roof.filter(ImageFilter.GaussianBlur(6)))
d = ImageDraw.Draw(img)


# --- walls. Drawn last and left bright, so they read as the plan's structure.
def wall_rect(x0, y0, x1, y1):
    return [x0 - TH, y0 - TH, x1 + TH, y1 + TH]


WALLS = [
    wall_rect(L, T, L, B),              # west
    wall_rect(L, B, R, B),              # south
    wall_rect(R, T, R, EDOOR_T),        # east, north of the door
    wall_rect(R, EDOOR_B, R, B),        # east, south of the door
    wall_rect(XWALL, T, XWALL, DOOR_T),  # cross-wall, north of the door
    wall_rect(XWALL, DOOR_B, XWALL, B),  # cross-wall, south of the door
]

# the walls throw a shadow into the room, which is what gives them height
shadow = Image.new("L", (W, H), 0)
sd = ImageDraw.Draw(shadow)
for r in WALLS:
    sd.rectangle([r[0] + 10, r[1] + 18, r[2] + 10, r[3] + 18], fill=120)
img = Image.composite(Image.new("RGB", (W, H), (0, 0, 0)), img,
                      shadow.filter(ImageFilter.GaussianBlur(14)))
d = ImageDraw.Draw(img)

for r in WALLS:
    d.rectangle(r, fill=STONE)
    # masonry courses: rough blocks, seams a shade darker
    if r[2] - r[0] > r[3] - r[1]:        # a horizontal run
        x = r[0]
        while x < r[2]:
            x += random.randint(50, 110)
            d.line([x, r[1] + 3, x, r[3] - 3], fill=STONE_D, width=3)
    else:                                # a vertical run
        y = r[1]
        while y < r[3]:
            y += random.randint(50, 110)
            d.line([r[0] + 3, y, r[2] - 3, y], fill=STONE_D, width=3)
    for _ in range(int((r[2] - r[0] + r[3] - r[1]) / 6)):
        x = random.randint(r[0], r[2])
        y = random.randint(r[1], r[3])
        v = random.randint(-16, 16)
        rr = random.randint(2, 6)
        d.ellipse([x - rr, y - rr, x + rr, y + rr],
                  fill=(STONE[0] + v, STONE[1] + v, STONE[2] + v))
    d.rectangle(r, outline=STONE_D, width=4)

# --- the front door: a worn stone threshold, and the door itself long since off its
#     hinges and lying just inside. Drawn after the walls so it sits in the gap.
d.rectangle([R - TH, EDOOR_T, R + TH, EDOOR_B], fill=(96, 89, 76))
for _ in range(260):
    x = random.randint(R - TH, R + TH)
    y = random.randint(EDOOR_T, EDOOR_B)
    v = random.randint(-14, 14)
    d.point((x, y), fill=(96 + v, 89 + v, 76 + v))
d.line([R - TH, EDOOR_T, R + TH, EDOOR_T], fill=STONE_D, width=5)
d.line([R - TH, EDOOR_B, R + TH, EDOOR_B], fill=STONE_D, width=5)
door = [(R - 150, EDOOR_T + 8), (R - 34, EDOOR_T + 30),
        (R - 48, EDOOR_B + 26), (R - 164, EDOOR_B + 4)]
d.polygon(door, fill=(62, 52, 41), outline=(41, 34, 27))
for i in range(3):                       # planks, so it reads as a door
    t = 0.25 + i * 0.25
    d.line([(door[0][0] + (door[3][0] - door[0][0]) * t,
             door[0][1] + (door[3][1] - door[0][1]) * t),
            (door[1][0] + (door[2][0] - door[1][0]) * t,
             door[1][1] + (door[2][1] - door[1][1]) * t)],
           fill=(48, 40, 32), width=4)

# --- the north wall came down long ago: a climbable rubble spill, not a barrier.
#     Broken masonry, so angular blocks rather than boulders - big ones laid first
#     and the chippings scattered over them, which is how a fallen wall sits.
def block(cx, cy, r, shade):
    """One piece of broken masonry: an irregular polygon with a lit top edge."""
    n = random.randint(4, 6)
    a0 = random.uniform(0, 6.28)
    pts = []
    for i in range(n):
        a = a0 + 6.283 * i / n + random.uniform(-0.22, 0.22)
        rr = r * random.uniform(0.66, 1.0)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a) * 0.82))
    d.polygon(pts, fill=shade,
              outline=(shade[0] - 30, shade[1] - 29, shade[2] - 26))
    # a chip of light on the upper face, so the pile reads as having depth
    d.polygon([(px, py - r * 0.22) for px, py in pts[:3]],
              fill=(min(255, shade[0] + 22), min(255, shade[1] + 21),
                    min(255, shade[2] + 19)))


for r_lo, r_hi, count, spread in ((22, 38, 130, 30), (11, 22, 620, 36),
                                  (4, 11, 1700, 42)):
    for _ in range(count):
        cx = random.randint(L - 55, R + 55)
        cy = random.gauss(T, spread)
        v = random.randint(-24, 24)
        block(cx, cy, random.randint(r_lo, r_hi),
              (RUBBLE[0] + v, RUBBLE[1] + v, RUBBLE[2] + v))

img = img.filter(ImageFilter.SMOOTH)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "images",
                   "the-sarkorian-house.jpg")
os.makedirs(os.path.dirname(out), exist_ok=True)
img.save(out, quality=92)
print("wrote", out, img.size)
