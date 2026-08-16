extends Control

@export var default_port = 4242
@export var max_players = 4


func _on_host_pressed() -> void:
	if %nameedit.text == "":
		get_parent().error_popup("Error: nombre vacio")
		return
	if %portedit.text == "":
		get_parent().error_popup("Error: puerto vacio")
		return
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(int(%portedit.text), max_players) == OK:
		multiplayer.multiplayer_peer = peer
		get_parent().player_name = %nameedit.text
		get_parent().change_scene("res://waiting room/waiting_room.tscn")


func _on_connect_pressed() -> void:
	if %nameedit.text == "":
		get_parent().error_popup("Error: nombre vacio")
		return
	if %portedit.text == "":
		get_parent().error_popup("Error: puerto vacio")
		return
	if %ipedit.text == "":
		get_parent().error_popup("Error: direccion ip vacia")
		return
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(%ipedit.text, int(%portedit.text)) == OK:
		multiplayer.multiplayer_peer = peer
		get_parent().player_name = %nameedit.text
		get_parent().change_scene("res://waiting room/waiting_room.tscn")


func _on_nameedit_editing_toggled(toggled_on: bool) -> void:
	if not DisplayServer.has_hardware_keyboard():
		if toggled_on:
			DisplayServer.virtual_keyboard_show(%nameedit.text)
		else:
			DisplayServer.virtual_keyboard_hide()

func _on_portedit_editing_toggled(toggled_on: bool) -> void:
	if not DisplayServer.has_hardware_keyboard():
		if toggled_on:
			DisplayServer.virtual_keyboard_show(%portedit.text)
		else:
			DisplayServer.virtual_keyboard_hide()

func _on_ipedit_editing_toggled(toggled_on: bool) -> void:
	if not DisplayServer.has_hardware_keyboard():
		if toggled_on:
			DisplayServer.virtual_keyboard_show(%ipedit.text)
		else:
			DisplayServer.virtual_keyboard_hide()
