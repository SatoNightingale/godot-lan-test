extends Node


func _init() -> void:
	if not Engine.is_embedded_in_editor():
		var files = DirAccess.get_files_at("user://patches")
		for f in files:
			if f.ends_with(".pck"):
				aplicar_parche("user://patches".path_join(f))


func copiar_parche(path: String) -> Error:
	limpiar_parches()
	var err = DirAccess.copy_absolute(
		ProjectSettings.globalize_path(path),
		"user://patches/".path_join(path.get_file())
	)
	if err != OK:
		message_box("La carga del parche ha fallado\nCodigo de error: {0}".format([str(err)]))
	return err


func limpiar_parches():
	var files = DirAccess.get_files_at("user://patches")
	for f in files:
		if f.ends_with(".pck"):
			DirAccess.remove_absolute("user://patches".path_join(f))


func aplicar_parche(path: String):
	var success = ProjectSettings.load_resource_pack(path)
	if success:
		print("Cargado parche: ", path)
	else:
		printerr("No se pudo cargar parche: ", path)


func message_box(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	dialog.title = "Sistema de parcheo"
	add_child(dialog)
	dialog.ready.connect(func(): 
		dialog.popup_centered_clamped()
		dialog.confirmed.connect(remove_child.bind(dialog))
		dialog.confirmed.connect(dialog.queue_free)
	)
