extends SceneTree
## The audio buses (plan chapter 10, 13.2; M1 sprint 8, step 1) written to res://default_bus_layout.tres, which Godot
## loads at start. Every diegetic bus sends to World, World to Master; the six reverb buses are wet-only (dry 0, wet 1:
## an Area3D sends a copy of each sound to its reverb bus while the dry sound carries on through the player's own bus,
## so a reverb left at the default dry 1.0 would play every sound twice); their starting values are chapter 10, 9.1's,
## to be calibrated by measurement (13.11).
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/audio/make_buses.gd

const OUT := "res://default_bus_layout.tres"
## [name, sends to, [effects]]; an effect is [class, {property: value}]
const BUSES := [
	["World", "Master", [["AudioEffectHighShelfFilter", {"cutoff_hz": 7000.0, "gain": 1.0}], ["AudioEffectCompressor", {"ratio": 2.0, "threshold": -16.0, "attack_us": 20000.0, "release_ms": 400.0}]]],
	["Water", "World", [["AudioEffectHighShelfFilter", {"cutoff_hz": 5000.0, "gain": 1.0}]]],
	["Wind", "World", []],
	["Beds", "World", []],
	["Crowd", "World", []],
	["Voices", "World", [["AudioEffectCompressor", {"ratio": 1.6, "threshold": -18.0, "attack_us": 5000.0, "release_ms": 150.0}]]],
	["Ritual", "World", []],
	["Animals", "World", []],
	["Foley", "World", []],
	["Distant", "World", [["AudioEffectLowPassFilter", {"cutoff_hz": 2500.0}], ["AudioEffectReverb", {"room_size": 0.7, "damping": 0.6, "dry": 0.85, "wet": 0.15, "predelay_msec": 60.0}]]],
	["Rv_Hall", "World", [["AudioEffectReverb", {"room_size": 0.9, "damping": 0.45, "hipass": 0.05, "predelay_msec": 30.0, "dry": 0.0, "wet": 1.0}]]],
	["Rv_Room", "World", [["AudioEffectReverb", {"room_size": 0.35, "damping": 0.8, "hipass": 0.1, "predelay_msec": 6.0, "dry": 0.0, "wet": 1.0}]]],
	["Rv_Dead", "World", [["AudioEffectReverb", {"room_size": 0.2, "damping": 0.9, "hipass": 0.2, "predelay_msec": 3.0, "dry": 0.0, "wet": 1.0}]]],
	["Rv_Stone", "World", [["AudioEffectReverb", {"room_size": 0.6, "damping": 0.4, "hipass": 0.1, "predelay_msec": 12.0, "dry": 0.0, "wet": 1.0}]]],
	["Rv_Lane", "World", [["AudioEffectReverb", {"room_size": 0.35, "damping": 0.55, "hipass": 0.1, "predelay_msec": 10.0, "dry": 0.0, "wet": 1.0}],
		["AudioEffectDelay", {"dry": 0.0, "tap1_active": true, "tap1_delay_ms": 30.0, "tap1_level_db": -6.0, "tap2_active": true, "tap2_delay_ms": 70.0, "tap2_level_db": -10.0, "feedback_active": false}]]],
	["Rv_Gorge", "World", [["AudioEffectReverb", {"room_size": 0.85, "damping": 0.5, "hipass": 0.05, "predelay_msec": 40.0, "dry": 0.0, "wet": 1.0}],
		["AudioEffectDelay", {"dry": 0.0, "tap1_active": true, "tap1_delay_ms": 180.0, "tap1_level_db": -8.0, "tap2_active": false, "feedback_active": true, "feedback_delay_ms": 250.0, "feedback_level_db": -14.0}]]],
	["Music", "Master", [["AudioEffectCompressor", {"ratio": 2.0, "threshold": -20.0}]]],
	["UI", "Master", []],
]


func _initialize() -> void:
	while AudioServer.bus_count > 1:
		AudioServer.remove_bus(AudioServer.bus_count - 1)
	while AudioServer.get_bus_effect_count(0) > 0:
		AudioServer.remove_bus_effect(0, 0)
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, lim)
	for b in BUSES:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, String(b[0]))
		AudioServer.set_bus_send(i, StringName(b[1]))
		for e in b[2]:
			var fx: AudioEffect = ClassDB.instantiate(String(e[0]))
			for k in (e[1] as Dictionary):
				fx.set(k, e[1][k])
			AudioServer.add_bus_effect(i, fx)
	var err := ResourceSaver.save(AudioServer.generate_bus_layout(), OUT)
	print("buses: %d written to %s (%s)" % [AudioServer.bus_count, OUT, error_string(err)])
	quit()
