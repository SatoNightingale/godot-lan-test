class_name MenuPausa extends Control


var juego_pausado := false


func _ready() -> void:
	%open_button.pressed.connect(%menu_screen.show)
	%btn_resumir.pressed.connect(%menu_screen.hide)
	%btn_disconnect.pressed.connect(_on_disconnect_request)
	%btn_serverpause.disabled = !multiplayer.is_server()
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		theme = load("res://menus/tema_movil.tres")


@rpc("call_local")
func server_pause_game(pause_state: bool):
	juego_pausado = pause_state
	get_tree().paused = juego_pausado
	%pause_screen.visible = juego_pausado


func _on_disconnect_request():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	var main_menu = load("res://menus/main menu.tscn").instantiate()
	get_tree().change_scene_to_node(main_menu)


func _on_menu_screen_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			%menu_screen.hide()


func _on_btn_serverpause_pressed() -> void:
	if multiplayer.is_server():
		juego_pausado = !juego_pausado
		%btn_serverpause.text = "Reanudar juego" if juego_pausado else "Detener juego"
		server_pause_game.rpc(juego_pausado)
		if not juego_pausado:
			%menu_screen.hide()


func _on_menu_screen_visibility_changed() -> void:
	%open_button.visible = !%menu_screen.visible
