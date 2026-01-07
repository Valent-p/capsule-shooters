class_name PlaceableItemData
extends ItemData

enum PlaceableLocationType {
	ROOM_TILE,
	CORRIDOR_TILE,
	WALL_TILE
}

enum RotationType {
	RANDOM,
	GRID_SNAP
}

enum RoomLocationType {
	CORNER,
	OPEN_SPACE,
	WALL
}

@export var density: float = 0.01
@export var location_type: PlaceableLocationType = PlaceableLocationType.ROOM_TILE
@export var is_stackable: bool = false
@export var rotation: float = 0.0
@export var y_offset: float = 0.0
@export var rotation_type: RotationType = RotationType.RANDOM

## For items to place in a room
@export_group("room logic", "room")
@export var room_location: RoomLocationType = RoomLocationType.OPEN_SPACE
