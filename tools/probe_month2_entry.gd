extends Node

## 翻到第 2 月那一瞬间，玩家屏幕上到底是什么。
## 用法：<godot> --path <PROJ> --resolution 1600x900 res://tools/probe_month2_entry.tscn
## 首月自动替玩家点完（含"结束这个月"），换月过场落定后停手，只报状态 + 截图。

var _dir := "user://month2_entry"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	print("[entry] 开局 phase=", town.get("_month12_phase"))
	for i in 1400:
		await get_tree().create_timer(0.05).timeout
		var phase := String(town.get("_month12_phase"))
		var month := int(town.get("_month12_month"))
		# 已经站在第 2 月、过场也播完了：停手，看玩家实际会看到什么。
		if month >= 2 and phase == "month_nodes" and not bool(town.call("wipe_playing")):
			break
		if bool(town.get("_hud_tour_active")):
			town.get("_hud_tour").call("advance")
			continue
		var tutorial = town.get("_month_phone_tutorial")
		if tutorial != null and bool(tutorial.get("_card").visible):
			tutorial.call("close_tutorial")
			continue
		var unlock = town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			continue
		if phase in ["tour", "e02_walk", "node_walk"]:
			var wp: Vector2 = town.get("_month12_waypoint")
			if wp.x > -90000.0:
				town.get("_player").position = wp
			continue
		if bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				var ev: Dictionary = panel.get("_event")
				panel.call("_on_choice_picked", String(ev.get("id", "")), "A", 45)
			elif stage != "interaction" and stage != "handbook":
				panel.call("_advance")
			continue
		if phase == "activity":
			town.call("_on_end_month_pressed")
			continue
		if phase == "close":
			town.call("_on_month12_close_finished")
			continue
	await get_tree().create_timer(1.2).timeout
	_report(town, "刚进第 2 月")
	await _shot(town, "01_第2月第一眼")
	print("[entry] 再等 3 秒（看主线面板会不会自己开）")
	await get_tree().create_timer(3.0).timeout
	_report(town, "等了三秒后")
	await _shot(town, "02_等三秒后")
	get_tree().quit()


func _report(town: Node, label: String) -> void:
	var panel = town.get("_story_event_panel")
	var button = town.get("_end_month_button")
	var doors: Dictionary = town.get("_month12_place_portals")
	var hud = town.get("_town_ui_v2")
	print("[entry] %s：月=%s phase=%s 面板开=%s 结束钮可见=%s 门=%d 任务卡=%s 副行=%s" % [
		label, town.get("_month12_month"), town.get("_month12_phase"),
		bool(panel.call("is_open")), (button as Control).visible if button != null else false,
		doors.size(), String(hud.get("_task_title").text) if hud.get("_task_title") != null else "?",
		String(hud.get("_task_note").text) if hud.get("_task_note") != null else "?",
	])


func _shot(town: Node, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	img.save_png(path)
	print("[shot] ", path)
