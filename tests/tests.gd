extends Node2D

@export_file var arma_inicial_path

func _ready() -> void:
	$player.player_id = 1
	$player2.player_id = 2
	$player.inventario.server_add_item(
		ItemManager.new_item_dto(ResourceUID.uid_to_path(arma_inicial_path)),
		InventarioPlayer.SlotRole.MAIN_WEAPON)
	$player.weapon_prop.connect_init(func(new_weapon, old_weapon):
		if new_weapon:
			new_weapon.bullet_fired.connect(on_bullet_fired)
		if old_weapon:
			old_weapon.bullet_fired.disconnect(on_bullet_fired)
	)
	$UI.player = $player
	$UI.initialize()


func on_bullet_fired(direction: Vector2):
	var weapon = $player.weapon as FireWeapon
	var bala = weapon.slot_municion.item.duplicar_object()
	bala.position = weapon.cannon.get_global_position()
	bala.shoot(direction, $player)
	add_child(bala)
