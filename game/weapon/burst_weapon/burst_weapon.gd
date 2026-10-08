class_name BurstWeapon extends FireWeapon

@export var burst_length := 3
@export var burst_time := 0.5

var burst_count := 0

func _ready() -> void:
	super._ready()
	bullet_fired.connect(_increase_burst)

func _increase_burst(..._args):
	burst_count += 1
	if burst_count == burst_length:
		$burst_timer.start()
		shoot_semaphore.adquirir_timer($burst_timer)

func _on_burst_timer_timeout() -> void:
	burst_count = 0
