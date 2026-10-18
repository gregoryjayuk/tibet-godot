#!/usr/bin/env python3
"""Spike S5's pop test (plan chapter 05, 13.2: "hand-over without a pop"): tests/crowd/out/pop_{skeletal,vat,empty}_{noshadow,shadow}.png
are one frozen instant with the people within 38 m drawn skeletal, then VAT, then not at all, once without shadows
(the figures alone) and once with every tier casting them. The figures' pixels are where the skeletal image differs
from the empty one; the pop is the share of those that change between skeletal and VAT by more than ΔE 8 (CIE76, the
shot checks' threshold). Run: tools/py tools/perf/s5_pop.py
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "tests", "crowd", "out")


def lab(path):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=np.float64) / 255.0
    a = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = a @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 216 / 24389, np.cbrt(xyz), (24389 / 27 * xyz + 16) / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def measure(suffix):
    s, v, e = (lab(os.path.join(OUT, "pop_%s_%s.png" % (n, suffix))) for n in ("skeletal", "vat", "empty"))
    figure = np.linalg.norm(s - e, axis=-1) > 8
    changed = (np.linalg.norm(s - v, axis=-1) > 8) & figure
    return int(figure.sum()), changed.sum() / max(int(figure.sum()), 1)


def main():
    n, share = measure("noshadow")
    print("s5_pop: without shadows the figures cover %d pixels; %.1f%% of them change by more than ΔE 8 between skeletal and VAT" % (n, 100 * share))
    n, share = measure("shadow")
    print("s5_pop: with every tier casting shadows, figures and shadows cover %d pixels; %.1f%% change" % (n, 100 * share))


if __name__ == "__main__":
    main()
