@abstract class_name UISlot extends Control


var slot: Slot: set = set_slot
func set_slot(value: Slot):
	slot = value
	slot.item_prop.connect_init(observar_item)


func observar_item(new_item, _old_item):
	if new_item:
		textura().texture = load(new_item.icon_path)
	else:
		textura().texture = null


var inventario: Inventario: set = set_inventario
func set_inventario(value):
	if value is Inventario:
		inventario = value
	else:
		printerr("Tipo de inventario incorrecto")


class ItemDTO:
	var source_inventory: Inventario
	var item: Item
	var slot_id: int
	func _init(ui_slot: UISlot) -> void:
		source_inventory = ui_slot.inventario
		item = ui_slot.slot.item
		slot_id = ui_slot.slot.slot_id


@export var elevation := 10:
	set(value):
		elevation = value
		margin().add_theme_constant_override("margin_bottom", elevation)


@abstract func textura() -> TextureRect;
@abstract func margin() -> MarginContainer;


func _ready() -> void:
	if slot != null:
		slot = slot # llamar al setter para inicializar el slot


@abstract func _generar_preview() -> Node;

func _generar_item_data() -> ItemDTO:
	return ItemDTO.new(self)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot.item != null:
		set_drag_preview(_generar_preview())
		return _generar_item_data()
	else:
		return null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is ItemDTO and slot.validar_tipo(data.item)


## Al poner un item en un slot (drop) hay que moverlo desde su slot de origen hacia el slot de destino. Por tanto, el data debe contener el slot de origen, junto con su inventario. La operacion de tomar un item de otro inventario (o de este) y colocarlo en este inventario (procedente de otro o de este) es algo de lo que cada inventario se debe ocupar.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	## Frontend
	# Esto primero por las condiciones de carrera
	if slot.item: # si el slot no estaba vacio, tomar lo que tenia
		force_drag(_generar_item_data(), _generar_preview())
	## Llamadas al backend
	if data.source_inventory != inventario: ## De un inventario a otro
		inventario.intercambio.rpc_id(1, \
			data.source_inventory.get_path(),
			data.item.to_dto(), slot.slot_id)
	else: ## En el mismo inventario
		inventario.mover_item_local.rpc_id(1, \
			data.slot_id, slot.slot_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed and slot.item:
			TooltipManager.request_tooltip(self, event.position, slot.item)
			accept_event()


#func _make_custom_tooltip(for_text: String) -> Object:
	#if slot.item:
		#return slot.item.generate_tooltip(for_text)
	#else:
		#return null
#
#func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			#_make_custom_tooltip(tooltip_text)
