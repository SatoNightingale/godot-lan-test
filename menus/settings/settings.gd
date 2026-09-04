extends Control

signal go_back


func _ready() -> void:
	%nombre.text = Configurations.player_name
	%puerto.text = str(Configurations.default_port)

func _on_tree_exiting() -> void:
	Configurations.player_name = %nombre.text
	Configurations.default_port = %puerto.text.to_int()

#@onready var config_maps : Dictionary[Node, Array] = {
	#%nombre: ["player_name", get_text, set_text, as_is],
	#%puerto: ["default_port", get_text, set_text, cast_int]
#}
#
## Funciones de transformacion
#func as_is(x): return x
#func cast_int(x): return int(x)
#
## Funciones getters
#func get_text(c): return c.text
#
## Funciones setters
#func set_text(c, t): c.text = t
#
#
#func _ready() -> void:
	#for control in config_maps:
		#var propiedad = config_maps[control][0]
		#var setter = config_maps[control][2]
		#setter.call(control, Configurations.get(propiedad))
#
#
#func _on_tree_exiting() -> void:
	#for control in config_maps:
		#var propiedad = config_maps[control][0]
		#var getter = config_maps[control][1]
		#var func_transform = config_maps[control][3]
		#Configurations.set(propiedad, func_transform.call(getter.call(control)))


func _on_back_pressed() -> void:
	go_back.emit()
