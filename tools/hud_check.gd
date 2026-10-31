extends Node

## 界面体检：四角的东西还在不在。
## 左上（日期 + 岗位栏 + 处境行）、右上（任务卡）、右下（底排圆钮）、左下（摇杆）。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/hud_check.tscn

const SHOT_DIR := "res://test_artifacts/hud_check"

var _town: Node
var _ui: Node
var _done := false


func _ready() -> void:
	_watchdog()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(4.0)
	_ui = _town.get("_town_ui_v2") as Node
	if _ui == null:
		print("CHECK ui_present=false  ← 界面整块没建起来")
		await _shot("00_no_ui")
		_finish()
		return
	print("CHECK ui_present=true")
	# 首月是分批开放的：手机、手册要等到有内容才亮。为了体检先全部亮出来看位置，
	# 再单独拍一张"按剧情该有的样子"。
	var phone: Button = _ui.get("_phone_button") as Button
	var manual: Button = _ui.get("_manual_button") as Button
	print("CHECK archive_button_gone=", _ui.get("_archive_button") == null)
	print("CHECK job_plate=", _rect(_ui.get("_job_label")))
	print("CHECK standing_line=", _rect(_ui.get("_standing_line")), " visible=", _shown(_ui.get("_standing_line")))
	print("CHECK date_plate=", _rect(_ui.get("_act_label")))
	print("CHECK task_panel=", _rect(_ui.get("_task_panel")))
	print("CHECK task_title=", (_ui.get("_task_title") as Label).text, " | meta=", (_ui.get("_task_meta") as Label).text, " | note=", (_ui.get("_task_note") as Label).text)
	print("CHECK settings=", _rect(_ui.get("_settings_button")), " visible=", _shown(_ui.get("_settings_button")))
	print("CHECK phone=", _rect(phone), " visible=", _shown(phone))
	print("CHECK manual=", _rect(manual), " visible=", _shown(manual))
	# 挡图的卡片先收干净：剧情面板、月末卡、开场导览。
	_close_covering_panels()
	await _wait(0.5)
	await _shot("01_按剧情该有的样子")
	# 再把还没解锁的入口亮出来，看四角排版（不代表玩家此刻能看到）。
	_ui.call("set_phone_visible", true)
	_ui.call("set_manual_visible", true)
	_ui.call("_layout_hud")
	await _wait(0.3)
	await _shot("02_入口全亮")
	# 处境那一行：被观察时该在岗位栏底下出现。
	_ui.call("set_standing_line", "被观察", "e0a63c")
	await _wait(0.3)
	await _shot("03_处境那行字")
	# 点岗位栏该开档案页。
	var plate: Button = _ui.get("_job_label") as Button
	if plate != null:
		var before := String(_ui.get("_view"))
		plate.emit_signal("pressed")
		await _wait(0.6)
		print("CHECK 点岗位栏：页面 ", before, " -> ", String(_ui.get("_view")))
		await _shot("04_档案页")
	_finish()


func _close_covering_panels() -> void:
	for name in ["_story_event_panel", "_month12_close_panel", "_month12_handbook", "_month_phone_panel"]:
		var panel: Node = _town.get(name) as Node
		if panel != null and panel.has_method("is_open") and bool(panel.call("is_open")):
			if panel.has_method("close"):
				panel.call("close")
	var tour: Node = _town.get("_hud_tour") as Node
	if tour != null and tour.has_method("hide"):
		tour.call("hide")


func _rect(node: Object) -> String:
	if node == null:
		return "无"
	var control := node as Control
	if control == null:
		return "无"
	return "pos=%s size=%s" % [str(control.position), str(control.size)]


func _shown(node: Object) -> bool:
	var control := node as Control
	return control != null and control.is_visible_in_tree()


func _watchdog() -> void:
	await get_tree().create_timer(60.0).timeout
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


func _finish() -> void:
	_done = true
	print("HUD_CHECK_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)
