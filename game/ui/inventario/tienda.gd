@tool
class_name Tienda extends Inventario

## Creo que el frontend y el backend de la tienda pueden ir aqui.


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
		slot_id += 1


#@rpc("any_peer", "call_local")
func request_compra(item_path: String, transaction_inventory: InventarioPlayer): # , slot: InventarioPlayer.SlotRole
	if multiplayer.is_server():
		if ItemManager.item_type_exists(item_path):
			#var player_id = multiplayer.get_remote_sender_id()
			#var transaction_inventory = inventarios[player_id]
			var type = ItemManager.get_item_type(item_path)
			if transaction_inventory.dinero.value >= type.precio:
				# sellar el item con su id unico
				var dto = ItemManager.new_item_dto(item_path)
				#ItemManager.registrar_item(type)
				#var dto = type.to_dto()
				transaction_inventory.modificar_dinero(-type.precio)
				#transaction_inventory.server_add_item(dto, slot)
				return dto
			else:
				transaction_inventory.call_not_enough_money.rpc_id(
					transaction_inventory.player_id) # de pinga
				#printerr("Jugador con id: ", transaction_inventory.player_id, " intentando hacer una compra del objeto id '", type.item_type_path, "' para el cual no tiene suficiente dinero")
		else:
			printerr("El item '", item_path, "' no existe")


#@rpc("any_peer", "call_local")
func request_venta(item_id: int, transaction_inventory: InventarioPlayer):
	if multiplayer.is_server():
		#var player_id = multiplayer.get_remote_sender_id()
		#var transaction_inventory = inventarios[player_id]
		var selling = transaction_inventory.get_item(item_id)
		if selling:
			#var item_data = {"id": item_id, "precio": selling.precio}
			transaction_inventory.modificar_dinero(+selling.precio)
			transaction_inventory.server_take_item_id(item_id)
		else:
			printerr("el jugador no tiene el item con id: ", item_id)


## Esto se llama en el inventario que recibe el item intercambiado
## Por tanto, aqui va la operacion de venta
@rpc("any_peer", "call_local")
func intercambio(inv_origen_path: NodePath, item_dto: Dictionary, _dest_slot: int):
	# and validar_sesion(multiplayer.get_remote_sender_id())
	if multiplayer.is_server():
		var inventario_origen = get_node(inv_origen_path)
		if inventario_origen is InventarioPlayer:
			request_venta(item_dto.id, inventario_origen)
			#var item_recibido = inventario_origen.enviar_item(
				#self, item_dto, dest_slot)
		else:
			printerr("Ruta al inventario invalida: ", inv_origen_path, " o el nodo no es InventarioPlayer")


## Compra, basicamente
func enviar_item(inventario: Inventario, item_dto: Dictionary, _slot_dest: int):
	if multiplayer.is_server() and inventario is InventarioPlayer:
		return request_compra(item_dto.type_id, inventario)
	else: printerr("enviar_item solo puede llamarse en el servidor y debe ser un InventarioPlayer")
	return null


# Nadie añade ni toma items de la tienda modificando sus slots
func server_add_item(_item_dto: Dictionary, _slot_id):
	printerr("add_item_server no se usa en Tienda")
func server_take_item(_slot_id: int):
	printerr("take_item_server no se usa en Tienda")
func mover_item_local(_from_slot_id: int, _to_slot_id: int):
	printerr("mover_item_local no se usa en Tienda")


# Seria interesante poner este script en un nodo que tome las pulsaciones del mouse (como el Panel Container) y asi poder recibir directamente los dropeos sin tener que meterle un script a shop_tabs
