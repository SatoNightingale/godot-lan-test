class_name InventoryUI extends Control

## Esta UI no solo debe encargarse de mostrar el inventario y la tienda, sino que de modo general muestra el inventario del player más cualquier otro inventario con el que este interactúe e intercambie; desde este punto de vista, la tienda o un cofre cualquiera hallado en medio del mapa son un inventario, solo que definen comportamientos distintos de intercambio

@onready var inventory_front: InventarioFront = %Inventario
@onready var tienda: Tienda = %Tienda
@onready var money_button: Button = %money_button

var player: Player

func _ready() -> void:
	inventory_front.money_button = money_button
	inventory_front.tienda = tienda
	#inventory_front.player_inventory = player.inventario
	%money_button.pressed.connect(func():
		%shop_screen.visible = !%shop_screen.visible
	)
	%shop_screen.hide()
	var slots = get_tree().get_nodes_in_group("inventory_slots")
	slots.append_array(get_tree().get_nodes_in_group("shop_slots"))
	for slot in slots:
		slot.tienda = tienda
		slot.front_inventario = inventory_front


#func _ready() -> void:
	#if get_tree().current_scene == self:
		#debug_tasks()
#
#
#func debug_tasks():
	#var player = load("res://game/player/player.tscn").instantiate()
	#player.ready.connect(func():
		#inventarios[1] = player.inventory_front
		#inventory_front = player.inventory_front
		#inventory_front.server_add_item(ItemManager.new_item_dto(
			#"res://items/classes/ak47_item.tres"), 
			#Inventario.SlotRole.MAIN_WEAPON)
	#)
	#add_child(player)


func _on_shop_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and (
		event.button_index == MOUSE_BUTTON_LEFT or 
		event.button_index == MOUSE_BUTTON_RIGHT)
	) or event is InputEventScreenTouch:
		if event.is_pressed():
			%shop_screen.hide()
