#!/usr/bin/env python3
"""Dungri Karpo, the town's god (M2 sprint 6, step 5; plan chapter 02, 2.7: "the town's god; 13 km from T", 5,420 m;
chapter 08, V-13a: "Dungri Karpo, 12.7 km away and 11.7 degrees up, filling the notch, its small glacier on the north
face just showing"): the invented peak raised into the shaped ring (ring_shaped_30m.tif, in place), where the real
ground has none, so the ring's mesh, the horizon map and the checks all see it.
Its summit stands 12.7 km from the Gorge Rim Lookout at 032.5 degrees, in the real gorge's notch from the rim (DECISIONS,
9 Oct 2026; chapter 02's 040 from the old point), at chapter 02's 5,420 m. Its massif rises from the real ridges round
it (3,400-4,000 m there) on a footing about 3.2 km round: steep near the top (a pyramid of three main ridges and two
lesser, each faces between them), easing out to meet the ground; the real ground is kept wherever it stands higher. The
snow and the north face's ice are the terrain's own rule (shaders/inc/terrain_color.gdshaderinc terrain_snow: above the
snow line, lower on the shaded faces).
Run: tools/py tools/terrain/peak.py   (tools/terrain/build.sh runs it after horizons.py)
"""
import math
import os
import sys

import numpy as np
import rasterio

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terrain_site import Site  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
RING = os.path.join(GEN, "ring_shaped_30m.tif")
LOOKOUT = (258.0, 245.0)  # tools/town/gardens.py LOOKOUT
BEARING, DIST = 32.5, 12700.0  # from the Lookout (chapter 08: 12.7 km)
SUMMIT_Z = 5420.0  # chapter 02, 2.7
FOOT = 3200.0  # metres from the summit to where the massif meets the ground, on average
RIDGES = ((3, 0.24, 0.35), (5, 0.09, 1.9), (2, 0.07, 4.1))  # (lobes, depth, phase): its ridges and the faces between them
SUMMIT = (LOOKOUT[0] + DIST * math.sin(math.radians(BEARING)), LOOKOUT[1] + DIST * math.cos(math.radians(BEARING)))


def massif(X, Y, base):
    """The peak's surface over (X, Y) (the town grid): the summit at SUMMIT_Z, falling towards a footing FOOT out (more
    along its ridges, less across its faces), to `base` (the real ground's level round it); concave, steep above."""
    dx, dy = X - SUMMIT[0], Y - SUMMIT[1]
    r = np.hypot(dx, dy)
    th = np.arctan2(dx, dy)
    reach = FOOT * (1.0 + sum(d * np.cos(n * th + ph) for n, d, ph in RIDGES))
    t = r / reach
    return np.where(t < 1.0, SUMMIT_Z - (SUMMIT_Z - base) * np.clip(t, 0.0, 1.0) ** 0.78, -1.0e9)  # nothing past its footing


def main():
    site = Site.load()
    with rasterio.open(RING) as src:
        a = src.read(1).astype(np.float64)
        prof, tags = src.profile, src.tags()
    h, w = a.shape
    g = site.read(RING)  # a design-grid raster: rows north to south, its window in the town grid (terrain_site.Grid)
    GX, GY = np.meshgrid(g.x0 + (np.arange(w) + 0.5) * g.res, g.y1 - (np.arange(h) + 0.5) * g.res)
    r = np.hypot(GX - SUMMIT[0], GY - SUMMIT[1])
    near = r < FOOT * 1.6
    z = a - site.shift
    base = float(np.median(z[(r > FOOT * 0.9) & (r < FOOT * 1.3)]))  # the real ridges' level round its footing
    zp = massif(GX, GY, base)
    new = np.where(near, np.maximum(z, zp), z)
    raised = new - z
    with rasterio.open(RING, "w", **prof) as f:
        f.write((new + site.shift).astype(prof["dtype"]), 1)
        f.update_tags(**tags)
    print("peak: Dungri Karpo at (%.0f, %.0f), %.0f m, %.1f km from Tsongra at %.1f degrees; its massif over %.1f km2, raised at most %.0f m over the real ground (%.0f m round its footing)" % (
        SUMMIT[0], SUMMIT[1], SUMMIT_Z, math.hypot(*SUMMIT) / 1000.0, math.degrees(math.atan2(SUMMIT[0], SUMMIT[1])),
        float((raised > 1.0).sum()) * g.res * g.res / 1e6, float(raised.max()), base))


if __name__ == "__main__":
    main()
