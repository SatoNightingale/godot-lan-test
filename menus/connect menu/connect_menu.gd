extends Control

signal connected(address: String)
signal error(message: String)
#signal go_back


func _ready() -> void:
	%portedit.placeholder_text = str(Configurations.default_port)
	if not DisplayServer.has_hardware_keyboard():
		setup_virtual_keyboard_elevation()


func initialize():
	pass


func setup_virtual_keyboard_elevation():
	%ipedit.editing_toggled.connect(_on_field_editing_toggled.bind(%ipedit))
	%portedit.editing_toggled.connect(_on_field_editing_toggled.bind(%portedit))
	%nameedit.editing_toggled.connect(_on_field_editing_toggled.bind(%nameedit))
	#var margin_restart_callable = %margin.add_theme_constant_override.bind("margin_bottom", 0)
	#%ipedit.focus_entered.connect(_on_field_focused.bind(%ipedit))
	#%portedit.focus_entered.connect(_on_field_focused.bind(%portedit))
	#%nameedit.focus_entered.connect(_on_field_focused.bind(%nameedit))
	#%ipedit.focus_exited.connect(margin_restart_callable)
	#%portedit.focus_exited.connect(margin_restart_callable)
	#%nameedit.focus_exited.connect(margin_restart_callable)


func _on_connect_pressed() -> void:
	if %ipedit.text == "":
		error.emit("Error: especifique una direccion IP")
		return
	var ip = %ipedit.text
	var port = %portedit.text.to_int() if not %portedit.text.is_empty() else Configurations.default_port
	var peer = ENetMultiplayerPeer.new()
	var errcod = peer.create_client(ip, port)
	if errcod == OK:
		multiplayer.multiplayer_peer = peer
		connected.emit(ip)
	else:
		error.emit("Error al conectar: " + str(errcod))


func _on_field_editing_toggled(toggled_on: bool, field: Control):
	%margin.add_theme_constant_override("margin_bottom", 0)
	if toggled_on:
		var vk_height = DisplayServer.virtual_keyboard_get_height()
		var node_size_from_bottom = get_viewport_rect().size.y - field.global_position.y - field.size.y
		var diff = min(node_size_from_bottom - vk_height, 0)
		# duplicamos el diff porque está en un center container, y
		# añadimos un pequeño margen para que no roce el teclado
		%margin.add_theme_constant_override("margin_bottom", -diff * 2 + 2)


#func _on_back_pressed() -> void:
	#go_back.emit()
