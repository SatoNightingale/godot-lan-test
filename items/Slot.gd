class_name Slot extends Resource

const PRIVATE_SLOT = 0
const PUBLIC_SLOT = 1

enum Visibility {
	PRIVATE_SLOT = 0,
	PUBLIC_SLOT = 1,
	#INVALID_SLOT, # id del slot invalido, no existe
}

@export var tipo: Script = null
@export var visibility: Visibility = Visibility.PUBLIC_SLOT

@export_group("Datos de inicializacion")
@export var init_item_type: Item = null
@export var instance_data: Dictionary[StringName, Variant] = {}

var slot_id: int

var item: Item:
	set(value):
		item_prop.value = value
	get():
		return item_prop.value

var item_prop := Observable.new(null)


func validar_tipo(item_type) -> bool:
	# Todos los slots son nullables, asi que siempre se puede poner null en item
	# Por otra parte, si el tipo es null, cabe cualquier item
	if item_type == null or tipo == null:
		return true
	if item_type is Item:
		return ItemManager.is_instance_of_script(item_type, tipo)
	else: if item_type is String:
		return ItemManager.type_is_instance_of_script(item_type, tipo)
	else:
		printerr("Tipo invalido de item_type")
		return false
