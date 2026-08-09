"""Rasterise favicon.svg into favicon.ico and apple-touch-icon.png.

    python make-favicon.py .              write favicon.ico + apple-touch-icon.png
    python make-favicon.py . --preview    write preview-256.png + preview-small.png

Needs only Pillow. There is no SVG library on any of the three stations, so the
device is re-drawn here from the same numbers as favicon.svg rather than being
converted from it — if you change one, change the other. (A canvas diff of the
two at 32px came out at a mean 2/255 per channel, which is just the two
rasterisers disagreeing about antialiased edges.)

The --preview strip is the useful one: it blows up the 16/24/32 renders with
nearest-neighbour, which is the only honest way to see whether the sun still
reads at tab size. That check is what set the ray count and the sun's value.
"""
import math, sys
from PIL import Image, ImageDraw

CRIMSON = (0x7a, 0x1e, 0x1e, 255)   # --accent, the banner's field
SUN     = (0xa8, 0x70, 0x1c, 255)   # kept a full step under the sword on purpose
GOLD    = (0xf4, 0xda, 0xa0, 255)
K = 8   # supersample factor against the 64-unit viewBox

RAYS      = 8      # not 12 — the gaps are what survive downsampling
RAY_TIP   = 18.0   # ray point, from the sun's centre
RAY_BASE  = 10.0   # where the ray meets the disc
RAY_HALF  = 3.6    # half-width of the ray at its base
SUN_R     = 11.5
CX, CY    = 32, 21


def rot(p, deg):
    a = math.radians(deg)
    x, y = p[0] - CX, p[1] - CY
    return (CX + x * math.cos(a) - y * math.sin(a),
            CY + x * math.sin(a) + y * math.cos(a))


def render(size, rounded=True):
    S = 64 * K
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    u = lambda v: v * K                                        # noqa: E731
    box = lambda x0, y0, x1, y1: [u(x0), u(y0), u(x1), u(y1)]  # noqa: E731

    # the field — square for the touch icon, which iOS rounds off itself
    if rounded:
        d.rounded_rectangle(box(0, 0, 64, 64), radius=u(12), fill=CRIMSON)
    else:
        d.rectangle(box(0, 0, 64, 64), fill=CRIMSON)

    # the sun, behind the crosspiece
    d.ellipse(box(CX - SUN_R, CY - SUN_R, CX + SUN_R, CY + SUN_R), fill=SUN)
    ray = [(CX, CY - RAY_TIP), (CX + RAY_HALF, CY - RAY_BASE), (CX - RAY_HALF, CY - RAY_BASE)]
    for i in range(RAYS):
        pts = [rot(p, i * (360 / RAYS)) for p in ray]
        d.polygon([(u(x), u(y)) for x, y in pts], fill=SUN)

    # the longsword, point down
    d.ellipse(box(28.2, 3.0, 35.8, 10.6), fill=GOLD)                            # pommel
    d.rounded_rectangle(box(29.4, 6, 34.6, 18), radius=u(1.2), fill=GOLD)       # grip
    d.rounded_rectangle(box(11.5, 17, 52.5, 22), radius=u(2), fill=GOLD)        # crosspiece
    d.polygon([(u(x), u(y)) for x, y in
               [(26.8, 22), (37.2, 22), (35.6, 47), (32, 58.5), (28.4, 47)]], fill=GOLD)

    return im.resize((size, size), Image.LANCZOS)


root = (sys.argv[1] if len(sys.argv) > 1 else ".").rstrip("/\\")
if "--preview" in sys.argv:
    render(256).save(f"{root}/preview-256.png")
    strip = Image.new("RGBA", (160 * 3 + 40, 160), (0, 0, 0, 0))
    for i, s in enumerate((16, 24, 32)):
        strip.paste(render(s).resize((160, 160), Image.NEAREST), (i * 180, 0))
    strip.save(f"{root}/preview-small.png")
    print("wrote preview-256.png and preview-small.png — delete these, they are not shipped")
else:
    render(180, rounded=False).save(f"{root}/apple-touch-icon.png")
    ico = [render(s) for s in (16, 32, 48)]
    ico[2].save(f"{root}/favicon.ico", format="ICO",
                sizes=[(16, 16), (32, 32), (48, 48)], append_images=ico[:2])
    print("wrote favicon.ico and apple-touch-icon.png")
