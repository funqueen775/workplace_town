extends Node

## 拍"最长的那几条选项"在屏上到底放不放得下：直接把剧情面板叫出来，
## 翻到选项那一拍截图，并量一遍每条按钮的文字宽度和自己的宽。
## 用法：<godot> --path <PROJ> --resolution 1920x1080 res://tools/choice_fit_shot.tscn

const PANEL := preload("res://scripts/StoryEventPanel.gd")
const EVENTS_PATH := "res://data/story/v12m/events.json"
const SHOT_DIR := "res://test_artifacts/choice_fit"
const TARGETS := ["E32", "E50_selfreview", "E27", "E40", "E19"]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var by := {}
	for value in ((parsed as Dictionary).get("nodes", []) as Array):
		by[String((value as Dictionary).get("id", ""))] = value
	var font := load("res://assets/fonts/NotoSansCJKsc-Regular.otf") as Font
	for eid in TARGETS:
		var node: Dictionary = by.get(eid, {}) as Dictionary
		if node.is_empty():
			print("NO_NODE ", eid)
			continue
		var panel = PANEL.new()
		add_child(panel)
		panel.reduced_motion = true
		panel.call("present", node)
		for _i in 60:
			if String(panel.get("_stage")) == "choices":
				break
			panel.call("_advance")
			await get_tree().process_frame
		await get_tree().process_frame
		_print_fit(eid, panel, font)
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		print("SHOT ", eid, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + eid + ".png")))
		panel.call("dismiss")
		panel.queue_free()
		await get_tree().process_frame
	print("CHOICE_FIT_DONE")
	get_tree().quit(0)


func _print_fit(eid: String, panel: Node, font: Font) -> void:
	var stack: Array = [panel]
	while not stack.is_empty():
		var node = stack.pop_back()
		for child in (node as Node).get_children():
			if child is Button and not (child as Button).text.is_empty() and (child as Control).visible:
				var button := child as Button
				var size_px := button.get_theme_font_size("font_size")
				var wide := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
				var lines := 1
				if button.size.x > 0.0:
					lines = int(maxi(1, round(wide / (button.size.x - 24.0))))
				print("FIT ", eid, " 按钮宽 %.0f 文字单行 %.0f 需要约 %d 行 高 %.0f ｜%s" % [
					button.size.x, wide, lines, button.size.y, button.text.substr(0, 18)])
			stack.append(child)
