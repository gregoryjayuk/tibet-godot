#!/usr/bin/env python3
"""Terrain pass 1, the base (plan chapter 11, 8.1-8.2; roadmap RT-11).

The six Copernicus GLO-30 tiles (~/.cache/dungkardo/dem/, docs/VENDOR.md) are mosaicked and reprojected into the town
grid of chapter 02 (2.2), laid on the real ground where data/terrain/site.json puts it (tools/terrain/terrain_site.py):
a transverse Mercator centred on the site's Tsongra, turned as the site search placed the design (site_fit.py), x east
and y north in the design's frame, z metres above sea level, 1 m of grid is 1 m of ground. Since Greg's MOVE (25 Sep 2026)
Tsongra is at 29.973° N, 101.017° E and the design is turned 15° anticlockwise; before, 30.03° N, 101.01° E, unturned.
Written to assets/generated/terrain/ (not versioned):
  valley_1m.tif   the valley map, x -1,350..+2,300, y -1,100..+1,100, 1 m, bicubic from 30 m (pass 1 of 8)
  ring_30m.tif    the near ring, +-15 km, 30 m
  far_90m.tif     the far ring and the Minya Konka strip, +-105 km, 90 m
Heights stay real (metres above sea level); export_t3d.py lowers them by the site's shift for the game.
Run with the project's Python, under nice: nice -n 10 tools/py tools/terrain/fetch.py
Obligation: the Copernicus credit line (docs/VENDOR.md) goes into the game's credits.
"""
import glob
import os

import numpy as np
import rasterio
from rasterio.merge import merge
from rasterio.warp import Resampling, reproject

from terrain_site import Site

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "generated", "terrain")
DEM = sorted(glob.glob(os.path.expanduser("~/.cache/dungkardo/dem/Copernicus_DSM_COG_10_*_DEM.tif")))
GRIDS = {  # name: x0, x1, y0, y1, metres per pixel
    "valley_1m": (-1350.0, 2300.0, -1100.0, 1100.0, 1.0),
    "ring_30m": (-15000.0, 15000.0, -15000.0, 15000.0, 30.0),
    "far_90m": (-105000.0, 105000.0, -105000.0, 105000.0, 90.0),
}


def mosaic():
    assert len(DEM) == 6, "expected the six approved tiles in ~/.cache/dungkardo/dem/, found %d" % len(DEM)
    srcs = [rasterio.open(p) for p in DEM]
    m, mtrans = merge(srcs)
    crs = srcs[0].crs
    for s in srcs:
        s.close()
    return m[0], mtrans, crs


def warp(site, src, src_trans, src_crs, x0, x1, y0, y1, res):
    """The real heights on a design-grid window of `site`: (array, rows north to south, columns west to east; its true geotransform)."""
    w, h = int(round((x1 - x0) / res)), int(round((y1 - y0) / res))
    transform = site.transform(x0, y1, res)
    dst = np.full((h, w), np.nan, np.float32)
    reproject(source=src, destination=dst, src_transform=src_trans, src_crs=src_crs, dst_transform=transform,
              dst_crs=site.crs, resampling=Resampling.cubic, dst_nodata=np.nan)
    return dst, transform


def main():
    site = Site.load()
    os.makedirs(OUT, exist_ok=True)
    src, src_trans, src_crs = mosaic()
    print("mosaic", src.shape, "crs", src_crs, "site", site.tag())
    for name, (x0, x1, y0, y1, res) in GRIDS.items():
        dst, transform = warp(site, src, src_trans, src_crs, x0, x1, y0, y1, res)
        h, w = dst.shape
        path = os.path.join(OUT, name + ".tif")
        with rasterio.open(path, "w", driver="GTiff", width=w, height=h, count=1, dtype="float32", crs=site.crs,
                           transform=transform, nodata=np.nan, compress="deflate", predictor=3, tiled=True) as f:
            f.write(dst, 1)
            f.update_tags(site=site.tag(), design_window="%g %g %g %g %g" % (x0, x1, y0, y1, res))
        ok = np.isfinite(dst)
        print("%-10s %5d x %-5d at %4.0f m: z %.0f..%.0f m, %.1f%% covered -> %s" % (
            name, w, h, res, np.nanmin(dst), np.nanmax(dst), 100.0 * ok.mean(), path))


if __name__ == "__main__":
    main()
