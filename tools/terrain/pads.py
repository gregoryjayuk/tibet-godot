#!/usr/bin/env python3
"""Terrain passes 4-5, pads and road beds (plan chapter 11, 8.2; chapter 03, 3.8; PLAN step 8.4).

Pass 4, pads. Each placed building of the gazetteer (data/town.json) and of the town builder (data/town_generic.json)
stands on a level pad at its height, which is
the pad's level: the stable floor, the top of the dry-stone retaining wall its plinth continues (chapter 03, 3.8; e.g.
Dechen-tsang's 2,650 m under a roof at 2,659 m, R-06). The footprint (width along the facade, depth behind it; the
facade faces rot_deg, 180 by default, so width runs east-west) is levelled with an APRON of flat ground round it, then
the ground is handed back to the slope over a BATTER, cut uphill and filled downhill; the retaining walls and terraces
are the kit's meshes, the heightfield only approximates them. Where the packed core's pads meet, the nearest one wins.
The town builder's houses (IMP-023; Greg, 7 Oct 2026: the space round the houses "not a space you could actually exist
in ... wide enough for a few people to stand around and talk"): each has a level YARD before its front, 3.4-4.6 m deep,
its own, where it meets the ground behind the house below it holding all but a narrow alley (FRONT); and its level
ground ends at a wall, not a batter: the terrain's step, a metre wide on the 1 m lattice, set into the wall's higher
side (FILL_IN, CUT_OUT), so the wall's face stands clear of it and its top hides it (tools/town/walls.py and the kit's
export_walls.py build them there). Until 7 Oct 2026 every turned pad was turned the wrong way (its frame mirrored): 103
of the 104 houses had a corner of their level ground buried, up to 4.75 m in the slope.
Left alone: what follows the ground (mani walls, bridges, stairs, fields, graves, the caravan ground's 180 m picket
lines: anything over 70 m a side), and rows with a height range.
Pass 5, road beds, for the slice (the rest of R-01, R-03, R-09 and R-22 come with their districts): the Sky Stair,
SHL-15 / R-05, from Tsongra (2,665) to the Tödé chorten (2,782) along the gazetteer's line; the ground under it is
smoothed to its even grade over its width, not stepped, since the stair is the kit's, and lowered where the stair's
treads dip under that grade (the ends of its longer landings, up to a metre) to 0.4 m under its ramps' line: the kit's
own bed, from the stair's export (assets/generated/kit/types/sky_stair_v1.json, `bed`; M1 sprint 3, step 3: at the
tunnel's top the ground had stood 0.2 m over a landing and stopped the player). Without that file, the even grade.
Pass 5b, the side lanes (tools/town/builder.py's data/town_lanes.json; M1 sprint 4, step 1): each lane's bed across its
width, level at its foot, then 0.25 m under its flight's treads (a landing in the longer ones), level at its head; no
batter, since the houses' walls and walls.py's lane walls stand at its sides, the step under them set into their higher
side as at the yards. Each flight climbs exactly from the lane's foot to its head (its own stair, the kit's
export_lanes.py, wall to wall; whole metres of the kit's lane_stair until 7 Oct 2026).
Run: tools/py tools/terrain/pads.py   Reads valley_shaped_1m.tif (horizons.py); writes valley_padded_1m.tif and
docs/terrain/pads-report.md. The check, horizon and export tools read it with VALLEY=valley_padded_1m.
"""
import json
import math
import os
import random
import sys

import numpy as np
import rasterio

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402
import arrival  # noqa: E402
import samkha  # noqa: E402
import confluence  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
REPORT = os.path.join(ROOT, "docs", "terrain", "pads-report.md")
SOURCE = os.environ.get("VALLEY", "valley_shaped_1m")
OUT = "valley_padded_1m"
APRON, BATTER = 1.5, 2.0  # metres of flat ground round a footprint, and of slope back to the ground (2 m since kit step
# K6: a dry-stone retaining wall stands on the step, tools/town/walls.py; it was 8 m of bare earth)
YARD = (3.4, 4.6)  # metres of level ground before a town house's front, each its own (IMP-023)
FRONT = 0.45  # a yard's ground counts at this much of its distance from the front where pads meet: of a 6 m gap to the
# back of the house below, the yard holds 4.1 m and leaves an alley of 1.9 m
FILL_IN, CUT_OUT = 0.5, 1.0  # the terrain's step under a wall: a fill wall's level ground ends this far inside its top's
# line (the step's toe stays behind the face, which leans out over it; the wall's paved top covers the dip), a cut wall's
# runs this far on under the earth it holds (the step behind the face, which leans back over it)
WALL_MIN = 0.4  # a step this high or more is a wall (tools/town/walls.py)
SOFT = 1.2  # but a builder's house's level ground and a neighbour's, or the slope, within this of each other meet in a
# ramp twice as wide as their step (at least 1.5 m): no wall
TALL, EXT = 1.5, 1.0  # a fill wall this high (a parapet on it: walls.py PARAPET_MIN): its level ground runs on EXT past
# its line, the terrain's step below it
JOIN = 3.5  # two builder's houses' level grounds this near the line where they meet each run on to it (a yard and the
# alley behind the house below it; not side by side along a row, where the lanes climb)
LANE_MAX = 6.0  # a side lane's width at most (the builder's gap between two groups; LN-036 had been 31.7 m)
BIGGEST = 70.0  # footprints wider than this follow the ground
# Named buildings whose kit type walls a yard before their front (sprint 4, step 2): its depth, which their pad takes too
# (the gazetteer's footprint is the house's). Shared with the town builder, the ladders and the Rooftop Way. The Mani
# Lhakhang's is its forecourt, carried at its level to the Sky Stair's east edge, where the stair's east cheek opens
# onto it (the kit's sky_stair, `openings`; sprint 4, step 3).
YARDS = {"SHL-19": 6.0, "SHL-08": 7.0, "SHL-11": 3.1}  # Pema Ö's forecourt: 5 m before its front, 1.9 of it its SIZE's
# Pads larger than the gazetteer's footprint, which is the building's (M2 sprint 5, step 4): Pema Ö with its kora corridor
# 1.9 m deep round it (the kit's kit/confluence.py KORA)
SIZE = {"SHL-11": (19.8, 17.8)}
# The barkor's mani wall, SHL-09, splitting the Mani Lane (sprint 4, step 3; chapter 02; chapter 03, 8.2): its line, from
# west to east, and the lane's width either side of it. The gazetteer's wall runs 120 m from x = -110 to +10, across the
# Sky Stair (which passes x = -7 there): it ends 2 m short of the stair's west edge, and 70 m long about the gazetteer's
# middle (x = -51) it ends at x = -86, where the Rooftop Way walks round it (94 m to x = -110, the Way lost its upper
# roofs going round the far end; 26 Sep 2026). Shared with the builder (the lane kept clear), this pass (its bed),
# walls.py (its sides), tools/town/mani.py (the wall's segments) and the Rooftop Way.
BARKOR = {"id": "SHL-09", "from": (-86.0, 95.0), "to": (-16.0, 95.0), "wall": 1.2, "lane": 3.2}


def barkor_lane(z=None, g=None):
    """The Mani Lane as a lane (lane_list's form): along the wall's line and 2 m past each end, the wall and its lane
    either side wide, its bed level across and following the ground along it (the ground on its line every 2 m, smoothed
    over 10 m), read from `z` (a raster over `g`'s window) when given."""
    (ax, ay), (bx, by) = BARKOR["from"], BARKOR["to"]
    L = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / L, (by - ay) / L
    fx, fy = ax - ux * 2.0, ay - uy * 2.0
    lane = {"id": BARKOR["id"], "from": [fx, fy], "dir": [ux, uy], "length": L + 4.0, "width": BARKOR["wall"] + 2 * BARKOR["lane"],
            "z_a": 0.0, "z_b": 0.0, "flight": None}
    if z is not None:
        ss = np.arange(0.0, L + 4.01, 2.0)
        zs = []
        for sl in ss:
            c, r = int((fx + ux * sl - g.x0) / g.res), int((g.y1 - (fy + uy * sl)) / g.res)
            zs.append(float(z[r, c]))
        zs = np.array(zs)
        k = np.ones(5) / 5.0
        sm = np.convolve(np.pad(zs, 2, mode="edge"), k, mode="valid")
        lane["profile"] = [[round(float(a), 2), round(float(b), 2)] for a, b in zip(ss, sm)]
    return lane


def footprint(b):
    """A gazetteer record's ground: (x, y, width, depth), its yard before its front included (YARDS), or its own `pad`
    (a monk's house M2 and its yard beside it: tools/town/monastery.py); with its own `apron` narrower than APRON (a
    monk's house on the cliff-dwelling face: its front the podium's edge, its back against the rock; chapter 03, 14.5's
    podia 2-6 m high), the footprint less the difference, so its level ground is the house and that apron."""
    if "pad" in b:
        x, y, w, d = (float(v) for v in b["pad"])
    else:
        x, y = float(b["pos"][0]), float(b["pos"][1])
        w, d = SIZE.get(b.get("id", ""), (float(b["footprint"][0]), float(b["footprint"][1])))
        yd = YARDS.get(b.get("id", ""), 0.0)
        if yd:
            th = math.radians(float(b.get("rot_deg", 180.0)))  # the facing; the yard lies that way
            x, y, d = x + math.sin(th) * yd / 2, y + math.cos(th) * yd / 2, d + yd
    if "apron" in b:
        k = 2.0 * (APRON - float(b["apron"]))
        w, d = max(w - k, 0.5), max(d - k, 0.5)
    return x, y, w, d
FOLLOW_GROUND = ("bridge", "crossing", "vessel", "waterfall", "chain", "gallery", "roof", "mani wall", "walls", "route",
                 "road", "steps", "trees", "graves", "open ground", "open space", "gardens", "field", "pits", "butts",
                 "range", "cairn", "flagpole", "infrastructure", "beach", "site", "camp", "display wall",
                 "gateway chorten", "covered passage")  # the last two stand on the Sky Stair's bed (kit step K6)
# Pads that stand on more than one level (chapter 02, SHL-01: "Tsongra, 40 x 30 m on two levels"; the fuel stalls,
# SHL-29, stand "on Tsongra's lower level" at 2,660): (id, [(dx, dy, width, depth, level)] from its middle). The flight
# between the levels is the kit's (world/town.gd's TSONGRA_STEPS); tools/town/walls.py puts the wall on the step.
LEVELS = {"SHL-01": [(0.0, 7.5, 40.0, 15.0, 2662.0), (0.0, -7.5, 40.0, 15.0, 2660.0)]}
# Pads not where the gazetteer has them (M2 sprint 5, step 3): the Conch terrace beside the confluence's pool rather than
# across the head of Samkha's slot (its 14 m from the gazetteer's y -90 reached the river at -95): tools/terrain/confluence.py
# The Lukhang spring's yard 5.5 m down its slope from chapter 02's point (M2 sprint 6, step 3): at its 2,775 m the
# yard is cut about 4 m into the slope at its back, where the spring rises, not 8 m
# The Gorge Rim Lookout's terrace 55 m on round the contour from chapter 02's point, onto the gorge's rim, where the notch
# opens (M2 sprint 6, step 4; tools/town/gardens.py LOOKOUT)
MOVED = {"SHL-12": confluence.TERRACE, "SHL-14": (-110.0, 234.5), "SHL-32": (258.0, 245.0)}
RAISED = {"SHL-32": 2781.5}  # its level over the gazetteer's: the Lookout built out on the rim's edge (tools/town/gardens.py END_Z)
# The Caravan Ground's yards and houses at the middle of their real ground, the fodder yard moved onto the terrace by the
# Caravan Ramp's foot, the corral and the drowned footings on the ground as it is (tools/town/caravan_ground.py; M2 sprint
# 9, step 1: chapter 02's heights had put the fodder yard on a 10 m fill and the footings in a 10 m hole)
CARAVAN_GROUND = os.path.join(ROOT, "data", "caravan_ground.json")
FOLLOW_IDS = set()
if os.path.exists(CARAVAN_GROUND):
    _cg = json.load(open(CARAVAN_GROUND, encoding="utf-8"))
    for _pid, _pd in _cg.get("pads", {}).items():
        RAISED[_pid] = float(_pd["level"])
        if "at" in _pd:
            MOVED[_pid] = tuple(_pd["at"])
    FOLLOW_IDS = set(_cg.get("follow", []))
# The Castle Ramp's yards, moved off the flank it crosses, at the middle of their ground and turned along its contour
# (tools/town/castle_ramp.py; M2 sprint 11): the ula yard SAM-09, the stables SAM-08 behind it
CASTLE_RAMP = os.path.join(ROOT, "data", "castle_ramp.json")
TURNED = {}  # a pad's facing other than the gazetteer's
if os.path.exists(CASTLE_RAMP):
    for _pid, _pd in json.load(open(CASTLE_RAMP, encoding="utf-8")).get("pads", {}).items():
        RAISED[_pid] = float(_pd["level"])
        MOVED[_pid] = tuple(_pd["at"])
        TURNED[_pid] = float(_pd["facing"])
# The porters' rest SER-19 at the Serchu road's level beside it, not at the gazetteer's place 4 m under it, open to the road
# (tools/terrain/serchu_road.py `pads`; M2 sprint 12, step 2)
SERCHU_ROAD = os.path.join(ROOT, "data", "serchu_road.json")
if os.path.exists(SERCHU_ROAD):
    for _pid, _pd in json.load(open(SERCHU_ROAD, encoding="utf-8")).get("pads", {}).items():
        RAISED[_pid] = float(_pd["level"])
        MOVED[_pid] = tuple(_pd["at"])
        TURNED[_pid] = float(_pd["facing"])
# The mills SER-05 to 08 on the Serchu's north bank on the ground where tools/town/serchu_mills.py placed them, below their
# chutes' heads with their tail yards (its lanes), not on chapter 02's pads by the water, which had dammed the river (M2
# sprint 12, step 5)
SERCHU_MILLS = os.path.join(ROOT, "data", "serchu_mills.json")
if os.path.exists(SERCHU_MILLS):
    FOLLOW_IDS |= set(m["id"] for m in json.load(open(SERCHU_MILLS, encoding="utf-8")).get("mills", []))
# Hejie's named buildings at the middle of their real ground, its generic houses (tools/town/hejie.py; M2 sprint 9, step 4)
HEJIE = os.path.join(ROOT, "data", "hejie.json")
MONASTERY = os.path.join(ROOT, "data", "monastery.json")  # the monks' houses on the spur (tools/town/monastery.py; M2 sprint 13)
TODE = os.path.join(ROOT, "data", "tode.json")  # Tödé's houses and named places (tools/town/tode.py; M3 sprint 4, step 1)
if os.path.exists(HEJIE):
    for _pid, _pd in json.load(open(HEJIE, encoding="utf-8")).get("pads", {}).items():
        RAISED[_pid] = float(_pd["level"])
# The buildings tools/town/dungrong.py places with a pad (M3 sprint 1, step 4: the Parkhang off chapter 02's 28 m of fall),
# where it stands them
DUNGRONG = os.path.join(ROOT, "data", "dungrong.json")
if os.path.exists(DUNGRONG):
    for _pid, _pd in json.load(open(DUNGRONG, encoding="utf-8")).get("places", {}).items():
        if _pd.get("pad"):
            RAISED[_pid] = float(_pd["level"])
            MOVED[_pid] = tuple(_pd["at"])
            TURNED[_pid] = float(_pd["facing"])
            if "yard" in _pd:  # (the Parkhang's forecourt before its south gate: M3 sprint 6, step 6)
                YARDS[_pid] = float(_pd["yard"])
# Dungkar Gönpa's halls at the middle of their own ground; the thangka terrace on the slope (tools/town/monastery.py; M2
# sprint 13, step 2)
if os.path.exists(MONASTERY):
    _mo = json.load(open(MONASTERY, encoding="utf-8"))
    for _pid, _pd in _mo.get("pads", {}).items():
        RAISED[_pid] = float(_pd["level"])
        if "moved_from" in _pd:  # (the tantric college off its fall)
            MOVED[_pid] = tuple(_pd["at"])
        if float(_pd["facing"]) != 180.0:  # (the gates, facing out down their ways: the East Gate's range padded as a building)
            TURNED[_pid] = float(_pd["facing"])
        if "yard" in _pd:  # (the colleges' porticoes and forecourts: M3 sprint 3, step 2)
            YARDS[_pid] = float(_pd["yard"])
    FOLLOW_IDS |= set(_mo.get("follow", []))
# Tödé's named places at the middle of their own ground, moved where chapter 02's place would not hold them (tools/town/tode.py;
# M3 sprint 4, step 1)
if os.path.exists(TODE):
    for _pid, _pd in json.load(open(TODE, encoding="utf-8")).get("named", {}).items():
        RAISED[_pid] = float(_pd["level"])
        if "moved_from" in _pd:
            MOVED[_pid] = tuple(_pd["at"])
STAIRS = [  # (id, from (x, y, z), to (x, y, z), width, the kit's export with its bed, metres of level ground past its top)
    ("SHL-15 Sky Stair (R-05)", (0.0, 15.0, 2665.0), (-20.0, 255.0, 2782.0), 4.0, "sky_stair_v1", 9.0),
    # Pema Ö's steps (M2 sprint 5, step 4): from the Conch terrace up 6 m to the temple's forecourt, facing 140 degrees
    # (tools/town/gazetteer.py FACINGS): the kit's 40 steps of 0.4025 m from 28.1 m to 12 m before its middle (165, -55),
    # 3.6 m wide and its cheeks (kit/confluence.py STAIR_*, STAIR_FOOT, STAIR_TOP)
    ("SHL-11 Pema Ö's steps", (165.0 + 28.1 * math.sin(math.radians(140.0)), -55.0 + 28.1 * math.cos(math.radians(140.0)), 2664.0),
     (165.0 + 12.0 * math.sin(math.radians(140.0)), -55.0 + 12.0 * math.cos(math.radians(140.0)), 2670.0), 4.3, "sh11_pema_o_v1", 0.5),
    # R-08, Nétsang Lam, its last leg (M2 sprint 5, step 7): down an even ramp from the slope west of Pema Ö into its
    # forecourt's west end, which the pad had cut 3.5 m into the slope (no kit: the ground itself, 15 degrees)
    ("R-08 down to Pema Ö's forecourt", (162.4, -69.6, 2670.0), (149.0, -69.6, 2673.6), 3.2, "none", 1.0),
    # The lingkor's west side up the western mani wall SHL-10 (M2 sprint 6, step 6; chapter 02: "the lingkor's west side",
    # R-25 beside it, the wall on the right going up): an even 25-degree bed straight up the slope from the west edge for
    # 260 m at 352 degrees, the barkor's width (a 1.2 m wall in its sections down its middle, tools/town/mani.py west_wall,
    # and 3.2 m either side: up the west, down the east); the real slope there is 37-54 degrees, steeper than chapter
    # 02's line (2,620-2,780 m over 260 m) can take as a way
    ("SHL-10 the lingkor's west side", (-320.0, 62.0, 2624.0), (-356.19, 319.47, 2745.9), 7.6, "none", 2.0),
]
KIT = os.path.join(ROOT, "assets", "generated", "kit", "types")


def smoothstep(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


_yards = None


def yards():
    """{pad id: its yard's depth before its front}: the town builder's houses (data/town_generic.json), each its own
    (or the one it gives, `yard`), but the Rooftop Way's start, whose front is on the lane behind Dechen-tsang's compound
    (R-06); a named building has none (its own design: YARDS, LEVELS)."""
    global _yards
    if _yards is None:
        _yards = {}
        path = os.path.join(ROOT, "data", "town_generic.json")
        if os.path.exists(path):
            for h in json.load(open(path, encoding="utf-8"))["houses"]:
                if "yard" in h:  # a yard of its own depth (Samkha's: Castle Lane's two rows face each other across it)
                    _yards[h["id"]] = float(h["yard"])
                elif "way" not in h:
                    _yards[h["id"]] = round(random.Random(h["id"] + ":yard").uniform(*YARD), 2)
    return _yards


def frame(rot, X, Y):
    """Points (X, Y from a pad's middle, the town grid) in the pad's frame: u along its front, v behind it (its front at
    v = -depth/2), as the kit builds a house facing -v and world/town.gd turns it."""
    th = math.radians(rot - 180.0)
    c, s = math.cos(th), math.sin(th)
    return X * c - Y * s, X * s + Y * c


def pad_dist(fw, fd, yd, u, v):
    """(d, p, s) for points (u, v) in a pad's frame: d, how far beyond its level ground plus the APRON (the level ground
    is d <= APRON: the footprint, the apron round it and the yard `yd` deep before its front); p, how near the pad counts
    where pads meet (a yard's ground at FRONT of its distance from the front); s, how fast p grows away from the pad."""
    ex = np.maximum(np.abs(u) - fw / 2, 0.0)
    front = -v - fd / 2
    back = np.maximum(v - fd / 2, 0.0)
    if yd <= 0.0:
        d = np.hypot(ex, np.maximum(front, back))
        return d, d, np.ones_like(d)
    before = front > 0.0
    d = np.hypot(ex, np.where(before, np.maximum(front - (yd - APRON), 0.0), back))
    ep = np.where(before, front * FRONT, back)
    p = np.hypot(ex, ep)
    grad = np.hypot(ex, np.where(before, FRONT * FRONT * front, back))
    s = np.where(p > 1e-6, grad / np.maximum(p, 1e-6), 1.0)
    return d, p, s


RUN, RISER = 0.25, 0.2  # a lane flight's tread and riser (its risers exact: its rise in whole steps of about 0.2 m)
TOP_LANDING, MID_LANDING = 0.6, 1.2  # the landing on its top step, and halfway up a long one


def lane_flight(lid, L, z_a, z_b):
    """A side lane's flight, `L` metres long from its foot at z_a to its head at z_b: its first riser `s` metres up the
    lane, `n` risers of exactly its rise over n, its top step at the head with a landing of 0.6 m on it, a landing of
    1.2 m after `landing` risers halfway up a flight of 24 or more where the lane has room; its own stair, the kit's
    export_lanes.py (`file`). None for a lane under 0.3 m of rise (level), False where no flight fits (over 10.5 m, or
    longer than the lane)."""
    rise = z_b - z_a
    if rise < 0.3:
        return None
    n = max(2, int(round(rise / RISER)))
    run = n * RUN + TOP_LANDING
    mid = None
    if n >= 24 and L - run - (MID_LANDING - RUN) >= 0.5:
        mid = n // 2
        run += MID_LANDING - RUN
    if rise > 10.5 or L - run < 0.5:
        return False
    return {"file": "lane_%s" % lid, "s": round(L - run, 2), "rise": round(rise, 2), "z": round(z_a, 2), "n": n, "landing": mid}


def flight_steps(f):
    """A lane flight's steps up the lane: [(s0, s1, top)], the last its top step with the landing on it."""
    n = f.get("n") or int(round(f["rise"] / RISER))
    r = f["rise"] / n
    out, s = [], f["s"]
    for i in range(n):
        wd = RUN + TOP_LANDING if i == n - 1 else (MID_LANDING if f.get("landing") and i == f["landing"] - 1 else RUN)
        out.append((s, s + wd, f["z"] + (i + 1) * r))
        s += wd
    return out


def pad_list(window=(-1350.0, 2300.0, -1100.0, 1100.0)):
    """The pads: (id, x, y, level, width, depth, facing) for every placed building of the gazetteer and the town builder
    that stands on its own level (the rest follow the ground). Shared with tools/town/walls.py."""
    x0, x1, y0, y1 = window
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    generic = os.path.join(ROOT, "data", "town_generic.json")  # the town builder's houses (tools/town/builder.py)
    if os.path.exists(generic):
        town["buildings"] = town["buildings"] + json.load(open(generic, encoding="utf-8"))["houses"]
    if os.path.exists(HEJIE):  # and Hejie's (tools/town/hejie.py)
        town["buildings"] = town["buildings"] + json.load(open(HEJIE, encoding="utf-8"))["houses"]
    if os.path.exists(MONASTERY):  # and Dungkar Gönpa's monks' houses and khamtsen (tools/town/monastery.py; M2 sprint 13)
        _m = json.load(open(MONASTERY, encoding="utf-8"))
        town["buildings"] = town["buildings"] + _m["houses"] + _m.get("buildings", [])
    if os.path.exists(TODE):  # and Tödé's houses, each on its own pad, the gazetteer's records of the three it names left out;
        # its named places with no footprint in the gazetteer (the tower, the threshing floors) given theirs (tools/town/tode.py)
        _t = json.load(open(TODE, encoding="utf-8"))
        _named = {h["named"] for h in _t["houses"] if h.get("named")}
        _fp = {b["id"] for b in town["buildings"] if b.get("footprint")}
        town["buildings"] = [b for b in town["buildings"] if b["id"] not in _named] + _t["houses"] + [
            {"id": k, "type": v["kind"], "pos": [v["at"][0], v["at"][1], v["level"]], "footprint": v["pad"][2:] if "pad" in v else v["footprint"],
             "rot_deg": 180.0} for k, v in _t.get("named", {}).items() if k not in _fp]  # (its pad's size where larger: the tower's,
        # its log's foot 6 m out before its door; M3 sprint 4, step 3)
    pads = []
    for b in town["buildings"]:
        p, fp = b.get("pos"), b.get("footprint")
        if not p or p[2] is None or not fp or "z_range" in b or "line" in b:
            continue
        if (any(k in b["type"] for k in FOLLOW_GROUND) and b["id"] not in TURNED) or max(fp) > BIGGEST or b["id"] in FOLLOW_IDS:
            continue  # (a pad the Castle Ramp placed stands on its own level whatever its type: the stables' range)
        if fp[0] * fp[1] < 10.0:  # a fixture on a square or by a lane (Tsongra's basin): it stands on the ground there
            continue
        if not (x0 + 50 < p[0] < x1 - 50 and y0 + 50 < p[1] < y1 - 50):
            continue
        if b["id"] in LEVELS:  # a pad in levels: one pad a level (square to the grid: no such pad is turned)
            for k, (dx, dy, lw, ld, lz) in enumerate(LEVELS[b["id"]]):
                pads.append(("%s.%d" % (b["id"], k + 1), float(p[0]) + dx, float(p[1]) + dy, lz, lw, ld, 180.0))
            continue
        fx, fy, fw, fd = footprint(b)
        if b["id"] in MOVED:  # its new place, its yard still before its front (until 11 Oct 2026 the moved place was the
            # pad's middle, so a moved building's yard lay half behind it: the colleges' forecourts hung over the slope)
            mx, my = MOVED[b["id"]]
            fx, fy = mx + (fx - float(p[0])), my + (fy - float(p[1]))
        pads.append((b["id"], fx, fy, RAISED.get(b["id"], float(p[2])), fw, fd, TURNED.get(b["id"], float(b.get("rot_deg", 180.0)))))

    return pads


def lane_list(barkor=False):
    """The builder's side lanes (data/town_lanes.json), or none; with `barkor`, the Mani Lane after them as this pass cut
    it (assets/generated/terrain/barkor_lane.json)."""
    path = os.path.join(ROOT, "data", "town_lanes.json")
    lanes = json.load(open(path, encoding="utf-8"))["lanes"] if os.path.exists(path) else []
    bpath = os.path.join(GEN, "barkor_lane.json")
    if barkor and os.path.exists(bpath):
        lanes = lanes + [json.load(open(bpath))]
    return lanes


def ramp_lanes():
    """Samkha's ramps (SAM-06; the north M1 sprint 6, step 5, the south M2 sprint 3, step 1): their approaches, legs and
    landings as lanes with profiles (tools/town/north_ramp.py's data/north_ramp.json, south_ramp.py's south_ramp.json),
    carved as the Mani Lane is; and the garden lane's (gardens.json), the Caravan Ramp's (caravan_ground.json) and Hejie's
    River Street (hejie.json), the Castle Ramp's (castle_ramp.json), the Serchu road's last kilometre (serchu_road.json); or
    none."""
    out = []
    for name in ("north_ramp.json", "south_ramp.json", "gardens.json", "caravan_ground.json", "hejie.json", "castle_ramp.json",
                 "serchu_road.json", "serchu_mills.json", "dungrong.json", "gorge_stair.json", "gonpa_ways.json", "monastery.json",
                 "tode.json", "tode_stair.json", "tode_leat.json", "tode_things.json", "gonkor.json"):  # and the lane to the Gorge Rim Lookout (M2 sprint 6, step 4), the
        # Caravan Ramp (M2 sprint 9, step 1), River Street (step 4), the Castle Ramp (M2 sprint 11, step 1), R-01 from the
        # Serchu Zampa (M2 sprint 12), the north bank's leat, paths and the Yak Road's foot (M2 sprint 12, step 5), the 1,080
        # steps' flights and landings (M3 sprint 1), the Gorge Stair's (M3 sprint 2), the monastery's way up from the South Gate
        # (M3 sprint 3, step 1), the Gönkor's south stretch along its wheel galleries (step 6: tools/town/monastery.py), Tödé's
        # field paths (M3 sprint 4, step 1: tools/town/tode.py), the Tödé Stair up to them (step 2: tools/town/tode_stair.py)
        # and Tödé's leat's shelf, channels and the mills' tail yards (step 4: tools/town/tode_leat.py), and the Bön chapel's
        # circuit R-24 paved on its terrace (step 6: tools/town/tode_things.py), and the Gönkor round the monastery, its
        # flights, landings, shelves and its gallery on the gorge face (M3 sprint 7, step 1: tools/town/gonkor.py)
        path = os.path.join(ROOT, "data", name)
        if os.path.exists(path):
            out += json.load(open(path, encoding="utf-8")).get("lanes", [])
    return out


YARD_STEP_MAX = 3.6  # the most a flight between two yards climbs (18 risers); higher, a wall alone
YARD_LANE_W = 1.3  # its width


def yard_lanes(pads, yds, lanes):
    """The flights between yards (IMP-023), each a short lane of its own (`kind` "yard"): where two houses side by side
    (touching, or a slot of an alley between) have yards SOFT to YARD_STEP_MAX apart, a flight along the row from the
    lower yard up through the wall between them into the higher, its risers astride the line where the yards meet,
    halfway out across the stretch where both yards are level at its two ends; and where the higher of a side lane's two
    houses stands that much over the lane's foot, one from the lane up into its yard the same way. Clear of every house's
    footprint and of what stands on the ground by it (an outside stair), and of the side lanes' bands; where none fits,
    the wall alone."""
    sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
    import builder as B  # (lazy: they import this module)
    import ladders as LD
    houses = {h["id"]: h for h in json.load(open(os.path.join(ROOT, "data", "town_generic.json"), encoding="utf-8"))["houses"]}
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    blocks = [B.rect(h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1], h["rot_deg"], 0.3) for h in houses.values()]
    for b in town["buildings"]:
        p, fp = b.get("pos"), b.get("footprint")
        if p and fp and "line" not in b and max(fp) <= BIGGEST:
            blocks.append(B.rect(*footprint(b), b.get("rot_deg", 180.0), 0.3))
    for h in houses.values():  # its outside stair and the like, grown by a walker's room
        side = os.path.join(KIT, LD.kit_file(h) + ".json")
        if os.path.exists(side):
            th = math.radians(h["rot_deg"] - 180.0)
            c, s_ = math.cos(th), math.sin(th)
            for gb in json.load(open(side)).get("ground", []):
                blocks.append([(h["pos"][0] + u * c + v * s_, h["pos"][1] - u * s_ + v * c)
                               for u, v in ((gb[0] - 0.4, gb[1] - 0.4), (gb[2] + 0.4, gb[1] - 0.4), (gb[2] + 0.4, gb[3] + 0.4), (gb[0] - 0.4, gb[3] + 0.4))])
    bands = [B.rect(ln["from"][0] + ln["dir"][0] * ln["length"] / 2, ln["from"][1] + ln["dir"][1] * ln["length"] / 2,
                    ln["width"], ln["length"] + 1.0, math.degrees(math.atan2(ln["dir"][0], ln["dir"][1]))) for ln in lanes]
    by_id = {q[0]: q for q in pads}
    near = {q[0]: [o for o in pads if o is not q and math.hypot(o[1] - q[1], o[2] - q[2]) < 30.0] for q in pads if q[0] in yds}
    out = []

    def pd(q, x, y):
        u, v = frame(q[6], np.array([x - q[1]]), np.array([y - q[2]]))
        d, p, _ = pad_dist(q[4], q[5], yds.get(q[0], 0.0), u, v)
        return float(p[0]), float(d[0])

    def level(q, x, y):
        """Whether the pass draws (x, y) on q's level ground: q holds it first, and not within FILL_IN of its edge."""
        p, d = pd(q, x, y)
        return d <= APRON - FILL_IN and all(pd(o, x, y)[0] >= p for o in near[q[0]])

    def in_band(ln, x, y, shrink=0.3):
        sl = (x - ln["from"][0]) * ln["dir"][0] + (y - ln["from"][1]) * ln["dir"][1]
        lat = -(x - ln["from"][0]) * ln["dir"][1] + (y - ln["from"][1]) * ln["dir"][0]
        return -0.5 <= sl <= ln["flight"]["s"] - 0.3 if ln.get("flight") else -0.5 <= sl <= ln["length"], abs(lat) <= ln["width"] / 2 - shrink

    def add(z_lo, hi, foot, d, n, skip=None, between=None):
        L = 0.5 + n * RUN + TOP_LANDING
        lid = "YL-%03d" % (len(out) + 1)
        mx, my = foot[0] + d[0] * L / 2, foot[1] + d[1] * L / 2
        band = B.rect(mx, my, YARD_LANE_W + 0.2, L, math.degrees(math.atan2(d[0], d[1])))
        if any(B.overlap(band, q) for q in blocks) or any(B.overlap(band, q) for k, q in enumerate(bands) if k != skip):
            return False
        f = lane_flight(lid, L, z_lo, hi[3])
        if not f:
            return False
        out.append({"id": lid, "kind": "yard", "from": [round(foot[0], 2), round(foot[1], 2)], "dir": [round(d[0], 4), round(d[1], 4)],
                    "length": round(L, 2), "width": YARD_LANE_W, "z_a": round(z_lo, 2), "z_b": round(hi[3], 2), "flight": f,
                    "between": between})
        bands.append(band)
        return True

    def place(ends_ok, ts):
        """The middle of the longest run of distances out where both ends are level; None under 1.5 m of them."""
        best, cur = [], []
        for t in ts:
            if ends_ok(t):
                cur.append(t)
                if len(cur) > len(best):
                    best = list(cur)
            else:
                cur = []
        return best[len(best) // 2] if best and abs(best[-1] - best[0]) >= 1.5 else None

    ids = sorted(q for q in yds if q in by_id)
    late = {hid for hid, h in houses.items() if h.get("quarter") == "shol.nub"}  # the west edge's, a later pass (builder.py)

    def pair(a, b):
        """A flight between two yards side by side in a row, one a step above the other."""
        A, Bq = by_id[a], by_id[b]
        dzab = abs(A[3] - Bq[3])
        if not (SOFT <= dzab <= YARD_STEP_MAX) or math.hypot(A[1] - Bq[1], A[2] - Bq[2]) > 16.0:
            return
        lo, hi = (A, Bq) if A[3] < Bq[3] else (Bq, A)
        ub, vb = (float(w_[0]) for w_ in frame(lo[6], np.array([hi[1] - lo[1]]), np.array([hi[2] - lo[2]])))
        if abs(vb) > 3.0 or abs(ub) - (lo[4] + hi[4]) / 2 > 2.5:
            return  # not side by side in a row (a lane's gap or more: the lane's own, below)
        th = math.radians(lo[6] - 180.0)
        c, s_ = math.cos(th), math.sin(th)
        sg = 1.0 if ub > 0 else -1.0
        d = (c * sg, -s_ * sg)
        n = max(2, int(round(dzab / RISER)))
        back, ahead = 0.5 + n * RUN / 2, n * RUN / 2 + TOP_LANDING

        def meet(t):
            """Where the two yards meet at t before lo's front."""
            on = lambda u: (lo[1] + u * c - (lo[5] / 2 + t) * s_, lo[2] - u * s_ - (lo[5] / 2 + t) * c)
            u0, u1 = 0.0, ub
            for _ in range(24):
                um = (u0 + u1) / 2
                if pd(lo, *on(um))[0] < pd(hi, *on(um))[0]:
                    u0 = um
                else:
                    u1 = um
            return on((u0 + u1) / 2)

        def ends_ok(t):
            m = meet(t)
            return level(lo, m[0] - d[0] * (back + 0.3), m[1] - d[1] * (back + 0.3)) and level(hi, m[0] + d[0] * (ahead + 0.3), m[1] + d[1] * (ahead + 0.3)) \
                and level(lo, m[0] - d[0] * 0.6, m[1] - d[1] * 0.6)
        t = place(ends_ok, np.arange(0.9, max(yds[lo[0]], yds[hi[0]]) + 0.5, 0.1))
        if t is not None:
            m = meet(t)
            add(lo[3], hi, (m[0] - d[0] * back, m[1] - d[1] * back), d, n, between=[lo[0], hi[0]])

    for i, a in enumerate(ids):  # (the west edge's after the lanes' below: the flights before them keep their ids)
        for b in ids[i + 1:]:
            if a not in late and b not in late:
                pair(a, b)
    for k, ln in enumerate(lanes):  # from a side lane's foot up into its higher house's yard
        if ln.get("kind") == "yard" or ln.get("between", [None])[0] not in by_id:
            continue
        for hid in ln["between"]:
            hi = by_id.get(hid)
            if hi is None or hid not in yds or not (SOFT <= hi[3] - ln["z_a"] <= YARD_STEP_MAX):
                continue
            (fx, fy), (ux, uy), W = ln["from"], ln["dir"], ln["width"]
            lx, ly = -uy, ux
            if (hi[1] - fx) * lx + (hi[2] - fy) * ly < 0:
                lx, ly = uy, -ux
            n = max(2, int(round((hi[3] - ln["z_a"]) / RISER)))
            inside = min(n * RUN / 2, W / 2 - 0.9)  # how much of the flight stands in the lane
            ahead = n * RUN - inside + TOP_LANDING

            def at(sy, e):
                return fx + ux * sy + lx * (W / 2 + e), fy + uy * sy + ly * (W / 2 + e)

            def ends_ok(sy):
                fx_, fy_ = at(sy, -inside - 0.5)
                along, across = in_band(ln, fx_, fy_)
                return along and across and level(hi, *at(sy, ahead + 0.3))
            sy = place(ends_ok, np.arange(1.2, -5.0, -0.1))  # from just before the fronts outwards
            if sy is not None:
                add(ln["z_a"], hi, at(sy, -inside - 0.5), (lx, ly), n, skip=k, between=["lane " + ln["id"], hid])
    for k, ln in enumerate(lanes):  # from a side lane's head, where it ends in the open, up into a yard beside it (ISS-115:
        # LN-002 ended 3.5 m under H-SHL-022's yard, and that terrace of three houses reached the town by no way at all)
        if ln.get("kind") in ("yard", "mouth") or ln.get("head") or not ln.get("flight"):
            continue
        (fx, fy), (ux, uy), W, Lh = ln["from"], ln["dir"], ln["width"], ln["length"]
        hx, hy = fx + ux * Lh, fy + uy * Lh
        best = None
        for hid in yds:
            hi = by_id.get(hid)
            if hi is None or not (SOFT <= hi[3] - ln["z_b"] <= YARD_STEP_MAX) or math.hypot(hi[1] - hx, hi[2] - hy) > 14.0:
                continue
            n = max(2, int(round((hi[3] - ln["z_b"]) / RISER)))
            L = 0.5 + n * RUN + TOP_LANDING
            for back in np.arange(0.4, 1.61, 0.2):  # its foot on the lane's top landing
                for lat in np.arange(-(W / 2 - 0.9), W / 2 - 0.9 + 1e-6, 0.3):
                    ft = (hx - ux * back - uy * lat, hy - uy * back + ux * lat)
                    for a in np.radians(np.arange(0.0, 360.0, 5.0)):
                        d = (math.sin(a), math.cos(a))
                        if d[0] * ux + d[1] * uy < -0.2 or not level(hi, ft[0] + d[0] * (L + 0.3), ft[1] + d[1] * (L + 0.3)):
                            continue  # not back down the lane; its top on the yard
                        band = B.rect(ft[0] + d[0] * L / 2, ft[1] + d[1] * L / 2, YARD_LANE_W + 0.2, L, math.degrees(math.atan2(d[0], d[1])))
                        if any(B.overlap(band, q) for q in blocks) or any(B.overlap(band, q) for kk, q in enumerate(bands) if kk != k):
                            continue
                        score = L + 0.5 * abs(lat) + back  # the shortest, from the lane's middle and its very top
                        if best is None or score < best[0]:
                            best = (score, hi, ft, d, n, hid)
        if best is not None:
            _, hi, ft, d, n, hid = best
            add(ln["z_b"], hi, ft, d, n, skip=k, between=["lane " + ln["id"], hid])
    for i, a in enumerate(ids):  # the west edge's yards (builder.py's later pass), numbered after all the town's before them
        for b in ids[i + 1:]:
            if a in late or b in late:
                pair(a, b)
    return out


MOUTH_W = 3.0  # a mouth flight's width at most


def mouth_lanes(lanes, z_of, feet_q):
    """The flights down from the side lanes' mouths (IMP-023): a side lane's foot lies level with its two houses' yards,
    whose fronts are walls over the slope or the alleys below; where the ground before its mouth lies SOFT or more under
    it, a flight continues the lane down through the yards' wall to that ground, on the lane's axis, as wide as the lane
    (at most MOUTH_W), set into the wall (each a short lane of its own, `kind` "mouth"). Without it the lane's mouth was a
    ramp of a metre in a metre (the Rooftop Way stalled on one). Clear of every house's footprint and the other lanes'
    bands; where the ground before it rises again (an alley's floor, a pit), none."""
    sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
    import builder as B
    out = []
    bands = [B.rect(ln["from"][0] + ln["dir"][0] * ln["length"] / 2, ln["from"][1] + ln["dir"][1] * ln["length"] / 2,
                    ln["width"], ln["length"] + 1.0, math.degrees(math.atan2(ln["dir"][0], ln["dir"][1]))) for ln in lanes]
    for k, ln in enumerate(lanes):
        if ln.get("kind"):
            continue
        (fx, fy), (ux, uy) = ln["from"], ln["dir"]
        at = lambda sl: (fx + ux * sl, fy + uy * sl)
        z_low = z_of(*at(-4.5))
        if ln["z_a"] - z_low < SOFT:
            continue
        s_m = -4.5
        for _ in range(4):  # where the flight's foot lands, and the ground's height there
            n = max(2, int(round((ln["z_a"] - z_low) / RISER)))
            L = 0.5 + n * RUN + TOP_LANDING
            s_m = -0.5 - L
            z_low = z_of(*at(s_m - 0.4))
        if ln["z_a"] - z_low < SOFT or ln["z_a"] - z_low > 10.5:
            continue
        if any(z_of(*at(s_m - e)) > z_low + 0.6 for e in (1.0, 2.0)):
            continue  # the ground before its foot rises again: a pit, not a way on
        W = min(ln["width"], MOUTH_W)
        mx, my = at(s_m + L / 2)
        band = B.rect(mx, my, W + 0.2, L, math.degrees(math.atan2(ux, uy)))
        if any(B.overlap(band, q) for q in feet_q) or any(B.overlap(band, q) for j, q in enumerate(bands) if j != k):
            continue
        lid = "ML-%03d" % (len(out) + 1)
        f = lane_flight(lid, L, z_low, ln["z_a"])
        if not f:
            continue
        fx_, fy_ = at(s_m)
        out.append({"id": lid, "kind": "mouth", "from": [round(fx_, 2), round(fy_, 2)], "dir": [ux, uy], "length": round(L, 2),
                    "width": round(W, 2), "z_a": round(z_low, 2), "z_b": ln["z_a"], "flight": f, "between": ["below", ln["id"]]})
        bands.append(band)
    return out


def lane_bed(ln, s):
    """A side lane's bed at s metres up it: level at its foot, 0.25 m under its flight's risers' feet (level under its
    landing), level at its head; or a lane with a profile (the Mani Lane), its profile."""
    s = np.asarray(s, float)
    if "profile" in ln:
        prof = np.array(ln["profile"])
        return np.interp(s, prof[:, 0], prof[:, 1])
    f = ln["flight"]
    if not f:
        return np.full(s.shape, ln["z_a"])
    steps = flight_steps(f)
    r = f["rise"] / len(steps)
    xs, zs = [], []
    for s0, s1, top in steps:  # under each step's front, a riser and 0.25 m under its tread; under a landing's back, just
        # under its flags (the walkers' ground there: tools/town/graph.py)
        xs.append(s0)
        zs.append(top - r - 0.25)
        if s1 - s0 > RUN + 0.01:
            xs += [s0 + RUN, s0 + RUN + 0.05, s1 - 0.05]
            zs += [top - r - 0.25, top - 0.1, top - 0.1]
    xs.append(steps[-1][1])
    zs.append(ln["z_b"] - 0.1)
    return np.clip(np.maximum(np.interp(s, xs, zs, left=ln["z_a"], right=ln["z_b"]), ln["z_a"]), None, ln["z_b"])


def main():
    site = Site.load()
    shift = site.shift
    g = site.read(os.path.join(GEN, SOURCE + ".tif"))
    z = g.a - shift  # design altitude
    h, w = z.shape
    pads = pad_list((g.x0, g.x1, g.y0, g.y1))

    # The nearest pad at every cell near one, and the next nearest (how near: p, pad_dist's), each with its level, its d
    # and whether it is a builder's house (its ground a yard, sharp-edged: `sharp`).
    yds = yards()
    INF = np.float32(np.inf)
    bp, bz, bd, bs = np.full((h, w), INF), np.zeros((h, w), np.float32), np.full((h, w), INF), np.ones((h, w), np.float32)
    sp, sz, sd, ss = np.full((h, w), INF), np.zeros((h, w), np.float32), np.full((h, w), INF), np.ones((h, w), np.float32)
    bsharp, ssharp = np.zeros((h, w), bool), np.zeros((h, w), bool)
    bside, sside = np.zeros((h, w), bool), np.zeros((h, w), bool)  # beside the pad's footprint or off its corners
    feet = np.zeros((h, w), bool)  # on a footprint (for pass 5b: a lane's bed never cuts under a house)
    rows = []
    for pid, px, py, pz, fw, fd, rot in pads:
        yd = yds.get(pid, 0.0)
        r = math.hypot(fw / 2, fd / 2 + max(yd, 0.0)) + APRON + BATTER + 1.0
        c0, c1 = int((px - r - g.x0) / g.res), int((px + r - g.x0) / g.res) + 1
        r0, r1 = int((g.y1 - (py + r)) / g.res), int((g.y1 - (py - r)) / g.res) + 1
        c0, r0 = max(c0, 0), max(r0, 0)
        cx = g.x0 + (np.arange(c0, min(c1, w)) + 0.5) * g.res
        cy = g.y1 - (np.arange(r0, min(r1, h)) + 0.5) * g.res
        X, Y = np.meshgrid(cx - px, cy - py)
        u, v = frame(rot, X, Y)
        d, p, s = (a.astype(np.float32) for a in pad_dist(fw, fd, yd, u, v))
        sub = (slice(r0, r0 + len(cy)), slice(c0, c0 + len(cx)))
        inside = (np.abs(u) <= fw / 2) & (np.abs(v) <= fd / 2)
        feet[sub] |= inside
        natural = z[sub]
        rows.append((pid, px, py, pz, float(np.max(natural[inside] - pz)) if inside.any() else 0.0,
                     float(np.max(pz - natural[inside])) if inside.any() else 0.0))
        first = p < bp[sub]
        second = ~first & (p < sp[sub])
        side = np.abs(u) > fw / 2  # beside it, or off its corners: no join (a yard's corner had joined a stray terrace onto the slope)
        for dst, old, new in ((sp, bp, p), (sz, bz, pz), (sd, bd, d), (ss, bs, s), (ssharp, bsharp, yd > 0.0), (sside, bside, side)):
            dst[sub] = np.where(first, old[sub], np.where(second, new, dst[sub]))
        for dst, new in ((bp, p), (bz, pz), (bd, d), (bs, s), (bsharp, yd > 0.0), (bside, side)):
            dst[sub] = np.where(first, new, dst[sub])
    nat = z.copy()
    # A named building's pad as before: level on its footprint and apron, handed back to the slope over the batter.
    wgt = 1.0 - smoothstep(APRON, APRON + BATTER, bd)
    soft = np.where(np.isfinite(bd), nat * (1.0 - wgt) + bz * wgt, nat)
    # A builder's house's: level to its edge, where a wall stands (walls.py); the step on the wall's higher side. Inside
    # the level ground, the nearer edge is the next pad's (where it holds its own level ground there) or the slope's;
    # within FILL_IN of one lower by a wall, the ground is the lower side's. Two pads within SOFT of each other meet in
    # a ramp, no wall (a neighbour's yard a little higher or lower). Outside the level ground, the slope, but where it
    # stands higher by a wall within CUT_OUT: there the level ground runs on under the cut wall.
    e_nat = APRON - bd
    with np.errstate(invalid="ignore"):
        e_two = np.where(np.isfinite(sp), (sp - bp) / (bs + ss), INF)
        # Two builder's houses whose level grounds come within JOIN of the line where they meet each run level to it
        # (an alley floor up to the yard's wall over it, not a bank of the slope between them).
        joined = bsharp & ssharp & ~bside & ~sside & (e_two - e_nat <= JOIN) & (sd - e_two <= APRON + JOIN)
    to_two = ((e_two < e_nat) & (sd - e_two <= APRON)) | joined
    on_lvl = (bd <= APRON) | joined
    other = np.where(to_two, sz, nat)
    edge = np.where(to_two, e_two, e_nat)
    dz = np.abs(bz - other)
    ramp = bz + (other - bz) * 0.5 * (1.0 - smoothstep(0.0, np.maximum(0.75, dz), edge))
    # over a drop of TALL or more (a parapet's: walls.py), the level ground runs on EXT past the wall's line instead, the
    # step's toe banked against its face below (the game's terrain averages its vertices over a metre: shrunk, the yard
    # had dipped two metres back from its parapet)
    # under SOFT, to the slope as to a neighbour: a ramp, no wall (a low wall cut a yard off from the ground beside it)
    ramp_nat = bz + (other - bz) * (1.0 - smoothstep(0.0, np.maximum(0.75, dz), edge))
    in_lvl = np.where(dz < SOFT, np.where(to_two, ramp, ramp_nat),
                      np.where(bz > other, np.where((dz < TALL) & (edge < FILL_IN), other, bz),
                               np.where(to_two & (dz >= TALL) & (edge < EXT), other, bz)))
    two_soft = nat * smoothstep(APRON, APRON + BATTER, sd) + sz * (1.0 - smoothstep(APRON, APRON + BATTER, sd))
    out_lvl = np.where(sd <= APRON, np.where((bz - sz >= TALL) & (bd - APRON < EXT), bz, sz),
                       np.where(np.isfinite(sd) & ~ssharp & (sd < APRON + BATTER), two_soft,
                                np.where((nat > bz + SOFT) & (bd - APRON < CUT_OUT), bz,
                                         np.where((bz - nat >= TALL) & (bd - APRON < EXT), bz, nat))))
    z = np.where(bsharp, np.where(on_lvl, in_lvl, out_lvl), soft).astype(np.float32)
    yard_cells = int(np.sum(bsharp & on_lvl))

    # The Sky Stair's bed: its even grade across its width, handed back to the ground over the batter.
    beds = []
    px_all = g.x0 + (np.arange(w) + 0.5) * g.res
    py_all = g.y1 - (np.arange(h) + 0.5) * g.res
    for sid, a, b, width, kit, top_run in STAIRS:
        x0, x1 = min(a[0], b[0]) - width - BATTER, max(a[0], b[0]) + width + BATTER
        y0, y1 = min(a[1], b[1]) - width - BATTER, max(a[1], b[1]) + width + BATTER
        cols = np.where((px_all >= x0) & (px_all <= x1))[0]
        rws = np.where((py_all >= y0) & (py_all <= y1))[0]
        X, Y = np.meshgrid(px_all[cols], py_all[rws])
        ax, ay = b[0] - a[0], b[1] - a[1]
        L2 = ax * ax + ay * ay
        t_raw = ((X - a[0]) * ax + (Y - a[1]) * ay) / L2
        L = math.sqrt(L2)
        t = np.clip(t_raw, 0.0, 1.0 + top_run / L)  # the bed runs on past the top, level: its forecourt
        d = np.hypot(X - (a[0] + t * ax), Y - (a[1] + t * ay))
        grade = a[2] + np.minimum(t, 1.0) * (b[2] - a[2])
        side = os.path.join(KIT, kit + ".json")
        bed_note = "an even %.1f°" % math.degrees(math.atan2(b[2] - a[2], math.sqrt(L2)))
        if os.path.exists(side) and "bed" in json.load(open(side)):
            prof = np.array(json.load(open(side))["bed"])
            grade = a[2] + np.interp(t * L, prof[:, 0], prof[:, 1])
            plan = json.load(open(side))["plan"]  # the kit's own grade: its rise over its length (its top is 2,782.8 m)
            on = prof[:, 0] <= plan[-1][2]  # the stair itself, not its forecourt past the top
            dip = float(np.max(prof[on, 0] * plan[-1][4] / plan[-1][2] - prof[on, 1]))
            bed_note = "its bed (the grade, or 0.4 m under its ramps where they dip under it; %.2f m under the grade at most)" % dip
        sub = (slice(rws[0], rws[-1] + 1), slice(cols[0], cols[-1] + 1))
        wb = 1.0 - smoothstep(width / 2, width / 2 + BATTER, d)
        # alongside the stair only: beyond its ends the bed fades within a metre (it had thrown a tongue of ground 3 m
        # high into Tsongra, over the talkers' steps at the stair's foot)
        wb *= np.clip(t_raw * L + 1.0, 0.0, 1.0) * np.clip((1.0 - t_raw) * L + top_run + 1.0, 0.0, 1.0)
        before = z[sub].copy()
        z[sub] = z[sub] * (1.0 - wb) + grade * wb
        on = d <= width / 2
        beds.append((sid, float(np.max(np.abs(before[on] - grade[on]))), bed_note))

    # The side lanes' beds, each lane's head first settled on the padded ground past it (the builder had read the
    # ground before the pads were cut: a flight had ended 0.6 m under the apron it climbs to), its flight resized to it;
    # and the Mani Lane's, level across, following the ground along the wall (it is not the builder's: no settling).
    n_lanes = 0
    lanes = [ln for ln in lane_list() if ln.get("kind") != "yard"]  # (this pass's own flights between yards, redrawn)
    barkor = barkor_lane(z, g)
    for ln in lanes:
        fx, fy = ln["from"]
        ux, uy = ln["dir"]
        ln["width"] = min(ln["width"], LANE_MAX)
        hx, hy = fx + ux * (ln["length"] + 1.0), fy + uy * (ln["length"] + 1.0)
        c, r = int((hx - g.x0) / g.res), int((g.y1 - hy) / g.res)
        if ln.get("head") in yds:  # it ends at a house (the builder's): at its level
            ln["z_b"] = round(next(q[3] for q in pads if q[0] == ln["head"]), 2)
        elif 0 <= r < h and 0 <= c < w and abs(float(z[r, c]) - ln["z_b"]) > 0.1:
            ln["z_b"] = round(float(z[r, c]), 2)
        f = lane_flight(ln["id"], ln["length"], ln["z_a"], ln["z_b"])
        ln["flight"] = f or None
    n_side = len(lanes)
    lanes += yard_lanes(pads, yds, lanes)
    gx_at = lambda x, y: float(z[int((g.y1 - y) / g.res), int((x - g.x0) / g.res)])
    houses_q = []
    for h in json.load(open(os.path.join(ROOT, "data", "town_generic.json"), encoding="utf-8"))["houses"]:
        th = math.radians(h["rot_deg"] - 180.0)
        c_, s_ = math.cos(th), math.sin(th)
        a_, b_ = h["footprint"][0] / 2 + 0.3, h["footprint"][1] / 2 + 0.3
        houses_q.append([(h["pos"][0] + u * c_ + v * s_, h["pos"][1] - u * s_ + v * c_) for u, v in ((-a_, -b_), (a_, -b_), (a_, b_), (-a_, b_))])
    lanes += mouth_lanes(lanes, gx_at, houses_q)
    if lanes:
        path = os.path.join(ROOT, "data", "town_lanes.json")
        d = json.load(open(path, encoding="utf-8"))
        d["lanes"] = lanes
        json.dump(d, open(path, "w", encoding="utf-8"), indent=1)
    json.dump(barkor, open(os.path.join(GEN, "barkor_lane.json"), "w"), indent=1)  # for walls.py and tools/town/mani.py
    # Pass 5c, the arrival south of the slot (tools/terrain/arrival.py; M2 sprint 3): the gallery's rock, the nose, R-01's
    # bed past the eight chortens and V-01's near ground, before the ramps' lanes are carved into it
    arrival_notes = arrival.shape(z, g, json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8")))
    # Pass 5d, Samkha (tools/terrain/samkha.py; M2 sprint 4): the castle's ward levelled, the ground under the chain
    # bridge cut clear of its deck
    samkha_notes = samkha.shape(z, g, None)
    # Pass 5e, the confluence (tools/terrain/confluence.py; M2 sprint 5): the rivers' channels near it carved to the water
    # their banks hold (the pool, the slot's head, the Dungchu's and the Serchu's last metres)
    confluence_notes = confluence.shape(z, g, json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8")))
    road_band = np.zeros(z.shape, bool)  # the Caravan Ramp's lanes' own ground: where its legs lie side by side at a
    # switchback, one leg's cut behind its wall never takes the other's bed (M2 sprint 9, step 1)
    for ln in ramp_lanes():
        if ln.get("road") or ln.get("steps"):  # (and the 1,080 steps' legs beside each other at a switchback: M3 sprint 1)
            (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
            ex, ey = fx + ux * L, fy + uy * L
            cols = np.where((px_all >= min(fx, ex) - W) & (px_all <= max(fx, ex) + W))[0]
            rws = np.where((py_all >= min(fy, ey) - W) & (py_all <= max(fy, ey) + W))[0]
            if len(cols) and len(rws):
                X, Y = np.meshgrid(px_all[cols], py_all[rws])
                sl = (X - fx) * ux + (Y - fy) * uy
                lat = np.abs(-(X - fx) * uy + (Y - fy) * ux)
                road_band[rws[0]:rws[-1] + 1, cols[0]:cols[-1] + 1] |= (sl >= -0.5) & (sl <= L + 0.5) & (lat <= W / 2)
    path_bed = np.zeros(z.shape, bool)  # Tödé's field paths' beds laid so far (M3 sprint 4, step 1): where a switchback's
    # two legs overlap, the higher bed stands (carved in turn, the lower leg had cut the climbing one's start away)
    for k, ln in enumerate(lanes + [barkor] + ramp_lanes()):  # the north ramp's legs cut back into the slot's rim (sprint 6, step 5)
        fx, fy = ln["from"]
        ux, uy = ln["dir"]
        L, W = ln["length"], ln["width"]
        ex, ey = fx + ux * L, fy + uy * L
        x0, x1 = min(fx, ex) - W, max(fx, ex) + W
        y0, y1 = min(fy, ey) - W, max(fy, ey) + W
        cols = np.where((px_all >= x0) & (px_all <= x1))[0]
        rws = np.where((py_all >= y0) & (py_all <= y1))[0]
        if len(cols) == 0 or len(rws) == 0:
            continue
        X, Y = np.meshgrid(px_all[cols], py_all[rws])
        sl = (X - fx) * ux + (Y - fy) * uy
        lat = np.abs(-(X - fx) * uy + (Y - fy) * ux)
        sub = (slice(rws[0], rws[-1] + 1), slice(cols[0], cols[-1] + 1))
        along = (sl >= -0.5) & (sl <= L + 0.5)
        bed = lane_bed(ln, sl)
        if k < len(lanes) or ln.get("road") or ln.get("steps"):  # a builder's lane, the Caravan Ramp's and the 1,080
            # steps': the step under its walls in their higher side, as at the yards (a ramp's: not into another of its
            # lanes), so the terrain's slope stands behind the wall, not over the steps' own walls and treads
            cur = z[sub]
            hw = W / 2 + float(ln.get("margin", 0.0))  # (a lane's `margin`: its bed laid that much wider each side, so the
            # game's vertices at its edges, each the mean of the four pixels round it (export_t3d.py), are its bed's and
            # not half the slope's: the Gönkor's 2.2 m ways over high fills had sagged up to a metre at their edges, and the
            # walker slid into the parapet there; M3 sprint 7, step 1, ISS-223)
            core = along & (lat <= hw) & ~((lat > W / 2 - FILL_IN) & (cur < bed - WALL_MIN) & (not (ln.get("steps") or ln.get("path"))))
            # (the steps' and their way's narrow beds raised their whole width: FILL_IN's margin had left a ridge a cell
            # or two wide on a 3 m way over a high fill, the walker wedged between the walls' bodies; and Tödé's field
            # paths', 2 m wide: M3 sprint 4, step 1)
            cut = along & (lat > hw) & (lat <= hw + CUT_OUT) & (cur > bed + WALL_MIN) & ~feet[sub]
            if ln.get("road") or ln.get("steps"):
                cut &= ~road_band[sub]
            if ln.get("gallery"):  # a gallery of the Gorge Stair, and its rest gallery (tools/town/gorge_stair.py): cut where
                # the rock stands over its bed, never filled under it: it hangs on its beams over the slope
                z[sub] = np.where(core | cut, np.minimum(bed, cur), cur)
            elif ln.get("path"):  # a field path: on another path's bed the higher of the two
                prev = path_bed[sub]
                z[sub] = np.where(core | cut, np.where(prev & core, np.maximum(bed, cur), bed), cur)
                path_bed[sub] |= core
            else:
                z[sub] = np.where(core | cut, bed, cur)
        elif ln.get("channel"):  # a river's bed cut down where it stood over the water (tools/town/serchu_mills.py): cut only
            z[sub] = np.where(along & (lat <= W / 2), np.minimum(z[sub], bed), z[sub])
        elif ln.get("street"):  # Hejie's River Street (tools/town/hejie.py): its bed between the fronts, and past each
            # stretch's ends, so a bend's outer side keeps no wedge of the slope (its houses stand at its level)
            z[sub] = np.where((sl >= -1.5) & (sl <= L + 1.5) & (lat <= W / 2), bed, z[sub])
        elif ln.get("garden"):  # the garden lane (tools/town/gardens.py): its bed, and a metre more on its higher side, so
            # the terrain's step stands behind its wall there, not in front of it
            cur = z[sub]
            far = (sl >= -1.5) & (sl <= L + 1.5)  # past its ends too, so a bend's outer side has no wedge of the slope left
            z[sub] = np.where(far & ((lat <= W / 2) | ((lat <= W / 2 + 1.0) & (cur > bed))), bed, cur)
        else:
            z[sub] = np.where(along & (lat <= W / 2), bed, z[sub])
        n_lanes += 1

    with rasterio.open(os.path.join(GEN, SOURCE + ".tif")) as src:
        prof, tags = src.profile, src.tags()
    with rasterio.open(os.path.join(GEN, OUT + ".tif"), "w", **prof) as f:
        f.write((z + shift).astype(np.float32), 1)
        f.update_tags(**tags)

    out = ["# Pads report: terrain passes 4-5", "",
           "_Written by `tools/terrain/pads.py` from `%s` (plan chapter 11, 8.2; chapter 03, 3.8). A pad's level is the gazetteer's height; cut is how far the ground stood above it on the footprint (uphill, the retaining wall behind), fill how far below (downhill, the wall in front). Over 8 m either way, the design has put a house on a cliff or in a hole: for the next review of chapter 02._" % SOURCE, "",
           "%d pads; an apron of %.1f m and a batter of %.0f m; the town builder's %d houses each with a level yard of %.1f-%.1f m before its front and walled edges (%d m² of yards and aprons). The worst cuts and fills:" % (
               len(pads), APRON, BATTER, len(yds), YARD[0], YARD[1], yard_cells), "",
           "| Pad | x, y | Level | Cut | Fill |", "|---|---|---|---|---|"]
    for pid, px, py, pz, cut, fill in sorted(rows, key=lambda r: -max(r[4], r[5]))[:25]:
        out.append("| %s | %+.0f, %+.0f | %.0f | %.1f m | %.1f m |" % (pid, px, py, pz, cut, fill))
    over = [r for r in rows if max(r[4], r[5]) > 8.0]
    out += ["", "%d pads cut or fill more than 8 m; %d more than 20 m." % (len(over), sum(1 for r in rows if max(r[4], r[5]) > 20.0)), "",
            "**Road beds:** " + "; ".join("%s, its ground moved at most %.1f m to %s" % b for b in beds) + "; %d side lanes (the builder's), %d flights between yards and %d down from the lanes' mouths (IMP-023), the Mani Lane and the ramps' %d lanes (Samkha's two, the garden lane to the Gorge Rim Lookout, the Caravan Ramp, Hejie's River Street, the Castle Ramp, the Serchu road from its Zampa)." % (
                n_side, sum(1 for ln in lanes if ln.get("kind") == "yard"), sum(1 for ln in lanes if ln.get("kind") == "mouth"), n_lanes - len(lanes) - 1), "",
            "**The arrival** (pass 5c, tools/terrain/arrival.py; its check docs/terrain/arrival-report.md): " + "; ".join(arrival_notes) + ".", "",
            "**Samkha** (pass 5d, tools/terrain/samkha.py; its check docs/terrain/samkha-report.md): " + "; ".join(samkha_notes) + ".", "",
            "**The confluence** (pass 5e, tools/terrain/confluence.py; the rivers' check docs/terrain/rivers-report.md): " + "; ".join(confluence_notes) + "."]
    open(REPORT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("\n".join(out[4:]))


if __name__ == "__main__":
    main()
