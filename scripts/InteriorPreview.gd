class_name InteriorPreview
extends CanvasLayer

signal exit_requested
signal player_message_submitted(npc_id: String, message: String)
signal activity_selected(activity: Dictionary)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER_DOLL := preload("res://scripts/PaperDoll64Sprite.gd")
const OFFICE_NPC := preload("res://scripts/OfficeNpcWalker.gd")
const SCENE_SIZE := Vector2(1848, 851)
const ROAD_Y := 700.0
const WALK_MIN_X := 80.0
const WALK_MAX_X := 1790.0
const DOOR_AREA := Rect2(1740, 640, 108, 120)
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
}

var _root: Control
var _scene: Control
var _title: Label
var _purpose: Label
var _shade: ColorRect
var _player: Node2D
var _player_sprite: PaperDoll64Sprite
var _npc: OfficeNpcWalker
var _npc_name: Label
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
	_scene.size = SCENE_SIZE
	_root.add_child(_scene)
	_layout_scene()
	var room := TextureRect.new()
	room.texture = _load_texture(texture_path)
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.stretch_mode = TextureRect.STRETCH_SCALE
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
	_door_prompt.text = "返回小镇  →"
	_door_prompt.position = Vector2(1600, 566)
	_door_prompt.size = Vector2(186, 52)
	_door_prompt.focus_mode = Control.FOCUS_NONE
	_door_prompt.add_theme_font_override("font", FONT)
	_door_prompt.add_theme_font_size_override("font_size", 20)
	_door_prompt.add_theme_color_override("font_color", Color("ffe9b8"))
	_door_prompt.add_theme_color_override("font_hover_color", Color("fff6d8"))
	_door_prompt.add_theme_stylebox_override("normal", _door_prompt_style(Color("2b1a10", 0.88)))
	_door_prompt.add_theme_stylebox_override("hover", _door_prompt_style(Color("472814", 0.94)))
	_door_prompt.z_index = 1500
	_door_prompt.pressed.connect(func():
		if _player != null and _player.position.x >= 1600.0:
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
	var factor := minf(viewport_size.x / SCENE_SIZE.x, viewport_size.y / SCENE_SIZE.y)
	_scene.scale = Vector2.ONE * factor
	_scene.position = (viewport_size - SCENE_SIZE * factor) * 0.5

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
	_npc.show()
	_npc.process_mode = Node.PROCESS_MODE_INHERIT
	_update_talk_state()

func is_exploration_enabled() -> bool:
	return _exploration_enabled

## 门口状态供主世界和验收脚本读取。
func is_door_prompt_active() -> bool:
	return _door_prompt != null and _door_prompt.visible

func set_touch_vector(value: Vector2) -> void:
	_touch_vector = value.limit_length(1.0)

func set_activities(activities: Array, enabled: bool, remaining: int) -> void:
	for button in _activity_buttons:
		button.hide()
	for index in mini(activities.size(), _activity_buttons.size()):
		var activity := activities[index] as Dictionary
		var button := _activity_buttons[index]
		var card_path := String(ACTIVITY_CARDS.get(String(activity.get("id", "")), ""))
		button.texture_normal = _load_texture(card_path) if not card_path.is_empty() else null
		button.disabled = not enabled or remaining <= 0 or button.texture_normal == null
		button.scale = Vector2.ONE
		button.z_index = 1200
		button.modulate = Color.WHITE if not button.disabled else Color(0.72, 0.72, 0.72)
		button.tooltip_text = String(activity.get("title", "活动")) if not button.disabled else "自由活动窗口开放后可进入"
		button.set_meta("activity", activity.duplicate(true))
		button.show()

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
	var target := Vector2(clampf(previous.x + direction * PLAYER_SPEED * delta, WALK_MIN_X, WALK_MAX_X), ROAD_Y)
	_player.position = target
	_player.z_index = int(target.y)
	_player_sprite.set_motion(Vector2(direction, 0), previous.distance_to(target))
	_update_talk_state()
	if _exploration_enabled and DOOR_AREA.has_point(_player.position):
		exit_requested.emit()
		return
	_update_door_prompt()

func _update_door_prompt() -> void:
	if _door_prompt == null or _player == null:
		return
	_door_prompt.visible = _exploration_enabled \
		and (_dialog == null or not _dialog.visible)
	_door_prompt.disabled = _player.position.x < 1600.0

func _build_interior_characters(location: Dictionary) -> void:
	_player = Node2D.new()
	_player.name = "InteriorPlayer"
	_player.position = Vector2(930, ROAD_Y)
	_player.z_index = int(ROAD_Y)
	# 缩放必须挂在父节点上：精灵的 (-32,-72) 是按 scale=1
	# 设计的脚底锚点补偿，若直接放大精灵本身，脚底会偏到 (21,48)，影子就跟人物错位。
	_player.scale = Vector2.ONE * CHARACTER_SCALE
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
	_npc.scale = Vector2.ONE * CHARACTER_SCALE
	_scene.add_child(_npc)
	(_npc.get_child(0) as Node2D).scale = Vector2.ONE * 0.5
	_npc_name = _label("%s · %s" % [_npc_data.get("name", "场景 NPC"), _npc_data.get("role", "区域协作")], 17, Color("fff2c7"))
	_npc_name.position = Vector2(-18, -95)
	_npc_name.size = Vector2(170, 28)
	_npc_name.scale = Vector2.ONE / CHARACTER_SCALE
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
	for index in 2:
		var card := TextureButton.new()
		card.name = "ActivityCard%d" % index
		card.position = Vector2(1110, 70 + index * 207)
		card.size = Vector2(670, 190)
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
