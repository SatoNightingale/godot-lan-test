class_name ControladorVirtual extends Control

# TODO propiedad para deshabilitar esta talla por favor, especialmente los joysticks

var player: Player:
	set(_player):
		player = _player
		player.weapon_prop.connect_init(_on_player_weapon_changed)
		player.glance_mode.conectar(
			_on_player_glance_mode_changed)

var ammo_warning_tween: Tween


func _on_player_weapon_changed(weapon: Weapon, old_weapon: Weapon):
	setup_visibility(weapon != null)
	if weapon:
		if weapon is FireWeapon:
			%reload_button.setup(weapon.reload_cooldown, weapon.reloading)
			weapon.ammo_slot.item_prop.connect_init(
				_weapon_check_ammo.bind(weapon))
			weapon.update_ammo.connect(_on_update_ammo)
			_on_update_ammo(weapon.ammo, weapon.total_ammo)
			weapon.no_ammo.connect(_no_ammo_warning)
	if old_weapon:
		%reload_button.desetup()
		if old_weapon is FireWeapon:
			old_weapon.update_ammo.disconnect(_on_update_ammo)
			old_weapon.no_ammo.disconnect(_no_ammo_warning)
			old_weapon.ammo_slot.item_prop.desconectar(
				_weapon_check_ammo)


func _on_player_glance_mode_changed(value: bool, _old_value):
	%shoot_button.visible = value
	# intercambiar las texturas de %aim_button
	var aux_texture = %aim_button.texture_normal
	%aim_button.texture_normal = %aim_button.texture_pressed
	%aim_button.texture_pressed = aux_texture

## Se llama cuando cambia el item en el slot de municion
func _weapon_check_ammo(new_item: Item, _old_item, weapon: FireWeapon):
	if new_item:
		if new_item.item_type_path != weapon.clase_municion_path:
			%AmmoLabel.text = "Munición incorrecta"
		#new_item.cantidad_prop.connect_init(func(new_cantidad, _old_cantidad):
			#%AmmoLabel.text = "{0} / {1}".format([
				#str(weapon.ammo), str(new_cantidad)])
		#)


func _on_update_ammo(loaded_ammo: int, total_ammo: int):
	%AmmoLabel.text = "{0} / {1}".format([str(loaded_ammo), str(total_ammo)])


func _no_ammo_warning():
	# Tomado del 'func tas_arrancao' de inventario front, con modificaciones
	# Y si hacemos un script que agrupe todas estas cositas genericas que varia gente usa?
	if not (ammo_warning_tween and ammo_warning_tween.is_valid()):
		var label_orig_color = %AmmoLabel.get_theme_color("font_color")
		var tween = create_tween()
		var toggle_money_color = func():
			var color = Color.RED if %AmmoLabel.get_theme_color("font_color") == label_orig_color else label_orig_color
			%AmmoLabel.add_theme_color_override("font_color", color)
		tween.tween_callback(toggle_money_color)
		tween.tween_interval(0.5)
		tween.set_loops(6)
		ammo_warning_tween = tween


# Cuando no tiene arma, el tip del joystick de apuntar no debe mostrar el icono de bala
# Tambien se podria tener un controlador diferente para cada tipo de arma, con una variante para cuando no tiene arma ninguna. Pero eso ya es otra cosa
func setup_visibility(value: bool):
	%reload_button.visible = value
	%aim_button.visible = value
	%shoot_button.visible = false
	%AmmoLabel.visible = value
