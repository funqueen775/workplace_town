extends Node

## 心情讲解卡挪位核对：第 2 月月初卡点"继续"之后应弹卡，点"知道了"才启动本月。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/probe_mood_card_at_start.tscn

const SHOT_DIR := "res://test_artifacts/mood_card_start"

var _town: Node
var _card: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(4.0)
	_town.call("debug_jump_to_month", 2, "A")
	await _wait(3.0)
	_town.call("_on_month_start_continued")
	await _wait(1.5)
	_card = _town.get("_hud_button_tutorial")
	var open := _card != null and is_instance_valid(_card) and bool(_card.call("is_open"))
	print("[card] 月初卡点继续后，讲解卡打开=%s" % str(open))
	var phase := String(_town.get("_month12_phase"))
	print("[card] 此刻相位=%s（应为 month_start / month_nodes 之外，卡没关不能往下走）" % phase)
	await _shot("card_open")
	if open:
		_card.call("_on_open_pressed")
		await _wait(1.0)
		print("[card] 点了知道了之后相位=%s（应为 month_nodes）" % String(_town.get("_month12_phase")))
	await _shot("after_ok")
	print("MOOD_CARD_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	image.save_png(path)
	print("[card] shot ", path)
