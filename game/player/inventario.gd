class_name Inventario extends Node


@export var player: Player

@onready var player_id = player.player_id
@onready var local_player = player.local_player

@onready var dinero : Observable = player.dinero

var items: Array[Item]

# Algunos items del inventario deben representar slots "publicos", esto es, visibles y relevantes para todos los peers, y por tanto deben ser sincronizados aunque los demas items permanezcan locales y ocultos.

enum SlotRole {
	MAIN_WEAPON,
	SECONDARY_WEAPON,
	MAIN_BULLET,
	MAIN_GRENADE,
	CARRY
}

@export var public_items: Dictionary[SlotRole, SlotInventario]
# Dictionary[String, Dictionary]

#var weapon_item := Observable.new(null,
#func(new_item): # former name: new_weapon
	#if new_item and new_item.object:
		#if new_item.object is Weapon:
			#if player.weapon != null:
				#player.weapon.queue_free()
			#player.weapon = new_item.object
		#else:
			#printerr("El item pasado como weapon_item no contiene una Weapon")
	#else:
		#player.weapon = null
#)

@onready var weapon_item = public_items[SlotRole.MAIN_WEAPON].item

func set_weapon_item(new_item: Item):
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

# Las operaciones que afectan el inventario deben ser iniciadas por
# el servidor. El servidor y el cliente afectado deben realizar las
# mismas operaciones y tener siempre los mismos items

# add_item puede hacer algo distinto que add_weapon si solamente añade el item al inventario, sin setear el arma.
# Podrian tenerse mas armas que la activa


# Los items del inventario deben estar registrados en el servidor y en el peer al cual pertenecen (y en mas ningun lugar, para evitar espionaje). Por tanto, cuando un peer va a tomar un item por cualquier razon, debe mandarle una notificacion al servidor con el item_dto, el servidor debe validarla y añadir el item en el player de su propia instancia y en el peer que lo llamó, usando esta función.
# Como el dto que se recibió es el mismo que se envía (solo es validar) se podria buscar alguna optimización, pero eso ya es más palante
func server_add_item(item_dto: Dictionary, slot: SlotRole):
	# esto es para evitar condiciones de carrera si un cliente intenta setear slots publicos
	if multiplayer.is_server():
		add_item(item_dto, slot) # primero al servidor
		if player_id != 1: # luego en el cliente, si no es el servidor
			add_item.rpc_id(player_id, item_dto, slot) # aqui se llaman los request_set_public*

func server_take_item(item_id: int):
	if multiplayer.is_server():
		take_item(item_id)
		if player_id != 1:
			take_item.rpc_id(player_id, item_id)


## Tener presente que, si el cliente aqui hace algo que no sea añadir el item al inventario, en la posterior llamada a request_set_public_slot va a chocar conque no tiene el item puesto

@rpc("authority", "call_local")
func add_item(item_dto: Dictionary, role: SlotRole):
	var item = Item.new_from_dto(item_dto)
	items.append(item)
	# para que la weapon solo se setee una vez, y no dos veces (cliente y servidor) hacemos que solo el cliente emita la llamada para validar. Esto es porque debe estar separada la funcion de añadir item de la de llenar los slots; y por lo general, como esta funcion se llama por rpc, el cliente ejecuta esta tarea de ultimo. Con esto nos aseguramos de que el item a setear exista tambien en el servidor 
	if local_player and role != SlotRole.CARRY:
	#if local_player and item.object is Weapon:
		 #weapon se setea para todo el mundo, pero el servidor debe validar
		#request_set_weapon.rpc_id(1, item_dto.id)
		request_set_public_slot.rpc_id(1, item_dto.id, role)


@rpc("any_peer", "call_local")
func take_item(id: int):
	var i = 0
	for item in items:
		if item.id == id:
			items.remove_at(i)
			break
		i += 1
	# si esta equipado, desequiparlo
	if local_player:
		if weapon_item.value != null:
			if id == weapon_item.value.id:
				request_set_weapon.rpc_id(1, null)
				#weapon_item.value = null


func get_item(id: int) -> Item:
	for it in items:
		if it.id == id:
			return it
	return null

func has_item(id: int) -> bool:
	return get_item(id) != null


@rpc("any_peer", "call_local")
func request_set_public_slot(item_id, role: SlotRole):
	if multiplayer.is_server():
		#var num_slot = 0
		#for slot in public_items:
			#if slot.nombre == slot_name: break
			#num_slot += 1
		#if num_slot == public_items.size():
		if role not in public_items:
			printerr("Rol de slot ", role, " invalido")
			return
		if item_id != null:
			var item = get_item(item_id)
			if item != null:
				if item.object.get_script():
					if item.object.get_script().get_global_name() ==  public_items[role].tipo:
						set_public_slot.rpc(item.to_dto(), role)
					else:
						printerr("peer ", multiplayer.get_remote_sender_id(), " intentando asignar en slot publico un item que no coincide con el tipo del slot")
				else:
					printerr("Objeto ", item_id, " invalido: no tiene script asociado")
			else:
				printerr("peer ", multiplayer.get_remote_sender_id(), " intentando asignar en slot publico un item que no tiene")
		else:
			set_public_slot.rpc(null, role)


@rpc("authority", "call_local")
func set_public_slot(item_dto, role):
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


## Old

@rpc("any_peer", "call_local")
func request_set_weapon(item_id):
	if multiplayer.is_server():
		if item_id != null:
			var item = get_item(item_id)
			if item != null and item.object is Weapon:
				set_weapon.rpc(item.to_dto())
			else:
				printerr(multiplayer.get_remote_sender_id(), " intentando asignar como weapon un item que no existe o no es Weapon")
		else:
			set_weapon.rpc(null)

@rpc("authority", "call_local")
func set_weapon(item_dto):
	if item_dto != null:
		# En el cliente local, seteamos el item tomado de su inventario
		# En otros clientes, como no tienen el item, lo creamos
		if not local_player:
			var item = Item.new_from_dto(item_dto)
			weapon_item.value = item
		else:
			weapon_item.value = get_item(item_dto.id)
	else:
		weapon_item.value = null
