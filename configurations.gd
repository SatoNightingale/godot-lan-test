extends Node

var default_port_prop := Observable.new(4242)
var default_port: int:
	set(value): default_port_prop.value = value
	get(): return default_port_prop.value

var player_name_prop := Observable.new("Player")
var player_name: String:
	set(value): player_name_prop.value = value
	get(): return player_name_prop.value

## propiedades no persistentes
var _runtime_props = [
	"mostrar_consola",
]

var mostrar_consola_prop := Observable.new(false)
var mostrar_consola: bool:
	set(value): mostrar_consola_prop.value = value
	get(): return mostrar_consola_prop.value


func _ready() -> void:
	tree_exiting.connect(save_config)


func read_config():
	var config = ConfigFile.new()
	var errcode = config.load("user://config.cfg")
	if errcode != OK:
		printerr("Error al cargar la configuracion: ", errcode)
		return
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and \
		prop.class_name != "Observable" and \
		prop.name not in _runtime_props:
			set(prop.name, config.get_value(
				"data", prop.name, get(prop.name)))


func save_config():
	var config = ConfigFile.new()
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0 and \
		prop.class_name != "Observable" and \
		prop.name not in _runtime_props:
			config.set_value("data", prop.name, get(prop.name))
	var errcode = config.save("user://config.cfg")
	if errcode != OK:
		printerr("Error al guardar la configuracion: ", errcode)
