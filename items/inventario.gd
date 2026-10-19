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

@rpc("authority", "call_remote")
func set_slot(slot_id, item: Item):
	if slot_id in _slots:
		if _slots[slot_id].validar_tipo(item):
			_slots[slot_id].item = item
		else: printerr("Tipo de item invalido para el slot ", slot_id)
	else: printerr("Slot no existe: ", slot_id)


func get_front() -> Node:
	return null


#region Manejo de items en el servidor
# la cantidad viene aqui con el dto
# Intentar hacer el chequeo de visibilidad una sola vez
func server_add_item(item_dto: Dictionary, slot_id):
	if multiplayer.is_server():
		if has_slot(slot_id):
			var slot = _slots[slot_id]
			if slot.item:
				if slot.item.item_type_path == item_dto.type_id:
					if slot.item.cantidad + item_dto.cantidad <= slot.item.max_stack:
						# solo modificar la cantidad, porque un item del mismo tipo ya esta en el slot
						call_visibility(_modificar_cantidad, 
							[slot_id, item_dto.cantidad], slot)
					else:
						push_error("No puede sobrepasarse el max_stack de item: ", slot.item.nombre, " en slot ", slot_id, " (", item_dto.cantidad, " + ", slot.item.cantidad, " > ", slot.item.max_stack, ")")
				else:
					push_error("No se puede sobreescribir item de tipo ", slot.item.item_type_path, " en slot ", slot_id, " con un item de tipo ", item_dto.type_id)
					pass
			else: # añadir nuevo item
				if slot.validar_tipo(item_dto.type_id):
					call_visibility(_add_item_client,
						[item_dto, slot_id], slot)
				else:
					printerr("El tipo del objeto pasado es invalido: ", item_dto.type_id, " vs ", slot.tipo.resource_path)
		else: printerr("Slot invalido: ", slot_id)


func server_take_item(slot_id: int, cantidad: int):
	if multiplayer.is_server():
		if has_slot(slot_id):
			var slot = _slots[slot_id]
			if slot.item:
				if slot.item.cantidad >= cantidad:
					call_visibility(_modificar_cantidad,
						[slot_id, -cantidad], slot)
				else:
					printerr("Cantidad de retiro mayor que la cantidad del item en slot: ", slot_id)
			else:
				printerr("No hay item en slot ", slot_id)
		else:
			printerr("Slot invalido: ", slot_id)


func server_take_item_id(item_id: int, cantidad: int):
	if multiplayer.is_server():
		var slot_id = get_item_slot(item_id)
		if slot_id != -1:
			server_take_item(slot_id, cantidad)
		else:
			printerr("Item no encontrado: ", item_id)


## Mover items de un slot a otro dentro del mismo inventario. No convierte nada en DTO para slots privados
@rpc("any_peer", "call_local")
func mover_item_local(from_slot_id: int, to_slot_id: int, cantidad: int):
	if multiplayer.is_server() and validar_sesion(multiplayer.get_remote_sender_id()):
		if has_slot(from_slot_id) and has_slot(to_slot_id):
			var from_slot = _slots[from_slot_id]
			var to_slot = _slots[to_slot_id]
			# Validar tipos del item 
			if from_slot.validar_tipo(to_slot.item) and to_slot.validar_tipo(from_slot.item) and \
			(to_slot.item == null or to_slot.item.item_type_path == from_slot.item.item_type_path):
				# Mover dependiendo de la visibilidad
				var mov_item: Item = from_slot.item.duplicar_item()
				if cantidad < mov_item.cantidad: # si no se lleva todo el item
					# nuevo item con nuevo id
					ItemManager.registrar_item(mov_item)
					mov_item.cantidad = cantidad
				# tomar de un lado
				call_visibility(_modificar_cantidad,
					[from_slot_id, -cantidad], from_slot)
				# añadir en el otro
				if to_slot.item and to_slot.item.item_type_path != mov_item.item_type_path and not from_slot.item:
					set_slot(from_slot_id, to_slot.item)
					set_slot(to_slot_id, mov_item)
					call_visibility(_add_item_client, 
						[from_slot_id, to_slot.item.to_dto()],
						from_slot, false)
					call_visibility(_add_item_client, 
						[to_slot_id, mov_item.to_dto()],
						to_slot, false)
				else:
					server_add_item(mov_item.to_dto(), to_slot_id)
			else: printerr("Tipo de item incompatible con el slot")
		else: printerr("Id de slot invalido")


# Aqui podria hacerse que, al llamar a la funcion en el servidor, esta retorne un bool que lleve en si la validacion; y si ese bool es verdadero, se llame tambien en el cliente
func call_visibility(callable: Callable, args: Array, slot: Slot, call_on_server: bool = true):
	if multiplayer.is_server():
		# primero en el servidor, si este lo permite
		if call_on_server:
			callable.callv(args)
		# luego en los clientes
		match slot.visibility:
			Slot.Visibility.PUBLIC_SLOT: # todos los clientes
				callable.rpc(args)
			Slot.Visibility.PRIVATE_SLOT:
				if owner_id != 1: # cliente dueño, si no es el servidor
					callable.rpc_id(owner_id, args)

#endregion


#region Manejo de items en el cliente

@rpc("authority", "call_remote")
func _add_item_client(item_dto: Dictionary, slot_id: int):	
	var new_item = Item.new_from_dto(item_dto)
	set_slot(slot_id, new_item)


@rpc("authority", "call_remote")
func _modificar_cantidad(slot_id: int, cantidad: int):
	var item = _slots[slot_id].item
	if item:
		var nueva_cantidad = item.cantidad + cantidad
		if nueva_cantidad >= 0:
			if nueva_cantidad <= item.max_stack:
				item.cantidad = nueva_cantidad
				if item.cantidad == 0:
					set_slot(slot_id, null)
			else:
				printerr("No se puede sobrepasar la cantidad maxima de stack del item (", item.cantidad, " + ", cantidad, " > ", item.max_stack, ")")
		else:
			printerr("Cantidad de retiro mayor que la cantidad del item en slot ", slot_id, " (", item.cantidad, " + ", cantidad, ")")
	else:
		printerr("No hay item en slot ", slot_id)

#endregion

#region Funciones de intercambio

## Toma del inventario inv_origen_path 'cantidad' cantidad de items de su slot src_slot_id y colocalos en mi slot dest_slot_id. 
## Esto se llama en el inventario que recibe el item intercambiado
@rpc("any_peer", "call_local")
func intercambio(inv_origen_path: NodePath, src_slot_id: int, cantidad: int, dest_slot_id: int):
	if multiplayer.is_server() and validar_sesion(multiplayer.get_remote_sender_id()):
		var inventario_origen = get_node(inv_origen_path)
		if inventario_origen is Inventario:
			var item_dto_recibido = inventario_origen.enviar_item(
				self, src_slot_id, cantidad)
			if item_dto_recibido != {}:
				server_add_item(item_dto_recibido, dest_slot_id)
		else:
			printerr("Ruta al inventario invalida: ", inv_origen_path)

## Funcion de validacion para intercambios, que se llama en el inventario que envia el item intercambiado. Aqui, por ejemplo, Tienda puede decidir no enviar el item si el player no tiene baro
func enviar_item(_inv_dest: Inventario, src_slot: int, cantidad: int) -> Dictionary:
	if multiplayer.is_server():
		if has_slot(src_slot) and _slots[src_slot].item:
			if _slots[src_slot].item.cantidad >= cantidad:
				server_take_item(src_slot, cantidad)
				return get_slot(src_slot).item.to_dto()
			else: printerr("No hay suficientes items en el slot")
		else: printerr("Slot invalido: ", src_slot)
	else: printerr("enviar_item solo puede llamarse en el servidor")
	return {}

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

func get_slot(slot_id) -> Slot:
	return _slots.get(slot_id, null)

func has_item(id) -> bool:
	return get_item(id) != null

func has_enough_item(id, cantidad):
	var item = get_item(id)
	return item and item.cantidad >= cantidad

func has_slot(id) -> bool:
	return id in _slots

#endregion
