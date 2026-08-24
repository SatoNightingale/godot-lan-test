extends Node2D
class_name Game

signal anuncio(mensaje: String)

@export var player_scene = preload("res://game/player/player.tscn")
@export var bullet_scene = preload("res://game/bullet/bullet.tscn")

#@onready var player_name : String = get_parent().player_name

## TODO: player_data no debe tener un campo 'node', sino que el mismo valor mapeado a la clave debe ser el nodo del jugador, y acceder desde ahi a sus kills, muertes, etc.

var player_data : Dictionary

signal player_killed(killer_id: int, dead_id: int)

#var client_player : Player

var ready_player_count = 0


func _ready():
	%PlayerSpawner.spawn_function = spawn_player
	%BulletSpawner.spawn_function = spawn_bullet
	player_killed.connect(%UI.on_player_killed)
	anuncio.connect(%UI.anunciador.add_mensaje)
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	on_player_loaded.rpc_id(1)


@rpc("any_peer", "call_local")
func on_player_loaded():
	if multiplayer.is_server():
		ready_player_count += 1
		print("ready players: ", ready_player_count)
		if ready_player_count == player_data.size():
			#get_node("/root/Main/Game").
			server_initialize()


func server_initialize():
	#print(player_name, " init")
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
	# registrar datos del player
	player_data[data.id]["node"] = player
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
		player.weapon_changed.connect(_on_player_weapon_changed)
		if player.weapon != null:
			_on_player_weapon_changed(player.weapon, data.id)
		player.shot.connect(_on_player_shot.bind(data.id))
		player.ready.connect(func():
			player.respawn_timer.timeout.connect(respawn_player.bind(data.id)),
			CONNECT_ONE_SHOT
		)
	# configurar la UI con el jugador actual
	if data.id == multiplayer.get_unique_id():
		#client_player = player
		%UI.player_data = player_data
		%UI.configure_ui(player)
	return player


func spawn_bullet(shooter_id) -> Node:
	var bala = bullet_scene.instantiate()
	var shooter = player_data[shooter_id]["node"] as Player
	bala.position = shooter.weapon.cannon.get_global_position()
	bala.shoot(shooter.direction, shooter_id)
	return bala


func respawn_player(id: int):
	if not multiplayer.is_server():
		return
	var starting_position = %start_points.get_children().pick_random()
	var player = player_data[id].node as Player
	player.revive.rpc(starting_position.position)


func _on_player_shot(killer_id, dead_id):
	on_player_killed.rpc(killer_id, dead_id)


func _on_player_weapon_changed(weapon: Weapon, player_id: int):
	weapon.bullet_fired.connect(%BulletSpawner.spawn.bind(player_id))


@rpc("call_local")
func on_player_killed(killer_id: int, dead_id: int):
	# esto lo puede hacer el mismo player
	print(player_data[killer_id].name, " ha matado a ", player_data[dead_id].name)
	player_data[killer_id]["kills"] += 1
	player_data[dead_id]["deaths"] += 1
	player_killed.emit(killer_id, dead_id)
	anuncio.emit("{0} ha matado a {1}".format([
		player_data[killer_id].node.get_colored_player_name(),
		player_data[dead_id].node.get_colored_player_name(),
	]))


## cuando un peer se desconecta del servidor
func _on_player_disconnected(id: int):
	player_data[id].node.queue_free()
	remove_child(player_data[id].node)
	print(player_data[id].name, " desconectado")
	anuncio.emit(player_data[id].node.get_colored_player_name() + " se ha desconectado")
	player_data.erase(id)

## cuando el servidor se desconecta
func _on_server_disconnected():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	var main_menu = load("res://menus/main menu.tscn").instantiate()
	main_menu.ready.connect(main_menu.error_popup.bind("Servidor desconectado"), CONNECT_ONE_SHOT)
	get_tree().change_scene_to_node(main_menu)


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
