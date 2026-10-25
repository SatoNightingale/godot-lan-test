@tool
class_name WorldItem extends Node2D

## De aqui lo unico que importa para el juego es el item_type_path, lo otro es para facilitar la edicion. Propiedades de instancia van en instance_data. 
## De hecho, la misma propiedad item es sobreescrita al inicio por ItemManager.register_world_items
@export var item: Item:
	set(value):
		item = value
		%texture.texture = load(item.icon_path)

# Items de dinero deben tener un id? Si no tienen id, como se van a registrar en itemManager? 

@export var instance_data: Dictionary[String, Variant]:
	get():
		return instance_data.merged({
			"type_id": item.item_type_path
		}, true)

func is_on_interact_area(player: Player) -> bool:
	return %pick_area.overlaps_body(player)


@rpc("any_peer", "call_local")
func interact_with_player():
	if multiplayer.is_server():
		var game_instance = get_node_or_null("/root/Main/GameContainer/Game") as Game
		if game_instance == null: game_instance = get_node("/root/tests")
		var player_id = multiplayer.get_remote_sender_id()
		var player = game_instance.players[player_id]
		if is_on_interact_area(player):
			if item.item_type_path == "res://items/types/money_item.tres":
				player.inventario.dinero += item.cantidad
				ItemManager.remove_world_item.rpc(get_path())
				return true
			else: if player.inventario.add_new_item_to_bag(item):
				ItemManager.remove_world_item.rpc(get_path())
				return true
			else:
				pass # no hay espacio en el inventario
	return false


func _on_touch_screen_button_pressed() -> void:
	interact_with_player.rpc_id(1)
