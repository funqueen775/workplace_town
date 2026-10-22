extends Node

const STARTUP_FLOW := preload("res://scripts/StartupFlow.gd")

func _ready() -> void:
	var flow := STARTUP_FLOW.new()
	add_child(flow)
	flow.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for viewport_size in [Vector2(1920, 1080), Vector2(2400, 1080), Vector2(1080, 1920)]:
		flow.size = viewport_size
		for mode in ["intro", "avatar"]:
			flow.set("_mode", mode)
			flow.call("_rebuild")
			var frame: Panel = null
			for child in flow.get_children():
				if child is Panel and not child.is_queued_for_deletion():
					frame = child
			if frame == null:
				_fail("%s 页面没有外框" % mode)
				return
			var center := frame.position + frame.size * frame.scale * 0.5
			if center.distance_to(viewport_size * 0.5) > 0.5:
				_fail("%s 页面在 %s 视口没有居中" % [mode, viewport_size])
				return
			if frame.position.x < 0 or frame.position.y < 0:
				_fail("%s 页面超出 %s 视口" % [mode, viewport_size])
				return
	print("HARMONY_LAYOUT_PASS intro_and_avatar_centered=true")
	flow.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("HARMONY_LAYOUT_FAIL " + message)
	get_tree().quit(1)
