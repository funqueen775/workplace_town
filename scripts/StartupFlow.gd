extends Control

# 开场漫画 -> 标题页 -> 两道入职预演 -> 形象选择 -> Main.tscn。
const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const TITLE_BG := preload("res://assets/town/workplace_town_no_labels.png")
const LIN_ROOM := preload("res://assets/场景内部图/创意水巷.png")
const ZHOU_ROOM := preload("res://assets/场景内部图/树影图书馆.png")
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
const HOME_BG := preload("res://assets/town/workplace_town_no_labels.png")
const HOME_START := preload("res://assets/开始游戏页面/按钮-开始游戏.png")
const HOME_SETTINGS := preload("res://assets/开始游戏页面/按钮-设置.png")
const HOME_REPORT := preload("res://assets/开始游戏页面/按钮-我的报告.png")
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

const HOME_SIZE := Vector2(1672, 941)

## 开场选择只用于预演，不进入正式剧情和测评。
const PAGES := [
	{"title":"先问什么", "speaker":"小林", "role":"产品同事", "place":"销售部", "room":LIN_ROOM,
	 "portrait":LIN_PORTRAITS, "question":"客户刚发来新想法，但我们还不知道他最在意什么。你会先？",
	 "choices":["问清真正需求", "找同事估算", "做个草案给客户看"],
	 "replies":["好，我把客户叫回来，我们先问明白。", "我去约大家，先看看这事需要多少时间。", "可以，先让客户看到一个能讨论的东西。"],
	 "expressions":[3, 1, 2]},
	{"title":"从哪里开始", "speaker":"老周", "role":"资深同事", "place":"人事部", "room":ZHOU_ROOM,
	 "portrait":ZHOU_PORTRAITS, "question":"大家对同一件事有不同说法。复盘该从哪里开始？",
	 "choices":["先听各方说法", "先整理事实", "先提出自己的判断"],
	 "replies":["先听完，再看哪些地方说得不一样。", "有了事实，讨论才不会只剩立场。", "说说看。也别忘了听听别人的依据。"],
	 "expressions":[1, 0, 2]},
]

var _mode := "title"
var _page := 0
var _last_intro_page := 0
var _intro_answers := [-1, -1]
var _fonts: Dictionary = {}
var _report_panel: CanvasLayer
var _settings_panel: CanvasLayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_show_opening_comic()


func _show_opening_comic() -> void:
	var comic := OPENING_COMIC_SCENE.instantiate()
	comic.comic_finished.connect(_show_loading_transition)
	add_child(comic)


func _show_loading_transition() -> void:
	for child in get_children():
		child.queue_free()
	_mode = "title"
	_background()

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.position = Vector2(-190, -62)
	content.size = Vector2(380, 124)
	content.add_theme_constant_override("separation", 14)
	add_child(content)

	var title := _label("职 场 小 镇", 36, CREAM_TXT, 2.0, 0.22)
	title.custom_minimum_size.y = 52
	content.add_child(title)

	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(380, 10)
	progress.value = 0.0
	progress.add_theme_stylebox_override("background", _style(Color("2e1a12", 0.72), Color("fff1cc", 0.44), 1, 5))
	progress.add_theme_stylebox_override("fill", _style(Color("e8ba57"), Color("fff0bd"), 1, 5))
	content.add_child(progress)

	var hint := _label("正在加载", 17, Color("fff1d2", 0.78))
	hint.custom_minimum_size.y = 28
	content.add_child(hint)
	create_tween().tween_property(progress, "value", 100.0, 1.0)

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.15
	timer.timeout.connect(_show_login_screen)
	add_child(timer)
	timer.start()


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
		_background()
		if _mode == "avatar":
			_avatar_screen()
		else:
			_intro_screen()

func _background() -> void:
	var bg := TextureRect.new()
	bg.texture = TITLE_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.09, 0.12, 0.34 if _mode == "title" else 0.60)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

# ------------------------------------------------------------------ 标题屏

func _title_screen() -> void:
	var canvas := Control.new()
	canvas.name = "HomeCanvas"
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(canvas)
	var layout := func() -> void:
		var scale_factor: float = minf(size.x / HOME_SIZE.x, size.y / HOME_SIZE.y)
		canvas.size = HOME_SIZE
		canvas.scale = Vector2.ONE * scale_factor
		canvas.position = (size - HOME_SIZE * scale_factor) * 0.5
	resized.connect(layout)
	canvas.tree_exiting.connect(func() -> void: resized.disconnect(layout))
	layout.call()

	var bg := TextureRect.new()
	bg.texture = HOME_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = HOME_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	# 按交付效果图的坐标放置。AtlasTexture 裁掉素材四周的透明留白。
	_home_button(canvas, "StartGame", HOME_START, Rect2(145, 70, 1880, 550), Rect2(158, 481, 480, 133), _start_intro)
	_home_button(canvas, "Settings", HOME_SETTINGS, Rect2(190, 130, 1800, 470), Rect2(225, 627, 348, 74), _open_settings)
	_home_exit_button(canvas)
	_home_button(canvas, "MyReport", HOME_REPORT, Rect2(195, 105, 1800, 500), Rect2(1371, 52, 260, 73), _open_report)

func _home_exit_button(parent: Control) -> void:
	var image := AtlasTexture.new()
	image.atlas = INTRO_BUTTON_SECONDARY
	image.region = Rect2(202, 231, 1370, 440)
	var button := TextureButton.new()
	button.name = "ExitGame"
	button.texture_normal = image
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = Vector2(225, 715)
	button.size = Vector2(348, 74)
	button.pivot_offset = button.size * 0.5
	button.focus_mode = Control.FOCUS_NONE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.mouse_entered.connect(func() -> void:
		_animate_home_button(button, button.position + Vector2(0, -3), Vector2.ONE * 1.035, Color(1.09, 1.06, 1.02), 0.16))
	button.mouse_exited.connect(func() -> void:
		_animate_home_button(button, Vector2(225, 715), Vector2.ONE, Color.WHITE, 0.16))
	button.button_down.connect(func() -> void:
		_animate_home_button(button, Vector2(225, 717), Vector2.ONE * 0.96, Color(0.88, 0.84, 0.80), 0.07))
	button.button_up.connect(func() -> void:
		if button.is_hovered():
			_animate_home_button(button, Vector2(225, 712), Vector2.ONE * 1.035, Color(1.09, 1.06, 1.02), 0.12)
		else:
			_animate_home_button(button, Vector2(225, 715), Vector2.ONE, Color.WHITE, 0.12))
	button.pressed.connect(_quit_game)
	parent.add_child(button)
	var label := _label("退出游戏", 28, INK)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)

func _home_button(parent: Control, node_name: String, source: Texture2D, crop: Rect2, rect: Rect2, action: Callable) -> void:
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
	button.mouse_entered.connect(func() -> void:
		_animate_home_button(button, rect.position + Vector2(0, -3), Vector2.ONE * 1.035, Color(1.09, 1.06, 1.02), 0.16))
	button.mouse_exited.connect(func() -> void:
		_animate_home_button(button, rect.position, Vector2.ONE, Color.WHITE, 0.16))
	button.button_down.connect(func() -> void:
		_animate_home_button(button, rect.position + Vector2(0, 2), Vector2.ONE * 0.96, Color(0.88, 0.84, 0.80), 0.07))
	button.button_up.connect(func() -> void:
		if button.is_hovered():
			_animate_home_button(button, rect.position + Vector2(0, -3), Vector2.ONE * 1.035, Color(1.09, 1.06, 1.02), 0.12)
		else:
			_animate_home_button(button, rect.position, Vector2.ONE, Color.WHITE, 0.12))
	button.pressed.connect(_activate_home_button.bind(button, rect.position, action))
	parent.add_child(button)

func _animate_home_button(button: TextureButton, target_position: Vector2, target_scale: Vector2, tint: Color, duration: float) -> Tween:
	var previous: Tween = button.get_meta("motion_tween") as Tween if button.has_meta("motion_tween") else null
	if previous != null and previous.is_running():
		previous.kill()
	var motion := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.tween_property(button, "position", target_position, duration)
	motion.tween_property(button, "scale", target_scale, duration)
	motion.tween_property(button, "modulate", tint, duration)
	button.set_meta("motion_tween", motion)
	return motion

func _activate_home_button(button: TextureButton, rest_position: Vector2, action: Callable) -> void:
	button.disabled = true
	await _animate_home_button(button, rest_position + Vector2(0, 2), Vector2.ONE * 0.96, Color(0.90, 0.86, 0.82), 0.10).finished
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

# ------------------------------------------------------------------ 入职预演

func _intro_screen() -> void:
	var frame := Panel.new()
	_layout_startup_frame(frame)
	frame.add_theme_stylebox_override("panel", _style(PAPER, WOOD, 8, 8))
	add_child(frame)
	var back := _intro_button("返回", "secondary")
	back.position = Vector2(36, 34)
	back.size = Vector2(132, 60)
	back.pressed.connect(func():
		if _page == 0:
			_back()
		else:
			_go_page(_page - 1))
	frame.add_child(back)
	var heading := _label("入职职场小镇", 34, INK)
	heading.position = Vector2(300, 34)
	heading.size = Vector2(1100, 51)
	frame.add_child(heading)
	var sub := _label("两个选择，先认识这里的同事", 18, Color("7a5533"))
	sub.position = Vector2(300, 90)
	sub.size = Vector2(1100, 27)
	frame.add_child(sub)
	var step := _label("%d / %d" % [_page + 1, PAGES.size()], 22, BRICK)
	step.position = Vector2(1460, 46)
	step.size = Vector2(170, 42)
	frame.add_child(step)
	_scenario_content(frame, PAGES[_page])
	_footer(frame)

func _scenario_content(frame: Panel, page: Dictionary) -> void:
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
	var answer_index: int = _intro_answers[_page]
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
	var line := String(page["question"]) if answer_index < 0 else String(page["replies"][answer_index])
	var dialogue := _label(line, 27, INK)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.position = Vector2(90, 144)
	dialogue.size = Vector2(900, 104)
	card.add_child(dialogue)
	if answer_index >= 0:
		if _page == PAGES.size() - 1:
			var handoff := _label("老周递来入职登记表：选好自己的形象，就正式上班。", 25, INK)
			handoff.position = Vector2(360, 658)
			handoff.size = Vector2(980, 72)
			frame.add_child(handoff)
		return
	var choices: Array = page["choices"]
	for index in choices.size():
		var choice := _intro_button(String(choices[index]), "secondary")
		choice.position = Vector2(255 + index * 410, 660)
		choice.size = Vector2(380, 82)
		choice.pressed.connect(_choose_intro_answer.bind(index))
		frame.add_child(choice)

func _choose_intro_answer(index: int) -> void:
	if _page < 0 or _page >= PAGES.size() or _intro_answers[_page] >= 0:
		return
	_intro_answers[_page] = index
	_rebuild()


func _footer(frame: Panel) -> void:
	var counter := _label("第 %d / %d 页" % [_page + 1, PAGES.size()], 18, Color("7a5533"))
	counter.size = Vector2(180, 60)
	counter.position = Vector2(102, 828)
	frame.add_child(counter)

	var hint := _label("预演选择不计入正式测评", 18, Color("7a5533"))
	hint.position = Vector2(510, 828)
	hint.size = Vector2(550, 60)
	frame.add_child(hint)

	var previous := _intro_button("上一页", "secondary")
	previous.position = Vector2(1170, 828)
	previous.size = Vector2(135, 60)
	previous.disabled = _page == 0
	previous.pressed.connect(func(): _go_page(_page - 1))
	frame.add_child(previous)

	var skip := _intro_button("跳过", "secondary")
	skip.position = Vector2(1315, 828)
	skip.size = Vector2(120, 60)
	skip.pressed.connect(_start_avatar_selection)
	frame.add_child(skip)

	var next := _intro_button("去选择形象" if _page == PAGES.size() - 1 else "继续")
	next.position = Vector2(1445, 828)
	next.size = Vector2(200, 60)
	next.disabled = _intro_answers[_page] < 0
	next.pressed.connect(_start_avatar_selection if _page == PAGES.size() - 1 else func(): _go_page(_page + 1))
	frame.add_child(next)

func _start_intro() -> void:
	_mode = "intro"
	_page = 0
	_last_intro_page = 0
	_intro_answers = [-1, -1]
	_rebuild()

## 继续游戏：跳过导览直接进小镇，不重写 profile（保留上次开局留下的文件）。
## ⚠ 当前存档粒度只有「玩过没有」——真正的进度续玩（currentNodeId / 月份 / 精力落盘）
##   是方案 B 的活，别把这条当成已经能续上中途进度。
func _continue_game() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func _back() -> void:
	_mode = "title"
	_rebuild()
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
	_last_intro_page = _page
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
	back.pressed.connect(func() -> void: _mode = "intro"; _page = _last_intro_page; _rebuild())
	frame.add_child(back)

	var kicker := _label("入职登记", 22, BRICK)
	kicker.position = Vector2(250, 54)
	kicker.size = Vector2(1200, 32)
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

func _spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size.y = height
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _divider() -> Control:
	var line := ColorRect.new()
	line.color = Color(0.42, 0.26, 0.13, 0.45)
	line.custom_minimum_size.y = 3
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

## 小牌：给页码这类小信息裹一圈底盘。
## ⚠ 不能直接往 Label 上 override("normal") —— "normal" 是 Button 的 stylebox 名，
##   Label 只认 "normal" 之外的那套（其实 Label 根本没有 stylebox），所以当年那个框一直没画出来。
func _plate(child: Control, w: float, h: float) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(w, h)
	wrap.size = Vector2(w, h)
	wrap.add_theme_stylebox_override("panel", _style(Color("ead19c"), Color("865139"), 2, 5))
	wrap.add_child(child)
	return wrap

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
