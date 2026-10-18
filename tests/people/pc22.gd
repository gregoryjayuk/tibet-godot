extends Node3D
## PC-22 (plan chapter 09, the checks: "at 40 m, in grey scale, each group of people is told apart by silhouette"; M1
## sprint 4, step 5). The townsman and the townswoman (people2/body.py, DS-01 and DS-02), a monk (the stand-in until
## chapter 05's MK) and the player's traveller man and woman stand in one row on level ground in the afternoon light,
## each idle and then mid-stride beside itself; the view from 40 m at the game's field of view (68 degrees: a 1.65 m figure
## about 37 px tall at 1080p; chapter 09 counts 34), and from 10 m. tools/people/pc22.sh greys the 40 m view and lays
## both out for Greg's judgement.
## Run: tools/people/pc22.sh   Writes tests/people/out/pc22_40m.png and pc22_10m.png.

const Vignette := preload("res://world/vignette.gd")
const PERSON := preload("res://characters/person.gdshader")
const KINDS := ["townsman", "townswoman", "monk", "player_man", "player_woman"]
const OUT := "res://tests/people/out"
const CANVAS := Vector2i(1920, 1080)
const GAP := 1.25  ## metres between figures

var cam: Camera3D
var mat: ShaderMaterial


func _ready() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = CANVAS
	get_viewport().scaling_3d_scale = 1.0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	WorldClock.freeze(15.0)
	var look := Vignette.new()
	look.look_only = true
	add_child(look)
	await look.build()
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400.0, 400.0)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#B8A888")
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	mat = ShaderMaterial.new()
	mat.shader = PERSON
	var n := KINDS.size() * 2
	for k in KINDS.size():
		for row in 2:  # idle, then walking beside it, each figure a little turned from the camera
			var p: Node3D = (load("res://assets/generated/people/%s.glb" % KINDS[k]) as PackedScene).instantiate()
			add_child(p)
			p.position = Vector3((k * 2 + row - (n - 1) / 2.0) * GAP, 0.0, 0.0)
			p.rotation.y = deg_to_rad(20.0 if row == 0 else 60.0)
			PersonLook.apply(p, mat)
			var ap: AnimationPlayer = p.find_children("*", "AnimationPlayer", true, false)[0]
			ap.play("Idle_A" if row == 0 else "Walk")
			ap.seek(0.4, true)
			ap.pause()
	cam = Camera3D.new()
	cam.fov = 68.0  # the player's (player/player.gd)
	add_child(cam)
	cam.current = true
	for dist in [40.0, 10.0]:
		cam.position = Vector3(0.0, 1.6, dist)
		cam.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
		for i in 30:
			await get_tree().process_frame
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		var path := ProjectSettings.globalize_path(OUT).path_join("pc22_%dm.png" % int(dist))
		get_viewport().get_texture().get_image().save_png(path)
		print("pc22: %s" % path)
	get_tree().quit()
