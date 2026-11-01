extends Node

## 熊熊有招（松风训练谷的骰子对局）三段各拍一张：开场剧情 → 选搭档 → 对局界面。
## 用法：<godot> --path . --resolution 1600x900 res://tools/duel_shot.tscn

const OUT_DIR := "res://test_artifacts/duel"

var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	# 照城镇开这场对局的同一个办法挂：1280x720 的框按窗口缩放。
	var layer := CanvasLayer.new()
	layer.layer = 195
	add_child(layer)
	var frame := Control.new()
	frame.size = Vector2(1280, 720)
	frame.scale = get_viewport().get_visible_rect().size / frame.size
	layer.add_child(frame)
	var battle: Control = load("res://training_valley/main.tscn").instantiate()
	frame.add_child(battle)
	await get_tree().create_timer(1.4).timeout
	await _shot("1_开场")
	battle.call("_show_partner_select")
	await get_tree().create_timer(0.9).timeout
	await _shot("2_选搭档")
	battle.call("_select_wang")
	await get_tree().create_timer(1.2).timeout
	battle.call("_transition_to_battle")
	await get_tree().create_timer(1.6).timeout
	battle.call("_show_battle_controls")
	await get_tree().create_timer(0.9).timeout
	await _shot("3_对局")
	print("DUEL_SHOT_DONE")
	_done = true
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + name + ".png"))


func _watchdog() -> void:
	await get_tree().create_timer(60.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
