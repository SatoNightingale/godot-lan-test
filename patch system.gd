extends Node

#func _init() -> void:
	#var files = DirAccess.get_files_at("user://patches")
	#for f in files:
		#if f.ends_with(".pck"):
			#var success = ProjectSettings.load_resource_pack("user://patches".path_join(f))
			#if success:
				#print("Cargado parche: ", f)
			#else:
				#printerr("No se pudo cargar parche: ", f)
