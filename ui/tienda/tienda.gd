class_name Tienda extends Control


# Seria interesante poner este script en un nodo que tome las pulsaciones del mouse (como el Panel Container) y asi poder recibir directamente los dropeos sin tener que meterle un script a shop_tabs

var players: Dictionary[int, Player]

var inventario: Inventario:
	set(value):
		inventario = value
		%shop_screen.hide()
		%open_shop.text = str(int(inventario.dinero.value))
		inventario.dinero.connect_init(func(dinero):
			var tween = create_tween()
			tween.tween_method(set_button_money, int(%open_shop.text), dinero, 0.2)
		)
		var slots = get_tree().get_nodes_in_group("inventory_slots")
		slots.append_array(get_tree().get_nodes_in_group("shop_slots"))
		for slot in slots:
			slot.tienda = self
		# Player popula los slots que se refieren a items de su inventario
		inventario.weapon_item.connect_init(func(new_weapon):
			%arma_actual.set_item(new_weapon)
		)


func _ready() -> void:
	pass
	#if OS.has_feature("editor"):
		#debug_tasks()


func debug_tasks():
	var player = Player.new()
	player.ready.connect(func():
		inventario = player.inventario
		inventario.server_add_item(ItemManager.new_item_dto_from_path(
		"res://items/classes/ak47_item.tres"))
	)


# Podria hacerse que los cambios en el inventario por compra y venta
# solo se vieran en el servidor y en el cliente afectado, haciendo
# que en las funciones request_ el servidor llame a comprar y vender
# en el cliente con rpc_id(multiplayer.get_remote_sender_id()) 
# Esto liberaria un poco de trafico y mejoraria la confidencialidad,
# si bien los cambios en el estado del player afectado (p. ej. si se cambio de arma) tendrian que comunicarse a los demas peers de todas formas

@rpc("any_peer", "call_local")
func request_compra(info_path: String):
	if multiplayer.is_server():
		if ItemManager.item_info_exists(info_path):
			var player_id = multiplayer.get_remote_sender_id()
			var transaction_inventory = players[player_id].inventario
			var info = ItemManager.get_item_info(info_path)
			if transaction_inventory.dinero.value >= info.precio:
				# crear el item con su id unico
				var dto = ItemManager.new_item_dto(info)
				# Comprar en el servidor
				transaction_inventory.modificar_dinero(-dto.precio, player_id)
				#if player_id != 1: # Comprar en el cliente
					#transaction_inventory.modificar_dinero.rpc_id(
						#player_id, -dto.precio)
				# Adquirir item, servidor y cliente
				transaction_inventory.server_add_item(dto)
			else:
				printerr("Jugador con id: ", player_id, " intentando hacer una compra del objeto id '", info.resource_path, "' para el cual no tiene suficiente dinero")


@rpc("any_peer", "call_local")
func request_venta(item_id: int):
	if multiplayer.is_server():
		var player_id = multiplayer.get_remote_sender_id()
		var transaction_inventory = players[player_id].inventario
		var selling = transaction_inventory.get_item(item_id)
		if selling:
			var item_data = {"id": item_id, "precio": selling.precio}
			# Vender en el servidor
			transaction_inventory.modificar_dinero(item_data.precio, player_id)
			#if player_id != 1: # Vender en el cliente
				#transaction_inventory.modificar_dinero.rpc_id(
					#player_id, item_data.precio)
			# Retirar item, servidor y cliente
			transaction_inventory.server_take_item(item_id)
		else:
			printerr("el jugador no tiene el item con id: ", item_id)


func try_comprar(info: ItemInfo):
	# Esto todavia no es rpc, por lo que suponemos que todo va a ser legal
	if inventario.dinero.value >= info.precio:
		request_compra.rpc(info.resource_path)
	else:
		# emitir mensaje de "tas arrancao"
		var tween = create_tween()
		var toggle_money_color = func():
			var color = Color.RED if %open_shop.get_theme_color("font_color") == Color.GOLD else Color.GOLD
			%open_shop.add_theme_color_override("font_color", color)
		tween.tween_callback(toggle_money_color)
		tween.tween_interval(0.5)
		tween.set_loops(6)


func set_button_money(value: int):
	%open_shop.text = str(value)


func _on_shop_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and (
		event.button_index == MOUSE_BUTTON_LEFT or 
		event.button_index == MOUSE_BUTTON_RIGHT)
	) or event is InputEventScreenTouch:
		if event.is_pressed():
			%shop_screen.hide()
