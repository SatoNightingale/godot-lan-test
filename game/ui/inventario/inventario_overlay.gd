class_name InventoryUI extends Control

## Esta UI no solo debe encargarse de mostrar el inventario y la tienda, sino que de modo general muestra el inventario del player más cualquier otro inventario con el que este interactúe e intercambie; desde este punto de vista, la tienda o un cofre cualquiera hallado en medio del mapa son un inventario, solo que definen comportamientos distintos de intercambio

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
	# Y las sesiones? Como validamos las sesiones?
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


#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("reload"):
		#show()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or \
	event is InputEventScreenTouch and event.pressed:
		if event.is_pressed():
			close.emit()


func _on_open() -> void:
	opened = true
	show()

func _on_close() -> void:
	opened = false
	hide()
