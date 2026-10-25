class_name UISlot extends Control


var slot: Slot: set = set_slot
func set_slot(value: Slot):
	slot = value
	slot.item_prop.connect_init(observar_item)


func observar_item(new_item: Item, old_item: Item):
	if new_item:
		textura().texture = load(new_item.icon_path)
		new_item.cantidad_prop.connect_init(observar_cantidad)
		cantidad().show()
	else:
		textura().texture = null
		cantidad().hide()
	if old_item:
		old_item.cantidad_prop.desconectar(observar_cantidad)


func observar_cantidad(new_cantidad, _old_cantidad):
	if new_cantidad > 1:
		cantidad().show()
		cantidad().text = str(new_cantidad)
	else: if new_cantidad == 1:
		cantidad().text = " "


var inventario: Inventario: set = set_inventario
func set_inventario(value):
	if value is Inventario:
		inventario = value
	else:
		printerr("Tipo de inventario incorrecto")


class ItemDTO:
	var source_inventory: Inventario
	var item: Item
	var cantidad: int
	var src_slot_id: int
	func _init(ui_slot: UISlot) -> void:
		source_inventory = ui_slot.inventario
		item = ui_slot.slot.item
		#tipo = ui_slot.slot.item.item_type_path
		cantidad = ui_slot.slot.item.cantidad
		#cantidad_orig = cantidad
		src_slot_id = ui_slot.slot.slot_id


func textura() -> TextureRect: return $margin/textura
func margin() -> MarginContainer: return $margin
func cantidad() -> Label: return %cantidad


func _ready() -> void:
	if slot != null:
		slot = slot # llamar al setter para inicializar el slot


func _generar_preview() -> Control:
	var preview = duplicate()
	if slot.item.cantidad == 1:
		preview.get_node("%cantidad").hide()
	return preview

func _generar_item_data() -> ItemDTO:
	return ItemDTO.new(self)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot.item != null:
		set_drag_preview(_generar_preview())
		return _generar_item_data()
	else:
		return null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is ItemDTO and slot.validar_tipo(data.item.item_type_path)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# No se permite el intercambio (swap) de items entre slots que tienen items, donde no se trasladan todos los items de un slot al otro. Esto implicaria forzar el drag del item en el slot de destino (que fue sustituido por la parte del item de origen que se traslado, y no se pudo colocar en el slot de origen ya que no se recogieron todos los items de este slot) y no soportamos el drag forzado en movil porque es muy raro
	if slot.item and slot.item.item_type_path != data.item.item_type_path and data.cantidad < data.item.cantidad:
		return
	if data.source_inventory != inventario: # De un inventario a otro
		inventario.intercambio.rpc_id(1, \
			data.source_inventory.get_path(), data.src_slot_id,
			data.cantidad, slot.slot_id)
	else: # En el mismo inventario
		inventario.mover_item_local.rpc_id(1, \
			data.src_slot_id, slot.slot_id, data.cantidad)

#region Seleccion de cantidad de items
var _grabbing := false
var _grabbed := 0.0
var _grab_timer: Timer
var _drag_preview: UISlot
var _drag_data: ItemDTO

const drag_deadzone = 3

# Podria simplificarse este rollo con Input.parse_input_events y una clase InputEvent personalizada?
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed and slot.item:
			TooltipManager.request_tooltip(self, event.position, slot.item)
			start_grab_timer()
	if _grab_timer:
		if (event is InputEventScreenDrag and event.screen_relative.length() > drag_deadzone) or ((event is InputEventScreenTouch or event is InputEventMouseButton) and event.is_released()):
			erase_grab_timer()
			_grabbing = false


func _process(delta: float) -> void:
	if _grabbing and _drag_preview:
		if _grabbed < slot.item.cantidad:
			_grabbed += delta * (1.5 + (1.0/54.0) * _grabbed**2.5)
			if _grabbed >= slot.item.cantidad:
				_grabbed = slot.item.cantidad
			_drag_preview.set_grab_cantidad(int(_grabbed))
			_drag_data.cantidad = int(_grabbed)


func start_grab_timer():
	if not _grab_timer: # como se simula el toque con click, esto es para evitar que se llame dos veces
		_grab_timer = Timer.new()
		_grab_timer.one_shot = true
		_grab_timer.timeout.connect(_on_grab_timer_timeout)
		add_child(_grab_timer)
		_grab_timer.start(0.5)

func _on_grab_timer_timeout():
	_grabbing = true
	_grabbed = 1
	var preview = _generar_preview()
	if preview.has_method("as_drag_preview") and preview.has_method("set_grab_cantidad"): # dejame vomitarme sobre el duck-typing
		_drag_preview = preview
		_drag_data = _generar_item_data()
		_drag_preview.as_drag_preview()
		_drag_preview.set_grab_cantidad(int(_grabbed))
		_drag_data.cantidad = int(_grabbed)
		force_drag(_drag_data, _drag_preview)

func erase_grab_timer():
	_grab_timer.stop()
	_grab_timer.timeout.disconnect(_on_grab_timer_timeout)
	remove_child(_grab_timer)
	_grab_timer.queue_free()
	_grab_timer = null


# Tomado del proximo-a-morir inventory_slot
func as_drag_preview():
	cantidad().set_anchors_preset(PRESET_TOP_LEFT)
	cantidad().position = Vector2(-15, -20)
	position -= Vector2(20, 20)

func set_grab_cantidad(value: int):
	cantidad().text = str(value)

#endregion
