extends Node

## 结局探针：跳进第七月，按三条路线各跑一次判定，打出"这一路会播哪些屏 + 判定写了什么"。
## 只验本次改的东西：红线优先、举证门、两态、短收束那一屏、占位展开。
## 用法：godot --headless --path . res://tools/ending_probe.tscn

const MAIN_SCENE := preload("res://Main.tscn")


func _ready() -> void:
	for letter in ["A", "C", "P", "R"]:
		var town: Node = MAIN_SCENE.instantiate()
		add_child(town)
		await get_tree().process_frame
		town.call("debug_jump_to_month", 7, letter)
		var flags: Dictionary = town.get("_month12_flags")
		print("== 第七月·路线 ", letter,
			" 结论=", String(flags.get("m06_probation_status", "?")),
			" 红线=", String(flags.get("m06_redline_flag", "")),
			" 弱维=", _weak_list(flags),
			" 主线结束=", bool(flags.get("probation_ended", false)))
		print("   会播的屏：", ", ".join(_planned(town, flags)))
		var text := _closure_text(town, flags)
		if not text.is_empty():
			print("   短收束台词：", text)
		town.queue_free()
		await get_tree().process_frame
	# 第十二月：提名与没提名都要判一次晋升
	for letter in ["A", "C"]:
		var town2: Node = MAIN_SCENE.instantiate()
		add_child(town2)
		await get_tree().process_frame
		town2.call("debug_jump_to_month", 12, letter)
		var fl: Dictionary = town2.get("_month12_flags")
		# 模拟走到"结果/面谈"那一屏前：判一次
		town2.call("_evaluate_promotion")
		print("== 第十二月·路线 ", letter,
			" 未提名=", bool(fl.get("m12_not_nominated", false)),
			" 晋升结论=", String(fl.get("m12_promotion_status", "?")),
			" 缺=", String(fl.get("m12_promotion_reason", "")),
			" 这次没晋升=", bool(fl.get("m12_not_passed", false)))
		print("   会播的屏：", ", ".join(_planned(town2, fl, 12)))
		town2.queue_free()
		await get_tree().process_frame
	# 面板：四条路线都要点得动，且越线那条跳第八月会被收回第七月
	var panel_town: Node = MAIN_SCENE.instantiate()
	add_child(panel_town)
	await get_tree().process_frame
	panel_town.call("_toggle_jump_panel")
	var found: Array = []
	for entry in ["A", "C", "P", "R"]:
		var button: Node = panel_town.call("find_child", "JumpRoute" + entry, true, false)
		found.append("%s=%s" % [entry, "有" if button != null else "缺"])
	print("== 跳月面板路线按钮：", ", ".join(found))
	for entry in ["C", "P", "R"]:
		panel_town.set("_jump_path", entry)
		panel_town.call("debug_jump_to_month", 8, entry)
		var pf: Dictionary = panel_town.get("_month12_flags")
		print("   ", entry, " 跳第八月 → 实际月份=", int(panel_town.get("_month12_month")),
			" 结论=", String(pf.get("m06_probation_status", "?")))
	panel_town.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _weak_list(flags: Dictionary) -> String:
	var out: Array = []
	for dim in ["S", "O", "N", "D"]:
		if bool(flags.get("probation_weak_" + dim, false)):
			out.append(dim)
	return "/".join(out) if not out.is_empty() else "无"


func _planned(town: Node, flags: Dictionary, month_value := 7) -> Array:
	var ids: Array = []
	for node in town.call("_load_month_nodes", month_value):
		var when = node.get("when")
		var ok := true
		if when is Dictionary:
			var flag := String((when as Dictionary).get("flag", ""))
			var not_flag := String((when as Dictionary).get("notFlag", ""))
			if not flag.is_empty():
				ok = bool(flags.get(flag, false))
			elif not not_flag.is_empty():
				ok = not bool(flags.get(not_flag, false))
		if ok:
			ids.append(String(node.get("id", "")))
	return ids


## 把短收束那一屏按当前账本展开，看占位有没有换成真条文。
func _closure_text(town: Node, _flags: Dictionary) -> String:
	for node in town.call("_load_month_nodes", 7):
		if String(node.get("id", "")) != "M07_CLOSURE":
			continue
		var data: Dictionary = town.call("_runner_story_data", node)
		for beat in (data.get("beats", []) as Array):
			var text := String((beat as Dictionary).get("text", ""))
			if text.contains("条文") or text.contains("差的那一栏"):
				return text
	return ""
