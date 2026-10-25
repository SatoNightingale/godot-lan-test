class_name FireWeapon extends Weapon


signal update_ammo(loaded_ammo: int, total_ammo: int)
signal bullet_fired(direction: Vector2)
signal reloading
signal no_ammo

var slot_municion: Slot: set = set_slot_municion
#@export var municion: PackedScene = preload("res://game/bullet/bullet.tscn")
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

## Dos modelos de recarga: o que el arma "eche pa dentro" max_ammo balas cada vez que recargue, quitandoselas de una vez al inventario; o que se las vaya quitando una a una a medida que dispare. En el primer modelo, total_ammo y ammo tendrian mucho mas sentido como propiedades, pero seria dificil rastrear el item de proyectil "echado pa dentro". En el segundo modelo se conoce el item del proyectil y por ejemplo, al vender el arma no se vende con todas sus balas; pero entonces total_ammo y ammo son propiedades meramente frontend

var shoot_semaphore := SignalSemaphore.new()

var recharging := false

## WARNING Caso hipotetico: el jugador dropea la pistola, que se queda con su cantidad de balas (ammo) guardada como dto. Lo coge otro player que no tiene balas equipadas en su ranura. Se le carga la cantidad de balas del player, podria disparar?

func set_slot_municion(value: Slot):
	if slot_municion:
		slot_municion.item_prop.desconectar(new_ammo_update)
	slot_municion = value
	if slot_municion:
		slot_municion.item_prop.connect_init(new_ammo_update)

func new_ammo_update(new_ammo: Item, _old_ammo):
	if new_ammo:
		total_ammo = new_ammo.cantidad

var total_ammo := 0:
	set(value):
		total_ammo = value
		update_ammo.emit(ammo, total_ammo)

var ammo := 0:
	set(value):
		ammo = value
		update_ammo.emit(ammo, total_ammo)


func set_player(new_player: Player):
	if new_player:
		_on_player_revived()
		new_player.revived.connect(_on_player_revived)
	else:
		player.revived.disconnect(_on_player_revived)
	player = new_player


func _ready() -> void:
	super._ready()
	bullet_fired.connect(wielded.emit)
	reloading.connect(aplicar_ralentizacion.bind(
		reloading_slowdown, reload_cooldown))
	$shoot_timer.wait_time = shoot_cooldown
	$reload_timer.wait_time = reload_cooldown


func _process(_delta):
	if player == null:
		return
	
	if not player.local_player:
		return
	
	var camera_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if (automatica and Input.is_action_pressed("shoot")) \
	or (not automatica and Input.is_action_just_pressed("shoot")) \
	or (not player.glance_mode.value and camera_dir.length_squared() > 0.98):
		if shoot_semaphore.disponible():
			if ammo > 0:
				shoot.rpc_id(1)
			else:
				no_ammo.emit()
	
	if Input.is_action_just_pressed("reload") and not recharging:
		reload.rpc_id(1)


@rpc("any_peer", "call_local")
func shoot():
	if multiplayer.is_server():
		if shoot_semaphore.disponible() and ammo > 0:
			shoot_semaphore.adquirir_timer($shoot_timer)
			# la dirección de tiro se desvía aleatoriamente según el factor de dispersión del arma
			var desv = deg_to_rad(desviacion)
			var angulo_tiro = Vector2.from_angle(
				player.direction.angle() + \
				randf_range(-desv, +desv)
			)
			bullet_fired.emit(angulo_tiro)
			player.inventario.server_take_item(slot_municion.slot_id, 1)
			ammo -= 1
			if ammo == 0:
				reload()
			$shoot_timer.start()
			shoot_client.rpc()


@rpc("any_peer", "call_local")
func reload():
	if multiplayer.is_server():
		if not recharging and slot_municion.item:
			reload_client.rpc()


@rpc("authority", "call_local")
func shoot_client():
	if player.local_player and player.player_id != 1:
		shoot_semaphore.adquirir_timer($shoot_timer)
		$shoot_timer.start()
	%shot_sound.play()


@rpc("authority", "call_local")
func reload_client():
	recharging = true
	shoot_semaphore.adquirir_timer($reload_timer)
	reloading.emit()
	$reload_timer.start()
	$reload_pie.show()
	$reload_pie.value = 0
	var tween = create_tween()
	tween.tween_property($reload_pie, "value", 100, $reload_timer.wait_time)
	tween.tween_callback($reload_pie.hide)


func get_nuevo_proyectil() -> Node:
	return slot_municion.item.duplicar_object()


func _on_player_revived():
	#ammo = max_ammo
	shoot_semaphore.liberar()
	recharging = false


func _on_reload_timer_timeout():
	if slot_municion.item:
		if slot_municion.item.cantidad < max_ammo:
			ammo = slot_municion.item.cantidad
			total_ammo = 0
		else:
			ammo = max_ammo
			total_ammo = slot_municion.item.cantidad - max_ammo
	else:
		ammo = 0
		total_ammo = 0
		no_ammo.emit()
	recharging = false
