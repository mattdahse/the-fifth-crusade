"""Fingerprint one character sheet in a Fantasy Grounds db.xml, to prove later that it's unchanged.

    python sheet_fingerprint.py <db.xml> <character name, or its first word> --save <snapshot.json>
    python sheet_fingerprint.py <db.xml> <character name, or its first word> --compare <snapshot.json>

It only reads db.xml. The fingerprint is a SHA-256 of the character's whole <charsheet> node,
written out in a fixed order: tags, attributes and text, with whitespace between tags ignored.
It's also taken for each top-level section (abilities, inventory, spellset, ...) and for each
spell class, so a comparison says where a change is. Counts of spells and prepared spells are
included for a quick read.
"""
import argparse, hashlib, json, sys
import xml.etree.ElementTree as ET


def canon(e):
    attrs = "".join(f' {k}="{v}"' for k, v in sorted(e.attrib.items()))
    text = (e.text or "").strip()
    inner = "".join(canon(c) for c in e)
    return f"<{e.tag}{attrs}>{text}{inner}</{e.tag}>"


def digest(e):
    return hashlib.sha256(canon(e).encode("utf-8")).hexdigest()


def find_char(root, name):
    found = []
    sheets = root.find("charsheet")
    for c in (sheets if sheets is not None else []):
        n = (c.findtext("name") or "").strip().lower()
        if n == name.lower() or n.startswith(name.lower() + " "):
            found.append(c)
    if len(found) != 1:
        sys.exit(f"Expected one character named {name!r}, found {len(found)}.")
    return found[0]


def fingerprint(path, name):
    char = find_char(ET.parse(path).getroot(), name)
    fp = {
        "character": char.findtext("name"),
        "node": "charsheet." + char.tag,
        "sheet": digest(char),
        "sections": {c.tag: digest(c) for c in char},
        "spellclasses": {},
    }
    spellset = char.find("spellset")
    for cls in (spellset if spellset is not None else []):
        if cls.find("levels") is None:
            continue
        spells = [s for lvl in cls.find("levels") for sp in lvl.findall("spells") for s in sp if s.tag.startswith("id-")]
        fp["spellclasses"][cls.tag] = {
            "label": cls.findtext("label"),
            "hash": digest(cls),
            "spells": len(spells),
            "prepared": sum(int(s.findtext("prepared") or 0) for s in spells),
        }
    return fp


def show(fp):
    print(f"{fp['character']} ({fp['node']})  sheet {fp['sheet'][:16]}")
    for k, c in fp["spellclasses"].items():
        print(f"  {c['label']} ({k}): {c['spells']} spells, {c['prepared']} prepared  {c['hash'][:16]}")


def compare(old, new):
    if old["sheet"] == new["sheet"]:
        print("UNCHANGED: the whole character sheet is identical to the snapshot.")
        return 0
    print("CHANGED. Sections that differ from the snapshot:")
    for k in sorted(set(old["sections"]) | set(new["sections"])):
        a, b = old["sections"].get(k), new["sections"].get(k)
        if a != b:
            print(f"  {k}: " + ("added" if not a else "removed" if not b else "differs"))
    for k in sorted(set(old["spellclasses"]) | set(new["spellclasses"])):
        a, b = old["spellclasses"].get(k), new["spellclasses"].get(k)
        if a != b:
            fmt = lambda c: "none" if not c else f"{c['spells']} spells, {c['prepared']} prepared"
            print(f"  spell class {k} ({(a or b)['label']}): {fmt(a)} -> {fmt(b)}")
    return 1


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("db")
    ap.add_argument("name")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--save")
    g.add_argument("--compare")
    a = ap.parse_args()
    fp = fingerprint(a.db, a.name)
    show(fp)
    if a.save:
        with open(a.save, "w", encoding="utf-8") as f:
            json.dump(fp, f, indent=1)
        print(f"Saved {a.save}")
    elif a.compare:
        with open(a.compare, encoding="utf-8") as f:
            sys.exit(compare(json.load(f), fp))
