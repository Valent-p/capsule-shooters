extends Control

@export var slot_scene: PackedScene

var player_data: PlayerSaveData

var active_equipped_slot: Button
var active_available_slot: CharacterViewItemSlot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup()

func _setup():
	player_data = SaveManager.load_player()
	if player_data == null:
		GlobalLogger.info("CharacterView: player_data is never saved")
		## Show empty
		return
	else:
		show_equips(player_data)

func show_equips(data: PlayerSaveData):
	if data.bullet_left:
		%EquipCL.get_child(0).texture = data.bullet_left.icon
	if data.bullet_right:
		%EquipCR.get_child(0).texture = data.bullet_right.icon
	
	if data.throwable_left:
		%EquipTL.get_child(0).texture = data.throwable_left.icon
	
	if data.throwable_right:
		%EquipTR.get_child(0).texture = data.throwable_right.icon
	
	if data.assistant:
		%EquipTC.get_child(0).texture = data.assistant.icon
	
	if data.core:
		%EquipCC.get_child(0).texture = data.core.icon
	
	if data.propulsor:
		%EquipBC.get_child(0).texture = data.propulsor.icon

func show_avalable_throwable_items(is_right: bool):
	GlobalLogger.info("CharacterView.show_available_throwable_items")
	
	%BulletAvailableItems.visible = false

	%ThrowableAvailableItems.visible = true
	
	# Description
	%EquippedRichTextLabel.text = "" # Clear
	if is_right and player_data.throwable_right:
		%EquippedRichTextLabel.text = player_data.throwable_right.item_description
	elif player_data.throwable_left:
		%EquippedRichTextLabel.text = player_data.throwable_left.item_description

	## Clear
	for child in %ThrowableAvailableItems.get_children():
		%ThrowableAvailableItems.remove_child(child)
	
	## Load and display
	for data in GameManager.items_manager.throwable_items:
		var slot = slot_scene.instantiate()
		slot.item_data = data
		slot.slot_size = Vector2(80, 80)
		slot.selected.connect(_on_available_throwable_item_selected)
		%ThrowableAvailableItems.add_child(slot)

func _on_available_throwable_item_selected(slot: CharacterViewItemSlot) -> void:
	active_available_slot = slot
	%SelectedRichTextLabel.text = _get_throwable_description("Selected: ", slot.item_data, true)

func show_available_bullet_items(is_right: bool):
	GlobalLogger.info("CharacterView.show_available_hand_items")
	
	%ThrowableAvailableItems.visible = false
	
	%BulletAvailableItems.visible = true
	
	## Clear
	for child in %BulletAvailableItems.get_children():
		%BulletAvailableItems.remove_child(child)
	
	# Description
	%EquippedRichTextLabel.text = "" # Clear
	if is_right and player_data.bullet_right:
		%EquippedRichTextLabel.text = _get_bullet_description("Equipped",player_data.bullet_right)
	elif player_data.bullet_left:
		%EquippedRichTextLabel.text = _get_bullet_description("Equipped", player_data.bullet_left)
	
	## Load and display
	for data in GameManager.items_manager.hand_items:
		var slot = slot_scene.instantiate()
		slot.item_data = data
		slot.slot_size = Vector2(80, 80)
		slot.selected.connect(_on_available_bullet_item_selected)
		%BulletAvailableItems.add_child(slot)

func _on_available_bullet_item_selected(slot: CharacterViewItemSlot) -> void:
	active_available_slot = slot
	%SelectedRichTextLabel.text = _get_bullet_description("Selected: ", slot.item_data, true)

## Compare two numbers, the returns the difference in BBCode.
## NOTE: one value from active selected, and another value is taken from active equipped
func compare_actives(prop: StringName) -> String:
	var active_equipped_data
	if active_equipped_slot == %EquipCL:
		active_equipped_data = player_data.bullet_left
	else:
		active_equipped_data = player_data.bullet_right
		
	var dif = active_available_slot.item_data[prop] - active_equipped_data[prop]
	if dif < 0: # negative
		return "[color=red](-%d)[/color]" % dif
	elif dif == 0: # equal
		return ""
	else: # positive
		return "[color=green](+%d)[/color]" % dif

func _get_throwable_description(title: String, item_data: ThrowableItemData, compare: bool = false):
	return "Lorem ipsum..."

func _get_bullet_description(title:String, item: BulletItemData, compare: bool = false) -> String:
	var retval: String = "[u][font_size=24]%s[/font_size][/u]: " % title
	retval += "[font_size=18]%s[/font_size]\n" % item.item_name
	retval += "%s\n\n" % item.item_description
	
	# Stats
	if compare:
		retval += "Max Charges: %s units %s\n" % [str(item.max_charge), compare_actives("max_charge")]
		retval += "Recharge Speed: 1 per %s seconds %s\n" % [str(item.recharge_speed), compare_actives("recharge_speed")]
		retval += "Shoot Delay: %s seconds %s\n" % [str(item.shoot_delay), compare_actives("shoot_delay")]
		retval += "Speed: %s units/second %s\n" % [str(int(item.projectile_speed)), compare_actives("projectile_speed")]
		retval += "Damage: %s %s\n" % [str(item.projectile_damage), compare_actives("projectile_damage")]
	else:
		retval += "Max Charges: %s units\n" % str(item.max_charge)
		retval += "Recharge Time: %s seconds\n" % str(item.recharge_speed)
		retval += "Shoot Delay: %s seconds\n" % str(item.shoot_delay)
		retval += "Speed: %s units/second\n" % str(int(item.projectile_speed))
		retval += "Damage: %s\n" % str(item.projectile_damage)
	
	return retval

func _on_equip_tl_pressed() -> void:
	active_equipped_slot = %EquipTL
	show_avalable_throwable_items(false)

func _on_equip_tr_pressed() -> void:
	active_equipped_slot = %EquipTR
	show_avalable_throwable_items(true)

func _on_equip_cl_pressed() -> void:
	active_equipped_slot = %EquipCL
	show_available_bullet_items(false)

func _on_equip_cr_pressed() -> void:
	active_equipped_slot = %EquipCR
	show_available_bullet_items(true)

func _on_equip_button_pressed() -> void:
	if active_available_slot and active_equipped_slot:
		if active_equipped_slot == %EquipCL:
			player_data.bullet_left = active_available_slot.item_data
		elif active_equipped_slot == %EquipCR:
			player_data.bullet_right = active_available_slot.item_data
		elif active_equipped_slot == %EquipTL:
			player_data.throwable_left = active_available_slot.item_data
		elif active_equipped_slot == %EquipTR:
			player_data.throwable_right = active_available_slot.item_data
		else:
			GlobalLogger.err("Unknown slot: ", active_available_slot)
			
		# Save
		SaveManager.save_player(player_data)
		GlobalLogger.info("_on_swap_button_pressed: Swapped")
		# Refresh UI
		_setup()
	else:
		GlobalLogger.info("_on_swap_button_pressed: Didnt select both, ignoring...")


func _on_back_button_pressed() -> void:
	GameManager.to_main_menu()
