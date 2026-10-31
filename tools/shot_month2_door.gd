extends Control
## 第 2 月那扇图书馆的门，逐拍截图：评审室那句话 → 黄线走到门口 → 按 E →
## 屋里那一行 → 翻旧事故单这一屏 → 交回主线。
##
## 用法：
##   <godot> --path <PROJ> --resolution 1600x900 res://tools/shot_month2_door.tscn -- --dir E:/.../m02_door

var _dir := "user://month2_door"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	img.save_png(path)
	print("[shot] ", path)


## 替玩家把当前这一屏读完：旁白一路翻到底，选项按 A。
func _drain(town: Node, panel: Node, max_steps := 80) -> void:
	for i in max_steps:
		if not bool(panel.call("is_open")):
			return
		var stage := String(panel.get("_stage"))
		if stage == "choices":
			var event_data: Dictionary = panel.get("_event")
			panel.call("_on_choice_picked", String(event_data.get("id", "")), "A", 45)
		elif stage == "interaction" or stage == "handbook":
			pass
		else:
			panel.call("_advance")
		await get_tree().create_timer(0.12).timeout


## 翻到挂了某个钩子的那一拍就停下（截图要停在台词刚说完那一瞬）。
func _advance_to_hook(panel: Node, hook: String) -> void:
	for i in 40:
		if not bool(panel.call("is_open")):
			return
		var beats: Array = (panel.get("_event") as Dictionary).get("beats", []) as Array
		var index := int(panel.get("_beat_index"))
		if index < beats.size() and String((beats[index] as Dictionary).get("hook", "")) == hook:
			return
		if String(panel.get("_stage")) == "choices":
			return
		panel.call("_advance")
		await get_tree().create_timer(0.12).timeout


## 播放器把玩家派到某个点（walk 节点）：截图工具替玩家走完这一段，
## 不然它会一直停在"跟着黄线走"，面板永远不开。
func _arrive(town: Node, panel: Node) -> void:
	for i in 40:
		if String(town.get("_month12_phase")) == "node_walk":
			var wp: Vector2 = town.get("_month12_waypoint")
			if wp.x > -90000.0:
				(town.get("_player") as Node2D).position = wp
		if bool(panel.call("is_open")):
			return
		await get_tree().create_timer(0.1).timeout


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	# 直接从第 2 月的节点表开始：首月那 40 多拍不在本次检查范围内。
	town.set("_month12_month", 2)
	town.call("_set_date", 2, "early", "morning")
	town.call("_start_month_nodes", 2)
	await get_tree().create_timer(0.8).timeout

	# 1) 派活那一屏读完 → 走到 A 区评审室 → 翻到陈工那句"那不是退路"。
	await _drain(town, panel)
	await _arrive(town, panel)
	await _advance_to_hook(panel, "door_library")
	await _shot("01_e04_hook_beat")
	print("[state] story_door=", town.get("_story_door"), " phase=", town.get("_month12_phase"))

	# 2) 这一屏读完 → 播放器把人往书院门口派（黄线）。
	await _drain(town, panel)
	await get_tree().create_timer(0.8).timeout
	var door = town.get("_story_door")
	if door == null:
		print("[fail] 门没立起来，后面不用看了")
		get_tree().quit()
		return
	var door_at: Vector2 = (door as Node2D).position
	print("[state] door@", door_at, " phase=", town.get("_month12_phase"),
		" waypoint=", town.get("_month12_waypoint"))
	# 先站在门前十几步：这一张要同时看见黄线和门。
	(town.get("_player") as Node2D).position = door_at + Vector2(-6, 118)
	await get_tree().create_timer(0.9).timeout
	await _shot("02_walk_to_door")

	# 3) 走到门口：屏幕下方那颗 E 应该亮成「按 E 进去 · 图书馆二楼」。
	(town.get("_player") as Node2D).position = door_at
	await get_tree().create_timer(0.9).timeout
	var button = town.get("_interaction_button")
	print("[state] nearby=", town.get("_month12_nearby_place"),
		" button=", (button as Button).text if button != null else "(无)",
		" shown=", (button as Control).visible if button != null else false)
	await _shot("03_door_prompt")

	# 4) 按 E：进的是书院室内，进去之后右侧才列这一行。
	town.call("_begin_interaction")
	await get_tree().create_timer(1.1).timeout
	print("[state] active_zone=", (town.get("_active_zone") as Dictionary).get("code", ""),
		" interior_open=", bool(town.get("_interior_preview").call("is_open")))
	await _shot("04_inside_row")

	# 5) 点了那一行：这一屏就在屋里演，翻旧事故单。
	var place: Dictionary = town.call("_month12_visit_place")
	if place.is_empty():
		print("[fail] 屋里那一行没生成（visit 块读不出来）")
		get_tree().quit()
		return
	town.call("_on_activity_selected", place)
	await get_tree().create_timer(1.0).timeout
	await _shot("05_read_beats")
	for i in 5:
		if not bool(panel.call("is_open")):
			break
		panel.call("_advance")
		await get_tree().create_timer(0.14).timeout
	await _shot("06_read_last_beat")

	# 6) 读完交回主线：室内收掉、同事回到镇上、下一屏是"这一周"。
	await _drain(town, panel)
	await get_tree().create_timer(1.4).timeout
	print("[state] phase=", town.get("_month12_phase"),
		" visit=", town.get("_month12_visit_id"),
		" door=", town.get("_story_door"),
		" panel_open=", bool(panel.call("is_open")))
	await _shot("07_back_to_town")
	await _drain(town, panel)
	await get_tree().create_timer(0.8).timeout
	await _shot("08_next_node")
	print("[done] phase=", town.get("_month12_phase"))
	get_tree().quit()
