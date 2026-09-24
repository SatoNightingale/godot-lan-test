extends CanvasLayer


@onready var controlador: ControladorVirtual = %virtual_controls
@onready var anunciador: Anunciador = %label_anuncios
@onready var menu_pausa: MenuPausa = %"menu pausa"
@onready var tienda: Tienda = %Tienda

var player_data

var player : Player:
	set(_player):
		player = _player
		controlador.player = player
		respawn_timer = player.respawn_timer
		if player.is_node_ready():
			_on_player_ready()
		else:
			player.ready.connect(_on_player_ready)

var respawn_timer: Timer


func _ready() -> void:
	ConsoleLogger.set_console(%console)


func _on_player_ready():
	tienda.inventario = player.inventario


func set_dead_screen(killer_name: String):
	%respawn_screen.show()
	%virtual_controls.hide()
	%killer_name.text = killer_name + " te ha matado"
	%perdida.text = "¡-{0} de oro!".format([400])
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


func _on_toggle_console_toggled(toggled_on: bool) -> void:
	%console.visible = toggled_on
