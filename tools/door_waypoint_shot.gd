extends Node

## 实拍「黄线指着的门不许灰」：第 2 月起故事把人带去 B 区工位，门就立在那儿。
## 摆出 node_walk（黄线还在走、门本该全灰）那一帧，黄线终点压在门上，拍一张看颜色。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/door_waypoint_shot.tscn

const SHOT_DIR := "res://test_artifacts/door_waypoint"

var _town: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	for key in ["_month12_start_panel", "_story_event_panel"]:
		var node = _town.get(key)
		if node == null:
			continue
		for method in ["close", "dismiss", "hide_panel"]:
			if node.has_method(method):
				node.call(method)
		if node is CanvasItem:
			(node as CanvasItem).hide()
	await _wait(0.4)
	_town.set("_hud_tour_active", false)
	_town.set("_date_cutscene_lock", false)
	_town.call("_load_month12_places")
	_town.set("_month12_active", true)
	_town.set("_month12_places_open", true)
	for id in ["m1_rooftop", "m1_lakeside", "m1_tool"]:
		_town.call("_ensure_month12_place", id)
	await _wait(0.2)
	var doors: Dictionary = _town.get("_month12_place_portals")
	var door: Node2D = doors.get("m1_tool")
	# 站位挑黄线终点正压着的那扇门：故事带你去工位，门就在工位上。
	_town.set("_month12_phase", "node_walk")
	_town.set("_month12_waypoint", door.position)
	_town.call("_refresh_month12_place_seals")
	var player: Node2D = _town.get("_player")
	player.position = door.position + Vector2(-8, 78)
	# 拉近一点：截图里要一眼看出门的颜色，远景那个小点不够看。
	_town.set("_map_zoom_factor", 1.9)
	await _wait(1.6)
	var states := PackedStringArray()
	for key in doors.keys():
		states.append("%s=%s" % [key, "灰" if bool((doors[key] as Node2D).sealed) else "金"])
	print("node_walk 相位、黄线终点=门位 → ", " ".join(states))
	await _shot("01_waypoint_door")
	# 反面：把黄线撤掉，同一帧下该门应该退回灰（证明不是"永远金"）。
	_town.set("_month12_waypoint", Vector2(-99999, -99999))
	_town.call("_refresh_month12_place_seals")
	await _wait(0.8)
	print("黄线撤掉后 m1_tool = ", "灰" if bool(door.sealed) else "金")
	await _shot("02_no_waypoint")
	print("DOOR_WAYPOINT_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
