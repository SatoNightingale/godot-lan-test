extends Node


func _init() -> void:
	if not Engine.is_embedded_in_editor():
		if DirAccess.dir_exists_absolute("user://patches"):
			var files = DirAccess.get_files_at("user://patches")
			for f in files:
				if f.ends_with(".pck"):
					var path = "user://patches".path_join(f)
					var success = ProjectSettings.load_resource_pack(path)
					if success:
						print("Cargado parche: ", path)
					else:
						printerr("No se pudo cargar parche: ", path)
		else:
			DirAccess.make_dir_absolute("user://patches")


func cargar_parche(path: String) -> String:
	var err
	if path.ends_with(".pck"):
		limpiar_parches()
		if DirAccess.copy_absolute(
			ProjectSettings.globalize_path(path),
			"user://patches/".path_join(path.get_file())
		) == OK:
			if ProjectSettings.load_resource_pack(path):
				var override_src = FileAccess.open("res://override.cfg", FileAccess.READ)
				var override_dest = FileAccess.open("user://override.cfg", FileAccess.WRITE)
				if override_src != null and override_dest != null:
					if override_dest.store_string(
					override_src.get_as_text()):
						override_src.close()
						override_dest.close()
						return ""
					else:
						err = "No se pudo escribir el archivo de configuraciones"
				else: if not override_src:
					err = "Archivo de configuraciones no encontrado"
				else:
					err = "No se pudo crear el archivo de configuraciones"
			else:
				err = "Error al cargar recursos"
		else:
			err = "Error al copiar el archivo"
	else:
		err = "Archivo incorrecto: no tiene la extensión .pck"
	return err


func limpiar_parches():
	var files = DirAccess.get_files_at("user://patches")
	for f in files:
		if f.ends_with(".pck"):
			DirAccess.remove_absolute("user://patches".path_join(f))


#func open_patch_finder():
	#var filedialog = FileDialog.new()
	#filedialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	#filedialog.access = FileDialog.ACCESS_FILESYSTEM
	##filedialog.add_filter("*.pck", "Archivos de paquetes de Godot")
	#filedialog.filters.append("*.pck")
	#filedialog.use_native_dialog = true
	#filedialog.dialog_hide_on_ok = true
	#filedialog.title = "Buscar parche"
	#filedialog.file_selected.connect(func(path):
		#var err = copiar_parche(path)
		#if err == OK:
			#var msg = confirmation_dialog("Se han cargado algunas actualizaciones. Para que tengan efecto, el juego debe ser reiniciado. ¿Acepta?")
			#msg.confirmed.connect(func():
				#OS.set_restart_on_exit(true)
				#get_tree().quit()
			#)
		#else:
			#message_box("La carga del parche ha fallado\nCodigo de error: {0}".format([err]))
		#delete_dialog(filedialog)
	#)
	#filedialog.canceled.connect(delete_dialog.bind(filedialog))
	#filedialog.close_requested.connect(delete_dialog.bind(filedialog))
	#add_child(filedialog)
	#filedialog.popup_centered_clamped()


#func message_box(message: String) -> AcceptDialog:
	#var dialog = AcceptDialog.new()
	#dialog.dialog_text = message
	#dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	#dialog.title = "Sistema de parcheo"
	#dialog.ok_button_text = "Aceptar"
	#dialog.dialog_autowrap = true
	#dialog.confirmed.connect(delete_dialog.bind(dialog))
	#dialog.canceled.connect(delete_dialog.bind(dialog))
	#dialog.close_requested.connect(delete_dialog.bind(dialog))
	#add_child(dialog)
	#dialog.popup_centered_clamped()
	#return dialog
#
#
#func delete_dialog(dialog: AcceptDialog):
	#remove_child(dialog)
	#dialog.queue_free()
