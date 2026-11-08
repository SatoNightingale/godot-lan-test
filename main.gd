class_name Main extends Node

# Para asegurarnos de que tengan cosas como la referencia a main, el metodo configure, etc. seria mejor hacer que hereden de una clase 'GameScreen'

@onready var menu_scene = $MenuContainer/Main
var game_scene: Node

var program_args


func _init() -> void:
	program_args = parse_arguments()


func _ready() -> void:
	menu_scene.main = self
	menu_scene.error_popup.connect(error_popup)
	Network.error.connect(error_popup.bind("Error de conexion"))
	Configurations.mostrar_consola_prop.conectar(func(value, _old_value):
		%console.visible = value
	)
	ConsoleLogger.set_console(%console)
	# ERROR: Cannot reload script while instances exist.
	#print("Recargando script de PathSystem: ", PatchSystem.get_script().reload())


func change_to_game(data):
	if multiplayer.is_server():
		_load_game.rpc(data)


@rpc("authority", "call_local")
func _load_game(data):
	if menu_scene and is_instance_valid(menu_scene):
		menu_scene.queue_free()
		menu_scene = null
	game_scene = load("res://game/game.tscn").instantiate() 
	game_scene.main = self
	game_scene.error_popup.connect(error_popup)
	game_scene.player_data = data
	%GameContainer.add_child(game_scene)


func change_to_menu():
	if multiplayer.is_server():
		_load_menu.rpc()


@rpc("authority", "call_local")
func _load_menu():
	if game_scene and is_instance_valid(game_scene):
		game_scene.queue_free()
		game_scene = null
	menu_scene = load("res://menus/main menu.tscn").instantiate()
	menu_scene.main = self
	menu_scene.error_popup.connect(error_popup)
	%MenuContainer.add_child(menu_scene)


func error_popup(message: String, title: String):
	%error_popup.dialog_text = message
	%error_popup.title = title
	%error_popup.popup_centered_clamped()


func parse_arguments() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""
	return arguments


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
