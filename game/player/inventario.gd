class_name Inventario extends Node


var player: Player

var items: Array[Item]

# weapon_item (y todos los slots del player) deben ser sincronizados
# entre los peers, aunque los demas items del inventario permanezcan
# locales y ocultos. Ademas, la operacion debe ser iniciada por el 
# servidor. El servidor y el cliente afectado deben realizar las
# mismas operaciones y tener siempre los mismos items
var weapon_item: Observable


func add_item(item: Item):
	items.append(item)
	if item.object is Weapon:
		weapon_item.value = item
		#weapon.queue_free()
		#weapon = item.object

func get_item(id: int) -> Item:
	for item in items:
		if item.id == id:
			return item
	return null

func has_item(id: int) -> bool:
	return get_item(id) != null

func take_item(id: int):
	var i = 0
	for item in items:
		if item.id == id:
			items.remove_at(i)
			break
		i += 1
	# si esta equipado, desequiparlo
	if weapon_item.value != null:
		if id == weapon_item.value.id:
			weapon_item.value = null
