extends Control

@export var tienda: Tienda

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data.source == ItemSlot.ItemSource.INVENTORY

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	tienda.request_venta.rpc_id(1, data.item_id)
