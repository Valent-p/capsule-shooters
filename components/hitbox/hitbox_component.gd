extends Node3D
class_name HitboxComponent

@export var agent: Character
@export var health_component: HealthComponent
@export var show_feedback_labels: bool = true

var active_labels_pool = []
var free_labels_pool = []
var label_max_lifetime := 1.0

func _process(delta: float) -> void:
	# Update
	if show_feedback_labels:
		for l in active_labels_pool.duplicate():
			l.lifetime += delta
			# Clean if expired
			if l.lifetime > label_max_lifetime:
				# Remove from node
				remove_child(l.label)
				active_labels_pool.erase(l)
				free_labels_pool.append(l)
			else:
				l.label.global_position.y += l.speed * delta

## [code]shooter[/code] can null, in case it was deleted/freed.
## But must be a Character
func hit(damage: int, shooter):
	GlobalLogger.info("Hit ",damage, " on ", agent, " by ", shooter)
	
	if show_feedback_labels:
		var free_label := _get_free_label()
		free_label.position += Vector3(randf_range(-.2, .2), randf_range(-.2, .2), 0.0)
		free_label.text = "-"+str(damage)
		free_label.font_size = int(32.0 * randf_range(0.6, 2.0))
		add_child(free_label)
	
	#print("Hit ",damage, " on ", agent)
	health_component.current_health -= damage
	
	## LevelUP
	if shooter and shooter.leveling_system:
		shooter.leveling_system.add_xp(damage)
		if show_feedback_labels:
			var xp_label := _get_free_label()
			xp_label.position += Vector3(randf_range(-.2, .2), randf_range(-.2, .2), 0.0)
			xp_label.text = "XP "+str(damage)
			xp_label.font_size = int(32.0 * randf_range(0.6, 2.0))
			xp_label.modulate = Color(0.0, 1.0, 0.0, 1.0)
			add_child(xp_label)

func _get_free_label() -> Label3D:
	if not free_labels_pool.is_empty():
		var l = free_labels_pool.get(0)
		l.lifetime = 0
		l.label.position.y = 2.0
		free_labels_pool.erase(l)
		active_labels_pool.append(l)
		return l.label
	
	# OR Create
	var retval = Label3D.new()
	retval.modulate = Color(1.0, 0.0, 0.0, 1.0)
	retval.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	active_labels_pool.append({"lifetime": 0.0, "label": retval, "speed": randf_range(1.0, 2.0)})
	retval.position.y = 2.0
	
	return retval
