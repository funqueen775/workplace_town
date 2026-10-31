extends Node

## 月初卡样张：按第 2 月真实文案渲染一张"新的一月，回到日常"，用来看眉标那行字够不够大。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/month_start_card_shot.tscn

const PANEL := preload("res://scripts/v12m/MonthStartPanel.gd")
const SHOT := "res://test_artifacts/v12m_doors/month_start_card_m2.png"

var _panel


func _ready() -> void:
	_panel = PANEL.new()
	add_child(_panel)
	await get_tree().create_timer(0.4).timeout
	_panel.open(
		2,
		"A 区评审室",
		"带两张图过去",
		"",
		[
			"王哥让你带两张图去 A 区评审室。",
			"自研和开源各一份，写清依赖和退路。",
			"周三上午，陈工先到，他不等你。",
		]
	)
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/v12m_doors"))
	print("card -> %s" % image.save_png(ProjectSettings.globalize_path(SHOT)))
	get_tree().quit(0)
