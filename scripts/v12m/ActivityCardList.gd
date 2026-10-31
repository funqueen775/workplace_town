extends CanvasLayer

## 自由活动卡列表：进区之后，一屏一列、每行一张票根卡（2026-10-31）。
##
## 为什么另开一屏而不是塞进右侧窄栏：新画的卡是 1200×340 的整卡，缩略图占了三分之一，
## 窄栏只有 470 宽，缩进去字就看不清了。
##
## 为什么不直接把美术给的整卡贴上去（重要）：那 12 张图把区名、活动名、一句话、消耗
## 全烙死在像素里，而烙的字和游戏数据对不上——图上 E 区印"财务部"、H 区印"生产部"，
## 游戏里 E 是松风训练谷、H 是慢生活园；图上写"小馆咖啡聊天"，数据里这条叫"销售部外摆"。
## 所以这里只取图上不会错的两样零件（缩略图、蜂蜜罐，由 tools/v12m_cut_activity_cards.py 切出来），
## 版式照图重画，文字一律现读 activities.json。图重画了重跑那个脚本即可。
##
## 卡片只负责"选哪件"：点一下发 activity_selected，结算仍在原来的到访页。
## 这张票根不是解锁卡——解锁讲解卡是 PlaceVisitPanel.show_unlock() 那张歪纸片。

signal activity_selected(id: String)
signal closed()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const HAND_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const JAR_TEX := "res://assets/ui/activity_cards/honey_jar.png"
const THUMB_DIR := "res://assets/ui/activity_cards/thumb_%s.png"

const PAPER := Color("fdf6e6")
const INK := Color("3a2a1d")
const WEAK_INK := Color("7a5a40")
const EDGE_DARK := Color("6b2f12")
const EDGE_ORANGE := Color("f0a63c")
const BADGE_GREEN := Color("4e9a2f")
const BADGE_EDGE := Color("2c5a17")
const COST_GREEN := Color("dcefc6")
const COST_EDGE := Color("b0d094")

const CARD_W := 1100.0
const CARD_H := 288.0
const PLAIN_H := 104.0
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
	style.bg_color = Color("f6e6bd")
	style.border_color = Color("5b321f")
	style.set_border_width_all(5)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	_title = _label("能进去的地方", 34, INK, true)
	_title.position = Vector2(40, 22)
	_title.size = Vector2(760, 44)
	_panel.add_child(_title)

	_points = _label("", 20, WEAK_INK)
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

	_empty = _label("这个区现在还没有能去的地方。", 24, WEAK_INK)
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
	var thumb := _thumb_path(item)
	var row := Control.new()
	row.custom_minimum_size = Vector2(CARD_W, CARD_H if not thumb.is_empty() else PLAIN_H)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not thumb.is_empty():
		_build_ticket(row, item, thumb)
	else:
		_build_plain(row, item)
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


## 票根卡：外圈深褐、内圈橙，左边缩略图，中间名字和一句话，右边消耗栏。
## 照 assets/01_带缩略图面板 那套版式画，字全部来自数据。
func _build_ticket(row: Control, item: Dictionary, thumb: String) -> void:
	var outer := Panel.new()
	outer.position = Vector2.ZERO
	outer.size = Vector2(CARD_W, CARD_H)
	outer.add_theme_stylebox_override("panel", _box(PAPER, EDGE_DARK, 5, 26))
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(outer)

	var inner := Panel.new()
	inner.position = Vector2(9, 9)
	inner.size = Vector2(CARD_W - 18, CARD_H - 18)
	inner.add_theme_stylebox_override("panel", _box(PAPER, EDGE_ORANGE, 4, 20))
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(inner)

	# 区名牌：图上烙的是部门口径，这里按 ZONES 现读，改区名不用重画图。
	# 区名和活动同名的那条（松风训练谷）不写两遍，牌子省掉。
	var badge_text := String(item.get("badge", ""))
	if badge_text == String(item.get("title", "")):
		badge_text = ""
	if not badge_text.is_empty():
		var badge := Panel.new()
		badge.position = Vector2(28, 16)
		badge.size = Vector2(maxf(150.0, badge_text.length() * 30.0 + 46.0), 48)
		badge.add_theme_stylebox_override("panel", _box(BADGE_GREEN, BADGE_EDGE, 3, 22))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outer.add_child(badge)
		var badge_label := _label(badge_text, 26, Color("f4ffe8"), false, HAND_FONT)
		badge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(badge_label)

	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture = load(thumb)
	pic.position = Vector2(44, 80)
	pic.size = Vector2(362, 174)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(pic)

	var name_label := _label(String(item.get("title", "自由活动")), 38, INK, false, HAND_FONT)
	name_label.position = Vector2(438, 104)
	name_label.size = Vector2(408, 54)
	name_label.clip_text = true
	outer.add_child(name_label)

	var note := _label(String(item.get("note", "")), 21, WEAK_INK)
	note.position = Vector2(438, 166)
	note.size = Vector2(426, 70)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_constant_override("line_spacing", 3)
	outer.add_child(note)

	# 消耗栏 = 心情那本账。蜂蜜罐在全游戏只表示心情 H（HUD 顶上同款），
	# 所以这里的数字读 hCost，不读格子；占几格走下面那行小字。
	var cost_panel := Panel.new()
	cost_panel.position = Vector2(872, 30)
	cost_panel.size = Vector2(198, CARD_H - 60)
	cost_panel.add_theme_stylebox_override("panel", _box(COST_GREEN, COST_EDGE, 3, 16))
	cost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(cost_panel)
	var cost_title := _label("消耗", 24, Color("6b4a2a"), false, HAND_FONT)
	cost_title.position = Vector2(0, 10)
	cost_title.size = Vector2(198, 32)
	cost_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_panel.add_child(cost_title)
	var cost := int(item.get("cost", 0))
	if ResourceLoader.exists(JAR_TEX):
		var jar := TextureRect.new()
		jar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		jar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		jar.texture = load(JAR_TEX)
		jar.position = Vector2(66, 50)
		jar.size = Vector2(66, 80)
		jar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if cost <= 0:
			jar.modulate = Color(0.72, 0.70, 0.66, 0.55)
		cost_panel.add_child(jar)
	# 不花心情时罐子压暗、写"不花"：实拍里 0 在这套手写体下画成了一个方框，
	# 而且"消耗 0"读着像坏数据——"不花"才是人话，也正好是这条去处的卖点。
	var cost_number := _label("不花" if cost <= 0 else str(cost), 32,
		Color("8b857c") if cost <= 0 else Color("a35a3a"), false, HAND_FONT)
	cost_number.position = Vector2(0, cost_panel.size.y - 56)
	cost_number.size = Vector2(198, 40)
	cost_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_panel.add_child(cost_number)


## 没切出缩略图的去处仍走文字票根，不留空洞也不塌版。
func _build_plain(row: Control, item: Dictionary) -> void:
	var box := Panel.new()
	box.position = Vector2.ZERO
	box.size = Vector2(CARD_W, PLAIN_H)
	box.add_theme_stylebox_override("panel", _box(Color("fffaf0"), Color("d8b98f"), 3, 12))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)
	var name_label := _label(String(item.get("title", "自由活动")), 28, INK, true)
	name_label.position = Vector2(24, 14)
	name_label.size = Vector2(700, 36)
	box.add_child(name_label)
	var note := _label(String(item.get("note", "")), 18, WEAK_INK)
	note.position = Vector2(24, 54)
	note.size = Vector2(1000, 28)
	box.add_child(note)


## 整卡路径 -> 切好的缩略图。优先 cardKey，其次从 cardArt 文件名取「区_活动」。
func _thumb_path(item: Dictionary) -> String:
	var key := String(item.get("cardKey", ""))
	if key.is_empty():
		var file := String(item.get("cardArt", "")).get_file()
		if file.is_empty():
			return ""
		var parts := file.trim_suffix(".png").split("_")
		if parts.size() < 2:
			return ""
		key = "%s_%s" % [parts[0], parts[1]]
	var cut := THUMB_DIR % key
	if ResourceLoader.exists(cut):
		return cut
	var whole := String(item.get("cardArt", ""))
	return whole if ResourceLoader.exists(whole) else ""


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _label(text: String, size: int, color: Color, bold := false, font: Font = FONT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bold:
		label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.6))
		label.add_theme_constant_override("outline_size", 2)
	return label


func _box(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
