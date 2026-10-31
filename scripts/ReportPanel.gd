extends CanvasLayer

signal closed

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const DISPLAY_FONT := preload("res://assets/ui/ledger/LXGWWenKaiFull.ttf")
const REPORT_BACKGROUND := preload("res://assets/报告页/drawing-帮我做一个测评报告页的底图-我们里面要添加如图所示的元素-后面两张是我们测评游戏里面的角色-可以-1.png")
const INK := Color("30271e")
const MUTED := Color("776b5d")
const GREEN := Color("456a54")
const GOLD := Color("c58a30")
const TRACK := Color("eadfc8")
const PAPER := Color("fffaf2")
const LINE := Color("d8d0be")
const FS := 1.45

class BigFiveRadar:
	extends Control

	var rows: Array = []
	var font: Font

	func _draw() -> void:
		if rows.size() != 5 or font == null:
			return
		var center := size / 2.0
		var radius := minf(size.x * 0.35, size.y * 0.37)
		var angles := PackedFloat32Array()
		for index in 5:
			angles.append(-PI / 2.0 + TAU * float(index) / 5.0)
		for step in 5:
			var points := PackedVector2Array()
			for angle in angles:
				points.append(center + Vector2(cos(angle), sin(angle)) * radius * float(step + 1) / 5.0)
			points.append(points[0])
			draw_polyline(points, LINE, 1.5, true)
		var shape := PackedVector2Array()
		var complete := true
		for index in 5:
			var outer := center + Vector2(cos(angles[index]), sin(angles[index])) * radius
			draw_line(center, outer, LINE, 1.5)
			var score = rows[index].get("score")
			if score == null:
				complete = false
			else:
				shape.append(center + Vector2(cos(angles[index]), sin(angles[index])) * radius * clampf(float(score) / 100.0, 0.0, 1.0))
			var title := String(rows[index].get("name", ""))
			var text_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			var label_pos := center + Vector2(cos(angles[index]), sin(angles[index])) * (radius + 32.0)
			draw_string(font, label_pos - Vector2(text_size.x / 2.0, -text_size.y / 3.0), title,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
		if complete:
			draw_colored_polygon(shape, Color(0.28, 0.43, 0.33, 0.15))
			var outline := shape.duplicate()
			outline.append(shape[0])
			draw_polyline(outline, GREEN, 4.0, true)
			for index in shape.size():
				draw_circle(shape[index], 5.0,
					GREEN if rows[index].get("evidence") != "none" else Color("b5b0a5"))
		else:
			draw_string(font, center + Vector2(-54, 8), "证据不足", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, MUTED)


var _main: VBoxContainer
var _status: Label
var _retry: Button
var _radar: BigFiveRadar
var _scores: VBoxContainer
var _tags: FlowContainer
var _hint: Label
var _basis_note: Label
var _summary: Label
var _evidence_caption: Label


func _ready() -> void:
	layer = 220
	visible = false
	_build()
	ApiClient.report_ready.connect(_on_report_ready)
	ApiClient.report_failed.connect(_on_report_failed)


func open() -> void:
	visible = true
	_main.visible = false
	_hint.visible = false
	_status.text = "正在生成…"
	_retry.visible = false
	ApiClient.fetch_report()


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()


func _build() -> void:
	var background := ColorRect.new()
	background.color = PAPER
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var texture := TextureRect.new()
	texture.texture = REPORT_BACKGROUND
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	margin.custom_minimum_size.x = 1130
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 72)
	center.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	margin.add_child(root)

	var hero_body := VBoxContainer.new()
	hero_body.add_theme_constant_override("separation", 5)
	root.add_child(hero_body)
	hero_body.add_child(_label("职业档案   /   CAREER PROFILE", 11, GOLD))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	hero_body.add_child(head)
	var title := _label("你的职场画像", 39, INK)
	title.add_theme_font_override("font", DISPLAY_FONT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_status = _label("", 17, MUTED)
	_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_status)
	_retry = _button("重试")
	_retry.visible = false
	_retry.pressed.connect(open)
	head.add_child(_retry)
	var close_button := _button("关闭  ×")
	close_button.pressed.connect(close)
	head.add_child(close_button)
	_summary = _label("", 19, GREEN)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_body.add_child(_summary)
	root.add_child(_spacer(16))
	root.add_child(_rule(LINE, 1))
	root.add_child(_spacer(20))

	_hint = _label("", 19, MUTED)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.visible = false
	root.add_child(_hint)

	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 0)
	_main.visible = false
	root.add_child(_main)
	var analysis := HBoxContainer.new()
	analysis.add_theme_constant_override("separation", 45)
	_main.add_child(analysis)
	var chart_column := VBoxContainer.new()
	chart_column.custom_minimum_size.x = 485
	analysis.add_child(chart_column)
	chart_column.add_child(_section_title("五维轮廓", "01  /  PROFILE"))
	chart_column.add_child(_spacer(10))
	_radar = BigFiveRadar.new()
	_radar.font = FONT
	_radar.custom_minimum_size = Vector2(485, 310)
	chart_column.add_child(_radar)
	chart_column.add_child(_spacer(6))
	_evidence_caption = _label("", 15, GREEN)
	chart_column.add_child(_evidence_caption)
	_basis_note = _label("", 15, MUTED)
	_basis_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chart_column.add_child(_basis_note)

	var score_column := VBoxContainer.new()
	score_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	analysis.add_child(score_column)
	score_column.add_child(_section_title("维度细读", "02  /  DETAIL"))
	score_column.add_child(_spacer(25))
	_scores = VBoxContainer.new()
	_scores.add_theme_constant_override("separation", 11)
	score_column.add_child(_scores)
	_main.add_child(_spacer(16))
	_main.add_child(_rule(LINE, 1))
	_main.add_child(_spacer(24))
	_main.add_child(_section_title("你的风格标签", "03  /  STYLE"))
	_main.add_child(_spacer(16))
	_tags = FlowContainer.new()
	_tags.add_theme_constant_override("h_separation", 10)
	_tags.add_theme_constant_override("v_separation", 10)
	_main.add_child(_tags)


func _on_report_ready(report: Dictionary) -> void:
	if visible:
		render(report)


func _on_report_failed(reason: String) -> void:
	if visible:
		_main.visible = false
		_status.text = "生成失败"
		_hint.text = reason
		_hint.visible = true
		_retry.visible = true


func render(report: Dictionary) -> void:
	var persona: Dictionary = report.get("layers", {}).get("persona", {})
	var traits: Array = persona.get("bigfive", [])
	if traits.size() != 5:
		_on_report_failed("报告数据不完整")
		return
	_clear(_scores)
	_clear(_tags)
	var radar_rows: Array = []
	var has_empty := false
	var has_limited := false
	var names := {"O": "开放性", "C": "尽责性", "E": "外向性", "A": "宜人性", "N": "情绪稳定"}
	for key in ["O", "C", "E", "A", "N"]:
		var trait_row: Dictionary = {}
		for item in traits:
			if String(item.get("trait", "")) == key:
				trait_row = item
				break
		var name: String = names[key]
		var score := int(trait_row.get("portraitScore", 50))
		var evidence := String(trait_row.get("portraitEvidence", "none"))
		has_empty = has_empty or evidence == "none"
		has_limited = has_limited or evidence == "limited"
		radar_rows.append({"name": name, "score": score, "evidence": evidence})
		_add_score_row(name, score, evidence)
	_radar.rows = radar_rows
	_radar.queue_redraw()
	var sketch := String(persona.get("personaSketch", "")).strip_edges()
	if sketch.is_empty():
		_summary.text = "从你的选择里，慢慢看见自己的工作方式。"
	else:
		_summary.text = sketch
	var tags: Array = persona.get("styleTags", [])
	for tag in tags:
		_tags.add_child(_tag(String(tag)))
	if tags.is_empty():
		_tags.add_child(_tag("待积累经历"))
	_status.text = ""
	var skipped: Array = report.get("skippedStoryIds", [])
	_evidence_caption.text = "画像仍在形成" if has_empty or has_limited else "画像证据较充分"
	_basis_note.visible = true
	if has_empty:
		_basis_note.text = ("已跳过 %d 段剧情。" % skipped.size() if not skipped.is_empty() else "") + "灰色维度的 50 分只是中性起点，不代表已测得的个人特征。"
	elif has_limited:
		_basis_note.text = "部分维度的行为样本较少，分数仅供参考；继续体验后，画像会随证据更新。"
	else:
		_basis_note.text = "依据你在剧情中的选择与行为记录生成；分数描述倾向，不定义你是谁。"
	_hint.visible = false
	_retry.visible = false
	_main.visible = true


func _add_score_row(name: String, score: int, evidence: String) -> void:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 5)
	_scores.add_child(block)
	var top := HBoxContainer.new()
	block.add_child(top)
	var title := _label(name, 18, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var proof := "待观察" if evidence == "none" else "初步线索" if evidence == "limited" else "证据较充分"
	var proof_label := _label(proof, 13, MUTED)
	proof_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(proof_label)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 12)
	block.add_child(bar_row)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = score
	bar.show_percentage = false
	bar.custom_minimum_size.y = 11
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", _style(TRACK, 4))
	bar.add_theme_stylebox_override("fill", _style(
		Color("b5b0a5") if evidence == "none" else Color("cba15e") if evidence == "limited" else GREEN, 4))
	bar_row.add_child(bar)
	var value := _label(str(score), 18, MUTED if evidence == "none" else INK)
	value.custom_minimum_size.x = 42
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar_row.add_child(value)


func _tag(value: String) -> PanelContainer:
	var tag := PanelContainer.new()
	var style := _style(Color("edf1e9"), 3)
	style.border_color = Color("aec0ac")
	style.set_border_width_all(1)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	tag.add_theme_stylebox_override("panel", style)
	tag.add_child(_label(value, 17, GREEN))
	return tag


func _section_title(title: String, index: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	column.add_child(_label(index, 10, GOLD))
	var heading := _label(title, 23, INK)
	heading.add_theme_font_override("font", DISPLAY_FONT)
	column.add_child(heading)
	return column


func _spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size.y = height
	return node


func _rule(color: Color, height: float) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.custom_minimum_size.y = height
	return node


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", roundi(float(size) * FS))
	label.add_theme_color_override("font_color", color)
	return label


func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(110, 43)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _style(Color("edf1e9"), 3))
	button.add_theme_stylebox_override("hover", _style(Color("dce8dd"), 3))
	button.add_theme_stylebox_override("pressed", _style(Color("ccdccf"), 3))
	return button


func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
