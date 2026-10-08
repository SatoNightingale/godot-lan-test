class_name InventarioAbstract extends Node
## Un inventario abstracto, que puede ser lo mismo el inventario de un player que el de un cofre o la tienda.
##
## Define un conjunto de items y un conjunto de slots. Cualquier item que se vaya a añadir debe ocupar un slot específico, pero el concepto de slot debe ser lo suficientemente flexible como para abarcar slots 'contenedores' o slots dentro de items. En el conjunto de items, sin embargo, deben ir todos los items del inventario, de forma que se puedan añadir o eliminar mediante los métodos básicos, solo conociendo el slot del item. Por eso, en principio el slot es solo la posicion en el arreglo de items que ocupa el item recien añadido
##
## El inventario tiene poco que hacer si se le manda a añadir un item en un slot que ya tiene un item equipado, o si se le manda a quitar un item de un slot que no tiene nada.
# Por defecto, todos los slots son publicos, es decir, cualquier cambio en ellos se refleja en todos los clientes. Para habilitar los slots privados, es decir, aquellos cuyos cambios solo se ven en el cliente propietario y en el servidor, se define el id de este cliente propietario. 
## y la operacion de mover items de un lado a otro del mismo inventario?

## Esto aqui existe mas para poder validar que el que realiza la accion sobre el inventario es su dueño, que para nada de slots privados
## Inventarios sin dueño (cofres sueltos por ahi, etc.) tendran el owner_id en 0 y podrán ser manipulados por cualquiera (supongo...)
## O quizas habria que verificar si el inventario y el peer que lo modifica tienen una interaccion abierta. Eso es cosa de inventario_overlay
## Era tan buena idea lo de las sesiones (o eso me parecio) que el owner se hizo innecesario xd
#var owner_id: int = 0

## Esto solo lo controla el servidor y solo en el adquiere valores. Contiene los ids de todos los peers que tienen una sesion abierta con este inventario, y que por tanto pueden modificarlo
var sesiones_abiertas: Array[int]

## Todos los items van a vivir en el diccionario de slots.
## get_item buscara en ese diccionario (y en sus potenciales sub-diccionarios si el item tiene slots a su vez) para devolver los items
## take_item tomara el id y buscara de igual forma que get_item, pero seteando a null
#var _items: Array[Item]
## Slots publicos deben actualizarse en todos los peers
## en los slots, el indice es el numero o identificador o 'rol' del slot
## El indice -1 representa el slot invalido, esta prohibido para los slots
var _slots: Dictionary[int, Item]
## Slots privados deben actualizarse solo en el cliente dueño y en el servidor

func set_slot(slot_id: int, item):
	_slots[slot_id] = item


## Las funciones de abrir y cerrar sesion no son rpc, por tanto solamente el servidor puede llamarlas, y opened_sessions solamente es utilizado en el. En los demas peers, aparece vacio
func abrir_sesion(peer_id: int):
	if multiplayer.is_server():
		sesiones_abiertas.append(peer_id)

func cerrar_sesion(peer_id: int):
	if multiplayer.is_server():
		sesiones_abiertas.erase(peer_id)

func validar_sesion(peer_id) -> bool:
	if peer_id in sesiones_abiertas:
		return true
	else:
		printerr("El peer ", peer_id, " no tiene una sesion abierta con este inventario")
		return false


func get_item(id: int) -> Item:
	for slot in _slots:
		if _slots[slot].id == id:
			return _slots[slot]
	return null

func get_slot(item_id: int) -> int:
	for slot in _slots:
		if _slots[slot].id == item_id:
			return slot
	return -1

func has_item(id: int) -> bool:
	return get_item(id) != null


## Funcion que se encarga de determinar cuando un slot existe en el inventario y cuando es simplemente un numero inventado
## Esto deberia ser abstract?
func validar_slot(_slot_id: int):
	return true


func add_item_server(item_dto: Dictionary, slot: int):
	if multiplayer.is_server():
		if validar_slot(slot):
			## Todos los slots son publicos y se setean en todos los peers
			_add_item_client.rpc(item_dto, slot)


func take_item_server(slot: int):
	if multiplayer.is_server():
		if validar_slot(slot):
			_take_item_client.rpc(slot)


func take_item_id_server(item_id: int):
	if multiplayer.is_server():
		var slot_id = get_slot(item_id)
		if slot_id != -1:
			take_item_server(slot_id)
		else:
			printerr("Item no encontrado: ", item_id)


## Esto se llama en el inventario que recibe el item intercambiado
@rpc("any_peer", "call_local")
func intercambio(inv_origen_path: NodePath, item_dto: Dictionary, dest_slot: int):
	if multiplayer.is_server() and validar_sesion(multiplayer.get_remote_sender_id()):
		var inventario_origen = get_node(inv_origen_path)
		if inventario_origen is InventarioAbstract:
			var item_recibido = inventario_origen.enviar_item(
				self, item_dto, dest_slot)
			if item_recibido:
				add_item_server(item_dto, dest_slot)
		else:
			printerr("Ruta al inventario invalida: ", inv_origen_path)

## Funcion de validacion para intercambios, que se llama en el inventario que envia el item intercambiado. Aqui, por ejemplo, Tienda puede decidir no enviar el item si el player no tiene baro
func enviar_item(_inv_dest: InventarioAbstract, item_dto: Dictionary, _slot_dest: int):
	if multiplayer.is_server():
		if has_item(item_dto.id):
			take_item_server(item_dto.id)
			return get_item(item_dto.id)
	else:
		printerr("enviar_item solo puede llamarse en el servidor")
	return null


## Mover items de un slot a otro dentro del mismo inventario. No convierte nada en DTO
@rpc("any_peer", "call_local")
func mover_item_local(from_slot: int, to_slot: int):
	if multiplayer.is_server() and validar_sesion(multiplayer.get_remote_sender_id()):
		if !(validar_slot(from_slot) and validar_slot(to_slot)):
			printerr("Slots invalidos")
			return
		mover_item_client.rpc(from_slot, to_slot)


@rpc("authority", "call_local")
func mover_item_client(from_slot: int, to_slot: int):
	var aux = _slots[from_slot]
	set_slot(from_slot, _slots[to_slot])
	set_slot(to_slot, aux)
	#_slots[from_slot] = _slots[to_slot]
	#_slots[to_slot] = aux


@rpc("authority", "call_local")
func _add_item_client(item_dto: Dictionary, slot: int):
	var item = Item.new_from_dto(item_dto)
	#if _slots[slot] != null:
		##_items.append(item)
	#else:
		##_items.erase(item.id)
	set_slot(slot, item)
	#_slots[slot] = item


#@rpc("authority", "call_local")
#func _take_item_client(id: int):
	##var i = 0
	##for it in _items:
		##if it.id == id:
			##_items.remove_at(i)
			##break
		##i += 1
	#for slot_id in _slots:
		#if _slots[slot_id].id == id:
			#_slots[slot_id] = null


@rpc("authority", "call_local")
func _take_item_client(slot_id: int):
	#var id = _slots[slot_id]
	set_slot(slot_id, null)
	#_slots[slot_id] = null
	#var i = 0
	#for it in _items:
		#if it.id == id:
			#_items.remove_at(i)
			#break
		#i += 1
