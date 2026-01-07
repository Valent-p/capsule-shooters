class_name POIData
extends Resource

enum POILocationType {
	CORNER,
	OPEN_SPACE,
	WALL, # This is for tiles adjacent to a wall
	CORRIDOR_TILE,
	WALL_BLOCK, # This is for actual wall blocks (not floor)
	WALL_FEATURE # For items that attach to a wall, not part of it
}

@export var poi_scene: PackedScene
@export var density: float = 0.01
@export var location_type: POILocationType = POILocationType.OPEN_SPACE
