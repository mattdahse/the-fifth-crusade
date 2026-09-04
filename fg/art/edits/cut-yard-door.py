"""Cut a doorway between the yard and the house on the scrapyard plate.

The plate was generated with a solid west wall, so the house had no way in from the
yard at all - the occluder carried a door that sat on painted stone. Rather than
re-rolling the whole plate for one opening (which would move every wall the occluders
are written against), this transplants the house's own interior door: the leaf between
the living room and the shop, rotated a quarter turn into the west wall.

Using the plate's own art keeps the lighting, palette and stonework consistent, which
no amount of prompt-wrangling reliably does.

    python fg/art/edits/cut-yard-door.py
"""
import os
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
PLATE = os.path.join(HERE, '..', 'images', 'the-scrapyard.webp')

# The interior door between the living room and the shop, leaf plus a band of wall
# above and below it, measured off the plate.
SRC = (1184, 522, 1246, 571)
# Where it goes: the west wall at the one stretch of living-room floor with nothing
# standing against it. The wall is measured, not guessed - the source wall is 49px
# thick and this one is 24, so the tile is squeezed to fit rather than allowed to
# spill onto the floorboards, where wood on wood reads as a crate and not a door.
WALL_X0, WALL_X1 = 964, 989
DOOR_Y0, DOOR_Y1 = 352, 418


def main():
    im = Image.open(PLATE).convert('RGB')
    w, h = WALL_X1 - WALL_X0, DOOR_Y1 - DOOR_Y0
    tile = (im.crop(SRC)
              .rotate(90, expand=True, resample=Image.BICUBIC)
              .resize((w, h), Image.LANCZOS))

    # Feather along the wall (top and bottom), where the transplant meets the stonework
    # it is interrupting. Across the wall the edges are the wall's own faces and must
    # stay hard, or the doorway blurs into the yard on one side and the floor on the
    # other and stops reading as an opening at all.
    mask = Image.new('L', (w, h), 0)
    mask.paste(Image.new('L', (w, h - 10), 255), (0, 5))
    mask = mask.filter(ImageFilter.GaussianBlur(2))

    im.paste(tile, (WALL_X0, DOOR_Y0), mask)
    im.save(PLATE, 'WEBP', quality=88, method=6)
    print('doorway cut at x %d-%d, y %d-%d  (%s, %.0f KB)'
          % (WALL_X0, WALL_X1, DOOR_Y0, DOOR_Y1,
             '%dx%d' % im.size, os.path.getsize(PLATE) / 1024))


if __name__ == '__main__':
    main()
