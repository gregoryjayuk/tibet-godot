extends Node3D
## Spike S2, the town-scale draw test (plan chapter 11, 5 and 23.2; roadmap RT-10). 300 kit buildings, weighted like
## the town (mostly houses and monks' houses, a few halls), on a synthetic 24° slope, each with its three LODs and a
## per-building `variant` from its seed; beyond 250 m one merged proxy per 128 m cell hides them through
## `visibility_parent` (Godot's HLOD). Two stations, a monastery roof looking down the slope and a lane in the
## densest cell, are measured at native 1080p with occlusion culling on and off, turning a full circle, 240 frames
## each; every frame goes to CSV and a summary line per pass to perf/history.csv. Budget (chapter 11, 23.2):
## ≤ 2,000 draw calls, ≤ 3 M primitives, ≤ 20 ms GPU. Run: tools/perf/s2.sh [uncapped]

const Vignette := preload("res://world/vignette.gd")
const STATIC := preload("res://shaders/materials/stylized_static.tres")
const MIX := {"village_house": 150, "monks_quarters": 70, "chorten": 30, "sangkhang": 20, "red_chapel": 15,
		"prayer_wheel_gallery": 8, "palace_tower": 5, "assembly_hall": 2}
const SLOPE_DEG := 24.0
const SPACING := 19.0
const CELL := 128.0
const CANVAS := Vector2i(1920, 1080)
const SETTLE_MS := 2000
const FRAMES := 240
const HISTORY := "res://perf/history.csv"
const HISTORY_COLUMNS := ["date", "commit", "route", "view", "mode", "frames", "p50_ms", "p95_ms", "p99_ms", "worst_ms",
		"engine_process_ms", "engine_physics_ms", "render_cpu_ms", "draw_calls", "primitives_max", "objects", "mem_static_mb_max",
		"mem_video_mb_max", "mpx_3d", "tier", "thermal", "valid"]

var cam: Camera3D
var stations := []
var passes := []
var run_dir := ""
var commit := "none"
var uncapped := false
var current := {}
var counts := {"buildings": 0, "cells": 0, "proxy_triangles": 0}
var town_only := false  ## set before adding: build the look, ground and town, emit `built`, and measure nothing (S5 reuses the town)

signal built


func _slope_y(z: float) -> float:
	return tan(deg_to_rad(SLOPE_DEG)) * -z  # the slope rises towards -z


func _ready() -> void:
	for a in (OS.get_cmdline_user_args() if not town_only else PackedStringArray()):
		if a.begins_with("--run="):
			run_dir = ProjectSettings.globalize_path("res://" + a.substr(6)) if not a.substr(6).is_absolute_path() else a.substr(6)
		elif a.begins_with("--commit="):
			commit = a.substr(9)
		elif a == "--uncapped":
			uncapped = true
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	get_viewport().scaling_3d_scale = 1.0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	WorldClock.freeze(20.0)
	if uncapped:
		Quality.uncapped = true  # kept off through tier changes
		Engine.max_fps = 0
	if town_only:
		WorldClock.frozen = false  # S5's people and animals move; S2 froze the world for its stills
	var look := Vignette.new()
	look.look_only = true
	add_child(look)
	await look.build()
	_ground()
	_town()
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.far = 20000.0
	add_child(cam)
	cam.current = true
	_outline()
	if town_only:
		built.emit()
		return
	stations = [
		["roof", Vector3(0.0, _slope_y(-190.0) + 16.0, -190.0), Vector3(0.0, _slope_y(40.0), 40.0)],
		["lane", Vector3(9.5, _slope_y(9.5) + 1.6, 9.5), Vector3(80.0, _slope_y(9.5) + 1.6, 9.5)],
	]
	passes = [[0, true], [0, false], [1, true], [1, false]]
	Quality.start_thermal()
	Telemetry.event("s2", counts)
	_next_pass()


func _ground() -> void:
	var g := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(900.0, 900.0 / cos(deg_to_rad(SLOPE_DEG)))
	p.subdivide_depth = 8
	g.mesh = p
	g.rotation.x = deg_to_rad(SLOPE_DEG)  # tilted so that it rises towards -z
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#8a8f55")
	m.roughness = 1.0
	g.material_override = m
	add_child(g)


func _town() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1903
	var list := []
	for t in MIX:
		for i in MIX[t]:
			list.append(t)
	for i in range(list.size() - 1, 0, -1):  # a seeded Fisher-Yates shuffle
		var j := rng.randi_range(0, i)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp
	var scenes := {}
	for t in MIX:
		scenes[t] = load("res://assets/generated/kit/types/%s_v1.glb" % t)
	var side := int(ceil(sqrt(float(list.size()))))
	var cells := {}
	for i in list.size():
		var x := (i % side - side / 2.0) * SPACING + rng.randf_range(-3.0, 3.0)
		var z := (i / side - side / 2.0) * SPACING + rng.randf_range(-3.0, 3.0)
		var b: Node3D = scenes[list[i]].instantiate()
		b.position = Vector3(x, _slope_y(z) - 0.4, z)
		b.rotation.y = deg_to_rad(rng.randf_range(-20.0, 20.0))
		add_child(b)
		var variant := rng.randf()
		for mi in b.find_children("*", "MeshInstance3D", true, false):
			if String(mi.name).substr(String(mi.name).length() - 3) in ["_L0", "_L1", "_L2"]:
				(mi as GeometryInstance3D).set_instance_shader_parameter("variant", variant)
		var key := Vector2i(int(floor((x + CELL / 2.0) / CELL)), int(floor((z + CELL / 2.0) / CELL)))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(b)
	counts["buildings"] = list.size()
	for key in cells:
		_proxy(cells[key])
	counts["cells"] = cells.size()


func _proxy(buildings: Array) -> void:
	# The cell's L2 meshes merged into one mesh, no shadows, shown beyond 250 m + its half-diagonal (≤ 90 m).
	var st := SurfaceTool.new()
	var any := false
	for b in buildings:
		for mi in (b as Node).find_children("*_L2", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).mesh
			for s in m.get_surface_count():
				st.append_from(m, s, (mi as MeshInstance3D).global_transform)
				any = true
	if not any:
		return
	var mesh := st.commit()
	var proxy := MeshInstance3D.new()
	proxy.mesh = mesh
	proxy.material_override = STATIC
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(proxy)
	var half := minf(mesh.get_aabb().size.length() / 2.0, 90.0)
	proxy.visibility_range_begin = 250.0 + half
	proxy.visibility_range_begin_margin = 8.0
	proxy.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for b in buildings:
		for mi in (b as Node).find_children("*", "MeshInstance3D", true, false):
			if String(mi.name).substr(String(mi.name).length() - 3) in ["_L0", "_L1", "_L2"]:
				(mi as GeometryInstance3D).visibility_parent = (mi as Node).get_path_to(proxy)
	var arr := mesh.surface_get_arrays(0)
	counts["proxy_triangles"] += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arr[Mesh.ARRAY_INDEX] != null else 0


func _outline() -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2, 2)
	q.mesh = qm
	q.extra_cull_margin = 16384.0
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var om := ShaderMaterial.new()
	om.shader = preload("res://shaders/outline.gdshader")
	om.set_shader_parameter("enabled", 1.0)
	q.material_override = om
	cam.add_child(q)


func _next_pass() -> void:
	if passes.is_empty():
		Quality.stop_thermal()
		print("s2: done")
		get_tree().quit()
		return
	var p: Array = passes.pop_front()
	var st: Array = stations[p[0]]
	get_viewport().use_occlusion_culling = p[1]
	cam.global_position = st[1]
	cam.look_at(st[2], Vector3.UP)
	current = {"station": st[0], "occ": p[1], "yaw0": cam.rotation.y, "frame": -1, "until": Time.get_ticks_msec() + SETTLE_MS, "rows": []}
	current["name"] = "s2_%s_occ-%s_%s" % [st[0], "on" if p[1] else "off", "uncapped" if uncapped else "capped"]


func _process(_dt: float) -> void:
	if current.is_empty():
		return
	if current["frame"] < 0:
		if Time.get_ticks_msec() < current["until"]:
			return
		current["frame"] = 0
		Telemetry.tag = current["name"]
		Telemetry.start_csv(run_dir.path_join(current["name"] + ".csv"))
		return
	current["frame"] += 1
	cam.rotation.y = current["yaw0"] + TAU * float(current["frame"]) / FRAMES
	current["rows"].append(Telemetry.sample(0.0))
	if current["frame"] >= FRAMES:
		Telemetry.stop_csv()
		_summary()
		current = {}
		_next_pass()


func _summary() -> void:
	var intervals := PackedFloat32Array()
	var csv := FileAccess.open(run_dir.path_join(current["name"] + ".csv"), FileAccess.READ)
	csv.get_line()
	while not csv.eof_reached():
		var cols := csv.get_line().split(",")
		if cols.size() > 1:
			intervals.append(float(cols[1]))
	intervals.sort()
	var rows: Array = current["rows"]
	var n := intervals.size()
	var dc_max := 0.0
	var dc_sum := 0.0
	var prim_max := 0.0
	var obj_sum := 0.0
	var vid := 0.0
	var seen := {}
	for r in rows:
		dc_max = maxf(dc_max, r["draw_calls"])
		dc_sum += r["draw_calls"]
		prim_max = maxf(prim_max, r["primitives"])
		obj_sum += r["objects"]
		vid = maxf(vid, r["mem_video_mb"])
		seen["%d/%d" % [r["primitives"], r["draw_calls"]]] = true
	var valid := seen.size() > 1
	var line := {"date": Time.get_datetime_string_from_system(), "commit": commit, "route": "s2@%s:occ-%s" % [current["station"], "on" if current["occ"] else "off"],
		"view": 0, "mode": "uncapped" if uncapped else "capped", "frames": n, "p50_ms": intervals[n / 2],
		"p95_ms": intervals[mini(n - 1, int(n * 0.95))], "p99_ms": intervals[mini(n - 1, int(n * 0.99))], "worst_ms": intervals[n - 1],
		"engine_process_ms": 0.0, "engine_physics_ms": 0.0, "render_cpu_ms": 0.0, "draw_calls": dc_sum / maxf(rows.size(), 1.0),
		"primitives_max": prim_max, "objects": obj_sum / maxf(rows.size(), 1.0), "mem_static_mb_max": 0.0, "mem_video_mb_max": vid,
		"mpx_3d": CANVAS.x * CANVAS.y / 1000000.0, "tier": "1080p", "thermal": Telemetry.thermal, "valid": "yes" if valid else "NO (not redrawn)"}
	var path := ProjectSettings.globalize_path(HISTORY)
	var fresh := not FileAccess.file_exists(path)
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
	print("s2: %s%s: p50 %.1f ms, p95 %.1f, worst %.1f; draw calls mean %.0f, max %.0f; primitives max %.2f M; objects %.0f; video %.0f MB" % [
		"" if valid else "INVALID ", current["name"], line["p50_ms"], line["p95_ms"], line["worst_ms"], line["draw_calls"], dc_max,
		prim_max / 1000000.0, line["objects"], vid])
