extends Control

signal player_data_updated(id: int, new_data)

@export var max_players = 4

var game_scene = preload("res://game/game.tscn")
var connect_menu = preload("res://menus/connect menu/connect menu.tscn").instantiate()
var waiting_room = preload("res://menus/waiting room/waiting_room.tscn").instantiate()
var settings = preload("res://menus/settings/settings.tscn").instantiate()

var _active_scene: Node

var player_data: Dictionary


func _ready() -> void:
	# leer configuraciones
	Configurations.read_config()
	# conectar señales multiplayer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(error_popup.bind("Error al conectar al servidor.\nRevise la direccion IP", "Error de conexion"))
	# inicializar escenas
	init_scenes()
	# version
	%version_label.text = ProjectSettings.get_setting("application/config/version")
	# botones
	%boton_crear.pressed.connect(host_game)
	%boton_conectar.pressed.connect(change_scene.bind(connect_menu))
	%boton_config.pressed.connect(change_scene.bind(settings))
	# sistema de parcheo
	%boton_parche.pressed.connect(%patch_finder.popup_file_dialog)
	%patch_finder.file_selected.connect(func(path):
		if PatchSystem.copiar_parche(path) == OK:
			%dlg_patch_restart.popup_centered_clamped()
	)
	%dlg_patch_restart.confirmed.connect(func():
		OS.set_restart_on_exit(true)
		get_tree().quit()
	)
	# tema movil
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		theme = load("res://menus/tema_movil.tres")
	# tareas de debugeo
	if OS.has_feature("editor"):
		debug_tasks()


func init_scenes():
	# connect_menu
	connect_menu.connected.connect(on_connected)
	connect_menu.error.connect(error_popup.bind("Error de conexion"))
	# waiting_room
	waiting_room.player_data = player_data
	player_data_updated.connect(waiting_room.on_player_data_updated)
	waiting_room.game_start.connect(load_game)
	waiting_room.tree_exiting.connect(_on_waiting_room_disconnect)


func debug_tasks():
	var args = parse_arguments()
	if "host" in args or "player" in args:
		var peer = ENetMultiplayerPeer.new()
		if "host" in args:
			if peer.create_server(4242, 4) == OK:
				multiplayer.multiplayer_peer = peer
				host_game()
		if "player" in args:
			var numplayer = args["player"]
			if peer.create_client("localhost", 4242) == OK:
				multiplayer.multiplayer_peer = peer
				on_connected("localhost")
				match numplayer:
					"1": get_window().position = Vector2i(513, 110)
					"2": get_window().position = Vector2i(0, 240)
					"3": get_window().position = Vector2i(513, 240)
		#await multiplayer.peer_connected
		#if multiplayer.is_server():
			#$"waiting room"._on_start_pressed()


func init_player_data():
	player_data[multiplayer.get_unique_id()] = {
		"name": Configurations.player_name
	}


func host_game():
	var peer = ENetMultiplayerPeer.new()
	var port = Configurations.default_port
	var errcod = peer.create_server(port, max_players)
	if errcod == OK:
		multiplayer.multiplayer_peer = peer
	else:
		error_popup("Error al crear servidor: " + str(errcod))
	init_player_data()
	change_scene(waiting_room)

func on_connected(address: String):
	waiting_room.server_address = address
	# no se cambia la escena, porque eso se lo dejamos a la señal
	# connected_to_server


func load_game():
	var game = game_scene.instantiate()
	game.player_data = player_data
	get_tree().change_scene_to_node(game)


@rpc("any_peer", "call_local")
func _register_player(nombre: String):
	var id = multiplayer.get_remote_sender_id()
	if id not in player_data:
		print(Configurations.player_name, ": Peer conectado: ", id, " -> ", nombre)
		player_data[id] = {"name": nombre}
		player_data_updated.emit(id, player_data[id])


func change_scene(scene: Node):
	if _active_scene != null:
		%menu_container.remove_child(_active_scene)
	if scene != null:
		%menu_container.add_child(scene)
		if scene.has_method("initialize"):
			scene.initialize()
	_active_scene = scene


func _on_connected_to_server():
	print("on connected to server")
	init_player_data()
	change_scene(waiting_room)
	_register_player.rpc(Configurations.player_name)


func _on_peer_connected(id: int):
	_register_player.rpc_id(id, Configurations.player_name)


func _on_peer_disconnected(id: int):
	player_data.erase(id)


func _on_server_disconnected():
	error_popup("El servidor se ha desconectado", "Desconexion")
	player_data.clear()
	change_scene(null)


func _on_waiting_room_disconnect():
	player_data.clear()
	#change_scene(null)


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
