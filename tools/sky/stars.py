#!/usr/bin/env python3
"""The night sky's stars (art step A6; plan chapter 09, 9.1): the Yale Bright Star Catalogue, 5th revised edition
(~/.cache/dungkardo/downloads/bsc5-catalog.gz, docs/VENDOR.md), down to magnitude 5.5, written to data/stars.json as
[right ascension, declination, V magnitude, B-V colour] in degrees and magnitudes, brightest first. The positions are
the catalogue's equinox B1900, epoch 1900.0, which is within 2.5 arcminutes of 1903's sky (J2000's is 1.35 deg away),
so the game's sidereal time, reckoned for the equinox of date, puts them right. The 40 brightest keep their names
for the four-point glint. Run: tools/py tools/sky/stars.py
"""
import gzip
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.expanduser("~/.cache/dungkardo/downloads/bsc5-catalog.gz")
OUT = os.path.join(ROOT, "data", "stars.json")
LIMIT = 5.5


def field(line, a, b):
    return line[a - 1:b].strip()


def main():
    stars = []
    for raw in gzip.open(SRC, "rt", encoding="latin-1"):
        line = raw.rstrip("\n").ljust(197)
        rah, ram, ras = field(line, 61, 62), field(line, 63, 64), field(line, 65, 68)
        sign, ded, dem, des = field(line, 69, 69), field(line, 70, 71), field(line, 72, 73), field(line, 74, 75)
        vmag = field(line, 103, 107)
        if not (rah and ded and vmag):
            continue  # the catalogue's few entries without a position (novae, withdrawn stars)
        v = float(vmag)
        if v > LIMIT:
            continue
        ra = (int(rah) + int(ram) / 60.0 + float(ras) / 3600.0) * 15.0
        dec = int(ded) + int(dem) / 60.0 + int(des) / 3600.0
        if sign == "-":
            dec = -dec
        bv = field(line, 110, 114)
        stars.append([round(ra, 4), round(dec, 4), v, float(bv) if bv else 0.6, field(line, 5, 14)])
    stars.sort(key=lambda s: s[2])
    out = {"about": "The night sky's stars, from the Yale Bright Star Catalogue, 5th revised edition (Hoffleit and Warren 1991, CDS V/50), to V 5.5: [RA, Dec (equinox B1900, degrees), V magnitude, B-V]; the 40 brightest carry their catalogue name. Built by tools/sky/stars.py.",
           "equinox": "B1900", "limit": LIMIT, "count": len(stars),
           "stars": [s[:4] + ([s[4]] if i < 40 else []) for i, s in enumerate(stars)]}
    json.dump(out, open(OUT, "w"), separators=(",", ":"))
    print("stars: %d to V %.1f -> %s (%d bytes); brightest %s" % (len(stars), LIMIT, OUT, os.path.getsize(OUT), [s[4] for s in stars[:5]]))
    # how often two stars fall in one 0.5 deg cell of right ascension and declination (the shader's grid)
    cells = {}
    for ra, dec, v, bv, _ in stars:
        k = (int(ra / 0.5), int((dec + 90.0) / 0.5))
        cells[k] = cells.get(k, 0) + 1
    print("cells with more than one star: %d of %d occupied" % (sum(1 for c in cells.values() if c > 1), len(cells)))


if __name__ == "__main__":
    main()
