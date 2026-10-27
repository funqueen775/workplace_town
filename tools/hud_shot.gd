extends Node

## 小镇界面实拍：任务卡 + 右下角那排圆钮 + 档案页。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/hud_shot.tscn

const SHOT_DIR := "res://test_artifacts/v12m_hud"

var _town: Node
var _ui: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.4)
	_ui = _town.get("_town_ui_v2")
	if _ui == null:
		print("NO_UI")
		get_tree().quit(1)
		return
	# 五颗钮在首月是分阶段解锁的，拍图时全部亮出来，好一次看全。
	_ui.call("set_phone_visible", true)
	_ui.call("set_manual_visible", true)
	var panel = _town.get("_story_event_panel")
	for i in 400:
		await _wait(0.05)
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if panel != null and bool(panel.call("is_open")):
			panel.call("_advance")
			continue
		if String(_town.get("_month12_phase")) == "tour":
			break
	await _wait(0.8)
	await _shot("01_tour_card_and_buttons")
	_ui.call("open_view", "profile")
	await _wait(0.6)
	await _shot("02_archive_page")
	print("HUD_SHOTS_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
