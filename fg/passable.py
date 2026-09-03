"""Check that a token can actually get through a map's occluders.

    python fg/passable.py                    every map in the built module
    python fg/passable.py --map undercroft
    python fg/passable.py --token 1          a token one square across (default)

Rasterises the occluder layer, floods the open space, then erodes it by half a token and
reports how much of the map is still reachable and where it pinches shut.

WHY. Occluders that look right on the plate can still be unplayable. A traced boundary
sits on the edge of the LIT floor, which is inside the real walkable space, and at cell
resolution it is a saw-tooth whose every tooth eats into the corridor. Between the two, a
passage that reads as a square and a half of open rock on the art can come out narrower
than one square of occluder — and **Fantasy Grounds will not slide a token through a gap
narrower than the token**, so the map is broken in a way that only shows up when somebody
tries to move.

Drawing the walls does not catch this: the picture looks correct because the walls ARE on
the right features. It only shows up when you ask whether a disc of the right diameter can
travel between them.

The fix, when this reports a pinch, is `--grow` on trace-occluders.py — dilate the open
mask before tracing so the wall line sits back in the rock.
"""
import argparse
import io
import os
import sys
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image, ImageDraw, ImageFilter

SCALE = 4          # work at quarter resolution; plenty for a pinch test and much faster


def find_module(root):
    build = os.path.join(root, 'build')
    mods = [f for f in os.listdir(build) if f.endswith('.mod')] if os.path.isdir(build) else []
    if not mods:
        sys.exit('no .mod in build/ - run build-fg.ps1 first')
    return os.path.join(build, sorted(mods)[0])


def maps(root_el):
    sec = root_el.find('image')
    if sec is None:
        return
    for child in sec:
        for rec in (list(child) if child.tag == 'category' else [child]):
            im = rec.find('image')
            if im is None:
                continue
            layer = im.find('layers/layer')
            occ = layer.find('occluders') if layer is not None else None
            if occ is None:
                continue
            gs = (im.findtext('gridsize') or '0').split(',')[0]
            yield rec.tag, layer.findtext('bitmap'), int(float(gs or 0)), occ


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--map')
    ap.add_argument('--token', type=float, default=1.0, help='token size in squares (default 1)')
    a = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(here)
    z = zipfile.ZipFile(find_module(root))
    xml = ET.fromstring(z.read('db.xml').decode('utf-8'))
    sys.path.insert(0, here)
    from verify import placements
    spots = placements(xml)

    print('%-12s %6s %8s %9s  %s' % ('map', 'square', 'token px', 'tokens', 'verdict'))
    for mid, bitmap, gridsize, occ in maps(xml):
        if a.map and mid != a.map:
            continue
        if not gridsize:
            continue
        W, H = Image.open(io.BytesIO(z.read(bitmap))).size
        w, h = W // SCALE, H // SCALE

        # Walls in white on black, at quarter scale. Doors are passable when opened, so
        # they are NOT drawn - the question is whether the map works with doors open.
        walls = Image.new('L', (w, h), 0)
        d = ImageDraw.Draw(walls)
        for o in occ:
            if o.find('toggleable') is not None:
                continue
            v = [float(q) for q in (o.findtext('points') or '').split(',') if q.strip()]
            pts = [((x + W / 2.0) / SCALE, (H / 2.0 - y) / SCALE) for x, y in zip(v[0::2], v[1::2])]
            if len(pts) > 1:
                d.line(pts, fill=255, width=2)

        open_px = Image.eval(walls, lambda p: 0 if p else 255)

        # Erode by half a token: what is left is where a token's CENTRE may stand.
        # One pixel of slack. A gap exactly one square wide should admit a one-square
        # token - it fits precisely - but eroding by exactly half the token reduces that
        # gap to a zero-width line and the flood will not cross it. Without the slack the
        # test condemns every correctly-sized doorway on the map.
        r = max(1, int(round(gridsize * a.token / 2.0 / SCALE)) - 1)
        eroded = open_px
        for _ in range(r):
            eroded = eroded.filter(ImageFilter.MinFilter(3))

        # The honest question is not "how much space is open" - the rock outside the map
        # is open too. It is: CAN THE TOKENS THAT ARE PLACED ON THIS MAP REACH EACH OTHER?
        # So the placed encounter tokens are the seeds. Any token whose own square has
        # been eroded away cannot be stood in at all; any two tokens in different
        # components are separated by a gap no token can pass.
        px = eroded.load()
        seeds = spots.get(mid, [])
        label = [[0] * w for _ in range(h)]
        comp = 0
        results = []
        for name, ix, iy in seeds:
            sx, sy = int((ix + W / 2.0) / SCALE), int((H / 2.0 - iy) / SCALE)
            if not (0 <= sx < w and 0 <= sy < h) or not px[sx, sy]:
                results.append((name, None))
                continue
            if label[sy][sx]:
                results.append((name, label[sy][sx]))
                continue
            comp += 1
            stack = [(sx, sy)]
            label[sy][sx] = comp
            while stack:
                x, y = stack.pop()
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny] and not label[ny][nx]:
                        label[ny][nx] = comp
                        stack.append((nx, ny))
            results.append((name, comp))
        stuck = [n for n, c in results if c is None]
        groups = sorted(set(c for _, c in results if c))
        if not results:
            verdict = 'no tokens placed - nothing to test'
        elif stuck:
            verdict = 'STUCK: %s cannot stand in its own square' % ', '.join(sorted(set(stuck))[:3])
        elif len(groups) > 1:
            verdict = 'SPLIT into %d groups - a passage is too narrow' % len(groups)
        else:
            verdict = 'ok - every token reachable from every other'
        print('%-12s %6d %8.0f %9d  %s'
              % (mid, gridsize, gridsize * a.token, len(results), verdict))

        out = os.path.join(root, 'build', 'verify', 'passable-%s.png' % mid)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        plate = Image.open(io.BytesIO(z.read(bitmap))).convert('RGB').resize((w, h))
        tint = Image.merge('RGB', (Image.eval(eroded, lambda p: p // 3), eroded,
                                   Image.eval(eroded, lambda p: p // 3)))
        Image.blend(plate, tint, 0.45).resize((W, H)).save(out)

    print('\nGreen is where a token centre can stand. A corridor that goes dark is one no '
          'token can enter.')


if __name__ == '__main__':
    main()
