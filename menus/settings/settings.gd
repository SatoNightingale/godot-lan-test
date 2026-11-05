extends Control

signal done


func _ready() -> void:
	%nombre.text = Configurations.player_name
	%puerto.text = str(Configurations.default_port)
	%mostrar_consola.button_pressed = Configurations.mostrar_consola
	%mostrar_consola.toggled.connect(func(toggled_on):
		Configurations.mostrar_consola = toggled_on)
 

func game_mode():
	%Save.text = "Atrás"
	%Save.pressed.connect(done.emit)
	%nombre.editable = false
	%puerto.editable = false


func _on_save_pressed() -> void:
	Configurations.player_name = %nombre.text
	Configurations.default_port = %puerto.text.to_int()
	Configurations.save_config()


func deinitialize() -> void:
	_on_save_pressed()
