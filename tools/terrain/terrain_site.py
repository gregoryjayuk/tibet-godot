"""The site: where chapter 02's designed valley sits on the real ground (data/terrain/site.json; Greg's MOVE, 25 Sep 2026).

The design's grid (x east, y north, metres from Tsongra; chapter 02, 2.2) is a transverse Mercator centred on the
site's Tsongra, turned by the site's angle. Every raster fetch.py writes is laid out on the design grid: pixel (c, r)
of a raster whose window starts at x0 (west) and y1 (north) with spacing res is centred on design point
(x0 + (c + 0.5) res, y1 - (r + 0.5) res). The GeoTIFFs carry the true, turned georeferencing, so a GIS puts them in the
right place, and two tags: `site`, so no tool reads a raster made for another site, and `design_window`. Tools read
them with Site.read(), which returns a Grid; never with `~transform * (x, y)`, which is the turned frame, not the design's.
"""
import json
import math
import os

import numpy as np
import rasterio
from affine import Affine
from rasterio.crs import CRS

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE_JSON = os.path.join(ROOT, "data", "terrain", "site.json")


class Grid:
    """A design-grid raster: heights `a` (rows north to south, columns west to east), its window, bilinear z(x, y)."""

    def __init__(self, a, window):
        self.a = a
        self.x0, self.x1, self.y0, self.y1, self.res = window

    def pix(self, x, y):
        """Fractional (column, row) of design points, pixel centres at whole numbers."""
        return (np.asarray(x, np.float64) - self.x0) / self.res - 0.5, (self.y1 - np.asarray(y, np.float64)) / self.res - 0.5

    def z(self, x, y, clamp=False):
        """Bilinear heights at design points (numbers or arrays): NaN outside the raster or beside a hole, unless
        clamp, which holds the edge value."""
        a = self.a
        c, r = self.pix(x, y)
        if clamp:
            c, r = np.clip(c, 0, a.shape[1] - 1.001), np.clip(r, 0, a.shape[0] - 1.001)
        i, j = np.floor(r).astype(np.int64), np.floor(c).astype(np.int64)
        ok = (i >= 0) & (i < a.shape[0] - 1) & (j >= 0) & (j < a.shape[1] - 1)
        i, j = np.clip(i, 0, a.shape[0] - 2), np.clip(j, 0, a.shape[1] - 2)
        fr, fc = r - i, c - j
        z = (a[i, j] * (1 - fc) + a[i, j + 1] * fc) * (1 - fr) + (a[i + 1, j] * (1 - fc) + a[i + 1, j + 1] * fc) * fr
        return np.where(ok, z, np.nan)


class Site:
    def __init__(self, lat, lon, turn_deg, shift_m=0.0):
        self.lat, self.lon, self.turn, self.shift = float(lat), float(lon), float(turn_deg), float(shift_m)
        self.crs = CRS.from_proj4("+proj=tmerc +lat_0=%.7f +lon_0=%.7f +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs" % (self.lat, self.lon))
        th = math.radians(self.turn)
        self.c, self.s = math.cos(th), math.sin(th)

    @classmethod
    def load(cls, previous=False):
        """The site in data/terrain/site.json, or the one it replaced (previous=True)."""
        d = json.load(open(SITE_JSON, encoding="utf-8"))
        d = d["previous"] if previous else d
        return cls(d["tsongra_lat"], d["tsongra_lon"], d["turn_deg"], d["shift_m"])

    def tag(self):
        return json.dumps({"lat": self.lat, "lon": self.lon, "turn_deg": self.turn})

    def to_crs(self, x, y):
        """Design grid -> the site's transverse Mercator (true north up), metres."""
        return x * self.c + y * self.s, -x * self.s + y * self.c

    def from_crs(self, e, n):
        return e * self.c - n * self.s, e * self.s + n * self.c

    def transform(self, x0, y1, res):
        """The true geotransform of a design-grid raster whose top-left corner is design point (x0, y1)."""
        e0, n0 = self.to_crs(x0, y1)
        return Affine(res * self.c, -res * self.s, e0, -res * self.s, -res * self.c, n0)

    def from_lonlat(self, lon, lat):
        """Real longitude and latitude (degrees) -> design grid (x, y)."""
        from rasterio.warp import transform
        e, n = transform("EPSG:4326", self.crs, [lon], [lat])
        return self.from_crs(e[0], n[0])

    def north_deg(self):
        """The bearing, in the design's frame, of true north (the design is turned by `turn`)."""
        return -self.turn % 360.0

    def read(self, path):
        """A raster fetch.py wrote for this site, as a Grid."""
        with rasterio.open(path) as f:
            tags = f.tags()
            if tags.get("site") != self.tag():
                raise SystemExit("%s was made for another site (%s); re-run tools/terrain/fetch.py" % (path, tags.get("site")))
            window = tuple(float(v) for v in tags["design_window"].split())
            return Grid(f.read(1).astype(np.float64), window)
