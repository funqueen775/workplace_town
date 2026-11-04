extends Node2D

## 轻量程序化传送门：不依赖贴图，在地图上标出可自动进入的室内场景入口。
## 十二个月首月把这扇门当「活动门」用。
##
## 两种状态，全靠门自己的颜色说：
##   开着的 = 金色光环 + 转动的弧 + 外圈光点，在暖色底图上很抓眼；
##   不开放 = 整扇门压成灰、弧和光点全停，走近了也只给一句"这个月还不能进"。
## 以前不开放是在门上贴一条胶带 + 盖一枚红章，玩家反馈两件事：
## 一是贴纸和手绘小镇不是一个东西（像贴图错误），二是剧情正要把人带到这门口，
## 门上却贴着"禁止进入"。所以贴纸整套删掉，改成压灰。

var highlighted := false
var sealed := false
var _elapsed := 0.0
## 压灰进度 0→1，切换用 0.28 秒过渡：门"暗下去"要看得见，但不能闪。
var _mute := 0.0
## 刚开门的瞬间打一下高光，让玩家知道是这扇门变了，不是自己眼花。
var _open_flash := 0.0


func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()


func is_sealed() -> bool:
	return sealed


## 封 / 开。封 = 压灰；开 = 灰退回金色，顺手闪一下。
func set_sealed(value: bool) -> void:
	if sealed == value:
		return
	sealed = value
	if not sealed:
		_open_flash = 1.0


func _process(delta: float) -> void:
	_elapsed += delta
	rotation = sin(_elapsed * 1.8) * 0.035
	var target := 1.0 if sealed else 0.0
	if not is_equal_approx(_mute, target):
		_mute = move_toward(_mute, target, delta / 0.28)
	if _open_flash > 0.0:
		_open_flash = maxf(0.0, _open_flash - delta / 0.45)
	queue_redraw()


func _mix(a: Color, b: Color, weight: float) -> Color:
	return a.lerp(b, weight)


func _draw() -> void:
	var muted := _mute
	# 灰的那一档：把金色整体压到石板灰，饱和度砍掉，亮度也压下去。
	var accent := _mix(Color("ffe18a"), Color("9d9184"), muted)
	var deep_gold := _mix(Color("d88922"), Color("6f6558"), muted)
	var core := _mix(Color("ffd56d"), Color("8b8177"), muted)
	var heart := _mix(Color("fff0b5"), Color("a49a8e"), muted)
	var glow_alpha := ((0.96 if highlighted else 0.78) if not sealed else (0.34 if highlighted else 0.26))
	glow_alpha = lerpf(0.96 if highlighted else 0.78, glow_alpha, muted)
	glow_alpha += _open_flash * 0.35
	# 开着的门在呼吸，压灰的门不动：静止本身就是"现在别碰"。
	var pulse := 1.0 + sin(_elapsed * 3.0) * 0.07 * (1.0 - muted) + _open_flash * 0.12
	# 整体缩成纵向椭圆，避免与小镇的暖色手绘风格冲突。
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.58, 1.38))
	draw_circle(Vector2.ZERO, 42.0 * pulse, Color(accent, lerpf(0.14, 0.1, muted)))
	draw_circle(Vector2.ZERO, 33.0 * pulse, Color(deep_gold, lerpf(0.52, 0.4, muted)))
	draw_circle(Vector2.ZERO, 25.0 * pulse, Color(core, lerpf(0.88, 0.6, muted)))
	draw_circle(Vector2.ZERO, 16.0 * pulse, Color(heart, lerpf(0.74, 0.5, muted)))
	for ring_index in 4:
		var radius := 22.0 + ring_index * 5.6
		var direction := 1.0 if ring_index % 2 == 0 else -1.0
		var spin := _elapsed * (1.0 - muted)
		var start := spin * direction * (1.7 + ring_index * 0.22) + ring_index * 1.3
		var span := 1.55 + sin(_elapsed * 2.0 + ring_index) * 0.22
		draw_arc(Vector2.ZERO, radius * pulse, start, start + span, 20, Color(accent, glow_alpha - ring_index * 0.12), 2.8, true)
	if muted < 0.98:
		for particle_index in 6:
			var angle := _elapsed * (1.3 + particle_index * 0.08) + particle_index * TAU / 6.0
			var radius := 33.0 + sin(_elapsed * 2.6 + particle_index) * 5.0
			var point := Vector2(cos(angle), sin(angle) * 0.62) * radius * pulse
			draw_circle(point, 2.4 if highlighted else 1.8, Color(accent, 0.9 * (1.0 - muted)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
