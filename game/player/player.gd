extends CharacterBody2D
class_name Player


@export var SPEED = 250.0

@export var aim_offset = 100

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
var reload_graph_angle := 0.0

var camera_aim_angle : Vector2
var aim_mode := false: 
	set(value):
		if value != aim_mode:
			aim_mode = value
			%camara.position_smoothing_enabled = aim_mode
			var tween = %camara.create_tween()
			var anim_end = direction * aim_offset if aim_mode else Vector2.ZERO
			tween.tween_property(%camara, "offset", anim_end, 0.2)
		if not aim_mode: camera_aim_angle = Vector2.ZERO


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
		%camara.make_current()
		%camera_timer.timeout.connect(set.bind("aim_mode", true))


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
	reload_graph_angle = 0.0
	$shape.set_deferred("disabled", false)
	$hitbox.set_deferred("monitoring", true)
	match player_number:
		0: $sprite.self_modulate = Color.BLUE
		1: $sprite.self_modulate = Color.RED
		2: $sprite.self_modulate = Color.GREEN
		3: $sprite.self_modulate = Color.YELLOW


func control_movement(move_dir: Vector2, _camera_dir: Vector2):
	velocity = move_dir.normalized() * SPEED \
		if move_dir != Vector2.ZERO \
		else Vector2.ZERO


func control_camera(camera_dir: Vector2, move_dir: Vector2):
	if camera_dir != Vector2.ZERO:
		rotation = camera_dir.angle()
		direction = camera_dir
		if not %camera_timer.is_stopped() and camera_dir.dot(camera_aim_angle) < 0.98:
			%camera_timer.stop()
		if move_dir == Vector2.ZERO and %camera_timer.is_stopped() and not aim_mode:
			%camera_timer.start()
			camera_aim_angle = camera_dir
	else:
		aim_mode = false
		if not %camera_timer.is_stopped():
			%camera_timer.stop()
		if move_dir != Vector2.ZERO:
			rotation = move_dir.angle()
			direction = move_dir
	if move_dir != Vector2.ZERO:
		aim_mode = false
	if aim_mode:
		%camara.offset = direction * aim_offset


func _physics_process(_delta):
	if not is_multiplayer_authority():
		return
	if not alive:
		return
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var camera_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	control_movement(move_dir, camera_dir)
	control_camera(camera_dir, move_dir)
	# is_action_just_pressed para tiro a tiro
	# is_action_pressed para rafaga mientras este siendo presionado
	if Input.is_action_just_pressed("shoot"):
		shoot.rpc_id(1)
		$shoot_cooldown.start()
	if Input.is_action_just_pressed("reload"):
		reload.rpc()
	move_and_slide()


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
		reload_graph_angle = TAU - TAU * $reload_cooldown.time_left / $reload_cooldown.wait_time
		queue_redraw()


func _draw():
	if _recharging:
		var pos = (Vector2.RIGHT + Vector2.UP) * 20
		draw_arc(pos, 3, 0, reload_graph_angle, 10, Color.AQUA, 6, true)


func _on_shoot_cooldown_timeout():
	can_shoot = true


func _on_reload_cooldown_timeout():
	_recharging = false
	ammo = 3
	queue_redraw()
