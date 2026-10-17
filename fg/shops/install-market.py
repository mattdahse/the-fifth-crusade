"""Install shops marked `<!-- store: market -->` into a campaign as Market.ext markets.

    python fg/shops/install-market.py                 # dry run
    python fg/shops/install-market.py --write

The Real Work runs Market.ext, not Shops.ext, so a shop the players are meant to walk into
has to be a <market> record. build-fg.ps1 already compiles every fg/shops/*.md into
build/shops-campaign.xml as an MKshops record, with the SRD lookup, real weights and
descriptions. This reads that record and reshapes it into Market.ext's: the items become
<stocklist> rows, and the market's own settings come from the markdown header:

    <!-- store: market -->                 install with this script, not install-shop.py
    <!-- markup: 1.2 -->                   what the market charges over book price
    <!-- markdown: 0.5 -->                 the fraction of book price it pays when buying
    <!-- maxbuy: 300 gp -->                the most it pays for any one item
    <!-- buys: goods, potion, oil -->      the item kinds it will buy from players

A market already in the campaign is LEFT ALONE, for the same reason install-shop.py leaves
a live shop alone: its stock, coin and deals are play state. --replace ID resets one to its
markdown on purpose. A leftover MKshops record with the same id is removed, so the shop
does not exist twice.

Like install-shop.py, this refuses to run while Fantasy Grounds is up (it rewrites db.xml
on exit) and takes a timestamped backup first.
"""
import argparse
import glob
import io
import os
import re
import shutil
import sys
import time
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from importlib import import_module
_shop = import_module('install-shop')

HERE = _shop.HERE
ROOT = _shop.ROOT
BLOCK = _shop.BLOCK
CAMPAIGNS = _shop.CAMPAIGNS

BUY_KINDS = ['armor', 'goods', 'oil', 'potion', 'ring', 'rod', 'scroll', 'shield', 'staff',
             'wand', 'weapon', 'wondrous']
CP = {'pp': 1000, 'gp': 100, 'sp': 10, 'cp': 1}


def meta(text):
    return dict((k.strip(), v.strip()) for k, v in re.findall(r'<!--\s*([\w\-]+):\s*(.*?)\s*-->', text))


def market_docs():
    out = {}
    for f in sorted(glob.glob(os.path.join(HERE, '*.md'))):
        head = io.open(f, encoding='utf-8').read().split('\n## ', 1)[0]
        m = meta(head)
        if m.get('store', '').lower() == 'market' and m.get('id'):
            out[m['id']] = m
    return out


def to_cp(cost):
    total = 0
    for n, d in re.findall(r'([\d,.]+)\s*(pp|gp|sp|cp)', (cost or '').lower()):
        total += float(n.replace(',', '')) * CP[d]
    return total


def label(cp):
    cp = int(round(cp))
    parts = []
    for d in ('GP', 'SP', 'CP'):
        n, cp = divmod(cp, CP[d.lower()])
        if n:
            parts.append('%d %s' % (n, d))
    return ' '.join(parts) or 'Free'


def esc(v):
    return v.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def build_market(rid, rec, m):
    """rec is the MKshops record's XML text; returns the <market> record's XML text."""
    node = ET.fromstring(rec.strip())
    markup = float(m.get('markup', node.findtext('markup') or 1))
    buys = set(b.strip().lower() for b in m.get('buys', '').split(',') if b.strip())
    unknown = buys - set(BUY_KINDS)
    if unknown:
        sys.exit('%s: unknown buys: %s (known: %s)' % (rid, ', '.join(sorted(unknown)), ', '.join(BUY_KINDS)))

    L = ['\t\t<%s>' % rid, '\t\t\t<public />']
    for k in BUY_KINDS:
        L.append('\t\t\t<buy_%s type="number">%d</buy_%s>' % (k, 1 if k in buys else 0, k))

    # The coin float, verbatim from the shop record.
    coin = re.search(r'(?s)\n\t\t\t<coinlist>.*?\n\t\t\t</coinlist>', rec).group(0)
    # Every node players read must be <public />, or the market shows them nothing.
    coin = re.sub(r'(\n(\t+)<id-\d+>)', r'\1\n\2\t<public />', coin)
    L.append(coin.lstrip('\n').replace('<coinlist>', '<coinlist>\n\t\t\t\t<public />', 1))
    L += ['\t\t\t<deals>', '\t\t\t\t<public />', '\t\t\t</deals>',
          '\t\t\t<dealstamp type="number">0</dealstamp>',
          '\t\t\t<encumbrance>', '\t\t\t\t<public />', '\t\t\t\t<load type="number">0</load>', '\t\t\t</encumbrance>',
          '\t\t\t<markdown type="number">%s</markdown>' % m.get('markdown', '0.5'),
          '\t\t\t<markup type="number">%s</markup>' % ('%g' % markup),
          '\t\t\t<maxbuy type="string">%s</maxbuy>' % esc(m.get('maxbuy', '')),
          '\t\t\t<name type="string">%s</name>' % esc(node.findtext('name') or rid),
          '\t\t\t<stocklist>', '\t\t\t\t<public />']

    items = re.search(r'(?s)\n\t\t\t<shopitemlist>(.*?)\n\t\t\t</shopitemlist>', rec).group(1)
    for im in re.finditer(r'(?s)\n\t\t\t\t<(id-\d+)>(.*?)\n\t\t\t\t</\1>', items):
        slot, body = im.group(1), im.group(2)
        # Shops.ext's cart fields mean nothing to Market.ext.
        body = re.sub(r'\n\t+<(cartCount|excludedFromPurchase|locked)\b[^>]*>[^<]*</\1>', '', body)
        cost = re.search(r'<cost type="string">([^<]*)</cost>', body)
        price = label(to_cp(cost.group(1)) * markup) if cost else ''
        L.append('\t\t\t\t<%s>' % slot)
        L.append('\t\t\t\t\t<public />')
        if price:
            L.append('\t\t\t\t\t<calcprice type="string">%s</calcprice>' % price)
        L.append('\t\t\t\t\t<carried type="number">0</carried>')
        L.append('\t\t\t\t\t<locked type="number">1</locked>')
        L.append(body.lstrip('\n'))
        L.append('\t\t\t\t</%s>' % slot)
    L += ['\t\t\t</stocklist>', '\t\t\t<temp>', '\t\t\t\t<public />', '\t\t\t</temp>', '\t\t</%s>' % rid]
    return '\n' + '\n'.join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--campaign', default='The Real Work')
    ap.add_argument('--write', action='store_true')
    ap.add_argument('--replace', action='append', default=[], metavar='ID',
                    help='reset this live market to its markdown version (repeatable)')
    a = ap.parse_args()

    if not os.path.exists(BLOCK):
        sys.exit('no %s - run build-fg.ps1 first' % os.path.relpath(BLOCK, ROOT))
    block = io.open(BLOCK, encoding='utf-8').read()
    docs = market_docs()
    if not docs:
        sys.exit('no fg/shops/*.md is marked <!-- store: market -->')

    db = os.path.join(CAMPAIGNS, a.campaign, 'db.xml')
    if not os.path.exists(db):
        sys.exit('no campaign db.xml at ' + db)
    raw = io.open(db, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in raw else '\n'
    s = raw.replace('\r\n', '\n')

    done = []
    for rid, m in docs.items():
        rec = re.search(r'(?s)\n\t\t<%s>.*?\n\t\t</%s>' % (rid, rid), block)
        if not rec:
            sys.exit('%s is not in %s - rebuild with build-fg.ps1' % (rid, os.path.relpath(BLOCK, ROOT)))
        market = build_market(rid, rec.group(0), m)

        sec = re.search(r'(?s)\n\t<market>.*?\n\t</market>', s)
        live = sec and re.search(r'(?s)\n\t\t<%s>.*?\n\t\t</%s>' % (rid, rid), sec.group(0))
        if not sec:
            s = s.replace('\n</root>', '\n\t<market>' + market + '\n\t</market>\n</root>', 1)
            done.append('added ' + rid)
        elif live and rid in a.replace:
            at = sec.start() + live.start()
            s = s[:at] + market + s[at + len(live.group(0)):]
            done.append('reset ' + rid)
        elif live:
            done.append('kept live ' + rid)
        else:
            at = s.index('\n\t<market>') + len('\n\t<market>')
            s = s[:at] + market + s[at:]
            done.append('added ' + rid)

        # The shop must not also exist as a Shops.ext record.
        mk = re.search(r'(?s)\n\t<MKshops>.*?\n\t</MKshops>', s)
        old = mk and re.search(r'(?s)\n\t\t<%s>.*?\n\t\t</%s>' % (rid, rid), mk.group(0))
        if old:
            at = mk.start() + old.start()
            s = s[:at] + s[at + len(old.group(0)):]
            done.append('removed MKshops.' + rid)

    print('; '.join(done))
    try:
        ET.fromstring(s)
    except Exception as e:
        sys.exit('refusing to write - result would not parse: %s' % e)
    if not a.write:
        print('\ndry run. pass --write to install into %r.' % a.campaign)
        return
    if _shop.fg_running():
        sys.exit('Fantasy Grounds is RUNNING - it rewrites db.xml on exit and would eat this. Close it first.')
    backup = db.replace('db.xml', 'db.backup-%s.xml' % time.strftime('%Y%m%d-%H%M%S'))
    shutil.copy2(db, backup)
    print('backed up to', os.path.basename(backup))
    io.open(db, 'w', encoding='utf-8', newline=nl).write(s)
    print('wrote %r' % a.campaign)


if __name__ == '__main__':
    main()
