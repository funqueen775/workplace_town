extends Control

## 入职预演 + 入职登记：接在三页导览之后、选择形象之前。
## 前两道是情境预演（不写档案）；后面五题是登记表，老周念一句、你勾一档，
## 答案进 `ratings`，开局档案带着它，第 12 月报告拿它当先验（开发册 §4.27）。

signal finished
signal back_requested

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const INTRO_DIALOG_BG := preload("res://assets/对话框/角色对话框_空白.png")
const INTRO_BUTTON_PRIMARY := preload("res://assets/ui/rework_v1/task_book/20_推进按钮底板.png")
const INTRO_BUTTON_SECONDARY := preload("res://assets/ui/rework_v1/task_book/18_追踪按钮底板.png")
const LIN_ROOM := preload("res://assets/八大区域地图重制版/C_销售部.png")
const ZHOU_ROOM := preload("res://assets/八大区域地图重制版/D_人事部.png")
const LIN_PORTRAITS := [
	preload("res://assets/角色立绘/小林/小林_自然.png"),
	preload("res://assets/角色立绘/小林/小林_认真.png"),
	preload("res://assets/角色立绘/小林/小林_开心.png"),
	preload("res://assets/角色立绘/小林/小林_疑惑.png"),
]
const ZHOU_PORTRAITS := [
	preload("res://assets/角色立绘/老周/老周_认真.png"),
	preload("res://assets/角色立绘/老周/老周_疑惑.png"),
	preload("res://assets/角色立绘/老周/老周_无奈.png"),
]

const PAPER := Color("f6e6bd")
const INK := Color("4a2b1a")
const WOOD := Color("5b321f")
const BRICK := Color("b95035")
const BRICK_HOVER := Color("cf6247")
const BRICK_PRESSED := Color("8f3a26")
const EDGE := Color("2e1a12")
const CREAM_TXT := Color("fff4d5")
const SECOND_BG := Color("f1ddb0")
const SECOND_BG_HOVER := Color("fff0cc")
const SECOND_EDGE := Color("9a6a42")

## 登记表题库：题项原文来自 IPIP 公版标志物（每维 1 题）。
const SELFREPORT_PATH := "res://data/story/v12m/selfreport.json"

const PAGES := [
	{"title": "先问什么", "speaker": "小林", "role": "产品同事", "place": "销售部", "room": LIN_ROOM,
	 "portrait": LIN_PORTRAITS, "question": "客户刚发来新想法，但我们还不知道他最在意什么。你会先？",
	 "choices": ["问清真正需求", "找同事估算", "做个草案给客户看"],
	 "replies": ["好，我把客户叫回来，我们先问明白。", "我去约大家，先看看这事需要多少时间。", "可以，先让客户看到一个能讨论的东西。"],
	 "expressions": [3, 1, 2]},
	{"title": "从哪里开始", "speaker": "老周", "role": "资深同事", "place": "人事部", "room": ZHOU_ROOM,
	 "portrait": ZHOU_PORTRAITS, "question": "大家对同一件事有不同说法。复盘该从哪里开始？",
	 "choices": ["先听各方说法", "先整理事实", "先提出自己的判断"],
	 "replies": ["先听完，再看哪些地方说得不一样。", "有了事实，讨论才不会只剩立场。", "说说看。也别忘了听听别人的依据。"],
	 "expressions": [1, 0, 2]},
]

var _page := 0
## 每题选中的档位（页号 → 0..4）；登记表那几题的答案另存进 `ratings`。
var _answers := {}
var _fonts: Dictionary = {}
## 登记表五题（由 selfreport.json 生成），跑完拼在两道预演后面。
var _registry_pages: Array = []
## trait → 1..5。跳过就是空表：报告按"没答"处理，不许当成答了中间那档。
var ratings := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_registry()
	_rebuild()


## 全部题目 = 两道预演 + 登记表五题。读不到题库就只剩预演，不拦人入职。
func _all_pages() -> Array:
	return PAGES + _registry_pages


func _load_registry() -> void:
	if not _registry_pages.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SELFREPORT_PATH))
	if not (parsed is Dictionary):
		push_warning("读不到 %s，登记表这几题跳过" % SELFREPORT_PATH)
		return
	var data := parsed as Dictionary
	var scale: Array = (data.get("scale", []) as Array)
	var items: Array = (data.get("items", []) as Array)
	if scale.size() != 5:
		push_warning("登记表量表不是五点，跳过这几题")
		return
	for value in items:
		var item := Dictionary(value)
		var statement := String(item.get("text", "")).strip_edges()
		if statement.is_empty():
			continue
		_registry_pages.append({
			"kind": "registry",
			"speaker": "老周",
			"role": "资深同事",
			"place": "人事部",
			"room": ZHOU_ROOM,
			"portrait": ZHOU_PORTRAITS,
			"question": "「%s」——这句你勾哪一档？" % statement,
			"choices": scale,
			"expressions": [0, 0, 0, 0, 0],
			"trait": String(item.get("trait", "")),
		})

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var frame := Panel.new()
	_layout_startup_frame(frame)
	frame.add_theme_stylebox_override("panel", _style(PAPER, WOOD, 8, 8))
	add_child(frame)

	var back := _intro_button("返回", "secondary")
	back.position = Vector2(36, 34)
	back.size = Vector2(132, 60)
	back.pressed.connect(func() -> void:
		if _page == 0:
			back_requested.emit()
		else:
			_page -= 1
			_rebuild())
	frame.add_child(back)

	var pages := _all_pages()
	var registry := _page >= PAGES.size()
	var heading := _label("入职登记" if registry else "入职预演", 34, INK, 0.0, 0.16)
	heading.position = Vector2(300, 34)
	heading.size = Vector2(1100, 51)
	frame.add_child(heading)

	var sub := _label("登记表上五句话，勾你第一反应；没有对错，也不打分。"
		if registry else "两个选择，先认识这里的同事；预演不计入正式测评", 18, Color("7a5533"))
	sub.position = Vector2(300, 90)
	sub.size = Vector2(1100, 27)
	frame.add_child(sub)

	var step := _label("%d / %d" % [_page + 1, pages.size()], 22, BRICK, 0.0, 0.12)
	step.position = Vector2(1460, 46)
	step.size = Vector2(170, 42)
	frame.add_child(step)

	_scenario_content(frame, Dictionary(pages[_page]))
	_footer(frame)

func _scenario_content(frame: Panel, page: Dictionary) -> void:
	var is_registry := String(page.get("kind", "")) == "registry"
	var room := TextureRect.new()
	room.texture = page["room"] as Texture2D
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	room.position = Vector2(95, 198)
	room.size = Vector2(1510, 430)
	room.modulate = Color(0.78, 0.78, 0.78)
	frame.add_child(room)

	var shade := ColorRect.new()
	shade.color = Color(0.10, 0.07, 0.05, 0.27)
	shade.position = room.position
	shade.size = room.size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(shade)

	var answer_index: int = int(_answers.get(_page, -1))
	var portraits: Array = page["portrait"]
	var portrait := TextureRect.new()
	portrait.texture = portraits[0 if answer_index < 0 else int(page["expressions"][answer_index])] as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(125, 204)
	portrait.size = Vector2(450, 420)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)

	var card := _intro_dialog_panel()
	card.position = Vector2(480, 280)
	card.size = Vector2(1090, 300)
	frame.add_child(card)

	var place := _label(String(page["place"]) + "  ·  " + String(page["role"]), 19, BRICK)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	place.position = Vector2(300, 42)
	place.size = Vector2(650, 34)
	card.add_child(place)

	var speaker := _label(String(page["speaker"]), 34, INK, 0.0, 0.2)
	speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	speaker.position = Vector2(90, 85)
	speaker.size = Vector2(760, 48)
	card.add_child(speaker)

	# 登记表答完仍显示原题（让玩家看得见自己勾了哪一档）；预演答完换成对方的回应。
	var line := String(page["question"])
	if answer_index >= 0 and not is_registry:
		line = String(page["replies"][answer_index])
	var dialogue := _label(line, 27, INK)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.position = Vector2(90, 144)
	dialogue.size = Vector2(900, 104)
	card.add_child(dialogue)

	if answer_index >= 0 and not is_registry:
		# 两道预演答完，老周把登记表递过来——下一屏起就是那五句话。
		# 这句台词原样留着（StartupFlowTest 盯着它），现在它底下真有一张表了。
		if _page == PAGES.size() - 1:
			var handoff := _label("老周递来入职登记表：选好自己的形象，就正式上班。", 25, INK)
			handoff.position = Vector2(360, 658)
			handoff.size = Vector2(980, 72)
			frame.add_child(handoff)
		return

	var choices: Array = page["choices"]
	# 预演是三颗大按钮；登记表一句五档，改成一行五颗窄一点的，字也收一号。
	var slot := 250.0 if is_registry else 380.0
	var stride := 265.0 if is_registry else 410.0
	var font_size := 20 if is_registry else 24
	# 一整排居中：总宽 = 间距 ×(颗数 − 1) + 一颗的宽，别把间距重复算进去
	var span := stride * float(maxi(0, choices.size() - 1)) + slot
	var start_x := 255.0 + (1190.0 - span) * 0.5
	for index in choices.size():
		var chosen := index == answer_index
		var choice := _intro_button(String(choices[index]), "primary" if chosen else "secondary")
		choice.position = Vector2(start_x + index * stride, 660)
		choice.size = Vector2(slot, 82)
		choice.add_theme_font_size_override("font_size", font_size)
		choice.pressed.connect(_choose_answer.bind(index))
		frame.add_child(choice)

func _choose_answer(index: int) -> void:
	var pages := _all_pages()
	if _page < 0 or _page >= pages.size():
		return
	var page := Dictionary(pages[_page])
	# 预演一题只认第一次选择（要看的是情境反应，不是反复试）；登记表可以改勾。
	if String(page.get("kind", "")) != "registry" and int(_answers.get(_page, -1)) >= 0:
		return
	_answers[_page] = index
	if String(page.get("kind", "")) == "registry":
		# 注意：trait 在 GDScript 4.7 是保留字，变量只能叫 trait_key
		var trait_key := String(page.get("trait", ""))
		if not trait_key.is_empty():
			ratings[trait_key] = index + 1
	_rebuild()

func _footer(frame: Panel) -> void:
	var counter := _label("第 %d / %d 题" % [_page + 1, _all_pages().size()], 18, Color("7a5533"))
	counter.size = Vector2(180, 60)
	counter.position = Vector2(102, 828)
	frame.add_child(counter)

	var hint := _label("这几句会写进档案，第 12 月报告拿它对照"
		if _page >= PAGES.size() else "预演选择不计入正式测评", 18, Color("7a5533"))
	hint.position = Vector2(510, 828)
	hint.size = Vector2(550, 60)
	frame.add_child(hint)

	var previous := _intro_button("上一题", "secondary")
	previous.position = Vector2(1170, 828)
	previous.size = Vector2(135, 60)
	previous.pressed.connect(func() -> void:
		if _page == 0:
			back_requested.emit()
		else:
			_page -= 1
			_rebuild())
	frame.add_child(previous)

	var clear := _intro_button("这题不勾", "secondary")
	clear.position = Vector2(985, 828)
	clear.size = Vector2(170, 60)
	clear.visible = _page >= PAGES.size()
	clear.pressed.connect(func() -> void:
		ratings.erase(String(Dictionary(_all_pages()[_page]).get("trait", "")))
		_answers.erase(_page)
		_rebuild())
	frame.add_child(clear)

	var skip := _intro_button("跳过", "secondary")
	skip.position = Vector2(1315, 828)
	skip.size = Vector2(120, 60)
	skip.pressed.connect(func() -> void: finished.emit())
	frame.add_child(skip)

	var last := _all_pages().size() - 1
	var next := _intro_button("去选择形象" if _page == last else "继续")
	next.position = Vector2(1445, 828)
	next.size = Vector2(200, 60)
	next.disabled = int(_answers.get(_page, -1)) < 0
	next.pressed.connect(func() -> void:
		if _page >= last:
			finished.emit()
		else:
			_page += 1
			_rebuild())
	frame.add_child(next)

# ------------------------------------------------------------------ 零件

func _layout_startup_frame(frame: Panel) -> void:
	frame.size = Vector2(1700, 968)
	var layout := func() -> void:
		var factor: float = minf((size.x - 32.0) / frame.size.x, (size.y - 32.0) / frame.size.y)
		frame.scale = Vector2.ONE * factor
		frame.position = (size - frame.size * factor) * 0.5
	resized.connect(layout)
	frame.tree_exiting.connect(func() -> void: resized.disconnect(layout))
	layout.call()

func _font_weighted(amount: float) -> Font:
	if amount <= 0.0:
		return FONT
	var key := int(round(amount * 100.0))
	if not _fonts.has(key):
		var fv := FontVariation.new()
		fv.base_font = FONT
		fv.variation_embolden = amount
		_fonts[key] = fv
	return _fonts[key]

func _label(value: String, font_size: int, color: Color, outline := 0.0, weight := 0.0) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _font_weighted(weight))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0.0:
		label.add_theme_color_override("font_outline_color", Color(PAPER, 0.85))
		label.add_theme_constant_override("outline_size", int(outline))
	return label

func _intro_dialog_panel() -> NinePatchRect:
	var panel := NinePatchRect.new()
	var cropped := AtlasTexture.new()
	cropped.atlas = INTRO_DIALOG_BG
	cropped.region = Rect2(20, 145, 2132, 440)
	panel.texture = cropped
	panel.patch_margin_left = 120
	panel.patch_margin_top = 55
	panel.patch_margin_right = 120
	panel.patch_margin_bottom = 55
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _intro_button(value: String, kind := "primary") -> Button:
	var button := _button(value, kind)
	var source := INTRO_BUTTON_PRIMARY if kind == "primary" or kind == "tab_on" else INTRO_BUTTON_SECONDARY
	var crop := Rect2(155, 168, 1625, 460) if source == INTRO_BUTTON_PRIMARY else Rect2(202, 231, 1370, 440)
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = crop
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxTexture.new()
		style.texture = texture
		if state == "pressed":
			style.modulate_color = Color(0.85, 0.79, 0.72)
		elif state == "disabled":
			style.modulate_color = Color(0.72, 0.68, 0.63, 0.75)
		elif state == "hover":
			style.modulate_color = Color(1.08, 1.06, 1.02)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("786b57"))
	return button

func _button(value: String, kind := "primary") -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _font_weighted(0.16))
	button.add_theme_color_override("font_outline_color", EDGE)
	button.add_theme_constant_override("outline_size", 4)
	match kind:
		"primary":
			button.custom_minimum_size = Vector2(0, 68)
			button.add_theme_font_size_override("font_size", 30)
			button.add_theme_color_override("font_color", CREAM_TXT)
			button.add_theme_color_override("font_hover_color", Color("fffdf2"))
			button.add_theme_stylebox_override("normal", _style(BRICK, EDGE, 3, 6, 5))
			button.add_theme_stylebox_override("hover", _style(BRICK_HOVER, EDGE, 3, 6, 6))
			button.add_theme_stylebox_override("pressed", _style(BRICK_PRESSED, EDGE, 3, 6, 0))
		"secondary":
			button.custom_minimum_size = Vector2(0, 58)
			button.add_theme_font_size_override("font_size", 24)
			button.add_theme_color_override("font_color", INK)
			button.add_theme_color_override("font_hover_color", INK)
			button.add_theme_stylebox_override("normal", _style(SECOND_BG, SECOND_EDGE, 3, 6, 4))
			button.add_theme_stylebox_override("hover", _style(SECOND_BG_HOVER, SECOND_EDGE, 3, 6, 5))
			button.add_theme_stylebox_override("pressed", _style(Color("e2c894"), SECOND_EDGE, 3, 6, 0))
	button.add_theme_stylebox_override("disabled", _style(Color(0.84, 0.78, 0.65), Color("a9977c"), 3, 6))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.4, 0.34))
	return button

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
