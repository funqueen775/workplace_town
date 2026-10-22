class_name DiceButton
extends Button

var die_value := 1
var is_selected := false
var is_hidden := false
var hovered := false


func _ready() -> void:
	custom_minimum_size = Vector2(76, 76)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(func(): hovered = true; queue_redraw())
	mouse_exited.connect(func(): hovered = false; queue_redraw())


func configure(value: int, selected: bool, hidden: bool) -> void:
	die_value = clampi(value, 1, 6)
	is_selected = selected
	is_hidden = hidden
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(4, 4, size.x - 8, size.y - 8)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#263a5b") if is_hidden else Color("#fff4d9")
	if hovered and not disabled:
		style.bg_color = Color("#314d78") if is_hidden else Color("#fff9e9")
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_color = Color("#f5c451") if is_selected else Color("#6e4a35")
	var width := 6 if is_selected else 3
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.shadow_color = Color("#34251f55")
	style.shadow_size = 5
	style.shadow_offset = Vector2(2, 4)
	draw_style_box(style, rect)

	if is_hidden:
		_draw_paw(rect)
	else:
		_draw_pips(rect)


func _draw_pips(rect: Rect2) -> void:
	var center := rect.get_center()
	var dx := rect.size.x * 0.23
	var dy := rect.size.y * 0.23
	var positions := {
		"tl": center + Vector2(-dx, -dy),
		"tr": center + Vector2(dx, -dy),
		"ml": center + Vector2(-dx, 0),
		"c": center,
		"mr": center + Vector2(dx, 0),
		"bl": center + Vector2(-dx, dy),
		"br": center + Vector2(dx, dy),
	}
	var keys: Array[String] = []
	match die_value:
		1: keys = ["c"]
		2: keys = ["tl", "br"]
		3: keys = ["tl", "c", "br"]
		4: keys = ["tl", "tr", "bl", "br"]
		5: keys = ["tl", "tr", "c", "bl", "br"]
		6: keys = ["tl", "ml", "bl", "tr", "mr", "br"]
	for key in keys:
		draw_circle(positions[key], 5.5, Color("#5b392c"))


func _draw_paw(rect: Rect2) -> void:
	var center := rect.get_center() + Vector2(0, 6)
	var paw_color := Color("#8ec1dc")
	draw_circle(center, 13, paw_color)
	draw_circle(center + Vector2(-17, -15), 6, paw_color)
	draw_circle(center + Vector2(-6, -22), 6, paw_color)
	draw_circle(center + Vector2(7, -22), 6, paw_color)
	draw_circle(center + Vector2(18, -15), 6, paw_color)
