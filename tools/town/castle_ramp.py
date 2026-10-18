#!/usr/bin/env python3
"""The Castle Ramp SAM-10, R-16 (plan chapter 02, D04, SAM-10, R-01 and R-16; chapter 06: the chair's and the mount's way
between Hejie and Samkha; M2 sprint 11, step 1): from the castle ward's gate down the knob's west flank to Hejie's East
Gate HEJ-02, as lanes (tools/terrain/pads.py's form), the Caravan Ramp's cousin (tools/town/caravan_ground.py).

Chapter 02 gives it 300 m in three legs at 15%, from 2,645 to 2,598 m. On the real ground (the shaped raster before the
pads, in the design's heights) the knob falls 50 m from the ward to the East Gate within 105 m, steepest (60-80%) in the
40 m above the gate: three legs at 15% would be cut 10-20 m into the flank. Kept: its three legs, the Z that reads from
Hejie and across the valley, fitted as the Caravan Ramp's are (of all the zigzags between the ward, Dechen-tsang and
Norbu-tsang, Hejie's wall and the bank over the slot's water, the one whose beds keep nearest the ground along their
middles and their edges, so it is cut and filled least; its landings level with the ground about them), at 22%, the
gentlest grade at which three legs keep within 7 m of the ground (at 20% they are cut 8-11 m), over about 220 m. Five
legs could keep 17% over 296 m, but three of them bundle into the 30 m above the gate (a wide search, `--search legs
grade_lo grade_hi`, 10 Oct 2026). The ward has one gate, in its east wall (the kit's WARD_GATE; ../tibet-blender
kit/samkha.py): the way leaves it north between the ward's wall and Dechen-tsang's on the ground as it is; from the ward's
north-east corner the first leg goes down north-west over the saddle and the flank to its switchback under Hejie's north-east
corner, the second back south-south-east across the flank to a landing on the bank over the slot's water, and the third
north-west into a short run along the East Gate's passage (SAM-10.b), at River Street's level. So R-01 runs from the
chain bridge through the castle's passage and ward, out at its gate and down the ramp to Hejie, and every traveller from
the south walks through the Pönpo's house (chapter 02, D04). Chapter 02's stables and granary SAM-08 (at -165, -60) and
ula yard SAM-09 (-190, -45) stood on the flank the ramp crosses (with their places kept clear every zigzag was cut 13-18 m
into it): they are placed by the ramp (M2 sprint 11, step 3).
pads.py carves the lanes, tools/town/walls.py walls their sides where they are cut or filled, tools/terrain/control.py
paints them trodden; the street graph walks them (tools/town/graph.py).
Run: tools/py tools/town/castle_ramp.py   Writes data/castle_ramp.json and docs/town/castle-ramp-report.md
(tools/terrain/build.sh runs it before pads.py; about 10 s).
"""
import json
import math
import os
import sys

import numpy as np
from scipy.optimize import minimize

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
from terrain_site import Site  # noqa: E402
from caravan_ground import footprint_z, lane, seg_dist  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
SOURCE = os.path.join(GEN, "valley_shaped_1m.tif")  # the ground before the pads (pads.py's SOURCE)
OUT = os.path.join(ROOT, "data", "castle_ramp.json")
REPORT = os.path.join(ROOT, "docs", "town", "castle-ramp-report.md")
WARD_Z = 2649.0  # the ward's level (tools/terrain/samkha.py WARD_Z)
GATE = (-107.6, -75.6)  # the way's start: outside the ward's gate (the kit's WARD_GATE at -109.6, -73.5, 3.2 m wide), at its
GATE_Z = WARD_Z - 0.3  # south jamb, a step down from the ward's floor
HEAD = (-108.9, -62.8)  # past the ward's north-east corner (-110, -68), clear of Dechen-tsang's pad's wall (x -107.5 there): the
HEAD_Z = 2646.4  # first leg starts here, at the hollow's level between them (2,646.2-2,646.6 m); from the gate to it the ground as it is
# (a lane carved there had stood on a fill with a parapet across the way east to Nétsang Lam, its bed cut under the
# ward's wall; a head at 2,648 m stood on a fill whose wall barred the way up to it from the gate)
FOOT = (-212.0, -80.0)  # the last leg's end, before the East Gate (HEJ-02's passage from x -214.5 west, on River Street's axis
FOOT_Z = 2597.8  # y -80, at its level: data/hejie.json HEJ-02, HEJ-RS.01)
RUN_IN = 3.0  # the run along the gate's passage from the foot, level, into the gate tower's floor
WIDTH = 4.0  # a chair and its bearers, or a laden mule, and room to pass
SEP = WIDTH + 3.5  # at a switchback the two legs' middles this far apart: a strip of the slope between them
LANDING = 5.0  # a switchback's depth past the legs' ends: room for a chair to turn
OVERLAP = 1.0  # each leg runs this far into its landings, level, so no wedge of the slope is left where they meet
LEGS = 3
FIRST = 1  # the first switchback turns left (the second right, and so on)
GRADE = (0.20, 0.22)  # chapter 02's 15% would cut the flank 10-20 m deep: the gentlest at which three legs keep near it
# Where the legs and landings may not go (x0, x1, y0, y1): the ward and its batter, Dechen-tsang's and Norbu-tsang's pads
# (data/samkha.json, the gazetteer's SHL-04 and SHL-06), and inside Hejie's wall (tools/town/hejie.py WALL: its east side
# at x -214 up to its north-east corner at y 12, its face and 1.4 m clear of it); over the bank above the slot's water
KEEP_OUT = [(-153.0, -110.5, -99.0, -65.5), (-106.5, -43.5, -64.5, -15.5), (-157.0, -123.0, -10.0, 20.0), (-600.0, -212.0, -200.0, 15.0)]
RIM_Y = -105.0  # the bank over the slot's water west of the castle (its edge at y -112): a band's south edge no further south
START = [-202.7, -1.7, -186.4, -96.7]  # the switchbacks' points (the legs' ends at their landings' edges), from a wide
# search (10 Oct 2026: three to seven legs at 14.5-22%, 60 starts each way round)
TRIALS, SEED = 6, 11
W_EDGE, W_LANDING = 0.25, 24.0  # the edges' weight beside the middle's, the landings'
W_CORNER, CORNER_FREE = 60.0, 4.0  # a landing's corners more than this off the ground (the second's outer edge stands on
# the bank over the slot's water on a wall about 10 m high: weighed harder, the second leg is cut deeper for a metre less)
TOWN = os.path.join(ROOT, "data", "town.json")
# The ramp's yards (pads.py reads them: each at the middle, the median, of the ground under it, turned to lie along its
# contour): the ula yard SAM-09 north of the first switchback, outside Hejie's north-east corner, from chapter 02's
# (-190, -45), where the second leg crosses (there it stood on a 10 m fill over a 10 m cut; here within 3.3 m of its
# ground); the stables and granary SAM-08 along its uphill side, at its level, its stable doors into it (M2 sprint 11,
# step 3; chapter 02 had it at (-165, -60), on the ramp's first leg). [at, facing, behind]: a pad `behind` another stands
# against its back, at its level
PADS = {"SAM-09": ((-180.0, 5.0), 220.0, None), "SAM-08": (None, 220.0, "SAM-09")}


def turns(k):
    return FIRST if k % 2 == 0 else -FIRST


def legs_of(v):
    """The legs (start, end, z at start, z at end, grade, length) of the fit's vector: each leg's end on its landing's
    edge, the next one's start SEP to its side, the landing between them level; all at one grade, from the head to the
    foot."""
    ends = [np.array(v[2 * k:2 * k + 2], float) for k in range(LEGS - 1)] + [np.array(FOOT)]
    pts, S = [], np.array(HEAD)
    for k in range(LEGS):
        E = ends[k]
        pts.append((S.copy(), E.copy()))
        if k < LEGS - 1:
            d = (E - S) / max(1e-6, float(np.hypot(*(E - S))))
            S = E + np.array([-d[1], d[0]]) * turns(k) * SEP
    Ls = [float(np.hypot(*(b - a))) for a, b in pts]
    gr = (HEAD_Z - FOOT_Z) / sum(Ls)
    out, z = [], HEAD_Z
    for (a, b), L in zip(pts, Ls):
        out.append((a, b, z, z - gr * L, gr, L))
        z -= gr * L
    return out


def landing_box(leg, k):
    """A switchback's landing: its four corners (from this leg's outer edge across to the next one's, LANDING past the
    legs' ends)."""
    S, E, za, zb, gr, L = leg
    d = (E - S) / L
    n = np.array([-d[1], d[0]]) * turns(k)
    a, b = E - n * WIDTH / 2, E + n * (SEP + WIDTH / 2)
    return [a, b, b + d * LANDING, a + d * LANDING]


def outside(P, margin=0.0):
    """How far each point lies inside a place the ramp may not go (0 where it is clear)."""
    bad = np.zeros(len(P))
    for (x0, x1, y0, y1) in KEEP_OUT:
        dx = np.minimum(P[:, 0] - (x0 - margin), (x1 + margin) - P[:, 0])
        dy = np.minimum(P[:, 1] - (y0 - margin), (y1 + margin) - P[:, 1])
        bad = np.maximum(bad, np.maximum(0.0, np.minimum(dx, dy)))
    return np.maximum(bad, np.maximum(0.0, RIM_Y - P[:, 1]))


def make_cost(Z):
    def cost(v, rows=None):
        legs = legs_of(v)
        gr = legs[0][4]
        c = 1e8 * (max(0.0, gr - GRADE[1]) ** 2 + max(0.0, GRADE[0] - gr) ** 2)
        for k, (S, E, za, zb, g_, L) in enumerate(legs):
            if L < 1.0:
                return 1e9
            d = (E - S) / L
            n = np.array([-d[1], d[0]])
            s = np.arange(0.0, L + 0.01, 2.0)
            P = S[None] + d[None] * s[:, None]
            bed = za - g_ * s
            mid = Z(P[:, 0], P[:, 1]) - bed
            left = Z(P[:, 0] + n[0] * WIDTH / 2, P[:, 1] + n[1] * WIDTH / 2) - bed
            right = Z(P[:, 0] - n[0] * WIDTH / 2, P[:, 1] - n[1] * WIDTH / 2) - bed
            if np.isnan(mid).any() or np.isnan(left).any() or np.isnan(right).any():
                return 1e9
            c += 2.0 * (float(np.sum(mid ** 2)) + W_EDGE * float(np.sum(left ** 2 + right ** 2)))
            keep = P[2:] if k == 0 else P  # (the first leg's first metres come round the ward's and Dechen-tsang's corners)
            edges = np.concatenate([keep + n[None] * WIDTH / 2, keep - n[None] * WIDTH / 2])
            c += 1e4 * float(np.sum(outside(edges) ** 2))
            c += 1e3 * max(0.0, 25.0 - L) ** 2
            if rows is not None:
                rows.append({"leg": k + 1, "bearing": math.degrees(math.atan2(d[0], d[1])) % 360.0, "length": L, "z_a": za, "z_b": zb,
                             "grade": g_, "mean": float(np.mean(np.abs(mid))), "max": float(np.max(np.abs(mid))),
                             "cut": float(max(np.max(left), np.max(right), 0.0)), "fill": float(max(-np.min(left), -np.min(right), 0.0))})
        dl = (legs[-1][1] - legs[-1][0]) / legs[-1][5]
        c += 1e4 * max(0.0, dl[0] + 0.7) ** 2  # the last into the gate from the east, within 45 degrees of its axis
        for k in range(LEGS - 1):  # the landings clear, and level with the ground about them
            box = np.array(landing_box(legs[k], k))
            c += 1e4 * float(np.sum(outside(box) ** 2))
            m = box.mean(axis=0)
            c += W_LANDING * (float(Z(m[0], m[1])) - legs[k][3]) ** 2
            for q in box:  # and its corners: no landing held up on a high wall over the bank
                c += W_CORNER * max(0.0, abs(float(Z(q[0], q[1])) - legs[k][3]) - CORNER_FREE) ** 2
        for i in range(LEGS):  # no leg near another but where they meet at a landing, and two that meet part from there
            for j in range(i + 2, LEGS):
                c += 1e4 * max(0.0, WIDTH + 3.0 - seg_dist(legs[i][0], legs[i][1], legs[j][0], legs[j][1])) ** 2
        for i in range(LEGS - 1):
            a, b = legs[i], legs[i + 1]
            da = seg_dist(a[0], a[1] - (a[1] - a[0]) / max(a[5], 1.0) * 8.0, b[0] + (b[1] - b[0]) / max(b[5], 1.0) * 8.0, b[1])
            c += 1e4 * max(0.0, WIDTH + 0.5 - da) ** 2
        return c
    return cost


def fit(Z):
    cost = make_cost(Z)
    rng = np.random.default_rng(SEED)
    best = None
    for trial in range(TRIALS):
        v = np.array(START, float)
        if trial:
            v += rng.normal(0.0, 5.0, v.size)
        r = minimize(cost, v, method="Nelder-Mead", options={"maxiter": 30000, "maxfev": 30000, "xatol": 0.05, "fatol": 0.5, "adaptive": True})
        r = minimize(cost, r.x, method="Powell", options={"maxiter": 30000, "xtol": 0.05, "ftol": 1e-4})
        if best is None or r.fun < best.fun:
            best = r
    rows = []
    cost(best.x, rows)
    return best.x, rows, best.fun


def search(Z, legs, lo, hi, n=60):
    """A wide search (`--search legs grade_lo grade_hi`): n random starts each way round, the best few distinct fits."""
    global LEGS, GRADE, FIRST
    LEGS, GRADE = legs, (lo, hi)
    rng = np.random.default_rng(3)
    res = []
    for first in (1, -1):
        FIRST = first
        cost = make_cost(Z)
        for _ in range(n):
            v0 = np.concatenate([[rng.uniform(-225.0, -150.0), rng.uniform(-95.0, 35.0)] for _ in range(LEGS - 1)])
            r = minimize(cost, v0, method="Nelder-Mead", options={"maxiter": 20000, "maxfev": 20000, "xatol": 0.1, "fatol": 0.5, "adaptive": True})
            r = minimize(cost, r.x, method="Powell", options={"maxiter": 20000, "xtol": 0.05, "ftol": 1e-4})
            res.append((r.fun, first, r.x))
    res.sort(key=lambda q: q[0])
    seen = []
    for fun, first, x in res:
        if any(np.max(np.hypot(*(x - s).reshape(-1, 2).T)) < 6.0 for s in seen):
            continue
        seen.append(x)
        FIRST = first
        rows = []
        make_cost(Z)(x, rows)
        print("cost %.0f first %d: %s; %.0f m at %.1f%%" % (fun, first, " ".join("(%.1f, %.1f)" % tuple(x[2 * k:2 * k + 2]) for k in range(LEGS - 1)),
                                                         sum(r["length"] for r in rows), 100.0 * rows[0]["grade"]))
        for r in rows:
            print("  leg %d: bearing %03.0f, %.0f m; middle %.1f m off on average (%.1f at most), cut %.1f, filled %.1f" % (
                r["leg"], r["bearing"], r["length"], r["mean"], r["max"], r["cut"], r["fill"]))
        if len(seen) >= 4:
            break


def main():
    if "--search" in sys.argv:
        site = Site.load()
        g = site.read(SOURCE)
        i = sys.argv.index("--search")
        search(lambda x, y: g.z(x, y) - site.shift, int(sys.argv[i + 1]), float(sys.argv[i + 2]), float(sys.argv[i + 3]))
        return
    site = Site.load()
    g = site.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site.shift  # noqa: E731
    v, rows, fun = fit(Z)
    legs = legs_of(v)
    lanes = []
    L0 = float(np.hypot(HEAD[0] - GATE[0], HEAD[1] - GATE[1]))  # from the gate to the head on the ground as it is
    path = [[GATE[0], GATE[1], round(GATE_Z, 2)], [HEAD[0], HEAD[1], round(HEAD_Z, 2)]]
    for k, (S, E, za, zb, gr, L) in enumerate(legs):
        d = (E - S) / L
        back = OVERLAP if k else 0.0  # into the landing it leaves
        ahead = OVERLAP if k < LEGS - 1 else 0.0
        prof = [(0.0, za), (back + L, zb)] if not back else [(0.0, za), (back, za), (back + L, zb)]
        if ahead:
            prof.append((back + L + ahead, zb))
        lanes.append(lane("SAM-10.%d" % (k + 1), S - d * back, d, back + L + ahead, za, zb, WIDTH, prof, road=True))
        path.append([round(float(E[0]), 2), round(float(E[1]), 2), round(zb, 2)])
        if k < LEGS - 1:  # the landing: level, across both legs' ends and LANDING past them
            n = np.array([-d[1], d[0]]) * turns(k)
            lanes.append(lane("SAM-10.L%d" % (k + 1), E - n * WIDTH / 2 + d * LANDING / 2, n, SEP + WIDTH, zb, zb, LANDING, road=True))
            m = E + d * LANDING / 2  # the way round it, through its middle
            for q in (m, m + n * SEP, E + n * SEP):
                path.append([round(float(q[0]), 2), round(float(q[1]), 2), round(zb, 2)])
    # the run along the gate's axis from the foot into the gate tower's floor
    lanes.append(lane("SAM-10.b", np.array(FOOT), (-1.0, 0.0), RUN_IN, FOOT_Z, FOOT_Z, WIDTH, road=True))
    q = (FOOT[0] - RUN_IN, FOOT[1])
    path.append([round(q[0], 2), round(q[1], 2), FOOT_Z])
    total = L0 + sum(r["length"] for r in rows) + RUN_IN
    town = {b["id"]: b for b in json.load(open(TOWN, encoding="utf-8"))["buildings"]}
    pads, pad_lines = {}, []
    for pid, (at, facing, behind) in PADS.items():
        b = town[pid]
        w, d_ = b["footprint"]
        if behind:  # against the other's back, at its level
            o = town[behind]
            back = (math.sin(math.radians(facing + 180.0)), math.cos(math.radians(facing + 180.0)))
            reach = (o["footprint"][1] + d_) / 2.0
            x, y = pads[behind]["at"][0] + back[0] * reach, pads[behind]["at"][1] + back[1] * reach
            x, y = round(x, 2), round(y, 2)
        else:
            x, y = at
        zm = pads[behind]["level"] if behind else footprint_z(Z, x, y, facing, w, d_, "median")
        lo, hi = footprint_z(Z, x, y, facing, w, d_, "min"), -footprint_z(lambda a, c: -Z(a, c), x, y, facing, w, d_, "min")
        pads[pid] = {"at": [x, y], "level": round(zm, 2), "facing": facing}
        pad_lines.append("%s %s: at (%.0f, %.0f) facing %03.0f, level %.1f m (chapter 02: (%.0f, %.0f) at %.0f m), the ground under it %.1f to %.1f m" % (
            pid, b["name_en"].split(" (")[0], x, y, facing, zm, b["pos"][0], b["pos"][1], b["pos"][2], lo, hi))
    data = {"about": "The Castle Ramp SAM-10 (R-16; M2 sprint 11, step 1), written by tools/town/castle_ramp.py: `lanes`, the three legs fitted to the knob's west flank at one grade (SAM-10.1-3), the two switchbacks' level landings (SAM-10.L1-2), and the run into Hejie's East Gate (SAM-10.b), for tools/terrain/pads.py, tools/town/walls.py, tools/terrain/control.py and the street graph; `path` its line from the ward's gate to the East Gate (x, y and the design's height), round each landing through its middle. `pads`: the ramp's yards moved from chapter 02's places, each at the median of the ground under it and turned along its contour (`at`, `level`, `facing`), for pads.py. Regenerated with the terrain.",
            "grade": round(legs[0][4], 4), "width": WIDTH, "top": path[0], "foot": path[-1], "path": path, "lanes": lanes, "pads": pads}
    json.dump(data, open(OUT, "w", encoding="utf-8"), indent=1)
    lines = ["leg %d: bearing %03.0f, %.0f m at %.1f%%, %.1f to %.1f m; its middle %.1f m from the ground on average (%.1f at most), its edges cut %.1f m and filled %.1f m at most" % (
        r["leg"], r["bearing"], r["length"], 100.0 * r["grade"], r["z_a"], r["z_b"], r["mean"], r["max"], r["cut"], r["fill"]) for r in rows]
    report = ["# The Castle Ramp", "",
              "_Written by `tools/town/castle_ramp.py` (M2 sprint 11, step 1): the Castle Ramp SAM-10 fitted to the knob's west flank, cut and filled least. Regenerated with the terrain._", "",
              "From outside the ward's gate (%.1f, %.1f) at %.1f m, %.0f m north on the ground round the ward's north-east corner to the head at %.1f m, then at %.1f%%:" % (GATE[0], GATE[1], GATE_Z, L0, HEAD_Z, 100.0 * legs[0][4]), ""]
    report += ["- " + ln for ln in lines]
    report += ["- the run into the East Gate: %.0f m along its passage at %.1f m" % (RUN_IN, FOOT_Z), "",
               "%d landings, level, %.1f m by %.1f m. %.0f m in all (chapter 02: 300 m, R-16 320 m from the chain bridge), %.1f m down (chapter 02: 2,645 to 2,598 m)." % (
                   LEGS - 1, SEP + WIDTH, LANDING, total, GATE_Z - FOOT_Z), "",
               "Chapter 02's three legs at 15%% would be cut 10-20 m into the flank: these fall at the gentlest grade at which three keep within 7 m of it (five could keep 17%%, but three of them bundle into the 30 m above the gate). The stables SAM-08 and the ula yard SAM-09 stood on the flank the ramp crosses, and are placed beside it (M2 sprint 11, step 3). The fit's cost %.0f." % fun]
    report += ["", "## Its yards", ""] + ["- " + ln for ln in pad_lines]
    open(REPORT, "w", encoding="utf-8").write("\n".join(report) + "\n")
    print("castle_ramp: %d legs, %.0f m at %.1f%%, %.1f m down -> %s" % (LEGS, total, 100.0 * legs[0][4], GATE_Z - FOOT_Z, os.path.relpath(OUT, ROOT)))
    for ln in lines + pad_lines:
        print("  " + ln)


if __name__ == "__main__":
    main()
