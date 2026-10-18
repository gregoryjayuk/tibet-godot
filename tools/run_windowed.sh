#!/bin/bash
# Run the game in its own window for an automated job (a shot set, the walk test) without taking the keyboard
# from whoever is typing. Godot activates itself at start-up on macOS whatever the launch flags, so this notes the
# app in front, waits for Godot to take over (under a second) and re-activates that app. The game ignores input
# in these modes. By default --fixed-fps 30 makes every frame exactly 1/30 s, so runs repeat exactly.
# Usage: tools/run_windowed.sh <game arguments...>     e.g. tools/run_windowed.sh --walk-test
# The log goes to $LOG (default tests/out/last_run.log); the exit status is Godot's.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${LOG:-$ROOT/tests/out/last_run.log}"
mkdir -p "$(dirname "$LOG")"
: > "$LOG"
front_bundle() { lsappinfo info -only bundleid "$(lsappinfo front)" | sed -n 's/.*bundleID="\([^"]*\)".*/\1/p'; }
prev="$(front_bundle)"
# ENGINE_ARGS (optional) go before the "--", e.g. ENGINE_ARGS="--quit-after 150" for a short play-mode smoke test.
# FIXED_FPS (default 30) makes runs repeat exactly; timing runs set FIXED_FPS=0 to run in real time.
FIXED="--fixed-fps ${FIXED_FPS:-30}"; [ "${FIXED_FPS:-30}" = "0" ] && FIXED=""
open -W -g -n -a /Applications/Godot.app --args --path "$ROOT" --log-file "$LOG" $FIXED ${ENGINE_ARGS:-} -- "$@" &
pid=$!
# Watchdog: kill the game if it outlives TIMEOUT seconds (default 180), so a hang never leaves a window heating the Mac.
TIMEOUT="${TIMEOUT:-180}"
gpid=""
for _ in $(seq 1 50); do
  gpid="$(pgrep -n -f -- "log-file $LOG" || true)"
  [ -n "$gpid" ] && break
  perl -e 'select(undef,undef,undef,0.1)'
done
if [ -n "$gpid" ]; then
  # One process, detached from our output (an orphaned sleeper holding stdout would stall every caller), killed directly.
  # It also ends the run at once when a script fails to load: the window would otherwise idle until the timeout.
  perl -e 'my ($t, $p, $log) = @ARGV; my $end = time + $t;
    while (time < $end) { select(undef, undef, undef, 0.5); exit 0 unless kill 0, $p;
      if (open(my $r, "<", $log)) { local $/; my $s = <$r>; close $r;
        if ($s =~ /Failed to load script|Parse Error:/) { open(my $f, ">>", $log); print $f "run_windowed: killed: a script failed to load\n"; close $f; kill "TERM", $p; exit 0 } } }
    if (kill 0, $p) { open(my $f, ">>", $log); print $f "run_windowed: killed after $t s\n"; close $f; kill "TERM", $p }' \
    "$TIMEOUT" "$gpid" "$LOG" </dev/null >/dev/null 2>&1 &
  wdog=$!
fi
for _ in $(seq 1 60); do
  [ "$(front_bundle)" = "org.godotengine.godot" ] && break
  perl -e 'select(undef,undef,undef,0.1)'
done
# RETURN_FOCUS=0 skips the handback: when Greg is away on an empty AeroSpace workspace, re-activating the previous app
# would switch workspaces, hide the game window and stop it rendering (docs/ISSUES.md, ISS-012).
if [ "${RETURN_FOCUS:-1}" = "1" ] && [ -n "$prev" ] && [ "$prev" != "org.godotengine.godot" ]; then
  osascript -e "tell application id \"$prev\" to activate" >/dev/null 2>&1 || true
fi
wait "$pid"
[ -n "${wdog:-}" ] && kill "$wdog" 2>/dev/null
exit 0
