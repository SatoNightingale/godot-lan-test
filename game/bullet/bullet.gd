extends RigidBody2D
class_name Bullet

const speed = 1500

var recorrido
const max_recorrido = 700
#const tiempo_fogonazo = 25 # para que los neñes no se mueran por sus propios tiros al ser disparados, pero que aun así sus tiros los puedan matar si de alguna forma se implementan mecánicas como rebote de bala o algo parecido
var shooter_id: int

func _ready():
	recorrido = 0

#func _on_body_entered(body):
	#pass
	##if body is Player:
		##queue_free()

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	recorrido += delta * linear_velocity.length()
	if recorrido >= max_recorrido or get_contact_count() != 0:
		queue_free()


func shoot(direction, who: int):
	shooter_id = who
	apply_central_impulse(direction * speed)
