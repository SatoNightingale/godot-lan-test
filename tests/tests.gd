extends Node2D

@export_file var arma_inicial_path
@export var world_items_root: NodePath = "."

func _ready() -> void:
	$player.player_id = 1
	$player2.player_id = 2
	ItemManager.register_world_items(get_node(world_items_root))
	#$player.inventario.server_add_item(
		#ItemManager.new_item_dto(ResourceUID.uid_to_path(arma_inicial_path)), InventarioPlayer.MAIN_WEAPON)
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
	var bala = weapon.get_nuevo_proyectil()
	bala.position = weapon.cannon.get_global_position()
	bala.shoot(direction, $player)
	add_child(bala)


@rpc("any_peer", "call_local")
func on_player_pickup_item(item_id):
	if multiplayer.is_server():
		var world_item = ItemManager.get_world_item(item_id)
		if world_item.is_on_pickup_distance($player):
			if $player.inventario.add_new_item_to_bag(world_item.item):
				ItemManager.remove_world_item.rpc(world_item.get_path())
