#!/usr/bin/env python3
"""Tödé, the upper quarter (M3 sprint 4, step 1; plan chapter 02, D06 and TOD-01 to TOD-26; chapter 03, 3.2, 3.4, 3.5,
11.8 and 12.1): where its houses and its named places stand on the real ground.
- The 68 houses of TOD-16 to TOD-19, "standing in their own terraced fields" on the Danba model (D06), dispersed over the
  quarter: the 14 Gyalrong tower-houses C in upper Tödé (H-TOD-001 to 014: H-TOD-001 is the tulku's family house TOD-04
  at chapter 02's +60, +500, H-TOD-002 the masons' TOD-15), the 30 log-storey houses A in lower and east Tödé (H-TOD-015 to 044),
  the four Bön households' rammed-earth D round their chapel TOD-02 (H-TOD-045 to 048), 16 more D in west Tödé (H-TOD-049
  to 064), the 4 poor houses E at the fields' edges (H-TOD-065 to 068), and the empty tower-house TOD-26.
- Each house on its own pad cut into the slope at its ground's middle (tools/terrain/pads.py; its fill wall by
  tools/town/walls.py), facing down the fall line, its yard before it (a D's walled yard 14 x 10 m, chapter 03, 3.2; a
  terrace before the others), the next house at least GAP metres off (each its own fields between), clear of the named
  places and of the ways already laid (the Sky Stair's head and the Tödé chorten, the Lukhang spring, the garden lane and
  the Gorge Rim Lookout, the Gorge Stair's west leg), below the leat (2,978 m: the fields' top, chapter 02, 2.5).
- Each kind drawn where chapter 02 puts it, the farthest of a few candidates from the houses already placed (so they
  spread as the Danba houses do, none in a row), on ground no steeper than its kind's STEEP.
- The named: the tower TOD-01, the chapel TOD-02, the mills TOD-05 and 06, the wheel houses TOD-07 to 09, the threshing
  floors TOD-11 to 14, the masons' house TOD-15, the empty tower-house TOD-26: each at chapter 02's place, or at the
  nearest ground within SETTLE_R that holds it when that place has too much fall (ISS-043).
Run: tools/py tools/town/tode.py [--out path]   Writes data/tode.json and docs/town/tode-report.md.
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
TOWN = os.path.join(ROOT, "data", "town.json")
GENERIC = os.path.join(ROOT, "data", "town_generic.json")
GARDENS = os.path.join(ROOT, "data", "gardens.json")
GORGE = os.path.join(ROOT, "data", "gorge_stair.json")
TODE_STAIR = os.path.join(ROOT, "data", "tode_stair.json")  # the Tödé Stair up the band over the chorten (tools/town/tode_stair.py,
# run before this): the paths begin at its top, houses and paths keep off it (M3 sprint 4, step 2)
ARGS = sys.argv[1:]
OUT = ARGS[ARGS.index("--out") + 1] if "--out" in ARGS else os.path.join(ROOT, "data", "tode.json")
REPORT = os.path.join(ROOT, "docs", "town", "tode-report.md")
SEED = 1903
BOX = (-365.0, 300.0, 250.0, 650.0)  # D06: x -365 to +300, y +230 to +650 (its foot above upper Shöl's top row, y 237)
LEAT = 2978.0  # the fields' top (chapter 02, TOD-10: "edge of cultivation")
FOOT = 2786.0  # above the Sky Stair's head (the Tödé chorten at 2,782 m)
UPPER = 2860.0  # upper Tödé from here (the tower-houses; chapter 02, TOD-16)
WEST = -120.0  # west Tödé west of here (the rammed-earth houses; TOD-18)
LOWER = 2905.0  # lower Tödé below here (the log-storey houses with east Tödé; TOD-17)
EAST = -20.0
SIZE = {"C": (11.0, 10.0), "A": (10.0, 9.0), "D": (14.0, 11.0), "E": (6.0, 5.0)}  # width (across the slope), depth
YARD = {"C": 3.0, "A": 3.0, "D": 10.0, "E": 2.0}  # level ground before the front (a D's walled yard, chapter 03, 3.2)
STEEP = {"C": 36.0, "A": 34.0, "D": 28.0, "E": 38.0}  # degrees: the steepest ground a kind is set on
GAP = {"C": 26.0, "A": 22.0, "D": 22.0, "E": 16.0}  # the least distance to another house's middle
TRIES = 24  # candidates drawn for each house; the farthest from the others taken
COUNTS = [("C", 12), ("D", 16), ("A", 30), ("E", 4)]  # (the named two C and the Bön four D placed first)
# each kind's kit types and their variants (../tibet-blender export_types.py VARIANTS; A and E the town's, by type and
# variant: world/town.gd kit_file)
KITS = {"C1": ("tode_tower_house_c1", 6), "C2": ("tode_tower_house_c2", 4), "D1": ("tode_rammed_house_d1", 5),
        "D2": ("tode_rammed_house_d2", 5), "BON_D1": ("tode_bon_house_d1", 2), "BON_D2": ("tode_bon_house_d2", 2),
        "A1": (None, 9), "A2": (None, 9), "A3": (None, 9), "A4": (None, 9), "E1": (None, 3), "RUIN": ("tod26_empty_tower_house", 1)}
C2_SHARE = 0.4  # of the tower-houses five storeys (chapter 03, 3.5: C1 and C2)
A_VARIANTS = ["A1", "A2", "A3", "A4"]
SETTLE_R = 30.0  # a named place moved at most this far to ground that holds it (a threshing floor FLOOR_R)
FLOOR_R = 60.0
GARDEN_W = 12.0  # the garden lane's plots along both its sides (data/gardens.json `plots`): kept clear with it
SETTLE = 6.0  # metres of fall across a named place's footprint before it is moved
NAMED = {  # id: (kind, footprint, how it stands)
    "TOD-01": ("tower", (9.0, 9.0), "pad"), "TOD-02": ("chapel", (9.0, 7.0), "pad"),
    "TOD-05": ("mill", (4.0, 4.0), "pad"), "TOD-06": ("mill", (4.0, 4.0), "pad"),
    "TOD-07": ("wheel house", (2.5, 2.5), "pad"), "TOD-08": ("wheel house", (2.5, 2.5), "pad"), "TOD-09": ("wheel house", (2.5, 2.5), "pad"),
    "TOD-11": ("threshing floor", (14.0, 14.0), "pad"), "TOD-12": ("threshing floor", (14.0, 14.0), "pad"),
    "TOD-13": ("threshing floor", (12.0, 12.0), "pad"), "TOD-14": ("threshing floor", (12.0, 12.0), "pad"),
    "TOD-25": ("window stall", (6.0, 5.0), "pad"),  # (the widow's room at the Sky Stair's head: M3 sprint 4, step 5)
}
HOUSE_NAMED = {"H-TOD-001": "TOD-04", "H-TOD-002": "TOD-15"}  # the tower-houses chapter 02 places
FIXED = {"TOD-25": 2784.5}  # a named place kept at chapter 02's place, its pad at this level: the window stall on the
# forecourt by the Tödé chorten at the Sky Stair's head (2,782 m), cut into the band behind it (M3 sprint 4, step 5)
PAD = {"TOD-01": (13.0, 13.0), "TOD-02": (15.0, 13.0)}  # a named place's pad where it is larger than its footprint: the tower 9 m
# across, its log's foot 6 m out before its door on level ground (M3 sprint 4, step 3; the houses keep off its footprint as
# before); the Bön chapel's terrace, its circuit R-24 round it on the level (step 6: tools/town/tode_things.py)
BON = (-250.0, 560.0)  # the chapel TOD-02, round which the four Bön households live (TOD-03)
LATE = ("TOD-02", "TOD-11", "TOD-12", "TOD-13", "TOD-14", "TOD-05", "TOD-06")  # the named places with ways of their own, laid after
# the houses' (M3 sprint 4, step 6: the chapel's terrace, the threshing floors, the mills, for their people)
BON_R = (16.0, 45.0)  # their distance from it
# The field paths: from each house's side, where its pad meets the ground at its own level (a pad cut in at its back and
# filled at its front stands metres over the ground before it), by the cheapest way no steeper than PATH_GRADE to the
# paths already laid, the first from the Tödé chorten's forecourt at the Sky Stair's head and the garden lane's top by the
# Gorge Rim Lookout; across the quarter's 33 degrees they zigzag. Each straight piece a lane (`road`: carved by
# tools/terrain/pads.py, walled in dry stone by tools/town/walls.py, trodden earth in tools/terrain/control.py).
PATH_CELL = 3.0  # the search's grid, so a zigzag's legs lie 3 m apart, room for their banks between (until 11 Oct 2026
# 2.0: legs 2 m apart, each one's walls standing in the next one's bed, and the route up stalled at the first turn)
PATH_W = 2.0  # a path's bed (tools/terrain/pads.py raises a path's whole width over a fill, as the steps')
PATH_GRADE = 0.28  # the steepest a path climbs (the Castle Ramp's 22%, the garden lane's)
PATH_REUSE = 0.35  # a cell on a path already costs this share of a new one: the paths gather into ways
PATH_CLEAR = 2.5  # kept off a pad's level ground by this, its batter (tools/terrain/pads.py BATTER 2.0) and the top of a
# deep cut behind it (until 11 Oct 2026 0.6: a path ran along a house's cut, its fill wall 7 m over the pad below)
APRON = 1.5  # (tools/terrain/pads.py APRON: a pad's level ground round its footprint)
ENTRIES = [(-20.0, 265.0), (253.0, 239.0)]  # the Tödé chorten's forecourt; the garden lane's top (data/gardens.json GL-16)
# Ground the pads will carve that the paths start from, its level for their search (the ground before the pads stands up
# to 4 m over it): the Sky Stair's head and its 9 m of level ground past its top round the Tödé chorten (tools/terrain/
# pads.py STAIRS: 4 m wide at 2,782 m), the garden lane's top by the Lookout (data/gardens.json GL-16's end, 2,781.5 m)
CARVED = [(-22.0, -18.0, 261.0, 266.0, 2782.0), (251.0, 255.0, 237.0, 241.0, 2781.5)]  # x0, x1, y0, y1, level (the
# forecourt's 2,782.0 m north of the stair's top flight, as the pads carve it: until 11 Oct 2026 2,782.8, a step of 0.8 m
# where the path left it, and the route up stalled there)
SIMPLIFY = 1.0  # metres: a path's points kept where it bends more than this
# Where the slope is too steep for a ramp's zigzags (their legs 3 m apart blurred into one slope on the terrain's 1 m
# grid, and the route up stalled at every turn), a stone flight straight up it, as the Sky Stair and the 1,080 steps:
# a move steeper than PATH_GRADE up to FLIGHT_GRADE, its every metre FLIGHT_COST times a ramp's; each such piece a lane
# with its `flight` (`steps`: built by ../tibet-blender export_lanes.py with its own collision, placed by world/town.gd)
FLIGHT_GRADE = 0.85
FLIGHT_COST = 2.5
RISER = 0.19  # a flight's risers (the Gorge Stair's)
TERRACE_L, TERRACE_W = 15.0, 4.5  # the Tödé Stair's top terrace: a level walk along the contour from its last step, where every
# way into Tödé begins (M3 sprint 4, step 2: the ground round the top falls 90-115% across the contour, and three ways leaving
# it within ten metres of each other at three heights took each other's beds and stalled the walker)
FLIGHT_TURN = 30.0  # degrees a way may turn where a flight runs straight on into another (sharper, the walker stalled at the
# corner between them: M3 sprint 4, step 2)
HAIRPIN = 90.0  # nor more than this into or out of a flight: a hairpin's legs side by side at two heights took each other's
# beds; and no piece crosses one laid before but where it joins it (two ways' flights crossed at one height)
LANDING_CLEAR = 2.5  # no flight passes within this of an entry, the level landing at the Tödé Stair's top (M3 sprint 4,
# step 2; until 11 Oct 2026 none within 4.5 m of it, and on the steep ground round the top no way could leave it)
STAIR_BERTH = 3.0  # metres the paths' cells keep beside the Tödé Stair's pieces: a path's bed 2 m off its edge (at half a
# metre, until 11 Oct 2026, a path ran down beside its last flight, its bed cut into the stair's trench and the walker fell in)
PATH_WALL_MIN = [1.6, 1.4]  # a path's cut and fill walled from these heights (tools/town/walls.py `wall_min`); a lower bank
# earth (until 11 Oct 2026 1.0 and 0.9: walls along most of 4.7 km of path)


def fall(Z, x, y):
    """The fall line's way (unit, downhill) and the slope's degrees at (x, y), over 4 m."""
    e = 2.0
    gx = (float(Z(x + e, y)) - float(Z(x - e, y))) / (2 * e)
    gy = (float(Z(x, y + e)) - float(Z(x, y - e))) / (2 * e)
    gl = math.hypot(gx, gy)
    if gl < 1e-6:
        return (0.0, -1.0), 0.0
    return (-gx / gl, -gy / gl), math.degrees(math.atan(gl))


def rect(cx, cy, w, d, ux, uy, grow=0.0):
    """A footprint's corners: (ux, uy) its front's way; w across it, d along it."""
    ax, ay = -uy, ux
    hw, hd = w / 2 + grow, d / 2 + grow
    return [(cx + ax * a * hw + ux * b * hd, cy + ay * a * hw + uy * b * hd) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def overlap(a, b):
    """Two convex quads overlap (separating axes)."""
    for poly in (a, b):
        for i in range(4):
            x1, y1 = poly[i]
            x2, y2 = poly[(i + 1) % 4]
            nx, ny = y2 - y1, x1 - x2
            pa = [nx * x + ny * y for x, y in a]
            pb = [nx * x + ny * y for x, y in b]
            if max(pa) < min(pb) or max(pb) < min(pa):
                return False
    return True


def ground(Z, r):
    """The ground under a quad: (median, least, most) over a 7 x 7 grid of it."""
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = r
    zs = []
    for s in np.linspace(0.0, 1.0, 7):
        for t in np.linspace(0.0, 1.0, 7):
            ax, ay = x0 + (x1 - x0) * s, y0 + (y1 - y0) * s
            bx, by = x3 + (x2 - x3) * s, y3 + (y2 - y3) * s
            zs.append(float(Z(ax + (bx - ax) * t, ay + (by - ay) * t)))
    return float(np.median(zs)), min(zs), max(zs)


def lane_rects(paths, grow=2.0, along=None):
    """Every lane of the given planners' files as a quad, `grow` metres clear beside it (`along` beyond its ends, if given)."""
    out = []
    for p in paths:
        if not os.path.exists(p):
            continue
        for ln in json.load(open(p, encoding="utf-8")).get("lanes", []):
            (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
            a = grow if along is None else along
            out.append(rect(fx + ux * L / 2, fy + uy * L / 2, W + 2.0 * grow, L + 2.0 * a, ux, uy))
    return out


def house_site(Z, x, y, kind, blocked, placed):
    """A house of `kind` with its middle at (x, y), facing down the fall line, its yard before it: {rect (its pad), c, pad
    middle, facing, level, slope} or None where the ground is too steep, the leat or the box is crossed, or it meets
    something placed or kept clear."""
    (ux, uy), slope = fall(Z, x, y)
    if slope > STEEP[kind]:
        return None
    w, d = SIZE[kind]
    yd = YARD[kind]
    gx, gy = x + ux * yd / 2, y + uy * yd / 2  # the pad's middle: the house and its yard before it
    r = rect(gx, gy, w, d + yd, ux, uy)
    if not all(BOX[0] <= qx <= BOX[1] and BOX[2] <= qy <= BOX[3] for qx, qy in r):
        return None
    lv, lo, hi = ground(Z, r)
    if hi > LEAT - 2.0 or lo < FOOT - 4.0:
        return None
    grown = rect(gx, gy, w, d + yd, ux, uy, 1.5)
    if any(overlap(grown, q) for q in blocked) or any(overlap(grown, q) for q in placed):
        return None
    return {"rect": r, "c": (x, y), "g": (gx, gy), "facing": math.degrees(math.atan2(ux, uy)) % 360.0, "level": round(lv, 2),
            "slope": slope, "cut": round(hi - lv, 1), "fill": round(lv - lo, 1)}


def in_zone(kind, x, y, z):
    if kind == "C":
        return z >= UPPER
    if kind == "D":
        return x <= WEST
    if kind == "A":
        return z <= LOWER or x >= EAST
    return True


def settle(Z, x, y, w, d, others, reach=SETTLE_R):
    """A named place on more than SETTLE of fall moved to the nearest ground within `reach` that holds it (the least
    fall, a little for the distance), clear of the others: (x, y, fall)."""
    best = None
    for dx in np.arange(-reach, reach + 0.1, 2.0):
        for dy in np.arange(-reach, reach + 0.1, 2.0):
            if math.hypot(dx, dy) > reach:
                continue
            r = rect(x + dx, y + dy, w, d, 0.0, -1.0, 2.0)
            if any(overlap(r, q) for q in others):
                continue
            _, lo, hi = ground(Z, r)
            score = (hi - lo) + 0.1 * math.hypot(dx, dy)
            if best is None or score < best[0]:
                best = (score, x + dx, y + dy, hi - lo)
    return (x, y, None) if best is None else (best[1], best[2], best[3])


def _inside(r, X, Y):
    """Grid points inside a convex quad (its corners in order): on the side of each edge its own middle is on (until 11
    Oct 2026 the side the most of the grid lay on, so many pads were never kept clear and a path ran along a house)."""
    mx, my = sum(q[0] for q in r) / 4.0, sum(q[1] for q in r) / 4.0
    out = np.ones(X.shape, bool)
    for k in range(4):
        (ax, ay), (bx, by) = r[k], r[(k + 1) % 4]
        c = (bx - ax) * (Y - ay) - (by - ay) * (X - ax)
        inner = (bx - ax) * (my - ay) - (by - ay) * (mx - ax)
        out &= c * (1.0 if inner >= 0.0 else -1.0) >= 0.0
    return out


def _simplify(pts):
    """A path's points (x, y, z) kept where it bends more than SIMPLIFY or a straight piece would climb over PATH_GRADE
    (Ramer-Douglas-Peucker on the plan, split again where a merged piece grows too steep)."""
    if len(pts) < 3:
        return pts
    (ax, ay, az), (bx, by, bz) = pts[0], pts[-1]
    L = math.hypot(bx - ax, by - ay)
    worst, k = -1.0, 0
    for i in range(1, len(pts) - 1):
        x, y, _ = pts[i]
        dd = abs((bx - ax) * (ay - y) - (ax - x) * (by - ay)) / max(L, 1e-6)
        if dd > worst:
            worst, k = dd, i
    if worst <= SIMPLIFY and abs(bz - az) <= PATH_GRADE * 1.08 * max(L, 1e-6):
        return [pts[0], pts[-1]]
    return _simplify(pts[:k + 1])[:-1] + _simplify(pts[k:])


def _pieces(pts):
    """A path's points simplified run by run: its ramps (no steeper than PATH_GRADE) and its flights apart, so a straight
    piece is all ramp or all flight."""
    if len(pts) < 2:
        return pts
    steep = [abs(b[2] - a[2]) > PATH_GRADE * 1.04 * max(math.hypot(b[0] - a[0], b[1] - a[1]), 1e-6) for a, b in zip(pts, pts[1:])]
    out, start = [], 0
    for k in range(1, len(steep) + 1):
        if k == len(steep) or steep[k] != steep[start]:
            run = pts[start:k + 1]
            simple = _simplify(run) if not steep[start] else _straight(run)
            out += simple if not out else simple[1:]
            start = k
    return out


def _straight(pts):
    """A flight's run of points: straight between its ends where it bends less than SIMPLIFY, else split as a ramp is."""
    (ax, ay, _), (bx, by, _) = pts[0], pts[-1]
    L = math.hypot(bx - ax, by - ay)
    if len(pts) < 3 or max(abs((bx - ax) * (ay - y) - (ax - x) * (by - ay)) / max(L, 1e-6) for x, y, _ in pts[1:-1]) <= SIMPLIFY:
        return [pts[0], pts[-1]]
    k = len(pts) // 2
    return _straight(pts[:k + 1])[:-1] + _straight(pts[k:])


def field_paths(Z, houses, named_rects, blocked, entries=None, carved=None, terrace=None, late=()):
    """The field paths (PATH_*): [lane] and the path to each house as its points, for the report and the routes. `terrace`:
    {quad, z}, a level terrace every cell of which is an entry, which a way may reach by a ramp or by a flight (one flight a
    cell) and no flight crosses. `late`: rects kept clear by the houses' ways but not by the goals marked `after` (the named
    places laid after them: the Bön chapel's terrace, the threshing floors, the mills; M3 sprint 4, step 6), so the houses'
    ways stay as they were."""
    import heapq
    x0, x1, y0, y1 = BOX[0] - 15.0, BOX[1] + 15.0, BOX[2] - 25.0, BOX[3] + 10.0
    nx, ny = int((x1 - x0) / PATH_CELL) + 1, int((y1 - y0) / PATH_CELL) + 1
    X, Y = np.meshgrid(x0 + np.arange(nx) * PATH_CELL, y0 + np.arange(ny) * PATH_CELL)
    H = np.vectorize(lambda a, b: float(Z(a, b)))(X, Y)
    for cx0, cx1, cy0, cy1, cz in (CARVED if carved is None else carved):
        H[(X >= cx0) & (X <= cx1) & (Y >= cy0) & (Y <= cy1)] = cz
    free = np.ones(X.shape, bool)
    pad_of = lambda h: rect(h["pad"][0], h["pad"][1], h["pad"][2], h["pad"][3], math.sin(math.radians(h["rot_deg"])), math.cos(math.radians(h["rot_deg"])), APRON + PATH_CLEAR)
    for h in houses:
        if not h.get("after"):
            free &= ~_inside(pad_of(h), X, Y)
    for r in named_rects + blocked:
        free &= ~_inside(r, X, Y)
    free &= H < LEAT
    free_late = free.copy()  # (for the goals marked `after`: their own pads kept clear by them alone)
    for h in houses:
        if h.get("after"):
            free_late &= ~_inside(pad_of(h), X, Y)
    for r in late:
        free &= ~_inside(r, X, Y)
    cell = lambda x, y: (int(round((y - y0) / PATH_CELL)), int(round((x - x0) / PATH_CELL)))
    on = np.zeros(X.shape, bool)
    toward = {}  # a path's cell: the next cell towards the entry its way leads to (None at an entry)
    bed_z = {}  # a path's cell: its bed's height there, the straight piece over it (a path joining another mid-piece
    # starts at that piece's bed, not the ground: until 11 Oct 2026 a flight's foot had stood 0.7 m over the ramp it left)
    entries = ENTRIES if entries is None else entries
    landings = []  # each entry's cell's middle: the landing no flight crosses
    steep = np.zeros(X.shape, bool)  # the cells of the flights laid so far, their ends among them
    for ex, ey in entries:
        j, i = cell(ex, ey)
        free[j, i] = free_late[j, i] = on[j, i] = True
        toward[(j, i)] = None
        landings.append((float(X[j, i]), float(Y[j, i])))

    on_terrace = np.zeros(X.shape, bool)
    flight_in = set()  # the terrace's cells a flight has reached: one each
    if terrace is not None:
        on_terrace = _inside(terrace["quad"], X, Y)
        H[on_terrace] = terrace["z"]
        for j, i in zip(*np.nonzero(on_terrace)):
            free[j, i] = free_late[j, i] = on[j, i] = True
            toward[(int(j), int(i))] = None
            bed_z[(int(j), int(i))] = float(terrace["z"])
        inner_q = terrace["quad"]
        mx_, my_ = sum(q[0] for q in inner_q) / 4.0, sum(q[1] for q in inner_q) / 4.0
        inner_q = [(mx_ + (q[0] - mx_) * 0.8, my_ + (q[1] - my_) * 0.8) for q in inner_q]  # (its middle, a flight's end kept out)

    laid = {}  # the pieces' moves laid so far, by the cells round them: ((j0, i0), (j1, i1))

    def crosses(cj, ci, nj, ni):
        """The move from (cj, ci) to (nj, ni) crosses a move laid before (not where it meets it at a cell)."""
        seen = set()
        for jj in range(min(cj, nj) - 1, max(cj, nj) + 2):
            for ii in range(min(ci, ni) - 1, max(ci, ni) + 2):
                for sg in laid.get((jj, ii), ()):
                    if sg in seen:
                        continue
                    seen.add(sg)
                    (aj, ai), (bj, bi) = sg
                    if len({(aj, ai), (bj, bi), (cj, ci), (nj, ni)}) < 4:
                        continue  # (they meet at a cell: a junction or a way's own turn)
                    d1 = (ni - ci) * (aj - cj) - (nj - cj) * (ai - ci)
                    d2 = (ni - ci) * (bj - cj) - (nj - cj) * (bi - ci)
                    d3 = (bi - ai) * (cj - aj) - (bj - aj) * (ci - ai)
                    d4 = (bi - ai) * (nj - aj) - (bj - aj) * (ni - ai)
                    if d1 * d2 < 0 and d3 * d4 < 0:
                        return True
        return False

    def over_landing(cj, ci, nj, ni):
        ax_, ay_, bx_, by_ = float(X[cj, ci]), float(Y[cj, ci]), float(X[nj, ni]), float(Y[nj, ni])
        dx_, dy_ = bx_ - ax_, by_ - ay_
        for lx, ly in landings:
            t = max(0.0, min(1.0, ((lx - ax_) * dx_ + (ly - ay_) * dy_) / (dx_ * dx_ + dy_ * dy_)))
            if math.hypot(ax_ + t * dx_ - lx, ay_ + t * dy_ - ly) < LANDING_CLEAR:
                return True
        if terrace is not None:  # nor across the terrace
            tt = np.array([0.2, 0.4, 0.6])
            if _inside(inner_q, ax_ + tt * dx_, ay_ + tt * dy_).any():
                return True
        return False
    offs = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1), (1, 2), (1, -2), (-1, 2), (-1, -2), (2, 1), (2, -1), (-2, 1), (-2, -1)]
    steps = [(dj, di, PATH_CELL * math.hypot(dj, di)) for dj, di in offs]
    order = sorted(houses, key=lambda h: (bool(h.get("after")), min(math.hypot(h["pos"][0] - ex, h["pos"][1] - ey) for ex, ey in entries)))
    # (a goal marked `after`, the Bön chapel's terrace, last: the houses' ways as they were)
    lanes, ways, short = [], {}, []
    for h in order:
        if h.get("after"):  # (the named places after the houses: the rects kept clear for the houses' ways open to them)
            free = free_late
        th = math.radians(h["rot_deg"])
        ax, ay = -math.cos(th), math.sin(th)  # the kit's +x in the town grid: the pad's sides
        px, py, pw, pd = h["pad"]
        sides = sorted((1.0, -1.0), key=lambda s_: s_ != h.get("side", s_))  # (a D's gate side first)
        best = None
        for s_ in sides:
            if best is not None and "side" in h:
                break  # (a D's gate's side found a way: the other only when it found none; a C, A or E the nearer)
            reach = pw / 2 + APRON + PATH_CLEAR + 1.0
            dx, dy = px + s_ * ax * reach, py + s_ * ay * reach
            j, i = cell(dx, dy)
            if not (0 <= j < ny and 0 <= i < nx):
                continue
            # Dijkstra from the door to the paths already laid
            dist = {(j, i): 0.0}
            prev = {}
            heap = [(0.0, j, i)]
            found = None
            while heap:
                c, cj, ci = heapq.heappop(heap)
                if c > dist.get((cj, ci), 1e18):
                    continue
                if on[cj, ci]:
                    found = (cj, ci)
                    break
                hz = H[cj, ci]
                for dj, di, dl in steps:
                    nj, ni = cj + dj, ci + di
                    if not (0 <= nj < ny and 0 <= ni < nx) or not free[nj, ni]:
                        continue
                    if abs(dj) + abs(di) == 3 and not free[cj + dj // 2 if abs(dj) == 2 else cj, ci + di // 2 if abs(di) == 2 else ci]:
                        continue  # (a knight's move: the cell it passes over free too; until 15 Oct 2026 `(d - 1) // 2` for d = -2
                        # gave -2, the destination's own row or column, so a move west or south could jump a house's corner or a
                        # wall's 3 m band: ISS-221)
                    gr = abs(H[nj, ni] - hz) / dl
                    if gr > FLIGHT_GRADE:
                        continue
                    if gr > PATH_GRADE and over_landing(cj, ci, nj, ni):
                        continue  # (no flight over an entry's landing: there pieces meet)
                    if (cj, ci) in prev:  # no sharp turn from a flight straight into another, no hairpin into or out of one
                        pj, pi = prev[(cj, ci)]
                        was_steep = abs(float(H[cj, ci]) - float(H[pj, pi])) > PATH_GRADE * PATH_CELL * math.hypot(cj - pj, ci - pi)
                        if was_steep or gr > PATH_GRADE:
                            a1 = math.atan2(cj - pj, ci - pi)
                            a2 = math.atan2(dj, di)
                            turn = abs(math.degrees(math.atan2(math.sin(a2 - a1), math.cos(a2 - a1))))
                            if turn > HAIRPIN or (was_steep and gr > PATH_GRADE and turn > FLIGHT_TURN):
                                continue
                    if crosses(cj, ci, nj, ni):
                        continue
                    if on[nj, ni] and on_terrace[nj, ni]:
                        if gr > PATH_GRADE and (float(H[cj, ci]) < float(H[nj, ni]) or any(abs(nj - fj) <= 1 and abs(ni - fi) <= 1 for fj, fi in flight_in)):
                            continue  # (onto the terrace by a ramp, or down onto it by a flight two cells from any other:
                            # a flight up onto it from below had its top steps under its bed; two side by side off its edge at
                            # two heights took each other's steps)
                    elif on[nj, ni] and (gr > PATH_GRADE or steep[nj, ni]):
                        continue  # (a way joins the paths by a ramp, never at a flight's cells or its ends: two flights'
                        # ends meeting at a junction caught the walker, M3 sprint 4, step 2)
                    step_cost = dl * (1.0 + 2.0 * (gr / PATH_GRADE) ** 2) if gr <= PATH_GRADE else dl * FLIGHT_COST * (1.0 + 2.0 * gr)
                    nc = c + step_cost * (PATH_REUSE if on[nj, ni] else 1.0)
                    if nc < dist.get((nj, ni), 1e18):
                        dist[(nj, ni)] = nc
                        prev[(nj, ni)] = (cj, ci)
                        heapq.heappush(heap, (nc, nj, ni))
            if found is not None and (best is None or dist[found] < best[0]):
                cur, chain = found, [found]
                while cur in prev:
                    cur = prev[cur]
                    chain.append(cur)
                best = (dist[found], chain[::-1], s_)  # from the door to the junction
        if best is None:
            short.append(h["id"])
            continue
        _, chain, s_ = best
        if "side" in h and s_ != h["side"]:  # a D whose gate's side found no way: the variant with its gate on the other
            n = next(n_ for k_, n_ in KITS.values() if k_ == h["kit"])
            want = 0 if s_ > 0 else 1  # (the seed's parity: 101 v + 7 even for the kit's +x)
            h["seed"] = min((v for v in range(1, n + 1) if (101 * v + 7) % 2 == want), key=lambda v: abs(v - h["seed"]))
        h["side"] = s_
        for cj, ci in chain:
            on[cj, ci] = True
        for a_, b_ in zip(chain, chain[1:]):  # its steep moves' cells: flights, never a junction
            if abs(float(H[b_]) - float(H[a_])) > PATH_GRADE * PATH_CELL * math.hypot(b_[0] - a_[0], b_[1] - a_[1]):
                steep[a_] = steep[b_] = True
                if on_terrace[b_]:
                    flight_in.add(b_)
        for a_, b_ in zip(chain, chain[1:]):
            toward[a_] = b_
            for jj in range(min(a_[0], b_[0]), max(a_[0], b_[0]) + 1):
                for ii in range(min(a_[1], b_[1]), max(a_[1], b_[1]) + 1):
                    laid.setdefault((jj, ii), []).append((a_, b_))
        whole, cur = [], chain[0]  # the whole way from the door to its entry, for the routes
        while cur is not None:
            whole.append(cur)
            cur = toward.get(cur)
        hz = lambda c_: bed_z.get(c_, float(H[c_]))  # a cell on a piece laid before: that piece's bed there, not the ground
        raw = [(float(X[cj, ci]), float(Y[cj, ci]), hz((cj, ci))) for cj, ci in chain]
        pts = _pieces(raw)
        k_of = {}  # each kept point's place in the chain, for the beds of the cells between
        for k_, q in enumerate(raw):
            k_of.setdefault((q[0], q[1]), k_)
        for (ax_, ay_, az_), (bx_, by_, bz_) in zip(pts, pts[1:]):  # the cells under each piece: their bed's height
            i0, i1 = k_of[(ax_, ay_)], k_of[(bx_, by_)]
            Lp = max(math.hypot(bx_ - ax_, by_ - ay_), 1e-6)
            for c_ in chain[i0:i1 + 1]:
                if c_ in bed_z and c_ != chain[-1]:
                    continue
                t_ = ((float(X[c_]) - ax_) * (bx_ - ax_) + (float(Y[c_]) - ay_) * (by_ - ay_)) / (Lp * Lp)
                bed_z.setdefault(c_, az_ + (bz_ - az_) * min(1.0, max(0.0, t_)))
        ways[h["id"]] = [[round(x, 2), round(y, 2), round(z, 2)] for x, y, z in
                         _pieces([(float(X[cj, ci]), float(Y[cj, ci]), hz((cj, ci))) for cj, ci in whole])]
        n_way = len(ways)
        for k, ((ax_, ay_, az_), (bx_, by_, bz_)) in enumerate(zip(pts, pts[1:])):
            L = math.hypot(bx_ - ax_, by_ - ay_)
            if L < 0.5:
                continue
            # each house's path its own way (walls.py: where another way joins a piece, no wall across it), walled only
            # where its cut or its fill is high, a low bank left bare earth
            lid = "TOD-P%02d.%02d" % (n_way, k + 1)
            if abs(bz_ - az_) > PATH_GRADE * 1.08 * L:  # a flight, built from its foot up
                if bz_ < az_:
                    ax_, ay_, az_, bx_, by_, bz_ = bx_, by_, bz_, ax_, ay_, az_
                n = max(3, int(round((bz_ - az_) / RISER)))
                lanes.append({"id": lid, "from": [round(ax_, 2), round(ay_, 2)], "dir": [round((bx_ - ax_) / L, 4), round((by_ - ay_) / L, 4)],
                              "length": round(L, 2), "width": PATH_W, "z_a": round(az_, 2), "z_b": round(bz_, 2),
                              "profile": [[0.0, round(az_ - 0.1, 2)], [round(L, 2), round(bz_ - 0.1, 2)]], "steps": True, "path": True,
                              "flight": {"file": "tode_" + lid.lower().replace("-", "_").replace(".", "_"), "s": 0.0, "rise": round(bz_ - az_, 3),
                                         "z": round(az_, 2), "n": n, "run": round(L / n, 3), "top": 0.0, "walls": None},
                              "wall_min": PATH_WALL_MIN})
                continue
            lanes.append({"id": lid, "from": [round(ax_, 2), round(ay_, 2)],
                          "dir": [round((bx_ - ax_) / L, 4), round((by_ - ay_) / L, 4)], "length": round(L, 2), "width": PATH_W,
                          "z_a": round(az_, 2), "z_b": round(bz_, 2), "flight": None,
                          "profile": [[0.0, round(az_, 2)], [round(L, 2), round(bz_, 2)]], "road": True, "path": True,
                          "wall_min": PATH_WALL_MIN})
    return lanes, ways, short


def main():
    site_ = Site.load()
    g = site_.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site_.shift
    rng = random.Random(SEED)
    town = json.load(open(TOWN, encoding="utf-8"))
    recs = {b["id"]: b for b in town["buildings"]}
    # kept clear: the ways already laid, upper Shöl's top houses, the spring and the Lookout, the Sky Stair's head
    blocked = lane_rects([GORGE]) + lane_rects([GARDENS], GARDEN_W)
    stair = json.load(open(TODE_STAIR, encoding="utf-8")) if os.path.exists(TODE_STAIR) else None
    for h in json.load(open(GENERIC, encoding="utf-8"))["houses"]:
        if h["pos"][1] > 180.0:
            th = math.radians(h["rot_deg"])
            blocked.append(rect(h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1], math.sin(th), math.cos(th), 3.0))
    path_clear = list(blocked) + lane_rects([TODE_STAIR], STAIR_BERTH, 0.5)  # what the paths keep off: the same (the
    # stair by STAIR_BERTH beside it and half a metre beyond its ends, a house by 4), but the chorten's and the stall's own
    # ground, the paths' way in from the forecourt (a house keeps 10 m off the chorten, 4 m off the stall)
    blocked += lane_rects([TODE_STAIR], 4.0)
    for bid, grow in (("SHL-14", 6.0), ("SHL-32", 8.0), ("TOD-21", 10.0), ("TOD-25", 4.0)):
        b = recs[bid]
        fp = b.get("footprint") or (4.0, 4.0)
        blocked.append(rect(b["pos"][0], b["pos"][1], fp[0], fp[1], 0.0, -1.0, grow))
        if bid in ("SHL-14", "SHL-32"):
            path_clear.append(rect(b["pos"][0], b["pos"][1], fp[0], fp[1], 0.0, -1.0, 1.0))
    # the named places first, at chapter 02's or the nearest ground that holds them
    named = {}
    named_rects = []
    for nid, (kind, (w, d), how) in NAMED.items():
        b = recs[nid]
        x, y = float(b["pos"][0]), float(b["pos"][1])
        r = rect(x, y, w, d, 0.0, -1.0)
        _, lo, hi = ground(Z, r)
        moved = None
        if hi - lo > SETTLE and nid not in FIXED:
            nx, ny, f = settle(Z, x, y, w, d, blocked + named_rects, FLOOR_R if kind == "threshing floor" else SETTLE_R)
            if (nx, ny) != (x, y):
                moved = [x, y]
                x, y = nx, ny
                r = rect(x, y, w, d, 0.0, -1.0)
        lv, lo, hi = ground(Z, r)
        lv = FIXED.get(nid, lv)
        (fx_, fy_), _ = fall(Z, x, y)
        named[nid] = {"id": nid, "kind": kind, "at": [round(x, 2), round(y, 2)], "level": round(lv, 2), "footprint": [w, d],
                      "fall": round(hi - lo, 1), "was": [float(b["pos"][0]), float(b["pos"][1]), b["pos"][2]],
                      "facing": round(math.degrees(math.atan2(fx_, fy_)) % 360.0, 1)}  # (down the fall line: the tower's door
        # and its log, world/town.gd)
        if nid in PAD:
            named[nid]["pad"] = [round(x, 2), round(y, 2), PAD[nid][0], PAD[nid][1]]
        if moved:
            named[nid]["moved_from"] = moved
        named_rects.append(rect(x, y, w, d, 0.0, -1.0, 6.0 if kind != "threshing floor" else 3.0))
    blocked += named_rects
    houses, placed = [], []

    decks = {}  # each kit's variants in a shuffled order, dealt in turn, so no two near houses are alike

    def deal(key):
        kit, n = KITS[key]
        if not decks.get(key):
            decks[key] = rng.sample(range(1, n + 1), n)
        return kit, decks[key].pop()

    def add(hid, kind, s, extra=None):
        w, d = SIZE[kind]
        extra = extra or {}
        if kind == "C":
            variant = "C1" if extra.get("ruin") else ("C2" if rng.random() < C2_SHARE else "C1")
        elif kind == "D":
            variant = rng.choice(("D1", "D2"))
        elif kind == "A":
            variant = rng.choice(A_VARIANTS)
        else:
            variant = "E1"
        kit, seed = deal("RUIN" if extra.get("ruin") else ("BON_" + variant if extra.get("bon") else variant))
        h = {"id": hid, "type": kind, "variant": variant, "district": "tode", "quarter": "tode", "seed": seed,
             "pos": [round(s["c"][0], 2), round(s["c"][1], 2), s["level"]], "rot_deg": round(s["facing"], 1), "footprint": [w, d],
             "storeys": {"C": 5 if variant == "C2" else 4, "A": 2, "D": 2, "E": 1}[kind], "enterable": False,
             "pad": [round(s["g"][0], 2), round(s["g"][1], 2), w, d + YARD[kind]], "cut": s["cut"], "fill": s["fill"]}
        if kit:
            h["kit"] = kit
        if kind == "D":  # the yard's gate in its side wall, the kit's +x on an even seed (../tibet-blender kit/tode.py
            # rammed_house; export_types.py seeds a variant v as 101 v + 7): the house's path comes to that side
            h["side"] = 1.0 if (101 * seed + 7) % 2 == 0 else -1.0
        h.update(extra)
        houses.append(h)
        placed.append(s["rect"])
        return h

    def near(x, y, kind):
        return min([math.hypot(x - h["pos"][0], y - h["pos"][1]) - (GAP[kind] + GAP[h["type"]]) / 2 for h in houses] or [1e9])

    def draw(kind, ok, tries=TRIES, around=None):
        best = None
        for _ in range(tries * 40):
            if around:
                a = rng.uniform(0.0, 2.0 * math.pi)
                rr = rng.uniform(*around[1])
                x, y = around[0][0] + rr * math.sin(a), around[0][1] + rr * math.cos(a)
            else:
                x, y = rng.uniform(BOX[0], BOX[1]), rng.uniform(BOX[2], BOX[3])
            z = float(Z(x, y))
            if not ok(x, y, z) or near(x, y, kind) < 0.0:
                continue
            s = house_site(Z, x, y, kind, blocked, placed)
            if s is None:
                continue
            score = min(near(x, y, kind), 60.0) - 0.5 * s["slope"]
            if best is None or score > best[0]:
                best = (score, s)
            tries -= 1
            if tries <= 0:
                break
        return None if best is None else best[1]

    # the two tower-houses chapter 02 places: the tulku's family house by the rim, the masons'
    for hid, nid in HOUSE_NAMED.items():
        b = recs[nid]
        s = None
        for rr in (0.0, 4.0, 8.0, 12.0, 16.0, 20.0, 25.0, 30.0):
            for k in range(12 if rr else 1):
                a = 2.0 * math.pi * k / 12.0
                s = house_site(Z, b["pos"][0] + rr * math.sin(a), b["pos"][1] + rr * math.cos(a), "C", blocked, placed)
                if s:
                    break
            if s:
                break
        if s:
            add(hid, "C", s, extra={"named": nid})
    # the four Bön households round their chapel
    bon = named.get("TOD-02", {}).get("at", list(BON))
    for k in range(4):
        s = draw("D", lambda x, y, z: True, around=(bon, BON_R))
        if s:
            add("H-TOD-%03d" % (45 + k), "D", s, extra={"bon": True})
    nums = {"C": iter(range(3, 15)), "D": iter(range(49, 65)), "A": iter(range(15, 45)), "E": iter(range(65, 69))}
    short = {}
    for kind, n in COUNTS:
        for _ in range(n):
            s = draw(kind, lambda x, y, z, kind=kind: in_zone(kind, x, y, z))
            if s is None:
                s = draw(kind, lambda x, y, z: True)  # (its zone full: anywhere in the quarter)
                short[kind] = short.get(kind, 0) + 1
            if s:
                add("H-TOD-%03d" % next(nums[kind]), kind, s)
    # the empty tower-house TOD-26, at chapter 02's place or the nearest that holds it
    b = recs["TOD-26"]
    s = None
    for rr in (0.0, 4.0, 8.0, 12.0, 16.0, 20.0, 25.0, 30.0):
        for k in range(12 if rr else 1):
            a = 2.0 * math.pi * k / 12.0
            s = house_site(Z, b["pos"][0] + rr * math.sin(a), b["pos"][1] + rr * math.cos(a), "C", blocked, placed)
            if s:
                break
        if s:
            break
    if s:
        add("TOD-26", "C", s, extra={"ruin": 1, "named": "TOD-26"})
    entries, carved, terrace = list(ENTRIES), list(CARVED), None
    if stair:  # the paths begin on the Tödé Stair's top terrace, level along the contour from its last step (TERRACE_*)
        tx, ty, tz = stair["top"]
        e_ = 2.0
        gx_ = (float(Z(tx + e_, ty)) - float(Z(tx - e_, ty))) / (2 * e_)
        gy_ = (float(Z(tx, ty + e_)) - float(Z(tx, ty - e_))) / (2 * e_)
        ux_, uy_ = -gy_, gx_  # along the contour, into Tödé (northward)
        n_ = math.hypot(ux_, uy_) or 1.0
        ux_, uy_ = (ux_ / n_, uy_ / n_) if uy_ >= 0.0 else (-ux_ / n_, -uy_ / n_)
        terrace = {"quad": rect(tx + ux_ * TERRACE_L / 2, ty + uy_ * TERRACE_L / 2, TERRACE_W, TERRACE_L, ux_, uy_), "z": tz}
        entries = [e for k_, e in enumerate(entries) if k_ > 0]  # (the forecourt's entry, before the stair, its terrace now)
    goals = list(houses)  # and the tower TOD-01 (step 3): a path to its pad's side, as to a house's; and after the houses' (step
    # 6), the Bön chapel TOD-02's terrace, the threshing floors and the mills, for their people (world/tode_people.gd)
    for nid in ("TOD-01",) + LATE:
        if nid in named:
            tw = named[nid]
            goals.append({"id": nid, "type": tw["kind"], "pos": [tw["at"][0], tw["at"][1], tw["level"]], "rot_deg": tw["facing"],
                          "pad": tw.get("pad", [tw["at"][0], tw["at"][1], tw["footprint"][0], tw["footprint"][1]])})
            if nid in LATE:
                goals[-1]["after"] = True
    lanes, ways, no_way = field_paths(Z, goals, [r for k_, r in zip(NAMED, named_rects) if k_ != "TOD-01" and k_ not in LATE], path_clear, entries, carved,
                                      terrace, late=[r for k_, r in zip(NAMED, named_rects) if k_ in LATE])
    if stair:  # the terrace itself, from the stair's last step; each way across it from the top to where it leaves
        lanes.insert(0, {"id": "TOD-P00.01", "from": [round(tx, 2), round(ty, 2)], "dir": [round(ux_, 4), round(uy_, 4)],
                         "length": TERRACE_L, "width": TERRACE_W, "z_a": round(tz, 2), "z_b": round(tz, 2), "flight": None,
                         "profile": [[0.0, round(tz, 2)], [TERRACE_L, round(tz, 2)]], "road": True, "path": True,
                         "wall_min": PATH_WALL_MIN, "terrace": True})
        quad = terrace["quad"]
        for w in ways.values():
            if _inside(quad, np.array([w[-1][0]]), np.array([w[-1][1]]))[0]:
                w.append([round(tx, 2), round(ty, 2), round(tz, 2)])
    houses.sort(key=lambda h: h["id"])
    json.dump({"about": "Tödé, the upper quarter (tools/town/tode.py; M3 sprint 4, step 1): `houses`, its 68 houses and the empty tower-house TOD-26, each [id, type C, A, D or E, variant, seed, pos (its middle and its pad's level), rot_deg (its front's bearing, down the fall line), footprint, pad (the house and its yard before it: x, y, width, depth), cut and fill (metres of the slope cut behind it and filled before it)]; `named`: its named places at chapter 02's places or the nearest ground that holds them (`moved_from`), each its level at its ground's middle; `lanes`: the field paths, each straight piece a lane (TOD-P<way>.<piece>, a house's path its own way to where it joins the paths laid before it); `ways`: each house's whole way from the side of its pad to the Tödé chorten or the garden lane's top, its points on the ground (for the routes). Regenerated with the terrain.",
               "houses": houses, "named": named, "lanes": lanes, "ways": ways}, open(OUT, "w", encoding="utf-8"), indent=1)
    by = {}
    for h in houses:
        by[h["type"]] = by.get(h["type"], 0) + 1
    if "--out" not in ARGS:
        zs = [h["pos"][2] for h in houses]
        gaps = [min(math.hypot(h["pos"][0] - o["pos"][0], h["pos"][1] - o["pos"][1]) for o in houses if o is not h) for h in houses]
        rep = ["# Tödé, the upper quarter", "",
               "_Written by `tools/town/tode.py` (M3 sprint 4, step 1; plan chapter 02, D06 and TOD-01 to TOD-26; chapter 03, 3.2, 3.5) from the ground before the pads (`valley_shaped_1m`): its houses dispersed in their fields, each on its own pad cut into the slope, and its named places._", "",
               "- %d houses: %s; the empty tower-house TOD-26 among the C." % (len(houses), ", ".join("%s %d" % kv for kv in sorted(by.items()))),
               "- From %.0f to %.0f m; the nearest neighbour %.0f m off at the least, %.0f m at the median." % (min(zs), max(zs), min(gaps), float(np.median(gaps))),
               "- Cut behind a house up to %.1f m, fill before it up to %.1f m (their podia's walls: tools/town/walls.py)." % (max(h["cut"] for h in houses), max(h["fill"] for h in houses)),
               "- Short of their zones (placed elsewhere in the quarter): %s." % (", ".join("%s %d" % kv for kv in sorted(short.items())) or "none"),
               "- The field paths: %d straight pieces, %.0f m, from the Tödé Stair's terrace at its top (or the chorten's forecourt, without the stair) to the side of every house's pad: %d ramps (%.0f m, at most %.0f%%) and %d stone flights where the slope is too steep for them (%.0f m, %d steps); the longest way %.0f m (%s); %d houses with none." % (
                   len(lanes), sum(l["length"] for l in lanes), sum(1 for l in lanes if not l.get("steps")), sum(l["length"] for l in lanes if not l.get("steps")),
                   100.0 * max(abs(l["z_b"] - l["z_a"]) / l["length"] for l in lanes if not l.get("steps") and l["length"] > 0.5),
                   sum(1 for l in lanes if l.get("steps")), sum(l["length"] for l in lanes if l.get("steps")),
                   sum(int(l["flight"]["n"]) for l in lanes if l.get("steps") and l.get("flight")),
                   max(sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(w, w[1:])) for w in ways.values()),
                   max(ways, key=lambda k: sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(ways[k], ways[k][1:]))), len(no_way)), "",
               "| Named | Kind | At | Level | Fall | Moved from |", "|---|---|---|---|---|---|"]
        for nid, n in sorted(named.items()):
            rep.append("| %s | %s | %.0f, %.0f | %.1f | %.1f | %s |" % (nid, n["kind"], n["at"][0], n["at"][1], n["level"], n["fall"],
                                                              "%.0f, %.0f" % tuple(n["moved_from"]) if "moved_from" in n else ""))
        open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("tode: %d houses (%s), %d named (%d moved); short of their zones: %s; cut up to %.1f m, fill up to %.1f m; %d path pieces, %.0f m, %d houses with no way -> %s" % (
        len(houses), ", ".join("%s %d" % kv for kv in sorted(by.items())), len(named), sum(1 for v in named.values() if "moved_from" in v),
        short or "none", max(h["cut"] for h in houses), max(h["fill"] for h in houses), len(lanes), sum(l["length"] for l in lanes), len(no_way), OUT))


if __name__ == "__main__":
    main()
