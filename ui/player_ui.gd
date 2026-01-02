extends Control
class_name PlayerUI

@export var player: Player
@export var health_component: HealthComponent
@export var weapon_component: WeaponComponent
@export var leveling_system: LevelingSystem

var tertiary_item_template: Control

@onready var default_font: Font = ThemeDB.fallback_font
@onready var default_font_size: int = ThemeDB.fallback_font_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	weapon_component.charge_changed.connect(_on_charge_changed)
	weapon_component.throwable_count_changed.connect(_on_throwable_count_changed)
	
	health_component.health_changed.connect(_on_health_changed)
	
	leveling_system.leveled_up.connect(_on_leveled_up)
	leveling_system.xp_changed.connect(_on_xp_changed)
	
	## initials
	_on_charge_changed(weapon_component.bullet_left.max_charge, weapon_component.bullet_left.max_charge, false)
	_on_charge_changed(weapon_component.bullet_right.max_charge, weapon_component.bullet_right.max_charge, true)
	if is_instance_valid(weapon_component.throwable_left):
		%LeftThrowableItem.get_child(2).texture = weapon_component.throwable_left.icon
	if is_instance_valid(weapon_component.throwable_right):
		%RightThrowableItem.get_child(2).texture = weapon_component.throwable_right.icon
		
	_on_throwable_count_changed(weapon_component.throwable_left_count, false)
	_on_throwable_count_changed(weapon_component.throwable_right_count, true)
	
	_on_leveled_up(leveling_system.current_level, leveling_system.current_xp, leveling_system.prev_level_up_xp, leveling_system.next_level_up_xp)
	_on_health_changed(health_component.current_health, health_component.core.health)

func _on_leveled_up(new_level: int, current_xp: int, prev_level_up_xp, next_level_up_xp: int):
	%LevelProgressLabel.text = "LVL %d" % new_level
	%LevelProgressBar.value = current_xp - prev_level_up_xp
	%LevelProgressBar.max_value = next_level_up_xp - prev_level_up_xp

func _on_xp_changed(current_xp: int, _current_level, prev_level_up_xp:int, next_level_up_xp: int):
	%LevelProgressBar.value = current_xp - prev_level_up_xp
	%LevelProgressBar.max_value = next_level_up_xp - prev_level_up_xp

func _on_health_changed(current_health: int, max_health: int):
	%HealthBar.value = current_health
	%HealthBar.max_value = max_health

func _on_throwable_count_changed(current_count: int, is_right: bool) -> void:
	if is_right:
		%RightThrowableItem.get_child(1).text = str(current_count)
	else:
		%LeftThrowableItem.get_child(1).text = str(current_count)

func _on_charge_changed(current_charge: int, max_charge: int, is_right: bool) -> void:
	if is_right:
		%RChargeBar.value = current_charge
		%RChargeBar.max_value = max_charge
	else:
		%LChargeBar.value = current_charge
		%LChargeBar.max_value = max_charge

func _on_tertiary_weapons_updated(tertiary_weapons):
	# Clean current
	for child in %TertiaryItemsContainer.get_children():
		child.queue_free() # Permanent
		
	for item_name in tertiary_weapons:
		var new_node = tertiary_item_template.duplicate()
		new_node.get_child(0).text = item_name
		new_node.get_child(1).text = str(tertiary_weapons[item_name].count)
		%TertiaryItemsContainer.add_child(new_node)
