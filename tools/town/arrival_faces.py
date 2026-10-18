#!/usr/bin/env python3
"""The arrival's rock faces sampled from the built ground (M2 sprint 3, step 2; ISS-047: "the slot's walls are to become
rock meshes over holes in the heightfield"): cross-sections of valley_padded_1m every metre along the cliff gallery's
line (from the water's bank up over the rock's crest) and along R-01's cutting through the nose (both its walls), in each
line's own frame (y along it from its start, x to the right of a westbound walker, z over the start's level), for the
kit's rock_face (../tibet-blender export_arrival.py) to dress with strata and joints a little proud of the ground, so the
heightfield's stretched faces are hidden under rock.
Run: tools/py tools/town/arrival_faces.py   Writes assets/generated/terrain/arrival_faces.json (tools/terrain/build.sh
runs it after pads.py).
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
OUT = os.path.join(GEN, "arrival_faces.json")
STEP = 1.0  # metres between the sections along a line
DX = 0.5  # and between a section's points


def sections(zf, a, b, x_from, x_to, z0):
    """Cross-sections of the ground along a -> b: [[y, [[x, z], ...]], ...] in the line's frame."""
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    rx, ry = uy, -ux  # right of the walker from a to b
    out = []
    xs = np.arange(x_from, x_to + 1e-6, DX)
    for y in np.arange(0.0, L + 1e-6, STEP):
        px, py = a[0] + ux * y, a[1] + uy * y
        zs = zf(px + rx * xs, py + ry * xs) - z0
        out.append([round(float(y), 2), [[round(float(x), 2), round(float(z), 3)] for x, z in zip(xs, zs)]])
    return {"from": [a[0], a[1], z0], "dir": [round(ux, 6), round(uy, 6)], "length": round(L, 3), "sections": out}


def main():
    site = Site.load()
    g = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    zf = lambda x, y: np.asarray(g.z(x, y), np.float64) - site.shift
    arr = json.load(open(os.path.join(ROOT, "data", "arrival.json"), encoding="utf-8"))
    ga, gb = arr["gallery"]["from"], arr["gallery"]["to"]
    road = arr["road_west"]
    # the cutting: from the gallery's west end to the chorten's east side (the road's next vertex)
    k = next(i for i, p in enumerate(road) if abs(p[0] - gb[0]) < 0.01 and abs(p[1] - gb[1]) < 0.01)
    ca, cb = road[k], road[k + 1]
    faces = {"about": "The arrival's rock faces (tools/town/arrival_faces.py): cross-sections of the built ground every %.1f m along the cliff gallery and R-01's cutting through the nose, x to the right of a westbound walker, z over the line's start, for the kit's rock_face (../tibet-blender export_arrival.py)." % STEP,
             "gallery": sections(zf, ga, gb, -7.0, 15.0, ga[2]),
             "cutting": sections(zf, ca, cb, -16.0, 18.0, ca[2])}
    json.dump(faces, open(OUT, "w", encoding="utf-8"))
    print("arrival_faces: the gallery %d sections, the cutting %d -> %s" % (len(faces["gallery"]["sections"]), len(faces["cutting"]["sections"]), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
