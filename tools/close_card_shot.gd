extends Node

## 月末回顾卡实拍：用第 2 月那两行真文案，看行长与各行的落点。
## 用法：<godot> --path <proj> res://tools/close_card_shot.tscn

const SHOT_DIR := "res://test_artifacts/close_card"
const CLOSE := preload("res://scripts/v12m/Month12ClosePanel.gd")

const P1 := "第 2 月，你先让开源路线跑起来，速度快了，维护和回滚的账还留着。"
const P2 := "提交说明写清了工具做过什么，也写下了你还没把握的地方。"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("7d8a6a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := CLOSE.new()
	add_child(panel)
	for run in [
		{"tag": "01_one_para", "text": P1, "ledger": "这个月没有个人时间"},
		{"tag": "02_two_para", "text": P1 + "\n" + P2, "ledger": "这个月没有个人时间"},
		{"tag": "03_long_ledger", "text": P1 + "\n" + P2, "ledger": "这个月安排了 3 件：去旧机房找日志（心情 +1）、和小赵对了一轮口径、在老周那儿把提交说明补齐 · 行动点用掉 3 · 心情 4 → 6"},
	]:
		panel.open(String(run["text"]), 2, String(run["ledger"]))
		await _wait(0.4)
		print("%s card_h=%s" % [run["tag"], panel.get("_card_h")])
		for node in panel.find_children("*", "Label", true, false):
			var label := node as Label
			print("  [%s] y=%s size=%s lines=%d" % [
				label.text.substr(0, 8), label.position.y, label.size, label.get_line_count()])
		await _shot(String(run["tag"]))
	print("CLOSE_SHOT_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, shot_name])
	print("shot %s -> %s" % [shot_name, image.save_png(path)])
