extends Control

signal tutorial_pause_finished
signal training_completed
signal training_result(result: Dictionary)

const BattleModelScript = preload("res://training_valley/scripts/battle_model.gd")
const DiceButtonScript = preload("res://training_valley/scripts/dice_button.gd")
const BattleFxScript = preload("res://training_valley/scripts/battle_fx.gd")
const TEX_WANG = preload("res://training_valley/assets/characters/wang_front.png")
const TEX_PLAYER = preload("res://training_valley/assets/characters/player_temp_v2.png")
const TEX_SONG = preload("res://training_valley/assets/characters/song_guard_v2.png")
const TEX_XIAOZHAO = preload("res://training_valley/assets/characters/xiaozhao_locked.png")
const TEX_XIAOLIN = preload("res://training_valley/assets/characters/xiaolin_locked.png")
const TEX_LAOZHOU = preload("res://training_valley/assets/characters/laozhou_locked.png")
const TEX_MAP = preload("res://training_valley/assets/backgrounds/town_map.png")
const TEX_TABLE = preload("res://training_valley/assets/backgrounds/training_table.png")
const CHINESE_FONT = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

const CREAM := Color("#fff6df")
const INK := Color("#49362f")
const GREEN := Color("#537d64")
const GOLD := Color("#f0b94b")
const BLUE := Color("#55bce7")
const RED := Color("#d96558")

var model: BattleModel
var input_locked := true
var first_round_tutorial := true
var tutorial_complete := false
var song_skill_explained := false
var song_roll_introduced := false
var pending_wang_skill := false
var battle_logs: Array[String] = []

var map_background: TextureRect
var table_background: TextureRect
var battle_layer: Control

var round_label: Label
var phase_label: Label
var log_label: Label
var song_hp_bar: ProgressBar
var wang_hp_bar: ProgressBar
var player_hp_bar: ProgressBar
var song_hp_label: Label
var wang_hp_label: Label
var player_hp_label: Label
var song_portrait: TextureRect
var wang_portrait: TextureRect
var player_portrait: TextureRect
var song_unit_panel: Control
var wang_unit_panel: Control
var player_unit_panel: Control

var song_dice_hint: Label
var song_dice_row: HBoxContainer
var wang_dice_hint: Label
var wang_dice_row: HBoxContainer
var pool_hint: Label
var pool_row: HBoxContainer
var attack_button: Button
var double_button: Button
var heal_button: Button
var reroll_button: Button
var card_row: HBoxContainer

var dialogue_layer: Control
var dialogue_portrait_shadow: TextureRect
var dialogue_portrait: TextureRect
var dialogue_name: Label
var dialogue_text: Label
var dialogue_next: Button
var dialogue_lines: Array[Dictionary] = []
var dialogue_index := 0
var dialogue_complete := Callable()

var select_layer: Control
var wang_partner_card: Control
var tutorial_panel: PanelContainer
var tutorial_title: Label
var tutorial_text: Label
var tutorial_next: Button
var tutorial_callback := Callable()

var heal_panel: PanelContainer
var toast_label: Label

var cutin_layer: Control
var cutin_dim: ColorRect
var cutin_group: Control
var cutin_band: Panel
var cutin_title: Label
var cutin_character: TextureRect

var end_layer: Control
var end_title: Label
var end_text: Label
var end_button: Button
var return_button: Button
var transition_layer: ColorRect
var battle_fx: BattleFx


func _ready() -> void:
	model = BattleModelScript.new()
	_build_interface()
	_update_units()
	_start_intro()


func _build_interface() -> void:
	_build_backgrounds()
	battle_layer = Control.new()
	battle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_layer.visible = false
	add_child(battle_layer)

	_build_header()
	_build_units()
	_build_dice_and_cards()
	_build_dialogue_layer()
	_build_selection_layer()
	_build_tutorial_panel()
	_build_heal_panel()
	_build_toast()
	_build_cutin_layer()
	_build_end_layer()
	_build_transition_layer()
	battle_fx = BattleFxScript.new()
	add_child(battle_fx)


func _build_backgrounds() -> void:
	map_background = TextureRect.new()
	map_background.texture = TEX_MAP
	map_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(map_background)

	table_background = TextureRect.new()
	table_background.texture = TEX_TABLE
	table_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	table_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	table_background.visible = false
	add_child(table_background)


func _build_header() -> void:
	var title := _label("松风训练谷", 24, CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(28, 20)
	title.size = Vector2(250, 48)
	title.add_theme_stylebox_override("normal", _style(Color("#68432dee"), 14, Color("#d4a661"), 3))
	battle_layer.add_child(title)

	round_label = _label("训练准备", 19, CREAM)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.position = Vector2(1030, 20)
	round_label.size = Vector2(218, 44)
	round_label.add_theme_stylebox_override("normal", _style(Color("#68432dee"), 14, Color("#d4a661"), 3))
	battle_layer.add_child(round_label)

	phase_label = _label("2 对 1", 15, CREAM)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	phase_label.position = Vector2(790, 71)
	phase_label.size = Vector2(450, 30)
	battle_layer.add_child(phase_label)

	var log_panel := PanelContainer.new()
	log_panel.position = Vector2(1000, 145)
	log_panel.size = Vector2(262, 250)
	log_panel.add_theme_stylebox_override("panel", _style(Color("#fff0cfee"), 18, Color("#7a4c30"), 4))
	battle_layer.add_child(log_panel)
	var log_box := VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 8)
	log_panel.add_child(log_box)
	var log_title := _label("行动记录", 18, INK)
	log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	log_box.add_child(log_title)
	log_label = _label("剧情结束后开始训练。", 15, Color("#604b40"))
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size = Vector2(250, 195)
	log_box.add_child(log_label)


func _build_units() -> void:
	var song := _unit_panel("松叔", TEX_SONG, Vector2(540, 6), Vector2(200, 228), Color("#dcecf4"))
	battle_layer.add_child(song.panel)
	song_unit_panel = song.panel
	song_portrait = song.portrait
	song_hp_bar = song.bar
	song_hp_label = song.hp_label

	var wang := _unit_panel("王哥", TEX_WANG, Vector2(18, 478), Vector2(220, 230), Color("#fff1cf"))
	battle_layer.add_child(wang.panel)
	wang_unit_panel = wang.panel
	wang_portrait = wang.portrait
	wang_hp_bar = wang.bar
	wang_hp_label = wang.hp_label

	var player := _unit_panel("玩家", TEX_PLAYER, Vector2(1042, 478), Vector2(220, 230), Color("#e4f2ed"))
	battle_layer.add_child(player.panel)
	player_unit_panel = player.panel
	player_portrait = player.portrait
	player_hp_bar = player.bar
	player_hp_label = player.hp_label


func _unit_panel(unit_name: String, texture: Texture2D, pos: Vector2, panel_size: Vector2, tint: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _style(Color.TRANSPARENT, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -4)
	panel.add_child(box)
	var portrait := TextureRect.new()
	portrait.texture = texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(panel_size.x - 18, panel_size.y - 70)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)
	var hp_plate := PanelContainer.new()
	hp_plate.add_theme_stylebox_override("panel", _style(tint, 13, Color("#70482f"), 3))
	box.add_child(hp_plate)
	var hp_box := VBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 2)
	hp_plate.add_child(hp_box)
	var name_label := _label(unit_name, 16, INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_box.add_child(name_label)
	var hp_row := HBoxContainer.new()
	hp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hp_row.add_theme_constant_override("separation", 7)
	hp_box.add_child(hp_row)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(panel_size.x - 96, 15)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color("#5a443d55"), 8))
	bar.add_theme_stylebox_override("fill", _style(Color("#dd685b"), 8))
	hp_row.add_child(bar)
	var hp_label := _label("%d / %d" % [BattleModel.PLAYER_MAX_HP, BattleModel.PLAYER_MAX_HP], 13, INK)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.custom_minimum_size = Vector2(58, 20)
	hp_row.add_child(hp_label)
	return {"panel": panel, "portrait": portrait, "bar": bar, "hp_label": hp_label}


func _build_dice_and_cards() -> void:
	song_dice_hint = _label("松叔的三枚骰子", 15, INK)
	song_dice_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	song_dice_hint.position = Vector2(490, 213)
	song_dice_hint.size = Vector2(300, 28)
	song_dice_hint.add_theme_stylebox_override("normal", _style(Color("#d9edf2ee"), 10, Color("#416f85"), 2))
	song_dice_hint.visible = false
	battle_layer.add_child(song_dice_hint)

	song_dice_row = HBoxContainer.new()
	song_dice_row.position = Vector2(512, 247)
	song_dice_row.size = Vector2(256, 78)
	song_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	song_dice_row.add_theme_constant_override("separation", 10)
	song_dice_row.visible = false
	battle_layer.add_child(song_dice_row)

	wang_dice_hint = _label("王哥的三枚骰子", 15, INK)
	wang_dice_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wang_dice_hint.position = Vector2(242, 264)
	wang_dice_hint.size = Vector2(280, 28)
	wang_dice_hint.add_theme_stylebox_override("normal", _style(Color("#f6dcaadd"), 10, Color("#815536"), 2))
	battle_layer.add_child(wang_dice_hint)

	wang_dice_row = HBoxContainer.new()
	wang_dice_row.position = Vector2(256, 299)
	wang_dice_row.size = Vector2(254, 78)
	wang_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wang_dice_row.add_theme_constant_override("separation", 10)
	battle_layer.add_child(wang_dice_row)

	pool_hint = _label("选择你的骰子 · 自己3枚＋王哥留下2枚", 15, INK)
	pool_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pool_hint.position = Vector2(407, 355)
	pool_hint.size = Vector2(500, 30)
	pool_hint.add_theme_stylebox_override("normal", _style(Color("#f6dcaadd"), 10, Color("#815536"), 2))
	battle_layer.add_child(pool_hint)

	pool_row = HBoxContainer.new()
	pool_row.position = Vector2(420, 390)
	pool_row.size = Vector2(476, 82)
	pool_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pool_row.add_theme_constant_override("separation", 12)
	battle_layer.add_child(pool_row)

	card_row = HBoxContainer.new()
	card_row.position = Vector2(350, 490)
	card_row.size = Vector2(580, 106)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 12)
	battle_layer.add_child(card_row)

	double_button = _card_button("×2\n双倍", Color("#f1c35b"))
	double_button.pressed.connect(_on_double_pressed)
	card_row.add_child(double_button)
	heal_button = _card_button("♥\n回复", Color("#91c98a"))
	heal_button.pressed.connect(_on_heal_pressed)
	card_row.add_child(heal_button)
	reroll_button = _card_button("↻\n再投一次", Color("#8ebee7"))
	reroll_button.pressed.connect(_on_reroll_pressed)
	card_row.add_child(reroll_button)

	attack_button = Button.new()
	attack_button.text = "先选择一枚骰子"
	attack_button.position = Vector2(477, 613)
	attack_button.size = Vector2(326, 52)
	attack_button.add_theme_font_override("font", CHINESE_FONT)
	attack_button.add_theme_font_size_override("font_size", 20)
	attack_button.add_theme_color_override("font_color", CREAM)
	attack_button.add_theme_stylebox_override("normal", _style(Color("#496f5a"), 18))
	attack_button.add_theme_stylebox_override("hover", _style(Color("#5f8b70"), 18))
	attack_button.add_theme_color_override("font_disabled_color", Color("#fff0d0"))
	attack_button.add_theme_stylebox_override("disabled", _style(Color("#8a6f50"), 18, Color("#c99a55"), 2))
	attack_button.pressed.connect(_on_attack_pressed)
	battle_layer.add_child(attack_button)


func _build_dialogue_layer() -> void:
	dialogue_layer = Control.new()
	dialogue_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dialogue_layer)
	var shade := ColorRect.new()
	shade.color = Color("#14241c38")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_layer.add_child(shade)

	dialogue_portrait_shadow = TextureRect.new()
	dialogue_portrait_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_portrait_shadow.modulate = Color("#1a171355")
	dialogue_portrait_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_layer.add_child(dialogue_portrait_shadow)
	dialogue_portrait = TextureRect.new()
	dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_layer.add_child(dialogue_portrait)

	var panel := PanelContainer.new()
	panel.position = Vector2(66, 505)
	panel.size = Vector2(1148, 184)
	panel.add_theme_stylebox_override("panel", _style(Color("#fff0cef7"), 22, Color("#70452e"), 5))
	dialogue_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	dialogue_name = _label("旁白", 22, Color("#315b49"))
	dialogue_name.add_theme_color_override("font_outline_color", Color("#fff8e8"))
	dialogue_name.add_theme_constant_override("outline_size", 4)
	box.add_child(dialogue_name)
	dialogue_text = _label("", 19, INK)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size = Vector2(1010, 76)
	box.add_child(dialogue_text)
	dialogue_next = Button.new()
	dialogue_next.text = "继续"
	dialogue_next.custom_minimum_size = Vector2(156, 38)
	dialogue_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	dialogue_next.add_theme_font_override("font", CHINESE_FONT)
	dialogue_next.add_theme_font_size_override("font_size", 17)
	dialogue_next.add_theme_color_override("font_color", CREAM)
	dialogue_next.add_theme_stylebox_override("normal", _style(Color("#5f7f61"), 13, Color("#38563e"), 2))
	dialogue_next.add_theme_stylebox_override("hover", _style(Color("#749773"), 13, Color("#38563e"), 3))
	dialogue_next.pressed.connect(_advance_dialogue)
	box.add_child(dialogue_next)


func _build_selection_layer() -> void:
	select_layer = Control.new()
	select_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_layer.visible = false
	add_child(select_layer)
	var shade := ColorRect.new()
	shade.color = Color("#17251d66")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_layer.add_child(shade)

	var wang_shadow := TextureRect.new()
	wang_shadow.texture = TEX_WANG
	wang_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wang_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wang_shadow.position = Vector2(30, 99)
	wang_shadow.size = Vector2(350, 445)
	wang_shadow.modulate = Color("#18140f55")
	select_layer.add_child(wang_shadow)
	var wang_speaker := TextureRect.new()
	wang_speaker.texture = TEX_WANG
	wang_speaker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wang_speaker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wang_speaker.position = Vector2(18, 84)
	wang_speaker.size = Vector2(350, 445)
	select_layer.add_child(wang_speaker)

	var title := _label("选择本次训练的搭档", 27, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(405, 40)
	title.size = Vector2(820, 50)
	title.add_theme_stylebox_override("normal", _style(Color("#fff0ceee"), 16, Color("#70452e"), 4))
	select_layer.add_child(title)
	var row := HBoxContainer.new()
	row.position = Vector2(395, 104)
	row.size = Vector2(840, 382)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	select_layer.add_child(row)
	wang_partner_card = _partner_card("王哥", "可靠兜底", TEX_WANG, false)
	row.add_child(wang_partner_card)
	row.add_child(_partner_card("小赵", "尚未解锁", TEX_XIAOZHAO, true))
	row.add_child(_partner_card("小林", "尚未解锁", TEX_XIAOLIN, true))
	row.add_child(_partner_card("老周", "尚未解锁", TEX_LAOZHOU, true))

	var dialogue := PanelContainer.new()
	dialogue.position = Vector2(66, 532)
	dialogue.size = Vector2(1148, 152)
	dialogue.add_theme_stylebox_override("panel", _style(Color("#fff0cef7"), 22, Color("#70452e"), 5))
	select_layer.add_child(dialogue)
	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 4)
	dialogue.add_child(dialogue_box)
	var speaker_name := _label("王哥", 22, Color("#315b49"))
	dialogue_box.add_child(speaker_name)
	var words := _label("第一次进训练谷，先让我做你的搭档吧。选中我的角色卡，我们一起上场。", 19, INK)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size = Vector2(1020, 64)
	dialogue_box.add_child(words)


func _partner_card(char_name: String, subtitle: String, texture: Texture2D, locked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 370)
	panel.add_theme_stylebox_override("panel", _style(Color("#f8e7c5f2") if not locked else Color("#c9c2b5ee"), 18, Color("#795038"), 4))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var portrait := TextureRect.new()
	portrait.texture = texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(178, 247)
	portrait.modulate = Color("#777777") if locked else Color.WHITE
	box.add_child(portrait)
	var name_label := _label(char_name, 23, INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var role_label := _label(subtitle, 14, Color("#6f5a50"))
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(role_label)
	var button := Button.new()
	button.text = "未解锁" if locked else "选择王哥"
	button.custom_minimum_size = Vector2(176, 42)
	button.add_theme_font_override("font", CHINESE_FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", CREAM if not locked else INK)
	button.add_theme_stylebox_override("normal", _style(Color("#567861") if not locked else Color("#aaa394"), 12, Color("#68452f"), 2))
	button.add_theme_stylebox_override("hover", _style(Color("#6f9475") if not locked else Color("#b9b2a4"), 12, Color("#68452f"), 3))
	if locked:
		button.pressed.connect(_show_locked_toast.bind(char_name))
	else:
		button.pressed.connect(_select_wang)
	box.add_child(button)
	return panel


func _build_tutorial_panel() -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.position = Vector2(310, 104)
	tutorial_panel.size = Vector2(660, 154)
	tutorial_panel.visible = false
	tutorial_panel.z_index = 45
	tutorial_panel.add_theme_stylebox_override("panel", _style(Color("#fff9eefa"), 22, Color("#e5a83b"), 4))
	add_child(tutorial_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	tutorial_panel.add_child(box)
	tutorial_title = _label("新手引导", 22, Color("#9b651d"))
	box.add_child(tutorial_title)
	tutorial_text = _label("", 17, INK)
	tutorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_text.custom_minimum_size = Vector2(600, 57)
	box.add_child(tutorial_text)
	tutorial_next = Button.new()
	tutorial_next.text = "知道了"
	tutorial_next.custom_minimum_size = Vector2(140, 34)
	tutorial_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	_style_action_button(tutorial_next, Color("#5f8b65"))
	tutorial_next.pressed.connect(_on_tutorial_next)
	box.add_child(tutorial_next)


func _build_heal_panel() -> void:
	heal_panel = PanelContainer.new()
	heal_panel.position = Vector2(460, 285)
	heal_panel.size = Vector2(360, 170)
	heal_panel.visible = false
	heal_panel.z_index = 50
	heal_panel.add_theme_stylebox_override("panel", _style(Color("#f0f9e8"), 22, Color("#65965f"), 4))
	add_child(heal_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	heal_panel.add_child(box)
	var title := _label("回复牌给谁使用？", 21, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var self_button := Button.new()
	self_button.text = "回复自己 +5"
	_style_action_button(self_button, Color("#5d9367"))
	self_button.pressed.connect(_apply_heal.bind("player"))
	box.add_child(self_button)
	var wang_button := Button.new()
	wang_button.text = "回复王哥 +5"
	_style_action_button(wang_button, Color("#c48745"))
	wang_button.pressed.connect(_apply_heal.bind("wang"))
	box.add_child(wang_button)
	var cancel := Button.new()
	cancel.text = "暂时不用"
	_style_action_button(cancel, Color("#80624e"))
	cancel.pressed.connect(_cancel_heal)
	box.add_child(cancel)


func _build_toast() -> void:
	toast_label = _label("", 17, CREAM)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.position = Vector2(440, 66)
	toast_label.size = Vector2(400, 46)
	toast_label.visible = false
	toast_label.add_theme_stylebox_override("normal", _style(Color("#3f4d45ef"), 18))
	add_child(toast_label)


func _build_cutin_layer() -> void:
	cutin_layer = Control.new()
	cutin_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cutin_layer.visible = false
	cutin_layer.z_index = 70
	cutin_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cutin_layer)
	cutin_dim = ColorRect.new()
	cutin_dim.color = Color("#101817aa")
	cutin_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cutin_layer.add_child(cutin_dim)
	cutin_group = Control.new()
	cutin_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cutin_layer.add_child(cutin_group)
	cutin_band = Panel.new()
	cutin_band.position = Vector2(-110, 270)
	cutin_band.size = Vector2(1500, 188)
	cutin_band.pivot_offset = cutin_band.size * 0.5
	cutin_group.add_child(cutin_band)
	cutin_title = _label("由我兜底", 72, Color.WHITE)
	cutin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cutin_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cutin_title.position = Vector2(150, 282)
	cutin_title.size = Vector2(620, 170)
	cutin_group.add_child(cutin_title)
	cutin_character = TextureRect.new()
	cutin_character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cutin_character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cutin_character.position = Vector2(800, 118)
	cutin_character.size = Vector2(330, 520)
	cutin_group.add_child(cutin_character)


func _build_end_layer() -> void:
	end_layer = Control.new()
	end_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_layer.visible = false
	end_layer.z_index = 80
	add_child(end_layer)
	var shade := ColorRect.new()
	shade.color = Color("#14231dcc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(350, 170)
	panel.size = Vector2(580, 380)
	panel.add_theme_stylebox_override("panel", _style(Color("#fff7e8"), 30, GOLD, 5))
	end_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	end_title = _label("训练完成", 38, INK)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(end_title)
	end_text = _label("", 19, Color("#5c493f"))
	end_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_text.custom_minimum_size = Vector2(500, 150)
	box.add_child(end_text)
	end_button = Button.new()
	end_button.text = "再训练一次"
	end_button.custom_minimum_size = Vector2(240, 52)
	end_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_button.add_theme_font_size_override("font_size", 20)
	_style_action_button(end_button, Color("#5f8b65"))
	end_button.pressed.connect(_restart_battle)
	box.add_child(end_button)
	return_button = Button.new()
	return_button.text = "返回小镇"
	return_button.custom_minimum_size = Vector2(240, 52)
	return_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return_button.add_theme_font_size_override("font_size", 20)
	_style_action_button(return_button, Color("#5f8b65"))
	return_button.pressed.connect(func(): training_completed.emit())
	box.add_child(return_button)
	return_button.visible = false


func _build_transition_layer() -> void:
	transition_layer = ColorRect.new()
	transition_layer.color = Color("#172019")
	transition_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_layer.z_index = 100
	transition_layer.visible = false
	add_child(transition_layer)


func _start_intro() -> void:
	_hide_battle_controls()
	battle_fx.clear_focus()
	map_background.visible = true
	table_background.visible = false
	round_label.text = "剧情阶段"
	phase_label.text = "树影书院 → 创意水港"
	_show_dialogue_sequence([
		{"speaker": "旁白", "text": "树影书院的钟声刚落，你和王哥抱着资料一路赶往创意水港。"},
		{"speaker": "玩家", "text": "糟了，再绕主路肯定赶不上去码头的船。"},
		{"speaker": "王哥", "text": "穿过松风训练谷最快。走，我们从紧急通道过去。"},
		{"speaker": "松叔", "text": "站住。紧急通道只在紧急任务备案后开放。"},
		{"speaker": "玩家", "text": "我们赶着去码头交材料，这还不算紧急吗？"},
		{"speaker": "松叔", "text": "着急不等于紧急。规矩不能因为赶时间就跳过去。"},
		{"speaker": "王哥", "text": "那就按训练谷的规矩来。让我们证明自己能处理突发状况。"},
		{"speaker": "松叔", "text": "可以。赢过我的应急训练，我就放行。"},
	], _show_partner_select)


func _show_partner_select() -> void:
	dialogue_layer.visible = false
	map_background.visible = true
	table_background.visible = false
	select_layer.visible = true
	await get_tree().process_frame
	battle_fx.focus(wang_partner_card, "王哥正在教你选搭档 · 点击「选择王哥」", 12)


func _select_wang() -> void:
	battle_fx.clear_focus()
	select_layer.visible = false
	_show_dialogue_sequence([
		{"speaker": "王哥", "text": "好，这一场我和你并肩上。"},
		{"speaker": "王哥", "text": "待会儿我先选骰子、先出手；剩下的两枚会交到你的骰池里。别急，先看清楚再决定。"},
	], _transition_to_battle)


func _transition_to_battle() -> void:
	transition_layer.visible = true
	transition_layer.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(transition_layer, "modulate:a", 1.0, 0.35)
	await fade_in.finished
	dialogue_layer.visible = false
	select_layer.visible = false
	map_background.visible = false
	table_background.visible = true
	_start_battle()
	await get_tree().create_timer(0.12).timeout
	var fade_out := create_tween()
	fade_out.tween_property(transition_layer, "modulate:a", 0.0, 0.42)
	await fade_out.finished
	transition_layer.visible = false


func _start_battle() -> void:
	dialogue_layer.visible = false
	_show_battle_controls()
	model.reset()
	first_round_tutorial = true
	tutorial_complete = false
	song_skill_explained = false
	song_roll_introduced = false
	battle_logs.clear()
	_update_units()
	_update_cards()
	round_label.text = "训练准备"
	phase_label.text = "2 对 1 · 任一队友归零即失败"
	_show_tutorial(
		"先记住生命规则",
		"你和王哥各有10点生命；任何一方归零，搭档队就会失败。松叔有18点生命，需要两个人分别进攻，把他的生命降到0。",
		"开始第一轮",
		_start_round,
		song_unit_panel,
		"先看松叔的生命：你和王哥要分别进攻，把它降到0"
	)


func _start_round() -> void:
	tutorial_panel.visible = false
	heal_panel.visible = false
	battle_fx.clear_focus()
	input_locked = true
	song_dice_hint.visible = false
	song_dice_row.visible = false
	wang_dice_hint.visible = true
	wang_dice_row.visible = true
	pool_hint.visible = false
	pool_row.visible = false
	card_row.visible = false
	attack_button.visible = false
	_clear_row(wang_dice_row)
	_clear_row(pool_row)
	_clear_row(song_dice_row)
	var snapshot := model.begin_round()
	pending_wang_skill = bool(snapshot["wang_skill_triggered"])
	round_label.text = "第 %d 轮" % model.round_index
	phase_label.text = "王哥先选择并攻击"
	_update_units()
	_update_cards()
	if first_round_tutorial:
		_show_tutorial(
			"第一步：搭档先选",
			"王哥先投3枚骰子，并自己判断保留哪一枚。他保留的点数只用于王哥这次攻击，另外两枚随后会交给你。",
			"看王哥出手",
			_animate_wang_roll_and_attack,
			wang_dice_row,
			"先看这里：三枚骰子会滚动，王哥再挑走一枚"
		)
	else:
		await get_tree().create_timer(0.65).timeout
		_animate_wang_roll_and_attack()


func _animate_wang_roll_and_attack() -> void:
	tutorial_panel.visible = false
	await battle_fx.roll_dice(wang_dice_row, model.wang_rolls, [], false)
	await battle_fx.highlight_choice(
		wang_dice_row,
		model.wang_choice_index,
		"王哥选中了这枚 · 它将变成攻击骰",
		false
	)
	_resolve_wang_attack()


func _resolve_wang_attack() -> void:
	tutorial_panel.visible = false
	input_locked = true
	var result := model.resolve_wang_attack()
	await battle_fx.combat_resolution(
		"王哥",
		int(result["attack"]),
		"松叔",
		int(result["defense"]),
		wang_portrait,
		song_portrait,
		song_portrait,
		int(result["damage"]),
		bool(result["blocked"])
	)
	if bool(result["blocked"]):
		_add_log("王哥 %d 对 松叔防御 %d：格挡，王哥受到2点反击。" % [result["attack"], result["defense"]])
		await _play_cutin("song")
		await _explain_song_skill_once()
		battle_fx.show_damage(wang_portrait, 2)
		await get_tree().create_timer(0.8).timeout
	else:
		_add_log("王哥 %d 对 松叔防御 %d：造成%d点伤害。" % [result["attack"], result["defense"], result["damage"]])
	_update_units()
	if _check_battle_end():
		return
	await _prepare_player_phase()


func _prepare_player_phase() -> void:
	phase_label.text = "轮到你选择骰子"
	await _animate_player_pool_assembly()
	if pending_wang_skill:
		_add_log("王哥判断骰池过低，发动「由我兜底」，一枚可见骰子变为6。")
		await _play_cutin("wang")
		await _show_tutorial_pause(
			"王哥专属技能：由我兜底",
			"当你的5枚骰子点数全部不超过4时，王哥会把其中1枚可见骰子变成6。这个技能由王哥自己判断，每场只能发动1次。",
			"继续",
			pool_row,
			"刚才有一枚可见骰子被王哥变成了6"
		)
		pending_wang_skill = false
	if first_round_tutorial:
		_show_tutorial(
			"第二步：五选一",
			"你投出的3枚骰子，加上王哥留下的2枚，一共组成5枚骰池。松叔会遮住其中1枚的点数，但爪印骰仍然可以选择，选中后才会揭晓。",
			"查看技能牌",
			_tutorial_cards,
			pool_row,
			"五枚骰子已经汇合 · 从这里选择1枚"
		)
	else:
		_enable_player_choice()


func _animate_player_pool_assembly() -> void:
	pool_hint.visible = true
	pool_row.visible = true
	var own_values: Array = []
	var own_hidden: Array = []
	for i in range(3):
		own_values.append(model.player_rolls[i])
		own_hidden.append(bool(model.player_pool[i]["hidden"]))
	await battle_fx.roll_dice(pool_row, own_values, own_hidden, false)
	var leftover_indices: Array = []
	for i in range(model.wang_rolls.size()):
		if i != model.wang_choice_index:
			leftover_indices.append(i)
	await battle_fx.transfer_dice(wang_dice_row, leftover_indices, pool_row, false)
	_render_player_pool()
	card_row.visible = true
	attack_button.visible = true


func _tutorial_cards() -> void:
	_show_tutorial(
		"通用技能牌",
		"双倍：仅让你所选骰子的点数×2。再投一次：仅重投你当前选中的骰子。回复：可以给自己或王哥恢复5点生命，是唯一能给搭档使用的通用牌。每张牌本场只能用1次。",
		"查看攻击按钮",
		_tutorial_attack_button,
		card_row,
		"三张通用技能牌都在这里 · 每张本场限用一次"
	)


func _tutorial_attack_button() -> void:
	_show_tutorial(
		"第四步：发动攻击",
		"选好骰子后，这个按钮会亮起。你可以先使用技能牌，也可以直接点击它发动攻击；攻击与防御结算后，才会轮到松叔行动。",
		"我明白了",
		_tutorial_wang_release,
		attack_button,
		"选好骰子后，点击这里发动攻击"
	)


func _tutorial_wang_release() -> void:
	battle_fx.clear_focus()
	tutorial_panel.visible = false
	_show_dialogue_sequence([
		{"speaker": "王哥", "text": "该教的都说完了。接下来由你自己判断——选好骰子，我们一起说服松叔吧。"},
	], _finish_first_tutorial)


func _finish_first_tutorial() -> void:
	first_round_tutorial = false
	tutorial_complete = true
	_enable_player_choice()


func _enable_player_choice() -> void:
	tutorial_panel.visible = false
	input_locked = false
	_render_player_pool()
	attack_button.disabled = true
	attack_button.text = "先选择一枚骰子"
	_update_cards()
	battle_fx.clear_focus()


func _render_wang_dice() -> void:
	_clear_row(wang_dice_row)
	for i in range(model.wang_rolls.size()):
		var selected := i == model.wang_choice_index
		var die := _die_button(model.wang_rolls[i], selected, false)
		die.disabled = true
		die.tooltip_text = "王哥保留" if selected else "稍后交给玩家"
		wang_dice_row.add_child(die)


func _render_player_pool() -> void:
	_clear_row(pool_row)
	for i in range(model.player_pool.size()):
		var die_data := model.player_pool[i]
		var hidden := bool(die_data["hidden"])
		var selected := i == model.selected_pool_index
		var die := _die_button(int(die_data["value"]), selected, hidden)
		die.disabled = input_locked
		die.tooltip_text = "未知骰：可以选择，选中后揭晓" if hidden else ("你的骰子" if die_data["source"] == "player" else "王哥留下的骰子")
		die.pressed.connect(_on_pool_die_pressed.bind(i))
		pool_row.add_child(die)


func _on_pool_die_pressed(index: int) -> void:
	if input_locked:
		return
	var was_hidden := bool(model.player_pool[index]["hidden"])
	var clicked_die: Button = pool_row.get_child(index)
	if not model.select_player_die(index):
		return
	if was_hidden:
		input_locked = true
		await battle_fx.reveal_die(clicked_die, int(model.player_pool[index]["value"]))
		_add_log("你第一次选择了未知骰，揭晓点数为%d。" % int(model.player_pool[index]["value"]))
		input_locked = false
	_render_player_pool()
	attack_button.disabled = false
	attack_button.text = "用 %d 点发动攻击" % int(model.player_pool[index]["value"])
	_update_cards()


func _on_double_pressed() -> void:
	if input_locked:
		return
	if model.use_double():
		_add_log("你使用「双倍」，本次所选骰子的攻击点数×2。")
		attack_button.text = "双倍攻击：%d 点" % (int(model.player_pool[model.selected_pool_index]["value"]) * 2)
		_update_cards()


func _on_reroll_pressed() -> void:
	if input_locked:
		return
	var result := model.use_reroll()
	if bool(result.get("used", false)):
		input_locked = true
		_update_cards()
		var selected_die: Button = pool_row.get_child(model.selected_pool_index)
		await battle_fx.reveal_die(selected_die, int(result["new"]))
		input_locked = false
		_add_log("你使用「再投一次」：%d → %d。" % [result["old"], result["new"]])
		_render_player_pool()
		attack_button.text = "用 %d 点发动攻击" % int(result["new"])
		_update_cards()


func _on_heal_pressed() -> void:
	if input_locked or not model.can_use_card("heal"):
		return
	heal_panel.visible = true
	battle_fx.focus(heal_panel, "选择回复自己或王哥", 10)


func _cancel_heal() -> void:
	heal_panel.visible = false
	battle_fx.clear_focus()


func _apply_heal(target: String) -> void:
	battle_fx.clear_focus()
	var result := model.use_heal(target)
	if bool(result.get("used", false)):
		var who := "自己" if target == "player" else "王哥"
		_add_log("你把「回复」用于%s，恢复%d点生命。" % [who, result["amount"]])
		var target_portrait := player_portrait if target == "player" else wang_portrait
		_show_float_text(
			target_portrait.global_position + Vector2(70, 80),
			"+%d" % result["amount"],
			Color("#54b96e")
		)
		_update_units()
		_update_cards()
	else:
		_show_toast("目标生命已满，回复牌没有消耗。")
	heal_panel.visible = false
	battle_fx.clear_focus()


func _on_attack_pressed() -> void:
	if input_locked or model.selected_pool_index < 0:
		return
	_resolve_player_attack()


func _resolve_player_attack() -> void:
	input_locked = true
	battle_fx.clear_focus()
	_update_cards()
	attack_button.disabled = true
	var result := model.resolve_player_attack()
	if not bool(result.get("resolved", false)):
		input_locked = false
		return
	await battle_fx.combat_resolution(
		"玩家",
		int(result["attack"]),
		"松叔",
		int(result["defense"]),
		player_portrait,
		song_portrait,
		song_portrait,
		int(result["damage"]),
		bool(result["blocked"])
	)
	if bool(result["blocked"]):
		_add_log("你 %d 对 松叔防御 %d：格挡，你受到2点反击。" % [result["attack"], result["defense"]])
		await _play_cutin("song")
		await _explain_song_skill_once()
		battle_fx.show_damage(player_portrait, 2)
		await get_tree().create_timer(0.8).timeout
	else:
		var double_note := "（双倍）" if int(result["multiplier"]) == 2 else ""
		_add_log("你%s %d 对 松叔防御 %d：造成%d点伤害。" % [double_note, result["attack"], result["defense"], result["damage"]])
	_update_units()
	if _check_battle_end():
		return
	await get_tree().create_timer(0.8).timeout
	await _song_turn()


func _song_turn() -> void:
	phase_label.text = "松叔反击回合"
	wang_dice_hint.visible = false
	wang_dice_row.visible = false
	pool_hint.visible = false
	pool_row.visible = false
	card_row.visible = false
	attack_button.visible = false
	song_dice_hint.visible = true
	song_dice_row.visible = true
	var result := model.resolve_song_attack()
	var who := "你" if result["target"] == "player" else "王哥"
	var portrait := player_portrait if result["target"] == "player" else wang_portrait
	var emphasize_song_roll := not song_roll_introduced
	await battle_fx.roll_dice(song_dice_row, result["rolls"], [], emphasize_song_roll)
	await battle_fx.highlight_choice(
		song_dice_row,
		int(result["choice_index"]),
		"松叔选中了这枚 · 它将变成攻击骰",
		emphasize_song_roll
	)
	song_roll_introduced = true
	await battle_fx.combat_resolution(
		"松叔",
		int(result["attack"]),
		who,
		int(result["defense"]),
		song_portrait,
		portrait,
		portrait,
		int(result["damage"]),
		int(result["damage"]) <= 0
	)
	if int(result["damage"]) > 0:
		_add_log("松叔从3枚骰子中选出%d点攻击，%s防御%d，受到%d点伤害。" % [result["attack"], who, result["defense"], result["damage"]])
	else:
		_add_log("松叔攻击%d，%s防御%d：成功挡下。" % [result["attack"], who, result["defense"]])
	_update_units()
	song_dice_hint.visible = false
	song_dice_row.visible = false
	if _check_battle_end():
		return
	await get_tree().create_timer(1.2).timeout
	_start_round()


func _check_battle_end() -> bool:
	var result := model.battle_result()
	if result == "victory":
		_finish_victory()
		return true
	if result == "defeat":
		_finish_defeat()
		return true
	return false


func _finish_victory() -> void:
	input_locked = true
	training_result.emit(_result_payload("victory"))
	_hide_battle_controls()
	round_label.text = "训练通过"
	_show_dialogue_sequence([
		{"speaker": "松叔", "text": "行，反应、判断和配合都过关了。紧急通道打开，你们赶紧去码头。"},
		{"speaker": "松叔", "text": "以后想和其他搭档磨合，也可以来松风训练谷。这里不只管通行，也负责训练。"},
		{"speaker": "王哥", "text": "走吧，别让刚赢下来的时间又浪费了。"},
	], _show_victory_end)


func _finish_defeat() -> void:
	input_locked = true
	training_result.emit(_result_payload("defeat"))
	battle_layer.visible = false
	end_title.text = "训练未通过"
	end_text.text = "松叔：着急的时候更容易乱。回去重来一遍，先看清骰子，再做决定。\n\n任意一名队友生命归零，搭档队都会失败。"
	end_button.text = "重新训练"
	return_button.visible = false
	end_layer.visible = true


func _result_payload(outcome: String) -> Dictionary:
	return {
		"outcome": outcome,
		"rounds": model.round_index,
		"playerHp": model.player_hp,
		"partnerHp": model.wang_hp,
		"opponentHp": model.song_hp,
	}


func _show_victory_end() -> void:
	dialogue_layer.visible = false
	end_title.text = "第一关完成"
	end_text.text = "紧急通道已经开放。\n\n松风训练谷也正式成为你与不同搭档进行磨合训练的地点。"
	end_button.text = "再训练一次"
	return_button.visible = true
	end_layer.visible = true


func _restart_battle() -> void:
	end_layer.visible = false
	_show_battle_controls()
	_start_battle()


func _show_dialogue_sequence(lines: Array, completed: Callable) -> void:
	dialogue_lines.clear()
	for line in lines:
		dialogue_lines.append(line)
	dialogue_index = 0
	dialogue_complete = completed
	dialogue_layer.visible = true
	_show_dialogue_line()


func _show_dialogue_line() -> void:
	var line := dialogue_lines[dialogue_index]
	var speaker := str(line["speaker"])
	dialogue_name.text = speaker
	dialogue_text.text = str(line["text"])
	dialogue_next.text = "进入下一步" if dialogue_index == dialogue_lines.size() - 1 else "继续"
	_set_dialogue_portrait(speaker)


func _set_dialogue_portrait(speaker: String) -> void:
	var texture: Texture2D
	var portrait_position := Vector2(58, 72)
	var portrait_size := Vector2(390, 470)
	match speaker:
		"王哥":
			texture = TEX_WANG
		"松叔":
			texture = TEX_SONG
			portrait_position = Vector2(850, 38)
			portrait_size = Vector2(370, 485)
		"玩家":
			texture = TEX_PLAYER
		_:
			dialogue_portrait.visible = false
			dialogue_portrait_shadow.visible = false
			return
	dialogue_portrait.texture = texture
	dialogue_portrait.position = portrait_position
	dialogue_portrait.size = portrait_size
	dialogue_portrait.visible = true
	dialogue_portrait_shadow.texture = texture
	dialogue_portrait_shadow.position = portrait_position + Vector2(12, 14)
	dialogue_portrait_shadow.size = portrait_size
	dialogue_portrait_shadow.visible = true


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_show_dialogue_line()
		return
	dialogue_layer.visible = false
	if dialogue_complete.is_valid():
		dialogue_complete.call()


func _show_tutorial(
	title: String,
	text_value: String,
	button_text: String,
	callback: Callable,
	focus_control: Control = null,
	_focus_text: String = ""
) -> void:
	input_locked = true
	tutorial_title.text = title
	tutorial_text.text = text_value
	tutorial_next.text = button_text
	tutorial_callback = callback
	tutorial_panel.visible = true
	if is_instance_valid(focus_control):
		battle_fx.focus(focus_control, "", 14)


func _show_tutorial_pause(
	title: String,
	text_value: String,
	button_text: String,
	focus_control: Control = null,
	focus_text: String = ""
) -> void:
	_show_tutorial(
		title,
		text_value,
		button_text,
		func(): tutorial_pause_finished.emit(),
		focus_control,
		focus_text
	)
	await tutorial_pause_finished


func _explain_song_skill_once() -> void:
	if song_skill_explained:
		return
	song_skill_explained = true
	await _show_tutorial_pause(
		"松叔专属技能：寸步不让",
		"只要松叔成功挡下王哥或你的攻击，就会立刻反击刚才的攻击者，造成2点伤害。",
		"继续",
		song_portrait,
		"松叔格挡成功后，会反击攻击者2点生命"
	)


func _on_tutorial_next() -> void:
	tutorial_panel.visible = false
	battle_fx.clear_focus()
	var callback := tutorial_callback
	tutorial_callback = Callable()
	if callback.is_valid():
		callback.call()


func _play_cutin(kind: String) -> void:
	cutin_layer.visible = true
	cutin_dim.modulate.a = 0.0
	cutin_group.modulate.a = 1.0
	if kind == "wang":
		cutin_title.text = "由我兜底"
		cutin_title.position = Vector2(115, 282)
		cutin_character.texture = TEX_WANG
		cutin_character.position = Vector2(815, 120)
		cutin_band.rotation = -0.11
		cutin_band.add_theme_stylebox_override("panel", _style(Color("#f7bd45ee"), 18, Color("#fff4b8"), 8))
		cutin_title.add_theme_color_override("font_color", Color("#fff8d2"))
		cutin_title.add_theme_color_override("font_outline_color", Color("#5a321d"))
		cutin_title.add_theme_constant_override("outline_size", 14)
		cutin_group.position.x = -1350
	else:
		cutin_title.text = "寸步不让"
		cutin_title.position = Vector2(590, 282)
		cutin_character.texture = TEX_SONG
		cutin_character.position = Vector2(150, 110)
		cutin_band.rotation = 0.11
		cutin_band.add_theme_stylebox_override("panel", _style(Color("#3a9edbee"), 18, Color("#c9f5ff"), 8))
		cutin_title.add_theme_color_override("font_color", Color("#ecfbff"))
		cutin_title.add_theme_color_override("font_outline_color", Color("#163f68"))
		cutin_title.add_theme_constant_override("outline_size", 14)
		cutin_group.position.x = 1350
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cutin_dim, "modulate:a", 1.0, 0.3)
	tween.tween_property(cutin_group, "position:x", 0.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	await get_tree().create_timer(1.25).timeout
	var out := create_tween()
	out.set_parallel(true)
	out.tween_property(cutin_dim, "modulate:a", 0.0, 0.3)
	out.tween_property(cutin_group, "modulate:a", 0.0, 0.3)
	await out.finished
	cutin_group.modulate.a = 1.0
	cutin_layer.visible = false


func _show_float_text(pos: Vector2, value: String, color: Color) -> void:
	var label := _label(value, 32, color)
	label.add_theme_color_override("font_outline_color", Color("#fff8e7"))
	label.add_theme_constant_override("outline_size", 6)
	label.position = pos
	label.size = Vector2(120, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 65, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1)
	tween.finished.connect(label.queue_free)


func _update_units() -> void:
	song_hp_bar.max_value = BattleModel.SONG_MAX_HP
	song_hp_bar.value = model.song_hp
	song_hp_label.text = "%d / %d" % [model.song_hp, BattleModel.SONG_MAX_HP]
	wang_hp_bar.max_value = BattleModel.WANG_MAX_HP
	wang_hp_bar.value = model.wang_hp
	wang_hp_label.text = "%d / %d" % [model.wang_hp, BattleModel.WANG_MAX_HP]
	player_hp_bar.max_value = BattleModel.PLAYER_MAX_HP
	player_hp_bar.value = model.player_hp
	player_hp_label.text = "%d / %d" % [model.player_hp, BattleModel.PLAYER_MAX_HP]


func _update_cards() -> void:
	if model == null:
		return
	double_button.disabled = input_locked or not model.can_use_card("double") or model.selected_pool_index < 0 or model.double_armed
	reroll_button.disabled = input_locked or not model.can_use_card("reroll") or model.selected_pool_index < 0
	heal_button.disabled = input_locked or not model.can_use_card("heal")
	double_button.text = "×2\n双倍" if model.can_use_card("double") else "×2\n已使用"
	heal_button.text = "♥\n回复" if model.can_use_card("heal") else "♥\n已使用"
	reroll_button.text = "↻\n再投一次" if model.can_use_card("reroll") else "↻\n已使用"


func _add_log(text_value: String) -> void:
	battle_logs.push_front(text_value)
	if battle_logs.size() > 6:
		battle_logs.resize(6)
	log_label.text = "\n".join(battle_logs)


func _show_locked_toast(char_name: String) -> void:
	_show_toast("%s尚未解锁，本关只能选择王哥。" % char_name)


func _show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)
	tween.finished.connect(func(): toast_label.visible = false)


func _show_battle_controls() -> void:
	map_background.visible = false
	table_background.visible = true
	battle_layer.visible = true
	song_dice_hint.visible = false
	song_dice_row.visible = false
	wang_dice_hint.visible = true
	wang_dice_row.visible = true
	pool_hint.visible = true
	pool_row.visible = true
	card_row.visible = true
	attack_button.visible = true


func _hide_battle_controls() -> void:
	battle_fx.clear_focus()
	battle_layer.visible = false
	song_dice_hint.visible = false
	song_dice_row.visible = false
	wang_dice_hint.visible = false
	wang_dice_row.visible = false
	pool_hint.visible = false
	pool_row.visible = false
	card_row.visible = false
	attack_button.visible = false
	tutorial_panel.visible = false
	heal_panel.visible = false


func _die_button(value: int, selected: bool, hidden: bool) -> Button:
	var button := DiceButtonScript.new()
	button.configure(value, selected, hidden)
	return button


func _card_button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(180, 104)
	button.add_theme_font_override("font", CHINESE_FONT)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_outline_color", Color("#fff4d7"))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_stylebox_override("normal", _style(Color("#fff0c9"), 14, Color("#754a31"), 4))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.24), 14, color.darkened(0.25), 5))
	button.add_theme_stylebox_override("pressed", _style(color, 14, Color("#70462f"), 5))
	button.add_theme_color_override("font_disabled_color", INK)
	button.add_theme_stylebox_override("disabled", _style(color.lightened(0.48), 14, color.darkened(0.18), 3))
	return button


func _style_action_button(button: Button, color: Color) -> void:
	button.add_theme_font_override("font", CHINESE_FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, 12, color.darkened(0.28), 2))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.12), 12, Color("#ffe1a0"), 3))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.1), 12, Color("#fff0bf"), 3))


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", CHINESE_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style(bg: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if border_width > 0:
		style.border_color = border
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
	return style


func _clear_row(row: Container) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
