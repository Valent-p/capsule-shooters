# /items/placeable/placeable_data.gd
# A unified data resource for any object that can be placed by the procedural generator.
# This replaces poi_data.gd and placeable_item_data.gd.
class_name PlaceableData
extends Resource

# Primary location category for the object.
enum Location {
	ROOM,               # Inside a procedurally generated room.
	CORRIDOR,           # Inside a corridor.
	WALL_ADJACENT,      # On the floor, touching a wall (e.g., a torch, a crate).
	WALL_REPLACEMENT,   # Replaces a wall segment (e.g., a secret door, a window).
}

# Sub-location, used only when the primary location is ROOM.
enum RoomSubLocation {
	ANY,            # Anywhere on the floor of a room.
	OPEN_SPACE,     # On the floor, but not touching any walls.
	CORNER,         # In a corner.
	WALL_ADJACENT,  # On the floor, touching a single wall.
}

# How the object's rotation should be determined.
enum RotationType {
	FIXED,              # A fixed direction (North, East, South, West).
	RANDOM_360,         # Any random angle.
	RANDOM_90_DEG,      # Snapped to a random 90-degree angle.
	ALIGN_TO_CONTEXT,   # Aligned intelligently to its surroundings (e.g., face corridor, away from wall).
}

enum FixedDirection { NORTH, EAST, SOUTH, WEST }


@export_group("General")
@export var scene: PackedScene

@export_group("Placement Logic")
@export var density: float = 0.05
@export var y_offset: float = 0.0
@export var location: Location = Location.ROOM
@export var room_sub_location: RoomSubLocation = RoomSubLocation.ANY # Only used if location is ROOM.

@export_group("Rotation Logic")
@export var rotation_type: RotationType = RotationType.RANDOM_360
@export var fixed_direction: FixedDirection = FixedDirection.NORTH # Only used if rotation_type is FIXED.
