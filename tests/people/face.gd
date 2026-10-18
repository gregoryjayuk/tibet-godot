extends Node3D
## The player's face (M1 sprint 5, step 4; Greg, 26 Sep 2026: "i would like to be able to really see a face on him that
## looks more real"): the man and the woman side by side in the afternoon light of the street's look, idle, facing the
## camera a little turned; stills of each face from 1 m, of both from 3 m and from 10 m, at the player camera's field of
## view (68 degrees). tools/people/face.sh lays them out.
## Writes tests/people/out/face_close_man.png, face_close_woman.png (0.75 m, a 30-degree lens), face_1m_man.png,
## face_1m_woman.png, face_3m.png, face_10m.png.

const Vignette := preload("res://world/vignette.gd")
const PERSON := preload("res://characters/person.gdshader")
const KINDS := ["player_man", "player_woman"]  ## or two others: -- --kinds=townsman,townswoman
const OUT := "res://tests/people/out"
const CANVAS := Vector2i(1920, 1080)


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
	var mat := ShaderMaterial.new()
	mat.shader = PERSON
	var heads := []
	var kinds: Array = KINDS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kinds="):
			kinds = a.substr(8).split(",")
	for k in kinds.size():
		var p: Node3D = (load("res://assets/generated/people/%s.glb" % kinds[k]) as PackedScene).instantiate()
		add_child(p)
		p.position = Vector3((k - (kinds.size() - 1) / 2.0) * 0.9, 0.0, 0.0)
		p.rotation.y = deg_to_rad(-15.0 if k * 2 < kinds.size() else 15.0)
		print("face: %s, %d painted surfaces" % [kinds[k], PersonLook.apply(p, mat)])
		var ap: AnimationPlayer = p.find_children("*", "AnimationPlayer", true, false)[0]
		ap.play("Idle_A")
		ap.seek(0.4, true)
		ap.pause()
		var sk: Skeleton3D = p.find_children("*", "Skeleton3D", true, false)[0]
		await get_tree().process_frame
		var hb := sk.find_bone("head")
		var eyes := sk.global_transform * sk.get_bone_global_pose(hb).origin + Vector3(0.0, 0.03, 0.0)  # the nose's root
		heads.append([eyes, p.global_transform.basis.z.normalized()])  # the figure faces its +z
	var cam := Camera3D.new()
	cam.fov = 68.0
	add_child(cam)
	cam.current = true
	# the portraits (a narrow lens, 0.75 m) show the painting; the rest are the player camera's own view
	var shots := []
	if kinds.size() == 2:
		shots = [["close_man", heads[0][0], heads[0][1], 0.75], ["close_woman", heads[1][0], heads[1][1], 0.75],
			["1m_man", heads[0][0], heads[0][1], 1.0], ["1m_woman", heads[1][0], heads[1][1], 1.0],
			["3m", Vector3(0.0, 1.1, 0.0), Vector3(0.0, 0.0, 1.0), 3.0], ["10m", Vector3(0.0, 0.9, 0.0), Vector3(0.0, 0.0, 1.0), 10.0]]
	else:  # a line of them: each face, then the line from the front and from behind
		for k in kinds.size():
			shots.append(["close_%s" % kinds[k], heads[k][0], heads[k][1], 0.75])
		var span := kinds.size() * 0.9
		shots.append(["line_front", Vector3(0.0, 0.95, 0.0), Vector3(0.0, 0.0, 1.0), span * 0.95 + 1.5])
		shots.append(["line_back", Vector3(0.0, 0.95, 0.0), Vector3(0.0, 0.0, -1.0), span * 0.95 + 1.5])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for s in shots:
		cam.fov = 30.0 if String(s[0]).begins_with("close") else 68.0
		var at: Vector3 = s[1]
		cam.position = at + (s[2] as Vector3) * float(s[3]) + Vector3(0.0, 0.03, 0.0)
		cam.look_at(at, Vector3.UP)
		for i in 30:
			await get_tree().process_frame
		var path := ProjectSettings.globalize_path(OUT).path_join("face_%s.png" % s[0])
		get_viewport().get_texture().get_image().save_png(path)
		print("face: %s" % path)
	get_tree().quit()
