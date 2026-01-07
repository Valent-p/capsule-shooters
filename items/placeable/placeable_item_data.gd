class_name PlaceableItemData
extends ItemData

enum PlaceableLocationType {
	ROOM_TILE,
	CORRIDOR_TILE,
	WALL_TILE
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

## For items to place in a room
@export_group("room logic", "room")
@export var room_location: RoomLocationType = RoomLocationType.OPEN_SPACE
