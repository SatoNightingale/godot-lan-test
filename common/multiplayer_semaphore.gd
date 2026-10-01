class_name MultiplayerSemaphore extends Node

signal topped

var max_peers: int
var authority: int = 1

var _notified_peers : Array[int]

#func _init(_max_peers: int = 0, _authority = 1) -> void:
	##multiplayer = _multiplayerget_multiplayer_authority()
	#authority = _authority
	#if _max_peers == 0:
		#max_peers = multiplayer.get_peers().size()
	#else:
		#max_peers = _max_peers

func setup(callable: Callable, _max_peers: int, _authority: int = 1):
	topped.connect(callable, CONNECT_ONE_SHOT)
	max_peers = _max_peers
	authority = _authority


func notify():
	if multiplayer:
		_on_peer_notified.rpc_id(authority, multiplayer.get_unique_id())

# No se pueden tirar rpcs en tallas que no sean nodos...
@rpc("any_peer", "call_local")
func _on_peer_notified(peer_id: int):
	if multiplayer.get_unique_id() == authority:
		if peer_id not in _notified_peers:
			_notified_peers.append(peer_id)
		if _notified_peers.size() == max_peers:
			_notified_peers.clear()
			topped.emit()
