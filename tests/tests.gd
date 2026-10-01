extends Node2D


func _ready() -> void:
	$player.player_id = 1
	$player2.player_id = 2
	$player.inventario.server_add_item(
		ItemManager.new_item_dto("res://items/classes/colt_item.tres"), Inventario.SlotRole.MAIN_WEAPON)
	#$player.weapon = load("res://game/weapon/revolver/revolver.tscn").instantiate()
	$player.weapon_prop.connect_init(func(new_weapon):
		if new_weapon:
			new_weapon.bullet_fired.connect(on_bullet_fired)
	)
	$UI.overlay_inventario.inventory_front.tienda.init_inventarios(
		{1: $player}
	)
	$UI.initialize()


func on_bullet_fired(direction: Vector2):
	var bala = $player.weapon.municion.instantiate()
	bala.position = $player.weapon.cannon.get_global_position()
	bala.shoot(direction, $player)
	add_child(bala)
