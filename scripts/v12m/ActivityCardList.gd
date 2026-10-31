extends CanvasLayer

## 自由活动卡列表：进区之后，一屏一列、每行一张原尺寸卡（2026-10-31）。
##
## 为什么另开一屏而不是塞进右侧窄栏：新画的卡是 1200×330 的整卡，区名、缩略图、
## 活动名、一句话、消耗全烙在图里；窄栏只有 470 宽，缩进去字就看不清了。
##
## 卡片只负责"选哪件"：点一下发 activity_selected，结算仍在原来的到访页。
## 没有卡面的活动退回文字行，不塌、不留白框。

signal activity_selected(id: String)
signal closed()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER := Color("fdf6e6")
const INK := Color("3a2a1d")
const BRICK := Color("a35a3a")

const CARD_W := 1100.0
const CARD_GAP := 20.0

var _root: Control
var _panel: Panel
var _column: VBoxContainer
var _scroll: ScrollContainer
var _title: Label
var _points: Label
var _footer: Label
var _empty: Label


func _ready() -> void:
	layer = 150
	_root = Control.new()
	_root.name = "ActivityCardListRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	_root.add_child(dim)

	_panel = Panel.new()
	_panel.position = Vector2(140, 60)
	_panel.size = Vector2(1240, 960)
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color("c9a06a")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	_title = _label("能进去的地方", 34, INK, true)
	_title.position = Vector2(40, 22)
	_title.size = Vector2(760, 44)
	_panel.add_child(_title)

	_points = _label("", 20, Color("7a5a40"))
	_points.position = Vector2(40, 66)
	_points.size = Vector2(760, 30)
	_panel.add_child(_points)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(36, 104)
	_scroll.size = Vector2(1168, 760)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(_scroll)

	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override("separation", 18)
	_scroll.add_child(_column)

	_footer = _label("点一张卡进去；Esc 或点旁边关掉", 18, Color("9a8066"))
	_footer.position = Vector2(40, 880)
	_footer.size = Vector2(900, 28)
	_panel.add_child(_footer)

	_empty = _label("这个区现在还没有能去的地方。", 24, Color("7a5a40"))
	_empty.position = Vector2(40, 140)
	_empty.size = Vector2(900, 40)
	_empty.visible = false
	_panel.add_child(_empty)

	_root.hide()


func open(zone_title: String, items: Array, points_text := "") -> void:
	_title.text = "%s · 能进去的地方" % zone_title
	_points.text = points_text
	for child in _column.get_children():
		child.queue_free()
	_empty.visible = items.is_empty()
	_scroll.visible = not items.is_empty()
	var content_h := 0.0
	for item in items:
		var row := _build_row(item)
		_column.add_child(row)
		content_h += row.custom_minimum_size.y + CARD_GAP
	# 面板高度跟着内容走：只有一张卡时别留一大片空纸。
	var list_h := clampf(content_h, 120.0, 760.0)
	_scroll.size = Vector2(1168, list_h)
	_footer.position.y = 104 + list_h + 10
	_panel.size = Vector2(1240, 104 + list_h + 60)
	var view := get_viewport().get_visible_rect().size
	_panel.position = Vector2((view.x - _panel.size.x) * 0.5, maxf(40.0, (view.y - _panel.size.y) * 0.5))
	_root.show()
	_scroll.scroll_vertical = 0


func is_open() -> bool:
	return _root != null and _root.visible


func close() -> void:
	if not is_open():
		return
	_root.hide()
	closed.emit()


func _build_row(item: Dictionary) -> Control:
	var art := String(item.get("cardArt", ""))
	var row := Control.new()
	row.custom_minimum_size = Vector2(CARD_W, 300 if not art.is_empty() else 96)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not art.is_empty():
		var pic := TextureRect.new()
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture = load(art)
		pic.position = Vector2.ZERO
		pic.size = Vector2(CARD_W, 300)
		pic.custom_minimum_size = Vector2.ZERO
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pic)
	else:
		var box := Panel.new()
		box.position = Vector2.ZERO
		box.size = Vector2(CARD_W, 96)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("fffaf0")
		style.border_color = Color("d8b98f")
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		box.add_theme_stylebox_override("panel", style)
		row.add_child(box)
		var name_label := _label(String(item.get("title", "自由活动")), 28, INK, true)
		name_label.position = Vector2(24, 14)
		name_label.size = Vector2(700, 36)
		box.add_child(name_label)
		var note := _label(String(item.get("note", "")), 18, Color("7a5a40"))
		note.position = Vector2(24, 54)
		note.size = Vector2(1000, 28)
		box.add_child(note)

	var disabled := bool(item.get("disabled", false))
	if disabled:
		var grey := ColorRect.new()
		grey.color = Color(0.42, 0.40, 0.36, 0.55)
		grey.position = Vector2.ZERO
		grey.size = row.custom_minimum_size
		grey.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(grey)
		var reason := _label(String(item.get("note", "现在去不了")), 22, Color("fff4e0"), true)
		reason.position = Vector2(24, row.custom_minimum_size.y - 44)
		reason.size = Vector2(900, 32)
		row.add_child(reason)

	var hit := Button.new()
	hit.focus_mode = Control.FOCUS_NONE
	hit.flat = true
	hit.position = Vector2.ZERO
	hit.size = row.custom_minimum_size
	hit.disabled = disabled
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	hit.pressed.connect(func() -> void:
		var id := String(item.get("id", ""))
		close()
		activity_selected.emit(id))
	row.add_child(hit)
	return row


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bold:
		label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.6))
		label.add_theme_constant_override("outline_size", 2)
	return label
