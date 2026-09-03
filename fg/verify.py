"""Draw a built module's line-of-sight and token placements back onto its plates.

    python fg/verify.py                     every map
    python fg/verify.py --map manor         just one
    python fg/verify.py --out somewhere     write the images elsewhere

Reads `build/<module>.mod`, decodes every occluder and every encounter token placement
out of the XML, converts them back to image pixels, and writes one annotated PNG per
map. Prints a table of what it found.

WHY THIS EXISTS, AND WHY IT IS NOT OPTIONAL. Coordinates that look perfectly reasonable
in a markdown file are wrong in ways nothing else catches. Everything below was caught
by looking at the picture, and by nothing else:

  * the whole occluder layer mirrored, because FG's y-axis points UP from the image
    centre and the build was emitting it downward. Every wall was on the wrong side of
    its room, and on a symmetrical building it still looked like a floor plan.
  * a squatter placed standing inside a lit hearth, and a spearman on top of a table.
  * a wall breach thirty pixels of art away from where the occluder gap was.

Note especially that a ROUND TRIP CANNOT CATCH A CONVENTION ERROR. Decoding with the
same helper that encoded is self-consistent by construction and will happily draw a
mirrored layer the right way up. This tool re-implements the decode from FG's own
convention - origin at the plate's centre, y pointing up - precisely so it disagrees
with the build when the build is wrong.

Pure standard library plus Pillow.
"""
import argparse
import io
import os
import sys
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image, ImageDraw

WALL = (255, 45, 45)
DOOR = (70, 235, 120)
TERRAIN = (80, 190, 255)
TOKEN = (255, 215, 60)


def find_module(root):
    build = os.path.join(root, 'build')
    mods = [f for f in os.listdir(build)] if os.path.isdir(build) else []
    mods = [f for f in mods if f.endswith('.mod')]
    if not mods:
        sys.exit('no .mod in build/ - run build-fg.ps1 first')
    return os.path.join(build, sorted(mods)[0])


def image_records(root_el):
    """Yield (id, bitmap, gridsize, occluders element) - images may sit under <category>."""
    sec = root_el.find('image')
    if sec is None:
        return
    for child in sec:
        recs = list(child) if child.tag == 'category' else [child]
        for rec in recs:
            im = rec.find('image')
            if im is None:
                continue
            layer = im.find('layers/layer')
            if layer is None or not layer.findtext('bitmap'):
                continue
            gs = (im.findtext('gridsize') or '0').split(',')[0]
            yield rec.tag, layer.findtext('bitmap'), int(float(gs or 0)), layer.find('occluders')


def placements(root_el):
    """map id -> [(npc name, image x, image y)] from every battle's maplinks."""
    out = {}
    sec = root_el.find('battle')
    if sec is None:
        return out
    for battle in sec:
        npclist = battle.find('npclist')
        for entry in (npclist if npclist is not None else []):
            ml = entry.find('maplink')
            if ml is None:
                continue
            for spot in ml:
                ref = spot.find('imageref')
                if ref is None:
                    continue
                # recordname is image.<mapid>.image@<Module>
                mid = (ref.findtext('recordname') or '').split('.')
                if len(mid) < 2:
                    continue
                out.setdefault(mid[1], []).append(
                    (entry.findtext('name') or '?',
                     float(spot.findtext('imagex') or 0),
                     float(spot.findtext('imagey') or 0)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--map', help='only this map id')
    ap.add_argument('--out', default=None, help='directory for the PNGs (default build/verify)')
    ap.add_argument('--grid', action='store_true', help='draw the record\'s own grid too')
    a = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(here)
    modpath = find_module(root)
    out_dir = a.out or os.path.join(root, 'build', 'verify')
    os.makedirs(out_dir, exist_ok=True)

    z = zipfile.ZipFile(modpath)
    xml = ET.fromstring(z.read('db.xml').decode('utf-8'))
    spots = placements(xml)
    print('%s\n' % os.path.basename(modpath))
    print('%-12s %-12s %5s %6s %6s %6s  %s' % ('map', 'plate', 'grid', 'walls', 'doors', 'tokens', 'written'))

    any_written = False
    for mid, bitmap, gridsize, occ in image_records(xml):
        if a.map and mid != a.map:
            continue
        if occ is None and mid not in spots:
            continue                                    # a portrait, nothing to check
        try:
            plate = Image.open(io.BytesIO(z.read(bitmap))).convert('RGB')
        except KeyError:
            print('  %-12s bitmap %s is not in the module' % (mid, bitmap))
            continue
        W, H = plate.size
        d = ImageDraw.Draw(plate)

        if a.grid and gridsize:
            for x in range(0, W, gridsize):
                d.line([(x, 0), (x, H)], fill=(255, 255, 255), width=1)
            for y in range(0, H, gridsize):
                d.line([(0, y), (W, y)], fill=(255, 255, 255), width=1)

        walls = doors = 0
        for o in (occ if occ is not None else []):
            v = [float(q) for q in (o.findtext('points') or '').split(',') if q.strip()]
            # FG's own convention, re-implemented here on purpose: centre origin, y UP.
            pts = [(x + W / 2.0, H / 2.0 - y) for x, y in zip(v[0::2], v[1::2])]
            if not pts:
                continue
            if o.find('toggleable') is not None:
                colour, pts = DOOR, pts + [pts[0]]
                doors += 1
            elif o.find('terrain') is not None:
                colour = TERRAIN
            else:
                colour = WALL
                walls += 1
            d.line(pts, fill=colour, width=9, joint='curve')

        for name, ix, iy in spots.get(mid, []):
            x, y = ix + W / 2.0, H / 2.0 - iy
            r = max(18, (gridsize or 70) // 2)
            d.ellipse([x - r, y - r, x + r, y + r], outline=TOKEN, width=6)
            d.text((x - r, y + r + 4), name[:20], fill=TOKEN)

        name = os.path.join(out_dir, 'verify-%s.png' % mid)
        plate.save(name)
        any_written = True
        print('%-12s %-12s %5d %6d %6d %6d  %s'
              % (mid, '%dx%d' % (W, H), gridsize, walls, doors,
                 len(spots.get(mid, [])), os.path.relpath(name, root)))

    if not any_written:
        print('  nothing to draw')
    print('\nred = blocks sight   green = door   blue = terrain   yellow = token')


if __name__ == '__main__':
    main()
