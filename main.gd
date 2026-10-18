extends Node3D
## Dungkardo, the draft vignette (an alley and the red chapel). Main only assembles and reads the command line:
## the world (world/vignette.gd), the player (player/player.gd), the HUD (ui/hud.gd) and the test modes
## (tests/runtime/test_modes.gd). Time, quality and telemetry are autoloads (autoload/). Plan chapter 11, section 3.
##
## Play: open -n -a /Applications/Godot.app --args --path path/to/tibet-godot
## Command line (after --): --view=N (start at viewpoint N), --no-outline, --kit (buildings from the kit exports, RT-09), --shot=<png> (with --view),
## --tier=<QT-NAME>, --canvas=<W>x<H> --scale3d=<s> --upscaler=<name> (performance runs), --shot-set=<json>, --walk-test, --perf-route=<run folder> [--perf-uncapped] [--perf-commit=<hash>]. Automated runs go through tools/run_windowed.sh, which keeps the keyboard with
## whoever is typing (docs/DECISIONS.md, 25 Sep 2026).

const Vignette := preload("res://world/vignette.gd")
const Player := preload("res://player/player.gd")
const Hud := preload("res://ui/hud.gd")
const TestModes := preload("res://tests/runtime/test_modes.gd")
const DayCycle := preload("res://world/day.gd")
const Horizon := preload("res://world/horizon.gd")

var world: Vignette
var player: Player
var hud: Hud
var modes: TestModes


func _ready() -> void:
	seed(1903)  # every random choice repeats exactly, so screenshots can be compared
	world = Vignette.new()
	world.use_kit = "--kit" in OS.get_cmdline_user_args()
	add_child(world)
	await world.build()
	if world.use_kit:
		# M1's look runs the day (art step A7): the keyframes blended at the clock's minute, from 14:00 at 6:1.
		var day := DayCycle.new()
		for c in world.get_children():
			if c is DirectionalLight3D:
				day.sun = c
			elif c is WorldEnvironment:
				day.env = (c as WorldEnvironment).environment
		add_child(day)
		Horizon.load_globals(Horizon.STREET_PLACE)  # the ridge shadow (art step A8), the street set down at Tsongra
	player = Player.new()
	player.views = Vignette.VIEWS
	player.ink_air = world.use_kit  # M1's look draws with the ink pass (art step A5)
	player.third_person = world.use_kit  # M1's player is seen from behind (Greg, 25 Sep, 17:35)
	add_child(player)
	player.teleport(0)
	hud = Hud.new()
	hud.show_clock = world.use_kit  # the day runs in M1's look (art step A7)
	hud.third_person = world.use_kit
	hud.player = player if world.use_kit else null
	add_child(hud)
	modes = TestModes.new()
	modes.world = world
	modes.player = player
	modes.hud = hud
	add_child(modes)
	await get_tree().physics_frame
	await get_tree().physics_frame
	world.populate()  # grass and monks: after the collisions exist, and always in this order (the seed)
	_args()


func _args() -> void:
	var view := -1
	var single := ""
	var set_path := ""
	var walk := false
	var perf_dir := ""
	var perf_uncapped := false
	var perf_commit := ""
	var tier := ""
	var canvas := Vector2i.ZERO
	var scale3d := -1.0
	var upscaler := ""
	var soak_min := 0.0
	var soak_dir := "perf/runs/soak"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--view="):
			view = int(a.substr(7))
		elif a.begins_with("--shot="):
			single = a.substr(7)
		elif a.begins_with("--shot-set="):
			set_path = a.substr(11)
		elif a == "--walk-test":
			walk = true
		elif a.begins_with("--perf-route="):
			perf_dir = a.substr(13)
		elif a == "--perf-uncapped":
			perf_uncapped = true
		elif a.begins_with("--perf-commit="):
			perf_commit = a.substr(14)
		elif a.begins_with("--canvas="):
			var wh := a.substr(9).split("x")
			canvas = Vector2i(int(wh[0]), int(wh[1]))  # render at exactly this size, whatever the window
		elif a.begins_with("--scale3d="):
			scale3d = float(a.substr(10))
		elif a.begins_with("--upscaler="):
			upscaler = a.substr(11)  # bilinear, fsr, fsr2, metalfx_spatial, metalfx_temporal
		elif a.begins_with("--soak="):
			soak_min = float(a.substr(7))
		elif a.begins_with("--soak-dir="):
			soak_dir = a.substr(11)
		elif a.begins_with("--tier="):
			tier = a.substr(7)  # a quality tier by name, e.g. QT-NATIVE
		elif a == "--no-outline":
			player.set_outline(false)
	if tier != "":
		Quality.tier = tier  # applied when play mode calls Quality.track()
		Quality.base_tier = tier  # and the one the heat policy returns to
	if view > 0:
		player.teleport(view - 1)
	if walk:
		modes.start_walk_test()
	elif soak_min > 0.0:
		modes.start_soak(soak_min, soak_dir, canvas)
	elif perf_dir != "":
		modes.start_perf_route(perf_dir, perf_uncapped, perf_commit, canvas, scale3d, upscaler)
	elif set_path != "":
		var cfg = JSON.parse_string(FileAccess.get_file_as_string(TestModes.abs_path(set_path)))
		if typeof(cfg) != TYPE_DICTIONARY:
			push_error("shot set unreadable: " + set_path)
			get_tree().quit(1)
			return
		modes.start_shots(cfg)
	elif single != "":
		modes.start_shots({"size": [1600, 900], "shots": [{"view": maxi(view, 1), "out": single}]})
	else:
		Quality.track(get_viewport())  # play: the 3D pass at the tier's pixel budget, whatever the window's size
		Quality.start_thermal()
