#!/bin/bash
# A body's garments in its worst poses (sprint 5, step 2): builds the body in Blender without touching the game's files
# (../tibet-blender/people2/pose_sheet.py), renders the rest pose and the arm clips' frames with back faces culled, as
# the game draws them (characters/person.gdshader), and lays them out on tests/people/out/pose_<body>_sheet.jpg.
# Usage: tools/people/pose_sheet.sh [body] [--wire] [--close]   (body: player_man by default; any of body.py's
#        BODIES or TOWN; --wire draws the mesh's edges on a second still of each; --close frames the left shoulder)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BODY="${1:-player_man}"
shift || true
OUT="$ROOT/tests/people/out/pose_$BODY"
rm -rf "${OUT:?}"
BLENDER_USER_RESOURCES=~/.cache/dungkardo/blender /Applications/Blender.app/Contents/MacOS/Blender -b \
  --python "$ROOT/../tibet-blender/people2/pose_sheet.py" -- "$BODY" "$OUT" "$@" > "$ROOT/tests/out/pose_sheet.log" 2>&1
grep -E "^pose_sheet:|^chuba:|Traceback" "$ROOT/tests/out/pose_sheet.log"
"$ROOT/tools/py" - "$OUT" "$ROOT/tests/people/out/pose_${BODY}_sheet.jpg" <<'EOF'
import os, sys
from PIL import Image, ImageDraw
src, dst = sys.argv[1], sys.argv[2]
names = sorted(n for n in os.listdir(src) if n.endswith(".png"))
if not names:
    sys.exit("pose_sheet: no stills")
w, h = Image.open(os.path.join(src, names[0])).size
cols = 6
rows = (len(names) + cols - 1) // cols
sheet = Image.new("RGB", (cols * w, rows * (h + 18)), (40, 40, 40))
dr = ImageDraw.Draw(sheet)
for i, n in enumerate(names):
    x, y = (i % cols) * w, (i // cols) * (h + 18)
    sheet.paste(Image.open(os.path.join(src, n)).convert("RGB"), (x, y + 18))
    dr.text((x + 4, y + 3), n[:-4], fill=(230, 230, 230))
sheet.save(dst, quality=88)
print("pose_sheet: sheet", dst)
EOF
