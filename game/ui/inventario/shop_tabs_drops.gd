extends Control

@export var tienda: Tienda

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Se puede dropear cualquier cosa en la tienda porque se puede vender cualquier cosa.
	return data is UISlot.ItemDTO and data.source_inventory is InventarioPlayer


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	## vender
	if data.source_inventory != tienda and data.source_inventory is InventarioPlayer:
		tienda.intercambio.rpc_id(1, \
			data.source_inventory.get_path(), data.src_slot_id,
			data.cantidad, -1)


#func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	## Se puede dropear cualquier cosa en la tienda porque se puede vender cualquier cosa.
	#return data is UISlot.ItemDTO and data.source_inventory is InventarioPlayer
#
#func _drop_data(_at_position: Vector2, data: Variant) -> void:
	## Este codigo es copiado y pegado de ShopSlot, con pocas modificaciones. Al llamar a intercambio se pasa -1 como el slot (a quien diablos le interesa el slot?) porque se dropea en un lugar donde no hay slot alguno
	#if data.source_inventory != tienda and data.source_inventory is InventarioPlayer:
		#tienda.intercambio.rpc_id(1, \
			#data.source_inventory.get_path(),
			#data.item.to_dto(), -1)
