class_name Main extends Node

# Para asegurarnos de que tengan cosas como la referencia a main, el metodo configure, etc. seria mejor hacer que hereden de una clase 'GameScreen'

@onready var menu_scene = $MenuContainer/Main
var game_scene: Node

var program_args := parse_arguments()

func _ready() -> void:
	menu_scene.main = self
	menu_scene.error_popup.connect(error_popup)
	Network.error.connect(error_popup.bind("Error de conexion"))


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
