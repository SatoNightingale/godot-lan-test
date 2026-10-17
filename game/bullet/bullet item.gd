class_name BulletItem extends Item

@export var base_damage: int

func _validate_object(obj):
	return obj is Bullet
