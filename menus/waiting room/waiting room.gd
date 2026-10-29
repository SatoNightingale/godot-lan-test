extends Control

## Cuando un jugador se conecta, se llama a _on_connected_to_server, que a su vez llama a _register_player como rpc pasandole su nombre para inicializarlo en todos los peers (el incluido).
## Mientras tanto (puede ser antes o despues) el servidor, respondiendo a peer_connected, le manda player_data al peer recien conectado, con los datos de todos los peers. Si el peer se registro primero en el servidor le llega un player_data con sus propios datos, lo cual no importa demasiado
## De este modo, todos los peers reciben los datos del peer entrante y el peer entrante recibe de una vez los datos de todos los peers. Queda el mismo player_data sincronizado
## El unico problema que veo por ahora, antes de probar nada, es que connected_to_server puede no emitirse en esta escena, porque se emite antes de estar conectada a nuestra funcion. En este caso habria que correr el contenido de la funcion (que es simplemente llamar a _register_player) para initialize

signal game_start

var player_data: Dictionary
## Esto se va a ocupar exclusivamente de la informacion de los players mostrada en %player_list. De la informacion relevante para el juego se ocupa player_data, que por eso se comparte con el menu principal
var _player_items = {}

var server_address: String

var local_id: int

@onready var sprite_variants: PackedStringArray = %sprite.sprite_frames.get_animation_names()

var selected_sprite_index = 0

@export var _ready_icon: Texture2D = preload("res://menus/waiting room/ic_action_accept.png")

func _ready() -> void:
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


## Para código que debe ejecutarse cada vez que esta se vuelva la escena actual. _ready() solo se ejecuta una vez
func initialize():
	local_id = multiplayer.get_unique_id()
	%start.disabled = true
	%player_list.clear()
	selected_sprite_index = 0
	%sprite.animation = sprite_variants[selected_sprite_index]
	%sprite.play()
	_register_player.rpc(Configurations.player_name)
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


func _on_peer_connected(id: int):
	if multiplayer.is_server():
		_get_player_data.rpc_id(id, player_data)
		%start.disabled = true


func _on_peer_disconnected(id: int):
	player_data.erase(id)
	%player_list.remove_item(_player_items[id]["idx"])
	_player_items.erase(id)
	%start.disabled = not _everyone_ready()


@rpc("authority", "call_remote")
func _get_player_data(data: Dictionary):
	for id in data:
		player_data[id] = data[id]
		_player_items[id] = {
			"name": data[id].name,
			"idx": %player_list.add_item(data[id].name),
		}
		_select_sprite_variant_client(id, player_data[id].character_variant)

# Se supone que el player que se registra es un nuevo peer recien conectado; por tanto, los datos que este nuevo peer envia son minimos, exclusivamente los que dependen de el
@rpc("any_peer", "call_local")
func _register_player(nombre: String):
	var id = multiplayer.get_remote_sender_id()
	if id not in player_data:
		player_data[id] = {
			"name": nombre,
			"character_variant": -1
		}
		print(Configurations.player_name, "> Peer conectado: ", id, " -> ", nombre)
		_player_items[id] = {
			"name": nombre,
			"idx": %player_list.add_item(nombre),
		}


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
		player_data[local_id].character_variant != selected_sprite_index else "Deseleccionar"


func _get_sprite_variant_owner(index: int) -> int:
	for player_id in player_data:
		if player_data[player_id].character_variant == index:
			return player_id
	return -1


func _on_select_sprite_pressed() -> void:
	var index = selected_sprite_index if \
		player_data[local_id].character_variant != selected_sprite_index else -1
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
	%player_list.set_item_icon(_player_items[player_id].idx,
		_ready_icon if index != -1 else null)
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


func _on_start_pressed() -> void:
	if multiplayer.is_server() and _everyone_ready():
		call_game_start.rpc()


@rpc("call_local")
func call_game_start():
	game_start.emit()


## Esto NO se llama cuando se inicia el juego, sino cuando esta escena en el menu es depuesta por otra
func deinitialize():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	player_data.clear()


func _on_tree_exiting() -> void:
	%player_list.clear()
	_player_items.clear()
