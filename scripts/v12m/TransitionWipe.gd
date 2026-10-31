class_name TransitionWipe
extends CanvasLayer

## 十二个月的时间过场：跨旬、时段、翻月、昼夜四档。
## 卡上出现的字全部由调用方给，本脚本不认识剧情——过场只说「何时」，永远不说「何事」。
## 参数取自《十二个月开发文档_V1》4.14 与 11.23：压暗 + 斜切色条 + 旧字甩出 + 新字砸入 + 爪印甩墨。
## 2026-10-27 拍板：先不配声音，节奏全交给视觉。

signal finished(tier: String)
## 昼夜那一格换了，外面跟着把世界光照渐变过去。
signal band_lights(band: String)

const FONT_HAND := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const ART_PAW := preload("res://assets/ui/rework_v1/task_book/22_页面装饰爪印.png")

const DIM_INK := Color("452716")
const BAR_BRICK := Color("B94A32")
const BAR_DEEP := Color("8E3A2A")
const BAR_GOLD := Color("f4ad25")
const CARD_INK := Color("F3E3C2")
const CAPSULE_RED := Color("c0392b")

const QUALITY_FULL := 0
const QUALITY_SHORT := 1
const QUALITY_OFF := 2

## 整族转场的速度旋钮（2026-10-28 反馈"稍微放慢一些"，从 1.0 提到 1.3）。
## 只改这一个数：跨旬、翻月、昼夜三档连同日历翻页的小动作一起变慢，
## 档位之间的相对快慢不变（翻月仍然最重、昼夜仍然最轻）。
## 硬切 play_hard_cut 不在里面——那一下要的就是"什么都没发生"的干脆。
const TIME_SCALE := 1.3

var quality: int = QUALITY_FULL

## 过场皮肤（三张样张用的开关，挑完就固定成一个）：
## 0 = 现在这版：一条斜杠 + 暖色淡甩字。
## 1 = 多层斜切色块前后夹着字、字被色块"带"进来，配色仍是蜂蜜纸色。
## 2 = 连硬边皮肤一起借：近黑底 + 砖红/米白色块 + 白字重描边 + 网点压印，只在过场那一秒多生效。
var style: int = 0

const SKINS := [
	{"bars": [Color("d49a4c"), Color("B94A32"), Color("7a3a22")], "dim": Color("452716"), "ink": Color("F3E3C2"), "outline": 6, "halftone": 0.0},
	{"bars": [Color("e0a83f"), Color("B94A32"), Color("5c3a22")], "dim": Color("3a2113"), "ink": Color("FFF3DC"), "outline": 6, "halftone": 0.16},
	{"bars": [Color("141210"), Color("c0392b"), Color("f4f0e6")], "dim": Color("0d0b0a"), "ink": Color("ffffff"), "outline": 14, "halftone": 0.22},
]

var _root: Control
var _dim: ColorRect
var _bar: ColorRect
var _blocks: Array[ColorRect] = []
var _halftone: TextureRect
var _big: Label
var _sub: Label
var _paws: Array[TextureRect] = []
var _capsule: Panel
var _capsule_label: Label
var _sweep: ColorRect

var _tween: Tween
var _playing := false
var _allow_skip := false
var _skip_requested := false
var _tier := ""
## 这一档从开播到落定的真实时长：只在 V12M_WIPE_TIME=1 时打印，量节奏用。
var _started_msec := 0
## 落定前攒下的格子替换：点跳过的话一次写完，不会出现「跳过了但字还是旧的」。
var _cell_swaps: Array = []
## 跨旬卡顺带要换的昼夜档：和格子替换一起落定，点跳过也不会漏掉这一枪。
var _pending_band := ""


func _ready() -> void:
	layer = 185
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = Color(DIM_INK, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	_bar = ColorRect.new()
	_bar.color = Color(BAR_BRICK, 0.0)
	_bar.size = Vector2(220, 3000)
	_bar.pivot_offset = _bar.size * 0.5
	_bar.rotation_degrees = -14.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar)

	# 多层斜切色块：先建、排在字下面，飞进来时是"色块夹着字"而不是"字压在杠上"。
	for index in 3:
		var block := ColorRect.new()
		block.size = Vector2(300, 3000)
		block.pivot_offset = block.size * 0.5
		block.rotation_degrees = -14.0
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block.visible = false
		_blocks.append(block)
		_root.add_child(block)
	_halftone = TextureRect.new()
	_halftone.texture = _make_dots_texture()
	_halftone.stretch_mode = TextureRect.STRETCH_TILE
	_halftone.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# TextureRect 没有 color 属性（只有 modulate）；写错这行会让 _ready 直接中断。
	_halftone.modulate = Color(1, 1, 1, 0)
	_halftone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halftone.visible = false
	_root.add_child(_halftone)
	# 铺满要在进了父节点之后再设，否则取到的父矩形是空的。
	_halftone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_sub = _make_label(FONT_BODY, 64, Color("e8cfa4"))
	_root.add_child(_sub)

	_big = _make_label(FONT_HAND, 168, CARD_INK)
	_root.add_child(_big)

	for index in 2:
		var paw := TextureRect.new()
		paw.texture = ART_PAW
		paw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		paw.stretch_mode = TextureRect.STRETCH_SCALE
		paw.custom_minimum_size = Vector2(86, 86)
		paw.size = Vector2(86, 86)
		paw.modulate = Color(1, 1, 1, 0)
		paw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paw.rotation_degrees = -12.0 if index == 0 else 9.0
		_paws.append(paw)
		_root.add_child(paw)

	_capsule = Panel.new()
	var capsule_style := StyleBoxFlat.new()
	capsule_style.bg_color = CAPSULE_RED
	capsule_style.border_color = Color("ffe5a8")
	capsule_style.set_border_width_all(3)
	capsule_style.set_corner_radius_all(30)
	_capsule.add_theme_stylebox_override("panel", capsule_style)
	_capsule.size = Vector2(220, 60)
	_capsule.pivot_offset = _capsule.size * 0.5
	_capsule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capsule.modulate.a = 0.0
	_root.add_child(_capsule)
	_capsule_label = _make_label(FONT_BODY, 26, Color("fff4d6"))
	# 不能在这里用 PRESET_FULL_RECT：还没进父节点，取到的父矩形是空的，
	# 结果文字被居中到胶囊左边界外面去了。直接按胶囊尺寸摆。
	_capsule_label.position = Vector2.ZERO
	_capsule_label.size = Vector2(220, 60)
	_capsule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# _make_label 默认把自身透明度压到 0（大字卡要用淡入）；
	# 胶囊里的字必须跟着胶囊一起出现，这里显式拉回不透明。
	_capsule_label.modulate.a = 1.0
	_capsule.add_child(_capsule_label)

	# 昼夜那一格用的光带：只在格子内部划过去，不遮全屏。
	_sweep = ColorRect.new()
	_sweep.color = Color("ffe9b0", 0.0)
	_sweep.size = Vector2(46, 200)
	_sweep.pivot_offset = _sweep.size * 0.5
	_sweep.rotation_degrees = -14.0
	_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_sweep)
	_hide_all()


func is_playing() -> bool:
	return _playing


## 跨旬：上旬→中旬、中旬→下旬。mirrored=true 时整套动作左右镜像、色条更暗，
## 让玩家认得出「还是跨旬」，又不会觉得在重播。
## gap_text 非空时先单独交代「过了多久」（"两周后"），再让新旬字登场：
## 跨旬换掉的不只是一个字，是一段时间（2026-10-30 反馈「衔接太突然，没有过渡」）。
func play_xun(old_text: String, new_text: String, xun_cell: Label, sub_text: String, action_points: int, mirrored := false, band_cell: Label = null, band_text := "", gap_text := "") -> void:
	if quality == QUALITY_OFF:
		# 关闭档：一律 0.15 秒硬切，不出字。格子直接改。
		_set_cell_text(xun_cell, new_text)
		if band_cell != null and not band_text.is_empty():
			_set_cell_text(band_cell, band_text)
			band_lights.emit(band_text)
		play_hard_cut()
		return
	_begin("xun", quality == QUALITY_FULL)
	_queue_cell_swap(xun_cell, new_text)
	# 跨旬的同时还跨了昼夜（第 5 月深夜 → 第二天白天）：那一格在压暗期间一起换掉，
	# 灯也等字落定再亮，不然卡片还在说"中旬"、画面已经跳到白天。
	if band_cell != null and not band_text.is_empty():
		_queue_cell_swap(band_cell, band_text)
		_pending_band = band_text
	var out_dir := Vector2(1.0, -0.55) if not mirrored else Vector2(-1.0, 0.5)
	var in_dir := Vector2(-1.0, -0.35) if not mirrored else Vector2(1.0, 0.45)
	var bar_color := BAR_DEEP if mirrored else BAR_BRICK
	var dim_alpha := 0.96 if mirrored else 0.94
	_sweep_card(old_text, new_text, sub_text, action_points, out_dir, in_dir, bar_color, dim_alpha, _quality_time(1.4 * TIME_SCALE), gap_text)


## 「时段卡」（上午↔午后）已删：日历没有这一格、行动点不看钟点，
## 播了就是一句没有落点的旁白。日内只留 play_daylight 那一档。


## 翻月：三格全换，底板像撕日历那样翻一下，月份数字一格一格滚过去。
## 全游戏只有这一档用金色斜杠——看到金色就知道跨的不是旬，是月。
func play_month(month_cell: Label, xun_cell: Label, band_cell: Label, month_text: String, xun_text: String, band_text: String, sub_text: String, action_points: int) -> void:
	if quality == QUALITY_OFF:
		_set_cell_text(month_cell, month_text)
		_set_cell_text(xun_cell, xun_text)
		_set_cell_text(band_cell, band_text)
		band_lights.emit(band_text)
		play_hard_cut()
		return
	_begin("month", quality == QUALITY_FULL)
	# 三格的目标字先记进 _cell_swaps：滚字/回卷/淡换都在 tween 的回调里，
	# 玩家点一下跳过时 tween 被 kill，回调不会再跑——不预先记账，牌面就会停在上个月，
	# 而剧情已经翻篇（日期读数在 _set_date 里当场就记了），从此整月对不上（2026-10-30 实机截图）。
	_queue_cell_swap(month_cell, month_text)
	_queue_cell_swap(xun_cell, xun_text)
	_queue_cell_swap(band_cell, band_text)
	var center := _viewport_size() * 0.5
	_apply_skin()
	_show(_dim)
	_show(_bar)
	if style == 0:
		_sweep_bar(BAR_GOLD, _slow(0.24))
	else:
		_fly_layers_in(_slow(0.26))
	_show(_big)
	_big.text = month_text
	_center_on(_big, center, 150, 90)
	_big.pivot_offset = _big.size * 0.5
	_big.modulate.a = 0.0
	_big.rotation_degrees = -6.0
	_show(_sub)
	_sub.text = sub_text
	_center_on(_sub, center + Vector2(0, 150), 64)
	_sub.modulate.a = 0.0
	if action_points >= 0:
		_capsule_label.text = "行动点 %d" % action_points
		_capsule.position = center + Vector2(-110, 250)
		_capsule.modulate.a = 0.0
		_show(_capsule)

	_tween = create_tween().set_parallel(false)
	_tween.tween_property(_dim, "color:a", 0.97, _slow(0.22))
	_tween.tween_property(_big, "modulate:a", 1.0, _slow(0.28)).from(0.0) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_big, "rotation_degrees", 0.0, _slow(0.28))
	_tween.tween_callback(_shake.bind(_slow(0.12), 9.0))
	# 三格全换：月份数字一格一格滚、底板像撕日历翻一下、旬从右边回卷、时段淡过去。
	_tween.tween_callback(_roll_months.bind(month_cell, month_text))
	_tween.tween_callback(_flip_cell.bind(month_cell))
	_tween.tween_callback(_roll_in_from_right.bind(xun_cell, xun_text))
	_tween.tween_callback(_fade_swap_cell.bind(band_cell, band_text))
	_tween.tween_callback(_emit_band.bind(band_text))
	_tween.tween_property(_sub, "modulate:a", 1.0, _slow(0.2)).from(0.0)
	_tween.tween_callback(_stamp_paws.bind(0.6, 0.9))
	if action_points >= 0:
		_tween.tween_property(_capsule, "modulate:a", 1.0, _slow(0.12)).from(0.0) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 停留那一拍也要跟着放慢：玩家是在这一瞬读"第几月·哪一旬·白天还是夜"的。
	_tween.tween_interval(_slow(0.40) if quality == QUALITY_FULL else _slow(0.20))
	_tween.tween_callback(_fly_layers_out.bind(_slow(0.22)))
	_tween.tween_property(_big, "modulate:a", 0.0, _slow(0.18))
	_tween.parallel().tween_property(_sub, "modulate:a", 0.0, _slow(0.18))
	_tween.parallel().tween_property(_dim, "color:a", 0.0, _slow(0.22))
	_tween.parallel().tween_property(_bar, "color:a", 0.0, _slow(0.22))
	for paw in _paws:
		_tween.parallel().tween_property(paw, "modulate:a", 0.0, 0.22)
	_tween.parallel().tween_property(_capsule, "modulate:a", 0.0, 0.22)
	# 正常播完也走一次落字：_cell_swaps 里那三格与滚字结果一致，顺手清空，
	# 免得留到下一次过场去。
	_tween.tween_callback(_commit_cells)
	_tween.tween_callback(_end)


## 昼夜：不遮全屏，只在左上角那一格内部刷一道光带，字在光带后面换掉。
func play_daylight(cell: Label, band_text: String) -> void:
	if cell == null:
		finished.emit("daylight")
		return
	if quality == QUALITY_OFF:
		_set_cell_text(cell, band_text)
		band_lights.emit(band_text)
		finished.emit("daylight")
		return
	_started_msec = Time.get_ticks_msec()
	_playing = true
	_tier = "daylight"
	_cell_swaps = []
	_pending_band = ""
	_queue_cell_swap(cell, band_text)
	var rect := cell.get_global_rect()
	_show(_sweep)
	_sweep.size = Vector2(46, rect.size.y + 70)
	_sweep.pivot_offset = _sweep.size * 0.5
	_sweep.position = Vector2(rect.position.x - 60, rect.position.y - rect.size.y * 0.5)
	_sweep.color = Color("ffe9b0", 0.0)
	var travel := rect.size.x + 120.0
	var width := _slow(0.35 if quality == QUALITY_FULL else 0.26)
	_tween = create_tween().set_parallel(false)
	_tween.tween_property(_sweep, "color:a", 0.92, width * 0.22)
	_tween.tween_property(_sweep, "position:x", rect.position.x - 60.0 + travel, width * 0.66) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_commit_cells)
	_tween.tween_property(_sweep, "color:a", 0.0, width * 0.30)
	_tween.tween_callback(_end)
	band_lights.emit(band_text)


## 同段内的硬切：0.25 秒压暗一闪，不出字，也不锁操作。
func play_hard_cut() -> void:
	if quality == QUALITY_OFF:
		finished.emit("hard")
		return
	_started_msec = Time.get_ticks_msec()
	_playing = true
	_tier = "hard"
	_cell_swaps = []
	_pending_band = ""
	_show(_dim)
	_dim.color = Color(DIM_INK, 0.0)
	_tween = create_tween().set_parallel(false)
	_tween.tween_property(_dim, "color:a", 0.82, 0.09)
	_tween.tween_property(_dim, "color:a", 0.0, 0.16)
	_tween.tween_callback(_end)


## 玩家点一下：立刻落定，字全部写到位。第一次进入某个月的旬卡不给跳。
func request_skip() -> void:
	if not _playing or not _allow_skip:
		return
	_skip_requested = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_settle_card()
	_commit_cells()
	_end()


func _input(event: InputEvent) -> void:
	if not _playing or not _allow_skip:
		return
	if event is InputEventMouseButton and event.pressed:
		request_skip()
	elif event is InputEventScreenTouch and event.pressed:
		request_skip()


func _begin(tier: String, allow_skip: bool) -> void:
	_started_msec = Time.get_ticks_msec()
	_playing = true
	_tier = tier
	_allow_skip = allow_skip
	_skip_requested = false
	_cell_swaps = []
	_pending_band = ""
	_hide_all()
	# 斜杠的透明度会留在上一次的值上，这里先归零，否则非斜杠档会露出一条边。
	_bar.color = Color(BAR_BRICK, 0.0)
	_show(_dim)
	_show(_bar)
	_show(_big)
	_show(_sub)


func _end() -> void:
	if not _playing:
		return
	if OS.get_environment("V12M_WIPE_TIME") != "" and _started_msec > 0:
		print("[wipe] %s = %.2f 秒" % [_tier, float(Time.get_ticks_msec() - _started_msec) / 1000.0])
	_playing = false
	_allow_skip = false
	_hide_all()
	_root.position = Vector2.ZERO
	var tier := _tier
	_tier = ""
	finished.emit(tier)


func _settle_card() -> void:
	_big.modulate.a = 1.0
	_sub.modulate.a = 1.0
	_dim.color = Color(DIM_INK, 0.96)
	_root.position = Vector2.ZERO


## 跨旬卡的通用编排：旧字甩出 → 新字砸入 → 小字与爪印 → 停留 → 淡出。
## 给了 gap_text 时改成两拍：先把「过了多久」静静亮一下，再让新旬字进来
## （不甩色条、不砸字——这一档说的时间跨度最大，动作反而要最轻）。
func _sweep_card(old_text: String, new_text: String, sub_text: String, action_points: int, out_dir: Vector2, in_dir: Vector2, bar_color: Color, dim_alpha: float, total: float, gap_text := "") -> void:
	var center := _viewport_size() * 0.5
	var shrink := total / 1.4
	var has_gap := not gap_text.is_empty()
	_apply_skin()
	_show(_big)
	if has_gap:
		_big.text = gap_text
		_center_on(_big, center, 104, 30)
		_big.modulate.a = 0.0
	else:
		_big.text = old_text
		_center_on(_big, center, 168, 70)
		_big.modulate.a = 1.0
	_big.pivot_offset = _big.size * 0.5
	_big.rotation_degrees = 0.0
	_show(_sub)
	_sub.text = sub_text
	_center_on(_sub, center + Vector2(0, 130), 64)
	_sub.modulate.a = 0.0
	_show(_bar)
	_bar.color = Color(bar_color, 0.0)
	if action_points >= 0:
		_capsule_label.text = "行动点 %d" % action_points
		_capsule.position = _viewport_size() - Vector2(300, 190)
		_capsule.scale = Vector2.ONE
		_capsule.modulate.a = 0.0
		_show(_capsule)
	_tween = create_tween().set_parallel(false)
	if has_gap:
		# 第一拍：「两周后」在压暗里淡入，停够读字的时间，再淡出留给新旬字。
		_tween.tween_property(_dim, "color:a", dim_alpha if style == 0 else 0.97, _slow(0.45))
		_tween.parallel().tween_property(_big, "modulate:a", 1.0, _slow(0.35)).from(0.0)
		_tween.tween_interval(_slow(0.5))
		_tween.tween_property(_big, "modulate:a", 0.0, _slow(0.25))
	else:
		_tween.tween_property(_dim, "color:a", dim_alpha if style == 0 else 0.97, 0.18 * shrink)
		if style == 0:
			_tween.tween_callback(_sweep_bar.bind(bar_color, 0.2 * shrink))
		else:
			_tween.tween_callback(_fly_layers_in.bind(0.22 * shrink))
		_tween.tween_property(_big, "position", _big.position + out_dir * 1400.0, 0.17 * shrink) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_tween.parallel().tween_property(_big, "rotation_degrees", -16.0 if out_dir.x > 0 else 16.0, 0.17 * shrink)
		_tween.parallel().tween_property(_big, "modulate:a", 0.0, 0.17 * shrink)
	_tween.tween_callback(_land_new_text.bind(new_text, in_dir, shrink))
	_tween.tween_property(_sub, "modulate:a", 1.0, 0.2 * shrink).from(0.0)
	_tween.tween_callback(_stamp_paws.bind(0.6, 0.9))
	if action_points >= 0:
		_tween.tween_property(_capsule, "modulate:a", 1.0, 0.12).from(0.0) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.45 * shrink)
	_tween.tween_callback(_commit_cells)
	_tween.tween_callback(_fly_layers_out.bind(0.2 * shrink))
	_tween.tween_property(_big, "modulate:a", 0.0, 0.18 * shrink)
	_tween.parallel().tween_property(_sub, "modulate:a", 0.0, 0.18 * shrink)
	_tween.parallel().tween_property(_dim, "color:a", 0.0, 0.2 * shrink)
	_tween.parallel().tween_property(_bar, "color:a", 0.0, 0.2 * shrink)
	_tween.parallel().tween_property(_capsule, "modulate:a", 0.0, 0.2 * shrink)
	for paw in _paws:
		_tween.parallel().tween_property(paw, "modulate:a", 0.0, 0.2 * shrink)
	_tween.tween_callback(_end)


func _land_new_text(new_text: String, in_dir: Vector2, shrink: float) -> void:
	var center := _viewport_size() * 0.5
	_big.text = new_text
	_center_on(_big, center, 168, 70)
	_big.pivot_offset = _big.size * 0.5
	_big.rotation_degrees = 8.0 if in_dir.x < 0 else -8.0
	_big.modulate.a = 0.0
	var target := _big.position
	_big.position = target + in_dir * 900.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_big, "position", target, 0.26 * shrink) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_big, "modulate:a", 1.0, 0.12 * shrink)
	tween.tween_property(_big, "rotation_degrees", 0.0, 0.26 * shrink)
	# 落定那一下画面跟着震，是「砸进来」而不是「淡进来」的关键。
	_shake(0.08 * shrink, 7.0)


## 当前皮肤：字色、描边、压暗底色、色块配色都从这里取。
func _skin() -> Dictionary:
	return SKINS[clampi(style, 0, SKINS.size() - 1)]


## 皮肤只作用在过场这一秒多：回到小镇又是原来那套暖色，不改游戏本体画风。
func _apply_skin() -> void:
	var skin := _skin()
	_big.add_theme_color_override("font_color", skin["ink"])
	_big.add_theme_constant_override("outline_size", int(skin["outline"]))
	_sub.add_theme_color_override("font_color", Color(skin["ink"], 0.85))
	_dim.color = Color(skin["dim"], 0.0)


## 三层斜切色块从屏外撞进来，字跟着一起到位——这是"夹着字飞"而不是"字压在杠上"。
func _fly_layers_in(duration: float) -> void:
	if style == 0:
		return
	var skin := _skin()
	var bars: Array = skin["bars"]
	var screen := _viewport_size()
	var widths := [300.0, 150.0, 520.0]
	for index in _blocks.size():
		var block := _blocks[index]
		var width := float(widths[index])
		block.size = Vector2(width, screen.y * 2.2)
		block.pivot_offset = block.size * 0.5
		block.rotation_degrees = -14.0
		block.color = Color(bars[index % bars.size()], 0.92 if index == 2 else 0.97)
		var target := Vector2(screen.x * 0.5 + (float(index) - 1.0) * 260.0 - width * 0.5, -screen.y * 0.6)
		block.position = target - Vector2(screen.x, 0)
		block.visible = true
		var tween := create_tween()
		tween.tween_property(block, "position", target, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_halftone.visible = true
	var fade := create_tween()
	fade.tween_property(_halftone, "modulate:a", 0.16 if style == 1 else 0.22, duration)


func _fly_layers_out(duration: float) -> void:
	if style == 0:
		return
	var screen := _viewport_size()
	for block in _blocks:
		var tween := create_tween()
		tween.tween_property(block, "position:x", block.position.x + screen.x * 1.2, duration) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	var fade := create_tween()
	fade.tween_property(_halftone, "modulate:a", 0.0, duration)


## 网点压印：程序生成一张 12×12 圆点图平铺，0 新美术。
func _make_dots_texture() -> ImageTexture:
	var side := 12
	var img := Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for y in side:
		for x in side:
			var dx := float(x) - float(side) * 0.5 + 0.5
			var dy := float(y) - float(side) * 0.5 + 0.5
			if dx * dx + dy * dy <= 8.0:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


func _sweep_bar(color: Color, duration: float) -> void:
	var size := _viewport_size()
	_bar.color = Color(color, 0.92)
	_bar.size = Vector2(220, size.y * 2.2)
	_bar.pivot_offset = _bar.size * 0.5
	_bar.rotation_degrees = -14.0
	var start := Vector2(-_bar.size.x - 260, -size.y * 0.6)
	var finish := Vector2(size.x + 60, -size.y * 0.6)
	_bar.position = start
	var tween := create_tween()
	tween.tween_property(_bar, "position", finish, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _stamp_paws(scale_a: float, scale_b: float) -> void:
	var anchor: Vector2 = _big.get_global_rect().end - Vector2(40, 10)
	var index := 0
	for paw in _paws:
		var factor := scale_a if index == 0 else scale_b
		paw.size = Vector2(86, 86) * factor
		paw.position = anchor + Vector2(index * 54.0, index * 30.0 - 20.0)
		paw.scale = Vector2.ONE
		paw.modulate.a = 0.0
		_show(paw)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(paw, "modulate:a", 1.0, _slow(0.1))
		tween.tween_property(paw, "scale", Vector2.ONE, _slow(0.14)).from(Vector2(1.5, 1.5)) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		index += 1


func _shake(duration: float, strength: float) -> void:
	var tween := create_tween()
	tween.set_parallel(false)
	var steps := 4
	for step in steps:
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(_root, "position", offset, duration / float(steps) * 0.5)
	tween.tween_property(_root, "position", Vector2.ZERO, duration / float(steps) * 0.5)


## 底板像撕日历那样翻一下：宽度压到几乎为零，再弹回来。
func _flip_cell(cell: Label) -> void:
	var banner := cell.get_parent()
	if banner == null:
		return
	banner.pivot_offset = Vector2(0, banner.size.y * 0.5)
	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(banner, "scale", Vector2(0.06, 1.0), _slow(0.16)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(banner, "rotation_degrees", -3.0, _slow(0.16))
	tween.tween_property(banner, "scale", Vector2.ONE, _slow(0.24)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(banner, "rotation_degrees", 0.0, _slow(0.24))


const _MONTH_DIGITS := ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]


## 月份数字一格一格滚过去，不是硬换成下一个月。
func _roll_months(cell: Label, target_text: String) -> void:
	if cell == null:
		return
	var digits := target_text.split("")
	var slot := -1
	for index in digits.size():
		if _MONTH_DIGITS.has(digits[index]):
			slot = index
	if slot < 0:
		cell.text = target_text
		return
	var target_index := _MONTH_DIGITS.find(digits[slot])
	var tween := create_tween()
	# 往前倒三格再落到目标，读起来是「翻过去」而不是「换一张」。
	for step in range(3, 0, -1):
		var probe := digits.duplicate()
		probe[slot] = _MONTH_DIGITS[clampi(target_index - step, 0, _MONTH_DIGITS.size() - 1)]
		var frame_text := "".join(probe)
		tween.tween_callback(func(): cell.text = frame_text)
		tween.tween_interval(_slow(0.06))
	tween.tween_callback(func(): cell.text = target_text)


## 旬从「下旬」倒回「上旬」：从右边滑回来，暗示重新计时。
func _roll_in_from_right(cell: Label, text: String) -> void:
	if cell == null:
		return
	var home := cell.position
	cell.position = home + Vector2(220, 0)
	cell.modulate.a = 0.0
	cell.text = text
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cell, "position", home, _slow(0.24)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(cell, "modulate:a", 1.0, _slow(0.16))


func _fade_swap_cell(cell: Label, text: String) -> void:
	if cell == null:
		return
	var tween := create_tween()
	tween.tween_property(cell, "modulate:a", 0.0, _slow(0.14))
	tween.tween_callback(func(): cell.text = text)
	tween.tween_property(cell, "modulate:a", 1.0, _slow(0.3))


func _queue_cell_swap(cell: Label, text: String) -> void:
	if cell != null:
		_cell_swaps.append([cell, text])


func _commit_cells() -> void:
	for entry in _cell_swaps:
		_set_cell_text(entry[0], entry[1])
	_cell_swaps = []
	# 跨旬卡顺带跨了昼夜：字落定的同一帧把灯换掉，点跳过也走这条路。
	if not _pending_band.is_empty():
		var band := _pending_band
		_pending_band = ""
		_emit_band(band)


func _set_cell_text(cell: Label, text: String) -> void:
	if cell == null or text.is_empty():
		return
	cell.text = text


func _emit_band(band_text: String) -> void:
	if band_text != "":
		band_lights.emit(band_text)


func _quality_time(full_seconds: float) -> float:
	match quality:
		QUALITY_OFF:
			return 0.15
		QUALITY_SHORT:
			return full_seconds * 0.85
		_:
			return full_seconds


## 速度旋钮：所有写死的秒数都过这里一遍，调 TIME_SCALE 一个数就整体变快变慢。
func _slow(seconds: float) -> float:
	return seconds * TIME_SCALE


func _place(label: Label, at: Vector2, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.position = at
	label.reset_size()


## 按文字实际宽度居中摆放：reset_size 之后才有真实宽度，先摆会偏。
func _center_on(label: Label, center: Vector2, font_size: int, rise: float = 0.0) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.reset_size()
	label.position = center - label.size * 0.5 - Vector2(0, rise)


func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _make_label(font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("23170f"))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	return label


func _show(node: CanvasItem) -> void:
	node.visible = true


func _hide_all() -> void:
	_dim.visible = false
	_bar.visible = false
	for block in _blocks:
		block.visible = false
	_halftone.visible = false
	_big.visible = false
	_sub.visible = false
	_capsule.visible = false
	_sweep.visible = false
	for paw in _paws:
		paw.visible = false
