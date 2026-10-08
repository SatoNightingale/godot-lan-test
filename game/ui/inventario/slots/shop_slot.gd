@tool
class_name ShopSlot extends Slot

## Como todos los tipos de inventario van a usar esta clase Slot, la necesidad de unificar los tipos de inventario viene de aqui. El slot debe tener cosas como el _drop_data, que lo obliga a interactuar en terminos de tienda y demás.
## Y si drop_data fuera una señal, en plan "a mí me dropean cosas, haz lo que tú entiendas con ellas". El inventario que contiene el slot podría recibir esa señal, recibir los datos de dropeo y del inventario de origen. Tanto el inventario que emitió el dropeo, como el que lo recibe, pueden definir funciones de validación personalizadas. 
## Y no habría que pasar por una autoridad superior para efectuar una compra? Tienda puede no dejarte arrastrar sus slots si no tienes dinero, y que solo de tomarlos se haga la compra. Lo que pasa es que no tiene acceso a tu inventario ni por tanto a tu dinero... o sí?


## esto no es bool por la remota posibilidad de añadir un sistema de intercambio multipartito donde pueda haber un nuevo agente que no sea ni la tienda ni el player
#enum ItemSource {
	#INVENTORY,
	#SHOP
#}

#@export var item: Item: set = set_item
func set_item(value):
	super.set_item(value)
	if item:
		%nombre.text = item.nombre
		%precio.text = str(int(item.precio))
		#if _source == ItemSource.SHOP:
		#else:
			#%precio.text = ""
	else:
		%nombre.text = ""
		%precio.text = ""


func textura() -> TextureRect: return $panel/margin/textura
func margin() -> MarginContainer: return $panel/margin


#var tienda: Tienda
#var front_inventario: InventarioFront
#var inventory_role: Inventario.SlotRole
#var _source: ItemSource


#func _ready() -> void:
	#if is_in_group("inventory_slots"):
		#_source = ItemSource.INVENTORY
	#if is_in_group("shop_slots"):
		#_source = ItemSource.SHOP
	#super._ready()

func _generar_preview() -> Node:
	var preview = $panel.duplicate()
	preview.get_node("precio").hide()
	return preview


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# si puede realizar la operacion de vender
	# en data debe estar el inventario que pide la venta
	#if data.inventario is PlayerInventario:
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# vender
	#(inventario as Tienda).request_venta(data.item_id)
	pass
