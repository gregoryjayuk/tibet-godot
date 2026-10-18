#!/usr/bin/env python3
"""A way onto every roof (IMP-026; ISS-114: the notched logs up to the roofs went from 12 to 1 with the yards of IMP-023):
chapter 03, 3.8, "the downhill house's roof is the uphill house's yard", and chapter 02's second street over the roofs.
From the roofs already reached (the Rooftop Way's, the logs of tools/town/ladders.py, the bridges' of
tools/town/bridges.py), the cheapest join of rooftop.py's onto every other roof that the town can reach: from the ground,
over the parapet where the ground stands at the roof, roof-terrace steps, a plank from an upper yard or a lane across
the gap (the yard's parapet opened where it crosses: rooftop.py's gap_parapets), a notched log or a stair-ladder from a
yard, a lane or a lower roof; or from a roof already reached, over its neighbour's parapet, by steps, a plank or a log
(deck_joins); where none reaches a roof, a tall ladder up its wall (bridges.py's wall_ladder), dear, so that a run of
roofs joined to each other takes one. No piece ends within 1.8 m of a door, and a ladder from the ground has a level
run-up of 1.6 m behind its foot, a walker's width. Cheapest first, a roof at a time (Dijkstra over the roofs), so a roof comes by its neighbour where that is
the easy way. A ground end must reach a walkers' route of tools/town/graph.py by the ground's walk (bridges.py's
`reaches`), and none stands on the Sky Stair's flights.
Into assets/generated/terrain/roof_ways.json for world/town.gd (placed as the Way's pieces) and
docs/town/roof-ways-report.md.
Run: tools/py tools/town/roof_ways.py   (tools/terrain/build.sh runs it after bridges.py, before export_walls.py)
"""
import heapq
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
from terrain_site import Site  # noqa: E402
import bridges as BR  # noqa: E402  (reaches, town_cells, inside, wall_ladder)
import ladders as LD  # noqa: E402  (kit_file)
import rooftop as R  # noqa: E402  (load, Ground, ground_joins, deck_joins, gap_parapets)

GEN = R.GEN
OUT = os.path.join(GEN, "roof_ways.json")
REPORT = os.path.join(ROOT, "docs", "town", "roof-ways-report.md")
BOX = (-170.0, -100.0, 100.0, 290.0)  # the town grid round Shöl, Tsongra and Dechen-tsang: x0, y0, x1, y1
NEAR = 30.0  # roofs this near one another are tried for a join between them
DOOR_CLEAR = 1.8  # no piece's end within this of a door
WALL_MIN = 3  # roofs a tall ladder up a wall must open, its own and those reached on from it
WALL_COST = 20.0  # a tall ladder up a wall (bridges.py's wall_ladder): only where nothing else reaches a roof or its
# neighbours, so a run of roofs joined to each other takes one


def doors():
    """Every house door's place in the town grid (x, y): the builder's houses and the gazetteer's named ones, from
    their kit types' sidecars (SOCK_DOOR_n), placed as rooftop.py places their decks."""
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    houses = json.load(open(os.path.join(ROOT, "data", "town_generic.json"), encoding="utf-8"))["houses"]
    records = [(h, LD.kit_file(h)) for h in houses]
    named = {"B": "town_house_b2_v1", "B, large": "town_house_b3_v1", "B, workshop": "town_house_b1_v1"}
    own = {"SHL-19": "headman_house_v1", "SHL-21": "workshop_turner_v1", "SHL-22": "workshop_saddler_v1",
           "SHL-25": "workshop_tailor_v1", "SHL-08": "mani_lhakhang_v1", "SHL-04": "trading_house_v1"}
    for b in town["buildings"]:
        if b.get("pos") and b["pos"][2] is not None and (b["id"] in own or b.get("type") in named):
            records.append((b, own.get(b["id"]) or named[b["type"]]))
    out = []
    for h, f in records:
        path = os.path.join(R.KIT, f + ".json")
        if not os.path.exists(path):
            continue
        sp = json.load(open(path)).get("socket_pos", {})
        x, y = h["pos"][0], h["pos"][1]
        th = math.radians(h.get("rot_deg", 180.0) - 180.0)
        c, s_ = math.cos(th), math.sin(th)
        for k, (u, v, _) in sp.items():
            if k.startswith("SOCK_DOOR"):
                out.append((x + u * c + v * s_, y - u * s_ + v * c))
    return out


def _chain(how, i, decks):
    """The roofs from roof i back to where it was reached from: [i, its parent, ...]."""
    ids = {d.id: k for k, d in enumerate(decks)}
    out = [i]
    while i in how and how[i][0] in ids and len(out) < 200:
        i = ids[how[i][0]]
        out.append(i)
    return out


def ends(piece):
    """A piece's ends on the ground or a roof, (x, y) each."""
    return [tuple(piece[k][:2]) for k in ("foot", "top", "from", "to", "pos") if k in piece and isinstance(piece[k], list)]


def main():
    site = Site.load()
    padded = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    terrain = lambda x, y: padded.z(x, y) - site.shift
    decks, feet = R.load()
    decks = [d for d in decks if BOX[0] < d.cx < BOX[2] and BOX[1] < d.cy < BOX[3]]
    idx = {d.id: i for i, d in enumerate(decks)}
    lanes = json.load(open(os.path.join(ROOT, "data", "town_lanes.json"), encoding="utf-8"))["lanes"]
    ground = R.Ground(terrain, feet, *BOX, lambda X, Y: np.ones(np.shape(X), dtype=bool), lanes,
                      raster=(padded.x0, padded.y1, padded.res))
    goal = BR.town_cells(ground)
    reach_cache = {}

    def reaches(c):
        if c is None:
            return False
        if c not in reach_cache:
            reach_cache[c] = BR.reaches(ground, c, goal)
        return reach_cache[c]

    # the roofs already reached, and how
    had = {}
    way = json.load(open(os.path.join(GEN, "rooftop.json")))
    for leg in way["legs"]:
        if leg.get("on") in idx:
            had[idx[leg["on"]]] = "the Rooftop Way"
    for name, how in (("ladders.json", "a notched log (ladders.py)"), ("bridges.json", "a bridge's way (bridges.py)")):
        path = os.path.join(GEN, name)
        if not os.path.exists(path):
            continue
        data = json.load(open(path))
        for pc in data.get("ladders", []) + data.get("pieces", []):
            t = pc.get("top") or pc.get("from")
            if not t:
                continue
            for i, d in enumerate(decks):
                if BR.inside(d, t[0], t[1]) or (pc.get("deck") == d.id):
                    had[i] = how

    door_at = doors()

    def by_door(piece):
        return piece is not None and any(math.hypot(e[0] - dx, e[1] - dy) < DOOR_CLEAR for e in ends(piece) for dx, dy in door_at)

    def run_up(piece):
        """Whether a ladder from the ground has level ground behind its foot to be walked into it on its axis: 1.6 m
        back, a walker's width either side (in a shallow yard the walker had stood on its parapet)."""
        if piece is None or piece.get("kind") not in ("log", "stair", "wall") or piece.get("lane"):
            return True
        b = math.radians(float(piece["bearing"]))
        ax, ay = math.sin(b), math.cos(b)
        fx, fy, fz = piece["foot"]
        for back in (0.8, 1.2, 1.6):
            for lat in (-0.35, 0.0, 0.35):
                x, y = fx - ax * back - ay * lat, fy - ay * back + ax * lat
                g = ground.height(x, y)
                if g is None or abs(g - fz) > 0.3:
                    return False
        return True

    # every roof's joins from the town's ground (the reachable ones), and between roofs near each other
    from_ground = {}
    for i, d in enumerate(decks):
        best = None
        for land, gc, cost, piece, kind in R.ground_joins(i, d, ground):
            if by_door(piece) or not run_up(piece):
                continue
            if kind == "log" and piece is not None and piece.get("lane"):  # down from a lane: its top is the ground end
                end = piece["top"]
            else:
                end = piece.get("foot", piece.get("pos", piece.get("to"))) if piece else None
            cell = ground.cell(end[0], end[1]) if end else gc
            if best is not None and cost >= best[0]:
                continue
            if not reaches(cell):
                continue
            best = (cost, kind, piece)
        if best is None and i not in had:  # a tall ladder up its wall, the last way (dear: one to a run of roofs)
            wl = BR.wall_ladder(d, ground, goal, (0.0, 0.0))
            if wl is not None and not by_door(wl) and run_up(wl):
                best = (WALL_COST + wl["top"][2] - wl["foot"][2], "wall", wl)
        if best is not None:
            from_ground[i] = best
    between = {}
    bpath = os.path.join(GEN, "bridges.json")
    for br in (json.load(open(bpath))["bridges"] if os.path.exists(bpath) else []):  # a bridge joins its two roofs
        e0, e1 = br["ends"]
        if e0 in idx and e1 in idx:
            between[(idx[e0], idx[e1])] = (2.0, "bridge", None)
            between[(idx[e1], idx[e0])] = (2.0, "bridge", None)
    for i, a in enumerate(decks):
        for j, b in enumerate(decks):
            if i == j or math.hypot(a.cx - b.cx, a.cy - b.cy) > NEAR:
                continue
            for ca, cb, cost, piece, kind in R.deck_joins(a, b):
                if by_door(piece):
                    continue
                if (i, j) not in between or cost < between[(i, j)][0]:
                    between[(i, j)] = (cost, kind, piece)

    # cheapest first, outwards from the ground and the roofs already reached; a ladder up a wall that opens fewer than
    # WALL_MIN roofs (its own and those reached on from it) is left out and the search run again
    def search(cands):
        dist, how = {}, {}
        pq = []
        for i in had:
            dist[i] = 0.0
            how[i] = (had[i], None, None)
            heapq.heappush(pq, (0.0, i))
        for i, (cost, kind, piece) in cands.items():
            if cost < dist.get(i, 1e18):
                dist[i] = cost
                how[i] = ("ground", kind, piece)
                heapq.heappush(pq, (cost, i))
        while pq:
            c, i = heapq.heappop(pq)
            if c > dist.get(i, 1e18):
                continue
            for (a, b), (cost, kind, piece) in between.items():
                if a == i and c + cost < dist.get(b, 1e18):
                    dist[b] = c + cost
                    how[b] = (decks[i].id, kind, piece)
                    heapq.heappush(pq, (c + cost, b))
        return how

    for _ in range(4):
        how = search(from_ground)
        under = {i: 1 for i in how}  # each roof and the roofs reached on from it
        for i in sorted(how, key=lambda i: -len(_chain(how, i, decks))):
            for j in _chain(how, i, decks)[1:]:
                under[j] += 1
        weak = [i for i, h in how.items() if h[0] == "ground" and h[1] == "wall" and under[i] < WALL_MIN]
        if not weak:
            break
        for i in weak:
            del from_ground[i]
    pieces = []
    rows = []
    kinds = {}
    for i, d in enumerate(decks):
        if i in had:
            kinds["already"] = kinds.get("already", 0) + 1
            continue
        if i not in how:
            kinds["none"] = kinds.get("none", 0) + 1
            rows.append((d.id, "none", ""))
            continue
        frm, kind, piece = how[i]
        kinds[kind] = kinds.get(kind, 0) + 1
        rows.append((d.id, kind, frm))
        if piece is not None:
            pc = dict(piece, deck=d.id)
            if frm == "ground" and kind in ("log", "stair", "wall"):
                pc["from"] = "ground"  # drawn up at night with the town's (world/dusk.gd)
            pieces.append(pc)
    R.gap_parapets(pieces)
    json.dump({"about": "A way onto every roof, from tools/town/roof_ways.py (IMP-026): the pieces world/town.gd places as the Rooftop Way's (log, stair, steps, plank), each with the roof it leads onto (`deck`); a log or stair-ladder from the ground `from` it, drawn up at night (world/dusk.gd).",
               "pieces": pieces}, open(OUT, "w"), indent=1)
    reached = len(decks) - kinds.get("none", 0)
    with open(REPORT, "w") as f:
        f.write("# A way onto every roof (IMP-026)\n\n_Written by `tools/town/roof_ways.py`: chapter 03, 3.8, \"the downhill house's roof is the uphill house's yard\"._\n\n")
        f.write("%d of %d roofs reached: %d already (the Rooftop Way, the logs, the bridge), %s.\n\n" % (
            reached, len(decks), kinds.get("already", 0), ", ".join("%d by %s" % (v, k) for k, v in sorted(kinds.items()) if k not in ("already", "none"))))
        f.write("| Roof | By | From |\n|---|---|---|\n")
        for r in rows:
            f.write("| %s | %s | %s |\n" % r)
    print("roof_ways: %d of %d roofs reached (%s), %d pieces -> %s" % (reached, len(decks), kinds, len(pieces), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
