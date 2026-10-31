extends Node

## 能力涨了的说法：跨一档 = "真的长进了一块"，没跨档 = "长了一点，还没到换一档"。
## 只验措辞，不报数。用法：<godot> --headless --path . res://tools/ability_gain_probe.tscn

var _town: Node
var _done := false


func _ready() -> void:
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.0).timeout

	# A：只攒 1 点，够不到换档（阈值是 2/5/9）。
	_town.set("_ability_points", {})
	await _case({"expression": 1}, 0, "A 攒 1 点（不换档）")

	# B：先攒到 1 点，再 +1 → 到 2 点，跨进第一档。
	_town.set("_ability_points", {"expression": 1})
	await _case({"expression": 1}, 0, "B 攒到 2 点（跨一档）")

	# C：这一选没给能力点 → 不该冒出这句话。
	_town.set("_ability_points", {})
	await _case({}, 0, "C 没给能力点")

	# D：一维跨档（技术 1→3）、一维只攒到 1 点不换（表达 0→1）。
	_town.set("_ability_points", {"technical": 1})
	await _case({"technical": 2, "expression": 1}, 0, "D 一跨一不跨")

	# E：一次两维都跨档。
	_town.set("_ability_points", {"technical": 1, "expression": 1})
	await _case({"technical": 2, "expression": 2}, 0, "E 两维都跨档")

	# F：只熬心情，什么都没长。
	_town.set("_ability_points", {})
	await _case({}, -1, "F 只熬心情")

	# G：既长了本事，也熬了人。
	_town.set("_ability_points", {"expression": 1})
	await _case({"expression": 1}, -1, "G 有得有失")

	print("ABILITY_PROBE_DONE")
	_done = true
	get_tree().quit(0)


func _watchdog() -> void:
	await get_tree().create_timer(60.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _case(tags: Dictionary, mood_delta: int, label: String) -> void:
	var stale = _town.get("_toast_panel")
	var stale_id := int(stale.get_instance_id()) if stale != null and is_instance_valid(stale) else 0
	var before: Array = _town.call("ability_display_levels")
	_town.call("_record_ability_tags", tags)
	_town.call("_announce_choice_aftermath", before, tags, mood_delta)
	await get_tree().create_timer(0.25).timeout
	var panel = _town.get("_toast_panel")
	if panel == null or not is_instance_valid(panel) or int(panel.get_instance_id()) == stale_id:
		print("[ab] %-22s → 没弹新提示（对：这一选没给能力点）" % label)
		return
	print("[ab] %-22s → %s" % [label, _toast_text()])


func _toast_text() -> String:
	var panel = _town.get("_toast_panel")
	if panel == null or not is_instance_valid(panel):
		return "（没有提示）"
	var parts: Array = []
	for child in panel.get_children():
		_collect(child, parts)
	var joined := " / ".join(parts)
	return joined if not joined.is_empty() else "（提示是空的）"


func _collect(node: Node, parts: Array) -> void:
	if node is Label and not String((node as Label).text).is_empty():
		parts.append(String((node as Label).text))
	for child in node.get_children():
		_collect(child, parts)
