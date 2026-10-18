#!/usr/bin/env python3
"""Samkha's south ramp (SAM-06 south; chapter 02: "zigzags cut into the slot walls"; M2 sprint 3, step 1), as lanes
(tools/terrain/pads.py's form) for the terrain build, the north ramp's twin (tools/town/north_ramp.py): the animal branch
R-02 leaves R-01 at the south pavilion SAM-04 (where every caravan pays its toll), runs east along the slot's south rim
to the switchbacks' west line, then zigzags down the slot's south wall in legs between x = -77 and -33, each 4 m further
north and lower than the one above, joined by level landings, to the lower cantilever bridge's south end (SAM-05), the
deck's level the north ramp's foot. The upper legs are cut back into the rim, the lowest meets the face; the lanes'
walls (tools/town/walls.py) hold each leg's edge over the next. pads.py carves them, the caravan CV-02 comes down them
(world/caravan.gd, from the street graph's caravan path, tools/town/graph.py).
Run: tools/py tools/town/south_ramp.py   Writes data/south_ramp.json (tools/terrain/build.sh runs it before pads.py).
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "south_ramp.json")
NORTH = os.path.join(ROOT, "data", "north_ramp.json")
PAVILION = (-122.0, -141.0, 2655.0)  # before SAM-04's east side, on R-01's level there (the pavilion at -130, -145)
WEST, EAST = -77.0, -33.0  # the switchbacks' lines, as the north ramp's
Y_TOP, PITCH = -136.0, 4.0  # the top leg's line, and each leg's step north (its width: the legs tile the cut)
DECK_S = (-55.0, -118.0)  # the lower bridge's south end (the stand-in deck's, world/town.gd)
WIDTH = 4.0
APPROACH_GRADE = 0.05  # along the rim from the pavilion to the top leg


def main():
    foot_z = json.load(open(NORTH, encoding="utf-8"))["foot"][2] if os.path.exists(NORTH) else 2624.1  # the deck's level
    lanes = []
    # the approach: from before the pavilion along the rim to the top leg's west end
    ax, ay = WEST, Y_TOP
    dx, dy = ax - PAVILION[0], ay - PAVILION[1]
    L = math.hypot(dx, dy)
    z = PAVILION[2]
    zb = z - APPROACH_GRADE * L
    lanes.append({"id": "SAM-06S.a", "from": [PAVILION[0], PAVILION[1]], "dir": [round(dx / L, 5), round(dy / L, 5)], "length": round(L, 2),
                  "width": WIDTH, "z_a": round(z, 2), "z_b": round(zb, 2), "flight": None, "profile": [[0.0, round(z, 2)], [round(L, 2), round(zb, 2)]]})
    z = zb
    # five legs: four whole ones east and west, the last half one west to the bridge's end line
    legs = [((WEST, EAST) if k % 2 == 0 else (EAST, WEST)) for k in range(4)] + [(WEST, DECK_S[0])]
    grade = (z - foot_z) / sum(abs(b - a) for a, b in legs)
    for k, (xa, xb) in enumerate(legs):
        y = Y_TOP + PITCH * k
        L = abs(xb - xa)
        zb = z - grade * L
        lanes.append({"id": "SAM-06S.%d" % k, "from": [xa, round(y, 2)], "dir": [1.0 if xb > xa else -1.0, 0.0], "length": L,
                      "width": WIDTH, "z_a": round(z, 2), "z_b": round(zb, 2), "flight": None,
                      "profile": [[0.0, round(z, 2)], [L, round(zb, 2)]]})
        z = zb
        if k < len(legs) - 1:  # the landing at the switchback: level, from this leg's outer edge to the next one's
            lx = xb + (WIDTH / 2 if xb == EAST else -WIDTH / 2)
            ya, yb = y - WIDTH / 2, y + PITCH + WIDTH / 2
            lanes.append({"id": "SAM-06S.L%d" % k, "from": [lx, round(ya, 2)], "dir": [0.0, 1.0], "length": round(yb - ya, 2),
                          "width": WIDTH, "z_a": round(z, 2), "z_b": round(z, 2), "flight": None,
                          "profile": [[0.0, round(z, 2)], [round(yb - ya, 2), round(z, 2)]]})
    # the last few metres north onto the deck's end, level
    y_last = Y_TOP + PITCH * (len(legs) - 1)
    lanes.append({"id": "SAM-06S.b", "from": [DECK_S[0], round(y_last - WIDTH / 2 + 0.5, 2)], "dir": [0.0, 1.0],
                  "length": round(DECK_S[1] - (y_last - WIDTH / 2 + 0.5), 2), "width": WIDTH, "z_a": round(z, 2), "z_b": round(z, 2),
                  "flight": None, "profile": [[0.0, round(z, 2)], [round(DECK_S[1] - (y_last - WIDTH / 2 + 0.5), 2), round(z, 2)]]})
    top = [PAVILION[0], PAVILION[1], PAVILION[2]]
    foot = [DECK_S[0], DECK_S[1], round(z, 2)]
    json.dump({"about": "Samkha's south ramp (SAM-06 south), written by tools/town/south_ramp.py: the animal branch R-02 from the south pavilion SAM-04 along the slot's rim and down its south wall to the lower cantilever bridge's south end, as lanes (tools/terrain/pads.py's form: from, dir, length, width, and a profile of the bed's height along it), carved by pads.py, walled by walls.py. top: where it leaves R-01; foot: the lower bridge's south end.",
               "top": top, "foot": foot, "grade": round(grade, 4), "lanes": lanes}, open(OUT, "w", encoding="utf-8"), indent=1)
    legs_m = sum(abs(b - a) for a, b in legs)
    print("south_ramp: %d lanes, from %.1f m before SAM-04 down %.0f m of legs at %.1f%% to the bridge's south end at %.2f m -> %s" % (
        len(lanes), PAVILION[2], legs_m, grade * 100.0, z, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
