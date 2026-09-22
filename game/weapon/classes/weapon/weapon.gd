class_name Weapon extends Node2D

@warning_ignore("unused_signal")
signal wielded(args: Array)

## Daño básico del arma
@export var damage: float
## Tiempo en que el personaje permanece ralentizado luego de usar el arma
@export var after_wield_slowdown_time: float = 0.7
## Modificador de la velocidad del player cuando esta usando el arma
@export var wielding_slowdown := 0.66

# Yo pensaria incluso en una ralentizacion permanente por tener el arma equipada

var player: Player: set = set_player

func set_player(value: Player):
	player = value
	wielded.connect(aplicar_ralentizacion.bind(
		wielding_slowdown, after_wield_slowdown_time
	))


func _ready() -> void:
	$wield_slowdown_timer.timeout.connect(func():
		player.speed = player.base_speed
	)


## Aplica una ralentizacion al player por un tiempo determinado. Si ya hay una ralentizacion siendo aplicada, reinicia el Timer con el nuevo tiempo. 
## Utiliza parametros variables para poder conectarla con seguridad a señales de cualquier cantidad de argumentos. Despues de los de la señal disparada, los ultimos parametros son: modificador y tiempo
func aplicar_ralentizacion(...args):
	var modificador = args[-2]
	var tiempo = args[-1]
	player.speed = player.base_speed * modificador
	$wield_slowdown_timer.start(tiempo)
