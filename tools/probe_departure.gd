extends Node
## 验收尾句：跳到某个月，把整月走完（走位/到访/自由安排/月末都替玩家点掉），
## 每开一屏就报它的末句和三个选项的尾巴——看"按谁谁的安排，去哪儿吧"落在哪。
## 用法：<godot> --path <PROJ> --headless res://tools/probe_departure.tscn -- --month 8
## 状态机抄 probe_year：那一份是逐月跑到过第 12 月的，别再另起一套。

var _month := 8
var _seen := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--month" and i + 1 < args.size():
			_month = int(args[i + 1])
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	town.set("_debug_departure", true)
	await get_tree().create_timer(3.4).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	if bool(panel.call("is_open")):
		panel.call("dismiss")
	town.call("debug_jump_to_month", _month, "A")
	for tick in 4000:
		await get_tree().create_timer(0.04).timeout
		var phase := String(town.get("_month12_phase"))
		var start = town.get("_month12_start_panel")
		if start != null and bool(start.call("is_open")):
			town.call("_on_month_start_continued")
			continue
		if bool(town.get("_hud_tour_active")):
			town.get("_hud_tour").call("advance")
			continue
		var tutorial = town.get("_month_phone_tutorial")
		if tutorial != null and bool(tutorial.get("_card").visible):
			tutorial.call("close_tutorial")
			continue
		var unlock = town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			continue
		# 剧情那一眼（第 2 月图书馆）：走到门口按 E，进屋点那一行。
		var visit_id := String(town.get("_month12_visit_id"))
		if not visit_id.is_empty():
			var door = town.get("_story_door")
			if door != null:
				town.get("_player").position = (door as Node2D).position
			await get_tree().create_timer(0.12).timeout
			town.call("_begin_interaction")
			await get_tree().create_timer(0.25).timeout
			var place: Dictionary = town.call("_month12_visit_place")
			if not place.is_empty():
				town.call("_on_activity_selected", place)
			continue
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = town.get("_month12_waypoint")
			if wp.x > -90000.0:
				town.get("_player").position = wp
			continue
		if bool(panel.call("is_open")):
			_report(panel)
			var event: Dictionary = panel.get("_event")
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				panel.call("_on_choice_picked", String(event.get("id", "")), "A", 45)
			elif stage == "interaction" or stage == "handbook":
				pass
			else:
				panel.call("_advance")
			continue
		if phase == "handbook":
			var book = town.get("_month12_handbook")
			if book != null and bool(book.call("is_open")):
				book.call("close")
			continue
		if phase == "activity":
			await _do_activity(town)
			continue
		if phase == "close":
			town.call("_on_month12_close_finished")
			continue
		if phase == "done":
			break
	print("[尾] 第 %d 月共 %d 屏" % [_month, _seen.size()])
	get_tree().quit()


func _do_activity(town: Node) -> void:
	var runner = town.get("_month_runner")
	var node: Dictionary = runner.current if runner != null else {}
	var ids: Array = node.get("activityIds", []) as Array
	var slots: int = int(town.get("_month12_slots_left"))
	var pending: Array = []
	for value in ids:
		var aid := String(value)
		if bool(town.call("_month12_activity_visited", aid)):
			continue
		pending.append(aid)
	if slots <= 0 or pending.is_empty():
		town.call("_on_end_month_pressed")
		return
	town.call("_on_month12_place_confirmed", String(pending[0]))
	await get_tree().create_timer(0.25).timeout
	var scene = town.get("_weekend_scene_panel")
	if scene != null and bool(scene.call("is_open")):
		scene.call("_advance")


func _report(panel: Node) -> void:
	var ev: Dictionary = panel.get("_event")
	var eid := String(ev.get("id", ""))
	if _seen.has(eid):
		return
	_seen[eid] = true
	var beats: Array = ev.get("beats", [])
	var tail := ""
	if not beats.is_empty():
		tail = String((beats[beats.size() - 1] as Dictionary).get("text", ""))
	var outs: Array = []
	for c in (ev.get("choices", []) as Array):
		var oc := String((c as Dictionary).get("outcome", ""))
		outs.append(oc.substr(maxi(0, oc.length() - 26)))
	print("[尾] %s | 末句=%s | 选项尾=%s" % [eid, tail, str(outs)])
