extends Enemy

#@onready var powerup_scene:= preload("res://landmines/explosive_landmine/explosive_landmine_powerup.tscn")

@export_group("LimboAI Requirements")

@export var nav_agent: NavigationAgent3D
@export var sight_check_raycast: RayCast3D

func _ready() -> void:
	assert(nav_agent != null, "SimpleShooterEnemy: nav_agent is required!")
	assert(sight_check_raycast != null, "SimpleShooterEnemy: sight_check_raycast is required!")

func _on_health_component_died() -> void:
	#print("DIED ", self)
	## TODO: Orphan nodes are alwaays left in memory, find the best way to do it.
	##get_parent().remove_child.call_deferred(self)
	
	## Lets just use queuefree
	queue_free()

func animate_shoot_short() -> void:
	#$capbot_v1/AnimationPlayer.play("ShootShort")
	#$capbot_v1/AnimationPlayer.speed_scale = 3.0
	pass
