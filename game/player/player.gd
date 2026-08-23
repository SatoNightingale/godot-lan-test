extends CharacterBody2D
class_name Player


signal shot(shooter: int)
signal weapon_changed(new_weapon: Weapon)
signal revived

const player_colors = {
	0: Color.BLUE,
	1: Color.RED,
	2: Color.GREEN,
	3: Color.YELLOW
}

@export var speed = 250.0

@export var camera: Camera2D

@export var weapon: Weapon:
	set(new_weapon):
		if weapon:
			remove_child(weapon)
			weapon.queue_free()
		new_weapon.player = self
		weapon_changed.emit(new_weapon)
		#add_child(new_weapon)
		weapon = new_weapon

@export var respawn_timer : Timer

## TODO: vida para la gente, que las balas tengan daño

var player_id: int
var player_name: String
var player_number: int
var local_player: bool

var direction: Vector2
var alive := true


func _enter_tree() -> void:
	player_id = name.to_int()
	if player_id == 0: player_id = 1 # debug o single player
	local_player = player_id == multiplayer.get_unique_id()
	%ClientSynchronizer.set_multiplayer_authority(player_id)


func _ready():
	initialize(position)
	if local_player:
		%camara.make_current()


func initialize(pos: Vector2):
	if multiplayer.is_server():
		alive = true
	visible = true
	position = pos
	rotation = 0.0
	direction = Vector2.from_angle(rotation)
	$shape.set_deferred("disabled", false)
	$hitbox.set_deferred("monitoring", true)
	$sprite.self_modulate = player_colors[player_number]


@rpc("call_local")
func revive(pos: Vector2):
	initialize(pos)
	revived.emit()


func control_movement(move_dir: Vector2):
	velocity = move_dir.normalized() * speed \
		if move_dir != Vector2.ZERO \
		else Vector2.ZERO


func control_camera(camera_dir: Vector2, move_dir: Vector2):
	if camera_dir != Vector2.ZERO:
		rotation = camera_dir.angle()
		direction = camera_dir
	else: if move_dir != Vector2.ZERO:
			rotation = move_dir.angle()
			direction = move_dir


func _physics_process(_delta):
	if not local_player: # %ClientSynchronizer.is_multiplayer_authority():
		return
	if not alive:
		return
	var camera_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	control_movement(move_dir)
	control_camera(camera_dir, move_dir)
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D):
	if not multiplayer.is_server():
		return
	if body is Bullet:
		# el producto punto (angulo) entre la direccion en la que iba la bala y la direccion que tomaria hacia el centro del personaje
		# Cuanto mas pequeño sea este angulo, más directamente estará proyectada la bala contra el personaje y por consiguiente más daño le hará
		var bullet_dir = body.linear_velocity.normalized()
		var to_target = body.global_position.direction_to(global_position)
		bullet_dir.dot(to_target)
		die.rpc()
		shot.emit(body.shooter_id)


@rpc("call_local")
func die():
	if multiplayer.is_server():
		alive = false
	respawn_timer.start()
	visible = false
	$shape.set_deferred("disabled", true)
	$hitbox.set_deferred("monitoring", false)


func get_colored_player_name() -> String:
	return "[color={0}]{1}[/color]" \
		.format([player_colors[player_number].to_html(), player_name])
