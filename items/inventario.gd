class_name Inventario extends Node
## Un inventario abstracto, que puede ser lo mismo el inventario de un player que el de un cofre o la tienda.
##
## Define un conjunto de items y un conjunto de slots. Cualquier item que se vaya a añadir debe ocupar un slot específico, pero el concepto de slot debe ser lo suficientemente flexible como para abarcar slots 'contenedores' o slots dentro de items. En el conjunto de items, sin embargo, deben ir todos los items del inventario, de forma que se puedan añadir o eliminar mediante los métodos básicos, solo conociendo el slot del item. Por eso, en principio el slot es solo la posicion en el arreglo de items que ocupa el item recien añadido
##
## El inventario tiene poco que hacer si se le manda a añadir un item en un slot que ya tiene un item equipado, o si se le manda a quitar un item de un slot que no tiene nada.
## Por defecto, todos los slots son publicos, es decir, cualquier cambio en ellos se refleja en todos los clientes. Para habilitar los slots privados, es decir, aquellos cuyos cambios solo se ven en el cliente propietario y en el servidor, se define el id de este cliente propietario. 

## El id del peer dueño del slot, el único (además del servidor) en el cual tienen efecto las operaciones privadas. Cuando es 0 el inventario es público, lo que significa que configurar cualquier slot como privado queda sin efecto y todos los cambios se actualizan en todos los clientes
var owner_id: int = 0

#region Manejo de sesiones
## Esto solo lo controla el servidor y solo en el adquiere valores (en los demas peers esta vacío). Contiene los ids de todos los peers que tienen una sesion abierta con este inventario, y que por tanto pueden modificarlo
var sesiones_abiertas: Array[int]

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
#endregion

## Todos los items del inventario viven en este diccionario, que les asigna a cada uno un slot. El -1 esta prohibido como indice, porque representa el slot invalido.
## get_item buscara en ese diccionario (y en sus potenciales sub-diccionarios si el item tiene slots a su vez) para devolver los items
## take_item tomara el id y buscara de igual forma que get_item, pero seteando a null
@export var _slots: Dictionary[int, Slot]
## Slots privados deben actualizarse solo en el cliente dueño y en el servidor


func set_slot(slot_id, item: Item):
	if slot_id in _slots:
		if _slots[slot_id].validar_tipo(item):
			_slots[slot_id].item = item
		else: printerr("Tipo de item invalido para el slot ", slot_id)
	else: printerr("Slot no existe: ", slot_id)


#region Manejo de items en el servidor

func server_add_item(item_dto: Dictionary, slot_id):
	if multiplayer.is_server():
		if has_slot(slot_id):
			var slot = _slots[slot_id]
			var item = Item.new_from_dto(item_dto)
			if slot.validar_tipo(item):
				# Primero: setear en el servidor
				set_slot(slot_id, item)
				# Luego en los clientes
				match slot.visibility:
					Slot.Visibility.PUBLIC_SLOT: # todos los clientes
						_add_item_client.rpc(item_dto, slot_id)
					Slot.Visibility.PRIVATE_SLOT:
						if owner_id != 1: # cliente dueño, si no es el servidor
							_add_item_client.rpc_id(owner_id, item_dto, slot_id)
			else: printerr("El tipo del objeto pasado es invalido: ", item.item_type_path, " vs ", slot.tipo.resource_path)
		else: printerr("Slot invalido: ", slot_id)


func server_take_item(slot_id: int):
	if multiplayer.is_server():
		if has_slot(slot_id):
			var slot = _slots[slot_id]
			_take_item_client(slot_id)
			match slot.visibility:
				Slot.Visibility.PUBLIC_SLOT:
					_take_item_client.rpc(slot_id)
				Slot.Visibility.PRIVATE_SLOT:
					_take_item_client.rpc_id(owner_id, slot_id)
		else:
			printerr("Slot invalido: ", slot_id)


func server_take_item_id(item_id: int):
	if multiplayer.is_server():
		var slot_id = get_item_slot(item_id)
		if slot_id != -1:
			server_take_item(slot_id)
		else:
			printerr("Item no encontrado: ", item_id)


## Mover items de un slot a otro dentro del mismo inventario. No convierte nada en DTO
@rpc("any_peer", "call_local")
func mover_item_local(from_slot_id: int, to_slot_id: int):
	if multiplayer.is_server() and validar_sesion(multiplayer.get_remote_sender_id()):
		if has_slot(from_slot_id) and has_slot(to_slot_id):
			var from_slot = _slots[from_slot_id]
			var to_slot = _slots[to_slot_id]
			# Validar tipos del item 
			if from_slot.validar_tipo(to_slot.item) and to_slot.validar_tipo(from_slot.item):
				# Siempre se refleja el cambio en el servidor
				mover_item_client(from_slot_id, to_slot_id)
				# Mover dependiendo de la visibilidad
				if from_slot.visibility == Slot.Visibility.PUBLIC_SLOT or \
				to_slot.visibility == Slot.Visibility.PUBLIC_SLOT:
					# desde o hacia un slot publico. Setearlo en todos los peers
					mover_item_client.rpc(from_slot_id, to_slot_id)
				else:
					# de slot privado a slot privado, solo setearlo local y en el servidor
					if owner_id != 1: # si no es el servidor
						mover_item_client.rpc_id(owner_id, from_slot_id, to_slot_id)
			else: printerr("Tipo de item incompatible con el slot")
		else: printerr("Id de slot invalido")
#endregion


#region Manejo de items en el cliente

@rpc("authority", "call_remote")
func _add_item_client(item_dto: Dictionary, slot: int):
	var item = Item.new_from_dto(item_dto)
	set_slot(slot, item)


@rpc("authority", "call_remote")
func _take_item_client(slot_id: int):
	set_slot(slot_id, null)


@rpc("authority", "call_remote")
func mover_item_client(from_slot_id: int, to_slot_id: int):
	var aux_item = _slots[from_slot_id].item
	set_slot(from_slot_id, _slots[to_slot_id].item)
	set_slot(to_slot_id, aux_item)

#endregion

#region Funciones de intercambio

## Esto se llama en el inventario que recibe el item intercambiado
@rpc("any_peer", "call_local")
func intercambio(inv_origen_path: NodePath, item_dto: Dictionary, dest_slot: int):
	if multiplayer.is_server() and validar_sesion(multiplayer.get_remote_sender_id()):
		var inventario_origen = get_node(inv_origen_path)
		if inventario_origen is Inventario:
			var item_recibido = inventario_origen.enviar_item(
				self, item_dto, dest_slot)
			if item_recibido:
				server_add_item(item_dto, dest_slot)
		else:
			printerr("Ruta al inventario invalida: ", inv_origen_path)

## Funcion de validacion para intercambios, que se llama en el inventario que envia el item intercambiado. Aqui, por ejemplo, Tienda puede decidir no enviar el item si el player no tiene baro
func enviar_item(_inv_dest: Inventario, item_dto: Dictionary, _slot_dest: int):
	if multiplayer.is_server():
		if has_item(item_dto.id):
			server_take_item_id(item_dto.id)
			return get_item(item_dto.id)
	else: printerr("enviar_item solo puede llamarse en el servidor")
	return null

#endregion

#region Funciones de ayuda (helpers)

func get_item(id) -> Item:
	for slot in _slots:
		if _slots[slot].item != null and _slots[slot].item.id == id:
			return _slots[slot].item
	return null

func get_item_slot(id: int) -> int:
	for slot in _slots:
		if _slots[slot].item != null and _slots[slot].item.id == id:
			return slot
	return -1

func has_item(id) -> bool:
	return get_item(id) != null

func has_slot(id) -> bool:
	return id in _slots

#endregion
