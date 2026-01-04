@tool
extends SubViewport

@export_tool_button("Generate") var generate_action = generate

@export var model_scene: PackedScene:
	set(value):
		model_scene = value
		if is_instance_valid(model_scene):
			load_model()

func load_model():
	assert($ModelContainer != null, "IconMaker: $ModelContainer is required!")
	assert(model_scene != null, "IconMaker: model_scene is required!")
	for child in $ModelContainer.get_children():
		$ModelContainer.remove_child(child)
	var model = model_scene.instantiate()
	$ModelContainer.add_child(model)


func generate() -> void:
	assert(model_scene != null, "IconMaker: model_scene is required!")
	assert($ModelContainer != null, "IconMaker: $ModelContainer is required!")
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img = get_texture().get_image()
	var model_path = model_scene.resource_path
	var size_str = str(size.x) + "x" + str(size.y)
	var save_path = model_path.get_basename() + "_icon_%s.png" % size_str
	img.save_png(save_path)
	print("@IconMaker: Generated")
	if Engine.is_editor_hint():
		var fs = EditorInterface.get_resource_filesystem()
		fs.scan()
	#model.queue_free()
