#!/usr/bin/env python3
"""The Tödé Stair (M3 sprint 4, step 2; plan chapter 02, D06, TOD-21: the Tödé chorten "at the head of the Sky Stair: the
entrance to the upper quarter"): the way from the Sky Stair's head up into Tödé.

Every way into Tödé from below climbs 70-100% for its first 60-80 m (`docs/town/tode-report.md`); over the Tödé chorten
the band is 105-165% (46-59 degrees) from 2,786 to some 2,870 m, too steep for a field path's ramps or its short flights,
whose turns the walker could not take (ISS-208). The Sky Stair goes on up it as the Gorge Stair's east leg climbs the
gorge's face: in legs of flights fitted to the ground, a landing between two flights of a leg, a switchback's landing where
it turns back (tools/town/gorge_stair.py's lay, make_cost, fit and lanes_of, here with Tödé's width), from the forecourt
west of the chorten (the chorten stands across the forecourt's head) to the band's top, where Tödé's field paths begin
(tools/town/tode.py ENTRIES). Every flight and landing is a lane in tools/terrain/pads.py's form (`steps`): pads.py carves
its bed, tools/town/walls.py walls it, ../tibet-blender export_lanes.py builds it, world/town.gd places it.
Run: tools/py tools/town/tode_stair.py [--search]   Writes data/tode_stair.json and docs/town/tode-stair-report.md
(tools/terrain/build.sh runs it before tools/town/tode.py: a few seconds, laying out START; `--search` searches again, a
few minutes, and prints a new START).
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gorge_stair as G  # noqa: E402  (its functions read its module's constants: set below for Tödé's stair)

ROOT = G.ROOT
OUT = os.path.join(ROOT, "data", "tode_stair.json")
REPORT = os.path.join(ROOT, "docs", "town", "tode-stair-report.md")
TOWN = os.path.join(ROOT, "data", "town.json")
GENERIC = os.path.join(ROOT, "data", "town_generic.json")
FOOT = (-25.0, 261.5)  # on the forecourt's west side, beside the chorten (tools/terrain/pads.py STAIRS: the Sky Stair's head)
FOOT_Z = 2782.0  # the forecourt's level as the pads carve it
FOOT_DIR = 0.0  # up the band, north
LEAD = 1.0  # a level way off the forecourt before the first step
TOP = (-20.5, 345.5)  # on the contour at 2,872.8 m above the band, where Tödé's field paths start along it north (until 11
# Oct 2026 (-24, 340) at 2,867.5 m, on a spur's crest whose sides fall away at 90-115%: no path's ramp could leave it)
TOP_DIR = 0.0
INTO = 75.0  # the last leg within this many degrees of north
SPLIT = (2, 2, 2, 2, 2, 1)  # flights a leg: eleven of about 40 steps, five switchbacks
WIDTH = 2.0  # each piece's width, Tödé's way up (the Gorge Stair's 1.65)
START = [-50.6764, -40.9655, 78.3274, -21.6726, 89.0694, -13.6617]  # the search's legs' bearings (`--search` prints them;
# 11 Oct 2026, to the top on the contour: cost 7,289, 476 steps from 2,782.0 to 2,872.4 m, its worst cut 6.0 m and fill 7.3 m)
TRIALS, SEED = 10, 1903


def setup():
    """The Gorge Stair's machinery at Tödé's width; its foot off the forecourt within 85 degrees of north."""
    G.WIDTH = WIDTH
    G.BAND = G.WIDTH + 2 * G.SHOULDER
    G.SEP = G.BAND + 1.0
    G.TRIALS = TRIALS
    G.OFF = 85.0


def keeps_of():
    """The ground the stair keeps off: the Tödé chorten on the forecourt's head and the window stall beside it, upper
    Shöl's top houses, the Lukhang spring, the garden lane."""
    town = {b["id"]: b for b in json.load(open(TOWN, encoding="utf-8"))["buildings"]}
    keeps = []
    for bid, grow in (("TOD-21", 0.8), ("SHL-14", 3.0)):
        b = town[bid]
        fp = b.get("footprint") or (4.0, 4.0)
        keeps.append(G.rect(np.array(b["pos"][:2], float), fp[0] + 2 * grow, fp[1] + 2 * grow, 180.0))
    for h in json.load(open(GENERIC, encoding="utf-8"))["houses"]:
        if h["pos"][1] > 180.0:
            keeps.append(G.rect(np.array(h["pos"][:2], float), h["footprint"][0] + 4.0, h["footprint"][1] + 4.0, h["rot_deg"]))
    return keeps


def main():
    setup()
    search = "--search" in sys.argv[1:]
    site_ = G.Site.load()
    g = site_.read(G.SOURCE)
    Z = lambda x, y: g.z(np.asarray(x, float), np.asarray(y, float)) - site_.shift
    z1 = float(Z(*TOP))
    keeps = keeps_of()
    cost, riser, steps = G.make_cost(Z, keeps, None, FOOT, G.unit(FOOT_DIR), FOOT_Z, TOP, G.unit(TOP_DIR), z1, SPLIT, LEAD, into=INTO)
    rng = np.random.default_rng(SEED)
    guess = lambda t: G.zigzag(Z, FOOT, FOOT_Z, riser, SPLIT, steps, LEAD, 1.0 if t % 2 == 0 else -1.0, 4.0 * (t // 2), rng)
    best, v = G.fit("tode", cost, len(SPLIT), G.unit(FOOT_DIR), TOP, FOOT, START, search, rng, guess=guess)
    if search:
        print("tode_stair: START = [%s]  (cost %.0f)" % (", ".join("%.4f" % a for a in v), best))
    legs, joins = G.lay(v, FOOT, FOOT_Z, riser, SPLIT, steps, LEAD)
    lanes, n_fl = G.lanes_of("TOD-S", legs, joins, "tode_stair")
    walk = G.walk_of(legs, joins)
    rows = []
    cost(v, rows)
    S, d, L, pieces = legs[-1]
    top = S + d * L
    end_off = float(np.hypot(*(top - np.array(TOP))))
    n_steps = sum(steps)
    json.dump({"about": "The Tödé Stair (tools/town/tode_stair.py; M3 sprint 4, step 2): the Sky Stair's way on up the band over the Tödé chorten, from the forecourt west of the chorten to the band's top, in legs of flights fitted to the ground (tools/town/gorge_stair.py's machinery). `lanes`: each flight and landing in tools/terrain/pads.py's form (`steps`); `top`: its last flight's top (x, y, z), where Tödé's field paths begin (tools/town/tode.py); `walk`: its middle every few metres, for the routes. Regenerated with the terrain.",
               "lanes": lanes, "foot": [FOOT[0], FOOT[1], FOOT_Z], "top": [round(float(top[0]), 2), round(float(top[1]), 2), round(FOOT_Z + n_steps * riser, 2)],
               "top_dir": [round(float(d[0]), 4), round(float(d[1]), 4)], "walk": walk, "bearings": [round(float(a), 2) for a in v]},
              open(OUT, "w", encoding="utf-8"), indent=1)
    worst_cut = max(r["cut"] for r in rows)
    worst_fill = max(r["fill"] for r in rows)
    rep = ["# The Tödé Stair", "",
           "_Written by `tools/town/tode_stair.py` (M3 sprint 4, step 2) from the ground before the pads: the Sky Stair's way on up the band over the Tödé chorten (105-165% for some 60 m) to Tödé's field paths._", "",
           "- From the forecourt (%.1f, %.1f, %.1f m) to the band's top (%.1f, %.1f, %.1f m), %.1f m from its mark: %d steps of %.3f m on treads of %.2f m in %d flights, %d legs, %d switchbacks; %.1f m wide." % (
               FOOT[0], FOOT[1], FOOT_Z, top[0], top[1], FOOT_Z + n_steps * riser, end_off, n_steps, riser, G.TREAD, n_fl, len(legs),
               sum(1 for j in joins if j[0] == "turn"), WIDTH),
           "- Its legs' bearings: %s; its worst cut %.1f m, its worst fill %.1f m (the fit's cost %.0f)." % (", ".join("%.0f" % (a % 360.0) for a in v), worst_cut, worst_fill, best), ""]
    rep += ["| Leg | Piece | Steps | Bearing | Mean off the ground | Cut | Fill |", "|---|---|---|---|---|---|---|"]
    for r in rows:
        rep.append("| %d | %s %d | %d | %.0f | %.2f | %.1f | %.1f |" % (r["leg"], r["kind"], r["number"], r["n"], r["bearing"], r["mean"], r["cut"], r["fill"]))
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("tode_stair: %d steps in %d flights, %d legs, from %.1f to %.1f m; its top %.1f m from its mark; worst cut %.1f m, fill %.1f m -> %s" % (
        n_steps, n_fl, len(legs), FOOT_Z, FOOT_Z + n_steps * riser, end_off, worst_cut, worst_fill, OUT))


if __name__ == "__main__":
    main()
