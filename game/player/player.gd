class_name Player extends CharacterBody2D


signal dead(killer_id: int)
signal revived

const player_colors = {
	0: Color.BLUE,
	1: Color.RED,
	2: Color.GREEN,
	3: Color.YELLOW
}

var weapon: Weapon:
	set(new_weapon):
		weapon_prop.value = new_weapon
	get():
		return weapon_prop.value

var weapon_prop := Observable.new(null,
func(new_weapon, _old_weapon):
	if new_weapon:
		if new_weapon.get_parent() == null:
			%hand.add_child(new_weapon)
		else:
			new_weapon.reparent(%hand, false)
, func(new_weapon, old_weapon):
	if old_weapon:
		%hand.remove_child(old_weapon)
		#weapon.queue_free()
	if new_weapon:
		new_weapon.player = self
)

@export var base_speed := 180.0 # 200.0 puede servir como velocidad de caminata, 240 de velocidad de carrera

@export var respawn_timer : Timer

@export var vida_max := 100.0

@export var _lifebar_gradient: Gradient

@export var _camera: Camera2D

@onready var inventario : Inventario = $Inventario

@export var base_glance_distance := 100

var camera_dir: Vector2
var move_dir: Vector2

var glance_mode := Observable.new(false,
func(value):
	if value != glance_mode:
		glance_mode = value
		_camera.position_smoothing_enabled = glance_mode.value
		if !glance_mode.value:
			_camera.offset = Vector2.ZERO
)

var player_id: int
var player_name: String
var player_number: int
var local_player: bool

var speed := base_speed
var vida := vida_max:
	set(value):
		vida = value
		%lifebar.visible = vida < vida_max
		var vida_scaled = remap(vida, 0, vida_max, 0, 1)
		%lifebar.value = vida_scaled
		%lifebar.modulate = _lifebar_gradient.sample(vida_scaled)

var dinero := Observable.new(3000.0)
var direction: Vector2
var alive := true
var shape_radius_approx: float ## Radio aproximado del hitbox. Usado para calculos de precision en las colisiones


func _enter_tree() -> void:
	player_id = name.to_int()
	if player_id == 0: player_id = 1 # debug o single player
	local_player = player_id == multiplayer.get_unique_id()
	%ClientSynchronizer.set_multiplayer_authority(player_id)


func _ready():
	initialize(position)
	var shape_size = $hitbox/shape.shape.get_rect().size
	# (shape_size.x + shape_size.y) / 4
	shape_radius_approx = max(shape_size.x, shape_size.y) / 2
	if local_player:
		%camara.make_current()


func initialize(pos: Vector2):
	alive = true
	vida = vida_max
	visible = true
	position = pos
	rotation = 0.0
	direction = Vector2.from_angle(rotation)
	$shape.set_deferred("disabled", false)
	$hitbox.set_deferred("monitoring", true)
	%AnimationPlayer.play("RESET")
	#$sprite.self_modulate = player_colors[player_number]


@rpc("authority", "call_local")
func revive(pos: Vector2):
	initialize(pos)
	revived.emit()


func control_movement():
	velocity = move_dir.normalized() * speed \
		if move_dir != Vector2.ZERO \
		else Vector2.ZERO


func control_camera():
	if camera_dir != Vector2.ZERO:
		direction = camera_dir
	else: if move_dir != Vector2.ZERO:
		direction = move_dir
	if move_dir != Vector2.ZERO:
		glance_mode.value = false
	if glance_mode.value:
		_camera.offset = base_glance_distance * camera_dir


func animation():
	var dir = camera_dir if camera_dir else move_dir
	# Que la mano tiemble cuando esta disparando
	if camera_dir != Vector2.ZERO:
		%hand.global_rotation = camera_dir.angle()
	else:
		%hand.rotation = 0.0
	# poner scale.x en negativo voltea el nodo horizontalmente junto a todos sus hijos
	# Sin embargo, cuando se cambia el signo de scale.x, lo que hace Godot internamente es cambiar el signo de scale.y y aplicar una rotacion de 180' (que al final termina siendo lo mismo)
	if sign(dir.x) != 0 and sign(dir.x) != sign(scale.y):
			scale.x = -scale.x
	if move_dir != Vector2.ZERO:
		if %AnimationPlayer.assigned_animation == "RESET":
			#%AnimationPlayer.play("walk")
			play_anim_remote.rpc("walk")
	else:
		if %AnimationPlayer.assigned_animation == "walk":
			#%AnimationPlayer.play("RESET")
			play_anim_remote.rpc("RESET")

@rpc("any_peer", "call_local")
func play_anim_remote(anim: String):
	%AnimationPlayer.play(anim)


func _physics_process(_delta):
	if not local_player:
		return
	if not alive:
		return
	# No sera mejor que este camera_dir y este move_dir sean sincronziadas con un Synchronizer y que su efecto se aplique en el servidor?
	# Digamos que mediante Synchronizers, el cliente envia estas dos propiedades (camera_dir, move_dir) y el servidor actualiza el estado de cada player (posicion, rotacion, escala, etc.) y se lo envia a todos los clientes. Eso seria lo más seguro y profesional. Pero qué pasaría 
	#if local_player:
	camera_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	control_camera()
	control_movement()
	animation()
	if Input.is_action_just_pressed("aim"):
		glance_mode.value = !glance_mode.value
	move_and_slide()


@rpc
func public_control():
	control_movement()
	animation()
	move_and_slide()


@rpc("call_local")
func damage(dn: int, inflicter_id: int):
	vida -= dn
	if vida <= 0:
		die(inflicter_id)


#@rpc("call_local")
func die(killer_id: int):
	alive = false
	if multiplayer.is_server():
		dead.emit(killer_id)
	# TODO: animacion de muerte por aqui...
	# Estas lineas en realidad formarian parte de la animacion de muerte
	visible = false
	$shape.set_deferred("disabled", true)
	$hitbox.set_deferred("monitoring", false)
	#respawn_timer.start()


@rpc("authority", "call_local")
func start_respawn_timer():
	respawn_timer.start()


func _on_hitbox_body_entered(body: Node2D):
	if multiplayer.is_server():
		if body is Bullet and body.dist_segura_player(player_id):
			damage.rpc(body.calcular_dano(self), body.shooter_id)


func get_colored_player_name() -> String:
	return "[color={0}]{1}[/color]" \
		.format([player_colors[player_number].to_html(), player_name])
