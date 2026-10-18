#!/usr/bin/env python3
"""The Rooftop Way (plan chapter 02, R-06 and SHL-30; chapter 03, 3.8; chapter 12, M1's acceptance 5; M1 sprint 4,
step 1): from Dechen-tsang's guest yard up onto its roofs and on over Shöl's roofs and lanes to the roof by the spring
where V-28 is taken, the cheapest way through a graph of the town's walkable surfaces, into
assets/generated/terrain/rooftop.json for world/town.gd, and docs/town/rooftop-report.md.

The surfaces, each a grid of 0.5 m cells:
- the ground as the game draws it (Terrain3D: a vertex on every whole metre, the padded raster read there): a cell is
  walkable outside every building's footprint and what stands on the ground by it with a box of its own (its type's
  sidecar lists them, `ground`: a latrine's pit, a yard's walls), grown by the player's 0.35 m, off the brink of a drop (a neighbour
  1.0 m lower) and off the side lanes' flights; a step to a neighbour climbs 30 degrees at most; a cell whose quad has
  a facet over 45 degrees costs STEEP_COST times as much (the game's floor limit is 50);
- every roof the kit dresses (each type's sidecar lists its roofs: outline, deck, parapet and the plan of what stands
  on it, kit/roofs.py), placed as world/town.gd places the buildings, the A3 houses' terraces among them;
- Dechen-tsang's guest yard, a metre over its pad (kit/trading.py).
The joins, each a kit piece the game places (their costs in COST):
- over the parapets, where two roofs touch and their decks are within 0.45 m, or where the ground outside a roof lies
  at its deck or parapet;
- roof-terrace steps (roof_steps_06/10/14), their top at the higher roof's face, where two roofs touch and differ by
  0.45-1.8 m, or from the ground up to a parapet 0.3-1.8 m over it;
- a notched log (notched_log_24 to _42, 67-70 degrees), onto a parapet 1.5-3.87 m over a lower roof or the ground, or up
  a retaining wall onto the terrace over it; or down from a lane's edge onto a roof under it;
- a stair-ladder (stair_ladder_50/60/70, IN-04, 65-70 degrees), onto a parapet 3.87-6.34 m over the ground or a yard;
- a plank bridge (plank_bridge_3/4/5, SHL-30), between parapets, or from a parapet to a lane, across 1.2-5 m where the
  ends differ by 1.0 m or less (chapter 03, 3.8: "a plank over an areaway, which is why the lane above runs level with
  the roof below");
- up a side lane's flight (the builder's, data/town_lanes.json), foot to head.
A metre walked costs 0.7 on a roof, 3 on the town's ground and 6 on open hillside, so the way keeps to the roofs where it
can and to the town where it cannot. It passes the roofs in VIA, the way R-06 is drawn: left to its costs alone, the way
had flipped between the upper roofs and the hillside west of them on changes of a fifth of a per cent (the mani wall's
west end, a pitch's footprint; sprint 4, step 3). Each leg is string-pulled into straight stretches the walker can take,
clear 0.3 m either side; a ladder met from the ground gets an approach on its axis. The test: tools/player/s15.sh route
rooftop.
Run: tools/py tools/town/rooftop.py   (tools/terrain/build.sh runs it after ladders.py)
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
import builder as B  # noqa: E402  (rect)
import ladders as LD  # noqa: E402  (kit_file for the builder's houses)
import pads as P  # noqa: E402  (footprint)

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
KIT = os.path.join(ROOT, "assets", "generated", "kit", "types")
OUT = os.path.join(GEN, "rooftop.json")
REPORT = os.path.join(ROOT, "docs", "town", "rooftop-report.md")
END = (-95.0, 205.0)  # V-28, the top of R-06 (chapter 02): the roof by the spring
VIA = [(-67.9, 135.0), (-76.4, 165.9), (-106.0, 170.4)]  # roofs the way passes on its way up, each the roof nearest the
# point: H-SHL-093, the first of the upper town's; H-SHL-077 and 101, the planks along row 8 between them (IMP-023, 7 Oct
# 2026: on level yards the town's ground had grown cheaper than the roofs, and the way had left them for the lanes)
CELL = 0.5
CORRIDOR = 45.0  # metres either side of the line from Dechen-tsang to V-28
LOGS = LD.LOGS
LOG_LEAN, LOG_RISE = 67.0, 3.87  # the longest log (4.2 m, 0.2 over the parapet) climbs 3.87 m at 67 degrees
STAIRS = [(5.0, "stair_ladder_50_v1"), (6.0, "stair_ladder_60_v1"), (7.0, "stair_ladder_70_v1")]
STAIR_LEAN, STAIR_RISE = 65.0, 6.34  # as built (kit infra.stair_ladder); the longest climbs 6.34 m at 65 degrees
LOG_LEANS, STAIR_LEANS = (67.0, 70.0), (65.0, 70.0)  # the leans the planner tries, as chapter 03 allows (the game turns the piece)
STEPS = [(0.6, "roof_steps_06_v1"), (1.0, "roof_steps_10_v1"), (1.4, "roof_steps_14_v1")]
PLANKS = [(3.0, "plank_bridge_3_v1"), (4.0, "plank_bridge_4_v1"), (5.0, "plank_bridge_5_v1")]
COST = {"parapet": 1.0, "steps": 2.0, "plank": 2.5, "log": 4.0, "stair": 6.0}
W_ROOF, W_GROUND, W_OPEN = 0.7, 3.0, 6.0  # a metre on a roof, on the town's ground (aprons, lanes, yards), on open hillside
TOWN_REACH = 4.5  # the town's ground: within this of a building, or in a side lane
SLOPE_MAX = math.tan(math.radians(30.0))  # the steepest ground the way walks, cell to cell and along its straight stretches
FACET_MAX = math.tan(math.radians(45.0))  # a facet of the game's 1 m terrain steeper than this is dear to walk on
STEEP_COST = 4.0  # times a metre's cost, on such a facet
PARAPET_IN = 0.55  # from a roof's outline (the wall's face at the top, 0.1 proud) to its parapet's inner face
LAND = 0.95  # where a join lands on a roof: this far inside its outline


def climb_scale(lean, kind):
    """How much higher the longest piece climbs at `lean` than at its built lean."""
    built = LOG_LEAN if kind == "log" else STAIR_LEAN
    return math.sin(math.radians(lean)) / math.sin(math.radians(built))


class Deck:
    """A walkable flat: a roof (with its parapet) or a yard, a rectangle in its building's frame placed in the town grid,
    and its cells (0.5 m) free of the dressing."""

    def __init__(self, did, cx, cy, rot, u0, v0, u1, v1, z, parapet, dressed=True, obstacles=None):
        self.id, self.cx, self.cy, self.rot = did, cx, cy, rot
        self.u0, self.v0, self.u1, self.v1, self.z, self.parapet = u0, v0, u1, v1, z, parapet
        th = math.radians(rot - 180.0)
        self.c, self.s = math.cos(th), math.sin(th)
        m = PARAPET_IN if parapet > 0 else 0.3
        self.a0, self.a1, self.b0, self.b1 = u0 + m, u1 - m, v0 + m, v1 - m  # the deck inside the parapet
        self.nu = max(1, int((self.a1 - self.a0) / CELL))
        self.nv = max(1, int((self.b1 - self.b0) / CELL))
        self.free = np.ones((self.nv, self.nu), dtype=bool)
        if dressed:
            for j in range(self.nv):
                for i in range(self.nu):
                    u, v = self.cell_uv(i, j)
                    if obstacles is not None:  # the kit's own: the piers' and the fuel's hulls, grown by the player's 0.35 m
                        self.free[j, i] = not any(o[0] - 0.35 < u < o[2] + 0.35 and o[1] - 0.35 < v < o[3] + 0.35 for o in obstacles)
                    else:  # an older export: the piers at the corners, the firewood along the back and the left
                        corner = min(u - self.a0, self.a1 - u) < 0.75 and min(v - self.b0, self.b1 - v) < 0.75
                        fuel = v > self.b1 - 0.65 or u < self.a0 + 0.65
                        self.free[j, i] = not (corner or fuel)

    def cell_uv(self, i, j):
        return self.a0 + (i + 0.5) * (self.a1 - self.a0) / self.nu, self.b0 + (j + 0.5) * (self.b1 - self.b0) / self.nv

    def world(self, u, v):
        return self.cx + u * self.c + v * self.s, self.cy - u * self.s + v * self.c

    def local(self, x, y):
        dx, dy = x - self.cx, y - self.cy
        return dx * self.c - dy * self.s, dx * self.s + dy * self.c

    def cell_at(self, u, v):
        if not (self.a0 <= u <= self.a1 and self.b0 <= v <= self.b1):
            return None
        i = min(self.nu - 1, int((u - self.a0) / (self.a1 - self.a0) * self.nu))
        j = min(self.nv - 1, int((v - self.b0) / (self.b1 - self.b0) * self.nv))
        return (i, j) if self.free[j, i] else None

    def centre(self):
        return self.world((self.u0 + self.u1) / 2, (self.v0 + self.v1) / 2)

    def corners(self):
        return [self.world(u, v) for u, v in ((self.u0, self.v0), (self.u1, self.v0), (self.u1, self.v1), (self.u0, self.v1))]

    def top(self):
        return self.z + self.parapet


def side_frame(d, side):
    """A deck's side: the outward unit (du, dv), the along-side axis and its span, and the outline's coordinate."""
    if side == "+u":
        return (1.0, 0.0), "v", (d.b0, d.b1), d.u1
    if side == "-u":
        return (-1.0, 0.0), "v", (d.b0, d.b1), d.u0
    if side == "+v":
        return (0.0, 1.0), "u", (d.a0, d.a1), d.v1
    return (0.0, -1.0), "u", (d.a0, d.a1), d.v0


def on_side(d, side, t, out):
    """The point `out` metres outside deck d's outline on `side` at t along it (negative: inside), in the town grid,
    and the outward unit vector there."""
    (nu, nv), axis, _, edge = side_frame(d, side)
    if axis == "v":
        u, v = edge + nu * out, t
    else:
        u, v = t, edge + nv * out
    x, y = d.world(u, v)
    return (x, y), (nu * d.c + nv * d.s, -nu * d.s + nv * d.c)


def bearing(dx, dy):
    return math.degrees(math.atan2(dx, dy)) % 360.0


def load():
    """The decks (every roof of the builder's houses, the gazetteer's placed B houses and Dechen-tsang, and the guest
    yard) and the footprints to keep off."""
    decks, feet = [], []
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    houses = json.load(open(os.path.join(ROOT, "data", "town_generic.json"), encoding="utf-8"))["houses"]
    named = {"B": "town_house_b2_v1", "B, large": "town_house_b3_v1", "B, workshop": "town_house_b1_v1"}
    own = {"SHL-19": "headman_house_v1", "SHL-21": "workshop_turner_v1", "SHL-22": "workshop_saddler_v1", "SHL-25": "workshop_tailor_v1",
           "SHL-08": "mani_lhakhang_v1"}  # world/town.gd NAMED
    records = [(h, LD.kit_file(h)) for h in houses]
    for h in houses:
        feet.append(B.rect(h["pos"][0], h["pos"][1], h["footprint"][0], h["footprint"][1], h["rot_deg"], 0.35))
    for b in town["buildings"]:
        p, fp = b.get("pos"), b.get("footprint")
        if not p or p[2] is None or not fp or "line" in b or max(fp) > 80 or b.get("type") == "pitch":  # the pitch: with its wall, below
            continue
        feet.append(B.rect(*P.footprint(b), b.get("rot_deg", 180.0), 0.35))  # a walled yard with its house (pads.py YARDS)
        if b["id"] == "SHL-04":
            records.append((b, "trading_house_v1"))
        elif b["id"] in own:
            records.append((b, own[b["id"]]))
        elif b.get("type") in named:
            records.append((b, named[b["type"]]))
    for h, f in records:
        side = json.load(open(os.path.join(KIT, f + ".json")))
        x, y, z = h["pos"]
        th = math.radians(h.get("rot_deg", 180.0) - 180.0)
        c, s_ = math.cos(th), math.sin(th)
        for g in side.get("ground", []):  # what stands on the ground by it with a box of its own: a latrine's pit, a yard's walls
            feet.append([(x + u * c + v * s_, y - u * s_ + v * c) for u, v in ((g[0] - 0.35, g[1] - 0.35), (g[2] + 0.35, g[1] - 0.35),
                                                                           (g[2] + 0.35, g[3] + 0.35), (g[0] - 0.35, g[3] + 0.35))])
        for k, r in enumerate(side.get("roofs", [])):
            decks.append(Deck("%s.%d" % (h["id"], k), x, y, h.get("rot_deg", 180.0), r[0], r[1], r[2], r[3], z + r[4], r[5],
                              obstacles=r[6] if len(r) > 6 else None))
    mani = os.path.join(GEN, "mani_walls.json")  # the barkor's mani wall and its end pillars (tools/town/mani.py)
    if os.path.exists(mani):
        for wall in json.load(open(mani))["walls"]:
            for x, y, z, yaw, f in wall["segments"] + wall["ends"]:
                c, s_ = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
                hl, hw = (1.0, 0.7) if "seg" in f else (0.8, 0.8)
                feet.append([(x + u * c - v * s_, y + u * s_ + v * c) for u, v in ((-hl, -hw), (hl, -hw), (hl, hw), (-hl, hw))])
            if "pitch" in wall:  # Pasang's pitch: its kit frame's -1.0..1.8 by -0.6..0.7, turned as a named building is
                x, y, z, facing, f = wall["pitch"]["at"]
                th = math.radians(facing - 180.0)
                c, s_ = math.cos(th), math.sin(th)
                feet.append([(x + u * c + v * s_, y - u * s_ + v * c) for u, v in ((-1.35, -0.95), (2.15, -0.95), (2.15, 1.05), (-1.35, 1.05))])
    dechen = next(b for b in town["buildings"] if b["id"] == "SHL-04")
    x, y, z = dechen["pos"]
    decks.append(Deck("SHL-04.yard", x, y, 180.0, -8.7, 3.3, 8.7, 17.0, z + 1.0, 0.0, dressed=False))  # kit/trading.py
    return decks, feet


class Ground:
    def __init__(self, terrain, feet, x0, y0, x1, y1, keep, lanes=None, raster=None):
        self.x0, self.y0 = x0, y0
        self.nx, self.ny = int((x1 - x0) / CELL), int((y1 - y0) / CELL)
        xs = x0 + (np.arange(self.nx) + 0.5) * CELL
        ys = y0 + (np.arange(self.ny) + 0.5) * CELL
        GX, GY = np.meshgrid(xs, ys)
        # The game's ground (Terrain3D, tools/terrain/export_t3d.py): a vertex on every whole metre, its height the
        # raster read there (the mean of the four pixels round it), the quads between. Read at the raster's own pixel
        # centres instead, half a metre off, the way had run along a bank the game drew half a metre nearer.
        vx, vy = np.floor(GX), np.floor(GY)
        fx_, fy_ = GX - vx, GY - vy
        z00, z10 = terrain(vx, vy), terrain(vx + 1.0, vy)
        z01, z11 = terrain(vx, vy + 1.0), terrain(vx + 1.0, vy + 1.0)
        self.z = z00 * (1 - fx_) * (1 - fy_) + z10 * fx_ * (1 - fy_) + z01 * (1 - fx_) * fy_ + z11 * fx_ * fy_
        ok = np.isfinite(self.z) & keep(GX, GY)
        if raster is not None:
            # A cell in a quad with an edge or a diagonal steeper than FACET_MAX is dear to walk (a pad's edge had looked
            # a gentle slope where the game's facet was 51 degrees, over the player's floor limit, and the walker slid;
            # forbidden outright, they cut the way's roofs from eleven to seven).
            lim = FACET_MAX
            steep = (np.abs(z00 - z10) > lim) | (np.abs(z01 - z11) > lim) | (np.abs(z00 - z01) > lim) | (np.abs(z10 - z11) > lim) \
                | (np.abs(z00 - z11) > lim * 1.414) | (np.abs(z10 - z01) > lim * 1.414)
            self.steep = steep  # walkable, but dear: the way crosses such a facet only where it must (STEEP_COST)
        for q in feet:
            qx, qy = [p[0] for p in q], [p[1] for p in q]
            i0, i1 = max(0, int((min(qy) - y0) / CELL)), min(self.ny, int((max(qy) - y0) / CELL) + 1)
            j0, j1 = max(0, int((min(qx) - x0) / CELL)), min(self.nx, int((max(qx) - x0) / CELL) + 1)
            if i1 <= i0 or j1 <= j0:
                continue
            sx, sy = GX[i0:i1, j0:j1], GY[i0:i1, j0:j1]
            pos = np.ones(sx.shape, dtype=bool)
            neg = np.ones(sx.shape, dtype=bool)
            for k in range(4):
                ax, ay = q[k]
                bx, by = q[(k + 1) % 4]
                cr = (bx - ax) * (sy - ay) - (by - ay) * (sx - ax)
                pos &= cr >= 0.0
                neg &= cr <= 0.0
            ok[i0:i1, j0:j1] &= ~(pos | neg)
        # the brink of a drop is no place to walk: a cell with a neighbour 1.0 m lower (the rounded rim of a bank or a
        # terrace wall, which the walker's capsule overhangs and slips from)
        zf = np.where(np.isfinite(self.z), self.z, 1e9)
        brink = np.zeros(ok.shape, dtype=bool)
        for di, dj in ((0, 1), (1, 0), (0, -1), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            nb = np.full(zf.shape, 1e9)
            nb[max(di, 0):zf.shape[0] + min(di, 0), max(dj, 0):zf.shape[1] + min(dj, 0)] = zf[max(-di, 0):zf.shape[0] + min(-di, 0), max(-dj, 0):zf.shape[1] + min(-dj, 0)]
            brink |= zf - nb > 1.0
        for ln in (lanes or []):  # a walled lane's bed (the garden lane's, tools/town/gardens.py): its walls hold its edges
            if not ln.get("garden"):
                continue
            (fx, fy), (ux, uy) = ln["from"], ln["dir"]
            sl = (GX - fx) * ux + (GY - fy) * uy
            lat = -(GX - fx) * uy + (GY - fy) * ux
            brink &= ~((sl >= -0.5) & (sl <= ln["length"] + 0.5) & (np.abs(lat) <= ln["width"] / 2 - 0.3))
        self.brink = brink
        # the solid walls (tools/town/walls.py: 0.6 m or more, with collision in the game; IMP-023): their faces, and a
        # parapet on one, are no ground to cross, however the terrain's metre-wide step under them reads
        wall = np.zeros(ok.shape, dtype=bool)
        wpath = os.path.join(GEN, "walls.json")
        for r in (json.load(open(wpath))["runs"] if os.path.exists(wpath) else []):
            fl = r.get("flags", [0] * len(r["pts"]))
            for k, (a, b) in enumerate(zip(r["pts"][:-1], r["pts"][1:])):
                if not (fl[k] & 2 and fl[k + 1] & 2):
                    continue
                # the face from the wall's line out over its lower side (a fill wall's top, a cut wall's foot, on the
                # line), and a fill wall's parapet back over its yard
                para = 0.45 if r["kind"] == "fill" and fl[k] & 1 and fl[k + 1] & 1 else 0.0
                lean = 0.17 * max(a[5] - a[4], b[5] - b[4])
                n_ = max(2, int(math.hypot(b[0] - a[0], b[1] - a[1]) / 0.25) + 1)
                for t in np.linspace(0.0, 1.0, n_):
                    x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                    ox, oy = a[2], a[3]
                    for e in np.arange(-para, lean + 0.01, 0.25):
                        cx_, cy_ = x + ox * e, y + oy * e
                        i_, j_ = int((cy_ - y0) / CELL), int((cx_ - x0) / CELL)
                        for di_ in (-1, 0, 1):
                            for dj_ in (-1, 0, 1):
                                ii, jj = i_ + di_, j_ + dj_
                                if 0 <= ii < self.ny and 0 <= jj < self.nx and math.hypot(GX[ii, jj] - cx_, GY[ii, jj] - cy_) < 0.45:
                                    wall[ii, jj] = True
        self.wall = wall
        self.ok = ok & ~brink & ~wall
        if raster is None:
            self.steep = np.zeros(ok.shape, dtype=bool)
        # the town's own ground: near a building (its apron and the lane before it) or in a side lane; the rest is open
        town = np.zeros(ok.shape, dtype=bool)
        for q in feet:
            cx, cy = sum(p[0] for p in q) / 4, sum(p[1] for p in q) / 4
            r = max(math.hypot(p[0] - cx, p[1] - cy) for p in q) + TOWN_REACH
            i0, i1 = max(0, int((cy - r - y0) / CELL)), min(self.ny, int((cy + r - y0) / CELL) + 1)
            j0, j1 = max(0, int((cx - r - x0) / CELL)), min(self.nx, int((cx + r - x0) / CELL) + 1)
            if i1 > i0 and j1 > j0:
                town[i0:i1, j0:j1] |= np.hypot(GX[i0:i1, j0:j1] - cx, GY[i0:i1, j0:j1] - cy) <= r
        for ln in lanes or []:
            (fx, fy), (ux, uy) = ln["from"], ln["dir"]
            sl = (GX - fx) * ux + (GY - fy) * uy
            lat = -(GX - fx) * uy + (GY - fy) * ux
            town |= (sl >= -1.0) & (sl <= ln["length"] + 1.0) & (np.abs(lat) <= ln["width"] / 2 + 0.5)
            f = ln["flight"]
            if f:  # the flight itself, its cheeks and all, is no ground to walk or to stand a piece on: its own join climbs it
                s_up = f["s"] + max(0.0, ln["z_a"] - f["z"]) / 0.8
                self.ok &= ~((sl >= s_up - 0.3) & (sl <= ln["length"] - 0.5) & (np.abs(lat) <= ln["width"] / 2 + 0.2))  # wall to wall, but its top landing's back (IMP-023)
        self.town = town

    def cell(self, x, y):
        j, i = int(math.floor((x - self.x0) / CELL)), int(math.floor((y - self.y0) / CELL))
        if 0 <= i < self.ny and 0 <= j < self.nx and self.ok[i, j]:
            return i, j
        return None

    def height(self, x, y):
        c = self.cell(x, y)
        return float(self.z[c]) if c else None

    def raw(self, x, y):
        """The ground's height at (x, y), walkable or not (None outside the grid)."""
        j, i = int(math.floor((x - self.x0) / CELL)), int(math.floor((y - self.y0) / CELL))
        return float(self.z[i, j]) if 0 <= i < self.ny and 0 <= j < self.nx and np.isfinite(self.z[i, j]) else None

    def level(self, x, y, tol):
        """The ground at (x, y) if it and the ground 0.4 m round it are walkable and within tol of it."""
        g = self.height(x, y)
        if g is None:
            return None
        for ex, ey in ((0.4, 0), (-0.4, 0), (0, 0.4), (0, -0.4)):
            h = self.height(x + ex, y + ey)
            if h is None or abs(h - g) > tol:
                return None
        return g

    def xy(self, i, j):
        return self.x0 + (j + 0.5) * CELL, self.y0 + (i + 0.5) * CELL


_SOLID = None


def solid_walls():
    """The solid walls' points (tools/town/walls.py, 0.6 m or more): [x, y, top], their tops' coping 0.12 m over it."""
    global _SOLID
    if _SOLID is None:
        path = os.path.join(GEN, "walls.json")
        pts = []
        for r in (json.load(open(path))["runs"] if os.path.exists(path) else []):
            fl = r.get("flags", [0] * len(r["pts"]))
            pts += [[q[0], q[1], q[5]] for k, q in enumerate(r["pts"]) if fl[k] & 2]
        _SOLID = np.array(pts) if pts else np.zeros((0, 3))
    return _SOLID


def clears_walls(a, b):
    """Whether a plank from a (x, y, z) to b passes over every solid wall it crosses (its coping), not into it (a plank
    from a roof onto a yard had run 0.9 m under the yard's edge: IMP-023)."""
    w = solid_walls()
    if not len(w):
        return True
    dx, dy = b[0] - a[0], b[1] - a[1]
    L2 = max(dx * dx + dy * dy, 1e-9)
    t = ((w[:, 0] - a[0]) * dx + (w[:, 1] - a[1]) * dy) / L2
    near = (t > 0.05) & (t < 0.95) & (np.hypot(a[0] + dx * t - w[:, 0], a[1] + dy * t - w[:, 1]) < 0.6)
    return bool(np.all(a[2] + (b[2] - a[2]) * t[near] >= w[near, 2] + 0.07))


def ground_joins(di, d, ground):
    """Joins between deck d and the ground outside it: (deck cell, ground cell, cost, piece, kind)."""
    out = []
    top = d.top()
    for side in ("+u", "-u", "+v", "-v"):
        (nu, nv), axis, span, edge = side_frame(d, side)
        for t in np.arange(span[0] + 0.5, span[1] - 0.4, 1.0):
            u, v = (edge - nu * LAND, t) if axis == "v" else (t, edge - nv * LAND)
            land = d.cell_at(u, v)
            if land is None:
                continue
            (ex, ey), (ox, oy) = on_side(d, side, t, 0.0)
            # over the parapet onto ground at the deck or the parapet; a plank to a lane across an areaway
            for out_ in np.arange(0.4, 5.01, 0.25):
                gx, gy = ex + ox * out_, ey + oy * out_
                gc = ground.cell(gx, gy)
                if gc is None:
                    continue
                g = float(ground.z[gc])
                if out_ <= 0.8 and d.z - 0.25 <= g <= top + 0.3:
                    out.append((land, gc, COST["parapet"], None, "parapet"))
                if 1.2 <= out_ <= 5.0 and abs(g - top) <= 1.0 and ground.level(gx, gy, 0.25) is not None:
                    kit = next((p for p in PLANKS if p[0] >= out_), None)  # the kit's length is its span (its beams rest 0.3 m past each end)
                    if kit and clears_walls((ex, ey, top), (gx, gy, g)):
                        out.append((land, gc, COST["plank"] + out_ * 0.2, {"kind": "plank", "file": kit[1], "from": [round(ex - ox * 0.15, 2), round(ey - oy * 0.15, 2), round(top, 2)],
                                    "to": [round(gx, 2), round(gy, 2), round(g, 2)], "deck": d.id}, "plank"))
            # a log or a stair-ladder from the ground up to the parapet, its foot out from the wall at its lean (chapter 03:
            # a log at 65-70 degrees, a stair-ladder at 60-70; steeper where the ledge before a house is narrow)
            for kind, leans, lo, hi in (("log", LOG_LEANS, 1.5, LOG_RISE), ("stair", STAIR_LEANS, LOG_RISE, STAIR_RISE)):
                found = False
                for lean in leans:
                    for guess in np.arange(lo, hi + 0.01, 0.5):
                        dist = guess / math.tan(math.radians(lean))
                        fx, fy = ex + ox * dist, ey + oy * dist
                        g = ground.level(fx, fy, 0.25)
                        if g is None or abs(top - g - guess) > 0.3 or not lo <= top - g <= hi * climb_scale(lean, kind):
                            continue
                        rise = top - g
                        dist = rise / math.tan(math.radians(lean))
                        fx, fy = ex + ox * dist, ey + oy * dist
                        g2 = ground.level(fx, fy, 0.25)
                        if g2 is None or abs(g2 - g) > 0.15:
                            continue
                        kits = LOGS if kind == "log" else STAIRS
                        kit = next((k for k in kits if k[0] >= math.hypot(rise, dist) + 0.2), None)
                        if kit is None:
                            continue
                        if not all((ground.height(ex + ox * dist * q, ey + oy * dist * q) or -1e9) < g + rise * (1 - q) - 0.2 for q in (0.3, 0.6)):
                            continue
                        out.append((land, ground.cell(fx, fy), COST[kind] + rise, {"kind": kind, "file": kit[1], "foot": [round(fx, 2), round(fy, 2), round(g, 2)],
                                    "top": [round(ex, 2), round(ey, 2), round(top, 2)], "bearing": round(bearing(-ox, -oy), 1), "lean": lean, "deck": d.id}, kind))
                        found = True
                        break
                    if found:
                        break
            # roof-terrace steps from the ground up to the parapet, their top against the wall
            for kit in STEPS:
                n = max(2, int(round(kit[0] / 0.2)))
                length = n * 0.3
                fx, fy = ex + ox * (length + 0.05), ey + oy * (length + 0.05)
                g = ground.level(fx, fy, 0.2)
                if g is None or abs(top - g - kit[0]) > 0.2:
                    continue
                if any((ground.height(ex + ox * (length * q + 0.1), ey + oy * (length * q + 0.1)) or 1e9) > g + (top - g) * (1 - q) + 0.05 for q in (0.3, 0.7)):
                    continue
                out.append((land, ground.cell(fx + ox * 0.5, fy + oy * 0.5), COST["steps"], {"kind": "steps", "file": kit[1], "pos": [round(fx, 2), round(fy, 2), round(g, 2)],
                            "bearing": round(bearing(-ox, -oy), 1), "rise": round(top - g, 2), "deck": d.id}, "steps"))
                break
            # a log down from a lane above onto this roof: its foot on the roof, its top at the lane's edge
            for back in (0.6, 1.0):
                gx, gy = ex + ox * back, ey + oy * back
                g = ground.level(gx, gy, 0.3)
                if g is None:
                    continue
                rise = g - d.z
                if not 1.5 <= rise <= LOG_RISE:
                    continue
                dist = rise / math.tan(math.radians(LOG_LEAN))
                uu, vv = (edge - nu * (dist + 0.1), t) if axis == "v" else (t, edge - nv * (dist + 0.1))
                foot = d.cell_at(uu, vv)
                kit = next((k for k in LOGS if k[0] >= math.hypot(rise, dist) + 0.2), None)
                if foot is None or kit is None:
                    continue
                fx, fy = d.world(uu, vv)
                out.append((foot, ground.cell(gx, gy), COST["log"] + rise, {"kind": "log", "file": kit[1], "foot": [round(fx, 2), round(fy, 2), round(d.z, 2)],
                            "top": [round(ex + ox * 0.1, 2), round(ey + oy * 0.1, 2), round(g, 2)], "bearing": round(bearing(ox, oy), 1), "lean": LOG_LEAN, "deck": d.id, "lane": True}, "log"))
                break
    return out


def gap_parapets(pieces):
    """A gap in a yard's parapet (tools/town/walls.py; IMP-023) wherever a piece of the way crosses it: a plank from a
    roof onto a yard, a log or stair-ladder from a yard over its edge. walls.json's points there lose their parapet flag
    (the wall stays solid; its top is the yard's), before the kit's export_walls.py builds them (tools/terrain/build.sh
    runs this first) and tools/town/graph.py reads them."""
    path = os.path.join(GEN, "walls.json")
    if not os.path.exists(path):
        return
    data = json.load(open(path))
    spans = []
    for pc in pieces:
        if pc.get("kind") == "plank":
            spans.append((pc["from"][:2], pc["to"][:2]))
        elif pc.get("kind") in ("log", "stair"):
            spans.append((pc["foot"][:2], pc["top"][:2]))
    n = 0
    for r in data["runs"]:
        fl = r.get("flags")
        if not fl:
            continue
        for k, q in enumerate(r["pts"]):
            if not fl[k] & 1:
                continue
            for (ax, ay), (bx, by) in spans:
                dx, dy = bx - ax, by - ay
                t = max(0.0, min(1.0, ((q[0] - ax) * dx + (q[1] - ay) * dy) / max(dx * dx + dy * dy, 1e-9)))
                if math.hypot(ax + dx * t - q[0], ay + dy * t - q[1]) < 1.1:
                    fl[k] &= ~1
                    n += 1
                    break
    json.dump(data, open(path, "w"), indent=None)
    print("rooftop: %d parapet points opened where the way crosses a yard's edge" % n)


def wall_joins(ground):
    """Joins up the retaining walls (tools/town/walls.py's runs): a notched log against the wall, 1.5-3.87 m, its top on
    the coping. The terrain is read across each wall point for its break: the terrace's edge above it, the level ground
    below. (The lanes' stairs are the builder's, data/town_lanes.json: their beds are the ground here.)
    (lower ground cell, upper ground cell, cost, piece, kind)."""
    out = []
    runs = json.load(open(os.path.join(GEN, "walls.json")))["runs"]
    es = np.arange(-4.0, 6.01, 0.5)  # a cell apart
    for r in runs:
        fill = r["kind"] == "fill"
        for k, q in enumerate(r["pts"]):
            x, y, ox, oy, foot, top = q[:6]  # (a parapet's own top, the garden lane's, after them)
            if top - foot < 0.45 or (ground.cell(x + ox * 2, y + oy * 2) is None and ground.cell(x - ox * 2, y - oy * 2) is None):
                continue
            if r.get("flags") and r["flags"][k] & 1:
                continue  # a parapet along its top (IMP-023): no log over it
            nx, ny = (ox, oy) if fill else (-ox, -oy)  # towards the lower side
            h = [ground.raw(x + nx * e, y + ny * e) for e in es]
            if any(v is None for v in h):
                continue
            drops = [h[k] - h[k + 1] for k in range(len(es) - 1)]
            kb = int(np.argmax(drops))
            if drops[kb] < 0.3:
                continue
            k0 = kb
            while k0 > 0 and drops[k0 - 1] > 0.15:
                k0 -= 1
            k1 = kb + 1
            while k1 < len(es) - 1 and drops[k1] > 0.15:
                k1 += 1
            e_top, e_bot = es[k0], es[k1]
            z_up, z_low = h[k0], h[k1]
            rise = z_up - z_low
            if not 0.45 <= rise <= 8.0:
                continue
            tx, ty = x + nx * e_top, y + ny * e_top  # the wall's top edge
            up_cell = ground.cell(tx - nx * 0.5, ty - ny * 0.5)
            if up_cell is None or abs(float(ground.z[up_cell]) - z_up) > 0.2 or ground.level(tx - nx * 0.5, ty - ny * 0.5, 0.25) is None:
                continue
            low_ok = ground.level(x + nx * (e_bot + 0.5), y + ny * (e_bot + 0.5), 0.25)
            if low_ok is None or abs(low_ok - z_low) > 0.3:
                continue
            if 1.5 <= rise <= LOG_RISE:  # a log against the wall, its top on the coping
                dist = rise / math.tan(math.radians(LOG_LEAN))
                lx, ly = tx + nx * dist, ty + ny * dist
                gl = ground.level(lx, ly, 0.25)
                kit = next((kk for kk in LOGS if kk[0] >= math.hypot(rise, dist) + 0.2), None)
                if gl is not None and abs(gl - z_low) < 0.3 and kit is not None and dist >= e_bot - e_top:
                    out.append((ground.cell(lx, ly), up_cell, COST["log"] + rise, {"kind": "log", "file": kit[1], "foot": [round(lx, 2), round(ly, 2), round(gl, 2)],
                                "top": [round(tx, 2), round(ty, 2), round(z_up + 0.12, 2)], "bearing": round(bearing(-nx, -ny), 1), "lean": LOG_LEAN, "deck": "wall"}, "log"))
    return out


def deck_joins(a, b):
    """Joins from deck a onto deck b where a's side faces b: over the parapets, steps, a plank, or a log or stair-ladder
    from the lower onto the higher (its foot on a). (a cell, b cell, cost, piece, kind)."""
    out = []
    pts = [a.local(*p) for p in b.corners()]
    bu0, bu1 = min(p[0] for p in pts), max(p[0] for p in pts)
    bv0, bv1 = min(p[1] for p in pts), max(p[1] for p in pts)
    yard = a.parapet == 0.0
    for side in ("+u", "-u", "+v", "-v"):
        (nu, nv), axis, span, edge = side_frame(a, side)
        if axis == "v":
            lo, hi = max(a.b0, bv0), min(a.b1, bv1)
            gap = (bu0 - a.u1) if side == "+u" else (a.u0 - bu1)
        else:
            lo, hi = max(a.a0, bu0), min(a.a1, bu1)
            gap = (bv0 - a.v1) if side == "+v" else (a.v0 - bv1)
        if hi - lo < 1.2 or gap < -0.6 or gap > 5.0:
            continue
        for t in np.arange(lo + 0.6, hi - 0.5, 1.0):
            (ex, ey), (ox, oy) = on_side(a, side, t, 0.0)
            bx, by = ex + ox * (max(gap, 0.0) + LAND), ey + oy * (max(gap, 0.0) + LAND)
            cb = b.cell_at(*b.local(bx, by))
            if cb is None:
                continue
            dz = b.z - a.z
            ua, va = (edge - nu * LAND, t) if axis == "v" else (t, edge - nv * LAND)
            ca = a.cell_at(ua, va)
            if not yard and ca is not None and gap <= 0.9:
                if abs(dz) <= 0.45:
                    out.append((ca, cb, COST["parapet"], None, "parapet"))
                    continue
                if 0.45 < dz <= 1.8:  # steps on a, the lower, up to b's parapet top, over a's parapet: their top at b's face
                    rise = b.top() - a.z
                    kit = next((s for s in STEPS if s[0] >= rise - 0.25), None)
                    if kit is not None and abs(kit[0] - rise) <= 0.25:
                        length = max(2, int(round(kit[0] / 0.2))) * 0.3
                        back = length - max(gap, 0.0)
                        uf, vf = (edge - nu * back, t) if axis == "v" else (t, edge - nv * back)
                        um, vm = (edge - nu * back / 2, t) if axis == "v" else (t, edge - nv * back / 2)
                        cf = a.cell_at(uf, vf) if back > PARAPET_IN + 0.3 and a.cell_at(um, vm) is not None else None
                        if cf is not None:
                            fx, fy = a.world(uf, vf)
                            out.append((cf, cb, COST["steps"], {"kind": "steps", "file": kit[1], "pos": [round(fx, 2), round(fy, 2), round(a.z, 2)],
                                                                "bearing": round(bearing(ox, oy), 1), "rise": round(rise, 2), "deck": b.id}, "steps"))
                            continue
            if not yard and ca is not None and 1.2 <= gap <= 5.0 and abs(b.top() - a.top()) <= 1.0:
                kit = next((p for p in PLANKS if p[0] >= gap), None)
                if kit:
                    out.append((ca, cb, COST["plank"] + gap * 0.2, {"kind": "plank", "file": kit[1], "from": [round(ex - ox * 0.15, 2), round(ey - oy * 0.15, 2), round(a.top(), 2)],
                                                                   "to": [round(ex + ox * (gap + 0.15), 2), round(ey + oy * (gap + 0.15), 2), round(b.top(), 2)], "deck": b.id}, "plank"))
                    continue
            # a climb from a, the lower, onto b's parapet (b's face gap metres out from a's edge); the foot back on a
            rise = b.top() - a.z
            for kind, lean, lo_, hi_ in (("log", LOG_LEAN, 1.5, LOG_RISE), ("stair", STAIR_LEAN, LOG_RISE, STAIR_RISE)):
                if not lo_ <= rise <= hi_ or (kind == "stair" and not yard):
                    continue  # stair-ladders stand in yards (IN-04); from a roof, a log
                dist = rise / math.tan(math.radians(lean))
                back = dist - max(gap, 0.0)
                if back < LAND - 0.2:
                    continue
                uf, vf = (edge - nu * back, t) if axis == "v" else (t, edge - nv * back)
                cf = a.cell_at(uf, vf)
                kits = LOGS if kind == "log" else STAIRS
                kit = next((k for k in kits if k[0] >= math.hypot(rise, dist) + 0.2), None)
                if cf is None or kit is None:
                    continue
                fx, fy = a.world(uf, vf)
                tx, ty = ex + ox * max(gap, 0.0), ey + oy * max(gap, 0.0)
                out.append((cf, cb, COST[kind] + rise, {"kind": kind, "file": kit[1], "foot": [round(fx, 2), round(fy, 2), round(a.z, 2)],
                                                       "top": [round(tx, 2), round(ty, 2), round(b.top(), 2)], "bearing": round(bearing(ox, oy), 1), "lean": lean, "deck": b.id}, kind))
    return out


def simplify(pts, clear):
    """A run of cells as few points as a walk can take straight: from each kept point, on to the farthest later one the
    straight line to which `clear` passes (string pulling; a simplification by turns had cut the corners the cells had
    gone round, over a batter the walker slid off)."""
    if len(pts) <= 2:
        return pts
    out, i = [pts[0]], 0
    while i < len(pts) - 1:
        j = len(pts) - 1
        while j > i + 1 and not clear(pts[i], pts[j]):
            j -= 1
        out.append(pts[j])
        i = j
    return out


def main():
    site = Site.load()
    padded = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    terrain = lambda x, y: padded.z(x, y) - site.shift
    decks, feet = load()
    yard = next(d for d in decks if d.id == "SHL-04.yard")
    ax, ay = yard.centre()
    bx, by = END
    L2 = (bx - ax) ** 2 + (by - ay) ** 2

    def off_line(x, y):
        t = np.clip(((x - ax) * (bx - ax) + (y - ay) * (by - ay)) / L2, 0.0, 1.0)
        return np.hypot(x - (ax + t * (bx - ax)), y - (ay + t * (by - ay)))

    decks = [d for d in decks if off_line(*d.centre()) < CORRIDOR]
    lanes = json.load(open(os.path.join(ROOT, "data", "town_lanes.json"), encoding="utf-8"))["lanes"] if os.path.exists(os.path.join(ROOT, "data", "town_lanes.json")) else []
    ground = Ground(terrain, feet, min(ax, bx) - CORRIDOR, min(ay, by) - CORRIDOR, max(ax, bx) + CORRIDOR, max(ay, by) + 10.0,
                    lambda X, Y: off_line(X, Y) < CORRIDOR, lanes, raster=(padded.x0, padded.y1, padded.res))
    adj = {}

    def reach(n):
        """A join's ground end, or the nearest walkable cell within a metre of it (a ladder's foot on a narrow ledge's
        rim is mounted from within 0.9 m of it)."""
        if n[0] != "g" or ground.ok[n[1], n[2]]:
            return n
        best = None
        for di in range(-2, 3):
            for dj in range(-2, 3):
                i, j = n[1] + di, n[2] + dj
                if 0 <= i < ground.ny and 0 <= j < ground.nx and ground.ok[i, j] and abs(ground.z[i, j] - ground.z[n[1], n[2]]) < 0.4:
                    d = di * di + dj * dj
                    if best is None or d < best[0]:
                        best = (d, ("g", i, j))
        return best[1] if best else n

    def link(a, b, cost, piece, kind):
        a, b = reach(a), reach(b)
        adj.setdefault(a, []).append((cost, b, piece, kind))
        adj.setdefault(b, []).append((cost, a, piece, kind))

    for di, d in enumerate(decks):
        if d.parapet > 0.0:
            for ca, gc, cost, piece, kind in ground_joins(di, d, ground):
                link((di,) + ca, ("g",) + gc, cost, piece, kind)
    for lo, hi, cost, piece, kind in wall_joins(ground):
        link(("g",) + lo, ("g",) + hi, cost, piece, kind)
    for ln in lanes:  # up a side lane's flight: from where its treads leave the lane's floor to past its landing
        f = ln["flight"]
        if not f:
            continue
        (fx, fy), (ux, uy) = ln["from"], ln["dir"]
        s_up = f["s"] + max(0.0, ln["z_a"] - f["z"]) / 0.8
        lo = ground.cell(fx + ux * (s_up - 0.6), fy + uy * (s_up - 0.6))
        hi = ground.cell(fx + ux * (ln["length"] + 0.4), fy + uy * (ln["length"] + 0.4))
        if lo and hi:
            link(("g",) + lo, ("g",) + hi, W_GROUND * (ln["length"] - s_up) + 1.0,
                 {"kind": "lane", "lane": ln["id"], "bearing": round(bearing(ux, uy), 1)}, "lane")
    for ai, a in enumerate(decks):
        for bi, b in enumerate(decks):
            if ai != bi and math.hypot(a.cx - b.cx, a.cy - b.cy) < 45.0:
                for ca, cb, cost, piece, kind in deck_joins(a, b):
                    link((ai,) + ca, (bi,) + cb, cost, piece, kind)
    yi = decks.index(yard)
    start = (yi,) + yard.cell_at(0.0, 10.0)
    kinds = {}
    for a_, es in adj.items():
        for c_, b_, piece_, kind_ in es:
            key = ("ground-" if a_[0] == "g" or b_[0] == "g" else "deck-") + kind_
            kinds[key] = kinds.get(key, 0) + 1
    print("rooftop: %d decks, joins %s" % (len(decks), {k: v // 2 for k, v in sorted(kinds.items())}))
    end_deck = min((d for d in decks if d.parapet > 0), key=lambda d: math.hypot(d.centre()[0] - END[0], d.centre()[1] - END[1]))
    ei = decks.index(end_deck)
    s2 = math.sqrt(2.0)
    nbr = [(0, 1, 1.0), (1, 0, 1.0), (0, -1, 1.0), (-1, 0, 1.0), (1, 1, s2), (1, -1, s2), (-1, 1, s2), (-1, -1, s2)]
    gz, gok, gtown, gsteep = ground.z, ground.ok, ground.town, ground.steep

    def search(src, to):
        """The cheapest run of cells from src onto the deck `to`: [(cell, piece, kind)], the first cell's after src."""
        dist, prev = {src: 0.0}, {}
        pq = [(0.0, src)]
        goal = None
        while pq:
            dcur, n = heapq.heappop(pq)
            if dcur > dist.get(n, 1e18):
                continue
            if n[0] == to:
                goal = n
                break
            steps = []
            if n[0] == "g":
                _, i, j = n
                z0 = gz[i, j]
                for di_, dj_, w in nbr:
                    ii, jj = i + di_, j + dj_
                    if 0 <= ii < ground.ny and 0 <= jj < ground.nx and gok[ii, jj] and abs(gz[ii, jj] - z0) <= SLOPE_MAX * w * CELL:
                        steps.append(((W_GROUND if gtown[ii, jj] else W_OPEN) * (STEEP_COST if gsteep[ii, jj] else 1.0) * w * CELL, ("g", ii, jj), None, "walk"))
            else:
                k, i, j = n
                d = decks[k]
                for di_, dj_, w in nbr:
                    ii, jj = i + dj_, j + di_
                    if 0 <= ii < d.nu and 0 <= jj < d.nv and d.free[jj, ii]:
                        steps.append((W_ROOF * w * CELL, (k, ii, jj), None, "walk"))
            steps.extend(adj.get(n, []))
            for c, m, piece, kind in steps:
                nd = dcur + c
                if nd < dist.get(m, 1e18):
                    dist[m] = nd
                    prev[m] = (n, piece, kind)
                    heapq.heappush(pq, (nd, m))
        if goal is None:
            reached = sorted({decks[n[0]].id for n in dist if n[0] != "g"})
            print("rooftop: NO WAY from %s to %s; reached %d of %d decks: %s" % (
                "Dechen-tsang's guest yard" if src == start else decks[src[0]].id, decks[to].id, len(reached), len(decks), reached[:60]))
            sys.exit(1)
        run, n = [], goal
        while n != src:
            p, piece, kind = prev[n]
            run.append((n, piece, kind))
            n = p
        return run[::-1]

    cells, src, via = [], start, []
    for vx, vy in VIA:  # by the roofs it passes, then on to the end
        vd = min((d for d in decks if d.parapet > 0), key=lambda d: math.hypot(d.centre()[0] - vx, d.centre()[1] - vy))
        via.append(vd.id)
        cells += search(src, decks.index(vd))
        src = cells[-1][0]
    cells += search(src, ei)
    goal = cells[-1][0]
    surface = yard.id

    def where(n):
        if n[0] == "g":
            x, y = ground.xy(n[1], n[2])
            return [round(x, 2), round(y, 2), round(float(gz[n[1], n[2]]), 2)]
        d = decks[n[0]]
        x, y = d.world(*d.cell_uv(n[1], n[2]))
        return [round(x, 2), round(y, 2), round(d.z, 2)]

    def clear_on(surf):
        """Whether a straight walk from a to b stays on the surface: on a deck its free cells, on the ground walkable
        cells no steeper than SLOPE_MAX between samples a quarter-metre apart."""
        deck = next((d for d in decks if d.id == surf), None)

        def clear(a, b):
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            n = max(1, int(L / 0.25))
            sx, sy = (-(b[1] - a[1]) / L, (b[0] - a[0]) / L) if L > 0 else (0.0, 0.0)
            for off in (0.0, 0.3, -0.3):  # the line, walkable and gentle; the capsule's sides, walkable
                prev = None
                for k in range(n + 1):
                    x, y = a[0] + (b[0] - a[0]) * k / n + sx * off, a[1] + (b[1] - a[1]) * k / n + sy * off
                    if deck is not None:
                        if deck.cell_at(*deck.local(x, y)) is None and off == 0.0:
                            return False
                        continue
                    c = ground.cell(x, y)
                    if c is None or (ground.steep[c] and not (ground.steep[ground.cell(*a[:2]) or c] and ground.steep[ground.cell(*b[:2]) or c])):
                        return False
                    if off != 0.0:
                        continue
                    h = float(gz[c])
                    if prev is not None and abs(h - prev) > SLOPE_MAX * 0.25 + 0.06:
                        return False
                    prev = h
            return True
        return clear

    def approach(piece):
        """Where a walk meets a ladder square from the ground: on its axis 0.8, 0.6 or 0.4 m behind its foot, the first
        walkable spot level with the foot (the test walker, tests/terrain/s3.gd, starts its climb from there)."""
        if piece is None or piece["kind"] not in ("log", "stair") or piece.get("deck") == "wall":
            return None
        fx, fy, fz = piece["foot"]
        b = math.radians(piece["bearing"])
        for back in (0.8, 0.6, 0.4):
            x, y = fx - math.sin(b) * back, fy - math.cos(b) * back
            c = ground.cell(x, y)
            if c is not None and not ground.steep[c] and abs(float(gz[c]) - fz) < 0.3:
                return [round(x, 2), round(y, 2), round(float(gz[c]), 2)]
        return [fx, fy, fz]

    legs, pieces, kinds = [], [], {}
    run = [where(start)]
    for n, piece, kind in cells:
        if kind == "walk":
            run.append(where(n))
            continue
        legs.append({"on": surface, "points": simplify(run, clear_on(surface))})
        kinds[kind] = kinds.get(kind, 0) + 1
        if piece is not None and surface == "ground" and approach(piece):
            piece = dict(piece, approach=approach(piece))
        if piece is not None and piece["kind"] in ("log", "stair"):  # what its foot stands on: the ground, or a roof
            after = "ground" if n[0] == "g" else decks[n[0]].id
            piece = dict(piece, **{"from": surface if run[-1][2] < where(n)[2] else after})
        legs.append({"by": kind, "piece": piece})
        if piece:
            pieces.append(piece)
        surface = "ground" if n[0] == "g" else decks[n[0]].id
        run = [where(n)]
    legs.append({"on": surface, "points": simplify(run, clear_on(surface))})
    length = lambda pts: sum(math.hypot(q[0] - p[0], q[1] - p[1]) for p, q in zip(pts, pts[1:]))
    roofs = [l["on"] for l in legs if "on" in l and l["on"] not in ("ground", yard.id)]
    ground_m = sum(length(l["points"]) for l in legs if l.get("on") == "ground")
    roof_m = sum(length(l["points"]) for l in legs if "on" in l and l["on"] not in ("ground", yard.id))
    json.dump({"about": "The Rooftop Way (R-06), from tools/town/rooftop.py: its legs in order, walked on a surface (points in the town grid, z the design altitude) or crossed by a piece; and the pieces for world/town.gd (logs and stair-ladders as the ladders: foot, top, bearing, lean; steps: pos, bearing, rise; planks: from, to). Regenerated with the town.",
               "start": where(start), "end": end_deck.id, "legs": legs, "pieces": pieces}, open(OUT, "w"), indent=1)
    gap_parapets(pieces)
    summary = "%d roofs (%d houses), %.0f m on roofs and %.0f m on the ground, climbing %.1f m: %s" % (
        len(roofs), len({r.rsplit(".", 1)[0] for r in roofs}), roof_m, ground_m, end_deck.z - yard.z, ", ".join("%d %s" % (v, k) for k, v in sorted(kinds.items())))
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    lines = ["# The Rooftop Way (R-06)", "",
             "_Written by `tools/town/rooftop.py` (chapter 02, R-06: 260 m, +86 m, 9 ladders, 4 plank bridges, 11 roofs, five short lane stairs). The cheapest way over the town's roofs and lanes from Dechen-tsang's guest yard to V-28's roof, by the roof%s at %s (VIA)._" % ("s" if len(via) > 1 else "", ", ".join(via)), "",
             summary + ".", "", "| # | On | By | Metres | Level at the end (m) |", "|---|---|---|---|---|"]
    for i, l in enumerate(legs):
        if "on" in l:
            lines.append("| %d | %s | walk | %.0f | %.1f |" % (i + 1, l["on"], length(l["points"]), l["points"][-1][2]))
        else:
            lines.append("| %d | | %s | | |" % (i + 1, l["by"]))
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("rooftop: %s -> %s" % (summary, os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
