"""Export every PC charsheet from the Fantasy Grounds campaigns to JSON.

Read-only against the campaign db.xml files (never write those: FG rewrites them on exit).

    python fg-character-sheet-exports/export.py

Conversion rules:
- an element with children becomes an object keyed by tag (repeated tags become a list)
- type="number" leaves become numbers, other leaves strings
- type="formattedtext" keeps its inner FG markup as an HTML-ish string
- windowreference / token-style leaves with child nodes are kept as objects
- <holder> entries (FG login names / ownership ACLs) and <public /> markers are dropped
"""
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

CAMPAIGNS = {
    "wrath-of-the-righteous": "Wrath of the Righteous - AZ",
    "marchlands-commission": "The Real Work",
}
ROOT = os.path.join(os.environ["APPDATA"], "SmiteWorks", "Fantasy Grounds", "campaigns")
OUT = os.path.dirname(os.path.abspath(__file__))


def num(text):
    text = (text or "").strip()
    if text == "":
        return 0
    try:
        return int(text)
    except ValueError:
        try:
            return float(text)
        except ValueError:
            return text


def inner_xml(el):
    parts = [el.text or ""]
    for child in el:
        parts.append(ET.tostring(child, encoding="unicode"))
    return "".join(parts).strip()


def convert(el):
    kind = el.get("type")
    if kind == "formattedtext":
        return inner_xml(el)
    children = [c for c in el if c.tag not in ("holder", "public")]
    if not children:
        if kind == "number":
            return num(el.text)
        return (el.text or "").strip() if el.text is not None else ("" if kind else None)
    out = {}
    for c in children:
        val = convert(c)
        if c.tag in out:
            if not isinstance(out[c.tag], list):
                out[c.tag] = [out[c.tag]]
            out[c.tag].append(val)
        else:
            out[c.tag] = val
    return out


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-") or "unnamed"


def main():
    total = 0
    for folder, campaign in CAMPAIGNS.items():
        db = os.path.join(ROOT, campaign, "db.xml")
        tree = ET.parse(db)
        sheets = tree.getroot().find("charsheet")
        dest = os.path.join(OUT, folder)
        os.makedirs(dest, exist_ok=True)
        index = []
        for rec in sheets:
            if not rec.tag.startswith("id-"):
                continue
            data = convert(rec)
            name = data.get("name") or rec.tag
            fname = f"{slug(name)}.json"
            payload = {"campaign": campaign, "record": f"charsheet.{rec.tag}", **data}
            with open(os.path.join(dest, fname), "w", encoding="utf-8", newline="\n") as f:
                json.dump(payload, f, indent=2, ensure_ascii=False)
                f.write("\n")
            index.append({"name": name, "record": rec.tag, "file": fname,
                          "level": data.get("level"), "class": data.get("classes") and
                          [c.get("name") for c in data["classes"].values() if isinstance(c, dict)]})
            total += 1
        with open(os.path.join(dest, "index.json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump({"campaign": campaign, "characters": index}, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"{campaign}: {len(index)} sheets -> {dest}")
    print(f"total {total}")


if __name__ == "__main__":
    sys.exit(main())
