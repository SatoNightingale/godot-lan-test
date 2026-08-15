extends Control

@export var default_port = 4242
@export var max_players = 4


#func _ready() -> void:
	#print(OS.get_cmdline_args())
	#if "host" in OS.get_cmdline_args():
		#%nameedit.text = "Server"
	#if "p1" in OS.get_cmdline_args():
		#%nameedit.text = "Player1"
		#%ipedit.text = "localhost"
	#if "p2" in OS.get_cmdline_args():
		#%nameedit.text = "Player2"
		#%ipedit.text = "localhost"
	#if "p3" in OS.get_cmdline_args():
		#%nameedit.text = "Player3"
		#%ipedit.text = "localhost"


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
