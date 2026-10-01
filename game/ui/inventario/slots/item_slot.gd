@tool
class_name ItemSlot extends VBoxContainer


# esto no es bool por la remota posibilidad de añadir un sistema de intercambio multipartito donde pueda haber un nuevo agente que no sea ni la tienda ni el player
enum ItemSource {
	INVENTORY,
	SHOP
}

@export var item: Item:
	set(value):
		item = value
		if item:
			%textura.texture = load(item.icon_path)
			%nombre.text = item.nombre
			if _source == ItemSource.SHOP:
				%precio.text = str(int(item.precio))
			else:
				%precio.text = ""
		else:
			%textura.texture = null
			%nombre.text = ""
			%precio.text = ""

var tienda: Tienda
var front_inventario: InventarioFront
var inventory_role: Inventario.SlotRole
var _source: ItemSource


func _ready() -> void:
	if is_in_group("inventory_slots"):
		_source = ItemSource.INVENTORY
	if is_in_group("shop_slots"):
		_source = ItemSource.SHOP
	if item != null:
		item = item # llamar al setter para inicializar el slot


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item != null:
		var preview = $panel.duplicate()
		preview.get_node("precio").hide()
		set_drag_preview(preview)
		var drag_data
		if _source == ItemSource.INVENTORY:
			drag_data = {"source": _source, "item_id": item.id}
		else: if _source == ItemSource.SHOP:
			drag_data = {"source": _source, "item": item}
		return drag_data
	else:
		return null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Para comprar, arrastrar el item de la tienda al inventario
	# Para vender, arrastrar del inventario a la tienda. Tienda se ocupa del drag & drop del control shop_tabs en la tienda, pero como los slots estan encima, capturan el dropeo antes y por tanto deben especificar su codigo generico para vender
	return (data.source == ItemSource.SHOP and self._source == ItemSource.INVENTORY) or \
	(data.source == ItemSource.INVENTORY and self._source == ItemSource.SHOP)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# comprar
	if data.source == ItemSource.SHOP and self._source == ItemSource.INVENTORY:
		# Aqui realmente se intercambia de un inventario a otro
		front_inventario.try_comprar(data["item"], inventory_role)
	# vender
	if data.source == ItemSource.INVENTORY and self._source == ItemSource.SHOP:
		tienda.request_venta.rpc_id(1, data["item_id"])
	# Antes de hacer este par de acciones, mas bien habria que preguntarse por las especializaciones del slot y la accion que debe realizar en cada caso
