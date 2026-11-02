class_name FireWeaponItem extends WeaponItem


## Propiedades de clase

## Aqui puede colocarse lo mismo una referencia a un tipo de item que a un script. En el primer caso, el slot requerira única y exclusivamente ese tipo de item; en el segundo, cualquier item de la clase del script
@export var clase_municion_path: String
#@export var municion: PackedScene = preload("res://game/bullet/bullet.tscn")
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


func _validate_object(obj):
	return obj is FireWeapon


#func validar_slot(slot: Slot) -> bool:
	#if not slot.extra_data.has("ammo_slot"):
		#return true # no se esta equipando
	##else:
		##var ammo_slot = 
	#if not slot.item:
		#return true
	#else:
		#var item_type = slot.item.item_type_path
		#return (clase_municion_path.ends_with(".gd") and \
			#ItemManager.type_is_instance_of_script_path(
				#clase_municion_path, item_type)) or \
		#clase_municion_path == item_type


func to_dto() -> Dictionary:
	return super.to_dto().merged({
		"ammo": ammo
	})


func _generate_object(item: Item, dto: Dictionary) -> Object:
	object = super._generate_object(item, dto)
	if object is FireWeapon:
		object.max_ammo = max_ammo
		object.automatica = automatica
		object.alcance = alcance
		object.desviacion = desviacion
		object.shoot_cooldown = shoot_cooldown
		object.reload_cooldown = reload_cooldown
		object.reloading_slowdown = reloading_slowdown
		object.aim_distance = aim_distance
		object.clase_municion_path = clase_municion_path
		object.ammo = dto.ammo
		return object
	else:
		printerr("Objeto del FireWeaponItem ", item.nombre, " con id ", item.id, " no es un FireWeapon")
	return null


func get_tooltip(slot_text: String) -> String:
	@warning_ignore("incompatible_ternary")
	return \
"[font_size=16]{nombre}[/font_size]
[p][color=gainsboro][indent]{text}[/indent][/color][/p]
[color=darkorange]Tipo de munición: [/color]{ammo_type}
[color=darkorange]Daño: [/color]{damage}
[color=darkorange]Munición máxima: [/color]{max_ammo}
[color=darkorange]Cadencia de disparo: [/color]{cadencia} balas por minuto
[color=darkorange]Automática: [/color]{automatica}
[color=darkorange]Dispersión de bala: [/color]{desviacion}º
[color=darkorange]Tiempo de recarga: [/color]{reload_cooldown}s
[color=darkorange]Distancia de apuntado: [/color]{aim_dist}
[color=darkorange]Alcance: [/color]{alcance}
[p][font_size=10][color=darkgray]{slot_text}[/color][/font_size][/p]" \
.format({
	"nombre": nombre,
	"text": tooltip_text,
	"ammo_type": ItemManager.get_item_type(clase_municion_path).nombre,
	"damage": damage,
	"max_ammo": max_ammo,
	"cadencia": int(60 / shoot_cooldown),
	"automatica": "Si" if automatica else "No",
	"alcance": alcance,
	"desviacion": desviacion,
	"reload_cooldown": reload_cooldown,
	"aim_dist": aim_distance if aim_distance != 0 else "no apunta",
	"slot_text": slot_text,
})
