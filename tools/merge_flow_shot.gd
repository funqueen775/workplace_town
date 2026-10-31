extends Node

## 合并效果截图探针：三页导览 → 两道入职预演 → 新部门室内 → 活动卡。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/merge_flow_shot.tscn

const SHOT_DIR := "res://test_artifacts/merge_flow"
const STARTUP := preload("res://Startup.tscn")
const INTERIOR := preload("res://scripts/InteriorPreview.gd")

var _done := false

func _ready() -> void:
	_watchdog()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var startup = STARTUP.instantiate()
	add_child(startup)
	await _wait(0.8)
	await _shot("01_title")

	startup.call("_start_intro")
	await _wait(0.5)
	await _shot("02_guide_1")

	startup.call("_go_page", 2)
	await _wait(0.5)
	await _shot("03_guide_3")

	startup.call("_start_scenarios")
	await _wait(0.6)
	await _shot("04_scenario_1")

	var scenario = startup.get_child(startup.get_child_count() - 1)
	scenario.call("_choose_answer", 0)
	await _wait(0.5)
	await _shot("05_scenario_1_reply")

	scenario.set("_page", 1)
	scenario.call("_rebuild")
	await _wait(0.5)
	await _shot("06_scenario_2")

	scenario.call("_choose_answer", 0)
	await _wait(0.5)
	await _shot("07_scenario_2_reply")

	startup.queue_free()
	await _wait(0.4)

	var preview = INTERIOR.new()
	add_child(preview)
	preview.call("use_department_layout", true)
	preview.call("suppress_interior_npc", false)
	preview.call("present", {"id": "d", "code": "D", "name": "人事部"}, "res://assets/八大区域地图重制版/D_人事部.png")
	preview.call("enable_exploration")
	preview.call("set_activities", [
		{"id": "m9_library", "title": "书院复习"},
	], true, 2)
	await _wait(0.8)
	await _shot("08_department_d")

	preview.call("suppress_interior_npc", false)
	preview.call("present", {"id": "a", "code": "A", "name": "市场部"}, "res://assets/八大区域地图重制版/A_市场部.png")
	preview.call("enable_exploration")
	preview.call("set_activities", [], true, 2)
	await _wait(0.8)
	await _shot("10_department_a")

	print("MERGE_FLOW_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	_done = true
	get_tree().quit(0)

func _watchdog() -> void:
	await get_tree().create_timer(40.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")
	print("SHOT ", shot_name, " saved=", image.save_png(path))
