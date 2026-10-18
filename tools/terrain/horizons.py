#!/usr/bin/env python3
"""Terrain pass 6, the horizon constraints (plan chapter 11, 8.2; chapter 02, 2.7, 2.8 and 7; PLAN step 8.3).

The skyline is part of the design. Chapter 02's table 2.8 gives each of eight places an east horizon along the
sunrise (azimuth 104-112 degrees on the default day) and a west horizon along the sunset (246-256), and its first and
last sun follow from them; three viewpoints name what must be clear: V-02, the first sun straight down the Serchu, 8
degrees up; V-05, Dungri Karpo over the gorge from the Tsokchen roof, 11 up; V-13, Dungri Karpo in the gorge's notch
from the Gorge Rim Lookout, 11.7 up. Each is a cone from the place: inside its wedge of bearings and beyond its nearest
distance, the ground must stay under the angle. The table's horizons are the far ones, so they start at 300 m: the
town's own walls and banks a stone's throw away are not terrain to cut. The views start at 30 m.
Where the ground rises through a cone it is lowered, and the lowering is spread with a broad Gaussian, so a ridge sinks
as a ridge and does not get a notch. The town is never lowered: nothing within 80 m of a named place (the design's
floors), and each constrained place keeps its own spot, 10 m round, whose drop would raise its own horizon. One field of lowering is laid on both the valley map (1 m) and the ring (30 m, to
15 km), so where they hand over at the map's edge they still agree. The report says how far each constraint moved the
ground (chapter 11: "reports how far it moved reality").
Nothing is raised: a horizon lower than the design's gives an earlier first sun or a later last one, which the sun
report shows. Minya Konka must stay hidden (5 degrees on bearings 121-142 from every point of the valley map); the
report re-checks it from three places.
Run: tools/py tools/terrain/horizons.py   Reads valley_sculpted_1m.tif (sculpt.py) and ring_30m.tif; writes
valley_shaped_1m.tif, ring_shaped_30m.tif and docs/terrain/horizons-report.md. The check, horizon and export tools
read them with VALLEY=valley_shaped_1m RING=ring_shaped_30m.
"""
import json
import math
import os
import sys

import numpy as np
import rasterio
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Grid, Site  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
REPORT = os.path.join(ROOT, "docs", "terrain", os.environ.get("HORIZONS_REPORT", "horizons-report.md"))
R_EARTH, K_REFR = 6371000.0, 0.13
STEP = 10.0  # metres per cell of the lowering field
HALF = 15000.0  # the ring's half-width
SPREAD_VALLEY, SPREAD_RING = 40.0, 250.0  # the Gaussian's sigma inside the valley map and beyond it (m)
# Greg, 25 Sep 2026, 22:14: "Keep the real mountains". Meeting table 2.8 to the letter would have lowered 110 km² of
# real ground by up to 765 m and still met only half of it (the town's own buildings stand in some of its views), so
# the pass shapes only near the valley, and the table is recomputed from the terrain (PLAN step 8.5).
REACH = float(os.environ.get("REACH", "2000"))  # the farthest ground a constraint may lower (m)
CAP = float(os.environ.get("CAP", "250"))  # the most any ground is lowered (m)
SUFFIX = os.environ.get("SUFFIX", "shaped")  # the outputs: valley_<SUFFIX>_1m.tif, ring_<SUFFIX>_30m.tif

# (name, x, y, eye above the ground or None for an absolute height, absolute height, bearings, angle, nearest metres)
EAST, WEST = (103.0, 113.0), (245.0, 257.0)
PLACES = [  # chapter 02, table 2.8 (the Laptse La and Dungri Karpo's summit are the high zone's and the ring's)
    ("Ritro", 1080, 400, 1.6, 3.0, 3.0),
    ("Labrang and the gilded roofs", 620, 215, 20.0, 5.0, 7.0),
    ("Upper Tödé, Tathang", 300, 700, 1.6, 7.0, 8.0),
    ("Confluence pool", 210, -95, 1.6, 8.0, 12.0),
    ("Tsongra", 0, 0, 1.6, 10.0, 13.0),
    ("Hejie River Street", -463, -95, 1.6, 13.0, 15.0),
    ("The Landing", -480, -60, 1.6, 13.0, 16.0),
    ("Pharkha bluff", -760, -120, 1.6, 8.0, 20.0),
]
VIEWS = [  # chapter 02, 7: (name, x, y, eye, bearings, the angle the ground must stay under, nearest metres)
    ("V-02 Conch Eddy, first sun down the Serchu", 190, -90, 1.6, (104.0, 113.0), 8.0, 30.0),
    # Dungri Karpo at 034 from the Gorge Rim Lookout on the gorge's rim, its notch on the real ground, chapter 02's distance and
    # height kept (M2 sprint 6, step 4; DECISIONS, 9 Oct 2026: at 040 from (215, 215) the cone had lowered the mountains by
    # up to 319 m and still failed)
    ("V-05 Tsokchen roof, Dungri Karpo", 540, 150, 21.0, (030.0, 036.0), 10.5, 30.0),
    ("V-13 Gorge Rim Lookout, the notch", 258, 245, 1.6, (031.0, 037.0), 11.2, 30.0),
]


def drop(d):
    return d * d * (1.0 - K_REFR) / (2.0 * R_EARTH)


def constraints():
    out = []
    for name, x, y, eye, east, west in PLACES:
        out.append((name + ", east", x, y, eye, EAST, east, 300.0))
        out.append((name + ", west", x, y, eye, WEST, west, 300.0))
    for name, x, y, eye, bearings, angle, near in VIEWS:
        out.append((name, x, y, eye, bearings, angle, near))
    return out


def horizon(z_at, x, y, z_eye, bearings, near):
    """The highest angle of the ground over the bearings, from `near` metres out to the ring's edge; and where."""
    best = (-90.0, 0.0, 0.0)
    d = np.concatenate([np.arange(near, 2000.0, 2.0), 2000.0 * 1.004 ** np.arange(0, int(math.log(HALF / 2000.0) / math.log(1.004)))])
    for az in np.arange(bearings[0], bearings[1] + 0.01, 1.0):
        b = math.radians(az)
        zt = z_at(x + d * math.sin(b), y + d * math.cos(b))
        a = np.degrees(np.arctan2(np.where(np.isfinite(zt), zt, -1e9) - z_eye - drop(d), d))
        k = int(np.argmax(a))
        if a[k] > best[0]:
            best = (float(a[k]), float(d[k]), float(az))
    return best


def main():
    site = Site.load()
    shift = site.shift
    valley = site.read(os.path.join(GEN, os.environ.get("VALLEY", "valley_sculpted_1m") + ".tif"))
    ring = site.read(os.path.join(GEN, "ring_30m.tif"))
    vx0, vx1, vy0, vy1 = valley.x0, valley.x1, valley.y0, valley.y1

    def z_at(x, y, v=valley, r=ring):
        z = np.asarray(v.z(x, y), np.float64)
        m = np.isnan(z)
        if m.any():
            z[m] = r.z(np.asarray(x)[m], np.asarray(y)[m])
        return z - shift

    # The field of heights and lowering on a 10 m grid over the ring.
    xs = np.arange(-HALF + STEP / 2, HALF, STEP)
    ys = np.arange(HALF - STEP / 2, -HALF, -STEP)  # rows north to south
    gx, gy = np.meshgrid(xs, ys)
    zg = np.full(gx.shape, np.nan)
    inside = (gx > vx0) & (gx < vx1) & (gy > vy0) & (gy < vy1)
    zg[inside] = valley.z(gx[inside], gy[inside]) - shift
    zg[~inside] = ring.z(gx[~inside], gy[~inside]) - shift
    # The town is not lowered: every named floor, 80 m round, fading to 200 m; each constrained place 10 m round.
    town = json.load(open(os.path.join(ROOT, "data", "town.json"), encoding="utf-8"))
    origins = {(c[1], c[2]) for c in constraints()}
    floors = [(b["pos"][0], b["pos"][1]) for b in town["buildings"] if b.get("pos") and b["pos"][2] is not None
              and vx0 < b["pos"][0] < vx1 and vy0 < b["pos"][1] < vy1]
    floors = [p for p in floors if min(math.hypot(p[0] - o[0], p[1] - o[1]) for o in origins) > 20.0]
    free = np.ones(gx.shape, bool)
    for fx, fy in floors:
        i0, i1 = int((ys[0] - (fy + 200)) / STEP), int((ys[0] - (fy - 200)) / STEP) + 1
        j0, j1 = int((fx - 200 - xs[0]) / STEP), int((fx + 200 - xs[0]) / STEP) + 1
        free[max(i0, 0):i1, max(j0, 0):j1] &= np.hypot(gx[max(i0, 0):i1, max(j0, 0):j1] - fx, gy[max(i0, 0):i1, max(j0, 0):j1] - fy) > 80.0
    d_floor = ndimage.distance_transform_edt(free) * STEP
    protect = np.clip((d_floor - 0.0) / 120.0, 0.0, 1.0)  # 0 within 80 m (the mask), 1 by 200 m
    protect = protect * protect * (3 - 2 * protect)
    for ox, oy in origins:
        protect *= np.clip((np.hypot(gx - ox, gy - oy) - 10.0) / 30.0, 0.0, 1.0)
    need = np.zeros(gx.shape)
    rows = []
    for name, x, y, eye, bearings, angle, near in constraints():
        z_eye = float(z_at(np.array([x]), np.array([y]))[0]) + eye
        before = horizon(z_at, x, y, z_eye, bearings, near)
        dx, dy = gx - x, gy - y
        dist = np.hypot(dx, dy)
        az = np.degrees(np.arctan2(dx, dy)) % 360.0
        half = (bearings[1] - bearings[0]) / 2.0
        mid = (bearings[0] + half) % 360.0
        off = np.abs((az - mid + 180.0) % 360.0 - 180.0)
        lateral = np.maximum(half + 1.0, np.degrees(np.arctan2(40.0, np.maximum(dist, 1.0))))  # at least 40 m wide
        wedge = (off <= lateral) & (dist >= near) & (dist <= REACH)
        cone = z_eye + dist * math.tan(math.radians(angle)) - drop(dist)
        excess = np.where(wedge, zg - cone, 0.0) * protect
        need = np.maximum(need, excess)
        rows.append([name, x, y, bearings, angle, near, before, float(np.nanmax(np.where(wedge, excess, 0.0)))])
    need = np.minimum(np.nan_to_num(np.maximum(need, 0.0)), CAP)
    # Spread it: dilate by the Gaussian's reach, then blur, so the lowering covers what it must and fades out.
    sig = np.where(inside, SPREAD_VALLEY, SPREAD_RING) / STEP
    low_v = ndimage.gaussian_filter(ndimage.maximum_filter(need, size=int(2 * SPREAD_VALLEY / STEP) + 1), SPREAD_VALLEY / STEP)
    low_r = ndimage.gaussian_filter(ndimage.maximum_filter(need, size=int(2 * SPREAD_RING / STEP) + 1), SPREAD_RING / STEP)
    # inside the map the narrow spread, beyond it the broad one, handed over across the valley's 250 m edge band
    ex = np.minimum(np.minimum(gx - vx0, vx1 - gx), np.minimum(gy - vy0, vy1 - gy))
    t = np.clip(ex / 250.0, 0.0, 1.0)
    t = np.where(inside, t * t * (3 - 2 * t), 0.0)
    low = np.minimum(np.maximum(need, low_v * t + low_r * (1 - t)), CAP) * protect
    del sig

    # Apply to the valley (1 m) and the ring (30 m).
    def lowering_at(px, py):
        c = (px - xs[0]) / STEP
        r = (ys[0] - py) / STEP
        return ndimage.map_coordinates(low, [r, c], order=1, mode="nearest")

    h, w = valley.a.shape
    vxs = vx0 + (np.arange(w) + 0.5) * valley.res
    vys = vy1 - (np.arange(h) + 0.5) * valley.res
    new_v = valley.a.copy()
    for r0 in range(0, h, 256):
        cc, rr = np.meshgrid(vxs, vys[r0:r0 + 256])
        new_v[r0:r0 + 256] -= lowering_at(cc, rr)
    rh, rw = ring.a.shape
    rxs = ring.x0 + (np.arange(rw) + 0.5) * ring.res
    rys = ring.y1 - (np.arange(rh) + 0.5) * ring.res
    cc, rr = np.meshgrid(rxs, rys)
    new_r = ring.a - lowering_at(cc, rr)

    for src_name, arr, out_name in (("valley_1m", new_v, "valley_%s_1m" % SUFFIX), ("ring_30m", new_r, "ring_%s_30m" % SUFFIX)):
        with rasterio.open(os.path.join(GEN, src_name + ".tif")) as src:
            prof, tags = src.profile, src.tags()
        with rasterio.open(os.path.join(GEN, out_name + ".tif"), "w", **prof) as f:
            f.write(arr.astype(np.float32), 1)
            f.update_tags(**tags)

    # The report: each constraint before and after, how far the ground moved, and Minya Konka.
    nv = Grid(new_v, (valley.x0, valley.x1, valley.y0, valley.y1, valley.res))
    nr = Grid(new_r, (ring.x0, ring.x1, ring.y0, ring.y1, ring.res))
    z_new = lambda x, y: z_at(x, y, nv, nr)
    out = ["# Horizons report: terrain pass 6", "",
           "_Written by `tools/terrain/horizons.py` (plan chapter 11, 8.2 pass 6) from the sculpted valley (`sculpt.py`) and the real ring. Angles include the earth's curvature and refraction (k = 0.13); the eye is 1.6 m above the ground (the gilded roofs 20 m, the Tsokchen roof 21 m). Table 2.8's horizons are read from 300 m out, the views from 30 m._", "",
           "| Constraint | From | Bearings | Wanted under | Before | After | Most lowered |", "|---|---|---|---|---|---|---|"]
    for name, x, y, bearings, angle, near, before, most in rows:
        z_eye = float(z_new(np.array([x]), np.array([y]))[0]) + next(c[3] for c in constraints() if c[0] == name)
        after = horizon(z_new, x, y, z_eye, bearings, near)
        out.append("| %s | %+d, %+d | %03.0f-%03.0f° | %.1f° | %.1f° at %.2f km (%03.0f°) | %.1f° | %.0f m |" % (
            name, x, y, bearings[0], bearings[1], angle, before[0], before[1] / 1000, before[2], after[0], most))
    moved = low[low > 1.0]
    out += ["", "**How far the ground moved.** %.1f km² lowered by more than a metre, %.1f km² by more than 50 m, %.1f km² by more than 200 m; the most, %.0f m. Inside the valley map %.2f km² moved more than a metre." % (
        moved.size * STEP * STEP / 1e6, (low > 50).sum() * STEP * STEP / 1e6, (low > 200).sum() * STEP * STEP / 1e6, float(low.max()),
        (low[inside] > 1).sum() * STEP * STEP / 1e6)]
    k = np.unravel_index(int(np.argmax(low)), low.shape)
    out.append("The deepest cut is at (%+.0f, %+.0f), %.1f km from Tsongra at bearing %03.0f°." % (
        gx[k], gy[k], math.hypot(gx[k], gy[k]) / 1000, math.degrees(math.atan2(gx[k], gy[k])) % 360))
    out += ["", "**Minya Konka stays hidden** (the ground at least 5° high on every bearing 121-142° from the valley map):"]
    for name, x, y, eye in (("Tsongra", 0, 0, 1.6), ("Tsokchen roof", 540, 150, 21.0), ("Tathang", 300, 700, 1.6)):
        z_eye = float(z_new(np.array([x]), np.array([y]))[0]) + eye
        lowest = min(horizon(z_new, x, y, z_eye, (b, b), 1.0)[0] for b in range(121, 143))
        out.append("- %s: lowest %.1f° (%s)." % (name, lowest, "hidden" if lowest >= 5.0 else "**visible**"))
    open(REPORT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
