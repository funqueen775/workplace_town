extends Node

## 十二个月里"松风训练谷"这一格真的能打到熊熊有招吗：
## 进门 → 确认 → 对局挂起来 → 点"返回小镇" → 格子扣了、结果页播了。
## 用法：<godot> --path . --resolution 1600x900 res://tools/duel_entry_probe.tscn -- --no-resume

const OUT_DIR := "res://test_artifacts/duel"

var _town: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.0).timeout
	_town.call("debug_jump_to_month", 7)
	await get_tree().create_timer(1.6).timeout
	var start = _town.get("_month12_start_panel")
	if start != null and is_instance_valid(start) and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await get_tree().create_timer(1.0).timeout
	var unlocked: Dictionary = _town.get("_month12_unlocked_places")
	unlocked["m7_valley"] = true
	# 第 7 月的自由安排窗口本来要走到那一拍才开；探针直接摆成"窗口已开"的样子，
	# 不然格子是 0，结算会当成再访，测不到这一格有没有真的花掉。
	_town.set("_month12_activity_generic", true)
	_town.set("_month12_phase", "activity")
	_town.set("_month12_slots_total", 3)
	_town.set("_month12_slots_left", 3)
	var slots_before := int(_town.get("_month12_slots_left"))
	var month := int(_town.get("_month12_month"))
	print("[对局入口] 第", month, "月 开局还剩格子=", slots_before)
	_town.call("_on_month12_place_confirmed", "m7_valley")
	await get_tree().create_timer(1.6).timeout
	var overlay = _town.get("_training_overlay")
	print("[对局入口] 确认后对局挂起来=", overlay != null)
	if overlay == null:
		print("FAIL 没挂起对局")
		_finish(1)
		return
	await _shot("入口_对局")
	var battle = _find_battle(overlay)
	if battle == null:
		print("FAIL 覆盖层里找不到对局场景")
		_finish(1)
		return
	print("[对局入口] skip_intro=", battle.get("skip_intro"),
		" 输了能走=", battle.get("allow_leave_on_defeat"))
	battle.emit_signal("training_completed")
	await get_tree().create_timer(1.2).timeout
	var slots_after := int(_town.get("_month12_slots_left"))
	var overlay_after = _town.get("_training_overlay")
	var ledger: Array = _town.get("_month_ledger")
	print("[对局入口] 打完覆盖层收掉=", overlay_after == null,
		" 格子 ", slots_before, "->", slots_after)
	print("[对局入口] 这一月记了 ", ledger.size(), " 笔：", _last_ledger(ledger))
	await _shot("入口_打完")
	if overlay_after != null or slots_after >= slots_before:
		print("FAIL 打完没结这一格")
		_finish(1)
		return
	print("DUEL_ENTRY_PROBE_DONE")
	_finish(0)


func _last_ledger(ledger: Array) -> String:
	if ledger.is_empty():
		return "（空）"
	return JSON.stringify(ledger[ledger.size() - 1])


func _find_battle(node: Node) -> Control:
	for child in node.get_children():
		if child is Control and child.has_signal("training_completed"):
			return child as Control
		var deeper := _find_battle(child)
		if deeper != null:
			return deeper
	return null


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + name + ".png"))


func _finish(code: int) -> void:
	_done = true
	get_tree().quit(code)


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
