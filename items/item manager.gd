extends Node

var max_id = 0

## Aqui se referencian los modelos de items, recursos guardados en el disco (en res://items/classes/) que funcionan como "clases" para instanciar los items usados en el juego a partir de ellos. No deben ser modificadas, cada instancia generada a partir de ellos debe crearse con duplicate_deep()
## Se podria hacer mas rapido si en vez de la ruta utilizamos como clave el ResourceUID, ya que internamente guarda una cache de todos los recursos. Quizas nuestra propia cache no haga falta
var _item_type_index : Dictionary[String, Item]

var _cache_max_length = 20
var _cache_order = []

## Obtiene el dto de un nuevo item a partir de su tipo de item, referenciado por su resource_path. El nuevo item vendrá sellado con su id único y con los datos de instancia por defecto, más los datos de su tipo
func new_item_dto(path: String) -> Dictionary:
	if multiplayer.is_server():
		var item = Item.instanciar(get_item_type(path))
		if item:
			registrar_item(item)
			return item.to_dto()
		else: printerr("Error al instanciar item path: ", path)
	else:
		printerr("new_item_dto solo puede ser llamado por el servidor")
	return {}


func new_from_dto(item_dto: Dictionary) -> Item:
	if multiplayer.is_server():
		var default_dto = get_item_type(item_dto.type_id).to_dto()
		var item = Item.new_from_dto(item_dto.merged(default_dto))
		registrar_item(item)
		return item
	else:
		printerr("new_from_dto solo puede ser llamado por el servidor")
		return null


# Toda vez que se cree un item, debe registrarse en el servidor llamando a esta funcion, y el id devuelto debe pasarse a todos los peers
#@rpc("any_peer", "call_local")
func registrar_item(item: Item) -> int:
	if multiplayer.is_server(): # item.id == 0:
		max_id += 1
		item.id = max_id
		return max_id
	return 0


func item_type_exists(path: String) -> bool:
	return path in _item_type_index


## Obtiene un item modelo de tipo (no instancia) usado solo como referencia para acceder a los datos de tipo de un item de su tipo. Nótese que una información valiosa del objeto retornado es su propio tipo (herdado de Item), ya que podría definir DTO's o funciones especiales
func get_item_type(path: String) -> Item:
	if not item_type_exists(path):
		printerr("El item '", path, "' no existe")
		return null
	if _item_type_index[path] != null:
		# colocamos al final, como la mas recientemente usada
		_cache_order.erase(path)
		_cache_order.append(path)
		return _item_type_index[path]
	var item: Item = load(path)
	if item:
		item.item_type_path = path
		_item_type_index[path] = item
		_cache_order.append(path)
		# para que la cache no se llene demasiado, liberamos la menos recientemente usada cuando llegue al maximo de capacidad (algoritmo LRU)
		if _cache_order.size() > _cache_max_length:
			var oldest_path = _cache_order.pop_front()
			_item_type_index[oldest_path].free() # sí hay huevos
			_item_type_index[oldest_path] = null
		return item
	else:
		printerr("No se pudo cargar el item '", path ,"'")
		return null


func _ready() -> void:
	print("Registrando items...")
	_build_item_type_index("res://items/types")
	print("Todos los items registrados")


func _build_item_type_index(dir_path: String):
	var files = ResourceLoader.list_directory(dir_path)
	for file_name in files:
		if not file_name.ends_with("/"):
			if file_name.ends_with("_item.tres") or file_name.ends_with("_item.res") or file_name.ends_with("_item.tres.remap"):
				if file_name.ends_with(".remap"):
					file_name = file_name.get_basename()
				var path = dir_path.path_join(file_name)
				# Luego cada valor de path se carga y se asigna a medida que se van utilizando
				_item_type_index[path] = null
				print("Item registrado: ", path)
		else: # directorio
			_build_item_type_index(dir_path.path_join(file_name))

#region Items de mundo (dropeados en el mapa)
## La lista de items tirados en el piso en el mapa. Debe ser publica, tener el mismo contenido para todos los peers, por la siguiente razon: si un player va a tomar un item del piso, el codigo de tocar el item y demas interaccion visual se ejecuta en su maquina; el player que representa a su peer_id tambien esta en su maquina, y para validar hace falta este player y el item en cuestion sacado de esta lista.
## Tambien se le podria enviar al servidor el id del player...
## Supongo que no importa mucho si esta lista es publica o privada. Un peer hackeado podria ver la ubicacion de todos los world_items directo en el arbol de escenas, asi que...
var _world_items: Dictionary[int, NodePath]

# necesitamos una manera de definir una instancia de item, con datos de instancia, de modo que la podamos usar como recurso para inicializar items que no empiecen "de cero" como en new_item_dto

func register_world_items(node_to_scan: Node):
	if multiplayer.is_server():
		for child in node_to_scan.get_children():
			if child is WorldItem:
				child.item = new_from_dto(child.instance_data)
				register_world_item(child)
			if child.get_child_count() > 0:
				register_world_items(child)

func register_world_item(world_item: WorldItem):
	_world_items[world_item.item.id] = world_item.get_path()


# esto en la practica funciona como un multiplayer spawner... excepto que el spawner colocaria los items en una ruta fija, y esto permite una flexibilidad que podria dar muchos problemas...
@rpc("authority", "call_local")
func add_world_item(item_dto: Dictionary, ref_node: NodePath, pos: Vector2, as_child := true):
	var world_item = preload("res://items/world_item.tscn").instantiate()
	world_item.item = Item.new_from_dto(item_dto)
	world_item.position = pos
	world_item.ready.connect(register_world_item.bind(world_item))
	var parent = get_node(ref_node)
	if as_child:
		parent.add_child(world_item, true)
	else:
		parent.call_deferred("add_sibling", world_item, true)

@rpc("authority", "call_local")
func remove_world_item(item_path: NodePath):
	var world_item = get_node(item_path)
	_world_items.erase(world_item.item.id)
	world_item.get_parent().remove_child(world_item)
	world_item.queue_free()

#func remove_world_item(world_item: WorldItem):
	#_world_items.erase(world_item.item.id)

func get_world_item(item_id) -> WorldItem:
	return get_node(_world_items[item_id]) as WorldItem

#endregion

#region Verificacion de parentesco y herencia de items

## Funciones para verificar si el item es instancia de una clase, sea esta un tipo de item o un script del cual el item hereda. Hay variantes para referenciar las clases por los objetos Item y Script o por las rutas a estos recursos

func is_instance_of_type(item: Item, clase: Item) -> bool:
	return item.item_type_path == clase.item_type_path

func is_instance_of_type_path(item: Item, clase: String) -> bool:
	return item_type_exists(clase) and \
		item.item_type_path == clase

func is_instance_of_script(item: Item, clase: Script) -> bool:
	var base_script: Script = item.get_script()
	while base_script != null:
		if base_script == clase:
			return true
		base_script = base_script.get_base_script()
	return false

func is_instance_of_script_path(item: Item, clase: String) -> bool:
	return is_instance_of_script(item, load(clase) as Script)

func type_is_instance_of_script(type: String, clase: Script) -> bool:
	var item_type = get_item_type(type)
	return is_instance_of_script(item_type, clase)

func type_is_instance_of_script_path(type: String, clase: String) -> bool:
	var item_type = get_item_type(type)
	return is_instance_of_script_path(item_type, clase)

#endregion
