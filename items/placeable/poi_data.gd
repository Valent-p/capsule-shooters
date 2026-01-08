class_name POIData
extends Resource

enum POILocationType {
	CORNER,
	OPEN_SPACE,
	CORRIDOR_TILE, # Decorative pillar/debris in hall
	WALL_BLOCK,    # Replaces a solid wall tile (Secret door, grating)
	WALL_FEATURE   # Attached to a wall (Torch, Painting)
}

enum Direction {
	NORTH, EAST, SOUTH, WEST,
	RANDOM, GRID_SNAP
}

@export var poi_scene: PackedScene
@export var density: float = 0.05
@export var location_type: POILocationType = POILocationType.OPEN_SPACE
@export var offset_y: float

@export var direction: Direction = Direction.NORTH # Useful for WALL_FEATURE
