extends Node2D

@export var player_scene = preload("res://game/player/player.tscn")
@export var bullet_scene = preload("res://game/bullet/bullet.tscn")

@onready var player_name : String = get_parent().player_name

var player_data : Dictionary

signal player_killed(killer_id: int, dead_id: int)

#var client_player : Player


func _ready():
	%PlayerSpawner.spawn_function = spawn_player
	%BulletSpawner.spawn_function = spawn_bullet
	player_killed.connect(%UI.on_player_killed)
	#player_data.merge(get_parent().player_data)
	#%playagain_button.disabled = not multiplayer.is_server()
	print(player_name, " ready!")


func server_initialize():
	print(player_name, " init")
	#show_tree.rpc()
	var starting_positions = %start_points.get_children()
	var player_number = 0
	for id in player_data:
		var marker = starting_positions.pick_random()
		starting_positions.erase(marker)
		%PlayerSpawner.spawn({
			"id": id,
			"name": player_data[id]["name"],
			"start_pos": marker.position,
			"number": player_number
		})
		player_number += 1


# Esto va a ser llamado en cada peer por PlayerSpawner
func spawn_player(data) -> Node:
	# instanciar el player
	var player : Player = preload("res://game/player/player.tscn").instantiate()
	# registrar el nodo en el servidor
	player_data[data.id]["node"] = player
	#player_data[data.id]["respawn_timer"] = player.get_node("%respawn_timer")
	player_data[data.id]["deaths"] = 0
	player_data[data.id]["kills"] = 0
	# ponerle sus datos
	player.name = str(data.id)
	player.player_name = data["name"]
	# asignarle su posicion
	player.position = data["start_pos"]
	# asignarle su numero de indice
	player.player_number = data["number"]
	# conectar señales del juego
	if multiplayer.is_server(): # solo se ejecutan en el servidor
		player.bullet_fired.connect(
			%BulletSpawner.spawn.bind(data.id))
		player.shot.connect(_on_player_shot.bind(data.id))
		player.ready.connect(func():
			player.respawn_timer.timeout.connect(respawn_player.bind(data.id)),
			CONNECT_ONE_SHOT
		)
	# configurar la UI con el jugador actual
	if data.id == multiplayer.get_unique_id():
		#client_player = player
		%UI.configure_ui(player)
	return player


func spawn_bullet(shooter_id) -> Node:
	var bala = bullet_scene.instantiate()
	var shooter = player_data[shooter_id]["node"]
	bala.position = shooter.get_node("cannon").get_global_position()
	bala.shoot(shooter.direction, shooter_id)
	return bala


func respawn_player(id: int):
	if not multiplayer.is_server():
		return
	var starting_position = %start_points.get_children().pick_random()
	var player = player_data[id].node as Player
	player.initialize.rpc(starting_position.position)


func _on_player_shot(killer_id, dead_id):
	on_player_killed.rpc(killer_id, dead_id)


@rpc("call_local")
func on_player_killed(killer_id: int, dead_id: int):
	print(player_data[killer_id].name, " ha matado a ", player_data[dead_id].name)
	player_data[killer_id]["kills"] += 1
	player_data[dead_id]["deaths"] += 1
	player_killed.emit(killer_id, dead_id)


#@rpc("call_local")
#func restart_game():
	#%UI.set_game_screen()
	#if not multiplayer.is_server():
		#return
	#var starting_positions = %start_points.get_children()
	#var player_number = 0
	#for id in player_data:
		#var player = player_data[id].node as Player
		#var marker = starting_positions.pick_random()
		#starting_positions.erase(marker)
		#player.player_number = player_number
		#player.initialize.rpc(marker.position)
		#player_number += 1


#func _on_playagain_button_pressed() -> void:
	#if multiplayer.is_server():
		#restart_game.rpc()
