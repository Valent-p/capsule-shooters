extends RigidBody3D
class_name Projectile

@export var particles_scene: PackedScene

## Is set when initializing
var shooter: Character
var speed: float
var damage: float

func _ready() -> void:
	# In case didnt hit anything
	$RemoveTimer.timeout.connect(queue_free)
	linear_velocity = -transform.basis.z * speed

## On hit world
func _on_body_entered(body: Node3D) -> void:
	if body is Character:
		body.hitbox_component.hit(damage, shooter)
	
	_spawn_particles()
	queue_free()

func _spawn_particles():
	var particles = particles_scene.instantiate()
	particles.position = global_position
	get_parent().add_child(particles)
