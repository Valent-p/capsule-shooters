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

@abstract func animate_shoot_short() -> void
