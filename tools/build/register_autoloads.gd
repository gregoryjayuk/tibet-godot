extends SceneTree
## RT-03 (plan chapter 11, 3.1): register the game's autoload services, in processing order. Idempotent.
## Run headless: Godot --headless --path . -s tools/build/register_autoloads.gd

const AUTOLOADS := [
	["WorldClock", "res://autoload/world_clock.gd"],
	["Quality", "res://autoload/quality.gd"],
	["Telemetry", "res://autoload/telemetry.gd"],
	["TownSim", "res://autoload/town_sim.gd"],  # RT-13: idle until a scene calls setup()
	["Streamer", "res://autoload/streamer.gd"],  # RT-14: idle until a scene calls setup()
]

func _init() -> void:
	for a in AUTOLOADS:
		ProjectSettings.set_setting("autoload/" + a[0], "*" + a[1])
	var err := ProjectSettings.save()
	print("register_autoloads: ", AUTOLOADS.size(), " autoloads, error=", err)
	quit(err)
