class_name ControladorVirtual extends Control


var player: Player

func configure_ui(_player: Player):
	player = _player
	player.weapon_changed.connect(_on_player_weapon_changed)
	if player.weapon != null:
		_on_player_weapon_changed(player.weapon)


func _on_player_weapon_changed(weapon: Weapon):
	if "shoot_cooldown" in weapon:
		%shoot_button.setup(weapon.shoot_cooldown, weapon.bullet_fired)
	if "reload_cooldown" in weapon:
		%reload_button.setup(weapon.reload_cooldown, weapon.reloading)
	_on_update_ammo(weapon.ammo)
	weapon.update_ammo.connect(_on_update_ammo)
	weapon.aim_mode_changed.connect(_on_weapon_aim_mode_changed)


func _on_weapon_aim_mode_changed(value: bool):
	%shoot_button.visible = value
	# intercambiar las texturas de %aim_button
	var aux_texture = %aim_button.texture_normal
	%aim_button.texture_normal = %aim_button.texture_pressed
	%aim_button.texture_pressed = aux_texture


func _on_update_ammo(new_ammo: int):
	%AmmoLabel.text = "{0} / {1}".format([str(new_ammo), str(player.weapon.max_ammo)])
