#!/usr/bin/env python3
"""The masterplan as data (plan chapter 02, 12): `data/town.json` from chapter 02's tables, so the terrain's passes, the
kit's placement (K5 on) and the town builder read one file instead of the chapter.

Parsed: the control points (2.2), the elevation of every level (2.5), every named building and structure (4.2, the
gazetteer) and the named routes (5.2). A gazetteer position is "x, y, z" in the town grid; a height range ("2,568-2,584")
keeps its low end as z and the range beside it; "a, b to c, d" is a line (a stair, a wall), "a, b / c, d" two points;
anything else ("upper Shöl", "every roof") has no position, and the report lists it. Names keep their Tibetan and
Chinese script and drop the Wylie and pinyin readings, which are the plan's reading aids, not the game's.
Run: tools/py tools/town/gazetteer.py   Writes data/town.json and docs/town/gazetteer-report.md.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CHAPTER = os.path.join(ROOT, "docs", "plan", "02-town.md")
OUT = os.path.join(ROOT, "data", "town.json")
REPORT = os.path.join(ROOT, "docs", "town", "gazetteer-report.md")
CORE = (-500, 1150, -320, 1080)  # chapter 02, 2.6: x0, x1, y0, y1
VALLEY = (-1350, 2300, -1100, 1100)

# Facings the chapter does not give (a building faces south, 180, unless set here), clockwise from north, where the
# ground decides the front: the Mani Lhakhang faces west, onto the Sky Stair, whose treads are level with its pad
# there (facing south, its door had opened onto a 9.5 m drop off its platform; sprint 4, step 3, 26 Sep 2026).
# Pema Ö Lhakhang faces the confluence (chapter 03's table), its stair down to the Conch terrace (M2 sprint 5, step 4).
# The Lukhang spring's yard faces down its slope, as the town's rows do (M2 sprint 6, step 3).
# The Gorge Rim Lookout faces the gorge's notch and Dungri Karpo: 034 on the real ground (chapter 08, V-13a: 040; M2
# sprint 6, step 4: DECISIONS, 9 Oct 2026).
FACINGS = {"SHL-08": 270, "SHL-11": 140, "SHL-14": 190, "SHL-32": 34,
           # Hejie (M2 sprint 9, step 4): the row south of River Street fronts it, facing north; the gates face out
           **{h: 0 for h in ("HEJ-09", "HEJ-10", "HEJ-12", "HEJ-18", "HEJ-19", "HEJ-20", "HEJ-21", "HEJ-22", "HEJ-23", "HEJ-25", "HEJ-26", "HEJ-27")},
           "HEJ-02": 90, "HEJ-03": 270}
# Footprints the table gives in words the parser does not read ("yard 12 × 8"): the spring's yard is its pad
FOOTPRINTS = {"SHL-14": [12, 8], "SHL-32": [4, 6],  # (and the Lookout's 6 x 4 laid along its view, the stand at its tip)
              "HEJ-08": [22, 40]}  # the Guandi temple's 40 m on its north-south axis (chapter 03, 9.6), 22 m across
NUM = r"[−+\-]?\d[\d,]*(?:\.\d+)?"
TIBETAN = r"[ༀ-࿿][ༀ-࿿  ]*[ༀ-࿿]|[ༀ-࿿]"
CJK = r"[㐀-鿿豈-﫿][㐀-鿿豈-﫿·・]*"


def number(s):
    return float(s.replace("−", "-").replace(",", "").replace("+", ""))


def as_int(v):
    return int(v) if float(v).is_integer() else v


def table(lines, heading):
    """The rows of the first markdown table after `heading`, as lists of stripped cells."""
    i = next(k for k, l in enumerate(lines) if l.startswith(heading))
    rows, started = [], False
    for l in lines[i + 1:]:
        if l.startswith("|"):
            started = True
            cells = [c.strip() for c in l.strip().strip("|").split("|")]
            if set(cells[0]) <= set("-: ") or cells[0] in ("ID", "Point", "Level", "Water"):
                continue
            rows.append(cells)
        elif started:
            break
    return rows


def plain(text):
    """Markdown links to their text, emphasis and code marks removed."""
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    return text.replace("**", "").replace("`", "").strip()


def names(cell):
    """(English, Tibetan, Chinese) from a name cell such as 'Dechen-tsang, བདེ་ཆེན་ཚང; 楊家鍋莊 (Yángjiā guōzhuāng)'."""
    cell = plain(cell)
    bo = " ".join(m.group(0).strip() for m in re.finditer(TIBETAN, cell))
    zh = " ".join(m.group(0) for m in re.finditer(CJK, cell))
    en = re.sub(rf"({TIBETAN}|{CJK})\s*\([^)]*\)", "", cell)  # a script and the reading after it
    en = re.sub(rf"{TIBETAN}|{CJK}", "", en)
    en = re.sub(r"\s*[,;]\s*(?=[,;]|$)", "", en)
    en = re.sub(r"^[\s,;]+|[\s,;]+$", "", re.sub(r"\s{2,}", " ", en))
    en = re.sub(r"\s*,\s*,\s*", ", ", en)
    return en, bo or None, zh or None


def position(cell):
    """{'pos': [x, y, z or None], optional 'z_range', 'line' or 'points'} or {} when the cell names no place."""
    t = plain(cell)
    m = re.fullmatch(rf"({NUM}), ({NUM}), ({NUM})(?:[–-]({NUM}))?", t)
    if m:
        out = {"pos": [as_int(number(m.group(1))), as_int(number(m.group(2))), as_int(number(m.group(3)))]}
        if m.group(4):
            out["z_range"] = [as_int(number(m.group(3))), as_int(number(m.group(4)))]
        return out
    m = re.fullmatch(rf"({NUM}), ({NUM}) to ({NUM}), ({NUM})(?:, ({NUM})(?:[–-]({NUM}))?)?", t)
    if m:
        a = [as_int(number(m.group(1))), as_int(number(m.group(2)))]
        b = [as_int(number(m.group(3))), as_int(number(m.group(4)))]
        out = {"line": [a, b], "pos": [as_int((a[0] + b[0]) / 2), as_int((a[1] + b[1]) / 2), None]}
        if m.group(5):
            out["pos"][2] = as_int(number(m.group(5)))
            if m.group(6):
                out["z_range"] = [as_int(number(m.group(5))), as_int(number(m.group(6)))]
        return out
    m = re.fullmatch(rf"({NUM}), ({NUM}) / ({NUM}), ({NUM})", t)
    if m:
        pts = [[as_int(number(m.group(1))), as_int(number(m.group(2)))], [as_int(number(m.group(3))), as_int(number(m.group(4)))]]
        return {"points": pts, "pos": pts[0] + [None]}
    m = re.fullmatch(rf"({NUM}) and ({NUM}), ({NUM})", t)
    if m:
        y = as_int(number(m.group(3)))
        pts = [[as_int(number(m.group(1))), y], [as_int(number(m.group(2))), y]]
        return {"points": pts, "pos": pts[0] + [None]}
    return {}


def footprint(cell):
    """[width, depth] from '62 × 48', '30 × 12 ramp', '5 × 4 each', '1.2 × 1.0, 1.5 high'; None otherwise."""
    m = re.match(rf"\s*({NUM})\s*×\s*({NUM})", plain(cell))
    return [as_int(number(m.group(1))), as_int(number(m.group(2)))] if m else None


def storeys(cell):
    m = re.fullmatch(r"(\d+)(?:[–-](\d+))?", cell.strip())
    if not m:
        return None
    return [int(m.group(1)), int(m.group(2))] if m.group(2) else int(m.group(1))


def numbers(cell):
    return [as_int(number(n)) for n in re.findall(NUM, plain(cell))]


def control_points(lines):
    out = {}
    for c in table(lines, "### 2.2"):
        name = plain(c[0])
        xy = re.fullmatch(rf"({NUM}), ({NUM})", plain(c[1]))
        z = numbers(c[2])
        if not xy:
            out[name] = {"rule": plain(c[1]), "z": plain(c[2]), "what": plain(c[3])}
            continue
        rec = {"pos": [as_int(number(xy.group(1))), as_int(number(xy.group(2))), z[0] if z else None], "what": plain(c[3])}
        if "(water)" in c[2]:
            rec["water"] = True
        out[name] = rec
    return out


def levels(lines):
    return [{"level": plain(c[0]), "z": numbers(c[1]), "district": plain(c[2])} for c in table(lines, "### 2.5")]


def routes(lines):
    out = []
    for c in table(lines, "### 5.2"):
        en, bo, _ = names(c[1])
        out.append({"id": c[0], "name_en": en, "name_bo": bo, "from_to": plain(c[2]), "length": plain(c[3]),
                    "climb": plain(c[4]), "steps": plain(c[5]), "gradient": plain(c[6]), "users": plain(c[7])})
    return out


def buildings(lines):
    out = []
    for c in table(lines, "### 4.2"):
        if len(c) < 10:
            continue
        en, bo, zh = names(c[1])
        rec = {"id": c[0], "name_en": en}
        if bo:
            rec["name_bo"] = bo
        if zh:
            rec["name_zh"] = zh
        rec.update({"type": plain(c[2]), "district": plain(c[3])})
        where = position(c[4])
        if where:
            rec.update(where)
        else:
            rec["place"] = plain(c[4])
        fp = FOOTPRINTS.get(c[0]) or footprint(c[5])
        if fp:
            rec["footprint"] = fp
        rec["footprint_text"] = plain(c[5])
        if c[0] in FACINGS:
            rec["rot_deg"] = FACINGS[c[0]]
        st = storeys(c[6])
        if st is not None:
            rec["storeys"] = st
        rec["enterable"] = c[7].startswith("Y")
        if "★" in c[7]:
            rec["tags"] = ["hero"]
        rec["occupants"] = plain(c[8])
        rec["note"] = plain(c[9])
        out.append(rec)
    return out


def inside(p, box):
    return box[0] <= p[0] <= box[1] and box[2] <= p[1] <= box[3]


def overlaps(bs):
    """Pairs of placed buildings whose footprints, laid square to the grid, overlap by more than a metre each way."""
    boxes = [(b["id"], b["pos"][0], b["pos"][1], b["footprint"]) for b in bs if b.get("footprint") and b.get("pos") and "line" not in b]
    pairs = []
    for i in range(len(boxes)):
        for j in range(i + 1, len(boxes)):
            a, b = boxes[i], boxes[j]
            ox = (a[3][0] + b[3][0]) / 2 - abs(a[1] - b[1])
            oy = (a[3][1] + b[3][1]) / 2 - abs(a[2] - b[2])
            if ox > 1 and oy > 1:
                pairs.append((a[0], b[0], ox, oy))
    return pairs


def main():
    lines = open(CHAPTER, encoding="utf-8").read().split("\n")
    bs = buildings(lines)
    town = {
        "about": "The masterplan as data (plan chapter 02, 12), written by tools/town/gazetteer.py from chapter 02's tables; regenerate, never edit by hand. Positions are the town grid: x east, y north, metres from Tsongra; z metres above sea level.",
        "control": control_points(lines),
        "levels": levels(lines),
        "buildings": bs,
        "routes": routes(lines),
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(town, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    placed = [b for b in bs if "pos" in b]
    unplaced = [b for b in bs if "pos" not in b]
    no_z = [b for b in placed if b["pos"][2] is None]
    outside = [b for b in placed if not inside(b["pos"], VALLEY)]
    beyond_core = [b for b in placed if inside(b["pos"], VALLEY) and not inside(b["pos"], CORE)]
    ov = overlaps(placed)
    by_district = {}
    for b in bs:
        by_district.setdefault(b["district"], [0, 0])
        by_district[b["district"]][0] += 1
        by_district[b["district"]][1] += "pos" in b
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    with open(REPORT, "w", encoding="utf-8") as f:
        f.write("# The gazetteer as data: report\n\n")
        f.write("_Written by `tools/town/gazetteer.py`, which reads chapter 02's tables (2.2, 2.5, 4.2, 5.2) into `data/town.json`. Regenerate with `tools/py tools/town/gazetteer.py` after any edit to those tables._\n\n")
        f.write("%d control points, %d levels, %d buildings and structures (%d with a position, %d of them without a height), %d routes.\n\n" % (
            len(town["control"]), len(town["levels"]), len(bs), len(placed), len(no_z), len(town["routes"])))
        f.write("| District | Rows | With a position |\n|---|---|---|\n")
        for d, (n, p) in sorted(by_district.items()):
            f.write("| %s | %d | %d |\n" % (d, n, p))
        f.write("\n## Rows with no position (%d)\n\nThey name a place in words; the town builder places them from their district and note.\n\n" % len(unplaced))
        for b in unplaced:
            f.write("- %s, %s: \"%s\"\n" % (b["id"], b["name_en"], b["place"]))
        f.write("\n## Rows placed outside the valley map (%d)\n\n" % len(outside))
        for b in outside:
            f.write("- %s, %s at %s\n" % (b["id"], b["name_en"], b["pos"]))
        f.write("\n## In the valley map but outside the core (%d)\n\n" % len(beyond_core))
        f.write(", ".join(b["id"] for b in beyond_core) + "\n")
        f.write("\n## Footprints that overlap (%d)\n\nLaid square to the grid (the gazetteer gives no rotation), overlapping by more than a metre each way. Some are meant (a shrine in a courtyard, a stall on a square); the rest are for the next review of chapter 02.\n\n" % len(ov))
        for a, b, ox, oy in ov:
            f.write("- %s and %s: %.0f × %.0f m\n" % (a, b, ox, oy))
    print("gazetteer: %d buildings (%d placed, %d without a place, %d without a height), %d routes, %d overlaps -> %s" % (
        len(bs), len(placed), len(unplaced), len(no_z), len(town["routes"]), len(ov), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
