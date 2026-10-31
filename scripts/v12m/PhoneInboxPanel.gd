class_name PhoneInboxPanel
extends CanvasLayer

## 十二个月流程的手机收件箱与解锁讲解。
##
## 当前版本先做可运行的前端预览：
##   1. 讲解卡用现有纸面、胶带、印章、手机按钮、锁、勾选框拼出来；
##   2. 手机抽屉是右侧滑入，不做全屏，保留办公室上下文；
##   3. 玩家点“稍后”不会扣分，手机按钮继续亮着；
##   4. 回复只记录行为，不在前端算任何分数。
##
## 后续 MonthFlow12M 接入时，把 show_tutorial() / open_phone() 的调用点交给控制器即可。

signal phone_opened()
signal phone_closed()
signal reply_sent(reply_id: String, reply_text: String)
signal tutorial_skipped()
signal tutorial_completed()
## 只借这张讲解卡时：玩家点「打开手机」不打开预览抽屉，交给城镇的真手机。
signal tutorial_open_requested()
## 会话列表里点开了谁 / 谁的消息被看过了（红点该收掉）。
signal conversation_opened(conversation_id: String)
signal conversation_read(conversation_id: String)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const BG_TEXTURE := preload("res://assets/场景内部图/熊起东方总部.png")
const PHONE_FRAME := preload("res://assets/IMG_3984(1).PNG")
const WANG_SPRITE := preload("res://assets/characters/paper_doll_64/compiled/bear_plaid_glasses_walk_64.png")
const PAPER_TEXTURE := preload("res://assets/ui/ledger/paper_tex.png")
const TAPE_TEXTURE := preload("res://assets/ui/ledger/tape_tex.png")
const SEAL_TEXTURE := preload("res://assets/ui/ledger/seal_tex.png")
const PHONE_TEXTURE := preload("res://assets/ui/rework_v1/hud/reference_full_v1/06_手机按钮.png")
const LOCK_TEXTURE := preload("res://assets/ui/rework_v1/task_book/05_锁图标_灰白修正版.png")
const CHECK_TEXTURE := preload("res://assets/ui/rework_v1/task_book/16_未勾选框.png")
const AVATAR_FRAME := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/NPC_通用头像框.png")
const PAW_TEXTURE := preload("res://assets/ui/rework_v1/task_book/22_页面装饰爪印.png")

## 通讯录里四个常驻同事的立绘：头像统一裁头部那一小块。
const CONTACT_SPRITES := {
	"wang_ge": "res://assets/characters/paper_doll_64/compiled/bear_plaid_glasses_walk_64.png",
	"chen_gong": "res://assets/characters/paper_doll_64/compiled/bear_orange_blazer_walk_64.png",
	"xiao_lin": "res://assets/characters/paper_doll_64/compiled/bear_beige_blazer_walk_64.png",
	"lao_zhou": "res://assets/characters/paper_doll_64/compiled/bear_green_cardigan_walk_64.png",
	# 小赵没画过专属立绘：借 avatar_xiaoye 那只熊（蓝夹克），和四位同事的衬衫/西装分得开，
	# 免得列表里只剩一个"通用头像框 + 小"的灰方块。
	"xiao_zhao": "res://assets/characters/paper_doll_64/compiled/avatar_xiaoye_walk_64.png",
}

const INK := Color("2b2119")
const INK_SOFT := Color("5a4635")
const MUTED := Color("8a7259")
const PAPER := Color("f4e8d2")
const CREAM := Color("f8ecd8")
const RED := Color("b33a2c")
const GREEN := Color("5d6b4b")
const UI_PAPER := Color("fff1d5")
const UI_INK := Color("63301d")
const UI_WOOD := Color("704021")
const UI_GOLD := Color("f4ad25")
const UI_GREEN := Color("5f972f")

const CARD_SIZE := Vector2(1040, 650)

var _root: Control
var _hud_button: TextureButton
var _card: Panel
var _lock: TextureRect
var _backdrop: ColorRect
var _phone: Control
var _phone_size := Vector2(620, 900)
var _phone_margin := 58.0
var _thread_width := 500.0
var _message_font := 22
var _scroll: ScrollContainer
var _thread: VBoxContainer
var _read_mark: Label
var _toast: Panel
var _toast_label: Label
var _step_checks: Array[Label] = []
var _reply_buttons: Array[Button] = []
var _toast_tween: Tween
var _tutorial_completed := false
var _phone_open := false
## 强制模式：卡上只留「打开手机」，不给"稍后"，Esc 也关不掉。
## 首月用它——手机是王哥当场交到你手上的东西，不能不看。
var forced_tutorial := false
## 讲解卡三条步骤的覆盖文案（空 = 用卡上默认那三条）。
var tutorial_steps: Array = []
var _step_titles: Array[Label] = []
var _step_subs: Array[Label] = []
var _tutorial_later_button: Button
## 只做讲解卡（供 12 个月首月解锁手机时用）：自己的 HUD 按钮与预览抽屉都不出现。
var tutorial_only := false
## 抽屉内容：城镇侧喂进来；不喂就是原来那张预览的样子。
## 没立绘的人（陈工）把 contact_avatar 设成 null，头像退成通用框 + 姓氏。
var contact_name := "王哥"
var contact_role := "技术导师"
var contact_avatar: Texture2D = WANG_SPRITE
var contact_avatar_region := Rect2(22, 6, 36, 32)
## 这一屏的时间分隔：城镇侧按剧情给（"第 3 月 · 周三上午"）；不喂就不画时间，
## 不拿"今天 14:20"这种编出来的读数冒充（2026-10-30）。
var thread_date := ""
var thread_messages: Array = []
var reply_options: Array = []
## 会话列表（通讯录）：每一项是一位同事。
## {id, name, role, messages:[{speaker,text}], unread:bool, date:String, reply_options:Array}
## 空着的时候就退回老样子——打开手机直接是那一条聊天。
var conversations: Array = []
var reply_hint := "点一下回复就行。"
## 退出用的那颗：留空就不画。它是"先不回"，不是发给对方的一句话。
var decline_label := "先不回，收起手机"
## 城镇已经有自己的手机按钮时，关掉这张面板内置的那颗。
var hide_own_hud := false

var _screen_left := 0.0
var _screen_top := 0.0
var _screen_right := 0.0
var _screen_bottom := 0.0
var _header_y := 0.0
var _header_h := 96.0
var _body_font := 22
var _small_font := 16
var _button_font := 18
var _button_height := 46.0
var _header_name: Label
var _header_role: Label
var _header_avatar: Control
var _reply_bar: Panel
## 当前是「会话列表」还是「某个人的聊天」；没有 conversations 时永远是 chat（兼容老用法）。
var _view := "chat"
## 聊天页当前是谁的会话，回列表、回消息都靠它找回原会话。
var _active_id := ""
var _list: Control
var _list_scroll: ScrollContainer
var _list_box: VBoxContainer
var _header_back: Button
## 聊天页里回复栏本该不该出现：列表页要把它藏起来，但回聊天时得原样还回来。
var _reply_bar_wanted := false


func _ready() -> void:
	layer = 145
	_root = Control.new()
	_root.name = "PhoneInboxRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_phone_size = _compute_phone_size()
	_build_hud_phone()
	_build_card()
	_build_backdrop()
	_build_phone_drawer()
	_build_toast()

	_hud_button.visible = false
	_card.visible = false
	_backdrop.visible = false
	_phone.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _phone_open:
			close_phone()
			get_viewport().set_input_as_handled()
		elif _card != null and _card.visible:
			# 强制模式：这张卡只能靠「打开手机」收掉，Esc 也按不动。
			if forced_tutorial:
				show_toast("先看一眼手机，王哥还等着")
			else:
				close_tutorial()
			get_viewport().set_input_as_handled()


## 讲解卡在手机竖屏下的放大倍数：桌面 1920×1080 恒为 1，手机约 1.5～1.8。
## 卡两侧挂着伸出卡外的胶带和印章，所以按屏宽卡一次，别让装饰被屏幕切掉。
func _ui_scale() -> float:
	var view := get_viewport().get_visible_rect().size
	var scale_by_short_side := clampf(minf(view.x, view.y) / 1080.0, 1.0, 2.0)
	var scale_by_width := (view.x * 0.88 - 80.0) / CARD_SIZE.x
	return maxf(1.0, minf(scale_by_short_side, scale_by_width))


func open_tutorial() -> void:
	_hud_button.visible = not tutorial_only and not hide_own_hud
	_phone.visible = false
	_backdrop.visible = false
	_card.visible = true
	if _tutorial_later_button != null:
		_tutorial_later_button.visible = not forced_tutorial
	for i in _step_titles.size():
		if i >= tutorial_steps.size():
			break
		var step: Dictionary = tutorial_steps[i]
		_step_titles[i].text = "%02d %s" % [i + 1, String(step.get("title", ""))]
		_step_subs[i].text = String(step.get("sub", ""))
	_card.pivot_offset = CARD_SIZE * 0.5
	_card.modulate = Color(1, 1, 1, 0)
	# 手机竖屏时视口被 expand 拉得很高，卡按 1920×1080 排就只剩中间一条。
	# 按视口短边换算倍数放大（桌面 16:9 恒为 1），和另外两张讲解卡同一套算法。
	var card_scale := _ui_scale()
	_card.scale = Vector2(0.96, 0.96) * card_scale
	_lock.modulate = Color(1, 1, 1, 0.62)

	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(v: float) -> void: _card.modulate = Color(1, 1, 1, v), 0.0, 1.0, 0.26)
	tween.tween_property(_card, "scale", Vector2.ONE * card_scale, 0.34).from(Vector2(0.96, 0.96) * card_scale) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_method(func(v: float) -> void: _lock.modulate = Color(1, 1, 1, v), 0.62, 0.34, 0.55).set_delay(0.18)


func close_tutorial() -> void:
	if _card == null or not _card.visible:
		return
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _card.modulate = Color(1, 1, 1, v), _card.modulate.a, 0.0, 0.18)
	tween.tween_callback(_hide_card)
	show_toast("手机按钮会一直亮着，随时可以点。")
	tutorial_skipped.emit()


## 换联系人：名字、身份、头像一起换。
## 头像优先用通讯录里的立绘（王哥、陈工、小林、老周都有），查不到的人才退成通用框 + 姓氏。
func set_contact(contact_id: String, display_name: String, role: String) -> void:
	contact_name = display_name
	contact_role = role
	contact_avatar = _sprite_for(contact_id)
	if _phone != null and _phone.visible:
		_fill_thread()
		_apply_view()


func open_phone(show_list := false) -> void:
	if tutorial_only:
		# 讲解卡上的「打开手机」交给城镇真手机，不打开这张预览抽屉。
		_hide_card()
		tutorial_open_requested.emit()
		return
	if _phone_open:
		return
	if _card != null and _card.visible:
		_hide_card()
	_phone_open = true
	_tutorial_completed = true
	mark_step(0)
	mark_step(1)
	# 有通讯录就直接落在最近有消息的那位头上（手机是通知面板，点开先看到最新那条）；
	# 一条消息都没有才退回列表。剧情弹手机没有通讯录，走单条聊天。
	if conversations.is_empty():
		_view = "chat"
		_fill_thread()
		_apply_view()
		# 单条聊天（剧情弹手机）也可能带一长串历史，先停在最新那条。
		await _scroll_to_latest()
	else:
		var newest: String = "" if show_list else _newest_conversation_id()
		if newest.is_empty():
			_view = "list"
			_fill_thread()
			_fill_list()
			_apply_view()
		else:
			# 走玩家点会话那条路：填聊天页、停在最新一条，返回键可以退回列表。
			await _open_conversation(newest)

	_backdrop.visible = true
	_backdrop.modulate = Color(1, 1, 1, 0)
	_phone.visible = true
	_phone.modulate = Color(1, 1, 1, 0)
	_phone.position = _phone_offscreen_position()

	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(v: float) -> void: _backdrop.modulate = Color(1, 1, 1, v), 0.0, 1.0, 0.22)
	tween.tween_property(_phone, "position", _phone_target_position(), 0.42) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void: _phone.modulate = Color(1, 1, 1, v), 0.0, 1.0, 0.22)
	tween.set_parallel(false)
	tween.tween_callback(_emit_phone_opened)
	tutorial_completed.emit()


func close_phone() -> void:
	if not _phone_open:
		return
	_phone_open = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_phone, "position", _phone_offscreen_position(), 0.30) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_method(func(v: float) -> void: _phone.modulate = Color(1, 1, 1, v), _phone.modulate.a, 0.0, 0.22)
	tween.tween_method(func(v: float) -> void: _backdrop.modulate = Color(1, 1, 1, v), _backdrop.modulate.a, 0.0, 0.22)
	tween.set_parallel(false)
	tween.tween_callback(_finish_close_phone)


## 剧情里的手机演出：这条消息用真手机演一次——从右侧拉开，停在这里等玩家自己关。
## 和收件箱不同：不置已读、不出回复、不动会话列表。之前的往来通过 history 一起带进来，
## 让玩家看得到上下文，而不是孤零零一句。
var _peek_base_layer := -1
func peek_message(contact_id: String, sender_name: String, sender_role: String, history: Array, text: String) -> void:
	if _phone_open:
		return
	# 头像按发件人取，不再用默认那只熊；查不到的人才退回首字。
	set_contact(contact_id, sender_name if not sender_name.is_empty() else "手机", sender_role)
	conversations = []
	# 只有这条新消息是"此刻到的"（顶"刚刚"）；之前的往来各带自己那批的时间话，
	# 没带的就别拿"刚刚"去顶（也所以这里不靠 thread_date 兜底）。
	thread_date = ""
	# 剧情里弹手机是"读到一条消息"，不是一次对话：不给回复项，只留收起。
	reply_options = []
	decline_label = "收起手机"
	var thread: Array = []
	for value in history:
		var item := value as Dictionary
		var who := String(item.get("speaker", "npc"))
		var entry := {"speaker": "me" if who == "我" else "npc", "text": String(item.get("text", ""))}
		# 历史各自带时间话（投递那一批的月+旬+时段）：带上，好按批次顶分隔。
		var stamp := String(item.get("time", ""))
		if not stamp.is_empty():
			entry["time"] = stamp
		thread.append(entry)
	thread.append({"speaker": "npc", "text": text, "time": "刚刚"})
	thread_messages = thread
	# 抽屉平时在 145 层，剧情面板在 150 —— 演这一下期间临时抬上去，关掉再放回。
	_peek_base_layer = layer
	layer = 152
	open_phone()


func is_open() -> bool:
	return _phone_open or (_card != null and _card.visible)


func mark_step(index: int) -> void:
	if index >= 0 and index < _step_checks.size():
		_step_checks[index].visible = true


func show_toast(text: String) -> void:
	_toast.visible = true
	_toast_label.text = text
	_toast.modulate = Color(1, 1, 1, 0)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_method(func(v: float) -> void: _toast.modulate = Color(1, 1, 1, v), 0.0, 1.0, 0.16)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_method(func(v: float) -> void: _toast.modulate = Color(1, 1, 1, v), 1.0, 0.0, 0.24)
	_toast_tween.tween_callback(_hide_toast)


func _hide_card() -> void:
	if is_instance_valid(_card):
		_card.visible = false


func _emit_phone_opened() -> void:
	phone_opened.emit()


func _finish_close_phone() -> void:
	if _peek_base_layer >= 0:
		layer = _peek_base_layer
		_peek_base_layer = -1
		decline_label = "先不回，收起手机"
	if is_instance_valid(_phone):
		_phone.visible = false
	if is_instance_valid(_backdrop):
		_backdrop.visible = false
	phone_closed.emit()


func _hide_toast() -> void:
	if is_instance_valid(_toast):
		_toast.visible = false


# ---------------------------------------------------------------- 构建

func _build_hud_phone() -> void:
	_hud_button = TextureButton.new()
	_hud_button.name = "HudPhoneButton"
	_hud_button.texture_normal = PHONE_TEXTURE
	_hud_button.texture_pressed = PHONE_TEXTURE
	_hud_button.texture_hover = PHONE_TEXTURE
	_hud_button.ignore_texture_size = true
	_hud_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_hud_button.focus_mode = Control.FOCUS_NONE
	_hud_button.size = Vector2(96, 96)
	_hud_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hud_button.offset_left = -132
	_hud_button.offset_top = -132
	_hud_button.offset_right = -36
	_hud_button.offset_bottom = -36
	_hud_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_button.pressed.connect(_on_hud_pressed)
	_hud_button.visible = false if (tutorial_only or hide_own_hud) else true
	_root.add_child(_hud_button)


func _build_card() -> void:
	_card = Panel.new()
	_card.name = "PhoneTutorialCard"
	_card.size = CARD_SIZE
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -CARD_SIZE.x * 0.5
	_card.offset_top = -CARD_SIZE.y * 0.5
	_card.offset_right = CARD_SIZE.x * 0.5
	_card.offset_bottom = CARD_SIZE.y * 0.5
	_card.pivot_offset = CARD_SIZE * 0.5
	_card.rotation_degrees = -0.7
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.add_theme_stylebox_override("panel", _card_style())
	_root.add_child(_card)

	var paper := _texture(PAPER_TEXTURE, Rect2(Vector2.ZERO, CARD_SIZE), TextureRect.STRETCH_SCALE, 0.34)
	_card.add_child(paper)

	var tape_a := _texture(TAPE_TEXTURE, Rect2(-46, -28, 230, 66), TextureRect.STRETCH_SCALE, 0.90)
	tape_a.rotation_degrees = -18
	tape_a.pivot_offset = Vector2(115, 33)
	_card.add_child(tape_a)
	var tape_b := _texture(TAPE_TEXTURE, Rect2(CARD_SIZE.x - 190, CARD_SIZE.y - 34, 230, 66), TextureRect.STRETCH_SCALE, 0.90)
	tape_b.rotation_degrees = 7
	tape_b.pivot_offset = Vector2(115, 33)
	_card.add_child(tape_b)

	var seal := _texture(SEAL_TEXTURE, Rect2(CARD_SIZE.x - 154, 38, 108, 108), TextureRect.STRETCH_SCALE, 0.94)
	seal.rotation_degrees = 9
	seal.pivot_offset = Vector2(54, 54)
	_card.add_child(seal)
	var seal_text := _label("已解锁", 20, Color(0.97, 0.91, 0.82, 0.95), true, 108, HORIZONTAL_ALIGNMENT_CENTER)
	seal_text.position = Vector2(CARD_SIZE.x - 154, 78)
	seal_text.size = Vector2(108, 28)
	seal_text.rotation_degrees = 9
	_card.add_child(seal_text)

	var tag := Panel.new()
	tag.position = Vector2(42, -22)
	tag.size = Vector2(172, 34)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_stylebox_override("panel", _pill_style(Color("2b2119"), Color(0, 0, 0, 0)))
	_card.add_child(tag)
	var tag_dot := ColorRect.new()
	tag_dot.color = Color("e04a3c")
	tag_dot.position = Vector2(18, 13)
	tag_dot.size = Vector2(8, 8)
	tag_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(tag_dot)
	var tag_text := _label("第一次使用", 15, CREAM, false, 120)
	tag_text.position = Vector2(36, 4)
	tag_text.size = Vector2(120, 26)
	tag.add_child(tag_text)

	var hero := Control.new()
	hero.position = Vector2(58, 52)
	hero.size = Vector2(300, 360)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(hero)

	var phone_img := _texture(PHONE_TEXTURE, Rect2(24, 18, 252, 252), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	hero.add_child(phone_img)
	_lock = _texture(LOCK_TEXTURE, Rect2(0, 54, 94, 94), TextureRect.STRETCH_KEEP_ASPECT_CENTERED, 0.34)
	_lock.rotation_degrees = -14
	_lock.pivot_offset = Vector2(47, 47)
	hero.add_child(_lock)

	var caption := _label("工作手机", 31, Color("3a2a1d"), true, 300, HORIZONTAL_ALIGNMENT_CENTER)
	caption.position = Vector2(0, 288)
	caption.size = Vector2(300, 42)
	hero.add_child(caption)
	var hero_sub := _label("消息不会打断手头的事", 15, MUTED, false, 300, HORIZONTAL_ALIGNMENT_CENTER)
	hero_sub.position = Vector2(0, 332)
	hero_sub.size = Vector2(300, 26)
	hero.add_child(hero_sub)

	var content := Control.new()
	content.position = Vector2(400, 58)
	content.size = Vector2(580, 560)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(content)

	var kicker := _label("工作方式", 14, Color("a35a3a"), true, 580)
	kicker.position = Vector2(0, 0)
	kicker.size = Vector2(580, 22)
	content.add_child(kicker)

	var title := _label("你的工作手机", 54, INK, true, 580)
	title.position = Vector2(0, 22)
	title.size = Vector2(580, 64)
	content.add_child(title)

	var lede := _label("工作消息会落到这里，不用一直盯着。", 22, Color("6b5540"), false, 560)
	lede.position = Vector2(0, 92)
	lede.size = Vector2(560, 36)
	content.add_child(lede)

	var preview := Panel.new()
	preview.position = Vector2(0, 138)
	preview.size = Vector2(560, 86)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_theme_stylebox_override("panel", _soft_panel_style())
	content.add_child(preview)

	var avatar := _texture(AVATAR_FRAME, Rect2(14, 18, 50, 50), TextureRect.STRETCH_SCALE)
	preview.add_child(avatar)
	var avatar_text := _label("王", 22, Color("5a3a26"), true, 50, HORIZONTAL_ALIGNMENT_CENTER)
	avatar_text.position = Vector2(14, 18)
	avatar_text.size = Vector2(50, 50)
	preview.add_child(avatar_text)
	var bubble_name := _label("王哥 · 技术导师", 14, Color("9a7b5e"), false, 460)
	bubble_name.position = Vector2(78, 14)
	bubble_name.size = Vector2(460, 22)
	preview.add_child(bubble_name)
	var bubble_text := _label("手机拿好。以后有事，我在手机上找你。", 20, Color("33261b"), false, 460)
	bubble_text.position = Vector2(78, 38)
	bubble_text.size = Vector2(460, 34)
	preview.add_child(bubble_text)

	var steps := VBoxContainer.new()
	steps.position = Vector2(0, 240)
	steps.size = Vector2(560, 210)
	steps.add_theme_constant_override("separation", 0)
	steps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(steps)
	_add_step(steps, "01", "点右下角的手机", "圆形按钮，随时都能打开。")
	_add_step(steps, "02", "看未读消息", "红点只是提醒，不点也不会打断主线。")
	_add_step(steps, "03", "回一句", "“收到”或“稍后回复”，都算回应。")

	var open_button := Button.new()
	open_button.name = "OpenPhoneButton"
	open_button.text = "打开手机"
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.position = Vector2(0, 470)
	open_button.size = Vector2(210, 62)
	_style_primary(open_button)
	open_button.pressed.connect(open_phone)
	content.add_child(open_button)

	var later_button := Button.new()
	later_button.name = "LaterButton"
	later_button.text = "稍后，先忙手头的"
	later_button.flat = true
	later_button.focus_mode = Control.FOCUS_NONE
	later_button.position = Vector2(234, 480)
	later_button.size = Vector2(220, 46)
	_style_text_button(later_button)
	later_button.pressed.connect(close_tutorial)
	content.add_child(later_button)
	_tutorial_later_button = later_button

	var fineprint := _label("不回也不会扣分；但以后有事都走这台手机。", 15, Color("9a8066"), false, 560)
	fineprint.position = Vector2(0, 540)
	fineprint.size = Vector2(560, 24)
	content.add_child(fineprint)

	var paw := _texture(PAW_TEXTURE, Rect2(CARD_SIZE.x - 112, CARD_SIZE.y - 96, 78, 78), TextureRect.STRETCH_KEEP_ASPECT_CENTERED, 0.13)
	paw.rotation_degrees = -18
	paw.pivot_offset = Vector2(39, 39)
	_card.add_child(paw)


func _build_backdrop() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "PhoneBackdrop"
	_backdrop.color = Color(0.04, 0.03, 0.02, 0.42)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	_root.add_child(_backdrop)


func _build_phone_drawer() -> void:
	_screen_left = _phone_size.x * 0.115
	_screen_top = _phone_size.y * 0.080
	_screen_right = _phone_size.x * 0.885
	_screen_bottom = _phone_size.y * 0.900
	_phone_margin = _screen_left
	_thread_width = _screen_right - _screen_left
	_body_font = int(clampf(_phone_size.y / 38.0, 17, 24))
	_message_font = _body_font
	_small_font = int(clampf(_phone_size.y / 50.0, 13, 18))
	var name_font := int(clampf(_phone_size.y / 29.0, 22, 32))
	_button_font = int(clampf(_phone_size.y / 44.0, 16, 20))
	_button_height = clampf(_phone_size.y * 0.056, 40, 54)
	_header_y = _screen_top + 6.0

	_phone = Control.new()
	_phone.name = "PhoneDrawer"
	_phone.size = _phone_size
	_phone.position = _phone_offscreen_position()
	_phone.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_phone)

	var art := TextureRect.new()
	art.name = "PhoneFrame"
	art.texture = PHONE_FRAME
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.position = Vector2.ZERO
	art.size = _phone_size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone.add_child(art)

	_header_name = _label(contact_name, name_font, UI_INK, true, 220)
	_header_name.position = Vector2(_screen_left + 68, _header_y + 4)
	_header_name.size = Vector2(220, int(name_font * 1.25))
	_phone.add_child(_header_name)
	_header_role = _label(contact_role, _small_font, Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.62), false, 220)
	_header_role.position = Vector2(_screen_left + 68, _header_y + 4 + int(name_font * 1.25))
	_header_role.size = Vector2(220, _small_font + 12)
	_phone.add_child(_header_role)

	var close := _ui_button("×", Vector2(48, 48), UI_GOLD, 28)
	close.name = "ClosePhoneButton"
	close.position = Vector2(_screen_right - 48, _header_y)
	close.pressed.connect(close_phone)
	_phone.add_child(close)

	# 聊天页左上角的「返回通讯录」：列表页不出现。
	_header_back = _ui_button("返回", Vector2(60, 40), UI_GOLD, 16)
	_header_back.name = "BackToListButton"
	_header_back.position = Vector2(_screen_left - 4, _header_y + 14)
	_header_back.visible = false
	_header_back.pressed.connect(back_to_list)
	_phone.add_child(_header_back)

	var rule := ColorRect.new()
	rule.color = Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.12)
	rule.position = Vector2(_screen_left, _header_y + _header_h)
	rule.size = Vector2(_thread_width, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone.add_child(rule)

	_scroll = ScrollContainer.new()
	_scroll.name = "ThreadScroll"
	_scroll.position = Vector2(_screen_left, _header_y + _header_h + 14.0)
	_scroll.size = Vector2(_thread_width, 400.0)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_phone.add_child(_scroll)

	_thread = VBoxContainer.new()
	_thread.name = "Thread"
	_thread.alignment = BoxContainer.ALIGNMENT_END
	_thread.add_theme_constant_override("separation", 10)
	_thread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_thread)

	_reply_bar = Panel.new()
	_reply_bar.name = "ReplyBar"
	_reply_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reply_bar.add_theme_stylebox_override("panel", _reply_bar_style())
	_phone.add_child(_reply_bar)

	_build_conversation_list()
	_fill_thread()


## 会话列表（通讯录）：四个同事固定在这儿，谁有新消息谁那行亮红点。
func _build_conversation_list() -> void:
	_list = Control.new()
	_list.name = "ConversationList"
	_list.position = Vector2(_screen_left, _header_y + _header_h + 10.0)
	_list.size = Vector2(_thread_width, 320.0)
	_list.visible = false
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone.add_child(_list)

	_list_scroll = ScrollContainer.new()
	_list_scroll.name = "ConversationScroll"
	_list_scroll.position = Vector2.ZERO
	_list_scroll.size = _list.size
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_list_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_list.add_child(_list_scroll)

	_list_box = VBoxContainer.new()
	_list_box.name = "ConversationBox"
	_list_box.add_theme_constant_override("separation", 10)
	_list_box.custom_minimum_size = Vector2(_thread_width - 12, 0)
	_list_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list_scroll.add_child(_list_box)


## 视图切换：列表页把聊天那一套（气泡、回复栏、返回）收起来，聊天页原样还回来。
func _apply_view() -> void:
	if _phone == null:
		return
	var in_chat := _view == "chat" or conversations.is_empty()
	if _list != null:
		_list.visible = not in_chat
		var list_h := _screen_bottom - (_header_y + _header_h + 10.0) - 10.0
		_list.size = Vector2(_thread_width, maxf(list_h, 120.0))
		_list_scroll.size = _list.size
	if _scroll != null:
		_scroll.visible = in_chat
	if _reply_bar != null:
		_reply_bar.visible = in_chat and _reply_bar_wanted
	if _header_back != null:
		# 返回键只在聊天页出现；列表页左边留给「消息」这两个字。
		_header_back.visible = in_chat
	# 列表页头像是"消息"总览，不指向某一个人。
	if is_instance_valid(_header_avatar):
		_header_avatar.visible = in_chat
		_header_avatar.position.x = _screen_left + (68.0 if in_chat else 0.0)
	if _header_name != null and _header_role != null:
		if in_chat:
			_header_name.text = contact_name
			_header_role.text = contact_role
			# 返回键占了最左边那 68px，头像和名字整体往右让开。
			_header_name.position.x = _screen_left + 136
			_header_role.position.x = _screen_left + 136
		else:
			var waiting := 0
			for value in conversations:
				if value is Dictionary and bool((value as Dictionary).get("unread", false)):
					waiting += 1
			_header_name.text = "消息"
			if waiting > 0:
				_header_role.text = "%d 位联系人 · %d 人找你" % [conversations.size(), waiting]
			else:
				_header_role.text = "%d 位联系人" % conversations.size()
			_header_name.position.x = _screen_left + 6
			_header_role.position.x = _screen_left + 6


func back_to_list() -> void:
	if conversations.is_empty():
		close_phone()
		return
	_view = "list"
	_fill_list()
	_apply_view()
	_scroll.scroll_vertical = 0


## 外面换了会话数据（新消息到了 / 某条已读）之后调一下：列表和红点跟着重画。
func refresh_conversations() -> void:
	if _phone == null:
		return
	_fill_list()
	_apply_view()


## 点开某位同事：把这一条会话的内容接到聊天页上。
func _open_conversation(conversation_id: String) -> void:
	var conv := _find_conversation(conversation_id)
	if conv.is_empty():
		return
	_active_id = conversation_id
	contact_name = String(conv.get("name", ""))
	contact_role = String(conv.get("role", ""))
	contact_avatar = _sprite_for(conversation_id)
	thread_messages = (conv.get("messages", []) as Array).duplicate(true)
	reply_options = (conv.get("reply_options", []) as Array).duplicate(true)
	# 空会话的人没有时间戳，就别顶上一个别人的时间。
	thread_date = String(conv.get("date", ""))
	var was_unread := bool(conv.get("unread", false))
	if was_unread:
		conv["unread"] = false
	_view = "chat"
	_fill_thread()
	_apply_view()
	# 会话能跨好几个月，点进来先停在最新那条：停最上面，玩家看到的是三个月前的信，
	# 回复键却是这个月的（2026-10-30 第 11 月实拍）。等一帧让容器算完高度再滚。
	await _scroll_to_latest()
	conversation_opened.emit(conversation_id)
	if was_unread:
		conversation_read.emit(conversation_id)


## 滚到聊天最底下：新消息总在底部，打开谁的会话都该先看到它。
func _scroll_to_latest() -> void:
	await get_tree().process_frame
	if _scroll != null and is_instance_valid(_scroll):
		_scroll.scroll_vertical = 99999


func _find_conversation(conversation_id: String) -> Dictionary:
	for value in conversations:
		if not (value is Dictionary):
			continue
		var conv := Dictionary(value)
		if String(conv.get("id", "")) == conversation_id:
			return conv
	return {}


## 通讯录每一行：头像 / 名字 / 身份 / 最后一条 / 时间 / 未读红点。
func _fill_list() -> void:
	if _list_box == null:
		return
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.free()
	var row_w := _thread_width - 12.0
	for value in _ranked_conversations():
		if not (value is Dictionary):
			continue
		_add_conversation_row(Dictionary(value), row_w)


## 会话按最近一批的时间倒序：小赵刚发的那条要排在最上面，没聊过的垫底。
## `sort` 由城镇按「月 ×100 + 旬 ×10 + 时段」算；没有这格的老数据/探针数据按原顺序排。
func _ranked_conversations() -> Array:
	var indexed: Array = []
	for index in conversations.size():
		var value = conversations[index]
		if value is Dictionary:
			indexed.append({"i": index, "c": value})
	indexed.sort_custom(func(a, b):
		var sa := int((a["c"] as Dictionary).get("sort", -1))
		var sb := int((b["c"] as Dictionary).get("sort", -1))
		if sa != sb:
			return sa > sb
		return int(a["i"]) < int(b["i"])
	)
	var out: Array = []
	for entry in indexed:
		out.append(entry["c"])
	return out


## 打开手机先落到谁头上：优先还没看的那位（红点亮着，玩家点手机就是来看他的），
## 都看过了就落到最近有消息的那位；一条消息都没有才返回空串（退回列表）。
func _newest_conversation_id() -> String:
	var fallback := ""
	for value in _ranked_conversations():
		var conv := value as Dictionary
		if (conv.get("messages", []) as Array).is_empty():
			continue
		if bool(conv.get("unread", false)):
			return String(conv.get("id", ""))
		if fallback.is_empty():
			fallback = String(conv.get("id", ""))
	return fallback


func _add_conversation_row(conv: Dictionary, row_w: float) -> void:
	var row_h := 84.0
	var unread := bool(conv.get("unread", false))
	var plate := PanelContainer.new()
	plate.name = "Row_%s" % String(conv.get("id", ""))
	plate.custom_minimum_size = Vector2(row_w, row_h)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", _row_style(unread))
	_list_box.add_child(plate)

	var hit := Button.new()
	hit.name = "Open_%s" % String(conv.get("id", ""))
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.pressed.connect(_open_conversation.bind(String(conv.get("id", ""))))
	plate.add_child(hit)

	var inner := Control.new()
	inner.custom_minimum_size = Vector2(row_w, row_h)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(inner)

	var contact_id := String(conv.get("id", ""))
	var face := _row_avatar(contact_id, String(conv.get("name", "")))
	face.position = Vector2(14, 18)
	inner.add_child(face)

	var name_text := String(conv.get("name", ""))
	var name_label := _label(name_text, 20, UI_INK, true, 200)
	name_label.position = Vector2(74, 12)
	name_label.size = Vector2(200, 28)
	inner.add_child(name_label)

	var name_w := FONT.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	var role_label := _label(String(conv.get("role", "")), _small_font - 1, Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.55), false, 160)
	role_label.position = Vector2(74 + name_w + 10, 17)
	role_label.size = Vector2(160, 20)
	inner.add_child(role_label)

	var messages: Array = conv.get("messages", [])
	var preview := "还没有消息"
	if not messages.is_empty():
		preview = _preview_of(messages)
	var preview_label := _label(preview, _small_font, Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.72), false, row_w - 74 - 92)
	preview_label.position = Vector2(74, 46)
	preview_label.size = Vector2(row_w - 74 - 92, 26)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	preview_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	inner.add_child(preview_label)

	# 列表这格只放得下月份（"第 3 月"）；哪一旬、哪个时段点进会话看分隔。
	var date_text := String(conv.get("date_short", ""))
	if date_text.is_empty():
		date_text = String(conv.get("date", ""))
	if not date_text.is_empty():
		var date_label := _label(date_text, _small_font - 2, Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.45), false, 96, HORIZONTAL_ALIGNMENT_RIGHT)
		date_label.position = Vector2(row_w - 104, 16)
		date_label.size = Vector2(88, 20)
		inner.add_child(date_label)

	if unread:
		var dot := Panel.new()
		dot.name = "UnreadDot"
		dot.position = Vector2(row_w - 30, 46)
		dot.size = Vector2(10, 10)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", _pill_style(RED, Color(0, 0, 0, 0)))
		inner.add_child(dot)


## 列表预览只取最后一条，超过一行交给省略号。
func _preview_of(messages: Array) -> String:
	for index in range(messages.size() - 1, -1, -1):
		var value = messages[index]
		if not (value is Dictionary):
			continue
		var text := String((value as Dictionary).get("text", ""))
		if text.is_empty():
			continue
		if String((value as Dictionary).get("speaker", "")) == "我":
			return "我：" + text
		return text
	return ""


## 列表行的小头像：有立绘裁头，没有就通用框 + 姓氏。
func _row_avatar(contact_id: String, display_name: String) -> Control:
	var box := Control.new()
	box.size = Vector2(48, 48)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sprite := _sprite_for(contact_id)
	if sprite != null:
		var head := AtlasTexture.new()
		head.atlas = sprite
		head.region = contact_avatar_region
		box.add_child(_texture(head, Rect2(0, 0, 48, 48), TextureRect.STRETCH_KEEP_ASPECT_COVERED))
		return box
	box.add_child(_texture(AVATAR_FRAME, Rect2(0, 0, 48, 48), TextureRect.STRETCH_SCALE))
	var initial := _label(display_name.left(1), 20, Color("5a3a26"), true, 48, HORIZONTAL_ALIGNMENT_CENTER)
	initial.position = Vector2(0, 10)
	initial.size = Vector2(48, 28)
	box.add_child(initial)
	return box


func _sprite_for(contact_id: String) -> Texture2D:
	if CONTACT_SPRITES.has(contact_id):
		return load(String(CONTACT_SPRITES[contact_id])) as Texture2D
	return null


## 抽屉里的一切文字都从上面的变量来：换联系人、换消息、换回复项，不用重建控件树。
func _fill_thread() -> void:
	if _phone == null:
		return
	_header_name.text = contact_name
	_header_role.text = contact_role
	if is_instance_valid(_header_avatar):
		_phone.remove_child(_header_avatar)
		_header_avatar.free()
	_header_avatar = _make_avatar()
	_phone.add_child(_header_avatar)
	_phone.move_child(_header_avatar, _header_name.get_index())

	for child in _thread.get_children():
		_thread.remove_child(child)
		child.free()
	# 空会话把提示摆在中间，有消息时还是从底部往上堆。
	_thread.alignment = BoxContainer.ALIGNMENT_CENTER if thread_messages.is_empty() else BoxContainer.ALIGNMENT_END
	# 每条消息都按自己的剧情时间分隔：先放时间药丸，再放气泡；没有 time 就用会话的 thread_date 兜底。
	# 时间没变就不再加药丸——同一批两三条、或者跟在后面的回复，只该顶一个时间。
	if thread_messages.is_empty():
		if not thread_date.is_empty():
			_add_date(thread_date, _small_font)
		_add_empty_hint("还没有消息。")
	else:
		var last_time := ""
		for value in thread_messages:
			if not (value is Dictionary):
				continue
			var item := Dictionary(value)
			var text := String(item.get("text", ""))
			if text.is_empty():
				continue
			var t := String(item.get("time", ""))
			if t.is_empty():
				t = thread_date
			if not t.is_empty() and t != last_time:
				_add_date(t, _small_font)
				last_time = t
			_add_bubble(text, String(item.get("speaker", "")) == "我", _body_font)

	_reply_buttons.clear()
	for child in _reply_bar.get_children():
		_reply_bar.remove_child(child)
		child.free()
	var count := reply_options.size()
	# 「先不回」不是一句回复，是退出：中性色按钮，点了不发气泡、也不算回应。
	# 但它现在和回复项排在同一张网格里、一样宽——以前它单占一行整宽，
	# 跟上面那颗短短回复凑成"一长一短"，很难看。
	# 空会话没东西可回，这颗也收起来——右上角的 × 一直都在。
	var show_decline := not decline_label.is_empty() and (count > 0 or not thread_messages.is_empty())
	var total := count + (1 if show_decline else 0)
	# 回复项不超过两颗时两列并排；三颗以上还是整行一颗（文案长，挤半宽会折行）。
	var cols := 2 if count > 0 and count <= 2 else 1
	var rows := 0 if total == 0 else int(ceil(float(total) / float(cols)))
	var gap := 14.0
	var button_w := _thread_width - 32.0
	if cols > 1:
		button_w = (_thread_width - 32.0 - gap) * 0.5
	var reply_h := 16.0
	if total > 0:
		reply_h = 38.0 + float(rows) * (_button_height + 10.0) + 6.0
	_reply_bar.size = Vector2(_thread_width, reply_h)
	_reply_bar.position = Vector2(_screen_left, _screen_bottom - reply_h)
	_reply_bar_wanted = total > 0
	_reply_bar.visible = _reply_bar_wanted
	var thread_top := _header_y + _header_h + 14.0
	_scroll.position = Vector2(_screen_left, thread_top)
	_scroll.size = Vector2(_thread_width, maxf(_reply_bar.position.y - 16.0 - thread_top, 120.0))
	_thread.custom_minimum_size = Vector2(_thread_width - 16, maxf(_scroll.size.y - 16.0, 104.0))

	if count > 0:
		var hint := _label(reply_hint, _small_font, Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.62), false, _thread_width, HORIZONTAL_ALIGNMENT_CENTER)
		hint.position = Vector2(0, 8)
		hint.size = Vector2(_thread_width, _small_font + 12)
		_reply_bar.add_child(hint)

	var slot := 0
	for index in count:
		var option := Dictionary(reply_options[index])
		var label := String(option.get("text", ""))
		var option_id := String(option.get("id", "reply_%d" % index))
		var fill := UI_GREEN
		if index == 1:
			fill = UI_GOLD
		elif index > 1:
			fill = Color("cbb18b")
		var button := _ui_button(label, Vector2(button_w, _button_height), fill, _button_font)
		button.position = _reply_slot_position(slot, cols, button_w, gap)
		button.name = "Reply_%s" % option_id
		button.pressed.connect(_on_reply_pressed.bind(option_id, label))
		_reply_bar.add_child(button)
		_reply_buttons.append(button)
		slot += 1

	if show_decline:
		var decline := _ui_button(decline_label, Vector2(button_w, _button_height), UI_PAPER, _small_font)
		decline.name = "DeclineReplyButton"
		decline.position = _reply_slot_position(slot, cols, button_w, gap)
		decline.pressed.connect(close_phone)
		_reply_bar.add_child(decline)


## 回复栏里第 slot 颗按钮该放哪儿：一行 cols 颗，格子宽度一样。
func _reply_slot_position(slot: int, cols: int, button_w: float, gap: float) -> Vector2:
	var row := int(floor(float(slot) / float(cols)))
	var column := slot % cols
	return Vector2(16.0 + float(column) * (button_w + gap), 38.0 + float(row) * (_button_height + 10.0))

	# 回复栏有没有内容已经定了：该收的收（列表页），该还的还（聊天页）。
	_apply_view()


## 头像：有立绘就裁立绘，没立绘的人用通用头像框 + 姓氏占位。
func _make_avatar() -> Control:
	var box := Control.new()
	box.name = "ContactAvatar"
	box.position = Vector2(_screen_left, _header_y + 10)
	box.size = Vector2(56, 56)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if contact_avatar != null:
		var head := AtlasTexture.new()
		head.atlas = contact_avatar
		head.region = contact_avatar_region
		var sprite := _texture(head, Rect2(0, 0, 56, 56), TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		box.add_child(sprite)
		return box
	var frame := _texture(AVATAR_FRAME, Rect2(0, 0, 56, 56), TextureRect.STRETCH_SCALE)
	box.add_child(frame)
	var initial := _label(contact_name.left(1), 24, Color("5a3a26"), true, 56, HORIZONTAL_ALIGNMENT_CENTER)
	initial.position = Vector2(0, 14)
	initial.size = Vector2(56, 30)
	box.add_child(initial)
	return box


func _build_toast() -> void:
	_toast = Panel.new()
	_toast.name = "Toast"
	_toast.custom_minimum_size = Vector2(360, 52)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -280
	_toast.offset_top = -86
	_toast.offset_right = 280
	_toast.offset_bottom = -34
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_theme_stylebox_override("panel", _pill_style(Color("2b2119"), Color(0, 0, 0, 0.28)))
	_root.add_child(_toast)
	_toast_label = _label("", 18, CREAM, false, 520, HORIZONTAL_ALIGNMENT_CENTER)
	_toast_label.position = Vector2(20, 14)
	_toast_label.size = Vector2(520, 28)
	_toast.add_child(_toast_label)
	_toast.visible = false


# ---------------------------------------------------------------- 组件

func _add_step(parent: VBoxContainer, number: String, title: String, sub: String) -> void:
	var row := Control.new()
	row.custom_minimum_size = Vector2(560, 68)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)

	var box := _texture(CHECK_TEXTURE, Rect2(0, 10, 34, 34), TextureRect.STRETCH_SCALE)
	row.add_child(box)
	var check := _label("✓", 32, RED, true, 40, HORIZONTAL_ALIGNMENT_CENTER)
	check.position = Vector2(-3, 4)
	check.size = Vector2(40, 44)
	check.rotation_degrees = -7
	check.pivot_offset = Vector2(20, 22)
	check.visible = false
	row.add_child(check)
	_step_checks.append(check)

	var title_label := _label("%s %s" % [number, title], 22, INK, true, 490)
	title_label.position = Vector2(54, 0)
	title_label.size = Vector2(490, 30)
	row.add_child(title_label)

	var sub_label := _label(sub, 16, MUTED, false, 490)
	sub_label.position = Vector2(54, 30)
	sub_label.size = Vector2(490, 24)
	row.add_child(sub_label)
	_step_titles.append(title_label)
	_step_subs.append(sub_label)

	var line := ColorRect.new()
	line.color = Color(0.35, 0.24, 0.12, 0.16)
	line.position = Vector2(0, 67)
	line.size = Vector2(560, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)


## 聊天里的时间分隔：居中、半透明纸色小药丸，把对话按剧情时间一段段分开。
func _add_date(text: String, font_size: int = 16) -> void:
	var chip := PanelContainer.new()
	# 一个会话里会有好几个时间药丸；同名会被 Godot 改成 @PanelContainer@xx，
	# 探针和截图脚本就认不出来了。编号起名，谁都能按 "TimeDivider" 前缀找。
	chip.name = "TimeDivider_%d" % _thread.get_child_count()
	chip.custom_minimum_size = Vector2(_thread_width, font_size + 14)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _time_chip_style())
	var label := _label(text, font_size, Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.62), false, _thread_width, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(_thread_width, font_size + 14)
	chip.add_child(label)
	_thread.add_child(chip)


## 时间分隔药丸的底：半透明纸色，圆角，不要边框和阴影，别抢气泡的戏。
func _time_chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UI_PAPER.r, UI_PAPER.g, UI_PAPER.b, 0.5)
	style.set_corner_radius_all(10)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


## 空会话（还没聊过的人）不编假消息，直接说没有。
func _add_empty_hint(text: String) -> void:
	var label := _label(text, _small_font + 2, Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.45), false, _thread_width, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(_thread_width, 92)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_thread.add_child(label)


func _add_bubble(text: String, outgoing: bool, font_size: int = 22) -> void:
	var max_width := _thread_width * 0.78
	var measured := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var width := clampf(measured + 36, 130, max_width)

	var plate := PanelContainer.new()
	plate.name = "Bubble_outgoing" if outgoing else "Bubble_incoming"
	plate.custom_minimum_size = Vector2(width, 0)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_END if outgoing else Control.SIZE_SHRINK_BEGIN
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", _outgoing_bubble_style() if outgoing else _incoming_bubble_style())
	_thread.add_child(plate)

	var label := _label(text, font_size, CREAM if outgoing else UI_INK, false, width - 34)
	label.custom_minimum_size = Vector2(width - 34, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if outgoing else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(label)


func _on_reply_pressed(id: String, text: String) -> void:
	_add_bubble(text, true, _message_font)
	# 会话里也得长这一句：退回列表、下次再点进来，预览和聊天记录才对得上。
	var conv := _find_conversation(_active_id)
	if not conv.is_empty():
		var list: Array = conv.get("messages", [])
		list.append({"speaker": "我", "text": text, "time": thread_date})
		conv["messages"] = list
		conv["reply_options"] = []
		conv["date"] = thread_date
		thread_messages = list.duplicate(true)
	mark_step(2)
	for button in _reply_buttons:
		button.disabled = true
	show_toast("已回复")
	reply_sent.emit(id, text)
	await _scroll_to_latest()


func _on_hud_pressed() -> void:
	if not _tutorial_completed:
		open_tutorial()
	elif _phone_open:
		close_phone()
	else:
		open_phone()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			close_phone()


# ---------------------------------------------------------------- 样式

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color(0.35, 0.24, 0.12, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 16)
	return style


func _soft_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.36)
	style.border_color = Color(0.35, 0.24, 0.12, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style


## 通讯录每一行：有未读的那位纸更亮、描边也重一点，扫一眼就知道谁在等回复。
func _row_style(unread: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.965, 0.885, 0.94) if unread else Color(1, 0.975, 0.9, 0.66)
	style.border_color = Color(UI_WOOD.r, UI_WOOD.g, UI_WOOD.b, 0.30 if unread else 0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.06)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style


func _pill_style(fill: Color, shadow: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(999)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if shadow.a > 0:
		style.shadow_color = shadow
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 6)
	return style


func _chip_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(999)
	return style


func _phone_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.23, 0.16, 0.11, 1)
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(2)
	style.set_corner_radius_all(54)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 34
	style.shadow_offset = Vector2(0, 18)
	return style


func _phone_screen_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(42)
	style.border_color = Color(0.35, 0.24, 0.12, 0.18)
	style.set_border_width_all(1)
	return style


func _avatar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.93, 0.85, 1)
	style.border_color = Color(0.35, 0.24, 0.12, 0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style


func _incoming_bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UI_PAPER.r, UI_PAPER.g, UI_PAPER.b, 0.82)
	style.border_color = Color(UI_WOOD.r, UI_WOOD.g, UI_WOOD.b, 0.18)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.06)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _outgoing_bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI_GREEN
	style.border_color = Color(UI_WOOD.r, UI_WOOD.g, UI_WOOD.b, 0.28)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.10)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


func _reply_bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UI_PAPER.r, UI_PAPER.g, UI_PAPER.b, 0.58)
	style.border_color = Color(UI_WOOD.r, UI_WOOD.g, UI_WOOD.b, 0.18)
	style.border_width_top = 1
	style.set_corner_radius_all(18)
	return style


func _style_primary(button: Button) -> void:
	button.add_theme_font_override("font", _bold(FONT))
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color(1, 0.98, 0.93, 1))
	button.add_theme_stylebox_override("normal", _button_box(Color("2f241a"), 31, Color(0, 0, 0, 0.22)))
	button.add_theme_stylebox_override("hover", _button_box(Color("3d2f22"), 31, Color(0, 0, 0, 0.26)))
	button.add_theme_stylebox_override("pressed", _button_box(Color("241a12"), 31, Color(0, 0, 0, 0.18)))


func _style_chip(button: Button) -> void:
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("4a3626"))
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_disabled_color", Color(0.54, 0.45, 0.35, 0.45))
	button.add_theme_stylebox_override("normal", _button_box(Color(1, 1, 1, 0.55), 24, Color(0, 0, 0, 0), Color(0.35, 0.24, 0.12, 0.25), 1))
	button.add_theme_stylebox_override("hover", _button_box(Color("fff8ea"), 24, Color(0, 0, 0, 0), Color(0.35, 0.24, 0.12, 0.35), 1))
	button.add_theme_stylebox_override("disabled", _button_box(Color(1, 1, 1, 0.22), 24, Color(0, 0, 0, 0), Color(0.35, 0.24, 0.12, 0.10), 1))


func _style_text_button(button: Button, size: int = 19, color: Color = Color("7a5a40")) -> void:
	button.flat = true
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color("4a3626"))
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())


func _button_box(fill: Color, radius: int, shadow: Color, border: Color = Color(0, 0, 0, 0), border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	if shadow.a > 0:
		style.shadow_color = shadow
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 5)
	return style


# ---------------------------------------------------------------- 小工具

func _message_plate_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UI_PAPER.r, UI_PAPER.g, UI_PAPER.b, 0.58)
	style.border_color = Color(UI_INK.r, UI_INK.g, UI_INK.b, 0.10)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _ui_button(text: String, size_value: Vector2, fill: Color, font_size: int = 21) -> Button:
	var button := Button.new()
	button.text = text
	button.size = size_value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", UI_INK)
	button.add_theme_stylebox_override("normal", _ui_button_style(fill))
	button.add_theme_stylebox_override("hover", _ui_button_style(fill.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _ui_button_style(fill.darkened(0.08)))
	button.add_theme_stylebox_override("disabled", _ui_button_style(Color(fill.r, fill.g, fill.b, 0.45)))
	return button


func _ui_button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UI_WOOD
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	return style


func _texture(tex: Texture2D, rect: Rect2, stretch: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED, alpha: float = 1.0) -> TextureRect:
	var node := TextureRect.new()
	node.texture = tex
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = stretch
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.modulate.a = alpha
	return node


func _label(text: String, size: int, color: Color, bold: bool = false, width: float = 0.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _bold(FONT) if bold else FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if width > 0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(width, 0)
		label.size = Vector2(width, 0)
	return label


func _bold(font: Font) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = font
	variation.variation_embolden = 0.55
	return variation


func _bubble_size(text: String, font_size: int, max_width: float) -> Vector2:
	var measured := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var width := clampf(measured.x + 36, 120, max_width)
	var height := 56.0 if measured.y < 28 else 84.0
	return Vector2(width, height)


func _view_size() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2(1920, 1080)
	return vp.get_visible_rect().size


func _compute_phone_size() -> Vector2:
	var vp := _view_size()
	var height := clampf(vp.y - 30.0, 600.0, 1000.0)
	var width := height * 0.70
	var max_width := maxf(vp.x - 80.0, 360.0)
	if width > max_width:
		width = max_width
		height = width / 0.70
	return Vector2(width, height)


func _phone_target_position() -> Vector2:
	var size := _view_size()
	return Vector2(size.x - _phone_size.x - 80, (size.y - _phone_size.y) * 0.5)


func _phone_offscreen_position() -> Vector2:
	var size := _view_size()
	return Vector2(size.x + 40, (size.y - _phone_size.y) * 0.5)
