# /levels/generated_level.gd
# This script orchestrates the procedural generation and baking process for the level.
extends Node3D

# Assign these nodes in the editor.
@export var procedural_level_generator: ProceduralLevelGenerator
@export var navigation_region: NavigationRegion3D
@export var enemy_spawner: Node 

func _ready():
	# 1. Check that all required nodes are assigned.
	if not procedural_level_generator:
		push_error("ProceduralLevelGenerator is not assigned in GeneratedLevel.gd!")
		return
	if not navigation_region:
		push_error("NavigationRegion3D is not assigned in GeneratedLevel.gd!")
		return
	
	# 2. Connect to the generator's completion signal.
	# The _on_level_ready function will be called when the generator is finished.
	procedural_level_generator.level_ready.connect(_on_level_ready)
	
	# 3. Start the generation process.
	print("Starting procedural level generation...")
	procedural_level_generator.generate()

# This function is called automatically when the generator emits the 'level_ready' signal.
func _on_level_ready(level_data: Dictionary):
	print("Level generation finished. Baking navigation mesh...")
	
	# 4. Trigger the navigation mesh baking.
	# The 'true' argument bakes the mesh on the next physics frame, which is safe for runtime generation.
	navigation_region.bake_navigation_mesh(true)
	
	# You can connect to the 'baking_done' signal if you need to wait for it to finish.
	await navigation_region.bake_finished
	print("Navigation mesh baking complete.")
	
	# 5. The level is now fully generated and navigable.
	# You can now spawn the player, enemies, etc.
	# Example:
	if enemy_spawner:
		enemy_spawner.spawn_enemies(level_data)
