class_name TownUiV2
extends CanvasLayer

## 前端界面改造 V1.0(2) 的运行时界面。
## HUD、员工档案和主线任务册使用 assets/ui/rework_v1 的分件；外部数据和信号协议不变。

signal profile_requested
signal memory_wall_requested
signal standing_requested
signal task_requested
signal phone_requested
signal manual_requested
signal settings_requested
signal locate_requested(zone_code: String)
signal advance_requested
signal month_requested(target_month: int)
signal chat_requested(person: String)
signal phone_message_submitted(npc_id: String, message: String)
## 12 个月首月手机：固定回复选项（回一句 → 二选一），不走自由输入。
## 任何一个整页关掉时发一次：月末卡要趁这一步回到前台。
signal view_closed
signal phone_reply_selected(chat_id: String, reply_id: String, reply_text: String)
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
const HUD_PIN := preload("res://assets/ui/rework_v1/hud/components/08_任务_定位图标.png")
const HUD_VIEW := preload("res://assets/ui/rework_v1/hud/components/09_查看按钮_无字.png")
## 圆钮原来有五件（手机/月历/手册/档案/设置），统一重切过：同一张 1280 画布、牌面直径都是 1000，
## 放进 104 的槽里牌面一样大（原来的图留白和叶片外扩各不相同，直接摆会一大一小）。
## 月历 2026-10-29 撤下；档案同日撤下——它没有独有的内容，岗位、能力、人际、记忆墙、处境
## 全从左上角那条岗位栏进，右下角不再占一颗钮。屏幕上现在只有手册/手机/设置三颗。
const HUD_PHONE := preload("res://assets/ui/rework_v1/hud/components/16_圆钮统一_phone.png")
## 手册圆钮：与手机同一套画法（米色圆牌 + 木边 + 走线虚圈 + 左下两片叶）。
## 以前手册是代码画的深底白字圆，跟手机那颗完全不像，一排摆在一起像两套 UI。
const HUD_MANUAL := preload("res://assets/ui/rework_v1/hud/components/16_圆钮统一_manual.png")
## 档案圆钮：把原来那两颗没有字的深色圆钮（记忆墙 / 你的处境）收进来。
## 圆钮本体 2026-10-30 撤下（玩家：入口改点左上角岗位栏），这张图只剩讲解卡在用。
const HUD_ADVANCE := preload("res://assets/ui/rework_v1/hud/components/13_推进月份_无字标签.png")
const HUD_TASK_PANEL := preload("res://assets/ui/rework_v1/hud/revisions/03_主线任务空白面板.png")
const HUD_SETTINGS := preload("res://assets/ui/rework_v1/hud/components/16_圆钮统一_settings.png")
## 牌面直径（1280 画布上按不透明像素最宽一条量出来的）：手册 844、手机 993、月历 1001、设置 975。
## 槽位都是 104，图里的留白却不一样，直接摆会一大一小；
## 按 1001 对齐，整张图（连叶片）一起缩放，几颗看起来一样大。
const HUD_PLATE_TARGET := 1001.0
const HUD_PLATE_DIAMETER := {
	"manual": 844.0,
	"phone": 993.0,
	"month": 1001.0,
	"settings": 975.0,
}
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

## 档案页那五排格子的读数来源，由城镇在建树时挂进来
## （WorkplaceTown.ability_display_levels：起点 + 攒点 + 剧情点亮到顶）。
## 没挂上就退回旧的下线读法，不挡着别的界面用。
var ability_source := Callable()
## 档案页"留下的材料"：由城镇按已经发生过的旗标给，空数组就写"还没有"。
var material_source := Callable()

var _hud: Control
var _act_label: Label
## 左上角日期栏：第几月 / 上中下旬 / 白天夜晚，三格各站各位，谁变了谁动。
var _date_mode := false
var _date_month_cell: Label
var _date_xun_cell: Label
var _date_band_cell: Label
var _date_separators: Array[Label] = []
var _job_label: Button
## 岗位栏下面那一行处境读数：稳定时不出现，被观察起才亮字（原来是档案圆钮上的那颗点）。
var _standing_line: Label
var _energy_label: Label
var _task_title: Label
var _task_meta: Label
var _task_note: Label
var _task_caption: Label
var _root: Control
var _view: String = ""
var _energy_panel: Control
var _task_panel: Control
var _phone_button: Button
var _phone_dot: Panel
var _manual_button: Button
var _manual_dot: Panel
var _view_button: Button
var _settings_button: Button
var _honey_icons: Array[TextureRect] = []
var _player_portrait: TextureRect
var _phone_tab := "people"
var _phone_payload: Dictionary = {}
var _active_chat_id := ""
var _settings := {"music": 0.65, "sound": 0.7, "text_speed": 1, "large_text": false, "reduced_motion": false, "cutscenes": 0, "fullscreen": false}
## 数值型设置项：选中态按「等于第几档」判，不是按真假判。
const SETTINGS_INT_KEYS := ["text_speed", "cutscenes"]
var _trimmed_textures: Dictionary = {}


func _ready() -> void:
	layer = 140
	_load_settings()
	_build_hud()
	_build_overlay()
	get_viewport().size_changed.connect(_layout_hud)


## update_card：要不要顺手把右上角那张「本月主线」卡刷回 WorldClock 的主线。
## 十二个月流程下卡片归剧情这边写（自由安排会写「还剩几格」），
## 心情一变就重画那罐蜂蜜时若还刷卡片，标题会被打回 WorldClock 的旧主线，
## 于是出现「标题写着新员工手册、第三行却写着还剩 1 格」这种半新半旧的卡。
func refresh(snapshot: Dictionary, event: Dictionary, energy := 0, energy_max := 3, energy_caption := "精力", update_card := true) -> void:
	_layout_hud()
	var month := int(snapshot.get("month", 1))
	# 十二个月流程下左上角那格是日期栏，不再回写幕名，否则会把「第几月」刷掉。
	if not _date_mode:
		_act_label.text = String(event.get("actTitle", "第一幕 · 进入行业"))
	var state := ApiClient.server_state()
	_job_label.text = "当前职位  %s" % _profile_role(int(state.get("level", 1)))
	_energy_label.text = "%s  %d/%d" % [energy_caption, energy, energy_max]
	var lit := int(round(float(energy) / maxf(1.0, float(energy_max)) * float(_honey_icons.size())))
	for index in _honey_icons.size():
		_honey_icons[index].texture = HUD_HONEY_FULL if index < lit else HUD_HONEY_EMPTY
	if not update_card:
		return
	if event.is_empty():
		set_task_card("主线已完成", "继续探索小镇")
	else:
		set_task_card(String(event.get("title", "下一主线")),
			"第 %d 月 · %s 区" % [int(event.get("month", month)), String(event.get("locationId", "?"))])


func open_view(view: String, payload: Dictionary = {}) -> void:
	_active_chat_id = String(payload.get("chat_id", "")) if view == "phone" else ""
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
		page.size = Vector2(700, 850) if view == "phone" else Vector2(750, 870)
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
		close.position = Vector2(576, 36) if view == "phone" else Vector2(634, 30)
	if close.get_child_count() > 0 and close.get_child(0) is CanvasItem:
		(close.get_child(0) as CanvasItem).show_behind_parent = false
	close.pressed.connect(close_view)
	page.add_child(close)
	match view:
		"profile": _build_profile(page, payload)
		"task": _build_task(page, payload)
		"phone": _build_phone(page, payload)
		"settings": _build_settings(page)
	# 页面内容在关闭按钮之后创建；最后提到顶层，避免书本底图遮住按钮。
	close.move_to_front()

func current_chat_id() -> String:
	return _active_chat_id


func close_view() -> void:
	_view = ""
	_active_chat_id = ""
	_root.hide()
	view_closed.emit()


func is_open() -> bool:
	return _root != null and _root.visible


func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud.size = get_viewport().get_visible_rect().size
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)
	# 日期栏：不用那张底板了（它自带的褐色木边 / 叶片裁不干净）。
	# 直接画一块米色纸牌，边线用比纸略深的米色，整条没有褐色。
	var act := Panel.new()
	act.name = "DatePlate"
	act.position = Vector2(36, 14)
	act.size = Vector2(520, 116)
	act.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color("f6e6bd")
	plate_style.border_color = Color("e6cf9e")
	plate_style.set_border_width_all(2)
	plate_style.set_corner_radius_all(16)
	act.add_theme_stylebox_override("panel", plate_style)
	_hud.add_child(act)
	_act_label = _label("第一幕 · 进入行业", 28)
	_act_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_act_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_act_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	act.add_child(_act_label)
	_build_date_cells(act)
	# 左上这条岗位栏就是档案入口（2026-10-30 玩家定）：右下角那颗圆钮撤掉，点这里翻档案。
	# 开局就能点，不设解锁；处境那行字单独挂在它下面，点了同样开档案。
	var profile := _art_button(HUD_JOB, "当前职位  实习开发师", Vector2(36, 146), Vector2(440, 96))
	profile.mouse_filter = Control.MOUSE_FILTER_STOP
	profile.focus_mode = Control.FOCUS_NONE
	profile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	profile.pressed.connect(func(): profile_requested.emit())
	# 牌面是张图，没有按钮样式的 hover，只能靠一点点提亮告诉玩家这里能点。
	profile.mouse_entered.connect(func(): profile.modulate = Color(1.06, 1.03, 0.99))
	profile.mouse_exited.connect(func(): profile.modulate = Color.WHITE)
	_hud.add_child(profile)
	_job_label = profile
	# 处境警示从"档案钮上一颗点"改成"岗位栏底下一行字"：点没了，提醒还得留着，
	# 而且字比点诚实——被观察还是要危急，玩家一眼看到的是那句人话。
	# 稳定（或还没跟后台上账）时这一行根本不出现，左上角保持日期 + 岗位两条。
	_standing_line = _label("", 20)
	_standing_line.position = Vector2(58, 248)
	_standing_line.size = Vector2(392, 30)
	_standing_line.add_theme_color_override("font_color", Color("e0a63c"))
	_standing_line.add_theme_color_override("font_outline_color", Color("2a1c10"))
	_standing_line.add_theme_constant_override("outline_size", 5)
	_standing_line.mouse_filter = Control.MOUSE_FILTER_STOP
	_standing_line.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_standing_line.gui_input.connect(_on_standing_line_input)
	_standing_line.hide()
	_hud.add_child(_standing_line)
	_art(HUD_PORTRAIT, Vector2(46, 158), Vector2(72, 72), _hud)
	_player_portrait = _art(HUD_PLAYER_PORTRAITS.get(PlayerProfile.get_selected_avatar_id(), HUD_PLAYER_PORTRAITS["avatar_player"]), Vector2(53, 165), Vector2(58, 58), _hud)
	var energy := _art(HUD_ENERGY, Vector2.ZERO, Vector2(440, 98), _hud)
	_energy_panel = energy
	_energy_label = _label("心情  6/6", 28)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.position = Vector2(24, 14)
	_energy_label.size = Vector2(220, 68)
	energy.add_child(_energy_label)
	# 六罐：十二个月的心情账本就是 0–6（4.15 第 2 本账），一罐一格。
	# 旧 48 个月那条线只有 3 点，按比例点亮，不会出现"三罐空三罐"的假满格。
	# 起点 238、间距 30：底板内沿到 425 就收口，原来 250 + 32 排下来第六罐会骑到右边木边上。
	for index in 6:
		var honey := _art(HUD_HONEY_FULL, Vector2(238 + index * 30, 26), Vector2(28, 34), energy)
		_honey_icons.append(honey)
	var task := Control.new()
	task.size = Vector2(390, 380)
	_task_panel = task
	_hud.add_child(task)
	_art(HUD_TASK_PANEL, Vector2.ZERO, task.size, task)
	# 面板是张 1254 见方的空白纸：虚线内框归一化后约 左 0.116 / 右 0.885 / 上 0.088 / 下 0.913，
	# 落到 390×380 上就是 x 45..345、y 33..347。下面四行全部按这个内框排，
	# 不再出现"标题飘在纸上、下面一大片空"。
	# 起点 104 是给左上角那条红丝带让位：丝带压在 x 55..95，字从它右边开始。
	var caption := _label("本月主线", 30)
	caption.position = Vector2(104, 38); caption.size = Vector2(216, 40); task.add_child(caption)
	_task_caption = caption
	# 标题底下一条圆角暖黄条，与交付稿同一层结构（标题压在条上，不直接落纸）。
	_art(HUD_TASK, Vector2(44, 84), Vector2(302, 82), task)
	_task_title = _label("第一次被轻视", 31)
	_task_title.position = Vector2(54, 96); _task_title.size = Vector2(282, 60)
	_task_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_task_title.clip_text = true
	_task_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	task.add_child(_task_title)
	_art(HUD_PIN, Vector2(56, 188), Vector2(32, 32), task)
	_task_meta = _label("第 2 月 · A 区", 28)
	_task_meta.position = Vector2(96, 186); _task_meta.size = Vector2(250, 36)
	_task_meta.clip_text = true; _task_meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	task.add_child(_task_meta)
	# 第三行：这个月自己的时间还剩多少 / 没有时间安排时说什么。
	_task_note = _label("", 22)
	_task_note.position = Vector2(56, 228); _task_note.size = Vector2(290, 34)
	_task_note.add_theme_color_override("font_color", Color("8a4a2e"))
	_task_note.clip_text = true; _task_note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	task.add_child(_task_note)
	var check := _art_button(HUD_VIEW, "查看", Vector2(52, 278), Vector2(286, 64))
	_view_button = check
	check.pressed.connect(func(): task_requested.emit()); task.add_child(check)
	var phone := _hud_round_button(HUD_PHONE, "phone")
	_phone_button = phone
	phone.pressed.connect(func(): phone_requested.emit()); _hud.add_child(phone)
	# 12 个月流程：手机等第一条消息到达后再出现，并亮红点提醒。
	phone.visible = false
	var settings := _hud_round_button(HUD_SETTINGS, "settings")
	_settings_button = settings
	settings.pressed.connect(func(): settings_requested.emit()); _hud.add_child(settings)
	# 手册入口：首月工位流程后出现。图上已经画好一本合上的手册，不再叠字。
	_manual_button = _hud_round_button(HUD_MANUAL, "manual")
	_manual_button.pressed.connect(func(): manual_requested.emit())
	_hud.add_child(_manual_button)
	_manual_button.visible = false
	# 纯图标按钮必须带字：手机/手册/设置只靠图标，玩家猜不出来。
	_hud_caption(phone, "手机")
	_hud_caption(_manual_button, "手册")
	_hud_caption(settings, "设置")
	_layout_hud()


## 左上角日期栏的三格。底板图不动，只在里面排三段独立 Label：
## 谁变了谁动、没变的原地不动，玩家眼角一扫就知道时间走到哪了。
func _build_date_cells(banner: Control) -> void:
	# 底板右端自带一枚爪印装饰（约在 420 之后），三格文字必须收在 410 以内，
	# 否则「白天」两个字会压在爪印上（2026-10-27 实机反馈）。
	# 底板本身不再往高里拉（拉到 120 会从透明边后面露出别的层），
	# 靠把字加大、三格撑满纸带来"看起来更高"。
	_date_month_cell = _date_cell("第一月", 36, Vector2(48, 34), Vector2(124, 48), banner)
	_date_xun_cell = _date_cell("上旬", 36, Vector2(188, 34), Vector2(100, 48), banner)
	_date_band_cell = _date_cell("白天", 32, Vector2(306, 36), Vector2(100, 44), banner)
	_date_separators.append(_date_cell("·", 32, Vector2(168, 34), Vector2(22, 48), banner))
	_date_separators.append(_date_cell("·", 32, Vector2(284, 34), Vector2(22, 48), banner))
	for cell in [_date_month_cell, _date_xun_cell, _date_band_cell] + _date_separators:
		cell.visible = false


func _date_cell(text: String, font_size: int, at: Vector2, size_value: Vector2, parent: Control) -> Label:
	var label := _label(text, font_size)
	label.position = at
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


## 静默写入三格（开局那一拍用，不播过场）。
func set_date(month: int, xun: String, band: String) -> void:
	if _date_month_cell == null:
		return
	_date_mode = true
	_act_label.visible = false
	_date_month_cell.text = month_text(month)
	_date_xun_cell.text = xun
	_date_band_cell.text = band
	for cell in [_date_month_cell, _date_xun_cell, _date_band_cell] + _date_separators:
		cell.visible = true
		cell.modulate.a = 1.0
		cell.rotation_degrees = 0.0
		cell.scale = Vector2.ONE


func date_month_cell() -> Label:
	return _date_month_cell


func date_xun_cell() -> Label:
	return _date_xun_cell


func date_band_cell() -> Label:
	return _date_band_cell


func month_text(month: int) -> String:
	var digits := ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
	if month >= 1 and month <= digits.size():
		return "第%s月" % digits[month - 1]
	return "第 %d 月" % month


func _layout_hud() -> void:
	if _hud == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	_hud.size = viewport_size
	if _energy_panel != null:
		_energy_panel.position = Vector2((viewport_size.x - _energy_panel.size.x) * 0.5, 18)
	if _task_panel != null:
		_task_panel.position = Vector2(viewport_size.x - _task_panel.size.x - 30, 24)
	_layout_bottom_buttons(viewport_size)


## 只给当前可见的图标排槽，按钮组贴右侧，隐藏入口不再留下空位。
func _layout_bottom_buttons(viewport_size: Vector2) -> void:
	var buttons: Array[Button] = []
	for button in [_manual_button, _phone_button, _settings_button]:
		if button != null and button.visible:
			buttons.append(button)
	if buttons.is_empty():
		return
	var gap := 6.0
	var right_margin := 12.0
	var button_width := 104.0
	var row_width := buttons.size() * button_width + (buttons.size() - 1) * gap
	var x := viewport_size.x - right_margin - row_width
	var y := viewport_size.y - 132.0
	for button in buttons:
		button.position = Vector2(x, y)
		x += button_width + gap


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
	var progress_text := "下次评估：第 %d 月" % int(profile["next_review"]) if profile["next_review"] > 0 else "阶段评估均已完成"
	if assessment_history.is_empty():
		progress_text = "首次评估：第 6 月转正（尚未开始）"
	var progress_title := _label(progress_text, 16); progress_title.position = Vector2(271, 168); progress_title.size = Vector2(350, 21); page.add_child(progress_title)
	var assessment_note := _label("6月转正看岗位要求；12月晋升看独立负责、不看加班", 13)
	assessment_note.position = Vector2(271, 189); assessment_note.size = Vector2(350, 16); page.add_child(assessment_note)
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

	# 留下的材料：只列真的发生过的。现在有旗标的只有小工具和交接文档，
	# 评测表 / 署名纪要还没旗标——不在这里编一个"看起来有"的名字。
	var materials: Array = material_source.call() if material_source.is_valid() else []
	var material_text := "留下的材料：" + ("、".join(PackedStringArray(materials)) if not materials.is_empty() else "还没有")
	var material_label := _label(material_text, 14)
	material_label.position = Vector2(95, 511)
	material_label.size = Vector2(580, 20)
	page.add_child(material_label)

	# 底部两个入口：原来挂在地图右上角那两颗没有字的深色圆钮上，玩家猜不出来。
	# 现在收进档案页，名字直接写在按钮上。
	var wall := _button("记忆墙 · 攒下的便签", Vector2(285, 62), "paper")
	wall.position = Vector2(95, 534); wall.add_theme_font_size_override("font_size", 19)
	wall.pressed.connect(func():
		close_view()
		memory_wall_requested.emit())
	page.add_child(wall)
	var standing := _button("你的处境 · 站在哪里", Vector2(270, 62), "paper")
	standing.position = Vector2(400, 534); standing.add_theme_font_size_override("font_size", 19)
	standing.pressed.connect(func():
		close_view()
		standing_requested.emit())
	page.add_child(standing)

func _profile_snapshot() -> Dictionary:
	var snapshot := WorldClock.snapshot()
	var month := int(snapshot.get("month", 1))
	var server: Dictionary = ApiClient.server_state()
	var level := int(server.get("level", 1))
	var ability_levels: Dictionary = server.get("abilityLevels", {})
	var abilities: Array[int] = []
	if ability_source.is_valid():
		# 城镇自己那本账（起点 + 攒点 + 剧情点亮到顶），见 WorkplaceTown.ability_display_levels。
		# 没连后端时档案页也照它画，不再退回一个假的"半熟手"。
		abilities = ability_source.call()
	else:
		# 没连后端时按"第一天入职"的起点画，别假装半熟手（与后端基线同一份数）。
		var ability_baseline := {"technical": 1, "collaboration": 1, "expression": 1, "integrity": 2, "resilience": 1}
		var ability_keys := ["technical", "collaboration", "expression", "integrity", "resilience"]
		for key in ability_keys:
			abilities.append(clampi(int(ability_levels.get(key, ability_baseline[key])), 1, 5))
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
	var current_zone := String(payload.get("current_zone", ""))
	var month_ready := current_month >= month
	var location_ready := current_zone == zone
	var day := int(event.get("day", 1))
	var hour := int(event.get("hour", 9))
	var time_ready := bool(payload.get(
		"story_time_ready",
		not WorldClock.running and int(snapshot.get("worldMinute", 0)) >= (((month - 1) * 30 + (day - 1)) * 24 + hour) * 60
	))
	var activity_window_active := bool(payload.get("activity_window_active", false))
	var month12_active := bool(payload.get("month12_active", false))
	var month12_phase := String(payload.get("month12_phase", ""))
	var month12_step := _month12_task_step(month12_phase) if month12_active else {}
	var months_left := maxi(0, month - current_month)

	_art(TASK_BOOK, Vector2(54, 72), Vector2(1292, 727), page)
	_art(TASK_DECORATION, Vector2(91, 145), Vector2(38, 34), page)
	var heading := _label("主线任务", 32); heading.position = Vector2(390, 126); heading.size = Vector2(270, 62); page.add_child(heading)

	_task_surface(page, Vector2(224, 195), Vector2(475, 82), Color("fff7e7"), Color("dfad72"), 18)
	var title := _label(String(event.get("title", "主线任务")), 31)
	title.position = Vector2(245, 204); title.size = Vector2(433, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	page.add_child(title)

	if not month_ready:
		_task_surface(page, Vector2(286, 270), Vector2(350, 54), Color("f5ead4"), Color("d6b88d"), 14)
		_art(TASK_LOCK_ICON, Vector2(325, 280), Vector2(31, 31), page)
		var status := _label("尚未开放", 21); status.position = Vector2(360, 275); status.size = Vector2(220, 42); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(status)

	_art(TASK_ILLUSTRATION, Vector2(194, 326), Vector2(480, 220), page)
	_art(TASK_ILLUSTRATION_FRAME, Vector2(184, 316), Vector2(500, 240), page)
	_task_surface(page, Vector2(230, 552), Vector2(430, 178), Color("fff8eb"), Color("e4bd8d"), 16)
	var story_heading := _label("剧情简介", 21); story_heading.position = Vector2(270, 565); story_heading.size = Vector2(180, 35); page.add_child(story_heading)
	var story := RichTextLabel.new()
	story.name = "TaskStoryText"
	story.text = _task_story(event)
	story.position = Vector2(270, 608); story.size = Vector2(345, 105)
	story.add_theme_font_override("normal_font", FONT)
	story.add_theme_font_size_override("normal_font_size", 16)
	story.add_theme_color_override("default_color", INK)
	story.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	story.scroll_active = false
	story.clip_contents = true
	story.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(story)

	_task_info_row(page, TASK_CALENDAR_ICON, "开放月份", "第%d月" % month, 706, 185)
	_task_info_row(page, TASK_LOCATION_ICON, "地点", location, 706, 254)
	_task_info_row(page, TASK_PEOPLE_ICON, "相关人物", people, 706, 323)
	var divider := ColorRect.new(); divider.position = Vector2(704, 382); divider.size = Vector2(535, 2); divider.color = Color("dfbd91"); divider.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(divider)
	var condition_heading := _label("当前流程" if month12_active else "触发条件", 23); condition_heading.position = Vector2(720, 389); condition_heading.size = Vector2(220, 35); page.add_child(condition_heading)
	_task_surface(page, Vector2(720, 428), Vector2(430, 145), Color("fff8eb"), Color("e4bd8d"), 18)
	if month12_active:
		_task_condition(page, String(month12_step.get("title", "按当前任务提示继续")), bool(month12_step.get("done", false)), 746, 446)
		var step_detail := _label(String(month12_step.get("detail", "完成当前步骤后，首月流程会继续。")), 15)
		step_detail.position = Vector2(786, 486); step_detail.size = Vector2(340, 42)
		step_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(step_detail)
	else:
		_task_condition(page, "到达剧情时点（第%d月 %02d日 %02d:00）" % [month, day, hour], time_ready, 746, 434)
		_task_condition(page, "前往%s" % location, location_ready, 746, 476)
		_task_condition(page, "当前无进行中的自由活动", not activity_window_active, 746, 518)

	_task_surface(page, Vector2(720, 579), Vector2(430, 42), Color("f7ecd8"), Color("e0c39c"), 14)
	_art(TASK_CALENDAR_ICON, Vector2(740, 586), Vector2(28, 28), page)
	var countdown_text := ""
	if month12_active:
		countdown_text = "首月流程已完成" if bool(month12_step.get("done", false)) else "首月引导 · %s" % String(month12_step.get("short", "按当前任务继续"))
	elif time_ready and activity_window_active:
		countdown_text = "已到剧情时点 · 完成自由活动后触发"
	elif time_ready and not location_ready:
		countdown_text = "已到剧情时点 · 前往%s" % location
	elif time_ready:
		countdown_text = "剧情触发条件已满足"
	elif month_ready:
		countdown_text = "剧情时点：第%d月 %02d日 %02d:00" % [month, day, hour]
	else:
		countdown_text = "距开放还有%d个月 · %02d日 %02d:00" % [months_left, day, hour]
	var countdown := _label(countdown_text, 19); countdown.position = Vector2(777, 580); countdown.size = Vector2(345, 40); page.add_child(countdown)

	var locate := _task_action_button("设为追踪", Vector2(720, 661), Vector2(215, 52), false)
	_art(TASK_TRACK_PAW, Vector2(20, 14), Vector2(34, 34), locate)
	locate.pressed.connect(func(): locate_requested.emit(zone))
	page.add_child(locate)



func _month12_task_step(phase: String) -> Dictionary:
	match phase:
		"e01_panel":
			return {"title": "完成入职说明会", "short": "完成入职说明会", "detail": "确认本段剧情后，首月引导继续。"}
		"hud_tour":
			return {"title": "查看岗位卡与任务卡", "short": "查看界面导览", "detail": "按界面提示完成操作导览。"}
		"tour":
			return {"title": "跟随王哥完成带巡", "short": "跟随王哥带巡", "detail": "沿黄线前往下一站，抵达后剧情会自动继续。"}
		"tour_panel":
			return {"title": "完成当前带巡对话", "short": "完成带巡对话", "detail": "对话结算后会前往下一站。"}
		"handbook":
			return {"title": "准备参加跨组周会", "short": "前往跨组周会", "detail": "员工手册已开放查看；阅读为可选项。"}
		"e02_walk":
			return {"title": "前往 A 区跨组周会", "short": "前往跨组周会", "detail": "沿黄线到达会场，剧情会自动开启。"}
		"e02_panel":
			return {"title": "完成跨组周会剧情", "short": "完成跨组周会", "detail": "选择并确认后，进入本月自由安排。"}
		"activity":
			return {"title": "完成或结束本月自由安排", "short": "自由安排", "detail": "首月有 1 个行动点；可做一项活动，也可直接结束本月。"}
		"close":
			return {"title": "完成月末回顾", "short": "完成月末回顾", "detail": "回顾结束后睡一觉，睁眼就是下个月。"}
		"done":
			return {"title": "首月流程已完成", "short": "首月已完成", "detail": "这个月已经收好，正在换月。", "done": true}
		_:
			return {"title": "按当前任务提示继续", "short": "按当前任务继续", "detail": "完成当前步骤后，首月流程会继续。"}


func _task_info_row(page: Panel, icon: Texture2D, caption: String, value: String, x: float, y: float) -> void:
	_art(icon, Vector2(x, y + 6), Vector2(34, 34), page)
	var caption_label := _label(caption, 18); caption_label.position = Vector2(x + 46, y); caption_label.size = Vector2(96, 46); page.add_child(caption_label)
	_task_surface(page, Vector2(x + 148, y + 2), Vector2(280, 44), Color("fff8eb"), Color("dfbd91"), 13)
	var value_label := _label(value, 19); value_label.position = Vector2(x + 164, y + 1); value_label.size = Vector2(248, 44); value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; page.add_child(value_label)


func _task_condition(page: Panel, text: String, ready: bool, x: float, y: float) -> void:
	var box := Panel.new()
	box.position = Vector2(x, y + 2)
	box.size = Vector2(24, 24)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color("fff8e8")
	box_style.border_color = GREEN if ready else Color("bb9165")
	box_style.set_border_width_all(1)
	box_style.set_corner_radius_all(5)
	box.add_theme_stylebox_override("panel", box_style)
	page.add_child(box)
	if ready:
		var check := _label("✓", 20); check.position = Vector2(x - 1, y - 3); check.size = Vector2(26, 28); check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; page.add_child(check)
	var label := _label(text, 18); label.position = Vector2(x + 40, y - 5); label.size = Vector2(340, 36); label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; page.add_child(label)


func _task_surface(parent: Control, at: Vector2, size_value: Vector2, fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = size_value
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.28, 0.14, 0.06, 0.08)
	style.shadow_size = 2
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _task_action_button(text: String, at: Vector2, size_value: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = size_value
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("9d8266"))
	button.add_theme_stylebox_override("normal", _task_action_style(primary))
	button.add_theme_stylebox_override("hover", _task_action_style(primary, true))
	button.add_theme_stylebox_override("pressed", _task_action_style(primary, false, true))
	button.add_theme_stylebox_override("disabled", _task_action_style(false, false, false, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _task_action_style(primary: bool, hovered := false, pressed := false, disabled := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if disabled:
		style.bg_color = Color("eadfc9")
	else:
		style.bg_color = Color("edc46f") if primary else Color("fff4de")
		if hovered:
			style.bg_color = Color("f4d38d") if primary else Color("fff8ec")
		elif pressed:
			style.bg_color = Color("dfb45d") if primary else Color("f3e3c6")
	style.border_color = Color("bb8754")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style


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
		if not bool(payload.get("month12", false)):
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
		var reply_options: Array = payload.get("reply_options", []) as Array
		if not reply_options.is_empty():
			# 12 个月首月：固定回复选项（发出去的那句）+ 一颗"先不回"退出键；不出现自由输入框。
			var option_box := VBoxContainer.new()
			option_box.position = Vector2(128, 560)
			option_box.size = Vector2(440, 190)
			option_box.add_theme_constant_override("separation", 10)
			page.add_child(option_box)
			for value in reply_options:
				if not (value is Dictionary):
					continue
				var option := Dictionary(value)
				var option_button := _button(String(option.get("text", "")), Vector2(440, 50), "green")
				option_button.add_theme_font_size_override("font_size", 20)
				var reply_id := String(option.get("id", ""))
				var reply_text := String(option.get("text", ""))
				option_button.pressed.connect(func(): phone_reply_selected.emit(String(payload.get("chat_id", "")), reply_id, reply_text))
				option_box.add_child(option_button)
			var later := _button("先不回，收起手机", Vector2(440, 46), "paper")
			later.add_theme_font_size_override("font_size", 19)
			later.pressed.connect(close_view)
			option_box.add_child(later)
			return
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
	# 「减少动态效果」升级成三档：关闭 = 原来那档，所有过场一律 0.15 秒硬切不出字。
	_settings_options(page, "过场动画", ["完整", "简洁", "关闭"], "cutscenes", 445)
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
	var is_int_option := SETTINGS_INT_KEYS.has(key)
	for index in options.size():
		var selected := (int(_settings[key]) == index) if is_int_option else (bool(_settings[key]) == (index == 1))
		var button := _button(String(options[index]), Vector2(118, 42), "gold" if selected else "paper")
		button.position = Vector2(305 + index * 110, y)
		button.pressed.connect(func(): _settings[key] = index if is_int_option else index == 1; open_view("settings"))
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
	# 旧的 reduced_motion 字段留着，由过场档位派生：剧情面板等老代码不用改。
	_settings["reduced_motion"] = int(_settings.get("cutscenes", 0)) == 2
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
	_settings["reduced_motion"] = int(_settings.get("cutscenes", 0)) == 2
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


func _hud_caption(button: Button, text: String) -> void:
	var label := _label(text, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, -28)
	label.size = Vector2(button.size.x, 26)
	label.add_theme_color_override("font_color", Color("f6e7c8"))
	label.add_theme_color_override("font_outline_color", Color("23170f"))
	label.add_theme_constant_override("outline_size", 4)
	button.add_child(label)


## 控制首月手机入口显示；来信时另外用红点提醒。
func set_phone_visible(value: bool) -> void:
	if _phone_button != null:
		_phone_button.visible = value
		_layout_hud()


## 首月界面按剧情节点解锁：精力条 / 手册 / 查看先藏。
func set_energy_visible(value: bool) -> void:
	if _energy_panel != null:
		_energy_panel.visible = value


func set_manual_visible(value: bool) -> void:
	if _manual_button != null:
		_manual_button.visible = value
		_layout_hud()


## 手册按钮上的红点：第 3 月会前"有页了，但不弹窗"就是这么给的。
func set_manual_red_dot(value: bool) -> void:
	if _manual_button == null:
		return
	if _manual_dot == null and value:
		_manual_dot = Panel.new()
		_manual_dot.name = "ManualRedDot"
		_manual_dot.position = Vector2(76, 6)
		_manual_dot.size = Vector2(22, 22)
		_manual_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("e5503f")
		style.border_color = Color("fff3dc")
		style.set_border_width_all(2)
		style.set_corner_radius_all(11)
		_manual_dot.add_theme_stylebox_override("panel", style)
		_manual_button.add_child(_manual_dot)
	if _manual_dot != null:
		_manual_dot.visible = value


## 处境那一行字。stable 或还没跟后台上账就不出现；
## 出现时直接把话说完（"处境 · 被观察"），颜色只是快读辅助，语义靠文字兜着（§2.4）。
func set_standing_line(label_text: String, color_hex: String) -> void:
	if _standing_line == null:
		return
	if label_text.is_empty():
		_standing_line.hide()
		return
	_standing_line.text = "处境 · %s" % label_text
	_standing_line.add_theme_color_override("font_color", Color(color_hex))
	_standing_line.visible = _job_label != null and _job_label.visible


func _on_standing_line_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		profile_requested.emit()


func set_view_visible(value: bool) -> void:
	if _view_button != null:
		_view_button.visible = value


func set_act_label(text: String) -> void:
	if _act_label != null and not _date_mode:
		_act_label.text = text


## 首月任务卡直接写当前节点，不再提前露旧主线的标题。
func set_task_card(title: String, meta: String) -> void:
	if _task_title != null:
		_task_title.text = title
		# 标题条只有 282 宽：31 号字最多放 9 个字。长标题不缩字号就会被省略号咬掉后半句，
		# 而"咬掉后半句"在玩家眼里等于任务没显示全。
		var size := 31
		if title.length() > 11:
			size = 22
		elif title.length() > 9:
			size = 26
		_task_title.add_theme_font_size_override("font_size", size)
	if _task_meta != null:
		_task_meta.text = meta


## 任务卡第三行：这个月自己的时间。没有安排时间的月份也要有一句，不留空。
func set_task_note(text: String) -> void:
	if _task_note != null:
		_task_note.text = text


func set_task_caption(text: String) -> void:
	if _task_caption != null:
		_task_caption.text = text


## 左上角岗位栏本体：它就是档案入口，处境那一行字挂在它下面
## （WorkplaceTown._refresh_standing_line）。
func job_button() -> Button:
	return _job_label


## 手机有新消息时用呼吸式缩放提醒，直到玩家点开手机。
var _phone_attention: Tween


func start_phone_attention() -> void:
	if _phone_button == null or _phone_attention != null:
		return
	_phone_button.pivot_offset = _phone_button.size * 0.5
	_phone_attention = _phone_button.create_tween().set_loops()
	_phone_attention.tween_property(_phone_button, "scale", Vector2(1.08, 1.08), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_phone_attention.tween_property(_phone_button, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_phone_attention() -> void:
	if _phone_attention != null:
		_phone_attention.kill()
		_phone_attention = null
	if _phone_button != null:
		_phone_button.scale = Vector2.ONE


func set_phone_red_dot(value: bool) -> void:
	if _phone_button == null:
		return
	if _phone_dot == null:
		_phone_dot = Panel.new()
		_phone_dot.name = "PhoneRedDot"
		_phone_dot.position = Vector2(74, 6)
		_phone_dot.size = Vector2(22, 22)
		_phone_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("e5503f")
		style.border_color = Color("fff3dc")
		style.set_border_width_all(2)
		style.set_corner_radius_all(11)
		_phone_dot.add_theme_stylebox_override("panel", style)
		_phone_button.add_child(_phone_dot)
	_phone_dot.visible = value


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


## 每颗圆钮都从这儿建：按牌面直径把整张图缩放到同一档，再放进 104 的槽位。
func _hud_round_button(texture: Texture2D, key: String) -> Button:
	var art_scale: float = HUD_PLATE_TARGET / float(HUD_PLATE_DIAMETER.get(key, HUD_PLATE_TARGET))
	return _art_button(texture, "", Vector2.ZERO, Vector2(104, 104), art_scale)


func _art_button(texture: Texture2D, value: String, at: Vector2, size_value: Vector2, art_scale := 1.0) -> Button:
	var button := _button(value, size_value, "paper")
	button.position = at
	button.flat = true
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	# art_scale 只在圆钮上用来把牌面直径对齐，图仍以槽位中心为锚点放大。
	var art_size := size_value * art_scale
	var art := _art(texture, (size_value - art_size) * 0.5, art_size, button)
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


func _circle_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(52)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 6
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(PAPER, 0.96); style.border_color = WOOD; style.set_border_width_all(5); style.set_corner_radius_all(18); style.shadow_color = Color(0, 0, 0, 0.38); style.shadow_size = 18; return style


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = WOOD; style.set_border_width_all(3); style.set_corner_radius_all(14); return style
