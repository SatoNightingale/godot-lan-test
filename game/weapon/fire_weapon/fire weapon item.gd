class_name FireWeaponItem extends WeaponItem


## Propiedades de clase

## Escena que contiene el tipo de municion que usa el arma
## (item, ahora)
@export var municion: PackedScene = preload("res://game/bullet/bullet.tscn")
## Municion maxima del arma
@export var max_ammo : int
## Si el arma es automatica o no. Si es automatica, dispara mientras este presionada la accion de disparar; si no lo es, solo dispara una vez cuando se presiona la accion
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


## Propiedades de instancia

var ammo: int:
	get():
		return object.ammo if object else 0


func to_dto() -> Dictionary:
	return super.to_dto().merged({
		"ammo": ammo
	})


func _generate_object(item: Item, dto: Dictionary):
	super._generate_object(item, dto)
	if object is FireWeapon:
		object.municion = municion
		object.max_ammo = max_ammo
		object.automatica = automatica
		object.alcance = alcance
		object.desviacion = desviacion
		object.shoot_cooldown = shoot_cooldown
		object.reload_cooldown = reload_cooldown
		object.reloading_slowdown = reloading_slowdown
		object.aim_distance = aim_distance
		object.ammo = dto.ammo


func get_tooltip(slot_text: String) -> String:
	@warning_ignore("incompatible_ternary")
	return \
"[font_size=16]{nombre}[/font_size]
[p][color=gainsboro][indent]{text}[/indent][/color][/p]
[color=darkorange]Daño: [/color]{damage}
[color=darkorange]Munición máxima: [/color]{max_ammo}
[color=darkorange]Automática: [/color]{automatica}
[color=darkorange]Desviación de bala: [/color]{desviacion}º
[color=darkorange]Tiempo de recarga: [/color]{reload_cooldown}s
[color=darkorange]Distancia de apuntado: [/color]{aim_dist}
[color=darkorange]Alcance: [/color]{alcance}
[p][font_size=10][color=darkgray]{slot_text}[/color][/font_size][/p]
" \
.format({
	"nombre": nombre,
	"text": tooltip_text,
	"damage": damage,
	"max_ammo": max_ammo,
	"automatica": "Si" if automatica else "No",
	"alcance": alcance,
	"desviacion": desviacion,
	"reload_cooldown": reload_cooldown,
	"aim_dist": aim_distance if aim_distance != 0 else "no apunta",
	"slot_text": slot_text,
})
