extends Node

## 选完之后那句回应到底在屏幕上停多久、是不是"一选就结束"。
## 只起面板，不建城镇。用法：<godot> --path . --resolution 1600x900 res://tools/outcome_hold_probe.tscn

const PANEL := preload("res://scripts/StoryEventPanel.gd")
var NODE_ID := "E04"

var _done := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if not String(arg).is_empty():
			NODE_ID = String(arg)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/outcome_hold"))
	_watchdog()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	var node := {}
	for value in (parsed as Dictionary).get("nodes", []):
		if String(Dictionary(value).get("id", "")) == NODE_ID:
			node = Dictionary(value)
	if node.is_empty():
		print("[hold] 找不到 ", NODE_ID)
		get_tree().quit(1)
		return
	var panel = PANEL.new()
	add_child(panel)
	panel.reduced_motion = true
	panel.present(node)
	panel.outcome_acknowledged.connect(func(_a, _b, _c):
		print("[hold] !! outcome_acknowledged 被发了（说明有人替玩家点了一下）"))
	panel.beat_reached.connect(func(_e, idx, _beat):
		print("[hold] !! beat_reached index=", idx))

	# 走到选项那一拍。
	for i in 40:
		await get_tree().create_timer(0.05).timeout
		if String(panel.call("current_stage")) == "choices":
			break
		panel.call("_advance")
	await get_tree().create_timer(0.2).timeout
	print("[hold] 选项阶段=", panel.call("current_stage"))
	await _shot("01_选项")

	# 点一个选项，然后什么都不做，看它自己会不会收。
	print("[hold] 这条回应按谁说话摆=", panel.call("_split_spoken_outcome", panel.call("_outcome_text", "A")))
	panel.call("_on_choice_picked", NODE_ID, "A", 45)
	var samples: Array = []
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		samples.append(String(panel.call("current_stage")))
	print("[hold] 选完之后 2 秒里每一拍：", " ".join(samples))
	print("[hold] 面板还开着=", bool(panel.call("is_open")), " 现在这一拍=", panel.call("current_stage"))
	await _shot("02_选完之后两秒")

	# 玩家点一下才收。
	panel.call("_advance")
	await get_tree().create_timer(0.4).timeout
	print("[hold] 点了一下之后：开着=", bool(panel.call("is_open")))
	print("OUTCOME_HOLD_DONE")
	_done = true
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://test_artifacts/outcome_hold/" + name + ".png"))


func _watchdog() -> void:
	await get_tree().create_timer(45.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
