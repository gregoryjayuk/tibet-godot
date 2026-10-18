extends Node
## Streamer (plan chapter 11, 4.2-4.3; roadmap RT-14, spike S6): no loading screens. Exteriors are always resident;
## the detail layers of each 128 m cell load on a background thread when the player comes within 320 m of the cell
## and are freed beyond 420 m. A loaded cell is instantiated off the tree and enters it a few nodes at a time within a
## time budget of 2.5 ms a frame: chapter 11 proposed 300 nodes a frame, but S6 measured 118 nodes (40 physics bodies
## among them) at 20 ms, so the budget is time, not a count. Interiors hang on door markers: requested at 40 m, added at 15 m
## over three frames, freed at 60 m (chapter 11, 4.2). A warm-up pass draws one of everything once behind the title
## screen so no pipeline compiles in play (chapter 11, 7.5; spike S9). `last_us`: this frame's cost.

const CELL := 128.0
const LOAD_R := 320.0
const FREE_R := 420.0
const BUDGET_US := 2500  ## main-thread time a frame for nodes entering the tree
const DOOR_REQUEST := 40.0
const DOOR_ADD := 15.0
const DOOR_FREE := 60.0
const DOOR_FRAMES := 3

var enabled := false
var focus := Vector3.ZERO
var cells_dir := ""
var world: Node3D
var cells := {}  ## Vector2i -> {state, path, src, holder, pending}
var interiors: Array[Dictionary] = []  ## {door, path, parent, state, src, holder, pending, per_frame}
var resident: Array[Resource] = []  ## scenes kept loaded: their materials and compiled shaders must outlive their nodes
const MM_POOL := 64
const MM_CAPACITY := 600
var _mm_pool: Array[MultiMeshInstance3D] = []  ## MultiMeshes that stay in the tree: one entering it cost 13-14 ms (S6)

var last_us := 0
var nodes_added := 0  ## this frame
var slowest := ""  ## this frame's slowest node to enter the tree, and its time, for the tests
var _slowest_us := 0
var events: Array[String] = []  ## what happened this frame, for the test log


func setup(p_world: Node3D, dir: String) -> void:
	world = p_world
	cells_dir = dir
	for i in MM_POOL:
		var m := _new_mmi()
		world.add_child(m)  # in the tree for good, hidden while free; a cell only refills it
		_mm_pool.append(m)
	enabled = true


func _new_mmi() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = MM_CAPACITY
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # filled outside the physics tick
	mmi.visible = false
	return mmi


## An interior behind a door: its scene is added under `parent` (placed at the door) when the player comes close.
func add_interior(door: Vector3, path: String, parent: Node3D) -> void:
	interiors.append({"door": door, "path": path, "parent": parent, "state": "idle"})


func _cell_distance(key: Vector2i) -> float:
	var x0 := key.x * CELL
	var z0 := key.y * CELL
	var dx := maxf(maxf(x0 - focus.x, 0.0), focus.x - (x0 + CELL))
	var dz := maxf(maxf(z0 - focus.z, 0.0), focus.z - (z0 + CELL))
	return sqrt(dx * dx + dz * dz)


func _process(_dt: float) -> void:
	if not enabled:
		return
	var t0 := Time.get_ticks_usec()
	events.clear()
	nodes_added = 0
	slowest = ""
	_slowest_us = 0
	var budget := t0 + BUDGET_US  ## a deadline in microseconds
	# Ask for the cells now within reach (none where the town is resident and only the rooms stream: cells_dir "").
	var c := Vector2i(int(floor(focus.x / CELL)), int(floor(focus.z / CELL)))
	var r := int(ceil(LOAD_R / CELL)) if cells_dir != "" else -1
	for iz in range(c.y - r, c.y + r + 1):
		for ix in range(c.x - r, c.x + r + 1):
			var key := Vector2i(ix, iz)
			if cells.has(key) or _cell_distance(key) > LOAD_R:
				continue
			var path := "%s/c_%d_%d.scn" % [cells_dir, ix, iz]
			if not ResourceLoader.exists(path):
				continue
			ResourceLoader.load_threaded_request(path)
			cells[key] = {"state": "requested", "path": path}
	# Interiors first: the one the player is walking into matters most.
	for e in interiors:
		budget = _interior(e, budget)
	# Cells: loaded -> instantiated off the tree (one a frame) -> entering it within the budget -> live -> freed.
	var began := false
	for key in cells.keys():
		var e: Dictionary = cells[key]
		match e["state"]:
			"requested":
				if not began and ResourceLoader.load_threaded_get_status(e["path"]) == ResourceLoader.THREAD_LOAD_LOADED:
					began = true
					var ps: PackedScene = ResourceLoader.load_threaded_get(e["path"])
					if _cell_distance(key) > FREE_R:
						cells.erase(key)
						continue
					_begin_adding(e, ps, world)
					events.append("cell %s loaded" % str(key))
			"adding":
				if Time.get_ticks_usec() < budget:
					_add_some(e, budget)
				if e["state"] == "live":
					events.append("cell %s live" % str(key))
			"live":
				if _cell_distance(key) > FREE_R:
					var h: Node = e["holder"]
					for m in e.get("pooled", []):  # back to the pool, hidden, still in the tree
						(m as MultiMeshInstance3D).visible = false
						(m as MultiMeshInstance3D).multimesh.visible_instance_count = 0
						_mm_pool.append(m)
					h.queue_free()
					cells.erase(key)
					events.append("cell %s freed" % str(key))
	last_us = Time.get_ticks_usec() - t0


## A loaded scene is instantiated off the tree; its nodes then enter it a few at a time (_add_some). Cells' data-only
## nodes (occluder boxes, MultiMesh buffers) are turned into the real thing here, on the main thread.
func _begin_adding(e: Dictionary, ps: PackedScene, parent: Node3D) -> void:
	var src: Node3D = ps.instantiate()
	for n in src.find_children("*", "Node3D", true, false):
		if n.has_meta("occluder_box"):  # built here, on the main thread (see tools/build/make_test_cells.gd)
			var occ := OccluderInstance3D.new()
			var box := BoxOccluder3D.new()
			box.size = n.get_meta("occluder_box")
			occ.occluder = box
			n.add_child(occ)
		if n.has_meta("multimesh_buffer"):  # from the pool, already in the tree: filling one costs little
			var mmi: MultiMeshInstance3D
			if _mm_pool.is_empty():
				mmi = _new_mmi()
				world.add_child(mmi)
				events.append("MultiMesh pool empty: made one")
			else:
				mmi = _mm_pool.pop_back()
			var mm := mmi.multimesh
			var buf: PackedFloat32Array = n.get_meta("multimesh_buffer")
			var count := mini(buf.size() / 12, MM_CAPACITY)
			var full := buf.duplicate()  # padded to the pool's size by the engine, not a GDScript loop (15 ms for five cells)
			full.resize(MM_CAPACITY * 12)
			mm.mesh = n.get_meta("multimesh_mesh")
			mm.buffer = full
			mm.visible_instance_count = count
			mm.custom_aabb = n.get_meta("multimesh_aabb")
			mmi.visible = true
			var used: Array = e.get("pooled", [])
			used.append(mmi)
			e["pooled"] = used
	var holder := Node3D.new()
	holder.name = src.name
	holder.transform = src.transform
	parent.add_child(holder)
	var pending := src.get_children()
	for n in pending:
		for d in [n] + n.find_children("*", "", true, false):
			(d as Node).owner = null  # the nodes are moving to a new root
	e["src"] = src
	e["holder"] = holder
	e["pending"] = pending
	e["state"] = "adding"


## Move nodes from the off-tree copy into the live holder until the deadline (always at least one node).
func _add_some(e: Dictionary, deadline: int, max_nodes := -1) -> int:
	var pending: Array = e["pending"]
	var src: Node = e["src"]
	var holder: Node = e["holder"]
	var added := 0
	while not pending.is_empty() and (added == 0 or Time.get_ticks_usec() < deadline) and (max_nodes < 0 or added < max_nodes):
		var n: Node = pending.pop_back()
		var a0 := Time.get_ticks_usec()
		src.remove_child(n)
		holder.add_child(n)
		var took := Time.get_ticks_usec() - a0
		if took > _slowest_us:
			_slowest_us = took
			slowest = "%s %s %.1f ms" % [n.get_class(), n.name, took / 1000.0]
		var cost := 1 + n.get_child_count()
		added += cost
		nodes_added += cost
	if pending.is_empty():
		src.free()
		e["state"] = "live"
	return deadline


func _interior(e: Dictionary, budget: int) -> int:
	var d := focus.distance_to(e["door"])
	match e["state"]:
		"idle":
			if d < DOOR_REQUEST:
				if not e.has("scene"):
					ResourceLoader.load_threaded_request(e["path"])
				e["state"] = "requested"
				events.append("interior requested at %.1f m" % d)
		"requested":
			if d > DOOR_FREE:
				e["state"] = "idle"  # the load finishes in the background and is kept for next time
			elif d < DOOR_ADD and (e.has("scene") or ResourceLoader.load_threaded_get_status(e["path"]) == ResourceLoader.THREAD_LOAD_LOADED):
				if not e.has("scene"):
					# Kept for good: freeing a scene frees its materials, and the next visit recompiled their shaders
					# on the main thread, 18-33 ms (spike S6, docs/ISSUES.md).
					e["scene"] = ResourceLoader.load_threaded_get(e["path"])
					resident.append(e["scene"])
				_begin_adding(e, e["scene"], e["parent"])
				e["per_frame"] = int(ceil(float((e["pending"] as Array).size()) / DOOR_FRAMES))
				events.append("interior adding at %.1f m" % d)
		"adding":
			# The interior goes in over about three frames whatever else is waiting: the player is 15 m from the door.
			_add_some(e, Time.get_ticks_usec() + BUDGET_US * 4, e["per_frame"])
			if e["state"] == "live":
				events.append("interior live")
		"live":
			if d > DOOR_FREE:
				(e["holder"] as Node).queue_free()
				e["state"] = "idle"
				events.append("interior freed at %.1f m" % d)
	return budget


## Draw one of each streamed scene in front of the camera for a few frames, behind a black curtain, then free them,
## so every pipeline they need is compiled before play (chapter 11, 7.5). Returns when done.
func warm_up(cam: Camera3D, paths: Array[String], frames := 8) -> void:
	var curtain := CanvasLayer.new()
	curtain.layer = 100
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.add_child(black)
	add_child(curtain)
	var holder := Node3D.new()
	world.add_child(holder)
	var ahead := cam.global_transform.origin - cam.global_transform.basis.z * 6.0
	for p in paths:
		var ps: PackedScene = load(p)
		resident.append(ps)  # what the warm-up compiled stays compiled
		for e in interiors:
			if e["path"] == p:
				e["scene"] = ps
		var n: Node3D = ps.instantiate()
		holder.add_child(n)
		# Everything, whatever its own layout, is gathered into a 4 m box in front of the camera, facing it.
		for g in n.find_children("*", "Node3D", true, false):
			if g.get_parent() == n:
				var g3 := g as Node3D
				g3.global_position = ahead + Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2))
				g3.look_at(cam.global_position, Vector3.UP, true)  # one-sided quads must face the camera to be drawn
				if g is MultiMeshInstance3D:
					var mm := (g as MultiMeshInstance3D).multimesh
					if mm != null and mm.mesh != null:
						g3.global_position -= mm.get_aabb().get_center() - g3.global_basis * Vector3.ZERO
	for i in frames:
		await get_tree().process_frame
	holder.queue_free()
	curtain.queue_free()
	await get_tree().process_frame
