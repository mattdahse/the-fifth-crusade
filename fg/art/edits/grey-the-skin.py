"""Pull the green out of a half-orc's skin without touching the rest of the plate.

    python fg/art/edits/grey-the-skin.py portraits/dorogh-kell.webp --amount 0.45

WHY NOT RE-ROLL. The Dorogh render got the hard thing right - a young half-orc visibly
*attempting* to look friendly, one notch away from goofy in either direction - and got one
easy thing wrong, which was skin warmer than asked for. Re-rolling trades a certain win for
a coin flip on the expression.

MEASURE THE PLATE BEFORE WRITING THE FILTER. The first version of this script keyed on
"green leads red and blue" and changed exactly nothing, because half-orc skin under warm
light is not green in RGB at all: sampled across the face it came back r=101 g=85 b=59,
with red leading in 1090 of 1090 samples. It only READS green against a torch. So the
filter greys by WARMTH (r - b) instead, inside a feathered ellipse over the head and neck.
Steel and glass are near-neutral and barely move; the torch and the background are outside
the ellipse and do not move at all.

Keeps the untouched render under build/ the first time it runs - NOT beside the plate,
because anything with an image extension under fg/art/ is copied into the .mod, and a
backup that ships to the table is 200 KB of nothing.
"""
import argparse
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))


def grey_skin(im, amount, cx, cy, rx, ry, feather):
    px = im.load()
    w, h = im.size
    touched = 0
    for y in range(h):
        dy = (y - cy) / float(ry)
        if abs(dy) > 1.0 + feather:
            continue
        for x in range(w):
            dx = (x - cx) / float(rx)
            d = (dx * dx + dy * dy) ** 0.5
            if d > 1.0 + feather:
                continue
            edge = 1.0 if d <= 1.0 else 1.0 - (d - 1.0) / feather   # soft rim
            r, g, b = px[x, y]
            warmth = r - b
            if warmth <= 4:
                continue
            # ramp with how warm the pixel is, so lit cheek moves more than shadow and
            # nothing bands
            k = min(1.0, warmth / 45.0) * amount * edge
            grey = (r * 299 + g * 587 + b * 114) // 1000
            px[x, y] = (int(r + (grey - r) * k),
                        int(g + (grey - g) * k),
                        int(b + (grey - b) * k))
            touched += 1
    return touched, w * h


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('plate', help='path under fg/art/, e.g. portraits/dorogh-kell.webp')
    ap.add_argument('--amount', type=float, default=0.5, help='0 = none, 1 = fully grey')
    ap.add_argument('--centre', default='545,510', help='x,y of the head/neck ellipse')
    ap.add_argument('--radii', default='225,280', help='rx,ry of that ellipse')
    ap.add_argument('--feather', type=float, default=0.18)
    a = ap.parse_args()

    path = a.plate if os.path.isabs(a.plate) else os.path.join(HERE, '..', a.plate)
    if not os.path.exists(path):
        sys.exit('no such plate: ' + path)
    bdir = os.path.join(HERE, '..', '..', '..', 'build', 'verify')
    os.makedirs(bdir, exist_ok=True)
    backup = os.path.join(bdir, os.path.basename(os.path.splitext(path)[0]) + '-as-rendered.webp')
    im = Image.open(path).convert('RGB')
    if not os.path.exists(backup):
        im.save(backup, 'WEBP', quality=88, method=6)
        print('kept the original at', os.path.basename(backup))

    cx, cy = [int(v) for v in a.centre.split(',')]
    rx, ry = [int(v) for v in a.radii.split(',')]
    touched, total = grey_skin(im, a.amount, cx, cy, rx, ry, a.feather)
    im.save(path, 'WEBP', quality=88, method=6)
    print('greyed %.1f%% of the plate at strength %.2f -> %s (%.0f KB)'
          % (100.0 * touched / total, a.amount, os.path.basename(path),
             os.path.getsize(path) / 1024))


if __name__ == '__main__':
    main()
