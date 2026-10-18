#!/usr/bin/env python3
"""Tsongra's market on the market day (M2 sprint 10, step 4; plan chapter 05, 8.2 and 7.2; chapter 02, SHL-01 and SHL-29):
the stalls of the two markets on the square's two levels, each its keeper and its goods, set up for the morning and
packed at noon.

Chapter 05, 8.2: at 10:30 Tsongra holds 60 people on its 1,200 m², "stalls with two or three people each, a ring round
the mani-pa, children underfoot"; 7.2: both markets open at 08:00 and pack up at solar noon, 11:43; chapter 02: most
stalls are kept by women, the fuel stalls SHL-29 by women from the hamlets on the lower level. The stalls stand where
the square is level (the pads' two levels, tools/terrain/pads.py LEVELS), clear of the houses, the flagpole, the basin,
the talkers' steps and Tsongra's own, the fuel stalls, and of the walkers' main ways across it (the street graph's
routes), near the square's edges and facing into it; a ground stall (the kit's SH-03, a cloth with its umbrella) or a
trestle (SH-04, under its awning), a few metres apart. Their keepers are of the day's drawn (data/roster.json): the
hamlets' women on the lower level, Shöl's on the upper, the nomad women with their butter; their goods by level.
The stalls stay where they were first planned (the walkers' ways go round them since), each while its ground stays level
and clear; `--replan` plans them afresh. Their keepers are drawn again with each day's draw.
Run: tools/py tools/town/market.py [--replan]   Writes data/market.json and docs/town/market-report.md
(tools/terrain/build.sh runs it after the day's draw, before the street graph, whose walkers keep the stalls and buy at
them).
"""
import json
import math
import os
import random
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
from terrain_site import Site  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
OUT = os.path.join(ROOT, "data", "market.json")
REPORT = os.path.join(ROOT, "docs", "town", "market-report.md")
SEED = 1903
LEVELS = {"upper": (0.0, 7.5, 40.0, 15.0, 2662.0), "lower": (0.0, -7.5, 40.0, 15.0, 2660.0)}  # tools/terrain/pads.py LEVELS
HOURS = (7.6, 12.1)  # set up from 07:36, packed by 12:06 (the market opens at 08:00 and packs up at solar noon, 11:43)
KEEPS = (7.75, 11.75)  # the keepers at their stalls
STALLS = {"upper": 7, "lower": 6}  # besides the three fuel stalls (60 people at 10:30: two or three at each)
GAP = 3.3  # metres between two stalls' middles
EDGE = 1.4  # metres kept from a level's edge (its wall, its parapet, its drop)
BUSY = 4  # a way across the square as busy as this many routes within CLEAR keeps a stall off it
CLEAR = 1.3
KEEP_OFF = [  # (x0, y0, x1, y1): the talkers' steps, Tsongra's own steps, the basin, the flagpole, the fuel stalls (SHL-29) with
    # their buyers' side before them (where the stalls route walks: tools/player/s15.sh route stalls)
    (-10.6, 7.0, 10.6, 15.5), (-6.8, -4.6, 6.8, 0.8), (10.0, 6.3, 14.0, 9.3), (-9.5, 3.5, -6.5, 6.5), (-21.0, -15.5, -9.0, -8.2)]
GOODS = {"upper": ["butter, patted into cakes", "dried cheese and curds", "salt from the north", "brick tea, broken and weighed", "cloth and thread",
                   "needles, beads and coral", "felt boots and hats"],
         "lower": ["barley and tsampa", "turnips and radishes", "wooden bowls", "copper pots and ladles", "knives and flints", "dried meat"]}


def main():
    rnd = random.Random(SEED)
    site = Site.load()
    g = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    Z = lambda x, y: float(g.z(x, y) - site.shift)  # noqa: E731
    import graph as GR  # (the street graph's obstacles: every building's footprint and what stands by it)
    feet, _records, _town = GR.load(market=False)  # (not the stalls themselves)
    sg = json.load(open(os.path.join(GEN, "street_graph.json"), encoding="utf-8")) if os.path.exists(os.path.join(GEN, "street_graph.json")) else {"routes": {}}
    busy = {}
    for name, r in sg["routes"].items():  # the ways across the square: how many routes pass near each half metre
        p = r["p"]
        seen = set()
        for i in range(0, len(p) - 3, 3):
            x0, y0, x1, y1 = p[i], p[i + 1], p[i + 3], p[i + 4]
            n = max(1, int(math.hypot(x1 - x0, y1 - y0) / 0.5))
            for k in range(n + 1):
                x, y = x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n
                if -21.0 <= x <= 21.0 and -16.0 <= y <= 16.0:
                    seen.add((round(x * 2), round(y * 2)))
        for c in seen:
            busy[c] = busy.get(c, 0) + 1

    def inside(poly, x, y):
        c = False
        for i in range(len(poly)):
            (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % len(poly)]
            if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
                c = not c
        return c

    def near_feet(x, y, r=1.6):
        return any(inside(f, x + dx, y + dy) for f in feet for dx, dy in ((0, 0), (r, 0), (-r, 0), (0, r), (0, -r)))

    def traffic(x, y):
        return sum(v for (cx, cy), v in busy.items() if math.hypot(cx / 2.0 - x, cy / 2.0 - y) <= CLEAR) / max(1.0, (CLEAR * 2) ** 2)

    stalls = []
    if os.path.exists(OUT) and "--replan" not in sys.argv:  # where they stood (the walkers' ways go round them since),
        # each kept while its ground is still level and clear of the houses
        for s in json.load(open(OUT, encoding="utf-8"))["stalls"]:
            x, y, z = s["pos"]
            clear = not any(x0 - 1.4 <= x <= x1 + 1.4 and y0 - 1.4 <= y <= y1 + 1.4 for x0, y0, x1, y1 in KEEP_OFF)
            if clear and all(abs(Z(x + dx, y + dy) - z) <= 0.08 for dx in (-1.2, 0.0, 1.2) for dy in (-1.2, 0.0, 1.2)) and not near_feet(x, y):
                stalls.append(dict(s, keeper=None))
    for level, (cx, cy, w, d, z) in LEVELS.items():
        if sum(1 for s_ in stalls if s_["level"] == level) >= STALLS[level]:
            continue
        cands = []
        for x in np.arange(cx - w / 2 + EDGE, cx + w / 2 - EDGE + 0.01, 0.5):
            for y in np.arange(cy - d / 2 + EDGE, cy + d / 2 - EDGE + 0.01, 0.5):
                if any(x0 - 1.4 <= x <= x1 + 1.4 and y0 - 1.4 <= y <= y1 + 1.4 for x0, y0, x1, y1 in KEEP_OFF):
                    continue  # (a stall's own ground reaches 1.4 m from its middle)
                if any(abs(Z(x + dx, y + dy) - z) > 0.08 for dx in (-1.2, 0.0, 1.2) for dy in (-1.2, 0.0, 1.2)):
                    continue  # level all round it
                if near_feet(x, y):
                    continue
                t = traffic(x, y)
                if t * (CLEAR * 2) ** 2 >= BUSY:
                    continue
                edge = max(abs(x - cx) / (w / 2), abs(y - cy) / (d / 2))  # 1 at the level's edge
                cands.append((edge - 0.02 * t + rnd.uniform(0.0, 0.05), x, y))
        cands.sort(reverse=True)
        picked = []
        for _, x, y in cands:
            if len(picked) + sum(1 for s_ in stalls if s_["level"] == level) >= STALLS[level]:
                break
            if all(math.hypot(x - px, y - py) >= GAP for px, py in picked) and all(math.hypot(x - s["pos"][0], y - s["pos"][1]) >= GAP for s in stalls):
                picked.append((x, y))
        for k, (x, y) in enumerate(picked):
            face = math.degrees(math.atan2(cx - x, (cy - y) * 0.6)) % 360.0  # its front to the square's middle
            kind = "stall_sh03" if (level == "upper" and k % 3 != 2) or (level == "lower" and k % 3 == 0) else "stall_sh04"
            n_id = max([int(s_["id"][4:]) for s_ in stalls] + [0]) + 1  # (after the kept stalls' numbers, never one of theirs)
            stalls.append({"id": "MKT-%02d" % n_id, "level": level, "kit": kind, "seed": 1 + rnd.randrange(5),
                           "pos": [round(float(x), 2), round(float(y), 2), z], "facing": round(face, 1),
                           "goods": GOODS[level][k % len(GOODS[level])], "keeper": None})
    # their keepers, of the day's drawn: the nomad women to the butter, the hamlets' women below, Shöl's above
    roster = json.load(open(os.path.join(ROOT, "data", "roster.json"), encoding="utf-8"))["people"] if os.path.exists(os.path.join(ROOT, "data", "roster.json")) else []
    free = [p for p in roster if p.get("day") == "shol" and "walker" not in p and "named" not in p and p["sex"] == "f" and 15 <= int(p["age"]) <= 65]
    random.Random(SEED + 1).shuffle(free)  # a stream of their own: who keeps a stall hangs on the day's draw alone, not on
    # how many stalls this run planned afresh (10 Oct 2026: a build that kept all thirteen drew three other keepers)
    pools = {"nomad": [p for p in free if p["role"] == "NW"], "hamlet": [p for p in free if p["community"] == "hamlets" and p["role"] == "TW"],
             "shol": [p for p in free if p["community"] == "shol" and p["role"] == "TW"]}
    for s in stalls:
        want = ["nomad", "shol", "hamlet"] if s["goods"].startswith("butter") else (["hamlet", "shol"] if s["level"] == "lower" else ["shol", "hamlet"])
        for w in want:
            if pools[w]:
                s["keeper"] = pools[w].pop()["who"]
                break
    data = {"about": "Tsongra's market on the market day (M2 sprint 10, step 4), written by tools/town/market.py: `stalls`, each its id, level, kit type and seed (the kit's SH-03 ground stall or SH-04 trestle), place on the town grid, facing (its front, its customers' side), goods and keeper (one of the day's drawn, data/roster.json); `hours`, set up and packed (game hours); `keeps`, the keepers at their stalls. Placed by world/market.gd, walked by tools/town/graph.py. Regenerated with the town.",
            "hours": list(HOURS), "keeps": list(KEEPS), "stalls": stalls}
    json.dump(data, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    rep = ["# Tsongra's market", "", "_Written by `tools/town/market.py` (M2 sprint 10, step 4; plan chapter 05, 8.2 and 7.2): the market day's stalls on Tsongra's two levels, their keepers and goods. Regenerated with the town._", "",
           "%d stalls besides the three fuel stalls (SHL-29), set up %02d:%02d, packed by %02d:%02d; %d kept by the day's drawn." % (
               len(stalls), int(HOURS[0]), int(HOURS[0] % 1 * 60), int(HOURS[1]), int(HOURS[1] % 1 * 60), sum(1 for s in stalls if s["keeper"])), "",
           "| Stall | Level | Kit | x, y | Facing | Goods | Keeper |", "|---|---|---|---|---|---|---|"]
    rep += ["| %s | %s | %s_v%d | %.1f, %.1f | %03.0f | %s | %s |" % (s["id"], s["level"], s["kit"], s["seed"], s["pos"][0], s["pos"][1], s["facing"], s["goods"], s["keeper"] or "-") for s in stalls]
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join(rep) + "\n")
    print("market: %d stalls (%d above, %d below), %d with keepers -> %s" % (len(stalls), sum(1 for s in stalls if s["level"] == "upper"),
                                                                          sum(1 for s in stalls if s["level"] == "lower"), sum(1 for s in stalls if s["keeper"]), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
