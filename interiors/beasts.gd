extends Node3D
## The headman's beasts in their stalls (plan chapter 04, 4.1: "the two mules, the pony, the dzo and the cow in stalls
## against the south wall"; M2 sprint 7, step 4): when the stable's scene is streamed in, each at its stall (the kit's
## STALL sockets, in the stable's furnishings; tibet-blender kit/headman_rooms.py STALLS), facing its manger, eating or
## standing, its own coat; gone with the scene. The stand-ins are Mesh2Motion's horse, as the caravan's yak and mules
## (people2/stand_ins.py: mule, pony, and since this sprint dzo and cow).

const FIGS := {"mule": "res://assets/generated/people/mule.glb", "pony": "res://assets/generated/people/pony.glb",
		"dzo": "res://assets/generated/people/dzo.glb", "cow": "res://assets/generated/people/cow.glb"}
const PERSON := preload("res://characters/person.gdshader")  ## the coat the figure's vertex colour, lit as the people are
const TINTS := [1.0, 0.86, 1.04, 0.95, 1.0]  ## each its own tone (the second mule darker)

@export var kinds: Array[String] = ["mule", "mule", "pony", "dzo", "cow"]  ## in the stalls' order, west to east

var figures: Array = []  ## [root, AnimationPlayer] of each, for the tests
var _mat: ShaderMaterial


func _ready() -> void:
	set_process(true)  # the Streamer adds a room's nodes over a few frames, last to first: the stalls may come after this


func _process(_dt: float) -> void:
	if not figures.is_empty() or get_parent() == null:
		set_process(false)
		return
	var stalls := get_parent().find_children("SOCK_STALL_*", "Node3D", true, false)
	if stalls.is_empty():
		return
	set_process(false)
	_stand(stalls)


func _stand(stalls: Array) -> void:
	stalls.sort_custom(func(a, b): return int(String(a.name).get_slice("_", 2)) < int(String(b.name).get_slice("_", 2)))
	for k in mini(stalls.size(), kinds.size()):
		var kind := kinds[k]
		if not ResourceLoader.exists(FIGS[kind]):
			continue
		var s := stalls[k] as Node3D
		var fig: Node3D = (load(FIGS[kind]) as PackedScene).instantiate()
		var root := Node3D.new()
		root.name = "%s_%d" % [kind.capitalize(), k]
		add_child(root)
		root.add_child(fig)
		# at its stall, facing its manger: the socket's way (its Blender +y, Godot's -z), the figure built facing +z
		var at := to_local(s.global_position)
		var face := global_basis.inverse() * (-s.global_basis.z)
		root.position = Vector3(at.x, at.y, at.z)
		root.rotation.y = atan2(face.x, face.z)
		if _mat == null:
			_mat = ShaderMaterial.new()
			_mat.shader = PERSON
		for mi in fig.find_children("*", "MeshInstance3D", true, false):  # indoors: no sky's ambient (a pale grey in a dark
			(mi as MeshInstance3D).material_override = _mat  # stable with a standard material)
			(mi as MeshInstance3D).set_instance_shader_parameter("indoor", 1.0)
			(mi as MeshInstance3D).set_instance_shader_parameter("tint", TINTS[k % TINTS.size()])
		var sk: Skeleton3D = fig.find_children("*", "Skeleton3D", true, false)[0]
		if kind == "mule":  # a mule's long ears (bones the clips never move)
			for e in ["ear_1_r", "ear_1_l"]:
				var bi := sk.find_bone(e)
				if bi >= 0:
					sk.set_bone_pose_scale(bi, Vector3(1.25, 1.7, 1.25))
		var ap: AnimationPlayer = fig.find_children("*", "AnimationPlayer", true, false)[0]
		var clip := "Eating" if (k % 2 == 0 and ap.has_animation("Eating")) else "Idle"
		if ap.has_animation(clip):
			ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			ap.play(clip)
			ap.seek(fposmod(k * 1.37, ap.get_animation(clip).length), true)
		figures.append([root, ap])
