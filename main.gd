extends Node

signal player_data_updated(id: int, new_data)

var game_scene = preload("res://game/game.tscn")
var connect_scene = preload("res://connect menu/connect menu.tscn")
var lobby_scene = preload("res://waiting room/waiting_room.tscn")

var _active_scene: Node

var player_name: String
var player_data: Dictionary
var ready_player_count = 0


func _ready() -> void:
	read_config()
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(error_popup.bind("Error al conectar al servidor", "Error de conexion"))
	change_scene(connect_scene, init_connect_menu)
	debug_tasks()


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


func on_hosted(_player_name: String):
	player_name = _player_name
	player_data[multiplayer.get_unique_id()] = {"name": player_name}
	save_config()
	change_scene(lobby_scene, init_waiting_room_server)


func on_connected(_player_name: String, address: String):
	player_name = _player_name
	player_data[multiplayer.get_unique_id()] = {"name": player_name}
	save_config()
	change_scene(lobby_scene, init_waiting_room_client.bind(address))


func init_connect_menu(connect_menu: Node):
	connect_menu.player_name = player_name
	connect_menu.hosted.connect(on_hosted)
	connect_menu.connected.connect(on_connected)
	connect_menu.error.connect(error_popup.bind("Error de conexion"))


func init_waiting_room_server(waiting_room: Node):
	waiting_room.player_data = player_data
	player_data_updated.connect(waiting_room.on_player_data_updated)
	waiting_room.game_start.connect(load_game)
	waiting_room.exit.connect(_on_waiting_room_disconnect)


func init_waiting_room_client(waiting_room: Node, address: String):
	init_waiting_room_server(waiting_room)
	waiting_room.server_address = address


func load_game():
	var game_init = func(game):
		game.player_data = player_data
		game.ready.connect(func():
			print(player_name, " game ready")
			on_player_loaded.rpc_id(1)
		)
	change_scene(game_scene, game_init)


@rpc("any_peer", "call_local")
func on_player_loaded():
	if multiplayer.is_server():
		ready_player_count += 1
		print("ready players: ", ready_player_count)
		if ready_player_count == player_data.size():
			get_node("/root/Main/Game").server_initialize()


@rpc("any_peer", "call_local")
func _register_player(nombre: String):
	var id = multiplayer.get_remote_sender_id()
	if id not in player_data:
		print(player_name, ": Peer conectado: ", id, " -> ", nombre)
		player_data[id] = {"name": nombre}
		player_data_updated.emit(id, player_data[id])


func change_scene(scene: PackedScene, initproc: Callable) -> Node:
	var new_scene = scene.instantiate()
	if new_scene != null:
		if _active_scene != null:
			remove_child(_active_scene)
			_active_scene.queue_free()
		_active_scene = new_scene
		initproc.call(new_scene)
		add_child(_active_scene)
	else:
		printerr("Error al cargar la escena: ", scene.resource_name)
	return new_scene


func _on_connected_to_server():
	print("on connected to server")
	_register_player.rpc(player_name)


func _on_peer_connected(id: int):
	_register_player.rpc_id(id, player_name)


func _on_peer_disconnected(id: int):
	player_data.erase(id)


func _on_server_disconnected():
	error_popup("El servidor se ha desconectado", "Desconexion")
	player_data.clear()
	change_scene(connect_scene, init_connect_menu)


func _on_waiting_room_disconnect():
	player_data.clear()
	change_scene(connect_scene, init_connect_menu)


func error_popup(message: String, title := "Error"):
	%error_popup.dialog_text = message
	%error_popup.title = title
	%error_popup.popup_centered_clamped()


func parse_arguments() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--load")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""
	return arguments
