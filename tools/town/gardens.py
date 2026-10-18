#!/usr/bin/env python3
"""Upper Shöl's walled gardens and the lane through them to the Gorge Rim Lookout (M2 sprint 6, step 4; plan chapter 02,
SHL-32 "Gorge Rim Lookout, 6 x 4 terrace" and SHL-33 "Walled gardens and orchards, 12 plots: walnut, apple, pear";
chapter 08, V-13a's approach: "up through the walled gardens of upper Shöl along a lane between garden walls 2.5 m high,
which hides everything; the terrace opens on the gorge rim").
The lane leaves upper Shöl at H-SHL-095's yard (2,769.5 m), climbs the shoulder east of it at 15 degrees to the 2,777 m
contour, and keeps to the contour across the 35-40 degree slope for 170 m to the Lookout's terrace (2,778 m): its line
is LINE, its level the ground under it smoothed, no steeper than RAMP on the shoulder and FLAT beyond. Its bed is carved
by tools/terrain/pads.py as Samkha's ramps' are (each leg a lane of `lanes`, with its profile); tools/town/walls.py walls
both its sides the whole way, their tops WALL_H over the bed (`garden`); the twelve plots lie along it, six above and six
below, each its own trees (walnut, apple or pear, or two kinds) on its slope, divided by walls down the slope and closed
by a lower wall along its far side (`walls`, each a line of points with its top over the ground), a door into each from
the lane (`gates`). Into data/gardens.json for pads.py, walls.py, world/town.gd (the trees and the doors) and the game's
tests; and docs/town/gardens-report.md.
Run: tools/py tools/town/gardens.py   (tools/terrain/build.sh runs it before pads.py)
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
OUT = os.path.join(ROOT, "data", "gardens.json")
REPORT = os.path.join(ROOT, "docs", "town", "gardens-report.md")
# the lane's line in the town grid: from H-SHL-095's yard east up the shoulder, then along the contour to the terrace
LINE = [(13.0, 215.5), (42.0, 216.5), (60.0, 215.5), (75.0, 213.0), (90.0, 208.5), (105.0, 203.5), (120.0, 200.0),
        (135.0, 198.0), (150.0, 198.5), (165.0, 201.5), (180.0, 206.0), (195.0, 210.5), (210.0, 213.5), (222.0, 219.0),
        (234.0, 225.5), (245.0, 233.0), (254.0, 240.0)]  # on round the contour to the gorge's rim, where the notch opens (034)
START_Z, END_Z = 2769.5, 2781.5  # H-SHL-095's yard (data/town_generic.json) and the Lookout's terrace, raised 3.5 m over
# chapter 02's 2,778 m onto the rim's edge, so its viewer stands over the slope's cut, not beside it (tools/terrain/pads.py RAISED)
LOOKOUT = (258.0, 245.0)  # the terrace on the gorge's rim, 55 m on round the contour from chapter 02's (215, 215): from there
# the gorge's notch is at 034 degrees, its floor 11 degrees up (DECISIONS, 9 Oct 2026); tools/terrain/pads.py MOVED
WIDTH = 3.0  # between its walls: 2.55 m clear of the parapet on its lower side, room for two with their loads
RAMP, FLAT = 0.28, 0.05  # the steepest grade on the shoulder (to 32 m along) and beyond
SMOOTH = 21  # metres: the ground under the line, averaged
WALL_H = 2.5  # the garden walls' tops over the lane's bed (chapter 08)
PLOT_DEPTH = 9.0  # each plot from the lane wall
PLOTS = 6  # a side, along the contour
FROM_S = 36.0  # the plots begin past the shoulder's ramp
DIVIDER_H, OUTER_H = 1.8, 1.4  # the walls between the plots, and along their far sides, over the ground
SPECIES = {"walnut": (2, 3, 7.5), "apple": (4, 6, 4.5), "pear": (3, 5, 5.0)}  # trees a plot (from, to) and their spacing
SEED = 1033


def _resample(line, step=1.0):
    pts, cum = [line[0]], [0.0]
    for (ax, ay), (bx, by) in zip(line, line[1:]):
        L = math.hypot(bx - ax, by - ay)
        n = max(1, int(round(L / step)))
        for i in range(1, n + 1):
            pts.append((ax + (bx - ax) * i / n, ay + (by - ay) * i / n))
            cum.append(cum[-1] + L / n)
    return np.array(pts), np.array(cum)


def profile(z_at):
    """The lane's level along its line, every metre: the ground smoothed, its grade held to RAMP on the shoulder and
    FLAT beyond, its ends at H-SHL-095's yard and the terrace."""
    pts, s = _resample(LINE)
    g = np.array([z_at(x, y) for x, y in pts])
    k = SMOOTH // 2
    pad = np.concatenate([np.full(k, g[0]), g, np.full(k, g[-1])])
    zs = np.convolve(pad, np.ones(SMOOTH) / SMOOTH, mode="valid")
    zs[0], zs[-1] = START_Z, END_Z
    for _ in range(6):  # the grade held both ways, the ends kept
        for i in range(1, len(zs) - 1):
            lim = (RAMP if s[i] < 32.0 else FLAT) * (s[i] - s[i - 1])
            zs[i] = np.clip(zs[i], zs[i - 1] - lim, zs[i - 1] + lim)
        for i in range(len(zs) - 2, 0, -1):
            lim = (RAMP if s[i] < 32.0 else FLAT) * (s[i + 1] - s[i])
            zs[i] = np.clip(zs[i], zs[i + 1] - lim, zs[i + 1] + lim)
    return pts, s, g, zs


def legs(pts, s, zs):
    """The lane's legs for pads.py (Samkha's ramps' form): one a straight of LINE, its profile every metre."""
    out = []
    for k, ((ax, ay), (bx, by)) in enumerate(zip(LINE, LINE[1:])):
        L = math.hypot(bx - ax, by - ay)
        s0 = float(np.interp(0, [0], [0])) if k == 0 else sum(math.hypot(LINE[j + 1][0] - LINE[j][0], LINE[j + 1][1] - LINE[j][1]) for j in range(k))
        ss = np.arange(0.0, L + 0.01, 1.0)
        prof = [[round(float(t), 2), round(float(np.interp(s0 + t, s, zs)), 2)] for t in ss]
        if prof[-1][0] < L - 0.01:
            if L - prof[-1][0] < 0.5:  # its last metre's sample too near its end: the end in its place
                prof.pop()
            prof.append([round(L, 2), round(float(np.interp(s0 + L, s, zs)), 2)])
        out.append({"id": "GL-%02d" % (k + 1), "from": [ax, ay], "dir": [round((bx - ax) / L, 4), round((by - ay) / L, 4)],
                    "length": round(L, 2), "width": WIDTH, "z_a": prof[0][1], "z_b": prof[-1][1], "flight": None,
                    "profile": prof, "garden": True, "s0": round(s0, 2)})
    return out


def at_s(pts, s, t):
    """A point of the line at t metres along it, and the unit along it there."""
    i = int(np.clip(np.searchsorted(s, t), 1, len(s) - 1))
    a, b = pts[i - 1], pts[i]
    u = (b - a) / max(np.hypot(*(b - a)), 1e-6)
    f = (t - s[i - 1]) / max(s[i] - s[i - 1], 1e-6)
    return a + (b - a) * f, u


def plots(pts, s, zs, z_at, rnd):
    """The twelve plots: along the contour from FROM_S, PLOTS a side, each PLOT_DEPTH out from the lane wall; each its
    kinds of tree, its trees on its slope, its door from the lane."""
    out, trees, gates, walls = [], [], [], []
    span = (s[-1] - 14.0 - FROM_S) / PLOTS  # the walls go on to the rim; the plots end short of it
    kinds = ["walnut", "apple", "pear", "apple", "walnut", "pear", "pear", "apple", "walnut", "apple", "pear", "apple"]
    for side, sign in (("above", 1.0), ("below", -1.0)):
        for k in range(PLOTS):
            n = len(out)
            t0, t1 = FROM_S + k * span, FROM_S + (k + 1) * span
            kind = kinds[n]
            second = "walnut" if kind != "walnut" and rnd.random() < 0.3 else None
            lo, hi, gap = SPECIES[kind]
            count = rnd.randint(lo, hi)
            placed = []
            tries = 0
            while len(placed) < count and tries < 200:
                tries += 1
                t = rnd.uniform(t0 + 2.0, t1 - 2.0)
                d = rnd.uniform(WIDTH / 2 + 2.6, WIDTH / 2 + PLOT_DEPTH - 1.6)
                c, u = at_s(pts, s, t)
                nrm = np.array([-u[1], u[0]]) * sign  # out from the lane, up the slope or down it
                x, y = c + nrm * d
                if any(math.hypot(x - px, y - py) < gap for px, py, _ in placed):
                    continue
                kk = second if second and len(placed) == count - 1 else kind
                placed.append((float(x), float(y), kk))
            for x, y, kk in placed:
                trees.append({"kind": kk, "at": [round(x, 2), round(y, 2), round(float(z_at(x, y)), 2)], "seed": rnd.randint(1, 9999),
                              "size": round(rnd.uniform(0.85, 1.15), 2), "plot": n + 1})
            # the door into it from the lane, a third of the way along, on the lane wall's face
            tg = t0 + span * rnd.uniform(0.3, 0.7)
            c, u = at_s(pts, s, tg)
            nrm = np.array([-u[1], u[0]]) * sign
            gx, gy = c + nrm * (WIDTH / 2 + 0.05)
            gates.append({"plot": n + 1, "at": [round(float(gx), 2), round(float(gy), 2), round(float(np.interp(tg, s, zs)), 2)],
                          "facing": round(math.degrees(math.atan2(-nrm[0], -nrm[1])) % 360.0, 1)})
            # its far wall along the contour, and the wall down the slope at its end (the last plot's too)
            far = []
            for t in np.arange(t0, t1 + 0.01, 1.0):
                c, u = at_s(pts, s, t)
                nrm = np.array([-u[1], u[0]]) * sign
                x, y = c + nrm * (WIDTH / 2 + PLOT_DEPTH)
                far.append([round(float(x), 2), round(float(y), 2), round(float(z_at(x, y)), 2)])
            walls.append({"of": "plot %d far" % (n + 1), "pts": far, "h": OUTER_H})
            for t in ([t0] if k > 0 else [t0]) + ([t1] if k == PLOTS - 1 else []):
                c, u = at_s(pts, s, t)
                nrm = np.array([-u[1], u[0]]) * sign
                down = []
                for d in np.arange(WIDTH / 2 + 0.6, WIDTH / 2 + PLOT_DEPTH + 0.01, 1.0):
                    x, y = c + nrm * d
                    down.append([round(float(x), 2), round(float(y), 2), round(float(z_at(x, y)), 2)])
                walls.append({"of": "plot %d end" % (n + 1), "pts": down, "h": DIVIDER_H})
            out.append({"id": n + 1, "side": side, "from_s": round(t0, 1), "to_s": round(t1, 1), "kinds": [kind] + ([second] if second else []),
                        "trees": len(placed)})
    return out, trees, gates, walls


def main():
    site = Site.load()
    g = site.read(SOURCE)
    z_at = lambda x, y: float(g.z(x, y) - site.shift)
    pts, s, ground, zs = profile(z_at)
    rnd = random.Random(SEED)
    ps, trees, gates, walls = plots(pts, s, zs, z_at, rnd)
    data = {"about": "Upper Shöl's walled gardens and the lane to the Gorge Rim Lookout, from tools/town/gardens.py (M2 sprint 6, step 4): `lanes` the lane's legs in Samkha's ramps' form for pads.py to carve and walls.py to wall to WALL_H over the bed (`garden`); `plots` the twelve; `trees` each its kind, its foot (x, y, z: the town grid), seed and size; `gates` a door into each plot on the lane wall's face, facing the lane; `walls` the plots' far walls and the walls between them, each a line of ground points and its height over them. Regenerated with the terrain.",
            "wall_h": WALL_H, "lanes": legs(pts, s, zs), "plots": ps, "trees": trees, "gates": gates, "walls": walls}
    json.dump(data, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    cut = ground - zs
    lines = ["# The garden lane and the gardens", "",
             "_Written by `tools/town/gardens.py` (M2 sprint 6, step 4; chapter 02, SHL-32 and SHL-33; chapter 08, V-13a's approach)._", "",
             "The lane: %.0f m from H-SHL-095's yard (%.1f m) to the Gorge Rim Lookout's terrace (%.1f m); its steepest grade %.0f%% (%.1f degrees) on the shoulder, %.1f%% along the contour; the ground over its bed at most %.1f m (cut) and under it at most %.1f m (fill), on its middle line." % (
                 s[-1], START_Z, END_Z, 100 * max(abs(np.diff(zs[:33]))), math.degrees(math.atan(max(abs(np.diff(zs[:33]))))),
                 100 * max(abs(np.diff(zs[33:]))), max(cut), -min(cut)), "",
             "%d plots, %d trees (%s), %d doors from the lane, %d walls between and round the plots." % (
                 len(ps), len(trees), ", ".join("%d %s" % (sum(1 for t in trees if t["kind"] == k), k) for k in SPECIES), len(gates), len(walls)), "",
             "| Plot | Side | Along the lane (m) | Kinds | Trees |", "|---|---|---|---|---|"]
    for p in ps:
        lines.append("| %d | %s | %.0f-%.0f | %s | %d |" % (p["id"], p["side"], p["from_s"], p["to_s"], ", ".join(p["kinds"]), p["trees"]))
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("gardens: " + lines[4])
    print("gardens: " + lines[6])


if __name__ == "__main__":
    main()
