extends Node
class_name WeaponComponent
## Handles Hand Equippable items; Guns

@export var agent: Character
@export var shoot_marker: Marker3D

@export var bullet_left: BulletItemData
@export var bullet_right: BulletItemData

@export var throwable_left_count: int = 0
@export var throwable_left: ThrowableItemData
@export var throwable_right_count: int = 0
@export var throwable_right: ThrowableItemData

@export var assistant: AssistantItemData

var l_shoot_timer: float = 0.0
var r_shoot_timer: float = 0.0
var l_charge_timer: float = 0.0
var r_charge_timer: float = 0.0

var l_current_charge: int
var r_current_charge: int

signal charge_changed(current_charge: int, max_charge: int, is_right: bool)
signal throwable_count_changed(current_count:int, is_right: bool)

func _ready() -> void:
	l_current_charge = bullet_left.max_charge
	r_current_charge = bullet_right.max_charge

func _process(delta: float) -> void:
	l_shoot_timer -= delta
	r_shoot_timer -= delta
	l_charge_timer += delta
	r_charge_timer += delta
	
	if l_charge_timer >= bullet_left.recharge_speed:
		l_charge_timer = 0.0
		l_current_charge = clamp(l_current_charge+1, 0, bullet_left.max_charge)
		charge_changed.emit(l_current_charge, bullet_left.max_charge, false) 
	if r_charge_timer >= bullet_right.recharge_speed:
		r_charge_timer = 0.0
		r_current_charge = clamp(r_current_charge+1, 0, bullet_left.max_charge)
		charge_changed.emit(r_current_charge, bullet_right.max_charge, true) 

## Throws a throwable
func throw(is_right:bool):
	if is_right:
		if is_instance_valid(throwable_right) and throwable_right_count > 0:
			throwable_right_count -= 1
			throwable_count_changed.emit(throwable_right_count, true)
			
			var item = throwable_right.use_scene.instantiate()
			item.position = agent.shoot_marker.global_position
			item.agent = agent
			get_tree().current_scene.add_child(item)
			GlobalLogger.info("WeaponComponent.throw(right): DONE")
		else:
			GlobalLogger.info("WeaponComponent.throw(right): No item; Skipping")
	else:
		if is_instance_valid(throwable_left) and throwable_left_count > 0:
			throwable_left_count -= 1
			throwable_count_changed.emit(throwable_left_count, false)
			
			var item = throwable_left.use_scene.instantiate()
			item.position = agent.shoot_marker.global_position
			item.agent = agent
			get_tree().current_scene.add_child(item)
			GlobalLogger.info("WeaponComponent.throw(left): DONE")
		else:
			GlobalLogger.info("WeaponComponent.throw(left): No item; Skipping")

func shoot(is_right:bool):
	var bullet_data: BulletItemData
	
	if is_right:
		bullet_data = bullet_right
	else:
		bullet_data = bullet_left
		
	## Incase owner died
	#if not is_instance_valid(agent): return
	
	if is_right:
		if r_shoot_timer > 0 or r_current_charge <= 0: return
		r_shoot_timer = bullet_data.shoot_delay
		r_current_charge -= 1
	else:
		if l_shoot_timer > 0 or l_current_charge <= 0: return
		l_shoot_timer = bullet_data.shoot_delay
		l_current_charge -= 1
	
	var projectile: Projectile = bullet_data.use_scene.instantiate()
	projectile.position = shoot_marker.global_position
	projectile.rotation = agent.global_rotation
	
	projectile.shooter = agent
	projectile.speed = bullet_data.speed
	projectile.damage = bullet_data.damage
	
	agent.animate_shoot_short()
	
	get_tree().current_scene.add_child(projectile)
