class_name FireWeapon extends Weapon


signal update_ammo(loaded_ammo: int, total_ammo: int)
signal bullet_fired(direction: Vector2)
signal reloading
signal no_ammo
#signal wrong_ammo

var ammo_slot: Slot: set = set_ammo_slot
var clase_municion_path: String
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

## Dos modelos de recarga: o que el arma "eche pa dentro" max_ammo balas cada vez que recargue, quitandoselas de una vez al inventario; o que se las vaya quitando una a una a medida que dispare. En el primer modelo, total_ammo y ammo tendrian mucho mas sentido como propiedades, pero seria dificil rastrear el item de proyectil "echado pa dentro". En el segundo modelo se conoce el item del proyectil y por ejemplo, al vender el arma no se vende con todas sus balas; pero entonces total_ammo y ammo son propiedades meramente reguladoras y de frontend

var shoot_semaphore := SignalSemaphore.new()

var recharging := false

## WARNING Caso hipotetico: el jugador dropea la pistola, que se queda con su cantidad de balas (ammo) guardada como dto. Lo coge otro player que no tiene balas equipadas en su ranura. Se le carga la cantidad de balas del player, podria disparar?

var total_ammo := 0
var ammo := 0

func set_ammo_slot(value: Slot):
	if ammo_slot:
		ammo_slot.item_prop.desconectar(new_ammo_update)
	ammo_slot = value
	if ammo_slot:
		ammo_slot.item_prop.connect_init(new_ammo_update)

func new_ammo_update(new_ammo: Item, _old_ammo):
	if new_ammo:
		total_ammo = new_ammo.cantidad
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
				if check_ammo():
					shoot.rpc_id(1)
			else:
				no_ammo.emit()
	
	if Input.is_action_just_pressed("reload") and not recharging:
		if check_ammo():
			reload.rpc_id(1)

#region disparar
@rpc("any_peer", "call_local")
func shoot():
	if multiplayer.is_server():
		#print(shoot_semaphore.disponible(), " ", ammo > 0, " ", check_ammo(true))
		if shoot_semaphore.disponible() and ammo > 0 and check_ammo(true):
			#print("conditionals met")
			shoot_semaphore.adquirir_timer($shoot_timer)
			# la dirección de tiro se desvía aleatoriamente según el factor de dispersión del arma
			var desv = deg_to_rad(desviacion)
			var angulo_tiro = Vector2.from_angle(
				player.direction.angle() + \
				randf_range(-desv, +desv)
			)
			bullet_fired.emit(angulo_tiro)
			player.inventario.server_take_item(ammo_slot.slot_id, 1)
			ammo -= 1
			$shoot_timer.start()
			shoot_local.rpc()
			shoot_public.rpc()

@rpc("authority", "call_local")
func shoot_local():
	if player.local_player and player.player_id != 1:
		shoot_semaphore.adquirir_timer($shoot_timer)
		$shoot_timer.start()
		ammo -= 1
		update_ammo.emit(ammo, total_ammo)

@rpc("authority", "call_local")
func shoot_public():
	%shot_sound.play()
#endregion

#region recargar
@rpc("any_peer", "call_local")
func reload():
	if multiplayer.is_server():
		if not recharging and ammo_slot.item:
			reload_local.rpc()
			reload_public.rpc()

@rpc("authority", "call_local")
func reload_local():
	if player.local_player:
		recharging = true
		shoot_semaphore.adquirir_timer($reload_timer)
		reloading.emit()

@rpc("authority", "call_local")
func reload_public():
	$reload_timer.start()
	$reload_pie.show()
	$reload_pie.value = 0
	var tween = create_tween()
	tween.tween_property($reload_pie, "value", 100, $reload_timer.wait_time)
	tween.tween_callback($reload_pie.hide)

func _on_reload_timer_timeout():
	#print("reload timer timeout: ", ammo_slot.item, " ", ammo_slot.item.cantidad, " ", max_ammo)
	if player.local_player or multiplayer.is_server():
		if ammo_slot.item:
			if ammo_slot.item.cantidad < max_ammo:
				ammo = ammo_slot.item.cantidad
				total_ammo = 0
			else:
				ammo = max_ammo
				total_ammo = ammo_slot.item.cantidad - max_ammo
		else:
			ammo = 0
			total_ammo = 0
			no_ammo.emit()
		recharging = false
	if player.local_player:
		update_ammo.emit(ammo, total_ammo)

#endregion


func get_nuevo_proyectil() -> Node:
	return ammo_slot.item.duplicar_object()


func check_ammo(server_mode := false) -> bool:
	#print(ammo_slot.item.nombre)
	#print(clase_municion_path, " - ", ammo_slot.item.item_type_path)
	if ammo_slot.item != null:
		if ammo_slot.item.item_type_path == clase_municion_path:
			return true
	else: if not server_mode:
		no_ammo.emit()
	return false


func _on_player_revived():
	shoot_semaphore.liberar()
	recharging = false
