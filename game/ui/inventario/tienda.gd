class_name Tienda extends Control

# Pienso que deben estar en scripts separados los frontends de tienda y de inventario, asi como los backends de uno y otro.
# Aqui esta el backend y el frontend de la tienda, y el frontend del inventario

var inventarios: Dictionary[int, Inventario]


func init_inventarios(players: Dictionary):
	for id in players:
		inventarios[id] = players[id].inventario


@rpc("any_peer", "call_local")
func request_compra(item_path: String, slot: Inventario.SlotRole):
	if multiplayer.is_server():
		if ItemManager.item_type_exists(item_path):
			var player_id = multiplayer.get_remote_sender_id()
			var transaction_inventory = inventarios[player_id]
			var type = ItemManager.get_item_type(item_path)
			if transaction_inventory.dinero.value >= type.precio:
				# sellar el item con su id unico
				#var dto = ItemManager.new_item_dto(item_path)
				ItemManager.registrar_item(type)
				var dto = type.to_dto()
				transaction_inventory.modificar_dinero(
					-type.precio, player_id)
				transaction_inventory.server_add_item(dto, slot)
			else:
				printerr("Jugador con id: ", player_id, " intentando hacer una compra del objeto id '", type.item_type_path, "' para el cual no tiene suficiente dinero")
		else:
			printerr("El item '", item_path, "' no existe")


@rpc("any_peer", "call_local")
func request_venta(item_id: int):
	if multiplayer.is_server():
		var player_id = multiplayer.get_remote_sender_id()
		var transaction_inventory = inventarios[player_id]
		var selling = transaction_inventory.get_item(item_id)
		if selling:
			#var item_data = {"id": item_id, "precio": selling.precio}
			transaction_inventory.modificar_dinero(
				+selling.precio, player_id)
			transaction_inventory.server_take_item(item_id)
		else:
			printerr("el jugador no tiene el item con id: ", item_id)


# Seria interesante poner este script en un nodo que tome las pulsaciones del mouse (como el Panel Container) y asi poder recibir directamente los dropeos sin tener que meterle un script a shop_tabs
