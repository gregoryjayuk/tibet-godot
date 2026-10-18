#!/usr/bin/env python3
"""Terrain export for spike S3 (plan chapter 11, 8.2 step 8 and 8.4; roadmap RT-12).

Writes the heights Godot needs, in Godot's frame (chapter 11, 4.1: X = x, Y = elevation - 2,662, Z = -y):
- valley_t3d.r32 + .json: the Terrain3D import image, float32, 1 m, covering whole regions (REGION, default 256 m:
  the tightest fit, 150 regions and 9.8 M texels, against 12.6 M at 512 m and 21 M at 1,024 m)
  round the valley map. Inside the valley map the heights are the 1 m map sampled at whole metres (Terrain3D puts a
  vertex on every whole metre; the GeoTIFF's pixel centres sit at half metres, so each value is the mean of the four
  pixels round the corner); outside it, where the regions overhang, the 30 m ring upsampled, blended over 64 m.
- ring_t3d.r32 + .json: a 64 m grid of the 30 m ring out to 15 km for the ring mesh, with a hole where Terrain3D is.
Both are lowered by the earth's curvature with refraction, d^2 (1 - 0.13) / 2R, measured from Tsongra (chapter 11,
4.1): 0.15 m at 1.5 km, 15 m at 15 km. The drop is applied everywhere so the two surfaces meet without a step.
Both are also lowered by the site's shift (data/terrain/site.json: 15 m since the MOVE of 25 Sep 2026), so the real
river meets the design's and chapter 02's heights stay the game's altitudes: Godot y = real height - shift - 2,662.

Run: tools/py tools/terrain/export_t3d.py        (REGION=512 tools/py ... for 512 m regions)
Reads assets/generated/terrain/{valley_1m,ring_30m}.tif from fetch.py; writes beside them.
"""
import json
import math
import os

import numpy as np

from terrain_site import Site

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEN = os.path.join(ROOT, "assets", "generated", "terrain")
DATUM = 2662.0  # Tsongra's designed elevation is Godot y = 0 (chapter 11, 4.1)
R_EARTH, K_REFR = 6371000.0, 0.13
BLEND = 64.0  # metres over which the valley map hands over to the ring at its edge
RING_STEP, RING_HALF = 64, 14976  # the ring mesh grid: 469 x 469 vertices, a whole number of steps from any region edge


def drop(x, y):
    return (x * x + y * y) * (1.0 - K_REFR) / (2.0 * R_EARTH)


def main():
    region = int(os.environ.get("REGION", "256"))
    site = Site.load()
    ring_grid = site.read(os.path.join(GEN, os.environ.get("RING", "ring_30m") + ".tif"))  # ring_shaped_30m after horizons.py
    ring = lambda x, y: ring_grid.z(x, y, clamp=True)
    valley = site.read(os.path.join(GEN, os.environ.get("VALLEY", "valley_1m") + ".tif"))  # valley_sculpted_1m after sculpt.py
    v = valley.a
    # Corners between pixels: whole-metre x from left+1 to right-1, whole-metre y from top-1 down to bottom+1.
    corners = 0.25 * (v[:-1, :-1] + v[:-1, 1:] + v[1:, :-1] + v[1:, 1:])
    vx0, vx1 = int(valley.x0) + 1, int(valley.x1) - 1     # -1349 .. 2299
    vy1, vy0 = int(valley.y1) - 1, int(valley.y0) + 1     # 1099 .. -1099
    vz0, vz1 = -vy1, -vy0                            # Godot z -1099 .. 1099
    # The Terrain3D image: whole regions round the valley map.
    X0, X1 = math.floor(vx0 / region) * region, math.ceil((vx1 + 1) / region) * region
    Z0, Z1 = math.floor(vz0 / region) * region, math.ceil((vz1 + 1) / region) * region
    W, H = X1 - X0, Z1 - Z0
    xs = np.arange(X0, X1, dtype=np.float64)
    zs = np.arange(Z0, Z1, dtype=np.float64)
    gx, gz = np.meshgrid(xs, zs)
    gy = -gz
    h = ring(gx, gy)
    # Paste the valley map with a linear hand-over inside its edge.
    i0, j0 = vz0 - Z0, vx0 - X0
    vh = corners  # rows run north to south (Godot z increasing), columns west to east
    sub = h[i0:i0 + vh.shape[0], j0:j0 + vh.shape[1]]
    dx = np.minimum(np.arange(vh.shape[1]), np.arange(vh.shape[1])[::-1])[None, :]
    dz = np.minimum(np.arange(vh.shape[0]), np.arange(vh.shape[0])[::-1])[:, None]
    w = np.clip(np.minimum(dx, dz) / BLEND, 0.0, 1.0)
    h[i0:i0 + vh.shape[0], j0:j0 + vh.shape[1]] = sub * (1 - w) + vh * w
    seam = float(np.abs(sub - vh)[w < 1].mean())
    h = h - site.shift - DATUM - drop(gx, gy)
    h.astype("<f4").tofile(os.path.join(GEN, "valley_t3d.r32"))
    meta = {"about": "Terrain3D import heights, float32 little-endian, row-major, rows = Godot z; tools/terrain/export_t3d.py",
            "width": W, "height": H, "x0": X0, "z0": Z0, "spacing": 1.0, "region_size": region,
            "valley": {"x0": vx0, "x1": vx1, "z0": vz0, "z1": vz1}, "datum": DATUM, "site": json.loads(site.tag()), "shift": site.shift,
            "min": float(h.min()), "max": float(h.max()), "seam_mean_abs_m": seam,
            "regions": (W // region) * (H // region)}
    json.dump(meta, open(os.path.join(GEN, "valley_t3d.json"), "w"), indent=1)
    # The ring mesh grid.
    rs = np.arange(-RING_HALF, RING_HALF + 1, RING_STEP, dtype=np.float64)
    rx, rz = np.meshgrid(rs, rs)
    ry = -rz
    rh = ring(rx, ry) - site.shift - DATUM - drop(rx, ry)
    rh.astype("<f4").tofile(os.path.join(GEN, "ring_t3d.r32"))
    rmeta = {"about": "Ring mesh heights, float32 little-endian, row-major, rows = Godot z; tools/terrain/export_t3d.py",
             "n": len(rs), "step": RING_STEP, "x0": -RING_HALF, "z0": -RING_HALF,
             "hole": {"x0": X0, "x1": X1, "z0": Z0, "z1": Z1}}
    json.dump(rmeta, open(os.path.join(GEN, "ring_t3d.json"), "w"), indent=1)
    print(f"export_t3d: {W} x {H} m in {meta['regions']} regions of {region} m, heights {meta['min']:.0f} to "
          f"{meta['max']:.0f} (Godot y); the valley map's edge differs from the ring by {seam:.2f} m on average; "
          f"ring {len(rs)} x {len(rs)} at {RING_STEP} m")


if __name__ == "__main__":
    main()
