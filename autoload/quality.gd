extends Node
## Quality (plan chapter 11, 21.1–21.2): the tiers by name. For now a tier sets the frame cap and the 3D pixel budget
## (the 3D pass is rendered at the tier's megapixels whatever the window's size, and upscaled). It also runs the thermal
## helper (tools/bin/dk-thermal, built by tools/thermal/build.sh) and passes its state to Telemetry (chapter 11, 21.3).
## Since RT-14 (spike S18) it also applies each tier's look (volumetric fog, SSAO and SSIL, the sun's shadow splits and
## atlas) to the environment and sun registered with register_look(), and follows chapter 11's policy (21.3): on
## battery QT-BATT; Low Power Mode QT-COOL; thermal "serious" QT-COOL until "fair" or better has held for 60 s;
## "critical" also raises critical_heat for the game to pause on. Every change is logged. force() injects a state for
## tests. Dynamic resolution waits for spike S8's upscaler.

signal tier_changed(tier_name: String)
signal critical_heat

const TIERS := {
	# 3D megapixels: at least 1080p by default (Greg, 25 Sep 2026: "at the very least 1080p, if not 4K"; docs/DECISIONS.md).
	# "mpx": 0 means native: the 3D pass at the window's full resolution (4K on a 4K screen), for stills and strong GPUs.
	"QT-NATIVE": {"fps": 30, "mpx": 0.0, "shadow_splits": 4, "shadow_size": 4096, "volumetric_fog": "on", "ssao": "full", "crowd": 300, "omni": 64, "flags_smoke": "full"},
	"QT-FULL": {"fps": 30, "mpx": 3.7, "shadow_splits": 4, "shadow_size": 4096, "volumetric_fog": "on", "ssao": "half", "crowd": 300, "omni": 64, "flags_smoke": "full"},
	"QT-BAL": {"fps": 30, "mpx": 2.1, "mpx_min": 1.4, "mpx_max": 2.6, "shadow_splits": 4, "shadow_size": 4096, "volumetric_fog": "dawn, dusk and halls", "ssao": "half", "crowd": 300, "omni": 64, "flags_smoke": "full"},
	"QT-LOW": {"fps": 30, "mpx": 1.4, "shadow_splits": 3, "shadow_size": 2048, "volumetric_fog": "off outdoors", "ssao": "off", "crowd": 60, "omni": 16, "flags_smoke": "half"},
	"QT-COOL": {"fps": 20, "mpx": 0.9, "shadow_splits": 2, "shadow_size": 2048, "volumetric_fog": "off", "ssao": "off", "crowd": 60, "omni": 16, "flags_smoke": "half"},
	"QT-BATT": {"fps": 30, "mpx": 1.4, "shadow_splits": 3, "shadow_size": 2048, "volumetric_fog": "off", "ssao": "off", "crowd": 120, "omni": 16, "flags_smoke": "half"},
}

var tier := "QT-BAL"
var base_tier := "QT-BAL"  ## the player's choice; the policy may put the game in a cooler tier for a while
var machine := {"thermal": "unknown", "lowpower": "0", "battery": "0"}  ## the helper's last report
var forced := {}  ## test overrides of machine, e.g. {"thermal": "serious"}
var uncapped := false  ## a performance run's: no frame cap whatever the tier (set_tier had put the cap back on battery)
var recover_s := 60.0  ## how long "fair" or better must hold before leaving the heat tier
var _cooling := false
var _critical := false
var _cool_since := -1.0
var _env: Environment
var _sun: DirectionalLight3D
var _tracked: Viewport
var _thermal_pid := -1
var _thermal_pipe: FileAccess
var _thermal_thread: Thread
var _thermal_running := false  ## the reader loop stops on this: the pipe never reports end of file after the helper is killed


## An explicit choice (no reason given) becomes the base tier the policy returns to; the policy passes its reason.
func set_tier(tier_name: String, reason := "") -> void:
	assert(TIERS.has(tier_name), "unknown quality tier " + tier_name)
	var before := tier
	tier = tier_name
	if reason == "":
		base_tier = tier_name
		reason = "chosen"
	Engine.max_fps = 0 if uncapped else TIERS[tier]["fps"]
	if _tracked != null:
		fit_3d(_tracked)
	_apply_look()
	if before != tier:
		Telemetry.event("tier", {"from": before, "to": tier, "reason": reason})
	tier_changed.emit(tier)


## The environment and sun the tiers switch (the vignette's look registers its own).
func register_look(env: Environment, sun: DirectionalLight3D) -> void:
	_env = env
	_sun = sun
	_apply_look()


func _apply_look() -> void:
	var t: Dictionary = TIERS[tier]
	if _env != null:
		_env.volumetric_fog_enabled = not String(t["volumetric_fog"]).begins_with("off")
		_env.ssao_enabled = t["ssao"] != "off"
		_env.ssil_enabled = t["ssao"] != "off"
	if _sun != null:
		# Godot has 1, 2 or 4 splits; chapter 11's "3 splits" becomes 4 over a shorter distance.
		_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if t["shadow_splits"] <= 2 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		_sun.directional_shadow_max_distance = 160.0 if t["shadow_splits"] >= 4 else 110.0
	# The shadow atlas stays at 4,096 in every tier: reallocating it on a live switch was the likeliest cause of
	# S18's two late frames (52.8 and 51.7 ms, QT-COOL back to QT-BAL); a 4,096 atlas is 32 MB. The table's
	# shadow_size is kept for the day a restart applies it.


## For tests: pretend the machine reports these values (merged over the helper's), then apply the policy.
func force(kv: Dictionary) -> void:
	forced = kv
	_policy("forced " + JSON.stringify(kv))


func _policy(reason: String) -> void:
	var m := machine.duplicate()
	m.merge(forced, true)
	var hot: bool = m["thermal"] in ["serious", "critical"]
	var now := Time.get_ticks_msec() / 1000.0
	if hot:
		_cooling = true
		_cool_since = -1.0
	elif _cooling:
		if _cool_since < 0.0:
			_cool_since = now
		elif now - _cool_since >= recover_s:
			_cooling = false
	var want := base_tier
	var why := "the player's tier"
	if m["battery"] == "1":
		want = "QT-BATT"
		why = "on battery"
	if m["lowpower"] == "1":
		want = "QT-COOL"
		why = "Low Power Mode"
	if _cooling:
		want = "QT-COOL"
		why = "heat (%s)" % m["thermal"] if hot else "heat: waiting for %.0f s of fair" % recover_s
	var critical: bool = m["thermal"] == "critical"
	if critical and not _critical:
		Telemetry.event("thermal", {"state": "critical", "action": "pause"})
		critical_heat.emit()
	_critical = critical
	if want != tier:
		set_tier(want, "%s; %s" % [why, reason])


## Re-evaluate the policy (the helper's lines do it every 5 s; tests call it to hurry the clock).
func tick_policy() -> void:
	_policy("tick")


func track(vp: Viewport) -> void:
	## Keep this viewport's 3D pass at the tier's pixel budget as the window is resized (AeroSpace retiles it).
	_tracked = vp
	vp.size_changed.connect(func() -> void: fit_3d(vp))
	set_tier(tier)


func fit_3d(vp: Viewport) -> void:
	var size: Vector2 = vp.get_visible_rect().size
	var px := size.x * size.y
	var mpx: float = TIERS[tier]["mpx"]
	var s := 1.0 if mpx <= 0.0 else clampf(sqrt(mpx * 1000000.0 / maxf(px, 1.0)), 0.3, 1.0)
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if s < 0.99 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = s  # FSR 1 for now; spike S8 chooses between MetalFX Spatial and Temporal
	Telemetry.event("scale_3d", {"tier": tier, "window": [int(size.x), int(size.y)], "scale": snappedf(s, 0.001), "mpx_3d": snappedf(px * s * s / 1000000.0, 0.01)})


## Start the thermal helper; its first line arrives at once, then one every 5 s.
func start_thermal() -> void:
	if _thermal_pid > 0:
		return
	var bin := ProjectSettings.globalize_path("res://tools/bin/dk-thermal")
	if not FileAccess.file_exists(bin):
		Telemetry.event("thermal", {"state": "helper missing: run tools/thermal/build.sh"})
		return
	var p := OS.execute_with_pipe(bin, ["5"])
	if p.is_empty():
		Telemetry.event("thermal", {"state": "helper failed to start"})
		return
	_thermal_pid = p["pid"]
	_thermal_pipe = p["stdio"]
	_thermal_running = true
	_thermal_thread = Thread.new()
	_thermal_thread.start(_read_thermal)


func _read_thermal() -> void:
	# Runs on its own thread. get_line returns an empty string when nothing is waiting; the loop ends on the flag.
	while _thermal_running:
		var line := _thermal_pipe.get_line()
		if line.is_empty():
			OS.delay_msec(100)
			continue
		_on_thermal_line.call_deferred(line)


func _on_thermal_line(line: String) -> void:
	var kv := {}
	for part in line.split(" ", false):
		var pair := part.split("=")
		if pair.size() == 2:
			kv[pair[0]] = pair[1]
	var state: String = kv.get("thermal", "unknown")
	if state != Telemetry.thermal:
		Telemetry.thermal = state
		Telemetry.event("thermal", kv)
	for k in ["thermal", "lowpower", "battery"]:
		if kv.has(k):
			machine[k] = kv[k]
	_policy("helper")


func stop_thermal() -> void:
	_thermal_running = false
	if _thermal_pid > 0:
		OS.kill(_thermal_pid)
		_thermal_pid = -1
	if _thermal_thread != null and _thermal_thread.is_started():
		_thermal_thread.wait_to_finish()
		_thermal_thread = null


func _exit_tree() -> void:
	stop_thermal()
