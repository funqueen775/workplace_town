class_name ActionWindow
extends Node

signal window_started(snapshot: Dictionary)
signal action_spent(snapshot: Dictionary, record: Dictionary)
signal window_finished(snapshot: Dictionary)

const CONFIG_PATH := "res://data/story/main_story_v12.json"
const POINTS_PER_WINDOW := 3

var active := false
var remaining := 0
var current_window_id := ""
var current_after_event := ""

var _windows: Array = []
var _activities_by_region: Dictionary = {}
var _completed_window_ids: Array[String] = []
var _pending_windows: Array = []
var _records: Array = []


func _ready() -> void:
	_load_config()


func _load_config() -> void:
	var text := FileAccess.get_file_as_string(CONFIG_PATH)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("无法读取行动力窗口配置：" + CONFIG_PATH)
		return
	_windows = (parsed as Dictionary).get("freeWindows", []) as Array
	_activities_by_region = (parsed as Dictionary).get("activitiesByRegion", {}) as Dictionary


func start_after_event(event_id: String) -> bool:
	_pending_windows.clear()
	for value in _windows:
		if not (value is Dictionary):
			continue
		var window := value as Dictionary
		var window_id := String(window.get("id", ""))
		if String(window.get("afterEvent", "")) == event_id and not _completed_window_ids.has(window_id):
			_pending_windows.append(window.duplicate(true))
	if _pending_windows.is_empty():
		return false
	_start_next_pending_window()
	return true


func _start_next_pending_window() -> void:
	if _pending_windows.is_empty():
		active = false
		remaining = 0
		current_window_id = ""
		current_after_event = ""
		return
	var window := _pending_windows.pop_front() as Dictionary
	active = true
	remaining = POINTS_PER_WINDOW
	current_window_id = String(window.get("id", ""))
	current_after_event = String(window.get("afterEvent", ""))
	_records.clear()
	window_started.emit(snapshot())


func activities_for_region(region_id: String) -> Array:
	if not active:
		return []
	return configured_activities_for_region(region_id)


func configured_activities_for_region(region_id: String) -> Array:
	var activities = _activities_by_region.get(region_id.to_upper(), [])
	return (activities as Array).duplicate(true) if activities is Array else []


func spend_on_activity(activity: Dictionary) -> Dictionary:
	return _spend("area_activity", String(activity.get("id", "")), String(activity.get("title", "")))


func _spend(kind: String, target_id: String, label: String) -> Dictionary:
	if not active or remaining <= 0:
		return {"ok": false, "text": "当前不在自由活动窗口。"}
	var record := {
		"windowId": current_window_id,
		"kind": kind,
		"targetId": target_id,
		"label": label,
		"remainingBefore": remaining,
	}
	remaining -= 1
	record["remainingAfter"] = remaining
	_records.append(record)
	action_spent.emit(snapshot(), record)
	if remaining == 0:
		_completed_window_ids.append(current_window_id)
		active = false
		window_finished.emit(snapshot())
	return {"ok": true, "text": "行动完成，剩余行动力 %d/%d。" % [remaining, POINTS_PER_WINDOW], "remaining": remaining}


func has_pending_window() -> bool:
	return not _pending_windows.is_empty()


func continue_pending_window() -> bool:
	if active or _pending_windows.is_empty():
		return false
	_start_next_pending_window()
	return true

func abandon_for_month_jump() -> void:
	active = false
	remaining = 0
	current_window_id = ""
	current_after_event = ""
	_pending_windows.clear()
	_records.clear()


func snapshot() -> Dictionary:
	return {
		"active": active,
		"windowId": current_window_id,
		"afterEvent": current_after_event,
		"remaining": remaining,
		"maximum": POINTS_PER_WINDOW,
		"records": _records.duplicate(true),
		"completedWindowIds": _completed_window_ids.duplicate(),
		"pendingCount": _pending_windows.size(),
	}


func save_progress() -> Dictionary:
	return {"active": active, "remaining": remaining, "windowId": current_window_id, "afterEvent": current_after_event, "completed": _completed_window_ids.duplicate(), "pending": _pending_windows.duplicate(true), "records": _records.duplicate(true)}


func load_progress(data: Dictionary) -> void:
	active = bool(data.get("active", false))
	remaining = clampi(int(data.get("remaining", 0)), 0, POINTS_PER_WINDOW)
	current_window_id = String(data.get("windowId", ""))
	current_after_event = String(data.get("afterEvent", ""))
	_completed_window_ids.clear()
	for value in data.get("completed", []):
		_completed_window_ids.append(String(value))
	_pending_windows = (data.get("pending", []) as Array).duplicate(true)
	_records = (data.get("records", []) as Array).duplicate(true)
