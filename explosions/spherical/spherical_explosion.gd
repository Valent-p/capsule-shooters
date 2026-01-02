# Its rigid body to avoid rendering inside object. Physics engine handles for us.
extends RigidBody3D
class_name SphericalExplosion

# Set when creating explosion
var agent: Character
var max_damage: float

var elapsed_time := 0.0
var max_light_energy := 10.0

## We prevent those who registered the hit, to register again.
var hit_list: Array[Area3D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Debris.emitting = true
	$Debris.one_shot = true
	
	$Fire.emitting = true
	$Fire.one_shot = true
	
	$Smoke.emitting = true
	$Smoke.one_shot = true
	
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed_time += delta
	$OmniLight3D.light_energy = max(0, remap(elapsed_time/$Fire.lifetime, 0, 1, max_light_energy, 0 ))

func _on_body_entered(_body: Node) -> void:
	## Remove the collisions
	collision_layer = 0
	collision_mask = 0

## Scans only Hitboxes, set by the collision mask
func _on_hit_area_3d_area_entered(area: Area3D) -> void:
	# Avoid double hit as explosion takes some time
	if area in hit_list:
		return
	hit_list.append(area)
	
	var dist = area.global_position.distance_to(global_position)
	var radius = $HitArea3D/CollisionShape3D.shape.radius
	# 0.6 is the hitbox diameter
	var actual_damage = (1.0 - (dist-0.6)/radius) * max_damage
	#print("Damaged ", area.get_parent(), " with ", actual_damage, "at distance ", dist)
	actual_damage = floori(clamp(actual_damage,0, max_damage)) # In case maths went wrong
	area.hit(actual_damage, agent)
