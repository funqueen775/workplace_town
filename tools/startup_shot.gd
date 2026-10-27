extends Node

## 把开场链路逐屏拍下来，给只看平板的人对齐一眼：
## 标题页 → 开场漫画 → 导览三页 → 选熊页。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/startup_shot.tscn

const SHOT_DIR := "res://test_artifacts/v12m_startup"

var _root: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_root = load("res://Startup.tscn").instantiate()
	add_child(_root)
	await _wait(0.6)
	await _shot("01_title")

	_root.call("_show_opening_comic")
	await _wait(1.4)
	await _shot("02_comic")
	await _wait(1.6)
	await _shot("03_comic_next")

	_root.call("_start_intro")
	await _wait(0.5)
	await _shot("04_intro_1")
	_root.call("_go_page", 1)
	await _wait(0.4)
	await _shot("05_intro_2")
	_root.call("_go_page", 2)
	await _wait(0.4)
	await _shot("06_intro_3")

	_root.set("_mode", "avatar")
	_root.call("_rebuild")
	await _wait(0.4)
	await _shot("07_avatar")

	print("STARTUP_SHOTS_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
