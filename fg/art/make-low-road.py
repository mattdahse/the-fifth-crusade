"""Blockout for The Low Road: the slave tunnels under the South Bank.

Draws the whole dungeon as a plain painted floor plan on a 50 px grid (60 x 40 squares,
3000 x 2000 px). It is two things at once: the FIXED floor plan every ChatGPT repaint is
told not to move, and a playable plate if the repaint is not ready in time.

    python fg/art/make-low-road.py OUTDIR [--grid]

Writes OUTDIR/low-road-blockout.png (and -grid.png with --grid, for checking), the walkable
mask low-road-floor.png that the occluders are traced from, plus the
reference crops the renders are sent with: -master.png (whole plan at 1536 x 1024) and
-tile-{tl,tr,bl,br}.png (1600 x 1067 windows, overlapping 200 px across and 134 px down,
each scaled to 1536 x 1024).

Seams. The tiles overlap on x 1400-1600 (squares 28-32) and y 933-1067 (squares 18.7-21.3).
Nothing crosses those bands except four straight tunnels: the hall (y 10.5-13.5), the midden
link (y 27.5-29.5), the crawl (x 11.4-12.6) and the old ways (x 37.5-39.5). Keep it that way
when moving anything, or a stitch will cut a room in half.

All geometry is in squares, x west to east, y north to south. The cliff is the west edge.
"""
import argparse
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 50                 # px per five-foot square
W, H = 60, 40          # squares
PW, PH = W * S, H * S  # 3000 x 2000
SEED = 4713

# --------------------------------------------------------------------------- palette
ROCK = (22, 20, 18)
AIR = (196, 200, 202)
EARTH = (118, 96, 70)      # dug by hand
CAVE = (104, 100, 92)      # natural stone
FLAG = (146, 138, 124)     # the Dolvans' cellar
PLANK = (112, 86, 56)      # the Keeper's floor
MIDDEN = (66, 60, 40)
PIT = (30, 28, 20)
BLOCK = (128, 124, 116)    # mortared block walls
TIMBER = (70, 50, 32)
SACK = (176, 150, 104)
RUBBLE = (92, 88, 82)
CLOTH_R, CLOTH_B, CLOTH_G = (120, 52, 40), (64, 76, 96), (84, 90, 60)

# --------------------------------------------------------------------------- geometry
# Built rooms: crisp, walled in block.
BUILT = {
    'cellar':     ((53, 8, 58, 16), FLAG),
    'counting':   ((20, 4, 27, 9), PLANK),
    'strongroom': ((24, 1.2, 27, 4), PLANK),
}
# Dug rooms: roughened rectangles.
DUG = {
    'knot':     ((36, 8, 43, 16), EARTH),
    'grain':    ((36, 1.2, 44, 6), EARTH),
    'packing':  ((46, 1.2, 52, 6), EARTH),
    'dressing': ((45, 7.2, 52, 10), EARTH),
    'chapel':   ((20, 14, 27, 18), EARTH),
    'nest':     ((45, 30, 50, 35), EARTH),
    'fall':     ((32.5, 32, 37.5, 38), EARTH),
}
# Corridors: (points, width in squares, material).
CORRIDORS = [
    ([(43, 12), (53, 12)], 3, EARTH),                       # C2 the lodging
    ([(16.5, 12), (36, 12)], 3, EARTH),                     # the hall, through the gate
    ([(40, 5.5), (40, 8.5)], 2, EARTH),                     # knot to grain store
    ([(43.5, 3.5), (46.5, 3.5)], 1.2, EARTH),               # grain store to packing room
    ([(48.5, 9.5), (48.5, 11)], 1.2, EARTH),                # lodging to dressing room
    ([(23.5, 8.5), (23.5, 11)], 1.2, PLANK),                # hall to counting room
    ([(25.5, 3.5), (25.5, 4.5)], 1.2, PLANK),               # counting room to strongroom
    ([(23.5, 13), (23.5, 14.5)], 1.2, EARTH),               # hall to chapel
    ([(6.5, 12.5), (10, 12.5)], 3, CAVE),                   # cavern to ledge
    ([(38.5, 15.5), (38.5, 25)], 2, EARTH),                 # the old ways, south
    ([(38.5, 25), (44, 24), (50, 26), (55, 25)], 2, EARTH), # to the Tanner's
    ([(38.5, 25), (42, 29), (45.5, 31)], 2, EARTH),         # to the nest
    ([(49.5, 33.5), (53, 36)], 1.2, EARTH),                 # the squeeze to the well
    ([(38.5, 25), (37, 30), (35.5, 32.5)], 2, EARTH),       # to the fall
    ([(38.5, 25), (34, 28.5), (25.5, 28.5)], 2, EARTH),     # the midden link
    ([(12, 17.5), (12, 23.6), (12.4, 25.0)], 1.2, CAVE),      # the crawl, into the midden
]
# Natural spaces as unions of ellipses: (cx, cy, rx, ry).
CAVERN = [(13, 5.5, 3.6, 3.3), (12.4, 10, 4.2, 3.8), (13.6, 14.6, 3.6, 3.4),
          (15.2, 8, 2.2, 2.6), (10.6, 13, 1.8, 2.2)]
LEDGE = [(4.6, 12.5, 2.8, 2.4), (3.2, 12.5, 1.6, 1.6)]
MIDDEN_BLOB = [(19, 29.5, 6.8, 5.8), (14.5, 26, 2.6, 2.4), (23.5, 33, 2.6, 2.4),
               (13.8, 32.5, 2.2, 2.4)]
PIT_ELLIPSE = (19.2, 30.2, 3.8, 2.8)
WELL = (53.6, 36.6, 1.2)   # cx, cy, r

AIR_EDGE = 2.0             # squares; the cliff face is roughly here


def px(v):
    return int(round(v * S))


# --------------------------------------------------------------------------- noise
def smooth_noise(rng, cell, amp=1.0):
    """A soft greyscale noise field the size of the plate, 0..255 centred on 128."""
    w, h = max(2, PW // cell), max(2, PH // cell)
    small = Image.new('L', (w, h))
    small.putdata([int(128 + (rng.random() - 0.5) * 255 * amp) for _ in range(w * h)])
    return small.resize((PW, PH), Image.BICUBIC).filter(ImageFilter.GaussianBlur(cell / 3))


def textured(base, rng, strength, cell):
    """Fill a plate-sized RGB image with base colour modulated by noise."""
    n = np.asarray(smooth_noise(rng, cell), dtype=np.float32) - 128
    fine = np.asarray(smooth_noise(rng, 6), dtype=np.float32) - 128
    d = (n * strength + fine * strength * 0.5) / 128.0
    arr = np.array(base, dtype=np.float32)[None, None, :] * (1 + d[..., None])
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), 'RGB')


# --------------------------------------------------------------------------- masks
def draw_corridor(d, pts, width, fill):
    wpx = px(width)
    ps = [(px(x), px(y)) for x, y in pts]
    d.line(ps, fill=fill, width=wpx)
    r = wpx // 2
    for x, y in ps:
        d.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def draw_ellipse(d, e, fill, grow=0.0):
    cx, cy, rx, ry = e
    d.ellipse((px(cx - rx - grow), px(cy - ry - grow), px(cx + rx + grow), px(cy + ry + grow)),
              fill=fill)


def roughen(mask, rng, amount=22, cell=40):
    """Blur the mask, perturb it with noise and re-threshold: organic walls that stay on plan."""
    b = np.asarray(mask.filter(ImageFilter.GaussianBlur(amount * 0.45)), dtype=np.float32)
    n = np.asarray(smooth_noise(rng, cell), dtype=np.float32) - 128
    v = b + n * (amount / 40.0)
    return Image.fromarray(np.where(v > 128, 255, 0).astype(np.uint8), 'L')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('outdir')
    ap.add_argument('--grid', action='store_true')
    a = ap.parse_args()
    os.makedirs(a.outdir, exist_ok=True)
    rng = random.Random(SEED)

    # 1. organic floor mask (dug + natural), roughened; built rooms added crisp afterwards
    organic = Image.new('L', (PW, PH), 0)
    od = ImageDraw.Draw(organic)
    for (x0, y0, x1, y1), _ in DUG.values():
        od.rectangle((px(x0), px(y0), px(x1), px(y1)), fill=255)
    for pts, w, _ in CORRIDORS:
        draw_corridor(od, pts, w, 255)
    for e in CAVERN + LEDGE + MIDDEN_BLOB:
        draw_ellipse(od, e, 255)
    od.rectangle((0, px(10.4), px(AIR_EDGE + 1.5), px(14.6)), fill=255)   # the cave mouth
    floor = roughen(organic, rng, amount=26, cell=38)
    fd = ImageDraw.Draw(floor)
    for (x0, y0, x1, y1), _ in BUILT.values():
        fd.rectangle((px(x0), px(y0), px(x1), px(y1)), fill=255)
    for pts, w, mat in CORRIDORS:   # doorways into built rooms stay crisp and a full square
        if mat == PLANK:
            draw_corridor(fd, pts, w, 255)

    floor.save(os.path.join(a.outdir, 'low-road-floor.png'))   # the walkable mask, for tracing

    # 2. material map, drawn a little oversize so roughened edges inherit a material
    mat = Image.new('RGB', (PW, PH), EARTH)
    md = ImageDraw.Draw(mat)
    for e in CAVERN + LEDGE:
        draw_ellipse(md, e, CAVE, grow=0.8)
    md.rectangle((0, px(9.5), px(8), px(15.5)), fill=CAVE)
    draw_corridor(md, [(6.5, 12.5), (10, 12.5)], 4, CAVE)
    draw_corridor(md, [(12, 16.5), (12, 23.5)], 2.2, CAVE)
    for e in MIDDEN_BLOB:
        draw_ellipse(md, e, MIDDEN, grow=0.8)
    for (x0, y0, x1, y1), m in BUILT.values():
        md.rectangle((px(x0), px(y0), px(x1), px(y1)), fill=m)
    draw_corridor(md, [(23.5, 8.5), (23.5, 10.4)], 1.2, PLANK)
    draw_corridor(md, [(25.5, 3.5), (25.5, 4.5)], 1.2, PLANK)

    # 3. paint: rock everywhere, floors through the mask, air at the cliff
    rock = textured(ROCK, rng, 0.35, 30)
    plate = rock.copy()
    tex = np.asarray(smooth_noise(rng, 14), dtype=np.float32) - 128
    fine = np.asarray(smooth_noise(rng, 5), dtype=np.float32) - 128
    dd = (tex * 0.22 + fine * 0.12) / 128.0
    floors = Image.fromarray(np.clip(np.asarray(mat, dtype=np.float32) * (1 + dd[..., None]),
                                     0, 255).astype(np.uint8), 'RGB')
    # a darker lip where floor meets rock, so walls read at a glance
    edge = floor.filter(ImageFilter.GaussianBlur(9))
    plate.paste(floors, (0, 0), floor)
    shade = Image.new('RGB', (PW, PH), (10, 9, 8))
    lip = Image.eval(edge, lambda v: int(max(0, 150 - abs(v - 190) * 2.2)) if v < 250 else 0)
    lip = Image.composite(lip, Image.new('L', (PW, PH), 0), floor)
    plate.paste(shade, (0, 0), lip)

    # the air west of the cliff, with a ragged edge
    air = Image.new('L', (PW, PH), 0)
    ad = ImageDraw.Draw(air)
    pts = [(0, 0)]
    for yy in range(0, PH + 1, 40):
        pts.append((px(AIR_EDGE) + int((rng.random() - 0.5) * 34 + math.sin(yy / 90) * 14), yy))
    pts.append((0, PH))
    ad.polygon(pts, fill=255)
    air = air.filter(ImageFilter.GaussianBlur(3))
    plate.paste(textured(AIR, rng, 0.08, 60), (0, 0), air)

    d = ImageDraw.Draw(plate)

    # 4. block walls round the built rooms
    def block_wall(x0, y0, x1, y1, t=0.36):
        for (ax0, ay0, ax1, ay1) in ((x0 - t, y0 - t, x1 + t, y0), (x0 - t, y1, x1 + t, y1 + t),
                                     (x0 - t, y0, x0, y1), (x1, y0, x1 + t, y1)):
            d.rectangle((px(ax0), px(ay0), px(ax1), px(ay1)), fill=BLOCK)
            # mortar lines
            horiz = (ax1 - ax0) > (ay1 - ay0)
            step = 0.5
            if horiz:
                xx = ax0
                while xx < ax1:
                    d.line((px(xx), px(ay0), px(xx), px(ay1)), fill=(84, 80, 74), width=2)
                    xx += step
            else:
                yy = ay0
                while yy < ay1:
                    d.line((px(ax0), px(yy), px(ax1), px(yy)), fill=(84, 80, 74), width=2)
                    yy += step

    for name, ((x0, y0, x1, y1), _) in BUILT.items():
        block_wall(x0, y0, x1, y1)
    # re-open the doorways the walls just closed (a full square each)
    for pts, w, m in CORRIDORS:
        if m == PLANK:
            draw_corridor(d, pts, w, PLANK)
    d.rectangle((px(52.6), px(10.6), px(53.4), px(13.4)), fill=(98, 94, 88))   # C1 secret door, stone

    # flagstone joints in the cellar, planks in the Keeper's rooms
    for yy in range(8, 16):
        d.line((px(53), px(yy), px(58), px(yy)), fill=(118, 110, 98), width=2)
    for yy in [y / 2 for y in range(8, 32)]:
        if 4 < yy < 9:
            d.line((px(20), px(yy), px(27), px(yy)), fill=(86, 64, 40), width=2)
        if 1.2 < yy < 4:
            d.line((px(24), px(yy), px(27), px(yy)), fill=(86, 64, 40), width=2)

    # 5. props --------------------------------------------------------------------
    def rect(x0, y0, x1, y1, fill, outline=None):
        d.rectangle((px(x0), px(y0), px(x1), px(y1)), fill=fill, outline=outline, width=2)

    def blob(cx, cy, r, fill):
        d.ellipse((px(cx - r), px(cy - r), px(cx + r), px(cy + r)), fill=fill)

    def props_along(x0, x1, ytop, ybot, every=3.0):
        xx = x0 + 1
        while xx < x1:
            rect(xx - 0.2, ytop - 0.1, xx + 0.2, ytop + 0.25, TIMBER)
            rect(xx - 0.2, ybot - 0.25, xx + 0.2, ybot + 0.1, TIMBER)
            xx += every

    # C1 cellar: stair up in the north-east corner, rack on the west wall, crates and barrels
    for i in range(4):
        rect(55.6 + i * 0.6, 8.05, 56.2 + i * 0.6, 9.9, (132 - i * 12, 124 - i * 12, 110 - i * 12),
             outline=(70, 66, 60))
    rect(53.15, 8.6, 53.7, 10.4, TIMBER)                       # the empty rack
    for cx, cy in ((57.2, 14.8), (56.3, 15.1), (54.1, 15.0)):
        blob(cx, cy, 0.42, (96, 72, 44))
    rect(56.2, 12.2, 57.6, 13.4, (104, 80, 50), outline=(60, 44, 28))
    # C2 lodging: props, bedrolls, a crate for a table, a dead fire
    props_along(43, 53, 10.55, 13.45)
    for x0, top, col in ((44.2, True, CLOTH_R), (47.4, True, SACK), (45.0, False, CLOTH_B),
                         (50.0, False, CLOTH_G)):
        y0 = 10.75 if top else 12.45
        rect(x0, y0, x0 + 1.8, y0 + 0.8, col, outline=(40, 30, 22))
    rect(48.4, 11.6, 49.4, 12.4, (104, 80, 50), outline=(60, 44, 28))
    blob(51.3, 12.0, 0.45, (40, 34, 28))
    # C3 the knot: a chalk maze on the floor, a table, the bell-cord along the north wall
    for k in range(5):
        r = 0.4 + k * 0.45
        d.arc((px(39.5 - r), px(12 - r), px(39.5 + r), px(12 + r)), start=20 + k * 40,
              end=340 + k * 40, fill=(214, 208, 190), width=3)
    rect(41.2, 9.0, 42.4, 10.0, (104, 80, 50), outline=(60, 44, 28))
    d.line((px(42.6), px(8.4), px(33.4), px(10.7)), fill=(150, 130, 90), width=2)
    blob(33.4, 10.7, 0.15, (180, 150, 60))                     # the bell, at the gate
    # C4 grain store: heaped sacks, some split
    for i in range(34):
        cx = 36.8 + rng.random() * 6.4
        cy = 1.8 + rng.random() * 3.6
        rr = 0.42 + rng.random() * 0.2
        blob(cx, cy, rr, SACK if rng.random() > 0.15 else (204, 190, 150))
    # C5 packing room: made-up loads in rows, casks of lamp oil
    for i in range(6):
        rect(46.6 + i * 0.85, 1.7, 47.3 + i * 0.85, 2.6, (98, 76, 50), outline=(58, 42, 26))
    for cx in (47.2, 48.3, 49.4):
        blob(cx, 4.9, 0.45, (84, 58, 34))
    rect(50.6, 4.0, 51.6, 5.4, (104, 80, 50), outline=(60, 44, 28))
    # C12 dressing room: two bunks, pegs of clothes, a basin, a writing table
    rect(45.4, 7.5, 47.4, 8.4, (90, 70, 46), outline=(50, 36, 22))
    rect(45.4, 8.8, 47.4, 9.7, (90, 70, 46), outline=(50, 36, 22))
    for i, col in enumerate((CLOTH_R, (220, 216, 206), CLOTH_B, (220, 216, 206), CLOTH_G)):
        blob(48.3 + i * 0.6, 7.45, 0.2, col)
    blob(51.2, 9.2, 0.35, (130, 126, 118))
    rect(49.2, 8.6, 50.4, 9.6, (104, 80, 50), outline=(60, 44, 28))
    # C9 the gate: a barricade of crates across the hall with a one-square gap
    for yy in (10.6, 11.55, 13.45, 12.5):
        if abs(yy - 12.5) < 0.1:
            continue
        rect(33.3, yy, 34.3, yy + 0.9, (104, 80, 50), outline=(60, 44, 28))
    rect(33.3, 12.45, 34.3, 12.55, TIMBER)
    props_along(17, 36, 10.55, 13.45, every=3.5)
    # C10 counting room: desk, chair, shelf of ledgers, cot, the helm stand, a packed bag
    rect(21.0, 5.0, 23.2, 6.2, (86, 60, 34), outline=(50, 34, 20))
    blob(22.1, 6.8, 0.3, (70, 50, 30))
    rect(26.3, 4.4, 26.85, 7.6, TIMBER)
    rect(20.4, 7.6, 22.4, 8.6, CLOTH_B, outline=(40, 30, 22))
    blob(25.0, 8.2, 0.3, (60, 58, 54))
    rect(24.2, 5.4, 25.2, 6.2, (70, 54, 36), outline=(40, 30, 22))
    # C11 strongroom: an iron-bound chest
    rect(24.8, 2.0, 26.2, 3.0, (80, 62, 40), outline=(40, 40, 42))
    # C13 chapel: benches, the altar, the carved maze before it
    rect(21.0, 14.7, 24.0, 15.2, TIMBER)
    rect(21.0, 15.9, 24.0, 16.4, TIMBER)
    rect(24.6, 16.2, 26.6, 17.6, (120, 116, 108), outline=(70, 66, 60))
    for k in range(4):
        r = 0.3 + k * 0.3
        d.arc((px(25.6 - r), px(15.2 - r), px(25.6 + r), px(15.2 + r)), start=40 + k * 50,
              end=320 + k * 50, fill=(40, 30, 20), width=3)
    # C14 cavern: stalagmites and fallen rock
    for cx, cy in ((11.2, 4.5), (14.6, 6.6), (12.0, 8.4), (14.2, 11.0), (10.6, 10.8),
                   (13.0, 13.6), (15.0, 15.4), (11.6, 16.0), (16.0, 8.6), (12.6, 3.2)):
        blob(cx, cy, 0.28, (150, 146, 138))
        blob(cx, cy, 0.14, (178, 174, 166))
    for cx, cy, r in ((15.4, 4.2, 0.8), (10.2, 14.4, 0.7), (15.6, 13.2, 0.6)):
        blob(cx, cy, r, RUBBLE)
    # C15 ledge: the ladder heaped by the lip, four spikes
    for k in range(4):
        r = 0.2 + k * 0.12
        d.ellipse((px(3.3 - r), px(13.4 - r), px(3.3 + r), px(13.4 + r)),
                  outline=(150, 118, 70), width=3)
    for cx, cy in ((2.6, 12.2), (2.6, 12.9), (2.6, 13.6), (2.6, 14.3)):
        blob(cx, cy, 0.08, (60, 60, 64))
    # C6 the old ways: props, rubble half-blocking, the Tanner's ladder up
    for cx, cy, r in ((41.5, 24.3, 0.5), (47.0, 25.0, 0.45), (43.0, 28.0, 0.55),
                      (52.0, 34.8, 0.5), (51.0, 34.0, 0.4)):
        blob(cx, cy, r, RUBBLE)
    for i in range(5):
        yy = 16.5 + i * 1.8
        rect(37.35, yy, 37.6, yy + 0.35, TIMBER)
        rect(39.4, yy, 39.65, yy + 0.35, TIMBER)
    for k in range(4):
        rect(54.6 + k * 0.001, 24.3 + k * 0.4, 55.8, 24.4 + k * 0.4, (132, 100, 60))
    rect(54.6, 24.2, 54.75, 25.9, (132, 100, 60))
    rect(55.65, 24.2, 55.8, 25.9, (132, 100, 60))
    # nest chamber: husks and debris
    for i in range(18):
        blob(45.4 + rng.random() * 4.2, 30.4 + rng.random() * 4.2, 0.12 + rng.random() * 0.1,
             (150, 120, 70))
    # the well shaft
    cx, cy, r = WELL
    d.ellipse((px(cx - r), px(cy - r), px(cx + r), px(cy + r)), fill=BLOCK)
    d.ellipse((px(cx - r + 0.3), px(cy - r + 0.3), px(cx + r - 0.3), px(cy + r - 0.3)),
              fill=(18, 16, 14))
    # C7 the fall: a spill of rubble filling the south end; the Mole's pick and lantern
    for i in range(40):
        bx = 32.8 + rng.random() * 4.6
        by = 35.0 + rng.random() * 3.0
        blob(bx, by, 0.25 + rng.random() * 0.35, (RUBBLE[0] + rng.randint(-14, 14),) * 3)
    for cx, cy in ((34.0, 34.6), (35.2, 34.8), (36.1, 34.5)):
        blob(cx, cy, 0.1, (214, 208, 196))
    d.line((px(35.6), px(33.2), px(36.4), px(33.9)), fill=(90, 70, 44), width=4)
    blob(33.4, 33.0, 0.18, (220, 170, 70))
    # C8 midden: the pit, refuse heaped round it
    pcx, pcy, prx, pry = PIT_ELLIPSE
    d.ellipse((px(pcx - prx), px(pcy - pry), px(pcx + prx), px(pcy + pry)), fill=PIT)
    for i in range(60):
        a_ = rng.random() * math.tau
        rr = 1.0 + rng.random() * 0.45
        bx = pcx + math.cos(a_) * prx * rr
        by = pcy + math.sin(a_) * pry * rr
        col = rng.choice([(96, 86, 58), (80, 74, 50), (110, 96, 70), (74, 64, 44)])
        blob(bx, by, 0.2 + rng.random() * 0.3, col)

    out = os.path.join(a.outdir, 'low-road-blockout.png')
    plate.save(out)
    print('wrote', out, plate.size)

    if a.grid:
        g = plate.copy()
        gd = ImageDraw.Draw(g)
        for x in range(0, PW, S):
            gd.line((x, 0, x, PH), fill=(255, 255, 255) if x % (S * 10) == 0 else (90, 90, 90), width=1)
        for y in range(0, PH, S):
            gd.line((0, y, PW, y), fill=(255, 255, 255) if y % (S * 10) == 0 else (90, 90, 90), width=1)
        for x0, x1 in ((1400, 1600),):
            gd.rectangle((x0, 0, x1, PH), outline=(255, 0, 255), width=3)
        gd.rectangle((0, 933, PW, 1067), outline=(255, 0, 255), width=3)
        g.save(os.path.join(a.outdir, 'low-road-blockout-grid.png'))

    # reference crops for the renders
    plate.resize((1536, 1024), Image.LANCZOS).save(os.path.join(a.outdir, 'low-road-master.png'))
    tiles = {'tl': (0, 0, 1600, 1067), 'tr': (1400, 0, 3000, 1067),
             'bl': (0, 933, 1600, 2000), 'br': (1400, 933, 3000, 2000)}
    for k, box in tiles.items():
        plate.crop(box).resize((1536, 1024), Image.LANCZOS).save(
            os.path.join(a.outdir, 'low-road-tile-%s.png' % k))
    print('tiles', tiles)


if __name__ == '__main__':
    main()
