extends Node2D
class_name Weapon

signal update_ammo(new_ammo: int)
signal bullet_fired(direction: Vector2)
signal reloading
signal aim_mode_changed(value: bool)

const max_ammo = 6

@export var player: Player
@export var cannon: Marker2D
@export var shoot_cooldown: Timer
@export var reload_cooldown: Timer
@export var aim_timer: Timer

var ammo := 3:
	set(value):
		ammo = value
		update_ammo.emit(value)

## Factor de desviación del arma, en radianes.
## La dirección de cada disparo variará aleatoriamente en proporción a esta cantidad
var desviacion : float = PI / 36

var can_shoot := true

var _recharging := false
var reload_graph_angle := 0.0

var aim_offset = 100
var aim_mode := false:
	set(value):
		if value != aim_mode:
			aim_mode = value
			player.camera.position_smoothing_enabled = aim_mode
			aim_mode_changed.emit(aim_mode)
			if !aim_mode:
				player.camera.offset = Vector2.ZERO


func _ready() -> void:
	_on_player_revived() # "Es como si reviviera"
	player.revived.connect(_on_player_revived)


func _process(_delta):
	if not player.local_player:
		return
	
	var aim_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	camera_control(aim_dir)
	
	if can_shoot and ammo > 0 and (
	(not aim_mode and aim_dir.length_squared() > 0.98) or Input.is_action_just_pressed("shoot")):
		shoot.rpc()
		$shoot_cooldown.start()
	
	if Input.is_action_just_pressed("reload") and not _recharging:
		reload.rpc()
	
	if Input.is_action_just_pressed("aim"):
		aim_mode = !aim_mode
	
	if _recharging:
		reload_graph_angle = TAU - TAU * $reload_cooldown.time_left / $reload_cooldown.wait_time
		queue_redraw()


# si el arma soporta accion de apuntar
func camera_control(camera_dir: Vector2):
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir != Vector2.ZERO:
		aim_mode = false
	if aim_mode:
		player.camera.offset = aim_offset * camera_dir


@rpc("any_peer", "call_local")
func shoot():
	if can_shoot and ammo > 0:
		if multiplayer.is_server():
			can_shoot = false
			ammo -= 1
			if ammo == 0:
				reload.rpc()
			# la dirección de tiro se desvía aleatoriamente según
			# el factor de desviación del arma
			var angulo_tiro = Vector2.from_angle(
				player.direction.angle() + \
				randf_range(-desviacion, desviacion)
			)
			bullet_fired.emit(angulo_tiro)
			$shoot_cooldown.start()
		%shot_sound.play()


@rpc("any_peer", "call_local")
func reload():
	# mostar a todo el mundo que esta recargando
	if not _recharging:
		_recharging = true
		can_shoot = false
		reloading.emit()
		$reload_cooldown.start()


func _draw():
	if _recharging:
		draw_arc((Vector2.UP + Vector2.RIGHT) * 20, 3, 0, reload_graph_angle, 10, Color.AQUA, 6, true)


func _on_player_revived():
	ammo = max_ammo
	can_shoot = true
	_recharging = false
	reload_graph_angle = 0.0


func _on_shoot_cooldown_timeout():
	can_shoot = true


func _on_reload_cooldown_timeout():
	_recharging = false
	can_shoot = true
	ammo = max_ammo
	queue_redraw()
