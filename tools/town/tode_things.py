#!/usr/bin/env python3
"""Tödé's fields' and yards' things (M3 sprint 4, step 5; plan chapter 02, TOD-11 to 14, 20, 22, 24, 25; chapter 03, 11.8):
where tools/town/tode.py placed Tödé's houses, named places and paths and tools/town/tode_leat.py its leat, the things on
them, each {id, kit, at, level, facing} for world/town.gd (../tibet-blender kit/tode.py's types):
- the threshing floors TOD-11 to 14 on their pads (14 m across TOD-11 and 12, 12 m TOD-13 and 14), each turned at random;
- the byres and hay stores TOD-22 (chapter 02: "various", "some"): in BYRES of the rammed-earth houses' walled yards, in
  the yard's front corner on its gate's side (the house's sidecar: its GATE socket and its yard's walls), its door
  towards the house, clear of the gate's way in and of the darchen in the far corner;
- the maize and turnip racks TOD-24 on the fields (chapter 02: "on roofs and fields"; the rammed-earth houses' roofs have
  theirs in the kit): at a front corner of RACKS of the tower-houses' and log houses' pads, along the pad's front edge;
- the walnut grove TOD-20 (chapter 02: 60 by 40 m, 0.25 ha): its trees GROVE_GAP apart over the grove's ground, off the
  houses' pads, the paths, the leat and the named places (the kit's tree_walnut, late October, half bare);
- the window stall TOD-25 on its pad by the Tödé chorten's forecourt, its window to the forecourt;
- the Bön households' wheel niches TOD-03.Wn (step 6; chapter 03, 3.2: "prayer-wheel niches by the door set to turn
  anticlockwise"): the kit's tod03_wheel_niche against each Bön house's yard wall beside its gate, outside, away from the
  house (its way comes to the gate from the house's side), facing out; world/town.gd turns their wheels anticlockwise;
- the Yungdrung circuit R-24 round the Bön chapel TOD-02 (step 6; chapter 02's R-24, chapter 03's TOD-02: "the kora path
  round it paved and worn, walked anticlockwise"): its paving on the chapel's terrace (tools/town/tode.py PAD), four
  flagged lanes (`lanes`, `street` and `ring`: carved and paved by tools/terrain/pads.py and control.py, no walls of their
  own: the terrace's edges are walled), and `circuit`, the walkers' line round it anticlockwise from the front's west end,
  close by the wheels in the niches either side of the door (world/tode_people.gd, world/kora_wheels.gd).
Run: tools/py tools/town/tode_things.py   Writes data/tode_things.json and docs/town/tode-things-report.md (tools/terrain/
build.sh runs it after tools/town/tode_leat.py).
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
SOURCE = os.path.join(GEN, "valley_shaped_1m.tif")  # the ground before the pads (where nothing is carved, the ground)
TODE = os.path.join(ROOT, "data", "tode.json")
LEAT = os.path.join(ROOT, "data", "tode_leat.json")
KIT = os.path.join(ROOT, "assets", "generated", "kit", "types")
OUT = os.path.join(ROOT, "data", "tode_things.json")
REPORT = os.path.join(ROOT, "docs", "town", "tode-things-report.md")
SEED = 1908

FLOORS = {"TOD-11": 14, "TOD-12": 14, "TOD-13": 12, "TOD-14": 12}
BYRES = 0.6  # the share of the rammed-earth yards with a byre
BYRE = (6.2, 5.2)  # its size, the kit's at the most
RACKS = 0.4  # the share of the tower-houses' and log houses' pads with a rack at a front corner
GROVE = (-100.0, 470.0, 60.0, 40.0)  # chapter 02's TOD-20: its middle and size
GROVE_GAP = 8.0  # metres between its trees
GROVE_CLEAR = 2.0  # off a pad, a path or the leat
FORECOURT = (-20.0, 258.0)  # the window stall faces it
NICHE_OUT = 1.1  # a Bön house's wheel niche's front this far out from its gate's line (its back against the yard wall's outside)
NICHE_BESIDE = 1.7  # and this far beside the gate, away from the house
RING = (6.0, 5.0, 2.0)  # R-24's paving: its middle line's half-sizes along the chapel's x and y (its walls at 4.5 and 3.5) and its width
CIRCUIT = [(-4.6, -4.05), (4.6, -4.05), (5.4, -3.25), (5.4, 3.6), (4.6, 4.4), (-4.6, 4.4), (-5.4, 3.6), (-5.4, -3.25)]  # the walkers'
# line in the chapel's frame, anticlockwise seen from above from the front's west end: 0.55 m off the front (the wheels' axes
# 0.2 m in from it, within world/kora_wheels.gd's REACH), 0.9 m off the sides and the back


def ground():
    site_ = Site.load()
    g = site_.read(SOURCE)
    return lambda x, y: float(g.z(np.asarray(x, float), np.asarray(y, float)) - site_.shift)


def frame(at, facing):
    """A kit's frame on the town grid: its +x and +y (its front, -y, faces `facing`)."""
    f = math.radians(facing)
    return (-math.cos(f), math.sin(f)), (-math.sin(f), -math.cos(f))


def kit_to_town(at, facing, k):
    X, Y = frame(at, facing)
    return (at[0] + k[0] * X[0] + k[1] * Y[0], at[1] + k[0] * X[1] + k[1] * Y[1])


def sidecar(kit):
    p = os.path.join(KIT, kit + ".json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None


def main():
    Z = ground()
    td = json.load(open(TODE, encoding="utf-8"))
    rng = random.Random(SEED)
    things = []
    named = td["named"]
    for nid, size in FLOORS.items():
        n = named[nid]
        things.append({"id": nid, "kit": "tod_threshing_floor_%d_v%d" % (size, 1 + rng.randrange(2)), "at": n["at"], "level": n["level"],
                       "facing": round(rng.uniform(0.0, 360.0), 1)})
    byres = racks = 0
    for h in sorted(td["houses"], key=lambda h: h["id"]):
        hk = h.get("kit")
        r_ = random.Random("%s:%d" % (h["id"], SEED))
        if h["type"] == "D" and r_.random() < BYRES:  # a byre in the yard's front corner on the gate's side
            sc = sidecar("%s_v%d" % (hk or "tode_rammed_house_d1", int(h.get("seed", 1))))
            if sc is None:
                continue
            gate = sc["socket_pos"].get("SOCK_GATE_1")
            ys = [q[1] for q in sc.get("ground", [])] + [q[3] for q in sc.get("ground", [])]
            if gate is None or not ys:
                continue
            sx = 1.0 if gate[0] > 0 else -1.0
            kx = gate[0] - sx * (0.5 + BYRE[0] / 2 + 0.2)
            ky = min(ys) + 0.5 + BYRE[1] / 2 + 0.2
            at = kit_to_town(h["pos"], h["rot_deg"], (kx, ky))
            things.append({"id": "TOD-22.%d" % (byres + 1), "kit": "tod22_byre_v%d" % (1 + r_.randrange(4)), "at": [round(at[0], 2), round(at[1], 2)],
                           "level": h["pos"][2], "facing": round((h["rot_deg"] + 180.0) % 360.0, 1), "house": h["id"]})
            byres += 1
        elif h["type"] in ("C", "A") and not h.get("ruin") and r_.random() < RACKS:  # a rack at a front corner of its pad
            px, py, pw, pd = h["pad"]
            f = math.radians(h["rot_deg"])
            ux, uy = math.sin(f), math.cos(f)  # its front's way
            side = r_.choice((-1.0, 1.0))
            ax, ay = -uy * side, ux * side
            at = (px + ux * (pd / 2 - 0.7) + ax * (pw / 2 - 2.0), py + uy * (pd / 2 - 0.7) + ay * (pw / 2 - 2.0))
            crop = "maize" if r_.random() < 0.7 else "turnip"
            things.append({"id": "TOD-24.%d" % (racks + 1), "kit": "tod24_rack_%s_v%d" % (crop, 1 + r_.randrange(3 if crop == "maize" else 2)),
                           "at": [round(at[0], 2), round(at[1], 2)], "level": h["pos"][2], "facing": round((h["rot_deg"] + 180.0) % 360.0, 1), "house": h["id"]})
            racks += 1
    # the walnut grove: its trees off the pads, the paths, the leat and the named places
    blocks = []  # (centre, half-sizes, its +y's way) rectangles grown GROVE_CLEAR
    for h in td["houses"]:
        px, py, pw, pd = h["pad"]
        blocks.append(((px, py), (pw / 2 + GROVE_CLEAR, pd / 2 + GROVE_CLEAR), h["rot_deg"]))
    for ln in td["lanes"]:
        fx, fy = ln["from"]
        dx, dy = ln["dir"]
        L = ln["length"]
        blocks.append(((fx + dx * L / 2, fy + dy * L / 2), (ln["width"] / 2 + GROVE_CLEAR, L / 2 + GROVE_CLEAR), math.degrees(math.atan2(dx, dy))))
    for nid, n in named.items():
        fw, fd = n.get("pad", [0, 0] + n["footprint"])[2:] if "pad" in n else n["footprint"]
        blocks.append(((n["at"][0], n["at"][1]), (fw / 2 + GROVE_CLEAR + 2.0, fd / 2 + GROVE_CLEAR + 2.0), 0.0))
    leat_pts = []
    if os.path.exists(LEAT):
        for st in json.load(open(LEAT, encoding="utf-8"))["leat"]:
            leat_pts += [(q[0], q[1]) for q in st["pts"]]

    def free(x, y):
        for (cx, cy), (hw, hd), f in blocks:
            th = math.radians(f)
            ux, uy = math.sin(th), math.cos(th)
            if abs((x - cx) * ux + (y - cy) * uy) < hd and abs(-(x - cx) * uy + (y - cy) * ux) < hw:
                return False
        return all(math.hypot(x - qx, y - qy) > GROVE_CLEAR + 1.0 for qx, qy in leat_pts)

    gx, gy, gw, gd = GROVE
    trees = []
    for _ in range(4000):
        x, y = rng.uniform(gx - gw / 2, gx + gw / 2), rng.uniform(gy - gd / 2, gy + gd / 2)
        if all(math.hypot(x - t[0], y - t[1]) >= GROVE_GAP for t in trees) and free(x, y):
            trees.append((x, y))
    for k, (x, y) in enumerate(trees):
        things.append({"id": "TOD-20.%d" % (k + 1), "kit": "tree_walnut_v%d" % (1 + k % 3), "at": [round(x, 2), round(y, 2)], "level": round(Z(x, y) - 0.15, 2),
                       "facing": round(rng.uniform(0.0, 360.0), 1)})
    niches = 0
    for h in sorted(td["houses"], key=lambda h: h["id"]):  # the Bön households' wheel niches by their gates
        if not h.get("bon"):
            continue
        sc = sidecar("%s_v%d" % (h.get("kit") or "tode_bon_house_d1", int(h.get("seed", 1))))
        gate = sc["socket_pos"].get("SOCK_GATE_1") if sc else None
        if gate is None:
            continue
        sx = 1.0 if gate[0] > 0 else -1.0
        at = kit_to_town(h["pos"], h["rot_deg"], (gate[0] + sx * NICHE_OUT, gate[1] - NICHE_BESIDE))
        X, _ = frame(h["pos"], h["rot_deg"])
        things.append({"id": "TOD-03.W%d" % (niches + 1), "kit": "tod03_wheel_niche_v1", "at": [round(at[0], 2), round(at[1], 2)], "level": h["pos"][2],
                       "facing": round(math.degrees(math.atan2(X[0] * sx, X[1] * sx)) % 360.0, 1), "house": h["id"]})
        niches += 1
    if "TOD-25" in named:  # the window stall, its window to the forecourt
        n = named["TOD-25"]
        f = math.degrees(math.atan2(FORECOURT[0] - n["at"][0], FORECOURT[1] - n["at"][1])) % 360.0
        things.append({"id": "TOD-25", "kit": "tod25_window_stall_v1", "at": n["at"], "level": n["level"], "facing": round(f, 1)})
    lanes, circuit = [], []
    if "TOD-02" in named:  # R-24 on the chapel's terrace
        n = named["TOD-02"]
        at, f, lv = n["at"], n["facing"], n["level"]
        X, Y = frame(at, f)
        rx, ry, rw = RING
        for k, (a, d, L) in enumerate((((-rx, -ry), X, 2 * rx), ((rx, -ry + 1.0), Y, 2 * ry - 2.0), ((-rx, ry), X, 2 * rx), ((-rx, -ry + 1.0), Y, 2 * ry - 2.0))):
            fa = kit_to_town(at, f, a)
            lanes.append({"id": "TOD-R24.%02d" % (k + 1), "from": [round(fa[0], 2), round(fa[1], 2)], "dir": [round(d[0], 4), round(d[1], 4)],
                          "length": round(L, 2), "width": rw, "z_a": lv, "z_b": lv, "flight": None, "profile": [[0.0, lv], [round(L, 2), lv]],
                          "street": True, "ring": "R-24"})
        circuit = [[round(q[0], 2), round(q[1], 2), lv] for q in (kit_to_town(at, f, c) for c in CIRCUIT)]
    json.dump({"about": "Tödé's fields' and yards' things (tools/town/tode_things.py; M3 sprint 4, steps 5 and 6): each {id, kit (../tibet-blender kit/tode.py's types, the gardens' walnut), at, level, facing (its front's bearing; the kit's -y)}: the threshing floors TOD-11 to 14 on their pads, the byres TOD-22.n in rammed-earth yards (`house`), the racks TOD-24.n at the front corners of house pads, the walnut grove's trees TOD-20.n, the window stall TOD-25. Placed by world/town.gd. `lanes`: R-24's paving round the Bön chapel TOD-02 on its terrace (street lanes, tools/terrain/pads.py); `circuit`: its walkers' line, anticlockwise from the front's west end ([x, y, level]). Regenerated with the terrain.",
               "things": things, "lanes": lanes, "circuit": circuit}, open(OUT, "w", encoding="utf-8"), indent=1)
    rep = ["# Tödé's fields' and yards' things", "",
           "_Written by `tools/town/tode_things.py` (M3 sprint 4, step 5) from `data/tode.json` and `data/tode_leat.json`._", "",
           "- The threshing floors TOD-11 to 14 on their pads: %s." % ", ".join("%s %d m at %.1f m" % (k, v, named[k]["level"]) for k, v in FLOORS.items()),
           "- %d byres in rammed-earth yards (of %d), %d racks at house pads' front corners, %d walnuts in the grove (%.0f by %.0f m at %.0f, %.0f)." % (
               byres, sum(1 for h in td["houses"] if h["type"] == "D"), racks, len(trees), GROVE[2], GROVE[3], GROVE[0], GROVE[1]),
           "- %d wheel niches by the Bön households' gates (TOD-03), their wheels turning anticlockwise." % niches,
           "- R-24, the Yungdrung circuit: %s." % (("%.0f m of paving round the Bön chapel on its terrace at %.1f m, its walkers' line %.0f m round, anticlockwise" % (
               sum(l["length"] for l in lanes), named["TOD-02"]["level"], sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(circuit, circuit[1:] + circuit[:1])))) if lanes else "not laid (no TOD-02)"),
           "- The window stall TOD-25 %s." % (("at (%.1f, %.1f), %.1f m, facing %.0f" % (named["TOD-25"]["at"][0], named["TOD-25"]["at"][1], named["TOD-25"]["level"], [t for t in things if t["id"] == "TOD-25"][0]["facing"])) if "TOD-25" in named else "not placed (no TOD-25 in data/tode.json)")]
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("tode_things: 4 threshing floors, %d byres, %d racks, %d walnuts, %d Bön wheel niches%s -> %s" % (byres, racks, len(trees), niches, ", the window stall" if "TOD-25" in named else "", OUT))


if __name__ == "__main__":
    main()
