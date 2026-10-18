#!/usr/bin/env python3
"""Hejie at a distance (D03 `hejie`, HEJ-01 to HEJ-39; plan chapter 02, chapter 03, 9; M2 sprint 9, step 4): its pads on
the real ground, its wall and its generic houses, for the terrain build and the town.

The pads: chapter 02's heights are the design's, and on the real ground (Greg's MOVE) Hejie's buildings stood up to 10 m
off it (the post, the relay station, the farrier and the silk shop on fills over the slope down to the fan channel's
trench); each named building with a footprint stands at the middle (the median) of the ground under it, as the Caravan
Ground's do (tools/town/caravan_ground.py). pads.py reads `pads`.
The wall, HEJ-01 (chapter 03, 9.4: dry stone 3.5-4.5 m high; chapter 02: about 720 m, its south side on the Dungchu's
flood embankment): a line of WALL round the quarter, 4 m over the ground it follows, broken for the East Gate, the Water
Gate and the postern (their towers are the kit's `hejie_gate`, placed by world/town.gd from the gazetteer); walls.py
builds it as the gardens' walls are (`walls`).
The houses, HEJ-37 and HEJ-38 (chapter 02: H-HEJ-01 to 32, F shop-houses; H-HEJ-33 to 40, G courtyard houses): F houses
along River Street's line (STREET, from the East Gate down to the Water Gate; chapter 02: "shops on both sides"), each
side fronting it, every 7 m where the ground is free of the named buildings, of one another, of the street and of the
wall, and not over the trench, and where its frontage runs out, in the back lanes; G houses in the back lanes where a
14 x 18 m house fits. Each its form and seed (the kit's `hejie_f1`, `f2`, `f3`, `g1`, `g2`); a house's pad at its
ground's median, but a street house's at the street's level before its door.
River Street (`lanes`, carved by pads.py as the ramps' lanes are): its line bends between the named buildings that
front it as chapter 02 places them (the teahouse and the inn HEJ-11 on its north side, Han Desheng's shop and the inn
HEJ-12 on its south), its bed the ground along it smoothed over STREET_SMOOTH m and met at each end by its gate's floor;
the named buildings fronting it stand at its level too.
Run: tools/py tools/town/hejie.py   Writes data/hejie.json and docs/town/hejie-report.md
(tools/terrain/build.sh runs it before pads.py).
"""
import json
import math
import os
import random
import sys
import zlib

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
from terrain_site import Site  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
SOURCE = os.path.join(GEN, "valley_shaped_1m.tif")
TOWN = os.path.join(ROOT, "data", "town.json")
OUT = os.path.join(ROOT, "data", "hejie.json")
REPORT = os.path.join(ROOT, "docs", "town", "hejie-report.md")
WALL = [(-214.0, 12.0), (-214.0, -122.0), (-250.0, -126.0), (-300.0, -133.5), (-350.0, -137.0), (-400.0, -140.0),
        (-462.0, -142.0), (-462.0, 12.0), (-214.0, 12.0)]  # round the quarter, its south side on the trench's north bank
WALL_H = 4.0
GAPS = [("HEJ-02", (-214.0, -80.0), 4.5), ("HEJ-03", (-462.0, -95.0), 4.0), ("HEJ-04", (-330.0, 12.0), 0.8)]  # the
# gates' openings in it (half their width along it): the East Gate's and the Water Gate's towers stand in them
STREET = [(-214.0, -80.0), (-232.0, -82.0), (-255.0, -83.0), (-263.0, -84.0), (-277.0, -84.5), (-296.0, -94.5), (-304.0, -94.5),
          (-322.0, -89.0), (-338.0, -88.5), (-347.0, -85.5), (-358.0, -83.0), (-372.0, -83.2), (-382.0, -87.8), (-410.0, -91.5),
          (-440.0, -94.0), (-462.0, -95.0)]  # River Street's line, from the East Gate down to the Water Gate, round the
# named buildings' fronts (the wine shop, Han Desheng's shop, the teahouse, the inns, the silversmith, the brassware shop)
STREET_SMOOTH = 24.0  # its bed: the ground along it averaged over this many metres
STREET_W = 4.8  # its bed's width, inside the fronts (STREET_HALF)
FRONTS = 3.0  # a named building whose front stands this near the street's edge stands at the street's level
F_FORMS = [("hejie_f1", 6.0), ("hejie_f2", 8.0), ("hejie_f3", 8.0)]
F_DEPTH = 12.0
G_SIZE = (14.0, 18.0)
N_F, N_G = 32, 8
CLEAR = 1.2  # metres kept between a house and anything else
STREET_HALF = 2.6  # River Street's half width before the fronts
SEED = 1903


def rect(cx, cy, w, d, facing, grow=0.0):
    """A footprint's corners: w across its front, d deep, its front facing `facing` (compass degrees)."""
    th = math.radians(facing)
    fx, fy = math.sin(th), math.cos(th)  # the front
    ax, ay = fy, -fx  # along it
    hw, hd = w / 2 + grow, d / 2 + grow
    return [(cx + ax * u + fx * v, cy + ay * u + fy * v) for u, v in ((-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd))]


def _sep(a, b):
    """Whether two convex polygons are apart (a separating axis among their edges' normals)."""
    for poly in (a, b):
        for i in range(len(poly)):
            x0, y0 = poly[i]
            x1, y1 = poly[(i + 1) % len(poly)]
            nx, ny = y1 - y0, x0 - x1
            pa = [nx * x + ny * y for x, y in a]
            pb = [nx * x + ny * y for x, y in b]
            if max(pa) < min(pb) or max(pb) < min(pa):
                return True
    return False


def inside(poly, x, y):
    c = False
    for i in range(len(poly) - 1):
        (x0, y0), (x1, y1) = poly[i], poly[i + 1]
        if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
            c = not c
    return c


def kit_of(b):
    """The kit's type for a named building of Hejie's (as world/town.gd's _hejie_file chose it until M2 sprint 10, step 3:
    the inns, the gate towers, the post, the relay station, the official lodging, the temple, the godown; a G house or a
    shop by its type and width), its variant by its id's hash; written into `pads` for world/town.gd and the street graph."""
    bid, t = b["id"], b.get("type", "")
    seed = 1 + zlib.crc32(bid.encode()) % 3
    if bid in ("HEJ-11", "HEJ-12"):
        return "hejie_inn_v1"
    fixed = {"gate tower": "hejie_gate_v1", "yamen": "hejie_post_v1", "stables and rooms": "hejie_relay_v1",
             "courtyard house": "hejie_lodging_v1", "temple": "hejie_temple_v1", "long hall": "hejie_godown_v1"}
    if t in fixed:
        return fixed[t]
    if t in ("G", "courtyard mill", "F, large"):
        return "hejie_g%d_v%d" % (1 if t == "courtyard mill" else 2, min(seed, 2))
    if t in ("F", "F + yard", "F + forge", "F, open front"):
        if float((b.get("footprint") or [6, 12])[0]) <= 6.5:
            return "hejie_f1_v%d" % seed
        return ("hejie_f3_v%d" if seed == 3 else "hejie_f2_v%d") % seed
    return ""


def seg_dist(px, py, a, b):
    (x0, y0), (x1, y1) = a, b
    dx, dy = x1 - x0, y1 - y0
    t = max(0.0, min(1.0, ((px - x0) * dx + (py - y0) * dy) / max(dx * dx + dy * dy, 1e-9)))
    return math.hypot(px - (x0 + dx * t), py - (y0 + dy * t))


def main():
    site = Site.load()
    g = site.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site.shift  # noqa: E731

    def under(b):  # a named building's ground: (its median, its lowest, its highest) over its footprint
        x, y = b["pos"][:2]
        w, d = b["footprint"]
        th = math.radians(float(b["rot_deg"]) if b.get("rot_deg") is not None else 180.0)
        fx, fy = math.sin(th), math.cos(th)
        U, V = np.meshgrid(np.linspace(-w / 2, w / 2, 9), np.linspace(-d / 2, d / 2, 9))
        zs = Z(x + U * fy + V * fx, y - U * fx + V * fy)
        return float(np.nanmedian(zs)), float(np.nanmin(zs)), float(np.nanmax(zs))
    town = json.load(open(TOWN, encoding="utf-8"))
    hej = [b for b in town["buildings"] if b["id"].startswith("HEJ-")]
    taken = []  # the named buildings' footprints, grown, and the street's band
    pads, lines = {}, []
    # River Street's bed: the ground along its line every metre, averaged, met at each end by its gate's floor
    seg = [math.hypot(x1 - x0, y1 - y0) for (x0, y0), (x1, y1) in zip(STREET[:-1], STREET[1:])]
    cum = np.concatenate([[0.0], np.cumsum(seg)])
    total = float(cum[-1])
    ss = np.linspace(0.0, total, int(total) + 1)
    at = lambda t: (np.interp(t, cum, [q[0] for q in STREET]), np.interp(t, cum, [q[1] for q in STREET]))  # noqa: E731
    ground = np.array([float(Z(*at(t))) for t in ss])
    k = int(STREET_SMOOTH / 2)
    padded = np.concatenate([np.full(k, ground[0]), ground, np.full(k, ground[-1])])
    bed = np.convolve(padded, np.ones(2 * k + 1) / (2 * k + 1), mode="valid")
    ends = {gid: under(next(q for q in hej if q["id"] == gid))[0] for gid in ("HEJ-02", "HEJ-03")}  # the gates' floors at
    # their ground's median, as every named building's
    bed = bed + (ends["HEJ-02"] - bed[0]) * np.clip(1.0 - ss / 15.0, 0.0, 1.0) + (ends["HEJ-03"] - bed[-1]) * np.clip(1.0 - (total - ss) / 15.0, 0.0, 1.0)
    street_z = lambda t: float(np.interp(t, ss, bed))  # noqa: E731

    def street_s(px, py):  # the nearest point of the street's line: (its s, its distance)
        best = (0.0, 1e9)
        for i in range(len(STREET) - 1):
            (x0, y0), (x1, y1) = STREET[i], STREET[i + 1]
            dx, dy = x1 - x0, y1 - y0
            t = max(0.0, min(1.0, ((px - x0) * dx + (py - y0) * dy) / (dx * dx + dy * dy)))
            dd = math.hypot(px - (x0 + dx * t), py - (y0 + dy * t))
            if dd < best[1]:
                best = (float(cum[i]) + t * seg[i], dd)
        return best
    lanes = []
    for i in range(len(STREET) - 1):
        (x0, y0), (x1, y1) = STREET[i], STREET[i + 1]
        L = seg[i]
        loc = np.linspace(0.0, L, max(2, int(round(L)) + 1))
        lanes.append({"id": "HEJ-RS.%02d" % (i + 1), "from": [x0, y0], "dir": [round((x1 - x0) / L, 6), round((y1 - y0) / L, 6)], "length": round(L, 2),
                      "width": STREET_W, "z_a": round(street_z(cum[i]), 2), "z_b": round(street_z(cum[i + 1]), 2), "flight": None,
                      "profile": [[round(float(t), 2), round(street_z(cum[i] + t), 2)] for t in loc], "street": True})
        face = math.degrees(math.atan2(x1 - x0, y1 - y0)) % 360.0  # its band, which no house takes
        taken.append(rect((x0 + x1) / 2, (y0 + y1) / 2, 2 * STREET_HALF - 0.1, L, face))
    for b in hej:
        if not b.get("pos") or not b.get("footprint") or b["type"] in ("open space", "gardens", "well", "shrine", "stall", "latrine", "sties"):
            continue
        x, y = b["pos"][:2]
        w, d = b["footprint"]
        face = float(b["rot_deg"]) if b.get("rot_deg") is not None else 180.0  # (0, facing north, is a facing)
        th = math.radians(face)
        fx, fy = math.sin(th), math.cos(th)
        zm, zlo, zhi = under(b)
        fs, fd = street_s(x + fx * d / 2, y + fy * d / 2)
        on = b["id"] not in ("HEJ-02", "HEJ-03") and fd < STREET_HALF + FRONTS  # its front on River Street: at its level
        if on:
            zm = street_z(fs)
        pads[b["id"]] = {"level": round(zm, 2)}
        if kit_of(b):
            pads[b["id"]]["kit"] = kit_of(b)
        lines.append("%s %s: level %.1f m (chapter 02: %.0f)%s, its ground %.1f to %.1f m" % (b["id"], b["name_en"].split(" (")[0][:40], zm, b["pos"][2], ", River Street's before its door" if on else "", zlo, zhi))
        taken.append(rect(x, y, w, d, face, CLEAR))
    rnd = random.Random(SEED)
    houses = []
    # F houses along River Street, each side fronting it
    for i in range(len(STREET) - 1):
        (x0, y0), (x1, y1) = STREET[i], STREET[i + 1]
        L = math.hypot(x1 - x0, y1 - y0)
        ux, uy = (x1 - x0) / L, (y1 - y0) / L
        for side in (-1.0, 1.0):
            nx, ny = -uy * side, ux * side  # out from the street to this side
            face = math.degrees(math.atan2(-nx, -ny)) % 360.0  # the front faces the street
            s = 1.0 + rnd.uniform(0.0, 1.5)
            while s < L - 6.5 and sum(1 for h in houses if h["type"] == "F") < N_F:  # (a house within its stretch: at a
                # bend the next stretch's band keeps the inner side's houses out of the street)
                name, w = F_FORMS[rnd.randrange(3)]
                if s + w > L - 0.5:
                    name, w = F_FORMS[0]
                cx = x0 + ux * (s + w / 2) + nx * (STREET_HALF + F_DEPTH / 2)
                cy = y0 + uy * (s + w / 2) + ny * (STREET_HALF + F_DEPTH / 2)
                poly = rect(cx, cy, w, F_DEPTH, face)
                ok = all(inside(WALL, px, py) and min(seg_dist(px, py, WALL[k], WALL[k + 1]) for k in range(len(WALL) - 1)) > 1.5 for px, py in poly)
                ok = ok and all(_sep(poly, t) for t in taken)
                if ok:
                    zs = [float(Z(px, py)) for px, py in poly] + [float(Z(cx, cy))]
                    ok = max(zs) - min(zs) < 6.0  # not over the trench's bank
                if ok:
                    zf = street_z(cum[i] + s + w / 2)  # at the street's level before its door
                    houses.append({"id": "H-HEJ-%02d" % (len(houses) + 1), "type": "F", "kit": name, "pos": [round(cx, 2), round(cy, 2), round(zf, 2)],
                                   "footprint": [w, F_DEPTH], "rot_deg": round(face, 1), "seed": rnd.randint(1, 4 if name != "hejie_f3" else 3)})
                    taken.append(rect(cx, cy, w, F_DEPTH, face, CLEAR))
                    s += w + CLEAR + rnd.uniform(0.0, 1.5)
                else:
                    s += 1.5
    # the rest of the F houses, where the street's frontage has run out (the named buildings take much of it): in the back
    # lanes, fronting north or south, at their ground's median
    tries = 0
    while sum(1 for h in houses if h["type"] == "F") < N_F and tries < 6000:
        tries += 1
        name, w = F_FORMS[rnd.randrange(3)]
        cx, cy = rnd.uniform(-450.0, -225.0), rnd.uniform(-125.0, 2.0)
        face = rnd.choice([180.0, 0.0])
        poly = rect(cx, cy, w, F_DEPTH, face)
        if not all(inside(WALL, px, py) and min(seg_dist(px, py, WALL[k], WALL[k + 1]) for k in range(len(WALL) - 1)) > 1.5 for px, py in poly):
            continue
        if not all(_sep(poly, t) for t in taken):
            continue
        zs = [float(Z(px, py)) for px, py in poly] + [float(Z(cx, cy))]
        if max(zs) - min(zs) > 5.0:
            continue
        houses.append({"id": "H-HEJ-%02d" % (len(houses) + 1), "type": "F", "kit": name, "pos": [round(cx, 2), round(cy, 2), round(float(np.median(zs)), 2)],
                       "footprint": [w, F_DEPTH], "rot_deg": face, "seed": rnd.randint(1, 4 if name != "hejie_f3" else 3)})
        taken.append(rect(cx, cy, w, F_DEPTH, face, CLEAR))
    # G houses in the back lanes: wherever a courtyard house fits, the north part first
    tries = 0
    while sum(1 for h in houses if h["type"] == "G") < N_G and tries < 6000:
        tries += 1
        cx, cy = rnd.uniform(-450.0, -225.0), rnd.uniform(-125.0, 2.0)
        face = rnd.choice([180.0, 0.0])
        poly = rect(cx, cy, G_SIZE[0], G_SIZE[1], face)
        if not all(inside(WALL, px, py) and min(seg_dist(px, py, WALL[k], WALL[k + 1]) for k in range(len(WALL) - 1)) > 1.5 for px, py in poly):
            continue
        if not all(_sep(poly, t) for t in taken) or min(seg_dist(cx, cy, STREET[k], STREET[k + 1]) for k in range(len(STREET) - 1)) < STREET_HALF + G_SIZE[1] / 2:
            continue
        zs = [float(Z(px, py)) for px, py in poly] + [float(Z(cx, cy))]
        if max(zs) - min(zs) > 7.0:
            continue
        houses.append({"id": "H-HEJ-%02d" % (len(houses) + 1), "type": "G", "kit": "hejie_g%d" % rnd.randint(1, 2), "pos": [round(cx, 2), round(cy, 2), round(float(np.median(zs)), 2)],
                       "footprint": list(G_SIZE), "rot_deg": face, "seed": rnd.randint(1, 2)})
        taken.append(rect(cx, cy, G_SIZE[0], G_SIZE[1], face, CLEAR))
    for h in houses:  # the G houses' seeds within their kit's variants
        if h["kit"] == "hejie_g2":
            h["seed"] = 1 + (h["seed"] - 1) % 3
    # the wall: a point a metre along its line, but in the gates' openings
    pts = []
    for k in range(len(WALL) - 1):
        (x0, y0), (x1, y1) = WALL[k], WALL[k + 1]
        n = max(1, int(round(math.hypot(x1 - x0, y1 - y0))))
        for t in range(n):
            x, y = x0 + (x1 - x0) * t / n, y0 + (y1 - y0) * t / n
            gap = next((gid for gid, (gx, gy), half in GAPS if math.hypot(x - gx, y - gy) < half), None)
            pts.append(None if gap else (x, y))
    if None in pts and pts[0] is not None and WALL[0] == WALL[-1]:  # a closed line: begin it at a gate, so the corner it began at is not a break
        k = pts.index(None)
        pts = pts[k:] + pts[:k]
    runs, cur = [], []
    for q in pts + [None]:
        if q is None:
            if len(cur) >= 2:
                runs.append(cur)
            cur = []
        else:
            cur.append(q)
    walls = [{"of": "HEJ-01", "h": WALL_H, "pts": [[round(x, 2), round(y, 2), round(float(Z(x, y)), 2)] for x, y in run]} for run in runs]
    length = sum(len(r["pts"]) for r in walls)
    data = {"about": "Hejie at a distance (M2 sprint 9, step 4), written by tools/town/hejie.py: `pads` its named buildings at the median of their real ground (those fronting River Street at its level), for tools/terrain/pads.py; `walls` its wall HEJ-01, 4 m over the ground it follows, broken for the gates, for tools/town/walls.py; `houses` H-HEJ-01 to 40, F shop-houses along River Street at its level and G courtyard houses in the back lanes at their ground's median (the kit's type in `kit`, its seed), for pads.py and world/town.gd; `lanes` River Street's bed, a lane a stretch, carved by pads.py. Regenerated with the terrain.",
            "street": [list(q) for q in STREET], "lanes": lanes, "pads": pads, "walls": walls, "houses": houses}
    json.dump(data, open(OUT, "w", encoding="utf-8"), indent=1)
    nf = sum(1 for h in houses if h["type"] == "F")
    ng = len(houses) - nf
    rep = ["# Hejie", "", "_Written by `tools/town/hejie.py` (M2 sprint 9, step 4): Hejie's named buildings on the real ground, its wall, its generic houses. Regenerated with the terrain._", "",
           "## The named buildings' levels", ""] + ["- " + ln for ln in lines] + ["", "## The wall", "",
           "HEJ-01: %d m of dry stone, %.0f m over the ground it follows, in %d runs between the East Gate, the Water Gate and the postern (chapter 02: about 720 m)." % (length, WALL_H, len(walls)), "",
           "## River Street", "", "%.0f m from the East Gate (%.1f m) down to the Water Gate (%.1f m) in %d stretches, %.1f m wide between the fronts; its steepest stretch %.0f%% over 10 m, its bed at most %.1f m off the ground it follows." % (
               total, bed[0], bed[-1], len(lanes), 2 * STREET_HALF, 100.0 * max(abs(street_z(t + 10.0) - street_z(t)) / 10.0 for t in np.arange(0.0, total - 10.0, 1.0)), float(np.max(np.abs(bed - ground)))), "",
           "## The houses", "", "%d F shop-houses along River Street, %d G courtyard houses in the back lanes (chapter 02: 32 and 8)." % (nf, ng), "",
           "| House | Kit | x, y | Level | Facing |", "|---|---|---|---|---|"]
    rep += ["| %s | %s_v%d | %.0f, %.0f | %.1f | %03.0f |" % (h["id"], h["kit"], h["seed"], h["pos"][0], h["pos"][1], h["pos"][2], h["rot_deg"]) for h in houses]
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("hejie: %d named pads, %d m of wall, %d F and %d G houses -> %s" % (len(pads), length, nf, ng, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
