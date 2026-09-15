extends Node2D

func _ready() -> void:
	$player.weapon = load("res://game/weapon/revolver/revolver.tscn").instantiate()
	$player.weapon.bullet_fired.connect(on_bullet_fired)
	$UI.player = $player


func on_bullet_fired(direction: Vector2):
	var bala = $player.weapon.municion.instantiate()
	bala.position = $player.weapon.cannon.get_global_position()
	bala.shoot(direction, $player)
	add_child(bala)
