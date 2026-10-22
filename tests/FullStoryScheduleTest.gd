extends Node


func _ready() -> void:
	var events: Array = WorldClock.story_events()
	if events.size() != 39:
		_fail("V1.2主线事件数量应为39，实际为%d" % events.size())
		return
	var expected_order := [
		"E01", "E02", "E03", "E04", "E05", "E06", "E07", "E08", "E09", "E10",
		"E11", "E12", "E13", "E14", "E15", "E36", "E37", "E16", "E17", "E18",
		"E19", "E20", "E21", "E22", "E23", "E24", "E25", "E26", "E27", "E28",
		"E29", "E30", "E38", "E39", "E31", "E32", "E33", "E34", "E35",
	]
	for index in events.size():
		var event := events[index] as Dictionary
		if String(event.get("id", "")) != expected_order[index]:
			_fail("第%d个事件顺序错误：%s" % [index + 1, String(event.get("id", "?"))])
			return
		if (event.get("choices", []) as Array).size() != 3:
			_fail("%s必须有3个选项" % String(event.get("id", "?")))
			return
		if (event.get("outcome", {}) as Dictionary).size() != 3:
			_fail("%s必须有3条即时反馈" % String(event.get("id", "?")))
			return
	var last := events.back() as Dictionary
	if int(last.get("month", 0)) != 48 or String(last.get("id", "")) != "E35":
		_fail("终局必须是第48月E35")
		return
	var config = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/main_story_v12.json"))
	if not (config is Dictionary) or ((config as Dictionary).get("freeWindows", []) as Array).size() != 24:
		_fail("V1.2必须保留文档中的24个自由活动窗口")
		return
	print("FULL_STORY_SCHEDULE_PASS events=39 windows=24 end_month=48")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("FULL_STORY_SCHEDULE_FAIL " + message)
	get_tree().quit(1)
