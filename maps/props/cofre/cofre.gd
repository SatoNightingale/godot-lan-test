class_name Cofre extends Node2D

# Hace falta un mecanismo general de inicializacion de inventarios
# Mayormente el inventario de los cofres es el que hay que inicializar, asi que se puede disenar pensando en este caso

# Este inventario puede estar metido dentro de la escena del cofre (en cuyo caso resultaria opaco al exterior) o puede ser una escena exterior que el cofre capturaria (@exportandola), lo que permitiria que este adquiriera un inventario ya inicializado. Y si no se le asigna un inventario, se desactiva la funcionalidad del cofre. Puede hacerse asi, aunque manualmente setear todos los inventarios a sus cofres es duro; se puede definir en cambio una propiedad que contenga solo los items con los que el inventario debe inicializarse.
# Por esta linea, tambien seria bueno añadir un modo de que los items puedan inicializar sus propiedades de instancia. El problema es que si se modifica una propiedad añadida para ese fin, entonces o se guarda en todo el item (en el recurso que supuestamente representa el tipo de item) o se guarda en una copia de este recurso que ya no seria efectiva porque no guarda la referencia a su path original. Esto se puede resolver colocando las propiedades de inicializacion de los items en el slot que los guarda. La propiedad de inicializacion del slot puede ser un diccionario de nombre de propiedad -> valor, que luego el item o el slot apliquen en la inicializacion, convirtiendo el valor al tipo de la propiedad referida. Si bien esto tambien seria un poco engorroso
@export var inventario: Inventario

@export var front_scene = preload("res://maps/props/cofre/cofre front.tscn")

@export var cantidad_slots: int

var interacting_player: Player


func _ready() -> void:
	if not inventario:
		inventario = %Inventario
	inventario.owner_id = 0 # publico
	var slots: Dictionary[int, Slot] = {}
	for slot_id in range(cantidad_slots):
		var slot = Slot.new()
		slot.slot_id = slot_id
		slot.visibility = Slot.PUBLIC_SLOT
		slots[slot_id] = slot
	inventario._slots = slots
	inventario.front_builder = front_builder


func front_builder():
	var front = front_scene.instantiate()
	front.initialize(inventario, "Cofre")
	return front


func is_on_interact_area(player: Player) -> bool:
	return %interaction_area.overlaps_body(player)


func _on_button_pressed() -> void:
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
		interacting_player = game_instance.players[player_id]
		if is_on_interact_area(interacting_player):
			inventario.abrir_sesion(multiplayer.get_unique_id())
			# el cliente puede no cerrar la sesion cuando termine la interaccion, asi que la cerramos nosotros en el servidor cuando salga del area
			# El cliente tambien deberia estar programado para cerrarla, porque ejemplo: lo matan viendo un cofre y el overlay del cofre aun seguiria activo, aunque ya no pueda interactuar con el
			%interaction_area.body_exited.connect(
				close_on_exit_interaction_area, CONNECT_ONE_SHOT)
			_client_interact_with_player.rpc(player_id)
			return true
	return false


@rpc("any_peer", "call_local")
func close_interaction():
	if multiplayer.is_server():
		var player_id = multiplayer.get_remote_sender_id()
		if player_id in inventario.sesiones_abiertas:
			inventario.cerrar_sesion(player_id)
			_client_close_interaction.rpc()


@rpc("authority", "call_local")
func _client_interact_with_player(interacting_player_id: int):
	%sprite.animation = "abierto"
	# podemos confiar en el cliente aqui, porque la sesion con el inventario la abrimos ya en el servidor
	if multiplayer.get_unique_id() == interacting_player_id:
		var game_instance = get_game_instance()
		interacting_player = game_instance.players[interacting_player_id]
		var ui = game_instance.get_node("UI") as HUD
		ui.overlay_inventario.close.connect(
			close_interaction.rpc_id.bind(1), CONNECT_ONE_SHOT)
		%interaction_area.body_exited.connect(
			close_on_exit_interaction_area, CONNECT_ONE_SHOT)
		ui.overlay_inventario.interactuar(inventario)


@rpc("authority", "call_local")
func _client_close_interaction():
	%sprite.animation = "cerrado"
	interacting_player = null


func close_on_exit_interaction_area(body: Node2D):
	if body == interacting_player:
		var interacting_player_id = interacting_player.player_id
		if multiplayer.is_server():
			if interacting_player_id in inventario.sesiones_abiertas:
				inventario.cerrar_sesion(interacting_player_id)
		if interacting_player_id == multiplayer.get_unique_id():
				var game_instance = get_game_instance()
				var ui = game_instance.get_node("UI") as HUD
				ui.overlay_inventario.cerrar()
