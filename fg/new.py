"""Stamp out a new record's files with ids that already agree.

    python fg/new.py npc corwin-skell --name "Corwin Skell" --cr 1
    python fg/new.py encounter the-locust-sworn --name "The Locust-Sworn" --map manor
    python fg/new.py ability grab --name "Grab (Ex)"
    python fg/new.py parcel gear-corwin-skell --name "Gear: Corwin Skell"
    python fg/new.py story the-manor --name "The Sarkorian Manor"
    python fg/new.py map the-manor --name "The Sarkorian Manor" --image images/the-manor.webp

Writes the file (or, for an NPC, the whole set of them) with every marker filled in and
the section headings the conventions ask for, then tells you what art it still needs.
It never overwrites: an existing file is reported and skipped.

WHY. The prose in these records is the work and no script writes it. The *boilerplate*
is not, and it is where the mistakes happened. One NPC means five markdown files whose
ids all have to agree —

    fg/npcs/<slug>.md            id: <slug_>
    fg/images/<slug>.md          id: portrait_<slug_>
    fg/parcels/gear-<slug>.md    id: gear_<slug_>
    fg/art/tokens/<slug>.webp
    fg/art/portraits/<slug>.webp

— and nothing enforced that set. Renaming tokens from .png to .webp silently broke both
NPC references; the portrait records were forgotten entirely until a convention forced
them and then created by hand, three at a time. Every one of those is a naming mistake
rather than a writing mistake, which is exactly what a generator is for.

The build still validates everything afterwards. This just means the file starts out
correct instead of being corrected.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def ident(slug):
    return slug.replace('-', '_')


def write(path, text, made, skipped):
    if os.path.exists(path):
        skipped.append(path)
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text)
    made.append(path)


def npc(slug, name, a):
    i = ident(slug)
    stats = '\n'.join([
        '```stats',
        'cr: %s' % (a.cr or '1'),
        'xp: %s' % (a.xp or '400'),
        'type: %s' % (a.type or 'Humanoid'),
        'subtype: %s' % (a.subtype or 'human'),
        'alignment: %s' % (a.alignment or 'NE'),
        'size: Medium',
        'init: 0',
        'senses: Perception +0',
        'ac: 10, touch 10, flat-footed 10',
        'hp: 8',
        'hd: 1d10',
        'fortitudesave: 0', 'reflexsave: 0', 'willsave: 0',
        'speed: 30 ft.',
        'atk: TODO',
        'fullatk: TODO',
        'strength: 10', 'dexterity: 10', 'constitution: 10',
        'intelligence: 10', 'wisdom: 10', 'charisma: 10',
        'babgrp: Base Atk +0; CMB +0; CMD 10',
        'skills: TODO',
        'spacereach: 5 ft./5 ft.',
        '```',
    ])
    body = """# %s

*TODO: one line, the thing you would say describing them across a table.*

<!-- id: %s -->
<!-- token: tokens/%s.webp -->
<!-- portrait: portraits/%s.webp -->

%s

## Description

> TODO: read-aloud. Present tense, what the players see and hear. FG renders this as a
> boxed frame, so it is the paragraph you actually read out.

@link image: portrait_%s | Portrait (full size)
@link parcel: gear_%s | Gear

## Special abilities

TODO, with the numbers inline, and link the rule on its own line below. Write **None** if
there are none, so the reader knows it was considered rather than forgotten.

## Tactics

TODO: opening move, when it gives ground, what it will not do, and what makes it dangerous
in this specific room.

## Roleplaying

TODO: backstory only where it changes play. Then the questions that come up at the table —
can it be bought, and with what? What does it want? Is it looking for an excuse to stop
fighting, or to turn on the people it works for?
""" % (name, i, slug, slug, stats, i, i)

    portrait = """# %s (portrait)

<!-- id: portrait_%s -->
<!-- image: portraits/%s.webp -->
<!-- grid: off -->
<!-- category: Portraits -->

The full-size portrait, for showing the players.
""" % (name, i, slug)

    parcel = """# Gear: %s

<!-- id: gear_%s -->

What is on the body. Anything here that it would actually use in a fight belongs in the
statblock or the tactics as well — a parcel is not where a GM looks mid-combat.

## Coin

- 0 GP

## Items

### TODO
<!-- count: 1 -->
<!-- type: Gear -->
<!-- cost: 0 gp -->
<!-- weight: 0 -->

TODO: what the object is, in the world, and nothing else. This description is
**player-facing** — anything lootable gets looted and read off the character sheet — so
notes about how to use the prop belong in a story record instead.
""" % (name, i)

    made, skipped = [], []
    write(os.path.join(HERE, 'npcs', slug + '.md'), body, made, skipped)
    write(os.path.join(HERE, 'images', slug + '.md'), portrait, made, skipped)
    if not a.no_parcel:
        write(os.path.join(HERE, 'parcels', 'gear-' + slug + '.md'), parcel, made, skipped)
    art = [os.path.join('fg', 'art', 'tokens', slug + '.webp'),
           os.path.join('fg', 'art', 'portraits', slug + '.webp')]
    return made, skipped, art


def simple(kind, slug, name, a):
    i = ident(slug)
    if kind == 'encounter':
        text = """# %s

<!-- id: %s -->
<!-- level: %s -->
<!-- map: %s -->
<!-- Placements are FIGHT-START positions - where they stand when initiative is -->
<!-- rolled, not where they idle. Prose belongs in fg/story/; an FG battle has no -->
<!-- text field and discards anything written here. -->

## Foes

- 1x TODO_npc_id @ 0,0
""" % (name, i, a.level or '1', a.map or 'TODO')
    elif kind == 'ability':
        text = """# %s

<!-- id: %s -->
<!-- abilitytype: Ex -->

TODO: the rule, with this creature's own numbers. A save DC belongs to the thing that
carries it, so do not point at a shared record in another module.

## At the table

TODO: what it actually does to a fight, and what it is easy to forget.
""" % (name, i)
    elif kind == 'parcel':
        text = """# %s

<!-- id: %s -->

## Coin

- 0 GP

## Items

### TODO
<!-- count: 1 -->
<!-- type: Gear -->
<!-- cost: 0 gp -->
<!-- weight: 0 -->

TODO: player-facing description. A weapon needs `srd:` or explicit damage; armour needs
`srd:` or an explicit `ac`, or it does nothing when a player equips it.
""" % (name, i)
    elif kind == 'story':
        text = """# %s

<!-- id: %s -->
<!-- order: %s -->

TODO: the GM-facing text. This is the record that carries everything a battle cannot.

## What is actually happening

TODO.

## Running it

TODO.

## What the party's work changes

TODO: say out loud what is permanently different afterwards.
""" % (name, i, a.order or '1')
    elif kind == 'map':
        text = """# %s

<!-- id: %s -->
<!-- image: %s -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 100 -->
<!-- scale: one square - five feet -->

TODO: what the place is.

## Occluders

Top-left image pixels; the build converts to FG's own space (centre origin, y up).
Straight walls are written by hand, organic ones traced with `trace-occluders.py`.
Check the result with `python fg/verify.py --map %s`.

<!-- occluder: 0,0 0,0 -->
""" % (name, i, a.image or 'images/TODO.webp', i)
    else:
        sys.exit('unknown kind: ' + kind)

    folder = {'encounter': 'encounters', 'ability': 'abilities',
              'parcel': 'parcels', 'story': 'story', 'map': 'maps'}[kind]
    made, skipped = [], []
    write(os.path.join(HERE, folder, slug + '.md'), text, made, skipped)
    return made, skipped, []


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('kind', choices=('npc', 'encounter', 'ability', 'parcel', 'story', 'map'))
    ap.add_argument('slug', help='file name without .md, e.g. corwin-skell')
    ap.add_argument('--name', help='display name (default: the slug, title-cased)')
    ap.add_argument('--cr'), ap.add_argument('--xp')
    ap.add_argument('--type'), ap.add_argument('--subtype'), ap.add_argument('--alignment')
    ap.add_argument('--map'), ap.add_argument('--level'), ap.add_argument('--order')
    ap.add_argument('--image')
    ap.add_argument('--no-parcel', action='store_true', help='npc: skip the gear parcel')
    a = ap.parse_args()

    name = a.name or a.slug.replace('-', ' ').title()
    if a.kind == 'npc':
        made, skipped, art = npc(a.slug, name, a)
    else:
        made, skipped, art = simple(a.kind, a.slug, name, a)

    for p in made:
        print('  wrote   %s' % os.path.relpath(p, os.path.dirname(HERE)))
    for p in skipped:
        print('  EXISTS  %s (left alone)' % os.path.relpath(p, os.path.dirname(HERE)))
    for p in art:
        if not os.path.exists(os.path.join(os.path.dirname(HERE), p)):
            print('  needs   %s' % p)
    if art:
        print('\nGenerate the portrait, then: python fg/art/make-token.py portraits/%s.webp' % a.slug)
    print('Then: pwsh -File ./build-fg.ps1 -Install')


if __name__ == '__main__':
    main()
