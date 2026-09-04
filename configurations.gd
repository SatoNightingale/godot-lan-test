extends Node

@export var default_port := 4242
@export var player_name := "Player"

func _ready() -> void:
	tree_exiting.connect(save_config)


func read_config():
	var config = ConfigFile.new()
	var errcode = config.load("user://config.cfg")
	if errcode != OK:
		printerr("Error al cargar la configuracion: ", errcode)
		return
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			set(prop.name, config.get_value("data", prop.name, get(prop.name)))


func save_config():
	var config = ConfigFile.new()
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			config.set_value("data", prop.name, get(prop.name))
	var errcode = config.save("user://config.cfg")
	if errcode != OK:
		printerr("Error al guardar la configuracion: ", errcode)
