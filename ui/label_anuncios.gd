#@tool
extends RichTextLabel

var cola_mensajes: Array[String]


#func _ready() -> void:
	#var tween = create_tween()
	#tween.tween_callback(show).set_delay(1)
	#tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	#tween.tween_callback(hide)
	#tween.tween_callback(set_modulate.bind(Color.WHITE))
	#tween.set_loops()


func add_mensaje(mensaje: String):
	cola_mensajes.push_back(mensaje)
	_next_message()


func _next_message():
	if not cola_mensajes.is_empty():
		if $Timer.is_stopped():
			show()
			var next_mensaje = cola_mensajes.pop_front()
			text = next_mensaje
			var tween = create_tween()
			tween.tween_method(_fontsize_override_helper, 30, 23, 0.2)
			$Timer.start()
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
		tween.tween_callback(hide)
		tween.tween_callback(set_modulate.bind(Color.WHITE))


func _fontsize_override_helper(value: int):
	add_theme_font_size_override("normal_font_size", value)


func _on_timer_timeout() -> void:
	_next_message()
