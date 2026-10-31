extends Node

## 第 11 月那批「必须先读」的消息：不走完整月流程，直接把节点喂给同一条投递口，
## 看它是否也钉出横幅（第 3 月已经验过，这里要证明不是只给那一个月写的）。
## 用法：<godot> --path <proj> res://tools/gate11_probe.tscn

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	_town.call("debug_jump_to_month", 11, "A")
	await _wait(2.4)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await _wait(1.4)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	var nodes: Array = (raw as Dictionary).get("nodes", []) if raw is Dictionary else []
	var target: Dictionary = {}
	for value in nodes:
		if String(Dictionary(value).get("id", "")) == "M11_PHONE_CG":
			target = Dictionary(value)
			break
	if target.is_empty():
		print("GATE11 找不到 M11_PHONE_CG")
		get_tree().quit(1)
		return
	var gated := bool(_town.call("runner_deliver_phone", target))
	await _wait(0.8)
	var banner = _town.get("_gate_banner")
	var ui = _town.get("_town_ui_v2")
	print("GATE11 算前置=%s 横幅=%s 任务卡=%s / %s 门槛=%s" % [
		gated, "在" if (banner != null and is_instance_valid(banner)) else "无",
		String(ui.get("_task_title").text), String(ui.get("_task_note").text),
		bool(_town.get("_phone_gate_waiting")),
	])
	print("GATE11_DONE")
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
