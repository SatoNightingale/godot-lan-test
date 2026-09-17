extends CanvasLayer


@onready var controlador: ControladorVirtual = %virtual_controls
@onready var anunciador: Anunciador = %label_anuncios
@onready var menu_pausa: MenuPausa = %"menu pausa"
@onready var tienda: Tienda = %Tienda
#var tienda: Tienda

var player_data

var player : Player:
	set(_player):
		player = _player
		controlador.player = player
		respawn_timer = player.respawn_timer
		player.ready.connect(func(): 
			tienda.inventario = player.inventario
		)
		#respawn_timer.timeout.connect(set_game_screen)

var respawn_timer: Timer


#func _process(_delta: float) -> void:
	#if %respawn_screen.visible:
		#var time_left := ceili(respawn_timer.time_left)
		#if time_left != int(%respawn_count.text):
			#%respawn_count.text = str(time_left)


func set_dead_screen(killer_name: String):
	%respawn_screen.show()
	%virtual_controls.hide()
	%killer_name.text = killer_name + " te ha matado"
	%perdida.text = "¡-{0} de oro!".format([1000])
	var update_respawn_seconds = func(seconds):
		%respawn_countdown.text = str(seconds)
	var tween = create_tween()
	tween.tween_method(update_respawn_seconds, 3, 0, 3)
	actualizar_muertes()


@rpc("authority", "call_local")
func set_game_screen():
	%respawn_screen.hide()
	%virtual_controls.show()


func actualizar_bajas():
	%bajas.text = "Bajas: {0}".format(
		[str(player_data[multiplayer.get_unique_id()].kills)])

func actualizar_muertes():
	%muertes.text = "Muertes: {0}".format(
		[str(player_data[multiplayer.get_unique_id()].deaths)])

#func on_player_killed(killer_id: int, dead_id: int):
	#if multiplayer.get_unique_id() == killer_id:
		#%bajas.text = "Bajas: " + str(player_data[killer_id].kills)
	#if multiplayer.get_unique_id() == dead_id:
		##%UI.set_dead_screen(player_data[killer_id].name)
		#%muertes.text = "Muertes: " + str(player_data[dead_id].deaths)


@rpc("authority", "call_local")
func set_defeated_screen():
	%virtual_controls.hide()
	%respawn_screen.hide()
	%Tienda.hide()
	%defeated_screen.show()


@rpc("authority", "call_local")
func set_gameover_screen(winner_name: String):
	%gameover_screen.show()
	%winner_name.text = "{0} ha ganado la partida".format([winner_name])
	# un buen momento para mostrar leaderboard aqui
	

func _on_gameover_disconnect_pressed() -> void:
	menu_pausa._on_disconnect_request()


func _on_defeated_screen_gui_input(_event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#event.pressed
	pass
