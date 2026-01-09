# /levels/generation/level_tile_data.gd
# Defines the data for a single tile in the level grid.
class_name LevelTileData
extends Object

var is_floor: bool = false
var is_wall: bool = false
var is_corridor: bool = false
var is_room: bool = false
var is_prefab: bool = false
var room_id: int = -1

# Tile characteristics determined by the TileAnalyzer.
var is_corner: bool = false
var is_surrounded: bool = false
var neighbor_count: int = 0
var cardinal_neighbor_count: int = 0 # 4-way neighbor count, for corridor analysis.
var is_doorway: bool = false
var is_wall_adjacent: bool = false
