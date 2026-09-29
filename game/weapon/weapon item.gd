class_name WeaponItem extends Item


## Propiedades de clase

## Daño básico del arma
@export var damage: float
## Tiempo en que el personaje permanece ralentizado luego de usar el arma
@export var after_wield_slowdown_time: float = 0.7
## Modificador de la velocidad del player cuando esta usando el arma
@export var wielding_slowdown := 0.66

## Propiedades de instancia
##

func _validate_object(obj):
	return obj is Weapon
