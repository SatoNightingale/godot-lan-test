extends Control

signal to_host
signal to_connect
signal to_config

func _ready() -> void:
	%version_label.text = ProjectSettings.get_setting("application/config/version")
	# ProjectSettings.globalize_path("user://")
	%boton_parche.pressed.connect(%patch_finder.popup_file_dialog)
	%patch_finder.file_selected.connect(func(path):
		if PatchSystem.copiar_parche(path) == OK:
			%dlg_patch_restart.popup_centered_clamped()
	)
	%dlg_patch_restart.confirmed.connect(func():
		OS.set_restart_on_exit(true)
		get_tree().quit()
	)
	%boton_crear.pressed.connect(to_host.emit)
	%boton_conectar.pressed.connect(to_connect.emit)
	%boton_config.pressed.connect(to_config.emit)


func initialize():
	pass
