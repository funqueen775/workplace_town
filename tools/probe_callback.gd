extends Node
## 验自由活动的回响：把某个旗标开/关，看那一屏的条件旁白到底出不出。
## 用法：<godot> --headless --path . res://tools/probe_callback.tscn

var _by_id := {}

# 屏 id、旗标、用来认那句话的关键词
const CASES := [
	["M08_OPEN", "extra_push", "白板上已经有人接着往下写了"],
	["M10_OPEN", "extra_push", "早就写完了"],
	["M04_OPEN", "m01_activity_tool", "检查脚本"],
	["M09_NAME", "m07_valley_first", "训练谷那一局"],
	["M11_MATERIAL", "m09_longtable", "长桌上写的那份记录"],
]


func _ready() -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	for value in ((raw as Dictionary).get("nodes", []) as Array):
		_by_id[String((value as Dictionary).get("id", ""))] = value
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.4).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	if bool(panel.call("is_open")):
		panel.call("dismiss")
	town.call("debug_jump_to_month", 8, "A")
	await get_tree().create_timer(1.6).timeout
	for case in CASES:
		var node_id := String(case[0])
		var flag := String(case[1])
		var needle := String(case[2])
		var off := _has_line(town, node_id, flag, needle, false)
		var on := _has_line(town, node_id, flag, needle, true)
		print("[回响] %-13s 旗标=%-20s 关=%s 开=%s" % [node_id, flag, off, on])
	get_tree().quit()


func _has_line(town: Node, node_id: String, flag: String, needle: String, with_flag: bool) -> bool:
	var flags: Dictionary = town.get("_month12_flags")
	if with_flag:
		flags[flag] = true
	else:
		flags.erase(flag)
	var node: Dictionary = _by_id.get(node_id, {})
	if node.is_empty():
		return false
	var data: Dictionary = town.call("_runner_story_data", node)
	for beat in (data.get("beats", []) as Array):
		if needle in String((beat as Dictionary).get("text", "")):
			return true
	return false
