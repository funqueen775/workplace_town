extends Node

## 眉标字号样张：把带橙色眉标的几张卡各渲染一张，看放大后有没有压到标题。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/panel_kicker_shot.tscn

const ACT := preload("res://scripts/v12m/Month12ActivityPanel.gd")
const CLOSE := preload("res://scripts/v12m/Month12ClosePanel.gd")
const PLACE := preload("res://scripts/v12m/PlaceVisitPanel.gd")
const DIR := "res://test_artifacts/v12m_doors"

var _dir_abs := ""


func _ready() -> void:
	_dir_abs = ProjectSettings.globalize_path(DIR)
	DirAccess.make_dir_recursive_absolute(_dir_abs)

	var act := ACT.new()
	add_child(act)
	act.call("open")
	await _shoot("kicker_activity")
	act.queue_free()
	await get_tree().create_timer(0.3).timeout

	var close := CLOSE.new()
	add_child(close)
	close.call("open", "这个月把该交的都交了。剩下的，是下个月再说的话。", 2, "")
	await _shoot("kicker_close")
	close.queue_free()
	await get_tree().create_timer(0.3).timeout

	var place := PLACE.new()
	add_child(place)
	place.call("show_confirm", {
		"id": "m2_library",
		"name": "树影书院二楼 · 旧档案架",
		"location": "D 区 树影书院二楼",
		"description": "翻一翻上一版翻车那张单。",
	}, 3, 1)
	await _shoot("kicker_place")
	get_tree().quit(0)


func _shoot(name: String) -> void:
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("%s -> %s" % [name, image.save_png("%s/%s.png" % [_dir_abs, name])])
