class_name InventoryUI extends Control

## Esta UI no solo debe encargarse de mostrar el inventario y la tienda, sino que de modo general muestra el inventario del player más cualquier otro inventario con el que este interactúe e intercambie; desde este punto de vista, la tienda o un cofre cualquiera hallado en medio del mapa son un inventario, solo que definen comportamientos distintos de intercambio

signal close

@onready var inventory_front: InventarioFront = %Inventario_player
# La tienda esta aqui temporal...
@onready var tienda: Tienda = %Tienda

var player: Player

var money_button

func initialize():
	inventory_front.player_inventory = player.inventario
	inventory_front.money_button = money_button
	inventory_front.initialize()


#func interactuar(inventario_externo: Inventario):
	#if inventario_externo != tienda:
		#%ext_inventory_container.add_child(inventario_externo)


#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("reload"):
		#show()

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and (
		event.button_index == MOUSE_BUTTON_LEFT or 
		event.button_index == MOUSE_BUTTON_RIGHT)
	) or event is InputEventScreenTouch:
		if event.is_pressed():
			hide()
			close.emit()
