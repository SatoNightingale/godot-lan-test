extends Node

signal server_created
signal client_created(ip: String)
signal error(message: String)

var max_players = 4


func _enter_tree():
	multiplayer.peer_disconnected.connect(func(id):
		print("peer desconectado: ", id))
	multiplayer.server_disconnected.connect(func():
		print("server desconectado"))


func host():
	var peer = ENetMultiplayerPeer.new()
	var port = Configurations.default_port
	var errcod = peer.create_server(port, max_players)
	if errcod == OK:
		multiplayer.multiplayer_peer = peer
		server_created.emit()
	else:
		error.emit("Error al crear servidor: {0}".format([str(errcod)]))


func join(ip: String, port: int):
	var peer = ENetMultiplayerPeer.new()
	var errcod = peer.create_client(ip, port)
	if errcod == OK:
		multiplayer.multiplayer_peer = peer
		client_created.emit(ip)
	else:
		error.emit("Error al conectar al servidor: " + str(errcod))
