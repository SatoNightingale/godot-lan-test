extends TouchScreenButton


const modulate_active = Color(1.0, 1.0, 1.0, 0.75)
const modulate_cooldown = Color(0.5, 0.5, 0.5, 0.75)


var pie_angle := 0.0

var _cooldown := false:
	set(value):
		_cooldown = value
		modulate = modulate_active if not _cooldown else modulate_cooldown
		queue_redraw()

var timer: Timer:
	set(value):
		timer = value
		timer.timeout.connect(_on_cooldown_finished)


func setup(_timer: Timer, activation: Signal):
	self.timer = _timer
	activation.connect(on_activation)


func on_activation():
	_cooldown = true

func _process(_delta):
	if _cooldown:
		pie_angle = TAU - TAU * timer.time_left / timer.wait_time
		queue_redraw()

func _draw() -> void:
	draw_arc(
		shape.get_rect().size / 2 - Vector2(5.0, 5.0),
		50, 0, pie_angle, 25, Color.AQUA, 100, true
	)

func _on_cooldown_finished():
	_cooldown = false
	pie_angle = 0.0
