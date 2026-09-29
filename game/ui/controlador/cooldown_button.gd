extends TouchScreenButton


const modulate_active = Color(1.0, 1.0, 1.0, 0.75)
const modulate_cooldown = Color(0.5, 0.5, 0.5, 0.75)

var _cooldown := false

func setup(wait_time: float, activation: Signal):
	activation.connect(on_activation.bind(wait_time))


func on_activation(...args):
	if not _cooldown:
		_cooldown = true
		self_modulate = modulate_cooldown
		$pie.show()
		$pie.value = 0
		var timer_time = args[-1]
		var tween = create_tween()
		tween.tween_property($pie, "value", 100, timer_time)
		tween.tween_callback($pie.hide)
		tween.tween_callback(set.bind("self_modulate", modulate_active))
		tween.tween_callback(set.bind("_cooldown", false))
