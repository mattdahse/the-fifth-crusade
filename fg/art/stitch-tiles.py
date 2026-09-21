"""Stitch overlapping painted tiles into one plate.

    python fg/art/stitch-tiles.py BLOCKOUT OUT TL TR BL BR [--regions x0,y0,x1,y1 ...]

Made for The Low Road (make-low-road.py), whose tiles are 1600 x 1067 windows of a 3000 x 2000
blockout, rendered at 1536 x 1024. For each tile, in order:

1. Scale the render back to its window.
2. Register it to the blockout: a translation found by phase correlation on edge images, capped
   at 40 px. A render drifts a little from the plan it was told not to move; this puts the walls
   back where the plan, and the other tiles, have them.
3. Match its colour to the neighbours already placed, by per-channel gain and offset over the
   overlap, applied gently.
4. Join it along the cheapest seam through the overlap (dynamic programming on the squared
   difference), feathered a few pixels either side. The seam wanders round a stalagmite rather
   than cutting it in half.

The rows are joined first, then the two rows are joined top to bottom.
"""
import argparse

import numpy as np
from PIL import Image, ImageFilter

DEFAULT_REGIONS = [(0, 0, 1600, 1067), (1400, 0, 3000, 1067),
                   (0, 933, 1600, 2000), (1400, 933, 3000, 2000)]


def edges(a):
    g = a.mean(axis=2) if a.ndim == 3 else a
    gx = np.zeros_like(g); gy = np.zeros_like(g)
    gx[:, 1:-1] = g[:, 2:] - g[:, :-2]
    gy[1:-1, :] = g[2:, :] - g[:-2, :]
    return np.hypot(gx, gy)


def phase_shift(ref, mov, cap=40):
    """(dy, dx) that moves `mov` onto `ref`."""
    a, b = edges(ref), edges(mov)
    a = (a - a.mean()) * np.hanning(a.shape[0])[:, None] * np.hanning(a.shape[1])[None, :]
    b = (b - b.mean()) * np.hanning(b.shape[0])[:, None] * np.hanning(b.shape[1])[None, :]
    F = np.fft.fft2(a) * np.conj(np.fft.fft2(b))
    r = np.fft.ifft2(F / (np.abs(F) + 1e-9)).real
    dy, dx = np.unravel_index(np.argmax(r), r.shape)
    if dy > r.shape[0] // 2: dy -= r.shape[0]
    if dx > r.shape[1] // 2: dx -= r.shape[1]
    if abs(dy) > cap or abs(dx) > cap:
        return 0, 0
    return int(dy), int(dx)


def shift(a, dy, dx):
    out = np.roll(a, (dy, dx), axis=(0, 1))
    # fill the rolled-in edge with the nearest real pixels rather than wrapped ones
    if dy > 0: out[:dy] = out[dy:dy + 1]
    if dy < 0: out[dy:] = out[dy - 1:dy]
    if dx > 0: out[:, :dx] = out[:, dx:dx + 1]
    if dx < 0: out[:, dx:] = out[:, dx - 1:dx]
    return out


def colour_match(src_ov, ref_ov, strength=0.7):
    """Per-channel gain/offset taking src's overlap statistics toward ref's."""
    g, o = [], []
    for c in range(3):
        s, r = src_ov[..., c], ref_ov[..., c]
        gain = (r.std() + 1e-6) / (s.std() + 1e-6)
        gain = 1 + (np.clip(gain, 0.8, 1.25) - 1) * strength
        off = (r.mean() - s.mean() * gain) * strength
        g.append(gain); o.append(off)
    return np.array(g), np.array(o)


def seam_mask_vertical(a, b, feather=6):
    """a, b: overlapping HxWx3 arrays (a on the left). Returns HxW weights for b (0..1)."""
    cost = ((a - b) ** 2).sum(axis=2)
    h, w = cost.shape
    acc = cost.copy()
    back = np.zeros((h, w), dtype=np.int8)
    for y in range(1, h):
        prev = acc[y - 1]
        left = np.r_[np.inf, prev[:-1]]
        right = np.r_[prev[1:], np.inf]
        stack = np.vstack([left, prev, right])
        idx = stack.argmin(axis=0)
        acc[y] += stack[idx, np.arange(w)]
        back[y] = idx - 1
    # keep the seam away from the very edges of the overlap
    margin = max(8, w // 10)
    last = acc[-1].copy(); last[:margin] = np.inf; last[-margin:] = np.inf
    x = int(last.argmin())
    path = np.zeros(h, dtype=int)
    for y in range(h - 1, -1, -1):
        path[y] = x
        x = int(np.clip(x + int(back[y, x]), margin, w - margin - 1))
    m = (np.arange(w)[None, :] >= path[:, None]).astype(np.float32) * 255
    m = np.asarray(Image.fromarray(m.astype(np.uint8)).filter(ImageFilter.GaussianBlur(feather)),
                   dtype=np.float32) / 255.0
    return m


def join_h(left, right, ov):
    """Join two images side by side that overlap by `ov` columns."""
    a, b = left[:, -ov:], right[:, :ov]
    m = seam_mask_vertical(a, b)[..., None]
    mid = a * (1 - m) + b * m
    return np.concatenate([left[:, :-ov], mid, right[:, ov:]], axis=1)


def join_v(top, bottom, ov):
    t = np.transpose(top, (1, 0, 2)); b = np.transpose(bottom, (1, 0, 2))
    return np.transpose(join_h(t, b, ov), (1, 0, 2))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('blockout'); ap.add_argument('out')
    ap.add_argument('tiles', nargs=4, help='TL TR BL BR renders')
    a = ap.parse_args()
    plan = np.asarray(Image.open(a.blockout).convert('RGB'), dtype=np.float32)
    regions = DEFAULT_REGIONS
    arrs = []
    for path, (x0, y0, x1, y1) in zip(a.tiles, regions):
        im = Image.open(path).convert('RGB').resize((x1 - x0, y1 - y0), Image.LANCZOS)
        arr = np.asarray(im, dtype=np.float32)
        dy, dx = phase_shift(plan[y0:y1, x0:x1], arr)
        print('%s: shift dy=%d dx=%d' % (path.split('\\')[-1].split('/')[-1], dy, dx))
        arrs.append(shift(arr, dy, dx))
    tl, tr, bl, br = arrs
    ovx = regions[0][2] - regions[1][0]          # 200
    ovy = regions[0][3] - regions[2][1]          # 134
    # colour: anchor on TL
    g, o = colour_match(tr[:, :ovx], tl[:, -ovx:]); tr = tr * g + o
    g, o = colour_match(bl[:ovy], tl[-ovy:]); bl = bl * g + o
    g1, o1 = colour_match(br[:ovy], tr[-ovy:]); g2, o2 = colour_match(br[:, :ovx], bl[:, -ovx:])
    br = br * ((g1 + g2) / 2) + (o1 + o2) / 2
    top = join_h(tl, tr, ovx)
    bottom = join_h(bl, br, ovx)
    whole = join_v(top, bottom, ovy)
    Image.fromarray(np.clip(whole, 0, 255).astype(np.uint8)).save(a.out)
    print('wrote', a.out, whole.shape[1], 'x', whole.shape[0])


if __name__ == '__main__':
    main()
