extends Control

signal request_conectar(ip: String, port: int) # name
signal error(message: String)


func _ready() -> void:
	%portedit.placeholder_text = str(Configurations.default_port)
	if not DisplayServer.has_hardware_keyboard():
		setup_virtual_keyboard_elevation(self)


func _on_join_pressed() -> void:
	var ip = %ipedit.text if not %ipedit.text.is_empty() else "127.0.0.1"
	if not ip.is_valid_ip_address():
		error.emit("Direccion ip invalida")
		return
	var port = %portedit.text.to_int() if not %portedit.text.is_empty() else Configurations.default_port
	request_conectar.emit(ip, port)


func setup_virtual_keyboard_elevation(node: Node):
	# TODO: esto sigue jodiendo en las builds de movil...
	if node is LineEdit:
		node.editing_toggled.connect(
			_on_field_editing_toggled.bind(node))
	for child in node.get_children():
		setup_virtual_keyboard_elevation(child)


func _on_field_editing_toggled(toggled_on: bool, field: Control):
	%margin.add_theme_constant_override("margin_bottom", 10)
	if toggled_on:
		var vk_height = DisplayServer.virtual_keyboard_get_height()
		print("virtual keyboard height: ", vk_height)
		var node_size_from_bottom = get_viewport_rect().size.y - field.global_position.y - field.size.y
		var diff = min(node_size_from_bottom - vk_height, 0)
		print(diff)
		# duplicamos el diff porque está en un center container, y
		# añadimos un pequeño margen para que no roce el teclado
		%margin.add_theme_constant_override("margin_bottom", 10 -diff * 2 + 2)
