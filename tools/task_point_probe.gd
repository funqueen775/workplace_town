extends Node

## 把「让玩家去某个地方」这件事，整条链路扫一遍，看有没有自相矛盾。
## 同一个病有三种面孔，一次跑完：
##   A 黄线没画出来：任务卡说"跟着黄线走"，玩家离终点还远，但地面一条线都没有；
##   B 终点站不住：黄线目的地本身不可行走 / 出界，玩家根本走不到；
##   C 金门却按不了 E：门是亮的（说明这儿能去），贴到门口却没有任何按 E 提示。
## 用法：<godot> --path <proj> --headless res://tools/task_point_probe.tscn

const REACH := 96.0
## 发现新黄线终点后先让它自己铺 0.6 秒再传送：把玩家一帧挪过去就永远测不到"线画没画出来"。
const HOLD_SECONDS := 0.6
const WALK_PHASES := ["tour", "e02_walk", "node_walk", "sleep_walk"]

var _town: Node
var _panel
var _hits_a := {}
var _hits_b := {}
var _hits_c := {}
var _prompt_ok := {}
var _last_waypoint := Vector2(-99999, -99999)
var _hold_until_msec := 0
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
		if phase in WALK_PHASES:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0 and Time.get_ticks_msec() >= _hold_until_msec:
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
	_report()
	_done = true
	get_tree().quit(0)


func _sample(month: int, phase: String) -> void:
	# C 每帧都查：只在"换目标那一帧"查会漏掉真正贴着门站的那几帧。
	_check_gold_door_no_prompt(month, phase)
	var wp: Vector2 = _town.get("_month12_waypoint")
	var new_target := _last_waypoint.distance_to(wp) > 1.0
	_last_waypoint = wp
	if wp.x < -90000.0:
		return
	if new_target and phase in WALK_PHASES:
		# B：这个终点能不能站人。判定不能只看中心点——游戏要求的只是"走进 70 像素"，
		# 所以扫一圈：中心不可走时，看 70 像素内有没有任何能站的地方。
		if not _has_standing_ground(wp):
			var kb := "M%d|%s|%s" % [month, phase, str(wp)]
			if not _hits_b.has(kb):
				_hits_b[kb] = "月=%d 相位=%s 终点=%s 站不住（70 像素内没有能站的地面）" % [month, phase, str(wp)]
		_hold_until_msec = Time.get_ticks_msec() + int(HOLD_SECONDS * 1000.0)
		await get_tree().create_timer(HOLD_SECONDS).timeout
		# A：0.6 秒之后线该画出来了。
		var again: Vector2 = _town.get("_month12_waypoint")
		if again.distance_to(wp) < 1.0:
			var player: Node2D = _town.get("_player")
			var guide = _town.get("_guide_line")
			if player != null and guide != null and not bool(guide.call("is_guiding")):
				var dist := player.position.distance_to(wp)
				if dist > 70.0:
					var ka := "M%d|%s|%s" % [month, phase, str(wp)]
					if not _hits_a.has(ka):
						_hits_a[ka] = "月=%d 相位=%s 终点=%s 人距终点=%.0f 地面没有黄线" % [
							month, phase, str(wp), dist]
		_check_gold_door_no_prompt(month, phase)


## 终点附近有没有能站人的地面：中心 + 半径 10…70 的十六个方向，任一可走即可。
func _has_standing_ground(point: Vector2) -> bool:
	if bool(_town.call("_is_walkable_position", point)):
		return true
	for radius in [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0]:
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var probe: Vector2 = point + Vector2(cos(angle), sin(angle)) * float(radius)
			if bool(_town.call("_is_walkable_position", probe)):
				return true
	return false


## C：门是金的（说明"这儿能去"），人已经贴到门口，却没有任何按 E 的提示。
func _check_gold_door_no_prompt(month: int, phase: String) -> void:
	var doors: Dictionary = _town.get("_month12_place_portals")
	var button = _town.get("_interaction_button")
	var player: Node2D = _town.get("_player")
	if doors == null or button == null or player == null:
		return
	for key in doors.keys():
		var door = doors[key]
		if door == null or not is_instance_valid(door):
			continue
		if bool(door.get("sealed")):
			continue
		if player.position.distance_to((door as Node2D).position) > REACH:
			continue
		var kc := "M%d|%s|%s" % [month, phase, String(key)]
		if bool(button.visible):
			_prompt_ok[kc] = "月=%d 相位=%s 门=%s 门口有提示（文本=%s）" % [
				month, phase, String(key), String(button.text)]
			continue
		if not _hits_c.has(kc):
			_hits_c[kc] = "月=%d 相位=%s 门=%s 门位=%s 门是金的、人贴到门口却不给 E" % [
				month, phase, String(key), str((door as Node2D).position)]


func _report() -> void:
	print("---- 任务点一致性：三种面孔 ----")
	for title in ["A 任务卡说跟着黄线走、地面却没有线", "B 黄线终点站不住", "C 金门却按不了 E"]:
		print("== " + title)
	var bad := 0
	for key in _hits_a.keys():
		bad += 1
		print("  [A] ", _hits_a[key])
	for key in _hits_b.keys():
		bad += 1
		print("  [B] ", _hits_b[key])
	for key in _hits_c.keys():
		bad += 1
		print("  [C] ", _hits_c[key])
	print("ISSUE_COUNT=", bad,
		" A=", _hits_a.size(), " B=", _hits_b.size(), " C=", _hits_c.size())
	print("---- 参照：门在附近且门口有提示（不是问题，只用来确认抽样没落空）----")
	for key in _prompt_ok.keys():
		print("  [ok] ", _prompt_ok[key])
	print("PROMPT_OK=", _prompt_ok.size())


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
