extends Node

signal player_data_updated(id: int, new_data)

var game_scene = preload("res://game/game.tscn")
var connect_menu = preload("res://menus/connect menu/connect menu.tscn").instantiate()
var waiting_room = preload("res://menus/waiting room/waiting_room.tscn").instantiate()

var _active_scene: Node

var player_name: String
var player_data: Dictionary
#var ready_player_count = 0


func _ready() -> void:
	read_config()
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(error_popup.bind("Error al conectar al servidor.\nRevise la direccion IP", "Error de conexion"))
	# connect_menu
	connect_menu.player_name = player_name
	connect_menu.hosted.connect(on_hosted)
	connect_menu.connected.connect(on_connected)
	connect_menu.error.connect(error_popup.bind("Error de conexion"))
	# waiting_room
	waiting_room.player_data = player_data
	player_data_updated.connect(waiting_room.on_player_data_updated)
	waiting_room.game_start.connect(load_game)
	waiting_room.exit.connect(_on_waiting_room_disconnect)
	change_scene(connect_menu)
	#debug_tasks()


func read_config():
	var config = ConfigFile.new()
	var errcode = config.load("user://config.cfg")
	if errcode != OK:
		printerr("Error al cargar la configuracion: ", errcode)
		return
	player_name = config.get_value("data", "player_name", "Player")


func save_config():
	var config = ConfigFile.new()
	config.set_value("data", "player_name", player_name)
	var errcode = config.save("user://config.cfg")
	if errcode != OK:
		printerr("Error al guardar la configuracion: ", errcode)


func debug_tasks():
	var args = parse_arguments()
	if "host" in args or "player" in args:
		var peer = ENetMultiplayerPeer.new()
		if "host" in args:
			if peer.create_server(4242, 4) == OK:
				multiplayer.multiplayer_peer = peer
				on_hosted("Server")
		if "player" in args:
			var numplayer = args["player"]
			if peer.create_client("localhost", 4242) == OK:
				multiplayer.multiplayer_peer = peer
				on_connected("Player " + numplayer, "localhost")
				match numplayer:
					"1": get_window().position = Vector2i(723, 110)
					"2": get_window().position = Vector2i(723, 110)
					"3": get_window().position = Vector2i(723, 110)
		#await multiplayer.peer_connected
		#if multiplayer.is_server():
			#$"waiting room"._on_start_pressed()


func init_player_data(_player_name: String):
	player_name = _player_name
	player_data[multiplayer.get_unique_id()] = {"name": player_name}
	save_config()

func on_hosted(_player_name: String):
	init_player_data(_player_name)
	change_scene(waiting_room)

func on_connected(_player_name: String, address: String):
	waiting_room.server_address = address
	player_name = _player_name


func load_game():
	var game = game_scene.instantiate()
	game.player_data = player_data
	get_tree().change_scene_to_node(game)


@rpc("any_peer", "call_local")
func _register_player(nombre: String):
	var id = multiplayer.get_remote_sender_id()
	if id not in player_data:
		print(player_name, ": Peer conectado: ", id, " -> ", nombre)
		player_data[id] = {"name": nombre}
		player_data_updated.emit(id, player_data[id])


func change_scene(scene: Node):
	if _active_scene != null:
		remove_child(_active_scene)
	_active_scene = scene
	add_child(scene)
	#_active_scene.request_ready()
	if _active_scene.has_method("initialize"):
		_active_scene.initialize()


func _on_connected_to_server():
	print("on connected to server")
	init_player_data(player_name)
	change_scene(waiting_room)
	_register_player.rpc(player_name)


func _on_peer_connected(id: int):
	_register_player.rpc_id(id, player_name)


func _on_peer_disconnected(id: int):
	player_data.erase(id)


func _on_server_disconnected():
	error_popup("El servidor se ha desconectado", "Desconexion")
	player_data.clear()
	change_scene(connect_menu)


func _on_waiting_room_disconnect():
	player_data.clear()
	change_scene(connect_menu)


func error_popup(message: String, title := "Error"):
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
