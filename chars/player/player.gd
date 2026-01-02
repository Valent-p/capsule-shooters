extends Character
class_name Player

@export var input_component: InputComponent

func _enter_tree() -> void:
	# Overwrite initials, if there is a save
	SaveManager.set_data_to_player(self)
	GameManager.player = self

func animate_shoot_short() -> void:
	#$capbot_v1/AnimationPlayer.play("ShootShort")
	#$capbot_v1/AnimationPlayer.speed_scale = 2
	pass

func _on_health_component_died() -> void:
	GameManager.animate_player_die()
