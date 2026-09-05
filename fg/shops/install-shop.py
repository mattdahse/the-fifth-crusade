"""Install the built shop records into a Fantasy Grounds campaign's db.xml.

    python fg/shops/install-shop.py                 # dry run
    python fg/shops/install-shop.py --write

WHY THIS IS NOT IN THE MODULE. Shops.ext's MKshops window has a module-only branch:

    if DB.getModule(getDatabaseNode()) ~= "" then
        menubar.subwindow.locked.setVisible(false)

and current CoreRPG has no control named `locked` in record_window_tabbed's menubar, so a
shop record loaded FROM A MODULE throws on every client that loads it:

    Script execution error: [string "W:MKshops"]:7: attempt to index field 'locked'

The branch only runs for module-sourced records, which is why nobody had hit it: a shop is
normally a campaign record a GM makes in the client. Patching a third-party extension is
not ours to do and would be undone by its next update, so the shop lives campaign-side,
where DB.getModule() returns "" and that line never executes.

The markdown under fg/shops/ stays the source of truth. build-fg.ps1 compiles it to
build/shops-campaign.xml with the same item pipeline the parcels use - SRD lookup, real
weights, real damage - and this splices that block into db.xml.

WRITING A CAMPAIGN db.xml IS NORMALLY FORBIDDEN. Fantasy Grounds rewrites it wholesale on
exit, so anything written underneath a running client is destroyed without warning. This
refuses to run while FG is up, and takes a timestamped backup first.
"""
import argparse
import io
import os
import re
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
BLOCK = os.path.join(ROOT, 'build', 'shops-campaign.xml')
CAMPAIGNS = os.path.join(os.environ.get('APPDATA', ''), 'SmiteWorks', 'Fantasy Grounds', 'campaigns')


def fg_running():
    try:
        out = subprocess.run(['tasklist'], capture_output=True, text=True, timeout=20).stdout.lower()
    except Exception:
        return False
    return 'fantasygrounds' in out.replace(' ', '')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--campaign', default='The Real Work')
    ap.add_argument('--write', action='store_true')
    a = ap.parse_args()

    if not os.path.exists(BLOCK):
        sys.exit('no %s - run build-fg.ps1 first' % os.path.relpath(BLOCK, ROOT))
    block = io.open(BLOCK, encoding='utf-8').read().rstrip()
    ids = re.findall(r'(?m)^\t\t<([\w\-]+)>', block)
    names = re.findall(r'<name type="string">([^<]*)</name>', block)
    print('shop records to install: %s' % ', '.join(ids))
    if names:
        print('  "%s" with %d items' % (names[-1] if False else names[0], max(0, len(names) - 1)))

    db = os.path.join(CAMPAIGNS, a.campaign, 'db.xml')
    if not os.path.exists(db):
        sys.exit('no campaign db.xml at ' + db)

    if not a.write:
        print('\ndry run. pass --write to install into %r.' % a.campaign)
        return
    if fg_running():
        sys.exit('Fantasy Grounds is RUNNING - it rewrites db.xml on exit and would eat this. Close it first.')

    s = io.open(db, encoding='utf-8').read()
    backup = db.replace('db.xml', 'db.backup-%s.xml' % time.strftime('%Y%m%d-%H%M%S'))
    shutil.copy2(db, backup)
    print('backed up to', os.path.basename(backup))

    if re.search(r'(?s)\n\t<MKshops>.*?\n\t</MKshops>', s):
        s = re.sub(r'(?s)\n\t<MKshops>.*?\n\t</MKshops>', '\n' + block, s, count=1)
        how = 'replaced the existing <MKshops> section'
    else:
        s = s.replace('\n</root>', '\n' + block + '\n</root>', 1)
        how = 'added a new <MKshops> section'

    try:
        ET.fromstring(s)
    except Exception as e:
        sys.exit('refusing to write - result would not parse: %s' % e)

    io.open(db, 'w', encoding='utf-8', newline='\n').write(s)
    print('%s in %r' % (how, a.campaign))


if __name__ == '__main__':
    main()
