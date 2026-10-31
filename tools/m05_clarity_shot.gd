extends Node

## 第 5 月的「玩家看不看得懂」核对：
##   ① 深夜那一屏，王哥说"紧急通道"时气泡右上角有没有那颗能点的问号；
##   ② 自由安排那一屏，HUD 顶上有没有"这个月两格"这类提示。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/m05_clarity_shot.tscn

var _town: Node
var _dir := ""


func _ready() -> void:
	_watchdog()
	_dir = ProjectSettings.globalize_path("res://test_artifacts/m05_clarity")
	DirAccess.make_dir_recursive_absolute(_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.4)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await _wait(1.0)

	# 城镇自己只缓存首月那份 opening 表，这里现读一份全年的，按 id 取第 5 月的屏。
	var events := {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	for node in ((parsed as Dictionary).get("nodes", []) as Array):
		events[String((node as Dictionary).get("id", ""))] = node
	var night: Dictionary = events.get("M05_NIGHT", {})
	var panel: Node = _town.get("_story_event_panel")
	panel.set("reduced_motion", true)
	panel.call("present", night)
	await _wait(0.8)
	# 推到王哥那句"紧急通道不是后门"（第 5 拍）。
	for i in int((night.get("beats") as Array).size()):
		var shown := int(panel.get("_beat_index"))
		if shown >= 4:
			break
		panel.call("_advance")
		await _wait(0.35)
	await _wait(1.0)
	var has_dot := _find_dot(panel) != null
	print("[m05] 深夜屏第 %d 拍，问号点=%s" % [int(panel.get("_beat_index")) + 1, str(has_dot)])
	if has_dot:
		var dot: Button = _find_dot(panel)
		dot.pressed.emit()
		await _wait(0.6)
	await _shoot("night_term")
	panel.call("dismiss")
	await _wait(0.6)

	# 自由安排那一屏：直接把节点喂给城镇，看提示条长什么样。
	# 提示是按月的（hints.json 里 month=5），探针停在首月，得把月份拨过去才会发。
	_town.set("_month12_month", 5)
	var free: Dictionary = events.get("M05_FREE", {})
	_town.call("runner_open_activity", free)
	await _wait(1.0)
	await _shoot("free_hint")
	print("[m05] 自由安排屏提示已发，截图在 ", _dir)
	get_tree().quit(0)


func _find_dot(panel: Node) -> Button:
	for child in panel.get_children():
		var found := _dig(child)
		if found != null:
			return found
	return null


func _dig(node: Node) -> Button:
	if node is Button and String((node as Node).name) == "TermDot":
		return node as Button
	for child in node.get_children():
		var found := _dig(child)
		if found != null:
			return found
	return null


func _shoot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, name])


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
