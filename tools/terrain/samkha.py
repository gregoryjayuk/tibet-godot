#!/usr/bin/env python3
"""Terrain pass 5d, Samkha (M2 sprint 4, step 1; plan chapter 02, SAM-01 to SAM-05; chapter 03, 5 and 7): the ground the
castle and its chain bridge stand on, at 1 m, by tools/terrain/pads.py after the arrival's pass and before its lanes. The
sculpted ground rises from the castle's south-west corner (2,641) to the slot's north rim (2,653.5): no knob, and both of
the chain bridge's designed ends (2,647 in the gate passage, 2,652 at the south pavilion) lie 3-4 m under the built rims.
The plan's default (docs/PLAN.md, M2 sprint 4): the built levels kept, the castle on its ground as built, the bridge
between the built rims with the design's sag. Here:
1. Samkha Khar's ward (40 x 28 m, the tower 22 x 18 m at its north, its south side on the slot's rim) levelled at
   WARD_Z, the castle gate's level, the ground handed back to the slope over 3 m (its walls and the tower's plinth stand
   on the edges); never the slot's face below the rim.
2. The chain bridge SAM-03 on x = -130 from its north end at the ward's south edge (in the gate passage SAM-02, its
   windlass under the passage's outer end) to its south end on the south pavilion's floor (SAM-04, 2,655, where its
   chains are anchored): its deck on the chord between the two with a sag of SAG at the middle; the ground under it cut
   CLEAR below the deck, 4 m wide, where the rims and the south shelf stood over it, so it is carried over them and not
   through them.
3. The gate passage SAM-02 through the castle's ground storey (step 4 of the sprint): the castle stands on the rim, its
   south face over the rock, its ground storey on a plinth 1.5 m over the ward at the deck's end's level (the kit's
   samkha.castle, ../tibet-blender/kit/samkha.py); the ground under the passage at its floor (SINK under it, so the
   kit's flags show), and down the five steps from its inner door to the ward under their inner corners.
4. The south pavilion SAM-04's floor and its stele's ground, levelled at the deck's south end.
The bridge's line and levels, the ward, the castle, the passage and its steps are written to data/samkha.json for the
kit and the game.
Run: tools/py tools/terrain/samkha.py   Writes data/samkha.json (tools/terrain/build.sh runs it before pads.py; pads.py
calls `shape`). The check: tools/terrain/samkha_check.py (docs/terrain/samkha-report.md).
"""
import json
import math
import os

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "samkha.json")

WARD = (-150.0, -110.0, -96.0, -68.0)  # x from, to, y from, to (40 x 28 m)
TOWER = (-141.0, -119.0, -96.0, -78.0)  # 22 x 18 m on the rim, its south face on the ward's south edge (the gazetteer's
# centre (-130, -78) 9 m north: the plan's passage runs through the house; docs/DECISIONS.md, 9 Oct 2026)
CASTLE = (-130.0, -87.0)  # the kit's origin (the tower's middle on the ward's level), its front (the passage) south
WARD_Z = 2649.0  # the castle gate's level, the ward's and the tower's ground floor's
BATTER = 3.0
BRIDGE_X = -130.0
NORTH = (-95.0, 2650.5)  # the deck's north end: y, z (on the rim, in the gate passage's outer end)
SOUTH = (-143.0, 2655.0)  # its south end on the south pavilion's floor
SAG = 5.0  # metres under the chord at the middle (chapter 03, 7: 2,647, 2,644 and 2,652 make about 5)
WIDTH = 1.6  # the deck (chapter 02, SAM-03)
CLEAR = 1.5  # the ground at least this far under the deck where it is carried over the rims
PASSAGE = {"from": [-130.0, -95.0], "to": [-130.0, -78.2], "width": 3.0, "z_from": 2650.5, "z_to": 2650.5}
# (on the bridge's own line, where the gazetteer's SAM-02 stands 2 m east of it: the deck lands in the passage, which runs
# on the level of its end through the ground storey to the inner door in the north face)
STAIR = {"from": [-130.0, -78.2], "to": [-130.0, -76.1], "width": 3.6, "z_from": 2650.5, "z_to": WARD_Z, "steps": 5}
SINK = 0.08  # the ground this far under the passage's floor and under the steps' inner corners: the kit's own show
WARD_GATE = [-109.6, -73.5]  # the ward's gate in its east wall (the kit's WARD_GATE)
PAVILION = (-136.5, -120.5, -150.5, -143.0)  # SAM-04's floor and its stele's ground, at the deck's south end, from it south
PAVILION_AT = (-130.0, -146.0)  # the kit's origin: its floor's north edge on the deck's end


def smoothstep(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def deck_z(y):
    """The chain bridge's deck at y (between its ends): the chord less the sag's parabola."""
    f = np.clip((y - NORTH[0]) / (SOUTH[0] - NORTH[0]), 0.0, 1.0)
    return NORTH[1] + (SOUTH[1] - NORTH[1]) * f - 4.0 * SAG * f * (1.0 - f)


def shape(z, g, town):
    """Shapes the design heights `z` in place; returns report lines."""
    x0, x1, y0, y1 = -170.0, -90.0, -156.0, -55.0
    c0, c1 = int((x0 - g.x0) / g.res), int((x1 - g.x0) / g.res)
    r0, r1 = int((g.y1 - y1) / g.res), int((g.y1 - y0) / g.res)
    sub = (slice(r0, r1), slice(c0, c1))
    X, Y = np.meshgrid(g.x0 + (np.arange(c0, c1) + 0.5) * g.res, g.y1 - (np.arange(r0, r1) + 0.5) * g.res)
    Z = z[sub].astype(np.float64)
    before = Z.copy()
    lines = []
    # 1. The ward: level at WARD_Z, handed back to the slope over the batter; the slot's face below the rim left
    wx0, wx1, wy0, wy1 = WARD
    dx = np.maximum(np.maximum(wx0 - X, X - wx1), 0.0)
    dy = np.maximum(np.maximum(wy0 - Y, Y - wy1), 0.0)
    d = np.hypot(dx, dy)
    w = 1.0 - smoothstep(0.0, BATTER, d)
    w = np.where(Y < wy0, w * (Y > wy0 - 1.5), w)  # not down the slot's face
    moved_w = np.abs(WARD_Z - Z) * w
    Z = Z * (1.0 - w) + WARD_Z * w
    inside = d <= 0.0
    lines.append("Samkha Khar's ward levelled at %.1f m (the ground moved %.1f m at most; it had stood %.1f-%.1f m)" % (
        WARD_Z, float(moved_w.max()), float(before[inside].min()), float(before[inside].max())))
    # 2. Under the chain bridge: the ground at least CLEAR under its deck, 4 m wide, along its whole length
    on = (np.abs(X - BRIDGE_X) <= 2.0) & (Y <= NORTH[0] + 0.5) & (Y >= SOUTH[0] - 0.5)
    cap = deck_z(Y) - CLEAR
    # at its ends the deck lies on its abutments: the ground there at the deck's underside, not cut away
    ends = (Y > NORTH[0] - 1.5) | (Y < SOUTH[0] + 1.5)
    cut = np.where(on & ~ends, np.maximum(Z - cap, 0.0), 0.0)
    Z = Z - cut
    lines.append("under the chain bridge (x %.0f, y %.0f to %.0f, its deck %.1f-%.1f-%.1f m): the rims cut up to %.1f m to clear it" % (
        BRIDGE_X, NORTH[0], SOUTH[0], NORTH[1], float(deck_z(np.array((NORTH[0] + SOUTH[0]) / 2.0))), SOUTH[1], float(cut.max())))
    # 3. The gate passage's floor through the castle's ground storey, at the deck's end's level, SINK under the kit's
    # flags; then down the five steps from its inner door to the ward, under their inner corners
    for part in (PASSAGE, STAIR):
        pa, pb = part["from"], part["to"]
        ylo, yhi = min(pa[1], pb[1]), max(pa[1], pb[1])
        inp = (np.abs(X - pa[0]) <= part["width"] / 2.0 + 0.5) & (Y >= ylo - 0.5) & (Y <= yhi + 0.5)
        f = np.clip((Y - pa[1]) / (pb[1] - pa[1]), 0.0, 1.0)
        Z = np.where(inp, part["z_from"] + (part["z_to"] - part["z_from"]) * f - SINK, Z)
    lines.append("the gate passage's floor at %.1f m through the castle from the deck's end (y %.0f) to its inner door (y %.1f), then %d steps down to the ward (%.1f m) by y %.1f" % (
        PASSAGE["z_from"], PASSAGE["from"][1], PASSAGE["to"][1], STAIR["steps"], STAIR["z_to"], STAIR["to"][1]))
    # 4. The south pavilion's floor and its stele's ground at the deck's south end, handed back over 2 m
    px0, px1, py0, py1 = PAVILION
    dx = np.maximum(np.maximum(px0 - X, X - px1), 0.0)
    dy = np.maximum(np.maximum(py0 - Y, Y - py1), 0.0)
    w = 1.0 - smoothstep(0.0, 2.0, np.hypot(dx, dy))
    w = np.where(Y > py1, 0.0, w)  # nothing north of the deck's end: the deck's last metres rise over the ground there
    moved_p = np.abs(SOUTH[1] - Z) * w
    Z = Z * (1.0 - w) + SOUTH[1] * w
    lines.append("the south pavilion's floor levelled at %.1f m (the ground moved %.1f m at most)" % (SOUTH[1], float(moved_p.max())))
    changed = np.abs(Z - before) > 0.01
    z[sub] = Z.astype(z.dtype)
    lines.append("%d cells of 1 m changed (x %.0f to %.0f, y %.0f to %.0f)" % (int(changed.sum()), float(X[changed].min()) if changed.any() else 0.0,
                 float(X[changed].max()) if changed.any() else 0.0, float(Y[changed].min()) if changed.any() else 0.0, float(Y[changed].max()) if changed.any() else 0.0))
    return lines


def data():
    ys = np.linspace(NORTH[0], SOUTH[0], 25)
    return {"about": "Samkha (M2 sprint 4), written by tools/terrain/samkha.py: the chain bridge SAM-03 (its line on x, its ends and its deck's sag, sampled), Samkha Khar's ward and tower and their level, the castle's origin, the gate passage SAM-02 through its ground storey from the bridge's north end and its steps down to the ward, the ward's gate, the south pavilion SAM-04, in the town grid (x east, y north, design z).",
            "bridge": {"x": BRIDGE_X, "north": list(NORTH), "south": list(SOUTH), "sag": SAG, "width": WIDTH,
                       "deck": [[round(float(y), 2), round(float(deck_z(np.array(y))), 3)] for y in ys]},
            "ward": {"x": [WARD[0], WARD[1]], "y": [WARD[2], WARD[3]], "z": WARD_Z},
            "tower": {"x": [TOWER[0], TOWER[1]], "y": [TOWER[2], TOWER[3]], "z": WARD_Z},
            "castle": {"at": list(CASTLE), "z": WARD_Z, "facing": 180.0},
            "passage": PASSAGE, "stair": STAIR, "ward_gate": WARD_GATE,
            "pavilion": {"at": list(PAVILION_AT), "z": SOUTH[1], "facing": 180.0}}


def main():
    json.dump(data(), open(OUT, "w", encoding="utf-8"), indent=1)
    print("samkha: the chain bridge from (%.0f, %.0f) %.1f m to (%.0f, %.0f) %.1f m, the ward at %.1f m -> %s" % (
        BRIDGE_X, NORTH[0], NORTH[1], BRIDGE_X, SOUTH[0], SOUTH[1], WARD_Z, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
