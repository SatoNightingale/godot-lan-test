class_name FireWeaponRes extends Resource ##


## Textura que mostará el arma en el juego
var game_texture: Texture2D
## Escena que contiene el tipo de municion que usa el arma
@export var municion: PackedScene = preload("res://game/bullet/bullet.tscn")
## Marcador para la posicion desde donde las balas son disparadas
@export var cannonpos : Vector2
## Municion maxima del arma
@export var max_ammo := 6
## Si el arma es automatica o no. Si es automatica, dispara mientras este presionada la accion de disparar; si no lo es solo dispara una vez cuando se presiona la accion
@export var automatica := false
## Alcance de bala del arma
@export var alcance := 700
## Factor de desviación del arma, en grados.
## La dirección de cada disparo variará aleatoriamente en proporción a esta cantidad
@export var desviacion: float = 5.0
## Tiempo entre disparos
@export var shoot_cooldown: float = 0.6
## Tiempo que demora recargando
@export var reload_cooldown: float = 3.0
## Multiplicador de la velocidad del player cuando esta recargando
@export var reloading_slowdown = 0.8
## Distancia de apuntado del arma. Si es mayor que cero, sobreescribe la distancia de vistazo del player con este valor, haciendo posible mirar a una mayor longitud
@export var aim_distance := 0
