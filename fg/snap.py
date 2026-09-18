"""Snap every encounter token placement to the grid, onto a square a token can stand in.

    python fg/snap.py            # dry run: prints old -> new for every foe line
    python fg/snap.py --write    # rewrites fg/encounters/*.md

Run it AFTER a build: it reads the built module, so the walls it checks are the ones FG
will actually get. Medium and smaller go to the nearest square CENTRE; Large goes to the
nearest grid INTERSECTION, where a 2x2 token sits. A candidate square is rejected if it is
already taken in that encounter, if the line from the written position to it crosses a
wall (doors do not count), or if passable.py's eroded mask says no token can stand there -
so a snapped token is never pushed through a wall or into one. The build warns on any
placement that is off the grid.
"""
import glob
import io
import math
import os
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw, ImageFilter

FG = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, FG)
import passable  # noqa: E402

SCALE = passable.SCALE


def meta(s, key):
    m = re.search(r'<!--\s*%s:\s*(.*?)\s*-->' % re.escape(key), s)
    return m.group(1) if m else None


def cross(a, b, c, d):
    """Strict crossing: a point lying ON a wall line does not count as crossing it."""
    def o(p, q, r):
        v = (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
        return (v > 1e-9) - (v < -1e-9)
    return o(a, b, c) * o(a, b, d) < 0 and o(c, d, a) * o(c, d, b) < 0


def load_maps(z, xml):
    """Per map: the open-space raster (walls only - doors count as open), plate size,
    grid pitch, and the wall segments in top-left pixels."""
    out = {}
    for mid, bitmap, gridsize, occ in passable.maps(xml):
        if not gridsize:
            continue
        W, H = Image.open(io.BytesIO(z.read(bitmap))).size
        walls = Image.new('L', (W // SCALE, H // SCALE), 0)
        d = ImageDraw.Draw(walls)
        segs = []
        for o in occ:
            if o.find('toggleable') is not None:
                continue
            v = [float(q) for q in (o.findtext('points') or '').split(',') if q.strip()]
            full = [(x + W / 2.0, H / 2.0 - y) for x, y in zip(v[0::2], v[1::2])]
            segs += list(zip(full, full[1:]))
            if len(full) > 1:
                d.line([(x / SCALE, y / SCALE) for x, y in full], fill=255, width=2)
        out[mid] = (Image.eval(walls, lambda p: 0 if p else 255), W, H, int(gridsize), segs)
    return out


def standable(open_px, g, squares):
    # Same erosion as passable.py, so the two tools agree about what is a legal square.
    r = max(1, int(round(g * squares / 2.0 / SCALE)) - 1)
    e = open_px
    for _ in range(r):
        e = e.filter(ImageFilter.MinFilter(3))
    return e.load()


def main():
    write = '--write' in sys.argv
    z = zipfile.ZipFile(passable.find_module(os.path.dirname(FG)))
    xml = ET.fromstring(z.read('db.xml').decode('utf-8'))
    maps = load_maps(z, xml)

    sizes = {}
    for p in glob.glob(os.path.join(FG, 'npcs', '*.md')):
        s = io.open(p, encoding='utf-8').read()
        m = re.search(r'^size:\s*(\w+)', s, re.M)
        sizes[meta(s, 'id')] = m.group(1) if m else 'Medium'

    masks = {}
    for p in sorted(glob.glob(os.path.join(FG, 'encounters', '*.md'))):
        s = io.open(p, encoding='utf-8').read()
        mid = meta(s, 'map')
        if mid not in maps:
            continue
        open_px, W, H, g, segs = maps[mid]
        taken, out = set(), s
        for line in re.findall(r'^- \d+x \w+ @ .*$', s, re.M):
            npc = re.match(r'- \d+x (\w+) @', line).group(1)
            big = sizes.get(npc) in ('Large', 'Huge')
            sq = 2 if big else 1
            if (mid, sq) not in masks:
                masks[(mid, sq)] = standable(open_px, g, sq)
            px = masks[(mid, sq)]
            pts = [tuple(map(float, q.strip().split(','))) for q in line.split('@', 1)[1].split(';')]
            new = []
            for x, y in pts:
                if big:
                    bx, by = round(x / g) * g, round(y / g) * g
                else:
                    bx, by = math.floor(x / g) * g + g / 2, math.floor(y / g) * g + g / 2
                cands = [(bx + i * g, by + j * g) for i in range(-3, 4) for j in range(-3, 4)]
                cands.sort(key=lambda c: (c[0] - x) ** 2 + (c[1] - y) ** 2)
                for c in cands:
                    key = (int(c[0]), int(c[1]))
                    qx, qy = int(c[0] / SCALE), int(c[1] / SCALE)
                    if key in taken or not (0 <= qx < W // SCALE and 0 <= qy < H // SCALE):
                        continue
                    if not px[qx, qy] or any(cross((x, y), c, a, b) for a, b in segs):
                        continue
                    taken.add(key)
                    new.append(key)
                    break
                else:
                    sys.exit('no legal square near %s in %s' % (npc, os.path.basename(p)))
            spots = '; '.join('%d,%d' % c for c in new)
            print('%-22s %-26s %s -> %s' % (os.path.basename(p), npc,
                                            line.split('@', 1)[1].strip(), spots))
            out = out.replace(line, line.split('@', 1)[0] + '@ ' + spots)
        if write and out != s:
            io.open(p, 'w', encoding='utf-8', newline='\n').write(out)
    print('written' if write else 'dry run - add --write to apply')


if __name__ == '__main__':
    main()
