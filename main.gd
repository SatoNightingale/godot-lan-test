class_name Main extends Node

# Para asegurarnos de que tengan cosas como la referencia a main, el metodo configure, etc. seria mejor hacer que hereden de una clase 'GameScreen'
@export var menu_scene_resource = preload("res://menus/main menu.tscn")
@export var game_scene_resource = preload("res://game/game.tscn")

@onready var menu_scene = $MenuContainer/Main
var game_scene: Node


func _ready() -> void:
	menu_scene.main = self
	Network.error.connect(error_popup.bind("Error de conexion"))


func change_to_game(data):
	if multiplayer.is_server():
		_load_game.rpc(data)


@rpc("authority", "call_local")
func _load_game(data):
	if menu_scene and is_instance_valid(menu_scene):
		menu_scene.queue_free()
		menu_scene = null
	game_scene = game_scene_resource.instantiate()
	game_scene.main = self
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
	menu_scene = menu_scene_resource.instantiate()
	menu_scene.main = self
	%MenuContainer.add_child(menu_scene)


func error_popup(message: String, title: String):
	%error_popup.dialog_text = message
	%error_popup.title = title
	%error_popup.popup_centered_clamped()
