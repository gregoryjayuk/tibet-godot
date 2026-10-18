#!/usr/bin/env python3
"""The notched logs up to the roofs (plan chapter 02, 5.3; chapter 11, 13.3; M1 sprint 3, step 3): where a town house's
roof can be reached by a log of 2.4-4.2 m set at 60-75 degrees (the kit's lean is 67), from the ground beside it or from
a lower roof next to it (a two-storey house in a terrace is the step to its neighbours' roofs, chapter 03, 3.3), into
assets/generated/terrain/ladders.json for world/town.gd.

For every town house of the builder (data/town_generic.json), each of its walls but the front is walked every 0.5 m,
1.2 m in from its ends; a party wall too, since over a lower neighbour's roof it stands open. The log's top rests on the parapet's outer face at its top; its foot goes out from the
wall 0.8-2.5 m, onto the padded ground (valley_padded_1m.tif) or the roof of a lower house, never inside another
building or what stands by one (a latrine's pit: its type's sidecar lists them, `ground`), and onto level ground (within 0.25 m over 0.4 m round it: a foot on the batter at a cut's top had the player
slide into the trench). A foot is kept when the log would stand at 60-75 degrees, climb 1.5 m or more, be no longer than the longest
log less 0.2 m (it stands a little over the parapet), and clear the ground under it by 0.2 m. The best foot of a wall is
the one nearest 67 degrees; each house keeps its best wall, and no two logs stand within 6 m of each other.
The roof's height is the kit file's own (its CORNER sockets, from the export's sidecar), so the naming here follows
world/town.gd's kit_file for the builder's houses.
Run: tools/py tools/town/ladders.py   (tools/terrain/build.sh runs it after the pads and walls)
"""
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "terrain"))
sys.path.insert(0, os.path.join(ROOT, "tools", "town"))
from terrain_site import Site  # noqa: E402
import builder as B  # noqa: E402  (rect, overlap)
import pads as P  # noqa: E402  (footprint)

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
KIT = os.path.join(ROOT, "assets", "generated", "kit", "types")
OUT = os.path.join(GEN, "ladders.json")
LOGS = [(2.4, "notched_log_24_v1"), (3.0, "notched_log_30_v1"), (3.6, "notched_log_36_v1"), (4.2, "notched_log_42_v1")]
LEAN, LEAN_MIN, LEAN_MAX = 67.0, 60.0, 75.0
PARAPET = 0.45  # over the roof, to the parapet's top (R1 0.4, R2 0.5)
GROW = 0.14  # the crown's coping and parapet stand proud of the wall (kit/roofs.py crown)
BATTER = 0.05  # the walls lean in 5 cm a metre (kit/houses.py)
SPACING = 6.0


def kit_file(h):
    """world/town.gd's kit_file for a builder's house (type B, or type A since kit step K8, or type E on the west edge since
    8 Oct 2026, with a variant)."""
    seed = int(h.get("seed", 1))
    if h.get("type") == "A":
        return "log_house_%s_v%d" % (h["variant"].lower(), seed)
    if h.get("type") == "E":  # the west edge's poor houses (the game's ISS-105), as world/town.gd's "E"
        return "poor_house_e1_v%d" % seed
    name = "town_house_%s" % h["variant"].lower()
    if int(h.get("storeys", 3)) == 2:
        name += "_s2"
        seed = min(seed, 4)  # four variants with two storeys (IMP-019), as world/town.gd
    if "party" in h:
        name += "_" + h["party"]
    return "%s_v%d" % (name, seed)


def roof_height(f):
    """The roof's height over the house's pad: its hatch's (a log house's CORNER sockets stand on its piers)."""
    side = json.load(open(os.path.join(KIT, f + ".json")))
    hatch = [p[2] for n, p in side["socket_pos"].items() if n.startswith("SOCK_HATCH")]
    if hatch:
        return max(hatch)
    corners = [p[2] for n, p in side["socket_pos"].items() if n.startswith("SOCK_CORNER")]  # no hatch (a poor E house): its corners
    return max(corners) if corners else 2.6


ROOF_THINGS = ("SOCK_PIER", "SOCK_FUEL", "SOCK_SANG", "SOCK_POLE", "SOCK_HATCH", "SOCK_FLAG")  # what stands on a roof


def roof_things(h):
    """The things on a house's roof, in the town grid: its corner piers, its fuel stacks, its burner, its poles, its hatch
    (the kit's sockets; M2 sprint 6: a log's foot by a corner pier had the walker up on the pier and stopped there)."""
    side = json.load(open(os.path.join(KIT, kit_file(h) + ".json")))
    x, y, z = h["pos"]
    th = math.radians(h["rot_deg"] - 180.0)
    c, s_ = math.cos(th), math.sin(th)
    return [(x + p[0] * c + p[1] * s_, y - p[0] * s_ + p[1] * c) for n, p in side["socket_pos"].items() if n.startswith(ROOF_THINGS)]


def main():
    site = Site.load()
    ground = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    terrain = lambda x, y: float(ground.z(np.array([x]), np.array([y]))[0]) - site.shift
    houses = json.load(open(os.path.join(ROOT, "data", "town_generic.json"), encoding="utf-8"))["houses"]
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    others = [B.rect(*P.footprint(b), b.get("rot_deg", 180.0), 0.3)  # a named house's walled yard with it (pads.py YARDS)
              for b in town["buildings"] if b.get("pos") and b.get("footprint") and "line" not in b and max(b["footprint"]) <= 80]
    for h in houses:  # what stands on the ground by a house with a box of its own (its sidecar's `ground`: a latrine's pit)
        th = math.radians(h["rot_deg"] - 180.0)
        c, s_ = math.cos(th), math.sin(th)
        for g in json.load(open(os.path.join(KIT, kit_file(h) + ".json"))).get("ground", []):
            others.append([(h["pos"][0] + u * c + v * s_, h["pos"][1] - u * s_ + v * c) for u, v in
                           ((g[0] - 0.3, g[1] - 0.3), (g[2] + 0.3, g[1] - 0.3), (g[2] + 0.3, g[3] + 0.3), (g[0] - 0.3, g[3] + 0.3))])
    roofs = []  # (house, its footprint shrunk inside the parapet, roof z, footprint grown by the eaves)
    for h in houses:
        x, y, z = h["pos"]
        w, d = h["footprint"]
        top = z + roof_height(kit_file(h))
        roofs.append((h, B.rect(x, y, w - 1.4, d - 1.4, h["rot_deg"]), top, B.rect(x, y, w, d, h["rot_deg"], 0.3)))

    def inside(p, quad):
        return B.overlap([(p[0] - 0.01, p[1] - 0.01), (p[0] + 0.01, p[1] - 0.01), (p[0] + 0.01, p[1] + 0.01), (p[0] - 0.01, p[1] + 0.01)], quad)

    def stand(px, py, skip):
        """What a foot at (px, py) stands on: a lower roof, the ground, or None inside a building."""
        for h, inner, top, outer in roofs:
            if h is skip:
                continue
            if inside((px, py), inner):
                return top, h["id"]
            if inside((px, py), outer):
                return None, None
        if any(inside((px, py), q) for q in others):
            return None, None
        return terrain(px, py), "ground"

    # the solid walls and parapets (tools/town/walls.py; IMP-023): a log's foot stands clear of them and the log never
    # crosses one (a log from a yard over its parapet onto the roof below had stopped the player at the parapet)
    segs = []
    if os.path.exists(os.path.join(GEN, "walls.json")):
        for r in json.load(open(os.path.join(GEN, "walls.json")))["runs"]:
            fl = r.get("flags", [0] * len(r["pts"]))
            for k, (a, b) in enumerate(zip(r["pts"][:-1], r["pts"][1:])):
                if fl[k] & 3 and fl[k + 1] & 3:
                    segs.append((a[0], a[1], b[0], b[1]))
    segs = np.array(segs) if segs else np.zeros((0, 4))
    # every wall's top, for a roof foot's run-up (M2 sprint 6: a log from a roof in the ngakpa quarter had its run-up
    # against the top of the uphill house's retaining wall, and the walker stopped short of its foot)
    tops = np.array([(q[0], q[1], q[5]) for r in json.load(open(os.path.join(GEN, "walls.json")))["runs"] for q in r["pts"]]) if os.path.exists(os.path.join(GEN, "walls.json")) else np.zeros((0, 3))

    things = {}

    def runup_clear(fx, fy, ox, oy, g, on, h):
        """A roof foot's run-up, 0.6 and 1.2 m out behind it, and 0.8 m either side of it: on the same roof, at its level, no
        wall's top rising over it (a foot by the lower roof's edge had the walker up on its parapet and stopped there)."""
        if on not in things:
            things[on] = roof_things(next(q for q in houses if q["id"] == on))
        if any(math.hypot(tx_ - fx, ty_ - fy) < 1.6 for tx_, ty_ in things[on]):
            return False  # the lower roof's own things: well clear of its foot
        for qx, qy in ((ox * 0.6, oy * 0.6), (ox * 1.2, oy * 1.2), (ox * 2.2, oy * 2.2), (-oy * 0.8, ox * 0.8), (oy * 0.8, -ox * 0.8),
                       (-oy * 2.0, ox * 2.0), (oy * 2.0, -ox * 2.0)):
            rx, ry = fx + qx, fy + qy
            if any(math.hypot(tx_ - rx, ty_ - ry) < 0.8 for tx_, ty_ in things[on]):
                return False  # and of the walker's way to it, from behind it or along its wall
            sg, son = stand(rx, ry, h)
            if sg is None or son != on or abs(sg - g) > 0.3:
                return False
            if len(tops) and np.any((np.hypot(tops[:, 0] - rx, tops[:, 1] - ry) < 0.7) & (tops[:, 2] > g + 0.3)):
                return False
        return True

    flights = [ln for ln in P.lane_list() if ln.get("flight")]

    def on_flight(fx, fy):
        """Whether (fx, fy) stands on a lane's flight (wall to wall since IMP-023), or within half a metre of it."""
        for ln in flights:
            sl = (fx - ln["from"][0]) * ln["dir"][0] + (fy - ln["from"][1]) * ln["dir"][1]
            lat = -(fx - ln["from"][0]) * ln["dir"][1] + (fy - ln["from"][1]) * ln["dir"][0]
            if ln["flight"]["s"] - 0.8 <= sl <= ln["length"] + 0.3 and abs(lat) <= ln["width"] / 2 + 0.5:
                return True
        return False

    def walled(fx, fy, tx, ty):
        """Whether a log from (fx, fy) to (tx, ty) crosses a solid wall or a parapet, or its foot stands within 0.9 m of one."""
        if not len(segs):
            return False
        ax, ay, bx, by = segs[:, 0], segs[:, 1], segs[:, 2], segs[:, 3]
        dx, dy = bx - ax, by - ay
        t = np.clip(((fx - ax) * dx + (fy - ay) * dy) / np.maximum(dx * dx + dy * dy, 1e-9), 0.0, 1.0)
        if np.any(np.hypot(ax + dx * t - fx, ay + dy * t - fy) < 0.9):
            return True
        ex, ey = tx - fx, ty - fy
        den = ex * dy - ey * dx
        with np.errstate(divide="ignore", invalid="ignore"):
            u = ((ax - fx) * dy - (ay - fy) * dx) / den
            v = ((ax - fx) * ey - (ay - fy) * ex) / den
        return bool(np.any((np.abs(den) > 1e-9) & (u > 0.0) & (u < 1.0) & (v >= 0.0) & (v <= 1.0)))

    found = []
    for h, inner, top, outer in roofs:
        if h.get("type") == "E":  # a poor house's roof of poles, brush and earth (the west edge, ISS-105): not walked on
            continue
        x, y, z = h["pos"]
        w, d = h["footprint"]
        th = math.radians(h["rot_deg"] - 180.0)
        c, s = math.cos(th), math.sin(th)
        roof_h = top - z
        sides = [("back", 0.0, d / 2, w, (0.0, 1.0)), ("left", -w / 2, 0.0, d, (-1.0, 0.0)), ("right", w / 2, 0.0, d, (1.0, 0.0))]
        best = None
        for side, u0, v0, length, (nu, nv) in sides:
            half = (w / 2 if side != "back" else d / 2) - BATTER * roof_h + GROW  # the parapet's outer face, from the middle
            for k in range(int((length - 2.4) / 0.5) + 1):
                t = -length / 2 + 1.2 + k * 0.5
                u, v = (nu * half, t) if side != "back" else (t, nv * half)
                tx, ty = x + u * c + v * s, y - u * s + v * c
                ox, oy = nu * c + nv * s, -nu * s + nv * c  # outward
                tz = top + PARAPET
                for kd in range(18):
                    dist = 0.8 + kd * 0.1
                    fx, fy = tx + ox * dist, ty + oy * dist
                    g, on = stand(fx, fy, h)
                    if g is None:
                        continue
                    if on == "ground" and max(abs(terrain(fx + ex, fy + ey) - g) for ex, ey in ((0.4, 0), (-0.4, 0), (0, 0.4), (0, -0.4))) > 0.25:
                        continue
                    rise = tz - g
                    lean = math.degrees(math.atan2(rise, dist))
                    need = math.hypot(rise, dist) + 0.2
                    if rise < 1.5 or not LEAN_MIN <= lean <= LEAN_MAX or need > LOGS[-1][0]:
                        continue
                    # the ground under the log stays 0.2 m under it (a roof foot has its own roof under it)
                    clear = all((stand(fx - ox * dist * q, fy - oy * dist * q, h)[0] or -1e9) < g + rise * q - 0.2 for q in (0.3, 0.6, 0.85))
                    if not clear or walled(fx, fy, tx, ty) or on_flight(fx, fy):
                        continue
                    if on != "ground" and not runup_clear(fx, fy, ox, oy, g, on, h):
                        continue
                    score = abs(lean - LEAN)
                    if best is None or score < best[0]:
                        log = next(L for L in LOGS if L[0] >= need)
                        bearing = math.degrees(math.atan2(-ox, -oy)) % 360.0  # the way the log leans: from the foot to the wall
                        best = (score, {"house": h["id"], "side": side, "file": log[1], "length": log[0], "from": on,
                                        "foot": [round(fx, 2), round(fy, 2), round(g, 2)], "top": [round(tx, 2), round(ty, 2), round(tz, 2)],
                                        "bearing": round(bearing, 1), "lean": round(lean, 1), "rise": round(rise, 2)})
        if best is not None:
            found.append(best)
    found.sort(key=lambda b: b[0])
    kept = []
    for score, lad in found:
        if all(math.hypot(lad["foot"][0] - k["foot"][0], lad["foot"][1] - k["foot"][1]) >= SPACING for k in kept):
            kept.append(lad)
    json.dump({"about": "Notched logs up to the roofs, from tools/town/ladders.py: foot and top in the town grid (z the design altitude), the bearing it leans towards (from the foot to the wall), its lean from the level. Regenerated with the terrain.",
               "ladders": kept}, open(OUT, "w"), indent=1)
    by = {}
    for lad in kept:
        k = "from a roof" if lad["from"] != "ground" else "from the ground"
        by[k] = by.get(k, 0) + 1
    print("ladders: %d logs to %d of %d houses' roofs %s, climbing %.1f-%.1f m -> %s" % (
        len(kept), len({k["house"] for k in kept}), len(houses), by, min((k["rise"] for k in kept), default=0),
        max((k["rise"] for k in kept), default=0), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
