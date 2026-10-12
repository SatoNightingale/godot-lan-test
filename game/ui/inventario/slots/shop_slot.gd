@tool
class_name ShopSlot extends UISlot

## Como todos los tipos de inventario van a usar esta clase UISlot, la necesidad de unificar los tipos de inventario viene de aqui. El slot debe tener cosas como el _drop_data, que lo obliga a interactuar en terminos de tienda y demás.
## Y si drop_data fuera una señal, en plan "a mí me dropean cosas, haz lo que tú entiendas con ellas". El inventario que contiene el slot podría recibir esa señal, recibir los datos de dropeo y del inventario de origen. Tanto el inventario que emitió el dropeo, como el que lo recibe, pueden definir funciones de validación personalizadas. 


@export var item: Item:
	set(value):
		item = value
		if inventario:
			slot.item_prop.value = value

@export var cantidad: int = 1:
	set(value):
		cantidad = value
		if cantidad != 1: $panel/cantidad.text = str(cantidad)
		else: $panel/cantidad.text = ""


func set_slot(value: Slot):
	slot = value
	slot.item_prop.value = item
	slot.item_prop.connect_init(observar_item)

func set_inventario(value):
	if value is Tienda:
		inventario = value
	else:
		printerr("Tipo de inventario incorrecto")


func observar_item(new_item, old_item):
	super.observar_item(new_item, old_item)
	if new_item:
		new_item.item_type_path = new_item.resource_path
		%nombre.text = new_item.nombre
		%precio.text = str(int(new_item.precio))
		if cantidad != 1:
			$panel/cantidad.text = str(cantidad)
	else:
		%nombre.text = ""
		%precio.text = ""
		$panel/cantidad.text = ""


func textura() -> TextureRect: return $panel/margin/textura
func margin() -> MarginContainer: return $panel/margin


func _generar_preview() -> Node:
	var preview = $panel.duplicate()
	preview.get_node("precio").hide()
	return preview


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Se puede dropear cualquier cosa en la tienda porque se puede vender cualquier cosa.
	return data is ItemDTO and data.source_inventory is InventarioPlayer


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	## vender
	if data.source_inventory != inventario and data.source_inventory is InventarioPlayer:
		inventario.intercambio.rpc_id(1, \
			data.source_inventory.get_path(),
			data.item.to_dto(), slot.slot_id)
