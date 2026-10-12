extends Node2D
class_name Game

signal anuncio(mensaje: String)
signal error_popup(message: String, title: String)
#signal player_killed(killer_id: int, dead_id: int)

@export var player_scene = preload("res://game/player/player.tscn")

var main: Main

var player_data : Dictionary
var players: Dictionary[int, Player]

@onready var _ready_semaphore : MultiplayerSemaphore = $MultiplayerSemaphore

#var client_player : Player


#region Recepcion de la escena / Pre-inicializacion

func _ready():
	%PlayerSpawner.spawn_function = spawn_player
	%BulletSpawner.spawn_function = spawn_bullet
	#player_killed.connect(%UI.on_player_killed)
	anuncio.connect(%UI.anunciador.add_mensaje)
	%UI.menu_pausa.desconectar.connect(desconectar_partida)
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		_ready_semaphore.setup(server_initialize, player_data.size())
	else:
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	_ready_semaphore.notify()
#endregion

#region Inicializacion

func server_initialize():
	if multiplayer.is_server():
		_ready_semaphore.setup(_on_every_player_ready, player_data.size())
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
	var player : Player = player_scene.instantiate()
	# registrar datos del player
	players[data.id] = player
	player_data[data.id]["deaths"] = 0
	player_data[data.id]["kills"] = 0
	player_data[data.id]["eliminated"] = false
	# ponerle sus datos
	player.name = str(data.id)
	player.player_name = data["name"]
	# asignarle su posicion inicial
	player.position = data["start_pos"]
	# asignarle su numero de indice
	player.player_number = data["number"]
	# conectar señales del juego
	if multiplayer.is_server(): # solo se ejecutan en el servidor
		player.weapon_prop.connect_init(_on_player_weapon_changed)
		player.dead.connect(_on_player_dead.bind(data.id))
		player.ready.connect(func():
			player.respawn_timer.timeout.connect(respawn_player.bind(data.id))
		, CONNECT_ONE_SHOT)
	player.ready.connect(_ready_semaphore.notify, CONNECT_ONE_SHOT)
	# configurar la UI con el jugador actual
	if data.id == multiplayer.get_unique_id():
		#client_player = player
		%UI.player_data = player_data
		%UI.player = player
		player.ready.connect(%UI.initialize)
		#%UI.initialize()
		# La tienda tiene que estar como que un poco mas cerquita del Game
		#%UI.tienda.players = players
	return player


func _on_every_player_ready():
	#%UI.overlay_inventario.tienda.init_inventarios(players)
	# Hay que darle a cada player un arma con su id unico registrado en el servidor. Como el servidor debe ser el que dé el id (y no el player que se lo pida) debe estar fuera del spawner, y como setear el arma de un jugador es una operación pública que deben conocer todos los clientes, hay que esperar hasta que todos los clientes estén cargados, para evitar condiciones de carrera
	if multiplayer.is_server():
		for id in players:
			players[id].inventario.server_add_item(
				ItemManager.new_item_dto("res://items/classes/colt_item.tres"), 
				InventarioPlayer.SlotRole.MAIN_WEAPON
			)
#endregion

#region Armas

func spawn_bullet(data) -> Node:
	var shooter = players[data.shooter_id]
	var bala = shooter.weapon.municion.instantiate()
	bala.position = shooter.weapon.cannon.get_global_position()
	bala.shoot(data.direction, shooter)
	return bala

func _on_player_weapon_changed(weapon: Weapon, old_weapon: Weapon):
	if weapon and weapon is FireWeapon:
		weapon.bullet_fired.connect(call_bullet_spawner.bind(weapon))
			#func(direction: Vector2):
			#%BulletSpawner.spawn({
				#"shooter_id": weapon.player.player_id,
				#"direction": direction
			#}))
	if old_weapon:
		old_weapon.bullet_fired.disconnect(call_bullet_spawner)

func call_bullet_spawner(direction: Vector2, weapon: Weapon):
	%BulletSpawner.spawn({
		"shooter_id": weapon.player.player_id,
		"direction": direction
	})

#endregion
#region Muertes de players

func _on_player_dead(killer_id, dead_id):
	if multiplayer.is_server():
		players[killer_id].inventario.modificar_dinero(600)
		players[dead_id].inventario.modificar_dinero(-400)
		_on_dead.rpc_id(dead_id, killer_id)
		_on_kill.rpc_id(killer_id, dead_id)
		_on_player_killed.rpc(killer_id, dead_id)
		var dead = players[dead_id]
		if dead.dinero.value > 0:
			dead.start_respawn_timer()
			dead.start_respawn_timer.rpc_id(dead_id)
		else:
			player_data[dead_id].eliminated = true
			%UI.set_defeated_screen.rpc_id(dead_id)
			var alive_count = 0
			var alive_id = 0 # tecnicamente es el mismo que killer_id, pero...
			for id in player_data:
				if not player_data[id].eliminated:
					alive_count += 1
					alive_id = id
			if alive_count == 1:
				%UI.set_gameover_screen.rpc(
					players[alive_id].get_colored_player_name())


@rpc("authority", "call_local")
func _on_dead(killer_id: int):
	#var myid = multiplayer.get_unique_id()
	#players[myid].inventario.dinero.value -= 600
	%UI.set_dead_screen(players[killer_id].get_colored_player_name())


@rpc("authority", "call_local")
func _on_kill(dead_id: int):
	#var myid = multiplayer.get_unique_id()
	#players[myid].inventario.dinero.value += 400
	anuncio.emit("Has matado a {0}".format([
		players[dead_id].get_colored_player_name()
	]))
	%UI.actualizar_bajas()


@rpc("authority", "call_local")
func _on_player_killed(killer_id: int, dead_id: int):
	print(player_data[killer_id].name, " ha matado a ", player_data[dead_id].name)
	player_data[killer_id]["kills"] += 1
	player_data[dead_id]["deaths"] += 1
	var myid = multiplayer.get_unique_id()
	if myid != dead_id and myid != killer_id:
		anuncio.emit("{0} ha matado a {1}".format([
			players[killer_id].get_colored_player_name(),
			players[dead_id].get_colored_player_name(),
		]))


func respawn_player(id: int):
	if not multiplayer.is_server():
		return
	%UI.set_game_screen.rpc_id(id)
	var starting_position = %start_points.get_children().pick_random()
	var player = players[id]
	player.revive.rpc(starting_position.position)
#endregion

#region Desconexiones
## cuando un peer se desconecta del servidor
func _on_peer_disconnected(id: int):
	if id in players:
		players[id].queue_free()
	#remove_child(players[id])
	print(player_data[id].name, " desconectado")
	anuncio.emit(players[id].get_colored_player_name() + " se ha desconectado")
	player_data.erase(id)
	players.erase(id)

## cuando el servidor se desconecta
func _on_server_disconnected():
	desconectar_partida()
	error_popup.emit("Servidor desconectado", "Desconexion")


func desconectar_partida():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	main.change_to_menu()
	#main.change_screen_path("main_menu")
#endregion

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
