class_name ThermalDetonator
extends ThrowableItem

@onready var explosion_scn:= preload("res://explosions/spherical/spherical_explosion.tscn")

## We prevent those who registered the hit, to register again.
var has_exploded:bool = false

## Timer for explosion
var timer: float = 10.0 # seconds to explode


func _ready() -> void:
	assert(explosion_scn != null, "ThermalDetonator: explosion_scn is required!")

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		_explode()

func _on_body_entered(body: Node3D) -> void:
	_on_detection_area_body_entered(body)

func _explode():
	has_exploded = true
	var explosion = explosion_scn.instantiate()
	explosion.position = global_position
	explosion.agent = agent
	explosion.max_damage = damage
	get_parent().add_child(explosion)
	queue_free()

func _on_detection_area_body_entered(body: Node3D) -> void:
	# This is to fix a bug where when you explode multiple enemies at once, they explode
	# Several times depending on the number they are. The issue is the area still detecting.
	if has_exploded: return
	
	# Dont report walls
	if body is StaticBody3D: return
	
	## Cant blast oneself; Maybe ;0
	if self.agent != body:
		_explode()
