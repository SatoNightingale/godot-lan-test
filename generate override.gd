#!/usr/bin/env -S godot -s
extends MainLoop

func _initialize() -> void:
	var args = OS.get_cmdline_user_args()
	if not args.is_empty():
		var new_ver = args[0]
		ProjectSettings.set_setting("application/config/version", new_ver)
		print("Guardando proyecto con version: ", ProjectSettings.get_setting("application/config/version"))
		ProjectSettings.save()
	ProjectSettings.save_custom("override.cfg")
	print("override.cfg generado")
