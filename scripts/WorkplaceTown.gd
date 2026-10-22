extends Node2D


const PAPER_DOLL := preload("res://scripts/PaperDoll64Sprite.gd")
const OFFICE_SET := preload("res://scripts/OfficeSet.gd")
const OFFICE_NPC := preload("res://scripts/OfficeNpcWalker.gd")
const TOWN_PORTAL := preload("res://scripts/TownPortal.gd")
const MAP_DEBUG_OVERLAY := preload("res://scripts/MapDebugOverlay.gd")
const TIME_HUD := preload("res://scripts/WorldTimeHud.gd")
const INTERIOR_PREVIEW := preload("res://scripts/InteriorPreview.gd")
const STORY_EVENT_PANEL := preload("res://scripts/StoryEventPanel.gd")
const ACTION_WINDOW := preload("res://scripts/ActionWindow.gd")
const ASSESSMENT_PANEL := preload("res://scripts/AssessmentPanel.gd")
const ACHIEVEMENT_PANEL := preload("res://scripts/AchievementPanel.gd")
const ACHIEVEMENT_PATH := "res://data/story/achievements_v12.json"
const TRAINING_SCENE := preload("res://training_valley/main.tscn")
const ASSESSMENT_MONTHS := [6, 12, 18, 24, 30, 36, 42]
const AREA_ACTIVITY_PANEL := preload("res://scripts/AreaActivityPanel.gd")
const MEMORY_WALL := preload("res://scripts/MemoryWallPanel.gd")
## 「你的处境」常驻页（Batch 6 / V5.27 §2.4 明示原则，最高优先级红线）。
## 数值全由服务端下发，本地只渲染。
const STANDING_PANEL := preload("res://scripts/StandingPanel.gd")
const FINALE_PANEL := preload("res://scripts/FinalePanel.gd")
## 设置弹窗（2026-09-17 UI 打磨）：操作说明 + 退出游戏收编在这里。
const SETTINGS_PANEL := preload("res://scripts/SettingsPanel.gd")
## 圆钮矢量图标（2026-09-17 晚：单字圆钮换图形，用户嫌字丑）。
const HUD_GLYPH := preload("res://scripts/ui/HudGlyph.gd")
## 区域活动演出：全屏场景图 + 底部逐字文字。
const WEEKEND_SCENE_PANEL := preload("res://scripts/WeekendScenePanel.gd")
const TOWN_UI_V2 := preload("res://scripts/TownUiV2.gd")
const GROUND_GUIDE := preload("res://scripts/ui/GroundGuideLine.gd")
const CHINESE_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const JOYSTICK_BASE := preload("res://assets/ui/rework_v1/hud/revisions/01_摇杆底图.png")
const JOYSTICK_KNOB := preload("res://assets/ui/rework_v1/hud/revisions/02_摇杆爪子按钮.png")
const TOWN_MAP_PATH := "res://assets/town/workplace_town_no_labels.png"
const TOWN_MAP_TEXTURE: Texture2D = preload("res://assets/town/workplace_town_no_labels.png")
const SOURCE_MAP_SIZE := Vector2(1678, 937)
const LOCATION_MARKER_RECTS := {
	"A": Rect2(250, 20, 230, 82),
	"B": Rect2(735, 25, 225, 82),
	"C": Rect2(1185, 60, 195, 82),
	"D": Rect2(1385, 525, 215, 82),
	"E": Rect2(755, 735, 195, 82),
	"F": Rect2(275, 635, 230, 82),
	"G": Rect2(160, 450, 215, 82),
	"H": Rect2(50, 210, 230, 100),
}
const WALKABILITY_MASK_PATH := "res://assets/town/walkability_mask.png"
const WALKABILITY_MASK: Texture2D = preload(WALKABILITY_MASK_PATH)
const REGIONS_PATH := "res://data/town/regions.json"
const NPCS_PATH := "res://data/town/npcs.json"
const COLLISION_DATA_PATH := "res://data/town/collision.json"
const NAVIGATION_DATA_PATH := "res://data/town/navigation.json"
const WORLD_SIZE := Vector2(1920, 1080)
const PLAYER_SPEED := 270.0
const COLLISION_LAYER := 1
## 键盘移动的兜底键位（按物理键位读，换键盘布局也认"WASD 那四个位置"）。
## 为什么需要兜底：project.godot 的 InputMap 里 move_* 四条曾被写成 device=16，
## 而真实键盘事件 device=0，Godot 会比对 device → 一条都匹配不上，玩家完全走不动。
## 配置再被改坏 / 被别的引擎版本重写时，这里保证键盘照样能走。
const MOVE_LEFT_KEYS := [KEY_A, KEY_LEFT]
const MOVE_RIGHT_KEYS := [KEY_D, KEY_RIGHT]
const MOVE_UP_KEYS := [KEY_W, KEY_UP]
const MOVE_DOWN_KEYS := [KEY_S, KEY_DOWN]
const INTERACTION_DISTANCE := 230.0
const ENTRANCE_DISTANCE := 64.0
const ZONE_ZOOM := 3.15
const OUTDOOR_EXPLORATION_ZOOM := 1.55
const CAMERA_FOLLOW_SPEED := 5.4
## 自由缩放：滚轮 / ± 键 / 触屏双指捏合每次的倍率步长。
const MAP_ZOOM_STEP := 1.12
## 缩放上限倍数（相对基础缩放）：1.55 × 2.6 ≈ 4.0，足够贴近看清角色与招牌。
const MAP_ZOOM_MAX_FACTOR := 2.6
## 缩放下限倍数：总 zoom 不能低于 _cover_zoom，否则视野超出 0..1920 / 0..1080，
## 相机 limit 会把画面钉在一边并露出灰底。1.0 / 1.55 ≈ 0.645 时正好看全整张地图。
const MAP_ZOOM_MIN_FACTOR := 1.0 / OUTDOOR_EXPLORATION_ZOOM
## 地面引导线：玩家挪出这么远才重算路径。太小会每帧重跑 BFS，太大线头会跟人脱开。
const GUIDE_REPATH_DISTANCE := 10.0
## 引导线拐角切圆弧的采样段数。只影响观感：4 段已经看不出折角。
const GUIDE_CORNER_STEPS := 4
const INTERIOR_ASSETS := {
	"A": "res://assets/场景内部图/熊起东方总部.png",
	"B": "res://assets/场景内部图/云栖科技丘.png",
	"C": "res://assets/场景内部图/创意水巷.png",
	"D": "res://assets/场景内部图/树影图书馆.png",
	"E": "res://assets/场景内部图/松风训练谷.png",
	"F": "res://assets/场景内部图/观澜展会码头.png",
	"G": "res://assets/场景内部图/暖邻康护院.png",
	"H": "res://assets/场景内部图/慢生活园.png",
}
## 小镇出生点，位于 H 区入口外的可通行道路，避开自动传送门感应范围。
const PLAYER_START_POSITION := Vector2(455, 500)
var WALKABLE_AREAS := [
	# Five destination forecourts / plazas.
	Rect2(70, 230, 330, 160), Rect2(760, 190, 330, 150), Rect2(1240, 420, 300, 200),
	Rect2(360, 680, 330, 210), Rect2(1150, 680, 340, 210),
	# Main road ring that connects every destination.
	Rect2(350, 330, 250, 500), Rect2(540, 300, 880, 120), Rect2(1320, 290, 220, 470),
	Rect2(350, 780, 1190, 160), Rect2(650, 620, 120, 230), Rect2(1040, 620, 120, 230),
]
var ZONES := [
	{"id": "a", "code": "A", "name": "启程广场·飓起东方总部", "rect": Rect2(75, 95, 315, 245), "center": Vector2(230, 210), "door": "bottom"},
	{"id": "b", "code": "B", "name": "云栖科技工厂", "rect": Rect2(760, 80, 320, 205), "center": Vector2(920, 180), "door": "bottom"},
	{"id": "c", "code": "C", "name": "创意水巷", "rect": Rect2(1450, 150, 390, 250), "center": Vector2(1645, 275), "door": "left"},
	{"id": "d", "code": "D", "name": "树影书院", "rect": Rect2(55, 420, 330, 250), "center": Vector2(220, 545), "door": "right"},
	{"id": "e", "code": "E", "name": "松风训练谷", "rect": Rect2(410, 760, 320, 230), "center": Vector2(570, 875), "door": "top"},
	{"id": "f", "code": "F", "name": "观澜会展码头", "rect": Rect2(255, 820, 330, 230), "center": Vector2(420, 930), "door": "top"},
	{"id": "g", "code": "G", "name": "暖邻康护院", "rect": Rect2(1320, 650, 360, 300), "center": Vector2(1500, 800), "door": "left"},
	{"id": "h", "code": "H", "name": "慢生活园·宿舍与桌游馆", "rect": Rect2(760, 760, 390, 250), "center": Vector2(955, 885), "door": "top"},
]
var NPCS := [
	{"zone": "a", "name": "陈工", "role": "邻组 Leader", "loadout": "bear_orange_blazer", "route": PackedVector2Array([Vector2(405, 345), Vector2(510, 345), Vector2(510, 390), Vector2(405, 390)]), "prompt": "结论是什么？预算和工期，一句话说完。"},
	{"zone": "b", "name": "王哥", "role": "技术 · 你的导师", "loadout": "bear_plaid_glasses", "route": PackedVector2Array([Vector2(850, 325), Vector2(1070, 325), Vector2(1070, 370), Vector2(850, 370)]), "prompt": "方案我看过了，先别急着推。说说你为什么选这条路线。"},
	{"zone": "c", "name": "小林", "role": "产品", "loadout": "bear_beige_blazer", "route": PackedVector2Array([Vector2(1435, 335), Vector2(1650, 335), Vector2(1650, 380), Vector2(1435, 380)]), "prompt": "客户那边催得很急，先帮我把需求优先级定下来。"},
	{"zone": "d", "name": "老周", "role": "资深", "loadout": "bear_green_cardigan", "route": PackedVector2Array([Vector2(1205, 680), Vector2(1285, 680), Vector2(1285, 800), Vector2(1205, 800)]), "prompt": "复盘会上有不同说法。你觉得该由谁来牵头？"},
]

var _office: OfficeSet
var _player: CharacterBody2D
var _player_sprite: Sprite2D
var _camera: Camera2D
## 相机铺满系数：视口比例 ≠ 16:9 时 > 1，让世界铺满视野（见 _apply_camera_cover）。
## _update_camera 的目标 zoom 都要乘它，否则会被 lerp 回 1.0，画面外又露出灰底。
var _cover_zoom := 1.0
## 上一帧的视口尺寸：变了才重算相机铺满（size_changed 信号时机不稳，会拿到过期尺寸）
var _last_viewport_size := Vector2.ZERO
## 玩家自由缩放的倍率（相对基础缩放），范围钳在 [MAP_ZOOM_MIN_FACTOR, MAP_ZOOM_MAX_FACTOR]。
## _update_camera 与 _apply_camera_cover 的目标 zoom 都要乘它，两边保持一致才不会互相打架。
var _map_zoom_factor := 1.0
## 鼠标拖动平移：按住左键拖动时，相机脱离玩家、按拖动量反向移动（地图跟着手走）。
## 松手后**保持**在当前视角不回弹 —— 拖动是"我去看看别处"；等玩家一有移动输入再滑回身上。
var _pan_offset := Vector2.ZERO
var _is_panning := false
var _pan_drag_origin := Vector2.ZERO
var _pan_offset_origin := Vector2.ZERO
## 触屏双指捏合：触控点 index -> 当前屏幕坐标
var _zoom_touches := {}
var _pinch_last_distance := 0.0
var _touch_vector := Vector2.ZERO
var _touch_active := false
var _active_zone: Dictionary = {}
var _nearby_zone: Dictionary = {}
var _nearby_npc: Dictionary = {}
var _npc_instances: Array[Dictionary] = []
var _zone_status: Control
var _interaction_button: Button
## 右上角功能圆钮（2026-09-17 UI 打磨）：记忆墙 / 周末手账 / 设置，横排一行。
## 旧的 190×56 长条按钮（退出游戏/记忆墙/周末手账）已删 —— 退出游戏收进设置弹窗。
## 原来 y=215 的「退出游戏」和精力条（同 y）整块叠在一起，这就是右上角「乱」的根源。
var _memory_wall_button: Button
## 圆钮行下方那条悬停名称提示（鼠标划过圆钮时显示两三个字）。
var _hud_button_caption: Label
## 设置弹窗与它的停钟还原（同记忆墙的待遇：开着时世界时钟停住）。
var _settings_panel
var _settings_resume_clock := false
## 顶部提醒横幅。整条横幅在超时后自毁。
var _toast_layer: CanvasLayer
var _toast_panel: Panel
var _toast_tween: Tween
var _dialog_label: Label
var _dialog_timer: Timer
var _last_walkable_position := Vector2.ZERO
## 进入室内前预先选好的主世界安全落点，避免退出时落进建筑碰撞或传送门感应区。
var _portal_return_position := Vector2.ZERO
var _debug_overlay
var _collision_debug_polygons: Array = []
var _coordinate_label: Label
var _walkability_image: Image
var _walkability_debug_sprite: Sprite2D
var _location_markers: Array[Sprite2D] = []
var _entrance_markers: Array = []
var _highlighted_zone_id := ""
var _portal_editor_active := false
var _dragged_portal_index := -1
var _portal_editor_save_button: Button
var _portal_editor_hint: Label
var _time_hud: WorldTimeHud
var _town_ui_v2: TownUiV2
var _phone_chat_history: Dictionary = {}
var _interior_preview: InteriorPreview
var _environment_tint: ColorRect
var _story_event_panel: StoryEventPanel
var _story_event: Dictionary = {}
var _action_window: ActionWindow
var _assessment_panel: AssessmentPanel
var _assessment_seen_months: Array[int] = []
var _achievement_panel
var _achievement_nodes: Array = []
var _achievement_seen_ids: Array[String] = []
var _training_first_cleared := false
var _training_overlay: CanvasLayer
var _activity_panel: AreaActivityPanel
var _pending_action_activity: Dictionary = {}
var _activity_busy := false
var _tutorial_step := 0
var _tutorial_complete := false
## 心湖记忆墙：读 user://workplace_town_memos.jsonl，把一路攒下的便签贴成一墙。
## 故意不写静态类型（也不给它 class_name）：免得依赖 .godot 里的全局类缓存，
## 那个缓存是编辑器扫描时才刷新的，切分支/新加类名时最容易在这里翻车。
var _memory_wall
## 开墙前世界时钟是不是在跑。关上要还原，否则玩家会莫名发现时间不走了。
var _wall_resume_clock := false
## 「你的处境」常驻页（Batch 6）+ 「处」钮上的处境警示点。
## 页面内容全来自服务端下发（ApiClient.server_state），本地不估算。
var _standing_panel
var _standing_dot: Panel
var _finale
## 开页前世界时钟是不是在跑。
var _standing_resume_clock := false
var _zone_entered_msec := 0
var _decision_opened_msec := 0
var _choice_hover_count := 0
var _last_hovered_choice_id := ""
## 区域活动演出面板。
var _weekend_scene_panel
## 地面引导线（见 scripts/ui/GroundGuideLine.gd）。写弱类型：理由同 _memory_wall。
var _guide_line
## 上次铺路时的玩家位置与目标：据此决定要不要重跑寻路。
var _guide_path_origin := Vector2(-99999, -99999)
var _guide_path_target := Vector2(-99999, -99999)
var _guide_path_urgent := false
## 左上角任务卡（主线提示）。名字沿用 _zone_status，因为它的 show()/hide()
## 左上角任务卡在区域进出和主流程切换时持续刷新。
## 卡内成员：小标签 / 主标题 / 区域徽标 / 副行。
var _objective_tag: Label
var _objective_title: Label
var _objective_badge: Label
var _objective_meta: Label
## 卡片左侧那条竖色条，到点态要换成橙金 —— 单独存一份好改色。
var _objective_accent: ColorRect
## 任务卡底板样式与"是否到点"：到点态要让边框呼吸起来。
var _objective_style: StyleBoxFlat
var _objective_urgent := false


func _ready() -> void:
	_load_achievement_nodes()
	_load_map_data()
	_build_map_backdrop()
	_load_walkability_mask()
	_build_map_collisions()
	_build_player()
	_build_guide_line()
	_build_npcs()
	_build_camera()
	_build_hud()
	_build_location_markers()
	_build_debug_overlay()
	_build_world_time()
	_build_town_ui_v2()
	_build_interior_preview()
	_build_story_event_panel()
	_build_action_window()
	_build_assessment_panel()
	_build_achievement_panel()
	_build_memory_wall()
	_build_standing_panel()
	_place_player_at_start()
	_refresh_objective_hint()
	_show_reminder_toast("操作教学", "先用 WASD、方向键或左下角摇杆移动角色")


## 键盘移动输入：先问 InputMap（方便以后在游戏里改键），拿不到就直接按物理键位兜底。
## 返回的方向已归一化，斜着走不会比直着走快。
func _read_move_input() -> Vector2:
	var from_actions := Input.get_vector("move_left", "move_right", "move_up", "move_down").limit_length(1.0)
	if from_actions != Vector2.ZERO:
		return from_actions
	return Vector2(
		float(_any_move_key_pressed(MOVE_RIGHT_KEYS)) - float(_any_move_key_pressed(MOVE_LEFT_KEYS)),
		float(_any_move_key_pressed(MOVE_DOWN_KEYS)) - float(_any_move_key_pressed(MOVE_UP_KEYS))
	).limit_length(1.0)


func _any_move_key_pressed(keys: Array) -> bool:
	for key in keys:
		if Input.is_physical_key_pressed(key):
			return true
	return false


func _physics_process(delta: float) -> void:
	if _player == null or _player_sprite == null:
		return
	if (_assessment_panel != null and _assessment_panel.visible) or (_achievement_panel != null and _achievement_panel.visible) or _training_overlay != null:
		_player.velocity = Vector2.ZERO
		_player_sprite.set_motion(Vector2.ZERO, 0.0)
		_hide_guide_line()
		return
	if _portal_editor_active:
		_player.velocity = Vector2.ZERO
		_player_sprite.set_motion(Vector2.ZERO, 0.0)
		_hide_guide_line()
		return
	if _interior_preview != null and _interior_preview.is_open():
		_interior_preview.set_touch_vector(_touch_vector)
		_hide_guide_line()
		return
	# 记忆墙同样盖住地图，人还在走就对不上；键盘不像鼠标，不受 CanvasLayer 拦。
	if _memory_wall != null and _memory_wall.is_open():
		_player.velocity = Vector2.ZERO
		_player_sprite.set_motion(Vector2.ZERO, 0.0)
		_hide_guide_line()
		return
	var direction := _read_move_input()
	if _touch_active:
		direction = _touch_vector
	if direction != Vector2.ZERO and not _tutorial_complete and _tutorial_step == 0:
		_tutorial_step = 1
		_show_reminder_toast("很好，角色可以移动了", "沿地面指引前往 B 区，走进金色传送门即可进入")
		_refresh_objective_hint()
	var wanted_position := _player.position + direction * PLAYER_SPEED * delta
	var move_direction := direction
	if direction != Vector2.ZERO and not _is_walkable_position(wanted_position):
		var horizontal := _player.position + Vector2(direction.x, 0.0) * PLAYER_SPEED * delta
		var vertical := _player.position + Vector2(0.0, direction.y) * PLAYER_SPEED * delta
		if direction.x != 0.0 and _is_walkable_position(horizontal):
			move_direction = Vector2(direction.x, 0.0)
		elif direction.y != 0.0 and _is_walkable_position(vertical):
			move_direction = Vector2(0.0, direction.y)
		else:
			move_direction = Vector2.ZERO
	if move_direction != Vector2.ZERO and _is_inside_active_zone(_player.position + move_direction * PLAYER_SPEED * delta):
		_player.velocity = move_direction * PLAYER_SPEED
		_player.move_and_slide()
		if _is_walkable_position(_player.position):
			_last_walkable_position = _player.position
		else:
			_player.position = _last_walkable_position
			_player.velocity = Vector2.ZERO
	else:
		_player.velocity = Vector2.ZERO
	_player_sprite.set_motion(move_direction, _player.velocity.length() * delta)
	_update_zone_state()
	_update_nearby_npc()
	_update_camera(delta)
	_refresh_guide_line()

func _process(_delta: float) -> void:
	if get_viewport_rect().size != _last_viewport_size:
		_apply_camera_cover()
	# 任务目标和入口采用低频呼吸动画，手机端无需额外粒子开销。
	var pulse := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
	# 主线到点时，任务卡边框跟着一起呼吸 —— 静态的橙色在这张底图上不够抓眼。
	if _objective_urgent and _objective_style != null:
		_objective_style.border_color = Color(1.0, 0.62, 0.20, 0.55 + pulse * 0.45)
		_objective_accent.modulate = Color(1, 1, 1, 0.72 + pulse * 0.28)
	for index in _entrance_markers.size():
		var marker: Node2D = _entrance_markers[index] as Node2D
		if not is_instance_valid(marker):
			continue
		var zone: Dictionary = ZONES[index] if index < ZONES.size() else {}
		var is_target := _portal_editor_active or String(zone.get("id", "")).to_lower() == _highlighted_zone_id.to_lower()
		marker.call("set_highlighted", is_target)
		marker.scale = Vector2.ONE * (1.08 + pulse * 0.12 if is_target else 1.0)
	_refresh_town_ui_v2()

## 拖动中的移动与松手走 _input 而不是 _unhandled_input：
## 拖动时鼠标很可能划过按钮/摇杆，那些 Control 会吃掉事件，_unhandled_input 就收不到松手了
## → 会一直卡在"拖动中"。这里抢在 GUI 之前收，并顺手把事件标记为已处理（拖动时不希望误触按钮）。
func _input(event: InputEvent) -> void:
	if _portal_editor_active:
		if event is InputEventMouseMotion and _dragged_portal_index >= 0:
			_move_dragged_portal(get_global_mouse_position())
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_dragged_portal_index = -1
			get_viewport().set_input_as_handled()
		return
	if not _is_panning:
		return
	if event is InputEventMouseMotion:
		_update_map_pan(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_map_pan()


## 拖动中窗口失焦（Alt+Tab 之类）会收不到鼠标松手：
## 不兜这一下，光标就卡在"抓手"上、`_is_panning` 也一直是 true。
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_end_map_pan()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_map_zoom_input(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F4 and (_interior_preview == null or not _interior_preview.is_open()):
			_set_portal_editor_active(not _portal_editor_active)
			return
		if _portal_editor_active:
			if event.keycode == KEY_S and event.ctrl_pressed:
				_save_portal_positions()
			return
		if _interior_preview != null and _interior_preview.is_open():
			# 大门感应区会自动返回；ESC 保留为兜底退出。
			if event.keycode == KEY_ESCAPE:
				_exit_zone()
			return
		if event.keycode == KEY_F3:
			_debug_overlay.set_overlay_visible(not _debug_overlay.visible_overlay)
			_walkability_debug_sprite.visible = _debug_overlay.visible_overlay
			_coordinate_label.visible = _debug_overlay.visible_overlay
			return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if _interaction_button != null and _interaction_button.visible:
				_begin_interaction()
				get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_Q:
			_exit_zone()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _portal_editor_active and _begin_portal_drag(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
			return
		if _debug_overlay != null and _debug_overlay.visible_overlay:
			var world_position := get_global_mouse_position()
			_coordinate_label.text = "地图坐标  x: %d  y: %d" % [roundi(world_position.x), roundi(world_position.y)]
		_begin_map_pan(event.position)


## 地图自由缩放入口。返回 true 表示这个事件已被缩放消费掉，别再往下传。
func _handle_map_zoom_input(event: InputEvent) -> bool:
	if _is_map_input_locked():
		_zoom_touches.clear()
		_pinch_last_distance = 0.0
		return false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(MAP_ZOOM_STEP)
			return true
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(1.0 / MAP_ZOOM_STEP)
			return true
	if event is InputEventMagnifyGesture:
		# 触控板 / 触屏的捏合手势，factor > 1 表示张开（放大）
		_zoom_by(event.factor)
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				_zoom_by(MAP_ZOOM_STEP)
				return true
			KEY_MINUS, KEY_KP_SUBTRACT:
				_zoom_by(1.0 / MAP_ZOOM_STEP)
				return true
			KEY_0, KEY_KP_0:
				# 一键回到默认视野
				_set_map_zoom(1.0)
				return true
	return _handle_pinch_zoom(event)


## 触屏双指捏合：两指距离张开 → 放大，收拢 → 缩小。
## 单指（拖摇杆、点按钮）不参与，避免和左下角摇杆抢手势。
func _handle_pinch_zoom(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed:
			_zoom_touches[event.index] = event.position
		else:
			_zoom_touches.erase(event.index)
		if _zoom_touches.size() < 2:
			_pinch_last_distance = 0.0
		return false
	if event is InputEventScreenDrag:
		if not _zoom_touches.has(event.index):
			return false
		_zoom_touches[event.index] = event.position
		if _zoom_touches.size() < 2:
			_pinch_last_distance = 0.0
			return false
		var indices := _zoom_touches.keys()
		indices.sort()
		var first: Vector2 = _zoom_touches[indices[0]]
		var second: Vector2 = _zoom_touches[indices[1]]
		var distance := first.distance_to(second)
		if _pinch_last_distance > 0.0 and distance > 0.0:
			# 单帧比例变化夹一下，手指甩得再快也不会一帧跳到极限
			_zoom_by(clampf(distance / _pinch_last_distance, 0.8, 1.25))
		_pinch_last_distance = distance
		return true
	return false


func _zoom_by(step: float) -> void:
	_set_map_zoom(_map_zoom_factor * step)


## 倍率钳制：下限保证「视野不超世界」（不露灰底），上限防止放太大糊成马赛克。
func _set_map_zoom(value: float) -> void:
	var clamped := clampf(value, MAP_ZOOM_MIN_FACTOR, MAP_ZOOM_MAX_FACTOR)
	if is_equal_approx(clamped, _map_zoom_factor):
		return
	_map_zoom_factor = clamped
	# 视野大小变了，可移动范围也跟着变，平移偏移要重新钳一次，
	# 否则缩小后相机会被相机 limit 钉在边上，玩家再移动时有一段"空转"。
	_clamp_pan_offset()


## 室内 / 剧情面板打开时不给缩放与拖动：那些界面盖住了地图，
## 此时改倍率或视角只会在退出后突然跳变一次，观感很差。
func _is_map_input_locked() -> bool:
	if _town_ui_v2 != null and _town_ui_v2.is_open():
		return true
	if _interior_preview != null and _interior_preview.is_open():
		return true
	if _story_event_panel != null and _story_event_panel.is_open():
		return true
	return false


## 当前场景的基础缩放：室外 = 探索视角，在区域内 = 区域视角。
func _base_zoom() -> float:
	return ZONE_ZOOM if not _active_zone.is_empty() else OUTDOOR_EXPLORATION_ZOOM


## 相机跟随的基准点：室外跟着玩家，区域内看区域中心。
func _camera_anchor() -> Vector2:
	if not _active_zone.is_empty():
		var center: Vector2 = _active_zone["center"]
		return center
	if _player != null:
		return _player.position
	return WORLD_SIZE * 0.5


func _begin_map_pan(screen_position: Vector2) -> void:
	if _is_map_input_locked():
		return
	_is_panning = true
	_pan_drag_origin = screen_position
	_pan_offset_origin = _pan_offset
	# 光标给个"抓手"反馈，松手恢复
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)


func _update_map_pan(screen_position: Vector2) -> void:
	if not _is_panning or _camera == null:
		return
	# 屏幕位移 ÷ zoom = 世界位移；鼠标向右拖 → 相机向左走，画面里的地图才跟着手走
	_pan_offset = _pan_offset_origin - (screen_position - _pan_drag_origin) / _camera.zoom
	_clamp_pan_offset()


func _end_map_pan() -> void:
	if not _is_panning:
		return
	_is_panning = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


## 相机最多走到「视野边缘贴住世界边缘」为止：再往外拖也看不见东西，只是白攒偏移。
## 不做这一步的话，拖过边界再松手，玩家移动时相机会先"空转"一段才跟上。
func _clamp_pan_offset() -> void:
	# 没平移过就直接返回：既省计算，也保证「只有滚轮缩放、没拖过鼠标」时偏移恒为 0
	if _camera == null or _pan_offset == Vector2.ZERO:
		return
	var half := get_viewport().get_visible_rect().size / _camera.zoom * 0.5
	# 参考系必须是「没平移时相机实际会待的位置」，也就是被 limit 钳过之后的落点。
	# 直接拿玩家位置当参考系是错的：玩家常常就站在可显示范围外（比如出生点 y=810，
	# 而 1080 世界里相机的 y 上限是 739.5，全靠 limit 兜着），那样一算就会凭空
	# 冒出一个 -70 的偏移 —— 表现是"只滚了下滚轮，画面就自己挪了一截"。
	var base_center := _camera_anchor().clamp(half, WORLD_SIZE - half)
	_pan_offset = (base_center + _pan_offset).clamp(half, WORLD_SIZE - half) - base_center


## 玩家一有移动输入就把视角滑回身上（拖动只是"去看看别处"，不是新的停留点）。
func _decay_pan_offset(delta: float) -> void:
	if _pan_offset == Vector2.ZERO or _is_panning:
		return
	var moving := false
	if _touch_active:
		moving = _touch_vector != Vector2.ZERO
	else:
		moving = _read_move_input() != Vector2.ZERO
	if not moving:
		return
	# 比相机跟随更快地收回（否则相机自身还在 lerp，两级平滑叠一起会显得迟钝）
	_pan_offset = _pan_offset.lerp(Vector2.ZERO, minf(delta * CAMERA_FOLLOW_SPEED * 2.5, 1.0))
	if _pan_offset.length() < 1.0:
		_pan_offset = Vector2.ZERO


func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.name = "Player"
	_player.position = PLAYER_START_POSITION
	_last_walkable_position = _player.position
	_player.collision_layer = 2
	_player.collision_mask = COLLISION_LAYER
	_player.z_index = 30
	add_child(_player)
	var body_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 17
	body_shape.shape = circle
	body_shape.position = Vector2(0, -10)
	_player.add_child(body_shape)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-24, -4), Vector2(24, -4), Vector2(31, 2), Vector2(18, 8), Vector2(-18, 8), Vector2(-31, 2)])
	shadow.color = Color(0.04, 0.06, 0.08, 0.28)
	shadow.position = Vector2(0, 2)
	_player.add_child(shadow)
	_player_sprite = PAPER_DOLL.new()
	_player_sprite.position = Vector2(-32, -72)
	_player_sprite.configure_motion_speed(PLAYER_SPEED)
	_player.add_child(_player_sprite)
	_player_sprite.set_loadout(PlayerProfile.get_selected_avatar_id())


func _build_npcs() -> void:
	for index in NPCS.size():
		var npc_data: Dictionary = NPCS[index]
		var safe_route := _sanitize_npc_route(npc_data["route"] as PackedVector2Array)
		if safe_route.size() < 2:
			push_warning("NPC %s 没有找到安全巡逻路线，已暂停移动。" % npc_data["name"])
			continue
		var character: Node2D = OFFICE_NPC.new()
		character.configure(String(npc_data["loadout"]), safe_route, 30.0 + index * 2.0, 100 + index)
		add_child(character)
		var name_tag := Label.new()
		name_tag.text = "%s  %s" % [npc_data["name"], npc_data["role"]]
		name_tag.position = Vector2(-62, -112)
		name_tag.add_theme_font_override("font", CHINESE_FONT)
		name_tag.add_theme_font_size_override("font_size", 16)
		name_tag.add_theme_color_override("font_color", Color("fff5d6"))
		name_tag.add_theme_color_override("font_outline_color", Color("20232d"))
		name_tag.add_theme_constant_override("outline_size", 4)
		name_tag.z_index = 2
		name_tag.hide()
		character.add_child(name_tag)
		var entry: Dictionary = npc_data.duplicate()
		entry["character"] = character
		entry["name_tag"] = name_tag
		_npc_instances.append(entry)


# NPC 不能像玩家一样依赖物理碰撞来"推回"，否则会在建筑边缘抖动。
# 创建路线时先把每个点和每一段路线都采样到通行遮罩上，确保不会经过红色碰撞区。
func _sanitize_npc_route(source_route: PackedVector2Array) -> PackedVector2Array:
	var route := PackedVector2Array()
	for source_point in source_route:
		var safe_point := _nearest_npc_walkable_point(source_point)
		if safe_point == Vector2.INF:
			continue
		if route.is_empty():
			route.append(safe_point)
			continue
		if _is_npc_route_segment_safe(route[-1], safe_point):
			route.append(safe_point)
	# A loop must also have a safe final segment back to its first point.
	if route.size() > 2 and not _is_npc_route_segment_safe(route[-1], route[0]):
		route.remove_at(route.size() - 1)
	return route


func _nearest_npc_walkable_point(source_point: Vector2) -> Vector2:
	if _is_walkable_position(source_point):
		return source_point
	# Search in small rings so a point near a red outline moves onto the closest road,
	# instead of jumping across a building or lake.
	for radius in range(12, 181, 12):
		for angle_degrees in range(0, 360, 30):
			var candidate := source_point + Vector2.RIGHT.rotated(deg_to_rad(float(angle_degrees))) * radius
			if _is_walkable_position(candidate):
				return candidate
	return Vector2.INF


func _is_npc_route_segment_safe(from: Vector2, to: Vector2) -> bool:
	var distance := from.distance_to(to)
	var steps := maxi(1, ceili(distance / 8.0))
	for index in range(steps + 1):
		var point := from.lerp(to, float(index) / float(steps))
		if not _is_walkable_position(point):
			return false
	return true


func _build_camera() -> void:
	_camera = Camera2D.new()
	# 室外镜头从玩家身边开始，不再一次展示完整地图。
	# 世界坐标、碰撞和角色位置不变，只有 Camera2D 负责等比缩放与取景。
	_camera.position = _player.position if _player != null else WORLD_SIZE * 0.5
	_camera.zoom = Vector2.ONE * OUTDOOR_EXPLORATION_ZOOM
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_FOLLOW_SPEED
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(WORLD_SIZE.x)
	_camera.limit_bottom = int(WORLD_SIZE.y)
	add_child(_camera)
	_camera.make_current()
	_apply_camera_cover()
	# 平滑是从 (0,0) 滑向世界中心的，头一两秒画面会带着偏移（左侧露灰底），
	# 开局直接落位，不参与平滑
	_camera.reset_smoothing()
	# 窗口尺寸变了（拖拽/转屏）都要重算铺满
	get_viewport().size_changed.connect(_apply_camera_cover)


## 窗口比例和世界（16:9）不一致时，project.godot 的 stretch aspect=expand 会把视口
## 撑到比世界更宽/更高，相机视野超出 0..1920 / 0..1080 的限制范围，
## 画面外就露出灰底（左侧那条灰就是它）。
## 解法：把相机 zoom 拉到「世界铺满视野」（等比 cover，多出的部分裁掉），
## 世界坐标、区域触发、NPC 全都不动 —— 只动相机。
func _apply_camera_cover() -> void:
	if _camera == null:
		return
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_last_viewport_size = vp
	# view_in_world = vp / zoom，要两个方向都 <= 世界尺寸，zoom 取较大者
	_cover_zoom = maxf(vp.x / WORLD_SIZE.x, vp.y / WORLD_SIZE.y)
	# 铺满系数只是地板：再乘上当前场景的基础缩放与玩家自由缩放倍率才是最终 zoom。
	# 少了后两项，窗口一变 zoom 就会被拽回 1.0，接着又被 _update_camera 拉回去 —— 画面会抖。
	_camera.zoom = Vector2.ONE * _cover_zoom * _base_zoom() * _map_zoom_factor


func _build_walls() -> void:
	for rect in _wall_rects():
		var wall := StaticBody2D.new()
		wall.collision_layer = COLLISION_LAYER
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		wall.add_child(shape)
		add_child(wall)


func _build_map_backdrop() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "TownMapReference"
	sprite.texture = TOWN_MAP_TEXTURE
	sprite.centered = false
	if sprite.texture != null:
		var source_size := sprite.texture.get_size()
		sprite.scale = Vector2(WORLD_SIZE.x / source_size.x, WORLD_SIZE.y / source_size.y)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -100
	add_child(sprite)


func _load_map_texture(path: String) -> Texture2D:
	var imported := ResourceLoader.load(path, "Texture2D") as Texture2D
	if imported != null:
		return imported
	if OS.has_feature("web"):
		push_error("小镇贴图资源不存在: %s" % path)
		return null
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		push_error("小镇底图加载失败: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _load_walkability_mask() -> void:
	_walkability_image = WALKABILITY_MASK.get_image()
	if _walkability_image == null or _walkability_image.is_empty():
		push_error("道路通行遮罩加载失败: %s" % WALKABILITY_MASK_PATH)
		_walkability_image = null
		return
	_walkability_debug_sprite = Sprite2D.new()
	_walkability_debug_sprite.name = "WalkabilityDebugMask"
	_walkability_debug_sprite.texture = ImageTexture.create_from_image(_walkability_image)
	_walkability_debug_sprite.centered = false
	_walkability_debug_sprite.modulate = Color(0.15, 1.0, 0.25, 0.28)
	_walkability_debug_sprite.z_index = 70
	_walkability_debug_sprite.visible = false
	add_child(_walkability_debug_sprite)


func _build_map_collisions() -> void:
	# Player movement is constrained by the pixel mask. Static bodies remain only
	# at the world edge so approximate polygons cannot block a valid curved road.
	_add_wall_collider(Rect2(0, 0, 1920, 18))
	_add_wall_collider(Rect2(0, 1062, 1920, 18))
	_add_wall_collider(Rect2(0, 0, 18, 1080))
	_add_wall_collider(Rect2(1902, 0, 18, 1080))
	var payload := _read_json(COLLISION_DATA_PATH)
	for layer in payload.get("layers", []):
		for polygon in layer.get("polygons", []):
			_collision_debug_polygons.append(_to_points(polygon))


func _to_points(points_data: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in points_data:
		if point is Array and point.size() >= 2:
			points.append(Vector2(float(point[0]), float(point[1])))
	return points


func _load_map_data() -> void:
	var region_payload := _read_json(REGIONS_PATH)
	var loaded_zones: Array = []
	for item in region_payload.get("regions", []):
		var rect_data: Dictionary = item.get("rect", {})
		var rect := Rect2(float(rect_data.get("x", 0)), float(rect_data.get("y", 0)), float(rect_data.get("w", 0)), float(rect_data.get("h", 0)))
		loaded_zones.append({
			"id": String(item.get("id", "")), "code": String(item.get("id", "")), "name": String(item.get("name", "")),
			"purpose": String(item.get("purpose", "")), "rect": rect, "center": rect.get_center(),
			"entrance": _dictionary_to_vector(item.get("entrance", {})), "door": "bottom"
		})
	if loaded_zones.size() == 8:
		ZONES = loaded_zones
	var npc_payload := _read_json(NPCS_PATH)
	var loaded_npcs: Array = []
	for item in npc_payload.get("npcs", []):
		var route_points := PackedVector2Array()
		for point in item.get("route", []):
			if point is Array and (point as Array).size() >= 2:
				route_points.append(Vector2(float(point[0]), float(point[1])))
		loaded_npcs.append({
			"id": String(item.get("id", "")),
			"zone": String(item.get("zone", "")).to_lower(), "name": String(item.get("name", "")),
			"role": String(item.get("role", "")), "loadout": String(item.get("loadout", "")),
			"route": route_points, "prompt": String(item.get("prompt", "")),
			"sunday_prompt": _string_array(item.get("sunday_prompt", [])),
		})
	if loaded_npcs.size() > 0:
		NPCS = loaded_npcs
	print("[WorkplaceTown] 载入区域 %d 个、NPC %d 位（来源 %s）" % [ZONES.size(), NPCS.size(), NPCS_PATH])
	var navigation_payload := _read_json(NAVIGATION_DATA_PATH)
	var loaded_areas: Array = []
	for item in navigation_payload.get("walkableRegions", []):
		var values: Array = item.get("rect", [])
		if values.size() == 4:
			loaded_areas.append(Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3])))
	if not loaded_areas.is_empty():
		WALKABLE_AREAS = loaded_areas


func _dictionary_to_vector(value: Dictionary) -> Vector2:
	return Vector2(float(value.get("x", 0)), float(value.get("y", 0)))


## jsonl/json 里的字符串数组兜底（sunday_prompt 等纯文案字段）。
func _string_array(value) -> Array:
	var out: Array = []
	if value is Array:
		for item in (value as Array):
			if item is String and not (item as String).is_empty():
				out.append(item)
	elif value is String and not (value as String).is_empty():
		out.append(value)
	return out


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("地图数据文件不存在，使用脚本内置默认值: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _add_polygon_collider(points_data: Array) -> void:
	if points_data.size() < 3:
		return
	var polygon := PackedVector2Array()
	for point in points_data:
		if point is Array and point.size() >= 2:
			polygon.append(Vector2(float(point[0]), float(point[1])))
	if polygon.size() < 3:
		return
	var body := StaticBody2D.new()
	body.collision_layer = COLLISION_LAYER
	var shape := CollisionPolygon2D.new()
	shape.polygon = polygon
	body.add_child(shape)
	add_child(body)


func _is_walkable_position(position: Vector2) -> bool:
	if _walkability_image == null or _walkability_image.is_empty():
		for area in WALKABLE_AREAS:
			if (area as Rect2).grow(-17.0).has_point(position):
				return true
		return false
	var sample_offsets: Array[Vector2] = [Vector2.ZERO, Vector2(-8, 0), Vector2(8, 0), Vector2(0, -8), Vector2(0, 8)]
	for offset: Vector2 in sample_offsets:
		var sample: Vector2 = position + offset
		if sample.x < 0.0 or sample.y < 0.0 or sample.x >= WORLD_SIZE.x or sample.y >= WORLD_SIZE.y:
			return false
		var x := clampi(floori(sample.x * _walkability_image.get_width() / WORLD_SIZE.x), 0, _walkability_image.get_width() - 1)
		var y := clampi(floori(sample.y * _walkability_image.get_height() / WORLD_SIZE.y), 0, _walkability_image.get_height() - 1)
		var pixel := _walkability_image.get_pixel(x, y)
		if pixel.a < 0.5 or pixel.r < 0.5:
			return false
	return true


func _is_inside_active_zone(position: Vector2) -> bool:
	if _active_zone.is_empty():
		return true
	return (_active_zone["rect"] as Rect2).grow(28.0).has_point(position)


func _build_location_markers() -> void:
	for zone in ZONES:
		var code := String(zone["code"])
		var source_rect: Rect2 = LOCATION_MARKER_RECTS.get(code, Rect2())
		var marker := Sprite2D.new()
		marker.name = "LocationMarker%s" % code
		marker.texture = _load_map_texture("res://assets/ui/location_markers/%s.png" % code)
		# 牌子固定在对应建筑上方；镜头移动时与地图保持相对位置。
		marker.position = source_rect.get_center() * (WORLD_SIZE / SOURCE_MAP_SIZE)
		marker.scale = WORLD_SIZE / SOURCE_MAP_SIZE
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marker.z_index = 45
		# 底图无地名；玩家进入区域框时才显示原图裁出的独立木牌。
		marker.visible = false
		add_child(marker)
		_location_markers.append(marker)
		var entrance_marker := TOWN_PORTAL.new()
		entrance_marker.name = "TownPortal%s" % zone["code"]
		entrance_marker.position = zone["entrance"]
		entrance_marker.z_index = 44
		add_child(entrance_marker)
		_entrance_markers.append(entrance_marker)


## 地面引导线。z_index = -50：高于地图底图(-100)，低于 NPC(0) 与玩家(30) ——
## 线是铺在路面上的一层漆，人踩在它上面才对。
func _build_guide_line() -> void:
	_guide_line = GROUND_GUIDE.new()
	_guide_line.name = "GroundGuideLine"
	_guide_line.z_index = -50
	add_child(_guide_line)


func _hide_guide_line() -> void:
	if _guide_line == null:
		return
	_guide_line.clear()
	_guide_path_target = Vector2(-99999, -99999)


## 每帧问一次"现在该把人引到哪儿"，再决定要不要重铺这条路。
## 玩家只挪了一点点时只把线头挪过去（set_origin），不重跑寻路 —— BFS 虽便宜，
## 但每帧重建 PackedVector2Array 会让虚线相位在世界坐标里抖。
func _refresh_guide_line(force: bool = false) -> void:
	if _guide_line == null or _player == null:
		return
	# 人在区域内部 / 不在小镇上时，小镇的地面引导没有意义。
	if not _active_zone.is_empty():
		_hide_guide_line()
		return
	var target := _resolve_guide_target()
	if target.is_empty():
		_hide_guide_line()
		return
	var goal: Vector2 = target["position"]
	var urgent: bool = target["urgent"]
	var unchanged := not force \
		and goal.distance_to(_guide_path_target) < 1.0 \
		and urgent == _guide_path_urgent \
		and _player.position.distance_to(_guide_path_origin) < GUIDE_REPATH_DISTANCE
	if unchanged:
		_guide_line.set_origin(_player.position)
		return
	_guide_path_origin = _player.position
	_guide_path_target = goal
	_guide_path_urgent = urgent
	_guide_line.set_path(_build_guide_path(_player.position, goal), urgent)


## 现在该把玩家引到哪儿。只有"此刻真的有地方要去"才铺线：
##   1) 已经到点、还没走完的主线事件 —— 不去就进不了剧情，最强引导（urgent）；
##   2) 本周末自由活动选定的组团/活动所在区域 —— 玩家自己安排的目的地。
##
## 故意**不**给"还没到点的下一个主线"铺线：那是两个月后的事，现在就在地上拖一条
## 穿两条街的线，玩家会读成"立刻过去"。未来的安排只写在左上角任务卡里当信息，
## 不当指令（2026-09-16 用户纠正）。
##
## 返回空字典表示"此刻没有目的地"，此时不画线。
func _resolve_guide_target() -> Dictionary:
	var next_event := WorldClock.next_main_event()
	var snapshot := WorldClock.snapshot()
	if not next_event.is_empty() and _is_event_due(next_event, snapshot):
		var due_zone := _zone_by_code(String(next_event.get("locationId", "")))
		if not due_zone.is_empty():
			return {
				"position": due_zone["entrance"], "code": String(due_zone["code"]),
				"title": String(next_event.get("title", "")), "urgent": true,
			}
	return {}


## 户外落点黄标：显示/隐藏 + 挪到落点。**只有落点真的是当前引导目标时才亮**——
## 主线到点时引导线去主线，黄标还亮着就成了第二套口径。没有目的地就收起来。
## 按区域 code（"A".."H"）取 ZONES 条目；找不到返回空字典。
func _zone_by_code(code: String) -> Dictionary:
	var wanted := code.strip_edges().to_upper()
	if wanted.is_empty():
		return {}
	for zone in ZONES:
		if String(zone.get("code", "")).to_upper() == wanted:
			return zone
	return {}


## 沿道路求一条从 from 到 to 的引导路径。
##
## 做法：把 WALKABLE_AREAS（道路环的若干矩形）看成一张图，两个矩形相交即相邻，
## BFS 出矩形序列，再取**每对相邻矩形交集的中心**当通道点。
## 之所以不用真寻路也不会穿墙：矩形是凸的，而通道点同时落在前后两个矩形内，
## 于是 every 相邻两点的线段都整体留在同一个矩形里 —— 而矩形就是可走区域。
func _build_guide_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var straight := PackedVector2Array([from, to])
	if WALKABLE_AREAS.size() < 2:
		return straight
	var start_index := _closest_area_index(from)
	var goal_index := _closest_area_index(to)
	if start_index < 0 or goal_index < 0:
		return straight
	var chain := _breadth_first_area_chain(start_index, goal_index)
	if chain.is_empty():
		return straight
	var path := PackedVector2Array()
	path.append(from)
	for index in chain.size() - 1:
		path.append(_shared_center(WALKABLE_AREAS[chain[index]] as Rect2, WALKABLE_AREAS[chain[index + 1]] as Rect2))
	path.append(to)
	return _smooth_guide_path(path)


## 两个道路矩形的公共边界中点，用作穿过这对矩形的通道点。
##
## 不用 Rect2.intersection()：它对"贴边但零面积"的一对会返回空矩形 Rect2()，
## 于是 get_center() 给出 (0,0)，路径中间会凭空插一个原点坐标，
## 整条线斜穿整张地图。而贴边恰恰是这份数据的常态 —— b_forecourt 的底边
## 就正好压在 north_road 的顶边上。这里手算 near/far，退化成一个点也照收。
func _shared_center(first: Rect2, second: Rect2) -> Vector2:
	var near := Vector2(maxf(first.position.x, second.position.x), maxf(first.position.y, second.position.y))
	var far := Vector2(minf(first.end.x, second.end.x), minf(first.end.y, second.end.y))
	if near.x > far.x or near.y > far.y:
		# 理论上进不来（BFS 只走相交的矩形对），留个兜底免得再出现原点坐标。
		return (first.get_center() + second.get_center()) * 0.5
	return (near + far) * 0.5


## 包含该点的矩形下标；都不包含时取最近的一个。
func _closest_area_index(point: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for index in WALKABLE_AREAS.size():
		var area: Rect2 = WALKABLE_AREAS[index]
		if area.has_point(point):
			return index
		var distance := point.distance_to(area.get_center())
		if distance < best_distance:
			best_distance = distance
			best = index
	return best


## 两个道路矩形是否连通。必须把"贴边"也算连通：data/town/navigation.json 里
## b_forecourt 的底边 (y=340) 正好压在 north_road 的顶边 (y=340) 上，而
## Godot 的 Rect2.intersects() 默认不含边界 → B 区会被判成孤岛，
## 引导路径退化成一条横穿心湖的直线。include_borders 把这类贴边接回图上。
func _areas_connect(first: int, second: int) -> bool:
	return (WALKABLE_AREAS[first] as Rect2).intersects(WALKABLE_AREAS[second] as Rect2, true)


## BFS 出矩形下标序列（含首尾）。不连通时返回空数组，调用方退化成两点直线。
func _breadth_first_area_chain(start_index: int, goal_index: int) -> Array[int]:
	if start_index == goal_index:
		var single: Array[int] = [start_index]
		return single
	var queue: Array[int] = [start_index]
	var came_from := {start_index: -1}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == goal_index:
			break
		for neighbour in WALKABLE_AREAS.size():
			if neighbour == current or came_from.has(neighbour):
				continue
			if not _areas_connect(current, neighbour):
				continue
			came_from[neighbour] = current
			queue.append(neighbour)
	if not came_from.has(goal_index):
		return [] as Array[int]
	var chain: Array[int] = []
	var cursor: int = goal_index
	while cursor != -1:
		chain.push_front(cursor)
		cursor = int(came_from[cursor])
	return chain


## 把 90° 硬拐角切成二次贝塞尔圆弧。不切的话，沿着道路矩形走出来的折线
## 在拐点处是个尖角，叠上 21px 的投影带会像墙角的描边而不是"路"。
func _smooth_guide_path(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var smoothed := PackedVector2Array()
	smoothed.append(points[0])
	for index in range(1, points.size() - 1):
		var previous := points[index - 1]
		var corner := points[index]
		var following := points[index + 1]
		if previous.distance_to(corner) < 0.001 or corner.distance_to(following) < 0.001:
			continue
		var radius := minf(52.0, minf(previous.distance_to(corner), corner.distance_to(following)) * 0.42)
		if radius < 6.0:
			smoothed.append(corner)
			continue
		var entry := corner + (previous - corner).normalized() * radius
		var exit := corner + (following - corner).normalized() * radius
		for step in range(1, GUIDE_CORNER_STEPS + 1):
			var t := float(step) / float(GUIDE_CORNER_STEPS)
			# de Casteljau 求二次贝塞尔 B(t)，控制点是 corner。
			smoothed.append(entry.lerp(corner, t).lerp(corner.lerp(exit, t), t))
	smoothed.append(points[points.size() - 1])
	return smoothed


func _build_debug_overlay() -> void:
	_debug_overlay = MAP_DEBUG_OVERLAY.new()
	_debug_overlay.name = "MapDebugOverlay"
	_debug_overlay.z_index = 80
	_debug_overlay.configure(WALKABLE_AREAS, ZONES, _collision_debug_polygons)
	add_child(_debug_overlay)


func _wall_rects() -> Array[Rect2]:
	return [Rect2(400, 120, 1060, 18), Rect2(400, 940, 1060, 18), Rect2(400, 120, 18, 838), Rect2(1442, 120, 18, 838), Rect2(1100, 265, 18, 127), Rect2(1100, 476, 18, 289)]


func _build_zone_enclosures() -> void:
	for zone in ZONES:
		_add_enclosure_colliders(zone["rect"] as Rect2, String(zone["door"]))


func _add_enclosure_colliders(rect: Rect2, door_side: String) -> void:
	var thickness := 18.0
	var door_width := 76.0
	var top := Rect2(rect.position.x, rect.position.y - thickness * 0.5, rect.size.x, thickness)
	var bottom := Rect2(rect.position.x, rect.end.y - thickness * 0.5, rect.size.x, thickness)
	var left := Rect2(rect.position.x - thickness * 0.5, rect.position.y, thickness, rect.size.y)
	var right := Rect2(rect.end.x - thickness * 0.5, rect.position.y, thickness, rect.size.y)
	if door_side == "top" or door_side == "bottom":
		var wall := top if door_side == "top" else bottom
		var gap_start := wall.position.x + (wall.size.x - door_width) * 0.5
		_add_wall_collider(Rect2(wall.position.x, wall.position.y, gap_start - wall.position.x, wall.size.y))
		_add_wall_collider(Rect2(gap_start + door_width, wall.position.y, wall.end.x - gap_start - door_width, wall.size.y))
		_add_wall_collider(left)
		_add_wall_collider(right)
		_add_wall_collider(bottom if door_side == "top" else top)
	else:
		var wall := left if door_side == "left" else right
		var gap_start := wall.position.y + (wall.size.y - door_width) * 0.5
		_add_wall_collider(Rect2(wall.position.x, wall.position.y, wall.size.x, gap_start - wall.position.y))
		_add_wall_collider(Rect2(wall.position.x, gap_start + door_width, wall.size.x, wall.end.y - gap_start - door_width))
		_add_wall_collider(top)
		_add_wall_collider(bottom)
		_add_wall_collider(right if door_side == "left" else left)


func _add_wall_collider(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var wall := StaticBody2D.new()
	wall.collision_layer = COLLISION_LAYER
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	wall.add_child(shape)
	add_child(wall)


## 左上角任务卡：整块深色底板 + 左侧金色竖条 + 右侧区域徽标。
## 原来这里只有一行 24px 裸文字，压在花花绿绿的小镇底图上几乎被背景吞掉；
## 主线是玩家唯一"必须做"的事，视觉权重得压过附近的坐标 / 对话提示。
## 2026-09-17 UI 打磨：432×98 → 500×122 → 560×160，字号整体上调两档（用户反馈「字太小」第二轮）。
func _build_objective_card(layer: CanvasLayer) -> void:
	var card := Panel.new()
	card.name = "ObjectiveCard"
	card.position = Vector2(26, 20)
	card.size = Vector2(560, 160)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_style = StyleBoxFlat.new()
	_objective_style.bg_color = Color(0.07, 0.10, 0.14, 0.84)
	_objective_style.border_color = Color(0.85, 0.70, 0.36, 0.80)
	_objective_style.set_border_width_all(2)
	_objective_style.set_corner_radius_all(10)
	_objective_style.shadow_color = Color(0, 0, 0, 0.38)
	_objective_style.shadow_size = 9
	card.add_theme_stylebox_override("panel", _objective_style)
	layer.add_child(card)
	_zone_status = card

	# 左侧竖色条：一眼区分"到点了（橙金）/ 还没到（暖黄）"。
	_objective_accent = ColorRect.new()
	_objective_accent.position = Vector2(0, 0)
	_objective_accent.size = Vector2(6, 160)
	_objective_accent.color = Color("ffd24a")
	_objective_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_objective_accent)

	_objective_tag = _make_card_label("当前目标", 20, Color("f0cf8a"), card, Vector2(24, 14), Vector2(320, 28))
	_objective_title = _make_card_label("", 36, Color("fff4d6"), card, Vector2(24, 48), Vector2(400, 56))
	_objective_meta = _make_card_label("", 19, Color("d9bd85"), card, Vector2(24, 112), Vector2(512, 30))
	_objective_badge = _make_card_label("", 36, Color("ffd966"), card, Vector2(430, 46), Vector2(106, 58))
	_objective_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# 三行文字都可能很长（"Agent 出错了算谁的"）。Label 默认不裁剪、会直接画出卡片外
	# （meta 行曾画出 500px 卡右边框，截图确诊），所以三行全部 clip + 省略号，
	# 标题再配一个按字数收缩字号的兜底。
	for label in [_objective_tag, _objective_title, _objective_meta]:
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# 伪粗体：Regular 中文在深底上笔画偏细，撑不起"主线"的分量。
	for label in [_objective_title, _objective_badge]:
		var bold := FontVariation.new()
		bold.base_font = CHINESE_FONT
		bold.variation_embolden = 0.5
		label.add_theme_font_override("font", bold)


func _make_card_label(text: String, font_size: int, color: Color, parent: Control, position: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", CHINESE_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label


## 刷新任务卡的四行内容。标题按字数收缩字号，长标题不缩会被省略号吃掉后半句。
func _set_objective(tag: String, title: String, meta: String, badge: String, urgent: bool) -> void:
	if _zone_status == null:
		return
	_objective_tag.text = tag
	_objective_title.text = title
	_objective_meta.text = meta
	_objective_badge.text = badge
	_objective_badge.visible = not badge.is_empty()
	var title_size := 36
	if title.length() > 15:
		title_size = 28
	elif title.length() > 11:
		title_size = 32
	_objective_title.add_theme_font_size_override("font_size", title_size)
	var accent := Color("ff9f2e") if urgent else Color("ffd24a")
	_objective_accent.color = accent
	_objective_accent.modulate = Color(1, 1, 1, 1)
	_objective_badge.add_theme_color_override("font_color", Color("ffc453") if urgent else Color("ffd966"))
	_objective_urgent = urgent
	if not urgent:
		_objective_style.border_color = Color(0.85, 0.70, 0.36, 0.80)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	layer.layer = 100
	add_child(layer)
	_build_objective_card(layer)
	_coordinate_label = Label.new()
	_coordinate_label.position = Vector2(34, 190)
	_coordinate_label.add_theme_font_override("font", CHINESE_FONT)
	_coordinate_label.add_theme_font_size_override("font_size", 22)
	_coordinate_label.add_theme_color_override("font_color", Color("fff2a8"))
	_coordinate_label.add_theme_color_override("font_outline_color", Color("18202b"))
	_coordinate_label.add_theme_constant_override("outline_size", 4)
	_coordinate_label.text = "地图坐标  x: 0  y: 0"
	_coordinate_label.hide()
	layer.add_child(_coordinate_label)
	_dialog_label = Label.new()
	_dialog_label.position = Vector2(34, 226)
	_dialog_label.size = Vector2(760, 108)
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.add_theme_font_override("font", CHINESE_FONT)
	_dialog_label.add_theme_font_size_override("font_size", 27)
	_dialog_label.add_theme_color_override("font_color", Color("ffffff"))
	_dialog_label.add_theme_color_override("font_outline_color", Color("172033"))
	_dialog_label.add_theme_constant_override("outline_size", 5)
	_dialog_label.hide()
	layer.add_child(_dialog_label)
	_dialog_timer = Timer.new()
	_dialog_timer.one_shot = true
	_dialog_timer.timeout.connect(_hide_dialog)
	add_child(_dialog_timer)
	_interaction_button = Button.new()
	_interaction_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_interaction_button.position = Vector2(-390, -150)
	_interaction_button.size = Vector2(350, 82)
	_interaction_button.add_theme_font_override("font", CHINESE_FONT)
	_interaction_button.add_theme_font_size_override("font_size", 22)
	_interaction_button.hide()
	_interaction_button.pressed.connect(_begin_interaction)
	layer.add_child(_interaction_button)
	# 右上角功能圆钮排（记忆墙 / 周末手账 / 设置），退出游戏收进设置弹窗。
	_build_hud_button_row(layer)
	_build_portal_editor_controls(layer)
	_build_settings_panel()
	_build_mobile_joystick(layer)


func _build_town_ui_v2() -> void:
	_town_ui_v2 = TOWN_UI_V2.new()
	_town_ui_v2.profile_requested.connect(_open_ui_profile)
	_town_ui_v2.task_requested.connect(_open_ui_task)
	_town_ui_v2.phone_requested.connect(_open_ui_phone)
	_town_ui_v2.calendar_requested.connect(_open_ui_calendar)
	_town_ui_v2.task_calendar_requested.connect(_open_ui_task_calendar)
	_town_ui_v2.settings_requested.connect(func(): _town_ui_v2.open_view("settings"))
	_town_ui_v2.month_requested.connect(_on_ui_month_requested)
	_town_ui_v2.chat_requested.connect(_on_ui_chat_requested)
	_town_ui_v2.phone_message_submitted.connect(_on_phone_message_submitted)
	ApiClient.chat_ready.connect(_on_npc_chat_ready)
	ApiClient.chat_failed.connect(_on_npc_chat_failed)
	_town_ui_v2.save_requested.connect(_save_game_progress)
	_town_ui_v2.load_requested.connect(_load_game_progress)
	_town_ui_v2.title_requested.connect(_on_ui_title_requested)
	_town_ui_v2.preferences_changed.connect(_on_ui_preferences_changed)
	_town_ui_v2.locate_requested.connect(_on_ui_locate_requested)
	_town_ui_v2.advance_requested.connect(_on_ui_advance_requested)
	ApiClient.state_changed.connect(_on_server_state_changed)
	add_child(_town_ui_v2)
	if _time_hud != null:
		_time_hud.hide()
	if _zone_status != null:
		_zone_status.hide()


func _refresh_town_ui_v2() -> void:
	if _town_ui_v2 == null:
		return
	if _time_hud != null:
		_time_hud.hide()
	if _zone_status != null:
		_zone_status.hide()
	var remaining := _action_window.remaining if _action_window != null and not _action_window.current_window_id.is_empty() else 3
	_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), remaining, 3)


func _on_server_state_changed(_state: Dictionary) -> void:
	_refresh_town_ui_v2()
	_refresh_standing_badge()
	if _town_ui_v2 != null and _town_ui_v2.is_open() and _town_ui_v2.get("_view") == "profile":
		_town_ui_v2.open_view("profile")


func _open_ui_profile() -> void:
	_town_ui_v2.open_view("profile")


func _open_ui_task() -> void:
	var remaining := _action_window.remaining if _action_window != null and _action_window.active else 3
	var current_zone := String(_active_zone.get("code", "")) if not _active_zone.is_empty() else ""
	_town_ui_v2.open_view("task", {
		"event": WorldClock.next_main_event(),
		"snapshot": WorldClock.snapshot(),
		"energy": remaining,
		"current_zone": current_zone,
	})


func _open_ui_phone() -> void:
	var people: Array = []
	for npc in _npc_instances:
		people.append({"name": String(npc.get("name", "同事")), "zone": String(npc.get("zone", "")).to_upper(), "message": String(npc.get("prompt", "等你来聊聊。"))})
	var memories: Array = []
	var seen_memories: Dictionary = {}
	var file := FileAccess.open("user://workplace_town_events.jsonl", FileAccess.READ)
	if file != null:
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			if line.is_empty():
				continue
			var record = JSON.parse_string(line)
			if not record is Dictionary:
				continue
			var event_id := String(record.get("eventId", ""))
			var memory_key := event_id + ":" + String(record.get("choiceId", ""))
			if seen_memories.has(memory_key):
				continue
			for event in WorldClock.story_events():
				if String(event.get("id", "")) == event_id:
					seen_memories[memory_key] = true
					var choice := String(record.get("choiceId", ""))
					memories.append({"month": event.get("month", 1), "title": event.get("title", ""), "outcome": (event.get("outcome", {}) as Dictionary).get(choice, "")})
					break
	_town_ui_v2.open_view("phone", {"people": people, "memories": memories})


func _open_ui_calendar() -> void:
	_town_ui_v2.open_view("calendar", {"month": int(WorldClock.snapshot().get("month", 1)), "target_month": int(WorldClock.next_main_event().get("month", 48)), "next_event": WorldClock.next_main_event(), "events": WorldClock.story_events()})


func _open_ui_task_calendar(target_month: int) -> void:
	_town_ui_v2.open_view("calendar", {
		"month": int(WorldClock.snapshot().get("month", 1)),
		"target_month": target_month,
		"next_event": WorldClock.next_main_event(),
		"events": WorldClock.story_events(),
	})


func _on_ui_chat_requested(person: String) -> void:
	for npc in _npc_instances:
		if String(npc.get("name", "")) == person:
			_open_phone_chat(String(npc.get("id", "")))
			return


func _open_phone_chat(npc_id: String, pending := false) -> void:
	for npc in _npc_instances:
		if String(npc.get("id", "")) == npc_id:
			_town_ui_v2.open_view("phone", {"chat_id": npc_id,
				"chat_name": String(npc.get("name", "")),
				"chat_messages": (_phone_chat_history.get(npc_id, []) as Array).duplicate(true),
				"chat_pending": pending})
			return

func _on_phone_message_submitted(npc_id: String, message: String) -> void:
	for npc in _npc_instances:
		if String(npc.get("id", "")) == npc_id:
			var history: Array = _phone_chat_history.get(npc_id, [])
			history.append({"speaker": "我", "text": message})
			_phone_chat_history[npc_id] = history
			_open_phone_chat(npc_id, true)
			ApiClient.request_npc_chat(npc_id, message, String(npc.get("zone", "A")))
			return

func _on_npc_chat_ready(npc_id: String, reply: String) -> void:
	_interior_preview.show_chat_reply(npc_id, reply)
	var history: Array = _phone_chat_history.get(npc_id, [])
	if not history.is_empty():
		history.append({"speaker": "npc", "text": reply})
		_phone_chat_history[npc_id] = history
	if _town_ui_v2.current_chat_id() == npc_id:
		_open_phone_chat(npc_id)

func _on_npc_chat_failed(npc_id: String, reason: String) -> void:
	_interior_preview.show_chat_failure(npc_id, reason)
	var history: Array = _phone_chat_history.get(npc_id, [])
	if not history.is_empty():
		history.append({"speaker": "system", "text": reason})
		_phone_chat_history[npc_id] = history
	if _town_ui_v2.current_chat_id() == npc_id:
		_open_phone_chat(npc_id)


func _on_ui_month_requested(target_month: int) -> void:
	var current_month := int(WorldClock.snapshot().get("month", 1))
	if target_month <= current_month or target_month > 48:
		_show_reminder_toast("无法推进", "请选择当前月份之后、第 48 月之前的月份")
		return
	if _story_event_panel != null and _story_event_panel.is_open():
		_show_reminder_toast("暂时不能跳月", "请先结束正在阅读的剧情")
		return
	var confirmation = preload("res://scripts/MonthJumpDialog.gd").new()
	confirmation.name = "MonthJumpDialog"
	confirmation.current_month = current_month
	confirmation.target_month = target_month
	confirmation.confirmed.connect(func():
		WorldClock.skip_to_month(target_month)
		if _action_window != null:
			_action_window.abandon_for_month_jump()
		if _activity_panel != null:
			_activity_panel.hide_panel()
		for month in ASSESSMENT_MONTHS:
			if month < target_month and not _assessment_seen_months.has(month):
				_assessment_seen_months.append(month)
		_tutorial_complete = true
		_tutorial_step = 5
		ApiClient.record_event("month_jump", {"regionId": "A", "targetMonth": target_month})
		_town_ui_v2.close_view()
		_refresh_town_ui_v2()
		_refresh_objective_hint())
	add_child(confirmation)


func _save_game_progress() -> void:
	if _story_event_panel != null and _story_event_panel.is_open():
		_show_reminder_toast("暂时不能保存", "请先完成当前剧情")
		return
	if ApiClient.is_live_mode() and (not ApiClient.is_session_confirmed() or ApiClient.pending_event_count() > 0):
		_show_reminder_toast("暂时不能保存", "请等待后端同步完成后再保存")
		return
	var file := FileAccess.open("user://town_progress_v1.json", FileAccess.WRITE)
	if file == null:
		_show_reminder_toast("保存失败", "无法写入存档")
		return
	file.store_string(JSON.stringify({"version": 1, "clock": WorldClock.save_progress(), "action": _action_window.save_progress(), "assessmentSeen": _assessment_seen_months, "achievementSeen": _achievement_seen_ids, "trainingFirstCleared": _training_first_cleared, "tutorialStep": _tutorial_step, "tutorialComplete": _tutorial_complete, "player": {"x": _player.position.x, "y": _player.position.y}, "apiSessionId": ApiClient.current_session_id() if ApiClient.is_live_mode() else "", "apiState": ApiClient.server_state() if ApiClient.is_live_mode() else {}}))
	file.close()
	_show_reminder_toast("已保存游戏", "当前月份与行动力已记录")


func _load_game_progress() -> void:
	var file := FileAccess.open("user://town_progress_v1.json", FileAccess.READ)
	if file == null:
		_show_reminder_toast("没有存档", "请先保存游戏")
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		_show_reminder_toast("读取失败", "存档格式不受支持")
		return
	if ApiClient.is_live_mode():
		if not ApiClient.is_session_confirmed() or ApiClient.pending_event_count() > 0:
			_show_reminder_toast("暂时不能读档", "请等待后端同步完成后再读取")
			return
		if String(data.get("apiSessionId", "")) != ApiClient.current_session_id() or data.get("apiState", {}) != ApiClient.server_state():
			_show_reminder_toast("不能读取此存档", "后端会话或进度已变化，读取会覆盖另一条剧情")
			return
	WorldClock.load_progress(data.get("clock", {}))
	_action_window.load_progress(data.get("action", {}))
	_assessment_seen_months.clear()
	for month in data.get("assessmentSeen", []):
		_assessment_seen_months.append(int(month))
	_achievement_seen_ids.clear()
	for node_id in data.get("achievementSeen", []):
		_achievement_seen_ids.append(String(node_id))
	_training_first_cleared = bool(data.get("trainingFirstCleared", false))
	_tutorial_step = int(data.get("tutorialStep", 0))
	_tutorial_complete = bool(data.get("tutorialComplete", false))
	var saved_player := data.get("player", {}) as Dictionary
	if saved_player.has("x") and saved_player.has("y"):
		var position := Vector2(float(saved_player["x"]), float(saved_player["y"]))
		if _is_walkable_position(position):
			_player.position = position
			_last_walkable_position = position
			_camera.position = position
			_camera.reset_smoothing()
	_town_ui_v2.close_view()
	_refresh_town_ui_v2()
	_refresh_objective_hint()
	_show_reminder_toast("已读取存档", "游戏进度已恢复")


func _on_ui_title_requested() -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.dialog_text = "返回标题？未保存的进度将丢失。"
	confirmation.confirmed.connect(func(): get_tree().change_scene_to_file("res://Startup.tscn"))
	confirmation.canceled.connect(confirmation.queue_free)
	add_child(confirmation)
	confirmation.popup_centered()


func _on_ui_preferences_changed(preferences: Dictionary) -> void:
	if _story_event_panel != null:
		_story_event_panel.text_speed = int(preferences.get("text_speed", 1))
		_story_event_panel.large_text = bool(preferences.get("large_text", false))
		_story_event_panel.reduced_motion = bool(preferences.get("reduced_motion", false))


func _on_ui_locate_requested(zone_code: String) -> void:
	if not zone_code.is_empty():
		_highlighted_zone_id = zone_code
		_show_reminder_toast("已设为追踪", "跟随地面指引前往 %s 区" % zone_code)
	_town_ui_v2.close_view()


func _on_ui_advance_requested() -> void:
	if _action_window != null and _action_window.active:
		_show_reminder_toast("暂时不能跳月", "请先消耗完本次自由活动的行动力")
		return
	WorldClock.jump_to_next_main_event()
	_town_ui_v2.close_view()
	_refresh_objective_hint()


func _build_portal_editor_controls(layer: CanvasLayer) -> void:
	_portal_editor_save_button = Button.new()
	_portal_editor_save_button.text = "保存传送门位置"
	_portal_editor_save_button.position = Vector2(34, 370)
	_portal_editor_save_button.size = Vector2(250, 52)
	_portal_editor_save_button.add_theme_font_override("font", CHINESE_FONT)
	_portal_editor_save_button.add_theme_font_size_override("font_size", 20)
	_portal_editor_save_button.pressed.connect(_save_portal_positions)
	_portal_editor_save_button.hide()
	layer.add_child(_portal_editor_save_button)

	_portal_editor_hint = Label.new()
	_portal_editor_hint.text = "传送门编辑：拖动金色传送门到入口位置，按 Ctrl+S 保存"
	_portal_editor_hint.position = Vector2(34, 338)
	_portal_editor_hint.add_theme_font_override("font", CHINESE_FONT)
	_portal_editor_hint.add_theme_font_size_override("font_size", 18)
	_portal_editor_hint.add_theme_color_override("font_color", Color("fff2a8"))
	_portal_editor_hint.add_theme_color_override("font_outline_color", Color("18202b"))
	_portal_editor_hint.add_theme_constant_override("outline_size", 4)
	_portal_editor_hint.hide()
	layer.add_child(_portal_editor_hint)


func _set_portal_editor_active(value: bool) -> void:
	_portal_editor_active = value
	_dragged_portal_index = -1
	if _portal_editor_save_button != null:
		_portal_editor_save_button.visible = value
	if _portal_editor_hint != null:
		_portal_editor_hint.visible = value
	for marker in _entrance_markers:
		if is_instance_valid(marker):
			marker.call("set_highlighted", value)
	_show_reminder_toast("传送门编辑" if value else "已退出编辑", "拖动后按 Ctrl+S 或点击右上角保存" if value else "位置保持为最后一次保存的配置")


func _begin_portal_drag(world_position: Vector2) -> bool:
	for index in _entrance_markers.size():
		var marker := _entrance_markers[index] as Node2D
		if is_instance_valid(marker) and marker.global_position.distance_to(world_position) <= 62.0:
			_dragged_portal_index = index
			return true
	return false


func _move_dragged_portal(world_position: Vector2) -> void:
	if _dragged_portal_index < 0 or _dragged_portal_index >= ZONES.size():
		return
	var position := world_position.clamp(Vector2(24, 24), WORLD_SIZE - Vector2(24, 24))
	var zone: Dictionary = ZONES[_dragged_portal_index]
	zone["entrance"] = position
	ZONES[_dragged_portal_index] = zone
	var marker := _entrance_markers[_dragged_portal_index] as Node2D
	if is_instance_valid(marker):
		marker.global_position = position
	if _coordinate_label != null:
		_coordinate_label.text = "传送门坐标  x: %d  y: %d" % [roundi(position.x), roundi(position.y)]


func _save_portal_positions() -> void:
	var payload := _read_json(REGIONS_PATH)
	var regions: Array = payload.get("regions", [])
	if regions.size() != ZONES.size():
		_show_reminder_toast("保存失败", "区域配置不完整，未写入文件")
		return
	for index in ZONES.size():
		var region: Dictionary = regions[index]
		var entrance: Vector2 = ZONES[index]["entrance"]
		region["entrance"] = {"x": roundi(entrance.x), "y": roundi(entrance.y)}
		regions[index] = region
	payload["regions"] = regions
	var file := FileAccess.open(REGIONS_PATH, FileAccess.WRITE)
	if file == null:
		_show_reminder_toast("保存失败", "当前运行包无权修改项目配置，请在 Godot 编辑器中运行")
		return
	file.store_string(JSON.stringify(payload, "  ") + "\n")
	file.close()
	_show_reminder_toast("位置已保存", "已写入 data/town/regions.json")


## ---------- 右上角功能圆钮排（2026-09-17 UI 打磨） ----------

## 圆钮行的 y 起点：时间面板（y 26..234）正下方。48px 圆 + 8px 间距，一行 6 颗
## （设/账/忆/生/信/处）；点「生」开生活面板（精力/周末/熊友，2026-09-18 拍板）。
const HUD_CIRCLE_ROW_Y := 250.0
const HUD_CIRCLE_SIZE := 58.0

## 从右往左：设置 / 记忆墙 / 你的处境。悬停时显示名称。
func _build_hud_button_row(layer: CanvasLayer) -> void:
	var defs := [
		{"glyph": "忆", "tip": "记忆墙 · 回看一路攒下的便签", "caption": "记忆墙", "cb": _open_memory_wall},
		{"glyph": "处", "tip": "你的处境 · 现在站在哪里、为什么", "caption": "你的处境", "cb": _open_standing},
	]
	for i in defs.size():
		var button := _make_circle_button(
			layer,
			String(defs[i]["glyph"]),
			String(defs[i]["tip"]),
			Vector2(-15.0 - HUD_CIRCLE_SIZE * (i + 2) - 8.0 * (i + 1), HUD_CIRCLE_ROW_Y)
		)
		button.pressed.connect(_on_circle_button_press.bind(button))
		button.pressed.connect(Callable(defs[i]["cb"]))
		button.mouse_entered.connect(_on_circle_button_hover.bind(button, 1.08))
		button.mouse_entered.connect(_show_hud_button_caption.bind(String(defs[i]["caption"])))
		button.mouse_exited.connect(_on_circle_button_hover.bind(button, 1.0))
		button.mouse_exited.connect(_hide_hud_button_caption)
		if String(defs[i]["glyph"]) == "处":
			# 处境警示点：处境一旦不是「稳定」，这颗点就亮 —— 被叫去谈话这件事
			# 不能等玩家自己想起来翻页才知道。颜色分两级（观察=琥珀 / 危急以上=红），
			# 但**颜色只是快读的辅助**，语义永远有页面上的文字兜着（§2.4）。
			_standing_dot = Panel.new()
			_standing_dot.position = Vector2(32, -3)
			_standing_dot.size = Vector2(14, 14)
			var sdot_style := StyleBoxFlat.new()
			sdot_style.bg_color = Color("e0a63c")
			sdot_style.set_corner_radius_all(7)
			_standing_dot.add_theme_stylebox_override("panel", sdot_style)
			_standing_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_standing_dot.visible = false
			button.add_child(_standing_dot)
		elif String(defs[i]["glyph"]) == "忆":
			_memory_wall_button = button
	_hud_button_caption = Label.new()
	_hud_button_caption.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hud_button_caption.position = Vector2(-410, HUD_CIRCLE_ROW_Y + HUD_CIRCLE_SIZE + 8)
	_hud_button_caption.size = Vector2(395, 24)
	_hud_button_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_button_caption.add_theme_font_override("font", CHINESE_FONT)
	_hud_button_caption.add_theme_font_size_override("font_size", 17)
	_hud_button_caption.add_theme_color_override("font_color", Color("f3d59a"))
	_hud_button_caption.add_theme_color_override("font_outline_color", Color("18202b"))
	_hud_button_caption.add_theme_constant_override("outline_size", 3)
	_hud_button_caption.hide()
	layer.add_child(_hud_button_caption)


## 圆钮构造。⚠ 顺序必须是 anchors 预设 → position → size（与旧按钮/精力条同款）：
## TOP_RIGHT 锚点下先设 size 会把右边界推到屏幕外，再设 position 也救不回来。
func _make_circle_button(layer: CanvasLayer, glyph: String, tip: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.position = pos
	button.size = Vector2(HUD_CIRCLE_SIZE, HUD_CIRCLE_SIZE)
	# 2026-09-17 晚：单字换矢量图标。glyph 参数不再是显示文字，只当图标种类标识
	# （「设/账/忆/力」的 if 链和 tooltip 仍靠它）。字体 override 留着无害，不拆。
	button.text = ""
	button.tooltip_text = tip
	var glyph_view := HUD_GLYPH.new()
	glyph_view.kind = glyph
	glyph_view.size = Vector2(HUD_CIRCLE_SIZE, HUD_CIRCLE_SIZE)
	glyph_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph_view)
	button.add_theme_font_override("font", CHINESE_FONT)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("ffe5a8"))
	button.add_theme_color_override("font_hover_color", Color("fff4d6"))
	button.add_theme_color_override("font_pressed_color", Color("f0cf8a"))
	button.add_theme_color_override("font_outline_color", Color("23170f"))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_stylebox_override("normal", _circle_style(Color(0.329, 0.196, 0.122, 0.94), Color("d49a4c")))
	button.add_theme_stylebox_override("hover", _circle_style(Color(0.42, 0.247, 0.149), Color("ffc453")))
	button.add_theme_stylebox_override("pressed", _circle_style(Color(0.278, 0.165, 0.098), Color("d49a4c")))
	button.pivot_offset = button.size / 2.0
	layer.add_child(button)
	return button


func _circle_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(HUD_CIRCLE_SIZE / 2.0))
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 6
	return style


func _on_circle_button_hover(button: Button, target_scale: float) -> void:
	var t := button.create_tween()
	t.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_circle_button_press(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	var t := button.create_tween()
	t.tween_property(button, "scale", Vector2(0.92, 0.92), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_hud_button_caption(caption: String) -> void:
	if _hud_button_caption == null:
		return
	_hud_button_caption.text = caption
	_hud_button_caption.show()


func _hide_hud_button_caption() -> void:
	if _hud_button_caption != null:
		_hud_button_caption.hide()


## ---------- 设置弹窗 ----------

func _build_settings_panel() -> void:
	_settings_panel = SETTINGS_PANEL.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.settings_closed.connect(_on_settings_closed)
	_settings_panel.quit_requested.connect(_quit_game)
	add_child(_settings_panel)


func _open_settings() -> void:
	if _settings_panel == null:
		_build_settings_panel()
	if _settings_panel.is_open():
		return
	if _memory_wall != null and _memory_wall.is_open():
		return
	# 与记忆墙同待遇：设置开着时世界时钟停住。
	_settings_resume_clock = WorldClock.running
	if _settings_resume_clock:
		WorldClock.set_running(false)
	_settings_panel.open()


func _on_settings_closed() -> void:
	if _settings_resume_clock:
		WorldClock.set_running(true)
	_settings_resume_clock = false


## 左下角虚拟摇杆（触屏/鼠标共用）。2026-09-18 用户反馈：整体放大到 220，
## 内部尺寸全部按底盘比例推，改大小只动 JOYSTICK_SIZE 一个数。
const JOYSTICK_SIZE := 244.0

func _build_mobile_joystick(layer: CanvasLayer) -> void:
	var half := JOYSTICK_SIZE * 0.5
	var travel := half * 0.733        # 旋钮最大位移（原 55）
	var center := Vector2(half, half)
	var joystick := Control.new()
	joystick.position = Vector2(40, 1080.0 - JOYSTICK_SIZE - 38.0)
	joystick.size = Vector2(JOYSTICK_SIZE, JOYSTICK_SIZE)
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	var base := TextureRect.new()
	base.texture = JOYSTICK_BASE
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_SCALE
	base.size = joystick.size
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.add_child(base)
	var knob := TextureRect.new()
	knob.texture = JOYSTICK_KNOB
	knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	knob.stretch_mode = TextureRect.STRETCH_SCALE
	knob.size = Vector2(120, 120)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.add_child(knob)
	var refresh_knob := func():
		knob.position = center + _touch_vector * travel - knob.size * 0.5
	refresh_knob.call()
	joystick.gui_input.connect(func(event):
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			_touch_active = event.pressed
			if not _touch_active:
				_touch_vector = Vector2.ZERO
		if event is InputEventScreenDrag or event is InputEventMouseMotion:
			if _touch_active:
				_touch_vector = (joystick.get_local_mouse_position() - center).limit_length(travel) / travel
		refresh_knob.call()
	)
	layer.add_child(joystick)


func _update_zone_state() -> void:
	_update_location_marker_visibility()
	if not _active_zone.is_empty():
		_nearby_zone = {}
		return
	_nearby_zone = {}
	for zone in ZONES:
		var entrance: Vector2 = zone["entrance"]
		if _player.position.distance_to(entrance) <= ENTRANCE_DISTANCE:
			_nearby_zone = zone
			_enter_nearby_zone()
			return


func _update_location_marker_visibility() -> void:
	var entered_code := ""
	if _active_zone.is_empty() and _player != null:
		for zone in ZONES:
			if (zone["rect"] as Rect2).has_point(_player.position):
				entered_code = String(zone["code"])
				break
	for marker in _location_markers:
		marker.visible = marker.name == "LocationMarker%s" % entered_code


func _enter_nearby_zone() -> void:
	if _nearby_zone.is_empty() or not _active_zone.is_empty():
		return
	_portal_return_position = _find_safe_portal_exit(_nearby_zone, _player.position)
	_active_zone = _nearby_zone
	_nearby_zone = {}
	_zone_entered_msec = Time.get_ticks_msec()
	ApiClient.record_event("region_entered", {"regionId": String(_active_zone.get("code", ""))})
	_zone_status.hide()
	_dialog_label.hide()
	for marker in _location_markers:
		marker.hide()
	for npc in _npc_instances:
		var is_current := String(npc["zone"]).to_lower() == String(_active_zone["id"]).to_lower()
		var character := npc["character"] as Node2D
		var tag := npc["name_tag"] as Label
		character.visible = is_current
		tag.visible = is_current
	var texture_path := String(INTERIOR_ASSETS.get(String(_active_zone["code"]), ""))
	if not texture_path.is_empty():
		_interior_preview.present(_active_zone, texture_path)
		_interior_preview.set_phase(String(WorldClock.snapshot().get("phaseId", "work")))
	var event_opened := _open_due_event_for_active_zone()
	if not event_opened:
		_interior_preview.enable_exploration()
		_refresh_activity_panel()


func _exit_zone() -> void:
	if _active_zone.is_empty():
		return
	var departing_zone := _active_zone.duplicate(true)
	var region_id := String(departing_zone.get("code", ""))
	if _zone_entered_msec > 0:
		ApiClient.record_event("zone_dwell", {
			"regionId": region_id,
			"durationMs": maxi(0, Time.get_ticks_msec() - _zone_entered_msec),
		})
	_zone_entered_msec = 0
	_active_zone = {}
	_nearby_npc = {}
	_interaction_button.hide()
	_zone_status.show()
	if _interior_preview != null:
		_interior_preview.dismiss()
	_place_player_outside_portal(departing_zone)
	if _activity_panel != null:
		_activity_panel.hide_panel()
	_refresh_objective_hint()
	for marker in _location_markers:
		marker.hide()
	for npc in _npc_instances:
		(npc["character"] as Node2D).show()
		(npc["name_tag"] as Label).hide()
	_hide_dialog()


func _place_player_outside_portal(zone: Dictionary) -> void:
	if _player == null:
		return
	var fallback := _find_safe_portal_exit(zone, _player.position)
	var destination := _portal_return_position if _is_safe_portal_exit(_portal_return_position) else fallback
	_player.position = destination
	_player.velocity = Vector2.ZERO
	_last_walkable_position = _player.position
	_portal_return_position = Vector2.ZERO


func _find_safe_portal_exit(zone: Dictionary, approach_position: Vector2) -> Vector2:
	var entrance: Vector2 = zone.get("entrance", approach_position)
	var preferred_direction := approach_position - entrance
	if preferred_direction.length_squared() < 4.0:
		var bounds: Rect2 = zone.get("rect", Rect2())
		preferred_direction = entrance - bounds.get_center()
	if preferred_direction.length_squared() < 4.0:
		preferred_direction = Vector2.DOWN
	preferred_direction = preferred_direction.normalized()
	for distance in [96.0, 124.0, 152.0, 184.0, 220.0]:
		var candidate: Vector2 = entrance + preferred_direction * distance
		if _is_safe_portal_exit(candidate):
			return candidate
	for distance in [112.0, 152.0, 200.0, 248.0]:
		for index in 16:
			var angle := TAU * float(index) / 16.0
			var candidate: Vector2 = entrance + Vector2(cos(angle), sin(angle)) * float(distance)
			if _is_safe_portal_exit(candidate):
				return candidate
	return _last_walkable_position if _is_safe_portal_exit(_last_walkable_position) else PLAYER_START_POSITION


func _is_safe_portal_exit(position: Vector2) -> bool:
	if not _is_walkable_position(position):
		return false
	for zone in ZONES:
		var entrance: Vector2 = zone.get("entrance", Vector2.ZERO)
		if position.distance_to(entrance) <= ENTRANCE_DISTANCE + 16.0:
			return false
	return true


## 区域活动演出结束后结算一次行动力。
func _on_weekend_scene_finished() -> void:
	if not _pending_action_activity.is_empty():
		var activity := _pending_action_activity.duplicate(true)
		_pending_action_activity = {}
		_activity_busy = false
		var result := _action_window.spend_on_activity(activity)
		_refresh_activity_panel()


func _place_player_at_start() -> void:
	if _player == null:
		return
	_player.position = PLAYER_START_POSITION
	_player.velocity = Vector2.ZERO
	_last_walkable_position = _player.position
	if _camera != null:
		_camera.position = _player.position
		_camera.reset_smoothing()


## 顶部提醒横幅：屏幕顶上下滑入 → 停 3.6s → 上滑淡出自毁。全程不挡鼠标。
## 新横幅来了先撕旧的，避免叠罗汉。
func _show_reminder_toast(title: String, sub: String) -> void:
	if _toast_layer == null:
		_toast_layer = CanvasLayer.new()
		_toast_layer.layer = 190
		add_child(_toast_layer)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	if _toast_panel != null:
		_toast_panel.queue_free()
	var panel := Panel.new()
	_toast_panel = panel
	panel.position = Vector2((1920.0 - 600.0) / 2.0, -100)
	panel.size = Vector2(600, 92)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.329, 0.196, 0.122, 0.97)
	style.border_color = Color("ffc453")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)
	_toast_layer.add_child(panel)
	# 左侧圆徽 + 标题 + 副文案。
	var chip := Panel.new()
	chip.position = Vector2(20, 26)
	chip.size = Vector2(40, 40)
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color("ef9f27")
	chip_style.set_corner_radius_all(20)
	chip.add_theme_stylebox_override("panel", chip_style)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(chip)
	var chip_label := Label.new()
	chip_label.text = "息"
	chip_label.add_theme_font_override("font", CHINESE_FONT)
	chip_label.add_theme_font_size_override("font_size", 20)
	chip_label.add_theme_color_override("font_color", Color("3a2410"))
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_label.size = Vector2(40, 40)
	chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_label)
	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(76, 14)
	title_label.size = Vector2(500, 32)
	title_label.add_theme_font_override("font", CHINESE_FONT)
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color("ffe5a8"))
	title_label.add_theme_color_override("font_outline_color", Color("23170f"))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_label)
	var sub_label := Label.new()
	sub_label.text = sub
	sub_label.position = Vector2(76, 48)
	sub_label.size = Vector2(500, 28)
	sub_label.add_theme_font_override("font", CHINESE_FONT)
	sub_label.add_theme_font_size_override("font_size", 17)
	sub_label.add_theme_color_override("font_color", Color("fff0c9"))
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub_label)
	# 滑入 → 停留 → 滑出自毁。
	_toast_tween = create_tween()
	_toast_tween.tween_property(panel, "position:y", 36.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(3.6)
	_toast_tween.tween_property(panel, "position:y", -100.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_toast_tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.26)
	_toast_tween.tween_callback(panel.queue_free)


func _update_nearby_npc() -> void:
	_nearby_npc = {}
	for npc in _npc_instances:
		if not _active_zone.is_empty() and String(npc["zone"]).to_lower() != String(_active_zone["id"]).to_lower():
			continue
		var npc_position := (npc["character"] as Node2D).position
		if (npc["character"] as Node2D).visible and _player.position.distance_to(npc_position) <= INTERACTION_DISTANCE:
			_nearby_npc = npc
			_interaction_button.text = "与 %s 交流  ·  E" % npc["name"]
			_interaction_button.show()
			return
	_interaction_button.hide()


func _update_camera(delta: float) -> void:
	if _camera == null or _player == null:
		return
	# 玩家自由缩放倍率叠在场景基础缩放之上：缩到最小时（下限）视野正好铺满整个世界。
	var target_zoom := Vector2.ONE * _base_zoom() * _cover_zoom * _map_zoom_factor
	# 拖动平移：相机可以暂时离开玩家去看别处，玩家一有移动输入就滑回去
	_decay_pan_offset(delta)
	var target_position := _camera_anchor() + _pan_offset
	if _is_panning:
		# 拖动中不做平滑，手感才跟手（松手后重新交给 lerp）
		_camera.position = target_position
	else:
		_camera.position = _camera.position.lerp(target_position, minf(delta * CAMERA_FOLLOW_SPEED, 1.0))
	_camera.zoom = _camera.zoom.lerp(target_zoom, minf(delta * 4.2, 1.0))


func _build_world_time() -> void:
	_time_hud = TIME_HUD.new()
	add_child(_time_hud)
	WorldClock.time_changed.connect(_on_world_time_changed)
	WorldClock.main_event_reached.connect(_on_main_event_reached)
	_on_world_time_changed(WorldClock.snapshot())
	var environment_layer := CanvasLayer.new()
	environment_layer.layer = 40
	add_child(environment_layer)
	_environment_tint = ColorRect.new()
	_environment_tint.color = Color(1, 1, 1, 0)
	_environment_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_environment_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	environment_layer.add_child(_environment_tint)


func _on_world_time_changed(snapshot: Dictionary) -> void:
	if _time_hud != null:
		_time_hud.set_time(snapshot)
	if _interior_preview != null and _interior_preview.is_open():
		_interior_preview.set_phase(String(snapshot.get("phaseId", "work")))
	_refresh_objective_hint()
	if _environment_tint == null:
		return
	# 视觉只区分白天和晚上；职业时间由主线事件直接跳转。
	_environment_tint.color = Color(0.07, 0.14, 0.35, 0.42) if String(snapshot["phaseId"]) == "night" else Color(1, 1, 1, 0)


func _on_main_event_reached(event: Dictionary) -> void:
	_highlighted_zone_id = String(event.get("locationId", ""))
	ApiClient.record_event("event_trigger", {
		"regionId": String(event.get("locationId", "")),
		"storyId": String(event.get("id", "")),
		"snapshot": WorldClock.snapshot(),
	})
	if _time_hud != null:
		_time_hud.show_event_gate(event)
	_refresh_objective_hint()
	# 事件到点 = 引导线切成"救火"态（橙金 + 加速流动），必须立刻重铺。
	_refresh_guide_line(true)


func _refresh_objective_hint() -> void:
	_apply_objective_content()
	# 任务卡和地面引导线是同一份"当前目标"的两种说法，永远一起刷新：
	# 分开调用时最容易出现"卡上写着去 B 区、地上那条线却还指着 D 区"。
	_refresh_guide_line(true)


## 从事件 cast 里取一位联系人显示名（跳过玩家小熊本人），取不到返回空串。
## cast 有两种历史格式：字符串 id（去 speakers 查显示名）/ 直接带 name 的字典；
## 空 cast（M3-E09 心悸、M5-E17 副业边界这类独角事件）返回空串。
## 只服务于任务卡的「谁找你」—— 事件标题是剧情，绝不从这里出去（2026-09-18 拍板）。
func _event_contact_name(event: Dictionary) -> String:
	var cast_v = event.get("cast", [])
	if not (cast_v is Array) or (cast_v as Array).is_empty():
		return ""
	for member_v in (cast_v as Array):
		var display := ""
		if member_v is String:
			if String(member_v) == "xiaoxiong":
				continue
			var speaker = event.get("speakers", {}).get(String(member_v), {})
			if speaker is Dictionary:
				display = String(speaker.get("name", ""))
			else:
				display = String(member_v)
		elif member_v is Dictionary:
			display = String(member_v.get("name", ""))
			if display == "小熊":
				continue
		if display != "":
			return display
	return ""


## 按优先级决定任务卡内容：教学 > 行动窗口 > 到点主线 > 后续主线 > 完结。
func _apply_objective_content() -> void:
	if _zone_status == null:
		return
	if not _tutorial_complete and _tutorial_step == 0:
		_set_objective(
			"教学 1/5",
			"移动角色",
			"键盘使用 WASD 或方向键 · 手机使用左下角摇杆",
			"操作",
			false
		)
		return
	if not _tutorial_complete and _tutorial_step == 1:
		_set_objective("教学 2/5", "跟随地面路线前往第一段剧情", "到达目标区域入口后按 E 进入", "B 区", true)
		return
	if _action_window != null and _action_window.active:
		var remaining := int(_action_window.remaining)
		var zone_code := String(_active_zone.get("code", "")) if not _active_zone.is_empty() else ""
		var action_tag := "自由活动 · 剩余行动力 %d/3" % remaining
		if not _tutorial_complete:
			action_tag = "教学 4/5 · 认识行动力" if _tutorial_step <= 3 else "教学 5/5 · 耗尽行动力"
		if zone_code in ["C", "D", "E", "F", "G", "H"]:
			_set_objective(
				action_tag,
				"选择右侧活动，或与场所NPC交谈",
				"剩余 %d/3 · 每次有效行动消耗 1 点，清零后开放主线" % remaining,
				"%s 区" % zone_code,
				false
			)
		else:
			_set_objective(
				action_tag,
				"前往 C 至 H 区自由安排",
				"剩余 %d/3 · 通过区域活动消耗" % remaining,
				"C-H 区",
				false
			)
		return
	var next_event := WorldClock.next_main_event()
	var snapshot := WorldClock.snapshot()
	if not next_event.is_empty() and _is_event_due(next_event, snapshot):
		var due_zone := _zone_by_code(String(next_event.get("locationId", "")))
		# 任务卡只说 who/when/where，不说 what（2026-09-18 用户拍板）：
		# 事件标题是剧情，提前亮出来等于预告牌。标题的揭示时刻 = 到场弹出事件面板那一刻。
		var contact := _event_contact_name(next_event)
		var who: String = "%s找你" % contact if contact != "" else "有件事等你"
		_set_objective(
			"主线 · 现在就去做",
			who,
			"已到点 · 去 %s 区跟着地面指引走" % String(due_zone.get("code", "?")),
			"%s 区" % String(due_zone.get("code", "?")),
			true
		)
		return
	if next_event.is_empty():
		_set_objective("主线已完成", "自由探索职业区域", "随便走走，或打开右上角「记忆墙」回顾一路的选择", "", false)
		return
	var upcoming_zone := _zone_by_code(String(next_event.get("locationId", "")))
	var event_month := int(next_event.get("month", 1))
	var months_left := event_month - int(snapshot.get("month", 1))
	# 同上：大标题只给日期（日历式），剧情标题留给事件面板当场揭示。
	var when := "第 %d 月 %02d 日" % [event_month, int(next_event.get("day", 1))]
	var left: String = "还有 %d 个月" % months_left if months_left > 0 else "本月内"
	_set_objective(
		"下一个主线",
		when,
		"%s · 到点后地面才会出现指引线" % left,
		"%s 区" % String(upcoming_zone.get("code", "?")),
		false
	)


func _is_event_due(event: Dictionary, snapshot: Dictionary) -> bool:
	if WorldClock.running:
		return false
	var event_minute := ((int(event.get("month", 1)) - 1) * 30 + (int(event.get("day", 1)) - 1)) * 24 * 60 + int(event.get("hour", 9)) * 60
	return int(snapshot.get("worldMinute", 0)) >= event_minute


func _build_interior_preview() -> void:
	_interior_preview = INTERIOR_PREVIEW.new()
	_interior_preview.exit_requested.connect(_exit_zone)
	_interior_preview.player_message_submitted.connect(_on_interior_message_submitted)
	add_child(_interior_preview)

func _build_story_event_panel() -> void:
	_story_event_panel = STORY_EVENT_PANEL.new()
	_story_event_panel.choice_confirmed.connect(_on_story_choice_confirmed)
	_story_event_panel.outcome_acknowledged.connect(_on_story_outcome_acknowledged)
	_story_event_panel.decision_opened.connect(_on_decision_opened)
	_story_event_panel.choice_hovered.connect(_on_choice_hovered)
	_story_event_panel.handbook_recorded.connect(_on_handbook_recorded)
	_story_event_panel.memo_recorded.connect(_on_memo_recorded)
	add_child(_story_event_panel)
	_on_ui_preferences_changed(_town_ui_v2.preferences())


func _build_action_window() -> void:
	_action_window = ACTION_WINDOW.new()
	_action_window.window_started.connect(_on_action_window_started)
	_action_window.action_spent.connect(_on_action_spent)
	_action_window.window_finished.connect(_on_action_window_finished)
	add_child(_action_window)

	_activity_panel = AREA_ACTIVITY_PANEL.new()
	_activity_panel.activity_selected.connect(_on_activity_selected)
	add_child(_activity_panel)

	_weekend_scene_panel = WEEKEND_SCENE_PANEL.new()
	_weekend_scene_panel.finished.connect(_on_weekend_scene_finished)
	add_child(_weekend_scene_panel)


func _build_assessment_panel() -> void:
	_assessment_panel = ASSESSMENT_PANEL.new()
	_assessment_panel.continued.connect(_on_assessment_continued)
	add_child(_assessment_panel)


func _load_achievement_nodes() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ACHIEVEMENT_PATH))
	if parsed is Dictionary:
		_achievement_nodes = parsed.get("nodes", [])


func _build_achievement_panel() -> void:
	_achievement_panel = ACHIEVEMENT_PANEL.new()
	_achievement_panel.continued.connect(_on_achievement_continued)
	add_child(_achievement_panel)


func _refresh_activity_panel() -> void:
	if _activity_panel == null or _action_window == null:
		return
	if not _action_window.active or _active_zone.is_empty():
		_activity_panel.hide_panel()
		return
	var zone_id := String(_active_zone.get("code", ""))
	var activities := _action_window.activities_for_region(zone_id)
	if activities.is_empty():
		_activity_panel.hide_panel()
		return
	_activity_panel.show_for_region(zone_id, activities, _action_window.remaining, ActionWindow.POINTS_PER_WINDOW)


func _on_activity_selected(activity: Dictionary) -> void:
	if _activity_busy or _action_window == null or not _action_window.active:
		return
	_activity_busy = true
	_pending_action_activity = activity.duplicate(true)
	_activity_panel.hide_panel()
	var loading := CanvasLayer.new()
	loading.layer = 155
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.02, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading.add_child(shade)
	var label := Label.new()
	label.text = "正在前往 · %s" % String(activity.get("title", "活动场景"))
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-260, -30)
	label.size = Vector2(520, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", CHINESE_FONT)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color("f5dfae"))
	loading.add_child(label)
	add_child(loading)
	await get_tree().create_timer(0.7).timeout
	loading.queue_free()
	_weekend_scene_panel.present({
		"title": String(activity.get("title", "区域活动")),
		"image": String(activity.get("image", "")),
		"lines": activity.get("lines", []),
	})


func _on_action_window_started(snapshot: Dictionary) -> void:
	_refresh_town_ui_v2()
	_show_reminder_toast("自由活动窗口开始", "获得 3 点行动力，只能通过区域活动消耗；只有消耗完 3 点行动力，才会解锁下一段剧情。")
	_refresh_activity_panel()
	_refresh_objective_hint()


func _on_action_spent(snapshot: Dictionary, record: Dictionary) -> void:
	ApiClient.record_event("action_spent", {
		"regionId": String(_active_zone.get("code", "A")) if not _active_zone.is_empty() else "A",
		"activityId": String(record.get("targetId", "")),
		"activityKind": String(record.get("kind", "")),
		"windowId": String(record.get("windowId", "")),
		"month": int(WorldClock.snapshot().get("month", 1)),
		"remainingAfter": int(record.get("remainingAfter", 0)),
	})
	_refresh_town_ui_v2()
	if _activity_panel != null:
		_activity_panel.refresh_points(int(snapshot.get("remaining", 0)), int(snapshot.get("maximum", 3)))
	if not _tutorial_complete and _tutorial_step < 4:
		_tutorial_step = 4
		_show_reminder_toast("行动力已成功消耗", "继续完成区域活动，直到剩余 0/3")
	_refresh_objective_hint()


func _on_action_window_finished(snapshot: Dictionary) -> void:
	if _activity_panel != null:
		_activity_panel.hide_panel()
	if _action_window != null and _action_window.has_pending_window():
		_show_reminder_toast("本窗口行动结束", "文档中的下一个自由活动窗口即将开始")
		_action_window.continue_pending_window()
		return
	if not _tutorial_complete:
		_tutorial_complete = true
		_tutorial_step = 5
		_show_reminder_toast("操作教学完成", "任务板已切换到下一主线，跟随地面路线继续")
	_advance_after_story(String(snapshot.get("afterEvent", "")))


## 心湖记忆墙。数据在磁盘上，所以它是常驻节点 —— 不依附于任何一次剧情事件。
func _build_memory_wall() -> void:
	_memory_wall = MEMORY_WALL.new()
	_memory_wall.name = "MemoryWall"
	_memory_wall.wall_closed.connect(_on_memory_wall_closed)
	_memory_wall.setup(null)
	add_child(_memory_wall)


func _open_memory_wall() -> void:
	if _memory_wall == null:
		return
	if _memory_wall.is_open():
		return
	# 开墙期间世界时钟停住，避免阅读时主流程变化。
	_wall_resume_clock = WorldClock.running
	if _wall_resume_clock:
		WorldClock.set_running(false)
	_memory_wall.open()


func _on_memory_wall_closed() -> void:
	var resume := _wall_resume_clock
	_wall_resume_clock = false
	if resume:
		WorldClock.set_running(true)


## ---------- 你的处境（Batch 6 · V5.27 §2.4 明示原则） ----------

## 常驻一页，随时能翻（§2.4「随时能查」）。内容全渲染服务端下发的字段，
## 本地一个数都不算 —— 口径只留服务端一份（2026-09-17 拍板）。
func _build_standing_panel() -> void:
	_standing_panel = STANDING_PANEL.new()
	_standing_panel.name = "StandingPanel"
	_standing_panel.standing_closed.connect(_on_standing_closed)
	add_child(_standing_panel)
	# 每次服务端回包都会刷新权威状态 → 顺手更新警示点。
	# 接 event_recorded 而不是 session_ready：后者一个会话只发一次，
	# 而处境是**会变的**（第 N 月埋了雷，就要当场亮）。
	ApiClient.event_recorded.connect(_on_standing_state_refreshed)
	_refresh_standing_badge()


func _open_standing() -> void:
	if _standing_panel == null:
		return
	if _standing_panel.is_open():
		return
	# 翻这一页时暂停主流程，避免阅读中切换状态。
	_standing_resume_clock = WorldClock.running
	if _standing_resume_clock:
		WorldClock.set_running(false)
	# 月份取世界时钟（玩家眼里的「现在第几月」），
	# 职级与处境取服务端（结算权威）。两者在跳月时会有差 —— 这是对的：
	# 账要等主线结算才算，而日历已经翻过去了。
	_standing_panel.open(ApiClient.server_state(), int(WorldClock.snapshot().get("month", 0)))


func _on_standing_closed() -> void:
	if _standing_resume_clock:
		WorldClock.set_running(true)
		_standing_resume_clock = false


## 服务端回包后刷新警示点（信号回调带两个参数，用不上）。
func _on_standing_state_refreshed(_envelope: Dictionary, _response: Dictionary) -> void:
	_refresh_standing_badge()


## 「处」钮上的点：处境不再是「稳定」就亮。
## 只做提示，不含任何数字 —— 想知道为什么，点进去看那一页。
func _refresh_standing_badge() -> void:
	if _standing_dot == null:
		return
	var view := Dictionary(ApiClient.server_state().get("survivalState", {}))
	var state_name := String(view.get("state", ""))
	var lit := state_name in ["observation", "critical", "last_talk"]
	_standing_dot.visible = lit
	if not lit:
		return
	var style := _standing_dot.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		# 观察给琥珀（还没到悬崖边），危急及以上给红（再一步就是正式谈话）。
		var dot_color := Color("e0a63c") if state_name == "observation" else Color("e5503f")
		(style as StyleBoxFlat).bg_color = dot_color


func _open_due_event_for_active_zone() -> bool:
	var next_event := WorldClock.next_main_event()
	if next_event.is_empty() or _active_zone.is_empty():
		return false
	# 自由活动窗口期间，主线即使地点相同也不能抢先开启。
	# 玩家必须把三点行动力通过区域活动消耗完。
	if _action_window != null and _action_window.active:
		return false
	if String(next_event.get("locationId", "")) != String(_active_zone.get("code", "")):
		return false
	if WorldClock.running or not _is_event_due(next_event, WorldClock.snapshot()):
		return false
	_story_event = next_event.duplicate(true)
	if not _tutorial_complete and _tutorial_step < 2:
		_tutorial_step = 2
		_show_reminder_toast("教学 3/5 · 完成第一段剧情", "阅读对话并做出选择，结算后会进入自由活动窗口")
		_refresh_objective_hint()
	_story_event_panel.present(_story_event)
	return true


func _begin_interaction() -> void:
	if not _nearby_npc.is_empty():
		var npc_id := String(_nearby_npc.get("id", ""))
		if _town_ui_v2 != null:
			_open_phone_chat(npc_id)
		return
	var next_event := WorldClock.next_main_event()
	if not _active_zone.is_empty() and not next_event.is_empty() and not WorldClock.running \
			and (_action_window == null or not _action_window.active) \
			and _is_event_due(next_event, WorldClock.snapshot()) \
			and String(next_event.get("locationId", "")) == String(_active_zone.get("code", "")):
		_story_event = next_event.duplicate(true)
		_story_event_panel.present(_story_event)
		if not _tutorial_complete and _tutorial_step < 2:
			_tutorial_step = 2
		return
	return


func _begin_primary_action() -> void:
	if not _active_zone.is_empty():
		_begin_interaction()


func _hide_dialog() -> void:
	if _dialog_label != null:
		_dialog_label.hide()

## 退出游戏：直接结束程序。标题页那个「退出游戏」按钮也是同一个动作。
func _quit_game() -> void:
	get_tree().quit()

## 记忆便签落盘：心湖记忆墙的唯一数据源。
## 便签原本是「弹一下就没了」的装饰，写进 user:// 之后玩家下次进游戏还能翻到
## 「第 1 月 15 日 · 新员工手册」当时贴了什么 —— 这是 E27 那句质问的情感承重墙。
func _on_memo_recorded(event_id: String, memo: Dictionary) -> void:
	if event_id.is_empty() or memo.is_empty():
		return
	var line := memo.duplicate(true)
	line["eventId"] = event_id
	line["worldMinute"] = WorldClock.world_minute
	var file := FileAccess.open("user://workplace_town_memos.jsonl", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("user://workplace_town_memos.jsonl", FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(line))
	file.close()

func _on_story_choice_confirmed(event_id: String, choice_id: String, duration_minutes: int) -> void:
	var event_data := WorldClock.next_main_event()
	var region_id := String(event_data.get("locationId", ""))
	ApiClient.record_event("option_click", {
		"regionId": region_id,
		"storyId": event_id,
		"choiceId": _contract_choice_id(event_id, choice_id),
		"hesitationMs": maxi(0, Time.get_ticks_msec() - _decision_opened_msec),
		"switchCount": maxi(0, _choice_hover_count - 1),
		"snapshot": WorldClock.snapshot(),
	}, duration_minutes * 60)


## 主线结算后由文档配置决定进入行动窗口或直接跳到下一事件。
func _on_story_outcome_acknowledged(event_id: String, choice_id: String, duration_minutes: int) -> void:
	var file := FileAccess.open("user://workplace_town_events.jsonl", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("user://workplace_town_events.jsonl", FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify({"eventId": event_id, "choiceId": choice_id, "durationMinutes": duration_minutes, "worldMinute": WorldClock.world_minute}))
	_story_event_panel.dismiss()
	WorldClock.complete_main_event(event_id)
	_story_event = {}
	if not _tutorial_complete and event_id == "E01":
		_tutorial_step = 3
		_show_reminder_toast("第一段剧情已完成", "前往其他场景参加区域活动，消耗完 3 点行动力后才能解锁下一段剧情。与 NPC 交流不消耗行动力。")
	if _interior_preview != null and _interior_preview.is_open():
		_interior_preview.enable_exploration()
	_advance_after_story(event_id)


func _advance_after_story(event_id: String) -> void:
	if event_id == "E35":
		_open_finale()
		return
	for node in _achievement_nodes:
		if String(node.get("afterEvent", "")) == event_id and not _achievement_seen_ids.has(String(node.get("id", ""))):
			WorldClock.set_running(false)
			_achievement_panel.open(node)
			return
	var upcoming := WorldClock.next_main_event()
	var next_month := int(upcoming.get("month", 49))
	for month in ASSESSMENT_MONTHS:
		if month < next_month and not _assessment_seen_months.has(month):
			WorldClock.set_running(false)
			_assessment_panel.open(month)
			return
	if _action_window != null and _action_window.start_after_event(event_id):
		_refresh_objective_hint()
		return
	if not _training_first_cleared and WorldClock.completed_main_event_ids().has("E07"):
		_open_training_first()
		return
	WorldClock.jump_to_next_main_event()
	_refresh_objective_hint()


func _on_assessment_continued(month: int) -> void:
	if not _assessment_seen_months.has(month):
		_assessment_seen_months.append(month)
	var completed := WorldClock.completed_main_event_ids()
	_advance_after_story(completed[-1] if not completed.is_empty() else "")


func _on_achievement_continued(node_id: String, choice_id: String) -> void:
	if not _achievement_seen_ids.has(node_id):
		_achievement_seen_ids.append(node_id)
	for node in _achievement_nodes:
		if String(node.get("id", "")) != node_id:
			continue
		var note := {"eventTitle": node.get("title", ""), "text": node.get("memory", ""), "tone": "gold", "month": int(WorldClock.snapshot().get("month", 1)), "day": 1}
		_on_memo_recorded(node_id, note)
		break
	ApiClient.record_event("achievement_view", {"regionId": "A", "storyId": node_id, "choiceId": choice_id})
	var completed := WorldClock.completed_main_event_ids()
	_advance_after_story(completed[-1] if not completed.is_empty() else "")


func _open_training_first() -> void:
	if _training_overlay != null:
		return
	WorldClock.set_running(false)
	_training_overlay = CanvasLayer.new()
	_training_overlay.layer = 195
	add_child(_training_overlay)
	var frame := Control.new()
	frame.size = Vector2(1280, 720)
	frame.scale = get_viewport_rect().size / frame.size
	_training_overlay.add_child(frame)
	var battle := TRAINING_SCENE.instantiate()
	frame.add_child(battle)
	battle.training_completed.connect(_on_training_first_completed)
	battle.training_result.connect(_on_training_result)
	ApiClient.record_event("node_enter", {"regionId": "E", "storyId": "training_valley_1"})


func _on_training_result(result: Dictionary) -> void:
	ApiClient.record_event("training_result", {
		"regionId": "E", "activityId": "training_valley_1",
		"month": int(WorldClock.snapshot().get("month", 1)), "result": result,
	})


func _on_training_first_completed() -> void:
	_training_first_cleared = true
	ApiClient.record_event("task_complete", {"regionId": "E", "activityId": "training_valley_1"})
	_training_overlay.queue_free()
	_training_overlay = null
	_advance_after_story("E07")

## 终局演出：E35 结算后触发。
## 报告交棒交给 FinalePanel 默认的「查看我的职业报告」按钮（直接实例化 ReportPanel.open()）。
func _open_finale() -> void:
	if _finale == null:
		_finale = FINALE_PANEL.new()
		add_child(_finale)
	var bears: Array = []
	var state := ApiClient.server_state()
	var stages: Dictionary = state.get("npcRelationStage", {})
	var names := {"wang_ge": "王哥", "xiao_lin": "小林", "xiao_zhao": "小赵", "lao_zhou": "老周"}
	for npc_id in ["wang_ge", "xiao_lin", "xiao_zhao", "lao_zhou"]:
		var stage_text := String(stages.get(npc_id, "关系记录同步中"))
		var level := 1
		if stage_text.begins_with("Lv"):
			level = int(stage_text.trim_prefix("Lv"))
			stage_text = ["点头之交", "渐渐熟悉", "并肩伙伴", "彼此信任", "可以托底"][clampi(level - 1, 0, 4)]
		bears.append({"id": npc_id, "name": names[npc_id], "level": level, "stage": stage_text})
	_finale.setup(bears)


func _on_decision_opened(event_id: String) -> void:
	_decision_opened_msec = Time.get_ticks_msec()
	_choice_hover_count = 0
	_last_hovered_choice_id = ""
	ApiClient.record_event("node_enter", {
		"regionId": String(_active_zone.get("code", "")),
		"storyId": event_id,
	})

func _on_choice_hovered(event_id: String, choice_id: String) -> void:
	if choice_id == _last_hovered_choice_id:
		return
	_last_hovered_choice_id = choice_id
	_choice_hover_count += 1
	ApiClient.record_event("option_hover", {
		"regionId": String(_active_zone.get("code", "")),
		"storyId": event_id,
		"choiceId": _contract_choice_id(event_id, choice_id),
		"hoverCount": _choice_hover_count,
	})

## 手册阅读埋点：V5.27 对 E01 的要求是记录「各章阅读时长与跳过行为」。
## 这份数据回答的是"玩家第一天到底想先弄明白什么"——比选项本身更早暴露取向。
func _on_handbook_recorded(event_id: String, records: Dictionary) -> void:
	if records.is_empty():
		return
	var line := {
		"eventId": event_id,
		"totalMs": int(records.get("totalMs", 0)),
		"chapters": records.get("chapters", {}),
		"worldMinute": WorldClock.world_minute,
	}
	var file := FileAccess.open("user://workplace_town_handbook.jsonl", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("user://workplace_town_handbook.jsonl", FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify(line))
		file.close()
	# 契约事件名是 manual_read（openapi PlayerEvent.eventType / constants.TRACKING_EVENTS），
	# 旧名 handbook_read 不在枚举里 → 报告侧永远读不到，等于埋了个寂寞还污染事件流。
	ApiClient.record_event("manual_read", {
		"regionId": String(_active_zone.get("code", "")) if not _active_zone.is_empty() else "B",
		"storyId": event_id,
		"totalMs": line["totalMs"],
		"chapters": line["chapters"],
		"snapshot": WorldClock.snapshot(),
	})

func _on_interior_message_submitted(npc_id: String, message: String) -> void:
	var region_id := String(_active_zone.get("code", "")) if not _active_zone.is_empty() else "A"
	ApiClient.request_npc_chat(npc_id, message, region_id)

func _contract_choice_id(event_id: String, choice_id: String) -> String:
	if choice_id.begins_with("option_"):
		var suffix := choice_id.trim_prefix("option_")
		var index: String = String({"a":"01", "b":"02", "c":"03"}.get(suffix, suffix))
		return "%s-C%s" % [event_id, index]
	return choice_id
