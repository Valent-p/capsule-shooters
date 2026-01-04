@abstract class_name Character
extends CharacterBody3D

@export var bottom_marker: Marker3D
@export var shoot_marker: Marker3D
@export var weapon_component: WeaponComponent
@export var health_component: HealthComponent
@export var movement_component: MovementComponent
@export var hitbox_component: HitboxComponent

## (Optional) for leveling up
@export var leveling_system: LevelingSystem

func _ready() -> void:
	assert(bottom_marker != null, "Character: bottom_marker is required!")
	assert(shoot_marker != null, "Character: shoot_marker is required!")
	assert(weapon_component != null, "Character: weapon_component is required!")
	assert(health_component != null, "Character: health_component is required!")
	assert(movement_component != null, "Character: movement_component is required!")
	assert(hitbox_component != null, "Character: hitbox_component is required!")
	# leveling_system is optional

@abstract func animate_shoot_short() -> void
