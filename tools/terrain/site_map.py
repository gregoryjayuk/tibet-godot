#!/usr/bin/env python3
"""The site decision as a picture for Greg (docs/ISSUES.md, ISS-019): the real ground round the anchor, shaded from
the 30 m tiles, with chapter 02's designed rivers and places laid on it twice: where the design sits today ("keep")
and at site_fit.py's best placement ("move": 6.3 km south, turned 15°). Red is the design; blue is where the real
Yalong runs (the lowest ground in each row near the design's river). North is up.
Greg chose MOVE on 25 Sep 2026, so this is now the record of that decision: it warps its own base in the old anchor's
frame (data/terrain/site.json, "previous"), whatever the current site. Two things it shows turned out looser than its
caption (docs/terrain/base-report.md, section 5): the real Yalong runs 190-630 m east of the placed design's, and the
133 m assumes a vertical shift that would perch the designed river 164 m above the real one.
Run: tools/py tools/terrain/site_map.py   Writes docs/terrain/site-map.jpg.
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import fetch
from terrain_site import Site

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONT = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 20)
SMALL = ImageFont.truetype(os.path.join(ROOT, "assets/source/fonts/noto-serif/NotoSerif[wdth,wght].ttf"), 16)
X0, X1, Y0, Y1 = -5000.0, 7000.0, -10000.0, 4000.0  # the window, town-grid metres (x east, y north)
SCALE = 1.6  # pixels per 30 m cell
# Chapter 02's designed places (x, y) and rivers, as site_fit.py scores them.
PLACES = {"Tsongra (the square)": (0, 0), "monastery": (575, 160), "Pharkha": (-700, -140), "Laptse La pass": (4760, 2750)}
RIVERS = {
    "Yalong": [(-525 + 0.04 * y, y) for y in range(-1100, 1401, 100)],
    "Dungchu": [(-487, -172), (-190, -118), (210, -95), (330, 185), (620, 800), (1150, 1850)],
    "Serchu": [(210, -95), (500, -230), (1250, -520), (2150, -850)],
}
VALLEY_MAP = [(-1350, -1100), (2300, -1100), (2300, 1100), (-1350, 1100), (-1350, -1100)]
OPTIONS = [("KEEP: the design where it is today", 0.0, 0.0, 0.0), ("MOVE: the best fit, 6.3 km south, turned 15°", 720.0, -6300.0, -15.0)]


def load():
    """The real ground over the window at 30 m, in the old anchor's frame."""
    z, _ = fetch.warp(Site.load(previous=True), *fetch.mosaic(), X0, X1, Y0, Y1, 30.0)
    return z.astype(np.float64)


def hillshade(z):
    gy, gx = np.gradient(z, 30.0)
    az, el = math.radians(315), math.radians(45)
    nx, ny, nz = -gx, gy, np.ones_like(z)
    n = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.clip((nx * math.sin(az) * math.cos(el) + ny * math.cos(az) * math.cos(el) + nz * math.sin(el)) / n, 0, 1)


def tint(z):
    t = np.clip((z - 2500.0) / 2200.0, 0, 1)[..., None]
    low, mid, high = np.array([118, 130, 92]), np.array([170, 140, 100]), np.array([235, 232, 228])
    return np.where(t < 0.5, low + (mid - low) * (t / 0.5), mid + (high - mid) * ((t - 0.5) / 0.5))


def place(x, y, dx, dy, deg):
    th = math.radians(deg)
    return x * math.cos(th) + y * math.sin(th) + dx, -x * math.sin(th) + y * math.cos(th) + dy


def main():
    z = load()
    hs = hillshade(z)
    rgb = tint(z) * (0.45 + 0.65 * hs[..., None])
    base = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).resize((int(z.shape[1] * SCALE), int(z.shape[0] * SCALE)), Image.LANCZOS)
    to_px = lambda x, y: ((x - X0) / 30.0 * SCALE, (Y1 - y) / 30.0 * SCALE)
    # The real Yalong: in each row, the lowest ground within 2.5 km of the design's river.
    real = []
    for y in np.arange(Y0 + 200, Y1 - 200, 150.0):
        xs = np.arange(-3000.0, 3000.0, 30.0)
        c = ((xs - X0) / 30.0).astype(int)
        r = int((Y1 - y) / 30.0)
        k = int(np.argmin(z[r, np.clip(c, 0, z.shape[1] - 1)]))
        real.append((xs[k], y))
    panels = []
    for title, dx, dy, deg in OPTIONS:
        im = base.copy()
        d = ImageDraw.Draw(im)
        d.line([to_px(*p) for p in real], fill=(40, 90, 220), width=4)
        d.line([to_px(*place(x, y, dx, dy, deg)) for x, y in VALLEY_MAP], fill=(250, 250, 250), width=2)
        for name, pts in RIVERS.items():
            d.line([to_px(*place(x, y, dx, dy, deg)) for x, y in pts], fill=(215, 30, 30), width=4)
        for name, (x, y) in PLACES.items():
            px, py = to_px(*place(x, y, dx, dy, deg))
            d.ellipse([px - 6, py - 6, px + 6, py + 6], fill=(215, 30, 30), outline=(255, 255, 255), width=2)
            d.text((px + 9, py - 11), name, font=SMALL, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
        sx, sy = 20, im.height - 30  # a 2 km scale bar
        d.line([(sx, sy), (sx + 2000 / 30.0 * SCALE, sy)], fill=(255, 255, 255), width=4)
        d.text((sx, sy - 26), "2 km", font=SMALL, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
        d.text((im.width - 40, 12), "N", font=FONT, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
        panels.append((title, im))
    w, h = panels[0][1].size
    sheet = Image.new("RGB", (2 * w + 30, h + 150), (250, 248, 243))
    d = ImageDraw.Draw(sheet)
    for k, (title, im) in enumerate(panels):
        sheet.paste(im, (10 + k * (w + 10), 50))
        d.text((10 + k * (w + 10), 14), title, font=FONT, fill=(40, 30, 25))
    d.text((10, h + 60), "Red: the designed rivers (Yalong, Dungchu, Serchu) and places; white outline: the 3.65 x 2.2 km valley map that is sculpted by hand either way.\n"
           "Blue: where the real Yalong runs. KEEP: the real river is about 700 m east of the designed one, so the sculpted valley bends it back at its edges;\n"
           "the real peaks round the town stay as chapter 02 measured them. MOVE: the design fits the real ground about three times better (133 m of height\n"
           "error against 416 m), and the high pass lands on a real ridge; but the site is 6.3 km south, so the far views must be re-checked.", font=SMALL, fill=(40, 30, 25))
    out = os.environ.get("OUT", os.path.join(ROOT, "docs", "terrain", "site-map.jpg"))
    sheet.save(out, quality=88)
    print("site_map: " + out)


if __name__ == "__main__":
    main()
