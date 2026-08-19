extends Control

## Cuando un jugador se conecta, se llama a _on_connected_to_server,
## que llama a _register_player como rpc en todos los pares conectados.
## Estos a su vez responden a su conexion con _on_peer_connected
## y se registran con _register_player en l id del jugador recien conectado

signal exit
signal game_start

var player_data: Dictionary
var _player_items = {}
var server_address: String

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	%start.disabled = not multiplayer.is_server()
	
	for id in player_data:
		on_player_data_updated(id, player_data[id])
	
	if multiplayer.is_server():
		var idx = 0
		for ip in IP.get_local_addresses():
			if ":" not in ip: # solo ipv4
				%ip_list.add_item(ip, idx)
				if ip.begins_with("192.168"):
					%ip_list.select(idx)
			idx += 1
		#if %ip_list.get_selected_id() == -1 and %ip_list.item_count > 0:
			#%ip_list.select(0)
	else:
		%ip_list.hide()
		%ip.text = server_address
		%ip.show()


func on_player_data_updated(id: int, data):
	_player_items[id] = {
		"name": data.name,
		"idx": %player_list.add_item(data.name)
	}


func _on_peer_disconnected(id: int):
	%player_list.remove_item(_player_items[id]["idx"])


func _on_exit_pressed() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	exit.emit()


func _on_start_pressed() -> void:
	if multiplayer.is_server():
		game_start.emit()
