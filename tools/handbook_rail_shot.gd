extends Node

## 手册目录那一列的滚动实拍：14 章会不会顶出页面、跳章时能不能滚到眼前、滚轮听不听话。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/handbook_rail_shot.tscn

const SHOT_DIR := "res://test_artifacts/handbook_rail"
const HANDBOOK := preload("res://scripts/HandbookPanel.gd")
const DATA_PATH := "res://data/story/employee_handbook_12m.json"

var _panel: CanvasLayer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("6f7d5a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = HANDBOOK.new()
	add_child(_panel)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	_panel.open(parsed if parsed is Dictionary else {})
	await _wait(0.5)
	var chapters: Array = parsed.get("chapters", []) as Array
	print("章节数 %d" % chapters.size())
	await _shot("01_open_ch1")
	var target := String(Dictionary(chapters[7]).get("id", ""))
	print("跳到第 8 章 id=%s" % target)
	_panel.call("_select_chapter", target)
	await _wait(0.4)
	await _shot("02_jump_ch8")
	var rail: ScrollContainer = _panel.get("_rail_scroll")
	print("跳章后目录位置 %s（视口 %s / 内容 %s）" % [rail.scroll_vertical, rail.size.y, _panel.get("_rail").size.y])
	for i in 6:
		_wheel_down(rail.get_global_rect().get_center())
		await _wait(0.1)
	await _wait(0.3)
	print("滚轮之后目录位置 %s" % rail.scroll_vertical)
	await _shot("03_wheel_down")
	print("HANDBOOK_RAIL_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wheel_down(at: Vector2) -> void:
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = at
	wheel.global_position = at
	get_viewport().push_input(wheel, true)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, shot_name])
	print("shot %s -> %s" % [shot_name, image.save_png(path)])
