class_name Month12ActivityPanel
extends CanvasLayer

## 12 个月首月 F 段：本周自由安排（1 个行动点）。
## 册子里的四条教学卡 + 三个选项（组内小工具 / 天台休息 / 暂不安排）。
## 只负责演出与选择，属性/行动点结算交给 WorkplaceTown。

signal option_chosen(option_id: String)
signal finished()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER := Color("f6e6bd")
const INK := Color("4a2b1a")
const WOOD := Color("5b321f")
const BRICK := Color("b95035")
const SECOND_BG := Color("f1ddb0")
const SECOND_EDGE := Color("9a6a42")
const CARD_SIZE := Vector2(1040, 660)

const TEACHING := [
	"行动点：用来安排一项需要主动投入时间的事。本周有 1 点。",
	"本周只选一项：做组内小工具会花 1 点；去天台休息会消耗 1 点，也会结束本周这次安排。",
	"其他地点会在认识更多人或推进剧情后开放。",
	"没用完的行动点不会留到下周；你也可以不安排活动，直接结束本月。",
]
const OPTIONS := [
	{
		"id": "m1_activity_tool", "title": "组内小工具", "cost": "消耗 1 点 · B 区",
		"desc": "去 B 区把重复检查做成一个小工具。",
		"outcome": "你花了些时间写完脚本。小赵试了一遍：“这个能用，发我一下。”",
	},
	{
		"id": "m1_activity_rooftop", "title": "天台休息", "cost": "消耗 1 点 · A 区",
		"desc": "去 A 区天台待一会儿。",
		"outcome": "你在天台待了会儿。回工位时，待办还在，但你没那么急着盯着它们。",
	},
	{
		"id": "m1_activity_skipped", "title": "暂不安排", "cost": "行动点月底清零",
		"desc": "先不做自由活动，结束本月。",
		"outcome": "你合上电脑，准备回去。",
	},
]

var _root: Control
var _card: Panel
var _option_buttons: Array[Button] = []


func _ready() -> void:
	layer = 152
	_root = Control.new()
	_root.name = "Month12ActivityRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.hide()


func open() -> void:
	_build()
	_root.show()


func close() -> void:
	_root.hide()


func _build() -> void:
	for child in _root.get_children():
		child.queue_free()
	_option_buttons.clear()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_card = Panel.new()
	_card.size = CARD_SIZE
	_card.add_theme_stylebox_override("panel", _style(PAPER, WOOD, 6, 14))
	var view := get_viewport().get_visible_rect().size
	_card.position = ((view - CARD_SIZE) * 0.5).round()
	_root.add_child(_card)

	var kicker := _label("本周自由安排 · 行动点 1", 30, BRICK, true)
	kicker.position = Vector2(48, 30)
	kicker.size = Vector2(620, 40)
	_card.add_child(kicker)
	var title := _label("这周先到这儿，剩下的时间你自己安排", 36, INK, true)
	title.position = Vector2(48, 72)
	title.size = Vector2(944, 50)
	_card.add_child(title)

	var y := 138.0
	for line in TEACHING:
		var row := _label("· " + line, 19, Color("634330"))
		row.position = Vector2(60, y)
		row.size = Vector2(920, 28)
		_card.add_child(row)
		y += 32.0

	y += 10.0
	for index in OPTIONS.size():
		var option: Dictionary = OPTIONS[index]
		var button := Button.new()
		button.position = Vector2(60, y)
		button.size = Vector2(920, 86)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", FONT)
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", INK)
		button.add_theme_stylebox_override("normal", _style(SECOND_BG, SECOND_EDGE, 3, 10, 4))
		button.add_theme_stylebox_override("hover", _style(Color("fff0cc"), SECOND_EDGE, 3, 10, 5))
		button.add_theme_stylebox_override("pressed", _style(Color("e2c894"), SECOND_EDGE, 3, 10, 0))
		button.pressed.connect(_on_option.bind(String(option["id"]), String(option["outcome"])))
		_card.add_child(button)
		_option_buttons.append(button)

		var head := _label("%s　%s" % [String(option["title"]), String(option["cost"])], 23, INK, true)
		head.position = Vector2(20, 10)
		head.size = Vector2(880, 34)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(head)
		var desc := _label(String(option["desc"]), 19, Color("7a5533"))
		desc.position = Vector2(20, 46)
		desc.size = Vector2(880, 30)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(desc)
		y += 98.0


func _on_option(option_id: String, outcome: String) -> void:
	option_chosen.emit(option_id)
	for button in _option_buttons:
		button.queue_free()
	_option_buttons.clear()
	var body := _label(outcome, 24, INK)
	body.position = Vector2(60, 470)
	body.size = Vector2(920, 80)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 8)
	_card.add_child(body)
	var next := Button.new()
	next.text = "继续"
	next.position = Vector2(760, 560)
	next.size = Vector2(220, 62)
	next.focus_mode = Control.FOCUS_NONE
	next.add_theme_font_override("font", FONT)
	next.add_theme_font_size_override("font_size", 28)
	next.add_theme_color_override("font_color", Color("fff4d5"))
	next.add_theme_stylebox_override("normal", _style(BRICK, Color("2e1a12"), 3, 8, 5))
	next.add_theme_stylebox_override("hover", _style(Color("cf6247"), Color("2e1a12"), 3, 8, 6))
	next.add_theme_stylebox_override("pressed", _style(Color("8f3a26"), Color("2e1a12"), 3, 8, 0))
	next.pressed.connect(func(): finished.emit())
	_card.add_child(next)


func _label(value: String, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(PAPER, 0.85))
		label.add_theme_constant_override("outline_size", 0)
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