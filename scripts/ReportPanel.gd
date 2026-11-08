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
		var axes := rows.size()
		if axes < 3 or font == null:
			return
		var center := size / 2.0
		# 0.35 时左右两个轴名会压到多边形上，缩一点给名字让位
		var radius := minf(size.x * 0.30, size.y * 0.34)
		var angles := PackedFloat32Array()
		for index in axes:
			angles.append(-PI / 2.0 + TAU * float(index) / float(axes))
		for step in 5:
			var points := PackedVector2Array()
			for angle in angles:
				points.append(center + Vector2(cos(angle), sin(angle)) * radius * float(step + 1) / 5.0)
			points.append(points[0])
			draw_polyline(points, LINE, 1.5, true)
		var shape := PackedVector2Array()
		var plotted := 0
		for index in axes:
			var outer := center + Vector2(cos(angles[index]), sin(angles[index])) * radius
			draw_line(center, outer, LINE, 1.5)
			var score: Variant = _normalized_score(rows[index])
			# 没标定的那一轴（大五的情绪稳定）不进多边形：画成零会被读成"很低"，那是假话。
			var measured := bool(rows[index].get("measured", true))
			if measured and score != null:
				shape.append(center + Vector2(cos(angles[index]), sin(angles[index])) * radius * float(score))
				plotted += 1
			var title := String(rows[index].get("name", ""))
			var text_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			# 轴名往外让 46：四维时左右两个名字会压到多边形上。
			var label_pos := center + Vector2(cos(angles[index]), sin(angles[index])) * (radius + 46.0)
			draw_string(font, label_pos - Vector2(text_size.x / 2.0, -text_size.y / 3.0), title,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK if measured else MUTED)
		if plotted == axes:
			draw_colored_polygon(shape, Color(0.28, 0.43, 0.33, 0.15))
			var outline := shape.duplicate()
			outline.append(shape[0])
			draw_polyline(outline, GREEN, 4.0, true)
		elif plotted == 0:
			draw_string(font, center + Vector2(-54, 8), "证据不足", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, MUTED)
		# 有维度未观察到时只连相邻的已测轴，留出明确断口，不把空维度伪装成低分。
		for index in axes:
			var row: Dictionary = rows[index]
			var score: Variant = _normalized_score(row)
			if not bool(row.get("measured", true)) or score == null:
				continue
			var value := center + Vector2(cos(angles[index]), sin(angles[index])) * radius * float(score)
			var dot = row.get("dot", null)
			draw_circle(value, 5.0, dot if dot is Color else (
				Color("b5b0a5") if String(row.get("evidence", "")) == "none" else GREEN))
			var next_index := (index + 1) % axes
			var next_row: Dictionary = rows[next_index]
			var next_score: Variant = _normalized_score(next_row)
			if bool(next_row.get("measured", true)) and next_score != null:
				var next_value := center + Vector2(cos(angles[next_index]), sin(angles[next_index])) * radius * float(next_score)
				draw_line(value, next_value, GREEN, 3.0, true)

	func _normalized_score(row: Dictionary) -> Variant:
		var value = row.get("coverage", row.get("score", null))
		if value == null:
			return null
		return clampf(float(value), 0.05, 1.0) if row.has("coverage") else clampf(float(value) / 100.0, 0.05, 1.0)


var _main: VBoxContainer
## 十二个月那本账的排版（沿用这一页的底图、字体和分节样式，不另起一页）
var _kicker_label: Label
var _title_label: Label
var _status: Label
var _retry: Button
var _radar: BigFiveRadar
var _scores: VBoxContainer
var _tags: FlowContainer
var _extras: VBoxContainer
var _hint: Label
var _basis_note: Label
var _summary: Label
var _evidence_caption: Label
var _detail_action_heading: Label
var _detail_actions: FlowContainer
var _detail_overlay: Control
var _detail_panel: Panel
var _detail_title: Label
var _detail_close_button: Button
var _detail_content: VBoxContainer
var _detail_scroll: ScrollContainer
var _month12_data: Dictionary = {}


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
	if _detail_overlay != null:
		_detail_overlay.hide()
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _detail_overlay != null and _detail_overlay.visible:
			_close_detail()
		else:
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
	scroll.name = "ReportScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
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
	root.name = "ReportRoot"
	root.add_theme_constant_override("separation", 0)
	margin.add_child(root)

	var hero_body := VBoxContainer.new()
	hero_body.add_theme_constant_override("separation", 5)
	root.add_child(hero_body)
	_kicker_label = _label("职业档案   /   CAREER PROFILE", 11, GOLD)
	hero_body.add_child(_kicker_label)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	hero_body.add_child(head)
	var title := _label("你的职场画像", 39, INK)
	title.add_theme_font_override("font", DISPLAY_FONT)
	_title_label = title
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
	var profile_head := _section_title("五维轮廓", "01  /  PROFILE")
	profile_head.name = "SectionProfile"
	chart_column.add_child(profile_head)
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
	var detail_head := _section_title("维度细读", "02  /  DETAIL")
	detail_head.name = "SectionDetail"
	score_column.add_child(detail_head)
	score_column.add_child(_spacer(25))
	_scores = VBoxContainer.new()
	_scores.add_theme_constant_override("separation", 11)
	score_column.add_child(_scores)
	_main.add_child(_spacer(16))
	_main.add_child(_rule(LINE, 1))
	_main.add_child(_spacer(24))
	var style_head := _section_title("你的风格标签", "03  /  STYLE")
	style_head.name = "SectionStyle"
	_main.add_child(style_head)
	_main.add_child(_spacer(16))
	_tags = FlowContainer.new()
	_tags.add_theme_constant_override("h_separation", 10)
	_tags.add_theme_constant_override("v_separation", 10)
	_main.add_child(_tags)
	_extras = VBoxContainer.new()
	_extras.add_theme_constant_override("separation", 0)
	_extras.name = "ExtraSections"
	_extras.visible = false
	_main.add_child(_extras)
	_detail_actions = FlowContainer.new()
	_detail_actions.name = "ReportDetailActions"
	_detail_actions.add_theme_constant_override("h_separation", 10)
	_detail_actions.add_theme_constant_override("v_separation", 8)
	_detail_actions.visible = false
	_detail_action_heading = _label("查看完整内容", 17, MUTED)
	_detail_action_heading.name = "ReportDetailActionHeading"
	_detail_action_heading.visible = false
	_main.add_child(_detail_action_heading)
	_main.add_child(_spacer(8))
	_main.add_child(_detail_actions)
	_build_detail_popup()


func _build_detail_popup() -> void:
	_detail_overlay = Control.new()
	_detail_overlay.name = "ReportDetailOverlay"
	_detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_overlay.z_index = 100
	_detail_overlay.hide()
	add_child(_detail_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.10, 0.08, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_overlay.add_child(dim)
	_detail_panel = Panel.new()
	_detail_panel.name = "ReportDetailPage"
	var style := _style(Color("fffaf2"), 8)
	style.border_color = Color("d8d0be")
	style.set_border_width_all(2)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 24
	_detail_panel.add_theme_stylebox_override("panel", style)
	_detail_overlay.add_child(_detail_panel)
	_detail_title = _label("报告详情", 27, INK)
	_detail_title.position = Vector2(28, 20)
	_detail_title.size = Vector2(760, 44)
	_detail_title.add_theme_font_override("font", DISPLAY_FONT)
	_detail_panel.add_child(_detail_title)
	_detail_close_button = _button("关闭  ×")
	_detail_close_button.name = "ReportDetailClose"
	_detail_close_button.custom_minimum_size = Vector2(120, 44)
	_detail_close_button.size = Vector2(120, 44)
	_detail_close_button.pressed.connect(_close_detail)
	_detail_panel.add_child(_detail_close_button)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.name = "ReportDetailScroll"
	_detail_scroll.position = Vector2(28, 82)
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_panel.add_child(_detail_scroll)
	_detail_content = VBoxContainer.new()
	_detail_content.name = "ReportDetailContent"
	_detail_content.add_theme_constant_override("separation", 10)
	_detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.add_child(_detail_content)


## 十二个月走完时直接喂这一页：内容来自 Month12Report 装配好的那一年那本账，
## 不请求后端、不显示任何分数。视觉沿用本页（底图、楷体标题、分节线）。
func open_with(data: Dictionary) -> void:
	visible = true
	_month12_data = data.duplicate(true)
	_kicker_label.text = "职业档案   /   CAREER PROFILE"
	_title_label.text = "你的职场画像"
	var personality: Dictionary = data.get("personality", {}) as Dictionary
	var trait_rows: Array = personality.get("rows", []) as Array
	var traits: Array = []
	var trait_keys := {"O": "O", "C": "C", "E": "E", "A": "A", "N": "N"}
	for row_value in trait_rows:
		var row := Dictionary(row_value)
		var trait_key := String(row.get("key", ""))
		var estimate = row.get("estimate", null)
		var has_evidence := int(row.get("events", 0)) > 0 or row.get("prior", null) != null
		var evidence := "none"
		if bool(row.get("measured", true)) and has_evidence:
			evidence = "solid" if String(row.get("level", "")) == "solid" else "limited"
		var score := roundi(50.0 + float(estimate) * 50.0) if estimate != null else 50
		traits.append({
			"trait": String(trait_keys.get(trait_key, trait_key)),
			"portraitScore": score,
			"portraitEvidence": evidence,
		})
	var persona := {
		"bigfive": traits,
		"personaSketch": "从你的选择里，慢慢看见自己的工作方式。",
		"styleTags": data.get("tags", []),
	}
	var report := {"layers": {"persona": persona}, "skippedStoryIds": data.get("skippedStoryIds", [])}
	_extras.visible = false
	_reuse(_extras)
	_basis_note.visible = false
	_detail_overlay.hide()
	_rename_head("SectionProfile", "五维轮廓", "01  /  PROFILE")
	_rename_head("SectionDetail", "维度细读", "02  /  DETAIL")
	_rename_head("SectionStyle", "你的风格标签", "03  /  STYLE")
	render(report)
	var report_scroll := find_child("ReportScroll", true, false) as ScrollContainer
	if report_scroll != null:
		report_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build_detail_actions(data)


func _build_detail_actions(data: Dictionary) -> void:
	_reuse(_detail_actions)
	var actions: Array[Dictionary] = [
		{"key": "personality", "title": "大五行为倾向"},
		{"key": "requirements", "title": "下一级要求"},
		{"key": "direction", "title": "方向倾向"},
		{"key": "section:summary", "title": "结论摘要"},
		{"key": "section:competency", "title": "岗位能力证据"},
		{"key": "section:behaviour", "title": "行为倾向观察"},
		{"key": "section:activity", "title": "自由活动回顾"},
		{"key": "section:next", "title": "后续建议"},
		{"key": "game_summary", "title": "七行摘要"},
		{"key": "evidence", "title": "证据与依据"},
	]
	for action in actions:
		var button := _button(String(action["title"]))
		button.custom_minimum_size = Vector2(178, 42)
		button.pressed.connect(_open_detail.bind(String(action["key"]), String(action["title"])))
		_detail_actions.add_child(button)
	_detail_action_heading.visible = true
	_detail_actions.visible = true


func _open_detail(key: String, title: String) -> void:
	_reuse(_detail_content)
	_detail_title.text = title
	var viewport_size := get_viewport().get_visible_rect().size
	_detail_panel.size = Vector2(minf(1120.0, viewport_size.x - 48.0), minf(780.0, viewport_size.y - 48.0))
	_detail_panel.position = (viewport_size - _detail_panel.size) * 0.5
	_detail_title.position = Vector2(28, 20)
	_detail_title.size = Vector2(_detail_panel.size.x - 210.0, 44)
	_detail_close_button.position = Vector2(_detail_panel.size.x - 160.0, 18)
	_detail_scroll.position = Vector2(28, 82)
	_detail_scroll.size = Vector2(_detail_panel.size.x - 56.0, _detail_panel.size.y - 108.0)
	match key:
		"personality":
			_fill_personality(_month12_data, _detail_content)
		"requirements":
			_append_requirements(_month12_data)
		"direction":
			_append_direction(_month12_data)
		"game_summary":
			_append_game_summary(_month12_data)
		"evidence":
			_append_evidence(_month12_data)
		_:
			if key.begins_with("section:"):
				_append_report_section(_month12_data, key.trim_prefix("section:"))
	_append_placeholder_if_empty()
	_detail_overlay.show()


func _close_detail() -> void:
	_detail_overlay.hide()


func _append_requirements(data: Dictionary) -> void:
	_detail_content.add_child(_section_title("下一级要求，已经覆盖到哪", ""))
	_detail_content.add_child(_spacer(12))
	for value in data.get("requirements", []) as Array:
		_detail_content.add_child(_requirement_row(Dictionary(value)))
	var captions := data.get("captions", {}) as Dictionary
	var note := String(captions.get("requirements", "")).strip_edges()
	if not note.is_empty():
		_detail_content.add_child(_spacer(8))
		_detail_content.add_child(_caption(note))


func _append_direction(data: Dictionary) -> void:
	var direction := data.get("direction", {}) as Dictionary
	_detail_content.add_child(_section_title("方向倾向", ""))
	_detail_content.add_child(_spacer(12))
	var line := String(direction.get("line", "")).strip_edges()
	if not line.is_empty():
		_detail_content.add_child(_paragraph(line))
	var observe := String(direction.get("observe", "")).strip_edges()
	if not observe.is_empty():
		_detail_content.add_child(_spacer(8))
		_detail_content.add_child(_caption(observe))
	var captions := data.get("captions", {}) as Dictionary
	var scope := String(captions.get("direction", "")).strip_edges()
	if not scope.is_empty():
		_detail_content.add_child(_spacer(8))
		_detail_content.add_child(_caption(scope))


func _append_report_section(data: Dictionary, section_id: String) -> void:
	for value in data.get("sections", []) as Array:
		var section := Dictionary(value)
		if String(section.get("id", "")) != section_id:
			continue
		_detail_content.add_child(_section_title(String(section.get("title", "报告详情")), ""))
		_detail_content.add_child(_spacer(12))
		for line in section.get("lines", []) as Array:
			var text := String(line).strip_edges()
			if not text.is_empty():
				_detail_content.add_child(_paragraph(text))
				_detail_content.add_child(_spacer(8))
		return
	_detail_content.add_child(_paragraph("这部分暂时没有可展示的记录。"))


func _append_game_summary(data: Dictionary) -> void:
	_detail_content.add_child(_section_title("游戏内摘要", ""))
	_detail_content.add_child(_spacer(12))
	var added := false
	for value in data.get("gameSummary", []) as Array:
		var row := Dictionary(value)
		var content := String(row.get("value", "")).strip_edges()
		if content.is_empty():
			continue
		_detail_content.add_child(_summary_row(String(row.get("label", "")), content))
		added = true
	if not added:
		_detail_content.add_child(_paragraph("这一年暂时没有足够记录生成摘要。"))


func _append_evidence(data: Dictionary) -> void:
	_detail_content.add_child(_section_title("证据与依据", ""))
	_detail_content.add_child(_spacer(12))
	var added := false
	for value in data.get("expand", []) as Array:
		var item := Dictionary(value)
		_detail_content.add_child(_label(String(item.get("label", "")), 19, INK))
		var lines := item.get("lines", []) as Array
		for line in lines:
			_detail_content.add_child(_paragraph(String(line)))
			_detail_content.add_child(_spacer(6))
		added = added or not lines.is_empty()
	if not added:
		_detail_content.add_child(_paragraph("这一年暂时没有可展开的证据记录。"))


func _append_placeholder_if_empty() -> void:
	if _detail_content.get_child_count() == 0:
		_detail_content.add_child(_paragraph("这一部分暂时没有可展示的记录。"))


## 分节标题就地改名，编号那行照原来那一页留着（换成中文，玩家可见文字全中文）。
func _rename_head(node_name: String, title: String, index: String) -> void:
	var head := _main.find_child(node_name, true, false) as VBoxContainer
	if head == null:
		return
	var labels: Array = []
	for child in head.get_children():
		if child is Label:
			labels.append(child)
	if labels.size() >= 2:
		(labels[0] as Label).text = index
		(labels[0] as Label).visible = not index.is_empty()
		(labels[1] as Label).text = title
	elif not labels.is_empty():
		(labels[0] as Label).text = title


## 轮廓图 + 细读条 + 风格标签：图吃的是这一年的证据覆盖，条右边不印数字。
func _fill_charts(data: Dictionary) -> void:
	var captions: Dictionary = data.get("captions", {}) as Dictionary
	var charts := (data.get("charts", []) as Array)
	var radar_rows: Array = []
	var notes: Array = []
	for value in charts:
		var row := Dictionary(value)
		radar_rows.append({
			"name": String(row.get("short", row.get("name", ""))),
			"coverage": float(row.get("coverage", 0.0)),
			"level": String(row.get("level", "waiting")),
		})
		var note := String(row.get("note", "")).strip_edges()
		if not note.is_empty():
			notes.append(note)
	if _radar != null:
		_radar.rows = radar_rows
		_radar.queue_redraw()
	_reuse(_scores)
	for value in charts:
		_add_coverage_row(Dictionary(value))
	if _evidence_caption != null:
		_evidence_caption.text = String(captions.get("coverage", ""))
	if _basis_note != null:
		_basis_note.text = "\n".join(notes)
	_reuse(_tags)
	var tags := (data.get("tags", []) as Array)
	for tag in tags:
		_tags.add_child(_tag(String(tag)))
	if tags.is_empty():
		_tags.add_child(_label(String(captions.get("noTags", "这一年还没攒出能当标签的样子。")), 17, MUTED))


## 细读条的一行：跟原来那版同一个形状（上行名字和档位词，下行一整条），只是条右边不印数字。
func _add_coverage_row(row: Dictionary) -> void:
	_scores.add_child(_coverage_block(row))


## 一行的形状：上行"维度名 + 档位词"，下行一整条。条的长短是证据覆盖，右边不印数字。
func _coverage_block(row: Dictionary) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 5)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	block.add_child(top)
	var title := _label(String(row.get("name", "")), 18, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var proof := _label(String(row.get("levelWord", "")), 13, MUTED)
	proof.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# 档位词右对齐成一列，维度名长短不一样时也不会贴上去。
	proof.custom_minimum_size.x = 76
	proof.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(proof)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.step = 0.01
	bar.value = clampf(float(row.get("coverage", 0.0)), 0.0, 1.0) * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size.y = 11
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", _style(TRACK, 4))
	bar.add_theme_stylebox_override("fill", _style(_bar_tone(row), 4))
	block.add_child(bar)
	return block


## 大五那一块（算法册 §3.1–3.3）：形状照能力四维那一块，喂的是 B_t 那本账。
## 情绪稳定这一版本没标定，所以那一轴不画点、条上写"这一版没测"。
func _fill_personality(data: Dictionary, destination: VBoxContainer = null) -> void:
	var personality: Dictionary = data.get("personality", {}) as Dictionary
	var rows := (personality.get("rows", []) as Array)
	var target := _extras if destination == null else destination
	if rows.is_empty() or target == null:
		return
	_reuse(target)
	if target == _extras:
		target.visible = true
	target.add_child(_spacer(20))
	target.add_child(_rule(LINE, 1))
	target.add_child(_spacer(24))
	var head := _section_title("这一年的行为倾向（大五）", "04 / 大五")
	head.name = "SectionPersonality"
	target.add_child(head)
	target.add_child(_spacer(10))
	var analysis := HBoxContainer.new()
	analysis.add_theme_constant_override("separation", 40)
	target.add_child(analysis)
	var chart_column := VBoxContainer.new()
	chart_column.custom_minimum_size.x = 430
	analysis.add_child(chart_column)
	var radar := BigFiveRadar.new()
	radar.font = FONT
	radar.custom_minimum_size = Vector2(430, 300)
	var radar_rows: Array = []
	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 11)
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in rows:
		var row := Dictionary(value)
		radar_rows.append({
			"name": String(row.get("short", row.get("name", ""))),
			"coverage": float(row.get("coverage", 0.0)),
			"level": String(row.get("level", "waiting")),
			"measured": bool(row.get("measured", true)),
			"dot": _bar_tone(row),
		})
		bars.add_child(_coverage_block(row))
	radar.rows = radar_rows
	chart_column.add_child(radar)
	analysis.add_child(bars)
	var caption := String(personality.get("caption", "")).strip_edges()
	if not caption.is_empty():
		target.add_child(_spacer(12))
		target.add_child(_caption(caption))


## 条子和点的颜色：数据给了 tone 就照它（大五那一块用它标朝哪一头），
## 没给就按档位——能力四维那边"证据较实"绿、"初步线索"黄、没观察到灰。
func _bar_tone(row: Dictionary) -> Color:
	match String(row.get("tone", "")):
		"green":
			return GREEN
		"gold":
			return GOLD
		"gray":
			return Color("b5b0a5")
		_:
			var level := String(row.get("level", "waiting"))
			return GREEN if level == "solid" else (GOLD if level == "early" else Color("b5b0a5"))


## 重开一页时清掉上一版的临时节点：先从树上摘下来再释放，避免同一帧里新旧叠着。
func _reuse(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()


## 摘要一行：左边字段名，右边那一本账里的原话。
func _summary_row(name: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var left := _label(name, 16, MUTED)
	left.custom_minimum_size = Vector2(120, 0)
	row.add_child(left)
	var right := _label(value, 17, INK)
	right.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	return row


## 一维的覆盖条：长度是"证据覆盖"，不是分数；右边配档位词。
func _coverage_row(row: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var name_label := _label(String(row.get("name", "")), 18, INK)
	name_label.custom_minimum_size = Vector2(150, 0)
	head.add_child(name_label)
	var track := Panel.new()
	track.custom_minimum_size = Vector2(0, 12)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.91, 0.87, 0.78, 0.75)
	track_style.set_corner_radius_all(6)
	track.add_theme_stylebox_override("panel", track_style)
	head.add_child(track)
	var level := String(row.get("level", "waiting"))
	var ratio := clampf(float(row.get("coverage", 0.0)), 0.0, 1.0)
	# 条子里放一个铺满的 HBox，用拉伸比例分"有证据"和"没有"两段：
	# 不靠手算像素宽度，窗口大小一变也不会错位。
	var meter := HBoxContainer.new()
	meter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meter.add_theme_constant_override("separation", 0)
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(meter)
	var fill := ColorRect.new()
	fill.color = GREEN if level == "solid" else (GOLD if level == "early" else Color("c9c2b2"))
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.size_flags_stretch_ratio = maxf(ratio, 0.02)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_child(fill)
	var rest := ColorRect.new()
	rest.color = Color(0, 0, 0, 0)
	rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest.size_flags_stretch_ratio = maxf(1.0 - ratio, 0.02)
	rest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_child(rest)
	var word := _label(String(row.get("levelWord", "")), 15, MUTED)
	word.custom_minimum_size = Vector2(96, 0)
	head.add_child(word)
	return box


## 下一级要求的一行：点 + 要求 + 状态。
func _requirement_row(row: Dictionary) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var covered := bool(row.get("covered", false))
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(16, 16)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = GREEN if covered else Color("c9c2b2")
	dot_style.set_corner_radius_all(8)
	dot.add_theme_stylebox_override("panel", dot_style)
	box.add_child(dot)
	var label := _label(String(row.get("label", "")), 17, INK)
	label.custom_minimum_size = Vector2(330, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	var state := _label("已有记录" if covered else "还没记录", 15, GREEN if covered else MUTED)
	state.custom_minimum_size = Vector2(90, 0)
	box.add_child(state)
	var cite := _label(String(row.get("cite", "")), 15, MUTED)
	cite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(cite)
	return box


## 图下面那行小字：只解释图，不另起结论。
func _caption(text: String) -> Label:
	var label := _label(text, 15, MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", 3)
	return label


func _paragraph(text: String) -> Label:
	var label := _label(text, 17, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", 5)
	return label


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
	# 十二个月那一版不写英文编号（措辞红线：玩家可见文字全中文），index 空就整行不出。
	if not index.is_empty():
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
