extends Node

@onready var _active_scene = $"Connect menu"

var player_name: String
var player_data: Dictionary
var ready_player_count = 0


func _ready() -> void:
	var args = parse_arguments()
	if "host" in args or "player" in args:
		var peer = ENetMultiplayerPeer.new()
		if "host" in args:
			if peer.create_server(4242, 4) == OK:
				multiplayer.multiplayer_peer = peer
				player_name = "Server"
				change_scene("res://waiting room/waiting_room.tscn")
		if "player" in args:
			var numplayer = args["player"]
			if peer.create_client("localhost", 4242) == OK:
				multiplayer.multiplayer_peer = peer
				player_name = "Player " + numplayer
				change_scene("res://waiting room/waiting_room.tscn")
				match numplayer:
					"1": get_window().position = Vector2i(723, 110)
					"2": get_window().position = Vector2i(723, 110)
					"3": get_window().position = Vector2i(723, 110)
		#await multiplayer.peer_connected
		#if multiplayer.is_server():
			#$"waiting room"._on_start_pressed()


func parse_arguments() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""
	return arguments


func change_scene(scene_path: String):
	remove_child(_active_scene)
	if _active_scene != null:
		_active_scene.queue_free()
	_active_scene = load(scene_path).instantiate()
	add_child(_active_scene)


func load_game():
	var game_scene : Node = preload("res://game/game.tscn").instantiate()
	game_scene.player_data = player_data
	game_scene.ready.connect(func():
		print(player_name, " load game")
		on_player_loaded.rpc_id(1)
	)
	add_child(game_scene)
	remove_child(_active_scene)
	_active_scene.queue_free()
	_active_scene = game_scene


@rpc("any_peer", "call_local")
func on_player_loaded():
	if multiplayer.is_server():
		ready_player_count += 1
		print("ready players: ", ready_player_count)
		if ready_player_count == player_data.size():
			get_node("/root/Main/Game").server_initialize()


func error_popup(message: String, title := "Error"):
	%error_popup.dialog_text = message
	%error_popup.title = title
	%error_popup.popup_centered_clamped()
