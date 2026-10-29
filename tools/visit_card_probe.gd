extends Node

## 剧情解锁卡探针：跳到第 2 月，推到"去树影书院二楼"那一拍，截讲解卡。

var _town: Node
var _dir := ""


func _ready() -> void:
	_dir = ProjectSettings.globalize_path("res://test_artifacts/visit_card")
	DirAccess.make_dir_recursive_absolute(_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.6).timeout
	_town.call("debug_jump_to_month", 2, "A")
	await get_tree().create_timer(2.4).timeout
	for i in 900:
		await get_tree().create_timer(0.05).timeout
		var start_panel = _town.get("_month12_start_panel")
		if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
			start_panel.emit_signal("continued")
			continue
		if String(_town.get("_month12_visit_id")) == "M02_LIBRARY":
			break
		var panel = _town.get("_story_event_panel")
		if panel != null and bool(panel.call("is_open")):
			var runner = _town.get("_month_runner")
			var node_id := String((runner.get("current") as Dictionary).get("id", "")) if runner != null else ""
			if String(panel.get("_stage")) == "choices":
				panel.call("_on_choice_picked", node_id, "A", 45)
			else:
				panel.call("_advance")
			continue
		var runner2 = _town.get("_month_runner")
		var waypoint: Vector2 = _town.get("_month12_waypoint")
		if runner2 != null and bool(runner2.get("waiting_walk")) and waypoint.x > -90000.0:
			(_town.get("_player") as Node2D).position = waypoint
			continue
	await get_tree().create_timer(1.6).timeout
	print("visit_id=", String(_town.get("_month12_visit_id")),
		" 卡面板开着=", _panel_open())
	await _shot("visit_card")
	print("VISIT_CARD_DONE")
	get_tree().quit(0)


func _panel_open() -> bool:
	var panel = _town.get("_month12_place_panel")
	if panel == null or not is_instance_valid(panel):
		return false
	return bool(panel.call("is_open"))


func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("shot ->", image.save_png("%s/%s.png" % [_dir, name]))
