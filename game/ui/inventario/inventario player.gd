class_name InventarioPlayer extends Inventario


@export var player: Player

@onready var player_id = player.player_id:
	set(id):
		player_id = id
		owner_id = player_id

func validar_sesion(peer_id) -> bool:
	## Solamente el player puede acceder a su inventario
	return peer_id == player_id


#@onready var local_player = player.local_player

# Quizas la fuente de verdad tenga que ser el mismo inventario... porque player no usa un cojon su dinero. Pero lo usa Game. Quizas player pueda tener una propiedad shortcut como esta. Porque cuando player esta ready, ya este nodo cargó
var dinero_prop := Observable.new(3000.0, 
func(new_value, _old_value):
	if multiplayer.is_server() and player_id != 1:
		set_dinero.rpc_id(player_id, new_value)
)
var dinero: float:
	get(): return dinero_prop.value
	set(value): dinero_prop.value = value
## Modifica el dinero en el servidor y en el cliente especificado, si este no es el servidor mismo. No debe llamarse por rpc, porque el internamente lo hace y se corre el riesgo de desincronizacion si se llama primero en un cliente
@rpc("authority")
func set_dinero(cantidad: float):
	dinero = cantidad

signal not_enough_money

@rpc("authority", "call_local")
func call_not_enough_money():
	not_enough_money.emit()

# Estos son los rangos de id's de los slot roles, a partir de donde empiezan los id's de cada rol
const MAIN_WEAPON = 0 ## Arma principal del player
#_PRIVATE_ROLE_MARK, ## esto solo es para marcar a partir de dónde empiezan los roles privados y no debe ser utilizado como rol de ningun slot o item en ningun caso
const SECONDARY_WEAPON = 1 ## Arma secundaria del player
const EXTRA_WEAPON = 2 ## Arma extra del player
const MAIN_AMMO = 3 ## Municion del arma principal del player
const ACCESORY = 4 ## Accesorios
const CARRY_SECURE = 10 ## Inventario que no se pierde al morir, pequeño
const CARRY_INSECURE = 16 ## Inventario que se dropea al morir, más grande
const MAX_SLOTS = 28 ## Esto solo es para marcar el final de la lista de slots y no debe usarse como rol de ningun item o slot

var slot_roles: Dictionary = {
	MAIN_WEAPON: {
		"tipo": preload("res://game/weapon/weapon/weapon item.gd"),
		"visibilidad": Slot.Visibility.PUBLIC_SLOT,
		"func_observadora": set_weapon_item,
	},
	SECONDARY_WEAPON: {
		"tipo": preload("res://game/weapon/weapon/weapon item.gd"),
		"visibilidad": Slot.Visibility.PUBLIC_SLOT
	}, 
	EXTRA_WEAPON: {
		"tipo": preload("res://game/weapon/weapon/weapon item.gd"),
		"visibilidad": Slot.Visibility.PUBLIC_SLOT
	}, 
	MAIN_AMMO: {
		"tipo": preload("res://game/bullet/bullet item.gd"),
		"visibilidad": Slot.Visibility.PUBLIC_SLOT
	},
	ACCESORY: {
		"arreglo": accesorios,
	},
	CARRY_SECURE: { "arreglo": bolsillo_seguro },
	CARRY_INSECURE: { "arreglo": mochila },
	MAX_SLOTS: null,
	"default": {
		"tipo": null,
		"visibilidad": Slot.Visibility.PRIVATE_SLOT,
		"arreglo": null,
		"func_observadora": null
	},
}

var accesorios: Array[Slot]
var bolsillo_seguro: Array[Slot]
var mochila: Array[Slot]

func _ready() -> void:
	var new_slot
	var key_roles = slot_roles.keys()
	key_roles.pop_back()
	var key_roles_index = 0
	for role in slot_roles:
		if str(role) != "default" and role != MAX_SLOTS:
			var next_role = key_roles[key_roles_index + 1]
			for i in range(next_role - role):
				new_slot = Slot.new()
				new_slot.slot_id = role + i
				_slots[new_slot.slot_id] = new_slot
				new_slot.visibility = slot_roles[role].visibilidad \
					if slot_roles[role].has("visibilidad") \
					else slot_roles["default"].visibilidad
				new_slot.tipo = slot_roles[role].tipo \
					if slot_roles[role].has("tipo") \
					else slot_roles["default"].tipo
				if slot_roles[role].has("arreglo"):
					slot_roles[role].arreglo.append(new_slot)
				if slot_roles[role].has("func_observadora"):
					_slots[new_slot.slot_id].item_prop.conectar(
						slot_roles[role].func_observadora)
			key_roles_index += 1


# Actualizar las balas cuando se setee el slot de balas
func set_weapon_item(new_item: Item, old_item):
	if new_item:
		if new_item.object and new_item is WeaponItem:
			if new_item is FireWeaponItem:
				var ammo_slot = _slots[MAIN_AMMO]
				new_item.object.ammo_slot = ammo_slot
				#ammo_slot.tipo = new_item.clase_municion_path
				#if ammo_slot.item and \
				#not ammo_slot.validar_item(ammo_slot.item):
					#new_item.object.wrong_ammo.emit()
			player.weapon = new_item.object
		else:
			printerr("El item pasado como weapon_item no contiene una Weapon: ", new_item.object)
	else:
		player.weapon = null
	if old_item and old_item.object is FireWeapon:
		old_item.object.slot_municion = null

## Añade un item al inventario del player, colocandolo en la primera posicion vacia de la mochila
func append_item(item: Item) -> bool:
	if multiplayer.is_server():
		for slot in bolsillo_seguro:
			if not slot.item:
				server_add_item(item.to_dto(), slot.slot_id)
				return true
		for slot in mochila:
			if not slot.item:
				server_add_item(item.to_dto(), slot.slot_id)
				return true
	return false


@rpc("any_peer", "call_local")
func drop_item(slot_id, cantidad: int = -1):
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == player_id:
		if has_slot(slot_id):
			var item = get_slot(slot_id).item
			if item:
				if cantidad == -1: ## dropear todo el item
					cantidad = item.cantidad
				if cantidad > 0:
					if item.cantidad >= cantidad:
						server_take_item(slot_id, cantidad)
						var item_dto = item.to_dto()
						item_dto.cantidad = cantidad
						ItemManager.add_world_item.rpc(item_dto, player.get_path(), player.position, false)
					else: printerr("No hay suficientes items en slot: ", slot_id)
				else: printerr("drop_item: la cantidad debe ser mayor que 0")
			else: printerr("El slot ", slot_id, " esta vacio")
		else: printerr("drop_item: Slot invalido: ", slot_id)
	else: printerr("drop_item solo puede ser llamada al servidor y por el peer que controla el inventario")
