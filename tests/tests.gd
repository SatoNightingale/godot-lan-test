extends Node2D

func _ready() -> void:
	#var item = Item.new_from_dto({
		#"type_id": "res://items/classes/colt_item.tres",
		#"id": 1
	#})
	#print(item)
	$player.player_id = 1
	$player2.player_id = 2
	$player.inventario.server_add_item(
		ItemManager.new_item_dto("res://items/classes/colt_item.tres"), Inventario.SlotRole.MAIN_WEAPON)
	#$player.weapon = load("res://game/weapon/revolver/revolver.tscn").instantiate()
	$player.weapon_prop.connect_init(func(new_weapon):
		if new_weapon:
			new_weapon.bullet_fired.connect(on_bullet_fired)
	)
	#$UI.player = $player
	#var player: Player = get_node("player")
	#var dict = {1: player}
	$UI.tienda.inventarios[1] = $player.inventario
	$UI.tienda.inventario = $player.inventario


func on_bullet_fired(direction: Vector2):
	var bala = $player.weapon.municion.instantiate()
	bala.position = $player.weapon.cannon.get_global_position()
	bala.shoot(direction, $player)
	add_child(bala)
