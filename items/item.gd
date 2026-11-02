class_name Item extends Resource
## Representa un item en el juego, lo mismo una instancia de item que un tipo de item (estos ultimos son recursos almacenados en disco)
##
## Items tienen una triple funcion:
## 1. Tipos genericos de items, guardados como recursos y usados por ItemManager para generar nuevos items
##
## 2. Items en el inventario o equipados, donde tienen un id unico y pueden contener estado
##
## 3. Envoltura como item de objetos equipados (p. ej. armas) donde se guarda su estado, permitiendo la interaccion con el sistema de items
## [p]Esta triple función determina una división en sus propiedades: la misma clase tiene propiedades de tipo (inmutables, compartidas entre todas las instancias: nombre, precio, max_stack) y propiedades de instancia (propias de cada instancia del item: id, cantidad). Lo hacemos de este modo para evitar un árbol duplicado de herencia: por ejemplo, si WeaponItem contiene la propiedad ammo (instancia) y WeaponItemType contiene max_ammo (tipo) entonces estamos obligados a especificar un ItemType por cada Item, duplicando el árbol de herencia de Item, lo cual es engorroso. La desventaja es que se sobreacumulan datos en la única clase Item que queda, pero tampoco es demasiado problema.[/p]
## [p]Cada vez que se vaya a transferir un item por la red, debe llamarse a to_dto y el receptor debe convertirlo de vuelta a Item con new_from_dto. Esto significa que en el DTO que viaja debe ir toda la informacion relevante de estado del item, necesaria para reproducir el item tal y como estaba antes de ser convertido en dto, pero creando de nuevo los datos serializables (que no se pueden transferir y no van en el DTO).[/p]


#region Campos de clase

## Ruta al recurso que sirve de modelo o clase del item. Funciona como id del tipo de item, que ItemManager setea cuando lo carga desde el disco. Cada item se construye mediante ItemManager a partir de uno de estos recursos.
@export var item_type_path: String = resource_path
## Nombre del item que se mostrara en el inventario
@export var nombre: String
## Precio de la unidad del item para operaciones de venta. En ventas del inventario del jugador, se multiplica este precio por la cantidad de items vendidos
@export var precio: float
## Máximo que se puede stackear el item. Con 0 puede stackear infinitamente
@export var max_stack: int = 1
## Ruta del icono que identifica este item en la tienda o el inventario
@export_file var icon_path: String
## Ruta a la escena que contiene el objeto que representa este item
@export_file("*.tscn") var item_scene_path: String
## Informacion para añadir en el tooltip del item
@export_multiline() var tooltip_text: String


static func instanciar(item_type: Item) -> Item:
	var item_instance = item_type.duplicate_deep()
	item_instance.item_type_path = item_type.item_type_path
	return item_instance

#func _validate_property(property: Dictionary) -> void:
	#if property.name == "item_type_path":
		#print("modified item_type_path")
		# Esto no duplica ni un carajo
		#property.usage |= PROPERTY_USAGE_ALWAYS_DUPLICATE
#endregion

#region Campos de instancia

## ID unico que identifica al item. El servidor lo establece antes de crearlo y luego se lo pasa a todos los peers, de modo que para una sincronizacion "legitima" todos los clientes deben tener los mismos items con los mismos id's en cada player
var id: int = 0:
	set(value):
		if id == 0: # El ID es de solo lectura, se escribe solo al crearse
			id = value

## Cantidad de elementos stackeados de este item
## Como la cantidad suele variar y en muchos casos se necesita observarla, se define como propiedad fantasma haciendo frontend a un Observable
var cantidad: int:
	set(value): cantidad_prop.value = value
	get(): return cantidad_prop.value

var cantidad_prop := Observable.new(1, Callable(),
	func(new_cantidad, _old_cantidad):
		if not stack_size_valido(new_cantidad):
			printerr("max_stack superado")
			return false
)

func stack_size_valido(size: int):
	return max_stack == 0 or size <= max_stack


## Referencia al objeto que el item representa en el inventario. 
var object: Object = null:
	set(value): 
		# Si la clase (o subclase) permite este objeto, lo seteamos
		if _validate_object(value):
			object = value
		else:
			printerr("El objeto pasado no es valido")

func _validate_object(_object):
	return true

func duplicar_object() -> Object:
	return _generate_object(self, to_dto())

func validar_slot(_slot: Slot) -> bool:
	return true

#endregion

## Genera un DTO con los datos de instancia necesarios para que este item pueda ser reproducido en otro peer remoto
func to_dto() -> Dictionary:
	return {
		"type_id": item_type_path,
		"id": id,
		"cantidad": cantidad
	}

# Esto existe porque el item tiene que registrarse en el servidor y crearse en los clientes. Con esta funcion se crea el dto transferido. Este dto, por otra parte, debe ser un diccionario, puesto que los rpc no serializan objetos
static func new_from_dto(dto: Dictionary) -> Item:
	var item_type = instanciar(ItemManager.get_item_type(dto.type_id))
	# A partir de aqui, le dejamos al tipo de item generar la nueva instancia. Con esto podemos acceder a los datos de tipo nativamente
	return item_type.inicializar_item(item_type, dto)


#region Funciones de tipo
## Función que llama el item modelo de tipo (cargado desde ItemManager) para instanciar un nuevo item a partir de sus datos de clase y de un DTO con los datos de instancia
func inicializar_item(new_item: Item, dto: Dictionary):
	# Propiedades de tipo
	_copy_type_properties(new_item)
	# Propiedades de instancia
	_copy_instance_properties(new_item, dto)
	new_item.object = _generate_object(new_item, dto)
	return new_item

## Copia de forma rápida todas las variables del script que estén marcadas como exportadas. En la práctica estas son casi siempre las variables de tipo, las que se muestran en el inspector
func _copy_type_properties(item: Item):
	#item.item_type_path = item_type_path
	for property in get_property_list():
		# propiedades exportadas del script
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_EDITOR:
			item.set(property.name, get(property.name))

## Aqui se copian datos de instancia que pertenezcan al item en sí (id, cantidad...), no al object, puesto que estas se almacenan en el object, que es la única fuente de verdad (además, puede haber setters personalizados para estas propiedades, lo cual complejizaría aún más la operación, pues estos setters pueden intentar acceder a un object que todavía no está creado). Para inicializar el object, sobreescribir _generate_object
func _copy_instance_properties(item: Item, dto: Dictionary):
	item.id = dto.id
	item.cantidad = dto.cantidad

## Genera y asigna la propiedad object, instanciando la escena indicada en la propiedad class_item_scene_path. Se puede extender para inicializar el objeto una vez creado con los datos del DTO
@warning_ignore("unused_parameter")
func _generate_object(item: Item, dto: Dictionary) -> Object:
	if not item_scene_path.is_empty():
		return load(item_scene_path).instantiate()
	return null


func duplicar_item() -> Item:
	var new_item = Item.instanciar(self)
	var item_dto = to_dto()
	_copy_instance_properties(new_item, item_dto)
	new_item.object = _generate_object(new_item, item_dto)
	return new_item

#endregion


func get_tooltip(slot_text: String) -> String:
	return \
"[font_size=16]{nombre}[/font_size]
[p][color=gainsboro]{text}[/color][/p]
[p][font_size=10][color=darkgray]{slot_text}[/color][/font_size][/p]
" \
.format({
	"nombre": nombre,
	"text": tooltip_text,
	"slot_text": slot_text
})
