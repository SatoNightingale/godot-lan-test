extends Node2D

func _ready() -> void:
	for tilemap: TileMapLayer in get_children():
	#var tilemap := $Suelo
		var tileset : TileSet = tilemap.tile_set
		var source1_id = tileset.get_source_id(3)
		var source2_id = tileset.get_source_id(4)
		for cell in tilemap.get_used_cells():
			var atlas_coords = tilemap.get_cell_atlas_coords(cell)
			var source_id = tilemap.get_cell_source_id(cell)
			var alternative_tile = tilemap.get_cell_alternative_tile(cell)
			if source_id == 0:
				var tile_y = atlas_coords.y
				if tile_y < 66:
					tilemap.set_cell(cell, source1_id, atlas_coords, alternative_tile)
				else:
					var new_coords = Vector2i(atlas_coords.x, atlas_coords.y - 66)
					tilemap.set_cell(cell, source2_id, new_coords, alternative_tile)
	
