class_name BulletItemData
extends EquippableItemData

@export var max_charge: int = 10
@export var recharge_speed: float = 0.5 # 1 charge every 0.2 sec
@export var shoot_delay: float = 0.2 # Shoot interval when current charge is at full

@export var speed: float = 20.0
@export var damage: int = 10

func _init() -> void:
	type = EquippableItemData.Type.BULLET
