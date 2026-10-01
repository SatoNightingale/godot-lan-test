class_name RPCRequest extends Node

## La funcion de esto es: mandar al servidor a hacer algo y que el pueda responder si lo hizo con exito o no. Nunca dejarle una ejecucion critica al cliente

signal response(code)

enum RESPONSE_CODE {
	OK,
	FAIL
}

## Llamado al servidor
@rpc("any_peer", "call_local")
func make(body: Dictionary):
	if multiplayer.is_server():
		get_node(body.node).call(body.method)
		pass

## Llamado al cliente
@rpc("authority", "call_local")
func respond(code: RESPONSE_CODE):
	response.emit(code)
