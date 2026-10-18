extends SceneTree
## Writes the controls' input actions (autoload/controls.gd ACTIONS; IMP-044) into project.godot's [input], the map the
## game starts with, and drops any action no longer in the table. Run after changing the table:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/build/make_input.gd
## (test_controls.gd fails while project.godot and the table disagree.) `-- --out=<file>` writes the whole project
## settings there instead, for a look before overwriting.

const Controls := preload("res://autoload/controls.gd")


func _init() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	for p in ProjectSettings.get_property_list():
		var n := String(p["name"])
		if n.begins_with("input/") and not Controls.ACTIONS.has(n.substr(6)) and not n.begins_with("input/ui_"):
			ProjectSettings.set_setting(n, null)
	for a in Controls.ACTIONS:
		ProjectSettings.set_setting("input/" + a, {"deadzone": float((Controls.ACTIONS[a] as Array)[1]), "events": Controls.events_of(a)})
	var err := ProjectSettings.save_custom(out) if out != "" else ProjectSettings.save()
	print("make_input: %d actions written to %s (%s)" % [Controls.ACTIONS.size(), out if out != "" else "project.godot", error_string(err)])
	quit()
