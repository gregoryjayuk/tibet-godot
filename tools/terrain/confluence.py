#!/usr/bin/env python3
"""Terrain pass 5e, the confluence (M2 sprint 5, step 3; plan chapter 02, C, SHL-11, SHL-12, SAM-13; chapter 08, V-02),
by tools/terrain/pads.py after Samkha's pass. The pads had levelled the Conch terrace SHL-12 across the head of Samkha's
slot (the gazetteer's 30 x 14 m at (190, -90) reached to y -97, where the river runs at -95); the terrace now stands
beside the pool, its south edge 5 m from the slot's line (pads.py MOVED: its middle at TERRACE). And the solved ground
round the confluence C lies under the design's water there (a basin at about 2,658 m against the design's 2,660 m), so
the water the banks hold was under the carved beds and the pool, the slot's head and the Dungchu's and the Serchu's
last metres were dry (tools/terrain/rivers.py). Here each channel within REACH of C is carved again as
tools/terrain/sculpt.py carves it (`river_profile`), within its own width, to the water its banks hold: the design's,
held 0.3 m under the lower bank and eased along as rivers.py eases it, never rising downstream, the pool at C the
lowest of the three's there; the slot's Conch Fall keeps its step.
Run: called by pads.py (`shape`); its effect is in docs/terrain/pads-report.md and the rivers' check
(docs/terrain/rivers-report.md).
"""
import json
import os
import sys

import numpy as np
from scipy.spatial import cKDTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402
import sculpt  # noqa: E402
import rivers  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
REACH = 75.0  # metres from the confluence within which the channels are carved to the water their banks hold
WALL = 2.0  # metres of a channel's walls beyond its bank carved with it (the arrival's nose stands 9 m off the Serchu)
DEEPER = 0.3  # metres deeper than its depth a channel is carved here
BANK = 0.5  # the pool's bank: from under its water at its shore up 2.8 m over this much more of its radius
TERRACE = (190.0, -83.5)  # the Conch terrace's middle (pads.py MOVED): its 14 m from y -90.5 to -76.5, beside the pool

def shape(z, g, town):
    """Carves the rivers' channels near the confluence into the design heights `z` (in place); returns report lines."""
    site = Site.load()
    base = site.read(os.path.join(GEN, "valley_1m.tif"))
    rivs = sculpt.rivers(town, sculpt.real_river(base, site.shift))
    c = np.array(town["control"]["C"]["pos"][:2], dtype=float)
    x0, x1, y0, y1 = c[0] - REACH - 30, c[0] + REACH + 30, c[1] - REACH - 30, c[1] + REACH + 30
    c0, c1 = int((x0 - g.x0) / g.res), int((x1 - g.x0) / g.res)
    r0, r1 = int((g.y1 - y1) / g.res), int((g.y1 - y0) / g.res)
    sub = (slice(r0, r1), slice(c0, c1))
    X, Y = np.meshgrid(g.x0 + (np.arange(c0, c1) + 0.5) * g.res, g.y1 - (np.arange(r0, r1) + 0.5) * g.res)
    Z = z[sub].astype(np.float64)
    before = Z.copy()
    near_c = np.hypot(X - c[0], Y - c[1]) <= REACH
    # never into the Conch terrace's pad and apron (30 x 14 m and 1.5 m round: tools/terrain/pads.py): its retaining wall is
    # the slot's north bank and the pool's lip (the channel and the basin's bank had cut its south 3-4 m away under the
    # kit's paving and parapet)
    terrace = (np.abs(X - TERRACE[0]) <= 16.5) & (np.abs(Y - TERRACE[1]) <= 8.5)
    zg = lambda x, y: Z[int((g.y1 - y) / g.res) - r0, int((x - g.x0) / g.res) - c0]
    # each channel's water near the confluence: the design's (sculpt.py), held 0.3 m under the lower of its banks 1.5 m
    # beyond its bed (rivers.py's own rule) and eased, never rising downstream; the pool at C the lowest of the three's
    chans = []
    for r in rivs:
        p, kind = np.asarray(r["pts"], dtype=float), np.asarray(r["kind"])
        keep = np.hypot(p[:, 0] - c[0], p[:, 1] - c[1]) <= REACH
        if keep.sum() < 2:
            continue
        p, kind = p[keep].copy(), kind[keep]
        d = np.gradient(p[:, :2], axis=0)
        d /= np.linalg.norm(d, axis=1, keepdims=True)
        nrm = np.c_[d[:, 1], -d[:, 0]]
        cap = np.empty(len(p))
        for i in range(len(p)):
            reach = sculpt.PROFILES[str(kind[i])][0] + 1.5
            banks = [zg(p[i, 0] + s_ * nrm[i, 0] * reach, p[i, 1] + s_ * nrm[i, 1] * reach) for s_ in (1, -1)]
            cap[i] = min(banks) - 0.3
        # eased along as rivers.py eases it (a line through its neighbours, never across the fall), so that the water it
        # finds stands over the bed carved here
        along = np.r_[0.0, np.cumsum(np.hypot(np.diff(p[:, 0]), np.diff(p[:, 1])))]
        fall = rivers.falls(p[:, 2]) if r["name"] == "Samkha slot" else set()
        p[:, 2] = np.minimum(rivers.ease(np.minimum(p[:, 2], cap), along, 3, fall), cap)
        chans.append([r["name"], p, kind, d])
    at_c = lambda p: int(np.argmin(np.hypot(p[:, 0] - c[0], p[:, 1] - c[1])))
    pool = min(ch[1][at_c(ch[1]), 2] for ch in chans)
    lines = []
    for name, p, kind, d in chans:
        p[at_c(p), 2] = pool
        p[:, 2] = np.minimum.accumulate(p[:, 2])
        # carved within the channel only (its bed and banks and WALL metres of its walls: never the ground beyond, the
        # arrival's nose and gallery among it), DEEPER metres deeper than its depth, for the water's easing in rivers.py
        tree = cKDTree(p[:, :2])
        dist, k = tree.query(np.c_[X.ravel(), Y.ravel()], distance_upper_bound=30.0)
        k = np.minimum(k, len(p) - 1)
        v = np.c_[X.ravel() - p[k, 0], Y.ravel() - p[k, 1]]
        s = np.sign(v[:, 0] * d[k, 1] - v[:, 1] * d[k, 0]) * np.where(np.isfinite(dist), dist, 0.0)
        width = np.array([sculpt.PROFILES[str(q)][2] for q in kind])[k] + WALL
        ok = np.isfinite(dist) & near_c.ravel() & (np.abs(s) <= width) & ~terrace.ravel()
        carve = sculpt.river_profile(kind[k], s, p[k, 2] - DEEPER, np.ones(len(k)))
        flat = Z.ravel()
        Z = np.where(ok, np.minimum(flat, carve), flat).reshape(Z.shape)
        lines.append("%s's last or first %d m, its water %.1f-%.1f m" % (name, int(len(p) * 5), p[:, 2].min(), p[:, 2].max()))
    # the pool where they meet (rivers.py POOL_AT, POOL_AXES; chapter 08, V-02): a basin 0.3-1.2 m under the pool's
    # water, its bank rising steeply beyond its edge to meet the ground
    rho = rivers.rho(X, Y)
    bed = np.where(rho <= 1.0, pool - DEEPER - 0.9 * (1.0 - rho ** 2), pool - DEEPER + 2.8 * (rho - 1.0) / BANK)
    Z = np.where((rho <= 1.0 + BANK) & ~terrace, np.minimum(Z, bed), Z)
    changed = np.abs(Z - before) > 0.05
    z[sub] = Z.astype(z.dtype)
    cut = (before - Z)[changed]
    worst = np.unravel_index(np.argmax(before - Z), Z.shape)
    lines.append("the pool at C at %.1f m, its basin %.0f x %.0f m; %d cells of 1 m cut, up to %.1f m at (%.0f, %.0f)" % (
        pool, 2 * rivers.POOL_AXES[0], 2 * rivers.POOL_AXES[1], int(changed.sum()), float(cut.max()) if cut.size else 0.0, X[worst], Y[worst]))
    return lines


if __name__ == "__main__":
    print(__doc__)
