extends Node

var max_id = 0

## Aqui se referencian los modelos de items, recursos guardados en el disco (en res://items/classes/) que funcionan como "clases" para instanciar los items usados en el juego a partir de ellos. No deben ser modificadas, cada instancia generada a partir de ellos debe crearse con duplicate_deep()
var _item_type_index : Dictionary[String, Item]

var _cache_max_length = 20
var _cache_order = []

# Si un item esta tirado en el suelo en un cliente cualquiera, ¿cómo le digo al servidor por rpc que pickee ese item para un player? Debe haber una manera general de buscar items por su id
var _item_db: Dictionary[int, Item]

## Obtiene el dto de un nuevo item a partir de su tipo de item, referenciado por su resource_path. El nuevo item vendrá sellado con su id único y con los datos de instancia por defecto, más los datos de su tipo
func new_item_dto(path: String) -> Dictionary:
	if multiplayer.is_server():
		#var item_type = get_item_type(path)
		#print(item_type.item_type_path)
		var item = Item.instanciar(get_item_type(path))
		#print(item.item_type_path)
		#print(item.nombre, " ", item.precio, " ", item.max_stack)
		if item:
			registrar_item(item)
			return item.to_dto()
		else: printerr("Error al instanciar item path: ", path)
	else:
		printerr("new_item_dto solo puede ser llamado por el servidor")
	return {}


# Toda vez que se cree un item, debe registrarse en el servidor llamando a esta funcion, y el id devuelto debe pasarse a todos los peers
#@rpc("any_peer", "call_local")
func registrar_item(item: Item) -> int:
	if multiplayer.is_server(): # item.id == 0:
		max_id += 1
		item.id = max_id
		_item_db[max_id] = item
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
	_build_item_type_index()


func _build_item_type_index():
	const item_dir = "res://items/types"
	var dir = DirAccess.open(item_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while not file_name.is_empty():
			#print(file_name)
			if file_name.ends_with("_item.tres") or file_name.ends_with("_item.res") or file_name.ends_with("_item.tres.remap"):
				if file_name.ends_with(".remap"):
					file_name = file_name.get_basename()
				var path = item_dir.path_join(file_name)
				# Luego cada valor de path se carga y se asigna a medida que se van utilizando
				_item_type_index[path] = null
				#print(path)
			file_name = dir.get_next()
	else:
		printerr("No se pudo cargar el caché de items")


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
