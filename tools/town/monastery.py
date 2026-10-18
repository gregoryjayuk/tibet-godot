#!/usr/bin/env python3
"""Dungkar Gönpa on the spur (M2 sprint 13; plan chapter 02, D08, MON-01 to MON-41; chapter 03, 6.1 and 6.9; chapter 12's
M2: kit K9 in part, "types M1 and M2 at L1/L2, so the spur reads from V-01"): where its houses stand and what its halls
are drawn as.
- The four khamtsen halls (MON-26, 12 x 10 m with a portico) each between its two ranges of cells (MON-29, H-MON-105 to
  112, M3, 24 x 7 m), round the south flank's lower rows.
- The 60 M1 (6 x 6 m, two storeys; MON-27, H-MON-001 to 060) "stacked up the west face above the gorge ... like a huge
  cliff-dwelling", spread evenly over its rows from the enclosure's foot to FACE_TOP, so the face reads as a stack and not
  a single file along its brink; on the gorge face the houses are the wall (MON-21).
- The 44 M2 (9 x 8 m, two or three storeys, a walled yard; MON-28, H-MON-061 to 104) spread over the lower zone's rows
  round the south flank and the middle zone's among the halls.
Rows run along the spur's contours ROW_RISE metres apart inside the enclosure (D08: x +430 to +705, y -40 to +270,
2,880-3,000 m), each building's front on its row's line facing down the fall line, its pad cut into the slope
(tools/terrain/pads.py; tools/town/walls.py walls its podium), clear of the halls' pads (data/town.json), the courtyards,
the gates' ways and each other. Each house its variant (the kit's monk_house m1 v1-v8, m2 v1-v6, monk_range_m3 v1-v4), none
like its neighbour. And the halls: each one's pad at the middle of its own ground (chapter 02's heights stood up to 10 m
off it), the tantric college moved off its 26 m of fall, each drawn by its far form (../tibet-blender kit/monastery.py
hall_far, by chapter 03's table; the Tsokchen the kit's assembly_hall).
Run: tools/py tools/town/monastery.py   Writes data/monastery.json and docs/town/monastery-report.md (tools/terrain/build.sh
runs it before pads.py).
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
STEPS = os.path.join(ROOT, "data", "dungrong.json")  # the 1,080 steps (tools/town/dungrong.py, run before this): kept clear,
# the South Gate at their top's level
GORGE = os.path.join(ROOT, "data", "gorge_stair.json")  # the Gorge Stair (tools/town/gorge_stair.py, run before this): kept clear
GONPA = os.path.join(ROOT, "data", "gonpa_ways.json")  # the way up from the South Gate to the courtyard (tools/town/gonpa_ways.py,
# run before this; M3 sprint 3, step 1): kept clear
LEVEL = {"MON-01": 2932.0, "MON-02": 2928.0,  # the Tsokchen on its platform 4 m over its courtyard (chapter 02's levels; the
         # medians of their own ground had stood the hall 8 m over it on a fill: ISS-190)
         "MON-06": 2944.0, "MON-07": 2944.0,  # the Tsenyi Dratsang and the Chöra at one level, its side door onto the court
         # the red chapels and the Gönkhang with their doors near the ground before them, their backs cut into the flank
         # (M3 sprint 3, step 3: at their grounds' medians their doors stood 3.6-3.8 m over the slope on fills): the Jampa
         # Lhakhang at chapter 02's 2,945 m, up 11 steps to its landing; the reliquary chapel up 5; the Gönkhang's porch at grade
         "MON-04": 2945.0, "MON-15": 2962.0, "MON-05": 2930.0,
         # step 4: the Labrang turned to 218 degrees and set 2.8 m under its ground's median, its door up 11 steps from the
         # slope (chapter 02's 2,990 m stood it 7 m over it); the estate office up 5; the Jakhang held where its flume's
         # trestles were measured (../tibet-blender export_types.py mon12_kitchen `pipe`)
         "MON-09": 2982.5, "MON-11": 2977.3, "MON-12": 2928.2,
         # step 6: the great wheel house at chapter 02's 2,960 m, its door at the slope before it (its median stood it 3 m over);
         # M3 sprint 7, step 1: out on the Gönkor (MOVE), its door at the ground where the circuit comes to it; the tsa-tsa
         # house at the circuit's landing beside it (tools/town/gonkor.py: 2,944.16 m, 15 Oct 2026), its window at eye height
         # from the way (at its ground's median it stood 3.5 m over it)
         "MON-23": 2973.5, "MON-24": 2944.2}
FORECOURT = {"MON-06": 5.7, "MON-08": 7.6, "MON-04": 1.0, "MON-15": 0.5, "MON-13": 6.5}  # the colleges' porticoes and forecourts levelled with them before their fronts
# (../tibet-blender kit/monastery.py college: the portico 2.2 m, the forecourt 5 m; tools/terrain/pads.py YARDS, its 1.5 m
# APRON beyond): the Tsenyi's level ground ends at its forecourt's front, where its steps go down the slope; the Gyüpa's
# runs 1.9 m past its closed front, its forecourt entered from its sides; the red chapels' landings (kit/monastery.py
# lhakhang `landing`: 2.5 and 2.0 m) level to their fronts, where their steps go down; the Dronkhang's stable yard 8 m
# deep before it (kit/monastery.py dronkhang `yard`)
# What stands before each hall's front, which the monks' houses keep clear of besides its footprint (metres out from its
# front: its forecourt, landing, porch or yard and its steps' run; M3 sprint 3, steps 2-4)
FRONT = {"MON-06": 11.9, "MON-08": 7.6, "MON-04": 5.4, "MON-15": 3.3, "MON-05": 1.6, "MON-09": 4.4, "MON-11": 2.8, "MON-13": 8.0,
         "MON-14": 2.0, "MON-10": 1.3}
# The Gönkor R-10's south stretch and its prayer-wheel galleries MON-22 (chapter 02: 128 wheels in eight 16 m sections; M3
# sprint 3, step 6): each section on the wall MON-21's south line (its wall the wall's own length there: the kit's
# wheel_gallery, its wall `GAL_WALL` metres behind its origin), spread from the east end westward at least GAL_GAP apart,
# clear of the steps' and the ways' lanes; the stretch a lane along the galleries at GAL_WALK from the line, level through
# each and ramped between, from the wall's south-east corner to its south-west foot (walked clockwise: westward)
GAL_N, GAL_LEN, GAL_WALL, GAL_GAP = 8, 16.0, 1.65, 12.0
GAL_WALK = -1.7  # the walk's middle from the wall's line (outward), the wheels within a hand of it
GAL_BED, GAL_WIDTH = -1.0, 4.0  # its bed's middle and width: from the gallery's posts back under the wall's line, so the wall
# between the galleries stands on the walk, not in a slot below its fill (a fall there); wide enough for the terrain's 1 m
# lattice in a cut 3-5 m deep (a bed of 1.4 m had its sides rise under the walker)
GAL_EAST = 685.0  # the first gallery's middle (the wall's south-east corner beyond climbs 8 m in 16: the circuit's east side)
GAL_RAMP = 2.4  # the most the walk climbs between two galleries (12 m: 20%): their levels smoothed to it
KORA_ENDS = (None, 447.0)  # its west end along the south line (its east end the first gallery's)
# Buildings the gazetteer has no place or record for, each on its own ground (M3 sprint 3, step 4; chapter 03, 6.7): MON-11's
# granary range beside its office, its front in line; the dogs' kennel MON-38 "by MON-19", inside the wall west of the East
# Gate's range, facing in. (id, name, type, kit, middle, footprint, facing)
EXTRA = [("MON-11G", "The estate's granary range", "granary", "mon11_granary", (681.0, 183.0), (20.0, 8.0), 180.0),
         ("MON-38", "The monastery dogs' kennel", "kennel", "mon38_kennel", (661.0, 84.0), (4.0, 3.0), 290.0)]
MOVE = {"MON-06": (600.0, 75.0),  # the Tsenyi Dratsang beside the Chöra, its east wall facing the court's west wall 6 m off
        # (chapter 03, 6.5: "opens onto the debate courtyard by a side door"; chapter 02's places had stood it 13 m north of it)
        "MON-23": (719.5, 140.0), "MON-24": (713.8, 46.0)}  # the great wheel house and the tsa-tsa house out on the Gönkor's east
# side, beyond the wall's east line (chapter 02: "on the Gönkor's east side"; at chapter 02's places they stood 15 m and 5 m
# inside the wall, the circuit passing behind it: M3 sprint 7, step 1), the circuit coming to the wheel house's door
# (tools/town/gonkor.py, its stretches E and NE meeting before it), the tsa-tsa house's window beside its way
INSIDE = {"MON-25"}  # the courtyard's sang burner: the courtyard's own (../tibet-blender kit/monastery.py tsokchen_court)
OUT = os.path.join(ROOT, "data", "monastery.json")
REPORT = os.path.join(ROOT, "docs", "town", "monastery-report.md")
SEED = 1658  # the monastery's founding (chapter 01)
BOX = (432.0, 705.0, -38.0, 268.0)  # the enclosure (D08), a little inside its wall
CENTRE = (575.0, 130.0)  # the spur's top, round which its rows are ordered (from the east, anticlockwise)
ROWS = (2884.0, 2962.0)  # the rows' levels: the lower zone and the middle (D08: 2,880-2,960 m)
ROW_RISE = 5.6  # metres between rows: a house's two storeys and its podium's step
COUNTS = {"M1": 60, "M2": 44}
SIZE = {"M1": (6.0, 6.0), "M2": (9.0, 8.0), "M3": (24.0, 7.0), "K": (12.0, 10.0)}  # width (along the row), depth
STEEP = {"M1": 64.0, "M2": 42.0, "M3": 44.0, "K": 40.0}  # degrees: the steepest ground under each
YARD = 4.0  # an M2's walled yard beside it (the kit's monk_house: 4 x 4 m, on one side)
PORTICO = 2.0  # a khamtsen hall's portico before its front (the kit's hall_far portico)
VARIANTS = {"M1": 8, "M2": 6, "M3": 4}
GAP = 1.6  # the least gap between two houses along a row
STACK_REACH = 4.0  # a face house stacked on the one below: its front this near that one's back, or not stacked
APRON = 0.3  # the level ground round a house on its podium (tools/terrain/pads.py's 1.5 m left podia of 8-17 m on the face)
MARGIN = 5.0  # clear of a hall's pad
WIDE = {"MON-02": 7.0, "MON-07": 7.0}  # the courtyards kept wider
GATES = [((465.0, 65.0), 11.0), ((672.0, 78.0), 12.0), ((428.0, -17.0), 14.0)]  # the South Gate's forecourt, the East
# Gate's, the thangka terrace's way: kept clear
FACE_X = 500.0  # west of this the west face
FACE_TOP = 2935.0  # the face's houses climb to here, below the colleges and the Gönkhang
MIDDLE = 2915.0  # the middle zone's foot (D08: gonpa.gate below it, gonpa.tsokchen above)
M2_LOWER = 28  # of the 44 M2, those in the lower zone; the rest among the halls of the middle zone (MON-28: "lower and
# middle zones")
GROUPS = ["Dungkar", "Minyak", "Nyarong", "Litang"]  # the khamtsen (MON-26), each between its two ranges (MON-29)
GROUP_ROWS = (1, 3)  # the south flank's rows they stand on, in turn (failing that, the lower zone's others)
# The halls' pads at the middle of their own ground, not at chapter 02's heights, which stood up to 10 m off it (pads 30 m
# over the slope; as Hejie's named buildings were, tools/town/hejie.py); the thangka terrace MON-41 on the slope as it is
# until its site is settled (a 40 x 20 m pad on 48 m of fall over the confluence: its fill 35 m; ISS-188); a hall on more
# fall than SETTLE moved to the nearest ground that holds it (the tantric college MON-08: 26 m under its 16 x 13 m)
FOLLOW = ["MON-41"]
SETTLE = 18.0
# Each hall's far form (../tibet-blender kit/monastery.py hall_far, by chapter 03, 6.1's table; M3 builds them whole) and
# where it does not face south, its facing: the gates outwards, down their ways
HERO_CELL = ("H-MON-012", 4)  # the monk's house carved, and the variant its kit was built from (chapter 04, 3.7)
# Its way to its door (ISS-214; M3 sprint 6, step 6): a level step before its front, its pad's own (HERO_STEP; until then
# its door stood 4.6 m over the slope with no way to it), and a way from the 1,080 steps' forecourt or the Gönkor's south stretch's west end to its side by Tödé's
# field paths (tools/town/tode.py field_paths: ramps no steeper than 28%, flights where too steep), on the face's ground at a
# finer grid and nearer the houses than Tödé's (WAY_*): each piece a lane MON-H.<n> (carved by tools/terrain/pads.py, walled
# by tools/town/walls.py, a flight built by ../tibet-blender export_lanes.py; MON-H.00 the step up from the way's start onto
# the end of the step before its door), its points in `ways` for the routes. The other
# face houses' doors are ISS-214's still (a dry run of the same from the forecourt alone reached 36 of the 60).
HERO_STEP = 1.2
WAY_BOX = (425.0, 485.0, -45.0, 75.0)  # the search's ground: the face's south end, the steps' top and the Gönkor's west end
WAY_CELL, WAY_CLEAR, WAY_W = 2.0, 1.0, 1.6
WAY_FLIGHT = 1.0  # its flights up to 45 degrees, a monastery's stair (Tödé's 0.85): the forecourt is cut 4-5 m into the slope
# on the house's side, and no gentler flight came down onto it
HALL_KIT = {"MON-01": "mon01_tsokchen_in_v1", "MON-02": "mon02_tsokchen_court_v1", "MON-07": "mon07_chora_v1", "MON-04": "mon04_maitreya_chapel_in_v1", "MON-05": "mon05_protector_chapel_in_v1",
            "MON-06": "mon06_philosophy_college_v1", "MON-08": "mon08_tantric_college_v1", "MON-09": "mon09_labrang_in_v1",
            "MON-10": "mon10_abbots_house_v1", "MON-11": "mon11_estate_office_v1", "MON-12": "mon12_kitchen_in_v1",
            "MON-13": "mon13_guest_house_v1", "MON-14": "mon14_library_in_v1", "MON-15": "mon15_reliquary_chapel_v1",
            "MON-17": "mon17_south_gate_v1", "MON-19": "mon19_east_gate_v1", "MON-23": "mon23_wheel_house_v1",
            "MON-33": "mon33_butter_store_v1", "MON-16": "mon16_thangka_wall_v1", "MON-30": "mon30_novices_yard_v1",
            "MON-34": "mon34_geese_pen_v1", "MON-24": "mon24_tsa_tsa_house_v1"}
FACING = {"MON-17": 215.0, "MON-19": 110.0, "MON-16": 225.0, "MON-09": 218.0,  # (MON-16's from chapter 02: "faces 225 degrees")
          "MON-23": 270.0, "MON-24": 270.0}  # (the Gönkor's great wheel house and tsa-tsa house facing the circuit outside the wall)
THANGKA_WALL = (20.0, 4.0)  # MON-16's footprint: its foot stands on its lowest ground (the kit builds it 8 m down)
# The wall MON-21 (chapter 03, 6.8: 1,050 m, 3-4 m high, battered, whitewash with a rounded red coping; "on the gorge face the
# monks' houses are the wall"): D08's rectangle less its west side, from the face's south-west foot east along the south,
# north up the east past the East Gate's range (its passage the gate: the wall meets its two ends), west along the north
# through the Upper Gate's door (MON-20, 1.4 m) to the face's north end; drawn by tools/town/walls.py as a free wall on the
# built ground, broken where a building or a gate stands; on D08's edge, 2 m outside BOX
WALL_H = 3.5
WALL_LINE = [(440.0, -40.0), (705.0, -40.0), (705.0, 64.0), "MON-19", (705.0, 94.0), (705.0, 270.0), (470.0, 270.0)]
DOORS = {"MON-20": ((660.0, 270.0), 0.9), "MON-18": ((445.0, 160.0), 0.9)}  # half the door's width and a little (the Upper
# Gate's door on the wall's north run, 20 m north of chapter 02's +660, +250, which stood among the houses inside it)


def contour(Z, z0, box, step=1.0):
    """The points of the contour at z0 inside the box, in order round CENTRE from the east, anticlockwise (the west face
    and the south flank run on unbroken; a convex spur's rows wrap round it)."""
    xs = np.arange(box[0], box[1], step)
    ys = np.arange(box[2], box[3], step)
    X, Y = np.meshgrid(xs, ys)
    H = Z(X, Y)
    pts = []
    for (a, b, ax) in ((H[:, :-1], H[:, 1:], 1), (H[:-1, :], H[1:, :], 0)):
        cross = (a - z0) * (b - z0) < 0.0
        t = np.where(cross, (z0 - a) / np.where(np.abs(b - a) < 1e-9, 1e-9, b - a), 0.0)
        if ax == 1:
            px, py = X[:, :-1] + t * step, Y[:, :-1]
        else:
            px, py = X[:-1, :], Y[:-1, :] + t * step
        pts += list(zip(px[cross], py[cross]))
    pts.sort(key=lambda p: math.atan2(p[1] - CENTRE[1], p[0] - CENTRE[0]) % (2.0 * math.pi))
    return pts


def arc_len(pts):
    """A row's length along its points (a jump between pieces of the contour counted as at most 5 m)."""
    return sum(min(math.hypot(b[0] - a[0], b[1] - a[1]), 5.0) for a, b in zip(pts, pts[1:]))


def fall(Z, x, y):
    """The fall line's way (unit, downhill) and the slope's degrees at (x, y)."""
    e = 2.0
    gx = (float(Z(x + e, y)) - float(Z(x - e, y))) / (2 * e)
    gy = (float(Z(x, y + e)) - float(Z(x, y - e))) / (2 * e)
    gl = math.hypot(gx, gy)
    if gl < 1e-6:
        return (0.0, -1.0), 0.0
    return (-gx / gl, -gy / gl), math.degrees(math.atan(gl))


def rect(cx, cy, w, d, ux, uy, grow=0.0):
    """A footprint's corners: (ux, uy) its front's way; w across it, d along it."""
    ax, ay = -uy, ux  # along the front (the kit's +x)
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


def site(Z, x, y, kind, blocked, placed):
    """A building of `kind` with its front on the row's line at (x, y), facing down the fall line: {rect, the house's
    middle, its ground's middle (a khamtsen's portico before it, an M2's yard beside it), facing, level}, or None where
    the ground is too steep, it would leave the enclosure, or it meets a hall or another building."""
    (ux, uy), slope = fall(Z, x, y)
    if slope > STEEP[kind]:
        return None
    w, d = SIZE[kind]
    W = w + (YARD if kind == "M2" else 0.0)
    D = d + (PORTICO if kind == "K" else 0.0)
    cx, cy = x - ux * d / 2, y - uy * d / 2
    gx, gy = cx + ux * (D - d) / 2, cy + uy * (D - d) / 2
    r = rect(gx, gy, W, D, ux, uy, 0.4)
    if not all(BOX[0] <= qx <= BOX[1] and BOX[2] <= qy <= BOX[3] for qx, qy in r):
        return None
    if any(overlap(r, q) for q in blocked) or any(overlap(r, q) for q in placed):
        return None
    return {"rect": r, "c": (cx, cy), "g": (gx, gy), "W": W, "D": D, "facing": math.degrees(math.atan2(ux, uy)) % 360.0,
            "level": float(Z(gx, gy))}


def settle(Z, b, others):
    """A hall on more fall than SETTLE moved to the nearest ground within 30 m that holds it (the least fall, a little for
    the distance), clear of the other halls by 3 m: (x, y) or None."""
    p, fp = b["pos"], b["footprint"]
    best = None
    for dx in np.arange(-30.0, 30.1, 2.0):
        for dy in np.arange(-30.0, 30.1, 2.0):
            x, y = p[0] + dx, p[1] + dy
            r = rect(x, y, fp[0], fp[1], 0.0, -1.0, 3.0)
            if not all(BOX[0] <= qx <= BOX[1] and BOX[2] <= qy <= BOX[3] for qx, qy in r) or any(overlap(r, q) for q in others):
                continue
            xs, ys = np.meshgrid(np.linspace(x - fp[0] / 2, x + fp[0] / 2, 9), np.linspace(y - fp[1] / 2, y + fp[1] / 2, 9))
            zz = Z(xs, ys)
            score = float(zz.max() - zz.min()) + 0.2 * math.hypot(dx, dy)
            if best is None or score < best[0]:
                best = (score, x, y)
    return None if best is None else (best[1], best[2])


def hero_way(Z, hero, houses, others, pads, halls, kora):
    """The hero monk's house's way from the 1,080 steps' forecourt to its side (HERO_CELL, WAY_*): (lanes, its points)."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import tode as TD  # (lazy: its constants set for the face below, then put back)
    st = json.load(open(STEPS, encoding="utf-8"))
    fc, top_z = st["top"]["forecourt"], st["top"]["z"]
    blocked = []
    for h in houses + others:
        if h is hero:
            continue
        th = math.radians(float(h["rot_deg"]))
        cx, cy, w, d = h["pad"] if "pad" in h else (h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1])
        blocked.append(rect(cx, cy, w, d, math.sin(th), math.cos(th), 0.8))
    for hid, pd in pads.items():
        b = next((o for o in halls if o["id"] == hid), None)
        if b is None:
            continue
        th = math.radians(pd["facing"])
        fr = FRONT.get(hid, 0.0)
        x, y = pd["at"][0] + math.sin(th) * fr / 2, pd["at"][1] + math.cos(th) * fr / 2
        blocked.append(rect(x, y, b["footprint"][0], b["footprint"][1] + fr, math.sin(th), math.cos(th), 1.0))
    lanes_in = list(kora)
    for path_ in (STEPS, GORGE, GONPA):
        if os.path.exists(path_):
            lanes_in += [ln for ln in json.load(open(path_, encoding="utf-8"))["lanes"] if ln["id"] != "R04.L23"]  # (the forecourt: the way starts on it)
    for ln in lanes_in:
        (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
        blocked.append(rect(fx + ux * L / 2, fy + uy * L / 2, W, L, ux, uy, 1.0))
    keep = (TD.BOX, TD.APRON, TD.PATH_CLEAR, TD.PATH_CELL, TD.PATH_W, TD.FLIGHT_GRADE)
    TD.BOX, TD.APRON, TD.PATH_CLEAR, TD.PATH_CELL, TD.PATH_W, TD.FLIGHT_GRADE = WAY_BOX, APRON, WAY_CLEAR, WAY_CELL, WAY_W, WAY_FLIGHT
    try:
        # (the forecourt a terrace any cell of which a way may reach, as the Tödé Stair's top: its middle is boxed in by the
        # South Gate's ground, and it is turned to the gate's 215 degrees)
        th = math.radians(float(fc["facing"]))
        quad = rect(fc["at"][0], fc["at"][1], float(fc["size"][0]), float(fc["size"][1]), math.sin(th), math.cos(th))
        # or from the Gönkor's south stretch's west end, on its bed (the forecourt is cut 6-10 m into the slope on the
        # house's side and the steps' last legs run in their trench between them)
        entries, carved = [tuple(fc["at"])], []
        if kora:
            k_ = kora[-1]
            for t in (0.0, 3.0):
                L_ = float(k_["length"])
                x_ = k_["from"][0] + k_["dir"][0] * (L_ - t)
                y_ = k_["from"][1] + k_["dir"][1] * (L_ - t) - (GAL_BED - GAL_WALK)  # (the walk's middle, not its bed's)
                z_ = k_["z_a"] + (k_["z_b"] - k_["z_a"]) * (L_ - t) / L_
                entries.append((x_, y_))
                carved.append((x_ - 1.0, x_ + 1.0, y_ - 1.0, y_ + 1.0, z_))
        lanes, ways, short = TD.field_paths(Z, [hero], [], blocked, entries=entries, carved=carved, terrace={"quad": quad, "z": top_z})
    finally:
        TD.BOX, TD.APRON, TD.PATH_CLEAR, TD.PATH_CELL, TD.PATH_W, TD.FLIGHT_GRADE = keep
    if short:
        print("monastery: WARNING: no way to %s's door" % hero["id"])
        return [], {}
    # the step up from where the way leaves the house's side onto the end of the step before its door (the way's first
    # point on the ground beside the house, a metre or so under its floor): a flight, or a ramp where it is gentle
    pts = ways[hero["id"]]
    th = math.radians(hero["rot_deg"])
    fx_, fy_ = math.sin(th), math.cos(th)  # its front's way
    ax_, ay_ = -math.cos(th), math.sin(th)  # the kit's +x
    sd = 1.0 if (pts[0][0] - hero["pos"][0]) * ax_ + (pts[0][1] - hero["pos"][1]) * ay_ > 0.0 else -1.0
    half = SIZE["M1"][1] / 2 + HERO_STEP / 2
    top_ = (hero["pos"][0] + fx_ * half + sd * ax_ * (SIZE["M1"][0] / 2 + APRON), hero["pos"][1] + fy_ * half + sd * ay_ * (SIZE["M1"][0] / 2 + APRON),
            round(hero["pos"][2] + 0.4, 2))
    a_, b_ = pts[0], top_
    L_ = math.hypot(b_[0] - a_[0], b_[1] - a_[1])
    if L_ > 0.3:
        d_ = [round((b_[0] - a_[0]) / L_, 4), round((b_[1] - a_[1]) / L_, 4)]
        link = {"id": "MON-H.00", "from": [round(a_[0], 2), round(a_[1], 2)], "dir": d_, "length": round(L_, 2), "width": WAY_W,
                "z_a": round(a_[2], 2), "z_b": b_[2], "path": True, "wall_min": TD.PATH_WALL_MIN}
        if abs(b_[2] - a_[2]) > TD.PATH_GRADE * L_:
            n = max(3, int(round(abs(b_[2] - a_[2]) / TD.RISER)))
            link.update({"profile": [[0.0, round(a_[2] - 0.1, 2)], [round(L_, 2), round(b_[2] - 0.1, 2)]], "steps": True,
                         "flight": {"file": "mon_h_00", "s": 0.0, "rise": round(b_[2] - a_[2], 3), "z": round(a_[2], 2), "n": n,
                                    "run": round(L_ / n, 3), "top": 0.0, "walls": None}})
        else:
            link.update({"profile": [[0.0, round(a_[2], 2)], [round(L_, 2), b_[2]]], "road": True, "flight": None})
        lanes.insert(0, link)
        ways[hero["id"]] = [[round(top_[0], 2), round(top_[1], 2), top_[2]]] + pts
    for k, ln in enumerate(lanes):  # (Tödé's ids and flights' files renamed the monastery's)
        ln["id"] = "MON-H.%02d" % k  # (the way up from the South Gate's are MON-W: tools/town/gonpa_ways.py)
        if ln.get("flight"):
            ln["flight"]["file"] = "mon_h_%02d" % k
    return lanes, ways


def main():
    site_ = Site.load()
    g = site_.read(SOURCE)
    Z = lambda x, y: g.z(x, y) - site_.shift
    rng = random.Random(SEED)
    town = json.load(open(TOWN, encoding="utf-8"))
    halls = [b for b in town["buildings"] if str(b.get("id", "")).startswith("MON-") and b.get("pos") and b.get("footprint")
             and b["pos"][2] is not None]
    # the halls first: a hall on too much fall moved, then each one's pad at the middle of its own ground
    moved = {}
    for b in halls:
        if b["id"] in FOLLOW or "roof" in str(b.get("type", "")):
            continue
        xs, ys = np.meshgrid(np.linspace(b["pos"][0] - b["footprint"][0] / 2, b["pos"][0] + b["footprint"][0] / 2, 9),
                             np.linspace(b["pos"][1] - b["footprint"][1] / 2, b["pos"][1] + b["footprint"][1] / 2, 9))
        zz = Z(xs, ys)
        if float(zz.max() - zz.min()) > SETTLE:
            others = [rect(o["pos"][0], o["pos"][1], o["footprint"][0], o["footprint"][1], 0.0, -1.0) for o in halls if o is not b]
            at = settle(Z, b, others)
            if at is not None:
                moved[b["id"]] = at
    moved.update(MOVE)
    pads = {}
    for b in halls:
        if b["id"] in FOLLOW or b["id"] in INSIDE or "roof" in str(b.get("type", "")):
            continue  # (the Tsokchen's roof terrace MON-40 is its roof's)
        x, y = moved.get(b["id"], (b["pos"][0], b["pos"][1]))
        fp = b["footprint"]
        xs, ys = np.meshgrid(np.linspace(x - fp[0] / 2, x + fp[0] / 2, 9), np.linspace(y - fp[1] / 2, y + fp[1] / 2, 9))
        if b["id"] in FACING:
            facing = FACING[b["id"]]
        else:
            facing = float(b.get("rot_deg") or 180.0)
        pads[b["id"]] = {"at": [round(x, 1), round(y, 1)], "level": LEVEL.get(b["id"], round(float(np.median(Z(xs, ys))), 1)), "facing": facing,
                         "was": b["pos"][2]}
        if b["id"] in HALL_KIT:
            pads[b["id"]]["kit"] = HALL_KIT[b["id"]]
        if b["id"] in FORECOURT:
            pads[b["id"]]["yard"] = FORECOURT[b["id"]]
        if b["id"] in moved:
            pads[b["id"]]["moved_from"] = b["pos"][:2]
    wall = next((b for b in town["buildings"] if b.get("id") == "MON-16"), None)
    if wall is not None and wall.get("pos"):  # the thangka wall: no pad, its foot on its lowest ground
        th = math.radians(FACING["MON-16"])
        r = rect(wall["pos"][0], wall["pos"][1], THANGKA_WALL[0], THANGKA_WALL[1], math.sin(th), math.cos(th))
        zs = [float(Z(qx, qy)) for qx, qy in r] + [float(Z(wall["pos"][0], wall["pos"][1]))]
        pads["MON-16"] = {"at": wall["pos"][:2], "level": round(min(zs), 1), "facing": FACING["MON-16"], "was": wall["pos"][2],
                          "kit": HALL_KIT["MON-16"], "follow": True}
    blocked = []
    for b in halls:
        if b["id"] in FOLLOW:
            continue
        x, y = pads.get(b["id"], {}).get("at", b["pos"][:2])
        th = math.radians(float(pads.get(b["id"], {}).get("facing", b.get("rot_deg") or 180.0)))
        fr = FRONT.get(b["id"], 0.0)  # (and what stands before its front)
        x, y = x + math.sin(th) * fr / 2, y + math.cos(th) * fr / 2
        blocked.append(rect(x, y, b["footprint"][0], b["footprint"][1] + fr, math.sin(th), math.cos(th), WIDE.get(b["id"], MARGIN)))
    extra = []
    for eid, name, typ, kit, (ex, ey), (ew, ed), ef in EXTRA:
        xs, ys = np.meshgrid(np.linspace(ex - ew / 2, ex + ew / 2, 9), np.linspace(ey - ed / 2, ey + ed / 2, 9))
        lv = round(float(np.median(Z(xs, ys))), 1)
        extra.append({"id": eid, "name_en": name, "type": typ, "district": "gonpa", "quarter": "gonpa.tsokchen", "kit": kit, "seed": 1,
                      "pos": [ex, ey, lv], "rot_deg": ef, "footprint": [ew, ed], "storeys": 2 if typ == "granary" else 1, "enterable": False})
        th = math.radians(ef)
        blocked.append(rect(ex, ey, ew, ed + (3.0 if typ == "granary" else 0.0), math.sin(th), math.cos(th), MARGIN))
    # the Gönkor's galleries on the south line, from its east end westward, and its south stretch through them
    yl = WALL_LINE[0][1]
    lanes_in = []
    for path_ in (STEPS, GONPA):
        if os.path.exists(path_):
            lanes_in += json.load(open(path_, encoding="utf-8"))["lanes"]
    lane_rects = [rect(ln["from"][0] + ln["dir"][0] * ln["length"] / 2, ln["from"][1] + ln["dir"][1] * ln["length"] / 2, ln["width"],
                       ln["length"], ln["dir"][0], ln["dir"][1], 1.5) for ln in lanes_in]
    yw_ = yl + GAL_WALK  # the walk's middle line
    gals, x = [], GAL_EAST
    while len(gals) < GAL_N and x - GAL_LEN / 2 > KORA_ENDS[1] + 2.0:
        r_ = rect(x, yl - GAL_WALL + 0.45, GAL_LEN, 3.4, 0.0, -1.0, 0.5)
        if any(overlap(r_, q) for q in lane_rects):
            x -= 2.0
            continue
        gals.append([x, float(np.mean([float(Z(x + u, yw_)) for u in np.linspace(-GAL_LEN / 2, GAL_LEN / 2, 9)]))])
        x -= GAL_LEN + GAL_GAP
    for _ in range(40):  # each gallery's level its walk's ground, eased until no gap climbs more than GAL_RAMP
        for a_, b_ in zip(gals, gals[1:]):
            over = abs(a_[1] - b_[1]) - GAL_RAMP
            if over > 0.0:
                sg = 1.0 if a_[1] > b_[1] else -1.0
                a_[1] -= sg * over / 2
                b_[1] += sg * over / 2
    gals = [(gx, round(gz, 1)) for gx, gz in gals]
    for k, (gx, gz) in enumerate(gals):
        # (its type not a "gallery", which pads.py's FOLLOW_GROUND leaves on the slope unlevelled)
        extra.append({"id": "MON-22%s" % "abcdefgh"[k], "name_en": "Gönkor prayer-wheel gallery, section %d" % (k + 1), "type": "wheel arcade",
                      "district": "gonpa", "quarter": "gonpa.gate", "kit": "mon22_wheel_gallery", "seed": k % 4 + 1,
                      "pos": [round(gx, 2), round(yl - GAL_WALL, 2), gz], "rot_deg": 180.0, "footprint": [GAL_LEN, 3.4], "storeys": 1,
                      "enterable": False})
        blocked.append(rect(gx, yl - GAL_WALL + 0.45, GAL_LEN, 3.4, 0.0, -1.0, MARGIN))
    stops = []  # (x, z) along it, east to west: each gallery's two ends and its west end
    for gx, gz in gals:
        stops += [(gx + GAL_LEN / 2, gz), (gx - GAL_LEN / 2, gz)]
    stops.append((KORA_ENDS[1], round(float(Z(KORA_ENDS[1], yw_)), 2)))
    kora = []
    for k, ((xa, za), (xb, zb)) in enumerate(zip(stops, stops[1:])):
        L = xa - xb
        if L < 0.5:
            continue
        kora.append({"id": "MON-K.%02d" % (k + 1), "from": [round(xa, 2), round(yl + GAL_BED, 2)], "dir": [-1.0, 0.0], "length": round(L, 2),
                     "width": GAL_WIDTH, "z_a": za, "z_b": zb, "flight": None,
                     "profile": [[round(t * L / 8.0, 2), round(za + (zb - za) * t / 8.0, 2)] for t in range(9)], "gonkor": True})
    if "MON-16" in pads:
        th = math.radians(FACING["MON-16"])
        blocked.append(rect(pads["MON-16"]["at"][0], pads["MON-16"]["at"][1], THANGKA_WALL[0], THANGKA_WALL[1], math.sin(th), math.cos(th), 3.0))
    for (gx, gy), r in GATES:
        blocked.append(rect(gx, gy, 2 * r, 2 * r, 0.0, -1.0))
    if os.path.exists(STEPS):  # the 1,080 steps' flights, landings and forecourt, 2 m clear; the gate at their top's level
        st = json.load(open(STEPS, encoding="utf-8"))
        for ln in st["lanes"]:
            (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
            blocked.append(rect(fx + ux * L / 2, fy + uy * L / 2, W, L, ux, uy, 2.0))
        if "MON-17" in pads:
            pads["MON-17"]["level"] = st["top"]["z"]
    if os.path.exists(GORGE):  # the Gorge Stair's flights and landings up the west face to the West Gate, 2 m clear; the
        # houses across its top and its rest gallery (its `things`)
        gj = json.load(open(GORGE, encoding="utf-8"))
        for ln in gj["lanes"]:
            (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
            blocked.append(rect(fx + ux * L / 2, fy + uy * L / 2, W, L, ux, uy, 2.0))
        for th in gj.get("things", []):
            f_ = math.radians(float(th["facing"]))
            size = (8.0, 2.5) if th.get("kind") == "rest_gallery" else (6.0, 6.0)
            blocked.append(rect(float(th["at"][0]), float(th["at"][1]), size[0], size[1], math.sin(f_), math.cos(f_), 2.0))
    if os.path.exists(GONPA):  # the way up from the South Gate to the courtyard's passage, its flights and landings 2 m clear
        for ln in json.load(open(GONPA, encoding="utf-8"))["lanes"]:
            (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
            blocked.append(rect(fx + ux * L / 2, fy + uy * L / 2, W, L, ux, uy, 2.0))
    levels = [ROWS[0] + k * ROW_RISE for k in range(int((ROWS[1] - ROWS[0]) / ROW_RISE) + 1)]
    rows = [contour(Z, z, BOX) for z in levels]
    placed, built = [], []

    def commit(s, kind, row, **extra):
        placed.append(s["rect"])
        built.append(dict(s=s, kind=kind, row=row, z=levels[row], **extra))

    # 1. The khamtsen, each hall between its two ranges, round the south flank's lower rows, spread along it
    lower_rows = [k for k, z in enumerate(levels) if z < MIDDLE]
    for gi, name in enumerate(GROUPS):
        first = GROUP_ROWS[gi % len(GROUP_ROWS)]
        done = False
        for row in [first] + [k for k in lower_rows if k != first]:
            pts = [p for p in rows[row] if p[0] >= FACE_X]
            if not pts:
                continue
            target = int(len(pts) * (gi + 0.5) / len(GROUPS))
            for k0 in sorted(range(len(pts)), key=lambda k: abs(k - target))[:600]:
                members, k, last = [], k0, None
                for kind in ("M3", "K", "M3"):
                    if last is not None:
                        need = SIZE[last[1]][0] / 2 + SIZE[kind][0] / 2 + 2.0
                        while k < len(pts) and math.hypot(pts[k][0] - last[0][0], pts[k][1] - last[0][1]) < need:
                            k += 1
                        if k >= len(pts) or math.hypot(pts[k][0] - last[0][0], pts[k][1] - last[0][1]) > need + 8.0:
                            break
                    s = site(Z, pts[k][0], pts[k][1], kind, blocked, placed + [m[0]["rect"] for m in members])
                    if s is None:
                        break
                    members.append((s, kind))
                    last = (pts[k], kind)
                if len(members) == 3:
                    for s, kind in members:
                        commit(s, kind, row, group=name)
                    done = True
                    break
            if done:
                break
        if not done:
            print("monastery: WARNING: no room for the %s khamtsen" % name)

    # 2. The M1 up the west face, each row its share spread along it; on the face (`stack`) first a house straight up the
    # fall line from each of the row below's where the contour and the ground let it, its front a metre or two behind
    # that one's back and its floor at about that one's roof, so the roof is its yard and its podium stands behind it
    # (chapter 03, 6.9: "stacked so that each roof is the next house's yard"; M3 sprint 3, step 5)
    def spread(kind, row_ids, total, part, stack=False):
        left = total
        below = []
        for i, k in enumerate(row_ids):
            if left <= 0:
                break
            pts = part(rows[k])
            if not pts:
                continue
            quota = math.ceil(left / (len(row_ids) - i))
            step = max(arc_len(pts) / quota, SIZE[kind][0] + (YARD if kind == "M2" else 0.0) + GAP)
            last, n, here = None, 0, []
            for s0 in (below if stack else []):
                if n >= quota:
                    break
                f0 = math.radians(s0["facing"])
                bx, by = s0["c"][0] - math.sin(f0) * SIZE[kind][1] / 2, s0["c"][1] - math.cos(f0) * SIZE[kind][1] / 2  # its back
                x, y = min(pts, key=lambda q: math.hypot(q[0] - bx, q[1] - by))
                if math.hypot(x - bx, y - by) > STACK_REACH:
                    continue
                s = site(Z, x, y, kind, blocked, placed)
                if s is None:
                    continue
                commit(s, kind, k, stacked=True)
                here.append(s)
                n += 1
                left -= 1
            for x, y in pts:
                if n >= quota:
                    break
                if last is not None and math.hypot(x - last[0], y - last[1]) < step * rng.uniform(0.8, 1.05):
                    continue
                s = site(Z, x, y, kind, blocked, placed)
                if s is None:
                    continue
                commit(s, kind, k)
                here.append(s)
                last, n = (x, y), n + 1
                left -= 1
            below = here
        return left

    face_rows = [k for k, z in enumerate(levels) if z <= FACE_TOP]
    m1_left = spread("M1", face_rows, COUNTS["M1"], lambda pts: [p for p in pts if p[0] < FACE_X], stack=True)
    # 3. The M2: the lower zone's round the south flank, the middle zone's among the halls (any side)
    lower = [k for k, z in enumerate(levels) if z < MIDDLE]
    middle = [k for k, z in enumerate(levels) if MIDDLE <= z <= ROWS[1] - 2.0]
    m2_left = spread("M2", lower, M2_LOWER, lambda pts: [p for p in pts if p[0] >= FACE_X])
    m2_left = spread("M2", middle, COUNTS["M2"] - M2_LOWER + m2_left, lambda pts: pts)
    # 4. What did not fit, packed into the rows anywhere (a warning if even that fails)
    for kind, n in (("M1", m1_left), ("M2", m2_left)):
        rid = 0
        while n > 0 and rid < len(rows):
            for x, y in rows[rid]:
                if n <= 0:
                    break
                s = site(Z, x, y, kind, blocked, placed)
                if s is not None:
                    commit(s, kind, rid)
                    n -= 1
            rid += 1
        if n > 0:
            print("monastery: WARNING: %d %s houses found no place" % (n, kind))
    # ids and variants: the M1 H-MON-001 to 060, the M2 061 to 104, the ranges 105 to 112, the khamtsen MON-26a to d
    houses, khamtsen = [], []
    nums = {"M1": 0, "M2": COUNTS["M1"], "M3": COUNTS["M1"] + COUNTS["M2"]}
    for bd in built:
        s, kind = bd["s"], bd["kind"]
        quarter = "gonpa.gate" if bd["z"] < MIDDLE else "gonpa.tsokchen"
        w, d = SIZE[kind]
        if kind == "K":
            k = len(khamtsen)
            khamtsen.append({"id": "MON-26%s" % "abcd"[k], "name_en": "Khamtsen hall, the %s house" % bd["group"], "type": "khamtsen hall",
                             "district": "gonpa", "quarter": quarter, "kit": "mon26_regional_house", "seed": k + 1,
                             "pos": [round(s["c"][0], 2), round(s["c"][1], 2), round(s["level"] - 0.4, 1)], "rot_deg": round(s["facing"], 1),
                             "footprint": [w, d], "storeys": 2, "enterable": False, "row": bd["row"],
                             "pad": [round(s["g"][0], 2), round(s["g"][1], 2), s["W"], s["D"]], "apron": APRON})
            continue
        nums[kind] += 1
        h = {"id": "H-MON-%03d" % nums[kind], "type": kind, "district": "gonpa", "quarter": quarter, "seed": 0,
             "pos": [round(s["c"][0], 2), round(s["c"][1], 2), round(s["level"] - 0.4, 1)], "rot_deg": round(s["facing"], 1),
             "footprint": [w, d], "storeys": 2, "enterable": False, "row": bd["row"], "apron": APRON}
        if kind == "M3":
            h["kit"] = "monk_range_m3"
            h["group"] = bd["group"]
        if kind == "M2":
            h["pad"] = [round(s["g"][0], 2), round(s["g"][1], 2), s["W"], s["D"]]
        if kind == "M1" and s["c"][0] < FACE_X:  # on the west face: its timber gallery over the gorge (the kit's
            # monk_house_face; chapter 03, 6.9: galleries 1-1.5 m on joists; M3 sprint 3, step 5), its podium its pad's
            # dry-stone fill walls (tools/town/walls.py: the 2-6 m of chapter 03's podia, IN-08)
            h["kit"] = "monk_house_face"
            if bd.get("stacked"):
                h["stacked"] = True
        houses.append(h)
    # each its variant, none like the nearest of its kind (within 25 m, or failing that 18, or 13)
    for h in houses:
        n_var = VARIANTS[h["type"]]
        dist = lambda o: math.hypot(o["pos"][0] - h["pos"][0], o["pos"][1] - h["pos"][1])
        same = [o for o in houses if o is not h and o["type"] == h["type"] and o["seed"]]
        for radius in (25.0, 18.0, 13.0):
            free = [v for v in range(1, n_var + 1) if v not in {o["seed"] for o in same if dist(o) < radius}]
            if free:
                break
        else:
            free = [max(range(1, n_var + 1), key=lambda v: min([dist(o) for o in same if o["seed"] == v] or [1e9]))]
        h["seed"] = rng.choice(free)
    # the hero monk's house carved (chapter 04, 3.7; M3 sprint 5, step 9): its kit the face house of its own variant with its
    # store and cell, `monk_house_face_in` (../tibet-blender export_types.py, built from that variant's seed)
    for h in houses:
        if h["id"] == HERO_CELL[0]:
            assert h["seed"] == HERO_CELL[1], "%s's variant moved: rebuild the kit's monk_house_face_in from v%d" % (h["id"], h["seed"])
            h["kit"], h["seed"], h["enterable"], h["variant"] = "monk_house_face_in", 1, True, HERO_CELL[1]  # (its kit file's _v1; the variant it was built from)
    # an M2's yard is on the side its variant gives (the kit's monk_house: v2, v4 and v6 on its +x, the others on its -x):
    # its pad the house and the yard together, where the rows reserved them; the house itself half a yard off its middle
    for h in houses:
        if h["type"] != "M2":
            continue
        cx, cy = h["pad"][0], h["pad"][1]
        th = math.radians(h["rot_deg"])
        ax, ay = -math.cos(th), math.sin(th)  # the kit's +x in the town grid
        ys = 1.0 if h["seed"] % 2 == 0 else -1.0
        h["pos"][0], h["pos"][1] = round(cx - ax * ys * YARD / 2, 2), round(cy - ay * ys * YARD / 2, 2)
    # the hero monk's house: a level step before its front, and its way from the 1,080 steps' forecourt to its side (ISS-214)
    way_lanes, ways = [], {}
    hero = next((h for h in houses if h["id"] == HERO_CELL[0]), None)
    if hero is not None and os.path.exists(STEPS):
        th = math.radians(hero["rot_deg"])
        hero["pad"] = [round(hero["pos"][0] + math.sin(th) * HERO_STEP / 2, 2), round(hero["pos"][1] + math.cos(th) * HERO_STEP / 2, 2),
                       SIZE["M1"][0], SIZE["M1"][1] + HERO_STEP]
        way_lanes, ways = hero_way(Z, hero, houses, khamtsen + extra, pads, halls, kora)
    # 5. The wall MON-21: WALL_LINE's runs at 1 m, the East Gate's range met at its ends, broken at the Upper Gate's door and
    # where any building or pad stands on its line
    def ends(hid):  # a range's two ends along its width, nearer first to the run's last point
        pd = pads[hid]
        b = next(o for o in halls if o["id"] == hid)
        th = math.radians(pd["facing"])
        ax, ay = -math.cos(th), math.sin(th)
        hw = b["footprint"][0] / 2
        return [(pd["at"][0] - ax * hw, pd["at"][1] - ay * hw), (pd["at"][0] + ax * hw, pd["at"][1] + ay * hw)]
    line = []
    for i, wp in enumerate(WALL_LINE):
        if wp == "MON-19":
            e = ends("MON-19")
            e.sort(key=lambda q: math.hypot(q[0] - line[-1][0], q[1] - line[-1][1]))
            line += [e[0], None, e[1]]  # (None: the range itself, no wall)
        else:
            line.append(wp)
    stand = [rect(h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1], math.sin(math.radians(h["rot_deg"])), math.cos(math.radians(h["rot_deg"])), 1.0)
             for h in houses + khamtsen + extra if h["type"] != "wheel arcade"]
    # the Gönkor's galleries stand on the line, their walls its length there: the wall run to each one's ends and no further
    # (until 11 Oct 2026 broken a metre round them as round a house, a 2 m gap at each end)
    stand += [rect(g["pos"][0], yl, GAL_LEN - 0.5, 2.0, 0.0, -1.0) for g in extra if g["type"] == "wheel arcade"]
    for ln in way_lanes:  # (and where the hero monk's house's way crosses its line: a gap)
        (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
        stand.append(rect(fx + ux * L / 2, fy + uy * L / 2, W + 1.0, L, ux, uy))
    for hid, pd in pads.items():
        b = next((o for o in halls if o["id"] == hid), None)
        if b is not None:
            th = math.radians(pd["facing"])
            stand.append(rect(pd["at"][0], pd["at"][1], b["footprint"][0], b["footprint"][1], math.sin(th), math.cos(th), 1.0))
    inside = lambda x, y, q: all(((q[(k + 1) % 4][0] - q[k][0]) * (y - q[k][1]) - (q[(k + 1) % 4][1] - q[k][1]) * (x - q[k][0])) >= 0 for k in range(4)) or \
        all(((q[(k + 1) % 4][0] - q[k][0]) * (y - q[k][1]) - (q[(k + 1) % 4][1] - q[k][1]) * (x - q[k][0])) <= 0 for k in range(4))
    walls, run = [], []
    for a, b in zip(line, line[1:]):
        if a is None or b is None:  # a gate: the run ends
            if len(run) >= 2:
                walls.append(run)
            run = []
            continue
        n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1])))
        for k in range(n + 1):
            x, y = a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n
            if any(inside(x, y, q) for q in stand) or any(math.hypot(x - c[0], y - c[1]) < r for c, r in DOORS.values()):
                if len(run) >= 2:
                    walls.append(run)
                run = []
                continue
            if not run or math.hypot(x - run[-1][0], y - run[-1][1]) > 0.5:
                run.append([round(x, 2), round(y, 2), round(float(Z(x, y)), 2)])
    if len(run) >= 2:
        walls.append(run)
    wall_m = sum(len(r) for r in walls)
    json.dump({"about": "Dungkar Gönpa on the spur (tools/town/monastery.py; M2 sprint 13). `houses`: the monks' houses, each [id, type M1, M2 or M3, seed (the kit's variant), pos (its middle and its pad's level, the town grid), rot_deg (its front's bearing, down the fall line), footprint, row, apron (its level ground's margin round it: pads.py's footprint); an M2's pad, its yard's ground with its own: x, y, width, depth; an M3's kit and its khamtsen]. `buildings`: the four khamtsen halls (MON-26a to d), placed as the houses are, with their kit and pad (the portico's ground); MON-11's granary range MON-11G and the dogs' kennel MON-38, each on the median of its own ground (M3 sprint 3, step 4). `pads`: the halls' at the middle of their own ground (pads.py RAISED, MOVED and TURNED, world/town.gd monastery_pads), with their far form's kit; `was` chapter 02's level, `moved_from` its place. `follow`: on the ground as it is. `walls`: the wall MON-21's runs on the ground, each its height and its points at 1 m (a free wall of tools/town/walls.py, as Hejie's). tools/terrain/pads.py cuts the pads, tools/town/walls.py walls their podia, world/town.gd places them. Regenerated with the terrain.",
               "houses": houses, "buildings": khamtsen + extra, "pads": pads, "follow": FOLLOW, "lanes": kora + way_lanes, "ways": ways,
               "gonkor": {"walk_y": round(yw_, 2), "line": yl},
               "walls": [{"of": "MON-21", "h": WALL_H, "pts": r} for r in walls]}, open(OUT, "w", encoding="utf-8"), indent=1)
    rows_used = sorted({h["row"] for h in houses})
    count = lambda t, f=lambda h: True: sum(1 for h in houses if h["type"] == t and f(h))
    face = count("M1", lambda h: h["pos"][0] < FACE_X)
    rep = ["# Dungkar Gönpa on the spur", "",
           "_Written by `tools/town/monastery.py` (M2 sprint 13; plan chapter 02, D08, MON-01 to MON-41; chapter 03, 6.1 and 6.9) from the ground before the pads (`valley_shaped_1m`): the khamtsen and their ranges, the M1 up the west face, the M2 round the south flank and among the halls, on rows along the spur's contours inside the enclosure; the halls' pads and far forms._", "",
           "- %d khamtsen halls (MON-26a to d) with %d ranges M3 (H-MON-105 to 112): %s." % (len(khamtsen), count("M3"), ", ".join("%s on row %d" % (k["name_en"].split("the ")[1], k["row"]) for k in khamtsen)),
           "- %d M1 of %d, %d of them on the west face, on rows %d to %d (%.0f to %.0f m)." % (count("M1"), COUNTS["M1"], face,
                                                                                        min(h["row"] for h in houses if h["type"] == "M1"), max(h["row"] for h in houses if h["type"] == "M1"),
                                                                                        min(h["pos"][2] for h in houses if h["type"] == "M1"), max(h["pos"][2] for h in houses if h["type"] == "M1")),
           "- %d M2 of %d, %d in the lower zone and %d in the middle." % (count("M2"), COUNTS["M2"], count("M2", lambda h: h["quarter"] == "gonpa.gate"), count("M2", lambda h: h["quarter"] == "gonpa.tsokchen")),
           "- %d rows in all, from %.0f to %.0f m." % (len(rows_used), min(h["pos"][2] for h in houses), max(h["pos"][2] for h in houses)), "",
           "The halls' pads at the middle of their own ground: " + ", ".join("%s %.0f m (was %.0f)" % (k, v["level"], v["was"]) for k, v in sorted(pads.items()) if abs(v["level"] - v["was"]) >= 2.0 and not v.get("follow")) + ".",
           "Moved off too much fall: " + (", ".join("%s from (%.0f, %.0f) to (%.0f, %.0f)" % (k, v["moved_from"][0], v["moved_from"][1], v["at"][0], v["at"][1]) for k, v in sorted(pads.items()) if "moved_from" in v) or "none") + ".",
           "On the ground as it is: " + ", ".join(FOLLOW) + "; the thangka wall MON-16 its foot on its lowest ground, %.0f m." % pads.get("MON-16", {}).get("level", 0.0), "",
           "Far forms: " + ", ".join("%s %s" % (k, v["kit"]) for k, v in sorted(pads.items()) if "kit" in v) + ".", "",
           "The wall MON-21: %d m in %d runs, %.1f m high, broken at the East Gate's range, the Upper Gate's door and where a building stands on its line (chapter 03, 6.8: 1,050 m with the west face, whose houses are the wall)." % (wall_m, len(walls), WALL_H)]
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    end_ = ways.get(HERO_CELL[0], [[0.0, 0.0, 0.0]])[-1]
    rep_way = ("The hero monk's house %s: a %.1f m step before its door, its way from %s %d pieces (%d flights), %.0f m (ISS-214)." % (
        HERO_CELL[0], HERO_STEP, "the Gönkor's west end" if end_[1] < 0.0 else "the 1,080 steps' forecourt", len(way_lanes),
        sum(1 for ln in way_lanes if ln.get("flight")), sum(ln["length"] for ln in way_lanes))) if way_lanes else "The hero monk's house: no way found to its door."
    open(REPORT, "a", encoding="utf-8").write("\n" + rep_way + "\n")
    print("monastery: %d khamtsen and %d ranges, %d M1 (%d on the west face) and %d M2 houses on %d rows; %d halls' pads; %d m of wall; %s -> %s" % (
        len(khamtsen), count("M3"), count("M1"), face, count("M2"), len(rows_used), len(pads), wall_m, rep_way, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
