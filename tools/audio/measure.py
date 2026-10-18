#!/usr/bin/env python3
"""A sound run's loudness (plan chapter 10, 13.11; M1 sprint 8, step 1): a WAV recorded off the Master bus by
tests/terrain/s3.gd's --sound mode, second by second (RMS, dBFS), with its integrated loudness and true peak by
ffmpeg's EBU R128 meter. A script cannot listen; this is the half of the check a script can do.
Run: tools/py tools/audio/measure.py tests/audio/out/sound_<station>_<hour>.wav
"""
import re
import subprocess
import sys

import numpy as np

sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
from wav import read_wav  # noqa: E402


def main(path):
    x, rate = read_wav(path)
    mono = x.mean(axis=1) if x.ndim > 1 else x
    secs = len(mono) // rate
    rows = []
    for s in range(secs):
        seg = mono[s * rate:(s + 1) * rate]
        rms = float(np.sqrt(np.mean(seg ** 2)))
        rows.append(20 * np.log10(max(rms, 1e-9)))
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True)
    i = re.findall(r"I:\s+(-?[\d.]+) LUFS", r.stderr)
    tp = re.findall(r"Peak:\s+(-?[\d.]+) dBFS", r.stderr)
    print("measure: %s, %d s, %d Hz" % (path, secs, rate))
    print("measure: dBFS a second: " + " ".join("%.0f" % v for v in rows))
    print("measure: integrated %s LUFS, true peak %s dBFS" % (i[-1] if i else "?", tp[-1] if tp else "?"))


if __name__ == "__main__":
    main(sys.argv[1])
