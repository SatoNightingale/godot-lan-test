extends CanvasLayer


@onready var player_data = get_parent().player_data
var respawn_timer: Timer


#func _ready():
	#print("revisando UI.player_data")
	#player_data["_test"] = "1"
	#print(get_parent().player_data.has("_test"))
	#print(get_parent().player_data["_test"])
	#print("--revisando UI.player_data")

# la UI completamente acoplada al player, y la UI no es del player...
func configure_ui(player: Player):
	respawn_timer = player.get_node("%respawn_timer")
	respawn_timer.timeout.connect(set_game_screen)
	player.update_ammo.connect(_on_update_ammo)
	%shoot_button1.setup(player.get_node("shoot_cooldown"), player.bullet_fired)
	%shoot_button2.setup(player.get_node("shoot_cooldown"), player.bullet_fired)
	%reload_button.setup(player.get_node("reload_cooldown"), player.reloading)


func _process(_delta: float) -> void:
	if %respawn_screen.visible:
		var time_left := ceili(respawn_timer.time_left)
		if time_left != int(%respawn_count.text):
			%respawn_count.text = str(time_left)


func set_dead_screen(killer_name: String):
	%respawn_screen.show()
	%screen_controls.hide()
	%killer_name.text = killer_name + " te ha matado"


func set_game_screen():
	%respawn_screen.hide()
	%screen_controls.show()


func on_player_killed(killer_id: int, dead_id: int):
	if multiplayer.get_unique_id() == killer_id:
		%bajas.text = "Bajas: " + str(player_data[killer_id].kills)
	if multiplayer.get_unique_id() == dead_id:
		set_dead_screen(player_data[killer_id].name)
		%muertes.text = "Muertes: " + str(player_data[dead_id].deaths)


func _on_update_ammo(new_ammo: int):
	%AmmoLabel.text = str(new_ammo)
