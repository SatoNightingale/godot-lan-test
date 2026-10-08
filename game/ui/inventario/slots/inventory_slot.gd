@tool
class_name InventorySlot extends Slot


func textura() -> TextureRect: return $margin/textura
func margin() -> MarginContainer: return $margin

func set_item(value: Item):
	item = value

@export var slot_role: int: ## Pero con slots del inventario del player
	set(value):
		slot_id = slot_role


func _generar_preview() -> Node:
	var preview = duplicate()
	if item.cantidad == 1:
		preview.get_node("%cantidad").hide()
	return preview

#
#
#func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	#return true
#
#
#func _drop_data(_at_position: Vector2, data: Variant) -> void:
	#pass
