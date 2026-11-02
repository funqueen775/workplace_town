extends Node

## 收件箱列表实拍：看每位同事那一行的头像取的是哪一帧。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/phone_list_shot.tscn

const SHOT_DIR := "res://test_artifacts/phone_list"

var _town: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	_town.call("debug_jump_to_month", 1, "A")
	await _wait(2.6)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
	await _wait(1.6)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	for value in ((raw as Dictionary).get("nodes", []) if raw is Dictionary else []):
		if String(Dictionary(value).get("id", "")) == "M01_PHONE_1":
			_town.call("runner_deliver_phone", Dictionary(value))
			break
	await _wait(0.8)
	# 剧情面板盖在上面就拍不到手机：先收干净
	for key in ["_story_event_panel", "_month12_start_panel", "_interior_preview"]:
		var node = _town.get(key)
		if node != null and node.has_method("close"):
			node.call("close")
		if node != null and node.has_method("dismiss"):
			node.call("dismiss")
	await _wait(0.4)
	var panel = _town.call("_ensure_month_phone_panel")
	panel.set("conversations", _town.call("_build_phone_conversations"))
	panel.call("open_phone", true)
	await _wait(0.9)
	await _shot("01_list")
	# 进陈工那条会话，看 56 像素的小头像取的是哪一帧
	var convs: Array = panel.get("conversations")
	for value in convs:
		var conv := Dictionary(value)
		if String(conv.get("id", "")) == "chen_gong":
			panel.call("_open_conversation", "chen_gong")
			break
	await _wait(0.8)
	await _shot("02_thread")
	print("LIST_DONE")
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("SHOT ", shot_name, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")))
