class_name MonthStartPanel
extends CanvasLayer

signal continued()
signal direct_requested()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER := Color("f6e6bd")
const INK := Color("4a2b1a")
const WOOD := Color("5b321f")
const BRICK := Color("b95035")
const CARD_SIZE := Vector2(900, 420)

var _root: Control
var _card: Panel


func _ready() -> void:
	layer = 152
	_root = Control.new()
	_root.name = "MonthStartRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.hide()
	get_viewport().size_changed.connect(_fit_card_to_viewport)


## today_lines：本月第一屏自带的"今天"三行（4.17）。有就照它写，没有才用 intro。
func open(month: int, destination: String, first_task: String, intro: String, today_lines: Array = [], allow_direct := false) -> void:
	for child in _root.get_children():
		child.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.43)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_card = Panel.new()
	_card.size = CARD_SIZE
	_card.add_theme_stylebox_override("panel", _style(PAPER, WOOD, 6, 14))
	_root.add_child(_card)
	_fit_card_to_viewport()

	var kicker_text := "第一天 · 入职" if month == 1 else "第 %d 月 · 月初" % month
	var kicker := _label(kicker_text, 36, BRICK)
	kicker.position = Vector2(48, 34)
	kicker.size = Vector2(700, 46)
	_card.add_child(kicker)

	var title_text := "欢迎来到小镇" if month == 1 else "新的一月，回到日常"
	var title := _label(title_text, 54, INK)
	title.position = Vector2(48, 84)
	title.size = Vector2(804, 72)
	_card.add_child(title)

	# 正文区：首月是一句 intro，其余十一个月是"今天"三行。两种都落在同一条左基线、同一块高度里，
	# 换月只换字，不换版面。
	var body_top := 168.0
	if today_lines.is_empty():
		var body := _label(intro, 32, Color("5a3a24"))
		body.position = Vector2(48, body_top)
		body.size = Vector2(804, 88)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_constant_override("line_spacing", 8)
		_card.add_child(body)
	else:
		# "今天"三行：谁叫你去、带什么、今天什么局面。一行一行摆，收在页脚那条淡线上面。
		var y := body_top
		for i in today_lines.size():
			var line := _label(String(today_lines[i]), 32, Color("5a3a24"))
			line.position = Vector2(48, y)
			line.size = Vector2(804, 40)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_card.add_child(line)
			y += 40.0

	# 页脚：淡线隔开正文，右边是同一个按钮，十二个月共用这一条基线。
	# 正文只有一句的月份（首月、缺"今天"三行的月份）才在左边补"今天的第一站 / 地点 / 任务"；
	# 正文已经交代了去哪儿做什么的月份（"今天"三行）不再重复 —— 重复的那一份还可能是月首开场地点，
	# 跟三行里说的去处对不上（如第 2 月：开场在 B 区工位，当天要去 A 区评审室）。
	var show_footer_text := today_lines.is_empty()
	var footer_y := 316.0
	var rule_y := 308.0
	if show_footer_text and allow_direct:
		# 多一个"直接开始"按钮时，文字块整体上移，给左下角腾位置（当前没有调用方走这条）。
		footer_y = 248.0
		rule_y = 240.0
	var rule := ColorRect.new()
	rule.color = Color(0.29, 0.17, 0.10, 0.09)
	rule.position = Vector2(48, rule_y)
	rule.size = Vector2(804, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(rule)
	if show_footer_text:
		# 小标题跟地点同一行、任务另起一行：竖排三行会在两行正文下压到卡片底边。
		var stop := _label("今天的第一站", 20, Color("8a7253"))
		stop.position = Vector2(48, footer_y)
		stop.size = Vector2(140, 44)
		_card.add_child(stop)
		var place := _label(destination, 30, INK)
		place.position = Vector2(196, footer_y)
		place.size = Vector2(360, 44)
		place.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_card.add_child(place)
		var task := _label(first_task, 24, Color("7c6248"))
		task.position = Vector2(48, footer_y + 50)
		task.size = Vector2(500, 36)
		task.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_card.add_child(task)

	var button := Button.new()
	button.text = "出门走走" if allow_direct else "开始这一天"
	button.position = Vector2(572, 326)
	button.size = Vector2(280, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color("fff4d5"))
	button.add_theme_stylebox_override("normal", _style(BRICK, Color("2e1a12"), 3, 8, 5))
	button.add_theme_stylebox_override("hover", _style(Color("cf6247"), Color("2e1a12"), 3, 8, 6))
	button.add_theme_stylebox_override("pressed", _style(Color("8f3a26"), Color("2e1a12"), 3, 8, 0))
	button.pressed.connect(func(): continued.emit())
	_card.add_child(button)
	if allow_direct:
		var direct := Button.new()
		direct.text = "不走了，直接开始"
		direct.position = Vector2(48, 322)
		direct.size = Vector2(250, 56)
		direct.focus_mode = Control.FOCUS_NONE
		direct.add_theme_font_override("font", FONT)
		direct.add_theme_font_size_override("font_size", 24)
		direct.add_theme_color_override("font_color", Color("5b321f"))
		direct.add_theme_stylebox_override("normal", _style(PAPER, WOOD, 2, 8, 3))
		direct.add_theme_stylebox_override("hover", _style(Color("ffeccb"), WOOD, 2, 8, 4))
		direct.add_theme_stylebox_override("pressed", _style(Color("e8d3a8"), WOOD, 2, 8, 0))
		direct.pressed.connect(func(): direct_requested.emit())
		_card.add_child(direct)
	_root.show()


func _fit_card_to_viewport() -> void:
	if _card == null:
		return
	var view := get_viewport().get_visible_rect().size
	var available := view - Vector2(32, 32)
	var fit := minf(1.0, minf(available.x / CARD_SIZE.x, available.y / CARD_SIZE.y))
	fit = maxf(fit, 0.01)
	_card.scale = Vector2.ONE * fit
	_card.position = ((view - CARD_SIZE * fit) * 0.5).round()


func close() -> void:
	_root.hide()


func is_open() -> bool:
	return _root.visible


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _style(background: Color, border: Color, width: int, radius: int, bevel := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	if bevel > 0:
		style.shadow_color = Color(border.r, border.g, border.b, 0.5)
		style.shadow_size = 2
		style.shadow_offset = Vector2(0, bevel)
	return style
