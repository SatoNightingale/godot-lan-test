@tool
class_name InventorySlot extends UISlot


func textura() -> TextureRect: return $margin/textura
func margin() -> MarginContainer: return $margin
func cantidad() -> Label: return %cantidad

func set_inventario(value):
	if value is InventarioPlayer:
		inventario = value
	else:
		printerr("Tipo de inventario incorrecto")


func _generar_preview() -> Control:
	var preview = duplicate()
	if slot.item.cantidad == 1:
		preview.get_node("%cantidad").hide()
	return preview


func as_drag_preview():
	cantidad().set_anchors_preset(PRESET_TOP_LEFT)
	cantidad().position = Vector2(-15, -20)
	position -= Vector2(20, 20)

func set_grab_cantidad(value: int):
	cantidad().text = str(value)


#func _drop_data(_at_position: Vector2, data: Variant) -> void:
	### Frontend
	## Esto primero por las condiciones de carrera
	#if slot.item: # si el slot no estaba vacio, tomar lo que tenia
		#force_drag(_generar_item_data(), _generar_preview())
	### Llamadas al backend
	#if data.source_inventory != inventario: ## De un inventario a otro
		## if data.source_inventory is Tienda: ...
		#inventario.intercambio.rpc_id(1, \
			#data.source_inventory.get_path(),
			#data.item.to_dto(), slot.slot_id, data.slot_id)
	#else: ## En el mismo inventario
		#inventario.mover_item_local.rpc_id(1, \
			#data.slot_id, slot.slot_id, data.slot_id)
