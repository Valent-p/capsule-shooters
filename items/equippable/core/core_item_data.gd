class_name CoreItemData
extends EquippableItemData

@export var health: int
## How many health point are gained each second.
## Useful for autogenerative core else 0
@export var regenerate_speed: int

func _init() -> void:
	type = EquippableItemData.Type.CORE
