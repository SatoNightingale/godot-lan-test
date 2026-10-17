class_name InventarioPlayer extends Inventario

# Si los SlotRole son simplemente alias para los id de slots, entonces cada role debe estar asociado a un slot y solo a uno, para que set_slot funcione. Ademas, hay que tener bien fijado el entero asociado a cada role en la enumeracion.
# Normalmente no bastaran las constantes definidas en SlotRole para poblar todos los slots del inventario, por lo que habra que crear el diccionario de slots con mas ids que los definidos ahi. Declararlos por el inspector como diccionario exportado es muy incomodo, ademas de que, si los indices son valores de enum, probablemente haya que repetir un mismo valor varias veces.
# Todo eso indica que lo mas sensato seria llenar el diccionario de slots por codigo. 

enum SlotRole {
	MAIN_WEAPON = 0, ## Arma principal del player
	#_PRIVATE_ROLE_MARK, ## esto solo es para marcar a partir de dónde empiezan los roles privados y no debe ser utilizado como rol de ningun slot o item en ningun caso
	SECONDARY_WEAPON = 1, ## Arma secundaria del player
	EXTRA_WEAPON = 2, ## Arma extra del player
	MAIN_AMMO = 3, ## Municion del arma principal del player
	#ACCESORY, ## Accesorios
	#CARRY_SECURE, ## Inventario que no se pierde al morir, pequeño
	#CARRY_INSECURE, ## Inventario que se dropea al morir, más grande
	##_MAX_SLOTS ## Esto solo es para marcar el final de la lista de slots y no debe usarse como rol de ningun item o slot
}


@export var player: Player

@onready var player_id = player.player_id:
	set(id):
		player_id = id
		owner_id = player_id

#@onready var local_player = player.local_player

# Quizas la fuente de verdad tenga que ser el mismo inventario... porque player no usa un cojon su dinero. Pero lo usa Game. Quizas player pueda tener una propiedad shortcut como esta. Porque cuando player esta ready, ya este nodo cargó
@onready var dinero : Observable = player.dinero
## Modifica el dinero en el servidor y en el cliente especificado, si este no es el servidor mismo. No debe llamarse por rpc, porque el internamente lo hace y se corre el riesgo de desincronizacion si se llama primero en un cliente
## Cliente no deberia ser siempre player_id?
@rpc("authority")
func modificar_dinero(cantidad: float): # , cliente: int = 1
	dinero.value += cantidad
	if multiplayer.is_server() and player_id != 1: # cliente
		modificar_dinero.rpc_id(player_id, cantidad)

signal not_enough_money

@rpc("authority", "call_local")
func call_not_enough_money():
	not_enough_money.emit()


func validar_sesion(peer_id) -> bool:
	## Solamente el player puede acceder a su inventario
	return peer_id == player_id


func _ready() -> void:
	var new_slot
	for i in range(36):
		new_slot = Slot.new()
		new_slot.slot_id = i
		if i == SlotRole.MAIN_WEAPON or \
			i == SlotRole.SECONDARY_WEAPON or \
			i == SlotRole.EXTRA_WEAPON:
			new_slot.tipo = preload("res://game/weapon/weapon/weapon item.gd")
			new_slot.visibility = Slot.Visibility.PUBLIC_SLOT
		if i == SlotRole.MAIN_AMMO:
			new_slot.visibility = Slot.Visibility.PUBLIC_SLOT
			new_slot.tipo = preload("res://game/bullet/bullet item.gd")
		else:
			new_slot.visibility = Slot.Visibility.PRIVATE_SLOT
		_slots[i] = new_slot
	_conectar_slots_player()


func _conectar_slots_player():
	_slots[SlotRole.MAIN_WEAPON].item_prop.conectar(set_weapon_item)

# Actualizar las balas cuando se setee el slot de balas
func set_weapon_item(new_item: Item, old_item):
	if new_item:
		if new_item.object and new_item is WeaponItem:
			player.weapon = new_item.object
			if new_item is FireWeaponItem:
				new_item.object.slot_municion = _slots[SlotRole.MAIN_AMMO]
				_slots[SlotRole.MAIN_AMMO].tipo = \
					load(new_item.clase_municion_path)
		else:
			printerr("El item pasado como weapon_item no contiene una Weapon: ", new_item.object)
	else:
		player.weapon = null
	if old_item and old_item.object is FireWeapon:
		old_item.object.slot_municion = null
