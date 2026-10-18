#!/usr/bin/env python3
"""Terrain pass 5c, the arrival (M2 sprint 3, step 1; ISS-138; plan chapter 02, SER-01 to SER-03, R-01, sightline rule 1;
chapter 08, V-01): the ground south of the Samkha slot shaped for M2's acceptance 1 ("walk the cliff gallery ... come out
under the Gate Chorten into V-01"), at 1 m, by tools/terrain/pads.py after its pads and road beds and before its lanes
(the south ramp's among them) are carved. The sculpted ground had no cliff under the gallery's line (its deck would
have stood 4-20 m over a slope of 4-18 degrees), a hollow where the road turns the ridge nose to SER-01, and level
ground west of SER-01 that hid V-01's chain bridge and south pavilion. Here:
1. The Golden Slot's south wall along the cliff gallery SER-03 (east to west, its deck falling from 2,712 to 2,700): the
   rock face a metre inland of the gallery's line (the deck 1.8 m wide on it) rising from a metre under the deck to 8 m
   over it within 2.5 m, then on up to a crest 10 m inland and back down to the ground behind; below the deck, the rock
   falling from the face at about 74 degrees to the water (the river's channel and banks never raised).
2. The ridge nose: R-01 from the gallery's west end to SER-01 in a cutting through the nose, rock rising 9 m over the
   road on the slot's side (the town hidden until the Gate Chorten) and 5 m on the hill's, the nose ending at the
   chorten, so V-01 opens as the road turns round it.
3. R-01's bed, 4 m wide with 3 m batters, from the gallery to SER-01 and on past the eight chortens SER-02 (the road
   splitting round the row, the westbound on its south side, so both directions keep it on their right; the row and
   the road stepping down from birth at +130 to nirvana at +60, 2,687 to 2,676) to the south pavilion SAM-04 (2,655).
4. V-01's near ground: west of the chorten, in the frame's cone (bearings 262-300 degrees), no higher than 10.5 degrees
   under the eye (2,695.6 m), so the ground falls away before the view; R-01's bed and the row keep their own levels.
The town's ground (north of the slot) is never touched. The road's line, the gallery's and V-01's station are written
to data/arrival.json for the game (world/town.gd places what stands on them; the caravan walks them).
Run: tools/py tools/terrain/arrival.py   Writes data/arrival.json (tools/terrain/build.sh runs it before pads.py; pads.py
calls `shape`). The check: tools/terrain/arrival_check.py (docs/terrain/arrival-report.md).
"""
import json
import math
import os

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "arrival.json")

GALLERY = ((420.0, -245.0, 2712.0), (285.0, -150.0, 2700.0))  # SER-03's line, east to west, its deck's level
FACE = -1.0  # the rock face, this far from the line inland (negative: left of the westbound walker)
DECK_W = 1.8
SER20 = (430.0, -250.0, 2712.0)
SER01 = (170.0, -175.0, 2692.0)
EYE = (166.0, -175.0, 2695.6)  # V-01's station: on the Gate Chorten's west side, an eye 1.6 m over its 2,694 m
PASSAGE = 282.0  # the chorten's passage, its axis's bearing westward (the road comes in at 258 and goes on at 304)
ROW = (130.0, 60.0, -150.0, 2687.0, 2676.0)  # SER-02: birth's x, nirvana's, the row's y, their platforms' levels
ROW_D = 5.0
WIDTH, BATTER = 4.0, 3.0
# R-01 from the gallery's west end, through the nose and the chorten, to the eight chortens' split; its two branches
# past the row; and on from where they meet to the south pavilion: (x, y, z) of the bed's line.
def row_z(x):
    return ROW[3] + (ROW[4] - ROW[3]) * (ROW[0] - x) / (ROW[0] - ROW[1])


ROAD = [(285.0, -150.0, 2700.0), (178.0, -173.0, 2692.0), (163.0, -176.0, 2692.0), (146.0, -150.5, 2688.6)]
SOUTH = [(146.0, -150.5, 2688.6), (136.0, -156.5, row_z(136.0)), (56.0, -156.5, row_z(56.0)), (46.0, -150.5, row_z(51.0))]
NORTH = [(146.0, -150.5, 2688.6), (136.0, -143.5, row_z(136.0)), (56.0, -143.5, row_z(56.0)), (46.0, -150.5, row_z(51.0))]
WEST = [(46.0, -150.5, row_z(51.0)), (-122.0, -141.0, 2655.0)]
CONE = (262.0, 300.0, 8.0, 140.0)  # V-01's frame for the near ground: bearings, from and to (m)
SHELF = (-124.0, -30.0, -139.0, -124.0)  # the south rim's shelf for the south ramp's approach: x from, to, y from, to
SHELF_Z = (2655.0, 2652.5)  # its level at its west and east ends (tools/town/south_ramp.py: the pavilion, the top leg)
DROP = math.tan(math.radians(10.5))


def smoothstep(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def segments(line):
    return list(zip(line[:-1], line[1:]))


def seg_field(X, Y, a, b):
    """For the segment a -> b (x, y, z): t along it (0-1, unclamped), the signed distance n (positive on the right of
    a walker going from a to b), the distance d to the segment, and the bed's z at the nearest point."""
    ax, ay, az = a
    bx, by, bz = b
    dx, dy = bx - ax, by - ay
    L = math.hypot(dx, dy)
    ux, uy = dx / L, dy / L
    t = ((X - ax) * ux + (Y - ay) * uy) / L
    n = (X - ax) * uy - (Y - ay) * ux  # right of the walker: (uy, -ux)
    tc = np.clip(t, 0.0, 1.0)
    d = np.hypot(X - (ax + tc * dx), Y - (ay + tc * dy))
    return t, n, d, az + tc * (bz - az), L


def polyline_bed(X, Y, lines, width=WIDTH):
    """The nearest of the lines' segments at every cell: (d, bed z)."""
    D = np.full(X.shape, np.inf)
    Z = np.zeros(X.shape)
    for line in lines:
        for a, b in segments(line):
            _, _, d, z, _ = seg_field(X, Y, a, b)
            take = d < D
            D = np.where(take, d, D)
            Z = np.where(take, z, Z)
    return D, Z


def river_distance(X, Y, town):
    """The distance to the Serchu's and the slot's water lines (the channels and banks the carving cut, never raised)."""
    cp = {k: v["pos"] for k, v in town["control"].items() if "pos" in v}
    pts = [cp[k] for k in ("S1", "S0", "C", "X")]
    D = np.full(X.shape, np.inf)
    for a, b in zip(pts[:-1], pts[1:]):
        _, _, d, _, _ = seg_field(X, Y, a, b)
        D = np.minimum(D, d)
    return D


def shape(z, g, town):
    """Shapes the design heights `z` (rows north to south, the Grid g's window) in place; returns report lines."""
    x0, x1, y0, y1 = -140.0, 470.0, -330.0, -112.0
    c0, c1 = int((x0 - g.x0) / g.res), int((x1 - g.x0) / g.res)
    r0, r1 = int((g.y1 - y1) / g.res), int((g.y1 - y0) / g.res)
    sub = (slice(r0, r1), slice(c0, c1))
    X, Y = np.meshgrid(g.x0 + (np.arange(c0, c1) + 0.5) * g.res, g.y1 - (np.arange(r0, r1) + 0.5) * g.res)
    Z = z[sub].astype(np.float64)
    before = Z.copy()
    wr = smoothstep(6.0, 9.0, river_distance(X, Y, town))  # nothing raised in the water's channel and banks
    # the slot's north side (the town, Samkha) is never touched: south of the C -> X line only, and east of it the Serchu's
    cp = {k: v["pos"] for k, v in town["control"].items() if "pos" in v}
    cx_, cy_ = cp["C"][0], cp["C"][1]
    xx_, xy_ = cp["X"][0], cp["X"][1]
    south_of_slot = (Y < cy_ + (X - cx_) * (xy_ - cy_) / (xx_ - cx_) - 4.0) | (X > cx_ + 20.0)
    lines = []

    # 1. The gallery's rock
    a, b = GALLERY
    t, n, d, _, L = seg_field(X, Y, a, b)
    deck = a[2] + np.clip(t, 0.0, 1.0) * (b[2] - a[2])
    along = smoothstep(-0.02, 0.04, t) * (1.0 - smoothstep(0.96, 1.03, t))  # its ends: SER-20's pad, the nose's cutting
    u = FACE - n  # inland from the face
    tc = np.clip(t, 0.0, 1.0)
    crest = 11.0 + 3.5 * np.sin(6.1 * tc + 0.4) + 1.8 * np.sin(15.3 * tc + 2.1)  # the rock's crest over the deck, uneven
    back = 0.65 + 0.2 * np.sin(4.3 * tc + 1.0)  # and its back falling to the ground behind at 25-40 degrees
    inland = np.where(u <= 2.5, deck - 1.0 + 9.0 * smoothstep(0.0, 2.5, u),
                      np.where(u <= 10.0, deck + 8.0 + (crest - 8.0) * (u - 2.5) / 7.5, deck + crest - back * (u - 10.0)))
    below = deck - 2.5 - 3.5 * (n - FACE)
    target = np.where(n < FACE, inland, below)
    raise_g = np.maximum(target - Z, 0.0) * along * wr * south_of_slot
    raise_g = raise_g * (1.0 - smoothstep(60.0, 75.0, u)) * (n < 14.0)  # inland, fading out between 60 and 75 m
    # under the deck itself the rock stands at least 2.5 m below it (the beams' sockets in the face above the drop)
    under = (np.abs(n) <= DECK_W / 2 + 0.2) & (t > 0.03) & (t < 0.97)
    Z = Z + raise_g
    Z = np.where(under, np.minimum(Z, deck - 2.5 - 3.5 * np.clip(n - FACE, 0.0, None)), Z)
    lines.append("the gallery's rock: raised up to %.1f m (the face and the crest behind it), the ground under its deck %.1f-%.1f m below it" % (
        float(raise_g.max()), float((deck - Z)[under].min()), float((deck - Z)[under].max())))

    # 2. The nose: the cutting from the gallery's west end to the chorten
    a, b = ROAD[0], ROAD[1]
    t, n, d, zr, Ln = seg_field(X, Y, a, b)
    zroad = a[2] + np.clip(t, 0.0, 1.0) * (b[2] - a[2])
    within = (t > -0.02) & (t < 1.06)
    # the slot's side (right of the westbound walker: north): the nose, 9 m over the road, ending at the chorten
    tn = np.clip(t, 0.0, 1.0)
    # its crest over the road, uneven, and higher towards the gallery, where the slot closes in before the reveal (the
    # upper town had shown over it from the gallery, 500 m off along its line)
    rib = 9.0 + 2.0 * np.sin(9.0 * tn + 0.7) + 9.0 * (1.0 - smoothstep(0.0, 0.4, tn))
    crest = 7.0 + 6.0 * (1.0 - smoothstep(0.0, 0.4, tn))
    north = zroad + rib * smoothstep(WIDTH / 2, WIDTH / 2 + 3.5, n) - (1.2 + 0.3 * np.sin(5.0 * tn)) * np.maximum(n - crest, 0.0)
    nose_t = smoothstep(-0.06, 0.03, t) * (1.0 - smoothstep(0.93, 1.02, t))  # from the gallery's end to the chorten's corner
    # the hill's side (south): 5 m over the road, then falling back to the ground at about 40 degrees
    south = zroad + 5.0 * smoothstep(WIDTH / 2, WIDTH / 2 + 3.5, -n) - 0.85 * np.maximum(-n - 8.0, 0.0)
    hill_t = smoothstep(-0.02, 0.06, t) * (1.0 - smoothstep(0.9, 1.0, t))
    tgt = np.where(n > 0.0, north, south)
    wt = np.where(n > 0.0, nose_t, hill_t) * within * wr * south_of_slot * (1.0 - smoothstep(45.0, 60.0, np.abs(n)))
    raise_n = np.maximum(tgt - Z, 0.0) * wt
    Z = Z + raise_n
    lines.append("the nose: raised up to %.1f m over the hollow, its cutting %.0f m long" % (float(raise_n.max()), Ln))

    # 3. R-01's bed: the cutting and the chorten's way, the row's two branches, on to the south pavilion
    D, Zb = polyline_bed(X, Y, [[SER20, GALLERY[0]], ROAD, SOUTH, NORTH, WEST])
    # the row itself, between the branches: each chorten's platform on the row's slope
    on_row = (X >= ROW[1] - 4.0) & (X <= ROW[0] + 4.0) & (np.abs(Y - ROW[2]) <= ROW_D / 2 + 1.0)
    Dr = np.where(on_row, 0.0, np.inf)
    Zr = row_z(np.clip(X, ROW[1], ROW[0]))
    D = np.where(on_row, Dr, D)
    Zb = np.where(on_row, Zr, Zb)
    wb = 1.0 - smoothstep(WIDTH / 2, WIDTH / 2 + BATTER, D)
    moved = np.abs(Zb - Z) * wb
    Z = Z * (1.0 - wb) + Zb * wb
    lines.append("R-01's bed: %.0f m of road and the row's platform, the ground moved at most %.1f m" % (
        sum(math.hypot(q[0] - p[0], q[1] - p[1]) for ln in (ROAD, SOUTH, WEST) for p, q in segments(ln)), float(moved.max())))

    # 3b. The slot's south rim between the south pavilion and the south ramp's switchbacks, cut down to a shelf at the
    # pavilion's level for the animal branch R-02 (tools/town/south_ramp.py's approach; the sculpted rim stood 12-18 m
    # over SAM-04's 2,655 m there), the ground handed back to the plateau over 2 m in 3; R-01's bed above it kept
    sx0, sx1, sy0, sy1 = SHELF
    dxs = np.maximum(np.maximum(sx0 - X, X - sx1), 0.0)
    dys = np.maximum(np.maximum(sy0 - Y, Y - sy1), 0.0)
    dout = np.hypot(dxs, dys)
    shelf_z = SHELF_Z[0] + (SHELF_Z[1] - SHELF_Z[0]) * np.clip((X - sx0) / (sx1 - sx0), 0.0, 1.0)
    cap_s = shelf_z + 1.5 * dout
    off_bed = smoothstep(WIDTH / 2, WIDTH / 2 + BATTER, D)
    cut_s = np.maximum(Z - cap_s, 0.0) * off_bed * (Y < -119.0)
    Z = Z - cut_s
    lines.append("the shelf for the south ramp's approach: the slot's rim cut down up to %.1f m to %.0f-%.0f m" % (float(cut_s.max()), SHELF_Z[0], SHELF_Z[1]))

    # 4. V-01's near ground: under 10.5 degrees below the eye in the frame's cone, but on the road and the row
    ex, ey, ez = EYE
    r = np.hypot(X - ex, Y - ey)
    brg = np.degrees(np.arctan2(X - ex, Y - ey)) % 360.0
    cone = smoothstep(CONE[0] - 4.0, CONE[0], brg) * (1.0 - smoothstep(CONE[1], CONE[1] + 4.0, brg))
    cone *= smoothstep(CONE[2] - 2.0, CONE[2], r) * (1.0 - smoothstep(CONE[3] - 20.0, CONE[3], r))
    cap = ez - DROP * r - 0.3
    free = 1.0 - (1.0 - smoothstep(WIDTH / 2, WIDTH / 2 + BATTER, D))  # off the beds
    lower = np.maximum(Z - cap, 0.0) * cone * free
    Z = Z - lower
    lines.append("V-01's near ground: lowered up to %.1f m in its cone (bearings %.0f-%.0f, %.0f-%.0f m)" % (float(lower.max()), *CONE))
    changed = np.abs(Z - before) > 0.01
    z[sub] = Z.astype(z.dtype)
    lines.append("%d cells of 1 m changed, from %.1f m down to %.1f m up" % (int(changed.sum()), float((Z - before).min()), float((Z - before).max())))
    return lines


def data():
    """The arrival's lines for the game: the road (its branches), the gallery, V-01's station and the chorten's axis."""
    r = lambda pts: [[round(p[0], 2), round(p[1], 2), round(p[2], 2)] for p in pts]
    return {"about": "The arrival by the Serchu road (M2 sprint 3), written by tools/terrain/arrival.py: R-01's line from SER-20 along the cliff gallery, through the nose to the Gate Chorten SER-01, past the eight chortens SER-02 (west: the branch south of the row; east: north of it) to the south pavilion SAM-04, in the town grid (x east, y north, design z); the gallery's line and deck; V-01's station and the chorten's passage axis.",
            "road_west": r([SER20, GALLERY[0]] + [GALLERY[1]] + ROAD[1:] + SOUTH[1:] + WEST[1:]),
            "road_east": r(list(reversed(WEST)) + list(reversed(NORTH))[1:] + list(reversed(ROAD[1:])) + [GALLERY[1], GALLERY[0], SER20]),
            "gallery": {"from": list(GALLERY[0]), "to": list(GALLERY[1]), "width": DECK_W, "face": FACE},
            "row": {"from_x": ROW[0], "to_x": ROW[1], "y": ROW[2], "z_from": ROW[3], "z_to": ROW[4], "depth": ROW_D},
            "v01": {"eye": list(EYE), "facing": 290.0, "turn": 52.0},
            "gate_chorten": {"at": list(SER01), "passage_bearing": PASSAGE},
            "ser20": list(SER20)}


def main():
    json.dump(data(), open(OUT, "w", encoding="utf-8"), indent=1)
    print("arrival: %d points on the westbound road -> %s" % (len(data()["road_west"]), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
