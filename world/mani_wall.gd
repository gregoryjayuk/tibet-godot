extends Node3D
## The barkor's mani wall (SHL-09; chapter 07: "clockwise, the holy thing on the right"; sprint 4, step 3): a walker in
## its lane going with the wall on their left for three seconds is told, once, how the lane is walked (ui/hud.gd), and
## an elder near by says so (PB-T44, world/barks.gd; sprint 7, step 8): the town's remark (chapter 07, 1); no score.

var a: Vector3  ## set before adding: the wall's west end and east end (Godot)
var b: Vector3
var half := 4.0  ## the lane's half width, the wall's included
var gloss := "A mani wall is kept on the right: its lane is walked east on the wall's north side and west on its south, and round its ends."  ## (the western wall's its own: tools/town/mani.py)
var _wrong := 0.0


func _physics_process(dt: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if p == null:
		return
	# in the town grid, x east and y north (Godot's -z)
	var u := Vector2(b.x - a.x, -(b.z - a.z))
	var length := u.length()
	u /= length
	var ap := Vector2(p.global_position.x - a.x, -(p.global_position.z - a.z))
	var along := ap.dot(u)
	var side := u.x * ap.y - u.y * ap.x  # > 0: north of the wall (to its left, looking east)
	var v := Vector2(p.velocity.x, -p.velocity.z)
	var going := v.dot(u)
	var wrong := along > -1.0 and along < length + 1.0 and absf(side) < half and absf(going) > 0.4 and signf(going) != signf(side)
	var was := _wrong
	_wrong = _wrong + dt if wrong else 0.0
	if _wrong > 3.0:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.gloss(gloss, "mani_wall")
		if was <= 3.0:  # each stretch walked the wrong way: an elder near may say so
			var barks := get_tree().get_first_node_in_group("barks")
			if barks != null:
				barks.call("remark_wrong_way", p.global_position)
