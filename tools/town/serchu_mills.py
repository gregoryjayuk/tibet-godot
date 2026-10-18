#!/usr/bin/env python3
"""The north bank across the Serchu at the mills (M2 sprint 12, step 5; plan chapter 02, D09: SER-05 to SER-11, SER-17,
SER-18; 6.1's Serchu leat; R-09): the leat SER-10, its four mills and two water prayer wheels, the mills' log footbridge
over the river and the paths to it, the monastery's barley terraces above, and the Yak Road's first legs up the spur.

The leat. Chapter 02's table: from its intake at (+600, -262), the river at 2,714 m, to the last wheel at (+420, -195),
200 m at 1%; "a leat on a 13% torrent gains head fast: by the mills it runs 8-15 m above the river, so it steps down
beside the mill row and each mill takes 3-4 m of head through its own chute". On the real ground (the shaped raster,
before the pads) the Serchu falls 20 m over those 200 m, the north bank a gravel terrace one to three metres over the
water and then the spur's flank at 25-30 degrees. So the leat is a cascade: it leaves the river at the intake and keeps
along the slope where the ground stands LEAT_RIM over its water (its channel cut into the slope, its outer bank built),
falling 1%; its first wheel house SER-09.2 straddles it and takes WHEEL_DROP; the first mill SER-08's chute takes its
water 3.2 m down to the horizontal wheel under its floor (FLOOR_UNDER, TAIL_UNDER), and its tail race, out of the arch
in its front, is the next stretch of the leat, and so on down the row to the last wheel house SER-09.1, whose race runs
down the bank into the river above the Golden Slot. Each stretch is traced metre by metre along the slope from the last
element's outflow until it reaches the next one's place (chapter 02's x), then eased. A mill stands below its chute's
head, downstream of it, its front to the river, where the ground at its back wall is its floor's level; a tail yard
before its arch is cut to the tail race's floor. The leat's shelf (its channel and the leat walk beside it, SHELF wide)
and the tail yards are road lanes for tools/terrain/pads.py; ../tibet-blender/export_serchu.py builds the channel, the
chutes and the race from `leat`, `chutes` and `race`; world/mills.gd runs the water in them and turns the wheels.

The footbridge SER-11 (chapter 02: two logs, a 12 m span, 3 m over the water, 0.8 m wide; "Yak Road foot to the south
bank"): where along the mills' reach both banks lie low beside a narrow water (above the reach, the slot's head, its
south bank a 7 m wall), its deck DECK_OVER over the water on a stone crib at each end with steps up to it. From its
south end a path zigzags up the bank to R-01 (data/serchu_road.json); from its north end the Yak Road R-09 climbs the
spur, LEGS legs at 12% (chapter 02: 2.1 km and 11 switchbacks to the East Gate MON-19; its first legs here, the rest with
the monastery), crossing the leat where it must in a culvert. Paths painted trodden from the footbridge to the mills'
doors and along the leat walk.

The barley terraces SER-17 (chapter 02: the spur's south flank, 12 ha, stubble in October): the flank above the leat,
x FIELDS_X, up to FIELDS_TOP, where a bench will hold (under 38 degrees), painted barley by tools/terrain/control.py (the
terrain shader draws the benches); hay piled on a few. And the river's bed by the mills cut down where it stood over the
water (`channel`: the Serchu ran dry there for 20 m).
Run: tools/py tools/town/serchu_mills.py   Writes data/serchu_mills.json and docs/town/serchu-mills-report.md
(tools/terrain/build.sh runs it after tools/terrain/serchu_road.py, before pads.py).
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

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
SOURCE = os.path.join(GEN, "valley_shaped_1m.tif")  # the ground before the pads (pads.py's SOURCE)
RIVERS = os.path.join(ROOT, "data", "rivers_seed.json")  # the rivers' line as M2 sprint 12 closed with it, pinned: the last
# build's data/rivers.json is fitted to ground these planners' own lanes cut, and drifted a step each build until they failed
# (ISS-182); refit it after the ground is reshaped (copy data/rivers.json over it and rerun the build)
ROAD = os.path.join(ROOT, "data", "serchu_road.json")
OUT = os.path.join(ROOT, "data", "serchu_mills.json")
REPORT = os.path.join(ROOT, "docs", "town", "serchu-mills-report.md")
SEED = 1905  # the north bank's own

# the leat
INTAKE = (600.0, -262.0)  # chapter 02's: at the river's north edge
GRADE = 0.01
LEAT_RIM = 0.25  # its line where the ground stands this over its water
DEPTH = 0.35  # its water over its channel's floor
SHELF_UNDER = 0.45  # the shelf (and the tail yards) this under the water: the channel's floor stands on it, a little over it
SHELF = 2.8  # the shelf's width: the channel (1.3 m with its banks) on its downhill side, the leat walk uphill
SHELF_OFF = 0.6  # the shelf's middle this far uphill of the channel's
TURN = 35.0  # degrees a metre's step of the trace may turn from the last
AHEAD = 3.0  # metres ahead along each way it might turn the trace looks for the ground at its level
SHY = 16.0  # a road's trace keeps this far from the river's water where it can (`shy` the weight a metre)
RIVER_CLEAR = 2.0  # metres the leat keeps from the river's wet edge, on its north bank
WET_MIN = 4.0  # the river's half-width at the least, where it runs dry (data/rivers.json from the build before)
EASE = 7  # points (a metre apart) in the trace's moving average
TOL = 0.6  # a shelf lane keeps within this of the eased line
# the cascade, downstream: (id, kind, chapter 02's x of its middle)
CASCADE = (("SER-09.2", "wheel", 575.0), ("SER-08", "mill", 545.0), ("SER-07", "mill", 515.0), ("SER-06", "mill", 480.0),
           ("SER-05", "mill", 450.0), ("SER-09.1", "wheel", 420.0))
# a mill (../tibet-blender kit/serchu.py water_mill, 4 x 4 m): its floor FLOOR_UNDER under the chute head's water, its tail
# race's water TAIL_UNDER under its floor; the chute's foot (the kit's JET socket) in its upstream wall low down, local
# (+2.0, +0.3, -0.6) (x upstream, y to its back, z up from its floor); its arch's sill local (0, -2.1), the tail race on
# from there; a wheel house (water_wheel_house, 2.5 x 2.5) straddles the leat, its water falling WHEEL_DROP inside it
FLOOR_UNDER = 1.8
TAIL_UNDER = 1.35
JET = (2.0, 0.3, -0.6)
DOOR = (-2.0, 0.6)  # its door in its downstream wall (local x, y), its sill at its floor's level, a step or two up to it
ARCH = 2.1
HALF = 2.0  # a mill's half depth (its walls' outer faces)
TRESTLE = 1.4  # a chute's trestles this far apart
WHEEL_HALF = 1.25
WHEEL_DROP = 0.9
TAIL_YARD = (3.0, 5.6)  # the tail yard's width and length, from 0.6 m behind a mill's middle out past its front
# the footbridge
DECK_OVER = 2.6  # its deck over the water
SPAN = 12.0
CRIB = 1.2  # each crib's depth along the bridge
STEP_RISE, STEP_RUN = 0.24, 0.3  # the steps up a crib
BRIDGE_X = (528.5, 531.5)  # the reach searched: the narrows between SER-07 and SER-08 that a search of x 440-545 found
# (10 Oct 2026); held there, since the river's line and widths (data/rivers.json, the last build's) move a little each build
# the paths and the Yak Road
PATH_W, PATH_GRADE = 1.6, 0.25
RAMP_GRADE = 0.28  # the path's last lane, along the road's edge up onto it, no steeper
ROAD_W, ROAD_GRADE = 4.0, 0.12
CUT_IN = 0.45  # a path's or the road's line where the ground stands this over its bed
WALL_MIN = (1.2, 0.8)  # as the Serchu road's (tools/terrain/serchu_road.py)
SEP = (PATH_W + 1.5, ROAD_W + 2.0)  # a switchback: the next leg starts this far up the slope from the last one's end, level with it
LEGS = (("east", 0.0), ("west", 125.0), ("east", 125.0))  # the Yak Road's first legs here: their ways and lengths (the first's
# as far as it must go to cross the leat)
LEG1_MAX = 0.22  # the first leg's steepest, from the footbridge up between two mills to the leat
LEG1_HEAD = math.pi / 2  # its way at first: north, up the bank (east along the river it must climb as the river does, 15%)
SLAB = 0.45  # the road over the leat on slabs: its bed this over the water
BUMP = 12.0  # metres each way over which the road rises to its slabs
PATH_LEGS = (("east", 26.0), ("west", 40.0), ("east", 40.0))  # the path up the south bank, as far as it needs
# the barley terraces
FIELDS_X = (410.0, 720.0)
FIELDS_TOP = 2880.0
FIELDS_BOTTOM = 2716.0  # (east of the intake, where the leat's line gives no edge, the bank's top)
FIELDS_SLOPE = 38.0
HAY = 12


def river():
    r = json.load(open(RIVERS, encoding="utf-8"))
    return next(x for x in r["rivers"] if x["name"] == "Serchu")["pts"]


def frame(pts, k):
    """The river at point k: its water, its downstream direction, its north normal (right of downstream), wet widths."""
    a, b = pts[max(k - 1, 0)], pts[min(k + 1, len(pts) - 1)]
    ux, uy = b[0] - a[0], b[1] - a[1]
    L = math.hypot(ux, uy)
    ux, uy = ux / L, uy / L
    return pts[k], (ux, uy), (uy, -ux)


def river_dist(pts, x, y, bank=None):
    """Metres from (x, y) to the river's wet water (its line less the wet half-width on that side, never less than
    WET_MIN: where the river ran dry over its bed's hump; 0 inside it); with `bank` ("north" or "south"), 0 too on the
    other side."""
    best, side_at = 1e9, 0.0
    for k in range(len(pts) - 1):
        a, b = pts[k], pts[k + 1]
        if abs(a[0] - x) > 60.0 or abs(a[1] - y) > 60.0:
            continue
        dx, dy = b[0] - a[0], b[1] - a[1]
        L2 = dx * dx + dy * dy
        t = max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / L2))
        px, py = a[0] + dx * t, a[1] + dy * t
        d = math.hypot(x - px, y - py)
        side = (x - a[0]) * dy - (y - a[1]) * dx  # > 0 right of downstream: the north
        w = max((a[4] if side > 0 else a[3]) if len(a) > 4 else WET_MIN, WET_MIN)
        if max(0.0, d - w) < best:
            best, side_at = max(0.0, d - w), side
    if (bank == "north" and side_at <= 0.0) or (bank == "south" and side_at > 0.0):
        return 0.0
    return best


def ease(pts, k=EASE):
    """A polyline's plan eased by a moving average (its ends kept), every point a metre apart again."""
    P = np.array([p[:2] for p in pts], float)
    if len(P) > k:
        Q = P.copy()
        h = k // 2
        for i in range(1, len(P) - 1):
            a, b = max(0, i - h), min(len(P), i + h + 1)
            Q[i] = P[a:b].mean(axis=0)
        P = Q
    s = np.r_[0.0, np.cumsum(np.hypot(*np.diff(P, axis=0).T))]
    n = max(2, int(s[-1]) + 1)
    t = np.linspace(0.0, s[-1], n)
    return np.c_[np.interp(t, s, P[:, 0]), np.interp(t, s, P[:, 1])], t


def trace(Z, pts_r, p0, z0, head, stop, grade, rim, avoid=None, steps=2000, bank="north", shy=0.0):
    """A line along the slope from p0 (its level z0 there), a metre a step, its level changing `grade` a metre (falling
    when negative), each step turned within TURN of the last to where the ground stands `rim` over its level, kept
    RIVER_CLEAR from the river and out of `avoid` (a function of x, y: True where it may not go); until stop(x, y, z) or
    `steps` steps."""
    x, y, z, h = p0[0], p0[1], z0, head
    out = [(x, y, z)]
    for _ in range(steps):
        if stop is not None and stop(x, y, z):
            break
        z += grade
        best = None
        for dh in np.radians(np.arange(-TURN, TURN + 0.1, 2.5)):
            a = h + dh
            qx, qy = x + math.cos(a), y + math.sin(a)
            e = float(Z(x + AHEAD * math.cos(a), y + AHEAD * math.sin(a))) - (z + grade * (AHEAD - 1.0) + rim)  # (looking ahead)
            c = abs(e) + 0.003 * abs(math.degrees(dh))
            rd = river_dist(pts_r, qx, qy, bank)
            if rd < RIVER_CLEAR:  # out of the river, and away from it while too near
                c += 20.0 + 10.0 * (RIVER_CLEAR - rd)
            c += shy * max(0.0, SHY - rd)  # (a road: off the river's raised bed, over the hollow behind it to the slope's foot)
            if avoid is not None and avoid(qx, qy):
                c += 50.0
            if best is None or c < best[0]:
                best = (c, a, qx, qy)
        _, h, x, y = best
        out.append((x, y, z))
    return out


def simplify(P, tol, zk=8.0):
    """Douglas-Peucker on the plan and the level (a metre of level counting `zk` metres): the kept indices."""
    P = np.asarray(P, float)[:, :3] * np.array([1.0, 1.0, zk])
    keep = {0, len(P) - 1}

    def rec(a, b):
        if b <= a + 1:
            return
        ab = P[b] - P[a]
        L = np.linalg.norm(ab)
        v = P[a + 1:b] - P[a]
        d = np.linalg.norm(np.cross(v, ab[None, :]), axis=1) / max(L, 1e-9)
        m = int(np.argmax(d))
        if d[m] > tol:
            keep.add(a + 1 + m)
            rec(a, a + 1 + m)
            rec(a + 1 + m, b)
    rec(0, len(P) - 1)
    return sorted(keep)


def lanes_along(lid, line, width, bed_under, off=0.0, tol=TOL, **kw):
    """Road lanes for pads.py along a line [x, y, z] (its level falling or rising evenly between its kept points): each
    stretch's bed `bed_under` under the line's level, its middle `off` to the left of the line (looking along it), a metre
    on past its end at its end's level, so no wedge of the slope is left where it meets the next."""
    keep = simplify(line, tol)
    out = []
    for n, (i, j) in enumerate(zip(keep[:-1], keep[1:])):
        a, b = line[i], line[j]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        if L < 0.3:
            continue
        ux, uy = dx / L, dy / L
        fx, fy = a[0] - uy * off, a[1] + ux * off
        za, zb = a[2] - bed_under, b[2] - bed_under
        ln = {"id": "%s.%d" % (lid, n + 1), "from": [round(fx, 2), round(fy, 2)], "dir": [round(ux, 5), round(uy, 5)], "length": round(L + 1.0, 2),
              "width": width, "z_a": round(za, 2), "z_b": round(zb, 2), "flight": None,
              "profile": [[0.0, round(za, 2)], [round(L, 2), round(zb, 2)], [round(L + 1.0, 2), round(zb, 2)]], "road": True, "wall_min": list(WALL_MIN)}
        ln.update(kw)
        out.append(ln)
    return out


def bearing(dx, dy):
    return math.degrees(math.atan2(dx, dy)) % 360.0


def place_mill(Z, H, zH, d):
    """A mill below its chute's head H (its water zH there), the leat's direction d there: its middle, its facing, its
    floor, the chute's foot and its tail race's start. Searched over the chute's runs along and down the slope for the
    place whose back wall stands on ground at its floor's level, its front no higher than its arch's sill, the chute
    falling at 25-50 degrees."""
    rx = (-d[0], -d[1])  # its local +x: upstream
    fwd = (-d[1], d[0])  # its front: left of downstream, the river's side
    zf = zH - FLOOR_UNDER
    best = None
    for A in np.arange(2.5, 5.51, 0.25):
        for B in np.arange(0.5, 7.01, 0.25):
            C = (H[0] - A * rx[0] + B * fwd[0], H[1] - A * rx[1] + B * fwd[1])
            back = float(Z(C[0] - HALF * fwd[0], C[1] - HALF * fwd[1]))
            front = float(Z(C[0] + HALF * fwd[0], C[1] + HALF * fwd[1]))
            jet = (C[0] + JET[0] * rx[0] - JET[1] * fwd[0], C[1] + JET[0] * rx[1] - JET[1] * fwd[1])
            run = math.hypot(H[0] - jet[0], H[1] - jet[1])
            ang = math.degrees(math.atan2(FLOOR_UNDER - JET[2], run))
            c = (back - zf) ** 2 + 0.5 * max(0.0, front - (zf - TAIL_UNDER)) ** 2 + 0.2 * (max(0.0, 25.0 - ang) + max(0.0, ang - 50.0)) ** 2
            if best is None or c < best[0]:
                best = (c, C, jet, back, front, ang, run)
    _, C, jet, back, front, ang, run = best
    facing = bearing(*fwd)
    arch = (C[0] + ARCH * fwd[0], C[1] + ARCH * fwd[1])
    return {"at": [round(C[0], 2), round(C[1], 2)], "level": round(zf, 2), "facing": round(facing, 1),
            "jet": [round(jet[0], 2), round(jet[1], 2), round(zf + JET[2], 2)], "arch": [round(arch[0], 2), round(arch[1], 2), round(zf - TAIL_UNDER, 2)],
            "back": round(back - zf, 2), "front": round(front - zf, 2), "chute": round(ang, 1), "run": round(run, 2)}


def leat_plan(Z, pts_r):
    """The cascade: its stretches [{id, pts [x, y, water z]}], its mills and wheel houses, the chutes, the race to the river."""
    k0 = min(range(len(pts_r)), key=lambda k: math.hypot(pts_r[k][0] - INTAKE[0], pts_r[k][1] - INTAKE[1]))
    q, dn, nn = frame(pts_r, k0)
    wet_n = q[4] if len(q) > 4 else 4.0
    p = (q[0] + nn[0] * wet_n, q[1] + nn[1] * wet_n)  # the intake on the north edge
    z = q[2]
    head = math.atan2(dn[1], dn[0])
    stretches, mills, wheels, chutes = [], [], [], []
    taken = []  # the houses' footprints so far: no stretch through them

    def avoid(x, y):
        return any(abs((x - c[0]) * f[0] + (y - c[1]) * f[1]) < h + 1.0 and abs((x - c[0]) * f[1] - (y - c[1]) * f[0]) < h + 1.0 for c, f, h in taken)

    for n, (eid, kind, X) in enumerate(CASCADE):
        x_end = X + (WHEEL_HALF if kind == "wheel" else 4.0)
        line = trace(Z, pts_r, p, z, head, lambda x, y, zz: x <= x_end, -GRADE, LEAT_RIM, avoid)
        P, s = ease(line)
        zs = z - GRADE * s
        pts = [[float(a), float(b), float(c)] for (a, b), c in zip(P, zs)]
        if n == 0:
            pts = [[float(q[0]), float(q[1]), float(q[2])]] + pts  # from the water's middle: the intake's weir
            weir = {"from": [round(p[0], 2), round(p[1], 2), round(z, 2)],  # from its north edge out across the water, angled upstream
                    "to": [round(q[0] - nn[0] * 1.5 - dn[0] * 4.0, 2), round(q[1] - nn[1] * 1.5 - dn[1] * 4.0, 2), round(z, 2)]}
        sid = "SER-10.%d" % (n + 1)
        stretches.append({"id": sid, "pts": pts})
        e = pts[-1]
        dx, dy = e[0] - pts[-4][0], e[1] - pts[-4][1]
        L = math.hypot(dx, dy)
        d = (dx / L, dy / L)
        if kind == "wheel":
            C = (e[0] + WHEEL_HALF * d[0], e[1] + WHEEL_HALF * d[1])
            fwd = (-d[1], d[0])
            out = (C[0] + WHEEL_HALF * d[0], C[1] + WHEEL_HALF * d[1])
            wheels.append({"id": eid, "at": [round(C[0], 2), round(C[1], 2)], "level": round(e[2], 2), "facing": round(bearing(*fwd), 1),
                           "in": [round(e[0], 2), round(e[1], 2), round(e[2], 2)], "out": [round(out[0], 2), round(out[1], 2), round(e[2] - WHEEL_DROP, 2)]})
            taken.append((C, fwd, WHEEL_HALF))
            p, z, head = out, e[2] - WHEEL_DROP, math.atan2(d[1], d[0])
            if n == len(CASCADE) - 1:  # the race: down the fall line to the river
                race = [[out[0], out[1], z]]
                x, y = out
                for _ in range(80):
                    gx = (float(Z(x + 1.0, y)) - float(Z(x - 1.0, y))) / 2.0
                    gy = (float(Z(x, y + 1.0)) - float(Z(x, y - 1.0))) / 2.0
                    g_ = math.hypot(gx, gy)
                    if g_ < 1e-3:
                        break
                    x, y = x - gx / g_, y - gy / g_
                    race.append([x, y, min(race[-1][2], float(Z(x, y)) + 0.12)])
                    if river_dist(pts_r, x, y) <= 0.0:
                        break
                stretches.append({"id": "SER-10.race", "pts": race, "race": True})
        else:
            m = place_mill(Z, (e[0], e[1]), e[2], d)
            m["id"] = eid
            m["head"] = [round(e[0], 2), round(e[1], 2), round(e[2], 2)]
            mills.append(m)
            hx, hy, hz = m["head"]
            jx, jy, jz = m["jet"]
            run = math.hypot(jx - hx, jy - hy)
            ground = []  # the ground under the chute every TRESTLE metres, for its trestles
            for k in range(1, int(run / TRESTLE) + 1):
                t = k * TRESTLE / run
                if t < 0.95:
                    gx_, gy_ = hx + (jx - hx) * t, hy + (jy - hy) * t
                    ground.append([round(gx_, 2), round(gy_, 2), round(hz + (jz - hz) * t, 2), round(float(Z(gx_, gy_)), 2)])
            chutes.append({"id": eid, "pts": [m["head"], m["jet"]], "ground": ground})
            fwd = (-d[1], d[0])
            taken.append(((m["at"][0], m["at"][1]), fwd, HALF))
            a = m["arch"]
            p = (a[0] + 0.9 * fwd[0], a[1] + 0.9 * fwd[1])  # the tail race out of the arch, turning down the leat's way
            z = a[2]
            head = math.atan2(d[1], d[0])
            stretches.append({"id": "SER-10.%dt" % (n + 1), "pts": [[a[0], a[1], z], [p[0], p[1], z]], "tail": eid})
    return stretches, mills, wheels, chutes, weir


def zigzag(Z, pts_r, p0, z0, legs, grade, sep, avoid=None, stop=None, bank="north", first_sep=False):
    """Legs along the slope from p0 (its level z0), each climbing `grade`, each its way ("east" or "west") and length,
    each next one starting `sep` up the slope from the last one's end, level with it (a switchback's landing, cut into the
    slope behind a wall); or until stop(x, y, z). Returns the legs' lines [x, y, z] and the landings [(end, start)]."""
    out, landings = [], []
    x, y, z = p0[0], p0[1], z0
    if first_sep:  # a switchback before the first leg too: it starts `sep` up the slope from p0, level with it
        gx = (float(Z(x + 1.0, y)) - float(Z(x - 1.0, y))) / 2.0
        gy = (float(Z(x, y + 1.0)) - float(Z(x, y - 1.0))) / 2.0
        g_ = max(math.hypot(gx, gy), 1e-6)
        landings.append(((x, y, z), (x + sep * gx / g_, y + sep * gy / g_, z)))
        x, y = x + sep * gx / g_, y + sep * gy / g_
    for k, (way, length) in enumerate(legs):
        head = 0.0 if way == "east" else math.pi
        line = trace(Z, pts_r, (x, y), z, head, stop, grade, CUT_IN, avoid, steps=int(length), bank=bank)
        P, s = ease(line)
        zs = z + grade * s
        pts = [[float(a), float(b), float(c)] for (a, b), c in zip(P, zs)]
        out.append(pts)
        e = pts[-1]
        if stop is not None and stop(*e):
            break
        gx = (float(Z(e[0] + 1.0, e[1])) - float(Z(e[0] - 1.0, e[1]))) / 2.0
        gy = (float(Z(e[0], e[1] + 1.0)) - float(Z(e[0], e[1] - 1.0))) / 2.0
        g_ = max(math.hypot(gx, gy), 1e-6)
        nx_, ny_ = e[0] + sep * gx / g_, e[1] + sep * gy / g_
        if avoid is not None and avoid(nx_, ny_):  # its landing would lie in the way: it ends here
            break
        landings.append(((e[0], e[1], e[2]), (nx_, ny_, e[2])))
        x, y, z = nx_, ny_, e[2]
    return out, landings


def bridge_site(Z, pts_r):
    """The footbridge's crossing: along the reach, where the water is narrow and both banks low at its span's ends; in
    BRIDGE_X, or failing that a little either side of it (the Serchu's line, read from the last build, drifts: ISS-182)."""
    for grow in (0.0, 6.0, 15.0):
        found = _bridge_site(Z, pts_r, (BRIDGE_X[0] - grow, BRIDGE_X[1] + grow))
        if found is not None:
            if grow:
                print("serchu_mills: WARNING: the footbridge found no crossing in x %s; it crosses at x %.1f" % (BRIDGE_X, found["at"][0]))
            return found
    raise SystemExit("serchu_mills: no crossing for the footbridge within 15 m of x %s" % (BRIDGE_X,))


def _bridge_site(Z, pts_r, xs):
    best = None
    for k, q in enumerate(pts_r):
        if not (xs[0] <= q[0] <= xs[1]) or len(q) < 6 or int(q[5]) < 1:
            continue
        _, dn, nn = frame(pts_r, k)
        a, b = q[4] + 1.2, q[3] + 1.2  # north and south ends from the water's middle
        span = a + b
        if span > SPAN + 1.0:
            continue
        c = (b - a) / 2.0  # the span centred over the water
        a = b = SPAN / 2.0
        mid = (q[0] - nn[0] * c, q[1] - nn[1] * c)
        deck = q[2] + DECK_OVER
        north = (mid[0] + nn[0] * a, mid[1] + nn[1] * a)
        south = (mid[0] - nn[0] * b, mid[1] - nn[1] * b)
        hn, hs = deck - float(Z(*north)), deck - float(Z(*south))
        if not (-0.6 <= hn <= 3.4 and -0.6 <= hs <= 3.4):
            continue
        score = abs(hn) + abs(hs) + 0.01 * abs(q[0] - 470.0)
        if best is None or score < best[0]:
            best = (score, mid, nn, deck, north, south, hn, hs, q)
    if best is None:
        return None
    _, mid, nn, deck, north, south, hn, hs, q = best
    return {"id": "SER-11", "at": [round(mid[0], 2), round(mid[1], 2)], "deck": round(deck, 2), "span": SPAN, "water": round(q[2], 2),
            "facing": round(bearing(nn[0], nn[1]), 1), "north": [round(north[0], 2), round(north[1], 2), round(hn, 2)],
            "south": [round(south[0], 2), round(south[1], 2), round(hs, 2)]}


def foot_of(br, end):
    """Where the steps down from a crib meet the ground: past the crib, along the bridge's axis outwards."""
    sgn = 1.0 if end == "north" else -1.0
    th = math.radians(br["facing"])
    ax, ay = math.sin(th) * sgn, math.cos(th) * sgn
    h = max(0.0, br[end][2])
    run = CRIB + (math.ceil(h / STEP_RISE) * STEP_RUN if h > 0.3 else 0.0)
    e = br[end]
    return (e[0] + ax * (run + 0.6), e[1] + ay * (run + 0.6)), br["deck"] - h, (ax, ay)


def cut_fill(Z, ln):
    L = ln["length"] - 1.0
    (fx, fy), (ux, uy) = ln["from"], ln["dir"]
    t = np.linspace(0.0, L, max(2, int(L / 1.0)))
    out = []
    for side in (-ln["width"] / 2, 0.0, ln["width"] / 2):
        z = np.interp(t, [p[0] for p in ln["profile"]], [p[1] for p in ln["profile"]])
        gz = Z(fx + ux * t - uy * side, fy + uy * t + ux * side)
        out.append(gz - z)
    d = np.concatenate(out)
    return float(max(d.max(), 0.0)), float(max(-d.min(), 0.0))


def crossings(legs, stretches):
    """Where the legs' lines cross the leat's stretches: {at, road (its level there), water, dir (the road's), leat}."""
    out = []
    for leg in legs:
        for a, b in zip(leg[:-1], leg[1:]):
            for st in stretches:
                for c, d_ in zip(st["pts"][:-1], st["pts"][1:]):
                    den = (b[0] - a[0]) * (d_[1] - c[1]) - (b[1] - a[1]) * (d_[0] - c[0])
                    if abs(den) < 1e-9:
                        continue
                    t = ((c[0] - a[0]) * (d_[1] - c[1]) - (c[1] - a[1]) * (d_[0] - c[0])) / den
                    u = ((c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0])) / den
                    if 0.0 <= t <= 1.0 and 0.0 <= u <= 1.0:
                        Lc = math.hypot(d_[0] - c[0], d_[1] - c[1])
                        out.append({"at": [round(a[0] + (b[0] - a[0]) * t, 2), round(a[1] + (b[1] - a[1]) * t, 2)], "road": round(a[2] + (b[2] - a[2]) * t, 2),
                                    "water": round(c[2] + (d_[2] - c[2]) * u, 2), "dir": [round(b[0] - a[0], 3), round(b[1] - a[1], 3)], "leat": st["id"],
                                    "leat_dir": [round((d_[0] - c[0]) / Lc, 4), round((d_[1] - c[1]) / Lc, 4)], "width": ROAD_W})
    return out


def main():
    site = Site.load()
    g = site.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site.shift
    pts_r = river()
    road = json.load(open(ROAD, encoding="utf-8"))
    rnd = random.Random(SEED)

    # the river's bed by the mills cut down where it stood over the water
    channel = []
    k0 = min(range(len(pts_r)), key=lambda k: abs(pts_r[k][0] - 575.0) + abs(pts_r[k][1] + 250.0))
    k1 = min(range(len(pts_r)), key=lambda k: abs(pts_r[k][0] - 520.0) + abs(pts_r[k][1] + 238.0))
    run = []
    for k in range(k0, k1 + 1):
        q = pts_r[k]
        run.append([q[0], q[1], q[2] - 0.45])
    for n, (a, b) in enumerate(zip(run[:-1], run[1:])):
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        channel.append({"id": "SER-CH.%d" % (n + 1), "from": [round(a[0], 2), round(a[1], 2)], "dir": [round(dx / L, 5), round(dy / L, 5)],
                        "length": round(L, 2), "width": 7.0, "z_a": round(a[2], 2), "z_b": round(b[2], 2), "flight": None,
                        "profile": [[0.0, round(a[2], 2)], [round(L, 2), round(b[2], 2)]], "channel": True})

    stretches, mills, wheels, chutes, weir = leat_plan(Z, pts_r)
    lanes = []
    for st in stretches:
        if st.get("race") or st.get("tail"):
            continue
        lanes += lanes_along(st["id"], st["pts"], SHELF, SHELF_UNDER, off=-SHELF_OFF, leat=True)  # (its middle uphill: right of downstream)
    for m in mills:  # each tail yard: from 0.6 m behind its middle out past its front, at the tail race's floor
        th = math.radians(m["facing"])
        fwd = (math.sin(th), math.cos(th))
        a = (m["at"][0] - 0.6 * fwd[0], m["at"][1] - 0.6 * fwd[1])
        zb = m["arch"][2] - SHELF_UNDER
        lanes.append({"id": "%s.yard" % m["id"], "from": [round(a[0], 2), round(a[1], 2)], "dir": [round(fwd[0], 5), round(fwd[1], 5)],
                      "length": TAIL_YARD[1], "width": TAIL_YARD[0], "z_a": round(zb, 2), "z_b": round(zb, 2), "flight": None,
                      "profile": [[0.0, round(zb, 2)], [TAIL_YARD[1], round(zb, 2)]], "road": True, "wall_min": [2.0, 2.0]})
    for w in wheels:  # under each wheel house, the shelf at its outflow's floor
        a, b = w["in"], w["out"]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        zb = b[2] - SHELF_UNDER
        lanes.append({"id": "%s.bed" % w["id"], "from": [round(a[0] - dx / L, 2), round(a[1] - dy / L, 2)], "dir": [round(dx / L, 5), round(dy / L, 5)],
                      "length": round(L + 2.0, 2), "width": 3.4, "z_a": round(zb, 2), "z_b": round(zb, 2), "flight": None,
                      "profile": [[0.0, round(zb, 2)], [round(L + 2.0, 2), round(zb, 2)]], "road": True, "wall_min": list(WALL_MIN)})

    # the footbridge, the path from its south end up to the road, the Yak Road from its north end
    br = bridge_site(Z, pts_r)
    s_foot, s_z, s_ax = foot_of(br, "south")
    n_foot, n_z, n_ax = foot_of(br, "north")
    rl = road["line"]

    def road_at(x, y):
        best = (1e9, 0.0)
        for a, b in zip(rl[:-1], rl[1:]):
            dx, dy = b[0] - a[0], b[1] - a[1]
            L2 = dx * dx + dy * dy
            t = max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / L2))
            d = math.hypot(a[0] + dx * t - x, a[1] + dy * t - y)
            if d < best[0]:
                best = (d, a[2] + (b[2] - a[2]) * t)
        return best

    road_band = road["width"] / 2 + PATH_W / 2 + 0.5  # the path keeps out of the road's band until it turns up onto it

    def at_road(x, y, z):
        """Where the path's legs stop: beside the road's band (then one lane along it up onto its edge)."""
        return road_at(x, y)[0] <= road_band + 1.0

    houses = [((m["at"][0], m["at"][1]), m["facing"]) for m in mills] + [((w["at"][0], w["at"][1]), w["facing"]) for w in wheels]
    shelf_pts = [pp for st in stretches for pp in st["pts"]]

    def near_leat(x, y, r=SHELF / 2 + 1.0):
        return any(abs(pp[0] - x) < r and abs(pp[1] - y) < r and math.hypot(pp[0] - x, pp[1] - y) < r for pp in shelf_pts)

    def near_house(x, y, r=ROAD_W / 2 + 1.0):
        """Within r of a mill's or a wheel house's footprint, or of a mill's tail yard before it."""
        for (cx, cy), f in houses:
            th = math.radians(f)
            fx_, fy_ = math.sin(th), math.cos(th)
            u = (x - cx) * fy_ - (y - cy) * fx_  # across its front
            v = (x - cx) * fx_ + (y - cy) * fy_  # out from its front
            if abs(u) < HALF + r and -HALF - r < v < HALF + TAIL_YARD[1] - 2.0 + r:
                return True
        return False

    path_legs, path_landings = zigzag(Z, pts_r, s_foot, s_z, PATH_LEGS, PATH_GRADE, SEP[0], stop=at_road, bank="south",
                                      avoid=lambda x, y: road_at(x, y)[0] < road_band)
    # the last lane: from the legs' end along the road's edge, climbing no steeper than RAMP_GRADE, onto the road where it
    # meets the road's level there (along the way the road falls, it meets it soonest), then into its middle
    e = path_legs[-1][-1]
    s_r = [0.0]
    for a, b in zip(rl[:-1], rl[1:]):
        s_r.append(s_r[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))

    def road_point(sv):
        for k in range(len(rl) - 1):
            if s_r[k + 1] >= sv:
                t = (sv - s_r[k]) / max(s_r[k + 1] - s_r[k], 1e-9)
                a, b = rl[k], rl[k + 1]
                L = s_r[k + 1] - s_r[k]
                return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t), ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        return tuple(rl[-1]), (0.0, 0.0)
    s_e = min((abs(sv - 0.0), sv) for sv in [0.0])[1]
    best_s, best_d = 0.0, 1e9
    for sv in np.arange(0.0, s_r[-1], 0.5):
        (qx, qy, _), _ = road_point(sv)
        if math.hypot(qx - e[0], qy - e[1]) < best_d:
            best_s, best_d = sv, math.hypot(qx - e[0], qy - e[1])
    s_e = best_s
    side = None
    merge = None
    for L_m in np.arange(3.0, 40.0, 0.5):
        for sgn in (1.0, -1.0):
            sv = s_e + sgn * L_m
            if not (0.0 < sv < s_r[-1]):
                continue
            (qx, qy, qz), (tx, ty) = road_point(sv)
            nx_, ny_ = -ty, tx  # the road's left, going down it: north, the river's side
            if (e[0] - qx) * nx_ + (e[1] - qy) * ny_ < 0.0:
                nx_, ny_ = -nx_, -ny_  # (the side the path comes from)
            T = (qx + nx_ * road["width"] / 2, qy + ny_ * road["width"] / 2)
            run = math.hypot(T[0] - e[0], T[1] - e[1])
            if abs(qz - e[2]) <= RAMP_GRADE * run:
                merge = (T, qz, (qx, qy))
                break
        if merge:
            break
    if merge is None:
        raise SystemExit("serchu_mills: the path from the footbridge finds no way onto the road")
    T, qz, Q = merge
    path_legs.append([list(e), [T[0], T[1], qz], [Q[0], Q[1], qz]])
    path_line = [pp for leg in path_legs for pp in leg]
    for k, leg in enumerate(path_legs[:-1]):
        lanes += lanes_along("SER-11.p%d" % (k + 1), leg, PATH_W, 0.0, tol=0.25)  # (a narrow way: its lanes keep to its line)
    for lid, a, b, za, zb in (("SER-11.onto", e, T, e[2], qz), ("SER-11.road", T, Q, qz, qz)):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L < 0.2:
            continue
        lanes.append({"id": lid, "from": [round(a[0], 2), round(a[1], 2)], "dir": [round((b[0] - a[0]) / L, 5), round((b[1] - a[1]) / L, 5)],
                      "length": round(L + 0.5, 2), "width": PATH_W, "z_a": round(za, 2), "z_b": round(zb, 2), "flight": None,
                      "profile": [[0.0, round(za, 2)], [round(L, 2), round(zb, 2)], [round(L + 0.5, 2), round(zb, 2)]], "road": True,
                      "wall_min": list(WALL_MIN)})
    for k, (e, s) in enumerate(path_landings[:len(path_legs) - 1]):
        dx, dy = s[0] - e[0], s[1] - e[1]
        L = math.hypot(dx, dy)
        lanes.append({"id": "SER-11.pl%d" % (k + 1), "from": [round(e[0] - dx / L, 2), round(e[1] - dy / L, 2)], "dir": [round(dx / L, 5), round(dy / L, 5)],
                      "length": round(L + 2.0, 2), "width": PATH_W + 0.8, "z_a": round(e[2], 2), "z_b": round(e[2], 2), "flight": None,
                      "profile": [[0.0, round(e[2], 2)], [round(L + 2.0, 2), round(e[2], 2)]], "road": True, "wall_min": list(WALL_MIN)})
    # the Yak Road: its first leg east under the mills and the wheel house, climbing as steeply as it must (no more than
    # LEG1_MAX) to cross the leat's head on slabs at SLAB over its water; then the legs above the leat at ROAD_GRADE
    leat_lines = [st for st in stretches if not st.get("race")]

    def leat_near(x, y, r):
        best = None
        for st in leat_lines:
            for pp in st["pts"]:
                if abs(pp[0] - x) < r and abs(pp[1] - y) < r:
                    d = math.hypot(pp[0] - x, pp[1] - y)
                    if d < r and (best is None or d < best[0]):
                        best = (d, pp[2], st["id"])
        return best

    best1 = None
    for g1 in np.arange(0.10, LEG1_MAX + 1e-6, 0.005):
        line = trace(Z, pts_r, n_foot, n_z, LEG1_HEAD, lambda x, y, z: leat_near(x, y, 1.0) is not None and not near_house(x, y, 4.0), g1, CUT_IN,
                     lambda x, y: near_house(x, y), steps=170, shy=0.25)
        hit = leat_near(line[-1][0], line[-1][1], 1.0)
        if hit is None or near_house(line[-1][0], line[-1][1], 4.0):
            continue
        on = trace(Z, pts_r, line[-1][:2], line[-1][2], math.atan2(line[-1][1] - line[-3][1], line[-1][0] - line[-3][0]), None, g1, CUT_IN, None, steps=int(SHELF + 4))
        P_, s_ = ease(line + on[1:])
        leg = [[float(a), float(b), float(n_z + g1 * c)] for (a, b), c in zip(P_, s_)]
        cr = crossings([leg], leat_lines)
        if not cr:
            continue
        miss = cr[0]["road"] - (cr[0]["water"] + SLAB)
        if best1 is None or (miss >= -0.05) > (best1[0] >= -0.05) or ((miss >= -0.05) == (best1[0] >= -0.05) and abs(miss) < abs(best1[0])):
            best1 = (miss, g1, leg)
    if best1 is None:
        raise SystemExit("serchu_mills: the Yak Road's first leg finds no crossing of the leat")
    miss, g1, leg1 = best1
    cr = crossings([leg1], leat_lines)[0]  # the road raised over the leat's slabs: a hump BUMP metres each way
    sc = min(range(len(leg1)), key=lambda i: math.hypot(leg1[i][0] - cr["at"][0], leg1[i][1] - cr["at"][1]))
    lift = max(0.0, cr["water"] + SLAB - cr["road"])
    for i in range(len(leg1)):
        leg1[i][2] += lift * max(0.0, 1.0 - abs(i - sc) / BUMP)
    rest, rest_landings = zigzag(Z, pts_r, (leg1[-1][0] + 0.0, leg1[-1][1]), leg1[-1][2], LEGS[1:], ROAD_GRADE, SEP[1],
                                 avoid=lambda x, y: near_house(x, y) or near_leat(x, y, SHELF / 2 + ROAD_W / 2 + 1.0), first_sep=True)
    yak_legs = [leg1] + rest
    yak_landings = rest_landings
    for k, leg in enumerate(yak_legs):
        lanes += lanes_along("R-09.%d" % (k + 1), leg, ROAD_W, 0.0, tol=0.4)  # (its lanes near its line: at a bend a lane far off it had
        # stood its wall across the next one's bed)
    for k, (e, s) in enumerate(yak_landings[:len(yak_legs) - 1]):  # (each between two legs)
        dx, dy = s[0] - e[0], s[1] - e[1]
        L = math.hypot(dx, dy)
        lanes.append({"id": "R-09.L%d" % (k + 1), "from": [round(e[0] - dx / L * 2.0, 2), round(e[1] - dy / L * 2.0, 2)], "dir": [round(dx / L, 5), round(dy / L, 5)],
                      "length": round(L + 4.0, 2), "width": ROAD_W + 2.0, "z_a": round(e[2], 2), "z_b": round(e[2], 2), "flight": None,
                      "profile": [[0.0, round(e[2], 2)], [round(L + 4.0, 2), round(e[2], 2)]], "road": True, "wall_min": list(WALL_MIN)})
    # where the road crosses the leat: on slabs, the channel going on under the road's bed
    culverts = crossings(yak_legs, leat_lines)

    # the paths painted trodden: from the footbridge's north foot to each mill's back door and to the wheel houses, the
    # leat walk along every stretch's shelf (its lanes are trodden already)
    paths = []
    for m in mills:  # from each mill's door (in its downstream wall, DOOR) down the slope to the road's first leg
        th = math.radians(m["facing"])
        fx_, fy_ = math.sin(th), math.cos(th)
        rx_, ry_ = -fy_, fx_  # its local +x, upstream
        door = (m["at"][0] + rx_ * (DOOR[0] - 1.0) - fx_ * DOOR[1], m["at"][1] + ry_ * (DOOR[0] - 1.0) - fy_ * DOOR[1])
        m["door"] = [round(door[0], 2), round(door[1], 2)]
        q_ = min(leg1, key=lambda pp: math.hypot(pp[0] - door[0], pp[1] - door[1]))
        if math.hypot(q_[0] - door[0], q_[1] - door[1]) < 40.0:
            paths.append([[round(door[0], 2), round(door[1], 2)], [round(q_[0], 2), round(q_[1], 2)]])

    # the barley terraces: above the leat, below FIELDS_TOP, the flank's own; hay on a few benches
    leat_y = {}
    for pp in shelf_pts:
        k = int(round(pp[0]))
        leat_y[k] = max(leat_y.get(k, -1e9), pp[1])
    fields = {"x": list(FIELDS_X), "top": FIELDS_TOP, "bottom": FIELDS_BOTTOM, "slope": FIELDS_SLOPE,
              "above": [[k, round(v + 6.0, 2)] for k, v in sorted(leat_y.items())]}
    hay = []
    tries = 0
    while len(hay) < HAY and tries < 5000:
        tries += 1
        x = rnd.uniform(FIELDS_X[0] + 20.0, FIELDS_X[1] - 40.0)
        y = rnd.uniform(-200.0, -60.0)
        z_ = float(Z(x, y))
        lo = max((v for k, v in leat_y.items() if abs(k - x) < 3), default=-1e9)
        if y < lo + 15.0 or z_ > FIELDS_TOP - 40.0:
            continue
        gx = (float(Z(x + 2.0, y)) - float(Z(x - 2.0, y))) / 4.0
        gy = (float(Z(x, y + 2.0)) - float(Z(x, y - 2.0))) / 4.0
        if math.degrees(math.atan(math.hypot(gx, gy))) > 32.0:
            continue
        if any(math.hypot(x - h["at"][0], y - h["at"][1]) < 18.0 for h in hay):
            continue
        if any(min(math.hypot(x - pp[0], y - pp[1]) for pp in leg) < ROAD_W + 4.0 for leg in yak_legs):
            continue
        hay.append({"id": "SER-17.h%d" % (len(hay) + 1), "kit": "camp_hay_pile_v1", "at": [round(x, 2), round(y, 2)], "level": round(z_ - 0.1, 2),
                    "facing": round(bearing(-gx, -gy), 1)})

    cf = {ln["id"]: cut_fill(Z, ln) for ln in lanes}
    out = {"about": "The north bank across the Serchu at the mills (tools/town/serchu_mills.py; M2 sprint 12, step 5): `leat` the leat SER-10's stretches, each [x, y, its water z] downstream (`tail` a mill's tail race out of its arch, `race` the last wheel's race to the river); `mills` SER-05 to 08 (`at`, `facing` its front, `level` its floor, `head` its chute's head on the leat, `jet` the chute's foot in its wall, `arch` its tail race's sill); `wheels` the water prayer wheels SER-09.1 and 09.2 (`in` and `out` the leat's water through them); `chutes` (each with the ground under its trestles); `weir` the intake's line of stones out into the river; `bridge` the footbridge SER-11 (`at` its middle over the water, `deck` its level, `facing` the bearing from its south end to its north, each end's place and its crib's height); `lanes` road lanes for tools/terrain/pads.py (the leat's shelf, the tail yards, the path up the south bank SER-11.p, the Yak Road R-09's first legs and landings) and the river's bed cut down where it stood over the water (`channel`); `culverts` where the road passes over the leat; `paths` painted trodden by tools/terrain/control.py; `fields` the barley terraces SER-17 (control.py), `things` hay on them. Regenerated with the terrain.",
           "leat": [{**st, "pts": [[round(v, 2) for v in pp] for pp in st["pts"]]} for st in stretches],
           "mills": mills, "wheels": wheels, "chutes": chutes, "weir": weir, "bridge": br,
           "south_path": [[round(v, 2) for v in pp] for pp in path_line],
           "yak_road": [[[round(v, 2) for v in pp] for pp in leg] for leg in yak_legs],
           "lanes": lanes + channel, "culverts": culverts, "paths": paths, "fields": fields, "things": hay}
    json.dump(out, open(OUT, "w", encoding="utf-8"), indent=1)

    # the report
    rep = ["# The north bank at the mills (SER-05 to SER-11, SER-17, SER-18)", "",
           "_Written by `tools/town/serchu_mills.py` (M2 sprint 12, step 5; plan chapter 02, D09 and 6.1) from the ground before the pads (`valley_shaped_1m`) and the Serchu's line (`data/rivers.json`): the leat's cascade, its mills and wheel houses, the footbridge and the paths to it, the Yak Road's first legs, the barley terraces._", "",
           "## The leat SER-10", "",
           "| Stretch | From | To | Length | Water | Over the river at its end |", "|---|---|---|---|---|---|"]
    for st in stretches:
        P = st["pts"]
        L = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(P[:-1], P[1:]))
        kk = min(range(len(pts_r)), key=lambda k: math.hypot(pts_r[k][0] - P[-1][0], pts_r[k][1] - P[-1][1]))
        rep.append("| %s | %+.0f, %+.0f | %+.0f, %+.0f | %.0f m | %.1f-%.1f | %.1f m |" % (st["id"], P[0][0], P[0][1], P[-1][0], P[-1][1], L, P[0][2], P[-1][2], P[-1][2] - pts_r[kk][2]))
    rep += ["", "## The mills and the wheel houses", "", "| Id | At | Facing | Floor | Chute | Back wall's ground | Front's ground |", "|---|---|---|---|---|---|---|"]
    for m in mills:
        rep.append("| %s | %+.1f, %+.1f | %.0f | %.2f | %.0f degrees over %.1f m | %+.2f | %+.2f |" % (m["id"], m["at"][0], m["at"][1], m["facing"], m["level"], m["chute"], m["run"], m["back"], m["front"]))
    for w in wheels:
        rep.append("| %s | %+.1f, %+.1f | %.0f | water %.2f | falls %.1f m | | |" % (w["id"], w["at"][0], w["at"][1], w["facing"], w["level"], WHEEL_DROP))
    rep += ["", "## The footbridge SER-11", "",
            "At %+.1f, %+.1f over the water at %.2f m, its deck %.2f m (%.1f m over it), facing %.0f; the north crib %.1f m, the south %.1f m over the ground." % (
                br["at"][0], br["at"][1], br["water"], br["deck"], DECK_OVER, br["facing"], br["north"][2], br["south"][2]), "",
            "The path up the south bank: %d legs, %.0f m, to the road at %.1f m." % (len(path_legs), sum(len(l_) for l_ in path_legs), path_line[-1][2] if path_line else 0.0), "",
            "The Yak Road R-09's first %d legs: %.0f m at %.0f%%, from %.1f to %.1f m; %d culverts over the leat." % (
                len(yak_legs), sum(len(l_) for l_ in yak_legs), 100 * ROAD_GRADE, yak_legs[0][0][2], yak_legs[-1][-1][2], len(culverts)), "",
            "## The lanes' cut and fill", "", "| Lane | Cut | Fill |", "|---|---|---|"]
    for lid, (c, f) in cf.items():
        if c > 1.5 or f > 1.5:
            rep.append("| %s | %.1f m | %.1f m |" % (lid, c, f))
    rep += ["", "%d hay piles on the barley." % len(hay), ""]
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep))
    print("serchu_mills: %d leat stretches, %d mills, %d wheel houses, the footbridge at %+.0f, %+.0f (cribs %.1f and %.1f m), %d path legs, %d road legs, %d culverts, %d lanes -> %s" % (
        len(stretches), len(mills), len(wheels), br["at"][0], br["at"][1], br["north"][2], br["south"][2], len(path_legs), len(yak_legs), len(culverts), len(lanes) + len(channel), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
