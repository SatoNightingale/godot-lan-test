class_name ControladorVirtual extends Control


var player: Player:
	set(_player):
		player = _player
		player.weapon_changed.connect(_on_player_weapon_changed)
		player.glance_mode.changed.connect(_on_player_glance_mode_changed)
		setup_visibility(player.weapon != null)
		if player.weapon != null:
			_on_player_weapon_changed(player.weapon)


func _on_player_weapon_changed(weapon: Weapon):
	setup_visibility(weapon != null)
	if weapon is FireWeapon:
		#%shoot_button.setup(weapon.get_node("shoot_timer"), weapon.bullet_fired)
		%reload_button.setup(weapon.get_node("reload_timer"), weapon.reloading)
		_on_update_ammo(weapon.ammo)
		weapon.update_ammo.connect(_on_update_ammo)


func _on_player_glance_mode_changed(value: bool):
	%shoot_button.visible = value
	# intercambiar las texturas de %aim_button
	var aux_texture = %aim_button.texture_normal
	%aim_button.texture_normal = %aim_button.texture_pressed
	%aim_button.texture_pressed = aux_texture


func _on_update_ammo(new_ammo: int):
	%AmmoLabel.text = "{0} / {1}".format([str(new_ammo), str(player.weapon.max_ammo)])


# Cuando no tiene arma, el tip del joystick de apuntar no debe mostrar el icono de bala
# Tambien se podria tener un controlador diferente para cada tipo de arma, con una variante para cuando no tiene arma ninguna. Pero eso ya es otra cosa
func setup_visibility(value: bool):
	%reload_button.visible = value
	%aim_button.visible = value
	%shoot_button.visible = false
	%AmmoLabel.visible = value
