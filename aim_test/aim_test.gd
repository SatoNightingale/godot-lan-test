extends Node2D

var bullet_scene = preload("res://game/bullet/bullet.tscn")

func _ready() -> void:
	$UI.configure_ui($player)
	$player.weapon.bullet_fired.connect(on_bullet_fired)


func on_bullet_fired():
	var bala = bullet_scene.instantiate()
	bala.position = $player.weapon.cannon.get_global_position()
	bala.shoot($player.direction, $player.player_id)
	add_child(bala)
