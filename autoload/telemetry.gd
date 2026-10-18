extends Node
## Telemetry (plan chapter 11, 19.7): the debug overlay (F3, which is fn+F3 on the MacBook's keyboard, or the ` key),
## the per-frame CSV logger and events. GPU time cannot be read on this Mac yet: Godot's GPU timer is 0.0 under Metal
## and the Metal HUD's log is redacted as <private> (tested 25 Sep 2026; docs/ISSUES.md, ISS-011), so the GPU cost is
## estimated from uncapped runs, where a GPU-bound frame lasts as long as the GPU's work (tools/perf/run_route.sh).

const COLUMNS := ["t_s", "frame_ms", "engine_process_ms", "engine_physics_ms", "render_cpu_ms", "objects", "primitives", "draw_calls",
		"mem_static_mb", "mem_video_mb", "pipe_draw", "pipe_spec", "scale_3d", "tier", "thermal", "tag"]
const MB := 1048576.0

var tag := ""  ## set by the route runner: what is being measured (e.g. "v3_capped")
var thermal := "unknown"  ## the thermal helper's last state, set by Quality
var _csv: FileAccess
var _t0 := 0
var _last_usec := 0
var _frame := 0
var _recent := PackedFloat32Array()  ## the last 60 frame intervals, for the overlay
var _layer: CanvasLayer
var _overlay: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	var scale := DisplayServer.screen_get_scale()
	_overlay = Label.new()
	_overlay.position = Vector2(12, 48) * scale
	_overlay.add_theme_font_size_override("font_size", int(13 * scale))
	_overlay.add_theme_color_override("font_color", Color(1, 1, 0.9))
	_overlay.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_overlay.add_theme_constant_override("shadow_offset_x", 1)
	_overlay.add_theme_constant_override("shadow_offset_y", 1)
	_overlay.visible = false
	_layer.add_child(_overlay)


func event(kind: String, data: Dictionary = {}) -> void:
	print("telemetry: ", kind, " ", JSON.stringify(data))


## Start writing one CSV row per frame to this absolute path.
func start_csv(path: String) -> void:
	stop_csv()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	_csv = FileAccess.open(path, FileAccess.WRITE)
	_csv.store_line(",".join(COLUMNS))
	_t0 = Time.get_ticks_usec()


func stop_csv() -> void:
	if _csv != null:
		_csv.close()
		_csv = null


## The numbers for the frame just finished, keyed like COLUMNS.
func sample(frame_ms: float) -> Dictionary:
	var vp := get_viewport()
	var rid := vp.get_viewport_rid()
	return {
		"t_s": (Time.get_ticks_usec() - _t0) / 1000000.0,
		"frame_ms": frame_ms,
		# Godot samples TIME_PROCESS and TIME_PHYSICS_PROCESS once a second and repeats them in between: trends, not per-frame costs.
		"engine_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"engine_physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu(),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"mem_static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / MB,
		"mem_video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB,
		"pipe_draw": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)),
		"pipe_spec": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)),
		"scale_3d": vp.scaling_3d_scale,
		"tier": Quality.tier,
		"thermal": thermal,
		"tag": tag,
	}


func _process(_dt: float) -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := 0.0 if _last_usec == 0 else (now - _last_usec) / 1000.0
	_last_usec = now
	_frame += 1
	if frame_ms <= 0.0:
		return
	_recent.append(frame_ms)
	if _recent.size() > 60:
		_recent.remove_at(0)
	if _csv == null and not _overlay.visible:
		return
	var s := sample(frame_ms)
	if _csv != null:
		var row := PackedStringArray()
		for c in COLUMNS:
			var v = s[c]
			row.append(("%.3f" % v) if typeof(v) == TYPE_FLOAT else str(v))
		_csv.store_line(",".join(row))
	if _overlay.visible and _frame % 10 == 0:
		_overlay.text = _overlay_text(s)


func _overlay_text(s: Dictionary) -> String:
	var sorted := _recent.duplicate()
	sorted.sort()
	var p50: float = sorted[sorted.size() / 2]
	var p95: float = sorted[mini(sorted.size() - 1, int(sorted.size() * 0.95))]
	var vp := get_viewport()
	var px: Vector2 = vp.get_visible_rect().size
	var mpx: float = px.x * px.y * vp.scaling_3d_scale * vp.scaling_3d_scale / 1000000.0
	return "\n".join([
		"frame p50 %.1f ms · p95 %.1f · worst %.1f  (%.0f fps)" % [p50, p95, sorted[sorted.size() - 1], 1000.0 / p50],
		"engine process %.2f ms · physics %.2f (1 s samples) · render CPU %.2f" % [s["engine_process_ms"], s["engine_physics_ms"], s["render_cpu_ms"]],
		"draw calls %d · primitives %.2f M · objects %d" % [s["draw_calls"], s["primitives"] / 1000000.0, s["objects"]],
		"memory: static %.0f MB · video %.0f MB" % [s["mem_static_mb"], s["mem_video_mb"]],
		"3D %.2f Mpx (scale %.3f of %d × %d) · %s · thermal %s" % [mpx, vp.scaling_3d_scale, int(px.x), int(px.y), Quality.tier, thermal],
		"GPU time: not readable on Metal (ISS-011)",
	])


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("telemetry"):  # F3 or `
		_overlay.visible = not _overlay.visible
		_recent.clear()


func _exit_tree() -> void:
	stop_csv()
