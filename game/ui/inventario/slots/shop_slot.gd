@tool
class_name ShopSlot extends UISlot

## Como todos los tipos de inventario van a usar esta clase UISlot, la necesidad de unificar los tipos de inventario viene de aqui. El slot debe tener cosas como el _drop_data, que lo obliga a interactuar en terminos de tienda y demás.
## Y si drop_data fuera una señal, en plan "a mí me dropean cosas, haz lo que tú entiendas con ellas". El inventario que contiene el slot podría recibir esa señal, recibir los datos de dropeo y del inventario de origen. Tanto el inventario que emitió el dropeo, como el que lo recibe, pueden definir funciones de validación personalizadas. 


@export var item: Item:
	set(value):
		item = value
		if inventario:
			slot.item_prop.value = value

@export var shop_cantidad: int = 1:
	set(value):
		shop_cantidad = value
		if shop_cantidad != 1: cantidad().text = str(shop_cantidad)
		else: cantidad().text = ""


func set_slot(value: Slot):
	slot = value
	slot.item_prop.value = item
	slot.item_prop.connect_init(observar_item)

func set_inventario(value):
	if value is Tienda:
		inventario = value
	else:
		printerr("Tipo de inventario incorrecto")


func observar_item(new_item: Item, _old_item: Item):
	if new_item:
		new_item.item_type_path = new_item.resource_path
		textura().texture = load(new_item.icon_path)
		cantidad().show()
		%nombre.text = new_item.nombre
		%precio.text = str(int(new_item.precio))
	else:
		textura().texture = null
		cantidad().hide()
		%nombre.text = ""
		%precio.text = ""


func textura() -> TextureRect: return $panel/margin/textura
func margin() -> MarginContainer: return $panel/margin
func cantidad() -> Label: return $panel/Control/cantidad


func _generar_item_data() -> ItemDTO:
	var data = super._generar_item_data()
	data.cantidad = shop_cantidad
	return data


func _generar_preview() -> Control:
	var preview = duplicate() # $panel.duplicate()
	preview.get_node("%precio").hide()
	return preview


#func as_drag_slot():
	#cantidad().set_anchors_preset(PRESET_TOP_LEFT)
	#cantidad().position = Vector2(-15, -20)
	#position -= Vector2(20, 20)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Se puede dropear cualquier cosa en la tienda porque se puede vender cualquier cosa.
	return data is ItemDTO and data.source_inventory is InventarioPlayer


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	## vender
	if data.source_inventory != inventario and data.source_inventory is InventarioPlayer:
		inventario.intercambio.rpc_id(1, \
			data.source_inventory.get_path(), data.src_slot_id,
			data.cantidad, slot.slot_id)
