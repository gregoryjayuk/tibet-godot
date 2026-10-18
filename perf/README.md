# perf/ — performance measurements

`history.csv` gets one summary line per viewpoint per pass from `tools/perf/run_route.sh` (spike S0; plan chapter 11, 19.7), with the commit it measured. `runs/` (not versioned) keeps each run's per-frame CSVs and logs.

How to read the columns:
- `p50_ms` … `worst_ms`: the real interval between frames, measured each frame. Capped at 30 fps, a healthy frame is 33.3 ms. Uncapped (vsync off, no cap), a frame lasts as long as its slowest part. When the CPU figures are small, that is the GPU's time, the only GPU estimate available here: Godot's GPU timer reads 0 on Metal and the Metal HUD's log is redacted (the repository's docs/ISSUES.md, ISS-011).
- `engine_process_ms`, `engine_physics_ms`: Godot's TIME_PROCESS and TIME_PHYSICS_PROCESS monitors. The engine samples them once a second and repeats them in between, so they show trends, not per-frame costs.
- `render_cpu_ms`: the viewport's measured CPU render time plus frame setup, per frame.
- `draw_calls`, `objects` (means) and `primitives_max`: per frame, from the rendering server.
- `valid`: "NO (not redrawn)" when the draw calls and primitives never changed while the camera turned a full circle, meaning the window was hidden or covered and nothing was drawn. Such rows are not measurements.
