@tool
extends EditorPlugin
## Registers the post-import step for the kit's GLBs (post_import.gd).

var _post: EditorScenePostImportPlugin


func _enter_tree() -> void:
	_post = preload("res://addons/dungkardo_import/post_import.gd").new()
	add_scene_post_import_plugin(_post)


func _exit_tree() -> void:
	remove_scene_post_import_plugin(_post)
