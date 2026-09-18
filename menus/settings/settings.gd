extends Control


func _ready() -> void:
	%nombre.text = Configurations.player_name
	%puerto.text = str(Configurations.default_port)


func _on_save_pressed() -> void:
	Configurations.player_name = %nombre.text
	Configurations.default_port = %puerto.text.to_int()
	Configurations.save_config()


func deinitialize() -> void:
	_on_save_pressed()
