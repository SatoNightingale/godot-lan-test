extends Node2D
class_name Weapon

signal update_ammo(new_ammo: int)
signal bullet_fired
signal reloading

@export var cannon : Marker2D
@export var shoot_cooldown : Timer
@export var reload_cooldown : Timer
@export var aim_timer : Timer

var aim_offset = 100
var can_shoot := true
var ammo := 3:
	set(value):
		ammo = value
		update_ammo.emit(value)

var _recharging := false
var reload_graph_angle := 0.0


func process():
	if Input.is_action_just_pressed("shoot"):
		shoot.rpc_id(1)
		#$shoot_cooldown.start()
	if Input.is_action_just_pressed("reload"):
		reload.rpc()


@rpc("any_peer", "call_local")
func shoot():
	if can_shoot and ammo > 0:
		if multiplayer.is_server():
			can_shoot = false
			ammo -= 1
			bullet_fired.emit()
			$shoot_cooldown.start()
		%shot_sound.play()


@rpc("any_peer", "call_local")
func reload():
	# mostar a todo el mundo que esta recargando
	_recharging = true
	#var tween = create_tween()
	#tween.tween_property(self, "reload_graph_angle", TAU, 3.0)
	#tween.tween_callback(set.bind("_recharging", false))
	reloading.emit()
	$reload_cooldown.start()


func _ready() -> void:
	ammo = 3
	can_shoot = true
	_recharging = false
	reload_graph_angle = 0.0


func _process(_delta):
	if _recharging:
		reload_graph_angle = TAU - TAU * $reload_cooldown.time_left / $reload_cooldown.wait_time
		queue_redraw()


func _draw():
	if _recharging:
		draw_arc((Vector2.UP + Vector2.RIGHT) * 20, 3, 0, reload_graph_angle, 10, Color.AQUA, 6, true)


func _on_shoot_cooldown_timeout():
	can_shoot = true


func _on_reload_cooldown_timeout():
	_recharging = false
	ammo = 3
	queue_redraw()
