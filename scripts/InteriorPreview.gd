class_name InteriorPreview
extends CanvasLayer

signal exit_requested
signal player_message_submitted(npc_id: String, message: String)
signal activity_selected(activity: Dictionary)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER_DOLL := preload("res://scripts/PaperDoll64Sprite.gd")
const OFFICE_NPC := preload("res://scripts/OfficeNpcWalker.gd")
# 三套动线：新部门室内（1848×851，右侧出口）/ 活动场景（1920×1080，下方）/ 旧室内兜底。
const DEPARTMENT_SCENE_SIZE := Vector2(1848, 851)
const DEPARTMENT_BOUNDS := Rect2(80, 700, 1710, 0)
const DEPARTMENT_START := Vector2(930, 700)
const DEPARTMENT_DOOR_AREA := Rect2(1740, 640, 108, 120)
const DEPARTMENT_DOOR_PROMPT := Vector2(1600, 566)
const DEPARTMENT_DOOR_X := 1600.0
const ROAD_Y := 700.0

const INTERIOR_BOUNDS := Rect2(560, 420, 820, 580)
# 活动专属场景（天台、湖边）：这批图的地板在画面下半部，
# 用区室内那套上界会把人放到栏杆外面，看着就像站在天上。
const ACTIVITY_BOUNDS := Rect2(330, 700, 1290, 340)
const ACTIVITY_START := Vector2(900, 860)
const ACTIVITY_DOOR_AREA := Rect2(830, 940, 260, 100)
const ACTIVITY_DOOR_PROMPT := Vector2(900, 898)
const DOOR_PROMPT_AT := Vector2(900, 682)
const INTERIOR_START := Vector2(1060, 500)
# 旧室内图的玻璃门都位于 1920x1080 场景坐标的底部中央。
const SCENE_SIZE := Vector2(1920, 1080)
const DOOR_AREA := Rect2(870, 725, 180, 120)
const PLAYER_SPEED := 260.0
const TALK_DISTANCE := 165.0
const CHARACTER_SCALE := 10.0 / 3.0
const ACTIVITY_CARDS := {
	"C_LAKE": "res://assets/01_带缩略图面板/C_LAKE_湖边散步_面板.png",
	"C_COFFEE": "res://assets/01_带缩略图面板/C_COFFEE_小馆咖啡聊天_面板.png",
	"D_STUDY": "res://assets/01_带缩略图面板/D_STUDY_独自学习_一起自习_面板.png",
	"D_ROOFTOP": "res://assets/01_带缩略图面板/D_ROOFTOP_书院露台吹风_面板.png",
	"E_SPORT": "res://assets/01_带缩略图面板/E_SPORT_草坪运动_面板.png",
	"E_ESCAPE": "res://assets/01_带缩略图面板/E_ESCAPE_团队密室_面板.png",
	"F_STAGE": "res://assets/01_带缩略图面板/F_STAGE_舞台后台排练_面板.png",
	"F_RAIN": "res://assets/01_带缩略图面板/F_RAIN_雨天共伞_面板.png",
	"G_NIGHT": "res://assets/01_带缩略图面板/G_NIGHT_夜间值守_资料整理_面板.png",
	"G_KTV": "res://assets/01_带缩略图面板/G_KTV_文娱室合唱_KTV_面板.png",
	"H_BBQ": "res://assets/01_带缩略图面板/H_BBQ_夜间烧烤_篝火_面板.png",
	"H_BOARD": "res://assets/01_带缩略图面板/H_BOARD_桌游馆_面板.png",
	# 十二个月自由活动：卡面标题和区域都印死在图上，只接能真正对上的。
	# E/H 仍是训练谷/慢生活园，卡面却印着财务部/生产部，先不接，继续走原活动面板。
	"m9_library": "res://assets/01_带缩略图面板/D_STUDY_独自学习_一起自习_面板.png",
}

## 屋里右上角那一叠的格子位置（场景坐标，1920×1080 那套动线）。
## 整卡和现画的票根共用这三个数，两种卡才不会错开半格。
const ACTIVITY_SLOT_AT := Vector2(1110, 70)
const ACTIVITY_SLOT_SIZE := Vector2(670, 190)
const ACTIVITY_SLOT_STEP := 207.0
## 现画票根上那枚蜂蜜罐（从整卡上切下来的零件，见 tools/v12m_cut_activity_cards.py）。
const ACTIVITY_JAR_TEX := "res://assets/ui/activity_cards/honey_jar.png"

var _root: Control
var _scene: Control
var _title: Label
var _purpose: Label
var _shade: ColorRect
var _player: Node2D
var _player_sprite: PaperDoll64Sprite
var _npc: OfficeNpcWalker
var _npc_name: Label
var _npc_suppressed := false
## 当前这套动线（可行走区 / 出生点 / 出口判定与标识位置）。
var _bounds := INTERIOR_BOUNDS
var _start_position := INTERIOR_START
var _door_area := DOOR_AREA
var _door_prompt_at := DOOR_PROMPT_AT
var _scene_size := SCENE_SIZE
var _horizontal_only := false
var _door_x_threshold := -1.0
var _character_scale := 5.0 / 3.0
var _door_prompt_text := "出口"
var _room_stretch := TextureRect.STRETCH_KEEP_ASPECT_CENTERED
var _npc_data: Dictionary = {}
var _talk_button: Button
var _door_prompt: Button
var _dialog: Panel
var _dialog_text: Label
var _message_input: LineEdit
var _send_button: Button
var _touch_vector := Vector2.ZERO
var _exploration_enabled := false
var _activity_buttons: Array[TextureButton] = []
## 没有整卡的那几处，按同一版式现画的票根（每次 set_activities 重画一遍）。
var _drawn_cards: Array[Control] = []

func _ready() -> void:
	layer = 80
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_root.hide()
	_root.resized.connect(_layout_scene)

func present(location: Dictionary, texture_path: String) -> void:
	for child in _root.get_children():
		child.queue_free()
	_exploration_enabled = false
	_player = null
	_npc = null
	_talk_button = null
	_dialog = null
	_activity_buttons.clear()
	var backdrop := ColorRect.new()
	backdrop.color = Color("10151e")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)
	_scene = Control.new()
	_scene.size = _scene_size
	_root.add_child(_scene)
	_layout_scene()
	var room := TextureRect.new()
	room.texture = _load_texture(texture_path)
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.stretch_mode = _room_stretch
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene.add_child(room)
	_shade = ColorRect.new()
	_shade.color = Color(1, 1, 1, 0)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene.add_child(_shade)
	# 新地图自带区域招牌，右端是返回主地图的出口。
	_door_prompt = Button.new()
	_door_prompt.name = "DoorExitPrompt"
	_door_prompt.text = _door_prompt_text
	_door_prompt.position = _door_prompt_at
	_door_prompt.size = Vector2(186, 52) if _horizontal_only else Vector2(120, 48)
	_door_prompt.focus_mode = Control.FOCUS_NONE
	_door_prompt.add_theme_font_override("font", FONT)
	_door_prompt.add_theme_font_size_override("font_size", 20)
	_door_prompt.add_theme_color_override("font_color", Color("ffe9b8"))
	_door_prompt.add_theme_color_override("font_hover_color", Color("fff6d8"))
	_door_prompt.add_theme_stylebox_override("normal", _door_prompt_style(Color("2b1a10", 0.88)))
	_door_prompt.add_theme_stylebox_override("hover", _door_prompt_style(Color("472814", 0.94)))
	_door_prompt.z_index = 1500
	_door_prompt.pressed.connect(func():
		if _player == null:
			return
		if _door_x_threshold < 0.0 or _player.position.x >= _door_x_threshold:
			exit_requested.emit())
	_door_prompt.hide()
	_scene.add_child(_door_prompt)
	_build_interior_characters(location)
	_build_activity_cards()
	_root.show()
	if room.texture == null:
		# Keep the preview usable when an editor import cache is missing.
		var notice := _label("室内素材加载失败：" + texture_path, 18, Color("ffd6b0"))
		notice.position = Vector2(44, 160)
		notice.size = Vector2(900, 40)
		_scene.add_child(notice)

func _layout_scene() -> void:
	if _scene == null or not is_instance_valid(_scene):
		return
	var viewport_size := _root.size
	var factor := minf(viewport_size.x / _scene_size.x, viewport_size.y / _scene_size.y)
	_scene.scale = Vector2.ONE * factor
	_scene.position = (viewport_size - _scene_size * factor) * 0.5

func dismiss() -> void:
	_root.hide()

func is_open() -> bool:
	return _root != null and _root.visible

func enable_exploration() -> void:
	if _player == null:
		return
	_exploration_enabled = true
	_player.show()
	_update_door_prompt()
	if _npc == null:
		return
	# 活动专属场景（天台、湖边）里不该有同事走动。
	if _npc_suppressed:
		_npc.hide()
		if _npc_name != null:
			_npc_name.hide()
		return
	_npc.show()
	_npc.process_mode = Node.PROCESS_MODE_INHERIT
	_update_talk_state()


## 收掉室内预览自带的走动同事（天台、湖边这类活动场景用）。
func suppress_interior_npc(value: bool) -> void:
	_npc_suppressed = value
	if value and _npc != null:
		_npc.hide()
		if _npc_name != null:
			_npc_name.hide()

## 活动专属场景换一套动线：地板在画面下半部，出生点、出口判定和「出口」标识都往下挪。
## 要在 present() 之前调用——出生点是建室内角色时取的。
## 三套动线：新部门室内（右侧出口）/ 活动场景（下方出口）/ 旧室内兜底。
func set_layout(mode: String) -> void:
	match mode:
		"department":
			_scene_size = DEPARTMENT_SCENE_SIZE
			_bounds = DEPARTMENT_BOUNDS
			_start_position = DEPARTMENT_START
			# 八张新室内的门位置不统一（有的在左、有的在右），不再要求走到门边；
			# 右下角固定一颗「返回小镇」，点它就走。
			_door_area = Rect2(-10, -10, 0, 0)
			_door_prompt_at = Vector2(1470, 742)
			_horizontal_only = true
			_door_x_threshold = -1.0
			_character_scale = 10.0 / 3.0
			_door_prompt_text = "返回小镇"
			_room_stretch = TextureRect.STRETCH_SCALE
		"activity":
			_scene_size = SCENE_SIZE
			_bounds = ACTIVITY_BOUNDS
			_start_position = ACTIVITY_START
			_door_area = ACTIVITY_DOOR_AREA
			_door_prompt_at = ACTIVITY_DOOR_PROMPT
			_horizontal_only = false
			_door_x_threshold = -1.0
			_character_scale = 5.0 / 3.0
			_door_prompt_text = "出口"
			_room_stretch = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_:
			_scene_size = SCENE_SIZE
			_bounds = INTERIOR_BOUNDS
			_start_position = INTERIOR_START
			_door_area = DOOR_AREA
			_door_prompt_at = DOOR_PROMPT_AT
			_horizontal_only = false
			_door_x_threshold = -1.0
			_character_scale = 5.0 / 3.0
			_door_prompt_text = "出口"
			_room_stretch = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

## 活动专属场景（天台、湖边）用一套把地板放低的动线。
func use_activity_layout(value: bool) -> void:
	set_layout("activity" if value else "legacy")

## 新部门室内（1848×851，右侧出口）用另一套动线。
func use_department_layout(value: bool) -> void:
	set_layout("department" if value else "legacy")


func is_exploration_enabled() -> bool:
	return _exploration_enabled

## 门口状态供主世界和验收脚本读取。
func is_door_prompt_active() -> bool:
	return _door_prompt != null and _door_prompt.visible

func set_touch_vector(value: Vector2) -> void:
	_touch_vector = value.limit_length(1.0)

func has_activity_card(activity_id: String) -> bool:
	return ACTIVITY_CARDS.has(activity_id)

func set_activities(activities: Array, enabled: bool, remaining: int) -> void:
	for button in _activity_buttons:
		button.hide()
	# 上一轮现画的票根先收掉，这轮按这一屋子的去处重画。
	for drawn in _drawn_cards:
		if is_instance_valid(drawn):
			drawn.queue_free()
	_drawn_cards.clear()
	var shown := 0
	for activity in activities:
		if shown >= _activity_buttons.size():
			break
		var dict := activity as Dictionary
		var activity_id := String(dict.get("id", ""))
		# 优先用数据里带的整卡（activities.json 的 cardArt），其次才查这张表——
		# 十二个月那套活动的 id 是 m1_lakeside / m7_lawn，不是图的文件名。
		var card_path := String(dict.get("cardArt", ""))
		if card_path.is_empty():
			card_path = String(ACTIVITY_CARDS.get(activity_id, ""))
		var can_go := enabled and remaining > 0 and not bool(dict.get("disabled", false))
		if card_path.is_empty():
			# 没有整卡的也留在这一叠里，同版式现画一张：
			# 之前它掉到右下角那块面板上，屋里一叠 + 右下角一份，同一件事读两遍。
			_drawn_cards.append(_draw_activity_ticket(shown, dict, can_go))
		else:
			var button := _activity_buttons[shown]
			button.texture_normal = _load_texture(card_path)
			button.disabled = not can_go
			button.scale = Vector2.ONE
			button.z_index = 1200
			button.modulate = Color.WHITE if can_go else Color(0.72, 0.72, 0.72)
			button.tooltip_text = String(dict.get("title", "活动")) if can_go \
				else String(dict.get("note", "自由活动窗口开放后可进入"))
			button.set_meta("activity", dict.duplicate(true))
			button.show()
		shown += 1


## 没整卡时现画的那张票根：版式照 assets/01_带缩略图面板 那套横票根，
## 区名、名字、消耗全部读传进来的数据，不烙死在图上。
func _draw_activity_ticket(slot: int, dict: Dictionary, can_go: bool) -> Control:
	var card := Panel.new()
	card.name = "ActivityTicket%d" % slot
	card.position = ACTIVITY_SLOT_AT + Vector2(0, ACTIVITY_SLOT_STEP * slot)
	card.size = ACTIVITY_SLOT_SIZE
	card.z_index = 1200
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fdf6e6")
	style.border_color = Color("f0a63c")
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	card.add_theme_stylebox_override("panel", style)
	if not can_go:
		card.modulate = Color(0.72, 0.72, 0.72)
	_scene.add_child(card)

	# 区名和活动同名的那条（松风训练谷）不重复写两遍：牌子直接省掉，留名字那行。
	var badge_text := String(dict.get("badge", ""))
	if badge_text == String(dict.get("title", "")):
		badge_text = ""
	if not badge_text.is_empty():
		var badge := Panel.new()
		badge.position = Vector2(16, 10)
		badge.size = Vector2(maxf(96.0, badge_text.length() * 26.0 + 34.0), 38)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color("4e9a2f")
		badge_style.border_color = Color("2c5a17")
		badge_style.set_border_width_all(2)
		badge_style.set_corner_radius_all(18)
		badge.add_theme_stylebox_override("panel", badge_style)
		card.add_child(badge)
		var badge_label := _label(badge_text, 22, Color("f4ffe8"))
		badge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(badge_label)

	var title := _label(String(dict.get("title", "自由活动")), 34, Color("3a2a1d"))
	# 现画的票根标题别跟着 _label 的自动换行走：套上 clip_text 之后实测整行不显示，
	# 名字这一行本来就一行装得下。
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.position = Vector2(22, 56)
	title.size = Vector2(430, 48)
	card.add_child(title)
	var note := _label(String(dict.get("note", "")), 19, Color("7a5a40"))
	note.position = Vector2(22, 108)
	note.size = Vector2(430, 62)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_constant_override("line_spacing", 2)
	card.add_child(note)

	var cost_box := Panel.new()
	cost_box.position = Vector2(ACTIVITY_SLOT_SIZE.x - 118, 16)
	cost_box.size = Vector2(102, ACTIVITY_SLOT_SIZE.y - 32)
	var cost_style := StyleBoxFlat.new()
	cost_style.bg_color = Color("dcefc6")
	cost_style.border_color = Color("b0d094")
	cost_style.set_border_width_all(2)
	cost_style.set_corner_radius_all(12)
	cost_box.add_theme_stylebox_override("panel", cost_style)
	card.add_child(cost_box)
	var cost_title := _label("消耗", 18, Color("6b4a2a"))
	cost_title.position = Vector2(0, 6)
	cost_title.size = Vector2(102, 24)
	cost_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_box.add_child(cost_title)
	var cost := int(dict.get("cost", 0))
	# 蜂蜜罐和整卡用同一枚零件：这栏是全游戏的心情账，图标必须对得上。
	if ResourceLoader.exists(ACTIVITY_JAR_TEX):
		var jar := TextureRect.new()
		jar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		jar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		jar.texture = load(ACTIVITY_JAR_TEX)
		jar.position = Vector2(32, 34)
		jar.size = Vector2(38, 46)
		jar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if cost <= 0:
			jar.modulate = Color(0.72, 0.70, 0.66, 0.55)
		cost_box.add_child(jar)
	var cost_value := _label("不花" if cost <= 0 else str(cost), 24,
		Color("8b857c") if cost <= 0 else Color("a35a3a"))
	cost_value.position = Vector2(0, cost_box.size.y - 52)
	cost_value.size = Vector2(102, 32)
	cost_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_box.add_child(cost_value)

	var hit := Button.new()
	hit.focus_mode = Control.FOCUS_NONE
	hit.flat = true
	hit.position = Vector2.ZERO
	hit.size = ACTIVITY_SLOT_SIZE
	hit.disabled = not can_go
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hit.pressed.connect(func(): activity_selected.emit(dict.duplicate(true)))
	card.add_child(hit)
	return card

func interact_with_npc() -> void:
	if _talk_button != null and _talk_button.visible:
		_talk_to_chen()

func set_phase(phase_id: String) -> void:
	if _shade == null:
		return
	_shade.color = Color(0.03, 0.07, 0.22, 0.42) if phase_id == "night" else Color(1, 1, 1, 0)

func _process(delta: float) -> void:
	if not _exploration_enabled or not is_open() or _player == null:
		return
	if _message_input != null and _message_input.has_focus():
		_player_sprite.set_motion(Vector2.ZERO, 0.0)
		_update_talk_state()
		_update_door_prompt()
		return
	var direction := Input.get_axis("move_left", "move_right")
	if is_zero_approx(direction):
		direction = float(int(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) \
			- int(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)))
	if _touch_vector.length_squared() > 0.001:
		direction = _touch_vector.x
	var previous := _player.position
	var target := previous + Vector2(direction * PLAYER_SPEED * delta, 0.0)
	target.x = clampf(target.x, _bounds.position.x, _bounds.end.x)
	target.y = clampf(target.y, _bounds.position.y, _bounds.end.y)
	_player.position = target
	_player.z_index = int(target.y)
	_player_sprite.set_motion(Vector2(direction, 0), previous.distance_to(target))
	_update_talk_state()
	if _exploration_enabled and _door_area.has_point(_player.position):
		exit_requested.emit()
		return
	_update_door_prompt()

func _update_door_prompt() -> void:
	if _door_prompt == null or _player == null:
		return
	# 位置在这里刷，不在设置时刷：出口标识是摆场景时才建出来的，早于它就取不到。
	_door_prompt.position = _door_prompt_at
	_door_prompt.text = _door_prompt_text
	_door_prompt.visible = _exploration_enabled \
		and (_dialog == null or not _dialog.visible)
	_door_prompt.disabled = _door_x_threshold >= 0.0 and _player.position.x < _door_x_threshold

func _build_interior_characters(location: Dictionary) -> void:
	_player = Node2D.new()
	_player.name = "InteriorPlayer"
	_player.position = _start_position
	_player.z_index = int(_start_position.y)
	# 缩放必须挂在父节点上：精灵的 (-32,-72) 是按 scale=1
	# 设计的脚底锚点补偿，若直接放大精灵本身，脚底会偏到 (21,48)，影子就跟人物错位。
	_player.scale = Vector2.ONE * _character_scale
	_scene.add_child(_player)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-24, -4), Vector2(24, -4), Vector2(30, 2), Vector2(18, 8), Vector2(-18, 8), Vector2(-30, 2)])
	shadow.color = Color(0.03, 0.04, 0.05, 0.3)
	shadow.scale = Vector2.ONE * 0.5
	_player.add_child(shadow)
	_player_sprite = PAPER_DOLL.new()
	_player_sprite.position = Vector2(-32, -72)
	_player_sprite.configure_motion_speed(PLAYER_SPEED)
	_player.add_child(_player_sprite)
	_player_sprite.set_loadout(PlayerProfile.get_selected_avatar_id())
	_player.hide()

	var route := PackedVector2Array([Vector2(260, ROAD_Y), Vector2(600, ROAD_Y)])
	_npc_data = _npc_for_location(location)
	if _npc_data.is_empty():
		_npc = null
		return
	_npc = OFFICE_NPC.new()
	_npc.name = "InteriorNpc"
	_npc.configure(String(_npc_data.get("loadout", "bear_green_cardigan")), route, 52.0, 20260914 + String(location.get("code", "A")).unicode_at(0))
	_npc.scale = Vector2.ONE * _character_scale
	_scene.add_child(_npc)
	(_npc.get_child(0) as Node2D).scale = Vector2.ONE * 0.5
	_npc_name = _label("%s · %s" % [_npc_data.get("name", "场景 NPC"), _npc_data.get("role", "区域协作")], 17, Color("fff2c7"))
	_npc_name.position = Vector2(-18, -95)
	_npc_name.size = Vector2(170, 28)
	_npc_name.scale = Vector2.ONE / _character_scale
	_npc_name.add_theme_color_override("font_outline_color", Color("172033"))
	_npc_name.add_theme_constant_override("outline_size", 4)
	_npc.add_child(_npc_name)

	_talk_button = Button.new()
	_talk_button.name = "TalkToInteriorNpc"
	_talk_button.text = "与%s交流" % _npc_data.get("name", "NPC")
	_talk_button.position = Vector2(320, ROAD_Y - 315)
	_talk_button.size = Vector2(230, 62)
	_talk_button.add_theme_font_override("font", FONT)
	_talk_button.add_theme_font_size_override("font_size", 22)
	_talk_button.add_theme_color_override("font_color", Color("fff4d4"))
	_talk_button.add_theme_stylebox_override("normal", _button_style(Color("9f4c36")))
	_talk_button.add_theme_stylebox_override("hover", _button_style(Color("bf6241")))
	_talk_button.z_index = 1900
	_talk_button.pressed.connect(_talk_to_chen)
	_talk_button.hide()
	_scene.add_child(_talk_button)

	_dialog = Panel.new()
	_dialog.name = "InteriorNpcDialog"
	_dialog.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialog.offset_left = 330
	_dialog.offset_top = -330
	_dialog.offset_right = -330
	_dialog.offset_bottom = -70
	_dialog.add_theme_stylebox_override("panel", _panel_style())
	_dialog.z_index = 2000
	_dialog.hide()
	_scene.add_child(_dialog)
	_dialog_text = _label("%s：欢迎来到%s。有什么想了解的吗？" % [_npc_data.get("name", "NPC"), location.get("name", "这个区域")], 21, Color("fff0c9"))
	_dialog_text.position = Vector2(36, 18)
	_dialog_text.size = Vector2(1188, 92)
	_dialog.add_child(_dialog_text)
	_message_input = LineEdit.new()
	_message_input.name = "PlayerMessageInput"
	_message_input.placeholder_text = "输入你想对%s说的话……" % _npc_data.get("name", "NPC")
	_message_input.position = Vector2(36, 126)
	_message_input.size = Vector2(950, 72)
	_message_input.add_theme_font_override("font", FONT)
	_message_input.add_theme_font_size_override("font_size", 21)
	_message_input.add_theme_color_override("font_color", Color("3a2618"))
	_message_input.add_theme_color_override("font_placeholder_color", Color("8f735c"))
	_message_input.add_theme_stylebox_override("normal", _input_style())
	_message_input.text_submitted.connect(func(_value: String): _send_player_message())
	_dialog.add_child(_message_input)
	_send_button = Button.new()
	_send_button.name = "SendMessageButton"
	_send_button.text = "发送"
	_send_button.position = Vector2(1008, 126)
	_send_button.size = Vector2(180, 72)
	_send_button.add_theme_font_override("font", FONT)
	_send_button.add_theme_font_size_override("font_size", 22)
	_send_button.add_theme_color_override("font_color", Color("fff4d4"))
	_send_button.add_theme_stylebox_override("normal", _button_style(Color("9f4c36")))
	_send_button.add_theme_stylebox_override("hover", _button_style(Color("bf6241")))
	_send_button.pressed.connect(_send_player_message)
	_dialog.add_child(_send_button)
	var close_button := Button.new()
	close_button.name = "CloseDialogButton"
	close_button.text = "关闭"
	close_button.position = Vector2(1080, 18)
	close_button.size = Vector2(108, 52)
	close_button.add_theme_font_override("font", FONT)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_stylebox_override("normal", _button_style(Color("6f4933")))
	close_button.pressed.connect(_close_dialog)
	_dialog.add_child(close_button)

	_player.hide()
	_npc.hide()
	_npc.process_mode = Node.PROCESS_MODE_DISABLED

func _build_activity_cards() -> void:
	# 3 个位子：一个区里现在最多同时开两条带整卡的去处（E 区湖边散步 + 草坪运动），
	# 留一位余量，第 4 条以后再说——再多就要考虑这叠要不要滚。
	for index in 3:
		var card := TextureButton.new()
		card.name = "ActivityCard%d" % index
		card.position = ACTIVITY_SLOT_AT + Vector2(0, ACTIVITY_SLOT_STEP * index)
		card.size = ACTIVITY_SLOT_SIZE
		card.ignore_texture_size = true
		card.stretch_mode = TextureButton.STRETCH_SCALE
		card.pivot_offset = card.size * 0.5
		card.focus_mode = Control.FOCUS_NONE
		card.z_index = 1200
		card.mouse_entered.connect(_set_activity_card_hover.bind(card, true))
		card.mouse_exited.connect(_set_activity_card_hover.bind(card, false))
		card.pressed.connect(func(): activity_selected.emit((card.get_meta("activity") as Dictionary).duplicate(true)))
		card.hide()
		_scene.add_child(card)
		_activity_buttons.append(card)

func _set_activity_card_hover(card: TextureButton, hovered: bool) -> void:
	if card.disabled:
		return
	if card.has_meta("hover_tween"):
		var previous_tween := card.get_meta("hover_tween") as Tween
		if previous_tween != null and previous_tween.is_running():
			previous_tween.kill()
	card.z_index = 1300 if hovered else 1200
	var tween := create_tween()
	card.set_meta("hover_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE * (1.035 if hovered else 1.0), 0.12)
	tween.tween_property(card, "modulate", Color(1.25, 1.18, 1.05) if hovered else Color.WHITE, 0.12)

func _npc_for_location(location: Dictionary) -> Dictionary:
	var code := String(location.get("code", "")).to_lower()
	var catalog := {
		"a": {"npcId":"chengong", "name":"陈工", "role":"邻组 Leader", "loadout":"bear_orange_blazer"},
		"b": {"npcId":"wange", "name":"王哥", "role":"技术 · 你的导师", "loadout":"bear_plaid_glasses"},
		"c": {"npcId":"xiaolin", "name":"小林", "role":"产品", "loadout":"bear_beige_blazer"},
		"d": {"npcId":"laozhou", "name":"老周", "role":"资深", "loadout":"bear_green_cardigan"},
		"e": {"npcId":"chengong", "name":"陈工", "role":"邻组 Leader", "loadout":"bear_orange_blazer"},
		"f": {"npcId":"xiaolin", "name":"小林", "role":"产品", "loadout":"bear_beige_blazer"},
		"g": {"npcId":"laozhou", "name":"老周", "role":"资深", "loadout":"bear_green_cardigan"},
		"h": {"npcId":"wange", "name":"王哥", "role":"技术 · 你的导师", "loadout":"bear_plaid_glasses"},
	}
	return catalog.get(code, {})

func _update_talk_state() -> void:
	if _talk_button == null or _npc == null or _player == null:
		return
	var nearby := _player.position.distance_to(_npc.position) <= TALK_DISTANCE
	_talk_button.visible = _exploration_enabled and nearby and not _dialog.visible
	_npc_name.visible = not _talk_button.visible
	_talk_button.position.x = clampf(_npc.position.x - 115.0, 80.0, 620.0)

func _talk_to_chen() -> void:
	if not _exploration_enabled:
		return
	_dialog.show()
	_talk_button.hide()
	_update_door_prompt()
	_message_input.grab_focus()

func _send_player_message() -> void:
	var message := _message_input.text.strip_edges()
	if message.is_empty():
		return
	_dialog_text.text = "你：%s\n%s 正在回复…" % [message, _npc_data.get("name", "NPC")]
	_send_button.disabled = true
	_message_input.editable = false
	player_message_submitted.emit(String(_npc_data.get("npcId", "npc")), message)
	_message_input.clear()

func show_chat_reply(npc_id: String, reply: String) -> void:
	if npc_id != String(_npc_data.get("npcId", "")) or not _dialog.visible:
		return
	_dialog_text.text = "%s：%s" % [_npc_data.get("name", "NPC"), reply]
	_send_button.disabled = false
	_message_input.editable = true
	_message_input.grab_focus()

func show_chat_failure(npc_id: String, reason: String) -> void:
	if npc_id != String(_npc_data.get("npcId", "")) or not _dialog.visible:
		return
	_dialog_text.text = "%s。你的发言已记录，可稍后重试。" % reason
	_send_button.disabled = false
	_message_input.editable = true
	_message_input.grab_focus()

func _close_dialog() -> void:
	_message_input.release_focus()
	_dialog.hide()
	_update_talk_state()
	_update_door_prompt()

func _load_texture(path: String) -> Texture2D:
	var imported := load(path) as Texture2D
	if imported != null:
		return imported
	var image := Image.new()
	var absolute_path := ProjectSettings.globalize_path(path)
	if image.load(absolute_path) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("23170f"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("54321f", 0.93)
	style.border_color = Color("d49a4c")
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	return style

func _door_prompt_style(bg: Color) -> StyleBoxFlat:
	# 门口提示专用：深底金边的圆角胶囊，和大门牌匾呼应。
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("d49a4c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(28)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := _panel_style()
	style.bg_color = color
	style.border_color = Color("4a2619")
	return style

func _input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff8e8")
	style.border_color = Color("b77b48")
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style
