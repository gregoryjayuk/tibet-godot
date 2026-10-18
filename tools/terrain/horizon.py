#!/usr/bin/env python3
"""The horizon map (plan chapter 11, 6.3; chapter 09, 10.2; spike S12; art step A8).

A shadow map reaches 120-160 m; the western ridge that takes the town's sun at 16:10 is 4 km away. So every lit shader
reads the terrain's horizon from this map instead: for each sample of a grid, the tangent of the elevation angle of
the highest ground in each of 32 azimuth sectors (sector k looks along the design's bearing k x 11.25 deg), seen from
eyes 1, 4, 10, 20 and 40 m above the ground. A fragment's horizon at its own height above the ground is the chord
between the two knots either side, in tangents (the horizon's tangent falls with height as the upper envelope of
straight lines, so it is convex, and five knots hold it to 0.05 deg on average and 0.17 deg at the 95th percentile
over the core, heights 1-30 m; two knots missed by up to 6 deg on Labrang's steep ground, as angles or as sight
lines). The shader (shaders/inc/horizon.gdshaderinc) does that for the two sectors either side of the light,
interpolates between them, and cuts the direct light where the sun, or the moon, is below the horizon. Angles, not
times, so the map is right on every date.

Four grids, the finest that covers a point wins: the confluence (`fine`, 130 x 100 m round C at 2 m and 256 sectors:
the Golden Slot's notch, through which its first sun comes, fell between the core's rays; M2 sprint 5), the core
(chapter 02's x -500 to +1,150, y -320 to +1,080) at 4 m,
the valley map at 16 m, and the ring to 15 km at 128 m (the ring's mountains would otherwise stay lit beside a
shadowed valley; the ring has only terrain, so it keeps only the 1 m eye). Rays march over the real ground (fetch.py's valley map, near ring and far ring, the finest that
covers each point) to 100 km, with the earth's curvature and refraction (k = 0.13) as terrain_check.py measures, and
stop early where no ground could rise above the angle already found.

Written to assets/generated/terrain/ (not versioned; world/horizon.gd loads them):
  horizon_<grid>.bin  float16, [layer][row][column][4], rows north to south: for each eye in turn, eight layers of
                      the 32 sectors' horizon tangents (sector 4l + c in layer l, channel c); then one layer with
                      the ground's Godot height (real - shift - 2,662 - the curvature drop from Tsongra) in R.
                      The core and the valley have 41 layers (five eyes), the ring 9 (one)
  horizon.json        the grids' windows, the sectors, the eye heights, the site
Then the check (spike S12): the first and last sun of chapter 02's table 2.8 on the default day (28 October 1903),
read through the map as the shaders read it and by a direct ray at the sun's own azimuth, against the table's times;
written to docs/terrain/sun-report.md. The map must agree with the direct rays within a minute; the real ground's
times against the design's say what the sculpting passes must do (docs/ISSUES.md, ISS-031).
Run: nice -n 10 tools/py tools/terrain/horizon.py   [--check] (the check only, from the last bake)
"""
import datetime
import json
import math
import os
import sys
from concurrent.futures import ProcessPoolExecutor

import numpy as np

from terrain_site import Site

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "tools", "calendar"))
import sky  # noqa: E402

GEN = os.path.join(ROOT, "assets", "generated", "terrain")
VALLEY = os.environ.get("VALLEY", "valley_1m")  # valley_sculpted_1m: the ground after passes 2-3 (sculpt.py)
RING = os.environ.get("RING", "ring_30m")  # ring_shaped_30m: the ring after pass 6 (horizons.py)
REPORT = os.path.join(ROOT, "docs", "terrain", os.environ.get("SUN_REPORT", "sun-report.md"))
OUTDIR = os.environ.get("HORIZON_DIR", GEN)  # where the map is baked and read back: a scratch folder for a trial ground
SCULPTED = VALLEY != "valley_1m"
GROUND = ("the shaped ground (`%s`, `%s`: `tools/terrain/build.sh`, passes 2-6; `docs/terrain/sculpt-report.md`, `horizons-report.md`, `pads-report.md`)" % (VALLEY, RING) if SCULPTED
          else "the real ground (the base pass, before any sculpting; `docs/terrain/base-report.md`)")
R_EARTH, K_REFR, DATUM = 6371000.0, 0.13, 2662.0
SECTORS = 32
EYES = (1.0, 4.0, 10.0, 20.0, 40.0)  # metres above the ground: the knots of the chord
GROUPS = SECTORS // 4  # layers per eye
GRID_SECTORS = {"fine": 256}  # a grid's own sectors, where not SECTORS


def sectors(name):
    return GRID_SECTORS.get(name, SECTORS)


def groups(name):
    return sectors(name) // 4
D_MAX = 100000.0
GRIDS = {  # name: x0 (west edge), y1 (north edge), spacing, columns, rows, eyes; in the design's frame
    # the confluence (M2 sprint 5, step 6; chapter 08, V-02): the first sun comes up the Golden Slot's narrow notch, which
    # fell between the core's rays 11.25 degrees apart (its first sun 26 minutes late through the map): 2 m and 256
    # sectors over C, the pool, the Conch terrace, the Conch Fall and Pema Ö
    "fine": (150.0, -40.0, 2.0, 65, 50, EYES),
    "core": (-500.0, 1080.0, 4.0, 413, 350, EYES),
    "valley": (-1350.0, 1100.0, 16.0, 229, 138, EYES),
    "ring": (-15040.0, 15040.0, 128.0, 235, 235, EYES[:1]),
}
DAY = datetime.date(1903, 10, 28)  # the default day (autoload/world_clock.gd), the day table 2.8 describes
# Chapter 02, table 2.8: place, x, y (the gazetteer's or the viewpoints' positions), eye above the ground, first and
# last sun. The gilded roofs are read at roof height; Dungri Karpo's summit where tools/terrain/peak.py raised it (M2
# sprint 6, step 5: the invented peak, at 032.5 degrees from the Gorge Rim Lookout).
PLACES = [
    ("Dungri Karpo summit", 7081, 10956, 1.6, "06:10", "17:17"),
    ("Laptse La", 4760, 2750, 1.6, "06:12", "17:15"),
    ("Ritro (Guru Drubphuk, RIT-01)", 1080, 400, 1.6, "06:28", "16:59"),
    ("Labrang and the gilded roofs", 620, 215, 20.0, "06:38", "16:40"),
    ("Upper Tödé, Tathang", 300, 700, 1.6, "06:48", "16:35"),
    ("Confluence pool, Pema Ö", 210, -95, 1.6, "06:52", "16:15"),
    ("Tsongra", 0, 0, 1.6, "07:02", "16:10"),
    ("Hejie River Street (the Water Gate, HEJ-03)", -463, -95, 1.6, "07:17", "16:00"),
    ("The Landing (FER-01)", -480, -60, 1.6, "07:17", "15:55"),
    ("Pharkha bluff (V-03)", -760, -120, 1.6, "06:52", "15:34"),
]
GATES = {"Tsongra": 3.0, "Labrang and the gilded roofs": 3.0}  # art step A8 (chapter 09, 16): +-3 min


class Heights:
    """Real ground z(x, y) at design points, bilinear, from the finest raster that covers each point; NaN beyond."""

    def __init__(self, site):
        self.grids = [site.read(os.path.join(GEN, n + ".tif")) for n in (VALLEY, RING, "far_90m")]
        for g in self.grids:
            g.a = g.a.astype(np.float32)
        self.zmax = max(float(np.nanmax(g.a)) for g in self.grids)

    def __call__(self, x, y):
        x, y = np.asarray(x, np.float64), np.asarray(y, np.float64)
        z = np.asarray(self.grids[0].z(x, y), np.float64)
        for g in self.grids[1:]:
            m = np.isnan(z)
            if not m.any():
                break
            z[m] = g.z(x[m], y[m])
        return z


def drop(d):
    return d * d * (1.0 - K_REFR) / (2.0 * R_EARTH)


def steps():
    """Ray distances: every 4 m to 400 m, then 1 % further each step."""
    d, out = 4.0, []
    while d <= D_MAX:
        out.append(d)
        d += max(4.0, d * 0.01)
    return np.array(out)


def layers(name):
    return groups(name) * len(GRIDS[name][5]) + 1


def centres(name):
    x0, y1, res, cols, rows, _ = GRIDS[name]
    xs = x0 + (np.arange(cols) + 0.5) * res
    ys = y1 - (np.arange(rows) + 0.5) * res
    return np.meshgrid(xs, ys)  # rows north to south, columns west to east


_H = None


def _init():
    global _H
    _H = Heights(Site.load())


def march(task):
    """One grid's horizon in one sector: (name, k, [the tangent of the horizon angle, rows x cols] per eye)."""
    name, k = task
    X, Y = centres(name)
    x, y = X.ravel(), Y.ravel()
    z0 = _H(x, y)
    b = math.radians(k * 360.0 / sectors(name))
    sb, cb = math.sin(b), math.cos(b)
    eyes = [z0 + e for e in GRIDS[name][5]]
    best = [np.full(x.shape, -90.0) for _ in eyes]
    active = np.isfinite(z0)
    for d in steps():
        idx = np.nonzero(active)[0]
        if idx.size == 0:
            break
        zt = _H(x[idx] + d * sb, y[idx] + d * cb)
        ok = np.isfinite(zt)
        dr = drop(d)
        for bi, e in zip(best, eyes):
            a = np.degrees(np.arctan2(np.where(ok, zt, -1e9) - e[idx] - dr, d))
            bi[idx] = np.maximum(bi[idx], a)
        # Beyond this step no ground rises above the highest in the rasters: stop where that is below the angle found.
        dn = d + max(4.0, d * 0.01)
        bound = np.degrees(np.arctan2(_H.zmax - eyes[0][idx] - drop(dn), dn))
        active[idx] = best[0][idx] < bound
    return name, k, [np.tan(np.radians(np.maximum(bi, -45.0))).reshape(X.shape).astype(np.float32) for bi in best]


def ground_godot(name, H, site):
    X, Y = centres(name)
    z = H(X.ravel(), Y.ravel()).reshape(X.shape)
    return (z - site.shift - DATUM - (X * X + Y * Y) * (1.0 - K_REFR) / (2.0 * R_EARTH)).astype(np.float32)


def bake():
    site = Site.load()
    H = Heights(site)
    tasks = [(n, k) for n in GRIDS for k in range(sectors(n))]
    out = {n: np.zeros((layers(n), GRIDS[n][4], GRIDS[n][3], 4), np.float32) for n in GRIDS}
    workers = max(1, (os.cpu_count() or 4))
    with ProcessPoolExecutor(max_workers=workers, initializer=_init) as ex:
        for i, (name, k, per_eye) in enumerate(ex.map(march, tasks, chunksize=1)):
            for e, t in enumerate(per_eye):
                out[name][e * groups(name) + k // 4, :, :, k % 4] = t
            if (i + 1) % 64 == 0:
                print("horizon: %d of %d sector bakes" % (i + 1, len(tasks)), flush=True)
    meta = {"about": "The horizon map, tools/terrain/horizon.py (plan chapter 11, 6.3): float16 RGBA layers per grid, "
                     "for each eye in turn eight layers of the 32 sectors' horizon tangents, then the ground's Godot height "
                     "in R; rows north to south; sector k looks along the design's bearing k x 11.25 deg.",
            "sectors": SECTORS, "format": "RGBAH", "site": json.loads(site.tag()), "shift": site.shift, "grids": {}}
    for name, (x0, y1, res, cols, rows, eyes) in GRIDS.items():
        out[name][layers(name) - 1, :, :, 0] = ground_godot(name, H, site)
        os.makedirs(OUTDIR, exist_ok=True)
        path = os.path.join(OUTDIR, "horizon_%s.bin" % name)
        out[name].astype("<f2").tofile(path)
        meta["grids"][name] = {"file": os.path.basename(path), "x0": x0, "y1": y1, "res": res, "cols": cols, "rows": rows,
                               "eyes": list(eyes), "layers": layers(name), "sectors": sectors(name)}
        print("horizon: %s %d x %d at %g m -> %s (%.1f MB)" % (name, cols, rows, res, path, os.path.getsize(path) / 1e6))
    json.dump(meta, open(os.path.join(OUTDIR, "horizon.json"), "w"), indent=1)


class MapRead:
    """The baked map read as the shader reads it: bilinear between samples (texel centres, edges clamped); per sector
    the chord between the two eye heights either side of the point's height, in tangents; linear between the sectors
    either side of the azimuth."""

    def __init__(self):
        self.meta = json.load(open(os.path.join(OUTDIR, "horizon.json")))
        self.grids = {}
        for name, g in self.meta["grids"].items():
            a = np.fromfile(os.path.join(OUTDIR, g["file"]), "<f2").astype(np.float32)
            self.grids[name] = (g, a.reshape(g["layers"], g["rows"], g["cols"], 4))

    def _bilinear(self, g, a, x, y, layer, ch):
        c = min(max((x - g["x0"]) / g["res"] - 0.5, 0.0), g["cols"] - 1.0)
        r = min(max((g["y1"] - y) / g["res"] - 0.5, 0.0), g["rows"] - 1.0)
        i, j = min(int(r), g["rows"] - 2), min(int(c), g["cols"] - 2)
        fr, fc = r - i, c - j
        p = a[layer, i:i + 2, j:j + 2, ch]
        return float((p[0, 0] * (1 - fc) + p[0, 1] * fc) * (1 - fr) + (p[1, 0] * (1 - fc) + p[1, 1] * fc) * fr)

    def grid_at(self, x, y):
        for name in ("fine", "core", "valley", "ring"):
            if name not in self.grids:
                continue
            g, a = self.grids[name]
            if g["x0"] <= x <= g["x0"] + g["cols"] * g["res"] and g["y1"] - g["rows"] * g["res"] <= y <= g["y1"]:
                return g, a
        return None, None

    def ground(self, x, y):
        g, a = self.grid_at(x, y)
        return self._bilinear(g, a, x, y, g["layers"] - 1, 0)

    def horizon(self, x, y, above, az):
        g, a = self.grid_at(x, y)
        ns = g.get("sectors", SECTORS)
        gr = ns // 4
        fs = (az % 360.0) / (360.0 / ns)
        s0 = int(math.floor(fs)) % ns
        s1, f = (s0 + 1) % ns, fs - math.floor(fs)
        eyes = g["eyes"]
        if len(eyes) == 1:
            i, t = 0, 0.0
        else:
            i = next((j for j in range(len(eyes) - 2) if above < eyes[j + 1]), len(eyes) - 2)
            t = (min(max(above, -2.0), 80.0) - eyes[i]) / (eyes[i + 1] - eyes[i])
        per_sector = []
        for s in (s0, s1):
            t0 = self._bilinear(g, a, x, y, i * gr + s // 4, s % 4)
            t1 = self._bilinear(g, a, x, y, (i + 1) * gr + s // 4, s % 4) if len(eyes) > 1 else t0
            per_sector.append(t0 + (t1 - t0) * t)
        return math.degrees(math.atan(per_sector[0] + (per_sector[1] - per_sector[0]) * f))


def direct(H, x, y, eye_z, az):
    """The horizon along one exact azimuth, marched finely: the reference the map is checked against."""
    b = math.radians(az)
    d = np.concatenate([np.arange(1.0, 2000.0, 1.0), 2000.0 * 1.0025 ** np.arange(0, int(math.log(D_MAX / 2000.0) / math.log(1.0025)))])
    zt = H(x + d * math.sin(b), y + d * math.cos(b))
    a = np.degrees(np.arctan2(np.where(np.isfinite(zt), zt, -1e9) - eye_z - drop(d), d))
    return float(a.max())


def sun_times(horizon_of):
    """First and last direct sun (LMT minutes) of DAY, where horizon_of(az) gives the horizon angle: the first minute
    of the morning the sun's centre clears it, and the last minute of the afternoon."""
    site = Site.load()
    lat, lon = site.lat, site.lon

    def lit(m):
        alt, az = sky.sun_alt_az(sky.lmt_to_jd(DAY, m, lon), lat, lon)
        return alt > horizon_of(az)

    def edge(a, b, rising):
        # the lit/unlit change inside [a, b] by bisection, to a second
        for _ in range(12):
            mid = (a + b) / 2.0
            if lit(mid) == rising:
                b = mid
            else:
                a = mid
        return (a + b) / 2.0

    first = last = None
    m = 300.0
    prev = lit(m)
    while m < 1140.0:
        n = m + 1.0
        now = lit(n)
        if now and not prev and first is None:
            first = edge(m, n, True)
        if prev and not now:
            last = edge(m, n, False)
        prev, m = now, n
    return first, last


def hhmm(m):
    if m is None:
        return "—"
    s = int(round(m * 60.0))
    return "%02d:%02d:%02d" % (s // 3600, s // 60 % 60, s % 60)


def minutes(s):
    h, m = s.split(":")
    return int(h) * 60 + int(m)


def check():
    site = Site.load()
    H = Heights(site)
    mp = MapRead()
    rows, worst, gates = [], {}, []
    for name, x, y, above, first_d, last_d in PLACES:
        z = float(H(np.array([x]), np.array([y]))[0])
        f_dir, l_dir = sun_times(lambda az: direct(H, x, y, z + above, az))
        f_map, l_map = sun_times(lambda az: mp.horizon(x, y, above, az))
        err = max(abs(f_map - f_dir), abs(l_map - l_dir)) if None not in (f_map, f_dir, l_map, l_dir) else float("nan")
        grid = mp.grid_at(x, y)[0]
        gname = next(n for n, g in mp.meta["grids"].items() if g is grid)
        if math.isfinite(err):
            worst[gname] = max(worst.get(gname, 0.0), err)
        rows.append("| %s | %+d, %+d | %.0f | %s | %s | %s | %s | %s | %s | %s | %+.1f / %+.1f | %+.0f / %+.0f |" % (
            name, x, y, z - site.shift, gname, first_d, hhmm(f_dir), hhmm(f_map), last_d, hhmm(l_dir), hhmm(l_map),
            f_map - f_dir, l_map - l_dir, f_dir - minutes(first_d), l_dir - minutes(last_d)))
        if name in GATES:
            miss = l_map - minutes(last_d)
            gates.append("- %s: last sun %s through the map, the design's %s: %+.0f min, %s (±%.0f min)." % (
                name, hhmm(l_map), last_d, miss, "within the gate" if abs(miss) <= GATES[name] else "**outside the gate**", GATES[name]))
    out = ["# Sun report: first and last sun through the horizon map",
           "",
           "_Written by `tools/terrain/horizon.py` (spike S12, art step A8) from the horizon map it bakes over %s. The day is %s, the site %.3f° N, %.3f° E; times are local mean time, to the second; the sun's centre against the terrain's horizon, curvature and refraction included, no refraction on the sun. \"Direct\" marches one ray at the sun's own azimuth; \"map\" reads the baked map as the shaders do. Regenerate: `tools/py tools/terrain/horizon.py`._" % (GROUND, DAY.isoformat(), site.lat, site.lon),
           "",
           "| Place | x, y | %s ground − shift (m) | Map grid | First sun, design | Direct | Map | Last sun, design | Direct | Map | Map − direct, first / last (min) | %s − design, first / last (min) |" % (("Sculpted", "Sculpted") if SCULPTED else ("Real", "Real")),
           "|---|---|---|---|---|---|---|---|---|---|---|---|"] + rows + [
           "",
           "**The map's own error** against the direct rays, the worst first or last sun per grid: %s. The S12 criterion is a minute for the map, and two minutes against chapter 02's times once the ground is sculpted. The ring's 128 m grid is for the mountains' light at a distance, not for timing a point: the Laptse La gets its own map with the high zone (chapter 11, 8.1)." % "; ".join("%s %.1f min" % (n, worst[n]) for n in ("fine", "core", "valley", "ring") if n in worst),
           "",
           "**Art step A8's gates** (chapter 09, 16):"] + gates + [
           "",
           ("The last column is the sculpted ground's, through the direct rays." if SCULPTED else "The last column is the real ground's, not the map's: until the sculpting passes give the valley chapter 02's shape (docs/ISSUES.md, ISS-031), the times follow the real ridges.")]
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("\n".join(out))
    return max(worst.values()) if worst else float("nan")


if __name__ == "__main__":
    if "--check" not in sys.argv:
        bake()
    check()
