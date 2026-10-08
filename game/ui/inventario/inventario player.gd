class_name InventarioPlayer extends InventarioAbstract

## Este es como el inventario base, pero añadiendole tipo y visibildiad de slots

enum SlotRole {
	MAIN_WEAPON = 0, ## Arma principal del player
	_PRIVATE_ROLE_MARK, ## esto solo es para marcar a partir de dónde empiezan los roles privados y no debe ser utilizado como rol de ningun slot o item en ningun caso
	SECONDARY_WEAPON, ## Arma secundaria del player
	EXTRA_WEAPON, ## Arma extra del player
	MAIN_AMMO, ## Municion del arma principal del player
	CARRY_SECURE, ## Inventario que no se pierde al morir, pequeño
	CARRY_INSECURE, ## Inventario que se dropea al morir, más grande
	_MAX_SLOTS ## Esto solo es para marcar el final de la lista de slots y no debe usarse como rol de ningun item o slot
}

enum SlotType {
	PUBLIC_SLOT,
	PRIVATE_SLOT,
	INVALID_SLOT,
}


@export var player: Player

@onready var player_id = player.player_id
@onready var local_player = player.local_player

@onready var dinero : Observable = player.dinero
## Modifica el dinero en el servidor y en el cliente especificado, si este no es el servidor mismo. No debe llamarse por rpc, porque el internamente lo hace y se corre el riesgo de desincronizacion si se llama primero en un cliente
@rpc("authority")
func modificar_dinero(cantidad: float, cliente: int = 1):
	dinero.value += cantidad
	if multiplayer.is_server() and cliente != 1:
		modificar_dinero.rpc_id(cliente, cantidad)


func validar_sesion(peer_id) -> bool:
	## Solamente el player puede acceder a su inventario
	return peer_id == player_id


var public_items = {
	SlotRole.MAIN_WEAPON: {
		"tipo": preload("res://game/weapon/weapon/weapon item.gd"),
		"item": Observable.new(null, set_weapon_item)
	}
}

@onready var weapon_item = public_items[SlotRole.MAIN_WEAPON].item

func set_weapon_item(new_item: Item, _old_item):
	if new_item and new_item.object:
		if new_item.object is Weapon:
			if player.weapon != null:
				player.weapon.queue_free()
			player.weapon = new_item.object
		else:
			printerr("El item pasado como weapon_item no contiene una Weapon")
	else:
		player.weapon = null


func validar_slot(slot_id: SlotRole):
	if slot_id in SlotRole:
		if slot_id >= 0 and slot_id < SlotRole._PRIVATE_ROLE_MARK:
			return SlotType.PUBLIC_SLOT
		else: if slot_id > SlotRole._PRIVATE_ROLE_MARK and slot_id < SlotRole._MAX_SLOTS:
			return SlotType.PRIVATE_SLOT
	return SlotType.INVALID_SLOT


func validar_tipo_slot(slot_id: SlotRole, item: Item):
	if validar_slot(slot_id) != SlotType.INVALID_SLOT:
		if slot_id in public_items and item != null: # todo slot es nullable
			return is_instance_of(item, public_items[slot_id].tipo)
		else:
			return true
	return false


func set_slot(slot_id: int, item: Item):
	super.set_slot(slot_id, item)
	#if multiplayer.is_server():
	# aqui hay que considerar las restricciones de public_items
	if validar_tipo_slot(slot_id, item):
		#set_public_slot.rpc(item.to_dto(), slot_id)
		public_items[slot_id].item.value = item


func add_item_server(item_dto: Dictionary, slot: SlotRole):
	if multiplayer.is_server():
		var slot_type = validar_slot(slot)
		if slot_type == SlotType.INVALID_SLOT:
			printerr("Slot invalido: ", slot)
			return
		var item = Item.new_from_dto(item_dto)
		if not validar_tipo_slot(slot, item):
			printerr("El tipo del objeto pasado es invalido")
			return
		# Primero: setear en el servidor
		set_slot(slot, item)
		if slot_type == SlotType.PUBLIC_SLOT:
			# tambien hay que chequear que sea valido en public_items
			_add_item_client.rpc(item_dto, slot)
		else: if slot_type == SlotType.PRIVATE_SLOT:
			#_add_item_client(item_dto, slot) # primero al servidor
			if player_id != 1: # luego en el cliente, si no es el servidor
				_add_item_client.rpc_id(player_id, item_dto, slot)


func take_item_server(slot: int):
	if multiplayer.is_server():
		var slot_visibility = validar_slot(slot)
		if slot_visibility == SlotType.INVALID_SLOT:
			printerr("Slot invalido: ", slot)
			return
		if slot_visibility == SlotType.PUBLIC_SLOT:
			_take_item_client.rpc(slot)
		else: if slot_visibility == SlotType.PRIVATE_SLOT:
			_take_item_client(slot)
			_take_item_client.rpc_id(player_id, slot)


## Esta sobreescritura es solamente para cambiar el tipo de rpc a call_remote
@rpc("authority", "call_remote")
func _add_item_client(item_dto: Dictionary, slot: int):
	super._add_item_client(item_dto, slot)


@rpc("any_peer", "call_local")
func mover_item_local(from_slot: int, to_slot: int):
	if multiplayer.is_server() and validar_sesion(multiplayer.get_remote_sender_id()):
		var from_slot_visibility = validar_slot(from_slot)
		var to_slot_visibility = validar_slot(to_slot)
		if from_slot_visibility != SlotType.INVALID_SLOT \
		and to_slot_visibility != SlotType.INVALID_SLOT:
			# Validar los tipos de items
			var source_item = _slots[from_slot]
			var dest_item = _slots[to_slot]
			if not (validar_tipo_slot(to_slot, source_item) and validar_tipo_slot(from_slot, dest_item)):
				printerr("Tipo de item incompatible con el slot")
				return
			# Mover dependiendo de la visibilidad
			if from_slot_visibility == SlotType.PUBLIC_SLOT or to_slot_visibility == SlotType.PUBLIC_SLOT:
				# desde o hacia un slot publico. Setearlo en todos los peers
				mover_item_client.rpc(from_slot, to_slot)
			else:
				# de slot privado a slot privado, solo setearlo local y en el servidor
				mover_item_client.rpc_id(1, from_slot, to_slot)
				mover_item_client.rpc_id(player_id, from_slot, to_slot)


#@rpc("authority")
#func set_public_slot(item_dto: Dictionary):
	#pass
