extends Node

## 旧 48 个月那本手册（data/story/employee_handbook.json，id 是 tech/process/promotion）
## 也走同一个阅读器。目录改成分组之后，得确认这本没有点号 id 的册子目录还在。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/handbook_legacy_shot.tscn

const SHOT_DIR := "res://test_artifacts/handbook_legacy"
const HANDBOOK := preload("res://scripts/HandbookPanel.gd")

var _panel: CanvasLayer
var _done := false


func _ready() -> void:
	_watchdog()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("6f7d5a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = HANDBOOK.new()
	add_child(_panel)
	await _wait(0.4)
	# 不传数据：走 CONTENT_PATH 那份旧册子
	_panel.call("open")
	await _wait(0.6)
	var rail: Control = _panel.get("_rail")
	var rows := 0
	for child in rail.get_children():
		if child is Button:
			rows += 1
			print("LEGACY 组名=", (child as Button).text)
		elif child is VBoxContainer:
			for item in (child as VBoxContainer).get_children():
				rows += 1
				print("LEGACY 条目=", (item as Button).text)
	var label: Label = _panel.get("_page_label")
	print("LEGACY 组标题按钮=", rows, " 页脚=", label.text)
	await _shot("01_legacy_open")
	_done = true
	print("LEGACY_DONE")
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
	print("SHOT ", shot_name, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")))
