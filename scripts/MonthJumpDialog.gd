class_name MonthJumpDialog
extends CanvasLayer

signal confirmed

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL_ART := preload("res://assets/对话框/角色对话框_空白.png")
const CONTINUE_ART := preload("res://assets/ui/rework_v1/task_book/18_追踪按钮底板.png")
const SKIP_ART := preload("res://assets/ui/rework_v1/task_book/20_推进按钮底板.png")
const INK := Color("63301d")

var current_month := 1
var target_month := 2


func _ready() -> void:
	layer = 160
	var overlay := Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.07, 0.03, 0.64)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var skin := AtlasTexture.new()
	skin.atlas = PANEL_ART
	skin.region = Rect2(PANEL_ART.get_width() * 0.02, PANEL_ART.get_height() * 0.20, PANEL_ART.get_width() * 0.96, PANEL_ART.get_height() * 0.58)
	var panel := NinePatchRect.new()
	panel.name = "MonthJumpArt"
	panel.texture = skin
	panel.patch_margin_left = 90
	panel.patch_margin_right = 90
	panel.patch_margin_top = 65
	panel.patch_margin_bottom = 65
	panel.size = Vector2(900, 360)
	var viewport_size := get_viewport().get_visible_rect().size
	var fit_scale := minf(1.0, minf((viewport_size.x - 40) / panel.size.x, (viewport_size.y - 40) / panel.size.y))
	panel.scale = Vector2.ONE * fit_scale
	panel.position = (viewport_size - panel.size * fit_scale) * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var title := _label("确认跳月", 36)
	title.position = Vector2(102, 45)
	title.size = Vector2(690, 55)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var warning := _label("你确定吗？还没有完成本月任务，会影响你最后的晋升，以及测评报告。", 24)
	warning.name = "WarningText"
	warning.position = Vector2(115, 112)
	warning.size = Vector2(670, 68)
	warning.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	panel.add_child(warning)

	var detail := _label("将从第 %d 月跳到第 %d 月；期间未完成的主线和自由活动会被跳过，不能补做。" % [current_month, target_month], 21)
	detail.position = Vector2(115, 182)
	detail.size = Vector2(670, 59)
	detail.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	panel.add_child(detail)

	var continue_button := _button("继续完成任务", CONTINUE_ART, Vector2(137, 265))
	continue_button.pressed.connect(queue_free)
	panel.add_child(continue_button)
	var skip_button := _button("确认跳过", SKIP_ART, Vector2(508, 265))
	skip_button.pressed.connect(func(): confirmed.emit(); queue_free())
	panel.add_child(skip_button)


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(value: String, art: Texture2D, at: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = Vector2(255, 70)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var background := TextureRect.new()
	var trimmed_art := AtlasTexture.new()
	trimmed_art.atlas = art
	trimmed_art.region = Rect2(art.get_width() * 0.10, art.get_height() * 0.22, art.get_width() * 0.80, art.get_height() * 0.56)
	background.texture = trimmed_art
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.size = button.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show_behind_parent = true
	button.add_child(background)
	return button
