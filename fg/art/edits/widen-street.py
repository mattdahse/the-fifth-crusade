"""Widen Cinder Row: add street to the west of the scrapyard plate.

The plate was generated with two squares of cobbles between the west edge and the fence,
which is no room at all to stage a party outside the gate. This adds ADD px of street on
the west by quilting the plate's own cobbles - the clean strips of street above and below
the open gate - into the new space, so the paving matches without re-rolling the plate and
moving every wall the occluders are written against.

ADD is a multiple of 160 so half the plate's width stays a whole number of 80px squares
and the grid still lands on the art whichever corner FG anchors from. Every top-left pixel
coordinate on this map (occluders, pins, lights, token placements) moves east by ADD.

Run once. It refuses to widen a plate that has already been widened.

    python fg/art/edits/widen-street.py
"""
import os
import random
import numpy as np
from PIL import Image, ImageFilter, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
PLATE = os.path.join(HERE, '..', 'images', 'the-scrapyard.webp')

ORIGINAL = (1600, 1120)
ADD = 480                      # six squares of street

# Clean cobbles on the original plate: the street strip north and south of the gate.
SOURCES = [(0, 0, 90, 330), (0, 700, 90, 1120)]
# The open gate leaves lie against the old west edge; the seam stays hard across them.
LEAF_Y = (335, 685)
TILE_W, TILE_H, FEATHER = 90, 160, 14
COVER = 4                      # how many tiles deep, on average
FLAT = 24                      # blur radius below which shading is kept, above it levelled
SEAM = 16                      # px of the old edge blended into the new paving


def feather(w, h, r):
    m = Image.new('L', (w, h), 0)
    m.paste(Image.new('L', (w - 2 * r, h - 2 * r), 255), (r, r))
    return m.filter(ImageFilter.GaussianBlur(r / 2))


def level(tile, mean):
    """Strip a tile's broad shading and set it to the street's mean tone.

    The source strips darken toward the fence, so laid side by side they read as stripes.
    Only the broad shading goes; the stones and the joints between them stay."""
    a = np.asarray(tile).astype(np.float32)
    low = np.asarray(tile.filter(ImageFilter.GaussianBlur(FLAT))).astype(np.float32)
    return Image.fromarray(np.clip(a - low + mean, 0, 255).astype(np.uint8))


def main():
    im = Image.open(PLATE).convert('RGB')
    if im.size != ORIGINAL:
        raise SystemExit('plate is %dx%d, not the original %dx%d - already widened?'
                         % (im.size + ORIGINAL))
    rng = random.Random(4713)
    mean = np.concatenate([np.asarray(im.crop(b)).reshape(-1, 3) for b in SOURCES]).mean(0)
    W, H = im.size[0] + ADD, im.size[1]
    # A mean-tone ground first, so a feathered edge fades into paving and not into black.
    street = Image.new('RGB', (ADD + SEAM, H), tuple(int(v) for v in mean))

    def lay(x, y):
        sx0, sy0, sx1, sy1 = rng.choice(SOURCES)
        ty = rng.randint(sy0, sy1 - TILE_H)
        tile = level(im.crop((sx0, ty, sx0 + TILE_W, ty + TILE_H)), mean)
        if rng.random() < 0.5:
            tile = ImageOps.mirror(tile)
        if rng.random() < 0.5:
            tile = ImageOps.flip(tile)
        street.paste(tile, (x, y), feather(TILE_W, TILE_H, FEATHER))

    # One close-packed pass so no ground shows through, then tiles scattered at random
    # on top of it: any regular placement left visible reads as stripes.
    for x in range(-FEATHER, ADD + SEAM, TILE_W - 3 * FEATHER):
        for y in range(-FEATHER, H, TILE_H - 3 * FEATHER):
            lay(x, y)
    area = (ADD + SEAM) * H
    for _ in range(int(COVER * area / (TILE_W * TILE_H))):
        lay(rng.randint(-TILE_W // 2, ADD + SEAM - TILE_W // 2),
            rng.randint(-TILE_H // 2, H - TILE_H // 2))

    out = Image.new('RGB', (W, H))
    out.paste(im, (ADD, 0))
    # The new paving runs a few pixels under the old edge and fades out there, except
    # across the gate leaves, whose own edge is a better boundary than any blend.
    mask = Image.new('L', (ADD + SEAM, H), 255)
    ramp = Image.linear_gradient('L').rotate(-90, expand=True).resize((SEAM, H))
    mask.paste(ramp, (ADD, 0))
    mask.paste(Image.new('L', (SEAM, LEAF_Y[1] - LEAF_Y[0]), 0), (ADD, LEAF_Y[0]))
    mask = mask.filter(ImageFilter.GaussianBlur(1))
    out.paste(street, (0, 0), mask)

    out.save(PLATE, 'WEBP', quality=88, method=6)
    print('street widened by %dpx: plate now %dx%d (%.0f KB)'
          % (ADD, W, H, os.path.getsize(PLATE) / 1024))


if __name__ == '__main__':
    main()
