#!/usr/bin/env -S godot -s
@tool
extends EditorScript

func _run() -> void:
	#ProjectSettings.set_setting("application/config/version", )
	ProjectSettings.save_custom("override.cfg")
	print("override.cfg generado")
