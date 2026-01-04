extends Node
class_name HealthComponent

signal health_changed(current_health: float, max_health: float)
signal died
var has_died: bool = false

@export var core: CoreItemData

var current_health: int:
	set(value):
		if has_died:
			GlobalLogger.info("HealthComponent.current_health.set: Already died, returning.")
			return
			
		current_health = clamp(value, 0, core.health)
		if current_health == 0:
			GlobalLogger.info("Emitting die...")
			has_died = true
			died.emit()
		
		health_changed.emit(current_health, core.health)
		
func _ready() -> void:
	assert(core != null, "HealthComponent: core is required!")
	current_health = core.health
	has_died = false
