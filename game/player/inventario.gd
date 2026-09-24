class_name Inventario extends Node


@export var player: Player

@onready var player_id = player.player_id
@onready var local_player = player.local_player

@onready var dinero : Observable = player.dinero

var items: Array[Item]

enum SlotRole {
	# publicos
	MAIN_WEAPON,
	_PRIVATE_ROLE_MARK, ## esto solo es para marcar a partir de dónde empiezan los roles privados y no debe ser utilizado como rol de ningun slot o item en ningun caso
	# privados
	SECONDARY_WEAPON,
	MAIN_BULLET,
	MAIN_GRENADE,
	CARRY_SECURE, ## Inventario que no se pierde al morir, pequeño
	CARRY_INSECURE ## Inventario que se dropea al morir, más grande
}

## Items del inventario que representan slots "publicos", esto es, visibles y relevantes para todos los peers, y que por tanto deben ser sincronizados aunque los demas items permanezcan locales y ocultos.
var public_items = {
	SlotRole.MAIN_WEAPON: {
		"tipo": preload("res://game/weapon/classes/weapon/weapon.gd"),
		"item": null
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

func _ready() -> void:
	# para cada uno de los slots (registrados como propiedades, si hay uno que queda sin registrar es un slot inaccesible)
	public_items[SlotRole.MAIN_WEAPON].item = Observable.new(null, set_weapon_item)
	# para todos los slots a la vez (excepto si hay uno sin observable_setter_name)
	#for slot in public_items:
		#var item_slot = public_items[slot]
		#item_slot.item = Observable.new(null, 
			#Callable.create(self, item_slot.observable_setter_name)
		#)


## Modifica el dinero en el servidor y en el cliente especificado, si este no es el servidor mismo. No debe llamarse por rpc, porque el internamente lo hace y se corre el riesgo de desincronizacion si se llama primero en un cliente
@rpc("authority")
func modificar_dinero(cantidad: float, cliente: int = 1):
	dinero.value += cantidad # si te modificaste esto por tus cojones y no eres el server, te desincronizaste...
	if multiplayer.is_server() and cliente != 1:
		modificar_dinero.rpc_id(cliente, cantidad)


## Los items del inventario deben estar registrados en el servidor y en el peer al cual pertenecen (y en mas ningun lugar, para evitar espionaje). Por tanto, cuando un peer va a tomar un item por cualquier razon, debe mandarle una notificacion al servidor con el item_dto, el servidor debe validarla y añadir el item en el player de su propia instancia y en el peer que lo llamó, usando esta función.
## Nota: Todos los items en el inventario deben ir en un slot especifico, de ahi que se pida el slot en todas las funciones de añadir
func server_add_item(item_dto: Dictionary, slot: SlotRole):
	# Como el dto que se recibió es el mismo que se envía (solo es validar) se podria buscar alguna optimización, pero eso ya es más palante
	# El orden es para evitar condiciones de carrera si un cliente intenta setear slots publicos
	if multiplayer.is_server():
		add_item(item_dto, slot) # primero al servidor
		if player_id != 1: # luego en el cliente, si no es el servidor
			#var ret = await RpcAwait.send_rpc(player_id, add_item.bind(item_dto))
			add_item.rpc_id(player_id, item_dto, slot)

func server_take_item(item_id: int):
	if multiplayer.is_server():
		take_item(item_id)
		if player_id != 1:
			take_item.rpc_id(player_id, item_id)


@rpc("authority", "call_local")
func add_item(item_dto: Dictionary, slot: SlotRole):
	var item = Item.new_from_dto(item_dto)
	items.append(item)
	# Si el item es añadido en un slot publico, hay que pedirle al servidor que replique este item en todos los peers.
	# Para que el item solo se setee una vez, y no dos veces (cliente y servidor) hacemos que solo el cliente emita la llamada para validar. Esto es porque debe estar separada la funcion de añadir item de la de llenar los slots; y como esta funcion se llama por rpc, el cliente la ejecuta de ultimo. Con esto nos aseguramos de que el item a setear exista tambien en el servidor 
	if local_player and slot < SlotRole._PRIVATE_ROLE_MARK:
		# el item se setea para todo el mundo, pero el servidor debe validar
		request_set_public_slot.rpc_id(1, item_dto.id, slot)


@rpc("any_peer", "call_local")
func take_item(id: int):
	var i = 0
	var item: Item
	for it in items:
		if it.id == id:
			item = it
			items.remove_at(i)
			break
		i += 1
	# si esta equipado, desequiparlo
	if local_player:
		for role in public_items:
			if public_items[role].item.value != null:
				if public_items[role].item.value.id == id:
					request_set_public_slot.rpc_id(1, null, role)
					break


@rpc("any_peer", "call_local")
func request_set_public_slot(item_id, role: SlotRole):
	if multiplayer.is_server():
		if role not in public_items:
			printerr("Rol de slot ", role, " invalido")
			return
		if item_id != null:
			var item = get_item(item_id)
			if item != null:
				if is_instance_of(item.object, public_items[role].tipo):
					_set_public_slot.rpc(item.to_dto(), role)
				else:
					printerr("peer ", multiplayer.get_remote_sender_id(), " intentando asignar en slot publico un item que no es del tipo del slot")
			else:
				printerr("peer ", multiplayer.get_remote_sender_id(), " intentando asignar en slot publico un item que no tiene")
		else:
			_set_public_slot.rpc(null, role)


@rpc("authority", "call_local")
func _set_public_slot(item_dto, role):
	if item_dto != null:
		# En el cliente local, seteamos el item tomado de su inventario
		# En otros clientes, como no tienen el item, lo creamos
		# Se asume que el item_dto mandado por el servidor siempre sera válido
		if not local_player:
			var item = Item.new_from_dto(item_dto)
			public_items[role].item.value = item
		else:
			public_items[role].item.value = get_item(item_dto.id)
	else:
		public_items[role].item.value = null


func get_item(id: int) -> Item:
	for it in items:
		if it.id == id:
			return it
	return null

func has_item(id: int) -> bool:
	return get_item(id) != null
