extends Node

## 哪些月份会等"先看手机"：跳进去看门槛状态、顶上有没有钉住横幅、任务卡写什么。
## 用法：<godot> --path <proj> res://tools/gate_months_probe.tscn

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	for month in [3, 11]:
		_town.call("debug_jump_to_month", month, "A")
		await _wait(2.4)
		var start_panel = _town.get("_month12_start_panel")
		if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
			start_panel.emit_signal("continued")
			await _wait(1.4)
		var banner = _town.get("_gate_banner")
		var ui = _town.get("_town_ui_v2")
		print("MONTH %d 门槛=%s 横幅=%s 任务卡=%s / %s 节点=%s" % [
			month, bool(_town.get("_phone_gate_waiting")),
			"在" if (banner != null and is_instance_valid(banner)) else "无",
			String(ui.get("_task_title").text), String(ui.get("_task_note").text), _node_id(),
		])
	print("GATE_MONTHS_DONE")
	get_tree().quit(0)


func _node_id() -> String:
	var runner = _town.get("_month_runner")
	if runner == null or not is_instance_valid(runner):
		return "-"
	return String((runner.get("current") as Dictionary).get("id", ""))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
