#!/usr/bin/env -S godot -s
extends MainLoop

func _initialize() -> void:
	#ProjectSettings.set_setting("application/config/version", )
	ProjectSettings.save_custom("override.cfg")
	print("override.cfg generado")
