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
		# 轴数跟着数据走：十二个月是能力四维，旧那版是大五。
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
			var score = rows[index].get("coverage", rows[index].get("score"))
			# 没标定的那一轴（大五的情绪稳定）不进多边形：画成零会被读成"很低"，那是假话。
			var measured := bool(rows[index].get("measured", true))
			if measured and score != null:
				shape.append(center + Vector2(cos(angles[index]), sin(angles[index])) * radius * clampf(float(score), 0.05, 1.0))
				plotted += 1
			var title := String(rows[index].get("name", ""))
			var text_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			# 轴名往外让 46：四维时左右两个名字会压到多边形上。
			var label_pos := center + Vector2(cos(angles[index]), sin(angles[index])) * (radius + 46.0)
			draw_string(font, label_pos - Vector2(text_size.x / 2.0, -text_size.y / 3.0), title,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK if measured else MUTED)
		if plotted >= 3:
			draw_colored_polygon(shape, Color(0.28, 0.43, 0.33, 0.15))
			var outline := shape.duplicate()
			outline.append(shape[0])
			draw_polyline(outline, GREEN, 4.0, true)
			for index in shape.size():
				var level := String(rows[index].get("level", "waiting"))
				# 数据能点名颜色就用它（大五那一块用颜色标朝哪一头），否则按档位。
				var dot = rows[index].get("dot", null)
				draw_circle(shape[index], 5.0, dot if dot is Color else (
					Color("b5b0a5") if level == "waiting" else (GREEN if level == "solid" else GOLD)))
		else:
			draw_string(font, center + Vector2(-54, 8), "证据不足", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, MUTED)


var _main: VBoxContainer
## 十二个月那本账的排版（沿用这一页的底图、字体和分节样式，不另起一页）
var _root_box: VBoxContainer
var _twelve: VBoxContainer
var _twelve_open := false
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
	_root_box = root

	var hero_body := VBoxContainer.new()
	hero_body.add_theme_constant_override("separation", 5)
	root.add_child(hero_body)
	_kicker_label = _label("职业档案", 11, GOLD)
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


## 十二个月走完时直接喂这一页：内容来自 Month12Report 装配好的那一年那本账，
## 不请求后端、不显示任何分数。视觉沿用本页（底图、楷体标题、分节线）。
func open_with(data: Dictionary) -> void:
	visible = true
	_status.visible = false
	_retry.visible = false
	_hint.visible = false
	_kicker_label.text = "职业档案 / 十二个月"
	_title_label.text = String(data.get("pageTitle", "这一年的报告"))
	_summary.text = String(data.get("headline", ""))
	# 原来那一页的三块（轮廓图 / 细读条 / 风格标签）照用，只是喂进去的账换成十二个月那一本。
	_main.visible = true
	_rename_head("SectionProfile", "能力四维轮廓", "01 / 轮廓")
	_rename_head("SectionDetail", "证据覆盖", "02 / 细读")
	_rename_head("SectionStyle", "这一年留下的样子", "03 / 样子")
	_fill_charts(data)
	_fill_personality(data)
	_fill_extras(data)
	_render_words(data)


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
func _fill_personality(data: Dictionary) -> void:
	var personality: Dictionary = data.get("personality", {}) as Dictionary
	var rows := (personality.get("rows", []) as Array)
	if rows.is_empty() or _extras == null:
		return
	_reuse(_extras)
	_extras.visible = true
	_extras.add_child(_spacer(20))
	_extras.add_child(_rule(LINE, 1))
	_extras.add_child(_spacer(24))
	var head := _section_title("这一年的行为倾向（大五）", "04 / 大五")
	head.name = "SectionPersonality"
	_extras.add_child(head)
	_extras.add_child(_spacer(10))
	var analysis := HBoxContainer.new()
	analysis.add_theme_constant_override("separation", 40)
	_extras.add_child(analysis)
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
		_extras.add_child(_spacer(12))
		_extras.add_child(_caption(caption))


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


## 图下面追加两块：下一级要求覆盖，和方向倾向。
func _fill_extras(data: Dictionary) -> void:
	if _extras == null:
		return
	var captions: Dictionary = data.get("captions", {}) as Dictionary
	var requirements := (data.get("requirements", []) as Array)
	var direction: Dictionary = data.get("direction", {}) as Dictionary
	var line := String(direction.get("line", "")).strip_edges()
	if requirements.is_empty() and line.is_empty():
		_extras.visible = false
		return
	_extras.visible = true
	_extras.add_child(_spacer(20))
	_extras.add_child(_rule(LINE, 1))
	_extras.add_child(_spacer(24))
	if not requirements.is_empty():
		_extras.add_child(_section_title("下一级要求，已经覆盖到哪", "05 / 要求"))
		_extras.add_child(_spacer(12))
		for value in requirements:
			_extras.add_child(_requirement_row(Dictionary(value)))
		var note := String(captions.get("requirements", "")).strip_edges()
		if not note.is_empty():
			_extras.add_child(_spacer(10))
			_extras.add_child(_caption(note))
	if not line.is_empty():
		_extras.add_child(_spacer(24))
		_extras.add_child(_rule(LINE, 1))
		_extras.add_child(_spacer(20))
		_extras.add_child(_section_title("方向倾向", "06 / 方向"))
		_extras.add_child(_spacer(10))
		_extras.add_child(_paragraph(line))
		var observe := String(direction.get("observe", "")).strip_edges()
		if not observe.is_empty():
			_extras.add_child(_spacer(8))
			_extras.add_child(_caption(observe))
		var scope := String(captions.get("direction", "")).strip_edges()
		if not scope.is_empty():
			_extras.add_child(_spacer(8))
			_extras.add_child(_caption(scope))


## 长文全部收进折叠：页面上先看见图和两块结论，摘要、依据、建议留给想看的人。
func _render_words(data: Dictionary) -> void:
	if _twelve == null and _root_box != null:
		_twelve = VBoxContainer.new()
		_twelve.add_theme_constant_override("separation", 0)
		_root_box.add_child(_twelve)
	if _twelve == null:
		return
	_twelve.visible = true
	_reuse(_twelve)

	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 0)
	detail.name = "TwelveDetail"
	detail.visible = _twelve_open

	for section in (data.get("sections", []) as Array):
		var block := Dictionary(section)
		var block_id := String(block.get("id", ""))
		# 轮廓图已经承载能力四维；下一级要求和方向倾向在图下面，这里不重复。
		if block_id in ["charts", "requirements", "direction"]:
			continue
		var lines := (block.get("lines", []) as Array)
		if lines.is_empty():
			continue
		detail.add_child(_spacer(24))
		detail.add_child(_rule(LINE, 1))
		detail.add_child(_spacer(20))
		detail.add_child(_section_title(String(block.get("title", "")), ""))
		detail.add_child(_spacer(12))
		for text_line in lines:
			var text := String(text_line).strip_edges()
			if text.is_empty():
				continue
			detail.add_child(_paragraph(text))
			detail.add_child(_spacer(9))

	# 七行摘要（册子 §6.2：字段缺失就整行隐藏，不留"暂无"这种占位）
	detail.add_child(_spacer(20))
	detail.add_child(_rule(LINE, 1))
	detail.add_child(_spacer(20))
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 8)
	summary_box.add_child(_label("游戏内摘要", 19, INK))
	for row in (data.get("gameSummary", []) as Array):
		var item := Dictionary(row)
		var value := String(item.get("value", "")).strip_edges()
		if value.is_empty():
			continue
		summary_box.add_child(_summary_row(String(item.get("label", "")), value))
	detail.add_child(summary_box)

	# 依据区（册子 §6.1 展开区）
	detail.add_child(_spacer(16))
	for row in (data.get("expand", []) as Array):
		var item := Dictionary(row)
		detail.add_child(_spacer(12))
		detail.add_child(_label(String(item.get("label", "")), 19, INK))
		for detail_line in (item.get("lines", []) as Array):
			detail.add_child(_paragraph(String(detail_line)))

	var toggle := _button("看文字版（结论摘要 · 能力证据 · 自由活动 · 七行摘要 · 依据）")
	toggle.name = "TwelveExpand"
	toggle.pressed.connect(_toggle_twelve)
	_twelve.add_child(_spacer(8))
	_twelve.add_child(toggle)
	_twelve.add_child(_spacer(14))
	_twelve.add_child(detail)


func _toggle_twelve() -> void:
	_twelve_open = not _twelve_open
	if _twelve == null:
		return
	var toggle := _twelve.find_child("TwelveExpand", true, false) as Button
	if toggle != null:
		toggle.text = "收起文字版" if _twelve_open else "看文字版（结论摘要 · 能力证据 · 自由活动 · 七行摘要 · 依据）"
	var detail := _twelve.find_child("TwelveDetail", true, false) as VBoxContainer
	if detail != null:
		detail.visible = _twelve_open


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
