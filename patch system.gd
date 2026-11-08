extends Node

# Si esto se carga como el primer autoload, y el es el que carga los paquetes con load_resource_pack y por tanto el que actualiza los scripts, el mismo no puede actualizarse, porque cuando llama a load_resource_pack ya esta cargado. Al parecer no se recarga el codigo mientras se esta ejecutando. Por otro lado, no puedo llamar a PatchSystem.get_script().reload() porque este no funciona cuando hay instancias del script. Y no creo que se hacer PatchSystem.free(), recargar el script y despues asignarle valor de nuevo (porque los autoloads son constantes)
# Por tanto, es mejor que el codigo de cargar parche se quede en main, que si es actualizado por esto. Lamentablemente, las builds que no tengan configurado su archivo de override no podran ser actualizadas, porque en un proyecto exportado no se pueden sobreescribir las propiedades y guardarlas con ProjectSettings.save(). Y en override.cfg es donde van los nuevos autoloads (imprescindibles para el juego) y la nueva version

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
						printerr("No se pudo cargar parche: ", path, ". Error: ", error_string(success))
		else:
			DirAccess.make_dir_absolute("user://patches")
