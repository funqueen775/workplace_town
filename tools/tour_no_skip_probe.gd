extends Node

## 带巡强制核对：按 Esc 不能再跳过，五站一站都不能少，手机照样发到手。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/tour_no_skip_probe.tscn

var _town: Node
var _ui: Node
var _done := false
var _esc_tried := false
var _rows: Array = []
var _stops_seen := 0
var _phone_card := false
var _tail_logged := {}


func _ready() -> void:
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	_ui = _town.get("_town_ui_v2")
	var panel = _town.get("_story_event_panel")
	panel.reduced_motion = true
	_town.call("_on_month_start_continued")
	await _wait(0.8)

	for i in 2400:
		await _wait(0.05)
		var phase := String(_town.get("_month12_phase"))
		var index := int(_town.get("_month12_tour_index"))
		if phase == "tour" and index > _stops_seen - 1 and not _esc_tried and _stops_seen == 0:
			_esc_tried = true
			await _try_escape(index)
		if phase == "tour":
			var now := index + 1
			if now > _stops_seen:
				_stops_seen = now
				_note("到第 %d 站（%s）" % [now, String(_town.get("_month12_phase"))])
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		var place = _town.get("_month12_place_panel")
		if place != null and is_instance_valid(place) and bool(place.call("is_open")):
			_note("第 %d 站的地点解锁卡弹出，替玩家点「知道了」" % (index + 1))
			place.call("_on_unlock_ok", "")
			await _wait(0.4)
			continue
		var drawer = _town.get("_month_phone_panel")
		if drawer != null and bool((drawer.get("_card") as Control).visible) and not _phone_card:
			_phone_card = true
			_note("手机讲解卡弹了（带巡没跳，手机发到手）")
			drawer.call("open_phone")
			await _wait(0.7)
			_note("右下角手机图标可见=%s" % (_ui.get("_phone_button") as Button).visible)
			drawer.call("close_phone")
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if int(_town.get("_month12_month")) >= 2:
			_note("进了第 2 月，停手")
			break
		if bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			_log_stop_tail(panel, index)
			if stage == "choices":
				var ev: Dictionary = panel.get("_event")
				panel.call("_on_choice_picked", String(ev.get("id", "")), "A", 45)
			elif stage != "interaction" and stage != "handbook":
				panel.call("_advance")
			continue
		if phase == "activity":
			_town.call("_on_end_month_pressed")
			continue
		if phase == "close":
			_town.call("_on_month12_close_finished")
			continue

	print("---- 带巡强制核对 ----")
	for row in _rows:
		print("  ", row)
	print("走过站数=", _stops_seen, " 手机卡=", _phone_card)
	_done = true
	get_tree().quit(0)


## 在第一站正要走的时候按一次真 Esc，看会不会被跳掉。
func _try_escape(before: int) -> void:
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	_town.call("_unhandled_input", esc)
	await _wait(0.6)
	var after := int(_town.get("_month12_tour_index"))
	_note("按 Esc 前站号=%d 按之后站号=%d 相位=%s → 被跳过了吗=%s" % [
		before, after, String(_town.get("_month12_phase")), str(after != before)])


## 每站只记一次：这一屏最后一句是谁说的、说了什么——核"屏末交代"有没有真进到面板里。
func _log_stop_tail(panel: Node, index: int) -> void:
	if _tail_logged.has(index):
		return
	_tail_logged[index] = true
	var ev: Dictionary = panel.get("_event")
	var beats: Array = ev.get("beats", [])
	if beats.is_empty():
		_note("第 %d 屏没有台词" % (index + 1))
		return
	var last: Dictionary = beats[beats.size() - 1]
	_note("第 %d 屏「%s」末句 = %s：%s" % [
		index + 1, String(ev.get("title", "")),
		String(last.get("speaker", last.get("type", ""))), String(last.get("text", ""))])


func _note(text: String) -> void:
	_rows.append(text)
	print("[tour] ", text)


func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	if _done:
		return
	print("---- 带巡强制核对（超时收尾）----")
	for row in _rows:
		print("  ", row)
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
