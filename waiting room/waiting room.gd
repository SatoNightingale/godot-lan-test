extends Control

## Cuando un jugador se conecta, se llama a _on_connected_to_server,
## que llama a _register_player como rpc en todos los pares conectados.
## Estos a su vez responden a su conexion con _on_peer_connected
## y llaman a _register_player al id del jugador recien conectado

@onready var _my_name: String = get_parent().player_name
var _player_items = {}

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if multiplayer.is_server():
		_player_items[1] = {
			"name": _my_name,
			"idx": %player_list.add_item(_my_name)
		}
	else:
		%start.disabled = true
	
	##var local_ips = IP.get_local_addresses()
	#var local_interfaces = IP.get_local_interfaces()
	##print("addresses:")
	##for ip in local_ips:
		##print(ip)
	#print("interfaces")
	#for interf in local_interfaces:
		#if interf["addresses"][0].begins_with("192.168"):
			#%ip.text = interf["addresses"][0]
		##print(interf["name"], " -> ", interf["friendly"], " -> ", interf["addresses"])


func _on_connected_to_server():
	print("on connected to server")
	_register_player.rpc(_my_name)


func _on_peer_connected(id: int):
	_register_player.rpc_id(id, _my_name)


func _on_peer_disconnected(id: int):
	%player_list.remove_item(_player_items[id]["idx"])
	_player_items.erase(id)


@rpc("any_peer", "call_local")
func _register_player(nombre: String):
	var id = multiplayer.get_remote_sender_id()
	if id not in _player_items:
		var idx = %player_list.add_item(nombre)
		print(_my_name, ": Peer conectado: ", id, " -> ", nombre)
		_player_items[id] = {
			"name": nombre,
			"idx": idx
		}


func _on_server_disconnected():
	get_parent().error_popup("El servidor se ha desconectado", "Desconexion")
	get_parent().change_scene("res://connect menu/connect menu.tscn")


@rpc("authority", "call_local")
func prepare_game(player_data):
	get_parent().player_data = player_data
	get_parent().load_game()


func _on_exit_pressed() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_parent().change_scene("res://connect menu/connect menu.tscn")


func _on_start_pressed() -> void:
	if not multiplayer.is_server(): return
	var player_data = {}
	for id in _player_items:
		player_data[id] = {"name": _player_items[id]["name"]}
		#player_data[id] = _player_items[id]["name"]
	prepare_game.rpc(player_data)
