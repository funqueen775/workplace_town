extends CanvasLayer
## 心湖记忆墙 —— 把一路攒下的「记忆便签」贴成一墙。
##
## 这是 V5.27 里「有人记得我」那条线的承载体：
##   金便签 = 你自己觉得站得住的（纸色偏暖）
##   灰便签 = 你心里还留着疙瘩的（纸色偏冷）
## 颜色即语气，**永不出现任何数值** —— 和剧情面板同一条红线。
##
## 数据源：user://workplace_town_memos.jsonl（WorkplaceTown 在结果拍逐条追加）
## 一局一面：每条便签带着局编号，墙只贴本局的；新开局城镇会把上一局的墙清掉。
## 以前这里还会回查旧 48 个月的剧情目录补写老便签，2026-10-29 删掉——
## 那面墙上冒出"第 37 月 · 吹哨两难"就是这么来的。
##
## 美术图到位后只改 WALL_TEXTURE 常量，布局不动。

signal wall_closed()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

const MEMO_PATH := "user://workplace_town_memos.jsonl"
## 一局一面墙：城镇开新局时发一个编号，墙上只显示这个编号的便签。
## -1 = 不过滤（验收脚本直接喂一组记录时用的）。
var run_stamp := -1

const PAGE_W := 1348.0
const PAGE_H := 848.0
const PAD := 64.0
## 竖直滚动条是**占位**的：它一出现，内容区就少 10px。
## 三列宽度必须按「减掉滚动条之后」的宽度去分，否则最右一列的边框会被裁掉。
const SCROLLBAR := 10.0
## 右边缘给滚动条留一条空沟：条画在容器里，不留沟就会压在第三列便签上。
const SB_GUTTER := 16.0
## 便签的高度不再写死：抬头区（日期 + 事件名）固定，正文按字数长，底下留一圈白。
const NOTE_HEAD := 74.0
const NOTE_FOOT := 26.0
const NOTE_MIN_H := 168.0
const CONTENT_W := PAGE_W - PAD * 2.0 - SCROLLBAR
const STRIP_W := PAGE_W - PAD * 2.0
const COLS := 3
const GAP_X := 41.0
const NOTE_W := (CONTENT_W - SB_GUTTER - GAP_X * 2.0) / COLS
## 卡高 216 + 行距 38 = 一屏刚好两行（470）—— 滚动区高度必须取整行，
## 否则第二行会被视口拦腰切断，纸片看着像坏了。
## 旧版固定高度只留给空墙/回退用，真高度见 _note_height()。
const NOTE_H := 216.0
const GAP_Y := 38.0

const SCROLL_Y := 152.0
const SCROLL_H := 452.0
const STRIP_Y := 624.0
const STRIP_H := 150.0
## 卡面上沿那条胶带是画在卡框**外面**的（y = -11），滚动区必须留出内边距，
## 否则滚到顶/底时最外面那一行的胶带会被视口切掉，纸片就"没贴住"。
const WALL_PAD := 14.0
## 选中的那张"被从墙上拿起来"的抬升量。
const LIFT := 6.0

const PAPER := Color("efe4cf")
const PAPER_DARK := Color("e2d4b8")
const INK := Color("352b1e")
const INK_SOFT := Color("6d5c46")
const NOTE_LINE := Color(0.32, 0.27, 0.19, 0.9)

## 金 / 灰两副纸。纸色就是语气，卡面上不再贴任何标签。
const TONE := {
	"gold": {"paper": Color("f4dfa4"), "line": Color("b08a37")},
	"gray": {"paper": Color("d5d2ca"), "line": Color("6e6f74")},
}
## 手贴的痕迹：固定角度轮换（不随机，免得每次开墙都在抖）。
const TILT := [-2.1, 1.5, -0.9, 2.3, -1.4, 0.8]

## 关系档色点（V5.27 §11.3：该 NPC 的便签颜色「蓝→黄→金」渐进）。
## 五档压成三色，分界点选在 Lv3 —— 那是「熊友卡解锁」这一档，是玩家能感知的门槛。
## ⚠ 这枚点**只管关系**；便签底色仍归 memoryNote.tone（金=站得住 / 灰=疙瘩）。
## 两套语义各走各的，谁都不覆盖谁。查不到角色（独处事件 / 陈工不在关系系统）就不贴。
const RELATION_DOT := {
	1: Color("6f9ec4"),
	2: Color("6f9ec4"),
	3: Color("d9b441"),
	4: Color("b08a37"),
	5: Color("b08a37"),
}
const DOT_SIZE := 16.0

var _root: Control
var _scroll: ScrollContainer
var _wall: Control
var _empty_label: Label
var _count_label: Label
var _detail_title: Label
var _detail_body: Label

var _notes: Array = []
var _cards: Array = []
## 每张便签的落点与高度：高度跟着正文走，同一行取最高那张，底下参差才像手贴的。
var _strip_tone: ColorRect
var _scroll_fade_top: TextureRect
var _scroll_fade_bottom: TextureRect
var _positions: Array[Vector2] = []
var _heights: Array[float] = []
var _selected := -1
## 关系档数据源可空：不做 autoload，验收脚本可直接 new
## 出来时它是 null —— 那种情况下墙上不贴色点，而不是报错或瞎猜一个档位。
var _life = null


## 注入生活系统。WorkplaceTown 建面板时调用；不调 = 没有关系档色点。
func setup(life) -> void:
	_life = life


func _ready() -> void:
	# 压在剧情面板(150)与手册(160)之上：从小镇 HUD 打开时不能被别的层遮住。
	layer = 170
	_root = Control.new()
	_root.name = "MemoryWallOverlay"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_build_shell()
	_root.hide()


# ---------------------------------------------------------------- 对外

## records 传空数组就从 user:// 读；显式给数据是为了验收脚本能灌样例。
func open(records: Array = []) -> void:
	show_records(records if not records.is_empty() else _load_records())

## 直接铺给定的一组记录，不碰磁盘。空数组 = 空墙（验收脚本要看空状态）。
## 十二个月只有 1–12 月：月号越界的记录一律不贴 —— 旧 48 个月那套目录曾经混进来过
## （「第 42 月 · 吹哨两难」），而这张墙是给玩家回看自己这一路的，
## 不能出现他根本没见过的事。闸门放在这个唯一入口，磁盘和外部灌进来都过一遍。
func show_records(records: Array) -> void:
	_notes = _only_month12(records)
	_selected = -1
	_cards.clear()
	_rebuild()
	_root.show()


func _only_month12(records: Array) -> Array:
	var kept: Array = []
	for value in records:
		if not (value is Dictionary):
			continue
		var month := int((value as Dictionary).get("month", 0))
		if month < 1 or month > 12:
			continue
		kept.append(value)
	return kept


func close() -> void:
	if _root == null or not _root.visible:
		return
	_root.hide()
	wall_closed.emit()


func is_open() -> bool:
	return _root != null and _root.visible


func note_count() -> int:
	return _notes.size()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- 骨架

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.88)
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

	var title := _label("心湖记忆墙", 42, INK, true, 700.0)
	title.position = Vector2(PAD, 38)
	title.size = Vector2(700, 58)
	page.add_child(title)

	# 语气说明写在标题下面 —— 玩家第一次进来得知道冷暖两种纸是干什么的。
	var sub := _label("金便签，是你自己觉得站得住的；灰便签，是你心里还留着疙瘩的。", 20, INK_SOFT, false, 900.0)
	sub.position = Vector2(PAD, 100)
	sub.size = Vector2(900, 30)
	page.add_child(sub)

	_count_label = _label("", 22, INK, false, 460.0)
	_count_label.position = Vector2(PAGE_W - PAD - 460.0, 52)
	_count_label.size = Vector2(460, 32)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page.add_child(_count_label)

	_scroll = ScrollContainer.new()
	_scroll.name = "WallScroll"
	_scroll.position = Vector2(PAD, SCROLL_Y)
	_scroll.size = Vector2(CONTENT_W, SCROLL_H)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_theme_constant_override("scrollbar_width", int(SCROLLBAR))
	page.add_child(_scroll)
	_style_scrollbar(_scroll.get_v_scroll_bar())

	_wall = Control.new()
	_wall.name = "Wall"
	_wall.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_wall)

	# 上下各压一道纸色渐隐：滚动区里被切开的那排便签会"化"进纸里，
	# 而不是齐边切一刀（截断的那排看着像画坏了）。
	_scroll_fade_top = _edge_fade(true)
	_scroll_fade_top.position = Vector2(PAD, SCROLL_Y)
	_scroll_fade_top.size = Vector2(CONTENT_W - SB_GUTTER, 30)
	page.add_child(_scroll_fade_top)
	_scroll_fade_bottom = _edge_fade(false)
	_scroll_fade_bottom.position = Vector2(PAD, SCROLL_Y + SCROLL_H - 30.0)
	_scroll_fade_bottom.size = Vector2(CONTENT_W - SB_GUTTER, 30)
	page.add_child(_scroll_fade_bottom)

	_empty_label = _label("墙上还是空的。\n\n做完第一个选择，第一张便签就会贴上来。", 26, INK_SOFT, false, CONTENT_W)
	_empty_label.position = Vector2(0, 150)
	_empty_label.size = Vector2(CONTENT_W, 110)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.hide()
	_wall.add_child(_empty_label)

	var strip := Panel.new()
	strip.name = "DetailStrip"
	strip.position = Vector2(PAD, STRIP_Y)
	strip.size = Vector2(STRIP_W, STRIP_H)
	strip.add_theme_stylebox_override("panel", _strip_style())
	page.add_child(strip)

	# 条子左边缘那一道色：跟被拿起的那张便签同色，一眼看出下面这段话是在说哪张纸。
	_strip_tone = ColorRect.new()
	_strip_tone.position = Vector2(0, 0)
	_strip_tone.size = Vector2(7, STRIP_H)
	_strip_tone.color = Color(0.85, 0.72, 0.35, 0.0)
	_strip_tone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(_strip_tone)

	_detail_title = _label("", 19, INK_SOFT, false, STRIP_W - 48.0)
	_detail_title.position = Vector2(24, 12)
	_detail_title.size = Vector2(STRIP_W - 48.0, 28)
	strip.add_child(_detail_title)

	# 回看那一刻：当时的选项 + 当时的结果。
	# ⚠ Label **默认不裁剪**：不设 max_lines_visible 的话，长结果会直接画出条外、
	# 压到下方页面空白上（视觉上像鬼影）。条高只够三行，超出用省略号收。
	_detail_body = _label("", 20, INK, false, STRIP_W - 48.0)
	_detail_body.max_lines_visible = 3
	_detail_body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_body.add_theme_constant_override("line_spacing", 6)
	_detail_body.position = Vector2(24, 46)
	_detail_body.size = Vector2(STRIP_W - 48.0, 96)
	_detail_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	strip.add_child(_detail_body)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "合上记忆"
	close_button.size = Vector2(200, 56)
	close_button.position = Vector2(PAGE_W - PAD - 200.0, PAGE_H - 74.0)
	_style_close(close_button)
	close_button.pressed.connect(close)
	page.add_child(close_button)


# ---------------------------------------------------------------- 铺墙

func _rebuild() -> void:
	for child in _wall.get_children():
		if child == _empty_label:
			continue
		_wall.remove_child(child)
		child.queue_free()
	_layout_notes()
	# 空墙也要留出高度，否则 _empty_label 的坐标会被 ScrollContainer 压掉。
	var wall_h := SCROLL_H
	if not _positions.is_empty():
		var max_bottom := 0.0
		for index in _positions.size():
			max_bottom = maxf(max_bottom, _positions[index].y + _heights[index])
		wall_h = maxf(SCROLL_H, max_bottom + WALL_PAD)
	_wall.custom_minimum_size = Vector2(CONTENT_W - SB_GUTTER, wall_h)
	_update_count()
	if _notes.is_empty():
		_empty_label.show()
		# 详情条这时候不写"还没有便签"——中间那句已经说过了，重复等于噪音。
		# 改成回答玩家真正会问的那个问题：这东西是从哪来的。
		_detail_title.text = "便签从哪来"
		_detail_body.text = "每次主线事件落幕，结果拍上浮出的那张小卡片会被贴到这儿，按时间从旧到新。同一件事重来一次，会盖掉同名的那张。"
		return
	_empty_label.hide()
	for index in _notes.size():
		_build_note(index, Dictionary(_notes[index]))
	# 默认选中最后一张：玩家最想看的通常是"刚贴上去的那张"。
	_select(_notes.size() - 1)
	# 顺手把它滚进视野 —— 否则高亮在屏幕外，下面的详情条就对不上人。
	_snap_to_latest()


## 滚到墙尾（最新那张）。
## ⚠ 必须等两帧：ScrollContainer 的 sort_children 是**延后**跑的，本帧它的可滚范围
## 还是 0，这时候设 scroll_vertical 会被 Range 直接夹回 0 —— 表现就是"滚不动"。
## 用 ensure_control_visible() 同理不稳：它也要先有内容高度才算得出目标位置。
func _snap_to_latest() -> void:
	if _cards.is_empty():
		return
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	await tree.process_frame
	if _cards.is_empty():
		return
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


## 这张便签要多高：抬头区 + 正文按宽度折行后的真实高度 + 底下留白。
## Label 的 autowrap 只有在宽度给对之后才算得出行数，所以先把宽度定死再量。
func _note_height(memo: Dictionary) -> float:
	var body_w := NOTE_W - 56.0
	var text := String(memo.get("text", ""))
	# 直接问字体：Label 在没进树、宽度还是 0 的时候量出来的是一行高，
	# 照那个数排出来的纸会矮一截，字被纸边切掉（第一版就是这么错的）。
	var font := _bold(FONT, 0.6)
	var text_size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, body_w, 25)
	var body_h := maxf(text_size.y, 34.0)
	return clampf(NOTE_HEAD + body_h + NOTE_FOOT, NOTE_MIN_H, 380.0)


## 一行三张，行高取本行最高的那张：短句子的便签就是短一张纸，不是硬撑成一样高。
## 不按列瀑布流是为了保住"从旧到新、从左到右"的读法。
func _layout_notes() -> void:
	_positions.clear()
	_heights.clear()
	var y := WALL_PAD
	var row_h := 0.0
	for index in _notes.size():
		var col := index % COLS
		if col == 0 and index > 0:
			y += row_h + GAP_Y
			row_h = 0.0
		var h := _note_height(Dictionary(_notes[index]))
		_heights.append(h)
		_positions.append(Vector2(float(col) * (NOTE_W + GAP_X), y))
		row_h = maxf(row_h, h)


func _build_note(index: int, memo: Dictionary) -> void:
	var card := Button.new()
	card.name = "Note%d" % index
	card.position = _base_position(index)
	var note_h := _heights[index] if index < _heights.size() else NOTE_H
	card.size = Vector2(NOTE_W, note_h)
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(_select.bind(index))
	# 手贴的痕迹：绕中心转一个小角度。父层不裁剪，所以角会微微出框，更像纸。
	card.pivot_offset = card.size * 0.5
	card.rotation = deg_to_rad(TILT[index % TILT.size()])
	_wall.add_child(card)
	_cards.append(card)
	_refresh_card(index)

	# 胶带：卡面上沿压的一小条，贴纸感的全部来源。
	var tape := ColorRect.new()
	tape.color = Color(0.99, 0.95, 0.83, 0.55)
	tape.position = Vector2(NOTE_W * 0.5 - 54.0, -11.0)
	tape.size = Vector2(108, 24)
	tape.pivot_offset = tape.size * 0.5
	# 胶带也歪一点点：整面墙每张都笔直居中，反而像印刷品。
	tape.rotation = deg_to_rad(0.0 if index % 2 == 0 else (1.2 if index % 3 == 0 else -1.0))
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tape)

	var meta := _label("%s · %s" % [_date_text(memo), String(memo.get("eventTitle", ""))], 18, INK_SOFT, false, NOTE_W - 56.0)
	meta.position = Vector2(28, 26)
	meta.size = Vector2(NOTE_W - 56.0, 26)
	card.add_child(meta)

	# 便签正文按 25px 排：一张卡内宽 320，最长的一条是 12 个汉字（300px），
	# 27px 会把它挤到第二行只剩一个「还」字。
	# 正文高度跟着便签走：以前写死 96，长句子会直接画到纸外面（实拍里被切掉半个字）。
	var body := _label(String(memo.get("text", "")), 25, INK, true, NOTE_W - 56.0)
	body.position = Vector2(28, 72)
	var body_h := maxf(note_h - 72.0 - 18.0, 34.0)
	body.size = Vector2(NOTE_W - 56.0, body_h)
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var line_h := maxf(_bold(FONT, 0.6).get_height(25), 1.0)
	body.max_lines_visible = maxi(1, floori(body_h / line_h))
	body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(body)

	# 关系档色点。落在**右下角**而不是右上角：右上被 meta（「第 12 月 28 日 · 事件名」）
	# 一直占到 x≈348，NOTE_W 才 376，放上去必然压字；右下这块是空的。
	var level := _dot_level_of(memo)
	if level > 0:
		card.add_child(_relation_dot(level, note_h))

	# 回填来的便签标一下出处：玩家能看出这张是从老存档里救回来的。
	if bool(memo.get("rescued", false)):
		var rescued := _label("· 从旧记录里找回", 15, INK_SOFT, false, 220.0)
		rescued.position = Vector2(28, note_h - 38.0)
		rescued.size = Vector2(220, 24)
		card.add_child(rescued)


## 这枚点：底色就是档位，卡面上不写任何数字和「Lv3」这类编号。
func _relation_dot(level: int, note_h := NOTE_H) -> Panel:
	var dot := Panel.new()
	dot.name = "RelationDot"
	dot.position = Vector2(NOTE_W - DOT_SIZE - 18.0, note_h - DOT_SIZE - 18.0)
	dot.size = Vector2(DOT_SIZE, DOT_SIZE)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = RELATION_DOT.get(level, RELATION_DOT[1])
	style.border_color = Color(1, 1, 1, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(DOT_SIZE * 0.5))
	dot.add_theme_stylebox_override("panel", style)
	return dot


## 便签挂在谁身上、那个人现在是什么档。返回 0 = 不贴点。
## memo["npc"] 存的是**显示名**（StoryEventPanel._lead_actor_name），
## 名字是两套 id 空间之间唯一都成立的 join key。
func _dot_level_of(memo: Dictionary) -> int:
	if _life == null:
		return 0
	var who := String(memo.get("npc", "")).strip_edges()
	if who.is_empty():
		return 0
	var npc_id := String(_life.relation_key_of_name(who))
	if npc_id.is_empty():
		return 0
	return int(_life.affinity_level(_life.affinity_of(npc_id)))


## 详情条上那句关系话：「和王哥 · 老熟人了」。**只有人话，没有分数。**
func _relation_label_of(memo: Dictionary) -> String:
	if _life == null or _dot_level_of(memo) <= 0:
		return ""
	var who := String(memo.get("npc", "")).strip_edges()
	var stage := String(_life.relation_stage_of_name(who))
	if stage.is_empty():
		return ""
	return "和%s · %s" % [who, stage]


func _refresh_card(index: int) -> void:
	if index < 0 or index >= _cards.size():
		return
	var card: Button = _cards[index]
	if card == null or not is_instance_valid(card):
		return
	var palette: Dictionary = TONE.get(String(Dictionary(_notes[index]).get("tone", "gold")), TONE["gold"])
	var paper := Color(palette["paper"])
	var line := Color(palette["line"])
	# 选中 = 深色粗边框 + 整张往上抬 6px：一墙纸里最像「这张被拿起来了」的提示。
	var on := index == _selected
	card.position = _base_position(index) + (Vector2(0, -LIFT) if on else Vector2.ZERO)
	card.add_theme_stylebox_override("normal", _note_box(paper, 5.0 if on else 2.0, line if on else NOTE_LINE))
	card.add_theme_stylebox_override("hover", _note_box(paper.lightened(0.07), 3.0, line))
	card.add_theme_stylebox_override("pressed", _note_box(paper.darkened(0.05), 5.0, line))


## 卡片在网格里的固定落点。选中抬升是叠在它上面的偏移，不写进这里。
func _base_position(index: int) -> Vector2:
	if index >= 0 and index < _positions.size():
		return _positions[index]
	return Vector2(
		float(index % COLS) * (NOTE_W + GAP_X),
		WALL_PAD + float(index / COLS) * (NOTE_H + GAP_Y)
	)


func _select(index: int) -> void:
	if index < 0 or index >= _notes.size():
		return
	var previous := _selected
	_selected = index
	_refresh_card(previous)
	_refresh_card(index)
	var memo := Dictionary(_notes[index])
	var tone_name := "灰便签" if String(memo.get("tone", "gold")) == "gray" else "金便签"
	if _strip_tone != null:
		var tone_key := String(memo.get("tone", "gold"))
		var palette: Dictionary = TONE.get(tone_key, TONE["gold"])
		_strip_tone.color = Color(palette["line"])
	_detail_title.text = "%s · %s · %s" % [_date_text(memo), String(memo.get("eventTitle", "")), tone_name]
	# 顺带说清那枚色点是给谁的、现在什么档 —— 否则它看着像个装饰。
	var relation_note := _relation_label_of(memo)
	if not relation_note.is_empty():
		_detail_title.text += "　·　%s" % relation_note
	var choice := String(memo.get("choiceText", ""))
	# 事件数据里的结果文案常用 "\n\n" 分段（剧情面板上是两段话），
	# 搬进这一条窄条里要把空行收掉，不然三行额度全被吃掉。
	var outcome := String(memo.get("outcome", "")).replace("\n\n", "\n").strip_edges()
	var head := ""
	if not choice.is_empty():
		head = "你当时选了「%s」。" % choice
	_detail_body.text = ("%s\n%s" % [head, outcome]).strip_edges()


func _update_count() -> void:
	var gold := 0
	for value in _notes:
		if String(Dictionary(value).get("tone", "gold")) != "gray":
			gold += 1
	var gray := _notes.size() - gold
	if _notes.is_empty():
		_count_label.text = ""
		return
	_count_label.text = "共 %d 张便签　·　金 %d　·　灰 %d" % [_notes.size(), gold, gray]


# ---------------------------------------------------------------- 数据

## 只读本局那面墙：便签落盘时带着局编号，编号对不上的一律不贴。
## 2026-10-29 起不再从旧 48 个月的剧情目录回填 —— 那正是"第 37 月 · 吹哨两难"
## 这种条目混进十二个月墙里的原因。路径做成参数：验收探针可以指临时文件跑。
func _load_records(memo_path: String = MEMO_PATH) -> Array:
	var by_event: Dictionary = {}
	var order: Array = []
	for line in _read_lines(memo_path):
		var parsed: Variant = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var row := Dictionary(parsed)
		var event_id := String(row.get("eventId", ""))
		if event_id.is_empty():
			continue
		if run_stamp > 0 and int(row.get("runStamp", 0)) != run_stamp:
			continue
		if not by_event.has(event_id):
			order.append(event_id)
		# 同一事件重玩以最后一次为准：后写的覆盖先写的。
		by_event[event_id] = row
	var records: Array = []
	for event_id in order:
		records.append(by_event[event_id])
	records.sort_custom(func(a, b): return int(Dictionary(a).get("worldMinute", 0)) < int(Dictionary(b).get("worldMinute", 0)))
	return records


func _read_lines(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var lines: Array = []
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if not line.is_empty():
			lines.append(line)
	file.close()
	return lines


## 便签上的日期跟着十二个月的口径走：第 N 月 · 上/中/下旬。
## 以前写"第 N 月 M 日"，那个"日"是旧 48 个月世界时钟算出来的，
## 玩家在界面上看到的从来不是它，两边对不上。
func _date_text(memo: Dictionary) -> String:
	var month := int(memo.get("month", 1))
	var phases := {"early": "上旬", "mid": "中旬", "late": "下旬"}
	var xun := String(phases.get(String(memo.get("phase", "")), ""))
	if xun.is_empty():
		return "第 %d 月" % month
	return "第 %d 月 · %s" % [month, xun]


# ---------------------------------------------------------------- 样式

func _view_size() -> Vector2:
	var vp: Viewport = get_viewport()
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
	label.size = Vector2(wrap_width, 40)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _bold(FONT, 0.6) if bold else FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _paper_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color(0.28, 0.22, 0.15, 0.85)
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 9)
	return style


func _strip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER_DARK
	style.border_color = Color(0.32, 0.25, 0.17, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style


func _note_box(fill: Color, border: float, line: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = line
	style.set_border_width_all(int(border))
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style


## 纸色渐隐：上沿从纸色渐到透明，下沿反过来，用来盖住被滚切开的便签边。
func _edge_fade(from_top: bool) -> TextureRect:
	var gradient := Gradient.new()
	var solid := Color(PAPER.r, PAPER.g, PAPER.b, 0.98)
	var clear := Color(PAPER.r, PAPER.g, PAPER.b, 0.0)
	gradient.set_color(0, solid if from_top else clear)
	gradient.set_color(1, clear if from_top else solid)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var fade := TextureRect.new()
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fade


## 滚动条：细、暖色、圆头。默认那条是系统灰，压在米色纸上像贴了条胶带。
func _style_scrollbar(bar: VScrollBar) -> void:
	if bar == null:
		return
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.42, 0.36, 0.26, 0.10)
	track.set_corner_radius_all(int(SCROLLBAR * 0.5))
	bar.add_theme_stylebox_override("scroll", track)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.42, 0.36, 0.26, 0.42)
	grabber.set_corner_radius_all(int(SCROLLBAR * 0.5))
	bar.add_theme_stylebox_override("grabber", grabber)
	var grabber_hi := grabber.duplicate() as StyleBoxFlat
	grabber_hi.bg_color = Color(0.42, 0.36, 0.26, 0.62)
	bar.add_theme_stylebox_override("grabber_highlight", grabber_hi)
	bar.add_theme_stylebox_override("grabber_pressed", grabber_hi)


func _style_close(button: Button) -> void:
	button.add_theme_font_override("font", _bold(FONT, 0.5))
	button.add_theme_font_size_override("font_size", 19)
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
