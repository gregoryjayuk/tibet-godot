#!/bin/bash
# Kenney's two CC0 audio packs (plan chapter 10, 11.2; downloaded with Greg's yes, 27 Sep 2026, 20:06: RPG Audio,
# 964,837 bytes, and Impact Sounds, 800,850 bytes, from kenney.nl), pinned by their checksums, unpacked (the sounds and
# the licence only) into audio_src/lib/kenney/ for tools/audio/process.py. Kept out of git: this script is their source.
# Run: tools/audio/fetch_kenney.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIR="$ROOT/audio_src/lib/kenney"
mkdir -p "$DIR"
cd "$DIR"
get() {  # name url sha256 folder
  if [ ! -f "$1" ] || ! echo "$3  $1" | shasum -a 256 -c --quiet - 2>/dev/null; then
    curl -sSL -o "$1" "$2"
  fi
  echo "$3  $1" | shasum -a 256 -c --quiet -
  mkdir -p "$4"
  unzip -q -o "$1" "*.ogg" "*.txt" -d "$4"
}
get kenney_rpg-audio.zip "https://kenney.nl/media/pages/assets/rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip" 6dbeaf8544da958d8f2adcb4a4a4b76c1ade34a05f8ab9edccd327da7375f38b rpg
get kenney_impact-sounds.zip "https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip" 029d734af1582474edf3a694d1b0cebc97c1c152f2f39fa34d4c2bafc5de77f8 impact
echo "fetch_kenney: $(find rpg impact -name '*.ogg' | wc -l | tr -d ' ') sounds in audio_src/lib/kenney"
