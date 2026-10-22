extends Node2D

## 轻量程序化传送门：不依赖贴图，在地图上标出可自动进入的室内场景入口。
var highlighted := false
var _elapsed := 0.0


func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	rotation = sin(_elapsed * 1.8) * 0.035
	queue_redraw()


func _draw() -> void:
	var accent := Color("ffe18a") if highlighted else Color("f6bd46")
	var deep_gold := Color("d88922")
	var glow_alpha := 0.96 if highlighted else 0.78
	var pulse := 1.0 + sin(_elapsed * 3.0) * 0.07
	# 整体缩成纵向椭圆，避免与小镇的暖色手绘风格冲突。
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.58, 1.38))
	draw_circle(Vector2.ZERO, 42.0 * pulse, Color(accent, 0.14))
	draw_circle(Vector2.ZERO, 33.0 * pulse, Color(deep_gold, 0.52))
	draw_circle(Vector2.ZERO, 25.0 * pulse, Color("ffd56d", 0.88))
	draw_circle(Vector2.ZERO, 16.0 * pulse, Color("fff0b5", 0.74))
	for ring_index in 4:
		var radius := 22.0 + ring_index * 5.6
		var direction := 1.0 if ring_index % 2 == 0 else -1.0
		var start := _elapsed * direction * (1.7 + ring_index * 0.22) + ring_index * 1.3
		var span := 1.55 + sin(_elapsed * 2.0 + ring_index) * 0.22
		draw_arc(Vector2.ZERO, radius * pulse, start, start + span, 20, Color(accent, glow_alpha - ring_index * 0.12), 2.8, true)
	for particle_index in 6:
		var angle := _elapsed * (1.3 + particle_index * 0.08) + particle_index * TAU / 6.0
		var radius := 33.0 + sin(_elapsed * 2.6 + particle_index) * 5.0
		var point := Vector2(cos(angle), sin(angle) * 0.62) * radius * pulse
		draw_circle(point, 2.4 if highlighted else 1.8, Color(accent, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
