extends Node

## 门色的实拍：能自由走动时门是金的，进了剧情/月末这些进不去的时段，门要压灰。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/door_grey_shot.tscn

const SHOT_DIR := "res://test_artifacts/door_grey"

var _town: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	# 月首卡和剧情面板都盖在画面上，截图前先收掉（否则拍到的是卡，不是门）
	for key in ["_month12_start_panel", "_story_event_panel"]:
		var node = _town.get(key)
		if node == null:
			continue
		for method in ["close", "dismiss", "hide_panel"]:
			if node.has_method(method):
				node.call(method)
		if node is CanvasItem:
			(node as CanvasItem).hide()
	await _wait(0.6)
	_town.set("_hud_tour_active", false)
	_town.set("_date_cutscene_lock", false)
	_town.set("_month12_waypoint", Vector2(-99999, -99999))
	_town.call("_load_month12_places")
	_town.set("_month12_active", true)
	_town.set("_month12_places_open", true)
	for id in ["m1_rooftop", "m1_lakeside", "m1_tool"]:
		_town.call("_ensure_month12_place", id)
	var doors: Dictionary = _town.get("_month12_place_portals")
	print("门 %d 扇" % doors.size())
	# 站位挑一扇"月末会变灰"的门旁边，两张图才看得出差别
	var first: Node2D = doors.get("m1_lakeside", doors.values()[0])
	var player: Node2D = _town.get("_player")
	player.position = first.position + Vector2(70, 60)
	for step in [
		{"phase": "activity", "tag": "01_free_window"},
		{"phase": "close", "tag": "02_month_close"},
		{"phase": "tour", "tag": "03_story_walk"},
	]:
		_town.set("_month12_phase", step["phase"])
		_town.call("_refresh_month12_place_seals")
		await _wait(0.6)
		var states := PackedStringArray()
		for key in doors.keys():
			states.append("%s=%s" % [key, "灰" if bool((doors[key] as Node2D).sealed) else "金"])
		print("%s → %s" % [step["phase"], " ".join(states)])
		await _shot(String(step["tag"]))
	print("DOOR_GREY_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
