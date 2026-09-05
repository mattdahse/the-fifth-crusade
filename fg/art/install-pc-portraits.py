"""Install the player portraits into a Fantasy Grounds campaign, contrast-passed.

    python fg/art/install-pc-portraits.py                 # list what it would do
    python fg/art/install-pc-portraits.py --write

WHY THE CONTRAST PASS APPLIES HERE TOO. Fantasy Grounds uses a character's portrait for
BOTH the sheet and the figure on the map - a PC has no separate <token> record the way an
NPC does. So a portrait installed straight from the painting puts the untreated, muted
version on the battlemap, which is exactly the brown-on-brown failure that made
make-token.py necessary in the first place. These get the same adjustment the NPC tokens
get: contrast, saturation, a lift, and a vignette that darkens the ring the circle crop
eats anyway.

WHERE THEY GO. FG stores a campaign's character portraits as EXTENSIONLESS PNG files named
for the charsheet record id:

    campaigns/<name>/portraits/id-00001

There is no db.xml entry - the file existing under that name IS the link, which is the
only reason this script is allowed to exist. Writing a campaign db.xml is forbidden; FG
rewrites it wholesale on exit and the loss is total.

The id-to-character mapping is read out of the campaign's db.xml (read only) rather than
hardcoded, because ids are assigned in creation order and guessing them silently gives one
player another player's face.
"""
import argparse
import importlib.util
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

# make-token.py is hyphenated, so it cannot be imported by name. Load it by path rather
# than keeping a second copy of the adjustment - two copies would drift, and then a PC's
# portrait and an NPC's token would stop matching each other on the same map.
_spec = importlib.util.spec_from_file_location('make_token', os.path.join(HERE, 'make-token.py'))
_mt = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mt)
tokenize = _mt.tokenize
CAMPAIGNS = os.path.join(os.environ.get('APPDATA', ''), 'SmiteWorks', 'Fantasy Grounds', 'campaigns')

# character name -> the portrait slug in fg/art/portraits/
PORTRAITS = {
    'Theep Gvosh': 'theep-gvosh',
    'Wende Sandhauler': 'wende-sandhauler',
    'Esper Toevel': 'esper-toevel',
    'Jules Arine': 'jules-arine',
}
SIZE = 512


def charsheets(campaign):
    """{character name: charsheet id} straight out of the campaign db.xml. READ ONLY."""
    p = os.path.join(CAMPAIGNS, campaign, 'db.xml')
    s = io.open(p, encoding='utf-8', errors='replace').read()
    m = re.search(r'(?s)\n\t<charsheet>.*?\n\t</charsheet>', s)
    out = {}
    if not m:
        return out
    seg = m.group(0)
    for cm in re.finditer(r'(?m)^\t\t<(id-\d+)>', seg):
        i = cm.end()
        nxt = seg.find('\n\t\t<id-', i)
        body = seg[i:nxt if nxt > 0 else len(seg)]
        # depth matters: the FIRST <name> at this level is the character's own, while the
        # nested ones belong to classes, feats and racial adjustments
        nm = re.search(r'(?m)^\t\t\t<name type="string">([^<]*)</name>', body)
        if nm:
            out[nm.group(1).strip()] = cm.group(1)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--campaign', default='The Real Work')
    ap.add_argument('--write', action='store_true', help='actually write (default: dry run)')
    a = ap.parse_args()

    if not os.path.isdir(os.path.join(CAMPAIGNS, a.campaign)):
        sys.exit('no campaign called %r under %s' % (a.campaign, CAMPAIGNS))

    sheets = charsheets(a.campaign)
    dest = os.path.join(CAMPAIGNS, a.campaign, 'portraits')
    if a.write:
        os.makedirs(dest, exist_ok=True)

    for name, slug in sorted(PORTRAITS.items()):
        src = os.path.join(HERE, 'portraits', slug + '.webp')
        cid = sheets.get(name)
        if not os.path.exists(src):
            print('  %-20s no portrait painted yet' % name)
            continue
        if not cid:
            print('  %-20s no charsheet in %r - portrait ready, nothing to attach it to'
                  % (name, a.campaign))
            continue
        out = os.path.join(dest, cid)
        if a.write:
            tokenize(src).resize((SIZE, SIZE)).save(out, 'PNG', optimize=True)
            print('  %-20s -> %-9s %6.0f KB  contrast-passed' % (name, cid, os.path.getsize(out) / 1024))
        else:
            print('  %-20s -> %-9s (would write)' % (name, cid))

    if not a.write:
        print('\ndry run. pass --write to install.')


if __name__ == '__main__':
    main()
