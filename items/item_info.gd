class_name ItemInfo extends Resource

## ItemInfo solo puede estar guardado como un archivo de recursos, nunca dentro de una escena, pues de lo contrario no podria construirse un item a partir de el

@export var nombre: String
@export var precio: float
# estas dos cosas son muy pesadas para cargarse en medio de un rpc
# mas cuando una solo lo usa la tienda y de la otra solo hace falta la ruta
#@export var shop_texture: Texture2D
#@export var item_scene: PackedScene
@export_file var icon_texture_path: String
@export_file("*.tscn") var item_scene_path: String

## Vamos a dejarlo por aqui porque parece que se me olvida muy a menudo:
## NO SE PASAN PRECIOS AL SERVIDOR


func as_item_dto() -> Dictionary:
	return {
		"nombre": nombre,
		"precio": precio,
		"info_resource": resource_path,
		"item_scene_path": item_scene_path
	}
	#dto.nombre = nombre
	#dto.precio = precio
	#dto.info_resource = resource_path
	#dto.item_scene_path = item_scene.resource_path
	#return dto

#func _set_item_properties(item: Item) -> Item:
	#item.nombre = nombre
	#item.precio = precio
	#item.info_resource = resource_path
	#return item
