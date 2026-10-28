extends Node

## 讲解卡样张：直接拿第 3 月水巷那张卡的文案和实拍配图，走真面板渲染一遍。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/place_card_shot.tscn

const PANEL := preload("res://scripts/v12m/PlaceVisitPanel.gd")
const SHOT := "res://test_artifacts/v12m_doors/place_card_waterway.png"

var _panel


func _ready() -> void:
	_panel = PANEL.new()
	add_child(_panel)
	await get_tree().create_timer(0.4).timeout
	_panel.show_unlock({
		"id": "m3_waterway",
		"name": "水巷外摆",
		"locationId": "C",
		"card": {
			"title": "水巷外摆",
			"lines": [
				"谈完客户的人都在这排坐着。",
				"坐一下午不加分，也不掉东西。",
				"去坐吧台前那把高脚凳。",
			],
			"shots": ["place_card_waterway_1.png"],
			"pages": 1,
		},
	})
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("card -> %s" % image.save_png(ProjectSettings.globalize_path(SHOT)))
	get_tree().quit(0)
