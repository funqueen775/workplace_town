extends Node

## 心情条实拍：满格 6/6 时六罐蜂蜜是否都还在底板里，空罐那一半对不对。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/hud_mood_shot.tscn

const SHOT_DIR := "res://test_artifacts/hud_mood"
const UI := preload("res://scripts/TownUiV2.gd")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("7f9a5e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var ui := UI.new()
	add_child(ui)
	await _wait(0.3)
	for value in [6, 3, 0]:
		ui.call("refresh", {"month": 1, "day": 1, "xun": "上旬", "band": "白天"}, {}, value, 6, "心情")
		await _wait(0.2)
		var first: Control = ui.get("_honey_icons")[0]
		var last: Control = ui.get("_honey_icons")[5]
		print("%d/6 首罐 x=%.0f 末罐 x=%.0f..%.0f（底板内沿约到 425）" % [
			value, first.position.x, last.position.x, last.position.x + last.size.x])
		await _shot("mood_%d" % value)
	print("HUD_MOOD_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, shot_name])
	print("shot %s -> %s" % [shot_name, image.save_png(path)])
