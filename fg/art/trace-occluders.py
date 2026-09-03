"""Trace line-of-sight occluders off a finished battlemap plate.

    python fg/art/trace-occluders.py images/the-cellar.png --threshold 62

Prints `<!-- occluder: ... -->` markers in top-left image pixels, ready to paste into
a map record under fg/maps/. `build-fg.ps1` converts those to Fantasy Grounds' own
convention (origin at the image centre, y pointing up) on the way into the module.

WHY THIS EXISTS. The pipeline used to draw a blockout in code and write occluders
against the coordinates the drawing script used. That is still right when geometry has
to be settled before art exists. But when the art comes FIRST - which is the better
order for an organic space like a cave, where hand-rolled polygon walls self-intersect
and look drawn-by-a-computer - the occluders have to be measured off the finished
plate instead. Measuring an irregular cave wall by eye against a picture of it is slow
and drifts. Reading it out of the pixels does not.

HOW. Open floor is lighter than solid rock, so a brightness threshold separates them.
The image is reduced to a coarse cell grid (each cell the mean of its pixels, which
blurs away brushwork and texture), thresholded, and the boundary of each open region
is walked with Moore neighbour tracing. The resulting rings are simplified with
Douglas-Peucker so the emitted polyline is a few dozen points rather than thousands.

The threshold is the one number that needs a human. Run with --preview to write a
mask image beside the plate and look at it: too low and the rock joins the floor, too
high and the floor breaks into islands. Pure standard library plus Pillow - no numpy
on this machine.
"""
import argparse
import math
import os
import sys
from PIL import Image, ImageFilter


def to_channel(img, channel):
    """Reduce to the single 8-bit channel the threshold is applied to.

    'lum' is plain brightness. 'warm' is red minus blue, which is usually the far
    better separator on a painted map: dug earth and lamplit floor are warm, and cut
    rock is neutral, so the two barely overlap. Brightness alone does overlap - on this
    cellar plate a shadowed stretch of tunnel is DARKER than the surrounding rock, so a
    brightness threshold cannot include the tunnel without also swallowing the rock.
    """
    if channel == 'lum':
        return img.convert('L')
    r, g, b = img.convert('RGB').split()
    from PIL import ImageChops
    return ImageChops.subtract(r, b)


def coarse_mask(img, cell, threshold, blur):
    """Reduce to a grid of cells and mark each one open (True) or solid (False)."""
    if blur:
        img = img.filter(ImageFilter.GaussianBlur(blur))
    w, h = img.size
    gw, gh = max(1, w // cell), max(1, h // cell)
    small = img.resize((gw, gh), Image.BOX)      # BOX = mean of the covered pixels
    px = small.load()
    return [[px[x, y] >= threshold for x in range(gw)] for y in range(gh)], gw, gh


def grow(mask, gw, gh, n):
    """Dilate the open region by n cells.

    The traced boundary otherwise sits on the edge of the LIT FLOOR, which is inside the
    real walkable space - painted maps shade the floor darker as it meets the wall. Worse,
    the boundary is a saw-tooth at cell resolution, and each tooth eats into the corridor.
    Between them a passage that looks a square and a half wide on the plate can come out
    narrower than one square of occluder, and Fantasy Grounds will not slide a token
    through a gap narrower than the token.

    Growing the mask pushes the wall line back INTO the rock, where it belongs: the art
    still reads correctly and the corridor is passable.
    """
    for _ in range(n):
        add = []
        for y in range(gh):
            for x in range(gw):
                if mask[y][x]:
                    continue
                if ((x and mask[y][x - 1]) or (x + 1 < gw and mask[y][x + 1]) or
                        (y and mask[y - 1][x]) or (y + 1 < gh and mask[y + 1][x])):
                    add.append((x, y))
        for x, y in add:
            mask[y][x] = True
    return mask


def components(mask, gw, gh, min_cells):
    """Flood-fill the open cells into regions, discarding specks."""
    seen = [[False] * gw for _ in range(gh)]
    out = []
    for sy in range(gh):
        for sx in range(gw):
            if not mask[sy][sx] or seen[sy][sx]:
                continue
            stack, cells = [(sx, sy)], []
            seen[sy][sx] = True
            while stack:
                x, y = stack.pop()
                cells.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < gw and 0 <= ny < gh and mask[ny][nx] and not seen[ny][nx]:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            if len(cells) >= min_cells:
                out.append(set(cells))
    return out


# Moore neighbour tracing, clockwise from the west neighbour of the start cell.
_N8 = [(-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1)]


def trace(cells):
    """Walk the outer boundary of one region and return its ring of cells."""
    start = min(cells, key=lambda c: (c[1], c[0]))     # topmost, then leftmost
    ring = [start]
    cur, back = start, 0                               # came from the west
    for _ in range(len(cells) * 8 + 16):
        found = False
        for k in range(1, 9):                          # sweep from just past the backtrack
            d = _N8[(back + k) % 8]
            nxt = (cur[0] + d[0], cur[1] + d[1])
            if nxt in cells:
                back = (_N8.index((-d[0], -d[1])) + 4) % 8
                back = (_N8.index(d) + 4) % 8          # face back the way we came
                cur = nxt
                ring.append(cur)
                found = True
                break
        if not found or (len(ring) > 2 and cur == start):
            break
    return ring


def simplify(pts, eps):
    """Douglas-Peucker: drop points that sit within eps of the line they span."""
    if len(pts) < 3:
        return pts
    ax, ay = pts[0]
    bx, by = pts[-1]
    worst, wi = -1.0, 0
    dx, dy = bx - ax, by - ay
    den = math.hypot(dx, dy)
    for i in range(1, len(pts) - 1):
        px, py = pts[i]
        if den == 0:
            dist = math.hypot(px - ax, py - ay)
        else:
            dist = abs(dy * px - dx * py + bx * ay - by * ax) / den
        if dist > worst:
            worst, wi = dist, i
    if worst <= eps:
        return [pts[0], pts[-1]]
    return simplify(pts[:wi + 1], eps)[:-1] + simplify(pts[wi:], eps)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image', help='plate, relative to fg/art/ or an absolute path')
    ap.add_argument('--threshold', type=int, default=64, help='0-255; above this is open floor')
    ap.add_argument('--channel', choices=('lum', 'warm'), default='lum',
                    help="'warm' (red minus blue) separates dug earth from cut rock far "
                         "better than brightness on a painted plate; try it first")
    ap.add_argument('--cell', type=int, default=8, help='pixels per sampled cell')
    ap.add_argument('--blur', type=float, default=3.0)
    ap.add_argument('--grow', type=int, default=2,
                    help='dilate the open region by this many cells before tracing, so the '
                         'wall line sits in the rock and corridors stay passable (default 2)')
    ap.add_argument('--epsilon', type=float, default=9.0, help='simplification, in pixels')
    ap.add_argument('--min-cells', type=int, default=400, help='ignore regions smaller than this')
    ap.add_argument('--exclude', default=None, metavar='x0,y0,x1,y1',
                    help='ignore open floor inside this box, e.g. a room walled by hand')
    ap.add_argument('--open-at', default=None, metavar='x0,y0,x1,y1',
                    help='break the traced ring inside this box, e.g. where a doorway '
                         'joins the cave to a room - otherwise the ring seals it shut')
    ap.add_argument('--preview', action='store_true', help='write <plate>-mask.png to look at')
    a = ap.parse_args()

    path = a.image
    if not os.path.isabs(path):
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), path)
    img = to_channel(Image.open(path), a.channel)
    W, H = img.size

    ex = None
    if a.exclude:
        ex = [int(v) for v in a.exclude.split(',')]

    mask, gw, gh = coarse_mask(img, a.cell, a.threshold, a.blur)
    if ex:
        for y in range(gh):
            for x in range(gw):
                px_, py_ = x * a.cell, y * a.cell
                if ex[0] <= px_ <= ex[2] and ex[1] <= py_ <= ex[3]:
                    mask[y][x] = False

    if a.grow:
        mask = grow(mask, gw, gh, a.grow)
    regions = components(mask, gw, gh, a.min_cells)
    regions.sort(key=len, reverse=True)
    print('# %s  %dx%d  channel %s  threshold %d  cell %d  -> %d region(s)'
          % (os.path.basename(path), W, H, a.channel, a.threshold, a.cell, len(regions)))

    if a.preview:
        prev = Image.new('RGB', (gw, gh), (0, 0, 0))
        pp = prev.load()
        for i, cells in enumerate(regions):
            col = [(230, 90, 90), (90, 200, 230), (230, 200, 90)][i % 3]
            for x, y in cells:
                pp[x, y] = col
        out = os.path.splitext(path)[0] + '-mask.png'
        prev.resize((W, H), Image.NEAREST).save(out)
        print('# preview ->', out)

    half = a.cell / 2.0
    for i, cells in enumerate(regions):
        ring = trace(cells)
        pts = [(x * a.cell + half, y * a.cell + half) for x, y in ring]
        pts = simplify(pts, a.epsilon)
        if pts[0] != pts[-1]:
            pts.append(pts[0])                          # close the ring
        note = ''
        if a.open_at:
            ob = [int(v) for v in a.open_at.split(',')]
            ring = pts[:-1] if pts[0] == pts[-1] else pts[:]
            inside = [j for j, (x, y) in enumerate(ring)
                      if ob[0] <= x <= ob[2] and ob[1] <= y <= ob[3]]
            if inside:
                # Rotate so the run of points inside the box sits at the end, then drop
                # it. What is left is an open polyline whose two ends are the doorway.
                cut = inside[-1]
                ring = ring[cut + 1:] + ring[:cut + 1]
                keep = [q for q in ring
                        if not (ob[0] <= q[0] <= ob[2] and ob[1] <= q[1] <= ob[3])]
                pts = keep
                note = '  (opened at %s, %d point(s) dropped)' % (a.open_at, len(ring) - len(keep))
            else:
                note = '  (WARNING: --open-at box matched no points)'
        print('# region %d: %d cells -> %d points%s' % (i + 1, len(cells), len(pts), note))
        print('<!-- occluder: %s -->'
              % ' '.join('%d,%d' % (round(x), round(y)) for x, y in pts))


if __name__ == '__main__':
    sys.setrecursionlimit(10000)
    main()
