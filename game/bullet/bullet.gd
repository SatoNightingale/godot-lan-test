extends RigidBody2D
class_name Bullet

const speed = 1500

var recorrido
const max_recorrido = 700
#const tiempo_fogonazo = 25 # para que los neñes no se mueran por sus propios tiros al ser disparados, pero que aun así sus tiros los puedan matar si de alguna forma se implementan mecánicas como rebote de bala o algo parecido
var shooter_id: int

#var target: Player

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
	queue_redraw()
	if recorrido >= max_recorrido or get_contact_count() != 0:
		queue_free()


#func _draw() -> void:
	#var bullet_dir = linear_velocity.normalized()
	#var to_target = global_position.direction_to(target.global_position)
	#draw_line(Vector2.ZERO, bullet_dir*50, Color.CORNFLOWER_BLUE, 5)
	#draw_line(Vector2.ZERO, to_target*50, Color.ORANGE_RED, 5)


func shoot(direction, who: int):
	shooter_id = who
	#target = to
	apply_central_impulse(direction * speed)
