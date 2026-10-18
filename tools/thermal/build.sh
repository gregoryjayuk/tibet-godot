#!/bin/bash
# Build the thermal helper into tools/bin/ (ignored by git) when it is missing or older than its source.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="$ROOT/tools/bin/dk-thermal"
SRC="$ROOT/tools/thermal/dk-thermal.swift"
if [ ! -x "$BIN" ] || [ "$SRC" -nt "$BIN" ]; then
  mkdir -p "$ROOT/tools/bin"
  swiftc -O -o "$BIN" "$SRC"
fi
echo "$BIN"
