#!/bin/bash
# Fetch the third-party files milestone M0 needs, exactly the list Greg approved on 25 Sep 2026 (roadmap RT-05,
# RT-07, RT-11, RT-12, RT-13; sizes, licences and sources in docs/VENDOR.md). Raw downloads go to ~/.cache/dungkardo/
# (outside the repository); what the project uses is then copied into it.
# Every file's size and SHA-256 are appended to $CACHE/manifest.tsv. Re-running skips files already present.
# RATE (default 3M bytes/s) keeps a video call usable while it runs.
set -uo pipefail
CACHE="${CACHE:-$HOME/.cache/dungkardo}"
RATE="${RATE:-3M}"
mkdir -p "$CACHE/downloads" "$CACHE/dem"
MANIFEST="$CACHE/manifest.tsv"
[ -f "$MANIFEST" ] || printf 'file\tbytes\tsha256\tsource\n' > "$MANIFEST"
get() {  # get <url> <destination>
  local url="$1" dst="$2"
  if [ -s "$dst" ]; then echo "have  $(basename "$dst")"; return 0; fi
  if curl -fL --retry 3 --retry-delay 5 --limit-rate "$RATE" -o "$dst.part" "$url"; then
    mv "$dst.part" "$dst"
    printf '%s\t%s\t%s\t%s\n' "$(basename "$dst")" "$(stat -f %z "$dst")" "$(shasum -a 256 "$dst" | cut -d' ' -f1)" "$url" >> "$MANIFEST"
    echo "got   $(basename "$dst") ($(du -h "$dst" | cut -f1))"
  else
    rm -f "$dst.part"; echo "FAILED $url"; return 1
  fi
}
D="$CACHE/downloads"
# RT-05: tests
get https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip "$D/Gut-9.7.1.zip"
# RT-07: fonts (OFL)
GF=https://raw.githubusercontent.com/google/fonts/main/ofl
get "$GF/jomolhari/Jomolhari-Regular.ttf" "$D/Jomolhari-Regular.ttf"
get "$GF/jomolhari/OFL.txt" "$D/Jomolhari-OFL.txt"
get "$GF/notoseriftibetan/NotoSerifTibetan%5Bwght%5D.ttf" "$D/NotoSerifTibetan[wght].ttf"
get "$GF/notoseriftibetan/OFL.txt" "$D/NotoSerifTibetan-OFL.txt"
get https://raw.githubusercontent.com/notofonts/noto-cjk/main/Serif/SubsetOTF/TC/NotoSerifTC-Regular.otf "$D/NotoSerifTC-Regular.otf"
get https://raw.githubusercontent.com/notofonts/noto-cjk/main/Serif/LICENSE "$D/NotoSerifCJK-LICENSE.txt"
get "$GF/notoserif/NotoSerif%5Bwdth,wght%5D.ttf" "$D/NotoSerif[wdth,wght].ttf"
get "$GF/notoserif/OFL.txt" "$D/NotoSerif-OFL.txt"
# RT-11: the six Copernicus GLO-30 elevation tiles (credit line required; docs/VENDOR.md)
for t in N29_00_E100_00 N29_00_E101_00 N29_00_E102_00 N30_00_E100_00 N30_00_E101_00 N30_00_E102_00; do
  k="Copernicus_DSM_COG_10_${t}_DEM"
  get "https://copernicus-dem-30m.s3.amazonaws.com/$k/$k.tif" "$CACHE/dem/$k.tif"
done
# RT-12: terrain
get https://github.com/TokisanGames/Terrain3D/releases/download/v1.0.2-stable/Terrain3D_v1.0.2-stable.zip "$D/Terrain3D_v1.0.2-stable.zip"
# RT-13: bodies, crowd animation
get "https://extensions.blender.org/download/sha256:4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87/add-on-mpfb-v2.0.17.zip" "$D/add-on-mpfb-v2.0.17.zip"
get https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip "$D/makehuman_system_assets_cc0.zip"
get https://raw.githubusercontent.com/antzGames/Godot_VAT_Blender_Tool/v0.0.2/vertex_animation.py "$D/vertex_animation-0.0.2.py"
echo "done; manifest: $MANIFEST"
