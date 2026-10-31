extends Control

const PHONE_PANEL := preload("res://scripts/v12m/PhoneInboxPanel.gd")
const BG_TEXTURE := preload("res://assets/场景内部图/熊起东方总部.png")
const SHOT_DIR := "res://test_artifacts/v12m_phone"

var _panel: CanvasLayer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.name = "OfficeBackground"
	bg.texture = BG_TEXTURE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.modulate = Color(0.82, 0.78, 0.72, 1)
	add_child(bg)

	var dim := ColorRect.new()
	dim.name = "StageDim"
	dim.color = Color(0.02, 0.02, 0.04, 0.42)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = PHONE_PANEL.new()
	add_child(_panel)
	await _run()


func _run() -> void:
	await _wait(0.20)
	_panel.call("open_tutorial")
	await _wait(0.45)
	await _shot("00_tutorial_enter")
	await _wait(0.70)
	await _shot("01_tutorial")

	_panel.call("open_phone")
	await _wait(0.55)
	await _shot("02_phone_open")

	var reply := _find_button(_panel, "收到")
	if reply != null:
		reply.pressed.emit()
	await _wait(0.40)
	await _shot("03_phone_replied")

	_panel.call("close_phone")
	await _wait(0.45)
	await _shot("04_after_close")

	print("V12M_PHONE_SHOTS_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _find_button(root: Node, text: String) -> Button:
	for child in root.get_children():
		if child is Button and child.text == text and not child.is_queued_for_deletion():
			return child as Button
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	var error := image.save_png(path)
	print("phone shot %s -> %s (%s)" % [name, path, error])
