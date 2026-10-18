#!/usr/bin/env python3
"""The Gorge Stair R-07 and the upper bridge RNG-02 (M3 sprint 2, step 1; plan chapter 02, D07, R-07, RNG-02, RNG-07,
RNG-08, MON-18; chapter 03's Gorge Stair row: risers 0.19 m, treads 0.24-0.28 m, 1.2 m wide, cut in rock; chapter 08, V-09
and V-17).

Chapter 02 has the Gorge Way from Tödé's east terrace (+230, +265, 2,795) down 385 steps in switchbacks on Tödé's gorge
wall (RNG-07) to the upper cantilever bridge RNG-02 (+330, +185: 24 m, four tiers, 2.2 m wide, raw new timber of 1902 on
grey old abutments, 10 m over the water), then up 885 steps cut in the rock of the east face (RNG-08) with three galleries
on socketed beams, its top 40 m under monks' houses, to the monastery's West Gate MON-18 (+445, +160, 2,890). On the real
ground (the shaped raster before the pads) the Dungchu runs at 2,708 m by the chapter's bridge, the west wall falls at
about 40 degrees, the east face rises at 54-63 degrees to 2,888 m; there the gorge is 43 m wide at 10 m over the water,
31 m at 6 m: the bridge's 24 m between its abutments' faces and their 3.2 m stand 6 m over it (BRIDGE_H). Tödé is not
built yet (M3 sprint 4): the west leg leaves the Gorge Rim Lookout's terrace SHL-32 through a gap in its south-east
parapet (../tibet-blender kit/gardens.py lookout `gap`), the rim's one terrace a walker reaches today, 35 m from the
chapter's place for Tödé's terrace, which will join it there.

Both legs are laid as tools/town/dungrong.py lays the 1,080 steps, from the bridge up: each a few legs of flights with a
landing between flights, a switchback where a leg turns back on itself, a bend where it turns less; the legs' bearings
fitted so the steps keep nearest the ground along their middles and edges, their turns' landings level with the ground
about them, the last leg arriving at its end (the Lookout's gap, the West Gate) on its axis, clear of the water, the
terrace and the garden lane. A flight whose outer side stands highest over the ground is a gallery's place (`gallery`:
the three highest on the east leg, ../tibet-blender builds them as galleries in step 3). Every flight and landing is a lane
in tools/terrain/pads.py's form (`steps`): pads.py carves its bed, tools/town/walls.py walls it where cut or filled (a
parapet on a fill), ../tibet-blender export_lanes.py builds it (its treads cut in the rock: no whitewashed walls),
world/town.gd places it and the bridge (`places`), tools/town/monastery.py keeps its houses off it.
Run: tools/py tools/town/gorge_stair.py   Writes data/gorge_stair.json and docs/town/gorge-stair-report.md
(tools/terrain/build.sh runs it after dungrong.py, before the monastery's planner: a few seconds, laying out START, the
wide search's legs; `--search` searches again, a few minutes, and prints a new START).
"""
import json
import math
import os
import sys

import numpy as np
from scipy.optimize import minimize

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
from terrain_site import Site  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
SOURCE = os.path.join(GEN, "valley_shaped_1m.tif")  # the ground before the pads (pads.py's SOURCE)
RIVERS = os.path.join(ROOT, "data", "rivers_seed.json")  # the rivers' line pinned (ISS-182; tools/town/dungrong.py)
GARDENS = os.path.join(ROOT, "data", "gardens.json")
OUT = os.path.join(ROOT, "data", "gorge_stair.json")
REPORT = os.path.join(ROOT, "docs", "town", "gorge-stair-report.md")

RISER, TREAD = 0.19, 0.26  # chapter 03: 0.19 m, 0.24-0.28 m (the riser trimmed so each leg's steps fill its height)
CLEAR, PARA = 1.2, 0.45  # chapter 03: 1.2 m wide, cut in rock; a parapet on its outer side where it stands on a fill
WIDTH, SHOULDER = CLEAR + PARA, 0.3  # each piece's width (export_lanes.py builds a parapet inside it), the cut's shoulders
BAND = WIDTH + 2 * SHOULDER
LAND = 1.4  # a landing between two flights along the way
SEP = BAND + 1.0  # at a switchback the two legs' middles this far apart
TURN = 2.6  # a switchback's landing past the legs' ends
FLIGHT = 40  # steps a flight, about (each leg's flights as even as its steps allow)
TURN_BACK = 100.0  # a join turning more than this is a switchback
# the upper bridge RNG-02 (chapter 02: +330, +185; 24 m, four tiers, 2.2 m wide): where the gorge at BRIDGE_H over the
# water is nearest its span and its abutments' depth, near the chapter's place (`--search`); its middle over the water,
# its axis (bearing, west to east), the water's level there
BRIDGE = (330.0, 185.0)
SPAN, ABUT, DECK_W = 24.0, 3.2, 2.2  # ../tibet-blender kit/infra.py cantilever_bridge: its abutments ABUT deep past the span
DECK_PAST = 2.6  # and its walkable deck this far past each abutment's face (the kit's deck hull): the stair's feet there
BRIDGE_H = 6.0  # the deck over the water
BRIDGE_MID, BRIDGE_AXIS, BRIDGE_WATER = (335.1, 199.3), 119.1, 2710.5  # (the search's, 11 Oct 2026: 15 m up the gorge from the
# chapter's place, where the gorge at 6 m over the water is 30.8 m across)
# the Gorge Rim Lookout SHL-32 (tools/town/gardens.py LOOKOUT, END_Z; tools/terrain/pads.py MOVED, RAISED): 4 x 6 m, its
# front at 034 degrees, parapets on its front and sides; the west leg leaves it through a gap in its south-east side
LOOKOUT, LOOKOUT_Z, LOOKOUT_FACING, LOOKOUT_SIZE = (258.0, 245.0), 2781.5, 34.0, (4.0, 6.0)
GAP_BACK = 1.0  # the gap's middle this far in from the terrace's back edge
GATE = (445.0, 160.0)  # the West Gate MON-18 (chapter 02; tools/town/monastery.py DOORS): the east leg arrives before it
GATE_OUT = 1.5  # its last flight's top this far short of the gate's place, towards the gorge
GATE_Z_ABOVE = 0.3  # at the gate's level: the ground at its place and this
W_EDGE, W_LAND, W_CORNER, CORNER_FREE = 0.3, 20.0, 40.0, 2.0
WATER_CLEAR = 2.5  # the steps' edges this far from the Dungchu's water but at the bridge
INTO = {"west": 60.0, "east": 90.0}  # the last leg within this many degrees of its end's axis (the Lookout's gap; the West
# Gate's anyhow: it stands on the face itself, which the way climbs in a zigzag to the last)
OFF = 85.0  # the first leg within this many degrees of the bridge's axis (it may turn along the face at once)
SPLIT_W = (2, 2, 2, 2, 1)  # flights a leg, the west leg (from the bridge up)
SPLIT_E = (2,) * 12  # and the east
TRIALS, SEED = 16, 1902
# The fit's legs' bearings, from a wide search (`--search`); a build lays them out as they are, the ground before the pads
# being the same each time. Rerun the search after the ground is reshaped.
START_W = [296.2152, 355.5670, 325.1939, 225.1939, 263.9869]  # (11 Oct 2026: cost 6,453, the middle 2.0 m off the ground on
# average, cut 3.8 m and filled 8.1 m at most)
START_E = [45.9623, 177.5263, 38.5340, 182.4267, 33.3850, 187.0835, 30.3059, 188.4066, 26.9788, 185.5073, 24.4726, 178.0590]
# (cost 20,181, the middle 1.5 m off the ground on average, cut 6.1 m and filled 6.4 m at most: twelve legs zigzagging up
# the face, each two flights)
GALLERIES = 3  # chapter 02: RNG-08 "with 3 galleries"
HOUSES_OVER, TOP_FLIGHTS, HOUSE, HEADROOM = 3, 5, (6.0, 6.0), 2.9  # monks' houses across the stair's top (chapter 02, 5.3: its
# top 40 m) over the highest flights that take them: an M1's 6 x 6 m,
# its floor this far over the stair's treads at its uphill end (../tibet-blender kit/monastery.py monk_house_over)
REST, RNG09 = (8.0, 2.5), (390.0, 175.0, 2810.0)  # the rest gallery (chapter 02: 8 x 2.5 m at +390, +175, 2,810)
WHEEL_DOWN, WHEEL_FEED, WHEEL_DROP = 26.0, 12.0, 0.9  # the water wheel RNG-04 down the river from the bridge, its channel's
# length up the river, the water's fall inside it (../tibet-blender kit/serchu.py WHEEL_DROP)
RNG05 = (345.0, 230.0)  # the naga shrine (chapter 02: +345, +230)
WATER_TOP, WATER_FOOT, WATER_UP = 2.6, 1.8, 0.5  # the way down to the water: its top landing's length south off the bridge's
# west landing, its foot landing's least length, the foot over the channel's water at its head
FLAG_SPANS = [(-9.0, None, 2800.0), (-34.0, 2830.0, 2810.0), (-58.0, 2850.0, 2825.0), (-82.0, 2868.0, 2835.0), (16.0, 2825.0, 2795.0),
              (40.0, 2845.0, 2790.0)]  # the strings: metres up the river (-) or down from the rest gallery's place, the
# height on the face their east pole stands at (V-17's, the first: the gallery's and 3 m), on the west side their west's
FLAG_POLE, FLAG_SAG = 3.0, 0.07  # a pole's top over its foot; the strings' sag, a share of the span (less where the ground is near)


def unit(deg):
    th = math.radians(deg)
    return np.array([math.sin(th), math.cos(th)])


def bearing(d):
    return math.degrees(math.atan2(d[0], d[1])) % 360.0


def rect(c, w, d, facing, grow=0.0):
    """A footprint's corners: w across its front, d along it, its front facing `facing`."""
    u = unit(facing)
    a = np.array([-u[1], u[0]])
    hw, hd = w / 2 + grow, d / 2 + grow
    c = np.asarray(c, float)
    return np.array([c + a * sa * hw + u * sb * hd for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))])


def inside(P, poly):
    """How far each point lies inside a convex polygon (0 outside)."""
    best = np.full(len(P), np.inf)
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        e = b - a
        n = np.array([e[1], -e[0]]) / max(1e-9, float(np.hypot(*e)))
        if float(np.dot(n, poly.mean(axis=0) - a)) < 0:
            n = -n
        best = np.minimum(best, (P - a) @ n)
    return np.maximum(best, 0.0)


def seg_dist(a, b, c, d):
    """The least distance between two segments."""
    def pt(p, q, r):
        qr = r - q
        t = np.clip(np.dot(p - q, qr) / max(1e-9, np.dot(qr, qr)), 0.0, 1.0)
        return float(np.hypot(*(p - (q + qr * t))))
    return min(pt(a, c, d), pt(b, c, d), pt(c, a, b), pt(d, a, b))


def overlaps(a, b):
    """Two convex quads overlap (separating axes)."""
    for poly in (a, b):
        for i in range(4):
            e = poly[(i + 1) % 4] - poly[i]
            nx, ny = e[1], -e[0]
            pa = a @ np.array([nx, ny])
            pb = b @ np.array([nx, ny])
            if pa.max() < pb.min() or pb.max() < pa.min():
                return False
    return True


def flights_of(n_total, split):
    """Each flight's steps: n_total shared among sum(split) flights as evenly as can be."""
    k = sum(split)
    base, extra = divmod(n_total, k)
    return [base + (1 if i < extra else 0) for i in range(k)]


def lay(angles, foot, z0, riser, split, steps, lead=0.0):
    """The way up from the foot at z0: its legs [(start, unit, length, pieces: (kind, s0, s1, z0, z1, steps, number))] and
    the joins between them [(kind, at, unit, z, number, normal)]: a switchback where the way turns back on itself (its
    landing past the leg's end, the next leg SEP to the side it turns), a bend where it turns less (a landing on along the
    leg, the next leg from its end). `lead`: a level way along the first leg before its first step (off the bridge)."""
    legs, joins = [], []
    S, z, fi = np.array(foot, float), z0, 0
    for k, n_f in enumerate(split):
        d = unit(angles[k])
        s, pieces = 0.0, []
        if k == 0 and lead > 0.0:
            pieces.append(("approach", 0.0, lead, z, z, 0, 0))
            s = lead
        for j in range(n_f):
            n = steps[fi]
            fi += 1
            pieces.append(("flight", s, s + n * TREAD, z, z + n * riser, n, fi))
            s += n * TREAD
            z += n * riser
            if j < n_f - 1:
                pieces.append(("landing", s, s + LAND, z, z, 0, fi))
                s += LAND
        legs.append((S.copy(), d, s, pieces))
        E = S + d * s
        if k == len(split) - 1:
            break
        turn = (angles[k + 1] - angles[k] + 180.0) % 360.0 - 180.0  # (bearings: positive to the right)
        if abs(turn) > TURN_BACK:
            nrm = np.array([-d[1], d[0]]) * (-1.0 if turn > 0 else 1.0)
            joins.append(("turn", E, d, z, fi, nrm))
            S = E + nrm * SEP
        else:
            joins.append(("bend", E, d, z, fi, None))
            S = E + d * LAND
    return legs, joins


def join_box(j):
    """A join's landing's corners: a switchback's spans both legs and TURN past their ends; a bend's is LAND square."""
    kind, E, d, z, _, nrm = j
    nr = np.array([-d[1], d[0]])
    if kind == "turn":
        c = E + nrm * SEP / 2 + d * TURN / 2
        w = SEP + BAND
        return np.array([c + nr * sa * w / 2 + d * sb * TURN / 2 for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    c = E + d * LAND / 2
    return np.array([c + nr * sa * BAND / 2 + d * sb * LAND / 2 for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))])


def make_cost(Z, keeps, water, foot, foot_dir, z0, top, top_dir, z1, split, lead, soft_top=False, into=40.0):
    """The fit's cost (as tools/town/dungrong.py's). `soft_top`: the last leg may run in a cutting (the East leg's top,
    under the monks' houses built across it: chapter 02, 5.3), its cut weighed a tenth of a fill."""
    n_total = int(round((z1 - z0) / RISER))
    riser = (z1 - z0) / n_total
    steps = flights_of(n_total, split)

    def cost(v, rows=None):
        legs, joins = lay(v, foot, z0, riser, split, steps, lead)
        c = 0.0
        for k, (S, d, L, pieces) in enumerate(legs):
            nrm = np.array([-d[1], d[0]])
            ss = np.arange(0.0, L + 0.01, 1.0)
            bed = np.interp(ss, [p[1] for p in pieces] + [pieces[-1][2]], [p[3] for p in pieces] + [pieces[-1][4]])
            P = S[None] + d[None] * ss[:, None]
            mid = Z(P[:, 0], P[:, 1]) - bed
            lft = Z(P[:, 0] + nrm[0] * BAND / 2, P[:, 1] + nrm[1] * BAND / 2) - bed
            rgt = Z(P[:, 0] - nrm[0] * BAND / 2, P[:, 1] - nrm[1] * BAND / 2) - bed
            if np.isnan(mid).any() or np.isnan(lft).any() or np.isnan(rgt).any():
                return 1e12
            if soft_top and k == len(legs) - 1:
                w_ = lambda a_: np.where(a_ > 0.0, 0.1, 1.0) * a_ ** 2
                c += float(np.sum(w_(mid))) + W_EDGE * float(np.sum(w_(lft) + w_(rgt)))
            else:
                c += float(np.sum(mid ** 2)) + W_EDGE * float(np.sum(lft ** 2 + rgt ** 2))
            edges = np.concatenate([P + nrm[None] * BAND / 2, P - nrm[None] * BAND / 2])
            for poly in keeps:
                c += 1e4 * float(np.sum(inside(edges, poly) ** 2))
            if water is not None and len(water):  # off the water (but where the first steps leave the bridge)
                e_ = edges[np.concatenate([ss, ss]) > (lead + 2.0 if k == 0 else -1.0)]
                if len(e_):
                    dist = np.min(np.hypot(e_[:, None, 0] - water[None, :, 0], e_[:, None, 1] - water[None, :, 1]) - water[None, :, 2], axis=1)
                    c += 1e4 * float(np.sum(np.maximum(0.0, WATER_CLEAR - dist) ** 2))
            if rows is not None:
                for kind, s0, s1, za, zb, n, num in pieces:
                    sel = (ss >= s0 - 0.01) & (ss <= s1 + 0.01)
                    rows.append({"leg": k + 1, "kind": kind, "number": num, "n": n, "bearing": bearing(d), "mean": float(np.mean(np.abs(mid[sel]))),
                                 "cut": float(max(np.max(lft[sel]), np.max(rgt[sel]), np.max(mid[sel]), 0.0)),
                                 "fill": float(max(-np.min(lft[sel]), -np.min(rgt[sel]), -np.min(mid[sel]), 0.0))})
        for j in joins:
            box = join_box(j)
            m = box.mean(axis=0)
            c += W_LAND * (float(Z(m[0], m[1])) - j[3]) ** 2
            for q in box:
                c += W_CORNER * max(0.0, abs(float(Z(q[0], q[1])) - j[3]) - CORNER_FREE) ** 2
            for poly in keeps:
                c += 1e4 * float(np.sum(inside(box, poly) ** 2))
        S, d, L, _ = legs[-1]
        c += 1e5 * float(np.sum((S + d * L - np.array(top)) ** 2))
        c += 1e4 * max(0.0, math.degrees(math.acos(max(-1.0, min(1.0, float(np.dot(d, top_dir)))))) - into) ** 2
        c += 1e4 * max(0.0, math.degrees(math.acos(max(-1.0, min(1.0, float(np.dot(legs[0][1], foot_dir)))))) - OFF) ** 2
        segs = [(S, S + d * L) for S, d, L, _ in legs]
        for i in range(len(segs)):  # no leg near another but where they meet
            for jx in range(i + 2, len(segs)):
                c += 1e4 * max(0.0, BAND + 2.0 - seg_dist(*segs[i], *segs[jx])) ** 2
        for i in range(len(segs) - 1):  # a switchback's two legs part from their landing
            if not (i < len(joins) and joins[i][0] == "turn"):
                continue
            a0, a1 = segs[i]
            b0, b1 = segs[i + 1]
            da, db = a1 - a0, b1 - b0
            ua, ub = da / max(1e-6, np.hypot(*da)), db / max(1e-6, np.hypot(*db))
            c += 1e4 * max(0.0, BAND + 0.4 - seg_dist(a0, a1 - ua * 5.0, b0 + ub * 5.0, b1)) ** 2
        return c
    return cost, riser, steps


def zigzag(Z, foot, z0, riser, split, steps, lead, first_side, jitter, rng):
    """A first guess at the legs' bearings, leg by leg up the ground: each leg across its start's fall line at the angle
    that makes its grade the ground's (a path at grade g on a slope of angle a runs acos(g / tan a) off the fall line),
    to alternate sides, so the way zigzags with the ground; `jitter` degrees of noise on each."""
    v = []
    side = first_side
    for k in range(len(split)):
        legs, _ = lay(v + [0.0] * (len(split) - len(v)), foot, z0, riser, split, steps, lead)
        S = legs[k][0]
        e = 2.0
        gx = (float(Z(S[0] + e, S[1])) - float(Z(S[0] - e, S[1]))) / (2 * e)
        gy = (float(Z(S[0], S[1] + e)) - float(Z(S[0], S[1] - e))) / (2 * e)
        up = bearing(np.array([gx, gy]))
        slope = math.hypot(gx, gy)
        n_k = sum(steps[sum(split[:k]):sum(split[:k + 1])])
        L_k = n_k * TREAD + (split[k] - 1) * LAND
        grade = n_k * riser / max(L_k, 0.1)
        phi = math.degrees(math.acos(min(1.0, grade / max(slope, 1e-3))))
        v.append(up + side * phi + rng.normal(0.0, jitter))
        side = -side
    return v


def fit(name, cost, k, foot_dir, top, foot, start, search, rng, guess=None):
    """The legs' bearings: a build refines START a little; `--search` refines TRIALS zigzags up the ground (`guess`,
    each with its own noise and first side) and keeps the best."""
    if not search and start is not None:
        r = minimize(cost, np.array(start), method="Powell", options={"maxiter": 3, "xtol": 0.005, "ftol": 1e-7})
        return r.fun, r.x
    found = []
    climb = bearing(np.array(top) - np.array(foot))
    for trial in range(TRIALS):
        if trial % 2 == 0:  # a zigzag up the ground
            v = np.array(guess(trial // 2), float)
        else:  # or at random across the climb's line
            side = rng.choice([-1.0, 1.0])
            a = rng.uniform(30.0, 80.0)
            v = np.array([climb + (a if (i % 2 == 0) else -a) * side for i in range(k)], float) + rng.normal(0, 6, k)
        r = minimize(cost, v, method="Powell", options={"maxiter": 3000, "xtol": 0.02, "ftol": 1e-6})
        r = minimize(cost, r.x, method="Nelder-Mead", options={"maxiter": 6000, "maxfev": 6000, "xatol": 0.02, "fatol": 0.5, "adaptive": True})
        r = minimize(cost, r.x, method="Powell", options={"maxiter": 3000, "xtol": 0.01, "ftol": 1e-7})
        found.append((r.fun, r.x))
        print("gorge_stair: %s trial %d: cost %.0f" % (name, trial, r.fun), flush=True)
    found.sort(key=lambda q: q[0])
    return found[0]


def lanes_of(prefix, legs, joins, file_prefix, k0=0):
    """The pieces as lanes in pads.py's form, numbered from k0: each flight (export_lanes.py builds it, its treads cut in
    the rock), each landing between flights and each switchback's or bend's landing (flagged, no walls of their own)."""
    out = []
    fl_no = k0

    def piece(lid, S, d, s0, s1, z0, z1, n, kind):
        o = S + d * s0
        L = s1 - s0
        ln = {"id": lid, "from": [round(float(o[0]), 3), round(float(o[1]), 3)], "dir": [round(float(d[0]), 5), round(float(d[1]), 5)],
              "length": round(float(L), 3), "width": WIDTH, "z_a": round(z0, 3), "z_b": round(z1, 3),
              "profile": [[0.0, round(z0 - (0.25 if kind == "flight" else 0.1), 3)], [round(float(L), 3), round(z1 - (0.25 if kind == "flight" else 0.1), 3)]], "steps": True}
        if kind == "flight":
            ln["flight"] = {"file": "%s_%s" % (file_prefix, lid.split(".")[1].lower()), "s": 0.0, "rise": round(z1 - z0, 3), "z": round(z0, 3),
                            "n": n, "run": TREAD, "top": 0.0, "walls": None}
        else:
            ln["flight"] = {"file": "%s_%s" % (file_prefix, lid.split(".")[1].lower()), "s": 0.0, "rise": 0.0, "z": round(z0, 3), "n": 0,
                            "length": round(float(L), 3), "walls": None}
        return ln

    for k, (S, d, L, pieces) in enumerate(legs):
        for kind, s0, s1, za, zb, n, num in pieces:
            if kind == "flight":
                fl_no += 1
                out.append(piece("%s.F%02d" % (prefix, fl_no), S, d, s0, s1, za, zb, n, "flight"))
            else:
                out.append(piece("%s.L%02d" % (prefix, fl_no if kind == "landing" else 0), S, d, s0, s1, za, zb, 0, kind))
        if k < len(joins):
            j = joins[k]
            kind, E, d_, z, num, nrm = j
            box = join_box(j)
            c = box.mean(axis=0)
            if kind == "turn":  # across the two legs' ends, its length along them TURN, its width both legs' bands
                o = c - d_ * TURN / 2
                ln = {"id": "%s.T%02d" % (prefix, fl_no), "from": [round(float(o[0]), 3), round(float(o[1]), 3)], "dir": [round(float(d_[0]), 5), round(float(d_[1]), 5)],
                      "length": TURN, "width": round(SEP + BAND, 3), "z_a": round(z, 3), "z_b": round(z, 3),
                      "profile": [[0.0, round(z - 0.1, 3)], [TURN, round(z - 0.1, 3)]], "steps": True,
                      "flight": {"file": "%s_t%02d" % (file_prefix, fl_no), "s": 0.0, "rise": 0.0, "z": round(z, 3), "n": 0, "length": TURN, "walls": None}}
            else:
                o = E
                ln = {"id": "%s.B%02d" % (prefix, fl_no), "from": [round(float(o[0]), 3), round(float(o[1]), 3)], "dir": [round(float(d_[0]), 5), round(float(d_[1]), 5)],
                      "length": LAND, "width": WIDTH, "z_a": round(z, 3), "z_b": round(z, 3),
                      "profile": [[0.0, round(z - 0.1, 3)], [LAND, round(z - 0.1, 3)]], "steps": True,
                      "flight": {"file": "%s_b%02d" % (file_prefix, fl_no), "s": 0.0, "rise": 0.0, "z": round(z, 3), "n": 0, "length": LAND, "walls": None}}
            out.append(ln)
    for ln in out:  # landings named by the flight they top; an approach's own
        if ln["id"].endswith(".L00"):
            ln["id"] = ln["id"].replace(".L00", ".A01")
            ln["flight"]["file"] = ln["flight"]["file"].replace("_l00", "_a01")
    return out, fl_no


def walk_of(legs, joins, every=4.0):
    """The way's middle, every few metres, round each join: [x, y, z]."""
    pts = []
    for k, (S, d, L, pieces) in enumerate(legs):
        ss = list(np.arange(0.0, L, every)) + [L]
        for s in ss:
            z = float(np.interp(s, [p[1] for p in pieces] + [pieces[-1][2]], [p[3] for p in pieces] + [pieces[-1][4]]))
            q = S + d * s
            pts.append([round(float(q[0]), 2), round(float(q[1]), 2), round(z, 3)])
        if k < len(joins):
            kind, E, d_, z, num, nrm = joins[k]
            if kind == "turn":  # round the switchback's landing
                a = E + d_ * TURN * 0.6
                b = E + nrm * SEP + d_ * TURN * 0.6
                pts.append([round(float(a[0]), 2), round(float(a[1]), 2), round(z, 3)])
                pts.append([round(float(b[0]), 2), round(float(b[1]), 2), round(z, 3)])
    return pts


def main():
    site = Site.load()
    g = site.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site.shift
    search = "--search" in sys.argv
    rng = np.random.default_rng(SEED)
    rivers = json.load(open(RIVERS, encoding="utf-8"))["rivers"]
    rv = next(r for r in rivers if "gorge" in r.get("name", ""))
    pts = rv["pts"]
    # the bridge: across the Dungchu where the gorge at BRIDGE_H over the water is nearest the span and its abutments
    if search:
        best = None
        for i in range(1, len(pts) - 1):
            q = pts[i]
            dch = math.hypot(q[0] - BRIDGE[0], q[1] - BRIDGE[1])
            if dch > 40.0:
                continue
            t = np.array([pts[i + 1][0] - pts[i - 1][0], pts[i + 1][1] - pts[i - 1][1]], float)
            t /= np.hypot(*t)
            n = np.array([-t[1], t[0]])
            if n[0] < 0:
                n = -n  # (west to east)
            ends = []
            for sgn in (1, -1):
                s = np.arange(2.0, 40.0, 0.25)
                P = np.array(q[:2])[None] + (sgn * n)[None] * s[:, None]
                zz = Z(P[:, 0], P[:, 1])
                kk = int(np.argmax(zz >= q[2] + BRIDGE_H))
                ends.append(float(s[kk]) if zz[kk] >= q[2] + BRIDGE_H else 99.0)
            score = abs(ends[0] + ends[1] - (SPAN + 2 * ABUT)) + 0.05 * dch
            if best is None or score < best[0]:
                best = (score, (round(q[0], 1), round(q[1], 1)), round(bearing(n), 1), round(q[2], 1))
        print("gorge_stair: the bridge's search: BRIDGE_MID, BRIDGE_AXIS, BRIDGE_WATER = %s, %s, %s" % best[1:])
        mid, axis, water_z = np.array(best[1]), best[2], best[3]
    else:
        mid, axis, water_z = np.array(BRIDGE_MID), BRIDGE_AXIS, BRIDGE_WATER
    deck = water_z + BRIDGE_H
    ax = unit(axis)
    w_end = mid - ax * (SPAN / 2 + DECK_PAST)
    e_end = mid + ax * (SPAN / 2 + DECK_PAST)
    water = np.array([[q[0], q[1], max(q[3], q[4])] for q in pts if math.hypot(q[0] - mid[0], q[1] - mid[1]) < 200.0])
    # the Lookout's gap: its south-east side (the kit's -x), GAP_BACK in from its back edge
    f = unit(LOOKOUT_FACING)
    se = np.array([f[1], -f[0]])  # (the terrace's right, looking out at its view)
    back = -f
    gap = np.array(LOOKOUT) + se * LOOKOUT_SIZE[0] / 2 + back * (LOOKOUT_SIZE[1] / 2 - GAP_BACK)
    head = gap + se * LAND  # the west leg's top: a landing out from the gap, then down
    # the gate's top: the east leg's last landing before the West Gate, on the line from the gorge
    gate = np.array(GATE)
    toward = gate - e_end
    toward /= np.hypot(*toward)
    gate_top = gate - toward * GATE_OUT
    gate_z = float(Z(gate[0], gate[1])) + GATE_Z_ABOVE
    # keep clear (the west leg): the Lookout's terrace (but its gap), the garden lane and its plots' walls near it, every 4 m
    keeps_w = [rect(LOOKOUT, LOOKOUT_SIZE[0], LOOKOUT_SIZE[1], LOOKOUT_FACING, 0.8)]
    near = lambda q: math.hypot(q[0] - LOOKOUT[0], q[1] - LOOKOUT[1]) < 60.0
    if os.path.exists(GARDENS):
        gj = json.load(open(GARDENS, encoding="utf-8"))
        for ln in gj["lanes"]:
            o, d_ = np.array(ln["from"], float), np.array(ln["dir"], float)
            if not (near(o) or near(o + d_ * ln["length"])):
                continue
            c_ = o + d_ * ln["length"] / 2
            keeps_w.append(rect(c_, ln["width"] + 1.0, ln["length"], bearing(d_), 0.5))
        for wl in gj["walls"]:
            q = np.array([p[:2] for p in wl["pts"]], float)[::4]
            for a_, b_ in zip(q[:-1], q[1:]):
                d_ = b_ - a_
                L_ = float(np.hypot(*d_))
                if L_ > 0.01 and (near(a_) or near(b_)):
                    keeps_w.append(rect((a_ + b_) / 2, 0.6, L_, bearing(d_), 0.5))
    # the west leg, from the bridge's west end up to the Lookout's gap; the east, from its east end up to the West Gate
    out = {"lanes": [], "walk": [], "legs": {}}
    report = []
    starts = {"west": START_W, "east": START_E}
    found = {}
    for name, foot, foot_dir, z0, top, top_dir, z1, split, prefix, keeps in (
            ("west", w_end, -ax, deck, head, -se, LOOKOUT_Z, SPLIT_W, "R07W", keeps_w),
            ("east", e_end, ax, deck, gate_top, toward, gate_z, SPLIT_E, "R07E", [])):
        lead = 1.6  # off the abutment's end along the bridge's axis before the first step
        cost, riser, steps = make_cost(Z, keeps, water, foot, foot_dir, z0, top, top_dir, z1, split, lead, soft_top=(name == "east"), into=INTO[name])
        guess = lambda t, foot=foot, z0=z0, riser=riser, split=split, steps=steps, lead=lead: zigzag(
            Z, foot, z0, riser, split, steps, lead, 1.0 if t % 2 == 0 else -1.0, 0.0 if t < 2 else 6.0, rng)
        fun, v = fit(name, cost, len(split), foot_dir, top, foot, starts[name], search, rng, guess)
        if search:
            print("gorge_stair: the search's %s legs: START_%s = [%s]" % (name, name[0].upper(), ", ".join("%.4f" % a_ for a_ in v)))
        rows = []
        cost(v, rows)
        legs, joins = lay(v, foot, z0, riser, split, steps, lead)
        found[name] = (fun, v, legs, joins, riser)
        lanes, nf = lanes_of(prefix, legs, joins, "gorge_" + name[0])
        S_, d_, L_, _ = legs[-1]
        end = S_ + d_ * L_
        last = gap if name == "west" else gate  # on level from the last flight into the Lookout's gap, or to the gate
        tl = last - end
        tL = float(np.hypot(*tl))
        if tL > 0.2:
            tu = tl / tL
            lanes.append({"id": "%s.L%02d" % (prefix, nf), "from": [round(float(end[0]), 3), round(float(end[1]), 3)], "dir": [round(float(tu[0]), 5), round(float(tu[1]), 5)],
                          "length": round(tL, 3), "width": WIDTH, "z_a": round(z1, 3), "z_b": round(z1, 3),
                          "profile": [[0.0, round(z1 - 0.1, 3)], [round(tL, 3), round(z1 - 0.1, 3)]], "steps": True,
                          "flight": {"file": "gorge_%s_l%02d" % (name[0], nf), "s": 0.0, "rise": 0.0, "z": round(z1, 3), "n": 0, "length": round(tL, 3), "walls": None}})
        out["lanes"] += lanes
        walk = walk_of(legs, joins)
        out["legs"][name] = {"steps": int(sum(steps)), "riser": round(riser, 4), "flights": len(steps), "bearings": [round(float(a_), 2) for a_ in v],
                             "cost": round(float(fun), 1), "foot": [round(float(foot[0]), 2), round(float(foot[1]), 2), round(z0, 3)],
                             "top": [round(float(top[0]), 2), round(float(top[1]), 2), round(z1, 3)], "walk": walk}
        report.append((name, rows, steps, riser, fun))
    # the galleries' places: the east leg's flights standing highest over the ground on their outer side
    ef = [r for r in report[1][1] if r["kind"] == "flight"]
    ef.sort(key=lambda r: -r["fill"])
    gal = sorted(r["number"] for r in ef[:GALLERIES])
    for ln in out["lanes"]:
        if ln["id"].startswith("R07E.F") and int(ln["id"][6:]) in gal:
            ln["gallery"] = True  # (pads.py cuts its bed but never fills under it; walls.py leaves it unwalled)
            o_, d_ = np.array(ln["from"], float), np.array(ln["dir"], float)
            m_ = o_ + d_ * ln["length"] / 2
            right = np.array([d_[1], -d_[0]])
            ln["flight"]["inner"] = 1 if float(Z(*(m_ + right * 2.0))) > float(Z(*(m_ - right * 2.0))) else -1  # (the kit's +x
            # is the lane's right going up: its beams go into the rock on that side)
            ln["flight"]["gallery"] = True
    things = []
    rects = [(ln["id"], np.array([np.array(ln["from"]) + np.array([-ln["dir"][1], ln["dir"][0]]) * sa * ln["width"] / 2 + np.array(ln["dir"]) * sb * ln["length"]
                                  for sa, sb in ((-1, 0), (1, 0), (1, 1), (-1, 1))])) for ln in out["lanes"]]

    def clear_of(poly, own):
        for lid, r in rects:
            if lid != own and overlaps(poly, r):
                return False
        return True

    # the top 40 m under monks' houses built across the stair on beams (chapter 02, 5.3): the highest flights that take a
    # 6 x 6 m house over their middles clear of the stair's other pieces, three of them
    top_no = max(int(ln["id"][6:]) for ln in out["lanes"] if ln["id"].startswith("R07E.F"))
    efl = [ln for ln in out["lanes"] if ln["id"].startswith("R07E.F") and not ln.get("gallery") and int(ln["id"][6:]) > top_no - TOP_FLIGHTS]
    efl.sort(key=lambda ln: -int(ln["id"][6:]))
    for ln in efl:
        if len([t for t in things if t["kind"] == "house_over"]) >= HOUSES_OVER:
            break
        o_, d_ = np.array(ln["from"], float), np.array(ln["dir"], float)
        c_ = o_ + d_ * ln["length"] / 2
        left = np.array([-d_[1], d_[0]])
        front = left if float(Z(*(c_ + left * 4.0))) < float(Z(*(c_ - left * 4.0))) else -left  # (its front to the gorge, the
        # stair passing under it along its x: ../tibet-blender kit/monastery.py monk_house_over)
        f_ = bearing(front)
        kx = np.array([-math.cos(math.radians(f_)), math.sin(math.radians(f_))])
        up = 1 if float(np.dot(d_, kx)) > 0 else -1
        poly = rect(c_, HOUSE[0], HOUSE[1], f_, 0.3)
        if not clear_of(poly, ln["id"]):
            continue
        z_up = ln["z_a"] + (ln["length"] / 2 + HOUSE[1] / 2) / ln["length"] * (ln["z_b"] - ln["z_a"])
        k_ = len([t for t in things if t["kind"] == "house_over"])
        things.append({"id": "R07.H%d" % (k_ + 1), "kind": "house_over", "kit": "monk_house_over_%s_v%d" % ("r" if up > 0 else "l", 1 + k_ % 3),
                       "at": [round(float(c_[0]), 2), round(float(c_[1]), 2)], "level": round(z_up + HEADROOM, 3), "facing": round(f_, 1), "over": ln["id"]})
        rects.append((things[-1]["id"], poly))
    # the rest gallery RNG-09 halfway up (chapter 02: +390, +175, 2,810; 8 x 2.5 m, roofed, a prayer wheel and a bench):
    # along the face on from the switchback's landing nearest its place, its back to the rock, its front over the gorge
    _, _, elegs, ejoins, _ = found["east"]
    best = None
    for j in ejoins:
        kind, E, d_, z, num, nrm = j
        if kind != "turn":
            continue
        c_ = E + nrm * SEP / 2 + d_ * (TURN + 0.2 + REST[0] / 2)
        gx = (float(Z(c_[0] + 2, c_[1])) - float(Z(c_[0] - 2, c_[1]))) / 4
        gy = (float(Z(c_[0], c_[1] + 2)) - float(Z(c_[0], c_[1] - 2))) / 4
        down = -np.array([gx, gy])
        out_ = down - d_ * float(np.dot(down, d_))
        if np.hypot(*out_) < 1e-6:
            continue
        out_ /= np.hypot(*out_)
        poly = rect(c_, REST[0], REST[1], bearing(out_), 0.2)
        if not clear_of(poly, None):
            continue
        dd = math.hypot(c_[0] - RNG09[0], c_[1] - RNG09[1]) + 0.5 * abs(z - RNG09[2])
        if best is None or dd < best[0]:
            best = (dd, c_, out_, z, d_, num)
    if best is not None:
        _, c_, out_, z, d_, num = best
        things.append({"id": "RNG-09", "kind": "rest_gallery", "kit": "rng09_rest_gallery_v1", "at": [round(float(c_[0]), 2), round(float(c_[1]), 2)],
                       "level": round(z, 3), "facing": round(bearing(out_), 1), "after_turn": num, "wheels": True})
        o_ = c_ - d_ * REST[0] / 2
        out["lanes"].append({"id": "R07E.G%02d" % num, "from": [round(float(o_[0]), 3), round(float(o_[1]), 3)], "dir": [round(float(d_[0]), 5), round(float(d_[1]), 5)],
                             "length": REST[0], "width": REST[1] + 0.6, "z_a": round(z, 3), "z_b": round(z, 3),
                             "profile": [[0.0, round(z - 0.1, 3)], [REST[0], round(z - 0.1, 3)]], "steps": True, "gallery": True, "flight": None})  # (its
        # ground cut to its floor, the gallery the kit's: rng09_rest_gallery)
        back = -out_
        seat = c_ + back * 0.75
        out["v17"] = {"seat": [round(float(seat[0]), 2), round(float(seat[1]), 2), round(z, 3)], "facing": round(bearing(out_), 1)}
    # the gorge's water prayer wheel RNG-04 (chapter 02: on a side channel by the upper bridge; chapter 03's water wheels):
    # the Serchu's wheel house (../tibet-blender kit/serchu.py water_wheel_house: its water in at its +x at its level, out
    # under its -x WHEEL_DROP lower) on the west bank WHEEL_DOWN m down the river from the bridge, fed by a channel from the
    # river's edge WHEEL_FEED m above it, its race back down to the water
    cum = [0.0]
    for a_, b_ in zip(pts[:-1], pts[1:]):
        cum.append(cum[-1] + math.hypot(b_[0] - a_[0], b_[1] - a_[1]))
    kb = min(range(len(pts)), key=lambda i: math.hypot(pts[i][0] - mid[0], pts[i][1] - mid[1]))

    def along(s_):  # the river's point s_ m down from the bridge: (x, y, water, half-width, downstream unit)
        tgt = cum[kb] + s_
        i = max(1, min(len(pts) - 1, next((k for k in range(len(cum)) if cum[k] >= tgt), len(cum) - 1)))
        a_, b_ = pts[i - 1], pts[i]
        f_ = (tgt - cum[i - 1]) / max(cum[i] - cum[i - 1], 1e-6)
        t_ = np.array([b_[0] - a_[0], b_[1] - a_[1]], float)
        t_ /= max(np.hypot(*t_), 1e-6)
        return (np.array([a_[0] + (b_[0] - a_[0]) * f_, a_[1] + (b_[1] - a_[1]) * f_]), a_[2] + (b_[2] - a_[2]) * f_,
                max(a_[3], a_[4], b_[3], b_[4]), t_)

    P_, wP, hP, tP = along(WHEEL_DOWN)
    I_, wI, hI, tI = along(WHEEL_DOWN - WHEEL_FEED)
    rP, rI = np.array([tP[1], -tP[0]]), np.array([tI[1], -tI[0]])  # (the right bank looking downstream: the west)
    H_ = P_ + rP * (hP + 1.5 + 1.25)
    z0 = wI - 0.25
    i_bank = I_ + rI * (hI + 0.3)
    u_ = i_bank - H_
    u_ /= np.hypot(*u_)
    f_w = (bearing(u_) + 90.0) % 360.0  # (the kit's +x up the channel)
    in_ = H_ + u_ * 1.25
    out_ = H_ - u_ * 1.25
    R_ = min(pts, key=lambda q: math.hypot(q[0] - out_[0], q[1] - out_[1]))
    r_edge = np.array(R_[:2]) + (out_ - np.array(R_[:2])) / max(np.hypot(*(out_ - np.array(R_[:2]))), 1e-6) * max(0.0, max(R_[3], R_[4]) - 0.4)
    out["wheel"] = {"id": "RNG-04", "at": [round(float(H_[0]), 2), round(float(H_[1]), 2)], "level": round(z0, 3), "facing": round(f_w, 1)}
    feed = [[round(float(i_bank[0] + (in_[0] - i_bank[0]) * t), 2), round(float(i_bank[1] + (in_[1] - i_bank[1]) * t), 2), round(wI + (z0 - wI) * t, 3)]
            for t in np.linspace(0.0, 1.0, max(2, int(np.hypot(*(in_ - i_bank))) + 1))]
    race = [[round(float(out_[0]), 2), round(float(out_[1]), 2), round(z0 - WHEEL_DROP, 3)], [round(float(r_edge[0]), 2), round(float(r_edge[1]), 2), round(float(R_[2]), 3)]]
    out["leat"] = [{"id": "RNG-04.feed", "pts": feed}, {"id": "RNG-04.race", "pts": race, "race": True}]
    out["chutes"] = []
    for nm, a_, b_, za, zb, w_ in (("RNG-04.F", i_bank, in_, wI - 0.3, z0 - 0.3, 1.1), ("RNG-04.R", out_, r_edge, z0 - WHEEL_DROP - 0.3, float(R_[2]) - 0.3, 1.0)):
        d_ = b_ - a_
        L_ = float(np.hypot(*d_))
        if L_ < 0.2:
            continue
        d_ /= L_
        out["lanes"].append({"id": nm, "from": [round(float(a_[0]), 3), round(float(a_[1]), 3)], "dir": [round(float(d_[0]), 5), round(float(d_[1]), 5)],
                             "length": round(L_, 3), "width": w_, "z_a": round(za, 3), "z_b": round(zb, 3),
                             "profile": [[0.0, round(za, 3)], [round(L_, 3), round(zb, 3)]], "channel": True, "flight": None})
    out["lanes"].append({"id": "RNG-04.H", "from": [round(float(out_[0] - u_[0] * 0.3), 3), round(float(out_[1] - u_[1] * 0.3), 3)], "dir": [round(float(u_[0]), 5), round(float(u_[1]), 5)],
                         "length": 3.1, "width": 3.0, "z_a": round(z0 - WHEEL_DROP - 1.1, 3), "z_b": round(z0 - WHEEL_DROP - 1.1, 3),
                         "profile": [[0.0, round(z0 - WHEEL_DROP - 0.5, 3)], [3.1, round(z0 - WHEEL_DROP - 0.5, 3)]], "channel": True, "flight": None})  # (its ground
    # cut down to where its walls stand, under its floor's water)
    # the way down to the water (the game's M3 sprint 2, step 6; chapter 02, D07: "water carriers"): from the bridge's west
    # landing south round the back of its abutment and down the bank in two flights to a landing beside the channel's head,
    # where Tödé's women fill their barrels from the Dungchu's water running into it (`water`)
    dn = unit(axis + 90.0)  # (across the bridge's axis, down the river)
    u_top = -(SPAN / 2 + ABUT + WIDTH / 2 + 0.1)  # the way's middle clear of the abutment's back
    t0 = mid + ax * u_top
    t1 = t0 + dn * WATER_TOP
    fill = i_bank - ax * 0.55  # the channel's west edge at its head
    f_end = fill - ax * (WIDTH / 2 + 0.25)
    d_w = f_end - t1
    L_w = float(np.hypot(*d_w))
    d_w /= L_w
    z_f = wI + WATER_UP
    n_w = max(2, int(round((deck - z_f) / RISER)))
    r_w = (deck - z_f) / n_w
    n1, n2 = n_w - n_w // 2, n_w // 2
    if L_w < (n1 + n2) * TREAD + LAND + WATER_FOOT:
        print("gorge_stair: WARNING the way down to the water has %.1f m for %.1f m of flights and landings" % (L_w, (n1 + n2) * TREAD + LAND + WATER_FOOT))

    def w_piece(lid, o, d_, L_, za, zb, n_, fname):
        ln = {"id": lid, "from": [round(float(o[0]), 3), round(float(o[1]), 3)], "dir": [round(float(d_[0]), 5), round(float(d_[1]), 5)],
              "length": round(float(L_), 3), "width": WIDTH, "z_a": round(za, 3), "z_b": round(zb, 3),
              "profile": [[0.0, round(za - (0.25 if n_ else 0.1), 3)], [round(float(L_), 3), round(zb - (0.25 if n_ else 0.1), 3)]], "steps": True}
        if n_:
            ln["flight"] = {"file": fname, "s": 0.0, "rise": round(zb - za, 3), "z": round(za, 3), "n": n_, "run": TREAD, "top": 0.0, "walls": None}
        else:
            ln["flight"] = {"file": fname, "s": 0.0, "rise": 0.0, "z": round(za, 3), "n": 0, "length": round(float(L_), 3), "walls": None}
        return ln

    a1 = t1 + d_w * n1 * TREAD
    a2 = a1 + d_w * LAND
    a3 = a2 + d_w * n2 * TREAD
    z1_ = deck - n1 * r_w
    # (each flight laid from its foot up, as export_lanes.py builds one: `from` its foot, `dir` up it)
    out["lanes"] += [w_piece("R07W.W01", t0 - dn * (WIDTH / 2), dn, WATER_TOP + WIDTH / 2, deck, deck, 0, "gorge_w_w01"),
                     w_piece("R07W.WF1", a1, -d_w, n1 * TREAD, z1_, deck, n1, "gorge_w_wf1"),
                     w_piece("R07W.W02", a1, d_w, LAND, z1_, z1_, 0, "gorge_w_w02"),
                     w_piece("R07W.WF2", a3, -d_w, n2 * TREAD, z_f, z1_, n2, "gorge_w_wf2"),
                     w_piece("R07W.W03", a3, d_w, float(np.hypot(*(f_end - a3))), z_f, z_f, 0, "gorge_w_w03")]
    out["water"] = {"path": [[round(float(q[0]), 2), round(float(q[1]), 2), round(float(z_), 3)] for q, z_ in
                             ((t0, deck), (t1, deck), (a1, z1_), (a2, z1_), (a3, z_f), (f_end, z_f))],
                    "fill": [round(float(fill[0]), 2), round(float(fill[1]), 2), round(float(wI), 3)], "steps": n_w, "riser": round(r_w, 4)}
    # the naga shrine and its spring RNG-05 (chapter 02: under an overhang, +345, +230, 2,735; offerings of milk): on the
    # east bank where the river passes nearest the chapter's place, its pool a metre from the water, its back in the face
    qn = min(pts, key=lambda q: math.hypot(q[0] - RNG05[0], q[1] - RNG05[1]))
    kq = pts.index(qn)
    tq = np.array([pts[kq + 1][0] - pts[kq - 1][0], pts[kq + 1][1] - pts[kq - 1][1]], float)
    tq /= np.hypot(*tq)
    east = np.array([-tq[1], tq[0]])  # (the left bank looking downstream: the east)
    c_ = np.array(qn[:2]) + east * (max(qn[3], qn[4]) + 2.4)
    zn = float(qn[2]) + 1.0
    things.append({"id": "RNG-05", "kind": "naga_shrine", "kit": "rng05_naga_shrine_v1", "at": [round(float(c_[0]), 2), round(float(c_[1]), 2)],
                   "level": round(zn, 3), "facing": round(bearing(-east), 1)})
    o_ = c_ - east * 1.8
    out["lanes"].append({"id": "RNG-05.P", "from": [round(float(o_[0]), 3), round(float(o_[1]), 3)], "dir": [round(float(east[0]), 5), round(float(east[1]), 5)],
                         "length": 3.6, "width": 4.6, "z_a": round(zn, 3), "z_b": round(zn, 3), "profile": [[0.0, round(zn - 0.05, 3)], [3.6, round(zn - 0.05, 3)]],
                         "steps": True, "gallery": True, "flight": None})  # (its ground cut back to its floor, the rock the kit's)
    # the six flag strings across the gorge RNG-06 (chapter 02: y +120 to +260, 180-240 m, from Tödé's rim to the
    # monastery's face; chapter 08, V-17: the nearest at eye level 8 m out from the rest gallery, the others stepping away
    # up and down the gorge): each across the river from a pole on the west side to one on the face, its sag kept 2 m over
    # the ground between them
    gal_ = next((t for t in things if t["kind"] == "rest_gallery"), None)
    spans = []
    if gal_ is not None:
        G_ = np.array(gal_["at"], float)
        kg = min(range(len(pts)), key=lambda i: math.hypot(pts[i][0] - G_[0], pts[i][1] - G_[1]))
        for off, z_e, z_w in FLAG_SPANS:
            tgt = cum[kg] + off
            i = max(1, min(len(pts) - 2, next((k for k in range(len(cum)) if cum[k] >= tgt), len(cum) - 2)))
            R_ = np.array(pts[i][:2], float)
            t_ = np.array([pts[i + 1][0] - pts[i - 1][0], pts[i + 1][1] - pts[i - 1][1]], float)
            t_ /= np.hypot(*t_)
            east_ = np.array([-t_[1], t_[0]])
            if np.dot(east_, G_ - R_) < 0:
                east_ = -east_

            def reach(d_, z_t):  # out from the river along d_ to where the ground first stands at z_t (or its highest)
                best_ = (None, -1e9)
                for r in np.arange(3.0, 260.0, 1.0):
                    q = R_ + d_ * r
                    zq = float(Z(q[0], q[1]))
                    if zq >= z_t:
                        return q, zq
                    if zq > best_[1]:
                        best_ = (q, zq)
                return best_

            e_q, e_z = reach(east_, (float(gal_["level"]) + 1.0) if z_e is None else z_e)  # (V-17's, the first: its pole on
            # the face beside the gallery, 8 m from it, at its eye's height; the view from the gallery runs along the strings)
            w_q, w_z = reach(-east_, z_w)
            if e_q is None or w_q is None:
                continue
            a_ = np.array([w_q[0], w_q[1], w_z + FLAG_POLE])
            b_ = np.array([e_q[0], e_q[1], e_z + FLAG_POLE])
            L_ = float(np.hypot(*(b_[:2] - a_[:2])))
            sag = L_ * FLAG_SAG
            ts = np.linspace(0.04, 0.96, 60)
            while sag > 0.0:
                ok = True
                for t in ts:
                    q = a_ + (b_ - a_) * t
                    if q[2] - 4.0 * sag * t * (1.0 - t) < float(Z(q[0], q[1])) + 2.0:
                        ok = False
                        break
                if ok:
                    break
                sag -= 1.0
            if sag < 0.0:
                continue
            spans.append({"a": [round(float(a_[0]), 2), round(float(a_[1]), 2), round(float(a_[2]), 2)], "b": [round(float(b_[0]), 2), round(float(b_[1]), 2), round(float(b_[2]), 2)],
                          "sag": round(float(sag), 2), "span": round(L_, 1), "v17": off == FLAG_SPANS[0][0]})
    out["flags"] = spans
    out["things"] = things
    # the walk: from the Lookout's gap down the west leg, over the bridge, up the east leg to the West Gate
    wl = out["legs"]["west"]["walk"]
    el = out["legs"]["east"]["walk"]
    inner = gap - se * 1.5  # on the terrace, by its gap
    way = [[round(float(inner[0]), 2), round(float(inner[1]), 2), LOOKOUT_Z], [round(float(gap[0]), 2), round(float(gap[1]), 2), LOOKOUT_Z]]
    way += list(reversed(wl))
    way += [[round(float(w_end[0]), 2), round(float(w_end[1]), 2), round(deck, 3)], [round(float(mid[0]), 2), round(float(mid[1]), 2), round(deck, 3)],
            [round(float(e_end[0]), 2), round(float(e_end[1]), 2), round(deck, 3)]]
    way += el
    way.append([round(float(gate[0]), 2), round(float(gate[1]), 2), round(gate_z, 3)])
    out["walk"] = way
    out["places"] = {"RNG-02": {"at": [round(float(mid[0]), 2), round(float(mid[1]), 2)], "level": round(deck, 3), "facing": round((axis + 180.0) % 360.0, 1)}}  # (the kit's
    # bridge lies along its y, its -y end facing `facing`: west, as the Conch Bridge's)
    out["bridge"] = {"mid": [round(float(mid[0]), 2), round(float(mid[1]), 2)], "axis": axis, "water": water_z, "deck": round(deck, 3), "span": SPAN,
                     "w_end": [round(float(w_end[0]), 2), round(float(w_end[1]), 2)], "e_end": [round(float(e_end[0]), 2), round(float(e_end[1]), 2)]}
    out["lookout_gap"] = {"at": [round(float(gap[0]), 2), round(float(gap[1]), 2)], "z": LOOKOUT_Z, "out": [round(float(se[0]), 4), round(float(se[1]), 4)]}
    out["gate"] = {"at": list(GATE), "top": [round(float(gate_top[0]), 2), round(float(gate_top[1]), 2), round(gate_z, 3)]}
    out["galleries"] = gal
    out["about"] = ("The Gorge Stair R-07 (tools/town/gorge_stair.py; M3 sprint 2, step 1): the west leg's and the east leg's flights and "
                    "landings as lanes (pads.py's form, `steps`: carved, walled where cut or filled, built by ../tibet-blender export_lanes.py), "
                    "the walk from the Gorge Rim Lookout's gap over the upper bridge RNG-02 (`places`, `bridge`) to the West Gate, the galleries' "
                    "flights (`gallery`).")
    json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    lines = ["# The Gorge Stair R-07 (tools/town/gorge_stair.py)", "",
             "_What this is: the planner's report, rewritten each run (M3 sprint 2, step 1). The way from the Gorge Rim Lookout's gap down the gorge's west wall, over the upper bridge RNG-02 and up the east face to the West Gate MON-18; each flight's and landing's fit to the ground (the shaped raster before the pads): the mean height of the ground over its middle, the deepest cut and the highest fill across its 1.8 m band._", "",
             "- The bridge RNG-02: its middle (%.1f, %.1f) over the water at %.1f m, its axis %.1f degrees, its deck at %.1f m (%.0f m over the water; chapter 02: 10 m, but the gorge there is 43 m wide at 10 m), %.0f m between its abutments' faces." % (mid[0], mid[1], water_z, axis, deck, BRIDGE_H, SPAN),
             "- The Lookout's gap at (%.1f, %.1f), %.1f m; the West Gate's top landing at (%.1f, %.1f), %.1f m." % (gap[0], gap[1], LOOKOUT_Z, gate_top[0], gate_top[1], gate_z), ""]
    for name, rows, steps, riser, fun in report:
        lines.append("## The %s leg: %d steps of %.3f m in %d flights (cost %.0f)" % (name, sum(steps), riser, len(steps), fun))
        lines.append("")
        lines.append("| leg | piece | steps | bearing | mean | cut | fill |")
        lines.append("|---|---|---|---|---|---|---|")
        for r in rows:
            lines.append("| %d | %s %s | %s | %.0f | %.1f | %.1f | %.1f |" % (r["leg"], r["kind"], r["number"] if r["kind"] != "approach" else "", r["n"] or "", r["bearing"], r["mean"], r["cut"], r["fill"]))
        lines.append("")
    lines.append("The galleries' places (the east leg's flights standing highest over the ground on their outer side): flights %s." % ", ".join(str(x) for x in gal))
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    for name, rows, steps, riser, fun in report:
        mean = np.mean([r["mean"] for r in rows if r["kind"] == "flight"])
        print("gorge_stair: the %s leg: %d steps (riser %.3f) in %d flights, cost %.0f, the middle %.1f m off the ground on average, cut %.1f m and filled %.1f m at most"
              % (name, sum(steps), riser, len(steps), fun, mean, max(r["cut"] for r in rows), max(r["fill"] for r in rows)))
    print("gorge_stair: %d lanes, the walk %d points, galleries at the east leg's flights %s, %d houses across its top (%s), the rest gallery %s -> %s"
          % (len(out["lanes"]), len(way), gal, len([t for t in out["things"] if t["kind"] == "house_over"]), ", ".join(t["over"] for t in out["things"] if t["kind"] == "house_over"),
             next(("after turn %d at (%.1f, %.1f), %.1f m" % (t["after_turn"], t["at"][0], t["at"][1], t["level"]) for t in out["things"] if t["kind"] == "rest_gallery"), "none"), os.path.relpath(OUT, ROOT)))
    print("gorge_stair: %d flag strings across the gorge, %s m long" % (len(out["flags"]), ", ".join("%.0f" % f_["span"] for f_ in out["flags"])))
    print("gorge_stair: the way down to the water, %d steps of %.3f m in two flights to the channel's head at %s" % (out["water"]["steps"], out["water"]["riser"], out["water"]["fill"]))
    print("gorge_stair: the water wheel RNG-04 at (%.1f, %.1f), %.1f m, its channel %.1f m from the river %.0f m above; the naga shrine RNG-05 at %s"
          % (out["wheel"]["at"][0], out["wheel"]["at"][1], out["wheel"]["level"], float(np.hypot(*(in_ - i_bank))), WHEEL_FEED,
             next((str(t["at"]) for t in out["things"] if t["kind"] == "naga_shrine"), "-")))


if __name__ == "__main__":
    main()
