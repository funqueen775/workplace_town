extends Node

## 首月从头跑到月末探针：把 E01 → HUD 引导 → 带巡 → 手册 → E02 → 自由安排 一路推到底，
## 然后按真的"结束这个月"，看月末卡有没有开、关掉之后回宿舍那一段有没有起来。

var _town: Node
var _last_phase := ""
var _log := []


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.6).timeout
	for i in 2400:
		var start_panel = _town.get("_month12_start_panel")
		if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
			start_panel.emit_signal("continued")
			await get_tree().create_timer(0.8).timeout
			continue
		await get_tree().create_timer(0.05).timeout
		var phase := String(_town.get("_month12_phase"))
		if phase != _last_phase:
			_last_phase = phase
			print("相位 → ", phase, "  节点=", _node_id(), "  玩家=", (_town.get("_player") as Node2D).position)
			_log.append(phase)
		if phase == "activity":
			var button = _town.get("_end_month_button")
			if button != null and is_instance_valid(button) and bool(button.visible):
				print("按「结束这个月」")
				button.emit_signal("pressed")
			elif i % 40 == 0:
				print("  activity 相位，按钮可见吗：", button != null and bool(button.visible))
			continue
		if phase == "close":
			var close_panel = _town.get("_month12_close_panel")
			if close_panel != null and is_instance_valid(close_panel):
				var root: Control = close_panel.get("_root")
				if root != null and root.visible:
					print("月末卡露脸了，关掉它")
					close_panel.call("close")
					_town.call("_on_month12_close_finished")
			else:
				print("月末卡对象都没有")
			continue
		if phase == "sleep_walk":
			print("回宿舍这一段起来了：落点 ", _town.get("_month12_waypoint"))
			break
		var tour = _town.get("_hud_tour")
		if tour != null and is_instance_valid(tour) and bool(tour.call("is_active")):
			tour.call("finish")
			continue
		var panel = _town.get("_story_event_panel")
		if panel != null and bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				panel.call("_on_choice_picked", _node_id(), "A", 45)
			else:
				panel.call("_advance")
			continue
		var waypoint: Vector2 = _town.get("_month12_waypoint")
		if waypoint.x > -90000.0:
			(_town.get("_player") as Node2D).position = waypoint
			continue
	print("跑完：日志=", ", ".join(_log))
	print("MONTH1_END_DONE")
	get_tree().quit(0)


func _node_id() -> String:
	var runner = _town.get("_month_runner")
	if runner == null or not is_instance_valid(runner):
		return "-"
	return String((runner.get("current") as Dictionary).get("id", ""))
