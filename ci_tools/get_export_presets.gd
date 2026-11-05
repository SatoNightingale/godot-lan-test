extends MainLoop

func _init() -> void:
	var presets = ConfigFile.new()
	var err = presets.load("res://export_presets.cfg")
	if err != OK:
		printerr("No se pudo cargar export_presets.cfg")
		return
		#quit(1)
	for section in presets.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			var preset_name = presets.get_value(section, "name")
			var preset_path = presets.get_value(section, "export_path")
			print(preset_name, "\t", preset_path)
	#quit()
