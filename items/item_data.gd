class_name ItemData
extends Resource
## An item has three main actions on it: [br]
## - Can be picked (into inventory),
## - Can be used (e.g. Plant if is landmine),
## - Dropped onto ground

## Who is owning it
var agent: Character

@export var item_name: String

## When it is in the inventory, 1 means none groupable
@export var group_size: int = 1

@export var icon: Texture2D

## Blender Model, used for drop scene and others
@export var model: PackedScene

## The scene when instantiated, if "use" cmd is made
@export var use_scene: PackedScene

func _init() -> void:
	assert(model != null, "ItemData: model is required!")
	assert(use_scene != null, "ItemData: use_scene is required!")

@export_multiline var item_description: String
