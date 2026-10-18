#!/usr/bin/env python3
"""Terrain pass 8's ground (plan chapter 11, 8.2 step 8; chapter 02, 2.4's cover in late October; M1 sprint 3, step 6):
the control map that tells the terrain shader what the ground is, a class for every texel of the Terrain3D image
(export_t3d.py's grid: 1 m, rows = Godot z), painted by rules of slope, aspect, elevation and district.

The class is Terrain3D's base texture id, bits 27-31 of each 32-bit control word; the other bits stay 0. The file is
the words' bytes, read by import_t3d.gd as a float image (Terrain3D's control format), and the shader
(shaders/terrain.gdshader, inc/terrain_color.gdshaderinc) colours each class:
  0 wild     the shader's own rules by slope, aspect and altitude: grass, scrub, wood, rock, scree, snow
  1 earth    bare trodden ground: every pad's yard (its apron), the open ground among upper Shöl's and Tödé's houses,
             the caravan ground
  2 barley   barley stubble on the benches along the contour: Tödé's fields below its leat (2,978 m), the monastery
             spur's south flank, patches of the Serchu's north bank
  3 buckwheat  red buckwheat stubble: Pharkha, and a share of Tödé's fields
  4 path     (kept for the routes: chapter 02's routes have no lines yet, ISS-057)
  6 fields   Tödé's fields, barley and buckwheat: the shader picks each strip's crop itself, pixel by pixel, so the
             strips' edges follow the contour smoothly (chosen here per texel, they came out stepped)
  5 paving   stone flags: lower Shöl's lanes (the open ground of Shöl below y = +130, under 30 degrees), Tsongra's two
             levels, Hejie's streets
Fields keep to ground a terrace can hold: Tödé up to 40 degrees ("terraced into benches 3-8 m wide": the heightfield
has no benches, its median slope there is 34 degrees; the shader draws the benches), the monastery's flank 38, Pharkha
35, the Serchu 25. Paving keeps to ground under 15 degrees (lanes are level or stepped), the town's steeper open
ground bare earth, up to 30; steeper ground still stays wild (earth or rock by the shader's rules). A field is a strip
along the contour: three benches (7.2 m of height) deep, about 35 m wide, the strips of one band staggered from the
next (square patches read as a quilt).
Run: tools/py tools/terrain/control.py   (tools/terrain/build.sh runs it after the pads, before export_t3d.py)
Writes assets/generated/terrain/valley_t3d_control.r32 beside the heights, and docs/terrain/control-report.md.
"""
import json
import math
import zlib
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402
import pads as P  # noqa: E402
import sculpt  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
REPORT = os.path.join(ROOT, "docs", "terrain", "control-report.md")
WILD, EARTH, BARLEY, BUCKWHEAT, PATH, PAVING, FIELDS = 0, 1, 2, 3, 4, 5, 6
NAMES = ["wild", "earth", "barley", "buckwheat", "path", "paving", "fields"]
FIELD_MAX, PAVE_MAX = 30.0, 15.0  # degrees: lanes are level or stepped; the town's sloping open ground is bare earth
LEAT = 2978.0  # the top of Tödé's fields (chapter 02, 2.5: TOD-10, the edge of cultivation)
UPPER_SHOL = 130.0  # upper Shöl: unpaved lanes


def hash2(i, j, seed):
    """A repeatable 0..1 per integer cell, for field patches."""
    v = np.sin(i * 127.1 + j * 311.7 + seed * 74.7) * 43758.5453
    return v - np.floor(v)


def main():
    meta = json.load(open(os.path.join(GEN, "valley_t3d.json")))
    W, H, X0, Z0 = meta["width"], meta["height"], meta["x0"], meta["z0"]
    site = Site.load()
    g = site.read(os.path.join(GEN, "valley_padded_1m.tif"))
    xs = X0 + np.arange(W, dtype=np.float64)
    ys = -(Z0 + np.arange(H, dtype=np.float64))  # town grid y (north) of each row
    inside_x = (xs > g.x0 + 2) & (xs < g.x1 - 2)
    inside_y = (ys > g.y0 + 2) & (ys < g.y1 - 2)
    cls = np.zeros((H, W), dtype=np.uint8)
    ri = np.where(inside_y)[0]
    ci = np.where(inside_x)[0]
    GX, GY = np.meshgrid(xs[ci], ys[ri])
    z = g.z(GX, GY) - site.shift  # design altitude
    # slope and aspect from the 1 m heights (rows run south, columns east)
    dzdy_row, dzdx = np.gradient(z)  # per row (southwards) and per column (eastwards), metres per metre
    dzdy = -dzdy_row  # northwards
    slope = np.degrees(np.arctan(np.hypot(dzdx, dzdy)))
    # districts from chapter 02's plan, on a 5 m grid, then per texel by the nearest cell
    plan = sculpt.plan_map()
    dxs = np.arange(xs[ci][0], xs[ci][-1] + 5, 5.0)
    dys = np.arange(ys[ri][-1], ys[ri][0] + 5, 5.0)
    dg = sculpt.district_grid(plan, dxs, dys)
    di = np.clip(np.round((GY - dys[0]) / 5.0).astype(int), 0, len(dys) - 1)
    dj = np.clip(np.round((GX - dxs[0]) / 5.0).astype(int), 0, len(dxs) - 1)
    dist = dg[di, dj]
    sub = np.zeros(GX.shape, dtype=np.uint8)
    gentle = slope < FIELD_MAX
    # fields: Tödé below its leat, a third of its fields buckwheat (by field, 40 m patches); Pharkha buckwheat; the
    # monastery spur's south flank barley; the Serchu's north bank a patch in three
    band = np.floor(z / 7.2)
    patch = hash2(np.floor(GX / 35.0 + 0.37 * band), band, 3.0)  # the Serchu's patches (Tödé's strips: the shader)
    south = dzdy / np.maximum(np.hypot(dzdx, dzdy), 1e-6)  # +1 where the ground falls to the south (rises to the north;
    # until 10 Oct 2026 its sign was turned, and the monastery spur's south flank, which faces south, had no barley)
    tode = (dist == "t") & (slope < 40.0) & (z < LEAT)
    sub[tode] = FIELDS
    sub[(dist == "p") & (slope < 35.0)] = BUCKWHEAT
    sub[(dist == "m") & (slope < 38.0) & (south > 0.6) & (z < 2960.0)] = BARLEY
    serchu = (dist == "y") & (slope < 25.0) & (patch < 0.33)
    sub[serchu] = BARLEY
    # the monastery's barley terraces SER-17 on the spur's south flank above the Serchu's mills (tools/town/serchu_mills.py
    # `fields`; M2 sprint 12, step 5): above the leat, below the flank's top, where a bench will hold
    sm = os.path.join(ROOT, "data", "serchu_mills.json")
    if os.path.exists(sm):
        fl = json.load(open(sm, encoding="utf-8"))["fields"]
        ab = np.array(fl["above"], float)
        above = np.interp(GX, ab[:, 0], ab[:, 1])  # (past the leat's ends, its end's)
        sub[(GX >= fl["x"][0]) & (GX <= fl["x"][1]) & (GY > above) & (z > fl.get("bottom", 0.0)) & (z < fl["top"]) & (slope < fl["slope"]) & (south > 0.3)] = BARLEY
    # the caravan ground, trampled
    sub[(dist == "c") & gentle] = EARTH
    # the town: lower Shöl's and Hejie's open ground paved; upper Shöl's and Tödé's near its houses bare earth
    town_low = (dist == "s") & (GY < UPPER_SHOL) | (dist == "h")
    sub[town_low & (slope < FIELD_MAX)] = EARTH
    sub[town_low & (slope < PAVE_MAX)] = PAVING
    EARTHEN = {"SAM-09"}  # the ula yard (M2 sprint 11, step 3): its animals' trampled earth
    # every pad's yard (its footprint and apron, and a builder's house's yard before its front) bare earth, one
    # household's in three flagged (IMP-023); Tsongra's two levels paved
    pads = P.pad_list((g.x0, g.x1, g.y0, g.y1))
    yds = P.yards()
    near_house = np.zeros(GX.shape, dtype=bool)
    x0g, y0g = GX[0, 0], GY[0, 0]  # the window's first column and row (rows run south)
    for pid, px, py, pz, fw, fd, rot in pads:
        th = math.radians(rot - 180.0)
        c, s = math.cos(th), math.sin(th)
        r = math.hypot(fw, fd) / 2 + yds.get(pid, 0.0) + P.APRON + 6.0
        j0, j1 = int(max(0, px - r - x0g)), int(min(GX.shape[1], px + r - x0g + 1))
        i0, i1 = int(max(0, y0g - (py + r))), int(min(GX.shape[0], y0g - (py - r) + 1))
        if j1 <= j0 or i1 <= i0:
            continue
        lx = GX[i0:i1, j0:j1] - px
        ly = GY[i0:i1, j0:j1] - py
        u = lx * c - ly * s  # along the facade
        v = lx * s + ly * c  # along the depth
        du = np.abs(u) - fw / 2
        dv = np.abs(v) - fd / 2
        dout = np.hypot(np.maximum(du, 0), np.maximum(dv, 0))
        yard = P.pad_dist(fw, fd, yds.get(pid, 0.0), u, v)[0] <= P.APRON
        win = sub[i0:i1, j0:j1]
        if pid.startswith("SHL-01") or (pid in yds and zlib.crc32(pid.encode()) % 3 == 0):
            win[yard] = PAVING
        elif pid in EARTHEN:  # trampled by beasts, never flagged
            win[yard] = EARTH
        else:
            win[yard & (win != PAVING)] = EARTH
        near_house[i0:i1, j0:j1] |= dout <= P.APRON + 6.0
    upper = ((dist == "s") & (GY >= UPPER_SHOL) | (dist == "t")) & near_house & gentle & (sub != PAVING)
    sub[upper] = EARTH
    for ln in P.ramp_lanes():  # the lane through upper Shöl's gardens to the Gorge Rim Lookout (tools/town/gardens.py):
        # trodden; the Caravan Ramp (tools/town/caravan_ground.py `road`) bare trodden earth, the camp's own; Hejie's River
        # Street (tools/town/hejie.py `street`) paved
        if not (ln.get("garden") or ln.get("road") or ln.get("street") or ln.get("steps")):  # (and the 1,080 steps' flights
            continue  # and landings, paved, their stones the kit's: tools/town/dungrong.py)
        (fx, fy), (ux, uy) = ln["from"], ln["dir"]
        sl = (GX - fx) * ux + (GY - fy) * uy
        lat = -(GX - fx) * uy + (GY - fy) * ux
        sub[(sl >= -0.5) & (sl <= ln["length"] + 0.5) & (np.abs(lat) <= ln["width"] / 2 + 0.3)] = EARTH if ln.get("road") else (PAVING if (ln.get("street") or ln.get("steps")) else PATH)
    for name in ("serchu_road.json", "serchu_mills.json", "../assets/generated/terrain/forest.json"):  # the Serchu road's
        # paths, trodden (M2 sprint 12, step 3): the durtro path up from its cairn, the way down to the gold washings; the
        # mills' doors down to the Yak Road (step 5); the woodcutters' down from the Shade Wood (step 6)
        sr = os.path.normpath(os.path.join(ROOT, "data", name))
        if not os.path.exists(sr):
            continue
        for line in json.load(open(sr, encoding="utf-8")).get("paths", []):
            for (ax, ay), (bx, by) in zip(line[:-1], line[1:]):
                L = math.hypot(bx - ax, by - ay)
                ux, uy = (bx - ax) / L, (by - ay) / L
                sl = (GX - ax) * ux + (GY - ay) * uy
                lat = -(GX - ax) * uy + (GY - ay) * ux
                sub[(sl >= -0.6) & (sl <= L + 0.6) & (np.abs(lat) <= 0.6)] = PATH
    cls[np.ix_(ri, ci)] = sub
    words = (cls.astype(np.uint32) << 27)
    words.astype("<u4").tofile(os.path.join(GEN, "valley_t3d_control.r32"))
    counts = {NAMES[k]: int((cls == k).sum()) for k in range(len(NAMES))}
    ha = {k: v / 10000.0 for k, v in counts.items()}
    lines = ["# Control report: terrain pass 8's ground", "",
             "_Written by `tools/terrain/control.py` (plan chapter 11, 8.2 step 8; chapter 02, 2.4). The class of every texel of the Terrain3D image, by rules of slope, aspect, elevation and district; the terrain shader colours each._", "",
             "| Class | Hectares |", "|---|---|"] + ["| %s | %.1f |" % (k, v) for k, v in ha.items()]
    open(REPORT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("control: %s ha -> %s" % (", ".join("%s %.1f" % (k, v) for k, v in ha.items() if v > 0), os.path.relpath(os.path.join(GEN, "valley_t3d_control.r32"), ROOT)))


if __name__ == "__main__":
    main()
