class_name Player extends CharacterBody2D

# TODO: Para no poner una señal _changed para cada propiedad que debe ser observada, sería bueno crear una clase observable que se ocupe de esto (similar a una Property)
signal weapon_changed(new_weapon: Weapon)
signal dead(killer_id: int)
signal revived
signal glance_mode_changed(value: bool)

const player_colors = {
	0: Color.BLUE,
	1: Color.RED,
	2: Color.GREEN,
	3: Color.YELLOW
}

@export var weapon: Weapon:
	set(new_weapon):
		if weapon:
			remove_child(weapon)
			#weapon.queue_free()
		weapon = new_weapon
		if new_weapon:
			new_weapon.player = self
			weapon_changed.emit(new_weapon)
			if new_weapon.get_parent() == null:
				add_child(new_weapon)
			else:
				new_weapon.reparent(self, false)

@export var base_speed := 250.0 # 200.0 puede servir como velocidad de caminata

@export var respawn_timer : Timer

@export var vida_max := 100.0

@export var base_glance_distance := 100

@export var _lifebar_gradient: Gradient

@export var _camera: Camera2D

var glance_mode := false:
	set(value):
		if value != glance_mode:
			glance_mode = value
			_camera.position_smoothing_enabled = glance_mode
			glance_mode_changed.emit(glance_mode)
			if !glance_mode:
				_camera.offset = Vector2.ZERO

var player_id: int
var player_name: String
var player_number: int
var local_player: bool

var speed := base_speed
var vida := vida_max:
	set(value):
		vida = value
		queue_redraw()
var dinero := Observable.new(3000.0)
var direction: Vector2
var alive := true

var weapon_item := Observable.new(null,
func(new_item): # former name: new_weapon
	if not multiplayer.is_server():
		return
	if new_item:
		if new_item.object is Weapon:
			if weapon != null:
				weapon.queue_free()
			weapon = new_item.object
		else:
			printerr("El item pasado como weapon_item no contiene una Weapon")
	else:
		weapon = null
)

@rpc("authority", "call_local")
func change_weapon_item(weapon_item_id: int):
	# weapon_item_id debe ser un id a la posicion en el inventario...
	# nope, porque no todo el mundo va a tener ese objeto. Tampoco es
	# algo que se pueda transferir por la red
	pass

var inventario: Array[Item]


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
	vida = vida_max
	visible = true
	position = pos
	rotation = 0.0
	direction = Vector2.from_angle(rotation)
	$shape.set_deferred("disabled", false)
	$hitbox.set_deferred("monitoring", true)
	$sprite.self_modulate = player_colors[player_number]


@rpc("authority", "call_local")
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
	else:
		if move_dir != Vector2.ZERO:
			rotation = move_dir.angle()
			direction = move_dir
	if move_dir != Vector2.ZERO:
		glance_mode = false
	if glance_mode:
		_camera.offset = base_glance_distance * camera_dir


func _physics_process(_delta):
	if not local_player:
		return
	if not alive:
		return
	var camera_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	control_movement(move_dir)
	control_camera(camera_dir, move_dir)
	if Input.is_action_just_pressed("aim"):
		glance_mode = !glance_mode
	move_and_slide()


func _draw() -> void:
	if vida < vida_max:
		var vida_scale = remap(vida, 0, vida_max, 0, 1)
		var bar_start = Vector2(-15, -30)
		var bar_end = bar_start + Vector2.RIGHT * vida / 100 * 40
		var bar_color = _lifebar_gradient.sample(vida_scale)
		draw_line(bar_start, bar_end, bar_color, 4)


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
	# animacion de muerte por aqui...
	visible = false
	$shape.set_deferred("disabled", true)
	$hitbox.set_deferred("monitoring", false)
	#respawn_timer.start()


@rpc("authority")
func start_respawn_timer():
	respawn_timer.start()


func _on_hitbox_body_entered(body: Node2D):
	if multiplayer.is_server():
		if body is Bullet:
			damage.rpc(body.calcular_dano(self), body.shooter_id)


func get_colored_player_name() -> String:
	return "[color={0}]{1}[/color]" \
		.format([player_colors[player_number].to_html(), player_name])


#TODO Se viene script de inventario para encapsular todas estas weas
# add_item puede hacer algo distinto que add_weapon si solamente añade el item al inventario, sin setear el arma.
# Podrian tenerse mas armas que la activa
func add_item(item: Item):
	inventario.append(item)
	if item.object is Weapon:
		weapon_item.value = item
		#weapon.queue_free()
		#weapon = item.object

func get_item(id: int) -> Item:
	for it in inventario:
		if it.id == id:
			return it
	return null

func has_item(id: int) -> bool:
	return get_item(id) != null

func take_item(id: int):
	var i = 0
	for item in inventario:
		if item.id == id:
			inventario.remove_at(i)
			break
		i += 1
	# si esta equipado, desequiparlo
	if weapon_item.value != null:
		if id == weapon_item.value.id:
			weapon_item.value = null
