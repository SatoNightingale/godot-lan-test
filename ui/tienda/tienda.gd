class_name Tienda extends Control


# Seria interesante poner este script en un nodo que tome las pulsaciones del mouse (como el Panel Container) y asi poder recibir directamente los dropeos sin tener que meterle un script a shop_tabs

var player: Player:
	set(value):
		player = value
		%shop_screen.hide()
		%open_shop.text = str(int(player.dinero.value))
		player.dinero.connect_init(func(dinero):
			var tween = create_tween()
			tween.tween_method(set_button_money, int(%open_shop.text), dinero, 0.2)
		)
		var slots = get_tree().get_nodes_in_group("inventory_slots")
		slots.append_array(get_tree().get_nodes_in_group("shop_slots"))
		for slot in slots:
			slot.tienda = self
		# Player popula los slots que se refieren a items de su inventario
		player.weapon_item.connect_init(func(new_weapon):
			%arma_actual.set_item(new_weapon)
		)


func _ready() -> void:
	pass
	#if OS.has_feature("editor"):
		#debug_tasks()


func debug_tasks():
	player = Player.new()
	player.add_item(Item.from_dto(
		ItemManager.new_item_dto_from_path("res://items/classes/ak47_item.tres")
	))


# Podria hacerse que los cambios en el inventario por compra y venta
# solo se vieran en el servidor y en el cliente afectado, haciendo
# que en las funciones request_ el servidor llame a comprar y vender
# en el cliente con rpc_id(multiplayer.get_remote_sender_id()) 
# Esto liberaria un poco de trafico y mejoraria la confidencialidad,
# si bien los cambios en el estado del player afectado (p. ej. si se cambio de arma) tendrian que comunicarse a los demas peers de todas formas

@rpc("any_peer", "call_local")
func request_comprar(info_path: String):
	if multiplayer.is_server():
		if ItemManager.item_info_exists(info_path):
			var info = ItemManager.get_item_info(info_path)
			if player.dinero.value >= info.precio:
				# crear el item con su id unico
				var dto = ItemManager.new_item_dto(info)
				comprar.rpc(dto)


@rpc("any_peer", "call_local")
func request_vender(id: int):
	if multiplayer.is_server():
		var selling = player.get_item(id)
		if selling:
			vender.rpc({"id": id, "precio": selling.precio})
		else:
			printerr("el jugador no tiene el item con id: ", id)


@rpc("authority", "call_local")
func comprar(dto: Dictionary):
	#if player.dinero.value < item.precio:
	player.dinero.value -= dto.precio
	player.add_item(Item.from_dto(dto))

@rpc("authority", "call_local")
func vender(item_data: Dictionary):
	#if player.has_item(item.id):
	player.dinero.value += item_data.precio
	player.take_item(item_data.id)


func try_comprar(info: ItemInfo):
	# Esto todavia no es rpc, por lo que suponemos que todo va a ser legal
	if player.dinero.value >= info.precio:
		request_comprar.rpc(info.resource_path)
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
