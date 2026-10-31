extends Control
## 档案页出图：看"留下的材料"那一行有没有落对位置、会不会压到别的东西。

var _dir := "user://profileshot"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(2.6).timeout
	var panel = town.get("_story_event_panel")
	if panel != null and bool(panel.call("is_open")):
		panel.call("dismiss")
		panel.visible = false
	# 月首卡会盖在档案页上面，出图前先收掉。
	var start = town.get("_month12_start_panel")
	if start != null and bool(start.call("is_open")):
		town.call("_on_month_start_continued")
		await get_tree().create_timer(1.4).timeout
	# 月首卡之后紧跟着 E01 那一屏，也收掉，不然档案页被压在底下。
	if panel != null and bool(panel.call("is_open")):
		panel.call("dismiss")
		panel.visible = false
		await get_tree().create_timer(0.3).timeout
	var toast = town.get("_toast_layer")
	if toast != null:
		toast.hide()
	var ui = town.get("_town_ui_v2")
	ui.call("open_view", "profile")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/profile.png" % _dir)
	print("[shot] profile -> ", _dir)
	get_tree().quit()
