#!/usr/bin/env python3
"""The Shade Wood SER-16 (M2 sprint 12, step 4; plan chapter 02, D09: "the south ridge above the slot, about 40 ha:
larch, birch, spruce, fir; firewood"; chapter 11, 5.2 and 13.1: one tree to 25 m², baked, never at start-up): its trees
scattered on the built ground in two stands, the shaded bank above the Serchu road from the gallery to the Zampa (from
the road's uphill edge to BANK metres up the slope) and the south rim above the Samkha slot, the north edge of its
plateau that the town sees (RIM), kept out of V-01's view west over the town (tools/terrain/arrival.py's cone, wider).
A jittered grid every SPACING metres, each point kept by a slow noise that makes groves and clearings, thinner along the
road's verge; never on a road, a ramp or a path, within reach of a building, a thing by the road or a river's water, nor
on ground steeper than STEEP. Each tree its kind by a second noise (conifers higher up the bank, birch along the road and
on the rim, a maple here and there), its variant, turn and size.
Run: tools/py tools/town/forest.py   Writes assets/generated/terrain/forest.json (world/forest.gd draws it) and
docs/terrain/forest-report.md (tools/terrain/build.sh runs it after the rivers).
"""
import json
import math
import os
import random
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
from terrain_site import Site  # noqa: E402
import pads as P  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
OUT = os.path.join(GEN, "forest.json")
REPORT = os.path.join(ROOT, "docs", "terrain", "forest-report.md")
SEED = 1916  # the wood's own
SPACING = 6.5  # a tree to about 42 m² where the noise keeps them all
BANK = (7.0, 230.0)  # the bank's stand: metres from the road's line up the slope
RIM = (-150.0, 440.0, -430.0, -165.0)  # the rim's stand: x from, to, y from, to
V01_CONE = (250.0, 310.0, 420.0)  # V-01's view kept clear: bearings from, to, out to (metres)
STEEP = 40.0  # degrees
KINDS = {"larch": 3, "spruce": 2, "fir": 2, "birch": 2, "maple": 1}  # each kind's variants (../tibet-blender export_types.py)
CUTTERS = ((760.0, -360.0), (840.0, -425.0), (905.0, -455.0))  # near where the woodcutters work (step 6), above the road
CUT_UP = (12.0, 40.0)  # metres up the bank from the road's line


def _noise(rng, X, Y, cell):
    """A smooth noise 0..1 over (X, Y): random values on a lattice `cell` apart, read bilinearly."""
    x0, y0 = X.min() - cell, Y.min() - cell
    nx, ny = int((X.max() - x0) / cell) + 3, int((Y.max() - y0) / cell) + 3
    lat = rng.random((ny, nx))
    fx, fy = (X - x0) / cell, (Y - y0) / cell
    i, j = np.floor(fy).astype(int), np.floor(fx).astype(int)
    ty, tx = fy - i, fx - j
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    return (lat[i, j] * (1 - tx) + lat[i, j + 1] * tx) * (1 - ty) + (lat[i + 1, j] * (1 - tx) + lat[i + 1, j + 1] * tx) * ty


def _seg_dist(X, Y, a, b):
    """Distance from (X, Y) to the segment a-b, and the signed lateral offset (left of a->b positive)."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    L2 = max(dx * dx + dy * dy, 1e-9)
    t = np.clip(((X - a[0]) * dx + (Y - a[1]) * dy) / L2, 0.0, 1.0)
    px, py = a[0] + t * dx, a[1] + t * dy
    d = np.hypot(X - px, Y - py)
    side = ((X - a[0]) * -dy + (Y - a[1]) * dx) / math.sqrt(L2)
    return d, side, t


def _line_dist(X, Y, line):
    """Distance to a polyline, the signed offset at its nearest point and whether that point is past its ends."""
    D = np.full(X.shape, np.inf)
    S = np.zeros(X.shape)
    inner = np.zeros(X.shape, bool)
    for k, (a, b) in enumerate(zip(line[:-1], line[1:])):
        d, side, t = _seg_dist(X, Y, a, b)
        nearer = d < D
        D = np.where(nearer, d, D)
        S = np.where(nearer, side, S)
        end = ((k == 0) & (t <= 0.0)) | ((k == len(line) - 2) & (t >= 1.0))
        inner = np.where(nearer, ~end, inner)
    return D, S, inner


def _rects_mask(X, Y, lanes, grow):
    m = np.zeros(X.shape, bool)
    for ln in lanes:
        (fx, fy), (ux, uy) = ln["from"], ln["dir"]
        sl = (X - fx) * ux + (Y - fy) * uy
        lat = -(X - fx) * uy + (Y - fy) * ux
        m |= (sl >= -grow) & (sl <= ln["length"] + grow) & (np.abs(lat) <= ln["width"] / 2 + grow)
    return m


def main():
    site = Site.load()
    g = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    rng = np.random.default_rng(SEED)
    sr = json.load(open(os.path.join(ROOT, "data", "serchu_road.json"), encoding="utf-8"))
    arr = json.load(open(os.path.join(ROOT, "data", "arrival.json"), encoding="utf-8"))
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    rivers = json.load(open(os.path.join(ROOT, "data", "rivers.json"), encoding="utf-8"))["rivers"]
    xs = np.arange(-150.0, 1260.0, SPACING)
    ys = np.arange(-700.0, -150.0, SPACING)
    X, Y = np.meshgrid(xs, ys)
    X = X + rng.uniform(-0.42, 0.42, X.shape) * SPACING
    Y = Y + rng.uniform(-0.42, 0.42, Y.shape) * SPACING
    Z = g.z(X, Y) - site.shift
    # the two stands
    dl, side, inner = _line_dist(X, Y, sr["line"])
    up = side  # the road runs down the river, west: its uphill side is its left, the south
    bank = (up >= BANK[0]) & (up <= BANK[1]) & inner & (X >= 440.0)
    rim = (X >= RIM[0]) & (X <= RIM[1]) & (Y >= RIM[2]) & (Y <= RIM[3])
    ex, ey = arr["v01"]["eye"][0], arr["v01"]["eye"][1]
    bear = np.degrees(np.arctan2(X - ex, Y - ey)) % 360.0
    rim &= ~((bear >= V01_CONE[0]) & (bear <= V01_CONE[1]) & (np.hypot(X - ex, Y - ey) <= V01_CONE[2]))
    keep = bank | rim
    # both on the south side of the water: the Serchu's line and the slot's below the confluence (the rim's box had reached
    # over the river onto the north bank by the mills, M2 sprint 12, step 5)
    water = [q[:2] for name in ("Serchu", "Samkha slot") for rv in rivers if rv["name"] == name for q in rv["pts"]]
    keep &= _line_dist(X, Y, water)[1] > 3.0  # (left of downstream: the south)
    # never on a road, a ramp, a path, by a building or a thing, in a river's water or on a crag
    keep &= ~_rects_mask(X, Y, P.ramp_lanes(), 5.0)
    for line in (arr["road_west"], arr["road_east"]):
        keep &= _line_dist(X, Y, line)[0] > 7.0
    keep &= _line_dist(X, Y, [arr["gallery"]["from"], arr["gallery"]["to"]])[0] > 9.0
    for path in sr.get("paths", []):
        keep &= _line_dist(X, Y, path)[0] > 3.0
    spots = [q["at"] for q in list(sr.get("places", {}).values()) + list(sr.get("pads", {}).values()) + list(sr.get("things", []))]
    for b in town["buildings"]:
        p, fp = b.get("pos"), b.get("footprint")
        if p and fp and -200.0 < p[0] < 1300.0 and -720.0 < p[1] < -100.0:
            spots.append([p[0], p[1], max(fp) / 2.0])
    for q in spots:
        r = (float(q[2]) if len(q) > 2 else 0.0) + 7.0
        keep &= np.hypot(X - float(q[0]), Y - float(q[1])) > r
    for rv in rivers:
        pts = rv["pts"]
        line = [[q[0], q[1]] for q in pts]
        wet = max(max(float(q[3]), float(q[4])) for q in pts) if len(pts[0]) > 4 else 8.0
        keep &= _line_dist(X, Y, line)[0] > wet + 3.0
    gy, gx = np.gradient(g.z(X, Y) - site.shift, SPACING)
    slope = np.degrees(np.arctan(np.hypot(gx, gy)))
    keep &= (slope <= STEEP) & np.isfinite(Z)
    # groves and clearings; the road's verge thin
    n1 = _noise(rng, X, Y, 38.0)
    n2 = _noise(rng, X, Y, 52.0)
    dens = 0.15 + 0.85 * np.clip((n1 - 0.28) / 0.4, 0.0, 1.0)
    dens = np.where(bank & (up < 22.0), dens * 0.45, dens)
    keep &= rng.random(X.shape) < dens
    trees, counts = [], {k: 0 for k in KINDS}
    pyr = random.Random(SEED)
    for x, y, z, b_, u, nn in zip(X[keep], Y[keep], Z[keep], bank[keep], up[keep], n2[keep]):
        if b_:
            w = {"larch": 58.0, "spruce": 12.0, "fir": 8.0, "birch": 18.0, "maple": 4.0} if u < 120.0 else \
                {"larch": 45.0, "spruce": 26.0, "fir": 16.0, "birch": 9.0, "maple": 4.0}
        else:
            w = {"larch": 55.0, "spruce": 10.0, "fir": 5.0, "birch": 25.0, "maple": 5.0}
        w["larch"] *= 0.6 + 1.2 * nn  # larch stands and conifer groves by the second noise
        w["spruce"] *= 1.6 - 1.2 * nn
        w["fir"] *= 1.6 - 1.2 * nn
        kind = pyr.choices(list(w), list(w.values()))[0]
        counts[kind] += 1
        trees.append([kind, pyr.randint(1, KINDS[kind]), round(float(x), 2), round(float(y), 2), round(float(z) - 0.25, 2),
                      round(pyr.uniform(0.0, 360.0), 1), round(pyr.uniform(0.82, 1.18), 3)])
    # the woodcutters (M2 sprint 12, step 6; ISS-180): at work by a tree a little up the bank from the road where its
    # slope is easy, each with the path he has trodden down to the road; the trees between him and the road left standing
    cutters, cut_paths = [], []
    road_line = sr["line"]
    for k, (cx, cy) in enumerate(CUTTERS):
        best = None
        for t in trees:
            if t[0] not in ("larch", "birch", "spruce"):
                continue
            d, sd, inner_ = (float(v) for v in (lambda r: (r[0][0], r[1][0], r[2][0]))(_line_dist(np.array([t[2]]), np.array([t[3]]), road_line)))
            if not (CUT_UP[0] <= sd <= CUT_UP[1]) or math.hypot(t[2] - cx, t[3] - cy) > 60.0:
                continue
            gx_ = (float(g.z(t[2] + 1.5, t[3])) - float(g.z(t[2] - 1.5, t[3]))) / 3.0
            gy_ = (float(g.z(t[2], t[3] + 1.5)) - float(g.z(t[2], t[3] - 1.5))) / 3.0
            if math.degrees(math.atan(math.hypot(gx_, gy_))) > 30.0:
                continue
            score = math.hypot(t[2] - cx, t[3] - cy) + abs(sd - (CUT_UP[0] + CUT_UP[1]) / 2)
            if best is None or score < best[0]:
                best = (score, t, gx_, gy_)
        if best is None:
            continue
        _, t, gx_, gy_ = best
        # he stands on the tree's downhill side, facing it
        gl = max(math.hypot(gx_, gy_), 1e-6)
        sx_, sy_ = t[2] - gx_ / gl * 1.1, t[3] - gy_ / gl * 1.1
        cutters.append({"at": [round(sx_, 2), round(sy_, 2), round(float(g.z(sx_, sy_)) - site.shift, 2)], "tree": [t[2], t[3]],
                        "facing": round(math.degrees(math.atan2(t[2] - sx_, t[3] - sy_)) % 360.0, 1)})
        # his path: down the slope to the road, a zig where it is steep (straight on the plan; control.py paints it)
        best_r = min(road_line, key=lambda q: math.hypot(q[0] - sx_, q[1] - sy_))
        mid = ((sx_ + best_r[0]) / 2 + 4.0, (sy_ + best_r[1]) / 2)
        cut_paths.append([[round(sx_, 2), round(sy_, 2)], [round(mid[0], 2), round(mid[1], 2)], [round(best_r[0], 2), round(best_r[1], 2)]])
    # the trees on his path and close round him (cut, not grown back) taken out
    def on_path(x, y):
        for path_ in cut_paths:
            for (ax_, ay_), (bx_, by_) in zip(path_[:-1], path_[1:]):
                dx_, dy_ = bx_ - ax_, by_ - ay_
                L2_ = dx_ * dx_ + dy_ * dy_ or 1e-9
                tt = max(0.0, min(1.0, ((x - ax_) * dx_ + (y - ay_) * dy_) / L2_))
                if math.hypot(ax_ + dx_ * tt - x, ay_ + dy_ * tt - y) < 2.5:
                    return True
        return any(math.hypot(c_["at"][0] - x, c_["at"][1] - y) < 2.0 and (abs(c_["tree"][0] - x) > 0.01 or abs(c_["tree"][1] - y) > 0.01) for c_ in cutters)
    before = len(trees)
    trees = [t for t in trees if not on_path(t[2], t[3])]
    for kind in counts:
        counts[kind] = sum(1 for t in trees if t[0] == kind)
    area = float(keep.size) * SPACING * SPACING
    stand_ha = float((bank | rim).sum()) * SPACING * SPACING / 1e4
    json.dump({"about": "The Shade Wood SER-16 (tools/town/forest.py; M2 sprint 12, step 4): each tree [kind, variant, x, y, z (its foot, the town grid), turn (degrees), size]; world/forest.gd draws them in MultiMeshes by 256 m cell, three levels of detail; `cutters` the woodcutters' places at work by a tree [at, tree, facing] and `paths` theirs down to the road, painted trodden by tools/terrain/control.py (step 6). Regenerated with the terrain.",
               "trees": trees, "cutters": cutters, "paths": cut_paths}, open(OUT, "w"), separators=(",", ":"))
    rep = ["# The Shade Wood SER-16", "",
           "_Written by `tools/town/forest.py` (M2 sprint 12, step 4; plan chapter 02, D09; chapter 11, 5.2): its trees on the built ground, the bank above the Serchu road and the south rim above the slot, out of V-01's view west; drawn by `world/forest.gd`._", "",
           "%d trees on about %.0f ha of stand (%.0f m² a tree there): %s." % (len(trees), stand_ha, stand_ha * 1e4 / max(len(trees), 1), ", ".join("%s %d" % kv for kv in counts.items())), ""]
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep))
    print("forest: %d trees on about %.0f ha (%s) -> %s" % (len(trees), stand_ha, ", ".join("%s %d" % kv for kv in counts.items()), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
