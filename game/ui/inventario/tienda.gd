@tool
class_name Tienda extends Inventario

## Creo que el frontend y el backend de la tienda pueden ir aqui.


func _ready() -> void:
	# ta raro que los slots de la tienda (al menos los que estan puestos ahi) empiecen en el 5
	var uislots = get_tree().get_nodes_in_group("shop_slots")
	var slot_id = 0
	for uislot in uislots:
		var slot = Slot.new()
		slot.slot_id = slot_id
		slot.visibility = Slot.PUBLIC_SLOT
		uislot.slot = slot
		uislot.inventario = self
		_slots[slot_id] = slot
		slot_id += 1


func get_front() -> Node:
	return self

# el precio debe multiplicarse por la cantidad?

#@rpc("any_peer", "call_local")
func request_compra(item_path: String, transaction_inventory: InventarioPlayer, cantidad: int) -> Dictionary:
	if multiplayer.is_server():
		if ItemManager.item_type_exists(item_path):
			var type = ItemManager.get_item_type(item_path)
			if transaction_inventory.dinero.value >= type.precio:
				# sellar el item con su id unico
				var dto = ItemManager.new_item_dto(item_path)
				dto.cantidad = cantidad
				transaction_inventory.modificar_dinero(-type.precio)
				return dto
			else:
				transaction_inventory.call_not_enough_money.rpc_id(
					transaction_inventory.player_id) # de pinga
		else:
			printerr("El item '", item_path, "' no existe")
	return {}


#@rpc("any_peer", "call_local")
func request_venta(transaction_inventory: InventarioPlayer, slot_id: int, cantidad: int):
	if multiplayer.is_server():
		var selling := transaction_inventory.get_slot(slot_id).item
		if selling:
			transaction_inventory.modificar_dinero(+selling.precio)
			transaction_inventory.server_take_item(slot_id, cantidad)
		else:
			printerr("el jugador no tiene un item en el slot: ", slot_id, " o el id de slot es invalido")


## Esto se llama en el inventario que recibe el item intercambiado
## Por tanto, aqui va la operacion de venta
@rpc("any_peer", "call_local")
func intercambio(inv_origen_path: NodePath, src_slot_id: int, cantidad: int, _dest_slot_id: int):
	# and validar_sesion(multiplayer.get_remote_sender_id())
	if multiplayer.is_server():
		var inventario_origen = get_node(inv_origen_path)
		if inventario_origen is InventarioPlayer:
			request_venta(inventario_origen, src_slot_id, cantidad)
			#var item_recibido = inventario_origen.enviar_item(
				#self, item_dto, dest_slot)
		else:
			printerr("Ruta al inventario invalida: ", inv_origen_path, " o el nodo no es InventarioPlayer")


## Compra, basicamente
func enviar_item(inventario: Inventario, src_slot: int, cantidad: int) -> Dictionary:
	if multiplayer.is_server() and inventario is InventarioPlayer:
		if has_slot(src_slot):
			var item_pedido = get_slot(src_slot).item
			return request_compra(item_pedido.item_type_path, inventario, cantidad)
		else:
			printerr("Slot invalido: ", src_slot)
	else: printerr("enviar_item solo puede llamarse en el servidor y con un InventarioPlayer")
	return {}


# Nadie añade ni toma items de la tienda modificando sus slots
func server_add_item(_item_dto: Dictionary, _slot_id):
	printerr("add_item_server no se usa en Tienda")
func server_take_item(_slot_id: int, _cantidad: int):
	printerr("take_item_server no se usa en Tienda")
func mover_item_local(_from_slot_id: int, _to_slot_id: int, _cantidad: int):
	printerr("mover_item_local no se usa en Tienda")


# Seria interesante poner este script en un nodo que tome las pulsaciones del mouse (como el Panel Container) y asi poder recibir directamente los dropeos sin tener que meterle un script a shop_tabs
