extends CharacterBody2D
class_name Player


const SPEED = 300.0

@onready var respawn_timer := %respawn_timer
@onready var initpos = position

signal update_ammo(new_ammo: int)
signal bullet_fired
signal reloading
signal shot(shooter: int)

var player_id: int
var player_name: String
var player_number: int
var local_player: bool

var direction: Vector2
var alive := true
var can_shoot := true
var ammo := 3:
	set(value):
		ammo = value
		update_ammo.emit(value)

var _recharging := false
var angle2 := 0.0


func _enter_tree() -> void:
	player_id = name.to_int()
	if player_id == 0: player_id = 1 # debug o single player
	local_player = player_id == multiplayer.get_unique_id()
	set_multiplayer_authority(player_id)
	%ClientSynchronizer.set_multiplayer_authority(player_id)
	%ServerSynchronizer.set_multiplayer_authority(1)


func _ready():
	initialize(position)
	if local_player:
		$camara.make_current()


@rpc("any_peer", "call_local")
func initialize(pos):
	if multiplayer.is_server():
		alive = true
		ammo = 3
		can_shoot = true
	visible = true
	position = pos
	rotation = 0.0
	direction = Vector2.from_angle(rotation)
	_recharging = false
	angle2 = 0.0
	$shape.set_deferred("disabled", false)
	$hitbox.set_deferred("monitoring", true)
	match player_number:
		0: $sprite.self_modulate = Color.BLUE
		1: $sprite.self_modulate = Color.RED
		2: $sprite.self_modulate = Color.GREEN
		3: $sprite.self_modulate = Color.YELLOW


func mode_angle(delta):
	var var_angle = Input.get_axis("turn_left", "turn_right")
	var avz = Input.get_axis("decelerate", "acelerate")
	if var_angle != 0:
		rotation += var_angle * 5 * delta
		direction = Vector2.from_angle(rotation)
	velocity = avz * direction * SPEED


func mode_direction(_delta):
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length_squared() > 0:
		velocity = dir.normalized() * SPEED
		rotation = dir.angle()
		direction = dir
	else:
		velocity = Vector2.ZERO


func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	if not alive:
		return
	mode_direction(delta)
	move_and_slide()


func _input(event):
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("shoot"):
		if alive and can_shoot and ammo > 0:
			shoot.rpc_id(1)
			$shoot_cooldown.start()
	if event.is_action_pressed("reload"):
		reload.rpc()


@rpc("any_peer", "call_local")
func shoot():
	if not multiplayer.is_server():
		return
	if alive and can_shoot and ammo > 0:
		can_shoot = false
		ammo -= 1
		bullet_fired.emit()
		$shoot_cooldown.start()
		%shot_sound.play()


@rpc("any_peer", "call_local")
func reload():
	# mostar a todo el mundo que esta recargando
	_recharging = true
	reloading.emit()
	$reload_cooldown.start()


func _on_hitbox_body_entered(body):
	if not multiplayer.is_server():
		return
	if body is Bullet:
		die.rpc()
		shot.emit(body.shooter_id)


@rpc("any_peer", "call_local")
func die():
	if multiplayer.is_server():
		alive = false
	respawn_timer.start()
	visible = false
	$shape.set_deferred("disabled", true)
	$hitbox.set_deferred("monitoring", false)


func _process(_delta):
	if _recharging:
		angle2 = TAU - TAU * $reload_cooldown.time_left / $reload_cooldown.wait_time
		queue_redraw()


func _draw():
	if _recharging:
		var pos = (Vector2.RIGHT + Vector2.UP) * 20
		draw_arc(pos, 3, 0, angle2, 10, Color.AQUA, 6, true)


func _on_shoot_cooldown_timeout():
	can_shoot = true


func _on_reload_cooldown_timeout():
	_recharging = false
	ammo = 3
	queue_redraw()
