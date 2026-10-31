extends Node

## 核对一条规矩：黄线指到哪扇门，那扇门就不该是灰的。
## 做法：像 probe_year 一样替玩家把全年点完，每一帧比「黄线终点」和每扇门的距离；
## 只要发现「终点落在一扇灰门的 PLACE_REACH_DISTANCE 以内」，就记一笔（同一相位同一门只记一次）。
## 用法：<godot> --path <proj> --headless res://tools/door_waypoint_probe.tscn

const REACH := 96.0
## 黄线正在带路的那几个相位：新规则只认这些。
const WALK_PHASES := ["hud_tour", "tour", "e02_walk", "node_walk", "sleep_walk"]

var _town: Node
var _panel
var _hits := {}
var _rescued := {}
var _samples := {}
var _done := false


func _ready() -> void:
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.5).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	for tick in 6000:
		await get_tree().create_timer(0.04).timeout
		var month := int(_town.get("_month12_month"))
		var phase := String(_town.get("_month12_phase"))
		_sample(month, phase)
		if month >= 12 and phase == "done":
			break
		if phase == "done" and month == 7 \
				and bool((_town.get("_month12_flags") as Dictionary).get("m07_probation_deferred", false)):
			break
		var start_card = _town.get("_month12_start_panel")
		if start_card != null and bool(start_card.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.2).timeout
			continue
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		var tutorial = _town.get("_month_phone_tutorial")
		if tutorial != null and bool(tutorial.get("_card").visible):
			tutorial.call("close_tutorial")
			continue
		if bool(_town.get("_phone_gate_waiting")) and not bool(_town.get("_phone_gate_read")):
			_town.call("_open_ui_phone")
			continue
		var inbox = _town.get("_month_phone_panel")
		if inbox != null and bool(inbox.call("is_open")):
			if bool(inbox.get("_phone_open")):
				inbox.call("close_phone")
			else:
				inbox.call("open_phone")
			continue
		var hud_card = _town.get("_hud_button_tutorial")
		if hud_card != null and bool(hud_card.call("is_open")):
			hud_card.call("_on_later_pressed")
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			await get_tree().create_timer(0.2).timeout
			continue
		var visit_id := String(_town.get("_month12_visit_id"))
		if not visit_id.is_empty():
			var visit_door = _town.get("_story_door")
			if visit_door != null:
				_town.get("_player").position = (visit_door as Node2D).position
			await get_tree().create_timer(0.12).timeout
			_town.call("_begin_interaction")
			await get_tree().create_timer(0.25).timeout
			var place: Dictionary = _town.call("_month12_visit_place")
			if not place.is_empty():
				_town.call("_on_activity_selected", place)
			continue
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var event: Dictionary = _panel.get("_event")
			var eid := str(event.get("id", ""))
			var stage := String(_panel.get("_stage"))
			if stage == "choices":
				_panel.call("_on_choice_picked", eid, "A", 45)
			elif stage == "interaction" or stage == "handbook":
				pass
			else:
				_panel.call("_advance")
			continue
		if phase == "handbook":
			var book = _town.get("_month12_handbook")
			if book != null and bool(book.call("is_open")):
				book.call("close")
			continue
		if phase == "activity":
			await _do_activity_month(month)
			continue
		if phase == "close":
			_town.call("_on_month12_close_finished")
			continue

	print("---- 黄线 x 灰门 核对 ----")
	var bad := 0
	for key in _hits.keys():
		bad += 1
		print("  [灰门挡路] ", _hits[key])
	print("HIT_COUNT=", bad)
	print("---- 靠新规则才亮起来的门（按月） ----")
	var tally := {}
	for key in _rescued.keys():
		var month_no := int(String(key).split("|")[0].substr(1))
		tally[month_no] = int(tally.get(month_no, 0)) + 1
		print("  ", _rescued[key])
	for no in range(1, 13):
		if not tally.has(no):
			continue
		print("  第 %d 月：%d 处" % [no, int(tally[no])])
	print("RESCUED_COUNT=", _rescued.size())
	print("DOOR_STATES=", _samples.size())
	for row in _samples.keys():
		print("  ", row)
	_done = true
	get_tree().quit(0)


func _sample(month: int, phase: String) -> void:
	var doors: Dictionary = _town.get("_month12_place_portals")
	if doors == null or doors.is_empty():
		return
	var wp: Vector2 = _town.get("_month12_waypoint")
	for key in doors.keys():
		var door = doors[key]
		if door == null or not is_instance_valid(door):
			continue
		var sealed := bool(door.get("sealed"))
		var tag := "M%d %s 门数=%d %s=%s @%s" % [
			month, phase, doors.size(), String(key), "灰" if sealed else "金", str(door.position)]
		_samples[tag] = true
		if sealed and wp.x > -90000.0 and (door.position as Vector2).distance_to(wp) <= REACH:
			var k := "M%d|%s|%s" % [month, phase, String(key)]
			if not _hits.has(k):
				_hits[k] = "月=%d 相位=%s 门=%s 门位=%s 黄线终点=%s 距=%.0f" % [
					month, phase, String(key), str(door.position), str(wp),
					(door.position as Vector2).distance_to(wp)]
		_count_rescue(month, phase, String(key), door as Node2D, sealed, wp)


## 这扇门现在之所以是金的，是不是全靠「黄线终点不压灰」这条新规则撑着。
## 判法：走位相位里，这个月的门本来不开（open_now=false），门现在又不灰，
## 门的位置离旧例外的两个剧情点（带巡站、E02 周会桌）都超过 150 像素，
## 但离黄线终点在 150 以内 —— 那就是新规则救回来的。
func _count_rescue(month: int, phase: String, key: String, door: Node2D, sealed: bool, wp: Vector2) -> void:
	if sealed or not (phase in WALK_PHASES) or wp.x < -90000.0:
		return
	var open_now := bool(_town.get("_month12_places_open")) and bool(_town.call("_month12_place_window_open"))
	if open_now:
		return
	var dist_wp := door.position.distance_to(wp)
	if dist_wp > 150.0:
		return
	for point in (_town.call("_month12_story_points") as Array):
		if door.position.distance_to(point as Vector2) < 150.0:
			return
	var k := "M%d|%s" % [month, key]
	if not _rescued.has(k):
		_rescued[k] = "月=%d 相位=%s 门=%s 距黄线终点=%.0f" % [month, phase, key, dist_wp]


func _do_activity_month(month: int) -> void:
	var runner = _town.get("_month_runner")
	var node: Dictionary = runner.current if runner != null else {}
	var ids: Array = node.get("activityIds", []) as Array
	var slots: int = int(_town.get("_month12_slots_left"))
	var pending: Array = []
	for value in ids:
		var aid := String(value)
		if bool(_town.call("_month12_activity_visited", aid)):
			continue
		pending.append(aid)
	if slots <= 0 or pending.is_empty():
		_town.call("_on_end_month_pressed")
		return
	_town.call("_on_month12_place_confirmed", String(pending[0]))
	await get_tree().create_timer(0.25).timeout
	var scene = _town.get("_weekend_scene_panel")
	if scene != null and bool(scene.call("is_open")):
		scene.call("_advance")


func _watchdog() -> void:
	await get_tree().create_timer(280.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
