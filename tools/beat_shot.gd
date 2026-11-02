extends Node

## 把某一屏的某一拍叫出来截图（查立绘 / 表情 / 气泡留白用）。
## 用法：<godot> --path <PROJ> --resolution 1920x1080 res://tools/beat_shot.tscn -- --node=M05_DEMO --beat=6

const PANEL := preload("res://scripts/StoryEventPanel.gd")
const EVENTS_PATH := "res://data/story/v12m/events.json"
const SHOT_DIR := "res://test_artifacts/beat_shot"

var _node_id := "M05_DEMO"
var _beat := 6
var _speaker := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--node="):
			_node_id = String(arg).get_slice("=", 1)
		elif String(arg).begins_with("--beat="):
			_beat = int(String(arg).get_slice("=", 1))
		elif String(arg).begins_with("--speaker="):
			_speaker = String(arg).get_slice("=", 1)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var node: Dictionary = {}
	for value in ((parsed as Dictionary).get("nodes", []) as Array):
		if String((value as Dictionary).get("id", "")) == _node_id:
			node = value as Dictionary
	if node.is_empty():
		print("BEATSHOT no_node ", _node_id)
		get_tree().quit(1)
		return
	var panel = PANEL.new()
	add_child(panel)
	panel.reduced_motion = true
	panel.call("present", node)
	# 要停在第几拍：给了 --speaker 就找那个人开口的那一拍，否则用 --beat。
	var target := _beat
	if not _speaker.is_empty():
		target = -1
		var index := 0
		for beat in (node.get("beats", []) as Array):
			if String((beat as Dictionary).get("speaker", "")) == _speaker:
				target = index
				break
			index += 1
		if target < 0:
			print("BEATSHOT no_speaker ", _speaker)
			get_tree().quit(1)
			return
	for _i in range(target + 2):
		if int(panel.call("beat_index")) >= target:
			break
		await get_tree().process_frame
		panel.call("_advance")
	for _i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var file := "%s_b%d.png" % [_node_id, target]
	print("BEATSHOT ", file, " beat_index=", int(panel.call("beat_index")),
		" saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + file)))
	get_tree().quit(0)
