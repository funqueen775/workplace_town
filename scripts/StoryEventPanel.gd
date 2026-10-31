class_name StoryEventPanel
extends CanvasLayer

## 主线事件演出。
##
## 版式几代演进：
##   第一代 = 全屏压暗 + 土黄弹窗，玩家在"弹窗里"做选择。
##   第二代 = 场景全屏 + 立绘 + 底部对话条 + 结果拍 + 记忆便签 + 黑场入场卡。
##   第三代 = beats 分镜脚本、场景入场拍与可交互选择。
##   当前对白层使用独立角色/旁白框和按台词切换的新立绘。
##
## beats（分镜）一个 beat 一个动作：
##   say       某人说话（气泡 + 名字牌 + 立绘聚焦）
##   narration 旁白（无立绘聚焦，人物退到背景）
##   interact  可交互物（翻开手册这类，点了才继续）
##   choice    三选一
## 没有 beats 的老事件自动退化成「入场卡 → 旁白 → 选择 → 结果」，行为不变。
##
## 三条红线（V5.27）：
##   1. 结果必须给，且只用行为语言 —— 永不出现数字。
##   2. 情境强度只走光影，不显示任何标签。
##   3. 独处事件 cast 为空 —— 画面上真的没有人。

signal choice_confirmed(event_id: String, choice_id: String, duration_minutes: int)
signal outcome_acknowledged(event_id: String, choice_id: String, duration_minutes: int)
signal decision_opened(event_id: String)
signal choice_hovered(event_id: String, choice_id: String)
## 手册阅读埋点回传（各章时长 / 跳过行为），由外部落盘
signal handbook_recorded(event_id: String, records: Dictionary)
## 结果拍浮出「记忆便签」时回传整条记录，由外部落盘。
## 便签是心湖记忆墙的唯一数据源：落了盘，玩家下次进游戏还能翻到自己当时贴了什么；
## 不落盘它就只是"弹一下就没了"的装饰。
signal memo_recorded(event_id: String, memo: Dictionary)
## 每一拍过手时对外广播一次：带巡要按某一句台词立门（beat 上的 hook），
## 面板自己不懂这些，只管把 beat 原样递出来。
signal beat_reached(event_id: String, beat_index: int, beat: Dictionary)

const HANDBOOK := preload("res://scripts/HandbookPanel.gd")
const TORN_BUBBLE := preload("res://scripts/ui/TornBubble.gd")

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const CHARACTER_DIALOG := preload("res://assets/对话框/角色对话框_空白.png")
const NARRATION_DIALOG := preload("res://assets/对话框/旁白对话框_空白.png")
const NAME_PLATE := preload("res://assets/对话框/姓名牌_空白_确认版.png")
const PORTRAIT_PATH := "res://assets/角色立绘/%s/%s_%s.png"
const CHARACTER_FRAME_REGION := Rect2(40, 168, 2088, 416)
const NARRATION_FRAME_REGION := Rect2(24, 176, 2136, 352)
const NAME_PLATE_REGION := Rect2(264, 288, 1368, 264)
const TYPE_INTERVAL := 0.022

var text_speed := 1
var large_text := false
var reduced_motion := false
## 剧情里的手机演出交给城镇那部真手机去演（城镇在构建面板时接上）。
var phone_peek := Callable()

## 入场拍：黑场里先把"这是哪一幕、哪一天、什么地方"压上来，再落进叙述。
const ENTRY_CARD_IN := 0.35
const ENTRY_HOLD := 1.45
const ENTRY_OUT := 0.5
## 黑场不完全捂住房间：留一点影子，玩家知道"人还站在那个屋里"。
const ENTRY_DIM := 0.62

## 区域内景图：剧情演出与可探索室内共用同一批场景美术。
const INTERIOR_BY_ZONE := {
	"A": "res://assets/场景内部图/熊起东方总部.png",
	"B": "res://assets/场景内部图/云栖科技丘.png",
	"C": "res://assets/场景内部图/创意水巷.png",
	"D": "res://assets/场景内部图/树影图书馆.png",
	"E": "res://assets/场景内部图/松风训练谷.png",
	"F": "res://assets/场景内部图/观澜展会码头.png",
	"G": "res://assets/场景内部图/暖邻康护院.png",
	"H": "res://assets/场景内部图/慢生活园.png",
}

## 情境强度只做光影，不显示任何标签或数字（V5.27 红线：测量口径不下发前端）
const SITUATION_SHADE := {
	"weak": Color(0.05, 0.08, 0.16, 0.52),
	"medium": Color(0.06, 0.09, 0.14, 0.33),
	"strong": Color(0.12, 0.08, 0.05, 0.24),
}
const NOTE_TONE := {
	"gold": Color("f2c14e"),
	"gray": Color("9aa2ab"),
}
## 关键词强调色：比正文深一档的砖红，米色纸面上够跳，又不会被读成"危险"。
const EMPHASIS_INK := Color("8f3a26")
## 能点的词用松绿 + 下划线：跟剧情重音（砖棕加粗）一眼分得开。
const TERM_INK := Color("2f6b5f")

const BUBBLE_FILL := Color(0.05, 0.05, 0.07, 0.95)
const BUBBLE_FILL_HOT := Color(0.14, 0.13, 0.17, 0.97)
const BUBBLE_LINE := Color(0.97, 0.96, 0.92)
const PLATE_FILL := Color(0.97, 0.96, 0.93)
const PLATE_LINE := Color(0.06, 0.05, 0.08)
const INK := Color(0.10, 0.09, 0.12)
const PAD_X := 46.0

var _root: Control
var _stage_layer: Control
var _ui_layer: Control
var _handbook: CanvasLayer
var _event: Dictionary = {}
var _stage := "closed"
var _chosen_id := ""
var _beats: Array = []
var _beat_index := -1
var _entry_fade: ColorRect
var _entry_card: Control
var _entry_age := 0.0
var _top_bar: Control
var _typewriter_label: Label
var _typewriter_rich: RichTextLabel
var _typewriter_full := ""
var _typewriter_shown := 0
var _typewriter_timer: Timer


func _ready() -> void:
	layer = 150
	_root = Control.new()
	_root.name = "EventOverlay"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_root_gui_input)
	add_child(_root)
	_root.hide()
	_stage_layer = Control.new()
	_stage_layer.name = "StageLayer"
	_stage_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stage_layer)
	_ui_layer = Control.new()
	_ui_layer.name = "UiLayer"
	_ui_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_ui_layer)
	_handbook = HANDBOOK.new()
	_handbook.name = "Handbook"
	_handbook.handbook_closed.connect(_on_handbook_closed)
	add_child(_handbook)
	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = TYPE_INTERVAL
	add_child(_typewriter_timer)
	_typewriter_timer.timeout.connect(_tick_typewriter)


func present(event: Dictionary, quiet := false) -> void:
	_event = event.duplicate(true)
	_chosen_id = ""
	_beats = _player_visible_beats(_event.get("beats", []) as Array)
	if _beats.is_empty():
		var story := String(_event.get("story", "事件内容待补充。"))
		if _is_developer_note(story):
			story = ""
		_beats = [
			{"type": "narration", "text": story},
			{"type": "choice"},
		]
	# 每个主线事件必须让玩家完成一次选择。部分新版事件有分镜，
	# 但数据没有写 choice beat 时，旧逻辑会在分镜结束后直接结算。
	if not (_event.get("choices", []) as Array).is_empty() and not _beats.any(func(beat): return String(Dictionary(beat).get("type", "")) == "choice"):
		_beats.append({"type": "choice"})
	_beat_index = -1
	_build_stage()
	if quiet:
		# 同一间屋子里连着问的后续屏：不再黑一次场、不再报一次标题，直接接上话。
		_root.show()
		_end_entry()
		return
	_show_entry()
	_root.show()


## 剧情文档中的「表现说明」是给制作人员的备注，绝不能作为玩家旁白显示。
func _player_visible_beats(source_beats: Array) -> Array:
	var visible: Array = []
	for value in source_beats:
		if not (value is Dictionary):
			continue
		var beat := Dictionary(value)
		var text := String(beat.get("text", ""))
		if _is_developer_note(text):
			continue
		visible.append(beat)
	return visible


func _is_developer_note(text: String) -> bool:
	return text.strip_edges().begins_with("表现说明")


func dismiss() -> void:
	_stage = "closed"
	_stop_typewriter()
	_entry_fade = null
	_entry_card = null
	_root.hide()


func is_open() -> bool:
	return _root != null and _root.visible


func current_stage() -> String:
	return _stage


func beat_index() -> int:
	return _beat_index


## 入场拍的淡入/停留由 _process 自己按秒数推进，不用 Tween、不用 Timer：
## 玩家在淡入途中点击时不会留下"半个动画"去改已经释放的节点。
func _process(delta: float) -> void:
	if _stage != "entry":
		return
	_entry_age += delta
	var total := ENTRY_CARD_IN + ENTRY_HOLD + ENTRY_OUT
	var out := clampf((_entry_age - ENTRY_CARD_IN - ENTRY_HOLD) / ENTRY_OUT, 0.0, 1.0)
	if is_instance_valid(_entry_card):
		_entry_card.modulate.a = clampf(_entry_age / ENTRY_CARD_IN, 0.0, 1.0) * (1.0 - out)
	if is_instance_valid(_entry_fade):
		var dim_in := clampf((_entry_age - 0.15) / 0.7, 0.0, 1.0)
		_entry_fade.color.a = lerpf(1.0, ENTRY_DIM, dim_in) * (1.0 - out)
	if _entry_age >= total:
		_end_entry()


# ---------------------------------------------------------------- 场景层

func _build_stage() -> void:
	for child in _stage_layer.get_children():
		child.queue_free()
	var size := _view_size()
	var zone := String(_event.get("locationId", "B"))
	var room := TextureRect.new()
	room.texture = _load_texture(String(INTERIOR_BY_ZONE.get(zone, INTERIOR_BY_ZONE["B"])))
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_layer.add_child(room)
	var shade := ColorRect.new()
	shade.color = _stage_shade()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_layer.add_child(shade)
	# 下半幅再压一层：气泡坐在暗角上才读得清字，也是剧场感的来源
	var floor_shade := ColorRect.new()
	floor_shade.color = Color(0.02, 0.02, 0.04, 0.40)
	floor_shade.position = Vector2(0, size.y * 0.60)
	floor_shade.size = Vector2(size.x, size.y * 0.40)
	floor_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_layer.add_child(floor_shade)
	_build_date_badge()
	_build_top_bar()


## 光影 = 情境强度 × 时段：白天别把画面压死，深夜才沉下去。
## weak / medium / strong 只在明暗上有差别，不出现任何文字标签。
func _stage_shade() -> Color:
	var base: Color = SITUATION_SHADE.get(String(_event.get("situation", "medium")), SITUATION_SHADE["medium"])
	var hour := int(_event.get("hour", 12))
	if hour >= 8 and hour < 17:
		return Color(base.r, base.g, base.b, maxf(0.18, base.a - 0.16))
	if hour >= 19 or hour < 6:
		return Color(base.r, base.g, base.b, minf(0.74, base.a + 0.08))
	return base


## 左上角日期时段牌。玩家一眼知道"这是哪一天、什么时辰"——
## 整部戏的测量口径就建立在"这件事什么时候发生"上面，时间必须一直在场。
func _build_date_badge() -> void:
	var stamp := _date_stamp(int(_event.get("month", 1)), int(_event.get("day", 1)), int(_event.get("hour", 9)))
	var plate: Control = TORN_BUBBLE.new()
	plate.name = "DateBadge"
	plate.size = Vector2(212, 142)
	plate.position = Vector2(48, 34)
	plate.fill_color = PLATE_FILL
	plate.outline_color = PLATE_LINE
	plate.outline_width = 4.0
	plate.tail_side = "none"
	plate.jag = 9.0
	plate.shape_seed = 991
	_stage_layer.add_child(plate)
	var big := _label(stamp["date"], 40, INK, true)
	big.position = Vector2(26, 20)
	big.size = Vector2(160, 56)
	big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(big)
	var week := _label(stamp["weekday"], 19, INK)
	week.position = Vector2(28, 80)
	week.size = Vector2(160, 26)
	plate.add_child(week)
	var phase := _label(stamp["phase"], 22, INK, true)
	phase.position = Vector2(28, 106)
	phase.size = Vector2(160, 30)
	plate.add_child(phase)


## 顶栏在入场拍先藏着 —— 那一刻画面中央已经有事件卡，再顶一行同样的话是重复。
func _build_top_bar() -> void:
	_top_bar = Control.new()
	_top_bar.name = "TopBar"
	_top_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.hide()
	_stage_layer.add_child(_top_bar)
	var act := _label(String(_event.get("actTitle", "主线事件")), 20, Color("ffe6b0"))
	act.position = Vector2(52, 190)
	act.size = Vector2(520, 32)
	act.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_top_bar.add_child(act)
	var where := "%s · %s" % [String(_event.get("title", "")), String(_event.get("location", ""))]
	var place := _label(where, 18, Color("e8dcc4"))
	place.size = Vector2(508, 30)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	place.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	place.position = Vector2(-560, 192)
	_top_bar.add_child(place)


## 事件卡上的时间戳：只用事件自带的 month / day / hour，不另外读时钟。
## 十二个月这条线不摆"几号几点"（开发文档：只说月 + 旬 + 时段），
## 所以 dateStyle 是 xun 的时候报旬位；老 48 个月那条线照旧。
func clock_text() -> String:
	if String(_event.get("dateStyle", "")) == "xun":
		return "第 %d 月 · %s · %s" % [
			int(_event.get("month", 1)),
			_xun_label(String(_event.get("phase", "early"))),
			_band_word(),
		]
	return "第 %d 月 %d 日 · %02d:00" % [
		int(_event.get("month", 1)), int(_event.get("day", 1)), int(_event.get("hour", 9)),
	]


## 时段那一个词。十二个月这条线一律以节点写的 timeBand 为准：
## 数据里 hour 多半没跟着填（几十处是缺省的 9 点），拿 hour 去算就会出现
## 标题写着"周四深夜 02:10"、日期牌上却写着"上午"（2026-10-29 与 10-30 两次实机）。
## 日期牌和入场卡两处都要用它，口径不能一边改一边忘。
func _band_word() -> String:
	var band := String(_event.get("timeBand", ""))
	if band == "night":
		return "夜里"
	if band == "afternoon":
		return "午后"
	if band == "morning":
		return "上午"
	return _time_word(int(_event.get("hour", 9)))


## 日期牌的显示口径：月/日 + 周几 + 时段，和 WorldClock 的 30 天月制对齐（不做真实历法）。
func _date_stamp(month: int, day: int, hour: int) -> Dictionary:
	# 十二个月这条线只认"月 + 旬 + 时段"（开发文档：月份表故事进程，上中下旬表月内状态）。
	# 老 48 个月那条线照旧用月/日 + 周几。
	if String(_event.get("dateStyle", "")) == "xun":
		return {
			"date": "第 %d 月" % maxi(month, 1),
			"weekday": _xun_label(String(_event.get("phase", "early"))),
			"phase": _band_word(),
		}
	const WEEKDAYS := ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	var total := (maxi(month, 1) - 1) * 30 + (maxi(day, 1) - 1)
	var phase := _time_word(hour)
	return {
		"date": "%d/%d" % [maxi(month, 1), maxi(day, 1)],
		"weekday": WEEKDAYS[posmod(total, 7)],
		"phase": phase,
	}


func _time_word(hour: int) -> String:
	if hour < 6:
		return "深夜"
	if hour < 8:
		return "清晨"
	if hour < 12:
		return "上午"
	if hour < 17:
		return "下午"
	if hour < 19:
		return "傍晚"
	return "夜晚"


func _xun_label(phase: String) -> String:
	if phase == "mid":
		return "中旬"
	if phase == "late":
		return "下旬"
	return "上旬"


## cast 兼容两种写法：
##   老格式 [{name, role, loadout, pos}]（E02-E04 在用）
##   新格式 cast 只列 id，speakers 字典给详情（E01 用它，同一角色跨 beat 复用一份档案）
func _cast_list() -> Array:
	var result: Array = []
	var speakers: Dictionary = _event.get("speakers", {})
	for entry in _event.get("cast", []) as Array:
		if result.size() >= 2:
			break
		if entry is Dictionary:
			var actor := Dictionary(entry)
			if not actor.has("id"):
				actor["id"] = String(actor.get("name", "actor"))
			result.append(actor)
		elif entry is String:
			var id := String(entry)
			var profile := Dictionary(speakers.get(id, {}))
			if profile.is_empty():
				continue
			profile["id"] = id
			result.append(profile)
	if result.size() == 2:
		(result[0] as Dictionary)["pos"] = "left"
		(result[1] as Dictionary)["pos"] = "right"
	return result


# ---------------------------------------------------------------- 分镜

func _next_beat() -> void:
	_beat_index += 1
	if _beat_index >= _beats.size():
		_finish_without_choice()
		return
	var beat := Dictionary(_beats[_beat_index])
	beat_reached.emit(String(_event.get("id", "")), _beat_index, beat)
	match String(beat.get("type", "say")):
		"say":
			_show_say(beat)
		"interact":
			_show_interact(beat)
		"choice":
			_show_choices(String(beat.get("prompt", "")))
		"phone_cinematic":
			_show_phone_message(beat)
		_:
			_show_narration(String(beat.get("text", "")), beat.get("emphasis", []) as Array)


## 说话拍：气泡 + 名字牌 + 立绘聚焦。
func _show_say(beat: Dictionary) -> void:
	_stage = "say"
	_clear_ui()
	var speaker_id := String(beat.get("speaker", ""))
	var text := String(beat.get("text", ""))
	var profile := _speaker_profile(speaker_id)
	var portrait_name := _portrait_name(String(profile.get("name", speaker_id)))
	var bubble := _make_dialogue_frame(true)
	# 能点的词单独标出来（松绿下划线），不然光有角上一颗点，玩家不知道句里哪个词能点。
	var term := _matched_term(text)
	var body := _emphasis_label(text, 30, beat.get("emphasis", []) as Array, 14, String(term.get("word", "")))
	body.position = Vector2(520.0, 72.0) if not portrait_name.is_empty() else Vector2(95.0, 72.0)
	body.size = Vector2(bubble.size.x - body.position.x - 90.0, bubble.size.y - 118.0)
	bubble.add_child(body)
	_typewriter_rich = body
	_start_typewriter(text)
	if not portrait_name.is_empty():
		var expression := String(beat.get("expression", ""))
		if expression not in ["开心", "认真", "无奈", "疑惑", "自然"]:
			expression = _expression_for(text)
		_add_speaker_portrait(portrait_name, expression)
	_add_asset_name_plate(bubble, profile, speaker_id)
	_add_dialogue_hint(bubble)
	_add_term_dot(bubble, term)


## 旁白拍：没有名字、没有立绘聚焦。玩家在看场景，不是在看人。
func _show_narration(text: String, emphasis: Array = []) -> void:
	_stage = "narration"
	_clear_ui()
	var bubble := _make_dialogue_frame(false)
	var term := _matched_term(text)
	var body := _emphasis_label(text, 29, emphasis, 14, String(term.get("word", "")))
	body.position = Vector2(92.0, 62.0)
	body.size = Vector2(bubble.size.x - 184.0, bubble.size.y - 118.0)
	bubble.add_child(body)
	_typewriter_rich = body
	_start_typewriter(text)
	_add_dialogue_hint(bubble)
	_add_term_dot(bubble, term)


## 手机演出拍：剧情里收到一条消息，交给系统里那部真手机演——右下角那颗的右侧抽屉
## 拉开、停一会儿、自己收回。这里不另画卡；手机还没建出来时才退回旁白，不让这一拍空白。
func _show_phone_message(beat: Dictionary) -> void:
	_stage = "narration"
	_clear_ui()
	var speaker := String(beat.get("speaker", ""))
	var text := String(beat.get("text", ""))
	if phone_peek.is_valid() and bool(phone_peek.call(speaker, text, _event)):
		return
	_show_narration(text)


## 可交互拍：不推进剧情，等玩家去碰它。
## V5.27 对 E01 的要求是「手册翻章（永久改变）」——所以这必须是个真动作，不是一行文案。
func _show_interact(beat: Dictionary) -> void:
	_stage = "interact"
	_clear_ui()
	var text := String(beat.get("label", "可交互"))
	var hint_text := String(beat.get("hint", "点击查看"))
	var bubble := _make_bubble(false, 480.0, text + "\n" + hint_text, 24)
	bubble.fill_color = Color(0.07, 0.06, 0.09, 0.94)
	var mark := _label("◆", 22, Color("f2c14e"))
	mark.position = Vector2(PAD_X, 24.0)
	mark.size = Vector2(34, 32)
	bubble.add_child(mark)
	var title := _label(text, 24, Color("f7f2e6"), true)
	title.position = Vector2(PAD_X + 32.0, 24.0)
	title.size = Vector2(bubble.size.x - PAD_X * 2.0 - 32.0, 34.0)
	bubble.add_child(title)
	var hint := _label(hint_text, 20, Color("c9bda6"))
	hint.position = Vector2(PAD_X + 32.0, 62.0)
	hint.size = Vector2(bubble.size.x - PAD_X * 2.0 - 32.0, 30.0)
	bubble.add_child(hint)
	_add_key_hint(bubble, "点击翻开")


## 选择拍沿用角色对白框素材，保留原选项命中和悬停记录。
func _show_choices(prompt: String) -> void:
	_stage = "choices"
	_stop_typewriter()
	# 犹豫时长从"选项出现在眼前"开始算，不能把读开场白的时间也算进去。
	decision_opened.emit(String(_event.get("id", "")))
	_clear_ui()
	var choices: Array = _event.get("choices", [])
	var size := _view_size()
	var bubble_w := minf(930.0, size.x - 64.0)
	var row_height := 118.0
	var row_gap := 16.0
	var start_y := maxf(150.0, (size.y - (row_height * 3.0 + row_gap * 2.0)) * 0.5)
	var start_x := (size.x - bubble_w) * 0.5
	var caption_text := prompt if not prompt.is_empty() else String(_event.get("prompt", ""))
	if not caption_text.is_empty():
		var caption := _label(caption_text, 25, Color("fff4e3"), true)
		caption.position = Vector2(start_x + 30.0, start_y - 52.0)
		caption.size = Vector2(bubble_w - 60.0, 38.0)
		caption.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.05, 0.92))
		caption.add_theme_constant_override("outline_size", 6)
		_ui_layer.add_child(caption)
	for index in mini(choices.size(), 3):
		var choice: Dictionary = choices[index]
		var choice_id := String(choice.get("id", "option_%d" % index))
		var text := String(choice.get("text", ""))
		var row := TextureRect.new()
		row.name = "Choice_%s" % choice_id
		row.texture = _cropped_texture(CHARACTER_DIALOG, CHARACTER_FRAME_REGION)
		row.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row.stretch_mode = TextureRect.STRETCH_SCALE
		row.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		row.size = Vector2(bubble_w, row_height)
		row.position = Vector2(start_x, start_y + float(index) * (row_height + row_gap))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui_layer.add_child(row)
		var label := _label(text, 27, Color("56301e"), true)
		label.position = Vector2(68.0, 20.0)
		label.size = Vector2(bubble_w - 136.0, row_height - 40.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_constant_override("line_spacing", 4)
		row.add_child(label)
		var button := Button.new()
		button.name = "Hit_%s" % choice_id
		button.flat = true
		button.size = row.size
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		var event_id := String(_event.get("id", ""))
		var duration_minutes := int(_event.get("durationMinutes", 45))
		button.mouse_entered.connect(func():
			row.modulate = Color("ffe3b6")
			choice_hovered.emit(event_id, choice_id))
		button.mouse_exited.connect(func():
			row.modulate = Color.WHITE)
		button.pressed.connect(func(): _on_choice_picked(event_id, choice_id, duration_minutes))
		row.add_child(button)


func _on_choice_picked(event_id: String, choice_id: String, duration_minutes: int) -> void:
	_chosen_id = choice_id
	choice_confirmed.emit(event_id, choice_id, duration_minutes)
	_show_outcome(choice_id)


func _show_outcome(choice_id: String) -> void:
	_stage = "outcome"
	_stop_typewriter()
	_clear_ui()
	var text := _outcome_text(choice_id)
	var spoken := _split_spoken_outcome(text)
	if not spoken.is_empty():
		_show_outcome_spoken(choice_id, String(spoken["who"]), String(spoken["said"]))
		return
	var bubble := _make_dialogue_frame(false)
	var body := _emphasis_label(text, 28, _choice_emphasis(choice_id), 10)
	body.position = Vector2(92.0, 57.0)
	body.size = Vector2(bubble.size.x - 184.0, bubble.size.y - 123.0)
	bubble.add_child(body)
	_typewriter_rich = body
	_start_typewriter(text)
	_finish_outcome_frame(bubble, choice_id)


## 结果句写成"某某：……"的，就当那个人在说话：名字牌、立绘都照台词摆。
## 它仍然是"结果"这一拍（点一下才收），不能被当成下一句台词。
func _show_outcome_spoken(choice_id: String, who: String, said: String) -> void:
	var profile := _profile_by_name(who)
	# 演员表里没有这个人（"大领导""跨部门评委"这种只在台上出现一次的）：
	# 照样给他一块名字牌，只是没有立绘——比把台词当旁白念强。
	if profile.is_empty():
		profile = {"name": who, "id": who}
	var portrait_name := _portrait_name(String(profile.get("name", who)))
	var bubble := _make_dialogue_frame(true)
	var body := _emphasis_label(said, 30, _choice_emphasis(choice_id), 14)
	body.position = Vector2(520.0, 72.0) if not portrait_name.is_empty() else Vector2(95.0, 72.0)
	body.size = Vector2(bubble.size.x - body.position.x - 90.0, bubble.size.y - 118.0)
	bubble.add_child(body)
	_typewriter_rich = body
	_start_typewriter(said)
	if not portrait_name.is_empty():
		_add_speaker_portrait(portrait_name, _expression_for(said))
	_add_asset_name_plate(bubble, profile, who)
	_finish_outcome_frame(bubble, choice_id)


## 结果这一拍底下共用的两行：你选了什么、记忆墙上贴一张、右下角"点击继续"。
func _finish_outcome_frame(bubble: Control, choice_id: String) -> void:
	var echo := _label("你选择了 · %s" % _choice_text(choice_id), 18, Color("9b6a48"))
	echo.position = Vector2(92.0, bubble.size.y - 70.0)
	echo.size = Vector2(bubble.size.x - 320.0, 28.0)
	echo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble.add_child(echo)
	_add_memo_note(choice_id)
	_add_dialogue_hint(bubble)


## "大领导：“这句比刚才那句有用。”" → {who: 大领导, said: “这句……”}
## 冒号必须在前 8 个字里，冒号前面不能带标点——免得把正文里的冒号当成人在说话。
func _split_spoken_outcome(text: String) -> Dictionary:
	var idx := text.find("：")
	if idx <= 0 or idx > 8:
		return {}
	var who := text.substr(0, idx).strip_edges()
	var said := text.substr(idx + 1).strip_edges()
	if who.is_empty() or said.is_empty():
		return {}
	if who.contains("，") or who.contains("。") or who.contains("“") or who.contains(" "):
		return {}
	return {"who": who, "said": said}


## 按**显示名**找演员：结果句里写的是"大领导"，不是演员表里的 id。
func _profile_by_name(name: String) -> Dictionary:
	if (_event.get("speakers", {}) as Dictionary).has(name):
		return _speaker_profile(name)
	for value in _cast_list():
		var actor := Dictionary(value)
		if String(actor.get("name", "")) == name:
			return actor
	return {}


func _finish_without_choice() -> void:
	outcome_acknowledged.emit(String(_event.get("id", "")), _chosen_id, int(_event.get("durationMinutes", 45)))
	dismiss()


# ---------------------------------------------------------------- 入场拍

## 第一拍 · 入场：黑场 + 事件卡（幕名 / 事件名 / 地点 / 世界时间）。
## 卡片内容全部读事件数据，任何一个字都不写死在脚本里。
func _show_entry() -> void:
	_stage = "entry"
	_stop_typewriter()
	_typewriter_full = ""
	_typewriter_shown = 0
	_clear_ui()
	_entry_age = 0.0
	var size := _view_size()
	_entry_fade = ColorRect.new()
	_entry_fade.name = "EntryFade"
	_entry_fade.color = Color(0.02, 0.03, 0.05, 1.0)
	_entry_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_entry_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_entry_fade)
	_entry_card = Control.new()
	_entry_card.name = "EntryCard"
	_entry_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_card.position = Vector2(140.0, size.y * 0.34)
	_entry_card.modulate.a = 0.0
	_ui_layer.add_child(_entry_card)
	var clock := clock_text()
	var act := _label(String(_event.get("actTitle", "主线事件")), 24, Color("e0b878"))
	act.position = Vector2(0, 0)
	act.size = Vector2(900, 34)
	act.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_entry_card.add_child(act)
	var title := _label(String(_event.get("title", "")), 46, Color("f7ecd6"))
	title.position = Vector2(0, 44)
	title.size = Vector2(1100, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_entry_card.add_child(title)
	var rule := ColorRect.new()
	rule.color = Color(0.72, 0.55, 0.32, 0.65)
	rule.position = Vector2(2, 118)
	rule.size = Vector2(120, 3)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_card.add_child(rule)
	var where := _label("%s · %s" % [String(_event.get("location", "")), clock], 24, Color("c2b399"))
	where.position = Vector2(0, 138)
	where.size = Vector2(1000, 34)
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_entry_card.add_child(where)


## 入场卡退场：淡场和卡片一起收走，顶栏在这时候才出来。
func _end_entry() -> void:
	_clear_entry()
	if is_instance_valid(_top_bar):
		_top_bar.show()
	_next_beat()


func _clear_entry() -> void:
	if is_instance_valid(_entry_fade):
		_entry_fade.queue_free()
	if is_instance_valid(_entry_card):
		_entry_card.queue_free()
	_entry_fade = null
	_entry_card = null


# ---------------------------------------------------------------- 手册

func _open_handbook() -> void:
	_stage = "handbook"
	_stop_typewriter()
	_handbook.open()


func _on_handbook_closed(records: Dictionary) -> void:
	handbook_recorded.emit(String(_event.get("id", "")), records)
	_next_beat()


# ---------------------------------------------------------------- 交互

func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance()


## 点击继续：正在打字就先把字补满（不催玩家，但也不让他干等）
func _advance() -> void:
	match _stage:
		"closed", "handbook", "choices":
			return
	if _is_typing():
		_finish_typewriter()
		return
	match _stage:
		"entry":
			_end_entry()
		"interact":
			_open_handbook()
		"outcome":
			var duration := int(_event.get("durationMinutes", 45))
			var event_id := String(_event.get("id", ""))
			outcome_acknowledged.emit(event_id, _chosen_id, duration)
			dismiss()
		_:
			_next_beat()


# ---------------------------------------------------------------- 打字机

func _start_typewriter(text: String) -> void:
	_typewriter_full = text
	_typewriter_shown = 0
	if not _has_typewriter_target():
		return
	if reduced_motion:
		_typewriter_shown = _visible_total()
		_set_typewriter_progress(-1)
	else:
		_set_typewriter_progress(0)
		_typewriter_timer.wait_time = [0.05, TYPE_INTERVAL, 0.008][clampi(text_speed, 0, 2)]
		_typewriter_timer.start()


func _tick_typewriter() -> void:
	if not _has_typewriter_target():
		_stop_typewriter()
		return
	var total := _visible_total()
	_typewriter_shown = mini(_typewriter_shown + 2, total)
	_set_typewriter_progress(_typewriter_shown)
	if _typewriter_shown >= total:
		_stop_typewriter()


func _is_typing() -> bool:
	return _has_typewriter_target() and _typewriter_shown < _visible_total()


func _finish_typewriter() -> void:
	_typewriter_shown = _visible_total()
	_set_typewriter_progress(-1)
	_stop_typewriter()


func _has_typewriter_target() -> bool:
	return is_instance_valid(_typewriter_rich) or is_instance_valid(_typewriter_label)


## 强调用的是 BBCode，字符数得按"看得见的字"算，不然打字机会把标签也算进去。
func _visible_total() -> int:
	if is_instance_valid(_typewriter_rich):
		return _typewriter_rich.get_total_character_count()
	return _typewriter_full.length()


func _set_typewriter_progress(count: int) -> void:
	if is_instance_valid(_typewriter_rich):
		# -1 = 全部显示；RichTextLabel 自己会跳过 BBCode 标签。
		_typewriter_rich.visible_characters = count
	elif is_instance_valid(_typewriter_label):
		_typewriter_label.text = _typewriter_full.substr(0, maxi(count, 0))


func _stop_typewriter() -> void:
	if _typewriter_timer != null:
		_typewriter_timer.stop()


# ---------------------------------------------------------------- 新对白素材

func _portrait_name(name: String) -> String:
	return name if name in ["小林", "小赵", "王哥", "老周"] else ""


func _portrait_texture(name: String, expression: String) -> Texture2D:
	var path := PORTRAIT_PATH % [name, name, expression]
	return _load_texture(path)


func _expression_for(text: String) -> String:
	if text.contains("?") or text.contains("？") or text.contains("怎么") or text.contains("为什么"):
		return "疑惑"
	if text.contains("不错") or text.contains("笑") or text.contains("做得好") or text.contains("可以") or text.contains("点头"):
		return "开心"
	if text.contains("无奈") or text.contains("只能") or text.contains("算了"):
		return "无奈"
	if text.contains("不") or text.contains("别") or text.contains("问题") or text.contains("责任") or text.contains("必须"):
		return "认真"
	return "自然"


func _cropped_texture(source: Texture2D, region: Rect2) -> AtlasTexture:
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = region
	return cropped


func _make_dialogue_frame(character: bool) -> Control:
	var size := _view_size()
	var frame := TextureRect.new()
	frame.texture = _cropped_texture(CHARACTER_DIALOG, CHARACTER_FRAME_REGION) if character else _cropped_texture(NARRATION_DIALOG, NARRATION_FRAME_REGION)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.size = Vector2(minf(1550.0, size.x - 56.0), 330.0 if character else 280.0)
	frame.position = Vector2((size.x - frame.size.x) * 0.5, size.y - frame.size.y - 70.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(frame)
	return frame


func _add_speaker_portrait(name: String, expression: String) -> void:
	var sprite := TextureRect.new()
	sprite.name = "DialoguePortrait"
	sprite.texture = _portrait_texture(name, expression)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = Vector2(10.0, _view_size().y - 690.0)
	sprite.size = Vector2(660.0, 660.0)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(sprite)


func _add_asset_name_plate(frame: Control, profile: Dictionary, fallback: String) -> void:
	var plate := TextureRect.new()
	plate.texture = _cropped_texture(NAME_PLATE, NAME_PLATE_REGION)
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.position = Vector2(355.0, -35.0)
	plate.size = Vector2(270.0, 70.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(plate)
	var label := _label(String(profile.get("name", fallback)), 27, Color("56301e"), true)
	label.position = Vector2(18.0, 13.0)
	label.size = Vector2(234.0, 44.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(label)


func _add_dialogue_hint(frame: Control) -> void:
	var label := _label("点击继续", 19, Color("9b6a48"), true)
	label.position = Vector2(frame.size.x - 235.0, frame.size.y - 72.0)
	label.size = Vector2(150.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frame.add_child(label)


# ---------------------------------------------------------------- 行话小圆点
#
# 只做一件事：台词里冒出一个玩家不可能懂的专业词，给一句人话。
# 不记录听过没听过、不进档案页、不呼吸提示。全年八个词（data/story/v12m/terms.json），
# 不点什么都不发生，点一下浮一句，再点任意地方收起。

const TERMS_PATH := "res://data/story/v12m/terms.json"
const TERM_DOT_SIZE := 46.0

var _terms: Array = []
var _term_card: Control
## 当前这一拍的气泡和可点的词：台词里那个词本身也能点，靠这两个变量找到该给谁开纸片。
var _term_frame: Control
var _term_current: Dictionary
## 鼠标此刻是不是停在那个词上（这一版 RichTextLabel 没有"某点在哪个链接上"的查询，
## 只能靠悬停信号自己记）。
var _term_hot := false
var _term_last_toggle := 0
## 第一次遇到能点的词时给一句一次性的说明：不解释的话玩家根本不知道有这功能。
var _term_hint_seen := false


func _load_terms() -> void:
	if not _terms.is_empty():
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TERMS_PATH))
	if parsed is Dictionary:
		_terms = (parsed as Dictionary).get("terms", []) as Array


func _matched_term(text: String) -> Dictionary:
	_load_terms()
	for value in _terms:
		if not (value is Dictionary):
			continue
		var term := value as Dictionary
		var word := String(term.get("word", ""))
		if not word.is_empty() and text.contains(word):
			return term
	return {}


func _add_term_dot(frame: Control, term: Dictionary) -> void:
	_term_frame = frame
	_term_current = term
	if term.is_empty():
		return
	var dot := Button.new()
	dot.name = "TermDot"
	dot.text = "？"
	dot.position = Vector2(frame.size.x - TERM_DOT_SIZE - 26.0, 22.0)
	dot.size = Vector2(TERM_DOT_SIZE, TERM_DOT_SIZE)
	dot.add_theme_font_override("font", FONT)
	dot.add_theme_font_size_override("font_size", 24)
	dot.add_theme_color_override("font_color", Color("fff4d5"))
	dot.add_theme_stylebox_override("normal", _term_dot_style(Color("b95035")))
	dot.add_theme_stylebox_override("hover", _term_dot_style(Color("cf6247")))
	dot.add_theme_stylebox_override("pressed", _term_dot_style(Color("8f3a26")))
	dot.pressed.connect(_toggle_term_card.bind(frame, term))
	frame.add_child(dot)
	if not _term_hint_seen:
		_term_hint_seen = true
		_add_term_hint(frame, dot)


## 一次性的说明：第一次有词可点时，点在呼吸、旁边写一行"这个词能点"。
## 呼吸四秒后自己停，字跟着淡掉；玩家点过一次之后就再也不出现。
func _add_term_hint(frame: Control, dot: Button) -> void:
	# 气泡是浅色纸，米白字会直接融进去——用砖棕，跟那颗点同一个颜色家族。
	var hint := _label("画线那个词，点一下", 20, Color("a8552e"), true)
	hint.name = "TermHint"
	hint.position = Vector2(frame.size.x - 470.0, 30.0)
	hint.size = Vector2(392.0, 30.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frame.add_child(hint)
	if reduced_motion:
		return
	dot.pivot_offset = dot.size * 0.5
	var breathe := dot.create_tween().set_loops()
	breathe.tween_property(dot, "scale", Vector2(1.16, 1.16), 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(dot, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var fade := create_tween()
	fade.tween_interval(4.0)
	fade.tween_property(hint, "modulate:a", 0.0, 0.6)
	fade.tween_callback(func():
		if is_instance_valid(hint):
			hint.queue_free())


## 点在那个词上：开 / 收那张纸片。
func _on_term_meta(_meta) -> void:
	# 触屏没有"悬停"，只有 meta_clicked；鼠标那边已经在 _on_term_body_input 里处理过了，
	# 200 毫秒内不重复翻面，否则一次点击会开完又关。
	if Time.get_ticks_msec() - _term_last_toggle < 200:
		return
	_open_term_card()


## 词以外的地方点了还是"点击继续"——不能因为文字接了鼠标，整段对话就卡住。
func _on_term_body_input(event: InputEvent, label: RichTextLabel) -> void:
	var pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
	if not pressed:
		return
	if not _term_hot:
		_advance()
		return
	_term_last_toggle = Time.get_ticks_msec()
	_open_term_card()


func _open_term_card() -> void:
	if _term_frame == null or not is_instance_valid(_term_frame) or _term_current.is_empty():
		return
	_toggle_term_card(_term_frame, _term_current)


func _term_dot_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(int(TERM_DOT_SIZE / 2.0))
	style.set_border_width_all(2)
	style.border_color = Color("f6e6bd")
	style.shadow_color = Color(0, 0, 0, 0.40)
	style.shadow_size = 4
	return style


func _toggle_term_card(frame: Control, term: Dictionary) -> void:
	if _term_card != null and is_instance_valid(_term_card):
		_term_card.queue_free()
		_term_card = null
		return
	var word := String(term.get("word", ""))
	var plain := String(term.get("plain", ""))
	var width := maxf(380.0, FONT.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 72.0)
	var card := Panel.new()
	card.name = "TermCard"
	card.size = Vector2(width, 106.0)
	card.position = Vector2(round((frame.size.x - width) * 0.5), -card.size.y - 16.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff3dc")
	style.border_color = Color("5b321f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 8
	card.add_theme_stylebox_override("panel", style)
	var title := _label(word, 24, Color("b95035"), true)
	title.position = Vector2(26, 14)
	title.size = Vector2(width - 52, 32)
	card.add_child(title)
	var body := _label(plain, 26, Color("4a2b1a"))
	body.position = Vector2(26, 52)
	body.size = Vector2(width - 52, 44)
	card.add_child(body)
	var close := Button.new()
	close.flat = true
	close.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	close.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close.pressed.connect(func():
		if is_instance_valid(card):
			card.queue_free()
		_term_card = null)
	card.add_child(close)
	frame.add_child(card)
	_term_card = card


# ---------------------------------------------------------------- 零件

## 对话气泡：黑底白边的撕纸片，尖角指向说话人那一侧。
## 高度跟着文案行数走 —— 一句话的气泡矮，一段话的气泡高，不做固定框。
func _make_bubble(center: bool, width: float, text: String, font_size: int) -> Control:
	return _make_bubble_sized(center, width, _bubble_height(text, width, font_size))


func _make_bubble_sized(center: bool, width: float, height: float) -> Control:
	var size := _view_size()
	var bubble: Control = TORN_BUBBLE.new()
	bubble.name = "Bubble"
	bubble.size = Vector2(width, height)
	bubble.fill_color = BUBBLE_FILL
	bubble.outline_color = BUBBLE_LINE
	bubble.outline_width = 4.0
	bubble.jag = 9.0
	bubble.shape_seed = 7717
	bubble.tail_side = "none" if center else "left"
	bubble.tail_at = 0.34
	bubble.tail_length = 40.0
	bubble.position = Vector2(round((size.x - width) * 0.5), round(size.y - height - 92.0))
	_ui_layer.add_child(bubble)
	return bubble


func _bubble_height(text: String, width: float, font_size: int) -> float:
	if text.is_empty():
		return 128.0
	var lines := _wrapped_lines(text, width - PAD_X * 2.0, font_size)
	# 行高 = 字号 ×1.42（中文字体实际行高）+ line_spacing 12；上下各留 34px 内边距。
	# 估小了正文就会压到下面那行「你选择了」上面去。
	return maxf(128.0, float(lines) * (float(font_size) * 1.42 + 12.0) + 68.0)


## 名字牌：白底黑字的斜切牌，挂在气泡外侧。
## 它的职责是让玩家随时知道"现在是谁在说"——旧版只有一行贴在图上的小字，很容易读丢。
func _add_name_plate(bubble: Control, profile: Dictionary) -> void:
	if profile.is_empty():
		return
	var name := String(profile.get("name", ""))
	var role := String(profile.get("role", ""))
	if name.is_empty():
		return
	var text := "%s　%s" % [name, role] if not role.is_empty() else name
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x + 58.0
	var plate: Control = TORN_BUBBLE.new()
	plate.name = "NamePlate"
	plate.size = Vector2(width, 52.0)
	plate.position = Vector2(bubble.position.x + 22.0, bubble.position.y - 46.0)
	plate.fill_color = PLATE_FILL
	plate.outline_color = PLATE_LINE
	plate.outline_width = 4.0
	plate.tail_side = "left"
	plate.tail_at = 0.5
	plate.tail_length = 22.0
	plate.jag = 6.0
	plate.shape_seed = 3311
	_ui_layer.add_child(plate)
	var label := _label(text, 21, INK, true)
	label.position = Vector2(28, 11)
	label.size = Vector2(width - 56.0, 30.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(label)


## 记忆便签：右下角浮出的小卡片，金 / 灰两种，颜色即语气，不写数值。
func _add_memo_note(choice_id: String) -> void:
	var note: Dictionary = _memo_note(choice_id)
	if note.is_empty():
		return
	# 便签一露面就回传：玩家这时候已经做完选择、也看过结果了。
	# 记账时机放在「点结束」之前 —— 就算他当场退出游戏，这张便签也已经贴上墙了。
	memo_recorded.emit(String(_event.get("id", "")), _memo_payload(choice_id, note))
	var size := _view_size()
	var card := Panel.new()
	card.name = "MemoNote"
	card.position = Vector2(size.x - 396.0, size.y - 700.0)
	card.size = Vector2(320.0, 146.0)
	var tone := String(note.get("tone", "gold"))
	var fill: Color = NOTE_TONE.get(tone, NOTE_TONE["gold"])
	card.add_theme_stylebox_override("panel", _note_style(fill))
	_ui_layer.add_child(card)
	var caption := _label("心湖记忆墙 · 新便签", 18, Color("5b4326"))
	caption.position = Vector2(20, 16)
	caption.size = Vector2(280, 28)
	card.add_child(caption)
	var body := _label(String(note.get("text", "")), 21, Color("3d2f1d"))
	body.position = Vector2(20, 50)
	body.size = Vector2(280, 80)
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(body)
	card.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.45).set_delay(0.35)


## 右下角操作提示：那排「F 快进 / X 自动 / LOG」的等价物。
func _add_key_hint(bubble: Control, text: String) -> void:
	var box: Control = TORN_BUBBLE.new()
	box.size = Vector2(116.0, 36.0)
	box.position = Vector2(bubble.size.x - 186.0, bubble.size.y - 52.0)
	box.fill_color = PLATE_FILL
	box.outline_color = PLATE_LINE
	box.outline_width = 2.0
	box.tail_side = "none"
	box.jag = 4.0
	box.shape_seed = 5150
	bubble.add_child(box)
	var key := _label("空格", 16, INK, true)
	key.position = Vector2(12, 7)
	key.size = Vector2(92, 22)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(key)
	var hint := _label(text, 16, Color("c4b9a2"))
	hint.position = Vector2(bubble.size.x - 312.0, bubble.size.y - 48.0)
	hint.size = Vector2(114, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bubble.add_child(hint)


func _clear_ui() -> void:
	for child in _ui_layer.get_children():
		child.queue_free()
	_typewriter_label = null
	_typewriter_rich = null
	_entry_fade = null
	_entry_card = null


func _speaker_profile(speaker_id: String) -> Dictionary:
	var speakers: Dictionary = _event.get("speakers", {})
	if speakers.has(speaker_id):
		var profile := Dictionary(speakers[speaker_id])
		profile["id"] = speaker_id
		return profile
	for value in _cast_list():
		var actor := Dictionary(value)
		if String(actor.get("id", "")) == speaker_id:
			return actor
	return {}


## 结果页那句"谁说了什么"读的是**选项自己带的 outcome**（开发册 11.4 第 2 条）。
## 以前只查事件级那张旧 outcome 表——全年 39 个带选项的节点都把话写在选项上，
## 表是空的，于是每次选完都掉到"你的选择被记录下来了"这句兜底里。
func _outcome_text(choice_id: String) -> String:
	for value in (_event.get("choices", []) as Array):
		if not (value is Dictionary):
			continue
		var choice := Dictionary(value)
		if String(choice.get("id", "")) != choice_id:
			continue
		var per_choice := String(choice.get("outcome", ""))
		if not per_choice.is_empty():
			return per_choice
	var outcomes: Dictionary = _event.get("outcome", {})
	return String(outcomes.get(choice_id, "你的选择被记录下来了。"))


func _memo_note(choice_id: String) -> Dictionary:
	var notes: Dictionary = _event.get("memoryNote", {})
	return Dictionary(notes.get(choice_id, {}))


## 便签的落盘记录：一次写全，读回时不需要再回查事件数据。
## 事件名 / 月日 / 选项文案 / 结果文案都带上了 —— 记忆墙要能独立成篇。
func _memo_payload(choice_id: String, note: Dictionary) -> Dictionary:
	return {
		"eventId": String(_event.get("id", "")),
		"eventTitle": String(_event.get("title", "")),
		"actTitle": String(_event.get("actTitle", "")),
		"month": int(_event.get("month", 1)),
		"day": int(_event.get("day", 1)),
		# 十二个月的日期口径是"上/中/下旬"，便签要跟着它写，别再用旧时钟算出来的"几日"。
		"phase": String(_event.get("phase", "")),
		"choiceId": choice_id,
		"choiceText": _choice_text(choice_id),
		"text": String(note.get("text", "")),
		"tone": String(note.get("tone", "gold")),
		"outcome": _outcome_text(choice_id),
		"npc": _lead_actor_name(),
	}


## 便签挂靠的角色**显示名**（cast 第一位）。记忆墙拿它反查好感档、在便签角落贴一枚色点。
## 只存显示名不用 id：NPC 有两套 id 空间（npcs.json 的 wange / MonthlyLife 的 wang_ge），
## 名字是唯一两边都成立的 join key。独处事件 cast 为空 → 空串 → 墙上就不贴点。
func _lead_actor_name() -> String:
	for value in _cast_list():
		var actor := Dictionary(value)
		var who := String(actor.get("name", ""))
		if not who.is_empty():
			return who
	return ""


func _choice_text(choice_id: String) -> String:
	for value in _event.get("choices", []) as Array:
		var choice := Dictionary(value)
		if String(choice.get("id", "")) == choice_id:
			return String(choice.get("text", ""))
	return choice_id


## 估算文字在给定宽度下占几行。给气泡定高用，不依赖运行时字体度量 ——
## headless 下的 Y 轴度量是 GUI 的两倍，拿它算高度会全错（判据 DisplayServer.get_name()）。
func _wrapped_lines(text: String, width: float, font_size: int) -> int:
	if width <= 1.0:
		return 1
	var lines := 0
	# 必须按 \n 分段算 —— 整段丢给 get_string_size 会把换行当成一个很宽的单行，
	# 于是气泡高度算矮、正文被底边切掉。
	for paragraph in text.split("\n"):
		if paragraph.is_empty():
			lines += 1
			continue
		var advance := FONT.get_string_size(paragraph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		lines += maxi(1, int(ceil(advance.x / width)))
	return maxi(1, lines)


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


func _load_texture(path: String) -> Texture2D:
	var imported := load(path) as Texture2D
	if imported != null:
		return imported
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _label(value: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(320, 40)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _bold(FONT, 0.6) if bold else FONT)
	label.add_theme_font_size_override("font_size", roundi(font_size * (1.12 if large_text else 1.0)))
	label.add_theme_color_override("font_color", color)
	return label


## 台词正文。强调短语来自 beat 的 emphasis 数组（数据里仍是干净原文），
## 这里只负责把关键词包成"更重的字重 + 砖红"，其余字保持原样。
func _emphasis_label(text: String, font_size: int, emphasis: Array, spacing: int = 14, term_word: String = "") -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# RichTextLabel 的 line_spacing 属性是枚举，像素间距要走主题常量。
	rich.add_theme_constant_override("line_spacing", spacing)
	var size := roundi(font_size * (1.12 if large_text else 1.0))
	rich.add_theme_font_override("normal_font", _bold(FONT, 0.6))
	rich.add_theme_font_override("bold_font", _bold(FONT, 1.0))
	rich.add_theme_font_size_override("normal_font_size", size)
	rich.add_theme_font_size_override("bold_font_size", size)
	rich.add_theme_color_override("default_color", Color("56301e"))
	rich.text = _markup(text, emphasis, term_word)
	if not term_word.is_empty() and text.contains(term_word):
		# 词本身可点：接到链接上就开解释；点在别处仍然照旧"点击继续"。
		rich.mouse_filter = Control.MOUSE_FILTER_STOP
		rich.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		rich.meta_clicked.connect(_on_term_meta)
		rich.meta_hover_started.connect(func(_meta): _term_hot = true)
		rich.meta_hover_ended.connect(func(_meta): _term_hot = false)
		rich.gui_input.connect(_on_term_body_input.bind(rich))
	return rich


func _markup(text: String, emphasis: Array, term_word: String = "") -> String:
	# 能点的词先单独包一层：松绿 + 下划线，跟剧情重音（砖棕加粗）区分开——
	# 一个意思是"这句要记住"，一个意思是"这个词可以点"，不能长一个样。
	var pre := text
	if not term_word.is_empty() and pre.contains(term_word):
		# [url] 包一层：玩家点的是这个词本身，不是只能去摸角上那颗点。
		pre = pre.replace(term_word,
			"[url=term][color=#%s][u]%s[/u][/color][/url]" % [TERM_INK.to_html(false), term_word])
	var phrases: Array[String] = []
	for value in emphasis:
		var phrase := String(value)
		if not phrase.is_empty() and text.contains(phrase):
			phrases.append(phrase)
	# 长的先包，避免短词把长词劈成两截。
	phrases.sort_custom(func(a, b): return a.length() > b.length())
	var result := pre
	var done: Array[String] = []
	for phrase in phrases:
		var covered := false
		for earlier in done:
			if earlier.contains(phrase):
				covered = true
				break
		if covered:
			continue
		result = result.replace(phrase, "[color=#%s][b]%s[/b][/color]" % [EMPHASIS_INK.to_html(false), phrase])
		done.append(phrase)
	return result


func _choice_emphasis(choice_id: String) -> Array:
	for value in _event.get("choices", []) as Array:
		if value is Dictionary and String((value as Dictionary).get("id", "")) == choice_id:
			return (value as Dictionary).get("emphasis", []) as Array
	return []


func _note_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.30, 0.24, 0.16, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style
