#!/usr/bin/env python3
"""Terrain passes 2-3, the valley's shape (plan chapter 11, 8.2; docs/ISSUES.md, ISS-031; PLAN step 8.2).

The real ground at the site stands about 140 m (RMS) off chapter 02's design at its control points, and its Yalong runs
200-600 m east of the designed one (docs/terrain/base-report.md), so these passes author the valley on the real ground
rather than touch it up:
1. A smooth design surface, solved on a coarse grid as a regularised least-squares fit (thin plate) through weighted
   constraints: the named places' floors (data/town.json: the gazetteer and the control points); the open rivers'
   banks and beds at their water levels; each district's slope and aspect (chapter 02, 2.4) sampled over its cells in
   the plan map (chapter 02, 9.1) and anchored to its own named places; the real ground, weakly, where the design is
   more than 200 m away and outside every district. At the map's edges the result hands over to the real ground over
   EDGE metres, so the rings meet it.
2. The real ground's fine relief (wavelengths under about 60 m, at most 8 m high) added back, so gullies and knolls
   survive; faded near the real Yalong's old line, whose trench would otherwise run through the town as a ghost.
3. The rivers (chapter 02, 2.3; chapter 11, 8.2 pass 2) in two parts. Their valleys' shape goes into the solve as
   constraints: the Yalong's banks, bent onto the real river near the map's north and south edges; the stream beds;
   wall points near the water at the design's angles (the gorge's west wall at 30 degrees, its east at 50; the Serchu's
   north bank at 40 per cent, the Shade Wood's side at 60), so the thin plate rounds each V into its rims. The carving
   then cuts only the narrow channels, never higher than a set height above the water: the Yalong's 90 m channel, the
   braids on the fan, the rock slot with the 7 m Conch Fall, the stream at the gorge's foot, the Serchu and its Golden
   Slot.
Heights are written in real altitude (design + the site's shift), like the base, so export_t3d.py, terrain_check.py and
horizon.py read it the same way (VALLEY=valley_sculpted_1m).
Run: tools/py tools/terrain/sculpt.py   (about a minute). Writes assets/generated/terrain/valley_sculpted_1m.tif,
docs/terrain/sculpt-report.md and docs/terrain/sculpt-map.jpg.
"""
import json
import math
import os
import re
import sys

import numpy as np
import rasterio
from scipy import ndimage, sparse
from scipy.sparse.linalg import spsolve
from scipy.spatial import cKDTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
TOWN = os.path.join(ROOT, "data", "town.json")
CHAPTER = os.path.join(ROOT, "docs", "plan", "02-town.md")
REPORT = os.path.join(ROOT, "docs", "terrain", "sculpt-report.md")
MAP = os.path.join(ROOT, "docs", "terrain", "sculpt-map.jpg")
OUT = os.path.join(GEN, "valley_sculpted_1m.tif")

COARSE = 20.0  # metres per cell of the smooth design surface
SIGMA = {"named": 1.0, "bank": 1.0, "valley": 4.0, "district": 15.0, "real": 15.0}  # metres: how firmly each holds
LAMBDA = float(os.environ.get("LAMBDA", "0.05"))  # the thin plate's weight against the data
DETAIL, DETAIL_MAX = 30.0, 8.0  # the real relief kept: the ground minus its blur at this sigma (m), clipped (m)
MID, MID_MAX = 90.0, 25.0  # and away from the named places its middle scales (30-90 m), so district planes are not sheets
BACKGROUND_GAP = 200.0  # real-ground anchors only this far from any design constraint, and outside the districts
EDGE = 250.0  # metres over which the sculpted ground hands over to the real at the map's edges

# The plan map's letters (chapter 02, 9.1) and the slopes of 2.4: facing (the downhill bearing) and gradient.
DISTRICTS = {"p": "pharkha", "c": "tsonggar", "h": "hejie", "s": "shol", "t": "tode", "g": "dungrong", "m": "gonpa",
             "y": "serchu", "w": "shade_wood", "a": "tathang", "r": "ritro"}
SLOPES = {"shol": (190.0, 0.45), "tode": (200.0, 0.45), "shade_wood": (355.0, 0.60), "serchu": (200.0, 0.40),
          "pharkha": (90.0, 0.30), "tathang": (185.0, 0.20)}  # Tathang: its bench at 4-8% and 35% above, as one plane
NOT_GROUND = ("bridge", "crossing", "vessel", "waterfall", "chain", "roof", "gallery")
DESIGNED = ("s", "t", "a", "h", "c", "m", "r")  # districts whose surface the design gives: no real middle-scale relief


# ---------------------------------------------------------------------------------------------------------- inputs
def plan_map():
    """[(x, y, letter)] for the district letters and the water of chapter 02's plan: a column is 25 m, a row 50 m."""
    lines = open(CHAPTER, encoding="utf-8").read().split("\n")
    i = next(k for k, l in enumerate(lines) if l.startswith("### 9.1"))
    j = next(k for k in range(i, len(lines)) if lines[k].startswith("```text"))
    block = lines[j + 1:next(k for k in range(j + 1, len(lines)) if lines[k].startswith("```"))]
    ticks = [c for c, ch in enumerate(block[0]) if ch == "|"]
    assert ticks[:5] == [7, 27, 47, 67, 87], ticks
    label = {k: int(l[:6].strip()) for k, l in enumerate(block) if re.fullmatch(r"[+-]?\d+", l[:6].strip() or "x")}
    k0, y0 = next(iter(label.items()))
    out = []
    for r, l in enumerate(block[1:-2], start=1):
        y = y0 - (r - k0) * 50.0
        for c, ch in enumerate(l):
            if c < 6 and r in label:
                continue
            if ch in DISTRICTS or ch == "~":
                out.append(((c - 47) * 25.0, y, ch))
    return out


def district_grid(points, xs, ys):
    """The district letter ('' for none, '~' water) at each (y, x) of a grid: the nearest plan letter within a cell."""
    pts = np.array([[p[0], p[1] * 0.5] for p in points])  # a row is twice a column: measure in columns
    tree = cKDTree(pts)
    gx, gy = np.meshgrid(xs, ys)
    d, i = tree.query(np.c_[gx.ravel(), gy.ravel() * 0.5], distance_upper_bound=40.0)
    letters = np.array([p[2] for p in points] + [""])
    return letters[np.minimum(i, len(points))].reshape(gx.shape)


def real_river(base, shift):
    """The real Yalong across the map: for each y, the lowest ground of the blurred real surface west of x = +600,
    smoothed along the river; (y, x, water z in design altitude)."""
    blur = ndimage.gaussian_filter(base.a, 20.0)
    ys = np.arange(base.y0 + 5, base.y1 - 5, 10.0)
    xs = np.arange(base.x0 + 5, 600.0, 5.0)
    gx, gy = np.meshgrid(xs, ys)
    c, r = base.pix(gx, gy)
    z = ndimage.map_coordinates(blur, [r.ravel(), c.ravel()], order=1, mode="nearest").reshape(gx.shape)
    k = np.argmin(z, axis=1)
    x = ndimage.median_filter(xs[k], size=15, mode="nearest")
    x = ndimage.gaussian_filter1d(x, 6.0, mode="nearest")
    zw = ndimage.gaussian_filter1d(np.min(z, axis=1) - shift, 6.0, mode="nearest")
    return ys, x, zw


def smoothstep(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------------------------------------------------- rivers
def densify(pts, step=5.0):
    """A polyline [(x, y, z)] resampled every `step` metres, z linear along it."""
    out = []
    for (x0, y0, z0), (x1, y1, z1) in zip(pts[:-1], pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
        for k in range(n):
            t = k / n
            out.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, z0 + (z1 - z0) * t))
    out.append(pts[-1])
    return np.array(out)


def rivers(town, real):
    """Each river as a dict: 'pts' (n, 3) downstream order with the water z, 'kind' per point, from chapter 02 (2.2, 2.3)."""
    cp = {k: v["pos"] for k, v in town["control"].items() if "pos" in v}
    ys_r, xs_r, zw_r = real
    # The Yalong: the design's centreline in the core, bent onto the real river near both edges; downstream = south.
    y = np.arange(1100.0, -1100.1, -5.0)
    xd = -525.0 + 0.04 * y
    zd = 2541.0 + 0.005 * (y + 170.0)
    # (north of Tathang's places, whose west end stands 60-150 m from the design's river: ISS-043)
    w = np.maximum(smoothstep(950.0, 1100.0, y), smoothstep(-350.0, -1100.0, y))
    xr, zr = np.interp(y, ys_r, xs_r), np.interp(y, ys_r, zw_r)
    yal = np.c_[xd + (xr - xd) * w, y, zd + (zr - zd) * w]
    # The Dungchu, downstream from where it enters the map on the gorge's line to its mouth.
    u5, intake = cp["U5"], cp["Leat intake"]
    t = (1100.0 - u5[1]) / (intake[1] - u5[1])
    enter = (u5[0] + (intake[0] - u5[0]) * t, 1100.0, u5[2] + (intake[2] - u5[2]) * t)
    gorge = densify([enter, tuple(u5), tuple(cp["U2"]), tuple(cp["C"])])
    c, x = cp["C"], cp["X"]
    slot = densify([tuple(c), tuple(x)])
    along = np.r_[0.0, np.cumsum(np.hypot(np.diff(slot[:, 0]), np.diff(slot[:, 1])))]
    slot[:, 2] = c[2] - (c[2] - x[2] - 7.0) * along / along[-1] - np.where(along > 40.0, 7.0, 0.0)  # the Conch Fall
    fan = densify([tuple(x), tuple(cp["M"])])
    # The Serchu, downstream to the confluence; its last 300 m is the Golden Slot.
    ser = densify([tuple(cp["S5"]), tuple(cp["S3"]), tuple(cp["S1"]), tuple(cp["S0"]), tuple(c)])
    to_c = np.r_[np.cumsum(np.hypot(np.diff(ser[::-1, 0]), np.diff(ser[::-1, 1])))[::-1], 0.0]
    narrow = 1.0 - NARROWS[2] * np.exp(-((yal[:, 1] - NARROWS[0]) / NARROWS[1]) ** 2)
    return [
        {"name": "Yalong", "pts": yal, "kind": np.full(len(yal), "yalong"), "scale": narrow},
        {"name": "Dungchu gorge", "pts": gorge, "kind": np.full(len(gorge), "gorge")},
        {"name": "Samkha slot", "pts": slot, "kind": np.full(len(slot), "slot")},
        {"name": "Dungchu fan", "pts": fan, "kind": np.full(len(fan), "fan")},
        {"name": "Serchu", "pts": ser, "kind": np.where(to_c < 300.0, "golden", "serchu")},
    ]


# The carved channels: (half-width of the bed, bed depth below the water, bank half-width, bank height above the water,
# wall tangent on the right looking downstream, on the left). Every wall is steep (56 degrees or more), so a channel
# stays narrow however high the ground beside it: its walls meet the ground without a step.
PROFILES = {
    "yalong": (35.0, 4.0, 50.0, 1.5, 12.0, 12.0),
    "fan": (8.0, 1.0, 14.0, 0.8, 1.5, 1.5),
    "slot": (5.0, 0.5, 5.0, 0.0, 4.7, 4.7),
    "gorge": (3.0, 1.0, 3.0, 0.0, 3.0, 3.0),
    "serchu": (6.0, 0.8, 10.0, 1.0, 1.5, 1.5),
    "golden": (4.0, 0.8, 4.0, 0.0, 4.0, 4.0),
}
NARROWS = (780.0, 60.0, 0.45)  # the Yalong's rock narrows (chapter 02, 2.3): at y, over +- metres, the width lost
T30, T50 = math.tan(math.radians(30.0)), math.tan(math.radians(50.0))
# The valleys' shape for the solve: (side, distance from the water's line, height above the water); side 0 is the line
# itself, +1 right of the flow looking downstream, -1 left. The gorge flows south-south-west, so its right is the town's
# 30-degree west wall and its left the monastery's 50-degree east wall; the Serchu flows west-north-west, so its right
# is the north bank at 40 per cent and its left the Shade Wood at 60. The slot is too narrow for the grid: carved only.
VALLEYS = {
    "yalong": [(1, 55.0, 2.0), (-1, 55.0, 2.0)],
    "fan": [(0, 0.0, 1.0)],
    "gorge": [(0, 0.0, 2.0)] + [(1, d, T30 * d) for d in (20.0, 40.0, 70.0)] + [(-1, d, T50 * d) for d in (20.0, 40.0, 70.0)],
    "serchu": [(0, 0.0, 1.5)] + [(1, d, 0.4 * d) for d in (25.0, 50.0, 80.0)] + [(-1, d, 0.6 * d) for d in (25.0, 50.0, 80.0)],
    "golden": [(0, 0.0, 1.5), (1, 15.0, 12.0), (-1, 15.0, 12.0)],
}


def river_profile(kind, s, zw, scale):
    """The carved height at signed distance s (positive right of the flow) from a river of `kind` at water zw, its
    widths multiplied by `scale` (the narrows)."""
    out = np.empty_like(s)
    for k, (bed, depth, bank, bank_h, wall_r, wall_l) in PROFILES.items():
        m = kind == k
        if not m.any():
            continue
        a = np.abs(s[m])
        b0, b1 = bed * scale[m], bank * scale[m]
        wall = np.where(s[m] >= 0, wall_r, wall_l)
        out[m] = np.where(a <= b0, zw[m] - depth,
                          np.where(a <= b1, zw[m] - depth + (depth + bank_h) * (a - b0) / np.maximum(b1 - b0, 1e-6),
                                   zw[m] + bank_h + wall * (a - b1)))
    return out


# ---------------------------------------------------------------------------------------------------------- constraints
def constraints(town, rivs, dgrid, gxs, gys, base, shift, lowpass):
    """(x, y, target design z, sigma, kind) for every constraint on the smooth surface."""
    X, Y, Z, S, K = [], [], [], [], []

    def add(x, y, z, kind):
        X.extend(np.atleast_1d(x))
        Y.extend(np.atleast_1d(y))
        Z.extend(np.atleast_1d(z))
        S.extend([SIGMA[kind]] * len(np.atleast_1d(x)))
        K.extend([kind] * len(np.atleast_1d(x)))

    named = []
    for b in town["buildings"]:
        p = b.get("pos")
        if not p or p[2] is None or "z_range" in b or "line" in b or any(w in b["type"] for w in NOT_GROUND):
            continue
        named.append((p[0], p[1], p[2], b["district"]))
    for k, v in town["control"].items():
        p = v.get("pos")
        if p and p[2] is not None and not v.get("water") and k not in ("C", "X", "M", "Laptse La", "Dungri Karpo", "Minya Konka"):
            named.append((p[0], p[1], p[2], ""))
    named = [n for n in named if base.x0 < n[0] < base.x1 and base.y0 < n[1] < base.y1]
    for x, y, z, _ in named:
        add(x, y, z, "named")
    # The rivers' valleys (VALLEYS): the Yalong's banks, the stream beds and the walls near the water.
    for r in rivs:
        p, kind = r["pts"][::4], r["kind"][::4]
        d = np.gradient(p[:, :2], axis=0)
        d /= np.linalg.norm(d, axis=1, keepdims=True)
        right = np.c_[d[:, 1], -d[:, 0]]
        for k, offsets in VALLEYS.items():
            m = kind == k
            if not m.any():
                continue
            sc = r.get("scale", np.ones(len(r["pts"])))[::4][m]
            for side, off, dz in offsets:
                q = p[m, :2] + side * off * sc[:, None] * right[m]
                add(q[:, 0], q[:, 1], p[m, 2] + dz, "bank" if off in (0.0, 55.0) else "valley")
    # The districts' slopes: a plane at the district's facing and gradient, its height fitted to its own named places.
    gx, gy = np.meshgrid(gxs, gys)
    for letter, name in DISTRICTS.items():
        if name not in SLOPES:
            continue
        facing, grad = SLOPES[name]
        dx, dy = math.sin(math.radians(facing)), math.cos(math.radians(facing))
        plane = lambda x, y: -grad * (np.asarray(x) * dx + np.asarray(y) * dy)
        own = [(x, y, z) for x, y, z, d in named if d == name]
        if not own:
            continue
        z0 = float(np.median([z - plane(x, y) for x, y, z in own]))
        m = dgrid == letter
        m[1::2, :] = False  # every other row and column: a sample every 40 m
        m[:, 1::2] = False
        add(gx[m], gy[m], z0 + plane(gx[m], gy[m]), "district")
    # The real ground far from the design and outside every district.
    design = np.c_[X, Y]
    tree = cKDTree(design)
    lat = np.meshgrid(np.arange(base.x0 + 30, base.x1, 60.0), np.arange(base.y0 + 30, base.y1, 60.0))
    lx, ly = lat[0].ravel(), lat[1].ravel()
    ci = np.clip(np.round((lx - gxs[0]) / (gxs[1] - gxs[0])).astype(int), 0, len(gxs) - 1)
    ri = np.clip(np.round((ly - gys[0]) / (gys[1] - gys[0])).astype(int), 0, len(gys) - 1)
    far = (tree.query(np.c_[lx, ly])[0] > BACKGROUND_GAP) & np.isin(dgrid[ri, ci], ["", "~"])
    add(lx[far], ly[far], lowpass(lx[far], ly[far]) - shift, "real")
    return np.array(X), np.array(Y), np.array(Z), np.array(S), np.array(K), named


def solve(x, y, z, sigma, gxs, gys):
    """The thin-plate surface on the grid (rows = gys, columns = gxs) through the weighted constraints."""
    nx, ny = len(gxs), len(gys)
    n = nx * ny
    res = gxs[1] - gxs[0]
    c = (x - gxs[0]) / res
    r = (y - gys[0]) / (gys[1] - gys[0])
    j = np.clip(np.floor(c).astype(int), 0, nx - 2)
    i = np.clip(np.floor(r).astype(int), 0, ny - 2)
    fc, fr = np.clip(c - j, 0, 1), np.clip(r - i, 0, 1)
    rows = np.repeat(np.arange(len(x)), 4)
    cols = np.c_[i * nx + j, i * nx + j + 1, (i + 1) * nx + j, (i + 1) * nx + j + 1].ravel()
    vals = np.c_[(1 - fc) * (1 - fr), fc * (1 - fr), (1 - fc) * fr, fc * fr].ravel()
    A = sparse.csr_matrix((vals, (rows, cols)), shape=(len(x), n))
    W = sparse.diags(1.0 / sigma ** 2)
    # The discrete Laplacian (Neumann at the border), for the thin plate's bending energy.
    def lap1(m):
        d = sparse.diags([np.ones(m - 1), -2 * np.ones(m), np.ones(m - 1)], [-1, 0, 1]).tolil()
        d[0, 0] = d[m - 1, m - 1] = -1
        return d.tocsr()
    L = sparse.kron(sparse.identity(ny), lap1(nx)) + sparse.kron(lap1(ny), sparse.identity(nx))
    M = (A.T @ W @ A + LAMBDA * (L.T @ L)).tocsc()
    b = A.T @ (W @ z)
    return spsolve(M, b).reshape(ny, nx)


# ---------------------------------------------------------------------------------------------------------- main
def main():
    site = Site.load()
    base = site.read(os.path.join(GEN, "valley_1m.tif"))
    town = json.load(open(TOWN, encoding="utf-8"))
    shift = site.shift
    blurred = ndimage.gaussian_filter(base.a, 30.0)
    lowpass = lambda x, y: base.__class__(blurred, (base.x0, base.x1, base.y0, base.y1, base.res)).z(x, y, clamp=True)

    plan = plan_map()
    gxs = np.arange(base.x0 + COARSE / 2, base.x1, COARSE)
    gys = np.arange(base.y0 + COARSE / 2, base.y1, COARSE)
    dgrid = district_grid(plan, gxs, gys)
    real = real_river(base, shift)
    rivs = rivers(town, real)
    X, Y, Z, S, K, named = constraints(town, rivs, dgrid, gxs, gys, base, shift, lowpass)
    kinds = {k: int((K == k).sum()) for k in SIGMA}
    print("sculpt: %d constraints %s" % (len(X), kinds))
    smooth = solve(X, Y, Z, S, gxs, gys)  # rows run south to north here

    # Up to 1 m: the base's pixel centres; the smooth surface is cubic between its cells.
    h, w = base.a.shape
    px = base.x0 + (np.arange(w) + 0.5) * base.res
    py = base.y1 - (np.arange(h) + 0.5) * base.res
    ci = (px - gxs[0]) / COARSE
    ri = (py - gys[0]) / COARSE
    spl = ndimage.spline_filter(smooth, order=3, mode="nearest")
    z = np.empty((h, w), np.float64)
    for r0 in range(0, h, 256):  # in bands, to keep the coordinate arrays small
        rr = ri[r0:r0 + 256]
        cc, rg = np.meshgrid(ci, rr)
        z[r0:r0 + 256] = ndimage.map_coordinates(spl, [rg, cc], order=3, mode="nearest", prefilter=False)
    g30 = ndimage.gaussian_filter(base.a, DETAIL)
    detail = np.clip(base.a - g30, -DETAIL_MAX, DETAIL_MAX)
    mid = np.clip(g30 - ndimage.gaussian_filter(base.a, MID), -MID_MAX, MID_MAX)
    del g30
    # The middle scales only away from the named places, where the design is a district's plane or nothing.
    tree_named = cKDTree(np.array([(n[0], n[1]) for n in named]))
    gxx, gyy = np.meshgrid(gxs, gys)
    far = smoothstep(80.0, 250.0, tree_named.query(np.c_[gxx.ravel(), gyy.ravel()])[0].reshape(gxx.shape))
    # and not where the design gives the surface (the town's districts, Tathang's race course, the monastery): their
    # terraces and benches would come out as knolls and hollows of 10-25 m (upper Tödé's check point sat in one)
    far *= ndimage.gaussian_filter((~np.isin(dgrid, list(DESIGNED))).astype(float), 2.0)
    far_1m = np.empty((h, w))
    for r0 in range(0, h, 256):
        rr = ri[r0:r0 + 256]
        cc, rg = np.meshgrid(ci, rr)
        far_1m[r0:r0 + 256] = ndimage.map_coordinates(far, [rg, cc], order=1, mode="nearest")
    # Both faded near the real Yalong where the design's is not: its trench's walls would haunt the town.
    ys_r, xs_r, _ = real
    xr_at = np.interp(py, ys_r, xs_r)[:, None]
    xd_at = np.interp(py, rivs[0]["pts"][::-1, 1], rivs[0]["pts"][::-1, 0])[:, None]
    away = np.abs(xr_at - xd_at) > 100.0
    near = np.abs(px[None, :] - xr_at)
    detail *= np.where(away & (near < 150.0), smoothstep(60.0, 150.0, near), 1.0)
    mid *= np.where(away & (near < 300.0), smoothstep(120.0, 300.0, near), 1.0)
    z += detail + mid * far_1m
    del mid, far_1m

    # The rivers, carved: every cell within reach of a river takes the lower of its height and the river's section.
    gx1, gy1 = np.meshgrid(px, py)
    for r in rivs:
        p, kind = r["pts"], r["kind"]
        d = np.gradient(p[:, :2], axis=0)
        d /= np.linalg.norm(d, axis=1, keepdims=True)
        tree = cKDTree(p[:, :2])
        x0, x1 = p[:, 0].min() - 450, p[:, 0].max() + 450
        y0, y1 = p[:, 1].min() - 450, p[:, 1].max() + 450
        cols = (px >= x0) & (px <= x1)
        rows = (py >= y0) & (py <= y1)
        if not cols.any() or not rows.any():
            continue
        sub = (slice(np.argmax(rows), len(rows) - np.argmax(rows[::-1])), slice(np.argmax(cols), len(cols) - np.argmax(cols[::-1])))
        qx, qy = gx1[sub].ravel(), gy1[sub].ravel()
        dist, k = tree.query(np.c_[qx, qy], distance_upper_bound=450.0)
        ok = np.isfinite(dist)
        k = np.minimum(k, len(p) - 1)
        v = np.c_[qx - p[k, 0], qy - p[k, 1]]
        s = np.sign(v[:, 0] * d[k, 1] - v[:, 1] * d[k, 0]) * dist  # positive to the right looking downstream
        carve = river_profile(kind[k], np.where(ok, s, 0.0), p[k, 2], r.get("scale", np.ones(len(p)))[k])
        zs = z[sub].ravel()
        zs = np.where(ok, np.minimum(zs, carve), zs)
        z[sub] = zs.reshape(z[sub].shape)
        print("sculpt: carved %-14s %5d points, %.1f M cells in reach" % (r["name"], len(p), ok.sum() / 1e6))

    # The hand-over to the real ground at the map's edges.
    de = np.minimum(np.minimum(px - base.x0, base.x1 - px)[None, :], np.minimum(py - base.y0, base.y1 - py)[:, None])
    wr = 1.0 - smoothstep(0.0, EDGE, de)
    z = z * (1.0 - wr) + (base.a - shift) * wr

    # Write in real altitude, tagged like the base.
    with rasterio.open(os.path.join(GEN, "valley_1m.tif")) as src:
        prof = src.profile
        tags = src.tags()
    with rasterio.open(OUT, "w", **prof) as f:
        f.write((z + shift).astype(np.float32), 1)
        f.update_tags(**tags)
    report(base, z, shift, named, rivs, real, X, Y, Z, K, smooth, gxs, gys, dgrid)
    print("sculpt: wrote %s" % os.path.relpath(OUT, ROOT))


def report(base, z, shift, named, rivs, real, X, Y, Z, K, smooth, gxs, gys, dgrid):
    from terrain_site import Grid
    g = Grid(z, (base.x0, base.x1, base.y0, base.y1, base.res))
    lines = ["# Sculpt report: terrain passes 2-3\n",
             "_Written by `tools/terrain/sculpt.py` (plan chapter 11, 8.2; ISS-031). Heights are the design's (the game's): real ground minus the site's shift of %.0f m._\n" % shift]
    res = np.array([g.z(x, y) - zz for x, y, zz, _ in named])
    real0 = np.array([base.z(x, y) - shift - zz for x, y, zz, _ in named])
    lines.append("## The named places\n\n%d floors and control points (the gazetteer's and chapter 02, 2.2's; bridges, boats and ranges left out). Before: the real ground's RMS %.0f m off the design; now %.1f m (median %.1f m, worst %.0f m). The pads (pass 4) level each footprint to its floor.\n" % (
        len(named), float(np.sqrt(np.nanmean(real0 ** 2))), float(np.sqrt(np.nanmean(res ** 2))), float(np.nanmedian(np.abs(res))), float(np.nanmax(np.abs(res)))))
    worst = np.argsort(-np.abs(np.nan_to_num(res)))[:8]
    lines.append("| Place | x, y | Design z | Sculpted | Off |\n|---|---|---|---|---|")
    ids = [n for n in named]
    for i in worst:
        x, y, zz, d = ids[i]
        lines.append("| %s | %+.0f, %+.0f | %.0f | %.0f | %+.0f |" % (d or "control", x, y, zz, zz + res[i], res[i]))
    ys_r, xs_r, zw_r = real
    lines.append("\n## The Yalong\n\nThe design's centreline x = −525 + 0.04y in the core, bent onto the real river from y = +950 northwards and from y = −350 southwards.\n")
    lines.append("| y | Design x | Real x | Carved x | Water, design | Water, real | Carved |\n|---|---|---|---|---|---|---|")
    yal = rivs[0]["pts"]
    for yy in (1095, 900, 500, 0, -170, -500, -800, -1095):
        k = int(np.argmin(np.abs(yal[:, 1] - yy)))
        lines.append("| %+d | %.0f | %.0f | %.0f | %.1f | %.1f | %.1f |" % (yy, -525 + 0.04 * yy, np.interp(yy, ys_r, xs_r), yal[k, 0],
                                                                      2541 + 0.005 * (yy + 170), np.interp(yy, ys_r, zw_r), yal[k, 2]))
    lines.append("\n## Constraints\n\n" + ", ".join("%s %d" % (k, int((K == k).sum())) for k in SIGMA) + "; a %g m grid, thin plate λ %g; the real relief under %g m kept.\n" % (COARSE, LAMBDA, DETAIL))
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    picture(base, z, shift, rivs, named)


def picture(base, z, shift, rivs, named):
    """Hillshades of the real ground and the sculpted, side by side, with the rivers and the named places."""
    from PIL import Image, ImageDraw
    def shade(a):
        a = a[::4, ::4]
        gy, gx = np.gradient(a, 4.0)
        az, alt = math.radians(315), math.radians(40)
        sl = np.arctan(np.hypot(gx, gy))
        asp = np.arctan2(-gx, gy)
        v = np.sin(alt) * np.cos(sl) + np.cos(alt) * np.sin(sl) * np.cos(az - asp)
        lo, hi = np.percentile(a, 2), np.percentile(a, 98)
        tint = np.clip((a - lo) / (hi - lo), 0, 1)
        rgb = np.stack([0.55 + 0.35 * tint, 0.62 + 0.2 * tint, 0.45 + 0.15 * tint], -1) * np.clip(v, 0, 1)[..., None] * 1.25
        return Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    a, b = shade(base.a - shift), shade(z)
    img = Image.new("RGB", (a.width * 2 + 20, a.height), "white")
    img.paste(a, (0, 0))
    img.paste(b, (a.width + 20, 0))
    d = ImageDraw.Draw(img)
    for off in (0, a.width + 20):
        to = lambda x, y: (off + (x - base.x0) / 4.0, (base.y1 - y) / 4.0)
        for r in rivs:
            d.line([to(x, y) for x, y, _ in r["pts"][::10]], fill=(40, 90, 200), width=2)
        for x, y, _, _ in named:
            px, py = to(x, y)
            d.ellipse([px - 2, py - 2, px + 2, py + 2], fill=(200, 40, 30))
    d.text((10, 10), "real ground (base pass)", fill=(0, 0, 0))
    d.text((a.width + 30, 10), "sculpted (passes 2-3)", fill=(0, 0, 0))
    img.save(MAP, quality=88)


if __name__ == "__main__":
    main()
