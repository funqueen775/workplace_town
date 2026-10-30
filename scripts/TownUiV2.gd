class_name TownUiV2
extends CanvasLayer

## 前端界面改造 V1.0(2) 的运行时界面。
## HUD、员工档案和主线任务册使用 assets/ui/rework_v1 的分件；外部数据和信号协议不变。

signal profile_requested
signal task_requested
signal phone_requested
signal calendar_requested
signal task_calendar_requested(target_month: int)
signal settings_requested
signal locate_requested(zone_code: String)
signal advance_requested
signal month_requested(target_month: int)
signal chat_requested(person: String)
signal phone_message_submitted(npc_id: String, message: String)
signal save_requested
signal load_requested
signal title_requested
signal preferences_changed(preferences: Dictionary)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PAPER := Color("fff1d5")
const INK := Color("63301d")
const WOOD := Color("704021")
const GOLD := Color("f4ad25")
const GREEN := Color("5f972f")
const PROFILE_VIEW_SCALE := 1.58
const HUD_ACT := preload("res://assets/ui/rework_v1/hud/components/01_章节栏_无字底板.png")
const HUD_JOB := preload("res://assets/ui/rework_v1/hud/components/02_职位栏_空白底板.png")
const HUD_PORTRAIT := preload("res://assets/ui/rework_v1/hud/components/03_职位栏_小头像框.png")
const HUD_ENERGY := preload("res://assets/ui/rework_v1/hud/components/04_精力条_空白底板.png")
const HUD_HONEY_FULL := preload("res://assets/ui/rework_v1/hud/components/05_蜂蜜罐_满.png")
const HUD_HONEY_EMPTY := preload("res://assets/ui/rework_v1/hud/components/06_蜂蜜罐_空.png")
const HUD_TASK := preload("res://assets/ui/rework_v1/hud/components/07_任务名称_空白小底板.png")
const HUD_VIEW := preload("res://assets/ui/rework_v1/hud/components/09_查看按钮_无字.png")
const HUD_PHONE := preload("res://assets/ui/rework_v1/hud/components/10_手机按钮_无红点.png")
const HUD_CALENDAR := preload("res://assets/ui/rework_v1/hud/components/12_日历_固定图标按钮.png")
const HUD_ADVANCE := preload("res://assets/ui/rework_v1/hud/components/13_推进月份_无字标签.png")
const HUD_TASK_PANEL := preload("res://assets/ui/rework_v1/hud/revisions/03_主线任务空白面板.png")
const HUD_SETTINGS := preload("res://assets/ui/rework_v1/hud/reference_full_v1/08_设置按钮.png")
const HUD_PLAYER_PORTRAITS := {
	"avatar_player": preload("res://assets/ui/rework_v1/profile/components/01_基础面板/玩家头像/00dfdf63-089c-42c3-a216-55528c3a04c7.png"),
	"avatar_xiaoye": preload("res://assets/ui/rework_v1/profile/components/01_基础面板/玩家头像/ce6c3ce3-1671-40c8-a8b2-cd242f7ec842.png"),
	"avatar_yueya": preload("res://assets/ui/rework_v1/profile/components/01_基础面板/玩家头像/10434eda-4aac-4962-82a0-7bce6e0ba11d.png"),
	"avatar_mili": preload("res://assets/ui/rework_v1/profile/components/01_基础面板/玩家头像/6c049b1d-f975-4f82-aa7f-256126192700.png"),
	"avatar_amai": preload("res://assets/ui/rework_v1/profile/components/01_基础面板/玩家头像/710c0b0c-c1ea-4b73-8637-90d53351fea2.png"),
}
const PROFILE_PAGE := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/空白大底板.png")
const PROFILE_TITLE := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/无字标题牌.png")
const PROFILE_PORTRAIT := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/玩家头像框.png")
const PROFILE_CLOSE := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/关闭按钮.png")
const PROFILE_ABILITY := preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力区_空白底板.png")
const PROFILE_PROMOTION_TRACK := preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/晋升进度_底槽.png")
const PROFILE_PROMOTION_FILL := preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/晋升进度_填充.png")
const PROFILE_ABILITY_EMPTY := preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力刻度_空.png")
const PROFILE_ABILITY_COLORS := [
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力刻度_蓝.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力刻度_绿.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力刻度_橙.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力刻度_紫.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力刻度_红.png"),
]
const PROFILE_ABILITY_REGIONS := [
	Rect2(492, 373, 466, 341),
	Rect2(409, 361, 630, 363),
	Rect2(434, 361, 582, 363),
	Rect2(338, 279, 773, 528),
	Rect2(328, 275, 792, 536),
]
const PROFILE_ABILITY_EMPTY_REGION := Rect2(386, 298, 677, 490)
const PROFILE_ABILITY_ICONS := [
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力图标_技术.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力图标_协作.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力图标_表达.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力图标_原则.png"),
	preload("res://assets/ui/rework_v1/profile/components/02_进度与能力/能力图标_抗压.png"),
]
const PROFILE_RELATION := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/人际关系_空白底板.png")
const PROFILE_HEART_EMPTY := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/关系_空爱心.png")
const PROFILE_HEART_FULL := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/关系_实心爱心.png")
const PROFILE_RECOGNITION := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/关系_认可爪印.png")
const PROFILE_NPC_PORTRAITS := {
	"wang_ge": preload("res://assets/ui/rework_v1/profile/components/03_人际关系/王哥头像.png"),
	"xiao_zhao": preload("res://assets/ui/rework_v1/profile/components/03_人际关系/小赵头像.png"),
	"xiao_lin": preload("res://assets/ui/rework_v1/profile/components/03_人际关系/小林头像.png"),
	"lao_zhou": preload("res://assets/ui/rework_v1/profile/components/03_人际关系/老周头像.png"),
}
const TASK_BOOK := preload("res://assets/ui/rework_v1/task_book/01_书本空白底图.png")
const TASK_CLOSE := preload("res://assets/ui/rework_v1/task_book/02_关闭按钮.png")
const TASK_TITLE := preload("res://assets/ui/rework_v1/task_book/03_任务名称底板.png")
const TASK_LOCK_PANEL := preload("res://assets/ui/rework_v1/task_book/04_锁定状态底板.png")
const TASK_LOCK_ICON := preload("res://assets/ui/rework_v1/task_book/05_锁图标_灰白修正版.png")
const TASK_ILLUSTRATION := preload("res://assets/ui/rework_v1/task_book/06_会议插画.png")
const TASK_ILLUSTRATION_FRAME := preload("res://assets/ui/rework_v1/task_book/07_插画相框.png")
const TASK_STORY := preload("res://assets/ui/rework_v1/task_book/08_剧情简介底板.png")
const TASK_INFO := preload("res://assets/ui/rework_v1/task_book/09_信息栏底板.png")
const TASK_CALENDAR_ICON := preload("res://assets/ui/rework_v1/task_book/10_日历图标.png")
const TASK_LOCATION_ICON := preload("res://assets/ui/rework_v1/task_book/11_定位图标.png")
const TASK_PEOPLE_ICON := preload("res://assets/ui/rework_v1/task_book/12_相关人物图标.png")
const TASK_DIVIDER := preload("res://assets/ui/rework_v1/task_book/13_爪印分隔线.png")
const TASK_LEAVES := preload("res://assets/ui/rework_v1/task_book/14_双叶图标.png")
const TASK_CONDITIONS := preload("res://assets/ui/rework_v1/task_book/15_条件空白底板.png")
const TASK_COUNTDOWN := preload("res://assets/ui/rework_v1/task_book/17_倒计时空白底板.png")
const TASK_TRACK := preload("res://assets/ui/rework_v1/task_book/18_追踪按钮底板.png")
const TASK_TRACK_PAW := preload("res://assets/ui/rework_v1/task_book/19_追踪爪印.png")
const TASK_ADVANCE := preload("res://assets/ui/rework_v1/task_book/20_推进按钮底板.png")
const TASK_NOTICE := preload("res://assets/ui/rework_v1/task_book/21_提示感叹号.png")
const TASK_DECORATION := preload("res://assets/ui/rework_v1/task_book/22_页面装饰爪印.png")
const PHONE_FRAME := preload("res://assets/IMG_3984(1).PNG")
const CALENDAR_FRAME := preload("res://assets/IMG_4006(1).PNG")
const SETTINGS_FRAME := preload("res://assets/IMG_4007(1).PNG")
const CALENDAR_MONTHS := [
	preload("res://assets/职业月历/05_第1月_当前.png"), preload("res://assets/职业月历/06_第2月_主线.png"),
	preload("res://assets/职业月历/07_第3月.png"), preload("res://assets/职业月历/08_第4月_约见.png"),
	preload("res://assets/职业月历/09_第5月.png"), preload("res://assets/职业月历/10_第6月_考核.png"),
	preload("res://assets/职业月历/11_第7月.png"), preload("res://assets/职业月历/12_第8月.png"),
	preload("res://assets/职业月历/13_第9月_训练.png"), preload("res://assets/职业月历/14_第10月.png"),
	preload("res://assets/职业月历/15_第11月.png"), preload("res://assets/职业月历/16_第12月.png"),
]
const SETTINGS_MUSIC := preload("res://assets/游戏设置/13_背景音乐滑条.png")
const SETTINGS_SOUND := preload("res://assets/游戏设置/14_游戏音效滑条.png")
const SETTINGS_ON := preload("res://assets/游戏设置/11_开关_开启.png")
const SETTINGS_OFF := preload("res://assets/游戏设置/12_开关_关闭.png")
const SETTINGS_BUTTONS := [
	preload("res://assets/游戏设置/06_保存游戏.png"), preload("res://assets/游戏设置/07_读取存档.png"),
	preload("res://assets/游戏设置/08_返回标题.png"), preload("res://assets/游戏设置/09_应用并关闭.png"),
]
const SETTINGS_BUTTON_REGIONS := [
	Rect2(379, 200, 1378, 331), Rect2(288, 183, 1596, 363),
	Rect2(391, 192, 1390, 355), Rect2(277, 165, 1614, 396),
]
const SETTINGS_PANEL := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/空白大底板.png")
const SETTINGS_TITLE := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/无字标题牌.png")

var _hud: Control
var _act_label: Label
var _job_label: Button
var _energy_label: Label
var _task_title: Label
var _task_meta: Label
var _month_button: Button
var _root: Control
var _view: String = ""
var _energy_panel: Control
var _task_panel: Control
var _phone_button: Button
var _settings_button: Button
var _honey_icons: Array[TextureRect] = []
var _player_portrait: TextureRect
var _phone_tab := "people"
var _phone_payload: Dictionary = {}
var _active_chat_id := ""
var _calendar_year := 0
var _selected_month := 1
var _settings := {"music": 0.65, "sound": 0.7, "text_speed": 1, "large_text": false, "reduced_motion": false, "fullscreen": false}
var _trimmed_textures: Dictionary = {}


func _ready() -> void:
	layer = 140
	_load_settings()
	_build_hud()
	_build_overlay()


func refresh(snapshot: Dictionary, event: Dictionary, energy := 0, energy_max := 3) -> void:
	_layout_hud()
	var month := int(snapshot.get("month", 1))
	_act_label.text = String(event.get("actTitle", "第一幕 · 进入行业"))
	var state := ApiClient.server_state()
	_job_label.text = "当前职位  %s" % _profile_role(int(state.get("level", 1)))
	_energy_label.text = "精力  %d/%d" % [energy, energy_max]
	for index in _honey_icons.size():
		_honey_icons[index].texture = HUD_HONEY_FULL if index < energy else HUD_HONEY_EMPTY
	_month_button.text = "第 %d 月" % month
	if event.is_empty():
		_task_title.text = "主线已完成"
		_task_meta.text = "继续探索小镇"
	else:
		_task_title.text = String(event.get("title", "下一主线"))
		_task_meta.text = "第 %d 月 · %s 区" % [int(event.get("month", month)), String(event.get("locationId", "?"))]


func set_activity_scene_mode(enabled: bool) -> void:
	if _task_panel != null:
		_task_panel.visible = not enabled


func open_view(view: String, payload: Dictionary = {}) -> void:
	_active_chat_id = String(payload.get("chat_id", "")) if view == "phone" else ""
	if view == "calendar" and _view != "calendar":
		_selected_month = int(payload.get("target_month", payload.get("month", 1)))
		_calendar_year = clampi((_selected_month - 1) / 12, 0, 3)
	_view = view
	if view == "profile":
		payload["month"] = int(WorldClock.snapshot().get("month", 1))
	_root.size = get_viewport().get_visible_rect().size
	for child in _root.get_children():
		child.queue_free()
	_root.show()
	var dim := ColorRect.new()
	dim.color = Color(0.10, 0.06, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_view())
	_root.add_child(dim)
	var page := Panel.new()
	if view == "profile":
		page.size = Vector2(760, 670)
		var viewport_size := get_viewport().get_visible_rect().size
		# 预留 HUD 与窗口边缘的安全区，避免高逻辑视口在 16:9 缩放后把标题顶到 HUD、履历贴到底边。
		var available_size := viewport_size - Vector2(48, 72)
		var fit_scale := minf(available_size.x / page.size.x, available_size.y / page.size.y)
		var profile_scale := minf(PROFILE_VIEW_SCALE, fit_scale)
		page.scale = Vector2.ONE * profile_scale
		page.position = (viewport_size - page.size * profile_scale) * 0.5
		page.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	elif view == "task":
		page.size = Vector2(1400, 850)
		var viewport_size := get_viewport().get_visible_rect().size
		var available_size := viewport_size - Vector2(40, 50)
		var task_scale := minf(available_size.x / page.size.x, available_size.y / page.size.y)
		page.scale = Vector2.ONE * task_scale
		page.position = (viewport_size - page.size * task_scale) * 0.5
		page.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		page.size = Vector2(700, 850) if view == "phone" else Vector2(1300, 850) if view == "calendar" else Vector2(750, 870)
		var viewport_size := get_viewport().get_visible_rect().size
		var fit_scale := minf((viewport_size.x - 36) / page.size.x, (viewport_size.y - 40) / page.size.y)
		page.scale = Vector2.ONE * minf(1.0, fit_scale)
		page.position = (viewport_size - page.size * page.scale) * 0.5
		page.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(page)
	var close: BaseButton
	if view == "profile":
		close = _art_button(PROFILE_CLOSE, "", Vector2(692, 18), Vector2(46, 46))
	elif view == "task":
		var task_close := _button("×", Vector2(56, 56), "gold")
		task_close.position = Vector2(1190, 92)
		task_close.add_theme_font_size_override("font_size", 30)
		task_close.z_index = 100
		close = task_close
	else:
		close = _button("×" if view == "phone" else "", Vector2(60, 60), "gold")
		if view != "phone":
			close.flat = true
			close.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		close.position = Vector2(576, 36) if view == "phone" else Vector2(1160, 38) if view == "calendar" else Vector2(634, 30)
	if close.get_child_count() > 0 and close.get_child(0) is CanvasItem:
		(close.get_child(0) as CanvasItem).show_behind_parent = false
	close.pressed.connect(close_view)
	page.add_child(close)
	match view:
		"profile": _build_profile(page, payload)
		"task": _build_task(page, payload)
		"phone": _build_phone(page, payload)
		"calendar": _build_calendar(page, payload)
		"settings": _build_settings(page)
	# 页面内容在关闭按钮之后创建；最后提到顶层，避免书本底图遮住按钮。
	close.move_to_front()

func current_chat_id() -> String:
	return _active_chat_id


func close_view() -> void:
	_view = ""
	_active_chat_id = ""
	_root.hide()


func is_open() -> bool:
	return _root != null and _root.visible


func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud.size = get_viewport().get_visible_rect().size
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)
	var act := _art(HUD_ACT, Vector2(36, 20), Vector2(520, 98), _hud)
	_act_label = _label("第一幕 · 进入行业", 28)
	_act_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_act_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_act_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	act.add_child(_act_label)
	var profile := _art_button(HUD_JOB, "当前职位  实习开发师", Vector2(36, 132), Vector2(440, 96))
	profile.pressed.connect(func(): profile_requested.emit())
	_hud.add_child(profile)
	_job_label = profile
	_art(HUD_PORTRAIT, Vector2(46, 144), Vector2(72, 72), _hud)
	_player_portrait = _art(HUD_PLAYER_PORTRAITS.get(PlayerProfile.get_selected_avatar_id(), HUD_PLAYER_PORTRAITS["avatar_player"]), Vector2(53, 151), Vector2(58, 58), _hud)
	var energy := _art(HUD_ENERGY, Vector2.ZERO, Vector2(440, 98), _hud)
	_energy_panel = energy
	_energy_label = _label("精力  3/3", 28)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.position = Vector2(24, 14)
	_energy_label.size = Vector2(240, 68)
	energy.add_child(_energy_label)
	for index in 3:
		var honey := _art(HUD_HONEY_FULL, Vector2(280 + index * 48, 20), Vector2(42, 48), energy)
		_honey_icons.append(honey)
	var task := Control.new()
	task.size = Vector2(390, 380)
	_task_panel = task
	_hud.add_child(task)
	_art(HUD_TASK_PANEL, Vector2.ZERO, task.size, task)
	var caption := _label("下一主线", 24)
	caption.position = Vector2(50, 38); caption.size = Vector2(270, 40); task.add_child(caption)
	_task_title = _label("第一次被轻视", 31)
	_task_title.position = Vector2(50, 94); _task_title.size = Vector2(290, 82); _task_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; task.add_child(_task_title)
	_task_meta = _label("第 2 月 · A 区", 23)
	_task_meta.position = Vector2(52, 196); _task_meta.size = Vector2(290, 38); task.add_child(_task_meta)
	var check := _art_button(HUD_VIEW, "查看", Vector2(52, 278), Vector2(286, 64))
	check.pressed.connect(func(): task_requested.emit()); task.add_child(check)
	var phone := _art_button(HUD_PHONE, "", Vector2.ZERO, Vector2(104, 104))
	_phone_button = phone
	phone.pressed.connect(func(): phone_requested.emit()); _hud.add_child(phone)
	_month_button = _art_button(HUD_CALENDAR, "", Vector2.ZERO, Vector2(104, 104))
	_month_button.pressed.connect(func(): calendar_requested.emit()); _hud.add_child(_month_button)
	var settings := _art_button(HUD_SETTINGS, "", Vector2.ZERO, Vector2(104, 104))
	_settings_button = settings
	settings.pressed.connect(func(): settings_requested.emit()); _hud.add_child(settings)
	_layout_hud()


func _layout_hud() -> void:
	if _hud == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	_hud.size = viewport_size
	if _energy_panel != null:
		_energy_panel.position = Vector2((viewport_size.x - _energy_panel.size.x) * 0.5, 18)
	if _task_panel != null:
		_task_panel.position = Vector2(viewport_size.x - _task_panel.size.x - 30, 24)
	if _phone_button != null:
		_phone_button.position = Vector2(viewport_size.x - 372, viewport_size.y - 132)
	if _month_button != null:
		_month_button.position = Vector2(viewport_size.x - 248, viewport_size.y - 132)
	if _settings_button != null:
		_settings_button.position = Vector2(viewport_size.x - 124, viewport_size.y - 132)


func _build_overlay() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root.size = get_viewport().get_visible_rect().size
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.hide()
	add_child(_root)


func _build_profile(page: Panel, _payload: Dictionary) -> void:
	var profile := _profile_snapshot()
	_art(PROFILE_PAGE, Vector2(18, 12), Vector2(724, 640), page)
	_art(PROFILE_TITLE, Vector2(256, 34), Vector2(290, 76), page)
	var title := _label("员工档案", 31); title.position = Vector2(286, 41); title.size = Vector2(230, 52); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(title)

	_art(PROFILE_PORTRAIT, Vector2(100, 108), Vector2(154, 150), page)
	_art(HUD_PLAYER_PORTRAITS.get(PlayerProfile.get_selected_avatar_id(), HUD_PLAYER_PORTRAITS["avatar_player"]), Vector2(115, 121), Vector2(124, 122), page)
	var role := _label("当前职位", 18); role.position = Vector2(270, 105); role.size = Vector2(120, 28); page.add_child(role)
	var role_name := _label(String(profile["role"]), 27); role_name.position = Vector2(270, 129); role_name.size = Vector2(280, 44); page.add_child(role_name)
	var assessment_history: Array = profile["assessment_history"]
	var progress_text := "下次晋升检查  第 %d 月" % int(profile["next_review"]) if profile["next_review"] > 0 else "6 个月晋升检查已全部完成"
	if assessment_history.is_empty():
		progress_text = "首次晋升检查：第 6 月（尚未开始）"
	var progress_title := _label(progress_text, 16); progress_title.position = Vector2(271, 172); progress_title.size = Vector2(350, 26); page.add_child(progress_title)
	_art(PROFILE_PROMOTION_TRACK, Vector2(270, 205), Vector2(370, 23), page)
	if int(profile["cycle_elapsed"]) >= 0:
		var fill_mask := Control.new(); fill_mask.position = Vector2(270, 205); fill_mask.size = Vector2(370.0 * float(profile["cycle_elapsed"]) / 6.0, 23); fill_mask.clip_contents = true; fill_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(fill_mask)
		_art(PROFILE_PROMOTION_FILL, Vector2.ZERO, Vector2(370, 23), fill_mask)

	# 两张底板的透明留边不同，按实际可见边界补偿位置与高度，让视觉上下边缘齐平。
	_art(PROFILE_ABILITY, Vector2(95, 238), Vector2(300, 270), page)
	var ability_heading := _label("能力数值", 20); ability_heading.position = Vector2(114, 246); ability_heading.size = Vector2(150, 30); page.add_child(ability_heading)
	var ability_names := ["技术", "协作", "表达", "原则", "抗压"]
	for index in ability_names.size():
		var y := 316 + index * 34
		_art(PROFILE_ABILITY_ICONS[index], Vector2(114, y), Vector2(25, 24), page)
		var ability_name := _label(ability_names[index], 17); ability_name.position = Vector2(145, y - 1); ability_name.size = Vector2(50, 28); page.add_child(ability_name)
		var value := int(profile["abilities"][index])
		for mark in 5:
			var filled := mark < value
			var texture: Texture2D = PROFILE_ABILITY_COLORS[index] if filled else PROFILE_ABILITY_EMPTY
			var region: Rect2 = PROFILE_ABILITY_REGIONS[index] if filled else PROFILE_ABILITY_EMPTY_REGION
			_art(_ability_mark_texture(texture, region), Vector2(202 + mark * 27, y + 4), Vector2(25, 18), page)

	# 关系分件横向透明边更宽，因此保留独立宽度；纵向与能力框严格一致。
	_art(PROFILE_RELATION, Vector2(400, 255), Vector2(270, 260), page)
	var relation_heading := _label("人际关系", 20); relation_heading.position = Vector2(424, 248); relation_heading.size = Vector2(150, 30); page.add_child(relation_heading)
	var npc_names := ["王哥", "小赵", "小林", "老周"]
	var npc_ids := ["wang_ge", "xiao_zhao", "xiao_lin", "lao_zhou"]
	for index in npc_ids.size():
		var y := 303 + index * 45
		var npc_id: String = npc_ids[index]
		_art(PROFILE_NPC_PORTRAITS[npc_id], Vector2(420, y + 4), Vector2(31, 31), page)
		var npc_name := _label(npc_names[index], 16); npc_name.position = Vector2(458, y + 2); npc_name.size = Vector2(46, 20); page.add_child(npc_name)
		var relation_level := int(profile["relations"].get(npc_id, 0))
		var relation_stage := _relation_stage(relation_level)
		if not relation_stage.is_empty():
			var relation_name := _label(relation_stage, 13); relation_name.position = Vector2(496, y + 2); relation_name.size = Vector2(58, 20); page.add_child(relation_name)
		for heart in 5:
			_art(PROFILE_HEART_FULL if heart < relation_level else PROFILE_HEART_EMPTY, Vector2(505 + heart * 25, y + 19), Vector2(21, 20), page)
		if relation_level >= 4:
			_art(PROFILE_RECOGNITION, Vector2(651, y + 9), Vector2(21, 22), page)

func _profile_snapshot() -> Dictionary:
	var snapshot := WorldClock.snapshot()
	var month := int(snapshot.get("month", 1))
	var server: Dictionary = ApiClient.server_state()
	var level := int(server.get("level", 1))
	var ability_levels: Dictionary = server.get("abilityLevels", {})
	var ability_keys := ["technical", "collaboration", "expression", "integrity", "resilience"]
	var abilities: Array[int] = []
	for key in ability_keys:
		abilities.append(clampi(int(ability_levels.get(key, 3)), 1, 5))
	var npc_stages: Dictionary = server.get("npcRelationStage", {})
	var relations := {}
	for npc_id in ["wang_ge", "xiao_zhao", "xiao_lin", "lao_zhou"]:
		var stage := String(npc_stages.get(npc_id, ""))
		relations[npc_id] = clampi(int(stage.trim_prefix("Lv")), 0, 5) if stage.begins_with("Lv") else 0
	var next_review := int(server.get("nextAssessmentMonth", 0))
	if next_review <= 0:
		next_review = 6
	var history: Array = server.get("assessmentHistory", [])
	var cycle_start := ((month - 1) / 6) * 6 + 1
	return {"role": _profile_role(level), "cycle_elapsed": month - cycle_start, "abilities": abilities, "relations": relations, "next_review": next_review, "assessment_history": history}


func _profile_role(level: int) -> String:
	var roles := ["实习开发师", "初级开发师", "开发师", "高级开发师", "项目负责人", "业务负责人", "合伙人"]
	return roles[clampi(level, 1, roles.size()) - 1]


func _relation_stage(level: int) -> String:
	return ["", "熟悉", "信任", "认可", "默契"][clampi(level, 1, 5) - 1]


func _build_task(page: Panel, payload: Dictionary) -> void:
	var event: Dictionary = payload.get("event", {})
	if event.is_empty():
		_build_task_complete(page)
		return

	var snapshot: Dictionary = payload.get("snapshot", WorldClock.snapshot())
	var current_month := int(snapshot.get("month", 1))
	var month := int(event.get("month", current_month))
	var zone := String(event.get("locationId", ""))
	var location := String(event.get("location", "%s 区" % zone))
	var people := _task_people(event)
	var energy := int(payload.get("energy", 0))
	var current_zone := String(payload.get("current_zone", ""))
	var month_ready := current_month >= month
	var location_ready := current_zone == zone
	var energy_ready := energy >= 1
	var months_left := maxi(0, month - current_month)

	_art(TASK_BOOK, Vector2(54, 72), Vector2(1292, 727), page)
	_art(TASK_DECORATION, Vector2(91, 145), Vector2(38, 34), page)
	var heading := _label("主线任务", 34); heading.position = Vector2(390, 126); heading.size = Vector2(270, 62); page.add_child(heading)

	_art(TASK_TITLE, Vector2(204, 195), Vector2(515, 82), page)
	var title := _label(String(event.get("title", "主线任务")), 34)
	title.position = Vector2(240, 204); title.size = Vector2(445, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	page.add_child(title)

	if not month_ready:
		_art(TASK_LOCK_PANEL, Vector2(286, 270), Vector2(350, 54), page)
		_art(TASK_LOCK_ICON, Vector2(325, 280), Vector2(31, 31), page)
		var status := _label("尚未开放", 21); status.position = Vector2(360, 275); status.size = Vector2(220, 42); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(status)

	_art(TASK_ILLUSTRATION, Vector2(212, 326), Vector2(500, 220), page)
	_art(TASK_ILLUSTRATION_FRAME, Vector2(202, 316), Vector2(520, 240), page)
	_art(TASK_STORY, Vector2(202, 552), Vector2(520, 178), page)
	var story_heading := _label("剧情简介", 22); story_heading.position = Vector2(305, 567); story_heading.size = Vector2(160, 35); page.add_child(story_heading)
	var story := RichTextLabel.new()
	story.name = "TaskStoryText"
	story.text = _task_story(event)
	story.position = Vector2(305, 620); story.size = Vector2(345, 78)
	story.add_theme_font_override("normal_font", FONT)
	story.add_theme_font_size_override("normal_font_size", 17)
	story.add_theme_color_override("default_color", INK)
	story.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	story.scroll_active = false
	story.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(story)

	_task_info_row(page, TASK_CALENDAR_ICON, "开放月份", "第%d月" % month, 706, 185)
	_task_info_row(page, TASK_LOCATION_ICON, "地点", location, 706, 254)
	_task_info_row(page, TASK_PEOPLE_ICON, "相关人物", people, 706, 323)
	_art(TASK_DIVIDER, Vector2(704, 382), Vector2(535, 38), page)
	_art(TASK_LEAVES, Vector2(706, 423), Vector2(34, 34), page)
	var condition_heading := _label("开始条件", 27); condition_heading.position = Vector2(751, 416); condition_heading.size = Vector2(200, 46); page.add_child(condition_heading)
	_art(TASK_CONDITIONS, Vector2(670, 329), Vector2(545, 378), page)
	_task_condition(page, "到达第%d月" % month, month_ready, 730, 478)
	_task_condition(page, "前往%s" % location, location_ready, 730, 522)
	_task_condition(page, "精力至少1点", energy_ready, 730, 566)

	_art(TASK_COUNTDOWN, Vector2(704, 642), Vector2(535, 62), page)
	_art(TASK_CALENDAR_ICON, Vector2(730, 655), Vector2(34, 34), page)
	var countdown_text := "任务已到开放月份" if month_ready else "距离开放还有 %d 个月" % months_left
	var countdown := _label(countdown_text, 23); countdown.position = Vector2(776, 650); countdown.size = Vector2(430, 44); countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(countdown)

	var locate := _art_button(TASK_TRACK, "设为追踪", Vector2(704, 714), Vector2(245, 64))
	_art(TASK_TRACK_PAW, Vector2(20, 14), Vector2(34, 34), locate)
	locate.pressed.connect(func(): locate_requested.emit(zone))
	page.add_child(locate)
	var advance_label := "查看职业月历" if month_ready else "推进至第%d月" % month
	var advance := _art_button(TASK_ADVANCE, advance_label, Vector2(968, 714), Vector2(278, 64))
	_art(TASK_CALENDAR_ICON, Vector2(18, 14), Vector2(34, 34), advance)
	advance.pressed.connect(func(): task_calendar_requested.emit(month))
	page.add_child(advance)
	_art(TASK_NOTICE, Vector2(715, 683), Vector2(24, 24), page)
	var notice := _label("推进前会先打开职业月历确认，不会直接跳过月份。", 15); notice.position = Vector2(746, 677); notice.size = Vector2(500, 34); page.add_child(notice)


func _task_info_row(page: Panel, icon: Texture2D, caption: String, value: String, x: float, y: float) -> void:
	_art(icon, Vector2(x, y + 5), Vector2(38, 38), page)
	var caption_label := _label(caption, 19); caption_label.position = Vector2(x + 48, y); caption_label.size = Vector2(116, 48); page.add_child(caption_label)
	_art(TASK_INFO, Vector2(x + 116, y), Vector2(280, 52), page)
	var value_label := _label(value, 20); value_label.position = Vector2(x + 178, y + 1); value_label.size = Vector2(334, 46); value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; page.add_child(value_label)


func _task_condition(page: Panel, text: String, ready: bool, x: float, y: float) -> void:
	var box := Panel.new()
	box.position = Vector2(x, y)
	box.size = Vector2(26, 26)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color("fff8e8")
	box_style.border_color = GREEN if ready else Color("a96a39")
	box_style.set_border_width_all(2)
	box_style.set_corner_radius_all(4)
	box.add_theme_stylebox_override("panel", box_style)
	page.add_child(box)
	if ready:
		var check := _label("✓", 22); check.position = Vector2(x - 1, y - 4); check.size = Vector2(28, 30); check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(check)
	var label := _label(text, 19); label.position = Vector2(x + 43, y - 6); label.size = Vector2(430, 40); page.add_child(label)


func _task_people(event: Dictionary) -> String:
	var names: Array[String] = []
	for value in event.get("cast", []) as Array:
		var name := String(value.get("name", "")) if value is Dictionary else String(value)
		if not name.is_empty() and not names.has(name):
			names.append(name)
	var speakers: Dictionary = event.get("speakers", {})
	for value in speakers.values():
		if value is Dictionary:
			var name := String((value as Dictionary).get("name", ""))
			if not name.is_empty() and not names.has(name):
				names.append(name)
	return "、".join(names) if not names.is_empty() else "独处事件"


func _task_story(event: Dictionary) -> String:
	var story := String(event.get("story", ""))
	if not story.begins_with("表现说明"):
		return story
	var dialogue: Array[String] = []
	for value in event.get("beats", []) as Array:
		if not (value is Dictionary):
			continue
		var beat := value as Dictionary
		var type := String(beat.get("type", ""))
		var text := String(beat.get("text", ""))
		if type == "narration":
			if not text.begins_with("表现说明") and not text.is_empty():
				return text
		elif type == "say" and not text.is_empty() and dialogue.size() < 2:
			dialogue.append(text)
	if not dialogue.is_empty():
		return " ".join(dialogue)
	return String(event.get("prompt", "主线事件将在开放月份到达指定地点后开启。"))


func _build_task_complete(page: Panel) -> void:
	_art(TASK_BOOK, Vector2(54, 72), Vector2(1292, 727), page)
	var heading := _label("主线任务", 34); heading.position = Vector2(132, 126); heading.size = Vector2(270, 62); page.add_child(heading)
	var complete := _label("六幕主线已完成", 38); complete.position = Vector2(390, 330); complete.size = Vector2(620, 80); complete.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(complete)
	var detail := _label("职业旅程已经走到终点。你可以返回小镇，或打开记忆墙回看一路留下的选择。", 22); detail.position = Vector2(390, 420); detail.size = Vector2(620, 110); detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; page.add_child(detail)


func _build_phone(page: Panel, payload: Dictionary) -> void:
	_art(PHONE_FRAME, Vector2.ZERO, page.size, page)
	var heading := _label("小熊手机", 38); heading.position = Vector2(222, 46); heading.size = Vector2(280, 58); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(heading)
	if payload.has("chat_name"):
		var back := _button("返回同事", Vector2(170, 52), "gold"); back.position = Vector2(108, 133); back.pressed.connect(func(): open_view("phone", _phone_payload)); page.add_child(back)
		var name := _label(String(payload["chat_name"]), 31); name.position = Vector2(126, 239); name.size = Vector2(430, 56); page.add_child(name)
		var conversation := ScrollContainer.new(); conversation.position = Vector2(128, 316); conversation.size = Vector2(440, 230); page.add_child(conversation)
		var messages := VBoxContainer.new(); messages.custom_minimum_size.x = 420; messages.add_theme_constant_override("separation", 14); conversation.add_child(messages)
		for entry in payload.get("chat_messages", []) as Array:
			if not entry is Dictionary:
				continue
			var speaker := String(entry.get("speaker", ""))
			if speaker == "npc":
				speaker = String(payload["chat_name"])
			elif speaker == "system":
				speaker = "系统"
			var line := _label(speaker + "：" + String(entry.get("text", "")), 23)
			line.custom_minimum_size.x = 420
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			messages.add_child(line)
		if bool(payload.get("chat_pending", false)):
			messages.add_child(_label("等待回复…", 23))
		var input := LineEdit.new(); input.position = Vector2(128, 574); input.size = Vector2(440, 54); input.placeholder_text = "输入要说的话"; input.max_length = 500; input.add_theme_font_override("font", FONT); input.add_theme_font_size_override("font_size", 21)
		var input_style := _button_style(PAPER); input_style.set_corner_radius_all(6); input_style.set_content_margin_all(10); input.add_theme_stylebox_override("normal", input_style); input.add_theme_stylebox_override("focus", input_style); input.add_theme_color_override("font_color", INK); input.add_theme_color_override("font_placeholder_color", WOOD); page.add_child(input)
		var send := _button("发送", Vector2(172, 54), "green"); send.position = Vector2(262, 645); send.disabled = bool(payload.get("chat_pending", false)); page.add_child(send)
		input.editable = not send.disabled
		var submit := func():
			var words := input.text.strip_edges()
			if not words.is_empty():
				phone_message_submitted.emit(String(payload.get("chat_id", "")), words)
		send.pressed.connect(submit)
		input.text_submitted.connect(func(_text: String): submit.call())
		return
	_phone_payload = payload.duplicate(true)
	for index in 2:
		var tab_id := "people" if index == 0 else "memories"
		var tab := _button("同事" if index == 0 else "记忆", Vector2(196, 52), "gold" if _phone_tab == tab_id else "paper")
		tab.position = Vector2(155 + index * 210, 126)
		tab.pressed.connect(func(): _phone_tab = tab_id; open_view("phone", payload))
		page.add_child(tab)
	var content := ScrollContainer.new()
	content.position = Vector2(90, 200)
	content.size = Vector2(526, 532)
	page.add_child(content)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 505
	list.add_theme_constant_override("separation", 10)
	content.add_child(list)
	if _phone_tab == "memories":
		var memories: Array = payload.get("memories", [])
		if memories.is_empty():
			var empty := _label("还没有留下剧情选择。", 23); list.add_child(empty)
		for memory in memories:
			var entry := _label("第 %d 月  %s\n%s" % [int(memory.get("month", 1)), String(memory.get("title", "往事")), String(memory.get("outcome", ""))], 20)
			entry.custom_minimum_size = Vector2(470, 110); entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(entry)
		return
	var people: Array = payload.get("people", [])
	for item in people:
		var row := _plate(Vector2(490, 112)); row.custom_minimum_size = Vector2(490, 112); list.add_child(row)
		var info := _label("%s   ·   %s 区\n%s" % [String(item.get("name", "同事")), String(item.get("zone", "?")), String(item.get("message", "等你来聊聊。"))], 18)
		info.position = Vector2(16, 5); info.size = Vector2(292, 100); info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; info.max_lines_visible = 3; info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; row.add_child(info)
		var locate := _button("定位", Vector2(142, 46), "gold"); locate.position = Vector2(330, 7); locate.pressed.connect(func(): locate_requested.emit(String(item.get("zone", "")))); row.add_child(locate)
		var chat := _button("聊天", Vector2(142, 46), "green"); chat.position = Vector2(330, 59); chat.pressed.connect(func(): chat_requested.emit(String(item.get("name", "")))); row.add_child(chat)


func _build_calendar(page: Panel, payload: Dictionary) -> void:
	_art(CALENDAR_FRAME, Vector2.ZERO, page.size, page)
	var month := int(payload.get("month", 1))
	var target_month := int(payload.get("target_month", month))
	if _calendar_year < 0 or _calendar_year > 3:
		_calendar_year = clampi((month - 1) / 12, 0, 3)
	var year_start := _calendar_year * 12 + 1
	var header := _label("第 %d 年 · %02d / 48 个月" % [_calendar_year + 1, month], 28); header.position = Vector2(580, 85); header.size = Vector2(530, 50); page.add_child(header)
	for year in 4:
		var tab := _button("第 %d 年" % (year + 1), Vector2(180, 58), "gold" if year == _calendar_year else "paper")
		tab.position = Vector2(74 + year * 193, 162)
		tab.pressed.connect(func(): _calendar_year = year; open_view("calendar", payload))
		page.add_child(tab)
	for index in 12:
		var displayed_month := year_start + index
		var illustrated := _calendar_year == 0 and not ((index == 0 and month != 1) or (index == 1 and month != 2))
		var card := _sprite_button(CALENDAR_MONTHS[index], Vector2(76 + (index % 4) * 190, 239 + (index / 4) * 180), Vector2(168, 166)) if illustrated else _button("", Vector2(168, 166), "paper")
		if not illustrated:
			card.position = Vector2(76 + (index % 4) * 190, 239 + (index / 4) * 180)
			var scenery := AtlasTexture.new()
			scenery.atlas = CALENDAR_MONTHS[2]
			scenery.region = Rect2(200, 510, 850, 505)
			_art(scenery, Vector2(9, 62), Vector2(150, 94), card)
			var month_label := _label("第 %d 月" % displayed_month, 22)
			month_label.position = Vector2(13, 12); month_label.size = Vector2(142, 42); month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(month_label)
		var events: Array = payload.get("events", [])
		for event in events:
			if int(event.get("month", 0)) == displayed_month and not illustrated:
				var marker := _label("主线", 17); marker.position = Vector2(47, 129); marker.size = Vector2(80, 28); marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(marker)
				break
		if displayed_month == month and not illustrated:
			var current := _label("当前", 17); current.position = Vector2(47, 129); current.size = Vector2(80, 28); current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(current)
		if displayed_month == _selected_month:
			card.modulate = Color("fff1ac")
		card.pressed.connect(func(): _selected_month = displayed_month; open_view("calendar", payload))
		page.add_child(card)
	var next := payload.get("next_event", {}) as Dictionary
	var detail := _label("已选择  第 %d 月\n\n%s\n\n%s" % [_selected_month, String(next.get("title", "暂无主线")) if _selected_month == target_month else "", "未完成的主线和活动将被跳过。" if _selected_month > month else "请选择未来月份"], 22)
	detail.position = Vector2(870, 228); detail.size = Vector2(326, 270); detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; page.add_child(detail)
	var next_month := _button("进入下个月", Vector2(290, 54), "gold"); next_month.position = Vector2(882, 534); next_month.disabled = month >= 48; next_month.pressed.connect(func(): month_requested.emit(month + 1)); page.add_child(next_month)
	var advance := _button("推进至第 %d 月" % _selected_month, Vector2(290, 54), "gold"); advance.position = Vector2(882, 606); advance.disabled = _selected_month <= month; advance.pressed.connect(func(): month_requested.emit(_selected_month)); page.add_child(advance)
	var cancel := _button("取消", Vector2(260, 50), "paper"); cancel.position = Vector2(898, 700); cancel.pressed.connect(close_view); page.add_child(cancel)


func _build_settings(page: Panel) -> void:
	_art(SETTINGS_PANEL, Vector2(18, 12), page.size - Vector2(36, 24), page)
	_art(SETTINGS_TITLE, Vector2(210, 30), Vector2(310, 76), page)
	var heading := _label("游戏设置", 37); heading.position = Vector2(245, 85); heading.size = Vector2(260, 56); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(heading)
	var sound_heading := _label("声音", 24); sound_heading.position = Vector2(130, 145); sound_heading.size = Vector2(200, 35); page.add_child(sound_heading)
	_settings_slider(page, "背景音乐", "music", 185, SETTINGS_MUSIC)
	_settings_slider(page, "游戏音效", "sound", 235, SETTINGS_SOUND)
	var reading := _label("显示与阅读", 24); reading.position = Vector2(130, 289); reading.size = Vector2(250, 38); page.add_child(reading)
	_settings_options(page, "文字速度", ["慢", "中", "快"], "text_speed", 334)
	_settings_options(page, "字体大小", ["标准", "大"], "large_text", 388)
	_settings_toggle(page, "减少动态效果", "reduced_motion", 445)
	_settings_toggle(page, "全屏显示", "fullscreen", 499)
	var save_title := _label("存档", 24); save_title.position = Vector2(130, 553); save_title.size = Vector2(160, 35); page.add_child(save_title)
	for index in 4:
		var texture := AtlasTexture.new()
		texture.atlas = SETTINGS_BUTTONS[index]
		texture.region = SETTINGS_BUTTON_REGIONS[index]
		var button := _art_button(texture, "", Vector2(92 + (index % 2) * 287, 595 + (index / 2) * 86), Vector2(252, 70))
		match index:
			0: button.pressed.connect(func(): save_requested.emit())
			1: button.pressed.connect(func(): load_requested.emit())
			2: button.pressed.connect(func(): title_requested.emit())
			3: button.pressed.connect(func(): _apply_settings(); close_view())
		page.add_child(button)


func _settings_slider(page: Panel, title: String, key: String, y: float, texture: Texture2D) -> void:
	var label := _label(title, 20); label.position = Vector2(130, y); label.size = Vector2(165, 42); page.add_child(label)
	_art(texture, Vector2(300, y + 4), Vector2(330, 40), page).modulate.a = 0.35
	var slider := HSlider.new(); slider.position = Vector2(310, y + 6); slider.size = Vector2(300, 36)
	slider.min_value = 0; slider.max_value = 1; slider.step = 0.01; slider.value = float(_settings[key])
	slider.value_changed.connect(func(value): _settings[key] = value; _apply_volume())
	page.add_child(slider)


func _settings_options(page: Panel, title: String, options: Array, key: String, y: float) -> void:
	var label := _label(title, 20); label.position = Vector2(130, y); label.size = Vector2(165, 42); page.add_child(label)
	for index in options.size():
		var selected := (int(_settings[key]) == index) if key == "text_speed" else (bool(_settings[key]) == (index == 1))
		var button := _button(String(options[index]), Vector2(118, 42), "gold" if selected else "paper")
		button.position = Vector2(305 + index * 110, y)
		button.pressed.connect(func(): _settings[key] = index if key == "text_speed" else index == 1; open_view("settings"))
		page.add_child(button)


func _settings_toggle(page: Panel, title: String, key: String, y: float) -> void:
	var label := _label(title, 20); label.position = Vector2(130, y); label.size = Vector2(245, 42); page.add_child(label)
	var toggle := _sprite_button(SETTINGS_ON if bool(_settings[key]) else SETTINGS_OFF, Vector2(335, y), Vector2(92, 42))
	toggle.pressed.connect(func(): _settings[key] = not bool(_settings[key]); open_view("settings"))
	page.add_child(toggle)


func _apply_volume() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_volume_linear(master, float(_settings["sound"]))
	var music := AudioServer.get_bus_index("Music")
	if music >= 0:
		AudioManager.set_volume_linear(float(_settings["music"]))


func _apply_settings() -> void:
	_apply_volume()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(_settings["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED)
	var config := ConfigFile.new()
	for key in _settings:
		config.set_value("display", key, _settings[key])
	config.save("user://town_ui_settings.cfg")
	preferences_changed.emit(_settings.duplicate())


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://town_ui_settings.cfg") == OK:
		for key in _settings:
			_settings[key] = config.get_value("display", key, _settings[key])
	_apply_volume()
	preferences_changed.emit(_settings.duplicate())


func preferences() -> Dictionary:
	return _settings.duplicate()


func _title(page: Panel, value: String) -> void:
	var label := _label(value, 46); label.position = Vector2(70, 48); label.size = Vector2(760, 68); page.add_child(label)


func _section(page: Panel, value: String, at: Vector2) -> void:
	var label := _label(value, 28); label.position = at; label.size = Vector2(450, 44); page.add_child(label)


func _plate(size_value: Vector2) -> Panel:
	var panel := Panel.new(); panel.size = size_value; panel.add_theme_stylebox_override("panel", _panel_style()); return panel


func _button(value: String, size_value: Vector2, kind: String) -> Button:
	var button := Button.new(); button.text = value; button.size = size_value; button.add_theme_font_override("font", FONT); button.add_theme_font_size_override("font_size", 21); button.add_theme_color_override("font_color", INK); button.add_theme_stylebox_override("normal", _button_style(GOLD if kind == "gold" else GREEN if kind == "green" else PAPER)); return button


func _label(value: String, font_size: int) -> Label:
	var label := Label.new(); label.text = value; label.add_theme_font_override("font", FONT); label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", INK); label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; return label


func _art(texture: Texture2D, at: Vector2, size_value: Vector2, parent: Control) -> TextureRect:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.position = at
	art.size = size_value
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art


func _art_button(texture: Texture2D, value: String, at: Vector2, size_value: Vector2) -> Button:
	var button := _button(value, size_value, "paper")
	button.position = at
	button.flat = true
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var art := _art(texture, Vector2.ZERO, size_value, button)
	art.show_behind_parent = true
	return button


func _sprite_button(texture: Texture2D, at: Vector2, size_value: Vector2) -> Button:
	if not _trimmed_textures.has(texture):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = texture.get_image().get_used_rect()
		_trimmed_textures[texture] = atlas
	return _art_button(_trimmed_textures[texture], "", at, size_value)


func _ability_mark_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	if not _trimmed_textures.has(texture):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		_trimmed_textures[texture] = atlas
	return _trimmed_textures[texture]


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(PAPER, 0.96); style.border_color = WOOD; style.set_border_width_all(5); style.set_corner_radius_all(18); style.shadow_color = Color(0, 0, 0, 0.38); style.shadow_size = 18; return style


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = WOOD; style.set_border_width_all(3); style.set_corner_radius_all(14); return style
