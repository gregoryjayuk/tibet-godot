#!/usr/bin/env python3
"""Dungkar Gönpa's way up from the South Gate to the Tsokchen's courtyard (the game's M3 sprint 3, step 1; plan chapter
02, D08, MON-02 and MON-17; chapter 03, 6.8): from the South Gate's passage (its inner side, at the 1,080 steps' top) up
the south flank between the monks' houses, in legs of two flights, to the passage through the courtyard's south range
(../tibet-blender kit/monastery.py tsokchen_court `gate_u`), on through it into the courtyard. Laid on the real ground as
the Gorge Stair is (tools/town/gorge_stair.py's lay, cost, fit and lanes, its constants widened for a monastery's lane):
risers of 19 cm, treads of 26 cm, 1.8 m clear and a parapet where it stands on a fill; carved by tools/terrain/pads.py,
walled by tools/town/walls.py, built by ../tibet-blender export_lanes.py, placed by world/town.gd; tools/town/monastery.py
keeps its houses off it.
Writes data/gonpa_ways.json (`lanes`, `walk`, `legs`) and docs/town/gonpa-ways-report.md. Run by tools/terrain/build.sh
after gorge_stair.py, before monastery.py; `--search` searches the legs again and prints START.
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gorge_stair as GS  # noqa: E402

ROOT = GS.ROOT
OUT = os.path.join(ROOT, "data", "gonpa_ways.json")
REPORT = os.path.join(ROOT, "docs", "town", "gonpa-ways-report.md")
STEPS = os.path.join(ROOT, "data", "dungrong.json")

CLEAR = 1.8  # a monastery's lane, wider than the Gorge Stair's 1.2 m (the 1,080 steps' 2.4 m between walls)
GATE, GATE_FACING, GATE_DEPTH = (465.0, 65.0), 215.0, 6.0  # the South Gate MON-17 (tools/town/monastery.py: its front to
# the steps' forecourt), a gatehouse 8 x 6 m (chapter 03, 6.8)
FOOT_OUT = 1.0  # the way's foot this far in from the gatehouse's back
COURT, COURT_SIZE, COURT_Z = (535.0, 110.0), (44.0, 36.0), 2928.0  # MON-02 (chapter 02: 44 x 36 m at 2,928 m)
GATE_U = 0.0  # the passage through its south range, along it from its middle (kit/monastery.py tsokchen_court)
TOP_OUT = 1.6  # the level way's turn this far south of the courtyard's edge, then on through the passage
BENCH = (517.0, 86.0)  # the flights' top on the edge of the courtyard's bench (the ground there 2,927-2,928 m; the flank below
# falls at 40 degrees and more): from there on level along the bench to the passage
RANGE_D = 5.6  # the courtyard's ranges' depth (the passage's length)
INTO = 70.0  # the last leg within this many degrees of east-north-east, onto the bench
LEAD = 0.0
CHORA_WALK = ((608.6, 75.0), (615.8, 75.0), 2944.0, 2.4)  # from the Tsenyi Dratsang's side door to the Chöra's west gate
# (tools/town/monastery.py MOVE, LEVEL: the college beside the court at its level; M3 sprint 3, step 2): its start, end,
# level and width
SPLIT = (2, 2, 2)  # flights a leg
START = [12.5082, 106.0192, 86.8753]  # (the search's, 11 Oct 2026: cost 2,368, the middle 2.9 m off the ground on average; `--search` again)
SEED = 1903
KEEPS = [((480.0, 70.0), 16.0, 12.0, 180.0, 0.8), ((500.0, 45.0), 16.0, 12.0, 180.0, 0.8), ((560.0, 75.0), 18.0, 12.0, 180.0, 0.8),
         (GATE, 8.0, 6.0, GATE_FACING, 0.0), (COURT, COURT_SIZE[0], COURT_SIZE[1], 180.0, -1.0)]  # the guest house MON-13, the
# novices' yard MON-30, the Jakhang MON-12 (chapter 03's footprints at chapter 02's places), the gatehouse and the courtyard


SQUARE = 45.0  # a bend turning more than this gets a square landing, the next leg leaving from its side


def square_bends(legs, joins):
    """A bend turning more than SQUARE: its landing square (the way's width each way) and the next leg leaving from its
    side, the legs after it moved with it (gorge_stair.py's lay goes on LAND along the leg and turns there, so a square
    turn's next flight began across its landing's far half: its first riser and its inner wall stood in the way). The
    legs and joins, and the numbers of the squared landings."""
    legs = [list(l) for l in legs]
    joins = [list(j) for j in joins]
    squares = []
    for k, j in enumerate(joins):
        if j[0] != "bend" or k + 1 >= len(legs):
            continue
        d, e = np.array(legs[k][1], float), np.array(legs[k + 1][1], float)
        if math.degrees(math.acos(max(-1.0, min(1.0, float(np.dot(d, e)))))) <= SQUARE:
            continue
        delta = np.array(j[1], float) + d * (GS.WIDTH / 2) + e * (GS.WIDTH / 2) - np.array(legs[k + 1][0], float)
        for m in range(k + 1, len(legs)):
            legs[m][0] = np.array(legs[m][0], float) + delta
        for m in range(k + 1, len(joins)):
            joins[m][1] = np.array(joins[m][1], float) + delta
        squares.append(int(j[4]))
    return [tuple(l) for l in legs], [tuple(j) for j in joins], squares


def widen():
    """The Gorge Stair's constants for a monastery's lane: its width, its band and a switchback's spacing."""
    GS.WIDTH = CLEAR + GS.PARA
    GS.BAND = GS.WIDTH + 2 * GS.SHOULDER
    GS.SEP = GS.BAND + 1.0
    GS.OFF = 80.0  # the first leg within this many degrees of the way in through the gate
    GS.TRIALS = 12


def main():
    widen()
    site = GS.Site.load()
    g = site.read(GS.SOURCE)
    Z = lambda x, y: g.z(x, y) - site.shift
    search = "--search" in sys.argv or START is None
    rng = np.random.default_rng(SEED)
    inward = GS.unit(GATE_FACING + 180.0)  # (through the gate into the monastery)
    foot = np.array(GATE) + inward * (GATE_DEPTH / 2 + FOOT_OUT)
    st = json.load(open(STEPS, encoding="utf-8")) if os.path.exists(STEPS) else {}
    z0 = float(st["top"]["z"]) if st else float(Z(*GATE))  # (the passage's floor: the forecourt's, the 1,080 steps' top)
    court = np.array(COURT)
    passage = court + np.array([GATE_U, -COURT_SIZE[1] / 2])
    turn = passage - np.array([0.0, TOP_OUT])
    north = np.array([0.0, 1.0])
    top = np.array(BENCH)
    keeps = [GS.rect(np.array(c), w, d, f, gr) for c, w, d, f, gr in KEEPS]
    cost0, riser, steps = GS.make_cost(Z, keeps, None, foot, inward, z0, top, GS.unit(70.0), COURT_Z, SPLIT, LEAD, into=INTO)

    cost = cost0
    guess = lambda t: GS.zigzag(Z, foot, z0, riser, SPLIT, steps, LEAD, 1.0 if t % 2 == 0 else -1.0, 0.0 if t < 2 else 6.0, rng)
    fun, v = GS.fit("gonpa", cost, len(SPLIT), inward, top, foot, START, search, rng, guess)
    if search:
        print("gonpa_ways: the search's legs: START = [%s]" % ", ".join("%.4f" % a for a in v))
    rows = []
    cost(v, rows)
    legs, joins = GS.lay(v, foot, z0, riser, SPLIT, steps, LEAD)
    legs, joins, squares = square_bends(legs, joins)
    lanes, nf = GS.lanes_of("MON-W", legs, joins, "gonpa_s")
    for ln in lanes:  # a squared bend's landing the way's width along the leg it ends
        if ln["id"] in ["MON-W.B%02d" % n for n in squares]:
            ln["length"] = round(GS.WIDTH, 3)
            ln["profile"][1][0] = round(GS.WIDTH, 3)
            ln["flight"]["length"] = round(GS.WIDTH, 3)
    # the foot's landing from the gate's passage to the first step; the last flight's top on level into the passage,
    # through the range and out into the courtyard
    gate_back = np.array(GATE) + inward * (GATE_DEPTH / 2)

    def level(lid, a, b, z, fname, width=None):
        d = b - a
        L = float(np.hypot(*d))
        if L < 0.2:
            return None
        d = d / L
        return {"id": lid, "from": [round(float(a[0]), 3), round(float(a[1]), 3)], "dir": [round(float(d[0]), 5), round(float(d[1]), 5)],
                "length": round(L, 3), "width": round(width or GS.WIDTH, 3), "z_a": round(z, 3), "z_b": round(z, 3),
                "profile": [[0.0, round(z - 0.1, 3)], [round(L, 3), round(z - 0.1, 3)]], "steps": True,
                "flight": {"file": fname, "s": 0.0, "rise": 0.0, "z": round(z, 3), "n": 0, "length": round(L, 3), "walls": None}}

    S_, d_, L_, _ = legs[-1]
    end = S_ + d_ * L_
    corner = np.array([turn[0], end[1]])  # (east along the bench, then north to the passage)
    extra = [level("MON-W.A00", gate_back, foot, z0, "gonpa_s_a00"),
             level("MON-W.L%02d" % (nf + 1), end, corner, COURT_Z, "gonpa_s_l%02d" % (nf + 1)),
             level("MON-W.L%02d" % (nf + 2), corner, turn, COURT_Z, "gonpa_s_l%02d" % (nf + 2))]
    lanes = [ln for ln in extra[:1] if ln] + lanes + [ln for ln in extra[1:] if ln]
    (ca, cb, cz, cw) = CHORA_WALK
    lanes.append(level("MON-C.01", np.array(ca), np.array(cb), cz, "gonpa_c_01", width=cw))  # (a way of its own)
    walk = [[round(float(gate_back[0] - inward[0] * 8.0), 2), round(float(gate_back[1] - inward[1] * 8.0), 2), round(z0, 3)],
            [round(float(gate_back[0]), 2), round(float(gate_back[1]), 2), round(z0, 3)]]  # (in from the forecourt through the gate)
    walk += GS.walk_of(legs, joins)
    for q in (corner, turn, passage, passage + north * RANGE_D, passage + north * (RANGE_D + 6.0)):
        walk.append([round(float(q[0]), 2), round(float(q[1]), 2), round(COURT_Z, 3)])
    out = {"about": "Dungkar Gönpa's way up from the South Gate to the Tsokchen's courtyard (tools/town/gonpa_ways.py; M3 sprint 3, step 1): "
                    "`lanes` its flights and landings in tools/terrain/pads.py's form (a flight's `flight` for ../tibet-blender export_lanes.py and "
                    "world/town.gd); `walk` a walker's way from the 1,080 steps' forecourt through the South Gate, up the way and through the "
                    "courtyard's south passage into it; `legs` the fit. Regenerated with the terrain.",
           "lanes": lanes, "walk": walk, "court": {"at": [COURT[0], COURT[1]], "size": list(COURT_SIZE), "z": COURT_Z, "gate_u": GATE_U},
           "legs": {"steps": int(sum(steps)), "riser": round(riser, 4), "flights": len(steps), "bearings": [round(float(a), 2) for a in v],
                    "cost": round(float(fun), 1), "foot": [round(float(foot[0]), 2), round(float(foot[1]), 2), round(z0, 3)],
                    "top": [round(float(top[0]), 2), round(float(top[1]), 2), COURT_Z], "turn": [round(float(turn[0]), 2), round(float(turn[1]), 2)]}}
    json.dump(out, open(OUT, "w", encoding="utf-8"), indent=1)
    fl = [r for r in rows if r["kind"] == "flight"]
    lines = ["# Dungkar Gönpa's way up from the South Gate (tools/town/gonpa_ways.py)", "",
             "_What this is: the report of the planner that lays the way from the South Gate's passage up the south flank to the Tsokchen's courtyard (M3 sprint 3, step 1). Regenerated with the terrain; do not edit._", "",
             "- %d steps of %.3f m in %d flights and %d legs, from %.1f m at the gate to the courtyard's %.1f m; legs at %s degrees; cost %.0f." % (
                 sum(steps), riser, len(steps), len(SPLIT), z0, COURT_Z, ", ".join("%.0f" % (a % 360.0) for a in v), fun),
             "- The flights' ground: the middle %.1f m off it on average, cut %.1f m and filled %.1f m at most." % (
                 float(np.mean([r["mean"] for r in fl])), max(r["cut"] for r in fl), max(r["fill"] for r in fl)), "",
             "| Flight | Steps | Bearing | Middle off the ground (m) | Cut (m) | Fill (m) |", "|---|---|---|---|---|---|"]
    for r in fl:
        lines.append("| %d | %d | %.0f | %.1f | %.1f | %.1f |" % (r["number"], r["n"], r["bearing"] % 360.0, r["mean"], r["cut"], r["fill"]))
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("gonpa_ways: %d steps of %.3f m in %d flights, legs at %s, cost %.0f; %d lanes, the walk %d points -> %s" % (
        sum(steps), riser, len(steps), ", ".join("%.0f" % (a % 360.0) for a in v), fun, len(lanes), len(walk), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
