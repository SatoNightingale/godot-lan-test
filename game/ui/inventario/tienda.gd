@tool
class_name Tienda extends Inventario


var shop_slots: Dictionary[int, ShopSlot]

func _ready() -> void:
	var uislots = get_tree().get_nodes_in_group("shop_slots")
	var slot_id = 0
	for uislot in uislots:
		var slot = Slot.new()
		slot.slot_id = slot_id
		slot.visibility = Slot.PUBLIC_SLOT
		uislot.slot = slot
		uislot.inventario = self
		_slots[slot_id] = slot
		shop_slots[slot_id] = uislot
		slot_id += 1


func get_front() -> Node:
	return self


# el precio de venta no se debe tomar de los items, sino de los propios slots de la tienda. Porque el precio de venta del tipo de item, vamos a establecerlo asi, es de la unidad de ese item, no de un stack con un numero arbitrario de elementos. Asi se puede comprar el item al precio de la tienda y venderlo al precio del tipo multiplicado por la cantidad (TODO)


func request_compra(slot: ShopSlot, transaction_inventory: InventarioPlayer) -> Dictionary:
	if multiplayer.is_server():
		if transaction_inventory.dinero >= slot.shop_precio:
			# sellar el item con su id unico
			var item_dto = ItemManager.new_item_dto(slot.item.item_type_path)
			item_dto.cantidad = slot.shop_cantidad
			transaction_inventory.dinero -= slot.shop_precio
			return item_dto
		else:
			transaction_inventory.call_not_enough_money.rpc_id(
				transaction_inventory.player_id) # de pinga
	return {}


#@rpc("any_peer", "call_local")
func request_venta(transaction_inventory: InventarioPlayer, slot_id: int, cantidad: int):
	if multiplayer.is_server():
		var selling := transaction_inventory.get_slot(slot_id).item
		if selling:
			transaction_inventory.dinero += selling.precio# * selling.cantidad
			transaction_inventory.server_take_item(slot_id, cantidad)
		else:
			printerr("el jugador no tiene un item en el slot: ", slot_id, " o el id de slot es invalido")


## Esto se llama en el inventario que recibe el item intercambiado
## Por tanto, aqui va la operacion de venta
@rpc("any_peer", "call_local")
func intercambio(inv_origen_path: NodePath, src_slot_id: int, cantidad: int, _dest_slot_id: int):
	if multiplayer.is_server():
		var inventario_origen = get_node(inv_origen_path)
		if inventario_origen is InventarioPlayer:
			request_venta(inventario_origen, src_slot_id, cantidad)
			#var item_recibido = inventario_origen.enviar_item(
				#self, item_dto, dest_slot)
		else:
			printerr("Ruta al inventario invalida: ", inv_origen_path, " o el nodo no es InventarioPlayer")


## Compra, basicamente
func enviar_item(inventario, src_slot: int, _cantidad: int) -> Dictionary:
	if multiplayer.is_server() and inventario is InventarioPlayer:
		if has_slot(src_slot):
			return request_compra(shop_slots[src_slot], inventario)
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


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Se puede dropear cualquier cosa en la tienda porque se puede vender cualquier cosa.
	return data is UISlot.ItemDTO and data.source_inventory is InventarioPlayer


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	## vender
	if data.source_inventory != self and data.source_inventory is InventarioPlayer:
		self.intercambio.rpc_id(1, \
			data.source_inventory.get_path(), data.src_slot_id,
			data.cantidad, -1)
