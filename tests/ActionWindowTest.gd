extends Node

const ACTION_WINDOW := preload("res://scripts/ActionWindow.gd")


func _ready() -> void:
	var window := ACTION_WINDOW.new()
	add_child(window)
	if not window.start_after_event("E01"):
		_fail("E01后必须开启自由活动窗口")
		return
	if not window.active or window.remaining != 3:
		_fail("窗口开始时必须发放3点行动力")
		return
	var activities := window.activities_for_region("C")
	if activities.size() != 2:
		_fail("C区必须显示2类活动")
		return
	for index in 3:
		var result := window.spend_on_activity(activities[index % activities.size()] as Dictionary)
		if not bool(result.get("ok", false)):
			_fail("第%d次活动未能消耗行动力" % (index + 1))
			return
	if window.active or window.remaining != 0:
		_fail("三次行动后窗口必须结束")
		return
	if window.start_after_event("E04"):
		_fail("文档未在E04后安排自由活动窗口")
		return
	print("ACTION_WINDOW_PASS points=3 activities_per_region=2")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("ACTION_WINDOW_FAIL " + message)
	get_tree().quit(1)
