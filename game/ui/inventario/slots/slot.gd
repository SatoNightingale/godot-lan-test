@abstract class_name Slot extends Control


#signal item_dragged(slot_id)
#signal item_dropped(slot_id, data)


@export var item: Item: set = set_item
func set_item(value: Item):
	item = value
	if item:
		textura().texture = load(item.icon_path)
	else:
		textura().texture = null


var inventario: InventarioAbstract: set = set_inventario
func set_inventario(value):
	if value is InventarioAbstract:
		inventario = value
	else:
		printerr("Tipo de inventario incorrecto")

#@export var public_slot: bool = true

var slot_id: int

class ItemDTO:
	var source_inventory: InventarioAbstract
	var item: Item
	var slot_id: int
	func _init(slot: Slot) -> void:
		source_inventory = slot.inventario
		item = slot.item
		slot_id = slot.slot_id


@export var elevation := 10:
	set(value):
		elevation = value
		margin().add_theme_constant_override("margin_bottom", elevation)


@abstract func textura() -> TextureRect;
@abstract func margin() -> MarginContainer;


func _ready() -> void:
	if item != null:
		item = item # llamar al setter para inicializar el slot


@abstract func _generar_preview() -> Node;

func _generar_item_data() -> ItemDTO:
	return ItemDTO.new(self)


## En las operaciones de drag n drop de slots influye la distincion entre publicas y privadas

## Y si se cancela el drop?

func tomar_item():
	#if public_slot:
	inventario.take_item_slot_server(slot_id)
	#else:
		#inventario._take_item_slot_client(slot_id)
	item = null


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item != null:
		# Adiciones de items nuevos o eliminaciones de items existentes siempre le incumben al servidor (pero nunca a los clientes, salvo que se trate de slots publicos)
		# Deberia ser con una señal?
		# Hay dos modos de hacer esto: o bien el inventario es la fuente de la accion, y el mismo aplica toda la validacion que hace falta; o bien el inventario es una entidad pasiva cuyos metodos se llaman para ser modificado.
		# vamos a optar por la segunda, porque no me parece que el inventario va a estar supervisando cada pequeño slot; aunque probablemente haya que cambiar a ese modo después. Creo que el inventario viejo del player seguia un diseño mas autoritativo
		# En el primer modo (inventario autoritativo) las acciones de drag n drop se envian como señales y se validan en el inventario. En el segundo modo (inventario pasivo), las acciones de drag n drop se validan llamando metodos del inventario. 
		set_drag_preview(_generar_preview())
		return _generar_item_data()
	else:
		return null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data.item != null

# Donde va el if data.source is Tienda?
## Al poner un item en un slot (drop) hay que moverlo desde su slot de origen hacia el slot de destino. Por tanto, el data debe contener el slot de origen, junto con su inventario. La operacion de tomar un item de otro inventario (o de este) y colocarlo en este inventario (procedente de otro o de este) es algo de lo que cada inventario se debe ocupar.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	## Llamadas al backend
	if data.inventario != inventario: ## De un inventario a otro
		inventario.intercambio.rpc_id(1, data.source_inventory.get_path(),
			data.item.to_dto(), slot_id)
	else: ## En el mismo inventario
		inventario.mover_item_local.rpc_id(1, data.slot_id, slot_id)
	## Frontend
	if item:
		force_drag(_generar_item_data(), _generar_preview())
	item = data.item
