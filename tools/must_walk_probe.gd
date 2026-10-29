extends Node

## 硬规则核对：跳月进去之后，剧情必须等玩家走到地点才开——不瞬移、不自动弹面板。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/must_walk_probe.tscn -- --months 5,8

var _dir := "E:/03_Projects/bear/workplace_town/test_artifacts/must_walk"
var _months: Array = [5, 8]
var _done := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
		elif args[i] == "--months" and i + 1 < args.size():
			_months = String(args[i + 1]).split(",", false)
	DirAccess.make_dir_recursive_absolute(_dir)
	_watchdog()
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await _wait(3.0)
	for raw in _months:
		await _check_month(town, int(String(raw)))
	print("PROBE_DONE ", _dir)
	_done = true
	get_tree().quit(0)


func _check_month(town: Node, month: int) -> void:
	town.call("debug_jump_to_month", month, "A")
	await _wait(1.6)
	_report(town, month, "月首卡")
	# 玩家点「开始这一天」——这是月首卡上唯一的按钮。
	town.call("_on_month_start_continued")
	await _wait(1.6)
	_report(town, month, "点了开始这一天")
	await _wait(5.0)
	_report(town, month, "等了 5 秒后")
	# 探针直接把人搬到目标点，模拟"走到了"。
	var wp: Vector2 = town.get("_month12_waypoint")
	if wp.x > -90000.0:
		town.get("_player").position = wp
	await _wait(1.6)
	_report(town, month, "走到点上之后")
	await _shot(town, "m%d_走到后" % month)


func _report(town: Node, month: int, label: String) -> void:
	var panel = town.get("_story_event_panel")
	var runner = town.get("_month_runner")
	var start_panel = town.get("_month12_start_panel")
	var node: Dictionary = runner.get("current") if runner != null else {}
	print("M%d %s｜phase=%s 节点=%s 等走=%s 剧情面板=%s 月首卡=%s 黄线目标=%s 人在%s 可点直开=%s" % [
		month, label,
		String(town.get("_month12_phase")),
		String(node.get("id", node.get("eventId", "-"))),
		bool(runner.get("waiting_walk")) if runner != null else "?",
		bool(panel.call("is_open")),
		bool(start_panel.call("is_open")) if start_panel != null and start_panel.has_method("is_open") else "无",
		town.get("_month12_waypoint"),
		(town.get("_player") as Node2D).position,
		_direct_start_buttons(town)])


## 屏幕上有没有"直接开始 / 立即前往"这类绕过走位的按钮。
func _direct_start_buttons(town: Node) -> int:
	var hits := 0
	var stack: Array = [town]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
			var button := child as Button
			if button != null and button.visible:
				var text := String(button.text)
				if text.contains("直接") or text.contains("立即") or text.contains("瞬"):
					hits += 1
	return hits


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(town: Node, name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _dir + "/" + name + ".png"
	image.save_png(path)
	print("SHOT ", path)
