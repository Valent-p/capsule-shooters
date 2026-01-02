extends Node

func info(message: String,...objs) -> void:
	for obj in objs:
		message += str(obj)
	
	print("[I] ", message)

func err(message: String,...objs) -> void:
	for obj in objs:
		message += str(obj)
	
	push_error("[E] ", message)

func warn(message: String,...objs) -> void:
	for obj in objs:
		message += str(obj)
	
	push_warning("[W] ", message)
