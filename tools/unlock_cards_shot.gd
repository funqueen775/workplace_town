extends Node

## 把每条自由活动的"解锁卡"逐张拍下来：那张歪纸片（手写"解 锁" + 三行 + 贴胶带的真截图）。
## 用法：<godot> --path . --resolution 1600x900 res://tools/unlock_cards_shot.tscn -- --no-resume

const OUT_DIR := "res://test_artifacts/unlock_cards"
const WANT := ["m5_stage", "m5_umbrella", "m3_waterway", "m11_boardgame", "m7_valley"]

var _town: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.2).timeout
	var start = _town.get("_month12_start_panel")
	for i in 60:
		await get_tree().create_timer(0.1).timeout
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.8).timeout
			break
	var story = _town.get("_story_event_panel")
	if story != null and is_instance_valid(story):
		story.call("dismiss")
		await get_tree().create_timer(0.4).timeout
	var panel = _town.get("_month12_place_panel")
	for id in WANT:
		var place: Dictionary = _town.call("_month12_place_by_id", id)
		if place.is_empty():
			print("[解锁卡] ", id, " 找不到")
			continue
		var shots: Array = (place.get("card", {}) as Dictionary).get("shots", []) as Array
		panel.call("show_unlock", place, false)
		await get_tree().create_timer(0.6).timeout
		await _shot(id)
		print("[解锁卡] ", id, " ", String(place.get("name", "")),
			" 行数=", ((place.get("card", {}) as Dictionary).get("lines", []) as Array).size(),
			" 配图=", shots)
		panel.call("close")
		await get_tree().create_timer(0.25).timeout
	print("UNLOCK_CARDS_DONE")
	_done = true
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + name + ".png"))


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
