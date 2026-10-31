extends Node

## 自由安排那一屏的体检：按钮叫什么、卡片三行写什么、心情刷新会不会把卡片打回去。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/activity_pause_check.tscn
##
## 直接喂节点给 runner_open_activity，不跑整月剧情：
## 关键是"后面还有没有剧情"这一条决定按钮标签，所以给两份不同的下一步。

const SHOT_DIR := "res://test_artifacts/activity_pause"

var _town: Node
var _ui: Node
var _done := false


func _ready() -> void:
	_watchdog()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(4.0)
	_ui = _town.get("_town_ui_v2")
	if _ui == null:
		print("CHECK ui_present=false")
		_finish()
		return
	_close_covering_panels()
	_town.set("_month12_active", true)
	_town.set("_month12_month", 3)
	var runner = _town.get("_month_runner")
	if runner == null:
		runner = MonthNodeRunner.new()
		runner.town = _town
		_town.set("_month_runner", runner)
	# 第 3 月的形状：两格夹在中间，后面还挂着「补会后记录」。
	runner.nodes = [{"id": "M03_BRIDGE", "nodeType": "main_story", "location": "B 区工位"}]
	runner.index = 0
	_town.call("runner_open_activity", _activity_node("M03_ACTIVITY"))
	await _wait(0.6)
	print("CHECK 中间月的按钮 = ", _button_text())
	print("CHECK 中间月的卡 = ", _card_text())
	await _shot("01_第三月_午后两格")
	# 心情变一次：卡片不许被打回 WorldClock 那条主线（打过就是"新员工手册"）。
	_town.call("_refresh_mood_hud")
	await _wait(0.4)
	print("CHECK 刷完心情后的卡 = ", _card_text())
	# 第 5 月的形状：两格就在月末，按钮照旧写「结束这个月」。
	runner.nodes = [{"id": "M05_CLOSE", "nodeType": "month_close"}]
	runner.index = 0
	_town.set("_month12_month", 5)
	_town.call("runner_open_activity", _activity_node("M05_FREE"))
	await _wait(0.5)
	print("CHECK 月末月的按钮 = ", _button_text())
	await _shot("02_第末月_结束这个月")
	_finish()


func _activity_node(node_id: String) -> Dictionary:
	return {
		"id": node_id,
		"nodeType": "activity",
		"timeBand": "afternoon",
		"budget": {"ap": 2, "slots": 2},
		"activityIds": [],
		"endMonthLabel": "结束这个月",
	}


func _button_text() -> String:
	var button: Button = _town.get("_end_month_button")
	if button == null:
		return "无"
	return "%s（可见=%s）" % [button.text, str(button.visible)]


func _card_text() -> String:
	if _ui == null:
		return "无"
	return "%s | %s | %s" % [
		String(_ui.get("_task_title").text),
		String(_ui.get("_task_meta").text),
		String(_ui.get("_task_note").text),
	]


func _close_covering_panels() -> void:
	for key in ["_story_event_panel", "_month12_close_panel", "_month12_handbook", "_month_phone_panel"]:
		var panel = _town.get(key)
		if panel != null and panel.has_method("is_open") and bool(panel.call("is_open")):
			if panel.has_method("close"):
				panel.call("close")
	var tour = _town.get("_hud_tour")
	if tour != null and tour.has_method("hide"):
		tour.call("hide")


func _watchdog() -> void:
	await get_tree().create_timer(45.0).timeout
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
	print("ACTIVITY_PAUSE_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)
