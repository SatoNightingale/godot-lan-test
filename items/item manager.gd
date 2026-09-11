extends Node

var max_id = 0

var _item_info_cache : Dictionary[String, ItemInfo]
var _cache_max_length = 20
var _cache_order = []


func new_item_dto(info: ItemInfo) -> Dictionary:
	if multiplayer.is_server():
		var item = info.as_item_dto()
		registrar_item(item)
		return item
	printerr("get_new_item solo puede ser llamado por el servidor")
	return {}


func new_item_dto_from_path(path: String) -> Dictionary:
	var info = get_item_info(path)
	return new_item_dto(info) if info != null else {}


## Toda vez que se cree un item, debe registrarse en el servidor llamando a esta funcion, y el id devuelto debe pasarse a todos los peers
#@rpc("any_peer", "call_local")
func registrar_item(item: Dictionary) -> int:
	if multiplayer.is_server(): # item.id == 0:
		max_id += 1
		item.id = max_id
		return max_id
	return 0


func item_info_exists(path: String):
	return path in _item_info_cache


func get_item_info(path: String) -> ItemInfo:
	if not item_info_exists(path):
		printerr("El item '", path, "' no existe")
		return null
	if _item_info_cache[path] != null:
		# colocamos al final, como la mas recientemente usada
		_cache_order.erase(path)
		_cache_order.append(path)
		return _item_info_cache[path]
	var info = load(path)
	if info:
		_item_info_cache[path] = info
		_cache_order.append(path)
		# para que la cache no se llene demasiado, liberamos la menos recientemente usada cuando llegue al maximo de capacidad (algoritmo LRU)
		if _cache_order.size() > _cache_max_length:
			var oldest_path = _cache_order.pop_front()
			#_item_info_cache[oldest_path].free()#pero no hay huevos
			_item_info_cache[oldest_path] = null
		return info
	else:
		printerr("No se pudo cargar el item '", path ,"'")
		return null


func _ready() -> void:
	_build_item_index()


func _build_item_index():
	const item_dir = "res://items/classes"
	var dir = DirAccess.open(item_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while not file_name.is_empty():
			if file_name.ends_with("_item.tres") or file_name.ends_with("_item.res"):
				var path = item_dir.path_join(file_name)
				_item_info_cache[path] = null
			file_name = dir.get_next()
	else:
		printerr("No se pudo cargar el caché de items")
