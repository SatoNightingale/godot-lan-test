class_name Inventario extends Node


@export var player: Player

@onready var player_id = player.player_id
@onready var local_player = player.local_player

@onready var dinero : Observable = player.dinero

var items: Array[Item]

@export var public_items: Dictionary[int, StringName]

# Algunos items del inventario deben representar slots "publicos",
# esto es, visibles y relevantes para todos los peers, y por tanto
# deben ser sincronizados aunque los demas items permanezcan locales
# y ocultos.
var weapon_item := Observable.new(null,
func(new_item): # former name: new_weapon
	if new_item and new_item.object:
		if new_item.object is Weapon:
			if player.weapon != null:
				player.weapon.queue_free()
			player.weapon = new_item.object
		else:
			printerr("El item pasado como weapon_item no contiene una Weapon")
	else:
		player.weapon = null
)

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
# Como el dto que se envió es el mismo que se recibe (solo es validar) se podria buscar alguna optimización, pero eso ya es más palante
func server_add_item(item_dto: Dictionary):
	# esto es para evitar condiciones de carrera si un cliente intenta setear slots publicos
	if multiplayer.is_server():
		add_item(item_dto) # primero al servidor
		if player_id != 1: # luego en el cliente, si no es el servidor
			add_item.rpc_id(player_id, item_dto) # aqui se llaman los request_set_public*

func server_take_item(item_id: int):
	if multiplayer.is_server():
		take_item(item_id)
		if player_id != 1:
			take_item.rpc_id(player_id, item_id)


@rpc("authority", "call_local")
func add_item(item_dto: Dictionary):
	var item = Item.new_from_dto(item_dto)
	items.append(item)
	# para que la weapon solo se setee una vez, y no dos veces (cliente y servidor) hacemos que solo el cliente emita la llamada para validar
	# TODO: Si el servidor es quien valida en su misma ejecucion (de modo que todo ocurre localmente en el) 
	if local_player and item.object is Weapon:
		# weapon se setea para todo el mundo, pero el servidor debe validar
		request_set_weapon.rpc_id(1, item_dto.id)


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
