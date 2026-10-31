extends Node

## 月首卡尺寸对照：同一张卡，分别在不同窗口尺寸下拍一张，看字到底小到什么程度。
## 用法：<godot> --path <proj> --resolution 1280x720 res://tools/card_size_shot.tscn
##       把 --resolution 换成 1920x1080 再跑一次就是另一档。

const SHOT_DIR := "res://test_artifacts/card_size"

var _done := false


func _ready() -> void:
	_watchdog()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("6f8f5a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := MonthStartPanel.new()
	add_child(panel)
	await _wait(0.4)
	panel.call("open", 1, "B 区训练室门口", "入职说明会", "第一天来到小镇，先熟悉这里，再开始手头的工作。")
	# 留几秒给屏幕截图工具抓"这块窗口实际多大"，PNG 本身看不出缩放。
	await _wait(0.5)
	if OS.get_cmdline_user_args().has("hold"):
		await _wait(5.0)
	var view := get_viewport().get_visible_rect().size
	var tag := "%dx%d" % [int(view.x), int(view.y)]
	await _shot(tag)
	_done = true
	print("CARD_SIZE_DONE ", tag)
	get_tree().quit(0)


func _watchdog() -> void:
	await get_tree().create_timer(25.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")
	print("SHOT ", shot_name, " saved=", image.save_png(path))
