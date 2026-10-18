#!/bin/bash
# The player's face at 1 m, 3 m and 10 m in the game's light (tests/people/face.gd; M1 sprint 5, step 4), then the
# sheet: tests/people/out/face_sheet.jpg.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Usage: tools/people/face.sh [man,woman]   (two bodies; the player's by default)
EXTRA=""
[ -n "${1:-}" ] && EXTRA=" -- --kinds=$1"
RETURN_FOCUS="${RETURN_FOCUS:-0}" TIMEOUT=200 ENGINE_ARGS="res://tests/people/face.tscn$EXTRA" "$ROOT/tools/run_windowed.sh"
grep -E "^face:|SCRIPT ERROR|SHADER ERROR" "$ROOT/tests/out/last_run.log"
"$ROOT/tools/py" - "$ROOT/tests/people/out" "${1:-}" <<'PY'
import os, sys
from PIL import Image
d = sys.argv[1]
import sys as _s
kinds = _s.argv[2].split(",") if len(_s.argv) > 2 and _s.argv[2] else []
if len(kinds) > 2:  # a line: the portraits cropped square, four a row, then the line from the front and behind
    ims = [Image.open(os.path.join(d, "face_close_%s.png" % k)).convert("RGB").crop((600, 180, 1320, 900)).resize((480, 480)) for k in kinds]
    lines = [Image.open(os.path.join(d, "face_line_%s.png" % v)).convert("RGB").resize((960, 540)) for v in ("front", "back")]
    rows = (len(ims) + 3) // 4
    sheet = Image.new("RGB", (1920, rows * 480 + 540), (40, 40, 40))
    for i, im in enumerate(ims):
        sheet.paste(im, ((i % 4) * 480, (i // 4) * 480))
    for i, im in enumerate(lines):
        sheet.paste(im, (i * 960, rows * 480))
else:
    names = ["face_close_man", "face_close_woman", "face_1m_man", "face_1m_woman", "face_3m", "face_10m"]
    ims = [Image.open(os.path.join(d, n + ".png")).convert("RGB") for n in names]
    w, h = 960, 540
    sheet = Image.new("RGB", (2 * w, 3 * h))
    for i, im in enumerate(ims):
        sheet.paste(im.resize((w, h)), ((i % 2) * w, (i // 2) * h))
sheet.save(os.path.join(d, "face_sheet.jpg"), quality=90)
print("face: sheet", os.path.join(d, "face_sheet.jpg"))
PY
