extends CharacterBody3D

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity()
		move_and_slide()
	
	# Animate the visual
	$explosive_landmine.rotate((Vector3(1, 1, 1) * randf()).normalized(), deg_to_rad(180) * delta)

## Only scans for Characters
func _on_contact_detector_body_entered(body: Node3D) -> void:
	GlobalLogger.info("Takes powerup: ", body)
	#body.weapon_component.add_tertiary(landmine_resource)
	GlobalLogger.info("Added a landmine.")
	queue_free()
