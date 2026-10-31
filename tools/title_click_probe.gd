extends Control
## 标题页真按钮点击探针：验证「开始游戏 → 开场漫画」「设置 → 设置面板」真的能点开。
## 用法（开窗口跑，会截图）：
##   <godot> --path <PROJ> --resolution 1280x720 res://tools/title_click_probe.tscn
## 产物：user://title_click/{title,settings,comic}.png

var _dir := "user://title_click"
var _startup: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in OS.get_cmdline_user_args().size():
		var args := OS.get_cmdline_user_args()
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_startup = load("res://Startup.tscn").instantiate()
	add_child(_startup)
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	print("SHOT %s %s err=%d" % [name, path, img.save_png(path)])


func _click(center: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	get_viewport().push_input(motion, true)
	await get_tree().process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.position = center
	down.global_position = center
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = center
	up.global_position = center
	get_viewport().push_input(up, true)
	await get_tree().process_frame


func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("title")

	var stage := _startup.get_node_or_null("TitleStage")
	var buttons: Array[TextureButton] = []
	if stage != null:
		for child in stage.get_children():
			if child is TextureButton:
				buttons.append(child)
	print("VIEWPORT %s STARTUP_SIZE %s STAGE scale=%s pos=%s" % [
		get_viewport().get_visible_rect().size, _startup.size,
		stage.scale if stage != null else "-", stage.position if stage != null else "-"])
	for button in buttons:
		print("BUTTON %s rect=%s" % [button.name, button.get_global_rect()])

	var by_name := {}
	for button in buttons:
		by_name[String(button.name)] = button

	# 1) 设置
	if by_name.has("Settings"):
		await _click((by_name["Settings"] as TextureButton).get_global_rect().get_center())
		await get_tree().create_timer(0.4).timeout
		var panel := _startup.get_node_or_null("SettingsPanel")
		print("SETTINGS_PANEL exists=%s open=%s" % [
			panel != null, panel.get("_open_flag") if panel != null else "-"])
		await _shot("settings")
		if panel != null:
			panel.call("close")
			await get_tree().create_timer(0.4).timeout
	else:
		print("SETTINGS_BUTTON_MISSING")

	# 2) 开始游戏 → 开场漫画
	if by_name.has("StartGame"):
		await _click((by_name["StartGame"] as TextureButton).get_global_rect().get_center())
		await get_tree().create_timer(0.6).timeout
		var comic := _startup.get_node_or_null("OpeningComic")
		print("COMIC exists=%s mode=%s children=%d" % [
			comic != null, _startup.get("_mode"), _startup.get_child_count()])
		await _shot("comic")
	else:
		print("START_BUTTON_MISSING")

	print("DONE")
	get_tree().quit()
