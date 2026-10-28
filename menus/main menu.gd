extends Control

signal player_data_updated(id: int, new_data)
signal error_popup(message: String, title: String)

var main: Main

var connect_menu = preload("res://menus/connect menu/connect menu.tscn").instantiate()
var waiting_room = preload("res://menus/waiting room/waiting_room.tscn").instantiate()
var settings = preload("res://menus/settings/settings.tscn").instantiate()

var _active_scene: Node

var player_data: Dictionary


func _ready() -> void:
	# leer configuraciones
	Configurations.read_config()
	# botones
	%boton_crear.pressed.connect(Network.host)
	%boton_conectar.pressed.connect(change_scene.bind(connect_menu))
	%boton_config.pressed.connect(change_scene.bind(settings))
	# conectar señales multiplayer
	Network.server_created.connect(on_hosted)
	Network.client_created.connect(on_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(error_popup.emit.bind("Error al conectar al servidor.\nRevise la direccion IP", "Error de conexion"))
	# inicializar escenas
	init_scenes()
	# version
	%version_label.text = ProjectSettings.get_setting("application/config/version")
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
	#if OS.has_feature("editor"):
		#debug_tasks()


func init_scenes():
	# connect_menu
	connect_menu.request_conectar.connect(Network.join)
	connect_menu.error.connect(error_popup.emit.bind("Error"))
	# waiting_room
	waiting_room.player_data = player_data
	player_data_updated.connect(waiting_room.on_player_data_updated)
	waiting_room.game_start.connect(func():
		if multiplayer.is_server():
			main.change_to_game(player_data.duplicate())
	)


func debug_tasks():
	var args = main.program_args
	if "host" in args or "player" in args:
		#var peer = ENetMultiplayerPeer.new()
		if "host" in args:
			Configurations.player_name = "Server"
			Network.host()
		if "player" in args:
			var numplayer = args["player"]
			Configurations.player_name = "Player " + str(numplayer)
			Network.join("localhost", 4242)
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


func on_hosted():
	init_player_data()
	change_scene(waiting_room)

func on_connected(address: String):
	waiting_room.server_address = address
	# no se cambia la escena, porque eso se lo dejamos a la señal connected_to_server


@rpc("any_peer", "call_local")
func _register_player(data: Dictionary):
	var id = multiplayer.get_remote_sender_id()
	if id not in player_data:
		player_data[id] = data
		print(Configurations.player_name, "> Peer conectado: ", id, " -> ", data.name)
		player_data_updated.emit(id, data)


func change_scene(scene: Node):
	if scene == _active_scene:
		return
	if _active_scene != null:
		if _active_scene.has_method("deinitialize"):
			_active_scene.call("deinitialize")
		%menu_container.remove_child(_active_scene)
	if scene != null:
		%menu_container.add_child(scene)
		if scene.has_method("initialize"):
			scene.call("initialize")
	_active_scene = scene


func _on_connected_to_server():
	init_player_data()
	change_scene(waiting_room)
	_register_player.rpc(player_data[multiplayer.get_unique_id()])


func _on_peer_connected(id: int):
	_register_player.rpc_id(id, player_data[multiplayer.get_unique_id()])


func _on_peer_disconnected(id: int):
	player_data.erase(id)


func _on_server_disconnected():
	error_popup.emit("El servidor se ha desconectado", "Desconexion")
	player_data.clear()
	change_scene(null)


## Para evitar leaks, porque cuando se le hace queue_free() a esta escena no se eliminan automaticamente estas cositas
func _exit_tree() -> void:
	connect_menu.queue_free()
	waiting_room.queue_free()
	settings.queue_free()
