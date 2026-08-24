extends CanvasLayer


@onready var anunciador: Anunciador = %label_anuncios
@onready var menu_pausa: MenuPausa = %"menu pausa"

var player_data

var player : Player
var respawn_timer: Timer


func configure_ui(_player: Player):
	player = _player
	player.weapon_changed.connect(_on_player_weapon_changed)
	if player.weapon != null:
		_on_player_weapon_changed(player.weapon)
	respawn_timer = player.respawn_timer
	respawn_timer.timeout.connect(set_game_screen)


func _on_player_weapon_changed(weapon: Weapon):
	if "shoot_cooldown" in weapon:
		%shoot_button.setup(weapon.shoot_cooldown, weapon.bullet_fired)
	if "reload_cooldown" in weapon:
		%reload_button.setup(weapon.reload_cooldown, weapon.reloading)
	_on_update_ammo(weapon.ammo)
	weapon.update_ammo.connect(_on_update_ammo)
	weapon.aim_mode_changed.connect(_on_weapon_aim_mode_changed)


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


func _on_weapon_aim_mode_changed(value: bool):
	%shoot_button.visible = value
	# intercambiar las texturas de %aim_button
	var aux_texture = %aim_button.texture_normal
	%aim_button.texture_normal = %aim_button.texture_pressed
	%aim_button.texture_pressed = aux_texture


func _on_update_ammo(new_ammo: int):
	%AmmoLabel.text = "{0} / {1}".format([str(new_ammo), str(player.weapon.max_ammo)])
