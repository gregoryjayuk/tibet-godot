#!/usr/bin/env python3
"""Where does chapter 02's designed valley fit the real ground best? (roadmap RT-11 follow-up; ISS-019)

Slides and turns the whole design over the real 30 m ground within +-9 km of the current site (data/terrain/site.json)
and scores each placement by how well about 30 designed points match the real heights (control points, the Yalong,
the Dungchu, the Serchu, the Laptse La): the weighted RMS after one vertical shift for the whole design. The river
points count double: a valley's shape is its rivers.
The shift is held within 30 m of the site's (the real Yalong's level against the design's). History: the first run,
on 25 Sep 2026 from the old anchor (30.03° N, 101.01° E), let the shift float up to +-400 m. It found today's site
(133 m at +178 m), and Greg chose it (MOVE); but a shift that large perches the designed river 164 m above the real
one, because a free shift lets a valley side score like a valley floor. With the shift held to the river the same
placement scores 179 m, still the best within 9 km, against 423 m for the old anchor; the site stands (docs/DECISIONS.md).
Run: tools/py tools/terrain/site_fit.py   (appends section 5 to docs/terrain/base-report.md; run terrain_check.py first)
"""
import math
import os

import numpy as np

from terrain_site import Site

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE = Site.load()
RING = SITE.read(os.path.join(ROOT, "assets", "generated", "terrain", "ring_30m.tif"))
FREE = 30.0  # metres the shift may move from the site's
# Designed points: name, x, y, z, weight (chapter 02, 2.2-2.5)
P = [("Tsongra", 0, 0, 2662, 1), ("confluence", 210, -95, 2660, 2), ("slot exit", -190, -118, 2593, 2), ("Dungchu mouth", -487, -172, 2541, 2),
     ("Gate Chorten", 170, -175, 2692, 1), ("Samkha Khar", -130, -78, 2640, 1), ("South Gate", 465, 65, 2882, 1), ("Tsokchen", 535, 110, 2928, 1),
     ("Labrang", 620, 215, 2990, 1), ("Gorge Rim", 215, 215, 2778, 1), ("Guru Drubphuk", 1080, 400, 3360, 1), ("Durtro", 1160, -1040, 3150, 1),
     ("Pharkha", -700, -140, 2620, 1), ("U2 bridge", 330, 185, 2712, 2), ("U5 bridge", 620, 800, 2822, 2), ("leat intake", 1150, 1850, 2992, 2),
     ("Serchu S1", 500, -230, 2700, 2), ("Serchu S3", 1250, -520, 2805, 2), ("Serchu S5", 2150, -850, 2955, 2), ("Laptse La", 4760, 2750, 4480, 1),
     ("Tathang", 300, 700, 3060, 1)]
for y in (-1000, -600, -170, 300, 800, 1300):  # the Yalong centreline, 2,541 m at y = -170, +0.5 m per 100 m upstream
    P.append(("Yalong y%+d" % y, -525 + 0.04 * y, y, 2541 + 0.005 * (y + 170), 2))
px = np.array([p[1] for p in P], float)
py = np.array([p[2] for p in P], float)
pz = np.array([p[3] for p in P], float)
pw = np.array([p[4] for p in P], float)


def fit(zs):
    """Per placement (rows): the shift nearest the median residual within FREE of the site's, and the weighted RMS."""
    d = zs - pz[None, :]
    off = np.clip(np.nanmedian(d, axis=1), SITE.shift - FREE, SITE.shift + FREE)
    rms = np.sqrt(np.nansum(pw[None, :] * (d - off[:, None]) ** 2, axis=1) / pw.sum())
    rms[np.isnan(zs).any(axis=1)] = np.inf
    return rms, off


def main():
    results = []
    shifts = np.arange(-9000, 9001, 60.0)
    X0, Y0 = np.meshgrid(shifts, shifts)
    X0, Y0 = X0.ravel(), Y0.ravel()
    for deg in range(-60, 61, 3):
        th = math.radians(deg)  # turn the design clockwise by deg (compass sense) on top of the site's turn
        rx = px * math.cos(th) + py * math.sin(th)
        ry = -px * math.sin(th) + py * math.cos(th)
        rms, off = fit(RING.z(X0[:, None] + rx[None, :], Y0[:, None] + ry[None, :]))
        for i in np.argsort(rms)[:40]:
            results.append((rms[i], X0[i], Y0[i], deg, off[i]))
    results.sort()
    best = []
    for r in results:  # distinct sites: at least 1.5 km apart
        if all(math.hypot(r[1] - b[1], r[2] - b[2]) > 1500 for b in best):
            best.append(r)
        if len(best) == 5:
            break
    here_rms, here_off = fit(RING.z(px, py)[None, :])
    from rasterio.warp import transform
    lines = ["", "## 5. Where the designed valley fits the real ground best", "",
             "`tools/terrain/site_fit.py` slid and turned chapter 02's design over the real 30 m ground within ±9 km of this site, scoring %d designed points (rivers counted double) by their weighted RMS height error after one vertical shift, held within %.0f m of the site's %+.0f m so the designed river stays at the real river's level." % (len(P), FREE, SITE.shift),
             "", "| Placement | Tsongra at (x, y) in this site's grid | Latitude, longitude | Turned from this site | Vertical shift | RMS error |", "|---|---|---|---|---|---|",
             "| This site | 0, 0 | %.3f° N, %.3f° E | 0° | %+.0f m | %.0f m |" % (SITE.lat, SITE.lon, here_off[0], here_rms[0])]
    for n, (rms, x0, y0, deg, off) in enumerate(best, 1):
        lon, lat = transform(SITE.crs, "EPSG:4326", *[[v] for v in SITE.to_crs(x0, y0)])
        lines.append("| Best %d | %+.0f, %+.0f | %.3f° N, %.3f° E | %+d° | %+.0f m | %.0f m |" % (n, x0, y0, lat[0], lon[0], deg, off, rms))
    lines += ["", "Read the RMS as how far, on average, the real ground sits from the design's heights at the scored points. A few tens of metres would mean the real valley has the design's shape and the sculpting passes only refine it; a few hundred mean the design is carved into ground of another shape, which is the case everywhere within 9 km: the valley map is authored either way (chapter 11, 8.1), and the site decides how its edges meet the real rings.",
              "", "History: the first search (25 Sep 2026, from the old anchor at 30.03° N, 101.01° E) let the shift float up to ±400 m and ranked this site first at 133 m with a shift of +178 m (the old anchor: 416 m at +128 m). Greg chose it (MOVE, 25 Sep, 15:04). A shift that large puts the designed river 164 m above the real one. Held to the river, this site still ranks first within 9 km (179 m; 201 m at the +15 m it uses), and the old anchor scores 423 m."]
    print("\n".join(lines))
    with open(os.path.join(ROOT, "docs", "terrain", "base-report.md"), "a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
