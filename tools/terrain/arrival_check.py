#!/usr/bin/env python3
"""The arrival's check (M2 sprint 3, step 1; ISS-138): on the built ground (VALLEY, default valley_padded_1m), what V-01
sees (chapter 02's frame: the chain bridge, the south pavilion, Samkha Khar, Tsongra, the lower bridge, Hejie's East
Gate, the Tödé tower, and turning right and up the monastery's South Gate and Tsokchen at 052 degrees), each target's
angle from the eye and the highest the ground between rises; the cliff gallery's deck against its rock (the ground under
its outer edge, the rock over its inner edge, the water below); whether the town stays hidden from R-01's cutting
until the Gate Chorten; and the road's grades (data/arrival.json, data/south_ramp.json).
Run: tools/py tools/terrain/arrival_check.py   Writes docs/terrain/arrival-report.md.
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
REPORT = os.path.join(ROOT, "docs", "terrain", "arrival-report.md")
VALLEY = os.environ.get("VALLEY", "valley_padded_1m")
# V-01's frame (chapter 02, V-01): [what, the gazetteer's id or a point (x, y, z), metres over its ground to look at]
TARGETS = [("the chain bridge", "SAM-03", 1.0), ("the south pavilion", "SAM-04", 5.0), ("Samkha Khar (its top)", "SAM-01", 24.0),
           ("Tsongra", "TSONGRA", 1.5), ("the lower bridge", "SAM-05", 1.0), ("Hejie's East Gate", "HEJ-02", 8.0),
           ("the Tödé tower", "TOD-01", 12.0)]
TURN = [("the monastery's South Gate", "MON-17", 6.0), ("the Tsokchen's roof", "MON-40", 0.0)]


def main():
    site = Site.load()
    g = site.read(os.path.join(GEN, VALLEY + ".tif"))
    zf = lambda x, y: float(g.z(x, y)) - site.shift
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    pos = {b["id"]: b["pos"] for b in town["buildings"] if b.get("pos") and b["pos"][2] is not None}
    pos["TSONGRA"] = [0.0, 0.0, 2662.0]
    arr = json.load(open(os.path.join(ROOT, "data", "arrival.json"), encoding="utf-8"))
    ex, ey, ez = arr["v01"]["eye"]
    out = ["# The arrival's check: the ground south of the slot", "",
           "_Written by `tools/terrain/arrival_check.py` from `%s` (M2 sprint 3, step 1; ISS-138). Angles are from V-01's eye at (%+.0f, %+.0f, %.1f m) on the Gate Chorten's west side; a target is seen when the ground between stays under the line to it. The ground was shaped by `tools/terrain/arrival.py` (pass 5c of `pads.py`)._" % (VALLEY, ex, ey, ez), "",
           "## V-01", "", "| Looking at | Bearing | Distance | Angle | The ground between, at its highest | |", "|---|---|---|---|---|---|"]
    seen = {}
    for name, pid, over in TARGETS + TURN:
        tx, ty, tz = pos[pid]
        tz = float(tz) + over
        dist = math.hypot(tx - ex, ty - ey)
        ang = math.degrees(math.atan2(tz - ez, dist))
        brg = math.degrees(math.atan2(tx - ex, ty - ey)) % 360.0
        worst, at = -90.0, 0.0
        for s in np.arange(3.0, dist - 6.0, 1.0):
            q = (ex + (tx - ex) * s / dist, ey + (ty - ey) * s / dist)
            a = math.degrees(math.atan2(zf(*q) - ez, s))
            if a > worst:
                worst, at = a, s
        ok = worst < ang - 0.05
        seen[name] = ok
        out.append("| %s | %.0f° | %.0f m | %+.1f° | %+.1f° at %.0f m | %s |" % (name, brg, dist, ang, worst, at, "seen" if ok else "**hidden**"))
    out += ["", "## The cliff gallery", "",
            "_Every 15 m from its east end: the deck's level; the ground under its outer edge (0.9 m out) and the rock over its inner edge 2.5 m in; the water's line, how far and how far down._", "",
            "| Along | Deck | Under its outer edge | The rock 2.5 m in | The water |", "|---|---|---|---|---|"]
    a, b = arr["gallery"]["from"], arr["gallery"]["to"]
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    nx, ny = uy, -ux  # right of the westbound walker: the water's side
    cp = {k: v["pos"] for k, v in town["control"].items() if "pos" in v}
    river = [cp[k] for k in ("S1", "S0", "C")]
    worst_under, worst_rock = 99.0, 99.0
    for s in np.arange(0.0, L + 0.1, 15.0):
        px, py = a[0] + ux * s, a[1] + uy * s
        deck = a[2] + (b[2] - a[2]) * s / L
        under = deck - zf(px + nx * 0.9, py + ny * 0.9)
        rock = zf(px - nx * 3.5, py - ny * 3.5) - deck
        best = (1e9, 0.0)
        for (x0, y0, z0), (x1, y1, z1) in zip(river[:-1], river[1:]):
            for f in np.linspace(0.0, 1.0, 200):
                d = math.hypot(x0 + (x1 - x0) * f - px, y0 + (y1 - y0) * f - py)
                if d < best[0]:
                    best = (d, z0 + (z1 - z0) * f)
        if 5.0 < s < L - 5.0:
            worst_under, worst_rock = min(worst_under, under), min(worst_rock, rock)
        out.append("| %.0f m | %.1f | %.1f m below | %+.1f m | %.0f m off, %.1f m below |" % (s, deck, under, rock, best[0], deck - best[1]))
    out += ["", "## Hidden until the Gate Chorten", "", "_From R-01 (an eye 1.6 m over the road), whether Tsongra is in sight: it should not be until the chorten._", ""]
    road = arr["road_west"]
    sights = []
    for (x0, y0, z0), (x1, y1, z1) in zip(road[:-1], road[1:]):
        seg = math.hypot(x1 - x0, y1 - y0)
        for f in np.linspace(0.0, 1.0, max(2, int(seg / 8.0))):
            px, py, pz = x0 + (x1 - x0) * f, y0 + (y1 - y0) * f, z0 + (z1 - z0) * f + 1.6
            if px > 300.0 or px < 150.0:
                continue
            dist = math.hypot(px, py)
            ang = math.atan2(2663.5 - pz, dist)
            vis = all(zf(px - px * s / dist, py - py * s / dist) < pz + math.tan(ang) * s - 0.05 for s in np.arange(3.0, dist - 10.0, 2.0))
            sights.append((px, py, vis))
    first = next(((x, y) for x, y, v in sights if v), None)
    out.append("Tsongra first comes into sight at (%+.0f, %+.0f)%s." % ((first[0], first[1], ", %.0f m before the chorten" % math.hypot(first[0] - 170.0, first[1] + 175.0)) if first else (0, 0, " nowhere")))
    out += ["", "## The road's grades", ""]
    for name, line in (("R-01 westbound", road), ("R-01 eastbound", arr["road_east"])):
        gr = []
        for (x0, y0, z0), (x1, y1, z1) in zip(line[:-1], line[1:]):
            d = math.hypot(x1 - x0, y1 - y0)
            if d > 0.5:
                gr.append(abs(z1 - z0) / d * 100.0)
        out.append("- %s: %.0f m, the steepest stretch %.1f%%." % (name, sum(math.hypot(q[0] - p[0], q[1] - p[1]) for p, q in zip(line[:-1], line[1:])), max(gr)))
    sr = os.path.join(ROOT, "data", "south_ramp.json")
    if os.path.exists(sr):
        s = json.load(open(sr, encoding="utf-8"))
        out.append("- The south ramp (R-02, SAM-06 south): from %.1f m before the south pavilion to %.2f m at the lower bridge's south end, its legs at %.1f%%." % (s["top"][2], s["foot"][2], s["grade"] * 100.0))
    out += ["", "**Summary:** V-01 sees %d of its %d targets (%s hidden); the gallery's deck stands at least %.1f m over the ground under its outer edge, its rock at least %+.1f m over the deck 2.5 m in; Tsongra %s." % (
        sum(seen.values()), len(seen), ", ".join(k for k, v in seen.items() if not v) or "none", worst_under, worst_rock,
        "comes into sight %.0f m before the chorten" % math.hypot(first[0] - 170.0, first[1] + 175.0) if first else "stays hidden along the road")]
    open(REPORT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print(out[-1])


if __name__ == "__main__":
    main()
