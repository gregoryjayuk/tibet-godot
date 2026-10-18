#!/usr/bin/env python3
"""Samkha's rim (M2 sprint 11, step 4; plan chapter 02, SAM-11 and SAM-12; chapter 03, 5.1): where the slot's face takes
the Leat Fall and the latrine's midden, on the built ground (valley_padded_1m.tif, in the design's heights).

- The Leat Fall SAM-11 ("the Shöl leat falls into the slot", 30 m drop): the slot's north rim between the castle and the
  Yak Gate is a rock lip a few metres higher than the ground behind it, so the leat comes through it in a culvert and
  spouts from the face below the lip (the kit's sam11_leat_outlet), at LEAT_X: west of Samkha's north ramp, whose legs
  now hold chapter 02's spot (-70, -82). The outlet where the face stands OUTLET_BELOW under its top; the water leaves
  the lip and falls in an arc (THROW out over the drop), kept CLEAR off the face, to the slot's river (data/rivers.json).
- The latrine's ledge midden SAM-12: the castle's latrine bay hangs from its fifth storey at the south face's west end
  (the kit's u -6.9: x -136.9); its drop lands on a ledge MIDDEN_BELOW under the rim, "not in the torrent" (the klu).
Run: tools/py tools/town/samkha_rim.py   Writes data/samkha_rim.json (tools/terrain/build.sh runs it after the rivers).
"""
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
from terrain_site import Site  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
OUT = os.path.join(ROOT, "data", "samkha_rim.json")
RIVERS = os.path.join(ROOT, "data", "rivers.json")
LEAT_X = -86.0  # the fall's line: between the 1861 breach (x -101 to -89) and the north ramp's west landings (x -79)
OUTLET_BELOW = 6.0  # metres under the face's top edge the culvert comes out
THROW = 0.9  # metres a second the water leaves the lip, out over the drop
CLEAR = 0.45  # the falling water kept this far off the face
LATRINE_X = -136.9  # the latrine's column (the castle at -130, its bay at the kit's u -6.9)
MIDDEN_BELOW = 8.0  # metres under the rim's top edge its ledge


def face(Z, x, y0=-90.0, y1=-115.0, step=0.1):
    """The slot's north face at x: (ys, zs) southwards from y0, and the top of its edge (the highest point before the
    ground falls away)."""
    ys = np.arange(y0, y1, -step)
    zs = np.array([Z(x, y) for y in ys])
    top = int(np.argmax(zs))
    return ys, zs, top


def at_level(ys, zs, top, z):
    """The first y south of the face's top where the ground is at z."""
    for i in range(top, len(ys) - 1):
        if zs[i] >= z > zs[i + 1]:
            f = (zs[i] - z) / (zs[i] - zs[i + 1])
            return float(ys[i] + (ys[i + 1] - ys[i]) * f)
    return float(ys[-1])


def main():
    site = Site.load()
    g = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    Z = lambda x, y: float(g.z(np.array([x]), np.array([y]))[0]) - site.shift  # noqa: E731
    # the Leat Fall
    ys, zs, top = face(Z, LEAT_X)
    z_out = float(zs[top]) - OUTLET_BELOW
    y_out = at_level(ys, zs, top, z_out)
    river = next(r for r in json.load(open(RIVERS, encoding="utf-8"))["rivers"] if r["name"] == "Samkha slot")
    near = min(river["pts"], key=lambda q: abs(q[0] - LEAT_X))
    z_water, y_river = float(near[2]), float(near[1])
    lip = (LEAT_X, y_out - 0.75, z_out + 0.24)  # the kit's LIP socket off the outlet's face
    path, t = [list(lip)], 0.0
    while True:  # the arc, kept off the face, until the water's level
        t += 0.05
        z = lip[2] - 4.905 * t * t
        y = lip[1] - THROW * t
        if z <= z_water:
            break
        y_face = at_level(ys, zs, top, z) if z < zs[top] else ys[top]
        y = min(y, y_face - CLEAR)
        if not path or abs(path[-1][2] - z) >= 0.75:
            path.append([LEAT_X, round(y, 2), round(z, 2)])
    foot = [LEAT_X, round(max(min(path[-1][1] - 0.3, y_river + 2.0), y_river - 1.0), 2), round(z_water, 2)]
    path.append(foot)
    # the midden's ledge
    ys2, zs2, top2 = face(Z, LATRINE_X, -94.0, -112.0)
    z_m = float(zs2[top2]) - MIDDEN_BELOW
    y_m = at_level(ys2, zs2, top2, z_m)
    data = {"about": "Samkha's rim (M2 sprint 11, step 4), written by tools/town/samkha_rim.py from the built ground: `leat_fall` the Leat Fall SAM-11, its `outlet` (x, y, the design's height, facing: the kit's sam11_leat_outlet set into the slot's face, its back into the rock), its water's `path` from the lip to the slot's river and its `foot` there, its `drop`; `midden` SAM-12's ledge under the castle's latrine bay (x, y, height, facing: the kit's sam12_midden). Placed by world/town.gd, the water drawn by world/leat_fall.gd. Regenerated with the terrain.",
            "leat_fall": {"outlet": [LEAT_X, round(y_out, 2), round(z_out, 2), 180.0], "path": [[round(v, 2) for v in q] for q in path],
                          "foot": foot, "drop": round(lip[2] - z_water, 2)},
            "midden": [LATRINE_X, round(y_m, 2), round(z_m, 2), 180.0]}
    json.dump(data, open(OUT, "w", encoding="utf-8"), indent=1)
    print("samkha_rim: the Leat Fall's outlet at (%.1f, %.1f) %.1f m, %.0f m over the slot's water (%d points); the midden at (%.1f, %.1f) %.1f m -> %s" % (
        LEAT_X, y_out, z_out, lip[2] - z_water, len(path), LATRINE_X, y_m, z_m, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
