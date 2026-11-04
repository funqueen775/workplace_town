class_name HandbookPanel
extends CanvasLayer

## 《新员工手册》阅读器（V5.27 · E01 核心可交互物）。
##
## 设计要点：
##  1. 这是一本**真的能读的册子**，不是三选一的选项文案——玩家看得到条款原文。
##  2. 册子边上有前任留下的铅笔批注（margin），读到章末才会浮出来：
##     让"手册"变成"有人用过的物件"，玩家读的是痕迹，不是说明书。
##  3. 埋点按 V5.27 要求：各章阅读时长 + 跳过行为。关闭时一次性交回。
##
## 2026-10-30 减量：八页，不是十四条。每条都必须有剧情里的考场（数据里的 examAt），
## 没考场的条款不进这本册子；clause.struck 是"王哥划掉的那一页"，标题画一道横线、
## 正文退成铅笔色——划掉的条款不考，但留着能看出这本册子有人不同意它。
## afterword 只印在最后一页的末尾（以前挂在 1.5 页末，翻到第一章中间就"到这里就结束了"）。
##
## 视觉上刻意与对话层相反：对话是黑底白字的撕裂气泡，手册是米黄纸质 + 深褐油墨。
##
## 布局注意（踩过的坑）：Label 开了 autowrap 之后，它的最小高度是按**当时**的 size.x
## 算的。所以每个 Label 在创建时就要给对宽度，否则容器按窄宽度算高度、正文被底边切掉。
## 同理，内容区必须放在 ScrollContainer 里——手册是真有字数的，一屏放不下。

signal handbook_closed(records: Dictionary)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const CONTENT_PATH := "res://data/story/employee_handbook.json"

const PAGE_W := 1348.0
const PAGE_H := 848.0
const RAIL_W := 330.0
## 整套字号的缩放档：2026-10-30 反馈「手册的字有点小」。
## 手册按 1920×1080 画，窗口一旦小于这个尺寸，canvas_items 拉伸会把整页再缩一道，
## 正文 19 号落到 1280 的窗口只剩 12 像素。字号统一抬一档，行高跟着同一档走，
## 以后要调只改这一个数。
const TYPE_SCALE := 1.18
const PAD := 64.0
const SCROLLBAR := 14.0
## 正文可用宽度：页面宽 - 左目录 - 左右内边距 - 滚动条
const CONTENT_W := PAGE_W - RAIL_W - PAD * 2.0 - SCROLLBAR

const PAPER := Color("efe4cf")
const PAPER_DARK := Color("e2d4b8")
const INK := Color("352b1e")
const INK_SOFT := Color("6d5c46")
const PENCIL := Color("7d6a52")
const RULE := Color("c8b694")

const CN_NUM := ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
## 停留不足这个时长就翻走 = 跳过（V5.27 埋点项）
const SKIP_THRESHOLD_MS := 1600

var _root: Control
var _rail: VBoxContainer
var _rail_scroll: ScrollContainer
var _rail_hint: Label
var _scroll: ScrollContainer
var _content: VBoxContainer
var _page_label: Label
var _data: Dictionary = {}
var _chapters: Array = []
var _current := ""
var _tab_buttons: Dictionary = {}
## 目录分三组（第一章 技术规范 / 第二章 协作流程 / 第三章 晋升通道）：
## 组数据、组标题按钮、组内条目容器，以及哪一组是展开的。
var _groups: Array = []
var _group_headers: Dictionary = {}
var _group_boxes: Dictionary = {}
var _expanded: Dictionary = {}
var _visited: Dictionary = {}
var _dwell_ms: Dictionary = {}
var _enter_ms := 0
var _open_ms := 0


func _ready() -> void:
	layer = 160
	_root = Control.new()
	_root.name = "HandbookOverlay"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_build_shell()
	_root.hide()


func open(data: Dictionary = {}) -> void:
	_data = data if not data.is_empty() else _load_default()
	_chapters = _data.get("chapters", []) as Array
	_visited.clear()
	_dwell_ms.clear()
	_open_ms = Time.get_ticks_msec()
	_enter_ms = _open_ms
	_current = ""
	_build_rail()
	var first := ""
	if not _chapters.is_empty():
		first = String(Dictionary(_chapters[0]).get("id", ""))
	_select_chapter(first)
	_root.show()


func close() -> void:
	if not _root.visible:
		return
	_settle_current()
	_root.hide()
	handbook_closed.emit(_records())


func is_open() -> bool:
	return _root != null and _root.visible


## 剧情点了名的那一页（手册节点解锁、E19 想起 3.3）直接翻到它，
## 玩家不用自己在一列目录里找。找不到就停在当前页，不报错。
func show_page(page_id: String) -> void:
	if page_id.is_empty() or not is_open():
		return
	if _chapter_data(page_id).is_empty():
		return
	_select_chapter(page_id)


func chapter_ids() -> Array:
	var ids: Array = []
	for chapter in _chapters:
		ids.append(String(Dictionary(chapter).get("id", "")))
	return ids


# ---------------------------------------------------------------- 骨架

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.05, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var page := Panel.new()
	page.name = "Page"
	page.size = Vector2(PAGE_W, PAGE_H)
	page.add_theme_stylebox_override("panel", _paper_style())
	_root.add_child(page)
	var size := _view_size()
	page.position = Vector2(round((size.x - PAGE_W) * 0.5), round((size.y - PAGE_H) * 0.5))

	# 装订线：册子中间那道折痕。有它才像"册子"，没它就是"弹窗"。
	var spine := ColorRect.new()
	spine.color = Color(0.0, 0.0, 0.0, 0.10)
	spine.position = Vector2(RAIL_W, 0)
	spine.size = Vector2(2, PAGE_H)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(spine)
	var spine_hi := ColorRect.new()
	spine_hi.color = Color(1, 1, 1, 0.22)
	spine_hi.position = Vector2(RAIL_W + 2, 0)
	spine_hi.size = Vector2(2, PAGE_H)
	spine_hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(spine_hi)

	# 目录：十四条目按三章分组，收起时只有三行；全展开仍可能顶出下沿，所以这一列本身要能滚。
	# 「目 录」和底下那句铅笔提示钉住不动，只有中间那一列滚。
	var rail_head := _label("目 录", 18, INK_SOFT, false, RAIL_W - 48.0)
	rail_head.position = Vector2(24, 84)
	rail_head.size = Vector2(RAIL_W - 48, 30)
	page.add_child(rail_head)

	_rail_scroll = ScrollContainer.new()
	_rail_scroll.name = "RailScroll"
	_rail_scroll.position = Vector2(18, 112)
	_rail_scroll.size = Vector2(RAIL_W - 36, PAGE_H - 112.0 - 118.0)
	_rail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rail_scroll.follow_focus = true
	_rail_scroll.add_theme_constant_override("scrollbar_width", 8)
	page.add_child(_rail_scroll)

	_rail = VBoxContainer.new()
	_rail.name = "Rail"
	_rail.custom_minimum_size = Vector2(RAIL_W - 48, 0)
	_rail.add_theme_constant_override("separation", 6)
	_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail_scroll.add_child(_rail)

	_rail_hint = _label("", 15, PENCIL, false, RAIL_W - 48.0)
	_rail_hint.name = "RailHint"
	_rail_hint.position = Vector2(24, PAGE_H - 104.0)
	_rail_hint.size = Vector2(RAIL_W - 48, 60)
	_rail_hint.add_theme_constant_override("line_spacing", 4)
	page.add_child(_rail_hint)

	_scroll = ScrollContainer.new()
	_scroll.name = "ContentScroll"
	_scroll.position = Vector2(RAIL_W + PAD, 54)
	_scroll.size = Vector2(PAGE_W - RAIL_W - PAD * 2, PAGE_H - 148)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_theme_constant_override("scrollbar_width", 10)
	page.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 16)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_content)

	_page_label = _label("", 17, INK_SOFT, false, 700.0)
	_page_label.position = Vector2(RAIL_W + PAD, PAGE_H - 66)
	_page_label.size = Vector2(700, roundi(30 * TYPE_SCALE))
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page.add_child(_page_label)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "合上手册"
	close_button.size = Vector2(190, 56)
	close_button.position = Vector2(PAGE_W - 190 - PAD, PAGE_H - 74)
	_style_close(close_button)
	close_button.pressed.connect(close)
	page.add_child(close_button)


## 目录按三章分组（2026-10-30 定：甲）。
## 数据里 14 条本来就自带章号（id 是 1.1 / 2.3，副标题写着「第一章 · 技术规范」），
## 以前却把它们平铺成「第 1 章…第 14 章」，于是目录说"第 2 章"、正文说"第一章 §1.2"、
## 剧情里王哥说"手册第一章第二条下面那句铅笔字"——三套编号互相打架。
## 分组后目录平时只有三行，条目写成「第一条…第五条」，跟正文和剧情都对得上。
func _build_rail() -> void:
	for child in _rail.get_children():
		child.queue_free()
	_tab_buttons.clear()
	_group_headers.clear()
	_group_boxes.clear()
	_groups = _group_chapters()
	_rail_hint.text = String(_data.get("marginHint", ""))
	for group in _groups:
		var key := String(group.get("key", ""))
		var header := Button.new()
		header.name = "Group_%s" % key
		header.custom_minimum_size = Vector2(RAIL_W - 48, roundi(34 * TYPE_SCALE))
		header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		header.focus_mode = Control.FOCUS_NONE
		_style_group_header(header)
		header.pressed.connect(func(): _toggle_group(key))
		_rail.add_child(header)
		_group_headers[key] = header
		var box := VBoxContainer.new()
		box.name = "GroupItems_%s" % key
		box.add_theme_constant_override("separation", 6)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rail.add_child(box)
		_group_boxes[key] = box
		for raw_entry in group.get("ids", []) as Array:
			var entry := String(raw_entry)
			var data := _chapter_data(entry)
			var button := Button.new()
			button.name = "Tab_%s" % entry
			# 条号写在前面：玩家听到的是"第一章第三条"，看到的就该是"第三条 …"。
			# 一组只有一条时不摆条号（旧 48 个月那本就是一章一条）。
			var entry_title := String(data.get("title", ""))
			button.text = entry_title if (group.get("ids", []) as Array).size() <= 1 else "%s　%s" % [_ordinal(_clause_no(entry)), entry_title]
			button.custom_minimum_size = Vector2(RAIL_W - 62, roundi(44 * TYPE_SCALE))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			# 条目按两行的高度起排（Button 没有"最多几行"这个开关，只能靠最小高度 +
			# 手风琴一次只摊一章，把整列压在视口里）；标题真超过两行时这行会长，目录能滚。
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.focus_mode = Control.FOCUS_NONE
			_style_tab(button, false)
			button.pressed.connect(func(): _select_chapter(entry))
			box.add_child(button)
			_tab_buttons[entry] = button
	_refresh_rail()
	if is_instance_valid(_rail_scroll):
		_rail_scroll.scroll_vertical = 0


## 按 id 前缀（"1." / "2." / "3."）把十四条目归成三组，组名直接取条目自带的副标题。
func _group_chapters() -> Array:
	var groups: Array = []
	var by_key := {}
	for raw_chapter in _chapters:
		var data := Dictionary(raw_chapter)
		var id := String(data.get("id", ""))
		var key := _group_key_of(id)
		if key.is_empty():
			continue
		if not by_key.has(key):
			var group := {"key": key, "title": String(data.get("subtitle", "第 %s 章" % key)), "ids": []}
			by_key[key] = group
			groups.append(group)
		(by_key[key] as Dictionary)["ids"].append(id)
	return groups


func _group_key_of(chapter_id: String) -> String:
	if chapter_id.is_empty():
		return ""
	var parts := chapter_id.split(".")
	# "1.1" 归第一章；旧 48 个月那本的 id 是 tech / process，没有点号，自己就是一组。
	return String(parts[0])


func _clause_no(chapter_id: String) -> int:
	var parts := chapter_id.split(".")
	return int(parts[1]) if parts.size() > 1 else 0


func _ordinal(value: int) -> String:
	if value <= 0:
		return "本条"
	if value <= 10:
		return "第%s条" % CN_NUM[value]
	if value < 20:
		return "第十%s条" % CN_NUM[value - 10]
	return "第 %d 条" % value


## 一次只摊开一章：14 条全平铺是这次要解决的问题，两组同时展开又会互相挤。
## 所以点组名 = 换一章摊开；再点一次已经摊开的那章 = 收起来，只剩三行。
func _toggle_group(key: String) -> void:
	if key.is_empty():
		return
	var was_open := bool(_expanded.get(key, false))
	for group in _groups:
		_expanded[String(Dictionary(group).get("key", ""))] = false
	if not was_open:
		_expanded[key] = true
	_refresh_rail()


## 选中某条时把它所属那组摊开、其余收回，
## 剧情里那句"翻到第一章第三条"才是点一下就到、且看得见选中框。
func _ensure_group_open(key: String) -> void:
	if key.is_empty() or bool(_expanded.get(key, false)):
		return
	for group in _groups:
		_expanded[String(Dictionary(group).get("key", ""))] = false
	_expanded[key] = true
	_refresh_rail()


## 展开只改可见性，标题上的箭头和"几条"跟着重画一遍。
func _refresh_rail() -> void:
	for raw_group in _groups:
		var group := Dictionary(raw_group)
		var key := String(group.get("key", ""))
		var header: Button = _group_headers.get(key, null)
		if header == null:
			continue
		var is_open := bool(_expanded.get(key, false))
		var ids := group.get("ids", []) as Array
		header.text = "%s%s　%d 条" % ["▾ " if is_open else "▸ ", _group_short_title(String(group.get("title", ""))), ids.size()]
		var box: VBoxContainer = _group_boxes.get(key, null)
		if box != null:
			box.visible = is_open


## 组标题在目录里只留"第一章"这一段，"· 技术规范"跟在后面会挤成三行。
func _group_short_title(subtitle: String) -> String:
	var parts := subtitle.split(" · ")
	return String(parts[0]) if parts.size() > 1 else subtitle


func _style_group_header(button: Button) -> void:
	button.add_theme_font_override("font", _bold(FONT, 0.5))
	button.add_theme_font_size_override("font_size", roundi(19 * TYPE_SCALE))
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color("171208"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.0)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 4
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = PAPER_DARK
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)


# ---------------------------------------------------------------- 章节

func _select_chapter(chapter_id: String) -> void:
	if chapter_id.is_empty() or chapter_id == _current:
		return
	_settle_current()
	_current = chapter_id
	_enter_ms = Time.get_ticks_msec()
	_visited[chapter_id] = true
	if not _dwell_ms.has(chapter_id):
		_dwell_ms[chapter_id] = 0
	for key in _tab_buttons.keys():
		var button: Button = _tab_buttons[key]
		if is_instance_valid(button):
			_style_tab(button, String(key) == chapter_id)
	# 先撑开所属那一组，再滚到这一条：从剧情里跳"第一章第三条"时两步并一步。
	_ensure_group_open(_group_key_of(chapter_id))
	_render_chapter(_chapter_data(chapter_id))
	# 目录是能滚的一列：从剧情里直接跳到第 8 章时，要把那一章滚到眼前，
	# 不然选中框在看不见的地方，玩家以为目录没反应。布局要下一帧才算好，所以延后。
	_reveal_tab.call_deferred(chapter_id)
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = 0
	if is_instance_valid(_page_label):
		# 页脚按"第几章第几条"报，跟目录、正文、剧情台词同一套编号。
		var page_data := _chapter_data(chapter_id)
		var clause_no := _clause_no(chapter_id)
		var clause_text := _ordinal(clause_no) if clause_no > 0 else ""
		_page_label.text = "%s%s　|　共 %d 章 %d 条　|　%s" % [
			String(page_data.get("subtitle", "")),
			("　" + clause_text) if not clause_text.is_empty() else "",
			_groups.size(), _chapters.size(), String(_data.get("edition", "")),
		]


## 把某一章的目录按钮滚到可见范围里。布局要下一帧才算得准，调用方用 deferred。
func _reveal_tab(chapter_id: String) -> void:
	if not _tab_buttons.has(chapter_id) or not is_instance_valid(_rail_scroll):
		return
	var button: Button = _tab_buttons[chapter_id]
	if not is_instance_valid(button):
		return
	var view := _rail_scroll.size.y
	# 条目现在住在组容器里，position.y 是组内坐标；按全局坐标折算回整列的位置。
	var top := button.get_global_position().y - _rail.get_global_position().y + float(_rail_scroll.scroll_vertical)
	var bottom := top + button.size.y
	var scroll := float(_rail_scroll.scroll_vertical)
	if top < scroll:
		_rail_scroll.scroll_vertical = int(maxf(top - 12.0, 0.0))
	elif bottom > scroll + view:
		_rail_scroll.scroll_vertical = int(bottom - view + 12.0)


func _settle_current() -> void:
	if _current.is_empty():
		return
	var spent := Time.get_ticks_msec() - _enter_ms
	_dwell_ms[_current] = int(_dwell_ms.get(_current, 0)) + spent


func _chapter_data(chapter_id: String) -> Dictionary:
	for chapter in _chapters:
		var data := Dictionary(chapter)
		if String(data.get("id", "")) == chapter_id:
			return data
	return {}


func _render_chapter(chapter: Dictionary) -> void:
	for child in _content.get_children():
		# 先摘出树再释放：只 queue_free 的话，同一帧内 get_children 仍返回旧节点，
		# 会和刚建好的新内容叠在一起显示一帧。
		_content.remove_child(child)
		child.queue_free()
	if chapter.is_empty():
		return
	var title := _label(String(chapter.get("title", "")), 34, INK, true, CONTENT_W)
	title.custom_minimum_size = Vector2(CONTENT_W, roundi(50 * TYPE_SCALE))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content.add_child(title)
	var sub := _label(String(chapter.get("subtitle", "")), 19, INK_SOFT, false, CONTENT_W)
	sub.custom_minimum_size = Vector2(CONTENT_W, roundi(30 * TYPE_SCALE))
	_content.add_child(sub)
	var lead := _label(String(chapter.get("lead", "")), 19, INK_SOFT, false, CONTENT_W)
	lead.custom_minimum_size = Vector2(CONTENT_W, roundi(28 * TYPE_SCALE))
	_content.add_child(lead)
	_content.add_child(_rule())

	for clause in chapter.get("clauses", []) as Array:
		_content.add_child(_build_clause(Dictionary(clause)))

	# 铅笔批注：读到章末才出现。它是"有人用过这本册子"的证据。
	var margin := String(chapter.get("margin", ""))
	if not margin.is_empty():
		_content.add_child(_rule())
		_content.add_child(_build_margin_note(margin, String(_data.get("marginOwner", ""))))

	# 后记只印在最后一页：它说的是"册子到这儿就没了"，
	# 印在第一章中间（以前挂在 1.5 的 margin 上）等于告诉玩家后面不用翻了。
	var afterword := String(_data.get("afterword", ""))
	if not afterword.is_empty() and _is_last_chapter(String(chapter.get("id", ""))):
		_content.add_child(_rule())
		_content.add_child(_build_afterword(afterword))


func _is_last_chapter(chapter_id: String) -> bool:
	if _chapters.is_empty():
		return false
	return String(Dictionary(_chapters[_chapters.size() - 1]).get("id", "")) == chapter_id


func _build_clause(clause: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var number := _label("§%s" % String(clause.get("id", "")), 19, INK_SOFT, false, 58.0)
	number.custom_minimum_size = Vector2(68, roundi(30 * TYPE_SCALE))
	head.add_child(number)
	# 右端留白给铅笔批注。批注是【玩家可见】的一句人话（不含任何事件编号）。
	# HBox 列宽必须刚好等于 CONTENT_W：§号 68 + 间距 12×2 + 标题 + 批注 300。
	# 之前少减了 52px，批注被挤出内容区、压到滚动条上。
	var name_width := CONTENT_W - 392.0
	# 被划掉的条款：标题退成铅笔色、正文也跟着暗一档，再在标题上拉一道横线。
	# 它不进考场（examAt 为空），留着的用处是让玩家看见"这本册子有人不同意"。
	var struck := bool(clause.get("struck", false))
	var name := _label(String(clause.get("title", "")), 22, PENCIL if struck else INK, true, name_width)
	name.custom_minimum_size = Vector2(name_width, roundi(34 * TYPE_SCALE))
	head.add_child(name)
	if struck:
		_strike_label(name)
	var pencil := String(clause.get("pencil", ""))
	if not pencil.is_empty():
		# 旁注比正文小一号才像旁注（15 vs 19，抬一档后 18 vs 22）
		var tag := _label(pencil, 15, PENCIL, false, 300.0)
		tag.custom_minimum_size = Vector2(300, roundi(30 * TYPE_SCALE))
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tag.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		head.add_child(tag)
	box.add_child(head)
	var body_width := CONTENT_W - 80.0
	var body := _label(String(clause.get("body", "")), 19, PENCIL if struck else INK, false, body_width)
	body.custom_minimum_size = Vector2(body_width, 0)
	body.add_theme_constant_override("line_spacing", 8)
	box.add_child(body)
	return box


## 在标题上画一道手划的横线。Label 不是容器，子节点按像素摆就行：
## 宽度按当下字体量一遍（标题短，不会折行），高度挂在 resized 上——
## 建的时候 size 还没定，等 HBox 排完才算得准。
func _strike_label(label: Label) -> void:
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var line := ColorRect.new()
	line.name = "Strike"
	line.color = Color(PENCIL.r, PENCIL.g, PENCIL.b, 0.9)
	line.size = Vector2(10, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_child(line)
	var place := func() -> void:
		if not is_instance_valid(line) or not is_instance_valid(label):
			return
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		line.position = Vector2(0, round(label.size.y * 0.5) - 1.0)
		line.size = Vector2(minf(width, label.size.x), 2)
	label.resized.connect(place)
	place.call_deferred()


## 最后一页末尾那句"手册到这里就结束了"。它不是王哥的铅笔字，
## 所以不用批注框，只用铅笔色、跟前文留开一点。
func _build_afterword(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body_width := CONTENT_W - 80.0
	var body := _label(text, 19, PENCIL, false, body_width)
	body.custom_minimum_size = Vector2(body_width, 0)
	body.add_theme_constant_override("line_spacing", 8)
	box.add_child(body)
	return box


func _build_margin_note(text: String, owner_name: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := _label("［%s 的铅笔字］" % owner_name, 15, PENCIL, false, CONTENT_W)
	head.custom_minimum_size = Vector2(CONTENT_W, roundi(26 * TYPE_SCALE))
	box.add_child(head)
	var body_width := CONTENT_W - 80.0
	var body := _label(text, 19, PENCIL, false, body_width)
	body.custom_minimum_size = Vector2(body_width, 0)
	body.add_theme_constant_override("line_spacing", 8)
	box.add_child(body)
	return box


func _rule() -> Control:
	var line := ColorRect.new()
	line.color = RULE
	line.custom_minimum_size = Vector2(CONTENT_W, 1)
	line.size = Vector2(CONTENT_W, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


# ---------------------------------------------------------------- 埋点

func _records() -> Dictionary:
	var chapters := {}
	for chapter in _chapters:
		var id := String(Dictionary(chapter).get("id", ""))
		var dwell := int(_dwell_ms.get(id, 0))
		var seen := bool(_visited.get(id, false))
		chapters[id] = {
			"visited": seen,
			"dwellMs": dwell,
			"skipped": (not seen) or dwell < SKIP_THRESHOLD_MS,
		}
	return {
		"totalMs": Time.get_ticks_msec() - _open_ms,
		"chapters": chapters,
	}


# ---------------------------------------------------------------- 零件

func _load_default() -> Dictionary:
	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_warning("HandbookPanel: 读不到 %s" % CONTENT_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return Dictionary(parsed)
	return {}


func _view_size() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2(1920, 1080)
	return vp.get_visible_rect().size


func _bold(font: Font, weight: float) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = font
	variation.variation_embolden = weight
	return variation


## wrap_width 必须在创建时就给对：autowrap 的最小高度按当时的 size.x 算，
## 先给 320 再被容器拉到 900 的话，高度会按 320 算，正文被底边切掉。
func _label(value: String, font_size: int, color: Color, bold: bool = false, wrap_width: float = 320.0) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(wrap_width, roundi(40 * TYPE_SCALE))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _bold(FONT, 0.6) if bold else FONT)
	label.add_theme_font_size_override("font_size", roundi(font_size * TYPE_SCALE))
	label.add_theme_color_override("font_color", color)
	return label


func _paper_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color(0.28, 0.22, 0.15, 0.85)
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _style_tab(button: Button, active: bool) -> void:
	button.add_theme_font_override("font", _bold(FONT, 0.6) if active else FONT)
	button.add_theme_font_size_override("font_size", roundi(20 * TYPE_SCALE))
	button.add_theme_color_override("font_color", PAPER if active else INK)
	button.add_theme_color_override("font_hover_color", PAPER if active else Color("171208"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.0) if not active else Color("4a3b28")
	normal.border_color = Color(1, 1, 1, 0.0) if not active else Color("2a2115")
	normal.set_border_width_all(0 if not active else 2)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 14
	normal.content_margin_right = 10
	# 上下内边距从 10 收到 6：目录一列有 14 条，每条多 8 像素就少说两行组名。
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("5d4a31") if active else PAPER_DARK
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)


func _style_close(button: Button) -> void:
	button.add_theme_font_override("font", _bold(FONT, 0.5))
	button.add_theme_font_size_override("font_size", roundi(19 * TYPE_SCALE))
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color("171208"))
	button.add_theme_stylebox_override("normal", _close_box(PAPER_DARK))
	button.add_theme_stylebox_override("hover", _close_box(Color("d6c5a3")))
	button.add_theme_stylebox_override("pressed", _close_box(Color("c9b795")))


func _close_box(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.32, 0.25, 0.17, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style
