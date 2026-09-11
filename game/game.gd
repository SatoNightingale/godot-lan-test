extends Node2D
class_name Game

signal anuncio(mensaje: String)
#signal player_killed(killer_id: int, dead_id: int)

@export var player_scene = preload("res://game/player/player.tscn")

## TODO: player_data no debe tener un campo 'node', considerar un diccionario aparte que mapee ids a nodos de players

var player_data : Dictionary
var players: Dictionary[int, Player]

#var client_player : Player

var ready_player_count = 0


func _ready():
	%PlayerSpawner.spawn_function = spawn_player
	%BulletSpawner.spawn_function = spawn_bullet
	#player_killed.connect(%UI.on_player_killed)
	anuncio.connect(%UI.anunciador.add_mensaje)
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
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
	if not multiplayer.is_server():
		return
	const ruta_arma_inicial = "res://items/classes/colt_item.tres"
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
		colocar_arma_inicial.rpc(id,
			ItemManager.new_item_dto_from_path(ruta_arma_inicial)
		)


# Esto va a ser llamado en cada peer por PlayerSpawner
func spawn_player(data) -> Node:
	# instanciar el player
	var player : Player = player_scene.instantiate()
	# registrar datos del player
	players[data.id] = player
	player_data[data.id]["deaths"] = 0
	player_data[data.id]["kills"] = 0
	# ponerle sus datos
	player.name = str(data.id)
	player.player_name = data["name"]
	# asignarle su posicion inicial
	player.position = data["start_pos"]
	# asignarle su numero de indice
	player.player_number = data["number"]
	# conectar señales del juego
	if multiplayer.is_server(): # solo se ejecutan en el servidor
		player.weapon_changed.connect(_on_player_weapon_changed)
		if player.weapon != null:
			_on_player_weapon_changed(player.weapon)
		player.dead.connect(_on_player_dead.bind(data.id))
		player.ready.connect(func():
			player.respawn_timer.timeout.connect(respawn_player.bind(data.id))
		, CONNECT_ONE_SHOT)
	# configurar la UI con el jugador actual
	if data.id == multiplayer.get_unique_id():
		#client_player = player
		%UI.player_data = player_data
		%UI.player = player
	return player


func spawn_bullet(data) -> Node:
	var shooter = players[data.shooter_id]
	var bala = shooter.weapon.municion.instantiate()
	bala.position = shooter.weapon.cannon.get_global_position()
	bala.shoot(data.direction, shooter)
	return bala


@rpc("authority", "call_local")
func colocar_arma_inicial(player_id: int, item_dto: Dictionary):
	players[player_id].add_item(Item.from_dto(item_dto))


func _on_player_weapon_changed(weapon: Weapon):
	if weapon is FireWeapon:
		weapon.bullet_fired.connect(func(direction: Vector2):
			%BulletSpawner.spawn({
				"shooter_id": weapon.player.player_id,
				"direction": direction
			}))


func _on_player_dead(killer_id, dead_id):
	if multiplayer.is_server():
		#players[killer_id].dinero.value += 700
		#players[dead_id].dinero.value -= 1000
		on_player_killed.rpc(killer_id, dead_id)
		var dead = players[dead_id]
		if dead.dinero.value > 0:
			dead.start_respawn_timer()
			dead.start_respawn_timer.rpc_id(dead_id)
		else:
			%UI.set_defeated_screen.rpc_id(dead_id)


@rpc("authority", "call_local")
func on_player_killed(killer_id: int, dead_id: int):
	# esto lo puede hacer el mismo player
	print(player_data[killer_id].name, " ha matado a ", player_data[dead_id].name)
	player_data[killer_id]["kills"] += 1
	player_data[dead_id]["deaths"] += 1
	players[killer_id].dinero.value += 700
	players[dead_id].dinero.value -= 1000
	#player_killed.emit(killer_id, dead_id)
	%UI.on_player_killed(killer_id, dead_id)
	anuncio.emit("{0} ha matado a {1}".format([
		players[killer_id].get_colored_player_name(),
		players[dead_id].get_colored_player_name(),
	]))
	if multiplayer.get_unique_id() == dead_id:
		%UI.set_dead_screen(player_data[killer_id].name)


func respawn_player(id: int):
	if not multiplayer.is_server():
		return
	var starting_position = %start_points.get_children().pick_random()
	var player = players[id]
	player.revive.rpc(starting_position.position)


## cuando un peer se desconecta del servidor
func _on_peer_disconnected(id: int):
	players[id].queue_free()
	remove_child(players[id])
	print(player_data[id].name, " desconectado")
	anuncio.emit(players[id].get_colored_player_name() + " se ha desconectado")
	player_data.erase(id)
	players.erase(id)

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
