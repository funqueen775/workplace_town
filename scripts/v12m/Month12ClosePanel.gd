class_name Month12ClosePanel
extends CanvasLayer

## 12 个月首月 G 段：月末回顾。月末卡 + 继续，自动保存由外部做。
## 档案入口并在这张卡上：这个月记下的第一条就是它，所以"去看档案"跟着卡走，
## 不再单独弹一张讲解卡（首月已经够多卡片要读了）。

signal finished()
signal archive_requested()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER := Color("f6e6bd")
const INK := Color("4a2b1a")
const WOOD := Color("5b321f")
const BRICK := Color("b95035")
const CARD_SIZE := Vector2(900, 440)
const BODY_TOP := 160.0
const BODY_WIDTH := 788.0

var _root: Control
var _card: Panel
var _card_h := CARD_SIZE.y


func _ready() -> void:
	layer = 152
	_root = Control.new()
	_root.name = "Month12CloseRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.hide()
	get_viewport().size_changed.connect(_fit_card_to_viewport)


func open(card_text: String, month := 1, ledger := "") -> void:
	for child in _root.get_children():
		child.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_card = Panel.new()
	_card.size = CARD_SIZE
	_card.add_theme_stylebox_override("panel", _style(PAPER, WOOD, 6, 14))
	_root.add_child(_card)
	var kicker := _label("第 %d 月 · 月末回顾" % int(month), 30, BRICK, true)
	kicker.position = Vector2(56, 38)
	kicker.size = Vector2(700, 42)
	kicker.add_theme_color_override("font_color", BRICK)
	_card.add_child(kicker)
	var title := _label("这个月先到这儿", 40, INK, true)
	title.position = Vector2(56, 82)
	title.size = Vector2(780, 56)
	_card.add_child(title)
	var card := _label(card_text, 26, Color("5a3a24"))
	# 先开换行再给宽度、高度按实际行数往下排：月末正文可能是两段
	# （月度总结 + 本月补充），第三行不能再压到「这个月没有个人时间」上。
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_theme_constant_override("line_spacing", 8)
	card.position = Vector2(56, BODY_TOP)
	card.size = Vector2(BODY_WIDTH, 72)
	_card.add_child(card)
	var body_bottom := BODY_TOP + maxf(card.get_combined_minimum_size().y, 72.0)
	# 这个月的账：去了几处、行动点花掉多少、心情从几到几。
	# 玩家有权在月末当场看见自己花了什么，不用先去档案里找。
	var ledger_y := body_bottom + 10.0
	var book: Label = null
	if not ledger.is_empty():
		book = _label(ledger, 20, Color("7c6248"))
		book.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		book.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		book.position = Vector2(56, ledger_y)
		book.size = Vector2(BODY_WIDTH, 56)
		_card.add_child(book)
	var note_y := ledger_y
	if book != null:
		note_y += maxf(book.get_combined_minimum_size().y, 30.0) + 10.0
	var note := _label("进度已自动保存。", 18, Color("8a7253"))
	note.position = Vector2(56, note_y)
	note.size = Vector2(500, 26)
	_card.add_child(note)
	var archive_line := _label("这条已经写进你的档案，随时能翻。", 20, Color("5a3a24"))
	archive_line.position = Vector2(56, note_y + 30)
	archive_line.size = Vector2(560, 28)
	_card.add_child(archive_line)
	var archive := Button.new()
	archive.text = "打开档案"
	archive.position = Vector2(360, note_y + 64)
	archive.size = Vector2(220, 58)
	archive.focus_mode = Control.FOCUS_NONE
	archive.add_theme_font_override("font", FONT)
	archive.add_theme_font_size_override("font_size", 24)
	archive.add_theme_color_override("font_color", Color("5a3a24"))
	archive.add_theme_stylebox_override("normal", _style(Color("f1ddb0"), Color("9a6a42"), 3, 8))
	archive.add_theme_stylebox_override("hover", _style(Color("fff0cc"), Color("9a6a42"), 3, 8))
	archive.add_theme_stylebox_override("pressed", _style(Color("e2c894"), Color("9a6a42"), 3, 8))
	archive.pressed.connect(func(): archive_requested.emit())
	_card.add_child(archive)
	var next := Button.new()
	next.text = "继续"
	next.position = Vector2(620, note_y + 64)
	next.size = Vector2(220, 58)
	next.focus_mode = Control.FOCUS_NONE
	next.add_theme_font_override("font", FONT)
	next.add_theme_font_size_override("font_size", 26)
	next.add_theme_color_override("font_color", Color("fff4d5"))
	next.add_theme_stylebox_override("normal", _style(BRICK, Color("2e1a12"), 3, 8, 5))
	next.add_theme_stylebox_override("hover", _style(Color("cf6247"), Color("2e1a12"), 3, 8, 6))
	next.add_theme_stylebox_override("pressed", _style(Color("8f3a26"), Color("2e1a12"), 3, 8, 0))
	next.pressed.connect(func(): finished.emit())
	_card.add_child(next)
	_card_h = note_y + 64 + 78
	_card.size = Vector2(CARD_SIZE.x, _card_h)
	_fit_card_to_viewport()
	_root.show()


func _fit_card_to_viewport() -> void:
	if _card == null:
		return
	var view := get_viewport().get_visible_rect().size
	var available := view - Vector2(32, 32)
	var size := Vector2(CARD_SIZE.x, _card_h)
	var fit := minf(1.0, minf(available.x / size.x, available.y / size.y))
	fit = maxf(fit, 0.01)
	_card.scale = Vector2.ONE * fit
	_card.position = ((view - size * fit) * 0.5).round()


func close() -> void:
	_root.hide()


func _label(value: String, font_size: int, color: Color, bold := false) -> Label:
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
