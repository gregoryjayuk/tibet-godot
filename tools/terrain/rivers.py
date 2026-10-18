#!/usr/bin/env python3
"""The rivers as water for the game (M2 sprint 5, step 1; plan chapter 02, 2.2-2.3; chapter 08, V-02; ISS-144): each
river's line downstream every 5 m as tools/terrain/sculpt.py `rivers` carves it, with its water's height (design
altitude), its half-width at the water (where the carved bed's bank rises through the water: sculpt.py PROFILES, the
Yalong's narrows), its kind and its waters' colours; the Conch Fall on Samkha's slot as a lip and a foot 0.6 m apart,
where the carving steps 7 m; and the confluence, where the slot begins with the Dungchu's milky water along its right
bank and the Serchu's amber along its left, side by side for MIX metres before they are one (chapter 08, V-02).
Then fitted to the built ground (valley_padded_1m.tif, the passes after the sculpt included): the water lowered under
any bank lower than it, and marked dry where it would stand under the ground (`fit`).
Run: tools/py tools/terrain/rivers.py   Writes data/rivers.json and docs/terrain/rivers-report.md (tools/terrain/build.sh
runs it after the pads).
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402
import sculpt  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
OUT = os.path.join(ROOT, "data", "rivers.json")
REPORT = os.path.join(ROOT, "docs", "terrain", "rivers-report.md")
VALLEY = os.environ.get("VALLEY", "valley_padded_1m")
# the waters' colours (chapter 02, 2.2; chapter 08, V-02): the Dungchu glacier-milky, the Serchu clear amber over golden
# gravel, the Yalong green-grey; below the confluence the two side by side, then one
COLOURS = {"dungchu": "#9FB4BC", "serchu": "#B89A5A", "gravel": "#C9A24E", "yalong": "#5F7F7A"}
WATER = {"gorge": "dungchu", "serchu": "serchu", "golden": "serchu", "slot": "mixed", "fan": "mixed", "yalong": "yalong"}
MIX = 100.0  # metres below the confluence over which the two waters run side by side (chapter 08, V-02's build)
FALL_AT = 37.6  # metres down the slot from the confluence where its carving steps 7 m, if the data does not say
FALL = 7.0
LIP = 0.6  # metres before the carving's step the Conch Fall's water leaves its lip
THROW = 2.5  # metres a second the water is thrown out over the step: an arc clear of the rock's face
ARC = 7  # points on the arc from the lip to the foot
SEARCH = 6.0  # metres beyond the water's edge searched for the built trough (fit)
# the pool at the confluence (chapter 08, V-02: "the pool where white and golden water run side by side"): its middle
# and its half-axes east-west and north-south (tools/terrain/confluence.py carves its basin); the water drawn as one
# surface out to RIM times its axes, under the ground's edge, the three rivers' ribbons sliding under it (`meet`)
POOL_AT = (214.0, -99.0)
POOL_AXES = (9.0, 7.0)
POOL_SHAPE = ((2, 0.12, 0.7), (3, 0.08, 2.1), (5, 0.05, 4.0))  # its shore's wandering: (harmonic, share of its radius, phase)
RIM = 1.12


def water_half_width(kind):
    """Where the carved section rises through the water: within the bed `depth` under it, on the bank's slope above."""
    bed, depth, bank, bank_h = sculpt.PROFILES[kind][:4]
    return bed + depth * (bank - bed) / (depth + bank_h) if bank > bed else bed


def resample_slot(p):
    """The slot's line with the Conch Fall as a sheet of water thrown over its lip: its points as sculpt.py's, but where
    the carving steps (half way between the last point at the upper level and the first below: sculpt.py carves each
    cell to its nearest point's level), the water leaves the lip LIP metres before the step, at the level above, and
    falls in an arc (THROW metres a second out over the step) to the pool at the level below; sculpt.py's points under
    the arc are left out. Returns the points, the step's metres down the slot, the fall's height and its lip's index
    (the arc's ARC points from it, the last its foot)."""
    along = np.r_[0.0, np.cumsum(np.hypot(np.diff(p[:, 0]), np.diff(p[:, 1])))]
    drop = np.where(np.diff(p[:, 2]) < -0.8 * FALL)[0]
    if not len(drop):
        return p, FALL_AT, FALL, -1
    k = int(drop[0])
    fall_at = (along[k] + along[k + 1]) / 2.0
    h = float(p[k, 2] - p[k + 1, 2])
    tf = math.sqrt(2.0 * h / 9.81)
    arc = []
    for t in np.linspace(0.0, tf, ARC):
        d = fall_at - LIP + THROW * t
        f = (d - along[k]) / max(along[k + 1] - along[k], 1e-6)
        q = p[k] + (p[k + 1] - p[k]) * f
        arc.append((q[0], q[1], p[k, 2] - 0.5 * 9.81 * t * t))
    end = fall_at - LIP + THROW * tf
    out = [tuple(q) for q, a_ in zip(p, along) if a_ < fall_at - LIP - 0.5]
    lip = len(out)
    out += arc
    out += [tuple(q) for q, a_ in zip(p, along) if a_ > end + 1.0]
    return np.array(out), fall_at, h, lip


def ease(z, along, k, fall=()):
    """A river's water level eased along it (`along` its metres): at each point a line fitted through its neighbours within
    k points (a mean would lower a slope's water where its window is cut short: at the river's ends, beside the fall),
    the points in `fall` kept as they are and left out of the others' windows. Also tools/terrain/confluence.py's."""
    zs = np.array(z, dtype=float)
    n = len(zs)
    for i in range(n):
        if i in fall:
            continue
        win = [j for j in range(max(0, i - k), min(n, i + k + 1)) if j not in fall and np.isfinite(z[j])]
        if len(win) >= 3:
            a_, b_ = np.polyfit(along[win], np.asarray(z)[win], 1)
            zs[i] = a_ * along[i] + b_
    return zs


def falls(z, lip=-1):
    """The indices kept out of the easing round a river's fall: the arc from `lip` (rivers.json's fall) and a point
    either side; with no lip, round each step of FALL or so in its water (sculpt.py's own points)."""
    out = set()
    if lip >= 0:
        return set(range(lip - 1, lip + ARC + 1))
    for f_ in np.where(np.diff(z) < -FALL * 0.8)[0]:
        out.update(range(f_ - 1, f_ + 3))
    return out


def data():
    site = Site.load()
    base = site.read(os.path.join(GEN, "valley_1m.tif"))
    town = json.load(open(sculpt.TOWN, encoding="utf-8"))
    rivs = sculpt.rivers(town, sculpt.real_river(base, site.shift))
    out = []
    fall_at, drop, lip = FALL_AT, FALL, -1
    for r in rivs:
        p = np.asarray(r["pts"], dtype=float)
        kind = np.asarray(r["kind"])
        scale = np.asarray(r.get("scale", np.ones(len(p))), dtype=float)
        if r["name"] == "Samkha slot":
            p, fall_at, drop, lip = resample_slot(p)
            kind = np.full(len(p), "slot")
            scale = np.ones(len(p))
        pts = [[round(float(q[0]), 2), round(float(q[1]), 2), round(float(q[2]), 2), round(float(water_half_width(str(k)) * s), 2)]
               for q, k, s in zip(p, kind, scale)]
        kinds = [str(k) for k in kind]
        out.append({"name": r["name"], "kinds": kinds, "water": [WATER[k] for k in kinds], "pts": pts})
    cp = town["control"]
    return {"about": "The rivers as water (tools/terrain/rivers.py, from tools/terrain/sculpt.py's rivers): each river's points downstream [x, y, water z (design altitude, fitted to the built ground), its wet width left of its line and right (looking downstream; where the built ground rises through the water), wet (1) or dry (0) (2: wet, its ribbon joining the pool's surface there, under it)], every 5 m in the town grid; its kinds and its water per point (dungchu, serchu, mixed, yalong); the waters' colours; the Conch Fall on the slot (`at` its step's metres below the confluence, `drop` its height, `lip` and `foot` the indices of the arc's first and last points on the slot); the confluence, where the slot begins with the Dungchu along its right bank and the Serchu along its left for `mix` metres.",
            "colours": COLOURS, "mix": MIX,
            "confluence": cp["C"]["pos"],
            "fall": {"river": "Samkha slot", "at": round(float(fall_at), 2), "drop": round(drop, 2), "lip": lip, "foot": lip + ARC - 1 if lip >= 0 else -1, "id": "SAM-13"},
            "rivers": out}


def fit(d):
    """The water fitted to the built ground (valley_padded_1m.tif, every pass after the sculpt included). The built
    trough wanders a few metres off the design's line (the solve's walls and the real ground's detail; the Yalong's
    design line crosses the real river's old trench, ISS-031), so at each point: the section across the river is sampled
    out to SEARCH metres beyond the water's edge, the middle of its lowest stretch found, and those offsets eased along
    the river (75 m on the Yalong, 15 m elsewhere) to give the water's line; its level is the design's, never higher than
    0.3 m under the lower of the banks 1.5 m beyond its edges (on the Yalong, where its built trench lies far under the
    design's water, the trench's bottom plus the bed's depth), eased along the river (a line through its neighbours) but
    for the Conch Fall; a point is wet where its water stands 0.15 m or more over the ground under
    it, dry where it does not (the game draws no water there); and each side's wet width, out to where the ground rises
    through the water. Each point becomes [x, y, water, left width, right width, wet]; returns the report's rows."""
    site = Site.load()
    g = site.read(os.path.join(GEN, VALLEY + ".tif"))
    inside = lambda x, y: g.x0 < x < g.x1 and g.y0 < y < g.y1
    zf = lambda x, y: float(g.z(x, y)) - site.shift if inside(x, y) else float("nan")
    rows = []
    for r in d["rivers"]:
        p = np.array([q[:4] for q in r["pts"]], dtype=float)
        kind = r["kinds"][0]
        depth = sculpt.PROFILES[kind][1]
        n = len(p)
        dirs = np.gradient(p[:, :2], axis=0)
        dirs /= np.maximum(np.linalg.norm(dirs, axis=1, keepdims=True), 1e-9)
        nrm = np.c_[dirs[:, 1], -dirs[:, 0]]  # the right bank, looking downstream
        off = np.zeros(n)
        for i in range(n):
            reach = p[i, 3] + SEARCH
            step = 2.0 if kind == "yalong" else 0.5
            ss = np.arange(-reach, reach + 1e-6, step)
            zs = np.array([zf(p[i, 0] + s_ * nrm[i, 0], p[i, 1] + s_ * nrm[i, 1]) for s_ in ss])
            if np.all(np.isnan(zs)):
                continue
            low = np.nanmin(zs)
            off[i] = float(np.mean(ss[zs <= low + 0.3]))
        k = 15 if kind == "yalong" else 3
        off = np.array([np.mean(off[max(0, i - k):i + k + 1]) for i in range(n)])
        c = p[:, :2] + nrm * off[:, None]
        under = np.array([zf(c[i, 0], c[i, 1]) for i in range(n)])
        cap = np.empty(n)
        for i in range(n):
            reach = p[i, 3] + 1.5
            banks = [zf(c[i, 0] + s_ * nrm[i, 0] * reach, c[i, 1] + s_ * nrm[i, 1] * reach) for s_ in (1, -1)]
            cap[i] = np.nanmin(banks) - 0.3 if not np.all(np.isnan(banks)) else p[i, 2]
        z = np.minimum(p[:, 2], cap)
        if kind == "yalong":  # where the built trench is far under the design's water (ISS-031), the trench's own level
            z = np.minimum(z, under + depth)
        # eased along the river so its surface does not step from point to point (the shader would read a step as a fall),
        # but never across the Conch Fall, and held under the banks again
        fall = falls(p[:, 2], d["fall"]["lip"]) if r["name"] == "Samkha slot" else set()
        along = np.r_[0.0, np.cumsum(np.hypot(np.diff(p[:, 0]), np.diff(p[:, 1])))]
        z = np.minimum(ease(z, along, k, fall), cap)
        if r["name"] == "Samkha slot" and d["fall"]["lip"] >= 0:  # the fall's arc is in the air: no bank holds it
            arc = slice(d["fall"]["lip"], d["fall"]["foot"] + 1)
            z[arc] = p[arc, 2]
        # each side's wet width: out from the middle until the ground rises through the water (a V-shaped valley's water
        # is narrower than the design's channel), eased along the river; the ribbon's edges go EDGE beyond, into the banks
        wl, wr = np.zeros(n), np.zeros(n)
        for i in range(n):
            for side, arr in ((1, wr), (-1, wl)):
                w = 0.0
                while w < p[i, 3] + SEARCH:
                    gz = zf(c[i, 0] + side * nrm[i, 0] * (w + 0.25), c[i, 1] + side * nrm[i, 1] * (w + 0.25))
                    if np.isnan(gz) or gz >= z[i]:
                        break
                    w += 0.25
                arr[i] = w
        wl = np.array([np.mean(wl[max(0, i - 2):i + 3]) for i in range(n)])
        wr = np.array([np.mean(wr[max(0, i - 2):i + 3]) for i in range(n)])
        wet = ~np.isnan(under) & (z - under >= 0.15) & (wl + wr >= 0.5)
        lowered = p[:, 2] - z
        for i in range(n):
            r["pts"][i] = [round(float(c[i, 0]), 2), round(float(c[i, 1]), 2), round(float(z[i]), 2),
                           round(float(wl[i]), 2), round(float(wr[i]), 2), int(bool(wet[i]))]
        rows.append((r["name"], n, float(wet.mean()), float(np.nanmax(lowered)), float(np.nanmedian(lowered)), float(np.max(np.abs(off)))))
    return rows


def shore(theta):
    """The pool's radius at angle `theta` (radians, from the east, in its axes' frame), as a share of its axes."""
    return 1.0 + sum(a * np.sin(k * theta + ph) for k, a, ph in POOL_SHAPE)


def rho(x, y):
    """Where a point lies in the pool: 0 its middle, 1 its shore (numpy arrays or numbers)."""
    u, v = (x - POOL_AT[0]) / POOL_AXES[0], (y - POOL_AT[1]) / POOL_AXES[1]
    return np.hypot(u, v) / shore(np.arctan2(v, u))


def meet(d):
    """The pool's surface where the three rivers meet: its level the slot's water where it leaves the pool (a little
    over), held under the ground round its rim; the Dungchu's and the Serchu's water drawn to their first point in it,
    just under its surface, the slot's from its last; the points further in left to the pool. Returns a report line."""
    site = Site.load()
    g = site.read(os.path.join(GEN, VALLEY + ".tif"))
    zf = lambda x, y: float(g.z(x, y)) - site.shift
    rv = {r["name"]: r for r in d["rivers"]}
    slot = rv["Samkha slot"]["pts"]
    out = next(i for i, q in enumerate(slot) if rho(q[0], q[1]) >= 1.0)
    # the ground round its rim, but where the rivers' own channels cross it
    lines = np.array([q[:2] for nm in ("Dungchu gorge", "Serchu", "Samkha slot") for q in rv[nm]["pts"]])
    ring = [(POOL_AT[0] + POOL_AXES[0] * RIM * shore(a) * math.cos(a), POOL_AT[1] + POOL_AXES[1] * RIM * shore(a) * math.sin(a))
            for a in np.linspace(0.0, 2.0 * math.pi, 72, endpoint=False)]
    rim = min(zf(x, y) for x, y in ring if np.min(np.hypot(lines[:, 0] - x, lines[:, 1] - y)) > 7.0)
    z = min(slot[out][2] + 0.05, rim - 0.1)
    # the Dungchu and the Serchu as they are while their water stands over the pool's; from their first point in the pool
    # or under its level, just under its surface on to the first well inside it (wet 2: the ribbon ends there square,
    # under the pool's surface, not tapered); the rest left to the pool
    for name in ("Dungchu gorge", "Serchu"):
        pts = rv[name]["pts"]
        f = next(i for i, q in enumerate(pts) if i > len(pts) - 30 and (rho(q[0], q[1]) < 1.0 or (rho(q[0], q[1]) < 1.6 and q[2] < z + 0.05)))
        while f < len(pts):
            pts[f][2], pts[f][5] = round(z - 0.05, 2), 1
            if rho(pts[f][0], pts[f][1]) < RIM - 0.1:
                pts[f][5] = 2
                break
            f += 1
        for q in pts[f + 1:]:
            q[5] = 0
    last = out - 1
    slot[last][2], slot[last][5] = round(z - 0.05, 2), 2
    for q in slot[:last]:
        q[5] = 0
    a, b = np.array(slot[last][:2]), np.array(slot[min(out + 1, len(slot) - 1)][:2])
    axis = (b - a) / np.linalg.norm(b - a)
    d["pool"] = {"at": list(POOL_AT), "axes": list(POOL_AXES), "shape": [list(h) for h in POOL_SHAPE], "rim": RIM, "z": round(z, 2),
                 "axis": [round(float(axis[0]), 4), round(float(axis[1]), 4)], "from": slot[last][:2],
                 "half": [slot[out][3], slot[out][4]]}
    return "the pool at the confluence %.0f x %.0f m, its water at %.2f m (the ground round its rim from %.2f m)" % (
        2 * POOL_AXES[0], 2 * POOL_AXES[1], z, rim)


def report(rows, pool=""):
    lines = ["# The rivers on the built ground", "",
             "_Written by `tools/terrain/rivers.py` from `%s` (M2 sprint 5, step 1): each river's water (`data/rivers.json`) fitted to the ground as built: its line moved onto the built trough across each section, its level the design's (tools/terrain/sculpt.py, chapter 02) or the trough plus the bed's depth where lower, held 0.3 m under the lower bank 1.5 m beyond the water's edge; a point is wet where that water stands 0.15 m or more over the ground under its middle (the game draws water only there)._" % VALLEY, "",
             "| River | Points | Wet | Lowered at most | Lowered, median | Moved onto its trough, at most |", "|---|---|---|---|---|---|"]
    for name, n, wet, mx, med, mv in rows:
        lines.append("| %s | %d | %d%% | %.1f m | %.1f m | %.1f m |" % (name, n, round(100 * wet), mx, med, mv))
    lines += ["", "Dry stretches are where the built ground stands over the design's water: the Conch terrace's pad over the slot's head (SHL-12, levelled at 2,664 m across the river: M2 sprint 5, step 4's ground pass), the map's edges where the sculpt hands over to the real ground, and the Yalong where its design line leaves the real river's trench (ISS-031). Large lowerings are the Yalong's and the gorge's, where the ground beside the design's line is lower than its water.",
              "", "**Summary:** " + "; ".join("%s %d%% wet" % (nm, round(100 * w)) for nm, n, w, mx, med, mv in rows) + "; " + pool + "."]
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    return lines[-1]


def main():
    d = data()
    rows = fit(d)
    summary = report(rows, meet(d))
    json.dump(d, open(OUT, "w", encoding="utf-8"), indent=1)
    n = sum(len(r["pts"]) for r in d["rivers"])
    print("rivers: %d rivers, %d points -> %s" % (len(d["rivers"]), n, os.path.relpath(OUT, ROOT)))
    print("rivers: " + summary)


if __name__ == "__main__":
    main()
