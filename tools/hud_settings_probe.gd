extends Node

## 城镇里实机核对 HUD 四颗：设置不弹卡直接进，档案/手册第一次点先出卡、
## 确认后才开面板，第二次点不再出卡。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/hud_settings_probe.tscn

var _dir := "user://hud_settings_probe"
var _done := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_watchdog()
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await _wait(3.0)
	var ui = town.get("_town_ui_v2")
	# 首月是分阶段开放的，这里先把四颗都亮出来，只看点击行为。
	ui.call("set_phone_visible", true)
	ui.call("set_manual_visible", true)
	_dump_buttons(ui, "开局")

	# 0) 左上角那条岗位栏：2026-10-30 起就是档案入口（右下角那颗圆钮已撤）。
	var job: Button = ui.get("_job_label")
	print("JOB 文字=", job.text, " 可点=", job.mouse_filter != Control.MOUSE_FILTER_IGNORE,
		" pressed 连接数=", job.pressed.get_connections().size())
	await _shot(town, "04_左上岗位条")

	# 1) 设置：不该有讲解卡，直接进设置页。
	ui.get("_settings_button").emit_signal("pressed")
	await _wait(0.5)
	var card = town.get("_hud_button_tutorial")
	print("SET 卡出现=", card != null and is_instance_valid(card) and bool(card.call("is_open")))
	print("SET 当前页=", ui.get("_view"), " 视图可见=", ui.call("is_open"))
	await _shot(town, "01_设置直进")
	ui.call("close_view")
	await _wait(0.4)

	# 2) 档案：第一次点岗位栏先出卡，确认后开档案页。
	job.emit_signal("pressed")
	await _wait(0.5)
	card = town.get("_hud_button_tutorial")
	print("ARCHIVE 首次卡=", card != null and bool(card.call("is_open")))
	await _shot(town, "02_档案卡")
	card.call("_on_open_pressed")
	await _wait(0.6)
	print("ARCHIVE 确认后页=", ui.get("_view"))
	ui.call("close_view")
	await _wait(0.4)

	# 3) 档案：第二次点岗位栏不再出卡。
	job.emit_signal("pressed")
	await _wait(0.5)
	print("ARCHIVE 二次卡=", bool(card.call("is_open")), " 页=", ui.get("_view"))
	ui.call("close_view")
	await _wait(0.4)

	# 4) 手册：第一次点先出卡。
	ui.get("_manual_button").emit_signal("pressed")
	await _wait(0.5)
	print("MANUAL 首次卡=", bool(card.call("is_open")))
	await _shot(town, "03_手册卡")
	card.call("_on_later_pressed")
	await _wait(0.4)
	print("MANUAL 稍后后卡=", bool(card.call("is_open")),
		" 算看过=", bool(town.get("_hud_tutorial_seen").get("manual", false)))
	print("PROBE_DONE ", _dir)
	_done = true
	get_tree().quit(0)


func _card_open(town: Node) -> bool:
	var card = town.get("_hud_button_tutorial")
	return card != null and is_instance_valid(card) and bool(card.call("is_open"))


func _dump_buttons(ui: Node, label: String) -> void:
	var visible_keys: Array = []
	for key in ["_manual_button", "_phone_button", "_settings_button", "_month_button"]:
		var button = ui.get(key)
		if button == null:
			print(label, " ", key, " 不存在")
			continue
		if button.visible:
			visible_keys.append(key)
	print(label, " 可见圆钮=", visible_keys)


func _watchdog() -> void:
	await get_tree().create_timer(40.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(town: Node, name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	image.save_png(path)
	print("SHOT ", path)
