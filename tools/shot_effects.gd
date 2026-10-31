extends Control
## 出三张实拍：① 档案页有材料 ② 手机消息 ③ 续玩落点。
## 用法：<godot> --path . --resolution 1600x900 --audio-driver Dummy res://tools/shot_effects.tscn -- --dir <out>

var _dir := "user://effectshot"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(2.8).timeout
	var panel = town.get("_story_event_panel")
	var start = town.get("_month12_start_panel")
	if start != null and bool(start.call("is_open")):
		town.call("_on_month_start_continued")
		await get_tree().create_timer(1.2).timeout
	if panel != null and bool(panel.call("is_open")):
		panel.call("dismiss")
		panel.visible = false
	var toast = town.get("_toast_layer")
	if toast != null:
		toast.hide()

	# ① 档案页：这一局已经有"组内小工具"和"交接文档"两样材料
	var flags: Dictionary = town.get("_month12_flags")
	flags["m01_activity_tool"] = true
	flags["m12_handoff_documents"] = true
	var ui = town.get("_town_ui_v2")
	ui.call("open_view", "profile")
	await _shot("01_档案_有材料")
	ui.call("close_view")
	await get_tree().create_timer(0.3).timeout

	# ② 手机消息：拿第 3 月 E10 里那句真台词
	var text := "你可以把概率压下去，别把概率写成誓言。"
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	for value in ((raw as Dictionary).get("nodes", []) as Array):
		var node := value as Dictionary
		if String(node.get("id", "")) != "E10":
			continue
		for beat in (node.get("beats", []) as Array):
			if String((beat as Dictionary).get("type", "")) == "phone_cinematic":
				text = String((beat as Dictionary).get("text", ""))
	panel.visible = true
	# 让城镇先把那部真手机建出来，不然这一拍会退回兜底卡。
	var inbox_probe = town.call("_ensure_month_phone_panel")
	print("[验] 收件箱回复项=", (inbox_probe.get("reply_options") as Array).size(), "（应大于 0）")
	# 先塞两条更早的往来，验"看得到上下文"
	var log: Array = town.get("_phone_log")
	log.append({"speaker": "王哥", "text": "方案里那句「保证不会有偏差」，先别写死。"})
	log.append({"speaker": "王哥", "text": "客户问起来，你就讲你验证过的那一段。"})
	panel.call("present", {
		"id": "M12_E10",
		"title": "客户在场",
		"location": "C 区水巷 · 客户展厅",
		"actTitle": "第 3 月",
		"beats": [{"type": "phone_cinematic", "speaker": "王哥", "text": text}],
		"choices": [],
	})
	await get_tree().create_timer(2.4).timeout
	if bool(panel.call("is_open")) and _town_beat_pending(panel):
		panel.call("_advance")
	await get_tree().create_timer(1.4).timeout
	await _shot("02_手机消息")
	var idx_before := int(panel.get("_beat_index"))
	var drawer = town.get("_month_phone_panel")
	if drawer != null and bool(drawer.call("is_open")):
		drawer.call("close_phone")
		await get_tree().create_timer(0.8).timeout
	print("[验] 关掉手机后：beat ", idx_before, " -> ", int(panel.get("_beat_index")),
		" 手机开着=", bool(drawer.call("is_open")) if drawer != null else false)
	if bool(panel.call("is_open")):
		panel.call("dismiss")
		panel.visible = false
	# ③ 第 2 月末的心情讲解卡
	if bool(panel.call("is_open")):
		panel.call("dismiss")
		panel.visible = false
	var phone = town.get("_month_phone_panel")
	if phone != null and bool(phone.call("is_open")):
		phone.call("close_phone")
		await get_tree().create_timer(0.6).timeout
	town.call("_show_hud_button_tutorial", "mood", func(): pass)
	await get_tree().create_timer(1.0).timeout
	await _shot("03_心情卡")
	# ④ 收件箱：带回复项的样子
	var inbox2 = town.get("_month_phone_panel")
	if inbox2 != null and bool(inbox2.call("is_open")):
		inbox2.call("close_phone")
		await get_tree().create_timer(0.6).timeout
	var card = town.get("_hud_button_tutorial")
	if card != null and bool(card.call("is_open")):
		card.call("_on_open_pressed")
		await get_tree().create_timer(0.4).timeout
	inbox2.set("_tutorial_completed", true)
	for value in ((raw as Dictionary).get("nodes", []) as Array):
		if String((value as Dictionary).get("id", "")) == "M01_PHONE_1":
			town.call("runner_deliver_phone", value)
			break
	town.call("_open_ui_phone")
	await get_tree().create_timer(1.0).timeout
	inbox2.call("_open_conversation", "chen_gong")
	await get_tree().create_timer(0.9).timeout
	print("[验] 收件箱画出回复项=", (inbox2.get("reply_options") as Array).size())
	await _shot("04_收件箱带回复")
	print("[shots] 完成 -> ", _dir)
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, name])
	print("[shots] ", name)


## 进场动画走完之前 _stage 还不是 narration：这时候补一下推进，把那一拍真正亮出来。
func _town_beat_pending(panel: Node) -> bool:
	return String(panel.get("_stage")) != "narration"
