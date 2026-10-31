extends Control
## 出三张实拍：第 6 月墙 / 挑主讲 / 第 12 月回放。
## 用法：<godot> --path . --resolution 1600x900 --audio-driver Dummy res://tools/shot_story.tscn -- --dir <out>

var _dir := "user://storyshot"
var _town: Node
var _panel
var _by := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	for value in ((raw as Dictionary).get("nodes", []) as Array):
		_by[String((value as Dictionary).get("id", ""))] = value
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(2.8).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	# 月首卡和开场剧情都收掉，不然全盖在实拍上
	var start = _town.get("_month12_start_panel")
	if start != null and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await get_tree().create_timer(1.2).timeout
	if bool(_panel.call("is_open")):
		_panel.call("dismiss")
	_panel.visible = false
	var card = _town.get("_hud_button_tutorial")
	if card != null and bool(card.call("is_open")):
		card.call("_on_open_pressed")
		await get_tree().create_timer(0.4).timeout
	# 新开一局会清空记忆墙，所以启动之后自己写几条
	var f := FileAccess.open("user://workplace_town_memos.jsonl", FileAccess.WRITE)
	if f != null:
		for row in [
			{"month": 2, "text": "两条路我都跑过才选的。"},
			{"month": 3, "text": "客户问能不能写，我说能做的写、做不到的写明兜底。"},
			{"month": 5, "text": "凌晨两点，我走了紧急通道，工单第二天补。"},
		]:
			f.store_line(JSON.stringify(row, ""))
		f.close()
	await _show("M06_WALL", "那张", "01_六月墙")
	await _show("M06_PICK", "__choice__", "02_挑主讲")
	await _show("M12_REPLAY", "第三面", "03_十二月回放_有便签")
	await _show("M12_REPLAY", "第六面", "04_十二月回放_空墙")
	print("[shots] 完成 -> ", _dir)
	get_tree().quit()


func _show(node_id: String, needle: String, name: String) -> void:
	_panel.visible = true
	_panel.call("present", _town.call("_runner_story_data", _by.get(node_id, {})))
	await get_tree().create_timer(1.9).timeout
	for i in 12:
		var stage := String(_panel.get("_stage"))
		if needle == "__choice__":
			if stage == "choice":
				break
		else:
			var beats: Array = _panel.get("_beats")
			var idx := int(_panel.get("_beat_index"))
			if idx >= 0 and idx < beats.size() and needle in String((beats[idx] as Dictionary).get("text", "")):
				break
		_panel.call("_advance")
		await get_tree().create_timer(0.45).timeout
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, name])
	print("[shots] ", name)
	if bool(_panel.call("is_open")):
		_panel.call("dismiss")
	_panel.visible = false
	await get_tree().create_timer(0.4).timeout
