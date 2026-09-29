class_name FireWeapon extends Weapon


signal update_ammo(new_ammo: int)
signal bullet_fired(direction: Vector2)
signal reloading

## Escena que contiene el tipo de municion que usa el arma
## (item, ahora)
@export var municion: PackedScene = preload("res://game/bullet/bullet.tscn")
## Marcador para la posicion desde donde las balas son disparadas
@export var cannon: Marker2D
## Municion maxima del arma
@export var max_ammo : int
## Si el arma es automatica o no. Si es automatica, dispara mientras este presionada la accion de disparar; si no lo es solo dispara una vez cuando se presiona la accion
@export var automatica : bool
## Alcance de bala del arma
@export var alcance := 700
## Factor de desviación del arma, en grados.
## La dirección de cada disparo variará aleatoriamente en proporción a esta cantidad
@export var desviacion: float = 5.0
## Tiempo entre disparos
@export var shoot_cooldown: float = 0.6
## Tiempo que demora recargando
@export var reload_cooldown: float = 3.0
## Multiplicador de la velocidad del player cuando esta recargando
@export var reloading_slowdown = 0.8
## Distancia de apuntado del arma. Si es mayor que cero, sobreescribe la distancia de vistazo del player con este valor, haciendo posible mirar a una mayor longitud
@export var aim_distance := 0


var ammo = max_ammo:
	set(value):
		ammo = value
		update_ammo.emit(value)

var shoot_semaphore := SignalSemaphore.new()

var recharging := false


func set_player(value: Player):
	super.set_player(value)
	reloading.connect(aplicar_ralentizacion.bind(
		reloading_slowdown, reload_cooldown))
	if aim_distance != 0: # si el arma apunta
		player.base_glance_distance = aim_distance
	_on_player_revived()
	player.revived.connect(_on_player_revived)


func _ready() -> void:
	super._ready()
	bullet_fired.connect(wielded.emit)
	$shoot_timer.wait_time = shoot_cooldown
	$reload_timer.wait_time = reload_cooldown


func _process(_delta):
	if player == null:
		return
	
	$sprite.flip_v = abs(global_rotation) > PI / 2
	
	if not player.local_player:
		return
	
	var camera_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if shoot_semaphore.disponible() and ammo > 0 and (
	(not player.glance_mode and camera_dir.length_squared() > 0.98)
	or (automatica and Input.is_action_pressed("shoot"))
	or (not automatica and Input.is_action_just_pressed("shoot"))
	):
		request_shoot.rpc_id(1)
	
	if Input.is_action_just_pressed("reload") and not recharging:
		request_reload.rpc_id(1)


@rpc("any_peer", "call_local")
func request_shoot():
	if multiplayer.is_server():
		if shoot_semaphore.disponible() and ammo > 0:
			shoot.rpc()

@rpc("any_peer", "call_local")
func request_reload():
	if multiplayer.is_server():
		if not recharging:
			reload.rpc()

@rpc("authority", "call_local")
func shoot():
	shoot_semaphore.adquirir_timer($shoot_timer)
	ammo -= 1
	# la dirección de tiro se desvía aleatoriamente según
	# el factor de desviación del arma
	var desv = deg_to_rad(desviacion)
	var angulo_tiro = Vector2.from_angle(
		player.direction.angle() + \
		randf_range(-desv, desv)
	)
	if multiplayer.is_server():
		bullet_fired.emit(angulo_tiro)
	$shoot_timer.start()
	if ammo == 0:
		reload()
	%shot_sound.play()


@rpc("authority", "call_local")
func reload():
	recharging = true
	shoot_semaphore.adquirir_timer($reload_timer)
	reloading.emit()
	$reload_timer.start()
	$reload_pie.show()
	$reload_pie.value = 0
	var tween = create_tween()
	tween.tween_property($reload_pie, "value", 100, $reload_timer.wait_time)
	tween.tween_callback($reload_pie.hide)


func _on_player_revived():
	ammo = max_ammo
	shoot_semaphore.liberar()
	recharging = false


func _on_reload_timer_timeout():
	recharging = false
	ammo = max_ammo
