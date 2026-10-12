class_name InventarioFront extends Control


@onready var slot_maps: Dictionary[InventarioPlayer.SlotRole, UISlot] = {
	InventarioPlayer.SlotRole.MAIN_WEAPON: %main_weapon,
	InventarioPlayer.SlotRole.SECONDARY_WEAPON: %secondary_weapon,
	InventarioPlayer.SlotRole.EXTRA_WEAPON: %extra_weapon,
	InventarioPlayer.SlotRole.MAIN_AMMO: %main_bullet
}

var money_button: Button
var player_inventory: InventarioPlayer

## TabContainer.switch_on_drag_hover
## Cambia a la pestaña hovereada si esta arrastrando algo
## Lo malo es que TabContainer pone todas sus tabs fijas en un lugar, pero podriamos ocultar las tabs y hacer botones que se comporten como switch_on_drag_hover (Viewport.gui_is_dragging)


func initialize():
	# dinero
	var set_button_money = func(money: int):
		money_button.text = str(money)
	set_button_money.call(int(player_inventory.dinero.value))
	player_inventory.dinero.conectar(func(dinero, _old_dinero):
		var tween = create_tween()
		tween.tween_method(set_button_money, int(money_button.text), dinero, 0.2)
	)
	player_inventory.not_enough_money.connect(_on_not_enough_money)
	# slots
	conectar_slots()


func conectar_slots():
	var slot_id = 0
	for slot_role in slot_maps:
		slot_maps[slot_role].slot = player_inventory._slots[slot_role]
		slot_maps[slot_role].inventario = player_inventory
		slot_id += 1
	var uislots = get_tree().get_nodes_in_group("slots")
	for uislot in uislots:
		if uislot.slot == null:
			uislot.slot = player_inventory._slots[slot_id]
			uislot.inventario = player_inventory
			slot_id += 1


func _on_not_enough_money():
	# emitir mensaje de "tas arrancao"
	var tween = create_tween()
	var toggle_money_color = func():
		var color = Color.RED if money_button.get_theme_color("font_color") == Color.GOLD else Color.GOLD
		money_button.add_theme_color_override("font_color", color)
	tween.tween_callback(toggle_money_color)
	tween.tween_interval(0.5)
	tween.set_loops(6)


#func try_comprar(item: Item, target_role: InventarioPlayer.SlotRole):
	## Esto todavia no es rpc, por lo que suponemos que todo va a ser legal
	#if player_inventory.dinero.value >= item.precio:
		## Cuando hacemos esta llamada no sabemos si el request va a ser aceptado o no, pero necesitariamos hacer algunas cosas (como fijar el item en el slot correspondiente) en caso de que sea aceptado y otras en caso de que no lo sea
		## La opcion facil es pasarle la decision al servidor, y asi nos aseguramos que las acciones realizadas no dependan del cliente. Sin embargo, habria que pasarle al servidor demasiada informacion, y redefinir sus metodos para que abarquen las nuevas responsabilidades.
		#tienda.request_compra.rpc(item.resource_path, target_role)
	#else:
		## emitir mensaje de "tas arrancao"
		#var tween = create_tween()
		#var toggle_money_color = func():
			#var color = Color.RED if money_button.get_theme_color("font_color") == Color.GOLD else Color.GOLD
			#money_button.add_theme_color_override("font_color", color)
		#tween.tween_callback(toggle_money_color)
		#tween.tween_interval(0.5)
		#tween.set_loops(6)
