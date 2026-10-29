extends Node

## 第 3 月手机前置探针：跳进第 3 月，看它是不是停在"先看手机"，
## 看完收件箱（开→关）之后才继续去工位、再去展厅。

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.6).timeout
	_town.call("debug_jump_to_month", 3, "A")
	await get_tree().create_timer(2.4).timeout
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await get_tree().create_timer(1.2).timeout
	print("门槛等着吗：", bool(_town.get("_phone_gate_waiting")),
		" 任务卡：", String(_town.get("_town_ui_v2").get("_task_title").text),
		" / ", String(_town.get("_town_ui_v2").get("_task_note").text))
	print("现在节点：", _node_id(), "（应该是手机那批，不该已经到 M03_OPEN）")
	# 玩家点开手机
	_town.call("_open_ui_phone")
	await get_tree().create_timer(1.0).timeout
	print("点开之后算读到了吗：", bool(_town.get("_phone_gate_read")))
	var panel = _town.get("_month_phone_panel")
	if panel != null and is_instance_valid(panel):
		panel.emit_signal("phone_closed")
	await get_tree().create_timer(2.0).timeout
	print("关掉收件箱后：门槛=", bool(_town.get("_phone_gate_waiting")),
		" 现在节点=", _node_id(), " 相位=", String(_town.get("_month12_phase")))
	print("PHONE_GATE_DONE")
	get_tree().quit(0)


func _node_id() -> String:
	var runner = _town.get("_month_runner")
	if runner == null or not is_instance_valid(runner):
		return "-"
	return String((runner.get("current") as Dictionary).get("id", ""))
