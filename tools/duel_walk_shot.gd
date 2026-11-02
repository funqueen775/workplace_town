extends Node

## 从镇上真点进这一格，一路拍到收束卡：选搭档 / 对局中 / 胜利那一句 / 收束卡。
## 走的是游戏自己那个入口（_open_month12_duel），所以拍到的挂法就是玩家看到的挂法。
## 用法：<godot> --path . --resolution 1600x900 res://tools/duel_walk_shot.tscn

const OUT_DIR := "res://test_artifacts/duel"

var _town: Node
var _battle: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.0).timeout
	var start: Variant = _town.get("_month12_start_panel")
	if start != null and is_instance_valid(start) and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await get_tree().create_timer(1.0).timeout
	_town.call("debug_jump_to_month", 7)
	await get_tree().create_timer(1.6).timeout
	for i in 20:
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.6).timeout
			break
		await get_tree().create_timer(0.3).timeout
	var places: Array = _town.get("_month12_places")
	var valley: Dictionary = {}
	for value in places:
		if String(Dictionary(value).get("id", "")) == "m7_valley":
			valley = Dictionary(value)
	_town.call("_open_month12_duel", valley)
	await get_tree().create_timer(1.6).timeout
	_battle = _find_duel(_town)
	if _battle == null:
		print("没找到对局页")
		_done = true
		get_tree().quit(1)
		return
	var overlay: CanvasLayer = _town.get("_training_overlay")
	var overlay_layer := -1
	if overlay != null:
		overlay_layer = overlay.layer
	print("搭档=", String(_battle.get("partner_name")), " 覆盖层=", overlay_layer)
	_shot("对局_1_选搭档.png")
	_battle.call("_select_wang")
	await get_tree().create_timer(0.8).timeout
	_battle.call("_advance_dialogue")
	await get_tree().create_timer(0.5).timeout
	_battle.call("_advance_dialogue")
	await get_tree().create_timer(0.9).timeout
	# 第一屏教学（生命规则）点掉，进对局。
	_battle.call("_on_tutorial_next")
	await get_tree().create_timer(1.4).timeout
	_shot("对局_2_对局中.png")
	for key in ["tutorial_panel", "wang_dice_hint", "wang_dice_row", "pool_hint", "pool_row",
		"song_dice_hint", "song_dice_row", "round_label", "phase_label"]:
		var node: Variant = _battle.get(key)
		if node is Control:
			var gr: Rect2 = (node as Control).get_global_rect()
			print("   %-14s 可见=%s 全局=(%.0f,%.0f) %.0fx%.0f 底=%.0f" % [
				key, str((node as Control).visible), gr.position.x, gr.position.y, gr.size.x, gr.size.y, gr.end.y])
	print("--- 这一屏所有可见控件（按 y 排）---")
	var rows: Array = []
	_collect(_battle, rows)
	rows.sort_custom(func(a, b): return int(a[1]) < int(b[1]))
	for row in rows:
		print("   y %4d..%4d  x %4d..%4d  %s" % [int(row[1]), int(row[3]), int(row[2]), int(row[4]), row[0]])
	# 再点一下"看小赵出手"：骰子是在这一步才滚出来的，
	# 上一张停在教学还没点掉那一拍，所以搭档那格是空的。
	_battle.call("_on_tutorial_next")
	await get_tree().create_timer(2.6).timeout
	_shot("对局_2b_骰子滚出来了.png")
	_battle.call("_finish_victory")
	await get_tree().create_timer(1.0).timeout
	_shot("对局_3_胜利.png")
	_battle.call("_advance_dialogue")
	await get_tree().create_timer(0.5).timeout
	_battle.call("_advance_dialogue")
	await get_tree().create_timer(0.5).timeout
	_battle.call("_advance_dialogue")
	await get_tree().create_timer(1.0).timeout
	_shot("对局_4_收束卡.png")
	# 点"返回小镇"（那颗按钮就是发这个信号），确认那一格真的结掉了。
	var slots_before := int(_town.get("_month12_slots_left"))
	_battle.emit_signal("training_completed")
	await get_tree().create_timer(1.6).timeout
	print("格子 ", slots_before, " → ", int(_town.get("_month12_slots_left")),
		" 覆盖层已收=", _town.get("_training_overlay") == null)
	print("DUEL_WALK_DONE")
	_done = true
	get_tree().quit(0)


func _find_duel(node: Node) -> Node:
	for child in node.get_children():
		if child.get("script") != null and String(child.name) == "SongfengTrainingValley":
			return child
		var found := _find_duel(child)
		if found != null:
			return found
	return null


func _collect(node: Node, rows: Array) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			if c.visible and c.get_global_rect().size.x > 1.0:
				var gr := c.get_global_rect()
				rows.append([String(c.name), gr.position.y, gr.position.x, gr.end.y, gr.end.x])
			_collect(child, rows)


func _shot(file_name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OUT_DIR + "/" + file_name)


func _watchdog() -> void:
	await get_tree().create_timer(240.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
