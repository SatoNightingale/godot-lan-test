extends CanvasLayer


@onready var controlador: ControladorVirtual = %virtual_controls
@onready var anunciador: Anunciador = %label_anuncios
@onready var menu_pausa: MenuPausa = %"menu pausa"

var player_data

var player : Player
var respawn_timer: Timer


func configure_ui(_player: Player):
	player = _player
	controlador.configure_ui(player)
	respawn_timer = player.respawn_timer
	respawn_timer.timeout.connect(set_game_screen)


func _process(_delta: float) -> void:
	if %respawn_screen.visible:
		var time_left := ceili(respawn_timer.time_left)
		if time_left != int(%respawn_count.text):
			%respawn_count.text = str(time_left)


func set_dead_screen(killer_name: String):
	%respawn_screen.show()
	%virtual_controls.hide()
	%killer_name.text = killer_name + " te ha matado"


func set_game_screen():
	%respawn_screen.hide()
	%virtual_controls.show()


func on_player_killed(killer_id: int, dead_id: int):
	if multiplayer.get_unique_id() == killer_id:
		%bajas.text = "Bajas: " + str(player_data[killer_id].kills)
	if multiplayer.get_unique_id() == dead_id:
		set_dead_screen(player_data[killer_id].name)
		%muertes.text = "Muertes: " + str(player_data[dead_id].deaths)
