extends Node

## 第 12 月答辩那一串：连着问的屏还在不在每问一次就重新开场一次。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/defense_flow_probe.tscn

var _dir := "E:/03_Projects/bear/workplace_town/test_artifacts/defense_flow"
var _town: Node
var _panel: Node
var _done := false
var _last_id := ""
var _rows: Array = []
## 已经记过、并且已经不再播入场卡的屏。
var _seen: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	_town.call("debug_jump_to_month", 12, "A")
	await _wait(2.2)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		_town.call("_on_month_start_continued")
		await _wait(1.0)

	var started := false
	var done_ticks := 0
	for i in 4000:
		await _wait(0.05)
		_watch_screen()
		var now_phase := String(_town.get("_month12_phase"))
		# 从 11 月翻进来时 phase 还停在上月末的 done；要等 12 月真开演过才算数。
		if int(_town.get("_month12_month")) >= 12 and now_phase != "done":
			started = true
		# 月中那一觉也会把 phase 短暂设成 done（黑场里翻日）；连续 done 够久才算收工。
		if started and int(_town.get("_month12_month")) >= 12 and now_phase == "done":
			done_ticks += 1
		else:
			done_ticks = 0
		if done_ticks > 200:
			_note("第 12 月跑完")
			break
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			continue
		var phase := String(_town.get("_month12_phase"))
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var stage := String(_panel.call("current_stage"))
			if stage == "choices":
				var ev: Dictionary = _panel.get("_event")
				var options: Array = ev.get("choices", [])
				var pick := String((options[0] as Dictionary).get("id", "A")) if not options.is_empty() else "A"
				_panel.call("_on_choice_picked", String(ev.get("id", "")), pick, 45)
			elif stage != "interaction" and stage != "handbook":
				_panel.call("_advance")
			continue
		if phase == "activity":
			_town.call("_on_end_month_pressed")
			continue
		if phase == "close":
			_town.call("_on_month12_close_finished")
			continue

	print("---- 答辩开场核对 ----")
	for row in _rows:
		print("  ", row)
	print("PROBE_DONE ", _dir)
	_done = true
	get_tree().quit(0)


## 每换一屏记一行：这屏有没有播入场卡、人有没有被要求重新走。
## 入场卡要播就是 2 秒多，这里 50 毫秒采一次，不会正好错过。
func _watch_screen() -> void:
	var ev: Dictionary = _panel.get("_event")
	var id := String(ev.get("id", ""))
	if id.is_empty() or _seen.has(id):
		return
	_seen.append(id)
	_last_id = id
	var card = _panel.get("_entry_card")
	var entry_now := card != null and is_instance_valid(card)
	var walked := String(_town.get("_month12_phase")) == "node_walk"
	_note("%-22s 入场卡=%-5s 走位中=%-5s 地点=%s" % [
		id, str(entry_now), str(walked), String(ev.get("location", ""))])
	if entry_now:
		_shot_later(id)


func _shot_later(id: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _dir + "/" + id + ".png"
	image.save_png(path)
	print("[shot] ", path)


func _note(text: String) -> void:
	_rows.append(text)
	print("[def] ", text)


func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	if _done:
		return
	print("---- 答辩开场核对（超时收尾）----")
	for row in _rows:
		print("  ", row)
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
