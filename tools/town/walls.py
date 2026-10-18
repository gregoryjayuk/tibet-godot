#!/usr/bin/env python3
"""The retaining walls' runs (plan chapter 03, 11.4, IN-07; kit step K6): where every pad (tools/terrain/pads.py) meets
ground more than WALL_MIN higher or lower, a dry-stone wall along its edge, into assets/generated/terrain/walls.json for
the kit's export_walls.py.

Each pad's edge is walked every STEP metres. A named building's is its footprint grown by the apron; beyond it the padded
ground falls or rises over the pad's batter, and the ground REACH metres out is the wall's other end. A town builder's
house's (IMP-023) is its level ground's own: the apron, its yard before its front, and where a neighbour holds the
ground first, the line where the two meet (pads.py's p, found along the edge's normal); the ground REACH_SHARP beyond,
past the terrain's step, is the other end; two such pads within SOFT of each other meet in a ramp and no wall. A fill
wall stands where the pad is the higher (its top the pad, its foot the ground below); a cut wall where the ground beyond
is the higher (its foot the pad, its top that ground). Consecutive points of one kind make a run; runs shorter than 2 m
are dropped. Where two pads meet, each walks its own; the lower one's cut wall is the higher one's fill, and the fill is
kept.
A yard's fill wall carries a parapet where it stands PARAPET_MIN or more (a back alley or the slope below; Greg, 7 Oct
2026: the space round the houses), and every wall SOLID_MIN high or more is solid (export_walls.py gives it collision):
the terrain's step under it is a metre wide on the lattice and the wall's top covers it (`strip`: how far its paved top
reaches back over its higher side).
No wall stands in a stair's corridor (pads.py's STAIRS, its width and a metre and a half either side): the stair's
bed and cheek walls make that edge (a wall on Tsongra's upper edge had crossed the Sky Stair's first flight). Nor in a
lane (the builder's side lanes, the flights between yards, pads.py's pass 5b): each lane's own sides are walked
instead, a wall wherever its bed and the ground beside it differ by SOFT, but where a house stands beside it (its wall is
the lane's side), and beside its flight on the lower side (the flight's own side is the wall there, with its parapet:
`lane_sides` tells the kit's export_lanes.py where).
A pad in levels (pads.py's LEVELS: Tsongra) has no apron on the edge its levels share: that wall stands on the edge
itself, along the step, with a gap for the kit's flight (TSONGRA_GAP) (sprint 3, step 6).
Run: tools/py tools/town/walls.py   (tools/terrain/build.sh runs it after pads.py)
"""
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
from terrain_site import Site  # noqa: E402
import pads as P  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
OUT = os.path.join(GEN, "walls.json")
STEP, REACH, WALL_MIN, MIN_RUN = 1.0, P.BATTER + 0.8, P.WALL_MIN, 2.0
REACH_SHARP = P.CUT_OUT + 0.6  # beyond a yard's wall line: past the terrain's step
PARAPET_MIN, SOLID_MIN = P.TALL, 0.6  # a yard's or a lane's fill wall this high carries a parapet; any wall this high is solid
STRIP = {"named": 0.5, "yard": 1.5, "lane": 1.0}  # how far a wall's paved top reaches back over its higher side
LEVEL_GAP = {"SHL-01": (-6.2, 6.2)}  # along the shared edge, x from the pad's middle: the flight between the levels
PARAPET, SOLID = 1, 2  # a point's flags
GARDENS = os.path.join(ROOT, "data", "gardens.json")  # the lane to the Gorge Rim Lookout and its gardens' walls


def _in_band(ln, x, y, grow):
    """Whether (x, y) is within a lane's bed, `grow` beyond its sides and ends."""
    sl = (x - ln["from"][0]) * ln["dir"][0] + (y - ln["from"][1]) * ln["dir"][1]
    lat = -(x - ln["from"][0]) * ln["dir"][1] + (y - ln["from"][1]) * ln["dir"][0]
    return -grow <= sl <= ln["length"] + grow and abs(lat) <= ln["width"] / 2 + grow


def edge_points(fw, fd, ext, r):
    """A pad's level ground's edge in its frame, about every STEP metres anticlockwise: (u, v, nu, nv), the outward
    normal; its footprint, `ext` more before its front, grown by `r` with rounded corners (as pads.py's pad_dist)."""
    a, vf, vb = fw / 2, -(fd / 2 + ext), fd / 2
    pts = []

    def line(u0, v0, u1, v1, nu, nv):
        n = max(1, int(round(math.hypot(u1 - u0, v1 - v0) / STEP)))
        for i in range(n):
            pts.append((u0 + (u1 - u0) * i / n, v0 + (v1 - v0) * i / n, nu, nv))

    def arc(cu, cv, a0):
        k = max(1, int(round(r * math.pi / 2 / STEP)))
        for i in range(k):
            ang = math.radians(a0 + 90.0 * i / k)
            pts.append((cu + r * math.cos(ang), cv + r * math.sin(ang), math.cos(ang), math.sin(ang)))
    line(-a, vf - r, a, vf - r, 0.0, -1.0)
    arc(a, vf, -90.0)
    line(a + r, vf, a + r, vb, 1.0, 0.0)
    arc(a, vb, 0.0)
    line(a, vb + r, -a, vb + r, 0.0, 1.0)
    arc(-a, vb, 90.0)
    line(-a - r, vb, -a - r, vf, -1.0, 0.0)
    arc(-a, vf, 180.0)
    return pts


def _inside(ln, x, y, margin=0.15):
    """Whether (x, y) is well inside a lane's bed: beyond its ends' and sides' lines by `margin` (not on its edge)."""
    sl = (x - ln["from"][0]) * ln["dir"][0] + (y - ln["from"][1]) * ln["dir"][1]
    lat = -(x - ln["from"][0]) * ln["dir"][1] + (y - ln["from"][1]) * ln["dir"][0]
    return margin < sl < ln["length"] - margin and abs(lat) < ln["width"] / 2 - margin


def _way(ln):
    """The way a lane is a stretch of: its id less its last part (R-01S.12 of R-01S, SER-11.p2.3 of the path's second leg)."""
    return str(ln.get("id", "")).rsplit(".", 1)[0]


def main():
    site = Site.load()
    ground = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    z_at = lambda x, y: ground.z(np.asarray(x, float), np.asarray(y, float)) - site.shift
    pads = P.pad_list()
    yds = P.yards()
    levels = [q for q in pads if "." in q[0]]  # the pads of a pad in levels: their shared edges are walked apart

    def on_shared(pid, x, y):
        base = pid.split(".")[0]
        for q in levels:
            if q[0] != pid and q[0].split(".")[0] == base and abs(x - q[1]) <= q[4] / 2 + P.APRON + 0.01 and abs(y - q[2]) <= q[5] / 2 + P.APRON + 0.01:
                return True
        return False

    def in_stair(x, y):
        for sid, a, b, width, kit, top_run in P.STAIRS:
            ax, ay = b[0] - a[0], b[1] - a[1]
            L2 = ax * ax + ay * ay
            t = ((x - a[0]) * ax + (y - a[1]) * ay) / L2
            if -0.05 <= t <= 1.0 + top_run / math.sqrt(L2) and math.hypot(x - (a[0] + t * ax), y - (a[1] + t * ay)) < width / 2 + 1.5:
                return True
        return False
    side_lanes = P.lane_list()  # the builder's side lanes and the flights between yards (pads.py wrote them)
    lanes = side_lanes + P.lane_list(barkor=True)[len(side_lanes):] + P.ramp_lanes()  # and the Mani Lane, the north ramp's legs

    def in_lane(x, y, grow=0.3, but=None, other=None):
        """Within a lane's band (but `but`); with `other`, only a lane of another way than it (_way)."""
        for ln in lanes:
            if ln is but or (other is not None and _way(ln) == other):
                continue
            sl = (x - ln["from"][0]) * ln["dir"][0] + (y - ln["from"][1]) * ln["dir"][1]
            lat = -(x - ln["from"][0]) * ln["dir"][1] + (y - ln["from"][1]) * ln["dir"][0]
            if -0.5 - grow <= sl <= ln["length"] + 0.5 + grow and abs(lat) <= ln["width"] / 2 + grow:
                return True
        return False

    def in_building(x, y):
        for pid, px, py, pz, fw, fd, rot in pads:
            u, v = P.frame(rot, x - px, y - py)
            if abs(u) <= fw / 2 + 0.2 and abs(v) <= fd / 2 + 0.2:
                return True
        return False

    near = {}  # a pad's neighbours that could claim its ground first
    for q in pads:
        r = math.hypot(q[4], q[5]) / 2 + yds.get(q[0], 0.0) + P.APRON + 1.0
        near[q[0]] = [o for o in pads if o is not q and math.hypot(o[1] - q[1], o[2] - q[2]) < r + math.hypot(o[4], o[5]) / 2 + yds.get(o[0], 0.0) + P.APRON]

    def p_of(q, x, y):
        u, v = P.frame(q[6], np.array([x - q[1]]), np.array([y - q[2]]))
        d, p, s = P.pad_dist(q[4], q[5], yds.get(q[0], 0.0), u, v)
        return float(p[0]), float(d[0])

    pts = []  # (x, y, ox, oy, kind, foot, top, pad level, edge id, flags, strip)
    for q in pads:
        pid, px, py, pz, fw, fd, rot = q
        th = math.radians(rot - 180.0)
        c, s = math.cos(th), math.sin(th)
        sharp = pid in yds
        yd = yds.get(pid, 0.0)
        edge = edge_points(fw, fd, max(yd - P.APRON, 0.0), P.APRON)
        for u, v, nu, nv in edge:
            x, y = px + u * c + v * s, py - u * s + v * c
            ox, oy = nu * c + nv * s, -nu * s + nv * c
            kind, zb, other_pad, strip = None, float("nan"), False, STRIP["yard" if sharp else "named"]
            if sharp:
                rival = [o for o in near[pid] if p_of(o, x, y)[0] < p_of(q, x, y)[0]]
                if rival:  # a neighbour holds the edge's ground first: the wall stands where the two meet
                    du, dv = min(max(u, -fw / 2), fw / 2), min(max(v, -fd / 2), fd / 2)  # the footprint's edge, its own
                    ix, iy = px + du * c + dv * s, py - du * s + dv * c
                    lo_, hi_ = 0.0, 1.0
                    for _ in range(24):
                        m = (lo_ + hi_) / 2
                        mx, my = ix + (x - ix) * m, iy + (y - iy) * m
                        mine = p_of(q, mx, my)[0]
                        if all(p_of(o, mx, my)[0] >= mine for o in rival):
                            lo_ = m
                        else:
                            hi_ = m
                    x, y = ix + (x - ix) * lo_, iy + (y - iy) * lo_
                    o = min(rival, key=lambda o_: p_of(o_, x + ox * 0.3, y + oy * 0.3)[0])
                    if p_of(o, x + ox * 0.3, y + oy * 0.3)[1] <= P.APRON + (P.JOIN if o[0] in yds else 0.0):  # its level ground there
                        zb, other_pad = o[3], True
                elif abs(nv) > 0.7:  # before or behind it, a neighbour's level ground within JOIN: both run on to where they meet
                    for e in np.arange(0.1, P.JOIN + 0.05, 0.1):
                        ex_, ey_ = x + ox * e, y + oy * e
                        mine = p_of(q, ex_, ey_)[0]
                        hit = [o for o in near[pid] if o[0] in yds and p_of(o, ex_, ey_)[0] < mine]
                        if hit:
                            o = min(hit, key=lambda o_: p_of(o_, ex_, ey_)[0])
                            if p_of(o, ex_, ey_)[1] <= P.APRON + P.JOIN:
                                x, y, zb, other_pad = ex_ - ox * 0.05, ey_ - oy * 0.05, o[3], True
                            break
                if not other_pad:
                    zb = float(z_at(x + ox * REACH_SHARP, y + oy * REACH_SHARP))
            else:
                zb = float(z_at(x + ox * REACH, y + oy * REACH))
            if "." in pid and on_shared(pid, x, y):
                continue  # the shared edge: its wall is below, on the step itself
            if in_stair(x, y) or in_lane(x, y) or in_building(x + ox * 0.3, y + oy * 0.3):
                continue
            need = P.SOFT if sharp else WALL_MIN  # a builder's house's: a ramp under SOFT (pads.py)
            if np.isfinite(zb) and abs(zb - pz) >= need:
                kind = "fill" if zb < pz else "cut"
            if not kind:
                pts.append(None)
                continue
            h = abs(zb - pz)
            flags = ((SOLID if h >= SOLID_MIN else 0) | (PARAPET if kind == "fill" and h >= PARAPET_MIN else 0)) if sharp else 0
            pts.append((x, y, ox, oy, kind, float(min(zb, pz)), float(max(zb, pz)), pz, pid, flags,
                        (strip if kind == "fill" else (P.CUT_OUT + 1.0 if sharp else STRIP["named"]))))
        pts.append(None)  # an edge's end
    # The lower pad's cut wall where a higher pad's fill wall stands: dropped.
    fills = np.array([(p[0], p[1], p[6]) for p in pts if p and p[4] == "fill"]) if any(p and p[4] == "fill" for p in pts) else np.zeros((0, 3))
    for i, p in enumerate(pts):
        if p and p[4] == "cut" and len(fills):
            dd = np.hypot(fills[:, 0] - p[0], fills[:, 1] - p[1])
            if np.any((dd < 1.2) & (fills[:, 2] >= p[6] - 0.4)):
                pts[i] = None
    runs, cur = [], []
    for p in pts + [None]:
        if p and cur and cur[-1][4] == p[4] and cur[-1][8] == p[8] and math.hypot(cur[-1][0] - p[0], cur[-1][1] - p[1]) < 2.5 * STEP:
            cur.append(p)
            continue
        if len(cur) * STEP >= MIN_RUN:
            runs.append(cur)
        cur = [p] if p else []
    # The step between a pad's levels: a fill wall on the shared edge, from the lower level to the upper, but for the flight.
    for q in levels:
        for r in levels:
            if q[0].split(".")[0] != r[0].split(".")[0] or q[3] <= r[3] or abs(q[1] - r[1]) > 0.01:
                continue
            ye = (q[2] - q[5] / 2) if q[2] > r[2] else (q[2] + q[5] / 2)  # the upper pad's edge towards the lower
            oy = -1.0 if q[2] > r[2] else 1.0
            g0, g1 = LEVEL_GAP.get(q[0].split(".")[0], (0.0, 0.0))
            for xa, xb in ((q[1] - q[4] / 2, q[1] + g0), (q[1] + g1, q[1] + q[4] / 2)):
                n = int((xb - xa) / STEP)
                if n >= 2:
                    runs.append([(xa + (xb - xa) * i / n, ye, 0.0, oy, "fill", r[3], q[3], q[3], q[0], 0, STRIP["named"]) for i in range(n + 1)])
    # The lanes' own walls: along each side, where the bed and the ground beside it differ by SOFT, but beside a house
    # and on the lower side of a flight (its own side and parapet); each side's kinds for export_lanes.py.
    lane_sides = {}
    garden_h = float(json.load(open(GARDENS, encoding="utf-8")).get("wall_h", 2.5)) if os.path.exists(GARDENS) else 2.5
    for ln in lanes:
        (fx, fy), (ux, uy), L, W = ln["from"], ln["dir"], ln["length"], ln["width"]
        builder = ln in side_lanes
        road = bool(ln.get("road"))  # the Caravan Ramp's: walled as a side lane is, past the terrain's step behind its walls
        steps = bool(ln.get("steps"))  # the 1,080 steps' and the way to them (tools/town/dungrong.py): the same, their
        # walls solid; a parapet on a high fill but beside a piece with its own whitewashed walls (export_lanes.py)
        own_walls = steps and bool(ln.get("flight")) and ln["flight"].get("walls") in ("lime", "turn")
        garden = bool(ln.get("garden"))  # the lane to the Gorge Rim Lookout (tools/town/gardens.py): walled the whole way,
        if garden:  # each side one wall along the whole lane, below (a leg's own had left a slit at every bend)
            continue
        if ln.get("channel"):  # a river's bed cut down under its water (tools/town/serchu_mills.py): its banks, no walls
            continue
        if ln.get("gallery"):  # a gallery of the Gorge Stair (tools/town/gorge_stair.py): its own beams and rail, the rock
            continue
        if ln.get("ring"):  # the Bön chapel's circuit R-24 paved on its terrace (tools/town/tode_things.py): the terrace's own
            continue  # edges are walled, its paving none
        f = ln.get("flight") if builder else None
        s_lo, s_hi = (f["s"] - 0.3, ln["length"]) if f else (1.0, -1.0)
        sides = {}
        for side in (-1.0, 1.0):
            ox, oy = -uy * side, ux * side  # outward
            cur, marks = [], []
            if garden:  # one kind a side, the side's own (holding the bed up, or the slope back), so the wall runs unbroken
                ds = [float(z_at(fx + ux * t + ox * (W / 2 + 2.0), fy + uy * t + oy * (W / 2 + 2.0))) - float(P.lane_bed(ln, np.array([t]))[0])
                      for t in np.linspace(0.0, L, 9)]  # (beyond the metre carved behind its higher side's wall)
                gkind = "fill" if sum(ds) < 0.0 else "cut"
            n = max(2, int(L / STEP))
            for i in range(n + 1):
                sl = L * i / n
                hw = W / 2 + float(ln.get("margin", 0.0))  # (at its bed's own edge: a lane's `margin`, tools/terrain/pads.py)
                x, y = fx + ux * sl + ox * hw, fy + uy * sl + oy * hw
                zl = float(P.lane_bed(ln, np.array([sl]))[0])
                zo = float(z_at(x + ox * (REACH_SHARP if builder or road or steps else 0.8), y + oy * (REACH_SHARP if builder or road or steps else 0.8)))
                kind, mark = None, "none"
                if garden:  # its walls stand the whole way, but inside the next leg's bed at a bend
                    if not any(o is not ln and o.get("garden") and _in_band(o, x, y, 0.05) for o in lanes):
                        kind = mark = gkind
                elif in_building(x + ox * 0.6, y + oy * 0.6):
                    mark = "house"
                elif builder and in_lane(x, y, grow=0.2, but=ln):
                    pass  # another lane crosses its side here (a flight up into a yard): no wall across it
                elif steps and any(o is not ln and _way(o) == _way(ln) and _inside(o, x, y) for o in lanes):
                    pass  # on another piece of its own way, a bend's landing (Dungkar Gönpa's way up turns 93 degrees: the
                    # next flight's inner wall had stood across its landing; M3 sprint 3, step 1): no wall across it
                elif ln.get("path") and in_lane(x, y, grow=0.8, but=ln):
                    pass  # a Tödé field path's turn: the next piece of its own way (or another's) goes on here, no wall
                    # across it (tools/town/tode.py; M3 sprint 4, step 1: a leg's wall had stood in the next leg's bed)
                elif road and in_lane(x, y, grow=0.2, but=ln, other=_way(ln)):
                    pass  # another road or path meets it here (the path up from the mills' footbridge onto R-01, the Yak Road
                    # over the leat's shelf; M2 sprint 12, step 5): no wall across it
                elif abs(zo - zl) >= (P.SOFT if builder and ln.get("kind") != "mouth" else (ln["wall_min"][0 if zo > zl else 1] if ln.get("wall_min") else WALL_MIN)):
                    # a mouth flight walled from 0.4 m: it had climbed between sand banks up to the yards' walls (ISS-116); a
                    # lane's own `wall_min` [cut, fill]: the Serchu road's walls only where its cut or its fill is high, a low
                    # bank bare earth (M2 sprint 12, step 1: it had run between walls for its whole kilometre)
                    kind = mark = "fill" if zo < zl else "cut"
                    if kind == "cut" and not builder and in_lane(x + ox * 0.8, y + oy * 0.8, grow=0.0):
                        kind, mark = None, "none"  # a higher lane beside it: that lane's fill wall is this one (the north ramp's legs)
                    if kind == "fill" and s_lo <= sl <= s_hi:
                        kind = None  # beside the flight: the flight's own side, and its parapet
                marks.append([round(sl, 2), mark or "none", round(zo, 2), round(zl, 2)])
                if kind:
                    hh = abs(zo - zl)
                    flags = ((SOLID if hh >= SOLID_MIN else 0) | (PARAPET if kind == "fill" and hh >= PARAPET_MIN and not own_walls and (not ln.get("path") or ln.get("parapet")) else 0)) if builder or road or steps else 0
                    # (a field path of Tödé's never a parapet: 2 m between its walls, a parapet's 0.45 m pinched its turns)
                    # (but the Gönkor's, `parapet`: 2.2 m wide, its north side's flights over fills of 5 m: tools/town/gonkor.py)
                    # (the Caravan Ramp's as a side lane's: solid, and a parapet over a high fill, for a herd on its legs)
                    ptop = None
                    if garden:  # its parapet to the garden wall's top over the bed, or a low one on a higher cut
                        flags = SOLID | PARAPET
                        ptop = max(zl + garden_h, max(zo, zl) + 0.4)
                    foot = min(zo, zl)
                    if ln.get("path"):  # a Tödé field path's wall sunk to the lowest ground by it (tools/town/tode.py; M3
                        # sprint 4, step 1): sampled outward alone its foot jumped by up to 2.8 m from one point to the next,
                        # where the ground there fell away to the zigzag below
                        foot = min(foot, float(z_at(x, y)), float(z_at(x + ox * 0.5, y + oy * 0.5)),
                                   float(z_at(x + ox * 1.5, y + oy * 1.5))) - 0.3
                    p = (x, y, ox, oy, kind, foot, max(zo, zl), zl, ln["id"], flags,
                         (STRIP["lane"] if kind == "fill" else P.CUT_OUT + 1.0) if builder or road or steps else STRIP["named"], ptop)
                if kind and cur and cur[-1][4] == kind:
                    cur.append(p)
                else:
                    if len(cur) * STEP >= MIN_RUN:
                        runs.append(cur)
                    cur = [p] if kind else []
            if len(cur) * STEP >= MIN_RUN:
                runs.append(cur)
            sides["%d" % side] = marks
        if builder:
            lane_sides[ln["id"]] = sides
    glegs = [ln for ln in lanes if ln.get("garden")]
    if glegs:  # the garden lane's walls: each side one run along the whole lane, its points every STEP on the side's line
        # mitred at the bends, its kind the side's own (holding the bed up, or the slope back), its parapet's top WALL_H
        # over the bed, solid
        cs, beds, us = [], [], []
        for ln in glegs:
            (fx, fy), (ux, uy), L = ln["from"], ln["dir"], ln["length"]
            for t in np.arange(0.0, L, STEP):
                cs.append((fx + ux * t, fy + uy * t))
                beds.append(float(P.lane_bed(ln, np.array([t]))[0]))
                us.append((ux, uy))
        last = glegs[-1]
        cs.append((last["from"][0] + last["dir"][0] * last["length"], last["from"][1] + last["dir"][1] * last["length"]))
        beds.append(float(last["z_b"]))
        us.append(tuple(last["dir"]))
        W = float(glegs[0]["width"])
        for side in (-1.0, 1.0):
            pts_ = []
            for k, ((cx_, cy_), zl) in enumerate(zip(cs, beds)):
                a_ = us[max(0, k - 1)]
                b_ = us[k]
                nx_, ny_ = -(a_[1] + b_[1]) * side, (a_[0] + b_[0]) * side  # the bisector of the two legs' normals
                nn = math.hypot(nx_, ny_) or 1.0
                cos_h = max(0.5, (nx_ / nn) * (-b_[1] * side) + (ny_ / nn) * (b_[0] * side))
                ox, oy = nx_ / nn, ny_ / nn
                off = W / 2 / cos_h  # mitred
                x, y = cx_ + ox * off, cy_ + oy * off
                zo = float(z_at(x + ox * 0.8, y + oy * 0.8))
                pts_.append((x, y, ox, oy, zo, zl))
            far = [float(z_at(x + ox * 2.0, y + oy * 2.0)) - zl for x, y, ox, oy, zo, zl in pts_[::5]]
            kind = "fill" if sum(far) < 0.0 else "cut"
            run = [(x, y, ox, oy, kind, min(zo, zl), max(zo, zl), zl, "GL", SOLID | PARAPET, STRIP["named"],
                    max(zl + garden_h, max(zo, zl) + 0.4)) for x, y, ox, oy, zo, zl in pts_]
            runs.append(run)
    free = []  # the gardens' walls between and round their plots (tools/town/gardens.py) and the Caravan Ground's (its
    # corral's: tools/town/caravan_ground.py): standing on the ground, their height over it, each a parapet on a wall of no
    # height, its normal across its line
    for path_ in (GARDENS, P.CARAVAN_GROUND, P.HEJIE, P.MONASTERY):  # (and Hejie's wall HEJ-01: tools/town/hejie.py; the
        # monastery's MON-21: tools/town/monastery.py, M2 sprint 13, step 4)
        if os.path.exists(path_):
            free += json.load(open(path_, encoding="utf-8")).get("walls", [])
    if free:
        for gw in free:
            q = gw["pts"]
            run = []
            for i, (x, y, _z) in enumerate(q):
                a_, b_ = q[max(0, i - 1)], q[min(len(q) - 1, i + 1)]
                dx, dy = b_[0] - a_[0], b_[1] - a_[1]
                n = math.hypot(dx, dy) or 1.0
                zg = float(z_at(x, y))
                run.append((x, y, -dy / n, dx / n, "cut", zg, zg, zg, gw["of"], SOLID | PARAPET, 0.0, zg + float(gw["h"])))
            if len(run) >= 2:
                runs.append(run)
    gk = os.path.join(ROOT, "data", "gonkor.json")  # where the Gönkor comes onto another way's landing over its fill, that
    # landing's parapet opened within a metre of its line (tools/town/gonkor.py `parapet_gaps`; M3 sprint 7, step 1)
    for lid, x0, y0, x1, y1 in (json.load(open(gk, encoding="utf-8")).get("parapet_gaps", []) if os.path.exists(gk) else []):
        dx, dy = x1 - x0, y1 - y0
        for r in runs:
            if r[0][8] != lid:
                continue
            for k, q in enumerate(r):
                t = max(0.0, min(1.0, ((q[0] - x0) * dx + (q[1] - y0) * dy) / max(dx * dx + dy * dy, 1e-9)))
                if math.hypot(x0 + dx * t - q[0], y0 + dy * t - q[1]) < 1.0 and q[9] & PARAPET:
                    r[k] = q[:9] + (q[9] & ~PARAPET,) + q[10:]
    roads = {ln["id"] for ln in lanes if ln.get("road")}  # a road's or a leat's walls: dry stone, never limed (export_walls.py)
    out = [{"kind": r[0][4], "strip": max(p[10] for p in r), "of": r[0][8],
            "pts": [[round(p[0], 2), round(p[1], 2), round(p[2], 3), round(p[3], 3), round(p[5], 2), round(p[6], 2)] +
                    ([round(p[11], 2)] if len(p) > 11 and p[11] is not None else []) for p in r],
            "flags": [p[9] for p in r], **({"road": True} if r[0][8] in roads else {})} for r in runs]
    json.dump({"about": "Retaining-wall runs from tools/town/walls.py: each point x, y (town grid), the outward normal ox, oy, the wall's foot and top (design altitude); each point's flags (1 a parapet, 2 solid), the run's top's reach back over its higher side (`strip`: a fill wall's paved, a cut wall's earth, from its line) and whose edge it is (`of`; `road` a road's or a leat's, whose parapets are never limed). `lane_sides`: along each side lane's two sides (-1 its right going up, the kit stair's +x), [s, what stands beside (house, fill, cut, none), the ground beside, the bed]. Regenerated with the terrain.",
               "runs": out, "lane_sides": lane_sides}, open(OUT, "w"), indent=None)
    total = sum(len(r["pts"]) for r in out) * STEP
    tall = max((p[5] - p[4] for r in out for p in r["pts"]), default=0.0)
    para = sum(1 for r in out for fl in r["flags"] if fl & PARAPET) * STEP
    print("walls: %d runs, %.0f m of wall (%d fill, %d cut), %.0f m with a parapet, the tallest %.1f m -> %s" % (
        len(out), total, sum(1 for r in out if r["kind"] == "fill"), sum(1 for r in out if r["kind"] == "cut"), para, tall, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
