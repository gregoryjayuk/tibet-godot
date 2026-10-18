extends Node3D
## Spike S5 (plan chapter 05, 13; chapter 11, 12.1 and 23; roadmap RT-13): 300 people and chapter 06's animals in S2's
## town of 300 kit buildings on a 24° slope. The people walk the lanes of the central 133 m (an 8 x 8 street graph,
## about 65 of them within 35 m of the lane station: harsher than chapter 02's Tsongra at 11:00, 90 within 60 m), as
## TownSim data drawn by characters/crowd.gd in three tiers; the animals are animals/herds.gd's.
## Modes (after --):
##   --perf    per station, turning a full circle over 240 frames: frame times with everything, without people,
##             without animals, and with neither (uncapped: each cost is a difference), and the scripts' own time
##             every frame (TownSim, the crowd, the herds). Summaries to perf/history.csv
##   --capped  the lane station at the 30 fps cap, 20 s: does 30 hold
##   --shots   stills from the lane and the roof to tests/crowd/out/
##   --pop     one frozen instant drawn three ways, near people skeletal, the same people VAT, and no people, to
##             tests/crowd/out/; tools/perf/s5_pop.py measures how much of the figures changes between the first two
##   --play    walk it yourself: the first-person player among the people and animals (tools/play.sh town)
## Run: tools/perf/s5.sh [perf|capped|shots|pop|all]

const S2 := preload("res://tests/perf/s2.gd")
const Player := preload("res://player/player.gd")
const Ink := preload("res://world/ink.gd")
const Hud := preload("res://ui/hud.gd")
const Crowd := preload("res://characters/crowd.gd")
const Herds := preload("res://animals/herds.gd")
const LANE := 19.0
const PEOPLE := 300
const KINDS: Array[String] = ["monk", "villager_woman", "villager_man"]
const OUT := "res://tests/crowd/out"
const SETTLE_MS := 3000
const FRAMES := 240
const HISTORY := "res://perf/history.csv"
const HISTORY_COLUMNS := ["date", "commit", "route", "view", "mode", "frames", "p50_ms", "p95_ms", "p99_ms", "worst_ms",
		"engine_process_ms", "engine_physics_ms", "render_cpu_ms", "draw_calls", "primitives_max", "objects", "mem_static_mb_max",
		"mem_video_mb_max", "mpx_3d", "tier", "thermal", "valid"]

var town: Node3D
var cam: Camera3D
var crowd: Node3D
var herds: Node3D
var mode := ""
var run_dir := ""
var commit := "none"
var uncapped := false
var jobs: Array = []
var current := {}
var people_on := true
var animals_on := true
var stations := {}
var vat_shadows := true  ## the VAT tier casts sun shadows too (0.3-0.5 ms, and no shadow pops at 35 m); --no-vat-shadows to compare


func _slope_y(z: float) -> float:
	return tan(deg_to_rad(24.0)) * -z


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a in ["--perf", "--capped", "--shots", "--pop", "--play"]:
			mode = a.substr(2)
		elif a.begins_with("--run="):
			run_dir = ProjectSettings.globalize_path("res://" + a.substr(6))
		elif a.begins_with("--commit="):
			commit = a.substr(9)
		elif a == "--uncapped":
			uncapped = true
		elif a == "--no-vat-shadows":
			vat_shadows = false
	town = S2.new()
	town.town_only = true
	add_child(town)
	await town.built
	cam = town.cam
	if "--ink" in OS.get_cmdline_user_args():
		Ink.attach(cam)  # art step A5's check: the ink pass on the town's stills (lines to 400 m)
	if uncapped:
		Quality.uncapped = true  # kept off through tier changes
		Engine.max_fps = 0
	# The street graph: the lanes between S2's buildings, 19 m apart, over the central 133 m.
	var nodes := PackedVector3Array()
	var index := {}
	for kz in range(6, 14):
		for kx in range(6, 14):
			var x := (kx - 9.5) * LANE
			var z := (kz - 9.5) * LANE
			index[Vector2i(kx, kz)] = nodes.size()
			nodes.append(Vector3(x, _slope_y(z), z))
	var adj := []
	for kz in range(6, 14):
		for kx in range(6, 14):
			var nb := PackedInt32Array()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var key: Vector2i = Vector2i(kx, kz) + d
				if index.has(key):
					nb.append(index[key])
			adj.append(nb)
	TownSim.setup(nodes, adj, PEOPLE, KINDS.size())
	var bounds := AABB(Vector3(-260, -140, -260), Vector3(520, 380, 520))
	crowd = Crowd.new()
	crowd.name = "Crowd"
	add_child(crowd)
	crowd.setup(TownSim, KINDS, bounds)
	crowd.set_shadows(true, vat_shadows)
	herds = Herds.new()
	herds.name = "Herds"
	add_child(herds)
	var ribbon := PackedVector3Array([Vector3(-190, 0, 185), Vector3(190, 0, 185), Vector3(190, 0, 205), Vector3(-190, 0, 205), Vector3(-190, 0, 185)])
	herds.setup(func(x: float, z: float) -> float: return _slope_y(z), Rect2(-130, 215, 260, 60), ribbon, Vector3(28.5, 0, 28.5), bounds)
	stations = {
		"lane": [Vector3(9.5, _slope_y(9.5) + 1.6, 9.5), Vector3(80.0, _slope_y(9.5) + 1.6, 9.5)],
		"roof": [Vector3(0.0, _slope_y(-120.0) + 16.0, -120.0), Vector3(0.0, _slope_y(60.0), 60.0)],
		"herd": [Vector3(0.0, _slope_y(160.0) + 12.0, 160.0), Vector3(0.0, _slope_y(240.0), 240.0)],
	}
	for i in 4:
		await get_tree().process_frame
	Telemetry.event("s5_setup", {"people": PEOPLE, "graph_nodes": nodes.size(), "herd": 130, "ribbon": 72, "skeletal_animals": 16, "birds": 300})
	match mode:
		"perf":
			Quality.start_thermal()
			for st in ["lane", "roof"]:
				for cond in ["all", "no_people", "no_animals", "none"]:
					jobs.append([st, cond])
			_next_pass()
		"capped":
			Quality.start_thermal()
			Engine.max_fps = 30
			jobs.append(["lane", "all"])
			_next_pass()
		"shots":
			jobs = [["lane", 90.0], ["lane", 200.0], ["roof", 0.0], ["herd", 0.0]]
			_next_shot()
		"pop":
			_start_pop()
		"play":
			_start_play()
		_:
			print("s5: no mode; use --perf, --capped, --shots, --pop or --play")
			get_tree().quit()


func _look(st: String) -> void:
	var s: Array = stations[st]
	cam.global_position = s[0]
	cam.look_at(s[1], Vector3.UP)


func _set_parts(people: bool, animals: bool) -> void:
	people_on = people
	animals_on = animals
	crowd.visible = people
	herds.visible = animals


func _process(dt: float) -> void:
	if crowd == null:
		return
	if people_on and TownSim.running:
		TownSim.step(dt, cam.global_position)
	if people_on:
		crowd.update(cam.global_position)
	if animals_on and not (mode == "pop" and WorldClock.frozen):
		herds.update(dt)
	if current.is_empty():
		return
	match mode:
		"perf", "capped":
			_perf_tick()
		"shots":
			_shot_tick()
		"pop":
			_pop_tick()


# ------------------------------------------------------------------ perf
func _next_pass() -> void:
	if jobs.is_empty():
		Quality.stop_thermal()
		print("s5: %s done" % mode)
		get_tree().quit()
		return
	var job: Array = jobs.pop_front()
	_set_parts(job[1] in ["all", "no_animals"], job[1] in ["all", "no_people"])
	_look(job[0])
	current = {"station": job[0], "cond": job[1], "yaw0": cam.rotation.y, "frame": -1, "until": Time.get_ticks_msec() + SETTLE_MS,
		"rows": [], "sim_us": 0, "crowd_us": 0, "herd_us": 0, "hero": 0, "near": 0, "swaps": 0,
		"frames_total": 600 if mode == "capped" else FRAMES}
	current["name"] = "s5_%s_%s%s_%s" % [job[0], job[1], "" if vat_shadows else "_novatsh", "capped" if mode == "capped" else ("uncapped" if uncapped else "capped")]


func _perf_tick() -> void:
	if current["frame"] < 0:
		if Time.get_ticks_msec() < current["until"]:
			return
		current["frame"] = 0
		Telemetry.tag = current["name"]
		Telemetry.start_csv(run_dir.path_join(current["name"] + ".csv"))
		return
	current["frame"] += 1
	if mode == "perf":
		cam.rotation.y = current["yaw0"] + TAU * float(current["frame"]) / FRAMES
	current["rows"].append(Telemetry.sample(0.0))
	current["sim_us"] += TownSim.last_us if people_on else 0
	current["crowd_us"] += crowd.last_us if people_on else 0
	current["herd_us"] += herds.last_us if animals_on else 0
	current["hero"] = maxi(current["hero"], crowd.counts["hero"])
	current["near"] = maxi(current["near"], crowd.counts["near"])
	current["swaps"] += crowd.swaps if people_on else 0
	if current["frame"] >= current["frames_total"]:
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
	var f := float(current["frame"])
	var dc := 0.0
	var prim_max := 0.0
	var vid := 0.0
	var over40 := 0
	for r in rows:
		dc += r["draw_calls"]
		prim_max = maxf(prim_max, r["primitives"])
		vid = maxf(vid, r["mem_video_mb"])
	for v in intervals:
		if v > 40.0:
			over40 += 1
	var line := {"date": Time.get_datetime_string_from_system(), "commit": commit, "route": "s5@%s:%s%s" % [current["station"], current["cond"], "" if vat_shadows else "+no_vat_shadows"],
		"view": 0, "mode": "capped" if mode == "capped" else ("uncapped" if uncapped else "capped"), "frames": n, "p50_ms": intervals[n / 2],
		"p95_ms": intervals[mini(n - 1, int(n * 0.95))], "p99_ms": intervals[mini(n - 1, int(n * 0.99))], "worst_ms": intervals[n - 1],
		"engine_process_ms": 0.0, "engine_physics_ms": 0.0, "render_cpu_ms": 0.0, "draw_calls": dc / maxf(rows.size(), 1.0),
		"primitives_max": prim_max, "objects": 0.0, "mem_static_mb_max": 0.0, "mem_video_mb_max": vid,
		"mpx_3d": 1920 * 1080 / 1000000.0, "tier": "1080p", "thermal": Telemetry.thermal, "valid": "yes"}
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
	print("s5: %s: p50 %.2f ms, p95 %.2f, worst %.2f, frames over 40 ms %d; scripts: TownSim %.2f ms, crowd %.2f ms, herds %.2f ms a frame; hero max %d, near max %d, swaps %d; draw calls %.0f, primitives max %.2f M, video %.0f MB" % [
		current["name"], line["p50_ms"], line["p95_ms"], line["worst_ms"], over40, current["sim_us"] / f / 1000.0, current["crowd_us"] / f / 1000.0,
		current["herd_us"] / f / 1000.0, current["hero"], current["near"], current["swaps"], line["draw_calls"], prim_max / 1000000.0, vid])


# ------------------------------------------------------------------ shots
func _next_shot() -> void:
	if jobs.is_empty():
		print("s5: shots done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var job: Array = jobs.pop_front()
	_look(job[0])
	cam.rotation.y += deg_to_rad(job[1])
	current = {"name": "%s_%03d" % [job[0], int(job[1])], "wait": 90}


func _shot_tick() -> void:
	current["wait"] -= 1
	if current["wait"] > 0:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var path := ProjectSettings.globalize_path(OUT).path_join("s5_%s.png" % current["name"])
	get_viewport().get_texture().get_image().save_png(path)
	print("s5: shot %s (hero %d, near %d, VAT %d)" % [path, crowd.counts["hero"], crowd.counts["near"], crowd.counts["vat"]])
	current = {}
	_next_shot()


# ------------------------------------------------------------------ play
func _start_play() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, false)  # the test modes keep the keyboard away
	var ground := StaticBody3D.new()  # S2 draws its slope without collision
	var cs := CollisionShape3D.new()
	var wb := WorldBoundaryShape3D.new()
	var a := deg_to_rad(24.0)
	wb.plane = Plane(Vector3(0.0, cos(a), sin(a)), 0.0)
	cs.shape = wb
	ground.add_child(cs)
	add_child(ground)
	var p := Player.new()
	p.ink_air = true  # the town is M1's content: the ink pass (art step A5)
	p.third_person = true  # M1's player, seen from behind
	# Keys 1-3: the lane, the roof and the herd (the player's views are in Blender's axes: x, -z, y).
	for st in ["lane", "roof", "herd"]:
		var s: Array = stations[st]
		p.views.append([Vector3(s[0].x, -s[0].z, s[0].y - 1.6), Vector3(s[1].x, -s[1].z, s[1].y)])
	add_child(p)
	p.teleport(0)
	p.flying = false
	p.cam.current = true
	cam = p.cam
	var hud := Hud.new()
	hud.third_person = true
	add_child(hud)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="):  # tools/play.sh's sharp and native
			Quality.tier = arg.substr(7)
			Quality.base_tier = Quality.tier
	Quality.track(get_viewport())
	print("s5: play: W S forward and back, A D turn, drag with the left button to look round, the right to steer, Shift held sprint, F to fly, 1-3 the lane, the roof and the herd")


# ------------------------------------------------------------------ pop
func _start_pop() -> void:
	for i in 60:  # let people spread along their streets before the instant is frozen
		await get_tree().process_frame
	TownSim.running = false
	WorldClock.freeze(WorldClock.anim_time)
	_look("lane")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# Without shadows first, so the figures alone are compared; then with every tier casting shadows.
	jobs = [["noshadow", "skeletal", 1], ["noshadow", "vat", 0], ["noshadow", "empty", -2], ["shadow", "skeletal", 1], ["shadow", "vat", 0], ["shadow", "empty", -2]]
	_next_pop()


func _next_pop() -> void:
	if jobs.is_empty():
		print("s5: pop images done in %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()
		return
	var job: Array = jobs.pop_front()
	crowd.set_shadows(job[0] == "shadow", job[0] == "shadow")
	if job[2] == -2:
		crowd.visible = false
	else:
		crowd.visible = true
		crowd.forced = job[2]
	current = {"name": "%s_%s" % [job[1], job[0]], "wait": 30}


func _pop_tick() -> void:
	current["wait"] -= 1
	if current["wait"] > 0:
		return
	var path := ProjectSettings.globalize_path(OUT).path_join("pop_%s.png" % current["name"])
	get_viewport().get_texture().get_image().save_png(path)
	print("s5: pop %s (hero %d, near %d, VAT %d)" % [current["name"], crowd.counts["hero"], crowd.counts["near"], crowd.counts["vat"]])
	current = {}
	_next_pop()
