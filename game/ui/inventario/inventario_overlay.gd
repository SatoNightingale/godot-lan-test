class_name InventoryUI extends Control


signal open
signal close

@onready var inventory_front: InventarioFront = %Inventario_player
# La tienda esta aqui temporal...
@onready var tienda: Tienda = %Tienda

var player: Player
var money_button: Button
var opened := false
@onready var actual_front: Node = tienda

func initialize():
	inventory_front.player_inventory = player.inventario
	inventory_front.money_button = money_button
	inventory_front.initialize()
	money_button.pressed.connect(func():
		if not opened: abrir_tienda()
		else: cerrar()
	)


func interactuar(inventario_externo: Inventario):
	# no podria haber un metodo para dejar cargado el ultimo inventario abierto, de forma que no se tenga que reiniciar si se cierra y se abre el mismo inventario varias veces?
	%ext_inventory_container.remove_child(actual_front)
	if actual_front != tienda:
		actual_front.queue_free()
	var front = inventario_externo.get_front()
	%ext_inventory_container.add_child(front)
	actual_front = front
	open.emit()

func abrir_tienda():
	if actual_front != tienda:
		if actual_front:
			%ext_inventory_container.remove_child(actual_front)
			actual_front.queue_free()
		%ext_inventory_container.add_child(tienda)
		actual_front = tienda
	open.emit()


func cerrar():
	close.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or \
	event is InputEventScreenTouch:
		if event.is_pressed():
			close.emit()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is UISlot.ItemDTO

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	player.inventario.drop_item.rpc_id(1, data.src_slot_id, data.cantidad)


func _on_open() -> void:
	opened = true
	show()
	# Para que, inmediatamente al abrir esta pantalla, no se mande a cerrar enseguida si el click esta puesto sobre el ColorRect
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_close() -> void:
	opened = false
	hide()
