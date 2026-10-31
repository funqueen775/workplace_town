extends Node

## 夜里的那几屏到底扣没扣心情：进屏前后各读一次。
## 用法：<godot> --path . --headless res://tools/mood_night_probe.tscn -- --no-resume --month 2

var _town: Node
var _panel: Node
var _done := false
var _month := 2
var _rows: Array = []
var _seen := []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--month" and i + 1 < args.size():
			_month = int(args[i + 1])
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	print("[mood] 开局心情=", _town.get("_mood"), "/", _town.get("_mood_max"))
	if int(_town.get("_month12_month")) != _month:
		_town.call("debug_jump_to_month", _month, "A")
	# 等月首卡真的弹出来再点，不然这一下会扑空，整局就停在 month_start。
	var start = _town.get("_month12_start_panel")
	for i in 80:
		await _wait(0.1)
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			break
	if start != null and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await _wait(1.0)
	print("[mood] 月首卡之后 phase=", _town.get("_month12_phase"))
	print("[mood] 进入第", _month, "月后心情=", _town.get("_mood"))

	for i in 1600:
		await _wait(0.05)
		if bool(_panel.call("is_open")):
			var ev: Dictionary = _panel.get("_event")
			var nid := String(ev.get("id", "")).replace("M12_", "")
			if not _seen.has(nid):
				_seen.append(nid)
				var band := String(ev.get("timeBand", ""))
				print("[mood] 进屏 ", nid, " band=", band, " 心情=", _town.get("_mood"))
				if band == "night":
					_rows.append("%-18s 夜里  当前心情=%s" % [nid, _town.get("_mood")])
			var stage := String(_panel.call("current_stage"))
			if stage == "choices":
				_panel.call("_on_choice_picked", String(ev.get("id", "")), "A", 45)
			elif stage != "interaction" and stage != "handbook":
				_panel.call("_advance")
			continue
		var phase := String(_town.get("_month12_phase"))
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if phase in ["activity", "close"]:
			break

	print("---- 夜里那几屏的心情 ----")
	for r in _rows:
		print("  ", r)
	print("[mood] 收尾心情=", _town.get("_mood"), "/", _town.get("_mood_max"))
	print("MOOD_PROBE_DONE")
	_done = true
	get_tree().quit(0)


func _watchdog() -> void:
	await get_tree().create_timer(120.0).timeout
	if _done:
		return
	print("---- 超时 ----")
	for r in _rows:
		print("  ", r)
	print("[mood] 收尾心情=", _town.get("_mood"))
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
