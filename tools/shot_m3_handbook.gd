extends Control
## 第 3 月手册那一件：会前红点亮不亮、第二章 2.3/2.4 在不在、铅笔字有没有。
## 用法：<godot> --path <PROJ> --resolution 1600x900 res://tools/shot_m3_handbook.tscn -- --dir E:/.../m3

var _dir := "user://m3"


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
	img.save_png("%s/%s.png" % [_dir, name])
	print("[shot] ", name)


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.4).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	panel.call("dismiss")
	panel.visible = false
	# 跳到第 3 月，走到"手册第二章开了"那一拍
	town.call("debug_jump_to_month", 3, "A")
	# 跳到第 3 月第一屏：提示条应该在这时候弹（m03_month）
	for i in 40:
		await get_tree().create_timer(0.15).timeout
		var start_card = town.get("_month12_start_panel")
		if start_card != null and bool(start_card.call("is_open")):
			town.call("_on_month_start_continued")
		var fired: Dictionary = town.get("_hint_fired")
		if bool(fired.get("m03_month", false)):
			break
	await get_tree().create_timer(0.35).timeout
	await _shot("00_翻月提示条")
	print("[state] 已弹过的提示=", (town.get("_hint_fired") as Dictionary).keys())
	var got := false
	for i in 60:
		await get_tree().create_timer(0.15).timeout
		var flags: Dictionary = town.get("_month12_flags")
		if bool(flags.get("handbook_page_2.3", false)):
			got = true
			break
		if bool(town.get("_month12_start_panel") != null) and bool(town.get("_month12_start_panel").call("is_open")):
			town.call("_on_month_start_continued")
		if bool(panel.call("is_open")):
			panel.call("_advance")
	print("[state] 2.3 页已解锁=", got, " 手册按钮上的红点=", _dot_visible(town))
	await _shot("01_会前_手册红点")
	town.call("_open_month12_handbook")
	await get_tree().create_timer(0.7).timeout
	print("[state] 翻开手册后 红点=", _dot_visible(town))
	var book = town.get("_month12_handbook")
	print("[state] 手册目录=", book.call("chapter_ids") if book != null else "无")
	if book != null:
		book.call("_select_chapter", "2.3")
		await get_tree().create_timer(0.6).timeout
		await _shot("02_手册_2.3")
		book.call("_select_chapter", "2.4")
		await get_tree().create_timer(0.6).timeout
		await _shot("03_手册_2.4_铅笔字")
		book.call("close")
	get_tree().quit()


func _dot_visible(town: Node) -> bool:
	var ui = town.get("_town_ui_v2")
	if ui == null:
		return false
	var dot = ui.get("_manual_dot")
	return dot != null and bool((dot as Control).visible)
