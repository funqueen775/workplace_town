extends Node

## 把每个月里"三选一"的屏走一遍，记下选完之后屏幕上那句话到底是什么。
## 用法：<godot> --path . --headless res://tools/choice_audit_probe.tscn -- --no-resume --months 1,2,3

var _town: Node
var _panel: Node
var _done := false
var _months: Array = [1, 2, 3]
var _rows: Array = []
var _fallback := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--months" and i + 1 < args.size():
			_months = String(args[i + 1]).split(",", false)
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	for raw in _months:
		await _run_month(int(String(raw)))

	print("---- 三选一选完之后 ----")
	for row in _rows:
		print("  ", row)
	print("共 %d 次三选一，掉进兜底 %d 次" % [_rows.size(), _fallback])
	print("CHOICE_AUDIT_DONE")
	_done = true
	get_tree().quit(0)


func _run_month(month: int) -> void:
	_town.call("debug_jump_to_month", month, "A")
	await _wait(2.2)
	var start = _town.get("_month12_start_panel")
	if start != null and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await _wait(1.0)
	var picked := 0
	for i in 1400:
		await _wait(0.05)
		if int(_town.get("_month12_month")) != month:
			return
		var phase := String(_town.get("_month12_phase"))
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var stage := String(_panel.call("current_stage"))
			if stage == "choices":
				picked += 1
				var ev: Dictionary = _panel.get("_event")
				var first := String(((ev.get("choices", []) as Array)[0] as Dictionary).get("id", "A"))
				var text := String(_panel.call("_outcome_text", first))
				var hit := text == "你的选择被记录下来了。" or text.strip_edges().is_empty()
				if hit:
					_fallback += 1
				_rows.append("%-14s 选%s → %s %s" % [
					String(ev.get("id", "")), first, "【兜底】" if hit else "", _clip(text)])
				_panel.call("_on_choice_picked", String(ev.get("id", "")), first, 45)
				await _wait(0.3)
				continue
			if stage == "outcome":
				_panel.call("_advance")
				await _wait(0.2)
				continue
			if stage != "interaction" and stage != "handbook":
				_panel.call("_advance")
			continue
		if picked > 0 and phase == "activity":
			return


func _clip(t: String) -> String:
	var s := t.replace("\n", " ")
	return s if s.length() <= 30 else s.substr(0, 30) + "…"


func _watchdog() -> void:
	await get_tree().create_timer(240.0).timeout
	if _done:
		return
	print("---- 超时收尾 ----")
	for row in _rows:
		print("  ", row)
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
