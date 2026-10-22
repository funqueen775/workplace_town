class_name FxTrails
extends Control

var attack_point := Vector2(470, 338)
var defense_point := Vector2(810, 338)
var center_point := Vector2(640, 338)
var intensity := 0.0
var result_mode := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_points(attack: Vector2, defense: Vector2) -> void:
	attack_point = attack
	defense_point = defense
	queue_redraw()


func set_impact(value: float, mode: String = "") -> void:
	intensity = value
	result_mode = mode
	queue_redraw()


func _draw() -> void:
	if intensity <= 0.0:
		return
	var warm := Color(1.0, 0.39, 0.23, 0.24 * intensity)
	var cool := Color(0.25, 0.75, 1.0, 0.24 * intensity)
	for width in [26.0, 14.0, 5.0]:
		var alpha_scale := 0.25 if width > 20.0 else (0.5 if width > 10.0 else 1.0)
		draw_line(attack_point, center_point, Color(warm, warm.a * alpha_scale), width, true)
		draw_line(defense_point, center_point, Color(cool, cool.a * alpha_scale), width, true)
	draw_circle(center_point, 48.0 * intensity, Color(1.0, 0.92, 0.60, 0.18 * intensity))
	draw_circle(center_point, 19.0 * intensity, Color(1.0, 0.98, 0.82, 0.75 * intensity))
	if result_mode == "hit":
		for offset in [-18.0, 0.0, 18.0]:
			draw_line(
				center_point + Vector2(-62 + offset, 72),
				center_point + Vector2(44 + offset, -76),
				Color(1.0, 0.34, 0.22, 0.7 * intensity),
				5.0,
				true
			)
	elif result_mode == "block":
		for radius in [35.0, 55.0, 78.0]:
			draw_arc(
				center_point,
				radius * intensity,
				0.0,
				TAU,
				48,
				Color(0.45, 0.88, 1.0, 0.55 * intensity),
				4.0,
				true
			)
