#!/usr/bin/env python3
"""Terrain check, first cut (plan chapter 11, 8.2 step 7; chapter 02, 2.2-2.8; roadmap RT-11).

Measures the REAL ground (the base pass from fetch.py, before any sculpting) against chapter 02's designed
geography: the control points' heights, where the real Yalong runs, the horizons that decide what can be seen
(Dungri Karpo in the gorge notch, the western ridge that makes the early sunset, the ridges that must hide Minya
Konka everywhere below the Laptse La), and Minya Konka itself as a check on the reprojection. Elevation angles
include the earth's curvature and ordinary refraction (k = 0.13), as chapter 02 does.
Everything is measured where data/terrain/site.json lays the design on the real ground (tools/terrain/terrain_site.py):
real heights are compared with the design's after the site's shift, and bearings are the design's, whose north is
turned from true north. Minya Konka is placed from its real summit, so its bearing follows the site.
The report tells the sculpting passes (3-6) how far reality sits from the design.
Run: tools/py tools/terrain/terrain_check.py   (writes docs/terrain/base-report.md)
"""
import math
import os

import numpy as np

from terrain_site import Site

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
VALLEY = os.environ.get("VALLEY", "valley_1m")  # valley_sculpted_1m: the ground after passes 2-3 (sculpt.py)
RING = os.environ.get("RING", "ring_30m")  # ring_shaped_30m: the ring after pass 6 (horizons.py)
R_EARTH, K_REFR, EYE = 6371000.0, 0.13, 1.6
MINYA_KONKA = (101.879167, 29.595833, 7509.0)  # summit, 29°35′45″ N 101°52′45″ E, 7,509 m (chapter 02, 2.2)


class Height:
    """Real z(x, y) at design points, bilinear, from the finest raster that covers the point."""

    def __init__(self, site):
        self.grids = [site.read(os.path.join(GEN, name + ".tif")) for name in (VALLEY, RING, "far_90m")]

    def __call__(self, x, y):
        for g in self.grids:
            z = float(g.z(x, y))
            if math.isfinite(z):
                return z
        return float("nan")


def drop(d):
    return d * d / (2.0 * R_EARTH) * (1.0 - K_REFR)


def horizon(z, x, y, h_eye, bearing, max_d, step=None, start=30.0):
    """Highest elevation angle (degrees) of the terrain along a bearing, with the distance and height where it peaks."""
    b = math.radians(bearing)
    best, at, zz = -90.0, 0.0, 0.0
    d = start
    while d <= max_d:
        s = step or max(15.0, d * 0.01)
        zt = z(x + d * math.sin(b), y + d * math.cos(b))
        if math.isfinite(zt):
            a = math.degrees(math.atan2(zt - h_eye - drop(d), d))
            if a > best:
                best, at, zz = a, d, zt
        d += s
    return best, at, zz


import peak as PK  # noqa: E402  (Dungri Karpo's summit)


def bearing_to(x, y, tx, ty):
    return math.degrees(math.atan2(tx - x, ty - y)) % 360.0


def main():
    site = Site.load()
    z = Height(site)
    mk_x, mk_y = site.from_lonlat(MINYA_KONKA[0], MINYA_KONKA[1])
    out = []
    say = lambda s="": (print(s), out.append(s))
    say("# Terrain base report: the real ground against chapter 02's design")
    say()
    say("_Written by `tools/terrain/terrain_check.py` from " + ("the Copernicus GLO-30 base pass (`tools/terrain/fetch.py`), before any sculpting." if VALLEY == "valley_1m" else "the shaped ground (`%s`, `%s`: `tools/terrain/build.sh`, passes 2-6 on the Copernicus GLO-30 base; the column headed \"real ground\" is that ground)." % (VALLEY, RING)) + " Positions are chapter 02's town grid (x east, y north, metres from Tsongra), laid on the real ground where `data/terrain/site.json` puts it: Tsongra at %.3f° N, %.3f° E, the design turned %+.0f° (true north lies at the design's bearing %03.0f°; every bearing here is the design's), the real ground lowered by %.0f m so the real river meets the design's. Angles include the earth's curvature and refraction (k = 0.13). Regenerate by running both scripts._" % (
        site.lat, site.lon, site.turn, site.north_deg(), site.shift))
    say()
    say("## 1. Control points: real ground against designed height")
    say()
    say("| Point | x, y | Designed z | Real ground | Real − %.0f − designed |" % site.shift)
    say("|---|---|---|---|---|")
    pts = [("T Tsongra", 0, 0, 2662), ("C confluence pool", 210, -95, 2660), ("X slot exit", -190, -118, 2593),
           ("M Dungchu mouth", -487, -172, 2541), ("Gate Chorten", 170, -175, 2692), ("Samkha Khar base", -130, -78, 2640),
           ("South Gate", 465, 65, 2882), ("Tsokchen court", 535, 110, 2928), ("Labrang floor", 620, 215, 2990),
           ("Gorge Rim Lookout", 258, 245, 2781.5), ("Guru Drubphuk", 1080, 400, 3360), ("Durtro", 1160, -1040, 3150),
           ("Pharkha dues house", -700, -140, 2620), ("Laptse La", 4760, 2750, 4480)]
    d = []
    for n, x, y, zd in pts:
        zr = z(x, y)
        d.append(zr - site.shift - zd)
        say("| %s | %+d, %+d | %d | %.0f | %+.0f |" % (n, x, y, zd, zr, d[-1]))
    say()
    say("Below the Laptse La (the last row, a high-zone design), the RMS of the last column is %.0f m." % math.sqrt(np.mean(np.square(d[:-1]))))
    say()
    say("## 2. Where the real Yalong runs")
    say()
    say("Designed: centreline x = −525 + 0.04y, water 2,541 m at y = −170, +0.5 m per 100 m upstream. Real: the lowest ground across each line of y, x from −1,350 to +700.")
    say()
    say("| y | Designed x | Real lowest x | Real east of designed | Real lowest z − %.0f | Designed water |" % site.shift)
    say("|---|---|---|---|---|---|")
    for y in (-1090, -1000, -500, -170, 0, 500, 1000, 1090):
        xs = np.arange(-1350, 700, 5.0)
        zs = [z(x, y) for x in xs]
        k = int(np.nanargmin(zs))
        xd = -525 + 0.04 * y
        say("| %+d | %.0f | %.0f | %+.0f m | %.0f | %.0f |" % (y, xd, xs[k], xs[k] - xd, zs[k] - site.shift, 2541 + 0.005 * (y + 170)))
    say()
    say("## 3. Horizons that decide what is seen")
    say()
    say("| From | Bearing | Needed | Real horizon | Verdict |")
    say("|---|---|---|---|---|")

    def check(name, x, y, zd, bearing, cond, needed):
        zg = z(x, y)
        h, at, zz = horizon(z, x, y, zg + EYE, bearing, 25000)
        ok = cond(h)
        say("| %s (%+d, %+d; real ground %.0f m, designed %d) | %03d° | %s | %.1f° at %.1f km (%.0f m) | %s |" % (
            name, x, y, zg, zd, bearing, needed, h, at / 1000.0, zz, "as designed" if ok else "**differs**"))
        return h

    def peak_check(name, x, y, zd, eye, seen, note):
        """Dungri Karpo (tools/terrain/peak.py) seen or hidden: the ground before it, to 1.5 km short of its summit, under
        or over the summit's own angle."""
        zg = z(x, y)  # the raster's, which carries the site's shift (as every height `z` gives)
        ze = (zg + EYE) if eye is None else (zd + site.shift + eye)  # a given eye: chapter 02's floor and its height over it
        b = bearing_to(x, y, PK.SUMMIT[0], PK.SUMMIT[1])
        dpk = math.hypot(PK.SUMMIT[0] - x, PK.SUMMIT[1] - y)
        ang = math.degrees(math.atan2(PK.SUMMIT_Z + site.shift - ze - drop(dpk), dpk))
        h, at, zz = horizon(z, x, y, ze, b, dpk - 1500.0)
        ok = (h < ang) if seen else (h >= ang)
        say("| %s (%+d, %+d; real ground %.0f m, designed %d) | %03.0f° | Dungri Karpo (%.1f° up, %.1f km) %s: the ground before it %s %.1f° | %.1f° at %.1f km (%.0f m) | %s |" % (
            name, x, y, zg, zd, b, ang, dpk / 1000.0, note, "under" if seen else "over", ang, h, at / 1000.0, zz, "as designed" if ok else "**differs**"))

    peak_check("Tsongra", 0, 0, 2662, None, False, "hidden")
    peak_check("Gorge Rim Lookout V-13", 258, 245, 2781.5, 1.6, True, "in the notch")
    peak_check("Tsokchen roof V-05", 540, 150, 2952, 21.0, True, "visible over the gorge")
    check("Tsongra", 0, 0, 2662, 250, lambda h: 12.0 <= h <= 16.0, "the western ridge (crest about 3,560 m at 3.9 km): 12–16°")
    check("Conch Eddy V-02", 190, -90, 2666, 110, lambda h: 6.0 <= h <= 10.0, "first sun down the Serchu: horizon about 8°")
    for name, x, y, zd in (("Tsongra", 0, 0, 2662), ("Tsokchen roof", 540, 150, 2952), ("Tathang", 300, 700, 3060)):
        b0 = bearing_to(x, y, mk_x, mk_y)
        lo = min(horizon(z, x, y, z(x, y) + EYE, b0 + db, 110000)[0] for db in range(-10, 11, 2))
        say("| %s (%+d, %+d) | %03.0f–%03.0f° | Minya Konka (at %03.0f°) hidden: horizon ≥ 5° on every bearing within 10° of it | lowest %.1f° | %s |" % (
            name, x, y, (b0 - 10) % 360, (b0 + 10) % 360, b0, lo, "as designed" if lo >= 5.0 else "**differs**"))
    # Minya Konka from the pass: its elevation angle over the curve of the earth, against the horizon short of it.
    lx, ly = 4760, 2750
    ze = z(lx, ly) + EYE
    dmk = math.hypot(mk_x - lx, mk_y - ly)
    bmk = bearing_to(lx, ly, mk_x, mk_y)
    amk = math.degrees(math.atan2(MINYA_KONKA[2] - ze - drop(dmk), dmk))
    h, at, zz = horizon(z, lx, ly, ze, bmk, dmk - 5000.0)
    say("| Laptse La V-08 (%+d, %+d; real ground %.0f m, designed 4480) | %03.0f° | Minya Konka (%.1f° over the real ground, %.1f km) visible: horizon lower | %.1f° at %.1f km (%.0f m) | %s |" % (
        lx, ly, ze - EYE, bmk, amk, dmk / 1000.0, h, at / 1000.0, zz, "as designed" if h < amk else "**differs**"))
    # The pass is reshaped in the high zone (chapter 11, 8.1): the same view from the saddle at its designed height,
    # over the real ground beyond 2 km.
    ze = 4480.0 + site.shift + EYE
    amk = math.degrees(math.atan2(MINYA_KONKA[2] - ze - drop(dmk), dmk))
    h, at, zz = horizon(z, lx, ly, ze, bmk, dmk - 5000.0, start=2000.0)
    say("| Laptse La V-08 at its designed 4,480 m, ground beyond 2 km | %03.0f° | Minya Konka (%.1f°) visible: horizon lower | %.1f° at %.1f km (%.0f m) | %s |" % (
        bmk, amk, h, at / 1000.0, zz, "as designed" if h < amk else "**differs**"))
    say()
    say("## 4. Minya Konka, as a check on the reprojection")
    say()
    xs = np.arange(mk_x - 3000, mk_x + 3000, 90.0)
    ys = np.arange(mk_y - 3000, mk_y + 3000, 90.0)
    best = max((z(x, y), x, y) for x in xs for y in ys)
    say("Chapter 02 gives the summit as 29°35′45″ N, 101°52′45″ E, 7,509 m: at this site (%+.0f, %+.0f) in the design's grid, %.1f km from Tsongra at the design's bearing %03.0f°. The highest real ground within 3 km of that point: %.0f m at (%+.0f, %+.0f), %.1f km from it (a 90 m grid rounds a needle summit down)." % (
        mk_x, mk_y, math.hypot(mk_x, mk_y) / 1000.0, bearing_to(0, 0, mk_x, mk_y), best[0], best[1], best[2], math.hypot(best[1] - mk_x, best[2] - mk_y) / 1000.0))
    os.makedirs(os.path.join(ROOT, "docs", "terrain"), exist_ok=True)
    with open(os.path.join(ROOT, "docs", "terrain", os.environ.get("CHECK_REPORT", "base-report.md")), "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
