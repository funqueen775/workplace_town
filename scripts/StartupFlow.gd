extends Control

# 开场漫画 -> 标题页 -> 三页小镇导览 -> Main.tscn。
const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const INTRO_BG := preload("res://assets/town/workplace_town_no_labels.png")
const ENTRY_COVER := preload("res://assets/ui/startup/entry_cover.png")
const COVER_START := preload("res://assets/开始游戏页面/按钮-开始游戏.png")
const COVER_SETTINGS := preload("res://assets/开始游戏页面/按钮-设置.png")
const COVER_EXIT := preload("res://assets/开始游戏页面/按钮-退出游戏.png")
## 三个按钮图四周各有上百像素透明留白，整张缩放会把按钮压扁。
## 用 AtlasTexture 只裁内容区，再按交付稿坐标落到封面上（坐标取自 557b538 版标题页）。
const COVER_START_CROP := Rect2(145, 70, 1880, 550)
const COVER_SETTINGS_CROP := Rect2(190, 130, 1800, 470)
const COVER_EXIT_CROP := Rect2(166, 118, 1840, 474)
const B_AREA_ART := preload("res://assets/场景内部图/云栖科技丘.png")
const WANG_GE_PORTRAIT := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/王哥头像.png")
const INTRO_DIALOG_BG := preload("res://assets/对话框/角色对话框_空白.png")
const INTRO_BUTTON_PRIMARY := preload("res://assets/ui/rework_v1/task_book/20_推进按钮底板.png")
const INTRO_BUTTON_SECONDARY := preload("res://assets/ui/rework_v1/task_book/18_追踪按钮底板.png")
const OPENING_COMIC_SCENE := preload("res://opening_comic/OpeningComic.tscn")
const PROFILE_PATH := "user://workplace_town_profile.json"
# Batch 3（2026-09-17）：「我的报告」接通 —— 面板按需实例化，报告只在服务端算。
const REPORT_PANEL := preload("res://scripts/ReportPanel.gd")
const SETTINGS_PANEL := preload("res://scripts/SettingsPanel.gd")
const DIRECT_AVATAR_FRAMES := {
	"avatar_player": "res://assets/characters/direct_frames/player/01.png",
	"avatar_xiaoye": "res://assets/characters/direct_frames/xiaoye/01.png",
	"avatar_yueya": "res://assets/characters/direct_frames/yueya/01.png",
	"avatar_mili": "res://assets/characters/direct_frames/mili/01.png",
	"avatar_amai": "res://assets/characters/direct_frames/amai/01.png",
}

const PAPER := Color("f6e6bd")
const INK := Color("4a2b1a")
const WOOD := Color("5b321f")
const BRICK := Color("b95035")
const BRICK_HOVER := Color("cf6247")
const BRICK_PRESSED := Color("8f3a26")
const EDGE := Color("2e1a12")
const CREAM_TXT := Color("fff4d5")
const SUB_TXT := Color("8a4a2e")
const CHIP_BG := Color("f0d9a8")
const CHIP_BG_HOVER := Color("ffeec4")
const SECOND_BG := Color("f1ddb0")
const SECOND_BG_HOVER := Color("fff0cc")
const SECOND_EDGE := Color("9a6a42")
const EXIT_BG := Color("70452c")
const EXIT_BG_HOVER := Color("88593a")
const EXIT_TXT := Color("f3dfbe")

## 导览三页共用的内容区（相对 frame）：切页不跳版靠它
## 高度 580→600，并把整页上移 12px：入职页的故事 + 引语和「怎么玩」的四行
## 都需要更多上下呼吸位，不能贴着卡片底边。
const CONTENT_RECT := Rect2(94, 238, 1512, 600)

## 引言三页（开发文档 11.14）。
const PAGES := [
	{"tab":"入职", "kicker":"入职 · B 区 云栖科技丘", "title":"换一种熊生，先试一年",
	 "body":"旧工作像一摞改不完的文件。你看到「职场小镇」的招工启事，点了申请——想试试换一种活法。",
	 "body2":"接下来的十二个月，你在 B 区做真实项目：两次评估，第 6 个月转正，第 12 个月晋升。",
	 "quote":"「来这儿不是躲清闲，是看看你还能做成什么。」", "quote_by":"王哥 · 你的导师",
	 "footer":"B 区 · 云栖科技丘 · 一年后见", "art":B_AREA_ART},
	{"tab":"怎么玩", "kicker":"操作", "title":"先学会走路，再学会做事",
	 "controls":true, "footer":"移动、交互、看地图——先把这四件事用顺"},
	{"tab":"每个月", "kicker":"每个月", "title":"主线必做，其余自选",
	 "body":"跟着左上角的目标走，主线不会错过。\n手机和手册不用先记，用到了自然会说。\n有行动点的月份，选一件事；不选也行。",
	 "footer":"月底自动存档，翻到下个月", "loop":true},
]

## 「怎么玩」页的四条操作。键盘和手机都写进去，别只写 PC。
const CONTROLS := [
	{"key":"移动", "text":"左下摇杆 / WASD / 方向键"},
	{"key":"互动", "text":"靠近后点右下按钮，或按 E —— 交谈 · 进门 · 开始剧情"},
	{"key":"返回", "text":"在建筑里点「返回小镇」，或按 Q"},
	{"key":"地图", "text":"滚轮 / ± / 双指捏合缩放，按住拖动平移"},
]

## 第 2 页底部的四步月循环；图标全部取自现有 HUD 素材。
const LOOP_STEPS := [
	{"icon": preload("res://assets/ui/rework_v1/hud/components/08_任务_定位图标.png"), "label": "主线"},
	{"icon": preload("res://assets/ui/rework_v1/hud/reference_full_v1/06_手机按钮.png"), "label": "手机 · 手册"},
	{"icon": preload("res://assets/ui/rework_v1/hud/components/05_蜂蜜罐_满.png"), "label": "自由安排"},
	{"icon": preload("res://assets/ui/rework_v1/hud/components/12_日历_固定图标按钮.png"), "label": "月末"},
]
var _mode := "title"
var _page := 0
var _fonts: Dictionary = {}
var _intro_started_ms := 0
var _report_panel: CanvasLayer
var _settings_panel: CanvasLayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 跳月看片：命令行带了 --v12m-month=N 就跳过开场漫画、标题和引言，直接进镇，
	# 由城镇在开局那一拍跳到点名的那个月。玩家包里不会带这个参数。
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--v12m-month="):
			# 换场景得等这一帧把子节点加完再做：直接在 _ready 里切，Godot 会拒绝
			# remove_child，结果标题还挂着、镇子也进不去（点「开始游戏」没反应）。
			_enter_town.call_deferred()
			return
	_show_login_screen()


func _show_opening_comic() -> void:
	for child in get_children():
		child.queue_free()
		if child is CanvasItem:
			child.visible = false
	var comic := OPENING_COMIC_SCENE.instantiate()
	comic.comic_finished.connect(_start_intro)
	add_child(comic)


func _start_game_flow() -> void:
	_mode = "comic"
	_show_opening_comic()


func _show_login_screen() -> void:
	_mode = "title"
	_rebuild()

func _rebuild() -> void:
	for child in get_children(): child.queue_free()
	_report_panel = null
	_settings_panel = null
	if _mode == "title":
		_title_screen()
	else:
		_background(INTRO_BG, 0.60)
		if _mode == "avatar":
			_avatar_screen()
		else:
			_intro_screen()

func _background(texture: Texture2D, shade_alpha: float) -> void:
	var bg := TextureRect.new()
	bg.texture = texture
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.09, 0.12, shade_alpha)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

# ------------------------------------------------------------------ 标题屏

func _title_screen() -> void:
	var paper := ColorRect.new()
	paper.color = Color("fbe7cf")
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)

	var stage := Control.new()
	stage.name = "TitleStage"
	add_child(stage)
	var layout := func() -> void:
		var factor := maxf(size.x / 1672.0, size.y / 941.0)
		stage.size = Vector2(1672, 941)
		stage.scale = Vector2.ONE * factor
		stage.position = (size - stage.size * factor) * 0.5
	resized.connect(layout)
	stage.tree_exiting.connect(func() -> void: resized.disconnect(layout))
	layout.call()

	var cover := TextureRect.new()
	cover.texture = ENTRY_COVER
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_SCALE
	cover.size = Vector2(1672, 941)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(cover)

	_cover_button(stage, "StartGame", COVER_START, COVER_START_CROP, Rect2(158, 481, 480, 133), _start_game_flow)
	_cover_button(stage, "Settings", COVER_SETTINGS, COVER_SETTINGS_CROP, Rect2(225, 627, 348, 74), _open_settings)
	_cover_button(stage, "ExitGame", COVER_EXIT, COVER_EXIT_CROP, Rect2(225, 716, 349, 71), _quit_game)


func _cover_button(parent: Control, node_name: String, source: Texture2D, crop: Rect2, rect: Rect2, action: Callable) -> void:
	var image := AtlasTexture.new()
	image.atlas = source
	image.region = crop
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = image
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(func() -> void:
		_animate_cover_button(button, rect.position + Vector2(0, -3), Vector2.ONE * 1.035, Color(1.09, 1.06, 1.02), 0.16))
	button.mouse_exited.connect(func() -> void:
		_animate_cover_button(button, rect.position, Vector2.ONE, Color.WHITE, 0.16))
	button.button_down.connect(func() -> void:
		_animate_cover_button(button, rect.position + Vector2(0, 2), Vector2.ONE * 0.96, Color(0.88, 0.84, 0.80), 0.07))
	button.button_up.connect(func() -> void:
		if button.is_hovered():
			_animate_cover_button(button, rect.position + Vector2(0, -3), Vector2.ONE * 1.035, Color(1.09, 1.06, 1.02), 0.12)
		else:
			_animate_cover_button(button, rect.position, Vector2.ONE, Color.WHITE, 0.12))
	button.pressed.connect(_activate_cover_button.bind(button, rect.position, action))
	parent.add_child(button)


## 悬停上浮 / 按下回弹（原交付稿的动效），用 tween 而不是直接改 modulate。
func _animate_cover_button(button: TextureButton, target_position: Vector2, target_scale: Vector2, tint: Color, duration: float) -> Tween:
	var previous: Tween = button.get_meta("motion_tween") as Tween if button.has_meta("motion_tween") else null
	if previous != null and previous.is_running():
		previous.kill()
	var motion := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.tween_property(button, "position", target_position, duration)
	motion.tween_property(button, "scale", target_scale, duration)
	motion.tween_property(button, "modulate", tint, duration)
	button.set_meta("motion_tween", motion)
	return motion


## 按下先播完回弹再执行动作，避免手指还按着画面就切走了。
func _activate_cover_button(button: TextureButton, rest_position: Vector2, action: Callable) -> void:
	button.disabled = true
	await _animate_cover_button(button, rest_position + Vector2(0, 2), Vector2.ONE * 0.96, Color(0.90, 0.86, 0.82), 0.10).finished
	if is_instance_valid(button):
		button.disabled = false
		action.call()

func _open_settings() -> void:
	if _settings_panel == null:
		_settings_panel = SETTINGS_PANEL.new()
		_settings_panel.name = "SettingsPanel"
		_settings_panel.quit_requested.connect(_quit_game)
		add_child(_settings_panel)
	_settings_panel.open()


## 打开「我的报告」面板（按需实例化，ReportPanel 自己管拉取与失败文案）。
func _open_report() -> void:
	if _report_panel == null:
		_report_panel = REPORT_PANEL.new()
		add_child(_report_panel)
	_report_panel.open()

# ------------------------------------------------------------------ 导览三页
# 【2026-09-15 排版重排】三个坑一起修掉，动这块之前先读完：
#  1. **属性顺序**：`Label.size` 必须写在 `autowrap_mode` **之后**；`TextureRect.size` 必须写在
#     `expand_mode` **之后**。反了的话，设 size 那一刻的最小尺寸还是"整行宽度 / 纹理原始尺寸"，
#     size 会被顶大、之后再也不会重算 —— 正文 620 实测变 838（压住右侧插图 104px）、插图 636×454
#     实测变 660×495（溢出木框），两个 bug 都是这个顺序错。
#  2. **正文不许写死高度**：Label 高度按行数自适应（行高 ≈ 1.5×字号）。写死 245 再垂直居中，
#     两行字就悬在框正中、上下各空一大块 —— 这就是"留白太多"的主因。
#  3. **`_label()` 默认垂直居中，只适合单行标题**，段落必须自己改回 TOP。

func _intro_screen() -> void:
	var frame := Panel.new()
	_layout_startup_frame(frame)
	frame.add_theme_stylebox_override("panel", _style(PAPER, WOOD, 8, 8))
	add_child(frame)

	# 顶栏：返回 / 标题 / 副标题
	var back := _intro_button("返回", "secondary")
	back.position = Vector2(36, 30)
	back.size = Vector2(140, 64)
	back.add_theme_font_size_override("font_size", 28)
	back.pressed.connect(_back)
	frame.add_child(back)

	var heading := _label("认识职场小镇", 44, INK)
	heading.position = Vector2(300, 26)
	heading.size = Vector2(1100, 58)
	frame.add_child(heading)

	var sub := _label("先了解这里怎么过，再决定怎么开始", 26, Color("7a5533"))
	sub.position = Vector2(300, 88)
	sub.size = Vector2(1100, 36)
	frame.add_child(sub)

	# 页签：三页居中排一行
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(140, 142)
	tabs.size = Vector2(1400, 76)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 16)
	frame.add_child(tabs)
	for index in PAGES.size():
		var tab := _intro_button(String(PAGES[index]["tab"]), "tab_on" if index == _page else "tab")
		tab.custom_minimum_size = Vector2(240, 72)
		tab.add_theme_font_size_override("font_size", 27)
		tab.pressed.connect(func(): _go_page(index))
		tabs.add_child(tab)

	var page: Dictionary = PAGES[_page]
	_text_content(frame, page)
	_footer(frame, page)

func _text_content(frame: Panel, page: Dictionary) -> void:
	var card := _intro_dialog_panel()
	card.position = CONTENT_RECT.position
	card.size = CONTENT_RECT.size
	frame.add_child(card)

	var has_art := page.has("art")
	var column_w := 760.0 if has_art else CONTENT_RECT.size.x - 290.0
	if has_art:
		var art_box := Control.new()
		art_box.position = Vector2(CONTENT_RECT.size.x - 64.0 - 540.0, (CONTENT_RECT.size.y - 405.0) * 0.5)
		art_box.size = Vector2(540.0, 405.0)
		card.add_child(art_box)

		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.texture = page["art"] as Texture2D
		art.position = Vector2(12, 12)
		art.size = art_box.size - Vector2(24, 24)
		art_box.add_child(art)

	var kicker := _label(str(page["kicker"]), 30, BRICK)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# 卡片左上角自带一条橙色短杠（在 9-patch 被拉伸后的 y≈101 中线上），
	# 文字要跟它同一条水平中线，不能按标题字号往上顶。
	kicker.position = Vector2(290, 81)
	kicker.size = Vector2(column_w - 145.0, 40)
	card.add_child(kicker)

	var title := _label(str(page["title"]), 54, INK, 0.0, 0.30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector2(145, 116)
	title.size = Vector2(column_w, 76)
	card.add_child(title)

	if page.get("controls", false):
		_controls_content(card)
		return

	var body := _label(str(page["body"]), 30, Color("634330"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 12)
	body.position = Vector2(145, 210)
	body.size = Vector2(column_w, 0)
	card.add_child(body)
	var body_bottom := body.position.y + body.size.y

	if page.has("body2"):
		var body2 := _label(str(page["body2"]), 30, Color("634330"))
		body2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		body2.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		body2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body2.add_theme_constant_override("line_spacing", 12)
		body2.position = Vector2(145, body_bottom + 16)
		body2.size = Vector2(column_w, 0)
		card.add_child(body2)
		body_bottom = body2.position.y + body2.size.y

	if page.has("quote"):
		_story_quote(card, page, Vector2(145, body_bottom + 30), column_w)

	if page.get("loop", false):
		_loop_strip(card, Vector2(145, body_bottom + 34), column_w)


## 「入职」页底部的人物引语：头像 + 一句话，比纯规则更有故事味。
func _story_quote(parent: Control, page: Dictionary, at: Vector2, width: float) -> Control:
	var strip := Panel.new()
	strip.position = at
	strip.size = Vector2(width, 100)
	strip.add_theme_stylebox_override("panel", _style(Color("f8e8c6"), Color("b98a55"), 2, 10))
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(strip)

	var portrait := TextureRect.new()
	portrait.texture = WANG_GE_PORTRAIT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.position = Vector2(14, 14)
	portrait.size = Vector2(72, 72)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(portrait)

	var quote := _label(str(page["quote"]), 26, Color("5a3a24"))
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	quote.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	quote.position = Vector2(104, 14)
	quote.size = Vector2(width - 124.0, 40)
	strip.add_child(quote)

	var byline := _label(str(page.get("quote_by", "")), 20, Color("8a4a2e"))
	byline.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	byline.position = Vector2(104, 58)
	byline.size = Vector2(width - 124.0, 30)
	strip.add_child(byline)
	return strip


## 「怎么玩」页：四条操作，一条一行，键位和说明分开。
func _controls_content(card: Control) -> void:
	var intro := _label("小镇没有菜单迷宫：会走、会点、会看地图，就能开始。", 30, Color("634330"))
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	intro.position = Vector2(145, 208)
	intro.size = Vector2(1222, 46)
	card.add_child(intro)

	var rows := VBoxContainer.new()
	rows.position = Vector2(145, 274)
	rows.size = Vector2(1222, 286)
	rows.add_theme_constant_override("separation", 10)
	card.add_child(rows)
	for control in CONTROLS:
		var row := Panel.new()
		row.custom_minimum_size = Vector2(1222, 64)
		row.add_theme_stylebox_override("panel", _style(Color("fbf0d6"), Color(0.66, 0.48, 0.30, 0.55), 2, 8))
		rows.add_child(row)

		var chip := Panel.new()
		chip.position = Vector2(14, 8)
		chip.size = Vector2(96, 48)
		chip.add_theme_stylebox_override("panel", _style(Color("e9cf98"), Color("7a4a2b"), 2, 8))
		row.add_child(chip)

		var key := _label(str(control["key"]), 24, INK, 0.0, 0.18)
		key.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		chip.add_child(key)

		var text := _label(str(control["text"]), 27, Color("5a3a24"))
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.position = Vector2(130, 0)
		text.size = Vector2(1070, 64)
		row.add_child(text)


func _loop_strip(parent: Control, at: Vector2, width: float) -> Control:
	var strip := Panel.new()
	strip.position = at
	strip.size = Vector2(width, 154)
	strip.add_theme_stylebox_override("panel", _style(Color("efd9a9"), Color("a97a4d"), 2, 8, 3))
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(strip)

	var row := HBoxContainer.new()
	row.size = strip.size
	row.add_theme_constant_override("separation", 0)
	strip.add_child(row)

	var cell_w := width / float(LOOP_STEPS.size())
	for index in LOOP_STEPS.size():
		var step: Dictionary = LOOP_STEPS[index]
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(cell_w, 154)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cell)

		var icon := TextureRect.new()
		icon.texture = step["icon"] as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon.position = Vector2((cell_w - 72.0) * 0.5, 18)
		icon.size = Vector2(72, 72)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)

		var caption := _label(str(step["label"]), 30, INK, 0.0, 0.18)
		caption.position = Vector2(0, 96)
		caption.size = Vector2(cell_w, 48)
		cell.add_child(caption)

		if index > 0:
			var rule := ColorRect.new()
			rule.color = Color(0.42, 0.26, 0.13, 0.35)
			rule.position = Vector2(0, 40)
			rule.size = Vector2(2, 74)
			rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(rule)
	return strip

func _footer(frame: Panel, page: Dictionary) -> void:
	var footer := _label(str(page.get("footer", "")), 24, Color("7a5533"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	footer.position = Vector2(102, 852)
	footer.size = Vector2(1020, 48)
	frame.add_child(footer)

	var skip := _intro_button("跳过", "secondary")
	skip.position = Vector2(1285, 846)
	skip.size = Vector2(130, 64)
	skip.add_theme_font_size_override("font_size", 28)
	skip.pressed.connect(_skip_intro)
	frame.add_child(skip)

	var next := _intro_button("继续")
	next.position = Vector2(1425, 846)
	next.size = Vector2(220, 64)
	next.add_theme_font_size_override("font_size", 28)
	if _page < PAGES.size() - 1:
		next.pressed.connect(func(): _go_page(_page + 1))
	else:
		next.pressed.connect(_start_avatar_selection)
	frame.add_child(next)


func _skip_intro() -> void:
	var dwell := int(round(float(Time.get_ticks_msec() - _intro_started_ms) / 1000.0))
	var api := get_node_or_null("/root/ApiClient")
	if api != null:
		api.record_event("intro_skip", {"page": _page + 1, "pageCount": PAGES.size()}, dwell)
	_start_avatar_selection()

func _start_intro() -> void:
	_mode = "intro"
	_page = 0
	_intro_started_ms = Time.get_ticks_msec()
	_rebuild()

## 继续游戏：跳过导览直接进小镇，不重写 profile（保留上次开局留下的文件）。
## ⚠ 当前存档粒度只有「玩过没有」——真正的进度续玩（currentNodeId / 月份 / 精力落盘）
##   是方案 B 的活，别把这条当成已经能续上中途进度。
func _continue_game() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func _back() -> void: _mode = "title"; _rebuild()
func _go_page(index: int) -> void: _page = clampi(index, 0, PAGES.size() - 1); _rebuild()
func _placeholder() -> void: pass

## 真正退出程序。之前这里挂的是 _placeholder，按钮点下去毫无反应。
func _quit_game() -> void:
	get_tree().quit()

func _enter_town() -> void:
	WorldClock.reset_story()
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"sessionId":"local-" + str(Time.get_unix_time_from_system()), "avatarId":PlayerProfile.get_selected_avatar_id(), "contentVersion":"v1.2", "currentNodeId":"E01", "unlockedRegionIds":["A", "B", "C", "D", "E", "F", "G", "H"]}))
	get_tree().change_scene_to_file("res://Main.tscn")


func _start_avatar_selection() -> void:
	_mode = "avatar"
	_rebuild()


func _avatar_screen() -> void:
	var frame := Panel.new()
	_layout_startup_frame(frame)
	frame.add_theme_stylebox_override("panel", _style(PAPER, WOOD, 8, 8))
	add_child(frame)

	var back := _button("返回", "secondary")
	back.position = Vector2(36, 34)
	back.size = Vector2(132, 60)
	back.pressed.connect(func() -> void: _mode = "intro"; _page = PAGES.size() - 1; _rebuild())
	frame.add_child(back)

	var kicker := _label("准备入职", 30, BRICK)
	kicker.position = Vector2(250, 48)
	kicker.size = Vector2(1200, 38)
	frame.add_child(kicker)
	var heading := _label("选择你的形象", 44, INK, 0.0, 0.30)
	heading.position = Vector2(250, 88)
	heading.size = Vector2(1200, 66)
	frame.add_child(heading)
	var description := _label("进入小镇后，地图、室内和剧情都会使用这套形象。", 19, Color("7a5533"))
	description.position = Vector2(250, 154)
	description.size = Vector2(1200, 32)
	frame.add_child(description)

	var cards := HBoxContainer.new()
	cards.position = Vector2(115, 238)
	cards.size = Vector2(1470, 410)
	cards.add_theme_constant_override("separation", 18)
	frame.add_child(cards)
	for avatar_value in PlayerProfile.AVATARS:
		var avatar := avatar_value as Dictionary
		var avatar_id := String(avatar.get("id", ""))
		var card := Button.new()
		card.custom_minimum_size = Vector2(279, 410)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_NONE
		card.add_theme_stylebox_override("normal", _style(Color("fff4d8"), BRICK if avatar_id == PlayerProfile.get_selected_avatar_id() else Color("865139"), 4 if avatar_id == PlayerProfile.get_selected_avatar_id() else 2, 6, 4))
		card.add_theme_stylebox_override("hover", _style(Color("fff9e9"), BRICK, 4, 6, 5))
		card.add_theme_stylebox_override("pressed", _style(Color("ead39f"), BRICK, 4, 6, 0))
		card.pressed.connect(_select_avatar.bind(avatar_id))
		cards.add_child(card)

		var portrait := TextureRect.new()
		portrait.texture = load(String(DIRECT_AVATAR_FRAMES.get(avatar_id, ""))) as Texture2D
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.position = Vector2(15, 8)
		portrait.size = Vector2(250, 250)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)

		var name := _label(String(avatar.get("name", "")), 28, INK, 0.0, 0.22)
		name.position = Vector2(0, 284)
		name.size = Vector2(279, 42)
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name)
		var selected := _label("当前选择" if avatar_id == PlayerProfile.get_selected_avatar_id() else "点击选择", 17, BRICK if avatar_id == PlayerProfile.get_selected_avatar_id() else Color("7a5533"))
		selected.position = Vector2(0, 332)
		selected.size = Vector2(279, 28)
		selected.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(selected)

	var confirm := _button("带着这个形象进入小镇", "primary")
	confirm.position = Vector2(625, 770)
	confirm.size = Vector2(450, 68)
	confirm.pressed.connect(_enter_town)
	frame.add_child(confirm)


func _layout_startup_frame(frame: Panel) -> void:
	frame.size = Vector2(1700, 968)
	var layout := func() -> void:
		var factor: float = minf((size.x - 32.0) / frame.size.x, (size.y - 32.0) / frame.size.y)
		frame.scale = Vector2.ONE * factor
		frame.position = (size - frame.size * factor) * 0.5
	resized.connect(layout)
	frame.tree_exiting.connect(func() -> void: resized.disconnect(layout))
	layout.call()


func _select_avatar(avatar_id: String) -> void:
	if PlayerProfile.set_selected_avatar_id(avatar_id):
		_rebuild()

# ------------------------------------------------------------------ 零件

## 伪粗体：工程里只有 Noto Sans CJK 的 Regular 一个字重，中文在小字号下偏虚，
## 用 FontVariation 的 embolden 补一点分量（不是换字体文件，是给同一份字体加变体）。
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
		# 描边颜色跟底色走（浅底深字用深描边），别一律白描边 —— 在米黄羊皮纸上会显脏
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
		"exit":
			button.custom_minimum_size = Vector2(0, 58)
			button.add_theme_font_size_override("font_size", 24)
			button.add_theme_color_override("font_color", EXIT_TXT)
			button.add_theme_color_override("font_hover_color", Color("fff1d8"))
			button.add_theme_stylebox_override("normal", _style(EXIT_BG, EDGE, 3, 6, 4))
			button.add_theme_stylebox_override("hover", _style(EXIT_BG_HOVER, EDGE, 3, 6, 5))
			button.add_theme_stylebox_override("pressed", _style(Color("5c3823"), EDGE, 3, 6, 0))
		"tab":
			# 导览页顶部页签：未选中
			button.custom_minimum_size = Vector2(0, 64)
			button.add_theme_font_size_override("font_size", 21)
			button.add_theme_color_override("font_color", Color("7a5533"))
			button.add_theme_color_override("font_hover_color", INK)
			button.add_theme_stylebox_override("normal", _style(Color("f8e9c6"), Color("865139"), 2, 5, 4))
			button.add_theme_stylebox_override("hover", _style(Color("fff6dc"), Color("865139"), 2, 5, 5))
			button.add_theme_stylebox_override("pressed", _style(Color("e6d3a4"), Color("865139"), 2, 5, 0))
		"tab_on":
			# 导览页顶部页签：选中（底色更深 + 边更粗）
			button.custom_minimum_size = Vector2(0, 64)
			button.add_theme_font_size_override("font_size", 21)
			button.add_theme_color_override("font_color", INK)
			button.add_theme_color_override("font_hover_color", INK)
			button.add_theme_stylebox_override("normal", _style(Color("e9cf98"), Color("7a4a2b"), 3, 5, 4))
			button.add_theme_stylebox_override("hover", _style(Color("f4e2b2"), Color("7a4a2b"), 3, 5, 5))
			button.add_theme_stylebox_override("pressed", _style(Color("dcc28a"), Color("7a4a2b"), 3, 5, 0))
		_:
			# chip：右上角那三个小方钮
			button.custom_minimum_size = Vector2(0, 52)
			button.add_theme_font_size_override("font_size", 22)
			button.add_theme_color_override("font_color", INK)
			button.add_theme_color_override("font_hover_color", INK)
			button.add_theme_stylebox_override("normal", _style(CHIP_BG, SECOND_EDGE, 3, 8, 4))
			button.add_theme_stylebox_override("hover", _style(CHIP_BG_HOVER, SECOND_EDGE, 3, 8, 5))
			button.add_theme_stylebox_override("pressed", _style(Color("dfc594"), SECOND_EDGE, 3, 8, 0))
	button.add_theme_stylebox_override("disabled", _style(Color(0.84, 0.78, 0.65), Color("a9977c"), 3, 6))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.4, 0.34))
	return button

## bevel：底边那层「厚度」（CSS 的 0 Npx 0）。用无模糊阴影偏移近似，比纯描边更有实体感。
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
