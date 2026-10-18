#!/usr/bin/env python3
"""A plank-and-rope bridge over the Sky Stair (IMP-023 (3), after Greg's 1773, 7 Oct 2026: "a cool view behind the player
as they run across an old bridge joining 2 parts of town (or just buildings)"): from H-SHL-061's roof on the stair's west
side to H-SHL-080's on its east, 22 m long and 4 m and more over the pilgrims' heads, joining upper Shöl's two halves,
which otherwise meet only on the stair; the one span over the stair with a clear line between two roofs at one level.
Its line is found, not drawn: the middle of the run of level lines out from the one roof's facing side that reach the
other's outline with nothing standing within 2.6 m under them and a free deck to land on at both ends. Each end rests
0.35 m in from its roof's outline, on its parapet; the deck sags a thirtieth of its span between them.
A way onto each roof from the town: the Rooftop Way's, or the cheapest of rooftop.py's ground joins (over the parapet
from ground at the roof, roof-terrace steps, a plank to a lane, a notched log, a stair-ladder) whose ground end reaches a
walkers' route of tools/town/graph.py within the ground's walk (cell to cell, no steeper than rooftop.py's SLOPE_MAX); or,
where none climbs onto a roof (080's is 8.4 m over its yard, the hillside behind it 35 degrees), a tall ladder up its
wall from its yard, as at the far end of 1773's bridge (`wall_ladder`: the kit's wall_ladder_80/90/100 at 72-78 degrees).
Into assets/generated/terrain/bridges.json for world/town.gd (the bridges, and the pieces as the Rooftop Way's) and
../tibet-blender/export_bridges.py (each bridge's kit export, assets/generated/kit/bridges/), and
docs/town/bridges-report.md.
Run: tools/py tools/town/bridges.py   (tools/terrain/build.sh runs it after rooftop.py)
"""
import json
import math
import os
import sys
from collections import deque

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
from terrain_site import Site  # noqa: E402
import rooftop as R  # noqa: E402

GEN = R.GEN
OUT = os.path.join(GEN, "bridges.json")
REPORT = os.path.join(ROOT, "docs", "town", "bridges-report.md")
GRAPH = os.path.join(GEN, "street_graph.json")
SPANS = [("BR-01", "H-SHL-061.0", "H-SHL-080.0", "middle", "over the Sky Stair, upper Shöl's west half to its east")]
WALL_LEAN = 75.0  # the kit's wall ladder, as built
WALL_LADDERS = [(8.0, "wall_ladder_80_v1"), (9.0, "wall_ladder_90_v1"), (10.0, "wall_ladder_100_v1")]
SAG = 1.0 / 30.0  # of the span
REST = 0.35  # each end this far in from its roof's outline, on the parapet
WIDTH = 1.0
CLEAR = 2.6  # nothing standing within this under the line
BOX = 40.0  # the ground read this far round the bridge
REACH_CELLS = 20000  # how far a join's ground is walked looking for the town


def inside(d, x, y):
    u, v = d.local(x, y)
    return d.u0 <= u <= d.u1 and d.v0 <= v <= d.v1


def line(a, b, decks, pick="middle"):
    """The bridge's line from deck a to deck b: (side, t, (x, y) on a's outline, (x, y) on b's, the outward unit); of the
    clear ones that land on a free cell of each deck (rooftop.py's LAND in from its outline), the middle one of the run
    or the longest."""
    best = None
    for side in ("+u", "-u", "+v", "-v"):
        _, _, (t0, t1), _ = R.side_frame(a, side)
        hits = []
        for t in np.arange(t0 + 0.4, t1 - 0.4 + 1e-6, 0.1):
            (px, py), (ox, oy) = R.on_side(a, side, t, 0.0)
            for k in range(1, 81):
                s = k * 0.5
                if inside(b, px + ox * s, py + oy * s):
                    lo, hi = s - 0.5, s
                    for _ in range(14):
                        m = (lo + hi) / 2.0
                        if inside(b, px + ox * m, py + oy * m):
                            hi = m
                        else:
                            lo = m
                    z = (a.top() + b.top()) / 2.0
                    clear = all(not (inside(d, px + ox * q, py + oy * q) and d.top() > z - CLEAR)
                                for q in np.arange(0.5, hi - 0.4, 0.25) for d in decks if d is not a and d is not b)
                    lands = a.cell_at(*a.local(px - ox * R.LAND, py - oy * R.LAND)) is not None and \
                        b.cell_at(*b.local(px + ox * (hi + R.LAND), py + oy * (hi + R.LAND))) is not None
                    if clear and lands:
                        hits.append((t, hi, (px, py), (px + ox * hi, py + oy * hi), (ox, oy)))
                    break
        if hits and (best is None or len(hits) > len(best[1])):
            best = (side, hits)
    if best is None:
        return None
    side, hits = best
    t, _, pa, pb, o = max(hits, key=lambda h: h[1]) if pick == "longest" else hits[len(hits) // 2]
    return side, t, pa, pb, o


_WALLS = None


def wall_pts():
    """Every wall's line (tools/town/walls.py, of any height), a point every 0.2 m: [x, y, top] (a parapet is opened where
    a plank crosses it: rooftop.py's gap_parapets)."""
    global _WALLS
    if _WALLS is None:
        pts = []
        path = os.path.join(GEN, "walls.json")
        for r in (json.load(open(path))["runs"] if os.path.exists(path) else []):
            fl = r.get("flags", [0] * len(r["pts"]))
            for k_, (a, b) in enumerate(zip(r["pts"][:-1], r["pts"][1:])):
                para = 0.0
                n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1]) / 0.2))
                for k in range(n + 1):
                    q = k / n
                    pts.append([a[0] + (b[0] - a[0]) * q, a[1] + (b[1] - a[1]) * q, a[5] + (b[5] - a[5]) * q + para])
        _WALLS = np.array(pts) if pts else np.zeros((0, 3))
    return _WALLS


def plank_clear(a, b):
    """Whether a plank from a (x, y, z) to b, with the kit's 0.3 m over each end, passes over every wall it crosses with
    room for the feet (rooftop.py's clears_walls reads the walls' points as they come, a metre or more apart); a yard's
    parapet in its way is opened (gap_parapets), as roof_ways.py's planks open theirs."""
    w = wall_pts()
    if not len(w):
        return True
    dx, dy = b[0] - a[0], b[1] - a[1]
    L = max(math.hypot(dx, dy), 1e-6)
    t = ((w[:, 0] - a[0]) * dx + (w[:, 1] - a[1]) * dy) / (L * L)
    over = 0.3 / L
    near = (t > -over) & (t < 1.0 + over) & (np.hypot(a[0] + dx * t - w[:, 0], a[1] + dy * t - w[:, 1]) < 0.7)
    return bool(np.all(a[2] + (b[2] - a[2]) * np.clip(t[near], 0.0, 1.0) >= w[near, 2] - 0.05))


def town_cells(ground):
    """The ground cells a walkers' route passes (tools/town/graph.py): the town as its people walk it."""
    out = set()
    if not os.path.exists(GRAPH):
        return out
    for r in json.load(open(GRAPH))["routes"].values():
        p = r["p"]  # x, y, z flat
        for k in range(0, len(p) - 2, 3):
            c = ground.cell(p[k], p[k + 1])
            if c:
                out.add(c)
    return out


def reaches(ground, start, goal):
    """Whether the ground's walk (cell to cell, no steeper than rooftop's SLOPE_MAX) leads from start to a goal cell."""
    if start in goal:
        return True
    seen, q = {start}, deque([start])
    nbr = [(0, 1, 1.0), (1, 0, 1.0), (0, -1, 1.0), (-1, 0, 1.0), (1, 1, 1.414), (1, -1, 1.414), (-1, 1, 1.414), (-1, -1, 1.414)]
    while q and len(seen) < REACH_CELLS:
        i, j = q.popleft()
        for di, dj, w in nbr:
            n = (i + di, j + dj)
            if n in seen or not (0 <= n[0] < ground.ny and 0 <= n[1] < ground.nx) or not ground.ok[n]:
                continue
            if abs(ground.z[n] - ground.z[i, j]) > R.SLOPE_MAX * w * R.CELL:
                continue
            if n in goal:
                return True
            seen.add(n)
            q.append(n)
    return False


def wall_ladder(d, ground, goal, away):
    """Where no join climbs onto deck d from the town, a tall ladder up its wall from level ground that reaches the town,
    off the bridge's side, its top on the parapet over a free cell of the roof: the piece, as the Way's ladders, or
    None. Of those found, the nearest the middle of its side at the kit's own lean."""
    top = d.top()
    best = None
    for side in ("+u", "-u", "+v", "-v"):
        (nu, nv), axis, (t0, t1), edge = R.side_frame(d, side)
        for t in np.arange(t0 + 0.5, t1 - 0.5 + 1e-6, 0.5):
            (ex, ey), (ox, oy) = R.on_side(d, side, t, 0.0)
            if ox * away[0] + oy * away[1] > 0.3:
                continue
            u, v = (edge - nu * R.LAND, t) if axis == "v" else (t, edge - nv * R.LAND)
            if d.cell_at(u, v) is None:
                continue
            for lean in (WALL_LEAN, 72.0, 78.0):
                tl = math.tan(math.radians(lean))
                for length, kit in WALL_LADDERS:
                    hi = length * math.sin(math.radians(lean)) - 0.2
                    for guess in np.arange(4.0, hi + 0.01, 0.25):
                        g = ground.level(ex + ox * guess / tl, ey + oy * guess / tl, 0.2)
                        if g is None or abs(top - g - guess) > 0.15:
                            continue
                        rise = top - g
                        if rise > hi:
                            continue
                        fx, fy = ex + ox * rise / tl, ey + oy * rise / tl
                        g2 = ground.level(fx, fy, 0.2)
                        if g2 is None or abs(g2 - g) > 0.15 or not all((ground.raw(ex + ox * rise / tl * q, ey + oy * rise / tl * q) or -1e9) < g + rise * (1 - q) - 0.2 for q in (0.3, 0.6)):
                            continue
                        if not reaches(ground, ground.cell(fx, fy), goal):
                            continue
                        # a level run-up behind its foot, 1.6 m and a walker's width (in a shallow yard the walker had
                        # stood on the yard's parapet and never reached it)
                        if not all(abs((ground.height(fx + ox * bk - oy * lt, fy + oy * bk + ox * lt) or -1e9) - g) <= 0.3
                                   for bk in (0.8, 1.2, 1.6) for lt in (-0.35, 0.0, 0.35)):  # out from the foot, away from the wall
                            continue
                        score = abs(lean - WALL_LEAN) / 3.0 + abs(t - (t0 + t1) / 2) + length / 10.0
                        if best is None or score < best[0]:
                            best = (score, {"kind": "wall", "file": kit, "foot": [round(fx, 2), round(fy, 2), round(g, 2)],
                                            "top": [round(ex, 2), round(ey, 2), round(top, 2)], "bearing": round(R.bearing(-ox, -oy), 1),
                                            "lean": lean, "deck": d.id})
                        break
                    if best is not None and best[1]["file"] == kit:
                        break
    return best[1] if best else None


def record(bid, A, za, B, zb, o, ends, drops, terrain, words):
    length = math.hypot(B[0] - A[0], B[1] - A[1])
    sag = round(length * SAG, 2)
    under = min(za + (zb - za) * q - 4.0 * sag * q * (1.0 - q) - float(terrain(A[0] + (B[0] - A[0]) * q, A[1] + (B[1] - A[1]) * q))
                for q in np.linspace(0.05, 0.95, 37))
    print("bridges: %s %s -> %s: %.1f m, rise %.2f, sag %.2f, at least %.1f m over the ground" % (bid, ends[0], ends[1], length, zb - za, sag, under))
    return {"id": bid, "file": "rope_bridge_%s" % bid.lower().replace("-", ""), "a": [round(A[0], 2), round(A[1], 2), round(za, 2)],
            "b": [round(B[0], 2), round(B[1], 2), round(zb, 2)], "dir": [round(o[0], 4), round(o[1], 4)], "length": round(length, 2),
            "rise": round(zb - za, 2), "sag": sag, "width": WIDTH, "rest": REST, "ends": list(ends), "drops": [round(x, 2) for x in drops],
            "under": round(under, 2), "words": words}


def main():
    site = Site.load()
    padded = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    terrain = lambda x, y: padded.z(x, y) - site.shift
    decks, feet = R.load()
    by_id = {d.id: d for d in decks}
    lanes = json.load(open(os.path.join(ROOT, "data", "town_lanes.json"), encoding="utf-8"))["lanes"]
    bridges, pieces = [], []
    n = 0
    way = json.load(open(os.path.join(GEN, "rooftop.json")))["pieces"] if os.path.exists(os.path.join(GEN, "rooftop.json")) else []
    on_way = {pc.get("deck") for pc in way}
    for bid, aid, bid2, pick, words in SPANS:
        a, b = by_id[aid], by_id[bid2]
        found = line(a, b, decks, pick)
        if found is None:
            print("bridges: %s: no clear line from %s to %s" % (bid, aid, bid2))
            continue
        side, t, pa, pb, (ox, oy) = found
        A = (pa[0] - ox * REST, pa[1] - oy * REST)
        B = (pb[0] + ox * REST, pb[1] + oy * REST)
        length = math.hypot(B[0] - A[0], B[1] - A[1])
        bridges.append(record(bid, A, a.top(), B, b.top(), (ox, oy), (aid, bid2), (a.parapet, b.parapet), terrain, words))
        x0, y0 = min(A[0], B[0]) - BOX, min(A[1], B[1]) - BOX
        x1, y1 = max(A[0], B[0]) + BOX, max(A[1], B[1]) + BOX
        ground = R.Ground(terrain, feet, x0, y0, x1, y1, lambda X, Y: np.ones(np.shape(X), dtype=bool), lanes,
                          raster=(padded.x0, padded.y1, padded.res))
        goal = town_cells(ground)
        for d, far, away in ((a, B, (ox, oy)), (b, A, (-ox, -oy))):
            if d.id in on_way:
                print("bridges: %s: onto %s by the Rooftop Way" % (bid, d.id))
                continue
            best = None
            for land, gc, cost, piece, kind in R.ground_joins(decks.index(d), d, ground):
                end = piece.get("foot", piece.get("pos", piece.get("to"))) if piece else None
                gx, gy = (ground.xy(*gc) if end is None else end[:2])
                s_ = (gx - A[0]) * ox + (gy - A[1]) * oy
                lat = abs(-(gx - A[0]) * oy + (gy - A[1]) * ox)
                if 0.0 < s_ < length and lat < 6.0:  # not down into the stair's slot under the bridge
                    continue
                if best is not None and cost >= best[0]:
                    continue
                if kind == "plank" and not plank_clear(piece["from"], piece["to"]):
                    continue
                if not reaches(ground, gc, goal):
                    continue
                best = (cost, kind, piece)
            if best is not None:
                cost, kind, piece = best
                print("bridges: %s: onto %s by %s (cost %.1f)" % (bid, d.id, kind, cost))
                if piece is not None:
                    pieces.append(dict(piece, bridge=bid))
                continue
            wl = wall_ladder(d, ground, goal, away)
            if wl is None:
                print("bridges: %s: NO WAY onto %s from the town" % (bid, d.id))
                continue
            print("bridges: %s: onto %s by a ladder up its wall, %.1f m at %.0f degrees (%s)" % (bid, d.id, wl["top"][2] - wl["foot"][2], wl["lean"], wl["file"]))
            pieces.append(dict(wl, bridge=bid))
    R.gap_parapets(pieces)  # where a plank onto a bridge's roof crosses a yard's parapet
    json.dump({"about": "The plank-and-rope bridges from tools/town/bridges.py (IMP-023 (3)): each from `a` to `b` (the town grid, an end on a roof's parapet or on the ground), sagging `sag` between them, its `drops` the steps down from each end to the roof's deck, built by ../tibet-blender/export_bridges.py along `dir` from `a`; and the pieces that lead onto their roofs from the town, as the Rooftop Way's (rooftop.json).",
               "bridges": bridges, "pieces": pieces}, open(OUT, "w"), indent=1)
    with open(REPORT, "w") as f:
        f.write("# The plank-and-rope bridges (IMP-023 (3))\n\n_Written by `tools/town/bridges.py`. Greg's 1773: \"a cool view behind the player as they run across an old bridge joining 2 parts of town (or just buildings)\"._\n\n")
        for bd in bridges:
            f.write("- **%s** (%s): from %s to %s, %.1f m, rising %.2f m, sagging %.2f m, at least %.1f m over the ground under it.\n" % (
                bd["id"], bd["words"], bd["ends"][0], bd["ends"][1], bd["length"], bd["rise"], bd["sag"], bd["under"]))
        for pc in pieces:
            f.write("- onto %s: a %s (`%s`)\n" % (pc["deck"], pc["kind"], pc["file"]))
    print("bridges: %d bridges, %d pieces -> %s" % (len(bridges), len(pieces), OUT))


if __name__ == "__main__":
    main()
