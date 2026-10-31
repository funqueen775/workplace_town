class_name PlaceVisitPanel
extends CanvasLayer

## 地点访问面板提供两种页型：
## ① 解锁讲解卡——适用于后续剧情逐处开放地点时（歪斜纸片 + 三行 + 真实截图）；
## ② 进门确认页——活动名 + 一句结果预告 + 代价行 + 就做这个 / 先回去。首月只使用确认页。
## 只负责演出与拿选择，行动点与旗标结算全部交回 WorkplaceTown。

signal unlock_dismissed(activity_id: String)
signal navigate_requested(zone_code: String)
signal activity_confirmed(activity_id: String)
signal activity_declined()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const HAND_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const TAPE_TEX := preload("res://assets/ui/ledger/tape_tex.png")
const PAPER := Color("f6e6bd")
const INK := Color("4a2b1a")
const WEAK_INK := Color("634330")
const WOOD := Color("5b321f")
const BRICK := Color("b95035")
const CARD_SIZE := Vector2(1180, 620)


func _ready() -> void:
	layer = 152
	var root := Control.new()
	root.name = "PlaceVisitRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.hide()


func is_open() -> bool:
	return get_node_or_null("PlaceVisitRoot") != null and get_node("PlaceVisitRoot").visible


func close() -> void:
	if get_node_or_null("PlaceVisitRoot") != null:
		get_node("PlaceVisitRoot").hide()


## ① 解锁讲解卡。card = activities.json 里的 card 字段（title / lines / shots）。
func show_unlock(activity: Dictionary, navigate := true) -> void:
	var card: Dictionary = activity.get("card", {}) as Dictionary
	var lines: Array = card.get("lines", []) as Array
	var paper := _open_sheet(-3.0)
	var heading := _label("解 锁", 96, Color("F3E3C2"), HAND_FONT)
	heading.position = Vector2(-18, 18)
	heading.size = Vector2(420, 120)
	paper.add_child(heading)
	var name_bar := Panel.new()
	name_bar.position = Vector2(70, 158)
	name_bar.size = Vector2(760, 56)
	name_bar.rotation_degrees = -3.0
	name_bar.add_theme_stylebox_override("panel", _style(Color("fff8e8"), WOOD, 3, 4))
	paper.add_child(name_bar)
	var place := _label(String(card.get("title", activity.get("name", ""))), 34, INK)
	place.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_bar.add_child(place)
	var y := 246.0
	for line in lines:
		# 纸片是深灰底，正文必须用米白——用深褐等于写在黑纸上看不见。
		var row := _label(String(line), 28, Color("F3E3C2"))
		row.position = Vector2(76, y)
		row.size = Vector2(700, 44)
		row.add_theme_constant_override("line_spacing", 4)
		paper.add_child(row)
		y += 52.0
	# 卡上贴真实游戏截图：白边、各自歪一点、压在纸片右下并出血。
	var shots: Array = card.get("shots", []) as Array
	var shot_x := 792.0
	for index in shots.size():
		var path := "res://assets/ui/place_cards/%s" % String(shots[index])
		if not ResourceLoader.exists(path):
			continue
		var frame := Panel.new()
		frame.position = Vector2(shot_x + index * 34.0, 300.0 + index * 46.0)
		frame.size = Vector2(330, 224)
		frame.rotation_degrees = 4.0 if index == 0 else -2.0
		frame.add_theme_stylebox_override("panel", _style(Color.WHITE, Color("d8c3a0"), 6, 2))
		paper.add_child(frame)
		var art := TextureRect.new()
		art.texture = load(path) as Texture2D
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.clip_contents = true
		art.size = Vector2(318, 212)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(art)
		var tape := TextureRect.new()
		tape.texture = TAPE_TEX
		tape.position = Vector2(96, -16)
		tape.size = Vector2(150, 44)
		tape.rotation_degrees = -8.0
		tape.modulate.a = 0.92
		tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tape)
	_page_button(paper, "知道了", Vector2(76, 512), Vector2(240, 62), true,
		_on_unlock_ok.bind(String(activity.get("id", ""))))
	if navigate:
		var zone_code := String(activity.get("locationId", ""))
		_page_button(paper, "带我去", Vector2(336, 512), Vector2(220, 62), false, _on_go_there.bind(zone_code))


func _on_unlock_ok(activity_id: String) -> void:
	close()
	unlock_dismissed.emit(activity_id)


func _on_go_there(zone_code: String) -> void:
	close()
	navigate_requested.emit(zone_code)


## ② 进门确认页。这一页用暖纸底（和月末卡同一套），不是讲解卡那种深灰拼贴。
## mood 是心情 H；首月还没有心情账本，缺省按宽裕处理。
## slots_left >= 0 = 十二个月那套「格」口径。
func show_confirm(activity: Dictionary, mood := 3, slots_left := -1) -> void:
	var paper := _open_sheet(0.0, false)
	var kicker := _label("到了 · %s" % String(activity.get("location", "")), 30, BRICK)
	kicker.position = Vector2(70, 50)
	kicker.size = Vector2(760, 40)
	paper.add_child(kicker)
	var title := _label(String(activity.get("name", "自由活动")), 40, INK)
	title.position = Vector2(70, 92)
	title.size = Vector2(900, 56)
	paper.add_child(title)
	var preview := String(activity.get("description", ""))
	if preview.is_empty():
		var card: Dictionary = activity.get("card", {}) as Dictionary
		var lines: Array = card.get("lines", []) as Array
		preview = String(lines[0]) if not lines.is_empty() else "在这儿待一会儿，手上的事不会变少。"
	var body := _label(preview, 28, INK)
	body.position = Vector2(70, 168)
	body.size = Vector2(900, 84)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper.add_child(body)
	var cost_line := _cost_line(activity, mood, slots_left)
	var cost := _label(String(cost_line["text"]), 24, WEAK_INK)
	cost.position = Vector2(70, 268)
	cost.size = Vector2(900, 40)
	paper.add_child(cost)
	if not String(cost_line["hint"]).is_empty():
		var hint := _label(String(cost_line["hint"]), 19, Color("8a7259"))
		hint.position = Vector2(70, 306)
		hint.size = Vector2(900, 30)
		paper.add_child(hint)
	var activity_id := String(activity.get("id", ""))
	var need := maxi(1, int(activity.get("slots", 1)))
	var can_go := slots_left < 0 or slots_left >= need
	_page_button(paper, String(cost_line["button"]), Vector2(70, 400), Vector2(320, 66), true,
		_on_confirm.bind(activity_id) if can_go else _on_back)
	_page_button(paper, "先回去", Vector2(420, 400), Vector2(220, 66), false, _on_back)


func _on_confirm(activity_id: String) -> void:
	close()
	activity_confirmed.emit(activity_id)


func _on_back() -> void:
	close()
	activity_declined.emit()


## 代价行按当前心情变（11.24）。首月没有心情账本，调用方给多少算多少。
## slots_left >= 0 时换成十二个月的「格」口径：先说实话要占几格、还剩几格。
func _cost_line(activity: Dictionary, mood: int, slots_left := -1) -> Dictionary:
	var cost := maxi(0, int(activity.get("hCost", 0)))
	var gain := int((activity.get("stateDelta", {}) as Dictionary).get("H", 0))
	# 主句先说"这件事对你这个人怎么样"，再说占几格：
	# 五本账里心情那本最容易被玩家忽略，别把它藏在第二行。
	var head := ""
	if gain > 0:
		head = "会给你缓回来一点（心情 +%d）。" % gain
	elif mood <= 2 and cost > 0:
		head = "你现在很累，这一件要扣两次心情（−%d）。" % (cost * 2)
	elif cost > 0:
		head = "会花掉你一点心情（−%d）。" % cost
	else:
		head = "不花心情，但也不会让手上的事变少。"
	if slots_left >= 0:
		var slots := maxi(1, int(activity.get("slots", 1)))
		if slots_left < slots:
			return {"text": "这个月剩下的格子不够。", "hint": "", "button": "先回去"}
		var slot_line := "占 1 格 · 本月还剩 %d 格。" % slots_left if slots == 1 			else "这一件要占 %d 格 · 本月还剩 %d 格。" % [slots, slots_left]
		return {"text": head, "hint": slot_line, "button": "就做这个"}
	if mood <= 0 and gain <= 0:
		return {"text": "这一格只能用来缓过来。", "hint": "", "button": "就在这儿坐着"}
	return {"text": head, "hint": "本月就 1 格，做完就没了。", "button": "就做这个"}


## 歪斜纸片 + 飞入：TRANS_BACK  overshoot 2.0，0.28 秒。
## dark_sheet = 深灰拼贴（讲解卡，字用米白）；false = 暖纸底（确认页，字用深褐）。
func _open_sheet(lean: float, dark_sheet := true) -> Panel:
	var root := get_node("PlaceVisitRoot")
	for child in root.get_children():
		child.queue_free()
	root.show()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var paper := Panel.new()
	paper.size = CARD_SIZE
	var view := get_viewport().get_visible_rect().size
	paper.position = ((view - CARD_SIZE) * 0.5).round()
	paper.pivot_offset = paper.size * 0.5
	paper.rotation_degrees = lean
	paper.add_theme_stylebox_override("panel", _style(Color("3a2b20") if dark_sheet else PAPER, WOOD, 6, 10, 16))
	root.add_child(paper)
	paper.scale = Vector2(1.12, 1.12)
	paper.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(paper, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(paper, "modulate:a", 1.0, 0.16)
	return paper


func _page_button(paper: Panel, text: String, at: Vector2, size_value: Vector2, primary: bool, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = size_value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("fff4d5") if primary else INK)
	button.add_theme_stylebox_override("normal", _style(BRICK if primary else Color("f1ddb0"), Color("2e1a12") if primary else WOOD, 3, 10, 5 if primary else 3))
	button.add_theme_stylebox_override("hover", _style(Color("cf6247") if primary else Color("fff0cc"), Color("2e1a12") if primary else WOOD, 3, 10, 5))
	button.add_theme_stylebox_override("pressed", _style(Color("8f3a26") if primary else Color("e2c894"), Color("2e1a12"), 3, 10, 0))
	button.pressed.connect(action)
	paper.add_child(button)
	return button


func _label(value: String, font_size: int, color: Color, font: Font = FONT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
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
		style.shadow_color = Color(0, 0, 0, 0.42)
		style.shadow_size = bevel
		style.shadow_offset = Vector2(0, 4)
	return style
