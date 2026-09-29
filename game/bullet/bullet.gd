class_name Bullet extends RigidBody2D

## SE SUPONE que el padre de las balas siempre es un nodo anclado al origen (0; 0), que puede fungir como "global"

const dist_quemarropa = 50

@export var sprite : Texture2D:
	set(value):
		sprite = value
		$Sprite2D.texture = sprite
@export var impulso := 1500.0
@export var curva_dano: Curve
@export_category("Trail")
@export var trail_length := 30
@export var trail_width := 2
@export var trail_color: Color = Color("ffc24d")

var max_alcance := 700.0
var base_damage := 100.0

var pos_emisor: Vector2 # hay que actualizar esto cada vez que haya un rebote o cambio de direccion brusco de la bala

var recorrido := 0.0
var shooter_id: int


func _ready() -> void:
	$trail.width = trail_width
	$trail.default_color = trail_color
	$trail.add_point(Vector2.ZERO)
	$trail.add_point(Vector2.ZERO)


func _physics_process(delta):
	recorrido += delta * linear_velocity.length()
	$trail.set_point_position(1, Vector2.LEFT * min(recorrido, trail_length))
	#if recorrido <= trail_length:
		#$trail.set_point_position(1, Vector2.LEFT * recorrido)
	if is_multiplayer_authority() and recorrido >= max_alcance:
		queue_free()


func shoot(direction: Vector2, who: Player):
	shooter_id = who.player_id
	var arma = who.weapon as FireWeapon
	max_alcance = arma.alcance
	base_damage = arma.damage
	pos_emisor = arma.cannon.global_position
	rotation = direction.angle()
	apply_central_impulse(direction * impulso)


# El tiempo de recorrido de la bala disminuye el daño recibido
# Con 0 recorrido (a quemarropa) hará el doble del daño. Con todo el recorrido, hará la mitad del daño
func modif_recorrido(x) -> float:
	# Se podría usar un objeto Curve para hacer esto más fácil, pero entonces la distancia de quemarropa sería relativa a, por ejemplo, un 0.25 del alcance de la bala
	const p := 3 # suavizado de la curva
	var Fb = 1.0 - 0.5 * (x / max_alcance) ** p # función de daño base
	var boost: float # función del daño de quemarropa
	const d = 10 # radio de decrecimiento de la meseta de quemarropa
	# límites izquierdo y derecho del descenso de la meseta de quemarropa
	var L = max(0, dist_quemarropa - d)
	var R = dist_quemarropa + d
	if x <= L: # antes de la distancia de quemarropa - d, todo el daño
		boost = 1.0
	else: if x >= R: # después de la distancia de quemarropa + d, no hay daño extra
		boost = 0.0
	else: # si está en la zona de decrecimiento del daño de quemarropa, el daño extra se calcula así
		var t = (x - L) / (R - L) # avance en la "cuesta"
		boost = 1 - (3 * t**2 - 2 * t**3)
	return Fb + boost


func calcular_dano(player: Player) -> float:
	# El angulo (desde el player impactado) que hace la linea desde el centro hacia el impacto de la bala con la linea recta al disparador
	var linea_recta = player.global_position.direction_to(pos_emisor)
	var dir_impacto = player.global_position.direction_to(global_position)
	# 0 <= angulo <= 90
	# 0 -> 1, 90 -> 0
	var factor_desviacion = abs(cos(linea_recta.angle_to(dir_impacto)))
	var mod_angulo = 0.5 + factor_desviacion / 2
	## El daño de bala disminuye según lo lejos que impactó la bala del centro del personaje. La distancia del impacto al centro se calcula según la tangente del angulo de tiro (cateto opuesto / cateto adyacente = distancia de impacto / longitud de la linea al centro del player). La relación entre esta distancia y el radio (aproximado por exceso) del hitbox del player da la tasa de desviación. Un disparo perfectamente centrado tendrá una tasa de desviación de 0
	#var bullet_dir = pos_emisor.direction_to(global_position)
	#var linea_recta = pos_emisor.direction_to(player.global_position)
	## cateto adyacente
	#var dist_linea_recta = pos_emisor.distance_to(player.global_position)
	## cateto opuesto
	#var dist_to_center = abs(tan(linea_recta.angle_to(bullet_dir))) * dist_linea_recta
	### Y esta talla no es mas facil y directa?
	###var dist_to_center = global_position.distance_to(player.global_position)
	#var tasa_desviacion = dist_to_center / player.shape_radius_approx
	##print("dist_to_center: ", dist_to_center, ", tasa desv: ", tasa_desviacion)
	## La tasa de desviacion disminuye el resultado final típicamente hasta el 50%, pero pueden darse casos donde esta sea mayor que 1 (anomalías de cálculo), lo cual reduciría aún más el daño del tiro, pero nunca por debajo de 0
	#var mod_angulo = 0.5 + max(1 - tasa_desviacion, 0) / 2
	
	var mod_recorrido = modif_recorrido(recorrido)
	#var mod_recorrido = curva_dano.sample(recorrido / max_alcance)
	print("> base: ", base_damage, ", recorrido: ", mod_recorrido, ", angulo: ", mod_angulo, " -> total: ", base_damage * mod_recorrido * mod_angulo)
	return base_damage * mod_recorrido * mod_angulo


func _on_body_entered(_body: Node) -> void:
	if is_multiplayer_authority():
		queue_free()
