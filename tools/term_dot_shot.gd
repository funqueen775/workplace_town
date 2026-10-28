extends Node

## 行话小圆点样张：同一句台词，拍"没点"和"点了"两张。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/term_dot_shot.tscn

const PANEL := preload("res://scripts/StoryEventPanel.gd")
const DIR := "res://test_artifacts/v12m_terms"

var _panel


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_panel = PANEL.new()
	add_child(_panel)
	await get_tree().create_timer(0.4).timeout
	_panel.call("present", {
		"id": "TERM_SHOT",
		"month": 11,
		"day": 1,
		"hour": 10,
		"actTitle": "第 11 月",
		"situation": "weak",
		"durationMinutes": 45,
		"dateStyle": "xun",
		"phase": "mid",
		"title": "材料上的那个数",
		"location": "A 区会议室",
		"locationId": "A",
		"cast": [],
		"speakers": {},
		"choices": [],
		"beats": [
			{"type": "say", "speaker": "老周",
			 "text": "这份材料的口径没写清，40 个人的结果被人当成所有人都会这样。",
			 "emphasis": ["40 个人的结果被人当成所有人都会这样"]},
		],
	})
	await get_tree().create_timer(1.2).timeout
	# present() 停在"这一场要演什么"的入场屏，点一下才进第一拍。
	_panel.call("_next_beat")
	await get_tree().create_timer(2.2).timeout
	await _shot("term_dot_idle")
	var dot := _find(_panel, "TermDot")
	if dot == null:
		print("NO_DOT 小圆点没挂上")
	else:
		dot.emit_signal("pressed")
		await get_tree().create_timer(0.5).timeout
		await _shot("term_dot_open")
	print("TERM_SHOT_DONE")
	get_tree().quit(0)


func _find(root: Node, node_name: String) -> Node:
	for child in root.get_children():
		if child.name == node_name:
			return child
		var found := _find(child, node_name)
		if found != null:
			return found
	return null


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
