extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var s := size
	# Warm wooden training hall.
	draw_rect(Rect2(Vector2.ZERO, s), Color("#e9d6ad"))
	for y in range(0, int(s.y), 48):
		var stripe := Color("#e2c797") if int(y / 48) % 2 == 0 else Color("#ecd9b2")
		draw_rect(Rect2(0, y, s.x, 48), stripe)
		draw_line(Vector2(0, y), Vector2(s.x, y), Color("#c99f6a55"), 2.0)

	# Training-valley windows and greenery.
	draw_rect(Rect2(0, 0, s.x, 112), Color("#426a55"))
	draw_rect(Rect2(42, 18, 300, 72), Color("#9ed6cf"), true)
	draw_rect(Rect2(s.x - 342, 18, 300, 72), Color("#9ed6cf"), true)
	for x in [64.0, 156.0, 248.0, s.x - 320.0, s.x - 228.0, s.x - 136.0]:
		draw_line(Vector2(x, 18), Vector2(x, 90), Color("#f5efd9"), 7.0)

	# Top-down oval table, deliberately central and spacious for dice.
	draw_circle(Vector2(s.x * 0.5, s.y * 0.54), minf(s.x * 0.39, 500.0), Color("#845636"))
	draw_circle(Vector2(s.x * 0.5, s.y * 0.54), minf(s.x * 0.37, 474.0), Color("#bf8753"))
	draw_circle(Vector2(s.x * 0.5, s.y * 0.54), minf(s.x * 0.335, 430.0), Color("#4f806b"))
	draw_circle(Vector2(s.x * 0.5, s.y * 0.54), minf(s.x * 0.315, 404.0), Color("#5f947b"))
	for angle in range(0, 360, 30):
		var rad := deg_to_rad(float(angle))
		var center := Vector2(s.x * 0.5, s.y * 0.54)
		var p1 := center + Vector2(cos(rad), sin(rad)) * 405.0
		var p2 := center + Vector2(cos(rad), sin(rad)) * 428.0
		draw_line(p1, p2, Color("#e7c98c99"), 3.0)
