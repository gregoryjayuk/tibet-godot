#!/usr/bin/env python3
"""The 1,080 steps, R-04 and RNG-11 (M3 sprint 1, step 1; plan chapter 02, D07, R-04, RNG-11 to RNG-13 and 5.3; chapter 12's
M3, acceptance 1: "climb the 1,080 steps with pilgrims counting on their rosaries, in about a quarter of an hour").

Chapter 02 gives them from the Conch Bridge RNG-01 (2,672 m) to the South Gate MON-17 (2,882 m): 380 m of path rising
210 m, 1,080 steps of 19.5 cm with treads of 27-30 cm, 2.4 m wide between whitewashed side walls 0.6 m high, in 23
flights of 36-60 steps with landings of 3 x 2.4 m; the Lhabab Chorten RNG-12 at landing 6 (+330, -5, 2,742), a chorten
and the rest house at landing 12, a chorten at the top (RNG-13), prayer-wheel niches at every fourth landing. On the real
ground (the shaped raster before the pads) the spur's south-west nose rises from the bridge to the chorten's shoulder at
about the stair's own 29 degrees, so the first six flights (60 steps each) climb it in two legs with a bend between; above
the shoulder the face to the South Gate is steeper than 45 degrees, so the other seventeen (43 and 42 steps) zigzag
across it in four legs with switchback landings, into the gate's forecourt. The legs' bearings are fitted as the Castle
Ramp's were (tools/town/castle_ramp.py): of all the ways between the bridge's east end, the chorten's shoulder and the
forecourt, the one whose steps keep nearest the ground along their middles and their edges, its landings level with the
ground about them, clear of the Parkhang RNG-10, the tsenkhang RNG-14, the thangka wall MON-16, the gate and its
neighbours and the Dungchu's water.
Every flight and landing is a lane in tools/terrain/pads.py's form: pads.py carves its bed, tools/town/walls.py walls its
sides where it is cut or filled, ../tibet-blender export_lanes.py builds each flight (its treads 0.285 m, its side walls
whitewashed) and world/town.gd places them; tools/town/monastery.py keeps its houses off the way and stands the South
Gate at its top's level.
Run: tools/py tools/town/dungrong.py   Writes data/dungrong.json and docs/town/steps-report.md (tools/terrain/build.sh
runs it before the monastery's planner and the pads; a second: it lays out START, the wide search's legs; `--search`
searches again, about nine minutes, and prints the new START).
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
TOWN = os.path.join(ROOT, "data", "town.json")
RIVERS = os.path.join(ROOT, "data", "rivers_seed.json")  # the rivers' line as M2 sprint 12 closed with it, pinned: the last
# build's data/rivers.json is fitted to ground these planners' own lanes cut, and drifted a step each build until they failed
# (ISS-182); refit it after the ground is reshaped (copy data/rivers.json over it and rerun the build)
OUT = os.path.join(ROOT, "data", "dungrong.json")
REPORT = os.path.join(ROOT, "docs", "town", "steps-report.md")

RISER, TREAD = 0.195, 0.285  # chapter 02, 5.3: 19.5 cm, 27-30 cm
WIDTH, WALL = 2.4, 0.45  # between the whitewashed side walls (0.6 m high), and each wall's thickness
BAND = WIDTH + 2 * WALL
LAND = 3.0  # a landing's length along the way (chapter 02: 3 x 2.4 m)
LAND_MAX = 20.0  # below the chorten, where the river's terrace rises at under 20 degrees, a landing runs on level up to this
# before the next flight, as long as puts that flight nearest its ground (and the way from the bridge to the first step)
SEP = BAND + 1.2  # at a switchback the two legs' middles this far apart, a strip of the slope between their walls
TURN = 3.4  # a switchback's landing past the legs' ends
PLAT = 9.0  # landing 6, the Lhabab Chorten's platform (the chorten, 6 x 6, beside the way on it)
BRIDGE = (225.0, -62.0)  # the Conch Bridge RNG-01 (chapter 02), just above the confluence
BRIDGE_Z, SPAN = 2672.0, 18.0  # its deck, the steps' foot; its span
ABUT = 3.2  # each abutment's depth past the span (../tibet-blender kit/infra.py cantilever_bridge): the deck's ends
PEMA, PEMA_SIZE, PEMA_YARD, PEMA_FACING = "SHL-11", (19.8, 17.8), 3.1, 140.0  # Pema Ö's pad (tools/terrain/pads.py SIZE,
# YARDS; tools/town/gazetteer.py FACINGS): the way to the bridge leaves its forecourt's east end, along the Dungchu's bank
PATH_W = 3.0  # that way's width
WAY_VIA = [(196.0, -62.0)]  # its bend, south of H-SHL-134's front (the house's door 3 m over a straight way's bed)
WAY_INSET = 3.0  # it leaves the forecourt's front edge this far in from its corner nearest the bridge
TSENKHANG = (235.0, -75.0, 330.0)  # RNG-14 on the Conch Prow (chapter 02), facing the steps' foot
PARKHANG = (270.0, -62.0, 160.0)  # RNG-10, the printing house "at the foot of the stair" (chapter 03, 6.10), its entrance
# to the south: chapter 02's (+290, -60) fell 28 m across its 28 m; of the sites within reach of the steps' foot clear of
# the way and the Dungchu, this falls least (17 m: its downhill side on a podium), its pad at the middle of its ground
# Its ways in (ISS-215; M3 sprint 6, step 6): from landing 1, which passes 8 m behind it over a hollow 2.4 m deep, a flagged
# walk straight off the landing through a gap in its wall to its stair hall's back door (its back face PARKHANG_BACK from its
# middle: ../tibet-blender kit/dungrong.py, the north range's walls; the walk ends inside the pad's 1.5 m apron), its pad at
# the landing's level; and a forecourt PARKHANG_YARD deep cut before its south gate (until then its gate opened onto the
# 1.5 m apron under the cut)
PARKHANG_BACK = 10.0
PARKHANG_WALK = 2.0  # the walk's width; the gap in the landing's wall a little wider
PARKHANG_YARD = 5.0
TERRACE6 = 8.0  # the Lhabab Chorten's terrace beside landing 6's platform, square (the chorten 6 x 6 on it)
TERRACE12 = (12.0, 6.0)  # landing 12's terrace beside it, along and across the way: its chorten and the rest house
NICHES = (4, 8, 12, 16, 20)  # the landings with a niche of prayer wheels (chapter 02, 5.3: every fourth)
NICHE_D = 0.75  # a niche's depth from its front to its back wall (../tibet-blender kit/dungrong.py wheel_niche)
STEPS = [60] * 6 + [43] * 6 + [42] * 11  # the 23 flights: 360 steps (70.2 m) to landing 6, 720 (140.4 m) above it
SPLIT = (2, 2, 2, 4, 5, 4, 4)  # flights a leg: three legs below the chorten (the river's terrace, then up the nose's
# steep front), four above it (across the face)
PLATFORM_AFTER = 3  # landing 6 after these legs
TURN_BACK = 100.0  # a join turning more than this is a switchback
L6 = (330.0, -5.0)  # the Lhabab Chorten RNG-12 (chapter 02): landing 6's platform within L6_FREE of it
L6_FREE = 12.0
GATE, GATE_FACING, GATE_DEPTH = (465.0, 65.0), 215.0, 6.0  # the South Gate MON-17, facing out down the steps
# (tools/town/monastery.py FACING)
COURT = (20.0, 12.0)  # its forecourt (chapter 03, 6.8): width, depth; the steps come into it at its outer edge
INTO = 50.0  # the last flight within this many degrees of the forecourt's axis
KEEP = {"RNG-10": 3.0, "RNG-14": 2.5, "MON-16": 3.0, "MON-17": 0.5, "MON-13": 2.0, "MON-30": 2.0, "MON-31": 2.0}  # and
# how far clear of each; MON-16's footprint is the thangka wall's (monastery.py THANGKA_WALL), facing 225
WATER_CLEAR = 3.0  # the steps' walls this far from the Dungchu's water but at the bridge
TRIALS, SEED = 16, 1080
# The fit's legs' bearings, from a wide search (`--search`: TRIALS random starts, about nine minutes, 10 Oct 2026: cost
# 17,856, the middle 1.3-5.6 m off the ground on average, cut 9.4 m and filled 8.3 m at most): a build lays them out as
# they are, the ground before the pads being the same each time. Rerun the search after the ground is reshaped.
START = [56.4393, 0.7523, 134.6297, 10.6302, 154.2777, 15.9322, 74.9768]
# The Conch Bridge where the search found it (the Dungchu's line in the last build's data/rivers.json drifts a little each
# build: ISS-182): its middle over the water, its axis, the water's level; the steps' foot at its east end
BRIDGE_MID, BRIDGE_AXIS, BRIDGE_WATER = (224.0, -62.33), 113.2, 2664.5
W_EDGE, W_LAND, W_CORNER, CORNER_FREE = 0.3, 20.0, 40.0, 3.0


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


def level_run(Z, S, d, s, z, n_next):
    """Below the chorten: how long a level landing from s (at z) puts the next flight of n_next steps nearest its ground."""
    best = None
    for cand in np.arange(LAND, LAND_MAX + 0.01, 1.0):
        ss = np.arange(0.0, cand + n_next * TREAD + 0.01, 1.0)
        bed = np.where(ss < cand, z, z + (ss - cand) / TREAD * RISER)
        P = S[None] + d[None] * (s + ss)[:, None]
        e = float(np.mean((Z(P[:, 0], P[:, 1]) - bed) ** 2))
        if best is None or e < best[0] - 0.05:
            best = (e, cand)
    return float(best[1])


def lay(angles, foot, Z=None):
    """The way from the foot: its legs [(start, unit, length, pieces along it: (kind, s0, s1, z0, z1, steps, number))] and
    the landings between them [(kind, at, unit, z, number, normal)]: landing 6's platform after the legs below the chorten
    (the next leg from its far side); between other legs a switchback where the way turns back on itself (its landing past
    the leg's end, the next leg SEP to the side it turns), a bend where it turns less (a landing on along the leg, the next
    leg from its end); each flight's steps and number, each landing numbered by the flight it tops. With the ground (Z),
    below the chorten the way from the bridge and each landing run on level as long as puts the next flight nearest its
    ground."""
    legs, joins = [], []
    S, z, fi = np.array(foot, float), BRIDGE_Z, 0
    for k, n_f in enumerate(SPLIT):
        d = unit(angles[k])
        s, pieces = 0.0, []
        below = k < PLATFORM_AFTER
        if k == 0 and Z is not None:  # the way from the bridge's abutment to the first step
            a0 = level_run(Z, S, d, 0.0, z, STEPS[0]) - LAND
            if a0 > 0.5:
                pieces.append(("approach", 0.0, a0, z, z, 0, 0))
                s = a0
        for j in range(n_f):
            n = STEPS[fi]
            fi += 1
            pieces.append(("flight", s, s + n * TREAD, z, z + n * RISER, n, fi))
            s += n * TREAD
            z += n * RISER
            if j < n_f - 1:
                ln = level_run(Z, S, d, s, z, STEPS[fi]) if (Z is not None and below) else LAND
                pieces.append(("landing", s, s + ln, z, z, 0, fi))
                s += ln
        legs.append((S.copy(), d, s, pieces))
        E = S + d * s
        if k == len(SPLIT) - 1:
            break
        if k == PLATFORM_AFTER - 1:  # landing 6: the chorten's platform on from this leg's end, the next from its far side
            C = E + d * PLAT / 2
            joins.append(("platform", C, d, z, fi, None))
            S = C + unit(angles[k + 1]) * PLAT / 2
            continue
        turn = (angles[k + 1] - angles[k] + 180.0) % 360.0 - 180.0  # (bearings: positive to the right)
        if abs(turn) > TURN_BACK:  # a switchback, its next leg to the side it turns
            nrm = np.array([-d[1], d[0]]) * (-1.0 if turn > 0 else 1.0)
            joins.append(("turn", E, d, z, fi, nrm))
            S = E + nrm * SEP
        else:  # a bend
            joins.append(("bend", E, d, z, fi, None))
            S = E + d * LAND
    return legs, joins


def landing_piece(lid, z, length, walls, rise=0.0):
    """A landing's piece for ../tibet-blender export_lanes.py and world/town.gd: flagstones `length` along the way at
    level z, whitewashed walls on both sides (`lime`), and across a switchback's far end (`turn`), or none (landing 6's
    platform, the chorten's; the forecourt); or a sloping flagged way rising `rise` along its length (the way from Pema Ö
    to the bridge, its own collision over its fill)."""
    return {"file": "steps_" + lid.split(".")[1], "s": 0.0, "rise": round(rise, 3), "z": round(z, 3), "n": 0, "length": round(length, 3), "walls": walls}


def lane_rect(ln, grow=0.0):
    """A lane's corners, grown."""
    o, d_ = np.array(ln["from"], float), np.array(ln["dir"], float)
    n_ = np.array([-d_[1], d_[0]])
    w_ = ln["width"] / 2 + grow
    e = o + d_ * ln["length"]
    return np.array([o - d_ * grow - n_ * w_, o - d_ * grow + n_ * w_, e + d_ * grow + n_ * w_, e + d_ * grow - n_ * w_])


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


def furnish(Z, lanes, legs, joins, top, top_z, ca):
    """The steps' chortens, rest house and wheel niches (chapter 02, RNG-12, RNG-13, 5.3; M3 sprint 1, step 3): the
    Lhabab Chorten on a terrace beside landing 6's platform, on its free side whose ground lies nearest its level; landing
    12's terrace beside it with the byang chub chorten and the rest house, the landing's wall open on that side; the rnam
    rgyal chorten in the forecourt beside the top step; a niche of three prayer wheels against the wall of every fourth
    landing (a switchback's at its far end). Adds the terraces' lanes; returns (things, {"RNG-12": its place})."""
    things, out = [], {}
    by_id = {ln["id"]: ln for ln in lanes}

    def fit(cx, cy, w_, d_, ux, uy, z):  # how far a terrace's ground lies from its level, on average
        xs = np.linspace(-0.5, 0.5, 5)
        P = [np.array([cx, cy]) + np.array([-uy, ux]) * a_ * w_ + np.array([ux, uy]) * b_ * d_ for a_ in xs for b_ in xs]
        return float(np.mean([abs(float(Z(q[0], q[1])) - z) for q in P]))

    def clear(rect, but):
        return not any(overlaps(rect, lane_rect(o, 0.6)) for o in lanes if o["id"] not in but)

    # landing 6: the Lhabab Chorten's terrace on a free side of the platform
    j6 = next(j for j in joins if j[0] == "platform")
    k6 = joins.index(j6)
    C, d6, z6 = j6[1], j6[2], j6[3]
    n6 = np.array([-d6[1], d6[0]])
    d_next = legs[k6 + 1][1]
    best = None
    for u in (d6, n6, -n6):  # (not back up the leg it comes in by)
        if float(np.dot(u, d_next)) > 0.7:
            continue  # (nor where the next leg leaves)
        T_ = C + u * (PLAT / 2 + TERRACE6 / 2)
        ln = {"id": "R04.C06", "from": [float((C + u * PLAT / 2)[0]), float((C + u * PLAT / 2)[1])], "dir": [float(u[0]), float(u[1])], "length": TERRACE6, "width": TERRACE6}
        if not clear(lane_rect(ln), {"R04.L06"}):
            continue
        f_ = fit(T_[0], T_[1], TERRACE6, TERRACE6, u[0], u[1], z6)
        if best is None or f_ < best[0]:
            best = (f_, u, T_, ln)
    _, u, T_, ln = best
    ln.update({"z_a": round(z6, 3), "z_b": round(z6, 3), "profile": [[0.0, round(z6 - 0.1, 3)], [TERRACE6, round(z6 - 0.1, 3)]],
               "flight": landing_piece("R04.C06", z6, TERRACE6, None), "steps": True})
    ln["from"] = [round(ln["from"][0], 3), round(ln["from"][1], 3)]
    ln["dir"] = [round(ln["dir"][0], 5), round(ln["dir"][1], 5)]
    lanes.append(ln)
    out["RNG-12"] = {"at": [round(T_[0], 2), round(T_[1], 2)], "level": round(z6, 3), "facing": round(bearing(-u), 1)}
    # landing 12: its terrace on the side whose ground lies nearest, clear of the other legs; the landing's wall open there
    l12 = by_id["R04.L12"]
    o12, d12 = np.array(l12["from"], float), np.array(l12["dir"], float)
    n12 = np.array([-d12[1], d12[0]])
    C12 = o12 + d12 * l12["length"] / 2
    z12 = l12["z_a"]
    best = None
    for side in (1.0, -1.0):
        T_ = C12 + n12 * side * (BAND / 2 + TERRACE12[1] / 2)
        ln = {"id": "R04.T12", "from": [float((T_ - d12 * TERRACE12[0] / 2)[0]), float((T_ - d12 * TERRACE12[0] / 2)[1])], "dir": [float(d12[0]), float(d12[1])],
              "length": TERRACE12[0], "width": TERRACE12[1]}
        r_ = lane_rect(ln)
        if not clear(r_, {"R04.L12", "R04.F12", "R04.F13"}):
            continue
        f_ = fit(T_[0], T_[1], TERRACE12[1], TERRACE12[0], d12[0], d12[1], z12)
        if best is None or f_ < best[0]:
            best = (f_, side, T_, ln)
    if best is not None:
        _, side, T_, ln = best
        ln.update({"z_a": z12, "z_b": z12, "profile": [[0.0, round(z12 - 0.1, 3)], [TERRACE12[0], round(z12 - 0.1, 3)]],
                   "flight": landing_piece("R04.T12", z12, TERRACE12[0], None), "steps": True})
        ln["from"] = [round(ln["from"][0], 3), round(ln["from"][1], 3)]
        ln["dir"] = [round(ln["dir"][0], 5), round(ln["dir"][1], 5)]
        lanes.append(ln)
        l12["flight"]["walls"] = "lime_r" if side > 0 else "lime_l"  # (its wall on the terrace's side left out: the kit's -x is the lane's left)
        out_ = -n12 * side  # the terrace's things face the way
        ch = T_ - d12 * 3.5
        things.append({"id": "RNG-13.1", "kit": "rng13_byangchub_v1", "at": [round(ch[0], 2), round(ch[1], 2)], "level": z12, "facing": round(bearing(out_), 1)})
        rh = T_ + d12 * 2.5 + n12 * side * 0.6
        things.append({"id": "RNG-13.3", "kit": "rng13_rest_house_v1", "at": [round(rh[0], 2), round(rh[1], 2)], "level": z12, "facing": round(bearing(out_), 1)})
    else:
        print("dungrong: WARNING: no room for landing 12's terrace")
    # the Parkhang's back door from landing 1: a flagged walk straight off the landing's side towards it, through a gap in
    # the landing's wall, to inside its pad's apron
    l1 = by_id["R04.L01"]
    o1, d1 = np.array(l1["from"], float), np.array(l1["dir"], float)
    b_ = unit(PARKHANG[2] + 180.0)  # the Parkhang's back, its back door's way out
    C_ = np.array(PARKHANG[:2], float)
    door_ = C_ + b_ * PARKHANG_BACK
    t1 = float(np.clip((door_ - o1) @ d1, PARKHANG_WALK, l1["length"] - PARKHANG_WALK))
    side = 1.0 if (door_ - o1) @ np.array([d1[1], -d1[0]]) > 0.0 else -1.0  # +1: on the landing's right going up
    n_ = np.array([d1[1], -d1[0]]) * side
    P0 = o1 + d1 * t1 + n_ * (l1["width"] / 2)
    s_ = (PARKHANG_BACK + 0.75 - (P0 - C_) @ b_) / (n_ @ b_)  # to 0.75 m beyond its back face, inside the apron
    z1 = l1["z_a"]
    if s_ > 0.5:
        lanes.append({"id": "R04.P01", "from": [round(float(P0[0]), 3), round(float(P0[1]), 3)], "dir": [round(float(n_[0]), 5), round(float(n_[1]), 5)],
                      "length": round(float(s_), 3), "width": PARKHANG_WALK, "z_a": z1, "z_b": z1,
                      "profile": [[0.0, round(z1 - 0.1, 3)], [round(float(s_), 3), round(z1 - 0.1, 3)]],
                      "flight": landing_piece("R04.P01", z1, float(s_), None), "steps": True})
        l1["flight"]["gap"] = [int(side), round(t1 - PARKHANG_WALK / 2 - 0.1, 3), round(t1 + PARKHANG_WALK / 2 + 0.1, 3)]
        out["RNG-10"] = {"level": z1}
    else:
        print("dungrong: WARNING: no walk to the Parkhang's back door")
    # the top: the rnam rgyal chorten in the forecourt, beside the top step on its right going up, the pilgrims passing it
    # on their right (until 15 Oct 2026 on the left, in the forecourt's west corner, 1-1.5 m from its edges: the Gönkor
    # crosses that half to its way along the face, tools/town/gonkor.py, and a walker keeping it on the right had no way by)
    across = np.array([-ca[1], ca[0]])
    ch = np.array(top) + ca * 3.0 - across * 6.5
    things.append({"id": "RNG-13.2", "kit": "rng13_namgyal_v1", "at": [round(ch[0], 2), round(ch[1], 2)], "level": round(top_z, 3), "facing": round(bearing(-ca), 1)})
    # the niches: against a landing's wall, inside it, on the side away from a terrace; a switchback's against its far wall
    for k_, num in enumerate(NICHES):
        lid = "R04.L%02d" % num
        ln = by_id.get(lid)
        if ln is None:
            continue
        o, d_ = np.array(ln["from"], float), np.array(ln["dir"], float)
        n_ = np.array([-d_[1], d_[0]])
        if ln["flight"]["walls"] == "turn":
            back = o + d_ * (TURN - 0.45)  # the far wall's inner face, between the legs
            front = back - d_ * NICHE_D
            face = -d_
        else:
            sgn = -1.0 if ln["flight"]["walls"] == "lime_r" else 1.0  # (the left's the kit's -x)
            if ln["flight"]["walls"] == "lime_l":
                sgn = 1.0
            mid_ = o + d_ * ln["length"] / 2
            back = mid_ + n_ * sgn * (WIDTH / 2)
            front = back - n_ * sgn * NICHE_D
            face = -n_ * sgn
        things.append({"id": "R04.N%02d" % num, "kit": "steps_wheel_niche_v%d" % (1 + k_ % 3), "at": [round(front[0], 2), round(front[1], 2)],
                       "level": ln["z_a"], "facing": round(bearing(face), 1), "wheels": True})
    return things, out


def join_box(j):
    """A landing between legs: its corners."""
    kind, at, d, z, num, nrm = j
    n = np.array([-d[1], d[0]])
    if kind == "bend":
        return np.array([at - n * BAND / 2, at + n * BAND / 2, at + n * BAND / 2 + d * LAND, at - n * BAND / 2 + d * LAND])
    if kind == "platform":
        return np.array([at + (-n - d) * PLAT / 2, at + (n - d) * PLAT / 2, at + (n + d) * PLAT / 2, at + (-n + d) * PLAT / 2])
    a, b = at - nrm * BAND / 2, at + nrm * (SEP + BAND / 2)
    return np.array([a, b, b + d * TURN, a + d * TURN])


def make_cost(Z, keeps, water, foot, foot_dir, top):
    court_axis = unit((GATE_FACING + 180.0) % 360.0)  # into the forecourt, towards the gate

    def cost(v, rows=None):
        legs, joins = lay(v, foot, Z)
        c = 0.0
        for k, (S, d, L, pieces) in enumerate(legs):
            nrm = np.array([-d[1], d[0]])
            ss = np.arange(0.0, L + 0.01, 1.0)  # the leg's bed: its flights' slopes and its landings level
            bed = np.interp(ss, [p[1] for p in pieces] + [pieces[-1][2]], [p[3] for p in pieces] + [pieces[-1][4]])
            P = S[None] + d[None] * ss[:, None]
            mid = Z(P[:, 0], P[:, 1]) - bed
            lft = Z(P[:, 0] + nrm[0] * BAND / 2, P[:, 1] + nrm[1] * BAND / 2) - bed
            rgt = Z(P[:, 0] - nrm[0] * BAND / 2, P[:, 1] - nrm[1] * BAND / 2) - bed
            if np.isnan(mid).any() or np.isnan(lft).any() or np.isnan(rgt).any():
                return 1e12
            c += float(np.sum(mid ** 2)) + W_EDGE * float(np.sum(lft ** 2 + rgt ** 2))
            edges = np.concatenate([P + nrm[None] * BAND / 2, P - nrm[None] * BAND / 2])
            for poly in keeps:
                c += 1e4 * float(np.sum(inside(edges, poly) ** 2))
            if k < PLATFORM_AFTER:  # off the water (but where the first steps leave the bridge's abutment)
                e_ = edges[np.concatenate([ss, ss]) > (6.0 if k == 0 else -1.0)]
                dist = np.min(np.hypot(e_[:, None, 0] - water[None, :, 0], e_[:, None, 1] - water[None, :, 1]) - water[None, :, 2], axis=1)
                c += 1e4 * float(np.sum(np.maximum(0.0, WATER_CLEAR - dist) ** 2))
            if rows is not None:
                for kind, s0, s1, z0, z1, n, num in pieces:
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
        C6 = next(j[1] for j in joins if j[0] == "platform")
        c += 1e3 * max(0.0, float(np.hypot(*(C6 - np.array(L6)))) - L6_FREE) ** 2
        S, d, L, _ = legs[-1]
        c += 1e5 * float(np.sum((S + d * L - np.array(top)) ** 2))
        c += 1e4 * max(0.0, math.degrees(math.acos(max(-1.0, min(1.0, float(np.dot(d, court_axis)))))) - INTO) ** 2
        c += 1e4 * max(0.0, math.degrees(math.acos(max(-1.0, min(1.0, float(np.dot(legs[0][1], foot_dir)))))) - 60.0) ** 2
        segs = [(S, S + d * L) for S, d, L, _ in legs]
        for i in range(len(segs)):  # no leg near another but where they meet
            for jx in range(i + 2, len(segs)):
                c += 1e4 * max(0.0, BAND + 2.0 - seg_dist(*segs[i], *segs[jx])) ** 2
        for i in range(len(segs) - 1):  # a switchback's two legs part from their landing
            if not (i < len(joins) and joins[i][0] == "turn"):
                continue
            a0, a1 = segs[i]
            b0, b1 = segs[i + 1]
            da = a1 - a0
            db = b1 - b0
            ua, ub = da / max(1e-6, np.hypot(*da)), db / max(1e-6, np.hypot(*db))
            c += 1e4 * max(0.0, BAND + 0.4 - seg_dist(a0, a1 - ua * 6.0, b0 + ub * 6.0, b1)) ** 2
        return c
    return cost


def main():
    site = Site.load()
    g = site.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site.shift
    town = {b["id"]: b for b in json.load(open(TOWN, encoding="utf-8"))["buildings"]}
    # the bridge: across the Dungchu where its water passes nearest chapter 02's place; the steps' foot at its east end
    search = "--search" in sys.argv
    rivers = json.load(open(RIVERS, encoding="utf-8"))["rivers"]
    best = None
    for rv in rivers:
        for i, q in enumerate(rv["pts"]):
            dq = math.hypot(q[0] - BRIDGE[0], q[1] - BRIDGE[1])
            if best is None or dq < best[0]:
                best = (dq, rv, i)
    _, rv, i = best
    pts = rv["pts"]
    if search:  # across the Dungchu where its water passes nearest chapter 02's place
        a, b = pts[max(0, i - 1)], pts[min(len(pts) - 1, i + 1)]
        t = np.array([b[0] - a[0], b[1] - a[1]])
        t /= np.hypot(*t)
        n = np.array([-t[1], t[0]])
        if n[0] < 0:  # (the east bank's way)
            n = -n
        mid, water_z = np.array(pts[i][:2], float), pts[i][2]
    else:
        n, mid, water_z = unit(BRIDGE_AXIS), np.array(BRIDGE_MID), BRIDGE_WATER
    foot = mid + n * SPAN / 2
    water = np.array([[q[0], q[1], max(q[3], q[4])] for q in pts if math.hypot(q[0] - foot[0], q[1] - foot[1]) < 220.0])
    # the top: the forecourt's outer edge on the gate's axis
    u = unit(GATE_FACING)
    court_c = np.array(GATE) + u * (GATE_DEPTH / 2 + COURT[1] / 2)
    top = np.array(GATE) + u * (GATE_DEPTH / 2 + COURT[1])
    keeps = []
    for kid, m in KEEP.items():
        b = town.get(kid)
        if b is None or not b.get("pos"):
            continue
        if kid == "MON-16":
            keeps.append(rect(b["pos"][:2], 20.0, 4.0, 225.0, m))
        elif kid == "MON-17":
            keeps.append(rect(GATE, 8.0, 6.0, GATE_FACING, m))
        elif kid == "RNG-10":
            keeps.append(rect(PARKHANG[:2], b["footprint"][0], b["footprint"][1], PARKHANG[2], m))
        elif b.get("footprint"):
            keeps.append(rect(b["pos"][:2], b["footprint"][0], b["footprint"][1], float(b.get("rot_deg") or 180.0), m))
    cost = make_cost(Z, keeps, water, foot, n, top)
    rng = np.random.default_rng(SEED)
    up = bearing(np.array(L6) - foot)
    climb = bearing(top - np.array(L6))
    found = []
    for trial in range(TRIALS if search else 0):
        sa, sb = rng.choice([-1.0, 1.0]), rng.choice([-1.0, 1.0])  # the zigzags' first legs to either side of the climb
        aa, ab = rng.uniform(40.0, 75.0), rng.uniform(40.0, 70.0)
        v = np.array([up + rng.normal(0, 10), up + aa * sa, up - aa * sa, climb + ab * sb, climb - ab * sb, climb + ab * sb, climb - ab * sb], float)
        v += rng.normal(0, 5, v.size)
        r = minimize(cost, v, method="Nelder-Mead", options={"maxiter": 3500, "maxfev": 3500, "xatol": 0.02, "fatol": 0.5, "adaptive": True})
        r = minimize(cost, r.x, method="Powell", options={"maxiter": 3000, "xtol": 0.02, "ftol": 1e-5})
        found.append((r.fun, r.x))
    found.sort(key=lambda q: q[0])
    if found:
        fun, v = found[0]
    else:  # a build: the search's legs, refined a little (a level landing below the chorten can come out a metre different)
        r = minimize(cost, np.array(START), method="Powell", options={"maxiter": 3, "xtol": 0.005, "ftol": 1e-7})
        fun, v = r.fun, r.x
    if search:
        print("dungrong: the search's legs: START = [%s]" % ", ".join("%.4f" % a_ for a_ in v))
    rows = []
    cost(v, rows)
    legs, joins = lay(v, foot, Z)
    E = legs[-1][0] + legs[-1][1] * legs[-1][2]
    # the lanes: every flight, every landing, the bend's, landing 6's platform, the switchbacks', the forecourt
    lanes, flights, landings, line, walk = [], [], [], [], []
    # the way from Pema Ö's forecourt along the bank to the bridge's west end, and over it to the steps' foot
    pm = town[PEMA]
    fw, ac = unit(PEMA_FACING), np.array([-math.cos(math.radians(PEMA_FACING)), math.sin(math.radians(PEMA_FACING))])
    front = np.array(pm["pos"][:2], float) + fw * (PEMA_SIZE[1] / 2 + PEMA_YARD)  # the forecourt's front edge's middle
    west = mid - n * (SPAN / 2 + ABUT)
    corner = min([front + ac * PEMA_SIZE[0] / 2, front - ac * PEMA_SIZE[0] / 2], key=lambda q: float(np.hypot(*(q - west))))
    p0 = corner + (front - corner) / float(np.hypot(*(front - corner))) * WAY_INSET
    pz = float(pm["pos"][2])
    way = [p0] + [np.array(q, float) for q in WAY_VIA] + [west]
    Lw = sum(float(np.hypot(*(b_ - a_))) for a_, b_ in zip(way, way[1:]))
    t0 = 0.0
    for k_, (a_, b_) in enumerate(zip(way, way[1:])):
        L_ = float(np.hypot(*(b_ - a_)))
        dw = (b_ - a_) / L_
        za, zb = pz + (BRIDGE_Z - pz) * t0 / Lw, pz + (BRIDGE_Z - pz) * (t0 + L_) / Lw
        lanes.append({"id": "R04.W%02d" % (k_ + 1), "from": [round(a_[0], 3), round(a_[1], 3)], "dir": [round(dw[0], 5), round(dw[1], 5)], "length": round(L_, 3),
                      "width": PATH_W, "z_a": round(za, 3), "z_b": round(zb, 3), "profile": [[0.0, round(za - 0.1, 3)], [round(L_, 3), round(zb - 0.1, 3)]],
                      "flight": landing_piece("R04.W%02d" % (k_ + 1), za, L_, None, zb - za), "steps": True})
        for t_ in np.arange(0.0, L_, 4.0):
            q = a_ + dw * t_
            walk.append([round(q[0], 2), round(q[1], 2), round(za + (zb - za) * t_ / L_, 3)])
        t0 += L_
    for q in (west, mid, foot):
        walk.append([round(float(q[0]), 2), round(float(q[1]), 2), BRIDGE_Z])
    tz = max(float(Z(TSENKHANG[0] + sx, TSENKHANG[1] + sy)) for sx in (-1.0, 1.0) for sy in (-1.0, 1.0))  # (its uphill corner's)
    places = {"RNG-01": {"at": [round(mid[0], 2), round(mid[1], 2)], "level": BRIDGE_Z, "facing": round((bearing(n) + 180.0) % 360.0, 1)},
              "RNG-14": {"at": [TSENKHANG[0], TSENKHANG[1]], "level": round(tz, 2), "facing": TSENKHANG[2]}}
    for k, (S, d, L, pieces) in enumerate(legs):
        for kind, s0, s1, z0, z1, nst, num in pieces:
            P = S + d * s0
            if kind == "flight":
                run = s1 - s0
                lanes.append({"id": "R04.F%02d" % num, "from": [round(P[0], 3), round(P[1], 3)], "dir": [round(d[0], 5), round(d[1], 5)], "length": round(run, 3),
                              "width": BAND, "z_a": round(z0, 3), "z_b": round(z1, 3), "profile": [[0.0, round(z0 - 0.25, 3)], [round(run, 3), round(z1 - 0.25, 3)]],
                              "flight": {"file": "steps_%02d" % num, "s": 0.0, "rise": round(z1 - z0, 3), "z": round(z0, 3), "n": nst, "run": TREAD, "top": 0.0,
                                         "landing": None, "walls": "lime"}, "steps": True})
                flights.append({"number": num, "n": nst, "from": [round(P[0], 2), round(P[1], 2)], "bearing": round(bearing(d), 1), "z": [round(z0, 3), round(z1, 3)], "leg": k + 1})
            else:
                ln_ = s1 - s0
                fid = "R04.L%02d" % num if kind == "landing" else "R04.A00"
                lanes.append({"id": fid, "from": [round(P[0], 3), round(P[1], 3)], "dir": [round(d[0], 5), round(d[1], 5)],
                              "length": round(ln_, 3), "width": BAND, "z_a": round(z0, 3), "z_b": round(z0, 3),
                              "profile": [[0.0, round(z0 - 0.1, 3)], [round(ln_, 3), round(z0 - 0.1, 3)]], "flight": landing_piece(fid, z0, ln_, "lime"), "steps": True})
                C = S + d * (s0 + ln_ / 2)
                if kind == "landing":
                    landings.append({"number": num, "kind": "landing", "at": [round(C[0], 2), round(C[1], 2)], "z": round(z0, 3), "bearing": round(bearing(d), 1),
                                     "length": round(ln_, 2)})
            for s in np.arange(s0, s1, 1.0):
                q = S + d * s
                line.append([round(q[0], 2), round(q[1], 2), round(z0 + (z1 - z0) * (s - s0) / max(1e-6, s1 - s0), 3)])
            for s in list(np.arange(s0, s1, 4.0)) + [s1]:  # the walk: every 4 m and each piece's end
                q = S + d * s
                walk.append([round(q[0], 2), round(q[1], 2), round(z0 + (z1 - z0) * (s - s0) / max(1e-6, s1 - s0), 3)])
        if k < len(joins):
            kind, at, dj, z, num, nrm = joins[k]
            box = join_box(joins[k])
            S2 = legs[k + 1][0]
            if kind == "turn":  # round a switchback's landing, not through the wall between its legs
                via = [at + dj * TURN / 2, at + nrm * SEP + dj * TURN / 2]
            elif kind == "platform":
                via = [at]
            else:
                via = []
            for q in via + [S2]:
                walk.append([round(float(q[0]), 2), round(float(q[1]), 2), round(z, 3)])
            if kind == "bend":
                lanes.append({"id": "R04.L%02d" % num, "from": [round(at[0], 3), round(at[1], 3)], "dir": [round(dj[0], 5), round(dj[1], 5)], "length": LAND,
                              "width": BAND, "z_a": round(z, 3), "z_b": round(z, 3), "profile": [[0.0, round(z - 0.1, 3)], [LAND, round(z - 0.1, 3)]],
                              "flight": landing_piece("R04.L%02d" % num, z, LAND, "lime"), "steps": True})
                C = at + dj * LAND / 2
            elif kind == "platform":
                lanes.append({"id": "R04.L%02d" % num, "from": [round((at - dj * PLAT / 2)[0], 3), round((at - dj * PLAT / 2)[1], 3)], "dir": [round(dj[0], 5), round(dj[1], 5)],
                              "length": PLAT, "width": PLAT, "z_a": round(z, 3), "z_b": round(z, 3), "profile": [[0.0, round(z - 0.1, 3)], [PLAT, round(z - 0.1, 3)]],
                              "flight": landing_piece("R04.L%02d" % num, z, PLAT, None), "steps": True})
                C = at
            else:
                mid_ = at + nrm * SEP / 2
                lanes.append({"id": "R04.L%02d" % num, "from": [round(mid_[0], 3), round(mid_[1], 3)], "dir": [round(dj[0], 5), round(dj[1], 5)], "length": TURN,
                              "width": round(SEP + BAND, 3), "z_a": round(z, 3), "z_b": round(z, 3), "profile": [[0.0, round(z - 0.1, 3)], [TURN, round(z - 0.1, 3)]],
                              "flight": landing_piece("R04.L%02d" % num, z, TURN, "turn"), "steps": True})
                C = mid_ + dj * TURN / 2
            landings.append({"number": num, "kind": kind, "at": [round(C[0], 2), round(C[1], 2)], "z": round(z, 3), "bearing": round(bearing(dj), 1),
                             "corners": [[round(q[0], 2), round(q[1], 2)] for q in box]})
    top_z = BRIDGE_Z + sum(STEPS) * RISER
    ca = unit((GATE_FACING + 180.0) % 360.0)  # the forecourt, level with the top step, paved, from its outer edge to the gate
    lanes.append({"id": "R04.L23", "from": [round(top[0], 3), round(top[1], 3)], "dir": [round(ca[0], 5), round(ca[1], 5)], "length": COURT[1],
                  "width": COURT[0], "z_a": round(top_z, 3), "z_b": round(top_z, 3), "profile": [[0.0, round(top_z - 0.1, 3)], [COURT[1], round(top_z - 0.1, 3)]],
                  "flight": landing_piece("R04.L23", top_z, COURT[1], None), "steps": True})
    landings.append({"number": len(STEPS), "kind": "top", "at": [round(court_c[0], 2), round(court_c[1], 2)], "z": round(top_z, 3), "bearing": round((GATE_FACING + 180.0) % 360.0, 1)})
    things, terraces = furnish(Z, lanes, legs, joins, top, top_z, ca)
    places["RNG-12"] = terraces.pop("RNG-12")
    pk_level = terraces.pop("RNG-10", {}).get("level")
    pk = town["RNG-10"]
    xs_, ys_ = np.meshgrid(np.linspace(-0.5, 0.5, 8), np.linspace(-0.5, 0.5, 8))
    u_ = unit(PARKHANG[2])
    a_ = np.array([-u_[1], u_[0]])
    P_ = np.array(PARKHANG[:2])[None, None, :] + a_[None, None, :] * xs_[..., None] * pk["footprint"][0] + u_[None, None, :] * ys_[..., None] * pk["footprint"][1]
    places["RNG-10"] = {"at": [PARKHANG[0], PARKHANG[1]], "level": round(float(np.median(Z(P_[..., 0], P_[..., 1]))), 1), "facing": PARKHANG[2], "pad": True,
                        "moved_from": pk["pos"][:2], "yard": PARKHANG_YARD}
    if pk_level is not None:  # (at landing 1's level: its back walk level with its door; its ground's median 0.4 m over it)
        places["RNG-10"]["level"] = pk_level
    line.append([round(E[0], 2), round(E[1], 2), round(top_z, 3)])
    walk.append([round(court_c[0], 2), round(court_c[1], 2), round(top_z, 3)])
    out = {"about": "The 1,080 steps R-04 (tools/town/dungrong.py; M3 sprint 1): `foot` the Conch Bridge's east end (its deck's level, the bridge's middle and axis); `top` the South Gate's forecourt (its middle, size, facing and level: tools/town/monastery.py stands the gate on it); `flights` each its number, steps, foot, bearing and levels; `landings` each its number (the flight it tops), kind (landing, bend, platform: landing 6, the Lhabab Chorten's; turn: a switchback's; top) and place; `lanes` every flight and landing in tools/terrain/pads.py's form (a flight's `flight` for ../tibet-blender export_lanes.py and world/town.gd); `line` the way's middle every metre, its level; `walk` a walker's way up it (from Pema Ö's forecourt along the bank and over the bridge, every 4 m, round each landing between legs, into the forecourt); `places` the Conch Bridge's, the tsenkhang's, the Lhabab Chorten's and the Parkhang's (world/town.gd; a `pad` tools/terrain/pads.py levels there); `things` the steps' other chortens, the rest house and the wheel niches, each its kit, place, level and facing (a niche's `wheels` turned by world/kora_wheels.gd); `way_in` the way from Pema Ö's forecourt to the bridge (lane R04.W01). Regenerated with the terrain.",
           "foot": {"at": [round(foot[0], 2), round(foot[1], 2)], "z": BRIDGE_Z, "bridge": {"mid": [round(mid[0], 2), round(mid[1], 2)], "axis": round(bearing(n), 1), "span": SPAN, "water": round(water_z, 2)}},
           "top": {"at": [round(top[0], 2), round(top[1], 2)], "z": round(top_z, 3), "forecourt": {"at": [round(court_c[0], 2), round(court_c[1], 2)], "size": list(COURT), "facing": GATE_FACING}},
           "steps": int(sum(STEPS)), "riser": RISER, "tread": TREAD, "width": WIDTH, "band": BAND,
           "flights": flights, "landings": landings, "lanes": lanes, "line": line, "walk": walk, "places": places, "things": things,
           "way_in": {"from": [round(p0[0], 2), round(p0[1], 2)], "to": [round(west[0], 2), round(west[1], 2)], "z": [round(pz, 2), BRIDGE_Z]}}
    json.dump(out, open(OUT, "w", encoding="utf-8"), indent=1)
    plen = sum(L for _, _, L, _ in legs) + sum({"bend": LAND, "platform": PLAT, "turn": TURN}[j[0]] for j in joins)
    j6 = next(j for j in joins if j[0] == "platform")
    fl_rows = [r for r in rows if r["kind"] == "flight"]
    rep = ["# The 1,080 steps", "",
           "_Written by `tools/town/dungrong.py` (M3 sprint 1; plan chapter 02, R-04, RNG-11 to RNG-13, 5.3) from the ground before the pads (`valley_shaped_1m`): the way from the Conch Bridge's east end to the South Gate's forecourt, fitted to the ground; its lanes are carved by `tools/terrain/pads.py` and walled by `tools/town/walls.py`, its flights built by `../tibet-blender` `export_lanes.py`._", "",
           "- %d steps of %.1f cm in %d flights, treads %.1f cm, %.1f m wide between their walls; from %.1f m at the Conch Bridge's east end (%.1f, %.1f) to %.1f m at the forecourt's edge (%.1f, %.1f), the last flight's top %.2f m from it." % (
               sum(STEPS), RISER * 100, len(STEPS), TREAD * 100, WIDTH, BRIDGE_Z, foot[0], foot[1], top_z, top[0], top[1], float(np.hypot(*(E - top)))),
           "- %.0f m of way with its landings (chapter 02: 380 m); %.0f degrees along it on average." % (plen, math.degrees(math.atan((top_z - BRIDGE_Z) / plen))),
           "- Landing 6, the Lhabab Chorten's platform, at (%.1f, %.1f), %.1f m from chapter 02's place, at %.1f m (chapter 02: 2,742)." % (
               j6[1][0], j6[1][1], float(np.hypot(*(j6[1] - np.array(L6)))), j6[3]), "",
           "| leg | bearing | flights | the middle off the ground on average | cut at most | filled at most |", "|---|---|---|---|---|---|"]
    for k in range(len(legs)):
        lr = [r for r in fl_rows if r["leg"] == k + 1]
        rep.append("| %d | %03.0f | %s | %.1f m | %.1f m | %.1f m |" % (k + 1, lr[0]["bearing"], ", ".join(str(r["number"]) for r in lr),
                                                                     float(np.mean([r["mean"] for r in lr])), max(r["cut"] for r in lr), max(r["fill"] for r in lr)))
    rep += ["", "The landings: " + ", ".join("%d %s %.1f m" % (lg["number"], lg["kind"], lg["z"]) for lg in landings) + "."]
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("dungrong: %d steps in %d flights, %.0f m of way from (%.1f, %.1f) to (%.1f, %.1f), landing 6 %.1f m from the chorten's place; cut %.1f m and filled %.1f m at most (cost %.0f) -> %s" % (
        sum(STEPS), len(STEPS), plen, foot[0], foot[1], E[0], E[1], float(np.hypot(*(j6[1] - np.array(L6)))),
        max(r["cut"] for r in fl_rows), max(r["fill"] for r in fl_rows), fun, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
