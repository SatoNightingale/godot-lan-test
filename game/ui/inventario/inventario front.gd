class_name InventarioFront extends Control


@onready var slot_maps: Dictionary[Inventario.SlotRole, ItemSlot] = {
	Inventario.SlotRole.MAIN_WEAPON: %arma_actual
}

var tienda: Tienda
var money_button: Button

var player_inventory: Inventario:
	set(value):
		player_inventory = value
		#%shop_screen.hide()
		money_button.text = str(int(player_inventory.dinero.value))
		player_inventory.dinero.connect_init(func(dinero):
			var tween = create_tween()
			tween.tween_method(set_button_money, int(money_button.text), dinero, 0.2)
		)
		# Player popula los slots que se refieren a items de su player_inventory
		for inv_slot_role in slot_maps:
			player_inventory.public_items[inv_slot_role].item \
			.connect_init(func(new_weapon):
				slot_maps[inv_slot_role].item = new_weapon
			)


func try_comprar(item: Item, target_role: Inventario.SlotRole):
	# Esto todavia no es rpc, por lo que suponemos que todo va a ser legal
	if player_inventory.dinero.value >= item.precio:
		# Cuando hacemos esta llamada no sabemos si el request va a ser aceptado o no, pero necesitariamos hacer algunas cosas (como fijar el item en el slot correspondiente) en caso de que sea aceptado y otras en caso de que no lo sea
		# La opcion facil es pasarle la decision al servidor, y asi nos aseguramos que las acciones realizadas no dependan del cliente. Sin embargo, habria que pasarle al servidor demasiada informacion, y redefinir sus metodos para que abarquen las nuevas responsabilidades.
		tienda.request_compra.rpc(item.resource_path, target_role)
	else:
		# emitir mensaje de "tas arrancao"
		var tween = create_tween()
		var toggle_money_color = func():
			var color = Color.RED if money_button.get_theme_color("font_color") == Color.GOLD else Color.GOLD
			money_button.add_theme_color_override("font_color", color)
		tween.tween_callback(toggle_money_color)
		tween.tween_interval(0.5)
		tween.set_loops(6)


func set_button_money(value: int):
	money_button.text = str(value)
