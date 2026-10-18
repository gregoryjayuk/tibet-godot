#!/usr/bin/env python3
"""Tödé's leat TOD-10, its two mills and three water prayer wheels (M3 sprint 4, step 4; plan chapter 02, D06, TOD-05 to
TOD-10, 6.1; chapter 03, 11.6-11.7; R-12): the line of cultivation.

Chapter 02: the leat, "stone-lined, 0.6 m wide", comes 1.9 km along the contour from its intake (2,992 m) east and north
of the quarter, the leat walk R-12 beside it at 0.7%, to Tödé's top at 2,978 m: fields below it, grazing above; then it
turns down through the terraces, its water taken in turn by the upper mill TOD-05, the water prayer wheel houses TOD-07
and TOD-08, the lower mill TOD-06 and the wheel house TOD-09 at the band's top, and goes on to Shöl. Here it enters the
quarter at EAST on the contour (the intake and the rest of R-12 lie off the built ground) and is traced along the slope
at GRADE where the ground stands RIM over its water (its channel cut into the slope, its outer bank built), its shelf
SHELF wide with the leat walk uphill of the channel (`lanes`, `leat`: road lanes for tools/terrain/pads.py, as the
Serchu's: tools/town/serchu_mills.py), until it comes over the upper mill (TURN_X). From there each stretch goes straight
down the hillside from the last machine's outflow to the next one's inflow in a stepped channel cut COVER under the
ground, its water falling all the way and never under the next inflow's level (`channel` lanes, cut only): a mill (the
Serchu's ser05_mill) stands at tools/town/tode.py's place on its pad, its +x side uphill, its chute from the head HEAD_AT
behind it down to the wheel under its floor, its tail race out of the arch in its front (a side, across the slope) and
its tail yard cut to the race's floor; a wheel house (ser09_wheel_house) straddles the channel at its place, the water in
at its uphill side at its pad's level and out WHEEL_DROP lower. Where a stretch passes under a field path (tools/town/
tode.py's lanes) its water is kept SLAB under the path's bed in a culvert (`culverts`; no channel cut across the path).
After the last wheel house the race goes down the fall line RACE_LEN towards Shöl. The machines are turned and heard by
world/mills.gd, the water drawn by world/leat.gd, the channel, chutes, races and culverts built by ../tibet-blender
export_serchu.py (`--data data/tode_leat.json`).
Run: tools/py tools/town/tode_leat.py   Writes data/tode_leat.json and docs/town/tode-leat-report.md (tools/terrain/
build.sh runs it after tools/town/tode.py, before the pads).
"""
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
from terrain_site import Site  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import serchu_mills as SM  # noqa: E402  (its ease, simplify, lanes_along, bearing and the machines' measures)

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
SOURCE = os.path.join(GEN, "valley_shaped_1m.tif")  # the ground before the pads (pads.py's SOURCE)
TODE = os.path.join(ROOT, "data", "tode.json")
OUT = os.path.join(ROOT, "data", "tode_leat.json")
REPORT = os.path.join(ROOT, "docs", "town", "tode-leat-report.md")

EAST = (262.0, 563.0)  # where it comes into the quarter along the contour (chapter 02: from the intake east and north)
TOP = 2978.0  # its water there: Tödé's top (chapter 02, R-12; tools/town/tode.py LEAT)
GRADE = 0.007  # R-12: 14 m in 1.9 km
RIM = 0.3  # the contour stretch's line where the ground stands this over its water
TURN = 30.0  # degrees a metre's step of the trace may turn
AHEAD = 3.0
TURN_X = 25.0  # the contour stretch ends this far east of the upper mill, over it, and turns down
SHELF, SHELF_UNDER, SHELF_OFF = 2.8, 0.45, 0.6  # the contour stretch's shelf (the Serchu's): the channel and the walk uphill
CASCADE = (("TOD-05", "mill"), ("TOD-07", "wheel"), ("TOD-08", "wheel"), ("TOD-06", "mill"), ("TOD-09", "wheel"))
HEAD_AT = (4.5, 0.3)  # a mill's chute's head from its middle: up the slope along its +x, and back from its front (the
# Serchu's place_mill: the chute 2.5 m long falling 2.4 m, 44 degrees)
COVER = 0.25  # a descending stretch's water this under the ground (its channel cut in)
FALL_MIN = 0.01  # its water falls at least this a metre
CHANNEL_W = 1.4  # the cut for its channel and banks (export_serchu.py: 0.7 m between banks 0.3 thick)
SLAB = 0.45  # its water under a path's bed where it passes under it
PATH_GROW = 0.6  # a path's footprint grown by this for the culvert
RACE_LEN = 40.0  # after the last wheel house, down the fall line towards Shöl
CLEAR = 1.5  # metres a stretch keeps off a house's pad
BEND = (4.0, -4.0, 8.0, -8.0, 12.0, -12.0, 16.0, -16.0, 20.0, -20.0, 25.0, -25.0)  # metres off its straight line a stretch may bend


def ground():
    site_ = Site.load()
    g = site_.read(SOURCE)
    return lambda x, y: float(g.z(np.asarray(x, float), np.asarray(y, float)) - site_.shift)


def trace(Z, p0, z0, head, stop, steps=600):
    """Along the slope from p0 (its water z0 there), a metre a step, its water falling GRADE a metre, each step turned
    within TURN of the last to where the ground AHEAD stands RIM over its water; until stop(x, y)."""
    x, y, z, h = p0[0], p0[1], z0, head
    out = [(x, y, z)]
    for _ in range(steps):
        if stop(x, y):
            break
        z -= GRADE
        best = None
        for dh in np.radians(np.arange(-TURN, TURN + 0.1, 2.5)):
            a = h + dh
            e = Z(x + AHEAD * math.cos(a), y + AHEAD * math.sin(a)) - (z - GRADE * (AHEAD - 1.0) + RIM)
            c = abs(e) + 0.003 * abs(math.degrees(dh))
            if best is None or c < best[0]:
                best = (c, a)
        h = best[1]
        x, y = x + math.cos(h), y + math.sin(h)
        out.append((x, y, z))
    return out


def path_bed(paths, x, y):
    """The highest bed of the field paths whose footprints (grown PATH_GROW) hold (x, y), with the path, or None."""
    best = None
    for ln in paths:
        fx, fy = ln["from"]
        ux, uy = ln["dir"]
        L, W = ln["length"], ln["width"]
        t = (x - fx) * ux + (y - fy) * uy
        if -PATH_GROW <= t <= L + PATH_GROW and abs(-(x - fx) * uy + (y - fy) * ux) <= W / 2 + PATH_GROW:
            z = ln["z_a"] + (ln["z_b"] - ln["z_a"]) * min(max(t, 0.0), L) / max(L, 1e-6)
            if best is None or z > best[0]:
                best = (z, ln)
    return best


def plan_line(a, b, blocked):
    """Its plan from a to b: straight, or bent through one point off the straight line's middle (BEND, nearest first)
    where the straight line meets something `blocked` (a house's pad)."""
    def clear(pl):
        for (x0, y0), (x1, y1) in zip(pl, pl[1:]):
            n = max(2, int(math.hypot(x1 - x0, y1 - y0)) + 1)
            if any(blocked(x0 + (x1 - x0) * k / (n - 1), y0 + (y1 - y0) * k / (n - 1)) for k in range(2, n - 2)):
                return False
        return True
    pl = [(a[0], a[1]), (b[0], b[1])]
    if clear(pl):
        return pl
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    nx_, ny_ = -(b[1] - a[1]) / L, (b[0] - a[0]) / L
    for off in BEND:
        for t in (0.5, 0.35, 0.65):
            m = (a[0] + (b[0] - a[0]) * t + nx_ * off, a[1] + (b[1] - a[1]) * t + ny_ * off)
            if clear([pl[0], m, pl[1]]):
                return [pl[0], m, pl[1]]
    return pl


def descend(Z, a, b, paths, blocked):
    """A stretch down from a (x, y, its water) to b (x, y, the next inflow's water), straight or bent round a pad
    (plan_line): its points a metre apart, the water COVER under the ground but falling FALL_MIN a metre at the least
    and never under b's, kept SLAB under a path's bed it passes under; and the culverts: [(index, path lane, its bed)]."""
    pl = plan_line(a, b, blocked)
    seg = np.array(pl, float)
    sl = np.r_[0.0, np.cumsum(np.hypot(*np.diff(seg, axis=0).T))]
    n = max(2, int(sl[-1]) + 1)
    pts, under = [], []
    z = a[2]
    for k in range(n):
        u = sl[-1] * k / (n - 1)
        x, y = float(np.interp(u, sl, seg[:, 0])), float(np.interp(u, sl, seg[:, 1]))
        cap = Z(x, y) - COVER
        pb = path_bed(paths, x, y)
        if pb is not None:
            cap = min(cap, pb[0] - SLAB)
            under.append((k, pb[1], pb[0]))
        if k > 0:
            z = max(min(z - FALL_MIN, cap), b[2])
        pts.append([round(x, 2), round(y, 2), round(z, 2)])
    pts[-1][2] = round(min(pts[-1][2], b[2]), 2)
    return pts, under


def cut_lanes(lid, pts, skip):
    """`channel` lanes (cut only) along a descending stretch, each straight piece of its kept points, the bed its water's
    less the channel's depth; none over the points in `skip` (a culvert's: the path's bed stands over it)."""
    out, run = [], []
    for k, q in enumerate(pts):
        if k in skip:
            if len(run) > 1:
                out.append(run)
            run = []
        else:
            run.append(q)
    if len(run) > 1:
        out.append(run)
    lanes = []
    for r_, seg in enumerate(out):
        keep = SM.simplify(seg, 0.3)
        for n, (i, j) in enumerate(zip(keep[:-1], keep[1:])):
            p, q = seg[i], seg[j]
            L = math.hypot(q[0] - p[0], q[1] - p[1])
            if L < 0.3:
                continue
            ux, uy = (q[0] - p[0]) / L, (q[1] - p[1]) / L
            za, zb = p[2] - 0.45, q[2] - 0.45
            lanes.append({"id": "%s.%d.%d" % (lid, r_ + 1, n + 1), "from": [p[0], p[1]], "dir": [round(ux, 5), round(uy, 5)], "length": round(L, 2),
                          "width": CHANNEL_W, "z_a": round(za, 2), "z_b": round(zb, 2), "flight": None,
                          "profile": [[0.0, round(za, 2)], [round(L, 2), round(zb, 2)]], "channel": True, "leat": True})
    return lanes


def main():
    Z = ground()
    td = json.load(open(TODE, encoding="utf-8"))
    named = td["named"]
    paths = [ln for ln in td["lanes"] if ln.get("path") and not ln.get("terrace")]
    pads = [h["pad"] + [h["rot_deg"]] for h in td["houses"]]

    def on_pad(x, y):
        for px, py, pw, pd, f in pads:
            th = math.radians(f)
            ux, uy = math.sin(th), math.cos(th)
            if abs((x - px) * ux + (y - py) * uy) < pd / 2 + CLEAR and abs(-(x - px) * uy + (y - py) * ux) < pw / 2 + CLEAR:
                return True
        return False

    # the machines where tools/town/tode.py placed them: their inflows and outflows
    mach = []
    for mid, kind in CASCADE:
        n = named[mid]
        C = (float(n["at"][0]), float(n["at"][1]))
        f = math.radians(float(n["facing"]))
        d = (math.sin(f), math.cos(f))  # downhill
        rx, fwd = (-d[0], -d[1]), (-d[1], d[0])  # its +x up the slope; its front left of downhill (the Serchu's frame)
        lv = float(n["level"])
        if kind == "mill":
            H = (C[0] + HEAD_AT[0] * rx[0] - HEAD_AT[1] * fwd[0], C[1] + HEAD_AT[0] * rx[1] - HEAD_AT[1] * fwd[1])
            jet = (C[0] + SM.JET[0] * rx[0] - SM.JET[1] * fwd[0], C[1] + SM.JET[0] * rx[1] - SM.JET[1] * fwd[1])
            arch = (C[0] + SM.ARCH * fwd[0], C[1] + SM.ARCH * fwd[1])
            run = math.hypot(H[0] - jet[0], H[1] - jet[1])
            m = {"id": mid, "at": [round(C[0], 2), round(C[1], 2)], "level": round(lv, 2), "facing": round(SM.bearing(*fwd), 1),
                 "head": [round(H[0], 2), round(H[1], 2), round(lv + SM.FLOOR_UNDER, 2)],
                 "jet": [round(jet[0], 2), round(jet[1], 2), round(lv + SM.JET[2], 2)],
                 "arch": [round(arch[0], 2), round(arch[1], 2), round(lv - SM.TAIL_UNDER, 2)],
                 "chute": round(math.degrees(math.atan2(SM.FLOOR_UNDER - SM.JET[2], run)), 1), "run": round(run, 2),
                 "back": round(Z(C[0] - SM.HALF * fwd[0], C[1] - SM.HALF * fwd[1]) - lv, 2), "front": round(Z(arch[0], arch[1]) - lv, 2)}
            tail = (arch[0] + 0.9 * fwd[0], arch[1] + 0.9 * fwd[1])
            mach.append((kind, m, (H[0], H[1], lv + SM.FLOOR_UNDER), (tail[0], tail[1], lv - SM.TAIL_UNDER), fwd))
        else:
            win = (C[0] - SM.WHEEL_HALF * d[0], C[1] - SM.WHEEL_HALF * d[1])
            wout = (C[0] + SM.WHEEL_HALF * d[0], C[1] + SM.WHEEL_HALF * d[1])
            w = {"id": mid, "at": [round(C[0], 2), round(C[1], 2)], "level": round(lv, 2), "facing": round(SM.bearing(*fwd), 1),
                 "in": [round(win[0], 2), round(win[1], 2), round(lv, 2)], "out": [round(wout[0], 2), round(wout[1], 2), round(lv - SM.WHEEL_DROP, 2)]}
            mach.append((kind, w, (win[0], win[1], lv), (wout[0], wout[1], lv - SM.WHEEL_DROP), d))

    # the contour stretch: from EAST along the slope, westward, until it is TURN_X east of the upper mill's head
    H5 = mach[0][2]
    line = trace(Z, EAST, TOP, math.pi, lambda x, y: x <= H5[0] + TURN_X)
    P, s = SM.ease(line)
    contour = [[round(float(a), 2), round(float(b), 2), round(TOP - GRADE * float(t), 2)] for (a, b), t in zip(P, s)]
    stretches = [{"id": "TOD-10.1", "pts": contour}]
    k_ = len(contour) // 2  # the uphill side, left or right looking downstream (the Serchu's is its left; here the leat flows
    # west along a south-facing slope, uphill on its right): the shelf's middle and the walk that way from the channel
    a_, b_ = contour[k_], contour[k_ + 1]
    dx_, dy_ = b_[0] - a_[0], b_[1] - a_[1]
    l_ = math.hypot(dx_, dy_) or 1.0
    up = 1.0 if Z(a_[0] - dy_ / l_ * 3.0, a_[1] + dx_ / l_ * 3.0) > Z(a_[0] + dy_ / l_ * 3.0, a_[1] - dx_ / l_ * 3.0) else -1.0
    lanes = SM.lanes_along("TOD-10.1", contour, SHELF, SHELF_UNDER, off=up * SHELF_OFF, leat=True)  # the channel and the walk beside it
    for ln in lanes:
        ln["wall_min"] = [1.2, 0.8]
    culverts, chutes, mills, wheels, falls = [], [], [], [], []
    prev = tuple(contour[-1])
    for n, (kind, rec, inflow, outflow, way) in enumerate(mach):
        sid = "TOD-10.%d" % (n + 2)
        pts, under = descend(Z, prev, inflow, paths, on_pad)
        stretches.append({"id": sid, "pts": pts})
        falls.append((sid, prev[2] - inflow[2], len(pts)))
        skip = set()
        seen = set()
        for k, ln, bed in under:
            skip.add(k)
            if ln["id"] in seen:
                continue
            seen.add(ln["id"])
            ks = [kk for kk, l2, _ in under if l2["id"] == ln["id"]]
            mid_k = ks[len(ks) // 2]
            q = pts[mid_k]
            a_, b_ = pts[max(0, mid_k - 1)], pts[min(len(pts) - 1, mid_k + 1)]
            ld = (b_[0] - a_[0], b_[1] - a_[1])
            ll = math.hypot(*ld) or 1.0
            culverts.append({"at": [q[0], q[1]], "road": round(bed, 2), "water": q[2], "dir": ln["dir"], "leat": sid,
                             "leat_dir": [round(ld[0] / ll, 4), round(ld[1] / ll, 4)], "width": ln["width"] + 0.5, "path": ln["id"]})
        lanes += cut_lanes(sid, pts, skip)
        if kind == "mill":
            mills.append(rec)
            ground_ = []
            hx, hy, hz = rec["head"]
            jx, jy, jz = rec["jet"]
            run = math.hypot(jx - hx, jy - hy)
            for k in range(1, int(run / SM.TRESTLE) + 1):
                t = k * SM.TRESTLE / run
                if t < 0.95:
                    gx_, gy_ = hx + (jx - hx) * t, hy + (jy - hy) * t
                    ground_.append([round(gx_, 2), round(gy_, 2), round(hz + (jz - hz) * t, 2), round(Z(gx_, gy_), 2)])
            chutes.append({"id": rec["id"], "pts": [rec["head"], rec["jet"]], "ground": ground_})
            a = rec["arch"]
            stretches.append({"id": "%st" % sid, "pts": [[a[0], a[1], a[2]], [round(outflow[0], 2), round(outflow[1], 2), a[2]]], "tail": rec["id"]})
            fwd = way
            ty_ = SM.TAIL_YARD
            cx, cy = rec["at"][0] + fwd[0] * (ty_[1] / 2 - 0.6), rec["at"][1] + fwd[1] * (ty_[1] / 2 - 0.6)
            lanes.append({"id": "%s.yard" % rec["id"], "from": [round(rec["at"][0] - fwd[0] * 0.6, 2), round(rec["at"][1] - fwd[1] * 0.6, 2)],
                          "dir": [round(fwd[0], 5), round(fwd[1], 5)], "length": ty_[1], "width": ty_[0], "z_a": a[2] - 0.1, "z_b": a[2] - 0.1,
                          "flight": None, "profile": [[0.0, a[2] - 0.1], [ty_[1], a[2] - 0.1]], "channel": True, "leat": True})
        else:
            wheels.append(rec)
        prev = outflow
    # the race after the last wheel house: down the fall line towards Shöl
    race = [[round(prev[0], 2), round(prev[1], 2), round(prev[2], 2)]]
    x, y = prev[0], prev[1]
    for _ in range(int(RACE_LEN)):
        gx = (Z(x + 1.0, y) - Z(x - 1.0, y)) / 2.0
        gy = (Z(x, y + 1.0) - Z(x, y - 1.0)) / 2.0
        g_ = math.hypot(gx, gy)
        if g_ < 1e-3:
            break
        x, y = x - gx / g_, y - gy / g_
        race.append([round(x, 2), round(y, 2), round(min(race[-1][2] - FALL_MIN, Z(x, y) + 0.12), 2)])
    stretches.append({"id": "TOD-10.race", "pts": race, "race": True})
    bad = [c for c in culverts if c["road"] - c["water"] < SLAB - 0.05]
    on_pads = [st["id"] for st in stretches[1:] if any(on_pad(q[0], q[1]) for q in st["pts"][2:-2])]
    walk = []  # the leat walk R-12's first stretch: its middle uphill of the channel, every 4 m, from the east
    for k in range(4, len(contour) - 1, 4):  # (from 4 m in: the trace's first metres turn, and a walk point off them stood off the shelf)
        a_, b_ = contour[k], contour[min(k + 1, len(contour) - 1)]
        dx, dy = b_[0] - a_[0], b_[1] - a_[1]
        L = math.hypot(dx, dy) or 1.0
        walk.append([round(a_[0] - up * dy / L * (SHELF_OFF + 0.7), 2), round(a_[1] + up * dx / L * (SHELF_OFF + 0.7), 2), round(a_[2] - SHELF_UNDER, 2)])
    json.dump({"about": "Tödé's leat TOD-10 (tools/town/tode_leat.py; M3 sprint 4, step 4), in tools/town/serchu_mills.py's form: `leat` its stretches, each [x, y, its water z] downstream (`tail` a mill's tail race, `race` the last to Shöl); `mills` and `wheels` the machines where tools/town/tode.py placed them (a mill's head, jet and arch; a wheel house's in and out); `chutes`; `culverts` where a stretch passes under a field path; `lanes` the contour stretch's shelf (road, `leat`) and the descending stretches' channels and the mills' tail yards (`channel`, cut only); `walk` the leat walk R-12's first stretch beside the contour stretch, from the east. Regenerated with the terrain.",
               "leat": stretches, "mills": mills, "wheels": wheels, "chutes": chutes, "culverts": culverts, "lanes": lanes, "walk": walk},
              open(OUT, "w", encoding="utf-8"), indent=1)
    L1 = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(contour, contour[1:]))
    rep = ["# Tödé's leat TOD-10", "",
           "_Written by `tools/town/tode_leat.py` (M3 sprint 4, step 4) from the ground before the pads and Tödé's places and paths (`data/tode.json`)._", "",
           "- Along the contour from (%.0f, %.0f) at %.1f m to (%.0f, %.0f) at %.1f m: %.0f m at %.1f%%, its shelf and the leat walk beside it." % (
               contour[0][0], contour[0][1], contour[0][2], contour[-1][0], contour[-1][1], contour[-1][2], L1, GRADE * 100),
           "- Down through the terraces past %s, then the race %.0f m towards Shöl: %d culverts under the field paths%s; %s." % (
               ", ".join("%s (%s, %.1f m)" % (r["id"], k, r["level"]) for k, r, *_ in mach), RACE_LEN, len(culverts),
               "" if not bad else " (%d too shallow: %s)" % (len(bad), ", ".join(c["path"] for c in bad)),
               "no stretch over a house's pad" if not on_pads else "stretches over houses' pads: " + ", ".join(on_pads)), "",
           "| Stretch | Falls | Metres |", "|---|---|---|"]
    for sid, f_, n_ in falls:
        rep.append("| %s | %.1f | %d |" % (sid, f_, n_ - 1))
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("tode_leat: %.0f m along the contour from %.1f to %.1f m, then down past %d mills and %d wheel houses; %d culverts%s%s -> %s" % (
        L1, contour[0][2], contour[-1][2], len(mills), len(wheels), len(culverts), "" if not bad else ", %d too shallow" % len(bad),
        "" if not on_pads else ", over pads: " + ",".join(on_pads), OUT))


if __name__ == "__main__":
    main()
