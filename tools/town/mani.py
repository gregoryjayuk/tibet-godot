#!/usr/bin/env python3
"""The barkor's mani wall, SHL-09 (plan chapter 02; chapter 03, 8.2, SC-03; M1 sprint 4, step 3): its 2 m segments along
its line down the middle of the Mani Lane, each set on the lane's bed there (tools/terrain/pads.py cuts it, level across,
following the ground along), and a pillar at each end for walkers to turn round clockwise, into
assets/generated/terrain/mani_walls.json for world/town.gd. The segments are the kit's four variants (mani_wall_seg_a to
_d), the one with an image and a skull one in eight; the ends mani_wall_end. And Pasang's pitch (SHL-27, the kit's
carver_pitch) against the wall's north face, where the gazetteer puts it along the wall, on the lane's bed (the
gazetteer's 2,700 m had left it floating 5 m over the lane; chapter 03's SH-06 has it by the wall).
Run: tools/py tools/town/mani.py   (tools/terrain/build.sh runs it after pads.py)
"""
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
import pads as P  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
OUT = os.path.join(GEN, "mani_walls.json")
SEG = 2.0


WEST_SINK = 0.45  # how far a western wall's segment sits down into the bed
WEST_SECTIONS = ((2.5, 62.0), (65.0, 127.0), (130.0, 192.0), (195.0, 260.0))  # along its bed (m): four walls with a way
# between, and room to go round the first's foot on the bed


def west_wall():
    """The western mani wall, SHL-10 (chapter 02: 260 m, the lingkor's west side): four walls in a line down the middle
    of the lingkor's bed (pads.py's STAIRS "SHL-10"), a way between each and the next, each its 2 m segments level and set
    down into the bed so the downhill end meets it, stepping up the slope, and a pillar at each of its ends. Going up the
    bed's west side and down its east keeps each on the right."""
    sid, a, b, width, kit, top_run = next(st for st in P.STAIRS if st[0].startswith("SHL-10"))
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    yaw = math.degrees(math.atan2(uy, ux))
    segs, ends = [], []
    k = 0
    for s0, s1 in WEST_SECTIONS:  # each section its segments down the bed's middle, a pillar at each of its ends
        n = int(round((s1 - s0 - 1.5) / SEG))
        for j in range(n):
            t = s0 + 0.75 + (j + 0.5) * (s1 - s0 - 1.5) / n
            z = a[2] + (b[2] - a[2]) * t / L
            h = (k * 2654435761 + 7) % 997 / 997.0
            file = "mani_wall_seg_d_v1" if h < 0.125 else ("mani_wall_seg_a_v1", "mani_wall_seg_b_v1", "mani_wall_seg_c_v1")[(k + 1) % 3]
            segs.append([round(a[0] + ux * t, 2), round(a[1] + uy * t, 2), round(z - WEST_SINK, 2), round(yaw, 2), file])
            k += 1
        for t in (s0 + 0.375, s1 - 0.375):
            z = a[2] + (b[2] - a[2]) * t / L
            ends.append([round(a[0] + ux * t, 2), round(a[1] + uy * t, 2), round(z - 0.3, 2), round(yaw, 2), "mani_wall_end_v1"])
    return {"id": "SHL-10", "segments": segs, "ends": ends, "half": 4.0, "sections": [list(q) for q in WEST_SECTIONS],
            "gloss": "A mani wall is kept on the right: the lingkor goes up the wall's west side and round, clockwise, as every way round a holy thing."}


SERCHU_ROAD = os.path.join(ROOT, "data", "serchu_road.json")
SERCHU_SINK = 0.15  # a road wall's segment set down so its lower end meets the bed (the Serchu road falls 11%)


def serchu_wall():
    """The road mani wall SER-15 on the Serchu road (M2 sprint 12, step 3; chapter 02: 90 m by (700, -320)): its 2 m
    segments down the middle of the road widened round it (tools/terrain/serchu_road.py `mani_wall`), each turned along
    the road there and set down SERCHU_SINK so its lower end meets the falling bed, a pillar at each end. Going down the
    road keeps it on the right by its south side, coming up by its north. None without the road."""
    if not os.path.exists(SERCHU_ROAD):
        return None
    mw = json.load(open(SERCHU_ROAD, encoding="utf-8")).get("mani_wall")
    if not mw or len(mw["line"]) < 2:
        return None
    line = mw["line"]
    cum = [0.0]
    for a, b in zip(line[:-1], line[1:]):
        cum.append(cum[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))

    def at(t):
        k = max(1, min(len(line) - 1, int(np.searchsorted(cum, t))))
        a, b = line[k - 1], line[k]
        f = (t - cum[k - 1]) / max(cum[k] - cum[k - 1], 1e-6)
        return [a[i] + (b[i] - a[i]) * f for i in range(3)], math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
    total = cum[-1]
    n = int(round((total - 1.5) / SEG))
    segs = []
    for k in range(n):
        q, yaw = at(0.75 + (k + 0.5) * (total - 1.5) / n)
        h = (k * 2654435761 + 11) % 997 / 997.0
        file = "mani_wall_seg_d_v1" if h < 0.125 else ("mani_wall_seg_a_v1", "mani_wall_seg_b_v1", "mani_wall_seg_c_v1")[(k + 2) % 3]
        segs.append([round(q[0], 2), round(q[1], 2), round(q[2] - SERCHU_SINK, 2), round(yaw, 2), file])
    ends = []
    for t in (0.375, total - 0.375):
        q, yaw = at(t)
        ends.append([round(q[0], 2), round(q[1], 2), round(q[2] - 0.3, 2), round(yaw, 2), "mani_wall_end_v1"])
    return {"id": mw["id"], "segments": segs, "ends": ends, "half": float(mw["width"]) / 2.0,
            "gloss": "A mani wall is kept on the right: going down the road, by its south side; coming up, by its north."}


TODE_WALL = ((-344.6, 405.2), (-335.4, 494.8))  # TOD-23's line (chapter 02: 90 m about (-340, 450), continuing the western wall
# up the lingkor and the Herd Lane towards the Tathang chorten THG-08): from the western wall's line on north through Tödé's
# west edge, clear of its houses and paths (tools/town/tode.py)
TODE_SINK = 0.45


def tode_wall():
    """The Tödé mani wall TOD-23 (M3 sprint 4, step 5): its 2 m segments up its line on the ground the pads leave (the
    padded raster), each level and set down TODE_SINK so its lower end meets the slope, stepping up it as the western
    wall does, and a pillar at each end. Going up its west side keeps it on the right."""
    sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
    from terrain_site import Site
    site_ = Site.load()
    g = site_.read(os.path.join(GEN, "valley_padded_1m.tif"))
    Z = lambda x, y: float(g.z(np.asarray(x, float), np.asarray(y, float)) - site_.shift)
    (ax, ay), (bx, by) = TODE_WALL
    L = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / L, (by - ay) / L
    yaw = math.degrees(math.atan2(uy, ux))
    n = int(round((L - 1.5) / SEG))
    segs = []
    for k in range(n):
        t = 0.75 + (k + 0.5) * (L - 1.5) / n
        x, y = ax + ux * t, ay + uy * t
        h = (k * 2654435761 + 23) % 997 / 997.0
        file = "mani_wall_seg_d_v1" if h < 0.125 else ("mani_wall_seg_a_v1", "mani_wall_seg_b_v1", "mani_wall_seg_c_v1")[(k + 1) % 3]
        segs.append([round(x, 2), round(y, 2), round(Z(x, y) - TODE_SINK, 2), round(yaw, 2), file])
    ends = []
    for t in (0.375, L - 0.375):
        x, y = ax + ux * t, ay + uy * t
        ends.append([round(x, 2), round(y, 2), round(Z(x, y) - 0.3, 2), round(yaw, 2), "mani_wall_end_v1"])
    return {"id": "TOD-23", "segments": segs, "ends": ends, "half": 3.0,
            "gloss": "A mani wall is kept on the right: up through Tödé on its west side, down on its east, as every way round a holy thing."}


def main():
    lane = json.load(open(os.path.join(GEN, "barkor_lane.json")))
    prof = np.array(lane["profile"])
    (fx, fy), (ux, uy) = lane["from"], lane["dir"]
    (ax, ay), (bx, by) = P.BARKOR["from"], P.BARKOR["to"]
    L = math.hypot(bx - ax, by - ay)
    s0 = math.hypot(ax - fx, ay - fy)  # the wall starts this far up the lane
    n = int(round(L / SEG))
    yaw = math.degrees(math.atan2(uy, ux))
    segs = []
    for k in range(n):
        sl = s0 + (k + 0.5) * L / n
        x, y = fx + ux * sl, fy + uy * sl
        z = float(np.interp(sl, prof[:, 0], prof[:, 1]))
        h = (k * 2654435761) % 997 / 997.0  # a repeatable pick of variant
        file = "mani_wall_seg_d_v1" if h < 0.125 else ("mani_wall_seg_a_v1", "mani_wall_seg_b_v1", "mani_wall_seg_c_v1")[k % 3]
        segs.append([round(x, 2), round(y, 2), round(z, 2), round(yaw, 2), file])
    ends = []
    for sl in (s0 - 0.75, s0 + L + 0.75):
        x, y = fx + ux * sl, fy + uy * sl
        ends.append([round(x, 2), round(y, 2), round(float(np.interp(sl, prof[:, 0], prof[:, 1])), 2), round(yaw, 2), "mani_wall_end_v1"])
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    pb = next(b for b in town["buildings"] if b["id"] == "SHL-27")
    sp = (pb["pos"][0] - ax) * ux + (pb["pos"][1] - ay) * uy  # along the wall from its west end
    nx, ny = -uy, ux  # the wall's north side, to its left looking east
    off = P.BARKOR["wall"] / 2 + 0.7  # the pitch's back (kit/sacred.py carver_pitch, 0.7 m behind its middle) on the wall
    px, py = ax + ux * sp + nx * off, ay + uy * sp + ny * off
    pitch = {"id": "SHL-27", "at": [round(px, 2), round(py, 2), round(float(np.interp(s0 + sp, prof[:, 0], prof[:, 1])), 2),
                                    round(math.degrees(math.atan2(nx, ny)) % 360.0, 1), "carver_pitch_v1"]}
    west = west_wall()
    sw = serchu_wall()  # the Serchu road's (M2 sprint 12, step 3)
    tw = tode_wall()  # Tödé's (M3 sprint 4, step 5)
    json.dump({"about": "The barkor's mani wall (SHL-09) from tools/town/mani.py: its 2 m segments and its two end pillars, each x, y, z (the town grid, the Mani Lane's bed), the yaw of its length from east (degrees, anticlockwise), its kit file; Pasang's pitch (SHL-27) against its north face: x, y, z, its facing (clockwise from north, as the gazetteer's rot_deg), its kit file. And the western mani wall (SHL-10, M2 sprint 6, step 6) stepping up the lingkor's west side on its bed (tools/terrain/pads.py STAIRS), the way up on its west, a segment set down WEST_SINK into the bed so its lower end meets it; its gloss for a walker going the wrong way (world/mani_wall.gd). And the Serchu road's SER-15 (M2 sprint 12, step 3) down the middle of the road widened round it (data/serchu_road.json). And Tödé's TOD-23 (M3 sprint 4, step 5) stepping up through its west edge on the ground.",
               "walls": [{"id": P.BARKOR["id"], "segments": segs, "ends": ends, "pitch": pitch}, west] + ([sw] if sw else []) + [tw]}, open(OUT, "w"), indent=1)
    print("mani: TOD-23, %d segments over 90 m stepping up %.0f m through Tödé's west edge" % (len(tw["segments"]), tw["segments"][-1][2] - tw["segments"][0][2]))
    if sw:
        print("mani: SER-15, %d segments over %.0f m down the Serchu road" % (len(sw["segments"]), math.hypot(sw["ends"][1][0] - sw["ends"][0][0], sw["ends"][1][1] - sw["ends"][0][1])))
    print("mani: SHL-10, %d segments over 260 m stepping up %.0f m on the lingkor's west side" % (len(west["segments"]), west["segments"][-1][2] - west["segments"][0][2]))
    rise = segs[-1][2] - segs[0][2]
    print("mani: %s, %d segments over %.0f m, rising %.1f m from west to east, two end pillars, Pasang's pitch at %s -> %s" % (
        P.BARKOR["id"], len(segs), L, rise, pitch["at"][:3], os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
