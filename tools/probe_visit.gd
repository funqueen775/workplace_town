extends Node
## 到访真路探针：跳进第 N 月，自由安排那一段按玩家真走的路演一遍——
## 走到门口 → 按 E 进屋 → 点右侧那一行 → 确认页 → 结果页 → 回主线。
## 用法：<godot> --path <PROJ> --headless res://tools/probe_visit.tscn -- --month=9 --path-letter=A
## 目的：把"只在去过某地之后才出现"的那几屏（书院那一眼、长桌交接文档、水巷门口那个人）
##       真的播一遍，而不是靠推理说它应该能出现。

var _town: Node
var _panel
var _visited_now: Array = []
var _last_id := ""
var _letter := "A"
var _close_texts := {}
var _only: Array = []


func _ready() -> void:
	var month := 1
	for arg in OS.get_cmdline_user_args():
		var text := String(arg)
		if text.begins_with("--month="):
			month = clampi(int(text.get_slice("=", 1)), 1, 12)
		elif text.begins_with("--path-letter="):
			_letter = text.get_slice("=", 1).to_upper()
		elif text.begins_with("--visit="):
			_only = text.get_slice("=", 1).split(",")
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.5).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	_town.call("debug_jump_to_month", month, _letter)
	for tick in 9000:
		await get_tree().create_timer(0.04).timeout
		var cur_month := int(_town.get("_month12_month"))
		var start_panel = _town.get("_month12_start_panel")
		if start_panel != null and bool(start_panel.call("is_open")):
			start_panel.emit_signal("continued")
			continue
		var phase := String(_town.get("_month12_phase"))
		var override_text := String(_town.get("_month_close_text_override"))
		if override_text != "" and not _close_texts.has(str(cur_month)):
			_close_texts[str(cur_month)] = String(override_text)
		_grab_close_card(cur_month)
		if cur_month >= 12 and phase == "done":
			break
		if cur_month > month and phase != "close":
			break
		var runner = _town.get("_month_runner")
		var node: Dictionary = runner.current if runner != null else {}
		var nid := String(node.get("id", ""))
		if phase in ["tour", "e02_walk", "node_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var event: Dictionary = _panel.get("_event")
			var eid := str(event.get("id", ""))
			if eid != _last_id:
				_last_id = eid
				print("[屏] m%d %-18s 拍=%d 选项=%d" % [
					cur_month, eid, (event.get("beats", []) as Array).size(),
					(event.get("choices", []) as Array).size()])
			var stage := String(_panel.get("_stage"))
			if stage == "choices":
				_panel.call("_on_choice_picked", eid, _letter, 45)
			elif stage in ["interaction", "handbook"]:
				pass
			else:
				_panel.call("_advance")
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			continue
		if phase == "handbook":
			var book = _town.get("_month12_handbook")
			if book != null and bool(book.call("is_open")):
				book.call("close")
			continue
		if phase == "activity":
			await _visit_all(node)
			continue
		if phase == "close":
			print("[月末卡] m%d ｜ %s" % [cur_month, _close_texts.get(str(cur_month), "(没抓到)")])
			_town.call("_on_month12_close_finished")
			continue
	print("[探针结束] phase=%s 月=%s 心情=%s 这一月去过的=%s" % [
		_town.get("_month12_phase"), _town.get("_month12_month"), _town.get("_mood"),
		JSON.stringify(_visited_now)])
	get_tree().quit(0)


## 这个月列出的去处，一个一个真走一遍：门口按 E → 列表 → 确认 → 结果。
## --visit=m9_library 点名的去处先走（格数有限，不点名就按数据里的顺序，可能轮不到新地方）。
func _visit_all(node: Dictionary) -> void:
	var ids: Array = node.get("activityIds", []) as Array
	var prioritized: Array = []
	for wanted in _only:
		if wanted in ids:
			prioritized.append(wanted)
	for value in ids:
		if not (value in prioritized):
			prioritized.append(value)
	ids = prioritized
	var did_any := false
	for value in ids:
		var aid := String(value)
		if int(_town.get("_month12_slots_left")) <= 0:
			break
		if bool(_town.call("_month12_activity_visited", aid)):
			continue
		var place: Dictionary = _town.call("_month12_place_by_id", aid)
		if place.is_empty():
			continue
		var portal = (_town.get("_month12_place_portals") as Dictionary).get(aid)
		if portal != null:
			_town.get("_player").position = (portal as Node2D).position
			await get_tree().create_timer(0.3).timeout
			_town.call("_begin_interaction")
			await get_tree().create_timer(0.4).timeout
		_town.set("_month12_nearby_place", aid)
		_town.call("_enter_month12_place")
		await get_tree().create_timer(0.5).timeout
		_town.call("_on_activity_selected", place)
		await get_tree().create_timer(0.4).timeout
		_town.call("_on_month12_place_confirmed", aid)
		await get_tree().create_timer(0.5).timeout
		var scene = _town.get("_weekend_scene_panel")
		if scene != null and bool(scene.call("is_open")):
			scene.call("_finish")
			await get_tree().create_timer(0.4).timeout
		_visited_now.append(aid)
		print("   [到访] %s → 格子剩 %s 行动点剩 %s 心情 %s" % [
			aid, _town.get("_month12_slots_left"), _town.get("_month12_ap_left"), _town.get("_mood")])
		did_any = true
	if not did_any:
		_town.call("_on_end_month_pressed")


## 月末卡真正写出来的那几行字：卡上的文案在引擎里一开卡就被清掉了，
## 所以探针每帧从卡上的 Label 直接读回来。
func _grab_close_card(month: int) -> void:
	if _close_texts.has(str(month)):
		return
	var cp = _town.get("_month12_close_panel")
	if cp == null:
		return
	var card = cp.get("_card")
	if card == null or not (card as Control).visible:
		return
	var lines: Array = []
	for child in (card as Control).get_children():
		if child is Label:
			var txt := String((child as Label).text)
			if txt.length() > 5 and txt != "这个月先到这儿":
				lines.append(txt)
	if lines.is_empty():
		return
	_close_texts[str(month)] = " ／ ".join(PackedStringArray(lines))


func _exit_tree() -> void:
	pass
