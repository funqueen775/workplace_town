extends Node

## 再访一处的实拍：回到已经做完的地方，那句环境话背后到底有没有图。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/revisit_shot.tscn

const SHOT_DIR := "res://test_artifacts/revisit"

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
	_town.set("_hud_tour_active", false)
	_town.set("_date_cutscene_lock", false)
	_town.call("_load_month12_places")
	var places: Array = _town.get("_month12_places") as Array
	for value in places:
		var activity := value as Dictionary
		if String(activity.get("id", "")) != "m1_tool":
			continue
		print("去处 %s · scene=[%s] · shots=%s" % [
			activity.get("id"), String(activity.get("scene", "")),
			str((activity.get("card", {}) as Dictionary).get("shots", []))])
		var image := String(activity.get("scene", ""))
		var shots: Array = (activity.get("card", {}) as Dictionary).get("shots", []) as Array
		if image.is_empty() and not shots.is_empty():
			image = "res://assets/ui/place_cards/%s" % String(shots[0])
		print("该用的图 = [%s] 存在=%s" % [image, FileAccess.file_exists(image)])
		_town.call("_present_month12_revisit", activity)
		await _wait(0.8)
		var panel = _town.get("_weekend_scene_panel")
		if panel != null:
			var rect = panel.get("_image_rect")
			print("面板可见=%s · 图=%s" % [panel.visible, "有" if rect != null and (rect as TextureRect).texture != null else "没有"])
		await _shot("01_revisit_m1_tool")
	print("REVISIT_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
