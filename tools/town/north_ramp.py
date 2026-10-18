#!/usr/bin/env python3
"""Samkha's north ramp (SAM-06 north; chapter 02: "180 m, 15%, 27 m up to the Yak Gate; zigzags cut into the slot
walls"; M1 sprint 6, step 5), as lanes (tools/terrain/pads.py's form) for the terrain build: from the Yak Gate (SAM-07,
-55, -78) a level approach south to the rim, then five legs at 15% zigzagging down the slot's north wall between
x = -77 and -33, joined by level landings at the switchbacks, to the lower cantilever bridge's north end (SAM-05) about
12 m over the water. The wall there is 60-70 degrees from the rim (y = -94, 2,655 m) to the slot's floor (y = -106,
2,613 m), too steep for switchbacks on its face, so the upper legs are cut back into the rim and the lowest meets the
face: each 4 m further south and 6.75 m lower than the one above (two and a half legs' fall at the far end), the lanes'
walls (tools/town/walls.py) holding each leg's edge over the next. 4 m legs on whole metres, so the game's 1 m ground
keeps each step sharp and most of each leg walkable (3.4 m legs, seven of them, had left a metre). pads.py carves each lane's profile across its width; the street graph walks them (tools/town/graph.py); the
caravan CV-02 climbs them (world/caravan.gd).
Run: tools/py tools/town/north_ramp.py   Writes data/north_ramp.json (tools/terrain/build.sh runs it before pads.py).
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "north_ramp.json")
GATE = (-55.0, -78.0)  # SAM-07, the Yak Gate
TOP = 2651.1  # the approach's level: the ground in the gate (2,652.2 had stood a metre over it, a hump between the piers)
WEST, EAST = -77.0, -33.0  # the switchbacks' lines
Y0, PITCH = -85.0, 4.0  # the first leg's line, and each leg's step south (its width: the legs tile the cut)
FOOT = TOP - 27.0  # the bridge's deck (chapter 02: SAM-05 10 m over the water; 27 m below the gate)
WIDTH = 4.0


def main():
    lanes = []
    z = TOP
    # the approach: level from the gate to the first leg's line
    head = GATE[1] + 0.5  # from just inside the gate, where the lane's ground meets it
    lanes.append({"id": "SAM-06.a", "from": [GATE[0], head], "dir": [0.0, -1.0], "length": round(head - Y0, 2),
                  "width": 4.0, "z_a": z, "z_b": z, "flight": None, "profile": [[0.0, z], [round(head - Y0, 2), z]]})
    # five legs: a half leg east from the approach, three whole ones back and forth, a half leg east to the bridge's end
    x = GATE[0]
    legs = [(x, EAST)] + [((EAST, WEST) if k % 2 == 0 else (WEST, EAST)) for k in range(3)] + [(WEST, GATE[0])]
    GRADE = (TOP - FOOT) / sum(abs(b - a) for a, b in legs)  # 176 m of legs: 15.3%
    for k, (xa, xb) in enumerate(legs):
        y = Y0 - PITCH * k
        L = abs(xb - xa)
        zb = z - GRADE * L
        lanes.append({"id": "SAM-06.%d" % k, "from": [xa, round(y, 2)], "dir": [1.0 if xb > xa else -1.0, 0.0], "length": L,
                      "width": WIDTH, "z_a": round(z, 2), "z_b": round(zb, 2), "flight": None,
                      "profile": [[0.0, round(z, 2)], [L, round(zb, 2)]]})
        z = zb
        if k < len(legs) - 1:  # the landing at the switchback: level, from this leg's outer edge to the next one's
            lx = xb + (WIDTH / 2 if xb == EAST else -WIDTH / 2)
            ya, yb = y + WIDTH / 2, y - PITCH - WIDTH / 2
            lanes.append({"id": "SAM-06.L%d" % k, "from": [lx, round(ya, 2)], "dir": [0.0, -1.0], "length": round(ya - yb, 2),
                          "width": WIDTH, "z_a": round(z, 2), "z_b": round(z, 2), "flight": None,
                          "profile": [[0.0, round(z, 2)], [round(ya - yb, 2), round(z, 2)]]})
    foot = [GATE[0], round(Y0 - PITCH * (len(legs) - 1), 2), round(z, 2)]
    json.dump({"about": "Samkha's north ramp (SAM-06 north), written by tools/town/north_ramp.py: its approach, legs and landings as lanes (tools/terrain/pads.py's form: from, dir, length, width, and a profile of the bed's height along it), carved by pads.py, walled by walls.py, walked by the street graph. foot: the bottom leg's end, where the lower cantilever bridge (SAM-05) begins.",
               "foot": foot, "lanes": lanes}, open(OUT, "w", encoding="utf-8"), indent=1)
    print("north_ramp: %d lanes, the gate at %.1f m, the foot at (%.1f, %.1f) %.2f m, %.0f m of legs -> %s" % (
        len(lanes), TOP, foot[0], foot[1], foot[2], sum(l["length"] for l in lanes if not l["id"].startswith("SAM-06.L") and l["id"] != "SAM-06.a"),
        os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
