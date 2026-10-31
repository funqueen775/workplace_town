extends Node

## 心情罐对比实拍：第 1 月 vs 第 2 月，各截一张全屏，看罐子到底在哪个月露面。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/probe_mood_jump.tscn

const SHOT_DIR := "res://test_artifacts/mood_jump"

var _town: Node
var _ui: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(4.0)
	_ui = _town.get("_town_ui_v2")
	await _report_shot("m1_open")

	_town.call("debug_jump_to_month", 2, "A")
	await _wait(5.0)
	await _report_shot("m2_open")

	_town.call("debug_jump_to_month", 4, "A")
	await _wait(5.0)
	await _report_shot("m4_open")

	print("MOOD_JUMP_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _report_shot(name: String) -> void:
	var meter: Control = _ui.get("_energy_panel") if _ui != null else null
	print("[jump] %s · 第 %d 月 · 罐子可见=%s" % [
		name, int(_town.get("_month12_month")), str(meter != null and meter.visible)])
	await _shot(name)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	image.save_png(path)
	print("[jump] shot ", path)
