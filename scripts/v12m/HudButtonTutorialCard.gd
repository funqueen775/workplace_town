class_name HudButtonTutorialCard
extends CanvasLayer

## 右下角 HUD 按钮的“第一次使用”讲解卡，纸卡样式与手机讲解卡同一套。
## 打开时只解释这一个按钮；点“打开X”进真实面板，点“稍后”下次再点还会出。

signal closed()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER_TEXTURE := preload("res://assets/ui/ledger/paper_tex.png")
const TAPE_TEXTURE := preload("res://assets/ui/ledger/tape_tex.png")
const SEAL_TEXTURE := preload("res://assets/ui/ledger/seal_tex.png")
const CHECK_TEXTURE := preload("res://assets/ui/rework_v1/task_book/16_未勾选框.png")
const PAW_TEXTURE := preload("res://assets/ui/rework_v1/task_book/22_页面装饰爪印.png")

const HEROES := {
	"archive": preload("res://assets/ui/rework_v1/hud/components/16_圆钮统一_archive.png"),
	"manual": preload("res://assets/ui/rework_v1/hud/components/16_圆钮统一_manual.png"),
	"mood": preload("res://assets/ui/rework_v1/hud/components/05_蜂蜜罐_满.png"),
}

const INK := Color("2b2119")
const INK_SOFT := Color("5a4635")
const MUTED := Color("8a7259")
const PAPER := Color("f4e8d2")
const CREAM := Color("f8ecd8")
const RED := Color("b33a2c")
const CARD_SIZE := Vector2(1040, 650)

var _root: Control
var _blocker: ColorRect
var _card: Panel
var _hero: TextureRect
var _hero_title: Label
var _hero_sub: Label
var _kicker: Label
var _title: Label
var _lede: Label
var _preview_title: Label
var _preview_text: Label
var _step_titles: Array[Label] = []
var _step_subs: Array[Label] = []
var _step_rows: Array[Control] = []
var _steps_box: VBoxContainer
## 条目区的顶边与每行的高度：按钮和小字都按实际条数往下排，条数变了不会压到一起。
const STEPS_TOP := 240.0
const STEP_ROW_H := 60.0
var _open_button: Button
var _later_button: Button
var _fineprint: Label
var _hide_later := false
var _on_open := Callable()
var _on_later := Callable()


func _ready() -> void:
	layer = 210
	_root = Control.new()
	_root.name = "HudButtonTutorialRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# 透明挡板：卡片外不能点到 HUD，但背景保持手机卡那样的明亮。
	_blocker = ColorRect.new()
	_blocker.color = Color(0, 0, 0, 0.0)
	_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_blocker)

	_build_card()
	_root.hide()


func is_open() -> bool:
	return _root != null and _root.visible


func open(config: Dictionary, on_open: Callable, on_later: Callable) -> void:
	_on_open = on_open
	_on_later = on_later
	var kind := String(config.get("kind", ""))
	_hero.texture = HEROES.get(kind, null)
	_hero_title.text = String(config.get("hero_title", ""))
	_hero_sub.text = String(config.get("hero_sub", ""))
	_kicker.text = String(config.get("kicker", "怎么用"))
	_title.text = String(config.get("title", ""))
	_lede.text = String(config.get("lede", ""))
	_preview_title.text = String(config.get("preview_title", ""))
	_preview_text.text = String(config.get("preview_text", ""))
	_open_button.text = String(config.get("open_label", "打开"))
	_fineprint.text = String(config.get("fineprint", ""))
	# 心情那张没有"打开某个面板"这一步（顶上那罐点不动），所以只有一个按钮：
	# 没有"稍后"，Esc 也按"知道了"处理——它不是入口，讲完就得让它过去。
	_hide_later = bool(config.get("hide_later", false))
	_later_button.visible = not _hide_later
	# 条目按需生成：手册三行、档案四行，行数不同就按行数把按钮往下推。
	var steps: Array = config.get("steps", [])
	while _step_titles.size() < steps.size():
		_add_step(_step_titles.size())
	for i in _step_titles.size():
		var used := i < steps.size()
		_step_rows[i].visible = used
		if not used:
			continue
		var step: Dictionary = steps[i]
		_step_titles[i].text = "%02d %s" % [i + 1, String(step.get("title", ""))]
		_step_subs[i].text = String(step.get("sub", ""))
	var steps_bottom := STEPS_TOP + float(steps.size()) * STEP_ROW_H
	_open_button.position.y = maxf(steps_bottom + 12.0, 470.0)
	_later_button.position.y = maxf(steps_bottom + 20.0, 480.0)
	_fineprint.position.y = maxf(steps_bottom + 80.0, 540.0)

	_root.show()
	var card_scale := _ui_scale()
	_card.modulate = Color(1, 1, 1, 0)
	_card.scale = Vector2(0.965, 0.965) * card_scale
	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(v: float) -> void: _card.modulate = Color(1, 1, 1, v), 0.0, 1.0, 0.18)
	tween.tween_property(_card, "scale", Vector2.ONE * card_scale, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 手机竖屏时 Godot 的 expand 会把视口拉到很高，按 1920×1080 排的卡片在屏幕上只剩一条，
## 字就跟着变小。按视口短边换算倍数放大：桌面 16:9 恒为 1，手机竖屏约 1.8。
## 再卡一次宽度，别让卡片顶出屏幕两侧。
func _ui_scale() -> float:
	var view := get_viewport().get_visible_rect().size
	var scale_by_short_side := clampf(minf(view.x, view.y) / 1080.0, 1.0, 2.0)
	# 卡片两侧还挂着胶带和印章这些伸出卡外的装饰，留够边距才不会被屏幕切掉。
	var scale_by_width := (view.x * 0.88 - 80.0) / CARD_SIZE.x
	return maxf(1.0, minf(scale_by_short_side, scale_by_width))


func _on_open_pressed() -> void:
	_close()
	var cb := _on_open
	_on_open = Callable()
	if cb.is_valid():
		cb.call()


func _on_later_pressed() -> void:
	_close()
	var cb := _on_later
	_on_later = Callable()
	if cb.is_valid():
		cb.call()


func _close() -> void:
	if _root == null or not _root.visible:
		return
	_root.hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		if _hide_later:
			_on_open_pressed()
		else:
			_on_later_pressed()
		get_viewport().set_input_as_handled()


func _build_card() -> void:
	_card = Panel.new()
	_card.name = "HudButtonTutorialCard"
	_card.size = CARD_SIZE
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -CARD_SIZE.x * 0.5
	_card.offset_top = -CARD_SIZE.y * 0.5
	_card.offset_right = CARD_SIZE.x * 0.5
	_card.offset_bottom = CARD_SIZE.y * 0.5
	_card.pivot_offset = CARD_SIZE * 0.5
	_card.rotation_degrees = -0.7
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.add_theme_stylebox_override("panel", _card_style())
	_root.add_child(_card)

	var paper := _texture(PAPER_TEXTURE, Rect2(Vector2.ZERO, CARD_SIZE), TextureRect.STRETCH_SCALE, 0.34)
	_card.add_child(paper)

	var tape_a := _texture(TAPE_TEXTURE, Rect2(-46, -28, 230, 66), TextureRect.STRETCH_SCALE, 0.90)
	tape_a.rotation_degrees = -18
	tape_a.pivot_offset = Vector2(115, 33)
	_card.add_child(tape_a)
	var tape_b := _texture(TAPE_TEXTURE, Rect2(CARD_SIZE.x - 190, CARD_SIZE.y - 34, 230, 66), TextureRect.STRETCH_SCALE, 0.90)
	tape_b.rotation_degrees = 7
	tape_b.pivot_offset = Vector2(115, 33)
	_card.add_child(tape_b)

	var seal := _texture(SEAL_TEXTURE, Rect2(CARD_SIZE.x - 154, 38, 108, 108), TextureRect.STRETCH_SCALE, 0.94)
	seal.rotation_degrees = 9
	seal.pivot_offset = Vector2(54, 54)
	_card.add_child(seal)
	var seal_text := _label("已解锁", 20, Color(0.97, 0.91, 0.82, 0.95), true, 108, HORIZONTAL_ALIGNMENT_CENTER)
	seal_text.position = Vector2(CARD_SIZE.x - 154, 78)
	seal_text.size = Vector2(108, 28)
	seal_text.rotation_degrees = 9
	_card.add_child(seal_text)

	var tag := Panel.new()
	tag.position = Vector2(42, -22)
	tag.size = Vector2(172, 34)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_stylebox_override("panel", _pill_style(Color("2b2119"), Color(0, 0, 0, 0)))
	_card.add_child(tag)
	var tag_dot := ColorRect.new()
	tag_dot.color = Color("e04a3c")
	tag_dot.position = Vector2(18, 13)
	tag_dot.size = Vector2(8, 8)
	tag_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(tag_dot)
	var tag_text := _label("第一次使用", 15, CREAM, false, 120)
	tag_text.position = Vector2(36, 4)
	tag_text.size = Vector2(120, 26)
	tag.add_child(tag_text)

	_hero = _texture(HEROES["archive"], Rect2(26, 30, 250, 250), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_card.add_child(_hero)
	_hero_title = _label("", 31, Color("3a2a1d"), true, 300, HORIZONTAL_ALIGNMENT_CENTER)
	_hero_title.position = Vector2(0, 292)
	_hero_title.size = Vector2(300, 42)
	_card.add_child(_hero_title)
	_hero_sub = _label("", 15, MUTED, false, 300, HORIZONTAL_ALIGNMENT_CENTER)
	_hero_sub.position = Vector2(0, 336)
	_hero_sub.size = Vector2(300, 26)
	_card.add_child(_hero_sub)

	var content := Control.new()
	content.position = Vector2(400, 58)
	content.size = Vector2(580, 560)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(content)

	_kicker = _label("怎么用", 22, Color("a35a3a"), true, 580)
	_kicker.position = Vector2(0, 0)
	_kicker.size = Vector2(580, 28)
	content.add_child(_kicker)
	_title = _label("", 54, INK, true, 580)
	_title.position = Vector2(0, 30)
	_title.size = Vector2(580, 64)
	content.add_child(_title)
	_lede = _label("", 22, Color("6b5540"), false, 560)
	_lede.position = Vector2(0, 100)
	_lede.size = Vector2(560, 36)
	content.add_child(_lede)

	# 预览框保持原位：lede 那行一旦折成两行会往下溢出十几像素，框往上挪就会压到它。
	var preview := Panel.new()
	preview.position = Vector2(0, 138)
	preview.size = Vector2(560, 86)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_theme_stylebox_override("panel", _soft_panel_style())
	content.add_child(preview)
	_preview_title = _label("", 14, Color("9a7b5e"), false, 520)
	_preview_title.position = Vector2(16, 12)
	_preview_title.size = Vector2(520, 22)
	preview.add_child(_preview_title)
	_preview_text = _label("", 20, Color("33261b"), false, 520)
	_preview_text.position = Vector2(16, 38)
	_preview_text.size = Vector2(520, 34)
	preview.add_child(_preview_text)

	_steps_box = VBoxContainer.new()
	_steps_box.position = Vector2(0, STEPS_TOP)
	_steps_box.size = Vector2(560, 280)
	_steps_box.add_theme_constant_override("separation", 0)
	_steps_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_steps_box)

	_open_button = Button.new()
	_open_button.name = "OpenButton"
	_open_button.text = "打开"
	_open_button.focus_mode = Control.FOCUS_NONE
	_open_button.position = Vector2(0, 470)
	_open_button.size = Vector2(210, 62)
	_style_primary(_open_button)
	_open_button.pressed.connect(_on_open_pressed)
	content.add_child(_open_button)

	_later_button = Button.new()
	_later_button.name = "LaterButton"
	_later_button.text = "稍后，先忙手头的"
	_later_button.flat = true
	_later_button.focus_mode = Control.FOCUS_NONE
	_later_button.position = Vector2(234, 480)
	_later_button.size = Vector2(220, 46)
	_style_text_button(_later_button)
	_later_button.pressed.connect(_on_later_pressed)
	content.add_child(_later_button)

	_fineprint = _label("", 15, Color("9a8066"), false, 560)
	_fineprint.position = Vector2(0, 540)
	_fineprint.size = Vector2(560, 24)
	content.add_child(_fineprint)

	var paw := _texture(PAW_TEXTURE, Rect2(CARD_SIZE.x - 112, CARD_SIZE.y - 96, 78, 78), TextureRect.STRETCH_KEEP_ASPECT_CENTERED, 0.13)
	paw.rotation_degrees = -18
	paw.pivot_offset = Vector2(39, 39)
	_card.add_child(paw)


func _add_step(index: int) -> void:
	var row := Control.new()
	row.custom_minimum_size = Vector2(560, STEP_ROW_H)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_steps_box.add_child(row)
	var box := _texture(CHECK_TEXTURE, Rect2(0, 8, 32, 32), TextureRect.STRETCH_SCALE)
	row.add_child(box)
	var title := _label("", 22, INK, true, 490)
	title.position = Vector2(52, 0)
	title.size = Vector2(490, 28)
	row.add_child(title)
	_step_titles.append(title)
	var sub := _label("", 16, MUTED, false, 490)
	sub.position = Vector2(52, 27)
	sub.size = Vector2(490, 24)
	row.add_child(sub)
	_step_subs.append(sub)
	var line := ColorRect.new()
	line.color = Color(0.35, 0.24, 0.12, 0.16)
	line.position = Vector2(0, STEP_ROW_H - 1.0)
	line.size = Vector2(560, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	_step_rows.append(row)


# ---------------------------------------------------------------- 组件

func _label(text: String, size: int, color: Color, bold := false, width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _bold(FONT) if bold else FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if width > 0.0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(width, 0)
		label.size = Vector2(width, 0)
	return label


func _bold(font: Font) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = font
	variation.variation_embolden = 0.55
	return variation


func _texture(texture: Texture2D, rect: Rect2, stretch: int, alpha := 1.0) -> TextureRect:
	var node := TextureRect.new()
	# 先设 expand，再给贴图：否则 1280 的 HUD 圆钮会按原尺寸把卡片撑破。
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = stretch
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.custom_minimum_size = Vector2.ZERO
	node.modulate.a = alpha
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color(0.35, 0.24, 0.12, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 16)
	return style


func _soft_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.36)
	style.border_color = Color(0.35, 0.24, 0.12, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style


func _pill_style(fill: Color, shadow: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(999)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.shadow_color = shadow
	style.shadow_size = 0
	return style


func _button_box(fill: Color, radius: int, shadow: Color, border := Color(0, 0, 0, 0), border_width := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


func _style_primary(button: Button) -> void:
	button.add_theme_font_override("font", _bold(FONT))
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color(1, 0.98, 0.93, 1))
	button.add_theme_stylebox_override("normal", _button_box(Color("2f241a"), 31, Color(0, 0, 0, 0.22)))
	button.add_theme_stylebox_override("hover", _button_box(Color("3d2f22"), 31, Color(0, 0, 0, 0.26)))
	button.add_theme_stylebox_override("pressed", _button_box(Color("241a12"), 31, Color(0, 0, 0, 0.18)))


func _style_text_button(button: Button, size := 19, color := Color("7a5a40")) -> void:
	button.flat = true
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color("4a3626"))
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
