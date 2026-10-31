extends Node

## 导览卡按钮三态实拍：把鼠标压到「下一步」上，看字还认不认得出来。
## 用法：<godot> --path <proj> --resolution 1280x720 res://tools/tour_hover_shot.tscn

const SHOT_DIR := "res://test_artifacts/tour_state"
const HUD_TOUR := preload("res://scripts/ui/HudTour.gd")

var _tour: CanvasLayer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("b9c6a4")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 目标块：假装是左上那张职位卡，说明卡落在它下面
	var target := ColorRect.new()
	target.color = Color("6f4f33")
	target.position = Vector2(40, 40)
	target.size = Vector2(440, 96)
	add_child(target)

	_tour = HUD_TOUR.new()
	add_child(_tour)
	_tour.start([
		{
			"rect": Rect2(40, 40, 440, 96),
			"title": "左上 · 你的岗位",
			"body": "职位卡可以打开员工档案，查看岗位和评估安排。先认识入口，结束导览后再看。",
			"place": "below",
		},
		{"rect": Rect2(40, 40, 440, 96), "title": "第二页", "body": "占位。", "place": "below"},
	])
	await _wait(0.6)
	var next := _find_button("下一步")
	if next == null:
		print("NO_BUTTON")
		get_tree().quit(1)
		return
	for node in _tour.find_children("*", "Label", true, false):
		var label := node as Label
		if label.text.begins_with("职位卡"):
			print("body size=%s autowrap=%d lines=%d" % [label.size, label.autowrap_mode, label.get_line_count()])
	print("resolved font_color=%s hover=%s pressed=%s" % [
		next.get_theme_color("font_color"),
		next.get_theme_color("font_hover_color"),
		next.get_theme_color("font_pressed_color"),
	])
	Input.warp_mouse(Vector2(8, 8))
	await _wait(0.4)
	await _shot("01_normal")
	var center: Vector2 = next.get_global_rect().get_center()
	Input.warp_mouse(center)
	for i in 10:
		if next.is_hovered():
			break
		var motion := InputEventMouseMotion.new()
		motion.position = center
		motion.global_position = center
		motion.relative = Vector2(1, 0)
		get_viewport().push_input(motion, true)
		await _wait(0.1)
	print("hovered=%s" % next.is_hovered())
	await _shot("02_hover")
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = center
	down.global_position = center
	get_viewport().push_input(down, true)
	await _wait(0.3)
	print("draw_mode=%d (HOVER_PRESSED=%d)" % [next.get_draw_mode(), BaseButton.DRAW_HOVER_PRESSED])
	await _shot("03_pressed")
	print("TOUR_SHOT_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _find_button(text: String) -> Button:
	for node in _tour.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, shot_name])
	print("shot %s -> %s" % [shot_name, image.save_png(path)])
