"""Cut a 512 token from a full-size portrait, and make it survive being drawn small.

    python fg/art/make-token.py portraits/labyrinth-squatter.webp
    python fg/art/make-token.py portraits/*.webp

Writes tokens/<same name>.webp at 512 x 512, quality 85.

WHY THE ADJUSTMENT. The archive's house look is muted earth - browns, rust, ash-grey,
low-key light - and that is right for a plate somebody studies. Fantasy Grounds crops a
token to a circle and draws it at about one grid square on a screen shared across a
table, and at that size the same painting collapses into an indistinguishable brown
square. Two NPCs painted this way become the same token.

So a token is not just a resized portrait. It gets:

  contrast   pulls the subject's values apart from the background's
  saturation gives each creature a dominant colour that survives the shrink
  brightness lifts the whole thing out of the murk FG's map view sinks it into
  vignette   darkens the outer ring, which is where the circle crop bites anyway,
             so the head reads as a shape rather than as part of the scenery

This is a rescue, not a substitute for generating the art brighter in the first place -
it cannot separate two portraits that were painted in the same palette. See
PROMPTS.md for the rule new token art is generated against.
"""
import glob
import os
import sys
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

SIZE = 512
CONTRAST = 1.55
SATURATION = 1.45
BRIGHTNESS = 1.12


def tokenize(src):
    im = Image.open(src).convert('RGB')
    im = ImageEnhance.Contrast(im).enhance(CONTRAST)
    im = ImageEnhance.Color(im).enhance(SATURATION)
    im = ImageEnhance.Brightness(im).enhance(BRIGHTNESS)

    # Darken the outside. The ellipse is wider than the frame and sits high, so the
    # falloff bites the corners and the bottom - never the head, which sits upper-centre
    # in every one of these portraits by design.
    w, h = im.size
    vig = Image.new('L', (w, h), 0)
    ImageDraw.Draw(vig).ellipse([-w * 0.30, -h * 0.34, w * 1.30, h * 1.16], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(w * 0.12))
    im = Image.composite(im, Image.new('RGB', (w, h), (18, 16, 15)), vig)

    return im.resize((SIZE, SIZE), Image.LANCZOS)


def main(args):
    here = os.path.dirname(os.path.abspath(__file__))
    paths = []
    for a in args:
        p = a if os.path.isabs(a) else os.path.join(here, a)
        paths.extend(sorted(glob.glob(p)) or [p])
    if not paths:
        print(__doc__)
        return 1
    for src in paths:
        if not os.path.exists(src):
            print('missing:', src)
            continue
        out = os.path.join(here, 'tokens', os.path.splitext(os.path.basename(src))[0] + '.webp')
        os.makedirs(os.path.dirname(out), exist_ok=True)
        tokenize(src).save(out, 'WEBP', quality=85, method=6)
        print('wrote %s  %d bytes' % (os.path.relpath(out, here), os.path.getsize(out)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
