extends Node
## Command-line test modes (plan chapter 11, 19.6–19.7; docs/DECISIONS.md, 25 Sep 2026), run through
## tools/run_windowed.sh, which keeps the keyboard with whoever is typing:
## - shot sets: --shot-set=<json> (or --view=N --shot=<png>). The world is frozen (time, particles, monks, the player)
##   and the seed fixed; each shot waits a minimum number of frames for temporal effects to settle, then for a quiet
##   frame (no new pipeline compilations for 10 frames), so two runs compare at ΔE 0 whatever the timing.
## - the walk test: --walk-test. Stand at viewpoint 1, settle for a second, run up the stair alley for four seconds;
##   pass when the body travelled more than 10 m and climbed the stair (more than 2 m up).
## - the performance route: --perf-route=<run folder> [--perf-uncapped] [--perf-commit=<hash>]. At each draft
##   viewpoint: settle 2 s of real time, then log every frame to CSV for 240 frames while turning a full circle; append a summary
##   line per viewpoint to perf/history.csv. Play-mode quality (the tier's pixel budget) and the thermal helper run.

const QUIET_FRAMES := 10
const QUIET_CAP := 300
const PERF_SETTLE_S := 2.0  ## seconds, not frames: the engine's CPU monitors are one-second samples
const PERF_FRAMES := 240
const HISTORY := "res://perf/history.csv"
const HISTORY_COLUMNS := ["date", "commit", "route", "view", "mode", "frames", "p50_ms", "p95_ms", "p99_ms", "worst_ms",
		"engine_process_ms", "engine_physics_ms", "render_cpu_ms", "draw_calls", "primitives_max", "objects", "mem_static_mb_max",
		"mem_video_mb_max", "mpx_3d", "tier", "thermal", "valid"]

var world: Node3D  ## world/vignette.gd
var player: CharacterBody3D  ## player/player.gd
var hud: CanvasLayer  ## ui/hud.gd

var shot_cfg := {}
var shot_index := -1
var shot_wait := -1
var quiet_seen := -1
var quiet_count := 0
var quiet_waited := 0
var walk_test := -1
var walk_start := Vector3.ZERO
var perf := {}
var soak := {}


func active() -> bool:
	return not shot_cfg.is_empty() or walk_test >= 0 or not perf.is_empty() or not soak.is_empty()


# ------------------------------------------------------------------ shots
func start_shots(cfg: Dictionary) -> void:
	shot_cfg = cfg
	var size: Array = cfg.get("size", [1600, 900])
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT  # render at exactly this size, whatever the window
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = Vector2i(int(size[0]), int(size[1]))
	get_viewport().scaling_3d_scale = 1.0
	_quiet()
	player.frozen = true
	world.set_physics_process(false)  # the monks stand where they were placed
	WorldClock.freeze(20.0)
	for p in world.find_children("*", "GPUParticles3D", true, false):
		(p as GPUParticles3D).speed_scale = 0.0  # already prewarmed; frozen so every run matches
	shot_index = -1
	_next_shot(int(cfg.get("first_wait", 75)))


func _next_shot(wait: int) -> void:
	shot_index += 1
	var shots: Array = shot_cfg["shots"]
	if shot_index >= shots.size():
		get_tree().quit()
		return
	player.teleport(int(shots[shot_index].get("view", 1)) - 1)
	shot_wait = wait
	quiet_seen = -1
	quiet_count = 0
	quiet_waited = 0


func _pipelines() -> int:
	return int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)
			+ Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)
			+ Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE)
			+ Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH))


func _shot_tick() -> void:
	if shot_wait > 0:
		shot_wait -= 1
		return
	# The minimum wait is over: now wait for a quiet frame.
	var p := _pipelines()
	quiet_count = quiet_count + 1 if p == quiet_seen else 0
	quiet_seen = p
	quiet_waited += 1
	if quiet_count >= QUIET_FRAMES or quiet_waited >= QUIET_CAP:
		if quiet_waited >= QUIET_CAP:
			push_warning("shot %d: no quiet frame after %d frames; taken anyway" % [shot_index + 1, QUIET_CAP])
		_take_shot()


func _take_shot() -> void:
	var spec: Dictionary = shot_cfg["shots"][shot_index]
	var out := abs_path(String(spec["out"]))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("shot ", shot_index + 1, "/", shot_cfg["shots"].size(), ": view ", spec.get("view", 1), " -> ", out, " (", img.get_width(), " x ", img.get_height(), ", quiet after ", quiet_waited, " frames)")
	_next_shot(int(shot_cfg.get("wait", 45)))


# ------------------------------------------------------------------ walk test
func start_walk_test() -> void:
	_quiet()
	player.teleport(0)
	walk_test = 5 * Engine.physics_ticks_per_second  # 1 s to settle, then 4 s of running, at any tick rate


func _walk_test_tick() -> void:
	walk_test -= 1
	if walk_test == 4 * Engine.physics_ticks_per_second:
		walk_start = player.global_position
		player.scripted = true
		player.scripted_move = Vector3(0.0, 1.0, -1.0)  # forward, running
	elif walk_test == 0:
		player.scripted_move = Vector3.ZERO
		var d := player.global_position - walk_start
		var flat := Vector2(d.x, d.z).length()
		var ok := flat > 10.0 and d.y > 2.0
		print("walk test: %s  moved %.1f m, climbed %.2f m, on floor %s, from %s to %s" % ["PASS" if ok else "FAIL", flat, d.y, player.is_on_floor(), walk_start, player.global_position])
		get_tree().quit(0 if ok else 1)


# ------------------------------------------------------------------ performance route
func start_perf_route(run_dir: String, uncapped: bool, commit: String, canvas := Vector2i.ZERO, scale3d := -1.0, upscaler := "") -> void:
	_quiet()
	player.frozen = true  # standing still; the camera turns
	if canvas != Vector2i.ZERO:
		# A fixed canvas: the 3D is rendered at exactly this size (e.g. 3840 × 2160) and shrunk into the window, so the
		# GPU does the full work whatever size the window manager gives the window.
		var win := get_window()
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = canvas
	if scale3d > 0.0:
		get_viewport().scaling_3d_scale = scale3d
		var modes := {"bilinear": Viewport.SCALING_3D_MODE_BILINEAR, "fsr": Viewport.SCALING_3D_MODE_FSR, "fsr2": Viewport.SCALING_3D_MODE_FSR2,
				"metalfx_spatial": Viewport.SCALING_3D_MODE_METALFX_SPATIAL, "metalfx_temporal": Viewport.SCALING_3D_MODE_METALFX_TEMPORAL}
		get_viewport().scaling_3d_mode = modes.get(upscaler, Viewport.SCALING_3D_MODE_BILINEAR)
		Telemetry.event("render", {"canvas": [canvas.x, canvas.y], "scale3d": scale3d, "upscaler": upscaler})
	else:
		Quality.track(get_viewport())
	Quality.start_thermal()
	if uncapped:
		Quality.uncapped = true  # kept off through tier changes (on battery the policy changes tier)
		Engine.max_fps = 0  # with --disable-vsync on the command line: a GPU-bound frame then lasts as long as the GPU's work
	var route := "draft5" if canvas == Vector2i.ZERO else "draft5@%dx%d" % [canvas.x, canvas.y]
	if scale3d > 0.0:
		route += "x%.3f%s" % [scale3d, ("+" + upscaler) if upscaler != "" else ""]
	perf = {"dir": abs_path(run_dir), "mode": "uncapped" if uncapped else "capped", "commit": commit, "view": 0, "frame": 0, "rows": [], "route": route}
	_perf_view()


func _perf_view() -> void:
	perf["view"] += 1
	if perf["view"] > world.VIEWS.size():
		Quality.stop_thermal()
		get_tree().quit()
		return
	player.teleport(perf["view"] - 1)
	perf["frame"] = -1_000_000  # settling: counted by time, see _perf_tick
	perf["settle_until"] = Time.get_ticks_msec() + int(PERF_SETTLE_S * 1000.0)
	perf["rows"] = []
	perf["yaw0"] = player.yaw


func _perf_tick() -> void:
	if perf["frame"] < 0:
		if Time.get_ticks_msec() < perf["settle_until"]:
			return
		perf["frame"] = -1
	perf["frame"] += 1
	var f: int = perf["frame"]
	if f == 0:
		Telemetry.tag = "v%d_%s" % [perf["view"], perf["mode"]]
		Telemetry.start_csv(perf["dir"].path_join("v%d_%s.csv" % [perf["view"], perf["mode"]]))
	elif f > 0:
		player.yaw = perf["yaw0"] + TAU * float(f) / PERF_FRAMES  # a full circle over the logged frames
		player.rotation.y = player.yaw
		perf["rows"].append(Telemetry.sample(1000.0 / maxf(Engine.get_frames_per_second(), 1.0)))
		if f >= PERF_FRAMES:
			Telemetry.stop_csv()
			Telemetry.tag = ""
			_perf_summary()
			_perf_view()


func _perf_summary() -> void:
	# Frame intervals come from the CSV Telemetry just wrote (measured between frames); the rest from the samples.
	var intervals := PackedFloat32Array()
	var csv := FileAccess.open(perf["dir"].path_join("v%d_%s.csv" % [perf["view"], perf["mode"]]), FileAccess.READ)
	csv.get_line()
	while not csv.eof_reached():
		var cols := csv.get_line().split(",")
		if cols.size() > 1:
			intervals.append(float(cols[1]))
	intervals.sort()
	var rows: Array = perf["rows"]
	var n := intervals.size()
	var mean := func(key: String) -> float:
		var t := 0.0
		for r in rows:
			t += float(r[key])
		return t / maxf(rows.size(), 1.0)
	var maxv := func(key: String) -> float:
		var m := 0.0
		for r in rows:
			m = maxf(m, float(r[key]))
		return m
	# A view whose draw calls and primitives never change while the camera turns was not being redrawn: the window was
	# hidden or covered (AeroSpace moves windows of other workspaces off screen). Its numbers are not measurements.
	var seen := {}
	for r in rows:
		seen["%d/%d" % [r["primitives"], r["draw_calls"]]] = true
	var valid := seen.size() > 1
	if not valid:
		push_warning("perf: view %d %s drew no new frames (window hidden or covered?); marked invalid" % [perf["view"], perf["mode"]])
	var vp := get_viewport()
	var line := {
		"date": Time.get_datetime_string_from_system(), "commit": perf["commit"], "route": perf["route"], "view": perf["view"],
		"mode": perf["mode"], "frames": n,
		"p50_ms": intervals[n / 2], "p95_ms": intervals[mini(n - 1, int(n * 0.95))], "p99_ms": intervals[mini(n - 1, int(n * 0.99))],
		"worst_ms": intervals[n - 1],
		"engine_process_ms": mean.call("engine_process_ms"), "engine_physics_ms": mean.call("engine_physics_ms"), "render_cpu_ms": mean.call("render_cpu_ms"),
		"draw_calls": mean.call("draw_calls"), "primitives_max": maxv.call("primitives"), "objects": mean.call("objects"),
		"mem_static_mb_max": maxv.call("mem_static_mb"), "mem_video_mb_max": maxv.call("mem_video_mb"),
		"mpx_3d": vp.get_visible_rect().size.x * vp.get_visible_rect().size.y * vp.scaling_3d_scale * vp.scaling_3d_scale / 1000000.0,
		"tier": Quality.tier, "thermal": Telemetry.thermal, "valid": "yes" if valid else "NO (not redrawn)",
	}
	var path := ProjectSettings.globalize_path(HISTORY)
	var fresh := not FileAccess.file_exists(path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var h := FileAccess.open(path, FileAccess.READ_WRITE if not fresh else FileAccess.WRITE)
	if fresh:
		h.store_line(",".join(HISTORY_COLUMNS))
	h.seek_end()
	var out := PackedStringArray()
	for c in HISTORY_COLUMNS:
		var v = line[c]
		out.append(("%.2f" % v) if typeof(v) == TYPE_FLOAT else str(v))
	h.store_line(",".join(out))
	h.close()
	print("perf: %sview %d %s: p50 %.1f ms, p95 %.1f, p99 %.1f, worst %.1f; engine process %.2f, physics %.2f (1 s samples), render CPU %.2f ms; %d draw calls, %.2f M primitives; video %.0f MB; %.2f Mpx; thermal %s" % [
		"" if valid else "INVALID ", perf["view"], perf["mode"], line["p50_ms"], line["p95_ms"], line["p99_ms"], line["worst_ms"], line["engine_process_ms"],
		line["engine_physics_ms"], line["render_cpu_ms"], int(line["draw_calls"]), line["primitives_max"] / 1000000.0,
		line["mem_video_mb_max"], line["mpx_3d"], line["thermal"]])


# ------------------------------------------------------------------ heat soak
## --soak=<minutes> (roadmap RT-06, spike S1): cycle the five viewpoints, 60 s each while turning, logging every frame
## and every thermal state; at the end print the average fps, the 1% low and the time spent in each thermal state, and
## pass when the average is at least 29.5 fps, the 1% low at least 25 fps and the Mac stayed "nominal" or "fair".
func start_soak(minutes: float, run_dir: String, canvas := Vector2i.ZERO) -> void:
	_quiet()
	player.frozen = true
	if canvas != Vector2i.ZERO:
		var win := get_window()
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = canvas
		get_viewport().scaling_3d_scale = 1.0
	else:
		Quality.track(get_viewport())
	Quality.start_thermal()
	var dir := abs_path(run_dir)
	Telemetry.tag = "soak"
	Telemetry.start_csv(dir.path_join("soak.csv"))
	soak = {"dir": dir, "end": Time.get_ticks_msec() + int(minutes * 60000.0), "start": Time.get_ticks_msec(), "view": -1,
			"next_view": 0, "frames": PackedFloat32Array(), "last": Time.get_ticks_usec(), "states": {}, "state_since": Time.get_ticks_msec(),
			"state": Telemetry.thermal, "minutes": minutes}


func _soak_tick() -> void:
	var now := Time.get_ticks_msec()
	var us := Time.get_ticks_usec()
	soak["frames"].append((us - soak["last"]) / 1000.0)
	soak["last"] = us
	if Telemetry.thermal != soak["state"]:
		soak["states"][soak["state"]] = soak["states"].get(soak["state"], 0) + now - soak["state_since"]
		soak["state"] = Telemetry.thermal
		soak["state_since"] = now
	if now >= soak["next_view"]:
		soak["view"] = (soak["view"] + 1) % world.VIEWS.size()
		player.teleport(soak["view"])
		soak["yaw0"] = player.yaw
		soak["view_start"] = now
		soak["next_view"] = now + 60000
	player.yaw = soak["yaw0"] + TAU * float(now - soak["view_start"]) / 60000.0
	player.rotation.y = player.yaw
	if now >= soak["end"]:
		_soak_finish()


func _soak_finish() -> void:
	var now := Time.get_ticks_msec()
	soak["states"][soak["state"]] = soak["states"].get(soak["state"], 0) + now - soak["state_since"]
	Telemetry.stop_csv()
	var f: PackedFloat32Array = soak["frames"]
	f = f.slice(30)  # the first second after start-up is not part of the soak
	var total := 0.0
	for x in f:
		total += x
	var sorted := f.duplicate()
	sorted.sort()
	var avg_fps := 1000.0 * f.size() / maxf(total, 1.0)
	var low_fps := 1000.0 / sorted[mini(sorted.size() - 1, int(sorted.size() * 0.99))]
	var states := {}
	for k in soak["states"]:
		states[k] = snappedf(soak["states"][k] / 60000.0, 0.1)
	var ok_thermal := not (states.has("serious") or states.has("critical"))
	var ok: bool = avg_fps >= 29.5 and low_fps >= 25.0 and ok_thermal
	print("soak: %s  %.0f min, %d frames, average %.2f fps, 1%% low %.1f fps, worst frame %.1f ms, minutes per thermal state %s" % [
			"PASS" if ok else "FAIL", soak["minutes"], f.size(), avg_fps, low_fps, sorted[sorted.size() - 1], JSON.stringify(states)])
	Quality.stop_thermal()
	get_tree().quit(0 if ok else 1)


# ------------------------------------------------------------------ shared
func _quiet() -> void:
	# Godot takes focus at start-up on macOS (ISS-008): stray keystrokes must do nothing.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	player.set_process_unhandled_input(false)
	hud.visible = false


func _physics_process(_dt: float) -> void:
	if not shot_cfg.is_empty() and shot_index >= 0:
		_shot_tick()
	if walk_test > 0:
		_walk_test_tick()


func _process(_dt: float) -> void:
	if not perf.is_empty():
		_perf_tick()
	if not soak.is_empty():
		_soak_tick()


static func abs_path(path: String) -> String:
	## Paths may be absolute or relative to the project folder.
	return path if path.is_absolute_path() else ProjectSettings.globalize_path("res://" + path)
