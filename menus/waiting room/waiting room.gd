extends Control

## Cuando un jugador se conecta, se llama a _on_connected_to_server,
## que llama a _register_player como rpc en todos los pares conectados.
## Estos a su vez responden a su conexion con _on_peer_connected
## y se registran con _register_player en l id del jugador recien conectado

signal game_start

var player_data: Dictionary
## Esto se va a ocupar exclusivamente de la informacion de los players mostrada en %player_list. De la informacion relevante para el juego se ocupa player_data, que por eso se comparte con el menu principal
var _player_items = {}

var server_address: String

var local_id: int

@onready var sprite_variants: PackedStringArray = %sprite.sprite_frames.get_animation_names()

var selected_sprite_index = 0

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


## Para código que debe ejecutarse cada vez que esta se vuelva la escena actual. _ready() solo se ejecuta una vez
func initialize():
	local_id = multiplayer.get_unique_id()
	%start.disabled = not multiplayer.is_server()
	%player_list.clear()
	selected_sprite_index = 0
	%sprite.animation = sprite_variants[selected_sprite_index]
	%sprite.play()
	for id in player_data:
		on_player_data_updated(id, player_data[id])
	if multiplayer.is_server():
		%ip_list.clear()
		var idx = 0
		for ip in IP.get_local_addresses():
			if ":" not in ip: # solo ipv4
				%ip_list.add_item(ip, idx)
				if ip.begins_with("192.168"):
					%ip_list.select(idx)
			idx += 1
		%ip_list.show()
		%ip.hide()
	else:
		%ip_list.hide()
		%ip.text = server_address
		%ip.show()


func on_player_data_updated(id: int, data):
	_player_items[id] = {
		"name": data.name,
		"idx": %player_list.add_item(data.name),
	}
	# data ya debe venir con su campo character_variant
	#player_data[id]["character_variant"] = -1
	%start.disabled = true
	_update_sprite_index(selected_sprite_index) ## temporal


func _on_previous_sprite_pressed() -> void:
	_update_sprite_index(selected_sprite_index - 1)

func _on_next_sprite_pressed() -> void:
	_update_sprite_index(selected_sprite_index + 1)

func _update_sprite_index(new_index):
	selected_sprite_index = new_index % sprite_variants.size()
	%sprite.animation = sprite_variants[selected_sprite_index]
	_update_select_sprite_button(
		_get_sprite_variant_owner(selected_sprite_index))

func _update_select_sprite_button(owner_id: int):
	%select_sprite.disabled = owner_id != -1 and owner_id != multiplayer.get_unique_id()
	%owner_name.visible = owner_id != -1
	if %owner_name.visible:
		%owner_name.text = player_data[owner_id].name
	%select_sprite.text = "Seleccionar" if \
		player_data[local_id].character_variant != selected_sprite_index \
		else "Deseleccionar"

func _get_sprite_variant_owner(index: int) -> int:
	for player_id in player_data:
		if player_data[player_id].character_variant == index:
			return player_id
	return -1

func _on_select_sprite_pressed() -> void:
	var index = selected_sprite_index if \
		player_data[local_id].character_variant != selected_sprite_index \
		else -1
	_select_sprite_variant.rpc_id(1, index)

@rpc("any_peer", "call_local")
func _select_sprite_variant(index: int):
	if multiplayer.is_server():
		var player_id = multiplayer.get_remote_sender_id()
		if index != -1: # tomar un indice de sprite
			if _get_sprite_variant_owner(index) == -1:
				_select_sprite_variant_client.rpc(player_id, index)
			else:
				printerr("peer ", multiplayer.get_remote_sender_id(), " intentando tomar un sprite que ya esta tomado")
		else: # soltar un indice de sprite
			_select_sprite_variant_client.rpc(player_id, -1)

@rpc("authority", "call_local")
func _select_sprite_variant_client(player_id: int, index: int):
	var previously_selected = player_data[player_id].character_variant
	player_data[player_id].character_variant = index
	# si index es -1, nunca va a ser igual a selected_sprite_index
	# sin embargo, en ese caso, la posicion en previously selected fue liberada y hay que actualizar el boton
	if index == selected_sprite_index or previously_selected == selected_sprite_index:
		_update_select_sprite_button(player_id)
	if multiplayer.is_server():
		%start.disabled = not _everyone_ready()


func _everyone_ready():
	for player_id in player_data:
		if player_data[player_id].character_variant == -1:
			return false
	return true


func _on_peer_disconnected(id: int):
	%player_list.remove_item(_player_items[id]["idx"])


@rpc("call_local")
func call_game_start():
	game_start.emit()


func _on_start_pressed() -> void:
	if multiplayer.is_server() and _everyone_ready():
		call_game_start.rpc()


## Esto NO se llama cuando se inicia el juego, sino cuando esta escena en el menu es depuesta por otra
func deinitialize():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	player_data.clear()


func _on_tree_exiting() -> void:
	%player_list.clear()
	_player_items.clear()
