extends Node2D

func _ready() -> void:
	# res://game/weapon/revolver.tscn
	var weapon = load("res://game/weapon/mp5/mp5.tscn").instantiate()
	$player.weapon = weapon
	$player.weapon.bullet_fired.connect(on_bullet_fired)
	$UI.configure_ui($player)


func on_bullet_fired(direction: Vector2):
	var bala = $player.weapon.municion.instantiate()
	bala.position = $player.weapon.cannon.get_global_position()
	bala.shoot(direction, $player)
	add_child(bala)
