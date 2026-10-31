extends Node

## 一整年走到黑：不截图，替玩家把 12 个月点完，逐月报"过了几屏、卡在哪"。
## 用法：<godot> --path <PROJ> --headless res://tools/probe_year.tscn
## 目的只有一个——找出流程上真正会卡住玩家的洞，不是来看画面的。

var _town: Node
var _panel
var _screens := {}
var _stall_ticks := 0
var _last_sig := ""
var _greedy := false


func _ready() -> void:
	for _arg in OS.get_cmdline_user_args():
		if _arg == "--greedy":
			_greedy = true  # 自由安排专挑耗心情的去处：验这条账的上限
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.5).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	var month_seen := {}
	for tick in 6000:
		await get_tree().create_timer(0.04).timeout
		var month := int(_town.get("_month12_month"))
		var phase := String(_town.get("_month12_phase"))
		if not month_seen.has(month):
			month_seen[month] = true
			if month > 1:
				print("[年] 第 ", month - 1, " 月共 ", int(_month_screens.get(month - 1, 0)), " 屏")
			print("[年] ---- 进入第 ", month, " 月 · 心情=", _town.get("_mood"), "/", _town.get("_mood_max"), " ----")
		# 从 11 月翻进来时 phase 还停在上月末的 done；要等 12 月真开演过才算走完。
		if month >= 12 and phase != "done":
			_m12_started = true
		# 月中那一觉也会把 phase 短暂设成 done（黑场里翻日）；要连续 done 够久才算真收工。
		if month >= 12 and phase == "done" and _m12_started:
			_m12_done_ticks += 1
		else:
			_m12_done_ticks = 0
		if _m12_done_ticks > 200:
			var r = _town.get("_month_runner")
			print("[年] 第 12 月走完 · runner index=", r.get("index"), "/", (r.get("nodes") as Array).size(),
				" active=", r.get("active"), " current=", String((r.get("current") as Dictionary).get("id", "")))
			break
		# 延期转正的人在第七月交接完就收尾：这也是一种正常结束。
		if phase == "done" and month == 7 and bool((_town.get("_month12_flags") as Dictionary).get("m07_probation_deferred", false)):
			print("[年] 第 7 月交接完，在岗主线提前结束")
			break
		var ev_now: Dictionary = _panel.get("_event")
		var sig := "%d|%s|%s|%s" % [month, phase, str(ev_now.get("id", "")), str(_panel.get("_beat_index"))]
		if sig == _last_sig:
			_stall_ticks += 1
		else:
			_stall_ticks = 0
			_last_sig = sig
		# 月末卡收尾那几秒也是在 done 上等（本局的结束态），不算卡住。
		var runner_now = _town.get("_month_runner")
		var closing_now := runner_now != null and String((runner_now.get("current") as Dictionary).get("id", "")) == "M12_CLOSE"
		if closing_now:
			_stall_ticks = 0
		if _stall_ticks > 150:
			var stuck_ev: Dictionary = _panel.get("_event")
			var run = _town.get("_month_runner")
			var cur: Dictionary = run.current if run != null else {}
			print("[年] 卡住：月=", month, " phase=", phase, " 面板=", bool(_panel.call("is_open")),
				" 屏=", str(stuck_ev.get("id", "")), " 结束钮=", _end_month_visible(),
				" 格子=", _town.get("_month12_slots_left"), " 门=", (_town.get("_month12_place_portals") as Dictionary).size(),
				" 当前节点=", String(cur.get("id", "")), " 等走位=", str(run.get("waiting_walk")) if run != null else "?",
				" 黄线终点=", _town.get("_month12_waypoint"), " 玩家=", _town.get("_player").position,
					" 这一眼=", String(_town.get("_month12_visit_id")),
					" 室内=", (_town.get("_interior_preview") != null and _town.get("_interior_preview").call("is_open")),
					" 手机=", (_town.get("_month_phone_panel") != null and _town.get("_month_phone_panel").call("is_open")),
					" 手册=", (_town.get("_month12_handbook") != null and _town.get("_month12_handbook").call("is_open")),
					" 导览开关=", str(_town.get("_hud_tour_active")),
					" 导览完成=", str(_town.get("_hud_tour_done")),
					" 导览重试=", str(_town.get("_hud_tour_retries")),
					" 导览在演=", (_town.get("_hud_tour") != null and bool(_town.get("_hud_tour").call("is_active"))),
					" 导览步=", "%d/%d" % [int(_town.get("_hud_tour").get("_index")), (_town.get("_hud_tour").get("_steps") as Array).size()] if _town.get("_hud_tour") != null else "?",
					" 岗位可见=", _hud_visible("_job_label"),
					" 任务卡可见=", _hud_visible("_task_panel"))
			_stall_ticks = 0
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
		# 首月带巡会把手机塞进手里：收件箱开着的时候走位是暂停的，探针得自己关掉。
		# 前置手机（requireRead）：只有点右下角那颗才会记"读过了"，
		# 直接 poke 面板不解锁流程——探针必须走玩家那条路。
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
		# HUD 的第一次使用卡（另一条线新加的）：走"打开/知道了"这个主按钮。
		# 注意别按"以后再说"——那条只弹一句提示，不会把流程接回去；
		# 第 2 月末那张「心情」卡只有主按钮一条路。
		var hud_card = _town.get("_hud_button_tutorial")
		if hud_card != null and bool(hud_card.call("is_open")):
			hud_card.call("_on_open_pressed")
			continue
		# 月末第一次发档案卡时，主按钮会把档案页真打开；不替玩家关掉，
		# 后面回宿舍那一步就一直等着（2026-10-31 探针卡在首月末的真实原因）。
		var archive_ui = _town.get("_town_ui_v2")
		if archive_ui != null and bool(archive_ui.call("is_open")):
			archive_ui.call("close_view")
			await get_tree().create_timer(0.2).timeout
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			await get_tree().create_timer(0.2).timeout
			continue
		# 剧情那一眼（第 2 月图书馆）：走到门口按 E，进屋点那一行
		var visit_id := String(_town.get("_month12_visit_id"))
		if not visit_id.is_empty():
			var door = _town.get("_story_door")
			if door != null:
				_town.get("_player").position = (door as Node2D).position
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
			if not _screens.has(eid):
				_screens[eid] = true
				_month_screen(month, eid)
				print("[屏] M%d %s %s" % [month, eid, str(event.get("title", ""))])
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
	print("[年] 结束：phase=", _town.get("_month12_phase"), " 月=", _town.get("_month12_month"),
		" 走过屏=", _screens.size(), " 心情=", _town.get("_mood"))
	get_tree().quit()


var _month_screens := {}
var _m12_started := false
var _m12_done_ticks := 0


func _month_screen(month: int, eid: String) -> void:
	_month_screens[month] = int(_month_screens.get(month, 0)) + 1


func _hud_visible(var_name: String) -> bool:
	var ui = _town.get("_town_ui_v2")
	if ui == null:
		return false
	var control = ui.get(var_name)
	return control is Control and (control as Control).is_visible_in_tree()


func _end_month_visible() -> bool:
	var b = _town.get("_end_month_button")
	return b != null and bool((b as Control).visible)


## 通用月份：把这个月列出的去处一处一处做完；没有可去的就点"结束这个月"。
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
	if _greedy and pending.size() > 1:
		var scored: Array = []
		for aid in pending:
			var place: Dictionary = _town.call("_month12_place_by_id", String(aid))
			scored.append([maxi(0, int(place.get("hCost", 0))), String(aid)])
		scored.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
		pending = scored.map(func(x): return x[1])
	_town.call("_on_month12_place_confirmed", String(pending[0]))
	await get_tree().create_timer(0.25).timeout
	var scene = _town.get("_weekend_scene_panel")
	if scene != null and bool(scene.call("is_open")):
		scene.call("_advance")


func _exit_tree() -> void:
	pass
