class_name SlotInventario extends Resource

## El tipo de Item que puede contener este slot. No confundir con el rol del slot en el inventario
@export var tipo: String
## Nombre de la funcion (de la clase Inventario) que va a servir de setter para el Observable item. Meh, pienso abandonarlo
@export var observable_setter_name: String
## Observable que contiene el item del slot en cuestion
var item: Observable
