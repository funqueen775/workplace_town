class_name HudTour
extends CanvasLayer

## 进镇后的四角导览：只解释「这块是干什么的」，不替玩家点。
## 每一步给一个目标矩形，四块压暗板把周围压黑，目标留亮；
## 说明卡贴在目标旁边，下一步/跳过都由玩家决定。
##
## 为什么不用全屏压暗 + 裁洞：Control 没有现成的圆角裁洞，
## 四块矩形拼出来的洞在 16:9 下更稳，也不会把 HUD 的点击层弄乱。

signal finished()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER := Color("fff9ea")
const INK := Color("3a2a1d")
const BRICK := Color("a35a3a")
const GOLD := Color("f2c14e")
const DIM := Color(0.02, 0.03, 0.05, 0.62)

var _root: Control
var _content: Control
var _steps: Array = []
var _index := 0
## 说明卡的基准尺寸（16:9 桌面下的样子）。手机上会整体乘 _ui_scale()。
var _caption_size := Vector2(520, 214)
var _busy := false


func _ready() -> void:
	# 190 是小屋提醒条（CanvasLayer.layer=190）的层号：导览必须压在提醒条上面，
	# 否则「跟着王哥走」会把说明卡左半边盖住。
	layer = 200
	_root = Control.new()
	_root.name = "HudTourRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.hide()


func start(steps: Array) -> void:
	_steps = steps
	_index = 0
	_busy = false
	_root.show()
	_show_step()


func is_active() -> bool:
	return _root != null and _root.visible


func advance() -> void:
	_next()


func finish() -> void:
	if not is_active():
		return
	_root.hide()
	_clear_step()
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		finish()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_next()
		get_viewport().set_input_as_handled()


func _next() -> void:
	if _busy:
		return
	_index += 1
	if _index >= _steps.size():
		finish()
		return
	_show_step()


func _clear_step() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.queue_free()
	_content = null


func _show_step() -> void:
	_clear_step()
	var step: Dictionary = _steps[_index]
	var view := get_viewport().get_visible_rect().size
	var target: Rect2 = step.get("rect", Rect2())
	_content = Control.new()
	_content.name = "Step"
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content)

	_add_dim_panels(view, target)
	_add_hole_blocker(target)
	_add_ring(target)
	_add_caption(view, target, step)


func _add_dim_panels(view: Vector2, target: Rect2) -> void:
	var rects := [
		Rect2(0, 0, view.x, maxf(target.position.y, 0)),
		Rect2(0, target.end.y, view.x, maxf(view.y - target.end.y, 0)),
		Rect2(0, target.position.y, maxf(target.position.x, 0), maxf(target.size.y, 0)),
		Rect2(target.end.x, target.position.y, maxf(view.x - target.end.x, 0), maxf(target.size.y, 0)),
	]
	for rect in rects:
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var dim := ColorRect.new()
		dim.color = DIM
		dim.position = rect.position
		dim.size = rect.size
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		_content.add_child(dim)


func _add_hole_blocker(target: Rect2) -> void:
	var blocker := Control.new()
	blocker.position = target.position
	blocker.size = target.size
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_content.add_child(blocker)


func _add_ring(target: Rect2) -> void:
	var ring := Panel.new()
	ring.position = target.position - Vector2(6, 6)
	ring.size = target.size + Vector2(12, 12)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.28)
	style.shadow_size = 8
	ring.add_theme_stylebox_override("panel", style)
	_content.add_child(ring)
	var tween := ring.create_tween().set_loops()
	tween.tween_property(ring, "modulate:a", 0.55, 0.65).set_trans(Tween.TRANS_SINE)
	tween.tween_property(ring, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE)


## 视口短边越大（手机竖屏时 Godot 的 expand 会把视口拉得很高），界面在屏幕上越小。
## 按短边换算一个倍数：桌面 1920x1080 恒为 1，手机竖屏约 1.8。再卡一次宽度，别顶出屏幕。
func _ui_scale(view: Vector2) -> float:
	var scale_by_short_side := clampf(minf(view.x, view.y) / 1080.0, 1.0, 2.0)
	var scale_by_width := (view.x - 32.0) / _caption_size.x
	return maxf(1.0, minf(scale_by_short_side, scale_by_width))


func _add_caption(view: Vector2, target: Rect2, step: Dictionary) -> void:
	var card_scale := _ui_scale(view)
	var card := _caption_size * card_scale
	var place := String(step.get("place", "below"))
	var at := Vector2.ZERO
	match place:
		"left":
			at = Vector2(target.position.x - card.x - 18.0, target.position.y)
		"above":
			at = Vector2(target.end.x - card.x, target.position.y - card.y - 18.0)
		_:
			at = Vector2(target.position.x, target.end.y + 18.0)
	at.x = clampf(at.x, 16.0, maxf(16.0, view.x - card.x - 16.0))
	at.y = clampf(at.y, 16.0, maxf(16.0, view.y - card.y - 16.0))

	var panel := Panel.new()
	panel.position = at
	panel.size = _caption_size
	# 卡片整体按 card_scale 放大（pivot 在左上，所以 position 还是卡片左上角）。
	panel.pivot_offset = Vector2.ZERO
	panel.scale = Vector2.ONE * card_scale
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color("58321f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)
	_content.add_child(panel)

	var title := _label(String(step.get("title", "")), 26, INK, true)
	title.position = Vector2(22, 14)
	title.size = Vector2(_caption_size.x - 44, 32)
	panel.add_child(title)

	var body := _label(String(step.get("body", "")), 19, Color("5a4635"), false)
	# 先开自动换行再给宽度：顺序反了的话 size 会先被「整句不折行」的最小宽度顶大，
	# 后面再开换行也不会缩回来，末尾几个字就跑到卡片外面去了。
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(22, 52)
	body.size = Vector2(_caption_size.x - 44, 96)
	body.add_theme_constant_override("line_spacing", 6)
	panel.add_child(body)

	var skip := Button.new()
	skip.text = "跳过"
	skip.flat = true
	skip.focus_mode = Control.FOCUS_NONE
	skip.position = Vector2(20, _caption_size.y - 54)
	skip.size = Vector2(104, 40)
	skip.add_theme_font_override("font", FONT)
	skip.add_theme_font_size_override("font_size", 18)
	# 原来这颗"跳过"是整张卡上最小也最浅的字，手机上基本看不清：字号加到和正文同级，
	# 颜色也压深一档（原来是 8a7259，浅棕在米色纸上对比不够）。
	skip.add_theme_color_override("font_color", Color("6f5a44"))
	skip.add_theme_color_override("font_hover_color", Color("4a3626"))
	skip.add_theme_color_override("font_pressed_color", Color("4a3626"))
	skip.pressed.connect(finish)
	panel.add_child(skip)

	var next := Button.new()
	next.text = "知道了" if _index >= _steps.size() - 1 else "下一步"
	next.focus_mode = Control.FOCUS_NONE
	next.position = Vector2(_caption_size.x - 152, _caption_size.y - 58)
	next.size = Vector2(132, 44)
	next.add_theme_font_override("font", FONT)
	next.add_theme_font_size_override("font_size", 19)
	# 只给 font_color 不够：Godot 自带主题把 hover/pressed 的字色设成接近白，
	# 一碰上去「下一步」就在浅金底上消失。三态都要按墨色写死。
	next.add_theme_color_override("font_color", INK)
	next.add_theme_color_override("font_hover_color", INK)
	next.add_theme_color_override("font_pressed_color", INK)
	next.add_theme_color_override("font_hover_pressed_color", INK)
	next.add_theme_stylebox_override("normal", _button_style(Color("efd9a9")))
	next.add_theme_stylebox_override("hover", _button_style(Color("f6e3b4")))
	next.add_theme_stylebox_override("pressed", _button_style(Color("e3c483")))
	# 鼠标按住时 Godot 走的是 hover_pressed，不一起换就会闪回默认灰底。
	next.add_theme_stylebox_override("hover_pressed", _button_style(Color("e3c483")))
	next.pressed.connect(_next)
	panel.add_child(next)

	var count := _label("%d / %d" % [_index + 1, _steps.size()], 15, Color("a35a3a"), true)
	count.position = Vector2(_caption_size.x - 94, 16)
	count.size = Vector2(72, 26)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(count)


func _label(value: String, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.18))
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 1)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("a97a4d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style
