extends Node

## 实拍：格子用完那一刻，结果卡上第二句到底是什么话。
## 三种状态各演一次：还有格 / 没格且后面就是月末 / 没格但今天后面还有剧情。
## 用法：<godot> --path . --headless res://tools/outcome_line_probe.tscn

var _town: Node
var _panel: Node
var _tool: Dictionary = {}
var _done := false


func _ready() -> void:
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.0).timeout
	var start: Variant = _town.get("_month12_start_panel")
	if start != null and is_instance_valid(start) and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await get_tree().create_timer(1.2).timeout
	_town.call("debug_jump_to_month", 3)
	await get_tree().create_timer(1.6).timeout
	_panel = _town.get("_weekend_scene_panel")
	var places: Array = _town.get("_month12_places")
	for value in places:
		if String(Dictionary(value).get("id", "")) == "m1_tool":
			_tool = Dictionary(value)
	if _tool.is_empty():
		print("WARN no m1_tool")
	# 状态一：还剩一格。
	_speak(1, false)
	print("STATE_1 还剩格 → ", _second_line())
	# 状态二：格子用完，后面紧跟月末（首月那种）。
	_speak(0, true)
	print("STATE_2 没格+后面是月末 → ", _second_line())
	# 状态三：格子用完，今天后面还有剧情屏（第 3/5/7/9/11 月）。
	_speak(0, false)
	print("STATE_3 没格+后面还有剧情 → ", _second_line())
	print("OUTCOME_TEXT_DONE")
	_done = true
	get_tree().quit(0)


func _speak(left: int, next_close: bool) -> void:
	_town.set("_month12_activity_generic", true)
	_town.set("_month12_slots_left", left)
	_town.set("_activity_next_is_close", next_close)
	if not _tool.is_empty():
		_town.call("_present_month12_place_outcome", _tool)


func _second_line() -> String:
	if _panel == null or not is_instance_valid(_panel):
		return "(没有结果面板)"
	var lines: Array = _panel.get("_lines")
	if lines.size() < 2:
		return "(只有一句)"
	return String(lines[1])


func _watchdog() -> void:
	await get_tree().create_timer(180.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
