class_name InventarioFront extends Control


@onready var slot_maps: Dictionary[int, UISlot] = {
	InventarioPlayer.MAIN_WEAPON: %main_weapon,
	InventarioPlayer.SECONDARY_WEAPON: %secondary_weapon,
	InventarioPlayer.EXTRA_WEAPON: %extra_weapon,
	InventarioPlayer.MAIN_AMMO: %main_bullet
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
	# slots especificos
	for slot_role in slot_maps:
		slot_maps[slot_role].slot = player_inventory._slots[slot_role]
		slot_maps[slot_role].inventario = player_inventory
	# conjuntos
	var conectar_conjuntos = func(group: StringName, conjunto: Array):
		var slots_grupo = get_tree().get_nodes_in_group(group)
		var slot_id = 0
		for slot in slots_grupo:
			if slot.slot == null:
				slot.slot = conjunto[slot_id]
				slot.inventario = player_inventory
				slot_id += 1
	conectar_conjuntos.call("accesorios", player_inventory.accesorios)
	conectar_conjuntos.call("bolsillo_seguro", player_inventory.bolsillo_seguro)
	conectar_conjuntos.call("mochila", player_inventory.mochila)


func _on_not_enough_money():
	# emitir mensaje de "tas arrancao"
	var tween = create_tween()
	var toggle_money_color = func():
		var color = Color.RED if money_button.get_theme_color("font_color") == Color.GOLD else Color.GOLD
		money_button.add_theme_color_override("font_color", color)
	tween.tween_callback(toggle_money_color)
	tween.tween_interval(0.5)
	tween.set_loops(6)
