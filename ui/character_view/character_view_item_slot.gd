extends Button
class_name CharacterViewItemSlot

var item_data: ItemData:
	set(value):
		item_data = value
		_setup()
var slot_size: Vector2

signal selected(slot: CharacterViewItemSlot)

func _enter_tree() -> void:
	_setup()

func _setup():
	assert(item_data != null, "CharacterViewItemSlot: item_data is required!")
	assert($TextureRect != null, "CharacterViewItemSlot: $TextureRect is required!")
	if not is_instance_valid(item_data):
		return
	size = slot_size
	$TextureRect.texture = item_data.icon

func _on_pressed() -> void:
	selected.emit(self)
