extends Node2D

@export_file var arma_inicial_path
@export var world_items_root: NodePath = "."

var players = {}

func _ready() -> void:
	$player.player_id = 1
	$player2.player_id = 2
	players = {1: $player, 2: $player2}
	ItemManager.register_world_items(get_node(world_items_root))
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
