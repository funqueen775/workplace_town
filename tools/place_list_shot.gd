extends Node

## 到访列表截图：跳到第 2 月，推进到"去书院二楼查旧事故单"那一屏，
## 直接按 D 区调出列表，看三件事：这一趟要去的排没排第一、每行有没有理由、面板底下有没有落点。

var _town: Node
var _dir := ""


func _ready() -> void:
	_dir = ProjectSettings.globalize_path("res://test_artifacts/place_list")
	DirAccess.make_dir_recursive_absolute(_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.4).timeout
	_town.call("debug_jump_to_month", 2, "A")
	await get_tree().create_timer(2.4).timeout
	# 直接摆出"这一屏等着玩家去书院"的状态，验列表本身（不跑整月）
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	for node in (parsed as Dictionary).get("nodes", []):
		if String((node as Dictionary).get("id", "")) == "M02_LIBRARY":
			_town.set("_month12_visit_node", node)
			_town.set("_month12_visit_id", "M02_LIBRARY")
			break
	print("visit 节点已摆好：", not ( _town.get("_month12_visit_node") as Dictionary).is_empty())
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
	var story = _town.get("_story_event_panel")
	if story != null and bool(story.call("is_open")):
		story.call("dismiss")
	await get_tree().create_timer(0.8).timeout
	_town.call("_show_month12_place_list", "D")
	await get_tree().create_timer(0.6).timeout
	var panel = _town.get("_activity_panel")
	if panel != null:
		var root = panel.get("_root")
		print("panel pos=", root.position, " size=", root.size, " rect=", root.get_global_rect(), " anchor=", root.anchor_left, ",", root.anchor_right)
		print("viewport=", get_viewport().get_visible_rect().size)
	await _shot("d_list")
	print("PLACE_LIST_DONE")
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("shot ->", image.save_png("%s/%s.png" % [_dir, name]))
