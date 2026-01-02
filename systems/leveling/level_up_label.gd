extends Label
## Must be used in PlayerUI

var level_up_timer: float = 0.0
@export var scale_curve: Curve
## Use in PlayerUI, and assign the player_ui
@export var player_ui: PlayerUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_ui.leveling_system.leveled_up.connect(_on_leveled_up)

func _process(delta: float) -> void:
	if visible:
		level_up_timer += delta
		pivot_offset = size / 2.0
		scale = Vector2.ONE * scale_curve.sample(level_up_timer)

func _on_leveled_up(new_level: int, _current_xp: int, _prev_level_up_xp:int, _next_levelup_xp: int):
	visible = true
	text ="Level Up!\n%d" % new_level
	level_up_timer = 0.0
	
	await  get_tree().create_timer(2.0).timeout
	
	visible = false
