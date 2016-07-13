extends Navigation2D

export(int,0,1000) var WIDTH = 0
export(int,0,1000) var HEIGHT = 0

func get_size():
	return Vector2(WIDTH,HEIGHT)
func get_cell_size():
	return get_node("TileMap").get_cell_size().x
func get_tilemap_scale():
	return get_node("TileMap").get_scale()
func get_tileset():
	return get_node("TileMap").get_tileset()
func get_level_name():
	return get_meta("level_name") || get_name()