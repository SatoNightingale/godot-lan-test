extends CharacterBody2D
class_name Player


#signal shot(shooter: int)
signal dead(killer_id: int)
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
		if weapon.get_parent() == null:
			add_child(new_weapon)
		weapon = new_weapon

@export var respawn_timer : Timer

var vida := 100.0

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
	alive = true
	vida = 100.0
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


@rpc("call_local")
func damage(dn: int, inflicter_id: int):
	vida -= dn
	
	if vida <= 0:
		die(inflicter_id)


#@rpc("call_local")
func die(killer_id: int):
	alive = false
	dead.emit(killer_id)
	# animacion de muerte por aqui...
	visible = false
	$shape.set_deferred("disabled", true)
	$hitbox.set_deferred("monitoring", false)
	respawn_timer.start()


func _on_hitbox_body_entered(body: Node2D):
	if not multiplayer.is_server():
		return
	if body is Bullet:
		damage.rpc(body.calcular_dano(self), body.shooter_id)
		#shot.emit(body.shooter_id)


func get_colored_player_name() -> String:
	return "[color={0}]{1}[/color]" \
		.format([player_colors[player_number].to_html(), player_name])
