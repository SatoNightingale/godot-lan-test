class_name Slot extends Resource

const PRIVATE_SLOT = 0
const PUBLIC_SLOT = 1

enum Visibility {
	PRIVATE_SLOT,
	PUBLIC_SLOT,
	#INVALID_SLOT, # id del slot invalido, no existe
}

@export var tipo: Script
@export var visibility: Visibility

var slot_id: int

var item: Item:
	set(value):
		item_prop.value = value
	get():
		return item_prop.value

var item_prop := Observable.new(null)


## Como el operador is solo funciona para tipos constantes, e is_instance_of con Scripts no recorre hacia arriba la jerarquia de herencia, tenemos que implementarlo nosotros.
## Shame on you, Godot Engine
func is_instance_of_script(object: Object, script: Script):
	var base_script: Script = object.get_script()
	while base_script != null:
		if base_script == script:
			return true
		base_script = base_script.get_base_script()
	return false


func validar_tipo(it: Item) -> bool:
	# Todos los slots son nullables, asi que siempre se puede poner null en item
	# Por otra parte, si el tipo es null, cabe cualquier item
	return it == null or tipo == null or is_instance_of_script(it, tipo)
