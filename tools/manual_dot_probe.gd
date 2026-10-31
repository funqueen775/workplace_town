extends Node
## 手册红点：该亮的时候亮、翻开就灭。
## 用法：<godot> --headless --path <PROJ> --quit-after 3000 res://tools/manual_dot_probe.tscn
## 期望输出：DOT_AFTER_UNLOCK=true / DOT_AFTER_OPEN=false / FAIL=0

var _fail := 0


func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	await _run()
	get_tree().quit()


func _dot(town: Node) -> bool:
	var ui = town.get("_town_ui_v2")
	if ui == null:
		return false
	var dot = ui.get("_manual_dot")
	return dot != null and bool((dot as Control).visible)


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.0).timeout
	var panel = town.get("_story_event_panel")
	if panel != null:
		panel.reduced_motion = true
		panel.visible = false
	print("[probe] 起始 红点=", _dot(town))

	# 直接喂第 3 月那个 silent 手册节点：会前给第二章，只亮红点。
	town.call("set", "_month12_month", 3)
	town.call("runner_unlock_handbook", {
		"id": "M03_HANDBOOK", "silent": true,
		"pages": [{"pageId": "2.3"}, {"pageId": "2.4"}],
	})
	await get_tree().create_timer(0.3).timeout
	var after_unlock := _dot(town)
	print("[probe] DOT_AFTER_UNLOCK=", after_unlock)
	if not after_unlock:
		_fail += 1

	# 玩家点圆钮 → 打开手册 → 红点必须灭。
	town.call("_open_month12_handbook")
	await get_tree().create_timer(0.6).timeout
	var after_open := _dot(town)
	print("[probe] DOT_AFTER_OPEN=", after_open)
	if after_open:
		_fail += 1

	# 关掉手册再喂一次新页，红点要能重新亮起来。
	var book = town.get("_month12_handbook")
	if book != null and bool(book.call("is_open")):
		book.call("close")
	await get_tree().create_timer(0.3).timeout
	town.call("runner_unlock_handbook", {
		"id": "M07_HANDBOOK_3",
		"pages": [{"pageId": "3.1"}],
	})
	await get_tree().create_timer(0.3).timeout
	var again := _dot(town)
	print("[probe] DOT_AGAIN=", again)
	if not again:
		_fail += 1
	print("[probe] FAIL=", _fail)
