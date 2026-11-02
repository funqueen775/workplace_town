extends Node

## 实拍两张：第 5 月客户说话时左边站的是新做的全灰剪影；第 7 月复盘会那位改回册子叫法之后有脸了。
## 走的是城镇自己的剧情面板（不新起面板），所以版式、层级、立绘判定都是玩家那一份。
## 用法：<godot> --path . --resolution 1600x900 res://tools/speaker_screen_shot.tscn

const OUT_DIR := "res://test_artifacts/speakers"

var _town: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.0).timeout
	await _shoot(5, "M05_DEMO", "客户", "01_客户_灰剪影.png")
	await _shoot(7, "E19", "产品同事", "02_产品同事_有脸.png")
	print("SPEAKER_SHOTS_DONE")
	_done = true
	get_tree().quit(0)


func _shoot(month_value: int, node_id: String, speaker: String, file_name: String) -> void:
	_town.call("debug_jump_to_month", month_value)
	await get_tree().create_timer(1.6).timeout
	var start: Variant = _town.get("_month12_start_panel")
	for i in 20:
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.6).timeout
			break
		await get_tree().create_timer(0.3).timeout
	var panel: CanvasLayer = _town.get("_story_event_panel")
	if panel != null and is_instance_valid(panel) and bool(panel.call("is_open")):
		panel.call("dismiss")
		await get_tree().create_timer(0.5).timeout
	var node: Dictionary = _node_by_id(node_id)
	if node.is_empty():
		print("   找不到节点 ", node_id)
		return
	var data: Dictionary = _town.call("_runner_story_data", node)
	panel.call("present", data, true)
	await get_tree().create_timer(0.8).timeout
	# 一拍拍往下走，走到那位说话人为止
	for step in 40:
		var beats: Array = panel.get("_beats")
		var index := int(panel.call("beat_index"))
		if index >= 0 and index < beats.size():
			var beat := Dictionary(beats[index])
			if String(beat.get("speaker", "")) == speaker:
				break
		panel.call("_next_beat")
		await get_tree().create_timer(0.45).timeout
	await get_tree().create_timer(0.8).timeout
	var beats2: Array = panel.get("_beats")
	var idx := int(panel.call("beat_index"))
	if idx >= 0 and idx < beats2.size():
		var shown := Dictionary(beats2[idx])
		print("   %s 停在：%s「%s」" % [node_id, String(shown.get("speaker", "旁白")),
			String(shown.get("text", "")).left(24)])
	get_viewport().get_texture().get_image().save_png(OUT_DIR + "/" + file_name)


func _node_by_id(node_id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	var nodes: Array = (parsed as Dictionary).get("nodes", [])
	for value in nodes:
		var node := Dictionary(value)
		if String(node.get("id", "")) == node_id:
			return node
	return {}


func _watchdog() -> void:
	await get_tree().create_timer(300.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
