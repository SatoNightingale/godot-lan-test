extends Control

signal hosted(name: String)
signal connected(name: String, address: String)
signal error(message: String)

@export var default_port = 4242
@export var max_players = 4

var player_name := "Player"

## TODO: redimensionar en movil para llenar mas la pantalla
# _ready conecta las señales, pero cuando se vuelve a llamar las conecta dos veces

func _ready() -> void:
	%nameedit.text = player_name
	%version_label.text = ProjectSettings.get_setting("application/config/version")
	# ProjectSettings.globalize_path("user://")
	%btn_patch.pressed.connect(%patch_finder.popup_file_dialog)
	%patch_finder.file_selected.connect(manejar_parche)
	%btn_patch_restart.confirmed.connect(func():
		OS.set_restart_on_exit(true)
		get_tree().quit()
	)
	if not DisplayServer.has_hardware_keyboard():
		setup_virtual_keyboard_elevation()


func initialize():
	pass


func manejar_parche(path: String):
	if PatchSystem.copiar_parche(path) == OK:
		%btn_patch_restart.popup_centered_clamped()


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


func _on_host_pressed() -> void:
	if %nameedit.text == "":
		error.emit("Error: nombre vacio")
		return
	if %portedit.text == "":
		error.emit("Error: puerto vacio")
		return
	var peer = ENetMultiplayerPeer.new()
	var errcod = peer.create_server(int(%portedit.text), max_players)
	if errcod == OK:
		multiplayer.multiplayer_peer = peer
		hosted.emit(%nameedit.text)
	else:
		error.emit("Error al crear servidor: " + str(errcod))


func _on_connect_pressed() -> void:
	if %nameedit.text == "":
		error.emit("Error: nombre vacio")
		return
	if %portedit.text == "":
		error.emit("Error: puerto vacio")
		return
	if %ipedit.text == "":
		error.emit("Error: direccion ip vacia")
		return
	var peer = ENetMultiplayerPeer.new()
	var errcod = peer.create_client(%ipedit.text, int(%portedit.text))
	if errcod == OK:
		multiplayer.multiplayer_peer = peer
		connected.emit(%nameedit.text, %ipedit.text)
	else:
		error.emit("Error al conectar: " + str(errcod))


func _on_field_editing_toggled(toggled_on: bool, field: Control):
	if toggled_on:
		var vk_height = DisplayServer.virtual_keyboard_get_height()
		var node_pos_from_bottom = get_viewport_rect().size.y - field.global_position.y
		var diff = max(vk_height - node_pos_from_bottom, 0)
		%margin.add_theme_constant_override("margin_bottom", diff)
	else:
		%margin.add_theme_constant_override("margin_bottom", 0)
