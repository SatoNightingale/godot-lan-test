class_name Item extends RefCounted

## Esto devuelve el nombre de la clase a la que directamente pertenece cada objeto instanciado. Sobreescribir en cada subclase
func get_item_class() -> StringName:
	return "Item"

## ID unico que identifica al item. El servidor lo establece antes de crearlo y luego se lo pasa a todos los peers, de modo que para una sincronizacion "legitima" todos los clientes deben tener los mismos items con los mismos id's en cada player
var id: int = 0
# un poco desperdicio que item tenga nombre y precio (mismas propiedades de item_info) pero bueh...
## Nombre del item que se mostrara en el inventario
var nombre: String
## Precio del item para operaciones de venta
var precio: float
## Referencia al objeto que el item representa en el inventario. 
var object: Object = null
## Ruta al recurso que identifica al item en la tienda. Cada item se construye mediante ItemManager a partir de uno de estos recursos
var info_resource: String
## Ruta a la escena que contiene el objeto que representa este item
var item_scene_path: String


func to_dto() -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"precio": precio,
		"info_resource": info_resource,
		"item_scene_path": item_scene_path
	}

# Esto existe porque el item tiene que registrarse en el servidor y crearse en los clientes. Con esta funcion se crea el dto transferido. Este dto, por otra parte, debe ser un diccionario, puesto que los rpc no serializan objetos
# Si hubiera subclases de item, dto puede venir con un campo que indique la subclase desde la que se llamo a to_dto, lo que permitiria mandarselo a la herencia de este metodo en esa subclase y asi construir el item con datos personalizados (pero siempre serializables)
static func new_from_dto(dto: Dictionary) -> Item:
	var item = Item.new()
	item.id = dto.id
	item.nombre = dto.nombre
	item.precio = dto.precio
	item.info_resource = dto.info_resource
	item.item_scene_path = dto.item_scene_path
	if not dto.item_scene_path.is_empty():
		item.object = load(dto.item_scene_path).instantiate()
	return item
