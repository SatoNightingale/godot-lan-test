extends RigidBody2D
class_name Bullet

var impulso = 1500
var max_distancia = 700

var recorrido = 0
#const tiempo_fogonazo = 25 # para que los neñes no se mueran por sus propios tiros al ser disparados, pero que aun así sus tiros los puedan matar si de alguna forma se implementan mecánicas como rebote de bala o algo parecido
var shooter_id: int
var base_damage := 100.0
	

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	recorrido += delta * linear_velocity.length()
	queue_redraw()
	if recorrido >= max_distancia:
		queue_free()


func shoot(direction, who: int):
	shooter_id = who
	apply_central_impulse(direction * impulso)


func calcular_dano(player: Player) -> float:
	# el producto punto (angulo) entre la direccion en la que iba la bala y la direccion que tomaria hacia el centro del personaje
	# Cuanto mas pequeño sea este angulo, más directamente estará proyectada la bala contra el personaje y por consiguiente más daño le hará
	var bullet_dir = linear_velocity.normalized()
	var to_target = global_position.direction_to(player.global_position)
	# si el angulo es de 90 grados, el daño se reduce a la mitad
	# si el angulo es de 0 grados, se hace el daño completo
	# el angulo se convierte en daño en funcion del coseno de cita, entre ambos extremos
	var bullet_angle = 0.5 + bullet_dir.dot(to_target) / 2
	# El tiempo de recorrido de la bala disminuye el daño recibido
	# Con 0 recorrido, hará el daño completo. Con todo el recorrido, hará la mitad del daño
	var recorrido_multiplier = 1.0 - recorrido / (max_distancia * 2)
	return base_damage * recorrido_multiplier * bullet_angle


func _on_body_entered(_body: Node) -> void:
	queue_free()
