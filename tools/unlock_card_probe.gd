extends Node

## 解锁卡核对：跳到某个月，把整月自动点过去，记下"新地点解锁卡"到底有没有弹、弹在哪一屏之后。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/unlock_card_probe.tscn -- --month=3
## 只读不改档：走的是 debug_jump_to_month，玩家包里没有这个入口。

var _town: Node
var _month := 3
var _cards: Array = []
var _shot_dir := ""
var _last_node := ""


func _ready() -> void:
	_watchdog()
	_read_args()
	_shot_dir = ProjectSettings.globalize_path("res://test_artifacts/unlock_cards")
	DirAccess.make_dir_recursive_absolute(_shot_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.4)
	_town.call("debug_jump_to_month", _month, "A")
	await _wait(2.4)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await _wait(1.2)

	var panel = _town.get("_story_event_panel")
	panel.set("reduced_motion", true)
	var place = _town.get("_month12_place_panel")
	var runner = _town.get("_month_runner")
	var seen_ids := {}

	for tick in 3000:
		await _wait(0.05)
		if not bool(runner.get("active")) and tick > 60:
			break
		var current_id := String((runner.get("current") as Dictionary).get("id", ""))
		if current_id != _last_node:
			_last_node = current_id
			var ui: Node = _town.get("_town_ui_v2")
			var band := ""
			var xun := ""
			if ui != null and is_instance_valid(ui):
				band = String((ui.call("date_band_cell") as Control).text)
				xun = String((ui.call("date_xun_cell") as Control).text)
			var cur: Dictionary = runner.get("current")
			var tail := ""
			var bs: Array = cur.get("beats", [])
			if not bs.is_empty():
				tail = String((bs[bs.size() - 1] as Dictionary).get("text", ""))
			_note("节点 %s | 数据时段=%s | 屏幕上=%s %s | 末句=%s" % [
				current_id, String(cur.get("timeBand", "")), xun, band, tail])
		# 门立起来了：记一笔，和"有没有卡"对着看。
		for key in (_town.get("_month12_place_portals") as Dictionary).keys():
			if not seen_ids.has(String(key)):
				seen_ids[String(key)] = true
				_note("门立起来了：%s" % String(key))
		if place != null and is_instance_valid(place) and bool(place.call("is_open")):
			var current: Dictionary = runner.get("current")
			_cards.append(String(current.get("id", "")))
			_note("★ 弹了解锁卡：在 %s 之后（第 %d 张）" % [String(current.get("id", "")), _cards.size()])
			get_viewport().get_texture().get_image().save_png(
				"%s/m%d_card_%d.png" % [_shot_dir, _month, _cards.size()])
			place.call("_on_unlock_ok", "")
			await _wait(0.5)
			continue
		var phone = _town.get("_month_phone_panel")
		if phone != null and is_instance_valid(phone) and bool((phone.get("_card") as Control).visible):
			phone.call("open_phone")
			await _wait(0.5)
			phone.call("close_phone")
			await _wait(0.4)
			continue
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				panel.call("_on_choice_picked", String((panel.get("_event") as Dictionary).get("id", "")), "A", 30)
			elif stage != "handbook":
				panel.call("_advance")
			continue
		if bool(runner.get("waiting_walk")):
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue

	print("---- 第 %d 月解锁卡核对 ----" % _month)
	print("  弹卡次数=", _cards.size(), " 卡在哪几屏之后=", _cards)
	print("  这个月立过的门=", seen_ids.keys())
	get_tree().quit(0)


func _read_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--month="):
			_month = int(arg.trim_prefix("--month="))


func _note(text: String) -> void:
	print("[card] ", text)


func _watchdog() -> void:
	await get_tree().create_timer(200.0).timeout
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
