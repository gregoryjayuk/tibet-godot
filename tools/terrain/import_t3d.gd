extends SceneTree
## Builds the Terrain3D data of the valley map from tools/terrain/export_t3d.py's heights (spike S3, roadmap RT-12).
## Run headless:  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/terrain/import_t3d.gd
## Writes world/terrain/t3d/ (one Terrain3D region file per region; gitignored, rebuilt from the elevation tiles by
## fetch.py, export_t3d.py and this script). Heights stay 32-bit: 16-bit would round 1,200 m of relief to half-metres.

const SRC := "res://assets/generated/terrain/valley_t3d"
const OUT := "res://world/terrain/t3d"


func _initialize() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SRC + ".json"))
	var w: int = meta["width"]
	var h: int = meta["height"]
	var bytes := FileAccess.get_file_as_bytes(SRC + ".r32")
	if bytes.size() != w * h * 4:
		push_error("import_t3d: %s.r32 has %d bytes, expected %d" % [SRC, bytes.size(), w * h * 4])
		quit(1)
		return
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RF, bytes)
	# Terrain pass 8 (sprint 3, step 6): the control map from tools/terrain/control.py, 32-bit words read as floats, the
	# ground's class in the base texture id's bits.
	var ctrl: Image = null
	if FileAccess.file_exists(SRC + "_control.r32"):
		var cb := FileAccess.get_file_as_bytes(SRC + "_control.r32")
		if cb.size() == w * h * 4:
			ctrl = Image.create_from_data(w, h, false, Image.FORMAT_RF, cb)
		else:
			push_warning("import_t3d: %s_control.r32 has %d bytes, expected %d; no control map" % [SRC, cb.size(), w * h * 4])
	var t := Terrain3D.new()
	t.vertex_spacing = 1.0
	t.save_16_bit = false
	root.add_child(t)
	await process_frame
	t.change_region_size(int(meta["region_size"]))  # only takes effect once the node is in the tree
	var t0 := Time.get_ticks_msec()
	t.data.import_images([img, ctrl, null], Vector3(meta["x0"], 0.0, meta["z0"]), 0.0, 1.0)
	var dir := ProjectSettings.globalize_path(OUT)
	if DirAccess.dir_exists_absolute(dir):
		for f in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.make_dir_recursive_absolute(dir)
	t.data.save_directory(OUT)
	var probe := Vector3(0.0, 0.0, 0.0)
	print("import_t3d: %d regions of %d m in %d ms; height at Tsongra %.2f (Godot y); range %s; ground class at Tsongra %d, at (0, 0, -600) %d; saved to %s" % [
		t.data.get_region_count(), t.region_size, Time.get_ticks_msec() - t0, t.data.get_height(probe),
		str(t.data.get_height_range()), t.data.get_control_base_id(probe), t.data.get_control_base_id(Vector3(0, 0, -600)), dir])
	quit()
