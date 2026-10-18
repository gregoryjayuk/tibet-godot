#!/usr/bin/env python3
"""The Caravan Ground's ground (D02 `tsonggar`, GAR-01 to GAR-14; plan chapter 02, chapter 06, 7.1 and 8.6; M2 sprint 9,
step 1): the Caravan Ramp down to it, its yards' and houses' levels on the real ground, and where its things stand.

The Caravan Ramp, R-03 (GAR-11; chapter 02: "South pavilion -> the camp, 600 m, -80 m, 13%, 5 zigzags", and I-07
"switchbacks with a view at every turn"; chapter 06, 8.4: the herd's way down to the camp), as lanes (tools/terrain/
pads.py's form), Samkha's ramps' cousin. From R-01's end before the south pavilion SAM-04 it runs south past the
pavilion's front to its head, then zigzags down the ridge foot's face west of it (58-70% steep under the pavilion, 40%
lower down) in six legs and five switchbacks, chapter 02's five zigzags: south, north, south, north, south, and the last
north-west onto the terrace at the Caravan Ground's north-east corner by the corral GAR-09; each leg falls at GRADE (the
last at the ground's own rate, no steeper); at each switchback the two legs come into a level landing SEP apart, a strip
of the slope between them behind their walls and room for a yak to turn, and from the foot a short run-out follows the
camp's own ground towards its middle. The switchbacks and the foot are fitted to the ground (the shaped raster before the pads, in the design's
heights: the real ground less the site's shift): of all the zigzags within the face's bounds (south of the pavilion's
forecourt and the fan channel's bank, no further south than the graveyard GAR-12), the one whose beds keep nearest the
ground along their middles and their edges, so it is cut and filled least; its landings level with the ground about
them; its foot on the fan's ground. pads.py carves the lanes, tools/town/walls.py walls their sides where they are cut
or filled, tools/terrain/control.py paints them trodden; the herd comes down them (M2 sprint 9, step 2).

The camp's levels: chapter 02's heights are the design's, and on the real ground its yards and houses stood up to 10 m
off it (the fodder yard on a 10 m fill over the slope to the fan channel, the drowned footings in a 10 m hole); each of
PADS stands at the middle (the median) of the ground under it, the fodder yard moved onto the terrace by the ramp's foot;
FOLLOW lie on the ground as it is (the corral's walls follow it; the footings show through the turf). pads.py reads them.

Its things (world/camp.gd places them, the kit's ../tibet-blender kit/camp.py builds them): the windbreaks of stacked
loads (GAR-02; chapter 06, 7.1: tea cases "stacked into windbreaks 3-12 m long and 1.2-1.5 m high"), CV-01's wool from
11:00 by the black tents, CV-02's tea in the hollow below the ramp's foot as its herd halts in a block beside it (8.6:
"yak halted by the windbreak stacks"; world/herd.gd), a trader's tea waiting for the coracles there all day; the hay
piles bought at the fodder yard for each caravan's yak (8.6: a quarter of an hour after); the fodder yard GAR-13 on its level; the dung-drying walls GAR-07, 60 m of them in short
walls along the contour on the slope under the graveyard; and the corral's walls (GAR-09), free-standing on the ground
(tools/town/walls.py, as the gardens' are). Each thing on the ground: along its contour where it is given no facing, at
the lowest ground under it (a stack is not left standing on air), a heap of hay at its middle height.
Run: tools/py tools/town/caravan_ground.py   Writes data/caravan_ground.json and docs/town/caravan-ground-report.md
(tools/terrain/build.sh runs it before pads.py; about 15 s).
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
OUT = os.path.join(ROOT, "data", "caravan_ground.json")
REPORT = os.path.join(ROOT, "docs", "town", "caravan-ground-report.md")
TOWN = os.path.join(ROOT, "data", "town.json")
JUNCTION = (-122.0, -141.0)  # R-01's end by the south pavilion's east side (data/arrival.json): R-02 leaves east, R-03 south
HEAD = (-122.0, -153.0)  # the ramp's head, past the pavilion's front (SAM-04, 10 x 6 at -130, -146, facing south)
TOP_Z = 2655.0  # R-01's level there, the pavilion's floor (the design's height)
GRADE = 0.13
LEGS = 6  # five switchbacks
WIDTH = 4.5  # a yak with its load, and room to pass it
SEP = WIDTH + 3.5  # at a switchback the two legs' middles this far apart: a strip of the slope between them (side by side,
# a sliver of ground was left between two walls)
LANDING = 5.0  # a switchback's depth past the legs' ends: room for a yak to turn
OVERLAP = 1.0  # each leg runs this far into its landings, level, so no wedge of the slope is left where they meet
NORTH_LIM, SOUTH_LIM = -150.0, -300.0  # the landings keep between these y
FOOT_X, FOOT_Y = -268.0, (-262.0, -170.0)  # the foot on the fan: west of the face, south of the fodder yard GAR-13
CAMP = (-360.0, -235.0)  # GAR-01's middle: the run-out turns towards it
LAST_GRADE = (0.04, GRADE)  # the last leg falls at the ground's own rate onto the fan, no steeper than GRADE
RUN_OUT = 14.0  # the run-out from the foot towards the camp's middle, on its own ground
START = [-140.7, -295.0, -165.9, -202.6, -201.3, -294.6, -207.9, -174.7, -240.4, -231.6, -268.0, -170.0, 41.8]  # the
# switchbacks' and the foot's points (the legs' ends at their landings' edges) and the last leg's grade (its logit), from
# a wide search (9 Oct 2026: five legs and six, the face's south bound at -282, -300 and -320)
TRIALS, SEED = 5, 5
W_EDGE, W_LANDING, W_FOOT = 0.25, 24.0, 50.0  # the edges' weight beside the middle's, the landings', the foot's
# The camp: each of PADS level at the median of the ground under it, at the gazetteer's place or the one given; FOLLOW on
# the ground as it is
PADS = {"GAR-04": None, "GAR-05": None, "GAR-06": None, "GAR-13": (-300.0, -168.0)}  # the fodder yard onto the terrace by
# the ramp's foot, from (-330, -175) on the slope down to the fan channel's trench
FOLLOW = ("GAR-03", "GAR-09", "GAR-14")  # the black tents pitched on the turf, the corral, the drowned footings
BLOCK = ((-303.5, -233.5), 8, 8, 3.0, 1.8, 270.0)  # CV-02's herd halted in a block by its windbreaks (chapter 06, 8.6): its
# middle, ranks and files, their spacing (along its facing and across), the way it faces (west, to the stacks)
ENTRY = (-283.0, -206.0)  # where the herd comes onto the camp from the ramp's run-out, past the corral's south-east corner
WALK = [(-282.0, -204.0), (-320.0, -207.0), (-337.0, -209.0)]  # on from the ramp's foot round the corral's south side to
# the trader's tea stacks (tests/terrain/s3.gd's route `camp`)
CORRAL = ((-315.0, -285.0, -200.0, -180.0), 1.6, (-315.0, -190.0), 3.0)  # GAR-09's box, its walls' height over the ground,
# its gate's middle (west, towards the plank bridge GAR-10 and Hejie) and width
# [type, x, y, facing (the front's bearing; None: along the ground's contour), from, until (minutes; None: all day), of]
THINGS = [
    ["gar13_fodder_yard_v1", -300.0, -168.0, 180.0, None, None, "GAR-13"],
    # CV-02's tea, stacked as its yak are unloaded (chapter 06, 8.6): an L in the hollow below the ramp's foot; its
    # minutes are after the herd's halt in its block beside it ("+n": world/herd.gd's working out gives the halt)
    ["camp_tea_stack_12_v1", -325.0, -223.0, 270.0, "+5", None, "CV-02"],
    ["camp_tea_stack_6_v2", -320.6, -216.4, 0.0, "+9", None, "CV-02"],
    ["camp_tea_stack_3_v1", -326.8, -232.0, 300.0, "+13", None, "CV-02"],
    ["camp_hay_pile_v1", -300.0, -246.0, None, "+15", None, "CV-02"],  # the hay bought for them, south of the block
    ["camp_hay_pile_v2", -309.0, -249.0, None, "+15", None, "CV-02"],
    ["camp_hay_pile_v3", -292.0, -250.0, None, "+17", None, "CV-02"],
    ["camp_hay_pile_v1", -316.0, -246.5, None, "+19", None, "CV-02"],
    # CV-01's wool, eastbound, unloaded by noon by the black tents (chapter 06's day: "11:00 crossed; being picketed and fed hay")
    ["camp_wool_stack_9_v1", -382.0, -246.0, None, 660, None, "CV-01"],
    ["camp_wool_stack_6_v2", -389.5, -236.5, None, 665, None, "CV-01"],
    ["camp_hay_pile_v2", -372.0, -252.0, None, 670, None, "CV-01"],
    ["camp_hay_pile_v3", -377.0, -262.0, None, 670, None, "CV-01"],
    ["camp_hay_pile_v1", -366.0, -243.0, None, 672, None, "CV-01"],
    # a trader's tea waiting for the coracles (GAR-02's own place), there all day
    ["camp_tea_stack_9_v3", -344.0, -213.0, None, None, None, "GAR-02"],
    ["camp_tea_stack_3_v2", -351.5, -219.5, 110.0, None, None, "GAR-02"],
    # the dung-drying walls GAR-07: 60 m of them in three rows along the contour on the slope under the graveyard
    ["camp_dung_wall_7_v1", -318.0, -262.0, None, None, None, "GAR-07"],
    ["camp_dung_wall_7_v2", -309.0, -262.5, None, None, None, "GAR-07"],
    ["camp_dung_wall_7_v3", -300.0, -263.0, None, None, None, "GAR-07"],
    ["camp_dung_wall_7_v2", -313.5, -268.5, None, None, None, "GAR-07"],
    ["camp_dung_wall_7_v1", -304.5, -269.0, None, None, None, "GAR-07"],
    ["camp_dung_wall_7_v3", -295.5, -269.5, None, None, None, "GAR-07"],
    ["camp_dung_wall_7_v1", -309.0, -275.0, None, None, None, "GAR-07"],
    ["camp_dung_wall_7_v2", -300.0, -275.5, None, None, None, "GAR-07"],
    # the camp at dusk (M2 sprint 9, step 3; chapter 06, 8.6): the two crews' black tents at GAR-03, CV-01's pitched since
    # it came up from the river, CV-02's pitched after its herd's halt; their dung fires (the game lights them: world/
    # camp.gd FIRES); the felt numnahs on CV-02's stacks; the picket line west of the trader's tea; the hirer's saddles
    ["black_tent_v1", -422.0, -250.0, None, 660, None, "CV-01"],  # on the gentler ground west of GAR-03's place (its slope
    ["black_tent_v2", -418.0, -266.0, None, "+30", None, "CV-02"],  # there 20-40%: a tent half buried), along the contour
    ["camp_hearth_v1", -381.0, -236.0, None, 660, None, "CV-01"],
    ["camp_hearth_v2", -395.0, -241.5, None, 660, None, "CV-01"],
    ["camp_hearth_v3", -331.0, -221.0, None, "+20", None, "CV-02"],
    ["camp_hearth_v1", -312.0, -209.5, None, "+20", None, "CV-02"],
    ["camp_hearth_v2", -333.5, -238.0, None, "+22", None, "CV-02"],
    ["camp_hearth_v3", -288.5, -236.5, None, "+22", None, "CV-02"],
    ["camp_numnahs_6_v1", -325.0, -226.0, 270.0, "+12", None, "CV-02"],
    ["camp_numnahs_6_v2", -320.6, -216.4, 0.0, "+12", None, "CV-02"],
    ["picket_line_v1", -362.0, -212.0, 90.0, None, None, "GAR-01"],
    ["pack_saddles_cn_v1", -318.5, -194.0, 270.0, None, None, "GAR-09"],
]
ON_STACK = {"camp_numnahs_6": 1.2}  # a kind laid on the stack beneath it: the stack's top over its foot
SIZE = {"camp_tea_stack_12": (12.0, 0.7), "camp_tea_stack_9": (9.0, 0.7), "camp_tea_stack_6": (6.0, 0.35), "camp_tea_stack_3": (3.0, 0.35),
        "camp_wool_stack_9": (9.0, 0.6), "camp_wool_stack_6": (6.0, 0.6), "camp_hay_pile": (2.4, 1.8), "camp_dung_wall_7": (7.0, 0.55),
        "gar13_fodder_yard": (20.0, 12.0), "black_tent": (8.0, 5.0), "camp_hearth": (1.4, 1.4), "camp_numnahs_6": (6.0, 0.7),
        "picket_line": (16.0, 0.6), "pack_saddles_cn": (2.0, 0.8)}  # each kind's length and depth on the ground, for its level and its contour


def last_grade(u):
    return LAST_GRADE[0] + (LAST_GRADE[1] - LAST_GRADE[0]) / (1.0 + math.exp(-max(-40.0, min(40.0, u))))


def legs_of(v):
    """The legs (start, end, z at start, z at end, grade, length) of the fit's vector: each leg's end on its landing's
    edge, the next one's start SEP west of it, the landing between them level."""
    E = np.asarray(v[:2 * LEGS], float).reshape(LEGS, 2)
    out = []
    S, z = np.array(HEAD), TOP_Z
    for k in range(LEGS):
        gr = GRADE if k < LEGS - 1 else last_grade(v[2 * LEGS])
        L = float(np.hypot(*(E[k] - S)))
        out.append((S.copy(), E[k].copy(), z, z - gr * L, gr, L))
        z -= gr * L
        S = E[k] + np.array([-SEP, 0.0])
    return out


def seg_dist(a0, a1, b0, b1):
    t = np.linspace(0.0, 1.0, 30)
    A = a0[None] + (a1 - a0)[None] * t[:, None]
    B = b0[None] + (b1 - b0)[None] * t[:, None]
    return float(np.min(np.hypot(A[:, None, 0] - B[None, :, 0], A[:, None, 1] - B[None, :, 1])))


def make_cost(Z):
    def cost(v, rows=None):
        legs = legs_of(v)
        c = 0.0
        for k, (S, E, za, zb, gr, L) in enumerate(legs):
            if L < 1.0:
                return 1e9
            d = (E - S) / L
            n = np.array([-d[1], d[0]])
            s = np.arange(0.0, L + 0.01, 2.0)
            P = S[None] + d[None] * s[:, None]
            bed = za - gr * s
            mid = Z(P[:, 0], P[:, 1]) - bed
            left = Z(P[:, 0] + n[0] * WIDTH / 2, P[:, 1] + n[1] * WIDTH / 2) - bed
            right = Z(P[:, 0] - n[0] * WIDTH / 2, P[:, 1] - n[1] * WIDTH / 2) - bed
            if np.isnan(mid).any() or np.isnan(left).any() or np.isnan(right).any():
                return 1e9
            c += 2.0 * (float(np.sum(mid ** 2)) + W_EDGE * float(np.sum(left ** 2 + right ** 2)))
            if rows is not None:
                rows.append({"leg": k + 1, "bearing": math.degrees(math.atan2(d[0], d[1])) % 360.0, "length": L, "z_a": za, "z_b": zb,
                             "grade": gr, "mean": float(np.mean(np.abs(mid))), "max": float(np.max(np.abs(mid))),
                             "cut": float(max(np.max(left), np.max(right), 0.0)), "fill": float(max(-np.min(left), -np.min(right), 0.0))})
            if k < LEGS - 1:  # the zigzag: south, north, south, north, south, each within 32 degrees of it
                c += 1e4 * (max(0.0, d[1] + 0.85) if k % 2 == 0 else max(0.0, 0.85 - d[1])) ** 2
            else:  # and the last west onto the fan
                c += 1e4 * max(0.0, d[0] + 0.3) ** 2
            c += 1e3 * max(0.0, 40.0 - L) ** 2
        E = np.asarray(v[:2 * LEGS], float).reshape(LEGS, 2)
        for k in range(LEGS - 1):  # the landings within the face's bounds, level with the ground about them
            south = k % 2 == 0
            c += 1e4 * (max(0.0, SOUTH_LIM - (E[k][1] - LANDING)) if south else max(0.0, E[k][1] + LANDING - NORTH_LIM)) ** 2
            m = E[k] + np.array([-SEP / 2, -LANDING / 2 if south else LANDING / 2])
            c += W_LANDING * (float(Z(m[0], m[1])) - legs[k][3]) ** 2
        foot, zf = legs[-1][1], legs[-1][3]
        c += W_FOOT * (float(Z(foot[0], foot[1])) - zf) ** 2
        c += 1e4 * (max(0.0, foot[0] - FOOT_X) ** 2 + max(0.0, FOOT_Y[0] - foot[1]) ** 2 + max(0.0, foot[1] - FOOT_Y[1]) ** 2)
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
            v[:2 * LEGS] += rng.normal(0.0, 6.0, 2 * LEGS)
        r = minimize(cost, v, method="Nelder-Mead", options={"maxiter": 30000, "maxfev": 30000, "xatol": 0.05, "fatol": 0.5, "adaptive": True})
        r = minimize(cost, r.x, method="Powell", options={"maxiter": 30000, "xtol": 0.05, "ftol": 1e-4})
        if best is None or r.fun < best.fun:
            best = r
    rows = []
    cost(best.x, rows)
    return best.x, rows


def lane(lid, a, d, L, za, zb, width, prof=None, **kw):
    out = {"id": lid, "from": [round(float(a[0]), 2), round(float(a[1]), 2)], "dir": [round(float(d[0]), 5), round(float(d[1]), 5)],
           "length": round(float(L), 2), "width": width, "z_a": round(float(za), 2), "z_b": round(float(zb), 2), "flight": None,
           "profile": [[round(float(s), 2), round(float(z), 2)] for s, z in (prof or [(0.0, za), (L, zb)])]}
    out.update(kw)
    return out

CLEAR = 1.4  # metres a beast keeps from another's middle (a yak's breadth and a little)


def _free(p, taken, things, clear=CLEAR, keep=None):
    """Whether a beast can stand at p: off every other's place, every stack, wall, tent and fire, and in `keep` (x0, x1, y0, y1)."""
    if keep is not None and not (keep[0] <= p[0] <= keep[1] and keep[2] <= p[1] <= keep[3]):
        return False
    for q in taken:
        if math.hypot(p[0] - q[0], p[1] - q[1]) < clear:
            return False
    for th in things:
        k = kind_of(th["type"])
        if k in ("camp_numnahs_6", "picket_line"):
            continue
        L, D = SIZE[k]
        if k == "black_tent":
            L, D = L + 8.0, D + 8.0  # and its guy ropes
        th_ = math.radians(th["facing"])
        fx, fy = math.sin(th_), math.cos(th_)
        dx, dy = p[0] - th["at"][0], p[1] - th["at"][1]
        u, v = dx * fy - dy * fx, dx * fx + dy * fy  # along its length, along its front
        if abs(u) < L / 2 + 0.9 and abs(v) < D / 2 + 0.9:
            return False
    return True


def _groups(rnd, Z, n, area, taken, things, size=(2, 3)):
    """n places in twos and threes over `area` (x0, x1, y0, y1): each group a few metres from any other, its beasts side
    by side or head to tail, all at rest; [x, y, z, facing]."""
    out = []
    tries = 0
    while len(out) < n and tries < 4000:
        tries += 1
        c = (rnd.uniform(area[0], area[1]), rnd.uniform(area[2], area[3]))
        if not _free(c, taken, things, clear=4.0):
            continue
        k = min(rnd.randint(*size), n - len(out))
        face = rnd.uniform(0.0, 360.0)
        mem = []
        for j in range(k):
            a = math.radians(face + 90.0 + rnd.uniform(-25.0, 25.0))
            q = (c[0] + math.sin(a) * (j - (k - 1) / 2) * 1.5 + rnd.uniform(-0.3, 0.3), c[1] + math.cos(a) * (j - (k - 1) / 2) * 1.5 + rnd.uniform(-0.3, 0.3))
            if not _free(q, taken + mem, things):
                mem = []
                break
            mem.append(q)
        for q in mem:
            taken.append(q)
            out.append([round(q[0], 2), round(q[1], 2), round(float(Z(*q)), 2), round((face + rnd.uniform(-30.0, 30.0)) % 360.0, 1)])
    return out


def _rings(Z, piles, per, taken, things, r=1.9):
    """`per` places round each pile, facing it (the yak's heads in the hay)."""
    out = []
    for (px, py) in piles:
        for j in range(per):
            a = 2.0 * math.pi * (j + 0.5) / per
            q = (px + math.cos(a) * r, py + math.sin(a) * r)
            taken.append(q)
            out.append([round(q[0], 2), round(q[1], 2), round(float(Z(*q)), 2), round(math.degrees(math.atan2(px - q[0], py - q[1])) % 360.0, 1)])
    return out


def camp_animals(Z, things, block):
    """The camp's beasts' places: CV-02's at its hay or lying in twos and threes round the hollow, CV-01's 60 by its own
    stacks and tents, the picket line's twelve mules and nine ponies with a mastiff tied at each end, the hirer's eight
    Chinese mules in his corral."""
    import random
    rnd = random.Random(1903)
    hay2 = [tuple(t["at"][:2]) for t in things if t["of"] == "CV-02" and kind_of(t["type"]) == "camp_hay_pile"]
    hay1 = [tuple(t["at"][:2]) for t in things if t["of"] == "CV-01" and kind_of(t["type"]) == "camp_hay_pile"]
    others = [t for t in things if kind_of(t["type"]) != "camp_hay_pile"]
    taken = []
    cv02_hay = _rings(Z, hay2, 8, taken, others)
    cv02_lie = _groups(rnd, Z, 62 - len(cv02_hay), (-336.0, -286.0, -260.0, -205.0), taken, others)
    taken1 = []
    cv01_eat = _rings(Z, hay1, 8, taken1, others)
    cv01_lie = _groups(rnd, Z, 30, (-418.0, -355.0, -275.0, -222.0), taken1, others)
    cv01_stand = _groups(rnd, Z, 6, (-418.0, -355.0, -275.0, -222.0), taken1, others, size=(1, 2))
    pk = next(t for t in things if kind_of(t["type"]) == "picket_line")
    th_ = math.radians(pk["facing"])
    fx, fy = math.sin(th_), math.cos(th_)  # its front: the side the beasts stand
    ax, ay = fy, -fx  # along the rope
    picket = []
    for j in range(21):  # twelve mules and nine ponies, each side of the rope by turns, a metre and a half apart a side,
        u = -7.5 + 15.0 * j / 20.0  # facing it
        side = 1.0 if j % 2 == 0 else -1.0
        q = (pk["at"][0] + ax * u + fx * side * 1.0, pk["at"][1] + ay * u + fy * side * 1.0)
        kind = "pony" if j % 7 in (1, 3, 5) else "mule"
        picket.append([kind, round(q[0], 2), round(q[1], 2), round(float(Z(*q)), 2), round((pk["facing"] + (180.0 if side > 0 else 0.0) + rnd.uniform(-12.0, 12.0)) % 360.0, 1)])
    for sx in (-1.0, 1.0):  # a mastiff tied at each end
        q = (pk["at"][0] + ax * sx * 9.2, pk["at"][1] + ay * sx * 9.2)
        picket.append(["mastiff", round(q[0], 2), round(q[1], 2), round(float(Z(*q)), 2), round(math.degrees(math.atan2(ax * sx, ay * sx)) % 360.0, 1)])
    (x0, x1, y0, y1), _h, _g, _w = CORRAL
    corral = []
    for j in range(8):
        for _ in range(60):
            q = (rnd.uniform(x0 + 2.0, x1 - 2.0), rnd.uniform(y0 + 2.0, y1 - 2.0))
            if all(math.hypot(q[0] - c[0], q[1] - c[1]) > 2.2 for c in corral):
                corral.append([round(q[0], 2), round(q[1], 2), round(float(Z(*q)), 2), round(rnd.uniform(0.0, 360.0), 1)])
                break
    return {"cv02_hay": cv02_hay, "cv02_lie": cv02_lie, "cv01": [p + ["eat"] for p in cv01_eat] + [p + ["lie"] for p in cv01_lie] + [p + ["stand"] for p in cv01_stand],
            "picket": picket, "corral": corral}


def kind_of(t):
    return t.rsplit("_v", 1)[0]


def contour_facing(Z, x, y):
    """The front's bearing that lays a thing's length along the ground's contour: facing down the slope."""
    e = 2.0
    gx = (float(Z(x + e, y)) - float(Z(x - e, y))) / (2 * e)
    gy = (float(Z(x, y + e)) - float(Z(x, y - e))) / (2 * e)
    if math.hypot(gx, gy) < 1e-3:
        return 180.0
    return math.degrees(math.atan2(-gx, -gy)) % 360.0


def footprint_z(Z, x, y, facing, L, D, how="min"):
    """The ground under a thing of length L (across its facing) and depth D: its least, or its median."""
    th = math.radians(facing)
    fx, fy = math.sin(th), math.cos(th)  # the front
    ax, ay = fy, -fx  # along its length
    us, vs = np.meshgrid(np.linspace(-L / 2, L / 2, max(3, int(L) + 1)), np.linspace(-D / 2, D / 2, max(3, int(D) + 1)))
    zs = Z(x + us * ax + vs * fx, y + us * ay + vs * fy)
    return float(np.nanmin(zs) if how == "min" else np.nanmedian(zs))


def main():
    site = Site.load()
    g = site.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site.shift  # noqa: E731
    v, rows = fit(Z)
    legs = legs_of(v)
    lanes = []
    a, b = np.array(JUNCTION), np.array(HEAD)
    L0 = float(np.hypot(*(b - a)))
    lanes.append(lane("R-03.a", a, (b - a) / L0, L0 + OVERLAP, TOP_Z, TOP_Z, WIDTH, road=True))  # past the pavilion's front
    path = [[JUNCTION[0], JUNCTION[1], TOP_Z], [HEAD[0], HEAD[1], TOP_Z]]
    for k, (S, E, za, zb, gr, L) in enumerate(legs):
        d = (E - S) / L
        back = OVERLAP if k else 0.0  # into the landing it leaves (the first from the head's own lane)
        ahead = OVERLAP if k < LEGS - 1 else 0.0
        prof = [(0.0, za), (back + L, zb)] if not back else [(0.0, za), (back, za), (back + L, zb)]
        if ahead:
            prof.append((back + L + ahead, zb))
        lanes.append(lane("R-03.%d" % (k + 1), S - d * back, d, back + L + ahead, za, zb, WIDTH, prof, road=True))
        path.append([round(float(E[0]), 2), round(float(E[1]), 2), round(zb, 2)])
        if k < LEGS - 1:  # the landing: level, across both legs' ends and LANDING past them
            south = k % 2 == 0
            yl = E[1] - LANDING / 2 if south else E[1] + LANDING / 2
            lanes.append(lane("R-03.L%d" % (k + 1), (E[0] + WIDTH / 2, yl), (-1.0, 0.0), SEP + WIDTH, zb, zb, LANDING, road=True))
            turn = E[1] - LANDING / 2 if south else E[1] + LANDING / 2  # the way round it, through its middle
            path += [[round(float(E[0]), 2), round(turn, 2), round(zb, 2)], [round(float(E[0] - SEP), 2), round(turn, 2), round(zb, 2)],
                     [round(float(E[0] - SEP), 2), round(float(E[1]), 2), round(zb, 2)]]
    # the run-out from the foot towards the camp's middle, its bed the camp's own ground under it from the foot's level
    S, E, za, zb, gr, L = legs[-1]
    d = np.array(CAMP) - E
    d /= float(np.hypot(*d))
    Lr = RUN_OUT
    ss = np.arange(0.0, Lr + 0.01, 2.0)
    ground = Z(E[0] + d[0] * ss, E[1] + d[1] * ss)
    bed = ground + (zb - ground[0]) * np.clip(1.0 - ss / (Lr * 0.6), 0.0, 1.0)  # the foot's step taken up over its first metres
    q = E + d * Lr
    zq = float(bed[-1])
    lanes.append(lane("R-03.b", E, d, Lr, zb, zq, WIDTH, list(zip(ss, bed)), road=True))
    path.append([round(float(q[0]), 2), round(float(q[1]), 2), round(zq, 2)])
    total = L0 + sum(r["length"] for r in rows) + Lr
    # the camp's pads on the real ground, and the corral's walls following it
    town = {b["id"]: b for b in json.load(open(TOWN, encoding="utf-8"))["buildings"]}
    pads, pad_lines = {}, []
    for pid, at in PADS.items():
        b = town[pid]
        x, y = (at if at else b["pos"][:2])
        w, d_ = b["footprint"]
        zm = footprint_z(Z, x, y, float(b.get("rot_deg") or 180.0), w, d_, "median")
        lo, hi = footprint_z(Z, x, y, float(b.get("rot_deg") or 180.0), w, d_, "min"), -footprint_z(lambda a, c: -Z(a, c), x, y, float(b.get("rot_deg") or 180.0), w, d_, "min")
        pads[pid] = {"level": round(zm, 2)} if not at else {"at": [x, y], "level": round(zm, 2)}
        pad_lines.append("%s %s: level %.1f m (chapter 02: %.0f), the ground under it %.1f to %.1f m%s" % (
            pid, b["name_en"].split(" (")[0], zm, b["pos"][2], lo, hi, " (moved from %.0f, %.0f)" % tuple(b["pos"][:2]) if at else ""))
    (x0, x1, y0, y1), wall_h, gate, gate_w = CORRAL
    ring = [(x0, gate[1] - gate_w / 2), (x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, gate[1] + gate_w / 2)]  # from the gate's
    pts = []  # south jamb round to its north jamb, a point a metre
    for (ax, ay), (bx, by) in zip(ring, ring[1:]):
        n = max(1, int(round(math.hypot(bx - ax, by - ay))))
        pts += [(ax + (bx - ax) * t / n, ay + (by - ay) * t / n) for t in range(n)]
    pts.append(ring[-1])
    walls = [{"of": "GAR-09", "h": wall_h, "pts": [[round(px, 2), round(py, 2), round(float(Z(px, py)), 2)] for px, py in pts]}]
    things = []
    for t, x, y, facing, t0, t1, of in THINGS:
        k = kind_of(t)
        L, D = SIZE[k]
        if facing is None:
            facing = contour_facing(Z, x, y)
        if of in pads:  # on its pad's level
            zt = pads[of]["level"]
        elif k in ("camp_hay_pile", "black_tent"):  # a loose heap settles on the ground, a tent's skirt is pegged down
            # into it: at its middle height, its bottom below its edges
            zt = footprint_z(Z, x, y, facing, L, D, "median")
        else:  # at the lowest ground under it
            zt = footprint_z(Z, x, y, facing, L, D, "min")
        th = {"type": t, "at": [x, y, round(zt, 2)], "facing": round(facing, 1), "from": t0, "until": t1, "of": of,
              "fall": round(-footprint_z(lambda a, c: -Z(a, c), x, y, facing, L, D) - footprint_z(Z, x, y, facing, L, D), 2)}
        if isinstance(t0, str):  # minutes after CV-02's halt
            th["from"], th["after"] = None, float(t0[1:])
        things.append(th)
    # CV-02's block: its spots, the farthest from the entry first (the first in fills the back), each a little off the
    # grid and turned, as a halted herd stands; on the ground (world/herd.gd stands each on the terrain)
    import random
    rnd = random.Random(902)
    (bx, by), ranks, files, dr, df, bface = BLOCK
    th_ = math.radians(bface)
    fwd = (math.sin(th_), math.cos(th_))
    acr = (fwd[1], -fwd[0])
    spots = []
    for r in range(ranks):
        for f in range(files):
            u, v = (r - (ranks - 1) / 2) * dr, (f - (files - 1) / 2) * df
            x, y = bx + fwd[0] * u + acr[0] * v + rnd.uniform(-0.3, 0.3), by + fwd[1] * u + acr[1] * v + rnd.uniform(-0.3, 0.3)
            spots.append([round(x, 2), round(y, 2), round((bface + rnd.uniform(-18.0, 18.0)) % 360.0, 1)])
    spots.sort(key=lambda q: -math.hypot(q[0] - ENTRY[0], q[1] - ENTRY[1]))
    block = {"entry": [ENTRY[0], ENTRY[1], round(float(Z(*ENTRY)), 2)], "spots": spots[:62]}
    for th in things:  # a thing on a stack: on its top
        k = kind_of(th["type"])
        if k in ON_STACK:
            st = min((t for t in things if kind_of(t["type"]).startswith("camp_tea_stack")),
                     key=lambda t: math.hypot(t["at"][0] - th["at"][0], t["at"][1] - th["at"][1]))
            th["at"][2] = round(st["at"][2] + ON_STACK[k], 2)
    animals = camp_animals(Z, things, block)
    data = {"about": "The Caravan Ground's ground (M2 sprint 9, step 1), written by tools/town/caravan_ground.py. `lanes`: the Caravan Ramp R-03 (GAR-11): from R-01's end past the south pavilion's front to its head, the six legs fitted to the ground falling at 13% (the last at the ground's own rate onto the fan), the five switchbacks' level landings, the run-out towards the camp's middle, for tools/terrain/pads.py, tools/town/walls.py, tools/terrain/control.py and the street graph; `path` its line from R-01's end to the camp (x, y and the design's height), round each landing through its middle. `pads`: the camp's yards and houses at the median of their ground (a moved one's `at`), `follow`: those on the ground as it is, for pads.py. `walls`: free-standing walls on the ground, their height over it (the corral GAR-09's), for walls.py. `walk`: the route `camp`'s way on from the ramp's foot (tests/terrain/s3.gd). `cv02_block`: where CV-02's herd comes onto the camp (`entry`) and the 62 spots it halts on (x, y, facing; the first in takes the first), for world/herd.gd. `animals`: the camp's beasts' places (x, y, the design's height, facing): CV-02's yak at its hay (`cv02_hay`) or lying down in twos and threes (`cv02_lie`), CV-01's 60 (`cv01`: at its hay, lying, standing), the picket line's mules and ponies and its two mastiffs (`picket`), the hirer's mules in his corral (`corral`), for world/herd.gd and world/camp_animals.gd. `things`: the kit's types world/camp.gd places (`at` x, y and the design's height, `facing` the front's bearing, shown from `from` until `until`, game minutes, or all day; or `after` minutes after CV-02's halt). Regenerated with the terrain.",
            "grade": GRADE, "width": WIDTH, "top": [JUNCTION[0], JUNCTION[1], TOP_Z], "foot": path[-1], "path": path, "lanes": lanes,
            "pads": pads, "follow": list(FOLLOW), "walls": walls, "things": things,
            "walk": [[x, y, round(float(Z(x, y)), 2)] for x, y in WALK], "cv02_block": block, "animals": animals}
    json.dump(data, open(OUT, "w", encoding="utf-8"), indent=1)
    lines = ["leg %d: bearing %03.0f, %.0f m at %.1f%%, %.1f to %.1f m; its middle %.1f m from the ground on average (%.1f at most), its edges cut %.1f m and filled %.1f m at most" % (
        r["leg"], r["bearing"], r["length"], 100.0 * r["grade"], r["z_a"], r["z_b"], r["mean"], r["max"], r["cut"], r["fill"]) for r in rows]
    report = ["# The Caravan Ground", "",
              "_Written by `tools/town/caravan_ground.py` (M2 sprint 9, step 1): the Caravan Ramp fitted to the ground of the ridge foot's face, cut and filled least; the camp's yards and houses on the real ground; where its things stand. Regenerated with the terrain._", "",
              "## The Caravan Ramp R-03", "",
              "From R-01's end by the south pavilion (%.0f, %.0f) at %.1f m, %.0f m south past its front to the head, then at %d%%:" % (JUNCTION[0], JUNCTION[1], TOP_Z, L0, round(GRADE * 100)), ""]
    report += ["- " + ln for ln in lines]
    report += ["- the run-out towards the camp's middle: %.0f m on its ground, %.1f to %.1f m (the foot %.1f m over the ground there)" % (Lr, zb, zq, zb - float(ground[0])), "",
               "%d landings, level, %.1f m by %.1f m. %.0f m in all (chapter 02: 600 m), %.1f m down (chapter 02: 80 m), to the camp's ground at (%.0f, %.0f, %.1f m)." % (
                   LEGS - 1, SEP + WIDTH, LANDING, total, TOP_Z - zq, q[0], q[1], zq), "",
               "## The camp's levels", ""]
    report += ["- " + ln for ln in pad_lines]
    report += ["- on the ground as it is: " + ", ".join("%s %s" % (f, town[f]["name_en"].split(" (")[0]) for f in FOLLOW), "",
               "## Its things", "", "Each at the lowest ground under it; `fall` is how far the ground under it rises above that (a thing on a slope sunk into it at its higher end).", "",
               "| Type | x, y | Height | Facing | Fall | Shown | Of |", "|---|---|---|---|---|---|---|"]
    hm = lambda m: "%02d:%02d" % (int(m) // 60, int(m) % 60)  # noqa: E731
    for th in things:
        report.append("| %s | %.0f, %.0f | %.1f | %03.0f | %.1f m | %s | %s |" % (th["type"], th["at"][0], th["at"][1], th["at"][2], th["facing"], th["fall"],
                                                                             ("%.0f min after CV-02's halt" % th["after"]) if "after" in th else ("all day" if th["from"] is None else "from " + hm(th["from"])), th["of"]))
    report += ["", "The corral GAR-09's walls: %.0f m, %.1f m over the ground, its gate %.0f m wide on the west." % (len(pts) - 1, wall_h, gate_w)]
    open(REPORT, "w", encoding="utf-8").write("\n".join(report) + "\n")
    print("caravan_ground: the ramp's %d legs, %.0f m, %.1f m down; %d pads, %d things, the corral's %.0f m of wall -> %s" % (
        LEGS, total, TOP_Z - zq, len(pads), len(things), len(pts) - 1, os.path.relpath(OUT, ROOT)))
    for ln in lines + pad_lines:
        print("  " + ln)


if __name__ == "__main__":
    main()
