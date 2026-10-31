extends Control
## 把 12 个月开场的关键几拍截成图，给平板上不方便操作的人看。
## 用法：
##   <godot> --path <PROJ> --resolution 1600x900 res://tools/shot_month_opening.tscn -- --dir E:/.../gallery

var _dir := "user://month12_opening"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _run() -> void:
	var packed: PackedScene = load("res://Main.tscn")
	var town: Node = packed.instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true

	# 1) 说明会开场旁白（入场卡已经过去）
	await _shot("01_meeting_open")

	# 2) 陈工讲两次评估：往后翻一拍
	panel.call("_advance")
	await get_tree().create_timer(0.15).timeout
	await _shot("02_meeting_assessment")

	# 3) 王哥接话「走，我带你转一圈」：E01 最后一拍
	for i in 7:
		panel.call("_advance")
		await get_tree().create_timer(0.06).timeout
	await _shot("03_meeting_wang")

	# 4) 带巡第一拍：翻掉 E01 的结算，跳过 E01_TOUR 入场卡
	panel.call("_advance")
	await get_tree().create_timer(0.45).timeout
	if panel.is_open():
		panel.call("_advance")
		await get_tree().create_timer(0.25).timeout
	await _shot("04_tour")

	# 5) 走完带巡：先等四角导览弹出来，逐个截；导览结束后再看任务卡和黄线
	for i in 9:
		if panel.is_open():
			panel.call("_advance")
		await get_tree().create_timer(0.06).timeout
	await get_tree().create_timer(0.9).timeout
	var tour = town.get("_hud_tour")
	if tour != null and tour.call("is_active"):
		await _shot("05_tour_left")
		tour.call("advance")
		await get_tree().create_timer(0.35).timeout
		await _shot("06_tour_right")
		tour.call("advance")
		await get_tree().create_timer(0.35).timeout
		await _shot("07_tour_bottom")
		tour.call("advance")
		await get_tree().create_timer(0.3).timeout
	var player: Node2D = town.get("_player")
	player.position = Vector2(700, 500)
	await get_tree().create_timer(0.6).timeout
	await _shot("08_objective")

	# 6) 点开手机：12m 来信（陈工两条），红点应该消失
	town.call("_open_ui_phone")
	await get_tree().create_timer(0.5).timeout
	await _shot("09_phone_inbox")
	town.get("_town_ui_v2").call("close_view")
	await get_tree().create_timer(0.3).timeout

	# 7) 到 B 区，旧的手册场景接上
	var zone: Dictionary = town.call("_zone_by_code", "B")
	var interaction: Dictionary = zone.get("interaction", {})
	player.position = Vector2(float(interaction.get("x", 970.0)), float(interaction.get("y", 210.0)))
	await get_tree().create_timer(1.0).timeout
	if panel.is_open():
		panel.call("_advance")  # 跳过入场卡
		await get_tree().create_timer(0.3).timeout
	await _shot("10_handbook")
	# 8) 王哥说话那拍：验证角色立绘已经补回来
	if panel.is_open():
		panel.call("_advance")
		await get_tree().create_timer(0.15).timeout
		panel.call("_advance")
		await get_tree().create_timer(0.2).timeout
		panel.call("_advance")
		await get_tree().create_timer(0.25).timeout
	await _shot("11_wang_portrait")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	img.save_png(path)
	print("[shot] %s" % path)
