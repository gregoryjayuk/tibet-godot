#!/usr/bin/env python3
"""The Serchu road's last kilometre (M2 sprint 12, step 1; plan chapter 02, D09, R-01, SER-04, SER-20; chapter 12's M2:
"the Serchu road's last kilometre (SER-01 to SER-04)"): R-01 from the Serchu Zampa's south abutment down the river's
south bank past the road chorten SER-20 to the cliff gallery's east end, fitted to the real ground as the ramps were
(tools/town/caravan_ground.py, castle_ramp.py). The south bank rises at 30-35 degrees from 10-15 m off the water
(data/rivers.json's Serchu: 2,805 m at the Zampa, 2,695 m by SER-20), so the road keeps along the slope at the level it
falls through, its bed cut into the slope and on fill below it (walled by tools/town/walls.py where either is high: a
mountain road's dry-stone revetments and retaining walls), falling evenly along its own length from the Zampa's deck
(2,812 m: chapter 02's 7 m over the water) to SER-20's (2,712 m, the arrival's road: data/arrival.json).
Its line: at every 5 m of the river, the offset south of the water where the ground stands a little over the road's
level there (so the bed is mostly cut, a little fill), smoothed so the road bends as the bank does but never sharply and
never back on itself; its two ends blended into the Zampa's abutment and SER-20; the levels then taken along the road's
own length and the offsets found again for them; then straightened into lanes no more than TOL off the line, each its own
grade, carved by tools/terrain/pads.py as road lanes (ramp_lanes), painted trodden by control.py.
It reads the river's line from data/rivers.json, the last build's (tools/terrain/rivers.py writes it after the pads): the
road keeps out of the channel, so the line it was fitted to holds.
Run: tools/py tools/terrain/serchu_road.py   Writes data/serchu_road.json (the lanes, the road's line for the game and the
caravan, the Zampa's axis) and docs/terrain/serchu-road-report.md (tools/terrain/build.sh runs it before pads.py).
"""
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
SOURCE = os.path.join(GEN, "valley_shaped_1m.tif")  # the ground before the pads (pads.py's SOURCE)
RIVERS = os.path.join(ROOT, "data", "rivers_seed.json")  # the rivers' line as M2 sprint 12 closed with it, pinned: the last
# build's data/rivers.json is fitted to ground these planners' own lanes cut, and drifted a step each build until they failed
# (ISS-182); refit it after the ground is reshaped (copy data/rivers.json over it and rerun the build)
OUT = os.path.join(ROOT, "data", "serchu_road.json")
REPORT = os.path.join(ROOT, "docs", "terrain", "serchu-road-report.md")
ZAMPA = (1250.0, -520.0)  # SER-04 over the river (chapter 02: an 18 m cantilever, 7 m over the water, 3 m wide)
ZAMPA_Z = 2812.0
SPAN = 18.0
SER20 = (427.5, -254.5)  # past the road chorten SER-20 (430, -250, 3 x 3) on its south side, so a walker going down keeps it
SER20_Z = 2712.0  # on the right; then level to the cliff gallery's east end, where the arrival's road goes on (data/arrival.json)
GALLERY = (420.0, -245.0, 2712.0)
WIDTH = 4.0  # R-01's bed as on the arrival (tools/terrain/arrival.py): a laden yak and room to pass
WALL_MIN = (1.2, 0.8)  # a dry-stone wall where the cut stands this high over the bed, or the fill this far under it
# (tools/town/walls.py, the lane's `wall_min`); lower, a bank of bare earth
CUT_IN = 0.8  # the bed sits into the slope: at the road's line the ground stands this much over its level
SMOOTH = 9  # river points (5 m apart) in the offset's moving average
D_MIN, D_MAX = 9.0, 70.0  # the road's line from the water's, metres
BEND = 1.6  # its offset changes no more than this a 5 m step of the river
BLEND = 40.0  # metres of the river over which each end is blended into the fitted line
TOL = 1.5  # a lane keeps within this of the fitted line
SHORT = 3.0  # the last lane stops this short of the gallery's east end (the arrival's bed goes on from there)
# The Zampa (M2 sprint 12, step 2): its deck runs on 2.6 m past each abutment's face (../tibet-blender kit/infra.py
# cantilever_bridge), its gateway chorten (chapter 02: "with gateway chorten") on the north end, the end the road from
# Jomo Gönpa reaches first, the road through its passage along the bridge's axis; R-01 on up the north bank from there,
# NORTH metres of the river, as far above the water as the deck is
DECK_PAST = 2.6
CHORTEN_W = 4.6  # the kit's ser04_gate_chorten: 4.6 m square, its passage 2.6 m wide on the road's level
NORTH = 220.0
NORTH_GRADE = 0.14  # its steepest, where the river climbs fastest above the Zampa
# The porters' rest SER-19 (chapter 02: 6 x 4, "a long low bench for propping loads"): beside the road on its uphill side
# REST_S metres from the Zampa, at the road's level, open to it (the gazetteer's place, 4 m under the road, had been cut)
REST = (6.0, 4.0)
REST_S = 14.0
# Along the road (M2 sprint 12, step 3): the road mani wall SER-15 (chapter 02: 90 m by (700, -320)) on the road, the road
# widened round it so each way keeps it on the right (going down, its south side); the durtro path's cairn SER-14 (by
# (1000, -470)) on the road's uphill side where the path nobody takes but funerals leaves it up the slope; the gold
# washings SER-12 (by (850, -380): three bark-roofed huts 4 x 3, the troughs) on the flat gravel bank between the road
# and the water, a path down to them from the road
MANI_AT, MANI_LEN, MANI_W = (700.0, -320.0), 90.0, 8.5
WALK_OFF = 2.4  # the way past it, off the road's line: the middle of the widened road's south half
CAIRN_AT = (1000.0, -470.0)
WASH_AT = (850.0, -380.0)
HUTS = ((-10.0, 3.5, 95.0), (0.0, 5.0, 85.0), (11.0, 3.0, 100.0))  # along the river from WASH_AT, back from the wet edge, turn
TROUGHS = ((-6.0, -0.6), (4.0, -0.4), (15.0, -0.7))  # along, from the wet edge: its low end over the water
WASH_SPOTS = (-22.0, -15.0, -10.5, 9.0, 21.0, 27.0)  # along the river from WASH_AT: where a washer crouches at the water's
# edge with a pan (step 6; the other six at the troughs and the camp)


def river():
    """The Serchu's points downstream: [x, y, water z, ...] every 5 m (data/rivers.json)."""
    r = json.load(open(RIVERS, encoding="utf-8"))
    return next(x for x in r["rivers"] if x["name"] == "Serchu")["pts"]


def nearest(pts, x, y):
    return min(range(len(pts)), key=lambda k: math.hypot(pts[k][0] - x, pts[k][1] - y))


def frames(pts, i0, i1):
    """For each river point from i0 to i1: [x, y, its south normal (left of downstream), downstream]."""
    out = []
    for k in range(i0, i1 + 1):
        a, b = pts[max(k - 1, 0)], pts[min(k + 1, len(pts) - 1)]
        ux, uy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(ux, uy)
        ux, uy = ux / L, uy / L
        out.append((pts[k][0], pts[k][1], -uy, ux, ux, uy))
    return out


def offsets(g, shift, F, z):
    """At each frame, the offset south of the water where the ground stands CUT_IN over the road's level z there."""
    D = []
    for (x, y, nx, ny, _, _), zk in zip(F, z):
        d = D_MAX
        for off in np.arange(D_MIN, D_MAX, 0.5):
            if float(g.z(x + nx * off, y + ny * off)) - shift >= zk + CUT_IN:
                d = float(off)
                break
        D.append(d)
    D = np.array(D)
    Ds = np.convolve(np.pad(D, SMOOTH // 2, mode="edge"), np.ones(SMOOTH) / SMOOTH, mode="valid")
    for j in range(1, len(Ds)):  # gentle bends
        Ds[j] = np.clip(Ds[j], Ds[j - 1] - BEND, Ds[j - 1] + BEND)
    n_b = int(BLEND / 5.0)  # the Zampa's end: off its south abutment, on its approach's fill
    d0 = SPAN / 2.0 + 1.0
    for j in range(min(n_b, len(Ds))):
        t = j / n_b
        Ds[j] = d0 + (Ds[j] - d0) * (3 * t * t - 2 * t ** 3)
    return Ds


def line_of(F, D, z):
    """The road's points [x, y, z] for the offsets D and levels z, the end blended into SER-20, never back on itself."""
    line = [[x + nx * d, y + ny * d, zk] for (x, y, nx, ny, _, _), d, zk in zip(F, D, z)]
    n_b = int(BLEND / 5.0)
    end = (SER20[0], SER20[1], SER20_Z)
    for j in range(max(0, len(line) - n_b), len(line)):
        t = (j - (len(line) - 1 - n_b)) / n_b
        w = 3 * t * t - 2 * t ** 3
        line[j] = [line[j][k] + (end[k] - line[j][k]) * w for k in range(3)]
    kept, at = [line[0]], [0]
    for j in range(1, len(line)):  # where the river bends sharply the offset line can loop on the bend's inside: a point
        # that does not go on from the last kept by a metre down the river is dropped
        ux, uy = F[j][4], F[j][5]
        if (line[j][0] - kept[-1][0]) * ux + (line[j][1] - kept[-1][1]) * uy >= 1.0 or j == len(line) - 1:
            kept.append(line[j])
            at.append(j)
    return kept, at


def even(line):
    """The levels along the road's own length: an even fall from the Zampa's deck to SER-20's."""
    s = [0.0]
    for a, b in zip(line[:-1], line[1:]):
        s.append(s[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    return [ZAMPA_Z + (SER20_Z - ZAMPA_Z) * v / s[-1] for v in s], s[-1]


def simplify(line, tol=TOL):
    """Douglas-Peucker on the plan, the levels carried."""
    P = np.array(line)
    keep = [0, len(P) - 1]

    def rec(a, b):
        if b <= a + 1:
            return
        ab = P[b, :2] - P[a, :2]
        L = np.linalg.norm(ab)
        v = P[a + 1:b, :2] - P[a, :2]
        d = np.abs(ab[0] * v[:, 1] - ab[1] * v[:, 0]) / max(L, 1e-9)
        m = int(np.argmax(d))
        if d[m] > tol:
            keep.append(a + 1 + m)
            rec(a, a + 1 + m)
            rec(a + 1 + m, b)
    rec(0, len(P) - 1)
    return [line[k] for k in sorted(keep)]


def split_at(pts, s_cut):
    """The polyline with a point put in at each of the lengths s_cut along it (the level interpolated)."""
    out, s = [list(pts[0])], 0.0
    cuts = sorted(s_cut)
    for a, b in zip(pts[:-1], pts[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        for c in cuts:
            if s < c < s + L - 0.01:
                t = (c - s) / L
                out.append([a[k] + (b[k] - a[k]) * t for k in range(3)])
        out.append(list(b))
        s += L
    return out


def at_length(pts, sv):
    """The point at length sv along the polyline, and its direction there."""
    s = 0.0
    for a, b in zip(pts[:-1], pts[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if s + L >= sv:
            t = (sv - s) / L
            return [a[k] + (b[k] - a[k]) * t for k in range(3)], ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        s += L
    a, b = pts[-2], pts[-1]
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    return list(b), ((b[0] - a[0]) / L, (b[1] - a[1]) / L)


def length_at(pts, x, y):
    """The length along the polyline of the point on it nearest (x, y)."""
    best, s, out = 1e18, 0.0, 0.0
    for a, b in zip(pts[:-1], pts[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        t = max(0.0, min(1.0, ((x - a[0]) * (b[0] - a[0]) + (y - a[1]) * (b[1] - a[1])) / (L * L)))
        d = math.hypot(a[0] + (b[0] - a[0]) * t - x, a[1] + (b[1] - a[1]) * t - y)
        if d < best:
            best, out = d, s + t * L
        s += L
    return out


def lanes_of(pts):
    """Each stretch a road lane (pads.py's ramp_lanes): its bed falling evenly, a metre on past its end at its foot's level
    so no wedge of the slope is left where it meets the next."""
    out = []
    for k, (a, b) in enumerate(zip(pts[:-1], pts[1:])):
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        out.append({"id": "R-01S.%d" % (k + 1), "from": [round(a[0], 2), round(a[1], 2)], "dir": [round(dx / L, 5), round(dy / L, 5)],
                    "length": round(L + 1.0, 2), "width": WIDTH, "z_a": round(a[2], 2), "z_b": round(b[2], 2), "flight": None,
                    "profile": [[0.0, round(a[2], 2)], [round(L, 2), round(b[2], 2)], [round(L + 1.0, 2), round(b[2], 2)]], "road": True,
                    "wall_min": list(WALL_MIN)})
    return out


def north_road(g, shift, pts, i0, axis, a0):
    """R-01 on the north bank: from the Zampa's north face `a0` along the bridge's `axis` through its gateway chorten,
    then up the bank NORTH metres of the river, at the deck's height over the water (smoothed), where the ground stands
    CUT_IN over that level north of the water; never back on itself. [x, y, z] from the bridge outwards."""
    over = ZAMPA_Z - pts[i0][2]
    n_up = int(NORTH / 5.0)
    ks = list(range(i0, max(0, i0 - n_up) - 1, -1))  # upstream from the Zampa
    F, z = [], []
    for k in ks:
        a, b = pts[max(k - 1, 0)], pts[min(k + 1, len(pts) - 1)]
        ux, uy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(ux, uy)
        ux, uy = ux / L, uy / L
        F.append((pts[k][0], pts[k][1], uy, -ux, -ux, -uy))  # its north normal (right of downstream), upstream
        z.append(pts[k][2] + over)
    z = list(np.convolve(np.pad(np.array(z), SMOOTH // 2, mode="edge"), np.ones(SMOOTH) / SMOOTH, mode="valid"))
    for j in range(1, len(z)):  # never falling as it goes up the river
        z[j] = max(z[j], z[j - 1])
    a1 = (a0[0] + axis[0] * (DECK_PAST + CHORTEN_W + 1.5), a0[1] + axis[1] * (DECK_PAST + CHORTEN_W + 1.5))
    for _ in range(3):  # its line where the ground stands at its levels, then its levels capped along its own length, again
        D = []
        for (x, y, nx, ny, _, _), zk in zip(F, z):
            d = D_MAX
            for off in np.arange(D_MIN, D_MAX, 0.5):
                if float(g.z(x + nx * off, y + ny * off)) - shift >= zk + CUT_IN:
                    d = float(off)
                    break
            D.append(d)
        D = np.convolve(np.pad(np.array(D), SMOOTH // 2, mode="edge"), np.ones(SMOOTH) / SMOOTH, mode="valid")
        for j in range(1, len(D)):
            D[j] = np.clip(D[j], D[j - 1] - BEND, D[j - 1] + BEND)
        line, at = [[a0[0], a0[1], ZAMPA_Z], [a1[0], a1[1], ZAMPA_Z]], [-1, -1]
        for j, ((x, y, nx, ny, ux, uy), d, zk) in enumerate(zip(F, D, z)):
            q = [x + nx * d, y + ny * d, max(zk, ZAMPA_Z)]
            if (q[0] - line[-1][0]) * ux + (q[1] - line[-1][1]) * uy >= 1.0 and math.hypot(q[0] - a1[0], q[1] - a1[1]) > BLEND / 2:
                line.append(q)
                at.append(j)
        for j in range(2, len(line)):  # no steeper than NORTH_GRADE along its own length (the river climbs 15% above the Zampa)
            run = math.hypot(line[j][0] - line[j - 1][0], line[j][1] - line[j - 1][1])
            line[j][2] = min(line[j][2], line[j - 1][2] + NORTH_GRADE * run)
        z = list(np.interp(np.arange(len(F)), at[2:], [q[2] for q in line[2:]]))
    return line


def cut_fill(g, shift, ln):
    """The most the ground stands over a lane's bed (cut) and under it (fill), across its width."""
    L = ln["length"] - 1.0
    (fx, fy), (ux, uy) = ln["from"], ln["dir"]
    t = np.linspace(0.0, L, max(2, int(L / 2.0)))
    out = []
    for side in (-WIDTH / 2, 0.0, WIDTH / 2):
        z = ln["z_a"] + (ln["z_b"] - ln["z_a"]) * t / L
        gz = g.z(fx + ux * t - uy * side, fy + uy * t + ux * side) - shift
        out.append(gz - z)
    d = np.concatenate(out)
    return float(max(d.max(), 0.0)), float(max(-d.min(), 0.0))


def main():
    site = Site.load()
    g = site.read(SOURCE)
    pts = river()
    i0, i1 = nearest(pts, *ZAMPA), nearest(pts, *SER20)
    F = frames(pts, i0, i1)
    s = [0.0]
    for k in range(i0 + 1, i1 + 1):
        s.append(s[-1] + math.hypot(pts[k][0] - pts[k - 1][0], pts[k][1] - pts[k - 1][1]))
    z = [ZAMPA_Z + (SER20_Z - ZAMPA_Z) * v / s[-1] for v in s]  # first along the river's length
    for _ in range(3):  # then along the road's own, its offsets found again for its levels
        D = offsets(g, site.shift, F, z)
        line, at = line_of(F, D, z)
        zl, length = even(line)
        z = list(np.interp(np.arange(len(F)), at, zl))
    for p_, zk in zip(line, zl):
        p_[2] = zk
    road = simplify(line) + [list(GALLERY)]
    s_mani = length_at(road, *MANI_AT)  # the mani wall's stretch: its lanes split off and widened round it
    m0, m1 = s_mani - MANI_LEN / 2, s_mani + MANI_LEN / 2
    road = split_at(road, [m0 - 3.0, m1 + 3.0])
    lanes = lanes_of(road)
    sv = 0.0
    for ln in lanes:
        if m0 - 3.5 <= sv and sv + ln["length"] - 1.0 <= m1 + 3.5:
            ln["width"] = MANI_W
            ln["mani"] = True
        sv += ln["length"] - 1.0
    last = lanes[-1]  # it stops short of the gallery's east end: the arrival's bed is the road's last metres, by the slot's edge
    L = last["length"] - 1.0 - SHORT
    last["length"] = round(L, 2)
    last["profile"] = [[0.0, last["z_a"]], [round(L, 2), last["z_b"]]]
    nx, ny = F[0][2], F[0][3]  # the Zampa's axis across the river, south to north
    axis = (-nx, -ny)
    a0 = (ZAMPA[0] - nx * SPAN / 2, ZAMPA[1] - ny * SPAN / 2)
    north = simplify(north_road(g, site.shift, pts, i0, axis, a0))
    for ln in lanes_of(north):  # (outwards from the bridge, as the south road's are)
        ln["id"] = ln["id"].replace("R-01S.", "R-01N.")
        lanes.append(ln)
    t1 = DECK_PAST + CHORTEN_W + 1.5  # a level landing where it turns up the bank out of the chorten's passage: the
    # turn is near a right angle, too sharp for two lanes' ends to meet without leaving a wedge of the slope
    lanes.append({"id": "R-01N.L", "from": [round(a0[0] + axis[0] * (t1 - 3.0), 2), round(a0[1] + axis[1] * (t1 - 3.0), 2)],
                  "dir": [round(axis[0], 5), round(axis[1], 5)], "length": 6.0, "width": 6.0, "z_a": ZAMPA_Z, "z_b": ZAMPA_Z,
                  "flight": None, "profile": [[0.0, ZAMPA_Z], [6.0, ZAMPA_Z]], "road": True, "wall_min": list(WALL_MIN)})
    cf = [cut_fill(g, site.shift, ln) for ln in lanes]
    # the porters' rest beside the south road, its front to the road, its floor at the road's level
    sv, k = 0.0, 1
    while k < len(road) - 1 and sv + math.hypot(road[k][0] - road[k - 1][0], road[k][1] - road[k - 1][1]) < REST_S:
        sv += math.hypot(road[k][0] - road[k - 1][0], road[k][1] - road[k - 1][1])
        k += 1
    (ax, ay, az), (bx, by, bz) = road[k - 1], road[k]
    seg = math.hypot(bx - ax, by - ay)
    t = (REST_S - sv) / seg
    dx, dy = (bx - ax) / seg, (by - ay) / seg
    sx_, sy_ = -dy, dx  # its uphill side: south of the westward road
    off = WIDTH / 2 + REST[1] / 2 + 0.3
    rest = {"at": [round(ax + dx * seg * t + sx_ * off, 2), round(ay + dy * seg * t + sy_ * off, 2)], "level": round(az + (bz - az) * t, 2),
            "facing": round(math.degrees(math.atan2(-sx_, -sy_)) % 360.0, 1)}
    chorten = {"at": [round(a0[0] + axis[0] * (DECK_PAST + CHORTEN_W / 2), 2), round(a0[1] + axis[1] * (DECK_PAST + CHORTEN_W / 2), 2)],
               "level": ZAMPA_Z, "facing": round(math.degrees(math.atan2(axis[0], axis[1])) % 360.0, 1)}
    zampa = {"at": [ZAMPA[0], ZAMPA[1], ZAMPA_Z], "span": SPAN, "south": [round(ZAMPA[0] + nx * SPAN / 2, 2), round(ZAMPA[1] + ny * SPAN / 2, 2)],
             "north": [round(ZAMPA[0] - nx * SPAN / 2, 2), round(ZAMPA[1] - ny * SPAN / 2, 2)], "water": round(pts[i0][2], 2),
             "facing": round(math.degrees(math.atan2(-nx, -ny)) % 360.0, 1)}
    places = {"SER-04": {"at": [ZAMPA[0], ZAMPA[1]], "level": ZAMPA_Z, "facing": zampa["facing"]}, "SER-04C": chorten}
    # the mani wall's line down the widened road's middle
    wall = []
    k = 0
    while m0 + 1.0 + k * 0.5 <= m1 - 1.0:
        q, _ = at_length(road, m0 + 1.0 + k * 0.5)
        wall.append([round(q[0], 2), round(q[1], 2), round(q[2], 2)])
        k += 1
    # the cairn beside the road on its uphill side, and the funeral path from it up the slope (south, then east up the
    # side ravine)
    cq, (cdx, cdy) = at_length(road, length_at(road, *CAIRN_AT))
    up = (-cdy, cdx)  # the road's uphill side, going down it (south)
    cairn = [cq[0] + up[0] * (WIDTH / 2 + 1.2), cq[1] + up[1] * (WIDTH / 2 + 1.2)]
    places["SER-14"] = {"at": [round(cairn[0], 2), round(cairn[1], 2)], "level": round(cq[2], 2),
                        "facing": round(math.degrees(math.atan2(-up[0], -up[1])) % 360.0, 1)}
    durtro = [cairn]
    for k, (fwd, side) in enumerate(((6.0, 4.0), (14.0, 9.0), (22.0, 18.0), (32.0, 24.0), (44.0, 33.0), (58.0, 40.0))):
        durtro.append([cairn[0] + up[0] * fwd + cdx * -side, cairn[1] + up[1] * fwd + cdy * -side])  # up, and upstream (east)
    # the gold washings on the flat bank between the road and the water: the huts back from the water, the troughs at its
    # edge, a path down to them from the road
    iw = nearest(pts, *WASH_AT)
    wx, wy = pts[iw][0], pts[iw][1]
    a_, b_ = pts[max(iw - 1, 0)], pts[min(iw + 1, len(pts) - 1)]
    ux, uy = b_[0] - a_[0], b_[1] - a_[1]
    Lw = math.hypot(ux, uy)
    ux, uy = ux / Lw, uy / Lw  # downstream
    sx_, sy_ = -uy, ux  # south, from the water towards the road
    wet = float(pts[iw][3]) if len(pts[iw]) > 3 else 7.5  # the water's edge on this bank (left of downstream: rivers.py)
    things = []
    for k, (al, back, turn) in enumerate(HUTS):
        off = wet + back
        x, y = wx + ux * al + sx_ * off, wy + uy * al + sy_ * off
        things.append({"id": "SER-12.%d" % (k + 1), "kit": "ser12_hut_v1", "at": [round(x, 2), round(y, 2)], "level": round(float(g.z(x, y)) - site.shift, 2),
                       "facing": round((math.degrees(math.atan2(-sx_, -sy_)) + turn - 90.0) % 360.0, 1)})
    for k, (al, edge) in enumerate(TROUGHS):
        off = wet + edge
        x, y = wx + ux * al + sx_ * off, wy + uy * al + sy_ * off
        things.append({"id": "SER-12.t%d" % (k + 1), "kit": "ser12_trough_v1", "at": [round(x, 2), round(y, 2)], "level": round(float(g.z(x, y)) - site.shift, 2),
                       "facing": round(math.degrees(math.atan2(-sx_, -sy_)) % 360.0, 1)})  # (its low end to the water)
    # the way walked down the road: on its line, but past the mani wall by its south side (going down, the wall on the
    # right), WALK_OFF off the line along the widened stretch
    walk, sv = [], 0.0
    for k, q in enumerate(road):
        if k:
            sv += math.hypot(q[0] - road[k - 1][0], q[1] - road[k - 1][1])
        if m0 - 3.5 < sv < m1 + 3.5:
            continue
        walk.append([q[0], q[1], q[2], False])
        if m0 - 3.5 >= sv and k + 1 < len(road) and sv + math.hypot(road[k + 1][0] - q[0], road[k + 1][1] - q[1]) > m0 - 3.5:
            t = m0 - 1.0
            while t <= m1 + 1.0:  # the way beside the wall, every 5 m
                (px, py, pz), (ddx, ddy) = at_length(road, t)
                walk.append([px - ddy * WALK_OFF, py + ddx * WALK_OFF, pz, True])  # (-ddy, ddx): left going down, south
                t += 5.0
    walk = [w_[:3] for w_ in walk]
    # and the way walked up it (M2 sprint 12, step 6): past the mani wall by its north side, so going up it is on the right
    walk_up, sv = [], 0.0
    for k, q in enumerate(road):
        if k:
            sv += math.hypot(q[0] - road[k - 1][0], q[1] - road[k - 1][1])
        if m0 - 3.5 < sv < m1 + 3.5:
            continue
        walk_up.append([q[0], q[1], q[2]])
        if m0 - 3.5 >= sv and k + 1 < len(road) and sv + math.hypot(road[k + 1][0] - q[0], road[k + 1][1] - q[1]) > m0 - 3.5:
            t = m0 - 1.0
            while t <= m1 + 1.0:
                (px, py, pz), (ddx, ddy) = at_length(road, t)
                walk_up.append([px + ddy * WALK_OFF, py - ddx * WALK_OFF, pz])  # (ddy, -ddx): right going down, north
                t += 5.0
    walk_up.reverse()
    # the gold washers' places at work (step 6): crouched at the water's edge on the bars either side of the troughs,
    # facing the water
    washers = []
    for al in WASH_SPOTS:
        k_ = nearest(pts, wx + ux * al, wy + uy * al)
        q_ = pts[k_]
        a2, b2 = pts[max(k_ - 1, 0)], pts[min(k_ + 1, len(pts) - 1)]
        vx, vy = b2[0] - a2[0], b2[1] - a2[1]
        Lv = math.hypot(vx, vy)
        vx, vy = vx / Lv, vy / Lv
        sx2, sy2 = -vy, vx  # south, from the water to the bank
        wet2 = float(q_[3]) if len(q_) > 3 else 7.5
        x, y = q_[0] + sx2 * (wet2 + 0.55), q_[1] + sy2 * (wet2 + 0.55)
        washers.append([round(x, 2), round(y, 2), round(float(g.z(x, y)) - site.shift, 2), round(math.degrees(math.atan2(-sx2, -sy2)) % 360.0, 1)])
    above = at_length(road, length_at(road, wx + sx_ * 30.0, wy + sy_ * 30.0))[0]
    wash_path = [[above[0], above[1]], [wx + ux * 14.0 + sx_ * 20.0, wy + uy * 14.0 + sy_ * 20.0], [wx + ux * 5.0 + sx_ * 13.0, wy + uy * 5.0 + sy_ * 13.0],
                 [wx + sx_ * (wet + 1.0), wy + sy_ * (wet + 1.0)]]
    grade = (ZAMPA_Z - SER20_Z) / length
    out = {"about": "R-01's last kilometre (tools/terrain/serchu_road.py; M2 sprint 12, step 1): from the Serchu Zampa's south abutment down the river's south bank to SER-20, the cliff gallery's east end; `lanes` road lanes for tools/terrain/pads.py (its bed cut into the slope, walled by tools/town/walls.py); `path` the way walked [x, y, z] from the Zampa to the gallery for the game and the caravan (past the mani wall by its south side), `path_up` the way walked from the gallery up to the Zampa (by its north side), `line` the road's own middle; `washers` the gold washers' places at the water's edge [x, y, z, facing] (step 6); `zampa` the bridge over the Serchu (its middle, span, abutments, the water under it, `facing` the bearing from its south end to its north); `north_path` R-01 on the north bank from the Zampa's north face through its gateway chorten and upstream (step 2); `places` where world/town.gd stands the Zampa SER-04, its gateway chorten (SER-04C) and the durtro path's cairn SER-14, `pads` the porters' rest SER-19 (pads.py cuts it at the road's level); `things` the gold washings' huts and troughs (SER-12) on the bank; `mani_wall` the road mani wall SER-15's line down the middle of the road widened round it (tools/town/mani.py sets its segments); `paths` the durtro path up from the cairn and the path down to the washings, painted trodden by tools/terrain/control.py (step 3). Regenerated with the terrain.",
           "length": round(length + math.hypot(GALLERY[0] - SER20[0], GALLERY[1] - SER20[1]), 1), "grade": round(grade, 4), "width": WIDTH, "zampa": zampa,
           "path": [[round(p_[0], 2), round(p_[1], 2), round(p_[2], 2)] for p_ in walk],
           "path_up": [[round(p_[0], 2), round(p_[1], 2), round(p_[2], 2)] for p_ in walk_up], "washers": washers,
           "line": [[round(p_[0], 2), round(p_[1], 2), round(p_[2], 2)] for p_ in road],
           "north_path": [[round(p_[0], 2), round(p_[1], 2), round(p_[2], 2)] for p_ in north], "lanes": lanes,
           "places": places, "pads": {"SER-19": rest}, "things": things,
           "mani_wall": {"id": "SER-15", "line": wall, "width": MANI_W},
           "paths": [[[round(q[0], 2), round(q[1], 2)] for q in durtro], [[round(q[0], 2), round(q[1], 2)] for q in wash_path]]}
    json.dump(out, open(OUT, "w", encoding="utf-8"), indent=1)
    rep = ["# The Serchu road's last kilometre (R-01 from SER-04 to SER-20)", "",
           "_Written by `tools/terrain/serchu_road.py` (M2 sprint 12, step 1; plan chapter 02, D09) from the ground before the pads (`valley_shaped_1m`) and the Serchu's line (`data/rivers.json`): the road from the Serchu Zampa's south abutment down the south bank to the cliff gallery's east end, its bed falling evenly, cut into the slope; carved by `tools/terrain/pads.py`, walled by `tools/town/walls.py`._", "",
           "%.0f m from the Zampa (%.0f m, %.1f m over the water) to SER-20 (%.0f m) at %.1f%%, %d lanes; its line %.0f-%.0f m south of the water's." % (
               length, ZAMPA_Z, ZAMPA_Z - pts[i0][2], SER20_Z, 100 * grade, len(lanes), float(np.min(D)), float(np.max(D))), "",
           "| Lane | From | Length | Level | Cut | Fill |", "|---|---|---|---|---|---|"]
    for ln, (c, f) in zip(lanes, cf):
        rep.append("| %s | %+.0f, %+.0f | %.0f m | %.1f-%.1f | %.1f m | %.1f m |" % (ln["id"], ln["from"][0], ln["from"][1], ln["length"] - 1.0, ln["z_a"], ln["z_b"], c, f))
    rep += ["", "The bed's most cut %.1f m (%s), most fill %.1f m (%s; the Zampa's approach is on fill to its abutment)." % (
        max(c for c, _ in cf), lanes[int(np.argmax([c for c, _ in cf]))]["id"], max(f for _, f in cf), lanes[int(np.argmax([f for _, f in cf]))]["id"]), ""]
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep))
    print("serchu_road: %.0f m at %.1f%%, %d lanes, cut up to %.1f m, fill up to %.1f m -> %s" % (
        length, 100 * grade, len(lanes), max(c for c, _ in cf), max(f for _, f in cf), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
