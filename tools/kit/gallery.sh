#!/bin/bash
# Stills of the kit gallery (tests/kit/gallery.tscn) into tests/kit/out/, or tests/kit/out/lod<N>/ with LOD=1 or 2
# (that level shown at every distance, to inspect it up close).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EXTRA=""; [ -n "${LOD:-}" ] && EXTRA="--lod=$LOD"
[ -n "${SET:-}" ] && EXTRA="$EXTRA --set=$SET"
ENGINE_ARGS="res://tests/kit/gallery.tscn" LOG="$ROOT/tests/out/gallery.log" "$ROOT/tools/run_windowed.sh" $EXTRA
grep -E "^gallery: done|ERROR" "$ROOT/tests/out/gallery.log"
