extends RigidBody3D
class_name Projectile

@export var particles_scene: PackedScene

## Is set when initializing
var shooter: Character
var speed: float
var damage: float

var timer: float = 3.0 # seconnds

func _ready() -> void:
	assert(particles_scene != null, "Projectile: particles_scene is required!")
	# In case didnt hit anything
	linear_velocity = -transform.basis.z * speed

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		queue_free()

## Only hit world
func _on_body_entered(_body: Node3D) -> void:
	_spawn_particles()
	queue_free()

func _spawn_particles():
	var particles = particles_scene.instantiate()
	particles.position = global_position
	get_parent().add_child(particles)

## Only hits hitboxes
func _on_detector_area_entered(area: Area3D) -> void:
	area.hit(damage, shooter)
	_spawn_particles()
	queue_free()
