class_name Cofre extends Node2D


@export var container_name := "Cofre"

@export var inventario: Inventario

@export var front_scene = preload("res://maps/props/cofre/cofre front.tscn")

@export var cantidad_slots: int

var interacting_player_ids: Array[int]


func _ready() -> void:
	# si por algun casual se me olvido asignarle el inventario, coge el primero de sus hijos que sea un Inventario. Si no tiene ninguno, bajanda
	if not inventario:
		for child in get_children():
			if child is Inventario:
				inventario = child
				break
		if not inventario:
			return
	inventario.owner_id = 0 # publico
	inventario.front_builder = front_builder
	inicializar_slots()


func inicializar_slots():
	var slot_ids = {}
	for slot_id in range(cantidad_slots):
		if not inventario._slots.has(slot_id):
			var slot = Slot.new()
			slot.slot_id = slot_id
			slot.visibility = Slot.PUBLIC_SLOT
			inventario._slots[slot_id] = slot
		else:
			inventario._slots[slot_id].slot_id = slot_id
			inventario._slots[slot_id].visibility = Slot.Visibility.PUBLIC_SLOT
			if multiplayer.is_server():
				inventario._slots[slot_id].inicializar_server()
				slot_ids[slot_id] = inventario._slots[slot_id].item.id
	if multiplayer.is_server():
		enviar_ids_items_inicializados.rpc(slot_ids)

# Se envia un mapa de id de slot -> id de item en ese slot. Se supone que en cada slot señalado va a haber un item
@rpc("authority", "call_remote")
func enviar_ids_items_inicializados(slot_ids: Dictionary):
	for id in slot_ids:
		inventario._slots[id].inicializar_client(slot_ids[id])


func front_builder():
	if inventario:
		var front = front_scene.instantiate()
		front.initialize(inventario, container_name)
		return front
	return null


func is_on_interact_area(player: Player) -> bool:
	return %interaction_area.overlaps_body(player)


func _on_button_pressed() -> void:
	if inventario and multiplayer.get_unique_id() not in interacting_player_ids:
		interact_with_player.rpc_id(1)
	#if await RpcAwait.send_rpc(1, interact_with_player, false):
		#pass


func get_game_instance():
	var game_instance = get_node_or_null("/root/Main/GameContainer/Game") as Game
	if game_instance == null:
		game_instance = get_node("/root/tests")
	return game_instance


@rpc("any_peer", "call_local")
func interact_with_player():
	if multiplayer.is_server():
		var game_instance = get_game_instance()
		var player_id = multiplayer.get_remote_sender_id()
		var player = game_instance.players[player_id]
		if is_on_interact_area(player):
			inventario.abrir_sesion(player_id)
			# el cliente puede no cerrar la sesion cuando termine la interaccion, asi que la cerramos nosotros en el servidor cuando salga del area
			_client_interact_with_player.rpc(player_id)
			return true
	return false

@rpc("authority", "call_local")
func _client_interact_with_player(player_id: int):
	%sprite.animation = "abierto"
	interacting_player_ids.append(player_id)
	# podemos confiar en el cliente aqui, porque la sesion con el inventario la abrimos ya en el servidor
	if multiplayer.get_unique_id() == player_id:
		var game_instance = get_game_instance()
		var ui = game_instance.get_node("UI") as HUD
		ui.overlay_inventario.close.connect(
			close_interaction.rpc_id.bind(1, player_id), CONNECT_ONE_SHOT)
		ui.overlay_inventario.interactuar(inventario)


@rpc("any_peer", "call_local")
func close_interaction(player_id: int):
	if multiplayer.is_server():
		if player_id in inventario.sesiones_abiertas:
			inventario.cerrar_sesion(player_id)
			_client_close_interaction.rpc(player_id)

@rpc("authority", "call_local")
func _client_close_interaction(player_id: int):
	interacting_player_ids.erase(player_id)
	if interacting_player_ids.is_empty():
		%sprite.animation = "cerrado"


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player and body.player_id in interacting_player_ids:
		var interacting_player_id = body.player_id
		if multiplayer.is_server():
			if interacting_player_id in inventario.sesiones_abiertas:
				inventario.cerrar_sesion(interacting_player_id)
				close_interaction(interacting_player_id)
		if interacting_player_id == multiplayer.get_unique_id():
			var game_instance = get_game_instance()
			var ui = game_instance.get_node("UI") as HUD
			ui.overlay_inventario.cerrar()
