@tool
class_name WorldItem extends Node2D

@export var item: Item:
	set(value):
		item = value
		%texture.texture = load(item.icon_path)

func is_on_pickup_distance(player: Player):
	return %pick_area.overlaps_body(player)


func _on_touch_screen_button_pressed() -> void:
	var game_instance = get_node_or_null("/root/Main/GameContainer/Game") as Game
	if game_instance == null:
		game_instance = get_node("/root/tests")
	game_instance.on_player_pickup_item.rpc_id(1, item.id)
