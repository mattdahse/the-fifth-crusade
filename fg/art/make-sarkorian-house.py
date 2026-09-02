"""Draw the blockout battlemap for The Sarkorian House.

    python fg/art/make-sarkorian-house.py

This is a plain, readable floor plan rather than generated art. It exists so the
geometry, the grid and the line-of-sight occluders can be settled and tested at the
table first; painted art can replace the plate later without moving a single wall,
because the occluders in fg/maps/the-sarkorian-house.md are written against these
exact coordinates.

Scale: 50 px to a five-foot square, which is what the map record's gridsize says.
The plate carries NO text of its own - no room numbers, no labels, no north arrow.
"""
import os
import random
from PIL import Image, ImageDraw, ImageFilter

SQ = 50                      # pixels per 5 ft square
W, H = 800, 700
# House footprint: 10 squares by 8, aligned to the grid so FG's squares line up.
L, T, R, B = 150, 150, 650, 550
XWALL = 400                  # the interior cross-wall
DOOR_T, DOOR_B = 330, 380    # its doorway, one square

random.seed(4713)            # deterministic: reruns produce the same plate

GROUND = (58, 54, 47)
FLOOR = (96, 88, 74)
FLOOR2 = (86, 79, 66)
STONE = (128, 120, 104)
STONE_D = (74, 69, 60)
RUBBLE = (110, 101, 86)
HEARTH = (48, 43, 38)

img = Image.new("RGB", (W, H), GROUND)
d = ImageDraw.Draw(img)

# --- ground outside the house: dry, broken valley dirt
for _ in range(9000):
    x, y = random.randrange(W), random.randrange(H)
    v = random.randint(-14, 14)
    d.point((x, y), fill=(GROUND[0] + v, GROUND[1] + v, GROUND[2] + v))

# --- flagstone floor inside, laid as irregular slabs
d.rectangle([L, T, R, B], fill=FLOOR)
y = T
while y < B:
    x = L + random.randint(-18, 18)
    row_h = SQ + random.randint(-6, 6)
    while x < R:
        w = SQ + random.randint(-12, 18)
        d.rectangle([max(x, L), y, min(x + w - 3, R), min(y + row_h - 3, B)],
                    fill=FLOOR if random.random() < 0.55 else FLOOR2)
        x += w
    y += row_h

# --- walls. Thickness reads as masonry rather than a drawn line.
TH = 12


def wall(x0, y0, x1, y1):
    d.rectangle([x0 - TH, y0 - TH, x1 + TH, y1 + TH], fill=STONE)
    d.rectangle([x0 - TH + 4, y0 - TH + 4, x1 + TH - 4, y1 + TH - 4], outline=STONE_D, width=2)


wall(L, T, L, B)          # west
wall(L, B, R, B)          # south
wall(R, T, R, B)          # east
wall(XWALL, T, XWALL, DOOR_T)   # cross-wall, north of the door
wall(XWALL, DOOR_B, XWALL, B)   # cross-wall, south of the door

# --- the north wall came down long ago: a climbable rubble spill, not a barrier.
for _ in range(1400):
    x = random.randint(L - 20, R + 20)
    y = int(random.gauss(T, 16))
    r = random.randint(2, 9)
    v = random.randint(-22, 22)
    d.ellipse([x - r, y - r, x + r, y + r],
              fill=(RUBBLE[0] + v, RUBBLE[1] + v, RUBBLE[2] + v))

# --- hearth in the south-east corner, cold for seventy years
hx, hy = R - 110, B - 90
d.rectangle([hx, hy, hx + 80, hy + 60], fill=STONE_D)
d.rectangle([hx + 12, hy + 12, hx + 68, hy + 52], fill=HEARTH)

# --- most of the roof is still on: everything indoors sits a little darker
shade = Image.new("RGB", (W, H), (255, 255, 255))
ImageDraw.Draw(shade).rectangle([L - TH, T, R + TH, B + TH], fill=(150, 150, 165))
img = Image.blend(img, Image.blend(img, shade, 0.0), 0.0)
dark = img.copy()
ImageDraw.Draw(dark).rectangle([L - TH, T, R + TH, B + TH], fill=(0, 0, 0))
mask = Image.new("L", (W, H), 0)
ImageDraw.Draw(mask).rectangle([L - TH, T, R + TH, B + TH], fill=60)
img = Image.composite(Image.blend(img, dark, 1.0), img, mask.point(lambda p: p))
img = img.filter(ImageFilter.SMOOTH)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "images",
                   "the-sarkorian-house.jpg")
os.makedirs(os.path.dirname(out), exist_ok=True)
img.save(out, quality=88)
print("wrote", out, img.size)
