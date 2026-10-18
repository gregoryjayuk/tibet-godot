#!/usr/bin/env python3
"""The Gönkor R-10 whole (M3 sprint 7, step 1; ISS-204; plan chapter 02, R-10: "round the monastery wall, 1.1 km loop ...
varies, 23% on average; a 40 m timber gallery on the gorge face; monks, pilgrims; clockwise"). The south stretch along
the wall's south line past the eight wheel galleries is tools/town/monastery.py's (`lanes` MON-K); this lays the rest of
the loop round the wall, outside it, from the stretch's east end: round the south-east corner and up the east side past
the great wheel house MON-23 to the north-east corner, west behind the Labrang along the north side and down it to the
gorge's rim, along the rim to the Gorge Stair's top by the West Gate; then down the Gorge Stair's last flight to its
landing 23 and off it along the face (`face_way`: the face's way at its own level, a shelf cut half into the face, and
chapter 02's timber gallery on beams where the face stands steeper than GALLERY_SLOPE, under the stacked monks' houses)
to the 1,080 steps' forecourt by the South Gate (tools/town/dungrong.py); down their last three flights to landing 20 and
out at a gap in its south wall (their trench's shallowest), and on along the face round the spur's south-west corner to
the south stretch's west end. The loop keeps outside the wall's line, its gates closed to it (the Upper Gate's door, the
East Gate's passage).
On the real ground the loop spans 2,850-3,046 m, not chapter 02's 2,882-3,005 (Greg kept the real mountains): its sides
fall 48% and 81% on average, so each stretch but the face's is laid as Tödé's field paths are (tools/town/tode.py `field_paths`: the
cheapest way over a 2 m grid, ramps no steeper than 28%, stone flights up to 45 degrees where the slope is too steep for
them, no sharp turn into or out of a flight), clear of every building, the wall and the other ways; each piece a lane
GK-<stretch>.<n> (`road`: carved by tools/terrain/pads.py, walled in dry stone where its cut or fill is high by
tools/town/walls.py, trodden by tools/terrain/control.py; `steps`: built by ../tibet-blender export_lanes.py and placed by
world/town.gd; a gallery's deck, `gallery` and a flight of no steps, built by export_lanes.py's build_deck), the whole
loop's points in `loop` for the walkers and the routes, the other ways' pieces it walks among them.
Run: tools/py tools/town/gonkor.py [--out <file>]   Writes data/gonkor.json and docs/town/gonkor-report.md (tools/terrain/
build.sh runs it after tools/town/monastery.py, before the pads).
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "terrain"))
import monastery as M  # noqa: E402
import tode as TD  # noqa: E402
from terrain_site import Site  # noqa: E402

ROOT = M.ROOT
ARGS = sys.argv[1:]
OUT = ARGS[ARGS.index("--out") + 1] if "--out" in ARGS else os.path.join(ROOT, "data", "gonkor.json")
REPORT = os.path.join(ROOT, "docs", "town", "gonkor-report.md")
GORGE = os.path.join(ROOT, "data", "gorge_stair.json")
BOX = (420.0, 735.0, -70.0, 305.0)  # the search's ground: the wall's line and 25-35 m round it
CELL, CLEAR, WIDTH = 2.0, 1.0, 2.2  # its grid, the berth it keeps from buildings, the way's bed (the face's way's, 1.6, wider:
# a circuit for crowds on the good days; 2.2 since a parapet, 0.45 m, stands on its edge over a high fill: 1.8 had left 1.35)
HOUSE_GROW = WIDTH / 2 + 0.1  # a house kept this far from the way's middle (the way-finder keeps its cells' middles clear)
FLIGHT = 1.0  # flights up to 45 degrees (the hero way's): the north side falls 81% on average
FLIGHT_COST = float(os.environ.get("GK_FLIGHT_COST", "1.0"))  # a flight's metre this many times a ramp's (Tödé's 2.5: on the
# north side's 81% its ways wound a kilometre of ramps down 146 m; a monastery's circuit takes the stairs)
WALL_BERTH = 0.6  # metres the way's edge keeps from the wall's face (its body 0.9 m thick: ../tibet-blender export_walls.py)
BED_MARGIN = 0.6  # its bed laid this much wider each side than the way (tools/terrain/pads.py `margin`): the game's ground's
# vertices are each the mean of the four pixels round them (tools/terrain/export_t3d.py), so a bed laid to the way's own
# width sagged at its edges over a fill, up to a metre on the north side's 60-degree ground (ISS-223)
FLIGHT_MAX, LAND = 10.0, 1.5  # a flight longer than this broken into equal flights with flagged landings this long between
# (the 1,080 steps' rhythm, 42-60 steps a flight: one of the way-finder's had run 150 m, 437 steps, up the east side)
# The stretches, clockwise from the south stretch's east end, each a way between two points (the town grid): its id, its
# end (laid from), its start (the way reaches it) and where its end and start lie: "kora_e" the south stretch's east end,
# "gate" the Gorge Stair's top by the West Gate, "hero" the hero monk's house's way's start beside the house, else a point
STRETCHES = [("E", "kora_e", "mon23"),  # round the south-east corner and up the east side to the great wheel house's door
             ("N", "mon23", "gate"),  # on up the east side, round the north-east corner, west behind the Labrang along the
             # north wall and down the north side round the wall's west end to the Gorge Stair's top landing by the West Gate
             # (one stretch round both corners: met at a corner, two stretches' ends zigzagged across each other there and
             # the walker fell off a shelf's edge; the wall's line closed to it, it goes round its ends)
             ("F", "l23", "in_steps"),  # off the Gorge Stair's landing 23 along the face to the 1,080 steps' forecourt
             ("S", "l20", "kora_w")]  # off the 1,080 steps' landing 20 along the face to the south stretch's west end
WHEEL_HOUSE, DOOR_OUT = 7.0, 1.6  # MON-23's depth, and the stretches E and N meet this far out before its door
GORGE_JOIN = ("R07E.L23", 1)  # the Gorge Stair's landing the face way comes off (its side: 1 its right going up, the west),
# the way on up its last flight F24 to its top by the West Gate (the top itself hemmed in by the house H-MON-003 4 m south)
STEPS_JOIN = ("R04.L20", 1)  # the 1,080 steps' landing the way from the south comes onto (its south side), the way on up their
# last three flights to the forecourt; their trench across the face is shallowest there (3.7 m; 8-10 m at landings 21-22)
FORECOURT = "R04.L23"  # the steps' forecourt, the face way's south end: on its north-west side, a metre in
GAP_IN, GAP_W = 0.2, 2.2  # the way's end this far in from a landing's side, the gap in its wall that wide
APPROACH = 2.5  # and a level piece this long straight out from the landing's side before it (square to the landing: a link
# from the face straight to its edge had run its last 2 m along the Gorge Stair's last flight's fill wall, the walker against it)
TIMBER_END = {"F": 1.4}  # the face stretches whose join is timber, and its width: off the Gorge Stair's landing 23 (1.4 m long,
# between its flights' fill walls) a balcony on beams and a timber stair down the face beside the last flight's masonry, the
# gallery's own form; in stone the walls round the steps where they came up into the balcony's fill stopped the walker
# The face (the stretches F and S): the gorge's wall stands at 45-60 degrees under the stacked monks' houses, where a way-finder
# over a grid of ramps and flights finds nothing; so these go along the face at their own level (face_way)
FROM_START = {"N", "E"}  # stretches searched from their start (the way-finder keeps one way into each cell: from the
# north, arriving at the wall's west end down the north side's flights, the turn south was a hairpin off a flight, and it
# found no way; from the gate it rounds the corner. Split there instead, the corner's 60-degree ground left a 58-degree link.
# E: from the south stretch's end it reached the level ground before the great wheel house's door only by a flight, which
# may not end there; from the door down it finds its way)
FACE = {"F": (2876.0, 2884.0), "S": (2855.0, 2876.0)}  # each one's levels to choose among
FACE_STEP = 1.0  # metres between its stations along the face
FACE_ENDS = (3.0, 5.0, 7.0, 9.0)  # its first and last stations this far along from its ends, the first that finds a way (a
# straight piece from each end to them: by the Gorge Stair's landing 23 the face is clear of its flights only 3-4 m below
# the landing, which a link of 3 m could not climb)
FACE_GRADE = 0.18  # the steepest it climbs (a circuit's way along the face, no flights; S falls 15 m in 95 m)
GALLERY_SLOPE = 55.0  # degrees: the face steeper than this across it, a timber gallery on beams socketed in the rock (the
# Gorge Stair's galleries' form: chapter 02's 40 m on the gorge face); else a shelf cut half into it, walled on its fill
FACE_BERTH = (1.0, 1.0)  # its bed's edge this far from another way's quad and from a house's or a hall's (0.4 from another
# way's had run the gallery along the Gorge Stair's last flight's fill wall, whose foot leans out under it: the walker
# stopped against it)
FACE_TOL = 0.3  # its straight pieces within this of its points
FACE_RUN = 4  # stations: a stretch of gallery or of shelf shorter than this goes with its neighbours'
FACE_PIECE = 12.0  # the longest straight piece (a gallery's deck each its own file)
FACE_WALL_MIN = [0.6, 0.4]  # its shelf's cut and fill walled from these heights (a parapet over a fill of 1.5 m: walls.py)
NARROW_GROW = 0.25  # the houses kept this far from it (elsewhere 0.8)


def landing_gap(ln, side):
    """Where a way comes onto a landing by its side (-1 its left going up, 1 its right): (the way's end on the landing,
    GAP_IN in from its edge (x, y, z), the landing's middle there (x, y, z), [side, from, to] along the landing, the gap in
    that side's wall for ../tibet-blender export_lanes.py)."""
    (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
    nx, ny = -uy * side * -1.0, ux * side * -1.0  # (the left normal is (-uy, ux); `side` -1 the left)
    mx, my = fx + ux * L / 2, fy + uy * L / 2
    z = float(ln["z_a"])
    end = (mx + nx * (W / 2 - GAP_IN), my + ny * (W / 2 - GAP_IN), z)
    half = min(GAP_W, L - 0.4) / 2
    return end, (mx, my, z), [side, round(L / 2 - half, 3), round(L / 2 + half, 3)]


def points(Z, mon):
    """The named ends: kora_e and kora_w (the south stretch's ends, on its bed), gate (the Gorge Stair's top), in_steps (on
    the 1,080 steps' forecourt by its north-west side), l20 and l23 (the ways' ends off the steps' landing 20 and the Gorge
    Stair's landing 23); each (x, y, z)."""
    kora = [ln for ln in mon["lanes"] if ln.get("gonkor")]
    k0, k1 = kora[0], kora[-1]
    out = {"kora_e": (float(k0["from"][0]), float(mon["gonkor"]["walk_y"]), float(k0["z_a"])),
           "kora_w": (float(k1["from"][0]) + float(k1["dir"][0]) * float(k1["length"]), float(mon["gonkor"]["walk_y"]), float(k1["z_b"]))}
    if os.path.exists(M.STEPS):
        by = {ln["id"]: ln for ln in json.load(open(M.STEPS, encoding="utf-8"))["lanes"]}
        if FORECOURT in by and STEPS_JOIN[0] in by:
            fc = by[FORECOURT]  # (the way's end on its north-west side's middle, a metre in from its edge)
            (fx, fy), (ux, uy), L, W = fc["from"], fc["dir"], fc["length"], fc["width"]
            nx, ny = -uy, ux
            out["in_steps"] = (fx + ux * L / 2 + nx * (W / 2 - 1.0), fy + uy * L / 2 + ny * (W / 2 - 1.0), float(fc["z_a"]))
            out["l20"] = landing_gap(by[STEPS_JOIN[0]], STEPS_JOIN[1])[0]
    wh = mon.get("pads", {}).get("MON-23")
    if wh is not None:  # before the great wheel house's door, out on the circuit (tools/town/monastery.py MOVE, FACING)
        th = math.radians(float(wh["facing"]))
        out["mon23"] = (wh["at"][0] + math.sin(th) * (WHEEL_HOUSE / 2 + DOOR_OUT), wh["at"][1] + math.cos(th) * (WHEEL_HOUSE / 2 + DOOR_OUT), float(wh["level"]))
    if os.path.exists(GORGE):
        gs = json.load(open(GORGE, encoding="utf-8"))
        top, at_ = gs["gate"]["top"], gs["gate"]["at"]
        out["gate"] = (float(at_[0]), float(at_[1]), float(top[2]))  # (the gate's place, the top landing's east end: the
        # way comes onto it there, past the stair's last flight)
        byg = {ln["id"]: ln for ln in gs["lanes"]}
        if GORGE_JOIN[0] in byg:
            out["l23"] = landing_gap(byg[GORGE_JOIN[0]], GORGE_JOIN[1])[0]
    return out


END_LEVEL = float(__import__("os").environ.get("GK_END_LEVEL", "2.5"))  # a stretch's ends' level ground for the search,
# metres either way (1.2 had left a link from the end to the way's first point of 3.9 m in 2.1 m on the steep sides)
LANDING = {}  # a named end's level ground for the search, metres either way (filled in by main: the gate's top 3.5, a way joining
# its goal by a ramp, and the Gorge Stair's top stands on a face of 45 degrees)
MEET = 7.0  # metres round a named end where the other ways' pieces are not kept clear: the Gönkor meets them there (the
# Gorge Stair's top landing by the West Gate)
KEEP = {"R07E.F23", "R07E.L23", "R07E.F24"}  # but these always (the Gorge Stair's last flights below its top: the way from the
# north comes onto the top landing beside them, not over them)


def kept(mon, town, others_lanes, meets=(), house_grow=0.8):
    """What the way keeps clear of: every building and hall, the wall's line (its gates closed to it), the other ways'
    pieces (but those within MEET of a place it meets them)."""
    blocked = []
    for h in mon["houses"] + mon["buildings"]:
        th = math.radians(float(h["rot_deg"]))
        cx, cy, w, d = h["pad"] if "pad" in h else (h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1])
        blocked.append(M.rect(cx, cy, w, d, math.sin(th), math.cos(th), house_grow))
    halls = {b["id"]: b for b in town["buildings"] if str(b.get("id", "")).startswith("MON-") and b.get("footprint")}
    for hid, pd in mon["pads"].items():
        b = halls.get(hid)
        if b is None:
            continue
        th = math.radians(pd["facing"])
        fr = M.FRONT.get(hid, 0.0)
        x, y = pd["at"][0] + math.sin(th) * fr / 2, pd["at"][1] + math.cos(th) * fr / 2
        blocked.append(M.rect(x, y, b["footprint"][0], b["footprint"][1] + fr, math.sin(th), math.cos(th), 1.0))
    line = [p for p in M.WALL_LINE if not isinstance(p, str)]  # (the East Gate's range between two of its points: the line on)
    for run in [{"pts": line}]:
        pts = run["pts"]
        for a, b in zip(pts, pts[1:]):
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            if L < 0.05:
                continue
            ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
            reach = WIDTH / 2 + WALL_BERTH  # (the way's middle this far from the wall's face, and past its ends: the way's own
            # half-width with it; 0.2 m past an end had let a way past the north run's west end within 0.5 m of its corner,
            # and the walker stopped against it)
            blocked.append(M.rect((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, 0.9 + 2 * reach, L + 2 * reach, ux, uy))
    for ln in others_lanes:
        (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
        ends = [(fx, fy), (fx + ux * L, fy + uy * L)]
        if ln["id"] not in KEEP and any(math.hypot(e[0] - m[0], e[1] - m[1]) < MEET for e in ends for m in meets):
            continue
        blocked.append(M.rect(fx + ux * L / 2, fy + uy * L / 2, W, L, ux, uy, 1.0))
    return blocked


def stretch(Z, sid, a, b, blocked):
    """One stretch's way from its end a to its start b (each (x, y, z)), Tödé's field paths with the Gönkor's grid: (lanes,
    its points from a to b), or ([], []) where none was found."""
    width, clear = WIDTH, CLEAR
    goal = {"id": "GK-" + sid, "pad": [a[0], a[1], 0.6, 0.6], "rot_deg": math.degrees(math.atan2(b[0] - a[0], b[1] - a[1])) % 360.0,
            "pos": [a[0], a[1], a[2]]}
    keep = (TD.BOX, TD.APRON, TD.PATH_CLEAR, TD.PATH_CELL, TD.PATH_W, TD.FLIGHT_GRADE, TD.LEAT, TD.FLIGHT_COST)
    # (and no ceiling: Tödé's paths stay under its fields' top, 2,978 m; the Gönkor climbs to 3,044)
    TD.BOX, TD.APRON, TD.PATH_CLEAR, TD.PATH_CELL, TD.PATH_W, TD.FLIGHT_GRADE, TD.LEAT, TD.FLIGHT_COST = BOX, 0.0, clear, CELL, width, FLIGHT, 1e9, FLIGHT_COST
    try:
        carved = [(p[0] - r, p[0] + r, p[1] - r, p[1] + r, p[2]) for p, r in ((a, LANDING.get(a, END_LEVEL)), (b, LANDING.get(b, END_LEVEL)))]
        lanes, ways, short = TD.field_paths(Z, [goal], [], blocked, entries=[(b[0], b[1])], carved=carved)
    finally:
        TD.BOX, TD.APRON, TD.PATH_CLEAR, TD.PATH_CELL, TD.PATH_W, TD.FLIGHT_GRADE, TD.LEAT, TD.FLIGHT_COST = keep
    if short:
        return [], []
    pts = ways.get(goal["id"], [])
    # its end a: the way-finder leaves a goal from its side, a couple of metres off; the link from there to the end itself
    q = pts[0]
    L = math.hypot(a[0] - q[0], a[1] - q[1])
    if L > 0.3:
        d = [round((a[0] - q[0]) / L, 4), round((a[1] - q[1]) / L, 4)]
        link = {"id": "", "from": [round(q[0], 2), round(q[1], 2)], "dir": d, "length": round(L, 2), "width": width,
                "z_a": round(q[2], 2), "z_b": round(a[2], 2), "path": True, "wall_min": TD.PATH_WALL_MIN}
        rise = a[2] - q[2]
        if abs(rise) > TD.PATH_GRADE * L:
            lo, hi = (q, a) if rise > 0.0 else (a, q)
            dd = [round((hi[0] - lo[0]) / L, 4), round((hi[1] - lo[1]) / L, 4)]
            n = max(3, int(round(abs(rise) / TD.RISER)))
            link.update({"from": [round(lo[0], 2), round(lo[1], 2)], "dir": dd, "z_a": round(lo[2], 2), "z_b": round(hi[2], 2),
                         "profile": [[0.0, round(lo[2] - 0.1, 2)], [round(L, 2), round(hi[2] - 0.1, 2)]], "steps": True,
                         "flight": {"file": "", "s": 0.0, "rise": round(abs(rise), 3), "z": round(lo[2], 2), "n": n, "run": round(L / n, 3),
                                    "top": 0.0, "walls": None}})
        else:
            link.update({"profile": [[0.0, round(q[2], 2)], [round(L, 2), round(a[2], 2)]], "road": True, "flight": None})
        lanes = [link] + lanes
        pts = [[round(a[0], 2), round(a[1], 2), round(a[2], 2)]] + pts
    return lanes, pts


def broken(ln):
    """A long flight as flights and landings between them, each a lane, in order up it (the landings shorter, to 0.9 m, where
    LAND's would leave its flights steeper than FLIGHT; as it was where even those would)."""
    f, L = ln["flight"], ln["length"]
    k = int(math.ceil(L / FLIGHT_MAX))
    dz = ln["z_b"] - ln["z_a"]
    land = min(LAND, (L - dz / FLIGHT) / max(k - 1, 1))
    if k <= 1 or land < 0.9:
        return [ln]
    run, rise = (L - (k - 1) * land) / k, dz / k
    (fx, fy), (ux, uy) = ln["from"], ln["dir"]
    keep = {kk: ln[kk] for kk in ("width", "wall_min", "gonkor_way", "path") if kk in ln}
    out, sl, z = [], 0.0, ln["z_a"]
    for i in range(k):
        n = max(3, int(round(f["n"] / k)))
        out.append(dict(keep, id="", **{"from": [round(fx + ux * sl, 3), round(fy + uy * sl, 3)], "dir": ln["dir"], "length": round(run, 3),
                                         "z_a": round(z, 3), "z_b": round(z + rise, 3), "profile": [[0.0, round(z - 0.1, 3)], [round(run, 3), round(z + rise - 0.1, 3)]],
                                         "steps": True, "flight": {"file": "", "s": 0.0, "rise": round(rise, 3), "z": round(z, 3), "n": n,
                                                                   "run": round(run / n, 3), "top": 0.0, "walls": None}}))
        sl, z = sl + run, z + rise
        if i < k - 1:  # (a landing: flagstones on a dry-stone block, export_lanes.py's build_landing)
            out.append(dict(keep, id="", **{"from": [round(fx + ux * sl, 3), round(fy + uy * sl, 3)], "dir": ln["dir"], "length": round(land, 3),
                                             "z_a": round(z, 3), "z_b": round(z, 3), "profile": [[0.0, round(z - 0.1, 3)], [round(land, 3), round(z - 0.1, 3)]],
                                             "steps": True, "flight": {"file": "", "s": 0.0, "rise": 0.0, "z": round(z, 3), "n": 0, "length": round(land, 3), "walls": None}}))
            sl += land
    return out


def face_quads(mon, town, others, skip):
    """What a face way keeps its berth from: the houses' and the halls' quads (grown by NARROW_GROW, with the wall's line)
    and the other ways' (but `skip`, the ones it joins), each grown by the way's half-width and its berth."""
    solid = kept(mon, town, [], (), house_grow=NARROW_GROW + WIDTH / 2 + FACE_BERTH[1])
    ways = []
    for ln in others:
        if ln["id"] in skip:
            continue
        (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
        ways.append(M.rect(fx + ux * L / 2, fy + uy * L / 2, W, L, ux, uy, WIDTH / 2 + FACE_BERTH[0]))
    return solid + ways


def timber_flight(Z, p, q, width):
    """A timber stair (a gallery of the Gorge Stair's form: ../tibet-blender export_lanes.py build_gallery) from p up to q
    (each (x, y, z)), its beams socketed on the side the ground stands higher."""
    lo, hi = (p, q) if q[2] > p[2] else (q, p)
    L = math.hypot(hi[0] - lo[0], hi[1] - lo[1])
    d = [round((hi[0] - lo[0]) / L, 5), round((hi[1] - lo[1]) / L, 5)]
    n = max(3, int(round((hi[2] - lo[2]) / TD.RISER)))
    mx, my = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
    rx, ry = d[1], -d[0]
    inner = 1 if float(Z(mx + rx * 2.0, my + ry * 2.0)) > float(Z(mx - rx * 2.0, my - ry * 2.0)) else -1
    return {"id": "", "from": [round(lo[0], 3), round(lo[1], 3)], "dir": d, "length": round(L, 3), "width": width,
            "z_a": round(lo[2], 3), "z_b": round(hi[2], 3), "road": True, "steps": True, "gallery": True, "face": True,
            "profile": [[0.0, round(lo[2] - 0.25, 3)], [round(L, 3), round(hi[2] - 0.25, 3)]],
            "flight": {"file": "", "s": 0.0, "rise": round(hi[2] - lo[2], 3), "z": round(lo[2], 3), "n": n, "run": round(L / n, 3),
                       "top": 0.0, "gallery": True, "inner": inner, "walls": None}}


def face_piece(Z, pts, kind, width=None):
    """A straight piece of a face way over its points (x, y, z) from the first to the last: a shelf (`road`) or a gallery's
    deck (`gallery`: a flight of no steps for export_lanes.py's build_deck, from its lower end up, its beams in the rock on
    `inner`, the kit's +x the right going up)."""
    p0, p1 = pts[0], pts[-1]
    if kind == "gallery" and p1[2] < p0[2]:  # (a deck is built from its lower end)
        p0, p1 = p1, p0
    L = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
    d = [round((p1[0] - p0[0]) / L, 5), round((p1[1] - p0[1]) / L, 5)]
    ln = {"id": "", "from": [round(p0[0], 3), round(p0[1], 3)], "dir": d, "length": round(L, 3), "width": width or WIDTH,
          "z_a": round(p0[2], 3), "z_b": round(p1[2], 3), "road": True, "flight": None, "wall_min": FACE_WALL_MIN, "face": True}
    if kind == "gallery":
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        rx, ry = d[1], -d[0]
        inner = 1 if float(Z(mx + rx * 2.0, my + ry * 2.0)) > float(Z(mx - rx * 2.0, my - ry * 2.0)) else -1
        ln.update({"gallery": True, "profile": [[0.0, round(p0[2] - 0.25, 3)], [round(L, 3), round(p1[2] - 0.25, 3)]],
                   "flight": {"file": "", "s": 0.0, "rise": round(p1[2] - p0[2], 3), "z": round(p0[2], 3), "n": 0, "length": round(L, 3),
                              "gallery": True, "deck": True, "inner": inner, "walls": None}})
    else:
        ln["profile"] = [[0.0, round(p0[2], 3)], [round(L, 3), round(p1[2], 3)]]
    return ln


def face_way(Z, sid, a, b, quads, a_out=None):
    """The face stretch with the shortest end links that find a way (FACE_ENDS); `a_out` a point before a (x, y, z) the
    way comes to first, a level piece on from it to a."""
    for end in FACE_ENDS:
        lanes, pts = face_way_at(Z, sid, a, b, quads, end, a_out)
        if lanes:
            return lanes, pts
    return [], []


def face_way_at(Z, sid, a, b, quads, end, a_out=None):
    """A face stretch from a to b (each (x, y, z)) along the face at its own level: its stations on rays from the spur's top
    (M.CENTRE) between a's and b's, FACE_STEP apart along the face, each station's point where the ground stands at the
    way's level there, so its bed is cut half into the face and built half out from it; the levels chosen by a dynamic
    programme for the shortest way climbing no steeper than FACE_GRADE whose points keep clear of `quads`. Its pieces
    straight to FACE_TOL, each a shelf, or a gallery where the face stands steeper than GALLERY_SLOPE across it; a
    straight piece from a to its first station and from its last to b. (lanes, its points from a to b), or ([], [])."""
    lo, hi = FACE[sid]
    cx, cy = M.CENTRE
    a0 = a
    if a_out is not None:
        a = a_out  # (the way's own end before a)
    ta, tb = math.atan2(a[1] - cy, a[0] - cx) % (2 * math.pi), math.atan2(b[1] - cy, b[0] - cx) % (2 * math.pi)
    ra, rb = math.hypot(a[0] - cx, a[1] - cy), math.hypot(b[0] - cx, b[1] - cy)
    rm = (ra + rb) / 2
    sg = 1.0 if tb > ta else -1.0
    t0, t1 = ta + sg * end / ra, tb - sg * end / rb
    n = max(3, int(abs(t1 - t0) * rm / FACE_STEP))
    ths = np.linspace(t0, t1, n + 1)
    levels = np.arange(lo, hi + 1e-6, 0.1)
    K = len(levels)
    rs = np.arange(min(ra, rb) - 35.0, max(ra, rb) + 45.0, 0.1)
    P = np.full((len(ths), K, 2), np.nan)
    for i, th in enumerate(ths):
        xs, ys = cx + rs * math.cos(th), cy + rs * math.sin(th)
        zr = np.asarray(Z(xs, ys), float)
        for k, lev in enumerate(levels):
            above = np.nonzero(zr >= lev)[0]
            if not len(above) or above[-1] >= len(rs) - 1:
                continue
            j = above[-1]  # (the outermost: the face, not a hollow behind it)
            t = (zr[j] - lev) / max(zr[j] - zr[j + 1], 1e-9)
            r = rs[j] + t * (rs[1] - rs[0])
            P[i, k] = (cx + r * math.cos(th), cy + r * math.sin(th))
    ok = ~np.isnan(P[:, :, 0])
    X, Y = np.where(ok, P[:, :, 0], 0.0), np.where(ok, P[:, :, 1], 0.0)
    for q in quads:
        qx, qy = [c[0] for c in q], [c[1] for c in q]
        if max(qx) < np.nanmin(P[:, :, 0]) - 1 or min(qx) > np.nanmax(P[:, :, 0]) + 1 or max(qy) < np.nanmin(P[:, :, 1]) - 1 or min(qy) > np.nanmax(P[:, :, 1]) + 1:
            continue
        ok &= ~TD._inside(q, X, Y)
    INF = 1e18
    C = np.full((len(ths), K), INF)
    back = np.full((len(ths), K), -1, int)

    def link(p, z, q, zq):
        """A straight piece's cost from p (x, y, z) to the point q at zq: its length, three times over a ramp's grade
        (a flight); none over FLIGHT."""
        L = math.hypot(q[0] - p[0], q[1] - p[1])
        rise = abs(zq - z)
        if rise > FLIGHT * max(L, 0.3):
            return INF
        return L * (3.0 if rise > TD.PATH_GRADE * max(L, 0.3) else 1.0)

    for k in range(K):
        if ok[0, k]:
            C[0, k] = link(a, a[2], P[0, k], levels[k])
    dz = np.abs(levels[:, None] - levels[None, :])
    for i in range(1, len(ths)):
        D = np.hypot(P[i - 1, :, None, 0] - P[i, None, :, 0], P[i - 1, :, None, 1] - P[i, None, :, 1])
        D = np.where(np.isnan(D), INF, D)
        cand = np.where(ok[i - 1][:, None] & ok[i][None, :] & (dz <= FACE_GRADE * D + 1e-9), C[i - 1][:, None] + D, INF)
        back[i] = np.argmin(cand, axis=0)
        C[i] = cand[back[i], np.arange(K)]
    end = np.array([C[-1, k] + (link(b, b[2], P[-1, k], levels[k]) if ok[-1, k] else INF) for k in range(K)])
    if end.min() >= INF / 2:
        return [], []
    k = int(np.argmin(end))
    ks = [k]
    for i in range(len(ths) - 1, 0, -1):
        k = int(back[i][k])
        ks.append(k)
    ks.reverse()
    way = [(float(P[i, k, 0]), float(P[i, k, 1]), float(levels[k])) for i, k in enumerate(ks)]
    # each station a gallery's or a shelf's, by the face's slope across it; short runs go with their neighbours'
    kinds = ["gallery" if M.fall(Z, p[0], p[1])[1] > GALLERY_SLOPE else "road" for p in way]
    changed = True
    while changed:
        changed = False
        runs, i = [], 0
        while i < len(kinds):
            j = i
            while j < len(kinds) and kinds[j] == kinds[i]:
                j += 1
            runs.append((i, j))
            i = j
        for i, j in runs:
            if j - i < FACE_RUN and len(runs) > 1:
                other = "road" if kinds[i] == "gallery" else "gallery"
                kinds[i:j] = [other] * (j - i)
                changed = True
                break
    pts = ([a0] if a_out is not None else []) + [a] + way + [b]
    kinds = (["road"] if a_out is not None else []) + ["road"] + kinds + ["road"]
    first = 2 if a_out is not None else 1  # (the first station's index in pts)
    # straight pieces: a run of one kind split where a point stands over FACE_TOL off the line, or at FACE_PIECE; the end
    # links (from a to the first station, from the last to b) each its own, a shelf (on its fill where it leaves the face)
    cuts = list(range(first + 1))
    i = first
    while i < len(pts) - 2:
        j = i + 1
        while j + 1 < len(pts) - 1 and kinds[j + 1] == kinds[i + 1]:
            p, q = pts[i], pts[j + 1]
            L = math.hypot(q[0] - p[0], q[1] - p[1])
            if L > FACE_PIECE:
                break
            ux, uy = (q[0] - p[0]) / max(L, 1e-9), (q[1] - p[1]) / max(L, 1e-9)
            if max(abs((m[0] - p[0]) * uy - (m[1] - p[1]) * ux) for m in pts[i + 1:j + 1]) > FACE_TOL:
                break
            j += 1
        cuts.append(j)
        i = j
    cuts.append(len(pts) - 1)
    lanes = []
    for i, j in zip(cuts, cuts[1:]):
        kind = "road" if i < first or j == len(pts) - 1 else kinds[i + 1]
        if i < first and sid in TIMBER_END:  # (its join in timber: a balcony, and a stair where steeper than a ramp)
            p, q = pts[i], pts[j]
            L = math.hypot(q[0] - p[0], q[1] - p[1])
            if abs(q[2] - p[2]) > TD.PATH_GRADE * L:
                lanes.append(timber_flight(Z, p, q, TIMBER_END[sid]))
            else:
                lanes.append(face_piece(Z, pts[i:j + 1], "gallery", TIMBER_END[sid]))
            continue
        if i < first or j == len(pts) - 1:  # (the end pieces: a ramp, or a flight where steeper)
            p, q = pts[i], pts[j]
            L = math.hypot(q[0] - p[0], q[1] - p[1])
            if abs(q[2] - p[2]) > TD.PATH_GRADE * L:
                lo_, hi_ = (p, q) if q[2] > p[2] else (q, p)
                nst = max(3, int(round(abs(q[2] - p[2]) / TD.RISER)))
                d = [round((hi_[0] - lo_[0]) / L, 5), round((hi_[1] - lo_[1]) / L, 5)]
                lanes.append({"id": "", "from": [round(lo_[0], 3), round(lo_[1], 3)], "dir": d, "length": round(L, 3), "width": WIDTH,
                              "z_a": round(lo_[2], 3), "z_b": round(hi_[2], 3), "steps": True, "face": True, "wall_min": FACE_WALL_MIN,
                              "profile": [[0.0, round(lo_[2] - 0.1, 3)], [round(L, 3), round(hi_[2] - 0.1, 3)]],
                              "flight": {"file": "", "s": 0.0, "rise": round(abs(q[2] - p[2]), 3), "z": round(lo_[2], 3), "n": nst,
                                         "run": round(L / nst, 3), "top": 0.0, "walls": None}})
                continue
        lanes.append(face_piece(Z, pts[i:j + 1], kind))
    return lanes, [[round(p[0], 2), round(p[1], 2), round(p[2], 2)] for p in pts]


GORGE_WAY = ["R07E.L24", "R07E.F24", "R07E.L23"]  # the other ways' pieces the loop walks, as laid (from the gate's place along
# the top landing and down the stair's last flight to landing 23; from the
STEPS_WAY = ["R04.F23", "R04.L22", "R04.F22", "R04.L21", "R04.F21", "R04.L20"]  # forecourt down to landing 20)


def walk(by, ids, end_mid=True):
    """The points along other ways' pieces, each from its top down to its foot (a landing's last to its middle)."""
    out = []
    for k, lid in enumerate(ids):
        ln = by[lid]
        (fx, fy), (ux, uy), L = ln["from"], ln["dir"], ln["length"]
        top = [fx + ux * L, fy + uy * L, float(ln["z_b"])]
        foot = [fx, fy, float(ln["z_a"])]
        if k == len(ids) - 1 and end_mid:
            foot = [fx + ux * L / 2, fy + uy * L / 2, float(ln["z_a"])]
        out += [top, foot]
    return [[round(p[0], 2), round(p[1], 2), round(p[2], 2)] for p in out]


def write_report(out, report, mon):
    """docs/town/gonkor-report.md: each stretch as laid, the circuit's length, its heights and its steps, the gallery."""
    loop = out["loop"]
    kora = [ln for ln in mon["lanes"] if ln.get("gonkor")]
    south = sum(ln["length"] for ln in kora)
    walked = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(loop, loop[1:]))
    zs = [p[2] for p in loop] + [ln["z_a"] for ln in kora] + [ln["z_b"] for ln in kora]
    climb = sum(max(0.0, a[2] - b[2]) for a, b in zip(loop, loop[1:]))  # (clockwise: the loop walked backwards)
    climb += sum(max(0.0, ln["z_a"] - ln["z_b"]) for ln in kora)
    steps = sum(int(ln["flight"].get("n") or 0) for ln in out["lanes"] if ln.get("flight") and not ln.get("gallery"))
    gal = [ln for ln in out["lanes"] if ln.get("gallery")]
    rows = ["# The Gönkor R-10 whole", "",
            "_Written by `tools/town/gonkor.py` (M3 sprint 7, step 1; ISS-204; plan chapter 02, R-10) with the terrain (`tools/terrain/build.sh`). Its pieces are `data/gonkor.json`'s `lanes`; the south stretch along the eight wheel galleries is `tools/town/monastery.py`'s (`data/monastery.json` MON-K). Chapter 02: \"round the monastery wall, 1.1 km loop, ±125 m (South Gate 2,882 to behind the Labrang 3,005), about 700 steps, 23% on average; a 40 m timber gallery on the gorge face; monks, pilgrims; clockwise\"._", "",
            "| Stretch | As laid |", "|---|---|"]
    names = {"E": "E: up the east side to the great wheel house's door",
             "N": "N: on up the east side, behind the Labrang and down the north side round the wall's west end to the West Gate",
             "F": "F: off the Gorge Stair's landing 23 along the face (its gallery) to the 1,080 steps' forecourt",
             "S": "S: off the steps' landing 20 along the face round the spur's south-west corner to the south stretch"}
    for sid, txt in report:
        rows.append("| %s | %s |" % (names.get(sid, sid), txt))
    rows += ["", "Round the circuit, clockwise from the south stretch's east end: the south stretch %.0f m, the rest %.0f m (with the Gorge Stair's last flight and the steps' last three that it walks), %.2f km in all; from %.0f m to %.0f m, %.0f m climbed; %d steps of its own and the 1,080 steps' last three flights' 126." % (
        south, walked, (south + walked) / 1000.0, min(zs), max(zs), climb, steps),
             "", "The gallery on the gorge face, under the stacked monks' houses south of the West Gate: %d decks, %.0f m, each half cut into the face, half on beams socketed in the rock (the face steeper than %.0f degrees across it); the rest of the face's way a shelf cut half into the face and walled on its fill." % (
                 len(gal), sum(ln["length"] for ln in gal), GALLERY_SLOPE),
             "", "The real ground spans more than chapter 02's 2,882-3,005 m (Greg kept the real mountains): the north side falls 81%% on average, so the way-finder's flights there run up to 45 degrees, each broken by a landing every %.0f m at most." % FLIGHT_MAX]
    open(REPORT, "w", encoding="utf-8").write("\n".join(rows) + "\n")


def main():
    site_ = Site.load()
    g = site_.read(M.SOURCE)
    Z = lambda x, y: g.z(x, y) - site_.shift
    mon = json.load(open(M.OUT, encoding="utf-8"))
    town = json.load(open(M.TOWN, encoding="utf-8"))
    named = points(Z, mon)
    others = []
    for path_ in (M.STEPS, M.GORGE, M.GONPA):
        if os.path.exists(path_):
            others += json.load(open(path_, encoding="utf-8"))["lanes"]
    others += [ln for ln in mon["lanes"] if not ln.get("gonkor")]  # (the hero way's: the Gönkor keeps beside it)
    by = {ln["id"]: ln for ln in others}
    meets = [named[k] for k in ("gate", "in_steps", "kora_w") if k in named]
    blocked = kept(mon, town, others, meets, house_grow=HOUSE_GROW)
    if "gate" in named:
        LANDING[named["gate"]] = 3.5
    at = lambda p: named[p] if isinstance(p, str) else (p[0], p[1], float(Z(p[0], p[1])))
    lanes, loop, report, gaps, para = [], [], [], {}, []
    joins = {"F": (GORGE_JOIN, "l23"), "S": (STEPS_JOIN, "l20")}
    for sid, a_, b_ in STRETCHES:
        if (isinstance(a_, str) and a_ not in named) or (isinstance(b_, str) and b_ not in named):
            report.append((sid, "its end or start not built"))
            continue
        a, b = at(a_), at(b_)
        if sid in FACE:
            (lid, side), _ = joins[sid]
            near = lambda ln: any(math.hypot(e[0] - b[0], e[1] - b[1]) < 1.5 for e in (ln["from"], (ln["from"][0] + ln["dir"][0] * ln["length"],
                                                                                          ln["from"][1] + ln["dir"][1] * ln["length"])))
            skip = {lid, FORECOURT} | {ln["id"] for ln in others if near(ln)}  # (the landing it comes onto, the forecourt, and the
            # ways that leave its start with it: the hero monk's house's way at the south stretch's west end; not the Gorge
            # Stair's flights either side of landing 23, which it keeps its berth from)
            _, m0, _ = landing_gap(by[lid], side)  # (the way's own end square out from the landing's side, APPROACH off it)
            ul = math.hypot(a[0] - m0[0], a[1] - m0[1])
            a_out = (a[0] + (a[0] - m0[0]) / ul * APPROACH, a[1] + (a[1] - m0[1]) / ul * APPROACH, a[2])
            ls, pts = face_way(Z, sid, a, b, face_quads(mon, town, others, skip), a_out)
        elif sid in FROM_START:
            ls, pts = stretch(Z, sid, b, a, blocked)
            ls, pts = ls[::-1], pts[::-1]
        else:
            ls, pts = stretch(Z, sid, a, b, blocked)
        if not ls:
            report.append((sid, "no way found from (%.0f, %.0f) to (%.0f, %.0f)" % (a[0], a[1], b[0], b[1])))
            continue
        ls = [q for ln in ls for q in (broken(ln) if ln.get("flight") and not ln.get("gallery") and ln["length"] > FLIGHT_MAX else [ln])]
        if sid not in FACE:
            for ln in ls:
                ln["parapet"] = True  # (a parapet on its fill wall where 1.5 m high: tools/town/walls.py)
        for k, ln in enumerate(ls):
            ln["id"] = "GK-%s.%02d" % (sid, k + 1)
            if ln.get("flight"):
                ln["flight"]["file"] = "gonkor_%s_%02d" % (sid.lower(), k + 1)
            ln["gonkor_way"] = sid
        if sid in FACE:  # onto the landing it comes off: the gap in its side's wall, and the other way's pieces the loop walks
            (lid, side), nm = joins[sid]
            o, m_, gap = landing_gap(by[lid], side)
            if lid.startswith("R04."):
                gaps[lid] = gap  # (the 1,080 steps' whitewashed walls: export_lanes.py leaves the gap)
            ux_, uy_ = o[0] - m_[0], o[1] - m_[1]
            ul = math.hypot(ux_, uy_)
            para.append([lid, round(m_[0], 2), round(m_[1], 2), round(o[0] + ux_ / ul * 1.5, 2), round(o[1] + uy_ / ul * 1.5, 2)])  # (walls.py)
            mid = [round(m_[0], 2), round(m_[1], 2), round(m_[2], 2)]
            shared = walk(by, GORGE_WAY) if sid == "F" else walk(by, STEPS_WAY)
            if sid == "S":
                shared = [[round(named["in_steps"][0], 2), round(named["in_steps"][1], 2), round(named["in_steps"][2], 2)]] + shared
            pts = shared + [mid] + pts
        lanes += ls
        loop += [p for p in pts if not loop or (abs(p[0] - loop[-1][0]) > 0.01 or abs(p[1] - loop[-1][1]) > 0.01)]
        L = sum(ln["length"] for ln in ls)
        gal = sum(ln["length"] for ln in ls if ln.get("gallery"))
        report.append((sid, "%d pieces (%d flights, %d landings%s), %.0f m, from %.0f to %.0f m" % (
            len(ls), sum(1 for ln in ls if ln.get("flight") and ln["flight"].get("n")), sum(1 for ln in ls if ln.get("flight") and not ln["flight"].get("n") and not ln.get("gallery")),
            ", %.0f m of gallery" % gal if gal else "", L, a[2], b[2])))
    for ln in lanes:
        ln["margin"] = BED_MARGIN  # (tools/terrain/pads.py: the bed laid wider than the way, its edges flat in the game's ground)
    marks = {"great wheel house": "mon23", "West Gate": "gate", "landing 20": "l20", "landing 23": "l23", "forecourt": "in_steps"}
    marks = {k: [round(named[v][0], 2), round(named[v][1], 2)] for k, v in marks.items() if v in named}
    marks["behind the Labrang"] = [710.0, 274.0]
    out = {"about": "The Gönkor R-10 beyond its south stretch (tools/town/gonkor.py; M3 sprint 7, step 1; ISS-204): `lanes` its pieces in "
                    "tools/terrain/pads.py's form, GK-<stretch>.<n> (E up the east side to the great wheel house's door, N on up round the "
                    "north-east corner, behind the Labrang and down the north side round the wall's west end to the Gorge Stair's top, "
                    "F along the face from the Gorge Stair's landing 23 to the 1,080 steps' "
                    "forecourt, S from their landing 20 along the face to the south stretch's west end; `face` the face's pieces, `gallery` "
                    "a timber gallery's deck), each `gonkor_way` its stretch; `loop` "
                    "the way's points from the south stretch's east end round to its west end, as laid (anticlockwise: walk it backwards), "
                    "with the Gorge Stair's last flight and the steps' last three that it walks; `stretches` what each found; `steps_gaps` "
                    "the gaps in the 1,080 steps' landings' walls where it joins them (../tibet-blender export_lanes.py: [side, from, to]); "
                    "`parapet_gaps` where it comes onto another way's landing, [its id, x0, y0, x1, y1]: that landing's parapet opened "
                    "within a metre of the line (tools/town/walls.py); `marks` the places along it by name (x, y), for the routes. "
                    "Regenerated with the terrain.",
           "lanes": lanes, "loop": loop, "stretches": {sid: txt for sid, txt in report}, "steps_gaps": gaps, "parapet_gaps": para, "marks": marks}
    json.dump(out, open(OUT, "w", encoding="utf-8"), indent=1)
    if OUT == os.path.join(ROOT, "data", "gonkor.json"):
        write_report(out, report, mon)
    for sid, txt in report:
        print("gonkor: %s: %s" % (sid, txt))
    print("gonkor: %d pieces, %.0f m -> %s" % (len(lanes), sum(ln["length"] for ln in lanes), os.path.relpath(OUT, ROOT) if OUT.startswith(ROOT) else OUT))


if __name__ == "__main__":
    main()
