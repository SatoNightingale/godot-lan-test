class_name Slot extends Resource

const PRIVATE_SLOT = 0
const PUBLIC_SLOT = 1

enum Visibility {
	PRIVATE_SLOT = 0,
	PUBLIC_SLOT = 1,
	#INVALID_SLOT, # id del slot invalido, no existe
}

## Tipo puede ser o bien un script de item (en cuyo caso permitiria todos los tipos de items generados a partir de ese script) o bien el recurso de un item o bien simplemente la ruta a ese recurso
var tipo
@export var tipo_script: Script:
	set(value): tipo_script = value; tipo = value
@export var tipo_item: Item:
	set(value): tipo_item = value; tipo = value
@export var tipo_string: String:
	set(value): tipo_string = value; tipo = value

@export var visibility: Visibility = Visibility.PUBLIC_SLOT

@export_group("Datos de inicializacion")
@export var init_item_type: Item = null
@export var instance_data: Dictionary[StringName, Variant] = {}

var slot_id: int

var item: Item:
	set(value):
		if validar_item(value) == false:
			printerr("el tipo del item pasado es incorrecto")
		item_prop.value = value
	get():
		return item_prop.value

var item_prop := Observable.new(null)

var extra_data: Dictionary

func validar_item(item_type) -> bool:
	# Todos los slots son nullables, asi que siempre se puede poner null en item
	# Por otra parte, si el tipo es null, cabe cualquier item
	if item_type == null or tipo == null:
		return true
	if tipo is Script:
		if item_type is Item:
			return ItemManager.is_instance_of_script(item_type, tipo)
		else: if item_type is String:
			return ItemManager.type_is_instance_of_script(item_type, tipo)
	else: if tipo is Item or tipo is String:
		var type = tipo.item_type_path if tipo is Item else tipo
		if item_type is Item:
			return type == item_type.item_type_path
		else: if item_type is String:
			return type == item_type
	printerr("Tipo invalido de item_type")
	return false


func inicializar_server():
	if init_item_type != null:
		item = ItemManager.new_from_dto(instance_data.merged({
			"type_id": init_item_type.item_type_path
		}))

func inicializar_client(id: int):
	if init_item_type != null:
		var default_dto = ItemManager.get_item_type(
			init_item_type.item_type_path).to_dto()
		item = Item.new_from_dto(instance_data.merged(
			default_dto.merged({"id": id}, true)
		))
