#!/usr/bin/env python3
"""Samkha's check (M2 sprint 4, step 1): on the built ground (VALLEY, default valley_padded_1m), the chain bridge's deck
over its ground every 2 m (the clearance where it is carried, the water's depth below it), the ward's level, and V-10's
frame from the deck's middle (chapter 08, V-10: up the slot at 087 degrees the lower bridge about 75 m off and some 20 m
lower, the Conch Fall's spray beyond; down it at 260 the fan, Hejie's East Gate and the Yalong; ahead the castle).
Run: tools/py tools/terrain/samkha_check.py   Writes docs/terrain/samkha-report.md.
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
REPORT = os.path.join(ROOT, "docs", "terrain", "samkha-report.md")
VALLEY = os.environ.get("VALLEY", "valley_padded_1m")
TARGETS = [("the lower bridge's deck", "SAM-05", 0.5), ("the Conch Fall", "SAM-13", 2.0), ("Hejie's East Gate", "HEJ-02", 8.0),
           ("the Water Gate", "HEJ-03", 8.0), ("the castle's parapet", "SAM-01", 18.0), ("the Yak Gate", "SAM-07", 3.6)]


def main():
    site = Site.load()
    g = site.read(os.path.join(GEN, VALLEY + ".tif"))
    zf = lambda x, y: float(g.z(x, y)) - site.shift
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    pos = {b["id"]: b["pos"] for b in town["buildings"] if b.get("pos") and not isinstance(b["pos"][0], str) and b["pos"][2] is not None}
    sk = json.load(open(os.path.join(ROOT, "data", "samkha.json"), encoding="utf-8"))
    br = sk["bridge"]
    bx = br["x"]
    deck = np.array(br["deck"])
    dz = lambda y: float(np.interp(-y, -deck[:, 0], deck[:, 1]))
    out = ["# Samkha's check: the chain bridge, the ward and V-10", "",
           "_Written by `tools/terrain/samkha_check.py` from `%s` (M2 sprint 4, step 1). The ground was shaped by `tools/terrain/samkha.py` (pass 5d of `pads.py`); the bridge's line and deck from `data/samkha.json`._" % VALLEY, "",
           "## The chain bridge over its ground", "", "| y | Deck | Ground under it | Clear |", "|---|---|---|---|"]
    worst = 99.0
    low = (0.0, 9999.0)
    for y in np.arange(br["north"][0], br["south"][0] - 0.1, -2.0):
        d, gz = dz(y), zf(bx, y)
        if br["north"][0] - 2.0 > y > br["south"][0] + 2.0:
            worst = min(worst, d - gz)
        if gz < low[1]:
            low = (y, gz)
        out.append("| %.0f | %.1f | %.1f | %.1f m |" % (y, d, gz, d - gz))
    ward = sk["ward"]
    wz = [zf(x, y) for x in np.linspace(ward["x"][0] + 1, ward["x"][1] - 1, 9) for y in np.linspace(ward["y"][0] + 1, ward["y"][1] - 1, 7)]
    ey = (br["north"][0] + br["south"][0]) / 2.0
    ex, ez = bx, dz(ey) + 1.6
    out += ["", "The deck stands at least %.1f m over the ground between its abutments, %.0f m over the water at its lowest (%.1f m at y %.0f); the ward lies at %.1f-%.1f m." % (worst, dz(low[0]) - low[1], low[1], low[0], min(wz), max(wz)),
            "", "## V-10 from the deck's middle", "", "_The eye at (%.0f, %.1f, %.1f m)._" % (ex, ey, ez), "",
            "| Looking at | Bearing | Distance | Angle | The ground between, at its highest | |", "|---|---|---|---|---|---|"]
    seen = {}
    for name, pid, over in TARGETS:
        if pid not in pos:
            continue
        tx, ty, tz = pos[pid]
        tz = float(tz) + over
        if pid == "SAM-05":
            tz = 2624.1 + over  # the built deck
        if pid == "SAM-01":  # the castle as built, on the rim (M2 sprint 4, step 4): its parapet 19.3 m over the ward
            tx, ty = sk["castle"]["at"]
            tz = float(sk["castle"]["z"]) + 19.3
        dist = math.hypot(tx - ex, ty - ey)
        ang = math.degrees(math.atan2(tz - ez, dist))
        brg = math.degrees(math.atan2(tx - ex, ty - ey)) % 360.0
        hi, at = -90.0, 0.0
        for s in np.arange(3.0, dist - 6.0, 1.0):
            a = math.degrees(math.atan2(zf(ex + (tx - ex) * s / dist, ey + (ty - ey) * s / dist) - ez, s))
            if a > hi:
                hi, at = a, s
        ok = hi < ang - 0.05
        seen[name] = ok
        out.append("| %s | %.0f° | %.0f m | %+.1f° | %+.1f° at %.0f m | %s |" % (name, brg, dist, ang, hi, at, "seen" if ok else "**hidden**"))
    out += ["", "**Summary:** the deck clears its ground by %.1f m at least between its abutments and stands %.0f m over the water; V-10 sees %d of %d (%s hidden)." % (
        worst, dz(low[0]) - low[1], sum(seen.values()), len(seen), ", ".join(k for k, v in seen.items() if not v) or "none")]
    open(REPORT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print(out[-1])


if __name__ == "__main__":
    main()
