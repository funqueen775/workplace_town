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
## 区域活动演出：全屏场景图 + 底部逐字文字。
const WEEKEND_SCENE_PANEL := preload("res://scripts/WeekendScenePanel.gd")
const TOWN_UI_V2 := preload("res://scripts/TownUiV2.gd")
const HUD_TOUR := preload("res://scripts/ui/HudTour.gd")
const MONTH12_ACTIVITY := preload("res://scripts/v12m/Month12ActivityPanel.gd")
const MONTH12_CLOSE := preload("res://scripts/v12m/Month12ClosePanel.gd")
const MONTH12_START := preload("res://scripts/v12m/MonthStartPanel.gd")
const HANDBOOK_PANEL := preload("res://scripts/HandbookPanel.gd")
const PHONE_INBOX := preload("res://scripts/v12m/PhoneInboxPanel.gd")
const HUD_BUTTON_TUTORIAL := preload("res://scripts/v12m/HudButtonTutorialCard.gd")
## B 方案：按事件表播一个月（第 2 月起）。
const MONTH_NODE_RUNNER := preload("res://scripts/v12m/MonthNodeRunner.gd")
## 到访制的进门确认页（12 个月 F 段，替代旧的中央菜单）。
const PLACE_VISIT_PANEL := preload("res://scripts/v12m/PlaceVisitPanel.gd")
const MONTH12_PLACES_PATH := "res://data/story/v12m/activities.json"
## 提示条表：一个月在哪些时刻该说什么，全在这份文件里（4.20 起由它驱动）。
const MONTH12_HINTS_PATH := "res://data/story/v12m/hints.json"
## 全年参数（每月几格行动点、心情上限、月初回几点）只有这一份出处。
const MONTH12_MANIFEST_PATH := "res://data/story/v12m/manifest.json"
## 判定门槛（三条红线、转正两态、晋升规则表）只认这一份文件，代码里不写数（4.21）。
## 缺字段一律往轻的那边退：配置没写全时，宁可放过，不可误判玩家不合格。
const MONTH12_RUBRICS_PATH := "res://data/story/v12m/rubrics.json"
## 十二个月的时间过场：跨旬 / 时段 / 翻月 / 昼夜四档，压在面板之上、提示条之下。
const TRANSITION_WIPE := preload("res://scripts/v12m/TransitionWipe.gd")
const MONTH12_HANDBOOK_PATH := "res://data/story/employee_handbook_12m.json"
## 门槛横幅左边那颗圆徽直接用右下角手机那张贴图：一看就知道说的是手机，
## 不用再来解释「息是什么」。
const GATE_PHONE_CHIP := preload("res://assets/ui/rework_v1/hud/components/16_圆钮统一_phone.png")
const GROUND_GUIDE := preload("res://scripts/ui/GroundGuideLine.gd")
const CHINESE_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const JOYSTICK_BASE := preload("res://assets/ui/rework_v1/hud/revisions/01_摇杆底图.png")
const JOYSTICK_KNOB := preload("res://assets/ui/rework_v1/hud/revisions/02_摇杆爪子按钮.png")
const TOWN_MAP_PATH := "res://assets/town/workplace_town_no_labels.png"
## 手机通讯录：主世界四位常驻同事，列表里固定都在，谁有新消息谁那行亮红点。
const PHONE_CONTACTS := [
	{"id": "wang_ge", "name": "王哥", "role": "技术导师"},
	{"id": "chen_gong", "name": "陈工", "role": "邻组 Leader"},
	{"id": "xiao_lin", "name": "小林", "role": "产品"},
	{"id": "lao_zhou", "name": "老周", "role": "老同事"},
]
## 会发消息但不是常驻的人（小赵）：有消息才临时出现在通讯录里。
const PHONE_EXTRA_CONTACTS := [
	{"id": "xiao_zhao", "name": "小赵", "role": "邻组同事"},
]
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
## 站在不该站的地方时，允许按输入方向硬挪的总额（像素）：够从树丛、水面走回路面，
## 不足以穿整栋楼。用完还没踩回路面就吸附到最近一块走得开的地面。
const STUCK_ESCAPE_PX := 160.0
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
## 到访制的门：走近到这个距离就给「按 E 进去」。比自动传送口宽一点，
## 门是玩家主动要进的地方，不该逼他踩在点上。
const PLACE_REACH_DISTANCE := 96.0
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
## 首月带巡的黄线：比旧线放宽一点（18 像素 ≈ 角色走半步）。
## 玩家走路时大约每半步重铺一次路，看上去是"线在跟着我改"，又不会抖。
const MONTH12_GUIDE_REPATH := 18.0
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
## 右上角那排没有字的圆钮已删（2026-10-27）：记忆墙 / 你的处境收进「档案」页。
## 档案圆钮也已于 2026-10-29 撤下（它没有独有内容），入口改到左上角那条岗位栏：
## 点它就开档案页，处境警示改写成岗位栏下面一行字，见 _refresh_standing_line()。
## 设置弹窗与它的停钟还原（同记忆墙的待遇：开着时世界时钟停住）。
var _settings_panel
var _settings_resume_clock := false
## 顶部提醒横幅。整条横幅在超时后自毁。
var _toast_layer: CanvasLayer
var _toast_panel: Panel
## 门槛横幅：不像提示条那样自己溜走，玩家不点不收（第 3 月「先看手机」用的就是它）。
var _gate_banner: Panel
## 钉住的那条是哪条提示、什么条件下收（数据里 persist=true 的提示带 dismissOn）。
var _gate_banner_hint: Dictionary = {}
## 上一帧的节点 id：节点一换就按 dismissOn 收掉对应的钉住提示。
var _last_month_node_id := ""
var _toast_tween: Tween
var _dialog_label: Label
var _dialog_timer: Timer
var _last_walkable_position := Vector2.ZERO
## 硬挪额度，踩回路面就补满（见 STUCK_ESCAPE_PX）。
var _escape_left := STUCK_ESCAPE_PX
## 进入室内前预先选好的主世界安全落点，避免退出时落进建筑碰撞或传送门感应区。
var _portal_return_position := Vector2.ZERO
var _debug_overlay
var _collision_debug_polygons: Array = []
var _coordinate_label: Label
var _walkability_image: Image
## 引导线寻路用的步行网格（从同一张通行遮罩推出来）。
var _walk_grid := TownWalkGrid.new()
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
var _hud_tour
var _hud_tour_active := false
var _hud_tour_done := false
## HUD 讲解等界面摆好的重试计数：等不到就跳过，不能把第 1 月堵死。
var _hud_tour_retries := 0
var _phone_chat_history: Dictionary = {}
var _interior_preview: InteriorPreview
var _environment_tint: ColorRect
var _story_event_panel: StoryEventPanel
var _story_event: Dictionary = {}
## 十二个月开场：进镇先播 E01 入职说明会 + 王哥带巡（数据来自 data/story/v12m/events.json）。
## 这一步只接开场；手机收件箱、1 点行动力、E02 仍走旧的 ActionWindow，别把这段当整月已接完。
const MONTH_OPENING_PATH := "res://data/story/v12m/events.json"
var _month_opening_events: Dictionary = {}
## 12 个月首月总开关：从进镇播 E01 起，到月末回顾结束都由这段流程接管；
## 旧的 WorldClock 主线/教程/行动力窗口在此期间全部让路。
var _month12_active := false
var _month12_phase := ""
## 当前在播第几个月；第 2 月起由节点播放器驱动。
var _month12_month := 1
var _month_runner
## 月末卡正文：节点播放器按旗标拼好后放这儿，月末卡照常走。
var _month_close_text_override := ""
## 月末卡落在哪一旬：首月是中旬，之后按节点表里写的（通常是下旬）。
var _month_close_phase := "mid"
var _month12_waypoint := Vector2(-99999, -99999)
## 上一次给黄线铺路时玩家站在哪儿：离它超过 MONTH12_GUIDE_REPATH 就重新寻路。
var _month12_guide_from := Vector2(-99999, -99999)
var _month12_tour_index := 0
var _tour_card_after := Callable()
var _month12_e02_choice := ""
var _month12_flags: Dictionary = {}
## 能力五格的本镇账（开发文档 4.19）：选项与剧情拍上的 abilityTags 累在这里，
## 攒点最多加到第 4 格，第 5 格只由 abilityPeak 点亮（peak_<能力> 旗标）。
## 后端也有一本同样的账；这边留一本是为了没连后端时档案页不装成半熟手。
var _ability_points: Dictionary = {}
## 跳月看片用的那条路线（A/B/C）与命令行指定的目标月，只在调试档里生效。
var _jump_path := "A"
## F9 调出来的跳月面板（十二格）：只在调试用，玩家包里没人按得到。
var _jump_panel: CanvasLayer
## 面板上那行"这一局走哪条路"的说明文字（选路线时刷新它）。
var _jump_route_caption: Label
var _jump_target := 0
var _month12_handbook
## 手册节点解锁的新页：下一次翻开直接定位到它（剧情点到哪儿，就翻到哪儿）。
var _handbook_pending_page := ""
var _month12_activity_panel
var _month12_close_panel
var _month12_start_panel
var _month12_start_next := Callable()
var _month12_skip_walk := false
## 从月末卡跳去看档案时置真：档案页关掉后要把月末卡放回来。
var _archive_return_to_close := false
## 首月手册讲解卡选了「打开手册」：等手册页关掉再去跨组周会。
var _manual_card_pending := false
## 上一屏剧情演在哪儿、人站在哪：同一地点、人没挪窝的连续节点（第 12 月那九问）
## 不再铺一次黄线、不再播一次入场卡，直接问完接下一题。
var _last_story_scene := ""
var _last_story_point := Vector2(-99999, -99999)
## 离开原地多远就不算"还站在刚才那一屏"：两步路以内接着问，走出去就得重新到场。
const SAME_SCENE_KEEP := 80.0
## 首月活动去处：三扇门在自由活动开始时一起出现，由玩家自己选择先去哪里。
var _month12_places: Array = []
var _month12_place_portals := {}
## 门开过就一直在：记下已经解锁的去处，后面的月份不用再列一遍也还在镇上。
var _month12_unlocked_places := {}
## 本月必玩是否已经做完：做完之前，不开放的门口压成灰；做完那一刻一起亮回来。
var _month12_places_open := false
var _month12_place_panel
var _month12_nearby_place := ""
var _month12_activity_taken := false
## 剧情拍上挂的解锁钩子：这一屏读完才立门、弹讲解卡，卡关掉当月才接着走。
var _pending_story_hooks: Array = []
## 靠 unlockAfter 解锁的去处：那一屏读完同样要弹讲解卡，排队方式和钩子一样。
## 以前只认 unlockAfter == "E02"，第 7/9/11 月的四处门是"悄悄亮"的，一张卡都没有。
var _pending_unlock_places: Array = []
var _hook_queue: Array = []
var _hook_after := Callable()
## 讲解卡上点了「带我去」：记住目的地，等这个月的门都立好再铺黄线。
var _hook_nav_zone := ""
## 通用月份的自由安排：格数从节点里读（第 3 月起是 2 格），不再写死首月那一格。
var _month12_activity_generic := false
## ---------- 五本账里先做成真账的两本（4.15）----------
## 心情 H：0–上限（manifest.hMax），月初回 1 点封顶；一处活动给回多少走 stateDelta.H，
## 额外消耗走 hCost，且 H≤2 时消耗翻倍（行动点不翻）。
var _mood := 6
var _mood_max := 6
var _mood_month_start := 6
## 行动点：每月几格从 manifest.apByMonth 读（1/3/5/7/9/11 = 1/2/2/3/3/3），月底清零不跨月。
var _ap_total := 0
## 这个月做过的每一笔，月末卡当场结算给玩家看：{"what","ap","mood"}
var _month_ledger: Array = []
var _mood_h_init := -1
## 心情读数亮不亮、以及"这个月刚亮起来"没有：亮起来这件事要搭在本来就要弹的那条提示上，
## 不另开一次停顿（解锁预算）。
## 这一笔结算前的心情读数：事件要写"从几到几"，不能只写结果。
var _mood_before_settle := 0
var _mood_meter_lit := false
var _mood_meter_just_lit := false
var _ap_by_month := {}
var _month12_ap_left := 0
var _month12_slots_left := 0
var _month12_slots_total := 0
## 这一屏自由安排是当天哪一段（午后/夜里/白天）：写进卡片副行。
var _activity_band_word := ""
## 自由安排后面紧跟的是不是月末卡：决定"结束这个月"这颗按钮叫什么、按下要不要解释。
var _activity_next_is_close := false
## 进了活动专属场景（天台、湖边）时把同事藏起来，出来还原。
var _month12_scene_npcs_hidden := false
## 首月不为每个地点单独弹解锁卡；活动入口同时出现，到达地点后再看活动确认页。
var _end_month_button: Button
## 剧情带路立出来的那扇门（目前只有第 2 月的图书馆）。
var _story_door: Node2D
## 这扇门是哪个钩子立起来的：台词先响，门才立，落点按钩子查。
var _story_door_hook := ""
## 剧情那一眼：节点上写着 enterPlace，播放器就停在这一步，
## 等玩家自己走到门口、按 E 进门、在屋里点那一行，才演这一屏。
var _month12_visit_node: Dictionary = {}
var _month12_visit_id := ""
## 提示条：表只读一次；_hint_fired 记已经弹过的（once）。
var _hints: Array = []
var _hint_fired: Dictionary = {}
## 上一帧脚边有没有门：只在"刚走到门口"那一刻弹一次 portal_reached。
var _hint_at_portal := false
## 走位兜底：黄线走了太久还没到，就允许按 E 直接过去（只跳走路，不跳内容）。
var _walk_started_msec := 0
var _walk_skip_offered := false
## 探针专用：开了就把"这一屏为什么没补收尾句"打到标准输出。玩家跑的时候是 false。
var _debug_departure := false
## 续玩：开机时从存档里接回的心情（-1 = 不接）。见 _try_resume_saved_month。
var _resume_mood := -1
const MONTH12_SAVE_PATH := "user://workplace_town_month12.json"
## 续玩还没上线（2026-10-30 晚拍板）：点「开始游戏」一律从第 1 月开始。
## 读存档、接月份/旗标/心情这一套代码留着，但不参与正式开局；
## 要验续玩（探针，或存档功能真正开做时）加 `-- --v12m-resume` 才打开这条路。
const MONTH12_RESUME_ARG := "--v12m-resume"
## 心湖记忆墙的数据：一局一份，新开局清一次（见 _begin_new_run）。
const MONTH12_MEMO_PATH := "user://workplace_town_memos.jsonl"
## 这一局的编号：贴在每张便签上，墙只显示本局的。旧版没有这个号，
## 所以老存档第一次续玩时也会重发一个号并把墙清掉——不然旧 48 个月的便签会混进来。
var _run_stamp := 0
## 四维证据：答辩判定用。每次选完把这条选项的能力锚点收进来，取各维最高那档。
var _dim_anchors := {"S": [], "O": [], "N": [], "D": []}
## 判定门槛缓存（rubrics.json 第一次用到时读进来）：红线、转正两态、晋升规则表都在这。
var _rubrics: Dictionary = {}
## 看手机/手册时把走位计时真正停住：关掉后从原处继续，不会被一口气拽走。
var _walk_pause_started_msec := 0
## 回宿舍那一夜：记着睡的是哪个月，睡醒翻到下一个月。
var _month12_sleep_month := 0
## 月中那一觉（第 2 月"先回去休息"）：睡醒不翻月，天亮接着走这个月的节点表。
var _sleep_then := Callable()
var _sleep_wake_phase := "early"
## 这一觉睡过去多久（"两周后"）：有值时黑场里亮一句，醒来直接落新旬，不再补一张旬卡。
var _sleep_gap_text := ""
## 剧情门的落点。不能照抄 regions.json 的 entrance：那个点是给旧 48 个月摆传送门用的，
## 图书馆这一处正压在镇子东墙里（墙占 x 1442–1460），玩家物理上走不过去，
## 黄线也寻不到路。这里写的是墙内最近的一块空地（书院牌楼斜对面）。
const STORY_DOOR_POSITIONS := {
	"door_library": Vector2(1424, 720),
	# 第 5 月会展码头：F 区在北侧开口，门就立在镇子最南边那排台阶前
	# （和 MONTH_NODE_POINTS 的 M05_DEMO 同一个点）。
	"door_expo": Vector2(702, 833),
}
## 左上角日期栏的当前读数：月 / 旬 / 白天夜晚 / 日内时段。
## 只由节点数据给（phase、timeBand），客户端不推算日子，也不显示钟点。
var _wipe: TransitionWipe
var _date_month := 0
var _date_xun := ""
var _date_band := ""
var _date_time_band := ""
## 下一次昼夜换灯用多长：走位途中换昼夜要跟着整段路慢慢暗，原地换旬不用。
## 由 _walk_date_first 在出发前写，_apply_date_band 用完就清。
var _band_fade_seconds := 0.0
## 过场期间锁移动；提示条等过场播完再出。
var _date_cutscene_lock := false
var _pending_toasts: Array = []
## 过场还在播时欠着的门槛提示（过场结束后补钉上去）。
var _pending_gate_banners: Array = []
## 时间过场是闸门：剧情面板还开着就先不播，播完再开下一件事。
## 直接播会把卡片压在刚打开的对话/手册上，看着像剧情被打断（2026-10-27 反馈）。
var _date_then_queue: Array = []
var _date_wait_panel: Array = []
var _date_debug := false
var _date_debug_step := 0
## 12m 首月手机：E01_TOUR 的信到了才解锁右下角手机；未读时点开直接进陈工这条。
var _month_phone_messages: Array = []
## 全年手机往来的流水（谁、说了什么）。收件箱每月会覆盖，这里只追加，
## 剧情里弹手机时拿它当上下文，让玩家看得到前因，不是孤零零一句。
var _phone_log: Array = []
## 剧情里的说话人名字 → 手机通讯录 id（头像靠它取，别再用默认那只熊）。
const MONTH12_PHONE_CONTACTS := {
	"王哥": "wang_ge",
	"陈工": "chen_gong",
	"小赵": "xiao_zhao",
	"小林": "xiao_lin",
	"老周": "lao_zhou",
}
var _month_phone_unread := false
## 当前这批消息的时间话（"第 3 月 · 周三上午"）：手机刚打开时那几条还没有逐条时间，
## 回复也还没落时间，都靠它兜底——以前这里写死"今天 10:20"，跟消息自己的时间对不上。
var _month_phone_date_text := ""
## 当前这批消息的发件人（senderId / senderName / senderRole）。
## 以前抽屉上的联系人写死成首月的陈工，第三月王哥发来的两条也顶着"陈工"的名字。
var _month_phone_contact: Dictionary = {}
## 手机通讯录的真身：senderId → {messages, unread, date, reply_options}。
## 每月的新消息按发件人往对应会话里追加，不再是"整机只存最后一批"。
var _phone_threads: Dictionary = {}
## 已经投递过的批次（batchId）：重播同一节点不该把同一句话再塞一遍。
var _phone_delivered_batches: Dictionary = {}
## 这一批消息是剧情的前置（第 3 月：不看王哥那两条就不知道为什么要去见客户）：
## 玩家没点开手机之前，节点播放器停在这批消息上，不给下一屏铺黄线。
var _phone_gate_waiting := false
var _phone_gate_read := false
var _month_phone_replied := false
var _month_phone_reply_options: Array = []
## 首月真手机：用 12m 那套手机外形抽屉，不用 HUD 里的方形卡片。
var _month_phone_panel
var _hud_button_tutorial
var _hud_tutorial_seen: Dictionary = {}
## 档案到第 1 月月末才翻开（2026-10-30 玩家定）：之前点职位卡只给一句话，不弹空页。
var _archive_open_allowed := false
## 月末那次"自动讲解"只弹一次；被「稍后」挡掉后改成玩家自己点职位卡时再出。
var _archive_card_offered := false
## 讲完档案那一步之后要接着做的事（回宿舍 / 翻月）：卡关掉、页面关掉才执行。
var _after_profile_step: Callable = Callable()
var _pending_after_profile: Callable = Callable()
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
## 「你的处境」常驻页（Batch 6）。
## 页面内容全来自服务端下发（ApiClient.server_state），本地不估算。
## 提醒不再是一颗点：处境不是「稳定」时，左上角岗位栏下面直接长出一行字。
var _standing_panel
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
	_build_transition_wipe()
	_build_hud_tour()
	_build_interior_preview()
	_build_story_event_panel()
	_build_action_window()
	_build_assessment_panel()
	_build_achievement_panel()
	_build_memory_wall()
	_build_standing_panel()
	_place_player_at_start()
	_refresh_objective_hint()
	# 12 个月开场：先播入职说明会，再让玩家跟着王哥走去 B 区工位。
	# 数据缺失时才退回旧的「操作教学」提示。
	call_deferred("_start_month_opening")
	# 命令行 --v12m-month=N 直接跳进第 N 月看片（--v12m-path=B 换那条路线）。
	# 开场流程是延后一帧起的，所以真正的跳在 _process 里等它跑完再做。
	for arg in OS.get_cmdline_user_args():
		var text := String(arg)
		if text.begins_with("--v12m-month="):
			_jump_target = clampi(int(text.get_slice("=", 1)), 1, 12)
		elif text.begins_with("--v12m-path="):
			_jump_path = text.get_slice("=", 1).to_upper()


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
	# 过场期间锁移动：只锁操作，不停世界时钟（11.23 接线规矩第 1 条）。
	if _date_cutscene_lock:
		_player.velocity = Vector2.ZERO
		_player_sprite.set_motion(Vector2.ZERO, 0.0)
		return
	if _hud_tour_active:
		_player.velocity = Vector2.ZERO
		_player_sprite.set_motion(Vector2.ZERO, 0.0)
		return
	if _month12_start_panel != null and _month12_start_panel.is_open():
		_player.velocity = Vector2.ZERO
		_player_sprite.set_motion(Vector2.ZERO, 0.0)
		_hide_guide_line()
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
	# 数据里那条"跟着王哥走"写着 dismissOn: first_move —— 玩家一动就收。
	if direction != Vector2.ZERO:
		_notice_hint("first_move", "")
	var wanted_position := _player.position + direction * PLAYER_SPEED * delta
	var move_direction := direction
	# 两种"走不动"要分开处理：
	# 1) 人站在不该站的地方（传送出口、剧情摆位落进树丛或水面）——这时按遮罩挡路就是四面都不动，
	#    先按玩家按着的方向放行，踩回路面立刻交回正常规则；最多挪这么多像素，用完还没出来就吸附。
	# 2) 站在合法路面但四周一步都判不过（水边木栈道那种死角）——直接吸附到最近一块走得开的地面。
	var escaping := direction != Vector2.ZERO \
			and not _is_walkable_position(_player.position) and _escape_left > 0.0
	if not escaping and direction != Vector2.ZERO and not _is_walkable_position(wanted_position):
		var horizontal := _player.position + Vector2(direction.x, 0.0) * PLAYER_SPEED * delta
		var vertical := _player.position + Vector2(0.0, direction.y) * PLAYER_SPEED * delta
		if direction.x != 0.0 and _is_walkable_position(horizontal):
			move_direction = Vector2(direction.x, 0.0)
		elif direction.y != 0.0 and _is_walkable_position(vertical):
			move_direction = Vector2(0.0, direction.y)
		else:
			move_direction = Vector2.ZERO
			if _is_pinned_in(_player.position):
				_recover_to_open_ground()
	if move_direction != Vector2.ZERO and not escaping \
			and not _is_inside_active_zone(_player.position + move_direction * PLAYER_SPEED * delta):
		move_direction = Vector2.ZERO
	if move_direction == Vector2.ZERO:
		_player.velocity = Vector2.ZERO
	elif escaping:
		# 树丛的碰撞多边形也会把人顶回来，所以这一步直接摆位置，不走 move_and_slide。
		_player.velocity = move_direction * PLAYER_SPEED
		_player.position += _player.velocity * delta
		_escape_left -= _player.velocity.length() * delta
		if _is_walkable_position(_player.position):
			_last_walkable_position = _player.position
			_escape_left = STUCK_ESCAPE_PX
		elif _escape_left <= 0.0:
			_recover_to_open_ground()
	else:
		_player.velocity = move_direction * PLAYER_SPEED
		_player.move_and_slide()
		_escape_left = STUCK_ESCAPE_PX
		if _is_walkable_position(_player.position):
			_last_walkable_position = _player.position
		else:
			_player.position = _last_walkable_position
			_player.velocity = Vector2.ZERO
	_player_sprite.set_motion(move_direction, _player.velocity.length() * delta)
	_update_zone_state()
	_update_nearby_npc()
	_update_camera(delta)
	_refresh_guide_line()
	if _month12_active:
		_update_month12_waypoint()
		_refresh_month12_place_seals()

func _process(_delta: float) -> void:
	# 剧情面板一关就把欠着的时间过场补上，别让「午后」卡在队列里不播。
	_flush_pending_date()
	# 命令行点名的那个月：等开场流程跑完、过场不播了再跳进去。
	if _jump_target > 0 and _month12_active and not wipe_playing():
		var jump_month := _jump_target
		_jump_target = 0
		debug_jump_to_month(jump_month, _jump_path)
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
		if event.keycode == KEY_F9:
			# 跳月面板（调试）：十二个月一格，点哪个月就到那个月的第一屏。
			_toggle_jump_panel()
			return
		if _jump_panel != null and _jump_panel.visible and event.keycode == KEY_ESCAPE:
			_jump_panel.hide()
			return
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
		if event.keycode == KEY_F7 and _date_debug:
			# 只在命令行带 --v12m-date-debug 时生效：把四档过场各播一遍，用来截首月撞不到的「下旬」。
			_play_date_debug_step()
			return
		if event.keycode == KEY_F8 and _month12_active:
			# 跳月看片：F8 = 下个月，Shift+F8 = 上个月。前一个月的账会一次补齐
			#（条件台词、老地方的门、能力五格），所以跳进去那一眼和真玩到那个月一样。
			debug_jump_to_month(clampi(_month12_month + (-1 if event.shift_pressed else 1), 1, 12), _jump_path)
			return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if _interaction_button != null and _interaction_button.visible:
				_begin_interaction()
				get_viewport().set_input_as_handled()
				return
			# 走位途中贴着一扇金门按 E：门在说"这儿能去"，键却是死的。
			# 不打断走位，只回一句，别让玩家以为按键坏了（2026-10-30 状态矩阵查出来的）。
			if _explain_dead_portal():
				get_viewport().set_input_as_handled()
				return
		# 带巡是强制的：王哥在 A 区那一站要把工作手机交给你，跳过去这个月就没手机了。
		# 所以这一段不接 Esc 跳过，Esc 只留给出室内。
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
	if not _walk_grid.build(_walkability_image, WORLD_SIZE):
		push_warning("步行网格构建失败，引导线退回矩形图")
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


## 卡死兜底：把玩家挪到最近一块"走得开"的路面上。
## 候选取两个：上一次还能走的位置（真玩的时候就是刚踩进去的那一步，几乎原地），
## 以及步行网格的格子中心（它比通行判定更严，往里收 20 像素，落过去必然还有出口）。
## 两个都合法时挑离得近的，不穿墙、不硬挪，所以不会出现"人穿过楼"。
func _recover_to_open_ground() -> void:
	var candidates: Array[Vector2] = [_last_walkable_position]
	if _walk_grid.is_ready():
		candidates.append(_walk_grid.nearest_walkable(_player.position))
	var best := Vector2.INF
	var best_distance := INF
	for spot in candidates:
		if not _is_walkable_position(spot) or _is_pinned_in(spot):
			continue
		var distance: float = spot.distance_squared_to(_player.position)
		if distance < best_distance:
			best_distance = distance
			best = spot
	if best == Vector2.INF:
		return
	_player.position = best
	_player.velocity = Vector2.ZERO
	_last_walkable_position = best


## 脚下是不是已经卡死：八个方向、三档步长都过不了通行判定。
## 一格 32 世界像素的遮罩在树缝、桥角会留下这种小块——站得进去，走不出来。
const PIN_STEPS := [8.0, 18.0, 34.0]
const PIN_DIRS := [
	Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
	Vector2(0.71, 0.71), Vector2(-0.71, 0.71), Vector2(0.71, -0.71), Vector2(-0.71, -0.71),
]


func _is_pinned_in(position: Vector2) -> bool:
	for step: float in PIN_STEPS:
		for offset: Vector2 in PIN_DIRS:
			if _is_walkable_position(position + offset * step):
				return false
	return true


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
	# 12 个月首月：黄线由 _update_month12_waypoint 驱动，旧目标不要来抢。
	if _month12_active:
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
	# 优先按通行遮罩真寻路：矩形图只认"大块可走区"，遇到心湖这种
	# 被矩形罩住的湖面，就会画出一条斜穿湖水的线。
	if _walk_grid.is_ready():
		var walked := _walk_grid.route(from, to)
		if walked.size() >= 2:
			return walked
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
	# 「结束这个月」：只在当月必玩做完之后出现，贴在任务卡正下方（11.10 的位置）。
	_end_month_button = Button.new()
	_end_month_button.name = "EndMonthButton"
	_end_month_button.text = "结束这个月"
	_end_month_button.position = Vector2(36, 244)
	_end_month_button.size = Vector2(190, 58)
	_end_month_button.focus_mode = Control.FOCUS_NONE
	_end_month_button.add_theme_font_override("font", CHINESE_FONT)
	_end_month_button.add_theme_font_size_override("font_size", 24)
	_end_month_button.add_theme_color_override("font_color", Color("fff4d5"))
	var end_style := StyleBoxFlat.new()
	end_style.bg_color = Color("b95035")
	end_style.border_color = Color("2e1a12")
	end_style.set_border_width_all(3)
	end_style.set_corner_radius_all(10)
	_end_month_button.add_theme_stylebox_override("normal", end_style)
	_end_month_button.pressed.connect(_on_end_month_pressed)
	_end_month_button.hide()
	layer.add_child(_end_month_button)


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
	# 屏幕正下方：右下角已经是手机/月历/设置三个入口，E 提示挤在那里会和它们叠在一起。
	_interaction_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_interaction_button.position = Vector2(-175, -140)
	_interaction_button.size = Vector2(350, 82)
	_interaction_button.add_theme_font_override("font", CHINESE_FONT)
	_interaction_button.add_theme_font_size_override("font_size", 22)
	_interaction_button.hide()
	_interaction_button.pressed.connect(_begin_interaction)
	layer.add_child(_interaction_button)
	_build_portal_editor_controls(layer)
	_build_settings_panel()
	_build_mobile_joystick(layer)


func _build_town_ui_v2() -> void:
	_town_ui_v2 = TOWN_UI_V2.new()
	# 档案页那五排格子读城镇这本账，不读后端的下发（没连后端也照画）。
	_town_ui_v2.ability_source = Callable(self, "ability_display_levels")
	_town_ui_v2.material_source = Callable(self, "month12_material_lines")
	_town_ui_v2.task_requested.connect(_open_ui_task)
	_town_ui_v2.phone_requested.connect(_open_ui_phone)
	_town_ui_v2.settings_requested.connect(func(): _town_ui_v2.open_view("settings"))
	_town_ui_v2.month_requested.connect(_on_ui_month_requested)
	_town_ui_v2.chat_requested.connect(_on_ui_chat_requested)
	_town_ui_v2.phone_message_submitted.connect(_on_phone_message_submitted)
	_town_ui_v2.phone_reply_selected.connect(_on_phone_reply_selected)
	_town_ui_v2.manual_requested.connect(_open_manual_with_tutorial)
	# 左上角那条岗位栏 = 员工档案页；记忆墙 / 你的处境从档案页里那两个入口进来。
	_town_ui_v2.profile_requested.connect(_open_ui_profile)
	_town_ui_v2.view_closed.connect(_on_ui_view_closed)
	_town_ui_v2.memory_wall_requested.connect(_open_memory_wall)
	_town_ui_v2.standing_requested.connect(_open_standing)
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
	_refresh_standing_line()
	if _time_hud != null:
		_time_hud.hide()
	if _zone_status != null:
		_zone_status.hide()


func _build_hud_tour() -> void:
	_hud_tour = HUD_TOUR.new()
	_hud_tour.name = "HudTour"
	_hud_tour.finished.connect(_on_hud_tour_finished)
	add_child(_hud_tour)


func _on_hud_tour_finished() -> void:
	_hud_tour_active = false
	_hud_tour_done = true
	if _month12_active:
		_start_month12_tour()
	else:
		_show_reminder_toast("接着走", "跟着黄线继续")


func _refresh_town_ui_v2() -> void:
	if _town_ui_v2 == null:
		return
	if _time_hud != null:
		_time_hud.hide()
	if _zone_status != null:
		_zone_status.hide()
	# 12 个月首月：HUD 的章节/任务卡由 _month12_flow 写，别让旧 WorldClock 又刷回去。
	if _month12_active:
		return
	var remaining := _action_window.remaining if _action_window != null and not _action_window.current_window_id.is_empty() else 3
	if _month12_active:
		# 一罐一格，六格封顶：读数跟着账走。
		_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), _mood, _mood_max, "心情")
	else:
		_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), remaining, 3)


## 处境不再是「稳定」时，左上角岗位栏底下长出一行字（挂法见 _refresh_standing_line）。
## 原来那是档案圆钮上的一颗点，2026-10-29 圆钮随底排一起撤了。
func _on_server_state_changed(_state: Dictionary) -> void:
	_refresh_town_ui_v2()
	_refresh_standing_line()
	if _town_ui_v2 != null and _town_ui_v2.is_open() and _town_ui_v2.get("_view") == "profile":
		_town_ui_v2.open_view("profile")


func _open_manual_with_tutorial() -> void:
	if _show_hud_button_tutorial("manual", Callable(self, "_open_month12_handbook")):
		return
	_open_month12_handbook()


# ---------------------------------------------------------------- HUD 圆钮的第一次使用卡
## 手册有一张（手机用收信面板自带那张），设置不弹卡直接进。
## 按钮解锁本身不弹卡；第一次点开才出。点"打开X"算看过，之后直接进面板；
## 点"稍后"不算看过，下次再点还会出。
## 档案也有一张，但讲的不是"怎么点"——入口那条岗位栏本身写着字，开场导览也说过能点；
## 这张卡讲的是"翻开来里面那五块各是什么"，所以放在第一次翻档案时出。

func _show_hud_button_tutorial(kind: String, after: Callable, later_toast: Array = []) -> bool:
	if bool(_hud_tutorial_seen.get(kind, false)):
		return false
	var config := _hud_button_tutorial_config(kind)
	if config.is_empty():
		return false
	if _hud_button_tutorial == null or not is_instance_valid(_hud_button_tutorial):
		_hud_button_tutorial = HUD_BUTTON_TUTORIAL.new()
		_hud_button_tutorial.name = "HudButtonTutorial"
		add_child(_hud_button_tutorial)
	# 「稍后」那句提示按入口不同换：月末卡里点进来时，"按钮会一直亮着"这句就是错的。
	var toast_title := "按钮会一直亮着"
	var toast_sub := "随时可以再点"
	if later_toast.size() >= 2:
		toast_title = String(later_toast[0])
		toast_sub = String(later_toast[1])
	_hud_button_tutorial.open(config,
		func():
			_hud_tutorial_seen[kind] = true
			after.call(),
		func():
			_show_reminder_toast(toast_title, toast_sub))
	return true


func _hud_button_tutorial_config(kind: String) -> Dictionary:
	match kind:
		"manual":
			return {
				"kind": "manual",
				"kicker": "怎么用",
				"title": "员工手册",
				"lede": "公司规则和流程，随时能翻。",
				"hero_title": "手册",
				"hero_sub": "规则和流程",
				"preview_title": "第一章",
				"preview_text": "提交前那三问，后面会用到。",
				"steps": [
					{"title": "点右下角的手册", "sub": "圆形按钮，随时都能打开。"},
					{"title": "先看第一章", "sub": "提交前那三问，后面会用到。"},
					{"title": "一共三章十四条", "sub": "技术规范、协作流程、晋升通道。"},
				],
				"open_label": "打开手册",
				"fineprint": "不看也能继续；手册只是把规则摆出来。",
			}
		"profile":
			return {
				"kind": "archive",
				"kicker": "里面有什么",
				"title": "员工档案",
				"lede": "岗位、能力、关系，都记在这一页。",
				"hero_title": "档案",
				"hero_sub": "你的这一路",
				"preview_title": "最先要看的",
				"preview_text": "那条进度走满半年，就是下一次评估。",
				"steps": [
					{"title": "岗位与评估进度", "sub": "上面写你现在的岗位；下面那条走满六个月就到下次评估。"},
					{"title": "能力数值", "sub": "技术／协作／表达／原则／抗压各五格，做事和选择会点亮它们。"},
					{"title": "人际关系", "sub": "四个人的好感度，五颗心。到四颗会多一枚认可的爪印。"},
					{"title": "记忆墙与处境", "sub": "墙上是这半年攒下的便签；处境写公司现在怎么看你。"},
				],
				"open_label": "打开档案",
				"fineprint": "随时可以从左上角那条岗位栏翻回来，不用一次记全。",
			}
		"mood":
			return {
				"kind": "mood",
				"kicker": "顶上那罐",
				"title": "心情",
				"lede": "它记着你还能撑多久，一共六格。",
				"hero_title": "心情",
				"hero_sub": "六格 · 一罐一格",
				"preview_title": "它不写在手册里",
				"preview_text": "公司不记这本账。剩几格，只有你自己知道。",
				"steps": [
					{"title": "每个月开头自己回一格", "sub": "满格就停在那儿，不往上堆。"},
					{"title": "休息的地方补一格，活儿压过来它就掉", "sub": "天台、湖边、草坪、桌游角、水巷外摆都能缓。"},
					{"title": "掉到两格以下，同一件事要花双倍力气", "sub": "掉到空了，那一格只能用来缓过来；主线照样走。"},
				],
				"open_label": "知道了",
				"hide_later": true,
				"fineprint": "它不换分数。它只记你这个人还撑不撑得住。",
			}
	return {}


func _open_ui_profile() -> void:
	if not _archive_open_allowed:
		# 月末之前这一格只是"你现在是什么岗位"，翻不开：给一句话，别弹一张空档案。
		_show_reminder_toast("月末再翻", "这个月的记录要等月底才收进档案")
		return
	# 第一次翻档案先出讲解卡：这一页五块内容，不解释玩家看不懂那些格子算什么。
	# 看过一次（点了"打开档案"）就不再弹，跟手册那张同一套规矩。
	if _show_hud_button_tutorial("profile", Callable(self, "_open_ui_profile")):
		return
	_town_ui_v2.open_view("profile")


func _open_ui_task() -> void:
	var remaining := _action_window.remaining if _action_window != null and _action_window.active else 3
	var current_zone := String(_active_zone.get("code", "")) if not _active_zone.is_empty() else ""
	var event := WorldClock.next_main_event()
	var snapshot := WorldClock.snapshot()
	_town_ui_v2.open_view("task", {
		"event": event,
		"snapshot": snapshot,
		"energy": remaining,
		"current_zone": current_zone,
		"story_time_ready": _is_event_due(event, snapshot),
		"activity_window_active": _action_window != null and _action_window.active,
		"month12_active": _month12_active,
		"month12_phase": _month12_phase,
	})


func _open_ui_phone() -> void:
	if not _month_phone_messages.is_empty():
		_phone_gate_read = true
	# 打开手机只算"翻开了"：前置门禁放行。
	# 红点改成按会话算——谁那条没点进去，他那一行和 HUD 上的红点就一直亮着。
	_month_phone_unread = false
	if _town_ui_v2 != null:
		_sync_phone_alert()
	if not _month_phone_messages.is_empty():
		_show_month_phone_drawer()
		return
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


# ---------------------------------------------------------------- 手机通讯录

## 取某人的会话；没有就开一条空的。四个常驻同事进来就有位置。
func _phone_thread(contact_id: String) -> Dictionary:
	if not _phone_threads.has(contact_id):
		_phone_threads[contact_id] = {"messages": [], "unread": false, "date": "", "reply_options": []}
	return _phone_threads[contact_id]


## 发件人是谁：先查四位常驻，再查临时联系人（小赵）。查不到返回空字典。
func _phone_contact_info(contact_id: String) -> Dictionary:
	for contact in PHONE_CONTACTS:
		if String(contact.get("id", "")) == contact_id:
			return contact
	for contact in PHONE_EXTRA_CONTACTS:
		if String(contact.get("id", "")) == contact_id:
			return contact
	return {}


## 往某人的会话里追加一批消息。
## contact_name / contact_role 存下来：临时联系人不在常驻表里，列表还得靠这两个字段显示。
## date_text 是聊天里的时间分隔（带月份），date_short 是会话列表右上那格（只放月份）。
## time_key 是这一批的先后次序（月·旬·时段压成一个数），列表按它把最近有消息的排前面。
## batch_key 非空时同一批只进一次（节点重播不会把同一句话塞两遍）；
## 文本也做一次去重——手机交接那句中转了两条路径，只该留一条。
func _phone_thread_push(contact_id: String, contact_name: String, contact_role: String,
		messages: Array, reply_options: Array, date_text: String, date_short: String = "",
		batch_key: String = "", time_key: int = 0) -> void:
	if contact_id.is_empty():
		return
	if not batch_key.is_empty():
		if bool(_phone_delivered_batches.get(batch_key, false)):
			return
		_phone_delivered_batches[batch_key] = true
	var thread := _phone_thread(contact_id)
	if not contact_name.is_empty():
		thread["name"] = contact_name
	if not contact_role.is_empty():
		thread["role"] = contact_role
	var list: Array = thread.get("messages", [])
	var known := {}
	for item in list:
		if item is Dictionary:
			known[String((item as Dictionary).get("text", ""))] = true
	var added := false
	for item in messages:
		if not (item is Dictionary):
			continue
		var text := String((item as Dictionary).get("text", ""))
		if text.is_empty() or known.has(text):
			continue
		list.append({"speaker": String((item as Dictionary).get("speaker", "npc")), "text": text, "time": date_text})
		added = true
	if not added:
		return
	thread["messages"] = list
	thread["unread"] = true
	if not date_text.is_empty():
		thread["date"] = date_text
	if not date_short.is_empty():
		thread["date_short"] = date_short
	if time_key > 0:
		thread["time_key"] = time_key
	if not reply_options.is_empty():
		thread["reply_options"] = reply_options.duplicate(true)


## 节点的剧情时间 → 手机上的时间分隔。
## 十二个月只走"月 + 旬"，可手机里的往来会横跨好几个月：只写 whenText（"周三上午"）
## 或者"今天 10:00"，跨月以后就看不出先后——实机里第 3 月的周三排在第二月的"今天"下面，
## 读起来像时间倒流（2026-10-30 反馈）。所以一律带上月份：
##   写了 whenText → "第 3 月 · 周三上午"（日期话由数据给，客户端只补月份）
##   没写        → "第 2 月 · 下旬 · 夜里"（月和旬来自节点，时段和剧情面板同一套词）
## 客户端不推算"周三是几号"、也不编"今天几点"（开发册 11.19：不走到天与小时）。
func _phone_date_text(node: Dictionary) -> String:
	var month := maxi(int(node.get("month", _month12_month)), 1)
	var when_text := String(node.get("whenText", "")).strip_edges()
	if not when_text.is_empty():
		return "第 %d 月 · %s" % [month, when_text]
	var parts: Array[String] = ["第 %d 月" % month]
	var xun := _xun_text(String(node.get("phase", "")))
	if not xun.is_empty():
		parts.append(xun)
	var band := _phone_band_word(String(node.get("timeBand", "")))
	if not band.is_empty():
		parts.append(band)
	return " · ".join(parts)


## 通讯录那一行右上的时间：那格放不下"第 3 月 · 上旬 · 上午"，只报月份，
## 具体哪一旬、哪个时段等点进会话看分隔（和真实聊天软件一样，列表只给到天/月）。
func _phone_date_short(node: Dictionary) -> String:
	return "第 %d 月" % maxi(int(node.get("month", _month12_month)), 1)


## 这一批在时间线上的先后：月 ×100 + 旬 ×10 + 时段。只用来排会话列表，
## 不参与显示——显示还是 `_phone_date_text()` 那串人话。
func _phone_time_key(node: Dictionary) -> int:
	var month := maxi(int(node.get("month", _month12_month)), 1)
	var phase: int = int({"early": 0, "mid": 1, "late": 2}.get(String(node.get("phase", "")), 0))
	var band: int = int({"morning": 0, "afternoon": 1, "night": 2}.get(String(node.get("timeBand", "")), 0))
	return month * 100 + phase * 10 + band


## timeBand → 手机分隔里的时段词，和剧情面板的日期牌同一套口吻。
## 左上角那格写的是白天/夜晚（只有昼夜两格），手机里信可以一晚来好几条，写到上午/午后/夜里。
func _phone_band_word(band: String) -> String:
	match band:
		"morning":
			return "上午"
		"afternoon":
			return "午后"
		"night":
			return "夜里"
	return ""


## 通讯录面板要的会话：四个常驻同事没有消息也留一行（进去是"还没有消息"），
## 临时联系人（小赵）有消息才出现，没聊过就不占位置。
func _build_phone_conversations() -> Array:
	var out: Array = []
	for contact in PHONE_CONTACTS:
		out.append(_phone_conversation(String(contact.get("id", "")), contact))
	for contact in PHONE_EXTRA_CONTACTS:
		var contact_id := String(contact.get("id", ""))
		var thread: Dictionary = _phone_threads.get(contact_id, {})
		if thread.is_empty() or (thread.get("messages", []) as Array).is_empty():
			continue
		out.append(_phone_conversation(contact_id, contact))
	return out


func _phone_conversation(contact_id: String, contact: Dictionary) -> Dictionary:
	var thread := _phone_thread(contact_id)
	return {
		"id": contact_id,
		"name": String(contact.get("name", thread.get("name", contact_id))),
		"role": String(contact.get("role", thread.get("role", ""))),
		"messages": (thread.get("messages", []) as Array).duplicate(true),
		"unread": bool(thread.get("unread", false)),
		"date": String(thread.get("date", "")),
		"date_short": String(thread.get("date_short", "")),
		# 列表排序用：最近有消息的排前面；没聊过的是 -1，永远排在最后。
		"sort": int(thread.get("time_key", -1)),
		"reply_options": (thread.get("reply_options", []) as Array).duplicate(true),
	}


## 有没有人还在等回复：HUD 那颗手机的红点只认这个。
func _phone_has_unread() -> bool:
	for contact_id in _phone_threads.keys():
		if bool((_phone_threads[contact_id] as Dictionary).get("unread", false)):
			return true
	return _month_phone_unread and not _month_phone_messages.is_empty()


## 玩家点进某个会话：那一位的红点收掉。
func _on_month_phone_conversation_read(conversation_id: String) -> void:
	var thread := _phone_thread(conversation_id)
	thread["unread"] = false
	_month_phone_unread = false
	_sync_phone_alert()


## 首月的手机：用 12m 那套"手机外形"抽屉装第一批信，联系人和回复项都从数据来。
func _ensure_month_phone_panel() -> Node:
	var source: Dictionary = _month_opening_events.get("M01_PHONE_1", {})
	var contact: Dictionary = _month_phone_contact
	if contact.is_empty():
		contact = {
			"id": String(source.get("senderId", "chen_gong")),
			"name": String(source.get("senderName", "陈工")),
			"role": String(source.get("senderRole", "邻组 Leader")),
		}
	if _month_phone_panel == null:
		_month_phone_panel = PHONE_INBOX.new()
		_month_phone_panel.name = "Month12PhoneDrawer"
		_month_phone_panel.tutorial_only = false
		_month_phone_panel.hide_own_hud = true
		_month_phone_panel.reply_sent.connect(_on_month_phone_reply_sent)
		_month_phone_panel.phone_closed.connect(_on_month_phone_closed)
		_month_phone_panel.conversation_read.connect(_on_month_phone_conversation_read)
		add_child(_month_phone_panel)
	# 谁发的消息就顶谁的名字，头像也从通讯录里取。
	_month_phone_panel.set_contact(
		String(contact.get("id", "")),
		String(contact.get("name", "王哥")),
		String(contact.get("role", "技术导师"))
	)
	# 通讯录：四个同事固定四个会话，谁有新消息谁那行亮红点。
	_month_phone_panel.conversations = _build_phone_conversations()
	# 这一批消息的时间话：逐条消息自己没带时间时（刚投递、玩家回复）就顶它，
	# 不再写死"今天 10:20"——那样同一屏里会出现两个对不上的时间。
	_month_phone_panel.thread_date = _month_phone_date_text
	_month_phone_panel.thread_messages = _month_phone_messages.duplicate(true)
	var options: Array = []
	if not _month_phone_replied:
		options = _month_phone_reply_options.duplicate(true)
		# 「先不回」由收件箱自己画（中性色、点了不发气泡），不再混进回复项里。
	_month_phone_panel.reply_options = options
	# 会话数据换了就重画一遍列表：红点、预览、时间都跟最新的走。
	_month_phone_panel.refresh_conversations()
	return _month_phone_panel


## 剧情里收到一条消息：让右下角那部真手机演——右侧抽屉拉开，停在玩家面前等他自己关。
## 之前的往来一起带进去当上下文；关掉手机这一屏才往下走，不自动收，免得没看完就被推走。
## node 是台上这一屏的剧情节点：拿它的 month / phase / timeBand 给这条留时间话，
## 以后它变成别人的历史消息时，分隔才带月份，不会永远写着"刚刚"。
func _peek_phone_for_story(speaker: String, text: String, node := {}) -> bool:
	if _month_phone_panel == null or not is_instance_valid(_month_phone_panel):
		return false
	var stamp := _phone_date_text(node) if not node.is_empty() else _month_phone_date_text
	var history: Array = []
	for value in _phone_log:
		var item := value as Dictionary
		var who := String(item.get("speaker", ""))
		if who == speaker or who == "我":
			history.append(item)
	var last_text := "" if history.is_empty() else String((history[history.size() - 1] as Dictionary).get("text", ""))
	if last_text != text:
		_phone_log.append({"speaker": speaker, "text": text, "time": stamp})
	var contact_id := String(MONTH12_PHONE_CONTACTS.get(speaker, ""))
	_month_phone_panel.call("peek_message", contact_id, speaker, "", history, text)
	if not _month_phone_panel.phone_closed.is_connected(_after_story_phone_closed):
		_month_phone_panel.phone_closed.connect(_after_story_phone_closed, CONNECT_ONE_SHOT)
	return true


## 玩家关掉剧情里的手机：这一屏算读完，接着往下演。
func _after_story_phone_closed() -> void:
	if _story_event_panel != null and bool(_story_event_panel.call("is_open")):
		_story_event_panel.call("_advance")


func _show_month_phone_drawer() -> void:
	var panel := _ensure_month_phone_panel()
	# 第一次点手机先看现有讲解卡（第一次使用 / 你的工作手机），卡上"打开手机"再进收件箱。
	if not bool(panel.get("_tutorial_completed")):
		panel.open_tutorial()
		return
	# 真翻开收件箱才算"看过了"：讲解卡那一步不算，红点和呼吸到这一步才收掉。
	_month_phone_unread = false
	_sync_phone_alert()
	panel.open_phone()


## 手机亮出来的那一刻就把讲解卡弹到脸上，不等玩家去点。
## 卡收掉（「打开手机」看完收件箱、或「稍后」）之后才把流程接下去，
## 不然带巡下一站的解锁卡会和它叠在一层。
func _offer_phone_tutorial() -> bool:
	var panel := _ensure_month_phone_panel()
	if bool(panel.get("_tutorial_completed")):
		# 卡在这一局里已经看过了（跳月回看首月）：图标直接给出来，不再弹第二次。
		_reveal_month_phone_button()
		_show_reminder_toast("手机有消息", "右下角手机带红点，点开查看；不回也没关系")
		return false
	# 强制：只留「打开手机」，卡上三条步骤改成"手机还没到手"的说法。
	panel.forced_tutorial = true
	panel.tutorial_steps = [
		{"title": "先看第一条", "sub": "手机刚交到你手上，第一条就在里面。"},
		{"title": "回一句或先放着", "sub": "挑一句回就行；不想回就点「先不回」。"},
		{"title": "之后它一直在右下角", "sub": "看完关掉，随时能再翻。"},
	]
	var fired: Array = [false]
	var finish := func():
		if bool(fired[0]):
			return
		fired[0] = true
		_advance_month12_tour_step()
	panel.phone_opened.connect(_on_month_phone_first_opened)
	panel.phone_closed.connect(finish)
	panel.open_tutorial()
	return true


## 收件箱关掉：如果这一批是前置，就把节点播放器接回正轨。
func _on_month_phone_closed() -> void:
	if not _phone_gate_waiting or not _phone_gate_read:
		return
	_phone_gate_waiting = false
	_phone_gate_read = false
	_hide_gate_banner()
	if _month_runner != null and is_instance_valid(_month_runner):
		_month_runner.on_panel_closed()


## 卡上点了「打开手机」：右下角那颗到这一步才长出来。
func _on_month_phone_first_opened() -> void:
	_reveal_month_phone_button()


func _on_month_phone_reply_sent(reply_id: String, reply_text: String) -> void:
	_month_phone_replied = true
	_month_phone_messages.append({"speaker": "我", "text": reply_text})
	# 回的那句要落在点开的那条会话里，退回收件箱时预览才对得上。
	var active := ""
	if _month_phone_panel != null and is_instance_valid(_month_phone_panel):
		active = String(_month_phone_panel.get("_active_id"))
	if active.is_empty():
		active = String(_month_phone_contact.get("id", "chen_gong"))
	var thread := _phone_thread(active)
	var list: Array = thread.get("messages", [])
	# 回复顶的是这条会话最后那批消息的时间：不另造一个"刚刚/今天"，也不让它重开一个分隔。
	list.append({"speaker": "我", "text": reply_text, "time": String(thread.get("date", ""))})
	thread["messages"] = list
	thread["reply_options"] = []
	# 我回的那句也进流水，剧情里再弹手机时才看得到"我当时回过什么"。
	# 时间跟这条会话的最后一批走，不跟别的联系人的最新批次走：回复不另起一个时间分隔。
	var reply_time := String(thread.get("date", ""))
	if reply_time.is_empty():
		reply_time = _month_phone_date_text
	_phone_log.append({"speaker": "我", "text": reply_text, "time": reply_time})
	ApiClient.record_event("m01_phone_reply", {"replyId": reply_id})


## 月末卡上的「打开档案」：先把卡让开，看完档案再把它放回原位，
## 不然月末卡在上一层，档案页会被压在它背后。
## 2026-10-30 改：第一次翻档案就讲——回顾卡这条入口也要先弹讲解卡。
## 代价是「稍后」会把玩家留在空屏上，所以卡一关就得把回顾卡放回来（见 _resume_after_close_card_profile_card）。
func _open_archive_from_close_card() -> void:
	_archive_open_allowed = true
	if _month12_close_panel != null:
		_month12_close_panel.hide()
	_archive_return_to_close = true
	if _show_hud_button_tutorial("profile", Callable(self, "_open_ui_profile"),
			["回顾还在这儿", "想看档案，随时点左上角那一格"]):
		# 自动讲解只给一次：这次被「稍后」挡掉，就等玩家自己点职位卡。
		_archive_card_offered = true
		_hud_button_tutorial.closed.connect(_after_close_card_profile_card, CONNECT_ONE_SHOT)
		return
	_town_ui_v2.open_view("profile")


func _after_close_card_profile_card() -> void:
	# 「打开档案」是关掉卡之后才开页：等这一帧走完再判断页面开没开。
	_resume_after_close_card_profile_card.call_deferred()


func _resume_after_close_card_profile_card() -> void:
	if _town_ui_v2 != null and _town_ui_v2.is_open():
		# 已经在看档案：关页时 _on_ui_view_closed 会把回顾卡放回来。
		return
	# 点了「稍后」：什么也没开。回顾卡得回来，否则玩家就停在空屏上了。
	_archive_return_to_close = false
	if _month12_close_panel != null:
		_month12_close_panel.show()


func _on_ui_view_closed() -> void:
	if _archive_return_to_close:
		_archive_return_to_close = false
		if _month12_close_panel != null:
			_month12_close_panel.show()
	# 月末那次「讲完档案再回宿舍」：档案页关掉才继续。
	if _pending_after_profile.is_valid():
		var after := _pending_after_profile
		_pending_after_profile = Callable()
		after.call()


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

func _on_phone_reply_selected(chat_id: String, reply_id: String, reply_text: String) -> void:
	if chat_id != "chen_gong":
		return
	_month_phone_replied = true
	_month_phone_messages.append({"speaker": "我", "text": reply_text})
	ApiClient.record_event("m01_phone_reply", {"replyId": reply_id})
	_town_ui_v2.open_view("phone", {
		"chat_id": "chen_gong",
		"chat_name": "陈工",
		"chat_messages": _month_phone_messages.duplicate(true),
		"chat_pending": false,
		"month12": true,
		"reply_options": [],
	})


func _on_phone_message_submitted(npc_id: String, message: String) -> void:
	if npc_id == "chen_gong":
		# 首月陈工这条是 12m 来信：回一句就记下来，不调 NPC 聊天接口。
		_month_phone_messages.append({"speaker": "我", "text": message})
		_town_ui_v2.open_view("phone", {
			"chat_id": "chen_gong",
			"chat_name": "陈工",
			"chat_messages": _month_phone_messages.duplicate(true),
			"chat_pending": false,
		})
		return
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
	if _month12_active and _month12_phase != "done":
		_show_reminder_toast("先完成首月", "月历现在可以查看；首月回顾后再推进月份")
		return
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
	if _wipe != null:
		# 过场三档：0 完整 / 1 简洁 / 2 关闭。关闭档下 reduced_motion 也跟着为真。
		_wipe.quality = clampi(int(preferences.get("cutscenes", 0)), 0, 2)
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


## ---------- 处境警示（左上角岗位栏下面那一行字） ----------

## 2026-10-29：档案圆钮从底排撤了，警示点没有了载体。提醒本身不能丢——
## 被叫去谈话不能等玩家自己想起来翻页才知道——所以改成一句话写在岗位栏底下。
## 颜色只是快读的辅助（观察=琥珀 / 危急以上=红），语义永远有文字兜着（§2.4）。
func _refresh_standing_line() -> void:
	if _town_ui_v2 == null or not _town_ui_v2.has_method("set_standing_line"):
		return
	var view := Dictionary(ApiClient.server_state().get("survivalState", {}))
	var state_name := String(view.get("state", ""))
	if state_name == "stable":
		# 稳定就别写字：左上角平时只有日期 + 岗位两条，多一行"处境 · 稳定"是噪音。
		_town_ui_v2.set_standing_line("", "")
		return
	if state_name in ["observation", "critical", "last_talk"]:
		var color := "e0a63c" if state_name == "observation" else "e5503f"
		# 措辞取服务端给的那句人话，本地不再翻一遍词典（口径只留一份）。
		var label_text := String(view.get("label", ""))
		if label_text.is_empty():
			label_text = "被观察" if state_name == "observation" else ("危急" if state_name == "critical" else "谈话在即")
		_town_ui_v2.set_standing_line(label_text, color)
	else:
		# 还没跟后台对上账：宁可不写，也不编一个"稳定"出来（同 StandingPanel 那条红线）。
		_town_ui_v2.set_standing_line("", "")


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
	if _month12_active:
		# 首月是脚本化带巡：所有入口/传送门一律不响应，防止玩家串场。
		_nearby_zone = {}
		return
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
		# 十二个月这条线不挂这批木牌：那八张是从旧 48 个月裁出来的（市场部 / 人事部 / 行政部…），
		# 而现在的底图自己已经把「熊起东方总部 / 树影书院 / 暖邻康护院」画在建筑上了，
		# 挂出来就是同一个门口两个名字打架（2026-10-28 实机截图里撞见）。
		marker.visible = not _month12_active and marker.name == "LocationMarker%s" % entered_code


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
	# 区的室内用默认动线；上一趟活动场景可能换过一套。
	_interior_preview.use_activity_layout(false)
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
	_restore_month12_scene_npcs()
	_interaction_button.hide()
	if not _month12_active:
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
	if _month12_activity_generic:
		# 通用月份：格子还有就回镇上继续，用完才翻月。
		# 0 格月例外：门只是开着让人看一眼，翻月由玩家自己点"结束这个月"。
		if _month12_slots_total <= 0 or _month12_slots_left > 0:
			return
		call_deferred("_finish_month12_activity_node")
		return
	if _month12_active:
		# 首月做完一件自由活动：不扣旧行动力窗口的点（那套窗口首月压根没启动），直接进月末。
		call_deferred("_start_month12_close")
		return
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
## ---------- 提示条：hints.json 的消费器 ----------
## 表里一条提示 = 某个月 + 某个时机 + 一句话。时机由流程在发生的地方叫一声。
## once：同一条只弹一次（记在 _hint_fired，不进存档）。
func _load_hints() -> void:
	if not _hints.is_empty():
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH12_HINTS_PATH))
	if parsed is Dictionary:
		_hints = (parsed as Dictionary).get("hints", []) as Array


func _fire_hints(trigger: String) -> void:
	if not _month12_active:
		return
	_load_hints()
	var month := _month12_month
	if OS.get_environment("V12M_HINT_DEBUG") != "":
		print("[hint] fire=%s month=%d active=%s loaded=%d" % [trigger, month, str(_month12_active), _hints.size()])
	for value in _hints:
		if not (value is Dictionary):
			continue
		var hint := value as Dictionary
		if int(hint.get("month", 0)) != month:
			continue
		if String(hint.get("trigger", "")) != trigger:
			continue
		# 第 1–2 月那几条已经写死在流程里了，别弹两遍。
		if bool(hint.get("legacy", false)):
			continue
		var hint_id := String(hint.get("id", ""))
		if bool(hint.get("once", true)) and bool(_hint_fired.get(hint_id, false)):
			continue
		_hint_fired[hint_id] = true
		if OS.get_environment("V12M_HINT_DEBUG") != "":
			print("[hint] show %s :: %s / %s" % [hint_id, String(hint.get("title", "")), String(hint.get("sub", ""))])
		_show_hint(hint)


func _show_hint(hint: Dictionary) -> void:
	var anchor := String(hint.get("anchor", "shell_toast"))
	var title := String(hint.get("title", ""))
	var sub := String(hint.get("sub", hint.get("text", "")))
	if anchor == "objective":
		# 目标行/本月卡那一行：不弹窗，直接写上去。
		if _town_ui_v2 != null:
			_town_ui_v2.set_task_note(sub)
		return
	# 数据里写着 persist 的提示 = 玩家没做到就一直有效（开发册 §12 那条：
	# persist 一律不得带自动淡出）。这类走钉住横幅，右边给叉，条件满足了由 _notice_hint 收。
	if bool(hint.get("persist", false)):
		_show_gate_banner(title, sub, Callable(), String(hint.get("id", "")))
		_gate_banner_hint["dismissOn"] = String(hint.get("dismissOn", ""))
		return
	_show_reminder_toast(title, sub, int(hint.get("autoDismissMs", 0)))


## 信息型提示：顶部居中的通知条，从屏幕上方滑下来。
## 2026-10-30 试过两版（左上米色纸片 / 左上无底板浮字），玩家都不认——「太碍眼」「好丑」，
## 要的还是「从上弹出来」。所以回到顶上这条：深棕底 + 金边 + 「息」圆徽，和 _show_gate_banner
## 同一套语言；区别只在它说完就走（3.0 秒），而门槛横幅钉住不收。
## 注意：它会盖住顶部心情条 2–3 秒（原来就是这样）。真要挪开，只能落到心情条下方
## y=120 一带，但那儿会蹭到剧情面板的「第 N 月」那行（y=190），得连字号一起改。
func _show_reminder_toast(title: String, sub: String, hold_ms := 0) -> void:
	# 提示必须等过场播完才允许出现：压在黑场上就白写了（4.10 抢占规则第 0 优先级）。
	if _wipe != null and _wipe.is_playing():
		_pending_toasts.append([title, sub])
		return
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
	# 从顶边滑下来 → 停 → 淡出自毁。3.0 秒：够读完两行，又不至于赖着不走。
	_toast_tween = create_tween()
	_toast_tween.tween_property(panel, "position:y", 36.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(float(hold_ms) / 1000.0 if hold_ms > 0 else 3.0)
	_toast_tween.tween_property(panel, "position:y", -100.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_toast_tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.24)
	_toast_tween.tween_callback(panel.queue_free)


## 钉在顶上那条门槛提示：滑进来就不走，要么点它（去干那件事），要么点叉收掉。
## 与 _show_reminder_toast 的区别就是「不自动消失」——挡主线的提示不该赌玩家看见了。
func _show_gate_banner(title: String, sub: String, on_confirm := Callable(), hint_id := "") -> void:
	_hide_gate_banner()
	if _wipe != null and _wipe.is_playing():
		# 过场还在播：压在黑场上等于没写，等它播完再钉。
		_pending_gate_banners.append([title, sub, on_confirm])
		return
	_gate_banner_hint = {"id": hint_id, "dismissOn": ""}
	if _toast_layer == null:
		_toast_layer = CanvasLayer.new()
		_toast_layer.layer = 190
		add_child(_toast_layer)
	var panel := Panel.new()
	_gate_banner = panel
	panel.position = Vector2((1920.0 - 620.0) / 2.0, -100.0)
	panel.size = Vector2(620, 92)
	# 只读的提示（数据里 persist=true 的那几条）不拦鼠标：它们钉在屏幕上，
	# 但玩家照样能点下面的东西；只有带动作的横幅（先看手机 / 宿舍在等你）才整块可点。
	panel.mouse_filter = Control.MOUSE_FILTER_STOP if on_confirm.is_valid() else Control.MOUSE_FILTER_IGNORE
	if on_confirm.is_valid():
		panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
					and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				on_confirm.call()
		)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.329, 0.196, 0.122, 0.97)
	style.border_color = Color("ffc453")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)
	_toast_layer.add_child(panel)
	# 圆徽 = 右下角那颗手机本体：指哪儿说哪儿。
	var chip := TextureRect.new()
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.texture = GATE_PHONE_CHIP
	chip.position = Vector2(16, 20)
	chip.size = Vector2(52, 52)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(chip)
	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(82, 14)
	title_label.size = Vector2(440, 32)
	title_label.add_theme_font_override("font", CHINESE_FONT)
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color("ffe5a8"))
	title_label.add_theme_color_override("font_outline_color", Color("23170f"))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_label)
	var sub_label := Label.new()
	sub_label.text = sub
	sub_label.position = Vector2(82, 48)
	sub_label.size = Vector2(470, 28)
	sub_label.add_theme_font_override("font", CHINESE_FONT)
	sub_label.add_theme_font_size_override("font_size", 17)
	sub_label.add_theme_color_override("font_color", Color("fff0c9"))
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub_label)
	# 右边的叉：玩家自己收。收了不算读过，门槛还在，任务卡照样写着先看手机。
	var close := Button.new()
	close.name = "GateBannerClose"
	close.text = "×"
	close.position = Vector2(566, 26)
	close.size = Vector2(40, 40)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_override("font", CHINESE_FONT)
	close.add_theme_font_size_override("font_size", 28)
	close.add_theme_color_override("font_color", Color("ffe5a8"))
	close.add_theme_color_override("font_hover_color", Color("fff6d8"))
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0, 0, 0, 0.0)
	close_style.border_color = Color("ffc453")
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(20)
	close.add_theme_stylebox_override("normal", close_style)
	var close_hover := close_style.duplicate() as StyleBoxFlat
	close_hover.bg_color = Color(1, 1, 1, 0.14)
	close.add_theme_stylebox_override("hover", close_hover)
	close.add_theme_stylebox_override("pressed", close_hover)
	close.pressed.connect(_hide_gate_banner)
	panel.add_child(close)
	create_tween().tween_property(panel, "position:y", 136.0, 0.32) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## hint_id 传了就只收那一条：别的提示已经顶上来时，晚到的"完成通知"不该把它一起收掉。
func _hide_gate_banner(hint_id := "") -> void:
	if not hint_id.is_empty() and String(_gate_banner_hint.get("id", "")) != hint_id:
		return
	if _gate_banner != null and is_instance_valid(_gate_banner):
		_gate_banner.queue_free()
	_gate_banner = null
	_gate_banner_hint = {}


func _update_nearby_npc() -> void:
	_nearby_npc = {}
	# 进了室内（含活动场景）就不该再冒"与某某交流"——那是镇上的事。
	if _interior_preview != null and _interior_preview.is_open():
		_interaction_button.hide()
		return
	if _month12_active:
		# 首月没有 NPC 互动；屏幕下方那颗 E 只留给"走进亮着的门"。
		_update_month12_place_prompt()
		return
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
	# 十二个月流程下光照归日期栏的昼夜那一格管，不让旧钟点读数来抢。
	if _month12_active:
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
	if _month12_active:
		# 十二个月整月不用这块旧深色任务卡：每次刷新都按一次隐藏，
		# 防止哪条旧路径把它 show 回来，从加高后的日期栏后面露一圈黑边。
		_zone_status.hide()
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
		_set_objective("第一天", "跟王哥去 B 区工位", "桌上那本手册先看第一章", "B 区", true)
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
	# 剧情里有人把玩家带到某个地方时立门（4.15.2）。
	_story_event_panel.beat_reached.connect(_on_story_beat_reached)
	# 剧情里收到消息：让右下角那部真手机演（右侧抽屉），不另画一张卡。
	_story_event_panel.phone_peek = Callable(self, "_peek_phone_for_story")
	add_child(_story_event_panel)
	_month12_place_panel = PLACE_VISIT_PANEL.new()
	_month12_place_panel.name = "PlaceVisitPanel"
	_month12_place_panel.activity_confirmed.connect(_on_month12_place_confirmed)
	_month12_place_panel.unlock_dismissed.connect(_on_place_unlock_dismissed)
	_month12_place_panel.navigate_requested.connect(_on_place_unlock_navigate)
	add_child(_month12_place_panel)
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
	if _month12_active:
		# 剧情那一眼：点了屋里那一行，就在屋里把这一屏演完——不扣点、不结算、不进档案。
		if not _month12_visit_id.is_empty() and String(activity.get("id", "")) == _month12_visit_id:
			_present_month12_place_visit()
			return
		# 在室内点了某一项，才给这一页确认（做什么 / 花什么 / 就做这个 / 先回去）。
		# 只有自由安排窗口里、还没结算过、格子也够，才走确认；其余都是"再访"：
		# 只演一句环境话，不扣点、不给好处（4.18 的全年规则）。
		if _month12_place_panel == null:
			return
		var month12_place := _month12_place_by_id(String(activity.get("id", "")))
		if month12_place.is_empty():
			return
		var in_window := _month12_activity_generic and _month12_phase == "activity"
		if in_window:
			if _month12_slots_left <= 0 \
					or _month12_activity_visited(String(activity.get("id", ""))):
				_month12_place_panel.close()
				_exit_zone()
				_present_month12_revisit(month12_place)
				return
			_month12_place_panel.show_confirm(month12_place, _mood, _month12_slots_left)
			return
		if _month12_activity_generic or _month_runner != null and bool(_month_runner.active):
			# 门开过就一直在：自由安排之外也能进来看看，只是不结算。
			_month12_place_panel.close()
			_exit_zone()
			_present_month12_revisit(month12_place)
			return
		if _month12_activity_taken:
			return
		_month12_place_panel.show_confirm(month12_place, _mood)
		return
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
	# 一局一面墙：只贴本局的便签，别把上一局（或旧 48 个月那版）的贴上来。
	_memory_wall.run_stamp = _run_stamp
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
	_refresh_standing_line()


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


## 服务端回包后刷新那一行处境字（信号回调带两个参数，用不上）。
func _on_standing_state_refreshed(_envelope: Dictionary, _response: Dictionary) -> void:
	_refresh_standing_line()


## 处境那一行字由 _refresh_standing_line()（见"处境警示"一节）统一刷。


func _open_due_event_for_active_zone() -> bool:
	if _month12_active:
		return false
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
		_show_reminder_toast("到了 B 区工位", "翻开桌上的《新员工手册》，先看第一章")
		_refresh_objective_hint()
	_story_event_panel.present(_story_event)
	return true


func _begin_interaction() -> void:
	if _month12_active and _walk_skip_offered and _month12_phase == "sleep_walk":
		# 只给月末回宿舍留兜底；剧情一律走到。
		_skip_walk_to_dorm()
		return
	if _month12_active:
		# 首月的 E 只有一件事：走进亮着的门，开进门确认页。
		_enter_month12_place()
		return
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

## 开一局：发一个新编号，并把上一局留在墙上的便签清掉。
## 记忆墙一局一面 —— 不清的话，同一台机器上玩过的每一局（连旧 48 个月那一版）
## 会全贴在同一面墙上，月份能排到第 48 月、张数堆到 45 张。
func _begin_new_run() -> void:
	_run_stamp = int(Time.get_unix_time_from_system())
	_clear_memory_wall()


## 续玩时接回本局的编号；老存档里没这个号，就当场重发一个并把墙清掉（一次性迁移）。
func _adopt_run_stamp(saved_stamp: int) -> void:
	if saved_stamp > 0:
		_run_stamp = saved_stamp
		return
	_begin_new_run()


func _clear_memory_wall() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("workplace_town_memos.jsonl"):
		dir.remove("workplace_town_memos.jsonl")


## 记忆便签落盘：心湖记忆墙的唯一数据源。
## 便签原本是「弹一下就没了」的装饰，写进 user:// 之后玩家下次进游戏还能翻到
## 「第 1 月 15 日 · 新员工手册」当时贴了什么 —— 这是 E27 那句质问的情感承重墙。
func _on_memo_recorded(event_id: String, memo: Dictionary) -> void:
	if event_id.is_empty() or memo.is_empty():
		return
	var line := memo.duplicate(true)
	line["eventId"] = event_id
	line["runStamp"] = _run_stamp
	line["worldMinute"] = WorldClock.world_minute
	var file := FileAccess.open("user://workplace_town_memos.jsonl", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("user://workplace_town_memos.jsonl", FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(line))
	file.close()

## ---------- 十二个月开场（E01 入职说明会 + 王哥带巡） ----------

## ---------- 十二个月首月（说明会 / A 区一站带巡 / 可选手册 / E02 / 一次自由活动 / 月末） ----------

const MONTH12_PHONE_TEXT := "这周先把开发环境装好，具体开发任务下周再安排。遇到问题可以找王哥。"
## 按剧情册走 5 站：B 区工位 → A 区总部 → 水道 → 心湖步道 → B 区工位。强制走完，不给跳过
## ——王哥要在 A 区那一站把工作手机交出去，跳了这一段这个月就没手机了。
const MONTH12_TOUR := [
	{"id": "b_desk", "pos": Vector2(1008, 240), "name": "B 区工位", "zone": "B", "location": "B 区工位",
		"lead": "王哥把你带回工位。", "card": "m1_tool"},
	{"id": "a_gate", "pos": Vector2(464, 272), "name": "A 区总部", "zone": "A", "location": "A 区总部",
		"lead": "王哥带你走进 A 区总部。", "card": "m1_rooftop"},
	{"id": "waterway", "pos": Vector2(1424, 273), "name": "水道", "zone": "C", "location": "C 区水道",
		"lead": "王哥带你穿过水道。"},
	{"id": "lakeside", "pos": Vector2(860, 770), "name": "心湖步道", "zone": "E", "location": "心湖步道",
		"lead": "王哥带你去心湖步道。", "card": "m1_lakeside"},
	{"id": "b_return", "pos": Vector2(1008, 240), "name": "B 区工位", "zone": "B", "location": "B 区工位",
		"lead": "回到工位。"},
]
const MONTH12_PLACE_POSITIONS := {
	"m1_rooftop": Vector2(464, 272),
	"m1_lakeside": Vector2(860, 770),
	"m1_tool": Vector2(1008, 240),
}
## 跨组周会的桌子：E02 要玩家走到这儿，所以这门口的门不能压灰。
const MONTH12_E02_DESK := Vector2(416, 241)
## 门离剧情落点多近算"挡在剧情路上"：带巡那一站和周会桌子只差 60 像素，
## 再小就兜不住；再大就会把所有门都算成剧情门。
const PLACE_STORY_KEEP_OPEN := 150.0
const MONTH12_MONTH_CARDS := {
	"A": "第 1 月：你在会上把那份方案说清楚了。",
	"B": "第 1 月：那份方案的文档里有了你的名字。",
	"C": "第 1 月：你先把手上的工作交掉了。",
}


func _build_transition_wipe() -> void:
	_wipe = TRANSITION_WIPE.new()
	_wipe.name = "TransitionWipe"
	_wipe.finished.connect(_on_wipe_finished)
	# 信号只带一个参数（昼夜），换灯时长由成员变量另外给，所以走一层窄壳，别直接连 _apply_date_band。
	_wipe.band_lights.connect(_on_band_lights)
	add_child(_wipe)
	# 截图验图用的调试档：命令行带 --v12m-date-debug 才生效，玩家包里没有这个键。
	_date_debug = OS.get_cmdline_user_args().has("--v12m-date-debug")


## 过场层说"该换昼夜了"：时长已经在 _band_fade_seconds 里（走位/原地/熄灯三档），这里只转手。
func _on_band_lights(band: String) -> void:
	_apply_date_band(band)


func _on_wipe_finished(_tier: String) -> void:
	_date_cutscene_lock = false
	_sync_band_lights()
	while not _pending_gate_banners.is_empty():
		var owed: Array = _pending_gate_banners.pop_front()
		_show_gate_banner(String(owed[0]), String(owed[1]), owed[2] as Callable)
	while not _pending_toasts.is_empty():
		var entry: Array = _pending_toasts.pop_front()
		_show_reminder_toast(String(entry[0]), String(entry[1]))
	while not _date_then_queue.is_empty():
		var next_step: Callable = _date_then_queue.pop_front()
		next_step.call()


## 换旬那档过场只翻「上/中/下旬」那一格，昼夜那一格和全屏光色都不归它管。
## 所以过场播完再对一次账：读数已经变成夜晚了，画面就得跟着暗下来（反过来也一样）。
func _sync_band_lights() -> void:
	if _town_ui_v2 == null or _date_band.is_empty():
		return
	var cell := _town_ui_v2.date_band_cell()
	if cell == null or cell.text == _date_band:
		return
	cell.text = _date_band
	_apply_date_band(_date_band)


## 昼夜换灯的两段配色：先走一段暖橙（黄昏/黎明），再落到夜蓝或全亮。
## 直接 0.6 秒压成深蓝太硬——玩家是在走位途中看着天"啪"一下黑的（2026-10-30 反馈）。
const BAND_COLOR_NIGHT := Color(0.07, 0.14, 0.35, 0.42)
const BAND_COLOR_DUSK := Color(0.86, 0.55, 0.32, 0.22)
const BAND_COLOR_DAWN := Color(0.96, 0.83, 0.68, 0.14)
## 三档时长：走位途中换昼夜跟着整段路走；原地换旬一眼看过去就够；熄灯紧跟黑场，别抢戏。
const BAND_FADE_WALK := 3.2
const BAND_FADE_STILL := 1.8
const BAND_FADE_SLEEP := 0.3


## 昼夜那一格换了，世界光照跟着渐变过去（复用旧版那块全屏色）。
## seconds > 0 时用它；否则用 _walk_date_first 预留在 _band_fade_seconds 里的值；都没有就按原地 1.8 秒。
func _apply_date_band(band: String, seconds := 0.0) -> void:
	var night := band == "夜晚"
	# 人正在屋里（宿舍、工位）的话，屋里那层夜色跟着一起换，
	# 不然会出现"外面已经入夜、屋里还大白天亮着"。
	if _interior_preview != null and is_instance_valid(_interior_preview) and _interior_preview.is_open():
		_interior_preview.set_phase("night" if night else "day")
	if _environment_tint == null:
		return
	var total := seconds
	if total <= 0.0:
		total = _band_fade_seconds if _band_fade_seconds > 0.0 else BAND_FADE_STILL
	_band_fade_seconds = 0.0
	var tween := create_tween()
	if night:
		tween.tween_property(_environment_tint, "color", BAND_COLOR_DUSK, total * 0.45) \
			.set_trans(Tween.TRANS_SINE)
		tween.tween_property(_environment_tint, "color", BAND_COLOR_NIGHT, total * 0.55) \
			.set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property(_environment_tint, "color", BAND_COLOR_DAWN, total * 0.4) \
			.set_trans(Tween.TRANS_SINE)
		tween.tween_property(_environment_tint, "color", Color(1, 1, 1, 0), total * 0.6) \
			.set_trans(Tween.TRANS_SINE)


## 换时间读数：三格谁变了谁动，没变的原地不动。
## 幅度决定分量——跨月最重、跨旬次之、昼夜最轻，日内挪一格只冒一张小卡。
## gap_text 是这一屏距上一屏"过了多久"（"两周后"），只挂在跨旬卡上，翻月/昼夜不用。
func _set_date(month: int, phase: String, time_band: String, action_points := -1, gap_text := "") -> void:
	if _town_ui_v2 == null or _wipe == null:
		return
	var xun := "上旬"
	if phase == "mid":
		xun = "中旬"
	elif phase == "late":
		xun = "下旬"
	var band := "夜晚" if time_band == "night" else "白天"
	var band_word := "上午"
	if time_band == "afternoon":
		band_word = "午后"
	elif time_band == "night":
		band_word = "夜里"
	if _date_month == 0:
		# 开局那一拍不播过场：玩家刚进镇，先给他一个已经站好的读数。
		_write_date_plate(month, xun, band, time_band)
		return
	var sub := "第 %d 月 · %s · %s" % [month, xun, band_word]
	if month != _date_month:
		_date_cutscene_lock = true
		_wipe.play_month(_town_ui_v2.date_month_cell(), _town_ui_v2.date_xun_cell(), _town_ui_v2.date_band_cell(), _town_ui_v2.month_text(month), xun, band, sub, action_points)
	elif xun != _date_xun:
		_date_cutscene_lock = true
		# 下旬是本月最后一档：整套动作左右镜像、色条更暗，认得出同类又不像在重播。
		# 旬和昼夜同时变（深夜 → 第二天白天）时，左上角那一格也得跟着换：
		# 只播旬卡的话卡片写着"中旬"、格子里还挂着"夜晚"，画面整场都是黑的。
		var band_cell: Label = null
		var band_word_ui := ""
		if band != _date_band:
			band_cell = _town_ui_v2.date_band_cell()
			band_word_ui = band
		_wipe.play_xun(_date_xun, xun, _town_ui_v2.date_xun_cell(), sub, action_points, xun == "下旬", band_cell, band_word_ui, gap_text)
	elif band != _date_band:
		_wipe.play_daylight(_town_ui_v2.date_band_cell(), band)
	# 上午↔午后不播：日历没有这一格，行动点也不看钟点，播了就是一句没有落点的旁白。
	# （2026-10-27 拍板删时段卡，文档 4.14 同步。）
	_record_date(month, xun, band, time_band)


## 静默把日期牌写成某月某旬（直接落字，不播过场）。
## 两个地方用它：开局那一拍（玩家刚进镇）、续玩接回某个月（牌面先站好，再由月初卡说话）。
## 没有过场替我们发"光色"这一枪，所以这里自己补一次，否则夜里进镇会亮着。
func _write_date_plate(month: int, xun: String, band: String, time_band: String) -> void:
	if _town_ui_v2 == null:
		return
	_town_ui_v2.set_date(month, xun, band)
	_record_date(month, xun, band, time_band)
	_apply_date_band(band)


## 换读数 + 播过场 + 播完接着做下一件事。三件事排成一条队：
## 剧情面板开着 → 等它关；过场在播 → 等它播完；都不在 → 立刻做。
func _date_then(month: int, phase: String, time_band: String, then: Callable, action_points := -1, gap_text := "") -> void:
	if _story_event_panel != null and _story_event_panel.is_open():
		_date_wait_panel = [month, phase, time_band, then, action_points, gap_text]
		return
	_set_date(month, phase, time_band, action_points, gap_text)
	if _wipe != null and _wipe.is_playing():
		_date_then_queue.append(then)
	else:
		then.call()


func _flush_pending_date() -> void:
	if _date_wait_panel.is_empty():
		return
	if _story_event_panel != null and _story_event_panel.is_open():
		return
	if _wipe != null and _wipe.is_playing():
		return
	var entry: Array = _date_wait_panel
	_date_wait_panel = []
	_date_then(int(entry[0]), String(entry[1]), String(entry[2]), entry[3], int(entry[4]), String(entry[5]))


func _record_date(month: int, xun: String, band: String, time_band: String) -> void:
	_date_month = month
	_date_xun = xun
	_date_band = band
	_date_time_band = time_band


## 验图工具用的两个公开口子：外部场景脚本不方便直接调下划线开头的私有函数。
func wipe_playing() -> bool:
	return _wipe != null and _wipe.is_playing()


func push_date(month: int, phase: String, time_band: String, action_points := -1) -> void:
	_set_date(month, phase, time_band, action_points)


## 调试档（命令行 --v12m-date-debug + 按 F7）：把四档过场各播一遍。
## 首月剧情里没有「下旬」，这一档只能靠它验，玩家包里进不来。
func _play_date_debug_step() -> void:
	_date_debug_step += 1
	match _date_debug_step % 5:
		1:
			_set_date(1, "mid", "morning")
		2:
			_set_date(1, "late", "morning")
		3:
			_set_date(1, "late", "night")
		4:
			_set_date(2, "early", "morning")
		_:
			_set_date(2, "mid", "morning")


## 续玩：存档里写着"这一月刚开头"，就把月份 / 旗标 / 心情 / 开过的门接回来，
## 直接从那个月的第一屏开始。月中关掉的话不接半截——那一个月从头再走一遍，
## 比恢复错位置、丢旗标要安全。返回 true 表示接上了，调用方不要再走首月开场。
##
## 默认不接（2026-10-30 晚）：存档功能还没上线，点「开始游戏」一律从第 1 月开始。
## 下面这段是留着的半成品，加 `-- --v12m-resume` 才走；玩家包里没有这个参数。
func _try_resume_saved_month() -> bool:
	if "--no-resume" in OS.get_cmdline_user_args():
		return false
	if not (MONTH12_RESUME_ARG in OS.get_cmdline_user_args()):
		return false
	var raw := FileAccess.get_file_as_string(MONTH12_SAVE_PATH)
	if raw.strip_edges().is_empty():
		return false
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return false
	var saved := parsed as Dictionary
	if not bool(saved.get("monthStart", false)):
		return false
	var month := int(saved.get("month", 0))
	if month < 2 or month > 12:
		return false
	var flags = saved.get("flags")
	if flags is Dictionary:
		_month12_flags = (flags as Dictionary).duplicate(true)
	var places = saved.get("unlockedPlaces")
	if places is Array:
		_month12_unlocked_places.clear()
		for value in places:
			_month12_unlocked_places[String(value)] = true
	_resume_mood = clampi(int(saved.get("mood", _mood_max)), 0, _mood_max)
	_adopt_run_stamp(int(saved.get("runStamp", 0)))
	_start_month_nodes(month)
	# 牌面也要跟着落到这一月：开场那句「第一月 · 上旬 · 白天」是在 _start_month_opening 里
	# 先写好的，续玩只接月份/旗标/心情、不接日期，左上角就会一直挂着第一月。
	# 第三月的一屏配上第一月的日期，玩家只会当成"手机和心情提前解锁了"（2026-10-30 实机截图）。
	# 这里静默写，不再播一次翻月卡：这一月叫什么、第一站去哪儿，月初卡已经说过了。
	_write_date_plate(month, "上旬", "白天", "morning")
	return true


func _start_month_opening() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH_OPENING_PATH))
	if not (parsed is Dictionary):
		_fallback_opening_tutorial()
		return
	for value in (parsed as Dictionary).get("nodes", []) as Array:
		if not (value is Dictionary):
			continue
		var node := Dictionary(value)
		var node_id := String(node.get("id", ""))
		if node_id in ["E01", "E01_TOUR", "M01_PHONE_1", "M01_HANDBOOK_1", "E02"]:
			_month_opening_events[node_id] = node
	if not _month_opening_events.has("E01"):
		_fallback_opening_tutorial()
		return
	_month12_active = true
	_month12_phase = "month_start"
	# 十二个月有自己的本月主线卡（右上），左上角这块旧的深色任务卡整月不需要：
	# 直接释放，免得它从加高后的日期栏透明边后面露出一圈深色。
	if _zone_status != null:
		_zone_status.queue_free()
		_zone_status = null
	_tutorial_complete = true
	WorldClock.set_running(false)
	if _town_ui_v2 != null:
		# 首月先聚焦岗位条和当前任务；手机、手册按流程需要再开放。
		# 档案不再是需要开放的东西：它就在左上角那条岗位栏上，开局就能翻。
		# 那罐蜂蜜是心情 H，不是体力。首月不亮：这个月没有任何东西会扣心情，
		# 摆一个不会动的读数上去，等于让玩家盯一件没有后果的事。
		# 第 2 月月初起账时它才登场（见 _begin_month_ledger）。
		_town_ui_v2.set_energy_visible(false)
		_town_ui_v2.set_phone_visible(false)
		_town_ui_v2.set_phone_red_dot(false)
		_town_ui_v2.set_manual_visible(false)
		_town_ui_v2.set_view_visible(true)
		_town_ui_v2.set_act_label("第一月 · 入职")
		# 左上角那格从「幕名」切成日期读数：第一月 · 上旬 · 白天。开局这一拍不播过场。
		_set_date(1, "early", "morning")
		_town_ui_v2.set_task_card(String((_month_opening_events.get("E01", {}) as Dictionary).get("title", "入职说明会")), "第 1 月 · B 区")
		_town_ui_v2.set_task_note("早上 · 先安顿下来")
	# 首月把入口传送门全部收掉：不是自由活动，别让玩家误入别的区。
	for marker in _entrance_markers:
		(marker as Node2D).visible = false
	# 旧 48 个月那批地名牌（市场部 / 人事部 / 行政部…）在这条线上永久收起：
	# 现在的底图自己已经把「熊起东方总部 / 树影书院 / 暖邻康护院」画在建筑上，
	# 再挂一层就是同一个门口两个名字打架（2026-10-28 实机截图撞见）。
	for marker in _location_markers:
		marker.visible = false
	# 先载入首月三个活动去处；它们的门会在 E02 结算后一起出现。
	_load_month12_places()
	# 上一次停在某个月的月首，就从那个月接上——不重走首月开场。
	if _try_resume_saved_month():
		return
	# 没有可接的存档就是新开一局：墙清空，编号重发。
	_begin_new_run()
	_begin_month_ledger(1)
	_refresh_objective_hint()
	_show_month_start(
		1,
		String((_month_opening_events.get("E01", {}) as Dictionary).get("location", "B 区训练室")),
		String((_month_opening_events.get("E01", {}) as Dictionary).get("title", "入职说明会")),
		"第一天来到小镇，先熟悉这里，再开始手头的工作。",
		[],
		false,
		func():
			_month12_phase = "e01_panel"
			if _town_ui_v2 != null:
				_town_ui_v2.set_task_card(String((_month_opening_events.get("E01", {}) as Dictionary).get("title", "入职说明会")), "第 1 月 · B 区")
				_town_ui_v2.set_task_note("上午 · B 区训练室 · 说明会")
			_present_month12_event("E01")
	)


func _show_month_start(month: int, destination: String, first_task: String, intro: String, today_lines: Array, allow_direct: bool, next_step: Callable) -> void:
	if _month12_start_panel == null or not is_instance_valid(_month12_start_panel):
		_month12_start_panel = MONTH12_START.new()
		_month12_start_panel.name = "MonthStartPanel"
		_month12_start_panel.continued.connect(_on_month_start_continued)
		_month12_start_panel.direct_requested.connect(_on_month_start_direct)
		add_child(_month12_start_panel)
	_month12_start_next = next_step
	_month12_skip_walk = false
	# 新的一月第一屏必须重新开场：把"上一屏在哪儿"清掉。
	_last_story_scene = ""
	_last_story_point = Vector2(-99999, -99999)
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("第 %d 月 · 月初" % month, destination)
		_town_ui_v2.set_task_note("本月第一站 · %s" % first_task)
	_set_objective("第 %d 月" % month, destination, first_task, "", false)
	_month12_start_panel.open(month, destination, first_task, intro, today_lines, allow_direct)


func _on_month_start_continued() -> void:
	if _month12_start_panel != null:
		_month12_start_panel.close()
	var next_step := _month12_start_next
	_month12_start_next = Callable()
	if next_step.is_valid():
		next_step.call()


func _on_month_start_direct() -> void:
	_month12_skip_walk = true
	_on_month_start_continued()


func _fallback_opening_tutorial() -> void:
	_show_reminder_toast("操作教学", "先用 WASD、方向键或左下角摇杆移动角色")


## 把 12m 数据包成 StoryEventPanel 认识的事件；缺的顶层字段在这里补齐。
func _present_month12_event(event_key: String, overrides: Dictionary = {}) -> void:
	var source: Dictionary = _month_opening_events.get(event_key, {})
	if source.is_empty():
		_finish_month12()
		return
	var node := source.duplicate(true)
	for key in overrides.keys():
		node[key] = overrides[key]
	node["id"] = "M12_%s" % event_key
	node["month"] = 1
	node["day"] = int(node.get("day", 1))
	node["hour"] = int(node.get("hour", 9))
	node["actTitle"] = "第一月 · 入职"
	node["situation"] = String(node.get("situation", "weak"))
	node["durationMinutes"] = int(node.get("durationMinutes", 45))
	if not node.has("cast"):
		node["cast"] = []
	if not node.has("speakers"):
		node["speakers"] = {}
	if not node.has("choices"):
		node["choices"] = []
	_story_event = node
	_story_event_panel.present(node)


## 剧情册 D：手册 1.1 / 1.2。桌面手册或 HUD 手册入口都开同一份数据。
func _open_month12_handbook() -> void:
	if _month12_handbook == null:
		_month12_handbook = HANDBOOK_PANEL.new()
		_month12_handbook.name = "Month12Handbook"
		_month12_handbook.handbook_closed.connect(_on_month12_handbook_closed)
		add_child(_month12_handbook)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH12_HANDBOOK_PATH))
	_month12_handbook.open(parsed if parsed is Dictionary else {})
	# 有新页就停在那一页：玩家点"打开手册"是为了看刚给的这条，不是从头再读一遍。
	if not _handbook_pending_page.is_empty():
		_month12_handbook.show_page(_handbook_pending_page)
		_handbook_pending_page = ""
	# 翻开就算看过：新页的红点在这里灭（点圆钮弹"怎么用"卡、再点"稍后"不算翻过，红点留着）。
	if _town_ui_v2 != null:
		_town_ui_v2.set_manual_red_dot(false)


func _on_month12_handbook_closed(_records: Dictionary) -> void:
	_month12_flags["handbook_read"] = true
	if _town_ui_v2 != null:
		_town_ui_v2.set_manual_visible(true)
	if _manual_card_pending:
		_manual_card_pending = false
		_start_month12_e02()
		return





## 场次推进：谁结算完，下一步去哪个节点。
func _advance_month12_story() -> void:
	match _month12_phase:
		"e01_panel":
			# 入职说明会结束 → 简短 HUD 引导 → A 区一站带巡。
			_month12_phase = "hud_tour"
			call_deferred("_schedule_hud_tour")
		"tour_panel":
			_advance_month12_tour()
		"e02_panel":
			call_deferred("_start_month12_activity")
		_:
			pass


# ---------------------------------------------------------------- C 带巡

func _start_month12_tour() -> void:
	_month12_phase = "tour"
	_month12_tour_index = 0
	_goto_month12_stop(0)


func _goto_month12_stop(index: int) -> void:
	if index >= MONTH12_TOUR.size():
		_start_month12_handbook()
		return
	var stop: Dictionary = MONTH12_TOUR[index]
	_month12_tour_index = index
	_month12_phase = "tour"
	_month12_waypoint = _snap_month12_point(stop["pos"])
	_set_objective("第一天", "跟着王哥走", "黄线尽头就是下一段话 · %s" % String(stop["name"]), String(stop["name"]), true)
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("带巡 · %s" % String(stop["name"]), "第 1 月 · 入职第一天")
		_town_ui_v2.set_task_note("第 %d/%d 站 · 沿黄线到%s" % [index + 1, MONTH12_TOUR.size(), String(stop["name"])])
	_lay_month12_guide(true)
	if index == 0:
		# 带巡不能跳：王哥要在 A 区那一站把工作手机交给你。
		_show_reminder_toast("跟着王哥走", "沿黄线到站，五站走完就回工位")


## 首月路线点如果落在草地/树丛上，就先吸到最近的可走矩形中心，
## 否则玩家被 _is_walkable_position 推回去，永远到不了点。
func _snap_month12_point(point: Vector2) -> Vector2:
	# 遮罩才是"踩得下去"的那一层：navigation.json 的大矩形把整个心湖都罩进去了，
	# 拿它的中心当落点就会落进水里。
	if _walk_grid.is_ready():
		return _walk_grid.nearest_walkable(point)
	for value in WALKABLE_AREAS:
		if (value as Rect2).has_point(point):
			return point
	var index := _closest_area_index(point)
	if index >= 0:
		return (WALKABLE_AREAS[index] as Rect2).get_center()
	return point


func _present_month12_stop() -> void:
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	var stop: Dictionary = MONTH12_TOUR[_month12_tour_index]
	var source_stops: Array = (_month_opening_events.get("E01_TOUR", {}) as Dictionary).get("stops", []) as Array
	var data_beats: Array = []
	for value in source_stops:
		if value is Dictionary and String((value as Dictionary).get("id", "")) == String(stop.get("id", "")):
			data_beats = (value as Dictionary).get("beats", []) as Array
			break
	var picked: Array = []
	# 先交代"到哪了、来干什么"，再接册子里的对话；否则每站都像凭空开口。
	var lead := String(stop.get("lead", ""))
	if not lead.is_empty():
		picked.append({"type": "narration", "text": lead})
	for value in data_beats:
		if value is Dictionary:
			picked.append(value)
	_present_month12_event("E01_TOUR", {
		"beats": picked,
		"title": "带巡 · %s" % String(stop["name"]),
		"location": String(stop.get("location", "A 区总部")),
		"locationId": String(stop.get("zone", "A")),
		"day": 1,
		"hour": 10,
	})
	_month12_phase = "tour_panel"


func _advance_month12_tour() -> void:
	var stop: Dictionary = MONTH12_TOUR[_month12_tour_index]
	var phone_stop := String(stop.get("id", "")) == "a_gate"
	if phone_stop:
		_unlock_month_phone()
	var card_id := String(stop.get("card", ""))
	if not card_id.is_empty():
		# 地点解锁卡先讲"这是哪儿"，关掉之后紧接着把手机讲解卡弹出来，
		# 两张卡不叠在一层；手机卡收掉才带玩家去下一站。
		_show_tour_card(card_id, func():
			if phone_stop and _offer_phone_tutorial():
				return
			_advance_month12_tour_step())
		return
	if phone_stop and _offer_phone_tutorial():
		return
	_advance_month12_tour_step()


func _advance_month12_tour_step() -> void:
	if _month12_tour_index < MONTH12_TOUR.size() - 1:
		call_deferred("_goto_month12_stop", _month12_tour_index + 1)
	else:
		call_deferred("_start_month12_handbook")


## 带巡经过的活动门口先弹一张解锁卡；点“知道了”再继续走，不挡路。
func _show_tour_card(activity_id: String, after: Callable) -> void:
	var place := _month12_place_by_id(activity_id)
	if place.is_empty() or _month12_place_panel == null:
		after.call()
		return
	_tour_card_after = after
	_month12_place_panel.show_unlock(place, false)


## 到达 A 区后：王哥把工作手机交到你手上。
## 注意顺序——先弹讲解卡，右下角那颗图标是玩家看完卡、亲手「打开手机」之后才长出来的；
## 卡是强制的，没有"稍后"，Esc 也关不掉。
func _unlock_month_phone() -> void:
	_month_phone_messages = [{"speaker": "npc", "text": MONTH12_PHONE_TEXT}]
	_month_phone_unread = true
	_month_phone_replied = false
	_month_phone_reply_options = [
		{"id": "ack_env", "text": "收到，我先装环境"},
	]
	# 王哥把手机交到你手上，屏幕上第一条是陈工的工作安排——落在陈工那条会话里。
	# 时间就取首月那条手机节点的剧情时间（第 1 月 · 上旬 · 上午），不再写死"今天 14:20"：
	# 玩家这会儿还在带巡的半路上，牌面上写的是上午。
	var handoff: Dictionary = _month_opening_events.get("M01_PHONE_1", {})
	var date_text := _phone_date_text(handoff)
	var date_short := _phone_date_short(handoff)
	_month_phone_date_text = date_text
	_phone_thread_push("chen_gong", "陈工", "邻组 Leader", _month_phone_messages,
		_month_phone_reply_options, date_text, date_short, "", _phone_time_key(handoff))


func _reveal_month_phone_button() -> void:
	if _town_ui_v2 == null:
		return
	# 只是把图标长出来，不改"有没有没看的消息"——红点和呼吸统一交给 _sync_phone_alert 判。
	_town_ui_v2.set_phone_visible(true)
	_sync_phone_alert()


## 手机提醒的唯一规则：有没看过的消息才亮红点、才呼吸；看完了（点开或回完）两样都收掉。
## 以前呼吸是"图标出现那一刻"起的，回完消息也没人关掉它，就成了常驻动画。
func _sync_phone_alert() -> void:
	if _town_ui_v2 == null:
		return
	var unread := _phone_has_unread()
	_town_ui_v2.set_phone_red_dot(unread)
	if unread:
		_town_ui_v2.start_phone_attention()
	else:
		_town_ui_v2.stop_phone_attention()


# ---------------------------------------------------------------- D 手册

func _start_month12_handbook() -> void:
	_month12_phase = "handbook"
	# 上午→午后不播时段卡；这里等带巡结束后开放手册入口并继续主线。
	_date_then(1, "early", "afternoon", _month12_handbook_step)


## 带巡结束后收掉黄线、展示可选手册入口，再把主线接到 E02。
func _month12_handbook_step() -> void:
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	if _town_ui_v2 != null:
		_town_ui_v2.set_manual_visible(true)
		_town_ui_v2.set_task_card("带巡完成", "第 1 月 · 接下来去跨组周会")
		_town_ui_v2.set_task_note("手册可随时查看；跟黄线去跨组周会")
	# 手册亮出来的那一刻就把讲解卡弹给他，卡收掉再去跨组周会：
	# 时段过场压在卡片底下会看不见，所以流程等这张卡。
	if _show_hud_button_tutorial("manual", Callable(self, "_open_month12_handbook")):
		_hud_button_tutorial.closed.connect(_after_manual_card_closed, CONNECT_ONE_SHOT)
		return
	call_deferred("_start_month12_e02")


## 卡收掉之后再看一眼：`closed` 是在「打开手册」真正开页之前发的，所以延一帧判。
func _after_manual_card_closed() -> void:
	call_deferred("_continue_after_manual_card")


func _continue_after_manual_card() -> void:
	if _month12_handbook != null and is_instance_valid(_month12_handbook) \
			and bool(_month12_handbook.call("is_open")):
		_manual_card_pending = true
		return
	_start_month12_e02()


# ---------------------------------------------------------------- E E02

func _start_month12_e02() -> void:
	_month12_phase = "e02_walk"
	# 上旬 → 中旬：首月唯一一次跨旬；过场结束后铺去 A 区周会桌的黄线。
	_date_then(1, "mid", "morning", _after_month12_xun_card)


## 跨旬卡播完之后才做的事：给主线目标 + 铺黄线。
func _after_month12_xun_card() -> void:
	_set_objective("主线 · 现在就去做", "去 A 区总部 · 跨组周会", "黄线尽头就是会场", "A 区", true)
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("第一次被轻视", "第 1 月 · A 区总部")
		_town_ui_v2.set_task_note("周三上午 · 跟着黄线走")
	_month12_waypoint = MONTH12_E02_DESK
	_lay_month12_guide(true)


func _present_month12_e02() -> void:
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	var e02: Dictionary = _month_opening_events.get("E02", {})
	var outcome := {}
	var notes := {}
	for value in (e02.get("choices", []) as Array):
		if not (value is Dictionary):
			continue
		var choice := Dictionary(value)
		var choice_id := String(choice.get("id", ""))
		outcome[choice_id] = String(choice.get("outcome", ""))
		var card := String(MONTH12_MONTH_CARDS.get(choice_id, ""))
		notes[choice_id] = {"text": card, "tone": "gray" if choice_id == "C" else "gold"}
	_present_month12_event("E02", {
		"outcome": outcome,
		"memoryNote": notes,
		"speakers": {
			"同事": {"name": "同事", "role": "", "pos": "left"},
			"陈工": {"name": "陈工", "role": "邻组 Leader", "pos": "left"},
			"王哥": {"name": "王哥", "role": "技术导师", "loadout": "bear_plaid_glasses", "pos": "right"},
		},
		"location": "A 总部 · 跨组周会",
		"locationId": "A",
		"situation": "medium",
	})
	_month12_phase = "e02_panel"


# ---------------------------------------------------------------- F 自由安排（到访制）
# E02 结算后同时开放三处活动地点；玩家自己走到其中一处，再看活动确认页。
# 月末按钮也在此时出现，玩家可以做一项活动，也可以直接结束本月。

func _start_month12_activity() -> void:
	_month12_phase = "activity"
	# 上午→午后不播了；这里只等 E02 那段结算画面收掉再让门亮起来。
	_date_then(1, "mid", "afternoon", _month12_activity_step, 1)


## E02 结算后：三扇门一起开，给一句常驻提示，剩下的时间玩家自己走。
func _month12_activity_step() -> void:
	_open_month12_places()
	_set_objective("本周自由安排", "去亮着的地方看看", "本周 1 个行动点；不用完月底清零", "自由安排", false)
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("本周自由安排 · 1 点", "第 1 月 · 门口亮起来了")
		_town_ui_v2.set_task_note("走近亮着的门，按 E 进去")
	_show_reminder_toast("门口亮了", "三个地方随你挑一个，或者结束这个月")
	_show_end_month_button(true)


func _load_month12_places() -> void:
	if not _month12_places.is_empty():
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH12_PLACES_PATH))
	if parsed is Dictionary:
		_month12_places = (parsed as Dictionary).get("activities", []) as Array


func _month12_place_by_id(activity_id: String) -> Dictionary:
	for value in _month12_places:
		if value is Dictionary and String((value as Dictionary).get("id", "")) == activity_id:
			return value
	if not activity_id.is_empty() and activity_id == _month12_visit_id:
		return _month12_visit_place()
	return {}


## 按活动 ID 的地点坐标放门；不做一键传送列表。
func _month12_place_position(activity_id: String) -> Vector2:
	if not MONTH12_PLACE_POSITIONS.has(activity_id):
		return Vector2.ZERO
	return _snap_month12_point(MONTH12_PLACE_POSITIONS[activity_id])


## 活动门按地点坐标出现；进入自由活动后统一开放。
func _unlock_month12_place(activity_id: String) -> void:
	_load_month12_places()
	var activity := _month12_place_by_id(activity_id)
	if activity.is_empty():
		return
	_month12_unlocked_places[activity_id] = true
	if _month12_place_portals.has(activity_id):
		return
	var portal := TOWN_PORTAL.new()
	portal.name = "PlacePortal_%s" % activity_id
	portal.position = _month12_place_position(activity_id)
	portal.z_index = 44
	add_child(portal)
	_month12_place_portals[activity_id] = portal
	_refresh_month12_place_seals()
	ApiClient.record_event("m01_place_unlocked", {"activityId": activity_id})


## E02 做完后：首月那三扇门一起亮起来。
## 只开 unlockAfter 指向 E02 的去处——去处表里还躺着第 3/7/9/11 月的门，
## 它们各有各的钩子或解锁时机，跟着一起开就会让玩家在第二月看见九扇门，
## 误以为"这个月在自由活动"（2026-10-28 实机反馈）。
func _open_month12_places(after_event := "E02") -> void:
	_load_month12_places()
	# 先立旗再开门：_unlock_month12_place 内部会刷一次封条，
	# 旗子没立上去的话，刚开的门会当场被压回灰。
	_month12_places_open = true
	for activity in _month12_places:
		if not (activity is Dictionary):
			continue
		if String((activity as Dictionary).get("unlockAfter", "")) != after_event:
			continue
		_unlock_month12_place(String((activity as Dictionary).get("id", "")))
	_refresh_month12_place_seals()


## 这个月还有哪几个点是剧情要玩家亲自走到的：A 区带巡点和 E02 周会桌。
func _month12_story_points() -> Array:
	var points: Array = []
	if _month12_phase in ["hud_tour", "tour", "tour_panel"]:
		for index in range(_month12_tour_index, MONTH12_TOUR.size()):
			points.append(MONTH12_TOUR[index]["pos"] as Vector2)
	elif _month12_phase == "handbook" and _month12_tour_index < MONTH12_TOUR.size():
		points.append(MONTH12_TOUR[_month12_tour_index]["pos"] as Vector2)
	if _month12_e02_choice.is_empty():
		points.append(MONTH12_E02_DESK)
	return points


## 现在是不是"能自由走动、进得去门"的窗口。
## E 提示和门的压灰共用这一条：以前两边各写一份，门一直金着、E 却不出现，
## 玩家走过去发现进不去 —— 门的颜色就在说谎。
func _month12_place_window_open() -> bool:
	if _date_cutscene_lock:
		return false
	if _story_event_panel != null and _story_event_panel.is_open():
		return false
	var phase := String(_month12_phase)
	var runner_month := _month_runner != null and bool(_month_runner.active)
	if runner_month:
		# 自由走动的那两态才给入口；月末卡、翻月过场期间不收进门的钱，也不该让人误点。
		return phase in ["month_nodes", "activity"]
	# 首月还是只在那一个自由安排窗口里开门。
	return phase == "activity"


## 首月正常路线在 E02 后一次创建并开放全部活动门；封条状态仅保留给剧情提前建门的兼容路径。
## set_sealed 自己会去重，因此门状态刷新不会重复播放动画。
func _refresh_month12_place_seals() -> void:
	if _month12_place_portals.is_empty():
		return
	var story_points := _month12_story_points()
	# 黄线终点也算剧情点：故事把人带到 B 区工位、湖边、书院门口时，门正好立在那儿，
	# 灰着就等于"跟着黄线一路走到一扇封了的门前面"（2026-10-29 实机反馈，第 2 月起几乎每月都撞）。
	# 只认"黄线正在带路"的那几个相位：月末卡、翻月期间黄线终点还挂着，
	# 那时门该灰还得灰，不然又成了"金着进不去"。黄线一改道，上一扇自己退回灰。
	if _month12_waypoint.x > -90000.0 \
			and _month12_phase in ["hud_tour", "tour", "e02_walk", "node_walk", "sleep_walk"]:
		story_points.append(_month12_waypoint)
	# 进不去的时候门就该是灰的：这一月没开门（还没解锁）、或者现在不是自由走动的窗口。
	var open_now := _month12_places_open and _month12_place_window_open()
	for portal in _month12_place_portals.values():
		var door := portal as Node2D
		if door == null:
			continue
		var want_sealed := not open_now
		for point in story_points:
			if door.position.distance_to(point as Vector2) < PLACE_STORY_KEEP_OPEN:
				want_sealed = false
				break
		door.set_sealed(want_sealed)


## ---------- 剧情解锁去处：讲解卡排在面板之后 ----------
##
## 台词拍上挂了钩子，门在当拍就亮；这一屏读完、剧情面板收掉之后才弹讲解卡。
## 卡关掉之前节点播放器停在原地，不然下一屏会从卡片背后长出来。

func _open_hook_cards(after: Callable) -> void:
	_hook_queue.clear()
	# unlockAfter 的去处先排：它们和当拍的钩子卡不会同时出现，一条队列按"先节点、后钩子"走。
	for value in _pending_unlock_places:
		if value is Dictionary:
			_hook_queue.append(value)
	_pending_unlock_places.clear()
	for value in _pending_story_hooks:
		var place := _month12_place_by_hook(String(value))
		if not place.is_empty():
			_hook_queue.append(place)
	_pending_story_hooks.clear()
	_hook_after = after
	_advance_hook_cards()


func _advance_hook_cards() -> void:
	if _hook_queue.is_empty():
		var after := _hook_after
		_hook_after = Callable()
		if after.is_valid():
			after.call()
		return
	if _month12_place_panel == null:
		_hook_queue.clear()
		_advance_hook_cards()
		return
	var place: Dictionary = _hook_queue.pop_front()
	_month12_place_panel.show_unlock(place)


func _on_place_unlock_dismissed(_activity_id: String) -> void:
	if _tour_card_after.is_valid():
		var after := _tour_card_after
		_tour_card_after = Callable()
		after.call()
		return
	_advance_hook_cards()


## 某一屏读完，把 unlockAfter 指向这一屏的去处立门并排队弹卡。
## activities.json 里那四处（草坪／书院／桌游角／复现）以前没有任何代码消费 unlockAfter，
## 门只在当月自由安排里悄悄亮起来，玩家看不到"这是哪儿、来干什么"。
func _queue_unlock_after_cards(node_id: String) -> void:
	if node_id.is_empty():
		return
	_load_month12_places()
	for value in _month12_places:
		if not (value is Dictionary):
			continue
		var place := value as Dictionary
		if String(place.get("unlockAfter", "")) != node_id:
			continue
		var once_key := "unlock_after_%s" % String(place.get("id", ""))
		if bool(_month12_flags.get(once_key, false)):
			continue
		_month12_flags[once_key] = true
		_ensure_month12_place(String(place.get("id", "")))
		_month12_places_open = true
		_refresh_month12_place_seals()
		_pending_unlock_places.append(place)


## 讲解卡上「带我去」：记下这个区，等这个月的门都立好再铺黄线。
func _on_place_unlock_navigate(zone_code: String) -> void:
	if _tour_card_after.is_valid():
		var after := _tour_card_after
		_tour_card_after = Callable()
		after.call()
		return
	_hook_nav_zone = zone_code
	_advance_hook_cards()


func _apply_hook_navigation() -> void:
	if _hook_nav_zone.is_empty():
		return
	var zone := _hook_nav_zone
	_hook_nav_zone = ""
	for value in _month12_places:
		if not (value is Dictionary):
			continue
		var activity := value as Dictionary
		if String(activity.get("locationId", "")) != zone:
			continue
		var door := _month12_place_portals.get(String(activity.get("id", ""))) as Node2D
		if door == null:
			continue
		_month12_waypoint = door.position
		if _guide_line != null and _player != null:
			_guide_line.set_path(_build_guide_path(_player.position, _month12_waypoint))
		if _town_ui_v2 != null:
			_town_ui_v2.set_task_note("跟着黄线去%s" % String(activity.get("name", "")))
		return


## ---------- 通用月份的自由安排（第 3 月起） ----------
##
## 首月那套是写死的：一个格子、三扇门、做完就进月末。第 3 月起格数从节点里读，
## 一个地方做完还能再去下一个；门开过就一直在，格子用完才翻月。

## 节点驱动：读 budget、把这个月能去的门立起来并点亮，等玩家自己走过去。
func runner_open_activity(node: Dictionary) -> void:
	var budget: Dictionary = node.get("budget", {})
	_month12_activity_generic = true
	_month12_slots_total = maxi(0, int(budget.get("slots", 1)))
	_month12_slots_left = _month12_slots_total
	# 节点没写预算就用全年那本账：每月几格只有一个出处，不靠节点里各写一遍。
	_month12_ap_left = maxi(0, int(budget.get("ap", _ap_total if _ap_total > 0 else _month12_slots_total)))
	_month12_places_open = true
	_month12_phase = "activity"
	# 这一屏是当天哪一段：日历格只有白天/夜晚，午后写不进日期牌，就写进卡片副行。
	_activity_band_word = _band_word_of(String(node.get("timeBand", "")))
	# 后面还有没有剧情：决定那颗按钮叫什么、按下去要不要多说一句。
	# 第 1/5/7 月的两格在月末，按下去就是收尾；第 3/9/11 月的两格夹在中间，
	# 按下去只是"不逛了"，当天晚上那几屏照演——按钮上写"结束这个月"是在说谎。
	var next_node: Dictionary = {}
	if _month_runner != null:
		next_node = _month_runner_peek()
	_activity_next_is_close = next_node.is_empty() or String(next_node.get("nodeType", "")) == "month_close"
	for value in (node.get("activityIds", []) as Array):
		_ensure_month12_place(String(value))
	# 门开过就一直在：这个月没再列一遍的旧去处也保留在镇上。
	for activity_id in _month12_unlocked_places.keys():
		_ensure_month12_place(String(activity_id))
	_refresh_month12_place_seals()
	_update_month12_activity_card()
	if _month12_slots_left > 0:
		_show_reminder_toast("门口亮了", "这个月还能去 %d 个地方" % _month12_slots_left)
	else:
		_show_reminder_toast("这个月没有个人时间", "老地方还能进去坐坐，不花点")
	_show_end_month_button(true)
	_refresh_end_month_label(node)
	_apply_hook_navigation()
	_fire_hints("activity_open")
	# 自由安排这一屏也要能挂自己的提示：`node_started:<活动节点 id>` 和剧情屏同一套触发词，
	# 否则"本月几格、去哪儿"这类话只能写死在每个月里（第 5 月就没有提示可挂）。
	_fire_hints("node_started:%s" % String(node.get("id", "")))


## 播放器下一步要演的那一屏（跳过条件不成立的）。没有播放器就给空字典。
func _month_runner_peek() -> Dictionary:
	if _month_runner == null:
		return {}
	var value = _month_runner.call("peek_next")
	if value is Dictionary:
		return value as Dictionary
	return {}


## timeBand → 卡片副行用的两个字。日历格里没有"午后"（4.14 拍板删了时段卡），
## 但卡片副行写得下，玩家至少要看见"这会儿是午后、晚上还有事"。
func _band_word_of(time_band: String) -> String:
	if time_band == "afternoon":
		return "午后"
	if time_band == "night":
		return "夜里"
	if time_band.is_empty():
		return ""
	return "白天"


## 立一扇门（按活动自己的 portal 找位置）。已经立过的跳过。
func _ensure_month12_place(activity_id: String) -> void:
	_month12_unlocked_places[activity_id] = true
	if _month12_place_portals.has(activity_id):
		return
	var activity := _month12_place_by_id(activity_id)
	if activity.is_empty():
		return
	# 一扇门代表的是一整个区：按 E 进去之后，右侧列的是这个区所有能做的事
	# （见 _enter_month12_place → _show_month12_place_list）。所以同一个区只立一扇门，
	# 后来解锁的活动只进"已解锁"名单，不再在旁边多长一扇——B 区就撞过这个：
	# 「组内小工具」和「把活往前赶」都写 zoneId B，结果一个地方两团光叠着。
	# E 区同理（2026-10-30 实机反馈）：「松风训练谷」原来写 zoneId E，和湖边那扇
	# 「湖边散步」（landmark heart_lake）在湖南岸上下叠出两团光；现在训练谷也挂
	# heart_lake，解锁后只进区清单，门只留湖边那一扇。
	var door_key := _month12_place_door_key(activity)
	for existing_id in _month12_place_portals:
		var existing := _month12_place_by_id(String(existing_id))
		if not existing.is_empty() and _month12_place_door_key(existing) == door_key:
			return
	var door := TOWN_PORTAL.new()
	door.name = "PlacePortal_%s" % door_key.replace(":", "_")
	door.position = _month12_place_free_position(_month12_place_position_of(activity))
	door.z_index = 44
	add_child(door)
	_month12_place_portals[activity_id] = door
	_fire_hints("place_unlocked")


## 门的分组键：有 zoneId 的按区算一扇，只有 landmark 的按地标各算一扇。
func _month12_place_door_key(activity: Dictionary) -> String:
	var portal: Dictionary = activity.get("portal", {})
	if portal.has("zoneId"):
		return "zone:%s" % String(portal["zoneId"])
	var landmark := String(portal.get("landmark", ""))
	if landmark.is_empty():
		return "activity:%s" % String(activity.get("id", ""))
	return "landmark:%s" % landmark


## 门的落点：优先 zoneId 的入口；只有 landmark 的去处用固定坐标表。
func _month12_place_position_of(activity: Dictionary) -> Vector2:
	var portal: Dictionary = activity.get("portal", {})
	if portal.has("zoneId"):
		var zone := _zone_by_code(String(portal["zoneId"]))
		if not zone.is_empty():
			return _snap_month12_point(zone.get("entrance", Vector2.ZERO))
	var landmark := String(portal.get("landmark", ""))
	if landmark == "heart_lake":
		return _snap_month12_point(Vector2(860, 770))
	if landmark == "waterway":
		return _snap_month12_point(Vector2(1424, 273))
	if landmark == "lawn":
		# E 区草坪：和湖边那扇门（heart_lake）岔开一点，两扇门不叠在一处。
		return _snap_month12_point(Vector2(640, 900))
	return _snap_month12_point(Vector2(1008, 240))


## 同一处已有门时，后来的人沿水平方向挪开：84 像素一档，左右交替试六档，
## 都占着再往上下错。判定半径 72 是"两扇门不至于糊在一起、又还在同一片地方"的折中。
func _month12_place_free_position(base: Vector2) -> Vector2:
	var occupied: Array = []
	for value in _month12_place_portals.values():
		if is_instance_valid(value):
			occupied.append((value as Node2D).position)
	if occupied.is_empty():
		return base
	if not _month12_place_taken(base, occupied):
		return base
	for slot in 6:
		var step := 84.0 * float(slot / 2 + 1)
		if slot % 2 == 1:
			step = -step
		var candidate := _snap_month12_point(base + Vector2(step, 0.0))
		if not _month12_place_taken(candidate, occupied):
			return candidate
	for slot in 3:
		var below := _snap_month12_point(base + Vector2(0.0, 96.0 * float(slot + 1)))
		if not _month12_place_taken(below, occupied):
			return below
	return base


func _month12_place_taken(point: Vector2, occupied: Array) -> bool:
	for other in occupied:
		if (other as Vector2).distance_to(point) < 72.0:
			return true
	return false


## 这个月还剩几个名额：首月看"做过没有"，后面几个月看剩余格数。## 只用于"要不要自动翻月"；门本身不再看这个数——再访不扣点照样进得去。
func _month12_out_of_slots() -> bool:
	if _month12_activity_generic:
		return _month12_slots_left <= 0
	return _month12_activity_taken


func _update_month12_activity_card() -> void:
	if _town_ui_v2 == null or not _month12_activity_generic:
		return
	var title := ""
	var note := ""
	if _month12_slots_total <= 0:
		title = "这个月没有个人时间"
		note = "旧地方还进得去 · 只当走一圈"
	elif _month12_slots_left <= 0:
		title = "这个月安排完了"
		note = "可以结束这个月" if _activity_next_is_close else "今天后面还有一段"
	else:
		title = "自由安排 · %d 点" % _month12_ap_left
		note = "还剩 %d 格 · 去亮着的地方" % _month12_slots_left
	# 点数会随着到访变少：标题和副行一起重写，别留一个旧数字在上面。
	# 副行第二段写"这会儿是什么时候"：日期牌只有白天/夜晚两格，午后只能落在卡上，
	# 否则玩家看不见"下午被跳过去了"，只以为剧情卡住。
	var meta := "第 %d 月 · 自己安排" % _month12_month
	if not _activity_band_word.is_empty():
		meta = "第 %d 月 · %s" % [_month12_month, _activity_band_word]
	_town_ui_v2.set_task_card(title, meta)
	_town_ui_v2.set_task_note(note)


## 通用月份的收尾：格子用完、或者玩家自己点"结束这个月"。
func _finish_month12_activity_node() -> void:
	_show_end_month_button(false)
	_hook_nav_zone = ""
	if _month12_activity_generic and _month12_slots_left > 0:
		# 翻月时还有格子没花：引擎记一笔跳过，月底的档案里看得出这个月没安排。
		_month12_flags["m%02d_activity_skipped" % _month12_month] = true
		_fire_hints("activity_skipped")
	_month12_activity_generic = false
	_month12_phase = "month_nodes"
	if _month_runner != null:
		_month_runner.call("_next")


## 走位途中贴着一扇金门按 E：门在说"这儿能去"，E 键却是死的。
## 走位是剧情的骨架，不能为了这扇门打断它；所以只回一句话，别让玩家以为按键坏了。
## （2026-10-30 用 tools/prompt_state_check.tscn 摆状态查出来的两种相位：剧情走位、首月带巡。）
func _explain_dead_portal() -> bool:
	if _player == null:
		return false
	if not (_month12_phase in ["hud_tour", "tour", "e02_walk", "node_walk", "sleep_walk"]):
		return false
	for activity_id in _month12_place_portals:
		var portal := _month12_place_portals[activity_id] as Node2D
		if portal == null or bool(portal.sealed):
			continue
		if _player.position.distance_to(portal.position) > PLACE_REACH_DISTANCE:
			continue
		_show_reminder_toast("这扇门先记着", "跟着黄线走完这一趟，回头再进来")
		return true
	return false


## 屏幕下方那颗 E：对「已解锁 + 已撕条」的门亮。
## 门开过就一直在：自由安排之外也进得去，只是只给一句环境话、不结算。
## 只在玩家能自由走动的时候亮——剧情面板开着、或者正在沿黄线走，都不打扰。
func _update_month12_place_prompt() -> void:
	_month12_nearby_place = ""
	if _interaction_button == null:
		return
	if _player == null or _date_cutscene_lock:
		_interaction_button.hide()
		return
	if _story_event_panel != null and _story_event_panel.is_open():
		_interaction_button.hide()
		return
	if not _month12_place_window_open():
		_interaction_button.hide()
		return
	var best := PLACE_REACH_DISTANCE
	for activity_id in _month12_place_portals:
		var portal := _month12_place_portals[activity_id] as Node2D
		if portal == null or bool(portal.sealed):
			continue
		var distance := _player.position.distance_to(portal.position)
		if distance <= best:
			best = distance
			_month12_nearby_place = String(activity_id)
	# 剧情那一眼那扇门也是一扇门：它不在去处表里，但同样要按 E 才进得去。
	if _story_door != null and not _month12_visit_id.is_empty() and not bool(_story_door.sealed) \
			and _player.position.distance_to(_story_door.position) <= best:
		_month12_nearby_place = _month12_visit_id
	if _month12_nearby_place.is_empty():
		_hint_at_portal = false
		_interaction_button.hide()
		return
	var activity := _month12_place_by_id(_month12_nearby_place)
	_interaction_button.text = "按 E 进去 · %s" % String(activity.get("name", ""))
	_interaction_button.show()
	if not _hint_at_portal:
		_hint_at_portal = true
		_fire_hints("portal_reached")


## 按 E 进的是这个区的室内（现成室内图），进去之后右边才列可做的事——
## 和旧版一样的顺序，不在门口给选项（2026-10-27 反馈）。
func _enter_month12_place() -> void:
	if _month12_nearby_place.is_empty():
		return
	var activity := _month12_place_by_id(_month12_nearby_place)
	if activity.is_empty():
		return
	var zone := _zone_by_code(String(activity.get("locationId", "")))
	if zone.is_empty():
		return
	if _interaction_button != null:
		_interaction_button.hide()
	_enter_month12_interior(zone, String(activity.get("scene", "")))
	_show_month12_place_list(String(zone.get("code", "")))


## 只借旧版"进室内"的演出与出口，不碰主线事件判定（那套在首月不该跑）。
## scene_path 非空 = 这个活动有自己的场景图（天台、心湖），用它，不用区的办公大堂图。
func _enter_month12_interior(zone: Dictionary, scene_path := "") -> void:
	if _player == null or _interior_preview == null:
		return
	_portal_return_position = _player.position
	_active_zone = zone
	_nearby_zone = {}
	_zone_entered_msec = Time.get_ticks_msec()
	ApiClient.record_event("region_entered", {"regionId": String(zone.get("code", ""))})
	if _zone_status != null:
		_zone_status.hide()
	if _dialog_label != null:
		_dialog_label.hide()
	for marker in _location_markers:
		marker.hide()
	var texture_path := scene_path
	if texture_path.is_empty():
		texture_path = String(INTERIOR_ASSETS.get(String(zone.get("code", "")), ""))
	# 活动图和人站的位置得配套：这批图的地板在画面下半部，先换动线再摆人。
	_interior_preview.use_activity_layout(not scene_path.is_empty())
	if not texture_path.is_empty():
		_interior_preview.present(zone, texture_path)
		# 屋里亮不亮看日期栏的昼夜那一格：十二个月这条线的光照不归旧钟点读数管，
		# 拿 WorldClock 的 phaseId 会让"夜里回宿舍"的屋子还是大白天亮着。
		var phase := _date_time_band if _month12_active else String(WorldClock.snapshot().get("phaseId", "work"))
		_interior_preview.set_phase(phase)
	_interior_preview.suppress_interior_npc(not scene_path.is_empty())
	_interior_preview.enable_exploration()
	if not scene_path.is_empty():
		_month12_scene_npcs_hidden = true
		for npc in _npc_instances:
			(npc["character"] as CanvasItem).visible = false
			(npc["name_tag"] as CanvasItem).visible = false


## 从活动场景出来：把同事们的可见性还原成"在镇上"的默认状态。
func _restore_month12_scene_npcs() -> void:
	if not _month12_scene_npcs_hidden:
		return
	_month12_scene_npcs_hidden = false
	for npc in _npc_instances:
		(npc["character"] as CanvasItem).visible = true
		(npc["name_tag"] as CanvasItem).visible = true


## 室内右侧那张活动列表：数据来自十二个月的去处表，不读旧 48 个月的配置。
func _show_month12_place_list(zone_code: String) -> void:
	if _activity_panel == null:
		return
	var rows: Array = []
	for value in _month12_places:
		if not (value is Dictionary):
			continue
		var act := value as Dictionary
		if String(act.get("locationId", "")) != zone_code:
			continue
		var pid := String(act.get("id", ""))
		if not _month12_place_portals.has(pid) and not _month12_unlocked_places.has(pid):
			# 门没开的去处不列出来：这一屋子只放"你去得了的地方"。
			# 之前是把全区清单照抄，第 7 月小赵那句话还没说，训练谷和草坪就已经挂在列表里了。
			continue
		var shots: Array = (act.get("card", {}) as Dictionary).get("shots", []) as Array
		var thumb := String(act.get("scene", ""))
		if thumb.is_empty() and not shots.is_empty():
			thumb = "res://assets/ui/place_cards/%s" % String(shots[0])
		var row := {
			"id": String(act.get("id", "")),
			"title": String(act.get("name", "自由活动")),
			"image": thumb,
			"note": _month12_place_row_note(act),
		}
		if _mood <= 0 and _restores_mood(act):
			# H=0：这一格只能用来缓过来（4.15 第 2 本账最后一句）——
			# 能缓过来的那处留着能按，别的压灰，主线照样能走。
			row["note"] = "能缓过来一点 · 就按这个"
		elif _mood <= 0:
			row["disabled"] = true
			row["note"] = "今天只能缓一缓"
		rows.append(row)
	# 剧情那一眼：屋里那一行只有"这一屏等着玩家进门"的时候才列出来，
	# 而且排在最前面——这一趟就是为它来的，不能垫在一堆老地方底下。
	var visit := _month12_visit_place()
	if not visit.is_empty() and String(visit.get("locationId", "")) == zone_code:
		var visit_thumb := String(visit.get("scene", ""))
		if visit_thumb.is_empty():
			visit_thumb = String(INTERIOR_ASSETS.get(zone_code, ""))
		rows.insert(0, {
			"id": _month12_visit_id,
			"title": "要去的 · %s" % String(visit.get("name", "看一眼")),
			"image": visit_thumb,
			"note": String(visit.get("rowNote", visit.get("object", "进去看看"))),
		})
	if rows.is_empty():
		_activity_panel.hide_panel()
		return
	var slots_left := _month12_slots_left if _month12_activity_generic \
		else (0 if _month12_activity_taken else 1)
	var slots_total := _month12_slots_total if _month12_activity_generic else 1
	var points_text := ""
	if _month12_activity_generic and _month12_phase == "activity":
		points_text = "本月还剩 %d 格" % slots_left if slots_left > 0 else "本月没有个人时间 · 依旧进得去"
	elif _month_runner != null and bool(_month_runner.active):
		points_text = "现在只是路过 · 不花点"
	else:
		# 首月那一格：口径跟通用月份一致，别再露出旧 48 个月的"剩余行动力"。
		points_text = "本月还剩 1 格" if slots_left > 0 else "这个月安排完了 · 老地方还能进去坐坐"
	_activity_panel.show_for_region(zone_code, rows, slots_left, slots_total, points_text,
		_month12_now_line(zone_code))


## 面板最底下那一句落点："现在去什么地方做什么"。
## 玩家看完一屋子能进的地方，最后要带走的是这一句，不是"这里有三处可去"。
func _month12_now_line(zone_code: String) -> String:
	var visit := _month12_visit_place()
	if not visit.is_empty():
		if String(visit.get("locationId", "")) == zone_code:
			return "现在就来对了：进门按%s" % String(visit.get("object", "那件东西"))
		return "现在要去的是 %s —— 跟着黄线走" % String(visit.get("location", visit.get("name", "剧情那一处")))
	if _month12_activity_generic and _month12_phase == "activity":
		if _month12_slots_left <= 0:
			return "这个月的格子用完了 · 想坐坐随时进，不花点"
		return "现在挑一扇亮着的门进去 · 按一件东西（还剩 %d 格）" % _month12_slots_left
	if _month_runner != null and bool(_month_runner.active):
		return "现在跟着黄线去 %s" % String((_month_runner.current as Dictionary).get("location", "下一处"))
	return ""


## 列表上的那行小字：先说去那儿干什么（活动表里现成的 placeLine），
## 只有真要占这个月的格子时才在最前面加代价——路过的时候不重复"不花点"。
func _month12_place_row_note(act: Dictionary) -> String:
	var reason := String(act.get("placeLine", ""))
	if reason.is_empty():
		reason = String(act.get("description", "进去按一件东西"))
	if not _month12_activity_generic:
		if _month_runner != null and bool(_month_runner.active):
			return reason
		# 首月那一格：口径跟账本一致，不再露出旧 48 个月的"行动力"说法。
		return reason if _month12_activity_taken else "占 1 格 · %s" % reason
	if _month12_phase != "activity" or _month12_slots_left <= 0 \
			or _month12_activity_visited(String(act.get("id", ""))):
		return reason
	return "占 1 格 · %s" % reason


func _month12_activity_visited(activity_id: String) -> bool:
	return bool(_month12_flags.get("visit_%d_%s" % [_month12_month, activity_id], false))


## 做完了：旗标与上报原样保住，再走结果演出。
func _on_month12_place_confirmed(activity_id: String) -> void:
	var activity := _month12_place_by_id(activity_id)
	if activity.is_empty():
		return
	if _month12_activity_generic:
		if _month12_slots_left <= 0 or _month12_activity_visited(activity_id):
			# 格子空了、或者这个月已经结算过：只演一句环境话，不扣点、不给好处。
			if _month12_place_panel != null:
				_month12_place_panel.close()
			_exit_zone()
			_present_month12_revisit(activity)
			return
		_month12_slots_left = maxi(0, _month12_slots_left - maxi(1, int(activity.get("slots", 1))))
		_month12_flags["visit_%d_%s" % [_month12_month, activity_id]] = true
		# 同月同活动只结算一次；这里只可能是第一次。
		var reward := String(activity.get("rewardFlag", ""))
		if not reward.is_empty():
			_month12_flags[reward] = true
		_update_month12_activity_card()
	else:
		_month12_activity_taken = true
	# 这一笔两本账一起结：行动点扣掉（首月那一格和通用月份的格子走同一条），
	# 心情按这处活动的消耗/给回算，两边都记进月末那行账。
	var ap_spent := maxi(0, int(activity.get("apCost", 1)))
	_month12_ap_left = maxi(0, _month12_ap_left - ap_spent)
	_record_ledger(String(activity.get("name", "自由活动")), ap_spent, _apply_activity_mood(activity))
	_fire_hints("activity_done")
	_month12_nearby_place = ""
	if _interaction_button != null:
		_interaction_button.hide()
	_on_month12_activity_chosen(activity_id)
	if _month12_place_panel != null:
		_month12_place_panel.close()
	# 做完先退出室内，回到镇上再播结果——不然结果图叠在室内预览上。
	_exit_zone()
	_present_month12_place_outcome(activity)


## 结果演出：一张真实截图 + 两句结果（复用旧版周末场景面板，图没了也不拦流程）。
func _present_month12_place_outcome(activity: Dictionary) -> void:
	if _weekend_scene_panel == null:
		call_deferred("_start_month12_close")
		return
	var shots: Array = (activity.get("card", {}) as Dictionary).get("shots", []) as Array
	var image := String(activity.get("scene", ""))
	if image.is_empty() and not shots.is_empty():
		image = "res://assets/ui/place_cards/%s" % String(shots[0])
	var second := "本周安排完了，可以结束这个月。"
	if _month12_activity_generic:
		second = "还能再去一个地方。" if _month12_slots_left > 0 else "这个月安排完了，可以结束这个月。"
	_weekend_scene_panel.present({
		"title": String(activity.get("name", "自由活动")),
		"image": image,
		"lines": [String(activity.get("outcome", "")), second],
	})


## 再访：同一个地方这个月已经结算过，只演一句环境话；0 格月也走这里。
func _present_month12_revisit(activity: Dictionary) -> void:
	var line := String(activity.get("againLine", ""))
	if line.is_empty():
		line = "这里还是老样子。"
	var shots: Array = (activity.get("card", {}) as Dictionary).get("shots", []) as Array
	var image := String(activity.get("scene", ""))
	if image.is_empty() and not shots.is_empty():
		image = "res://assets/ui/place_cards/%s" % String(shots[0])
	if _weekend_scene_panel == null:
		_show_reminder_toast(String(activity.get("name", "自由活动")), line)
		return
	_weekend_scene_panel.present({
		"title": String(activity.get("name", "自由活动")),
		"image": image,
		"lines": [line],
	})


func _on_month12_activity_chosen(option_id: String) -> void:
	_month12_flags["activity"] = option_id
	var act := _month12_place_by_id(option_id)
	# regionId 必须是 A–H：传输层缺省会兜到"A"，人在心湖做完一件事却记成总部，
	# 报告侧按组团统计投入结构就全错了。
	ApiClient.record_event("m%02d_activity" % _month12_month, {
		"activityId": option_id,
		"regionId": String(act.get("locationId", "")),
		"apSpent": maxi(0, int(act.get("apCost", 1))),
		"slotsSpent": maxi(1, int(act.get("slots", 1))),
		"moodBefore": _mood_before_settle,
		"moodAfter": _mood,
		"apLeftAfter": _month12_ap_left,
		"slotsLeftAfter": _month12_slots_left if _month12_activity_generic else (0 if _month12_activity_taken else 1),
	})


func _on_end_month_pressed() -> void:
	_show_end_month_button(false)
	if _month12_activity_generic:
		# 后面还有剧情时这颗按钮只是"不逛了"，不说一句玩家会以为整个月都翻过去了。
		if not _activity_next_is_close:
			_show_reminder_toast("这两格不安排了", "今天后面还有一段，接着走")
		call_deferred("_finish_month12_activity_node")
		return
	if not _month12_activity_taken:
		# 首月没去任何地方就翻月：引擎记一笔跳过（手册 4.15 的全年规则）。
		_month12_flags["m01_activity_skipped"] = true
	call_deferred("_start_month12_close")


func _show_end_month_button(value: bool) -> void:
	if _end_month_button == null:
		return
	# 每次亮出来先回到默认标签：这条函数也会被首月那套手写流程调用，
	# 不重置的话上一屏改过的"不逛了·回工位"会跟着飘到别的月份上。
	if value:
		_end_month_button.text = "结束这个月"
	_end_month_button.visible = value


## 这颗按钮在自由安排里到底干哪件事：后面直接进月末卡才是真的"结束这个月"，
## 后面还挂着当天晚上那几屏，就只写"不逛了·回工位"。
## 节点里的 endMonthLabel 一直是死数据，这里才开始用（第 1 月那枚写的是"结束本月"）。
func _refresh_end_month_label(node: Dictionary) -> void:
	if _end_month_button == null:
		return
	if _activity_next_is_close:
		var label := String(node.get("endMonthLabel", ""))
		_end_month_button.text = label if not label.is_empty() else "结束这个月"
		return
	_end_month_button.text = "不逛了·回工位"


# ---------------------------------------------------------------- G 月末回顾

func _start_month12_close() -> void:
	_month12_phase = "close"
	_settle_sleep_backup()
	_emit_month_close_snapshot()
	# 白天 → 夜晚：最小的一档，只在左上角那一格里刷一道光；天暗下去再开月末卡。
	_date_then(_month12_month, _month_close_phase, "night", _after_month12_night_card)


## 睡觉兜底：心情 ≤1 而这个月还有没花掉的格子时，那些格子自动拿去睡觉，每格回 1 点。
## 只在玩家没花的时候发生——想硬扛的人照样能把格子花出去，它不抢选择。
## 回的是 1 点，跟天台一样：如果睡觉回得比专门跑一趟天台还多，天台那页卡就白写了。
func _settle_sleep_backup() -> void:
	var left := 0
	if _month12_activity_generic:
		left = _month12_slots_left
	elif not _month12_activity_taken:
		left = 1
	if left <= 0 or _mood > 1:
		return
	var before := _mood
	_mood = mini(_mood_max, _mood + left)
	_record_ledger("睡觉", 0, _mood - before)
	_refresh_mood_hud()


## 月末收束快照：报告 8.1 里"自由活动回顾"和七行摘要的"状态行"要的就是这一条。
## 事件名用的是契约里已经注册的 weekend_close（月份 / 收束快照，不测评），
## 十二个月这条线之前一直没发过它。
func _emit_month_close_snapshot() -> void:
	var slept := false
	for entry in _month_ledger:
		if String((entry as Dictionary).get("what", "")) == "睡觉":
			slept = true
	ApiClient.record_event("weekend_close", {
		"month": _month12_month,
		"apBudget": _ap_total,
		"apSpent": _ap_total - _month12_ap_left,
		"apLeft": _month12_ap_left,
		"moodStart": _mood_month_start,
		"mood": _mood,
		"slept": slept,
		"ledger": _month_ledger.duplicate(true),
	})


## 入夜那道光刷完之后再开月末回顾卡。
func _after_month12_night_card() -> void:
	_set_objective("第 %d 月" % _month12_month, "月末回顾", "这个月的事都记下了", "", false)
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("月末回顾", "第 %d 月" % _month12_month)
		_town_ui_v2.set_task_note("这个月安排完了")
	var card := _month_close_text_override if not _month_close_text_override.is_empty() else String(MONTH12_MONTH_CARDS.get(_month12_e02_choice, "第 1 月：你先把手上的工作交掉了。"))
	_month_close_text_override = ""
	if _month12_close_panel == null:
		_month12_close_panel = MONTH12_CLOSE.new()
		_month12_close_panel.name = "Month12Close"
		_month12_close_panel.finished.connect(_on_month12_close_finished)
		_month12_close_panel.archive_requested.connect(_open_archive_from_close_card)
		add_child(_month12_close_panel)
	_month12_close_panel.open(card, _month12_month, _month_ledger_line())


func _on_month12_close_finished() -> void:
	if _month12_close_panel != null:
		_month12_close_panel.close()
	_month12_phase = "done"
	# 月历入口已删（TownUiV2 里的 set_month_visible 没了）；档案入口在回顾卡里给。
	# 换月过场播完就直接进下个月的节点表（没填表的月份由播放器收成"制作中"）。
	var finished_month := _month12_month
	_town_ui_v2.set_task_card("第 %d 月完成" % finished_month, "下一个月的记录在整理")
	_town_ui_v2.set_task_note("过场之后继续")
	_set_objective("第 %d 月完成" % finished_month, "下一个月的记录在整理", "这个月的选择已经记下", "", false)
	_save_month12_progress()
	_show_reminder_toast("第 %d 月完成" % finished_month, "把这个月收好，回去睡一觉")
	# 档案从这一夜才翻开（2026-10-30 玩家定）：先讲一次"里面有什么"，讲完再回宿舍 / 翻月。
	_unlock_archive_then(func(): _continue_after_month_close(finished_month))


## 月末回顾卡关掉之后的正事：评估、提前收口、翻月、走回宿舍。
func _continue_after_month_close(finished_month: int) -> void:
	# 第 6 月过完就判一次：红线 → 举证 → 分数，结论到第七月初才落地。
	if finished_month == 6 and not _month12_flags.has("m06_probation_status"):
		_evaluate_probation()
	# 未转正与违纪解除的人在第七月做完交接就结束在岗主线：不进第 8 月。
	if finished_month == 7 and bool(_month12_flags.get("probation_ended", false)):
		_end_year_early()
		return
	# 最后一个月不睡：那天之后是年度报告，不是下个月。
	if finished_month >= 12:
		_date_then(finished_month + 1, "early", "morning", func(): _start_month_nodes(finished_month + 1))
		return
	_start_sleep_walk(finished_month)


## 月末这一刻才允许翻档案，并且"第一次翻开"的讲解只自动弹这一次：
## 卡关掉（点「打开档案」或「稍后」都算）才继续往下走，不然回宿舍会被卡在半路。
func _unlock_archive_then(after: Callable) -> void:
	_archive_open_allowed = true
	if _archive_card_offered or not _show_hud_button_tutorial("profile", Callable(self, "_open_ui_profile")):
		after.call()
		return
	_archive_card_offered = true
	_after_profile_step = after
	_hud_button_tutorial.closed.connect(_on_profile_card_closed, CONNECT_ONE_SHOT)


func _on_profile_card_closed() -> void:
	# 卡片是"先关、后开页"：这一帧走完再看页面开没开，别把回宿舍那一步顶到档案页前面。
	_continue_after_profile_card.call_deferred()


func _continue_after_profile_card() -> void:
	var after := _after_profile_step
	_after_profile_step = Callable()
	if _town_ui_v2 != null and _town_ui_v2.is_open():
		# 玩家选了「打开档案」：等他看完、关掉那一页，再走。
		_pending_after_profile = after
		return
	after.call()


## 主线停在第七月：未转正与违纪解除都在这里收口。年度记录只收已经发生的事，
## 两种理由分开说——一种是差距，一种是越线，措辞都不出现处分、开除、人格评价。
func _end_year_early() -> void:
	var terminated := bool(_month12_flags.get("probation_terminated", false))
	_month12_phase = "done"
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("本年度到此为止", "交接完成")
		_town_ui_v2.set_task_note("记录收在这里 · 只写已发生的事")
	_set_objective(
		"第 7 月",
		"本年度到此为止",
		"交接完成",
		"违纪解除 · 理由已书面告知" if terminated else "未转正 · 差在哪一项已写进材料",
		false
	)
	_save_month12_progress()
	_show_reminder_toast(
		"交接完成",
		"这个年度的记录收在这里；" + ("解除依据在办公桌上那张纸上" if terminated else "下一步建议在那张纸上")
	)


## 月末不回工位直接翻月：先走回宿舍，进门熄灯，睡完才开下个月。
## 宿舍用现成的 H 区内景，不新做美术；走位有兜底（30 秒提示、60 秒自动带到门口）。
func _start_sleep_walk(finished_month: int, then := Callable(), wake_phase := "early", gap_text := "") -> void:
	var zone := _zone_by_code("H")
	if zone.is_empty():
		_date_then(finished_month + 1, "early", "morning", func(): _start_month_nodes(finished_month + 1))
		return
	var door: Vector2 = _snap_month12_point(zone.get("entrance", Vector2.ZERO))
	_month12_sleep_month = finished_month
	_sleep_then = then
	_sleep_wake_phase = wake_phase
	_sleep_gap_text = gap_text
	_month12_waypoint = door
	_month12_phase = "sleep_walk"
	_walk_started_msec = Time.get_ticks_msec()
	_walk_skip_offered = false
	_walk_pause_started_msec = 0
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("回宿舍", "慢生活园 · 宿舍与桌游馆")
		_town_ui_v2.set_task_note("回去睡一觉，明天再继续")
	_set_objective("第 %d 月" % finished_month, "慢生活园 · 宿舍", "回去睡一觉", "", false)
	if _guide_line != null and _player != null:
		_guide_line.set_path(_build_guide_path(_player.position, door))


## 到了宿舍门口：进门、熄灯、翻月。那两秒停顿是让"这一夜过去了"有实感。
## 年末深夜那段走位：按 E、或点顶上那条钉住的横幅，都能直接站到宿舍门口。
func _skip_walk_to_dorm() -> void:
	_walk_skip_offered = false
	_hide_gate_banner()
	if _player != null:
		_player.position = _month12_waypoint
	if _interaction_button != null:
		_interaction_button.hide()


func _do_sleep() -> void:
	if _month12_phase != "sleep_walk":
		return
	_hide_gate_banner()
	_notice_hint("month_closed", "")
	var month := _month12_sleep_month
	_month12_phase = "done"
	_walk_pause_started_msec = 0
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	var zone := _zone_by_code("H")
	if not zone.is_empty():
		_enter_month12_interior(zone, "")
		# 这一夜是夜里：室内也压成夜间色（和镇上的夜晚同一套，不另做美术）。
		if _interior_preview != null:
			_interior_preview.set_phase("night")
	# 熄灯紧跟黑场：这一枪只补个底，别跟后面的黑场抢时间。
	_apply_date_band("夜晚", BAND_FADE_SLEEP)
	_show_reminder_toast("熄灯", "今天到这儿。明天再来。")
	# 熄灯之后画面暗下去，在黑场里翻月——"睡着了"比"啪一下换成早晨"可信。
	var black := ColorRect.new()
	black.color = Color(0.02, 0.02, 0.04, 0.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 188
	layer.add_child(black)
	add_child(layer)
	var fade := create_tween()
	fade.tween_property(black, "color:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# 跨旬那一觉会在黑场里亮一句「两周后」，不摆"睡着了"那段长停顿：
	# 黑场已经够沉，早点把话说出来（2026-10-30 反馈"黑场有点长"）。
	var gap := ""
	if _sleep_then.is_valid():
		gap = _sleep_gap_text
		_sleep_gap_text = ""
	await get_tree().create_timer(1.2 if not gap.is_empty() else 2.2).timeout
	_exit_zone()
	if _sleep_then.is_valid():
		# 月中那一觉：不翻月。天亮回到镇上，玩家自己走回工位，节点表接着往下走。
		var then := _sleep_then
		_sleep_then = Callable()
		_month12_phase = "month_nodes"
		if gap.is_empty():
			_date_then(month, _sleep_wake_phase, "morning", then)
		else:
			# 跨旬那一觉（第 3 月收工后）：黑场里亮一句「两周后」，醒来牌面直接是中旬。
			# 这样"回宿舍睡一觉"和"过了多久"是同一拍，不再醒了之后再补一张旬卡。
			await _show_sleep_gap(gap)
			_write_date_plate(month, _xun_text(_sleep_wake_phase), "白天", "morning")
			# 把黑场拉开、让天先亮出来，再空一拍才开下一屏：
			# 一觉睡到中旬，直接切进去太快，没有"醒来"这一拍（2026-10-30 反馈）。
			var dawn := create_tween()
			dawn.tween_property(black, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
			await dawn.finished
			if is_instance_valid(layer):
				layer.queue_free()
			await get_tree().create_timer(0.5).timeout
			then.call()
			return
	else:
		_date_then(month + 1, "early", "morning", func(): _start_month_nodes(month + 1))
	# 两条路都要把黑场收掉。月中那一觉以前在这里提前 return，黑块就留在 188 层
	# （盖在 HUD 上面），第 2 月"太晚了，先回去休息"之后整个画面就一直是黑的。
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(layer):
		layer.queue_free()


## 睡过去的那一段：黑场里单独亮一句「两周后」，然后天亮。
## 层号要压过黑场（188），不然字被黑块盖住；字用和过场卡同一支手写体。
const SLEEP_GAP_FONT := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")


func _show_sleep_gap(text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 189
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", SLEEP_GAP_FONT)
	label.add_theme_font_size_override("font_size", 96)
	label.add_theme_color_override("font_color", Color("F3E3C2"))
	label.add_theme_color_override("font_outline_color", Color("23170f"))
	label.add_theme_constant_override("outline_size", 6)
	label.modulate.a = 0.0
	layer.add_child(label)
	# 铺满要等进了父节点再设，否则取到的父矩形是空的（同 TransitionWipe 那条注）。
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.35)
	tween.tween_interval(0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	await tween.finished
	if is_instance_valid(layer):
		layer.queue_free()


## 通宵那一屏（第 5 月那晚）：人没走，就在工位趴到天亮。
## 和回宿舍那一趟同一个读法——黑场里亮一句「第二天」，醒来牌面已经是白天——
## 只是不走位、不进屋：剧情里他回不去，线上还挂着告警。
func _do_all_nighter(month: int, then: Callable) -> void:
	_month12_phase = "sleep_desk"
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	# 面板还没收干净时压黑会把它一起盖住：等它关。
	while _story_event_panel != null and is_instance_valid(_story_event_panel) \
			and _story_event_panel.is_open():
		await get_tree().process_frame
	_show_reminder_toast("太晚了", "回不去了，就在工位趴一会儿。")
	var black := ColorRect.new()
	black.color = Color(0.02, 0.02, 0.04, 0.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 188
	layer.add_child(black)
	add_child(layer)
	var fade := create_tween()
	fade.tween_property(black, "color:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished
	await _show_sleep_gap("第二天")
	# 醒来就是白天：牌面在黑场里直接落到下一屏的旬，醒来不再补一张旬卡。
	var wake_phase := "early"
	if _month_runner != null and is_instance_valid(_month_runner):
		var nxt: Dictionary = _month_runner.call("peek_next")
		wake_phase = String(nxt.get("phase", "early"))
	_write_date_plate(month, _xun_text(wake_phase), "白天", "morning")
	var dawn := create_tween()
	dawn.tween_property(black, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	await dawn.finished
	if is_instance_valid(layer):
		layer.queue_free()
	await get_tree().create_timer(0.4).timeout
	_month12_phase = "month_nodes"
	then.call()


func _finish_month12() -> void:
	_month12_phase = "done"
	_save_month12_progress()


func _save_month12_progress(at_month_start := false) -> void:
	var payload := {
		"month": _month12_month,
		# 便签是一局一面的：存档记下这一局的编号，续玩才接得回自己那面墙。
		"runStamp": _run_stamp,
		# 只有"这一月刚开头"才置 true：开机续玩只认这一种落点，月中关掉不接半截。
		"monthStart": at_month_start,
		"e02": _month12_e02_choice,
		"activity": String(_month12_flags.get("activity", "")),
		"handbookRead": bool(_month12_flags.get("handbook_read", false)),
		"phoneRead": not _month_phone_unread,
		"unlockedPlaces": _month12_unlocked_places.keys(),
		"flags": _month12_flags,
		"mood": _mood,
		"moodMax": _mood_max,
		"apLeftThisMonth": _month12_ap_left,
		"monthLedger": _month_ledger,
	}
	var file := FileAccess.open("user://workplace_town_month12.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "  ") + "\n")


## 每帧：首月的黄线由这里驱动，到点即播下一段。
## 黄线跟着人实时改道。
##
## 以前只在目标出现那一刻铺一次路，之后每帧只把线头挪到玩家脚下：
## 玩家一旦没按原路走（绕开长椅、从另一侧过来），线就会从他现在的位置拉一条直线
## 插回老路的第二个拐点 —— 看着就像一条横穿草坪的假路。
## 现在每帧比一次"人离上次铺线时站的地方有多远"，超过一小步就用当前站位重新寻路；
## 没超过仍然只挪线头（便宜，也不会让虚线相位在世界坐标里抖）。
## 收掉十二个月这条引导线，连"上次是从哪儿铺的"一起清零：
## 不清零的话，下次铺线会以为原点没动，沿着上一条路径接着画。
func _hide_month12_guide() -> void:
	if _month12_guide_from.x < -90000.0:
		return
	if _guide_line != null and is_instance_valid(_guide_line):
		_guide_line.clear()
	_month12_guide_from = Vector2(-99999, -99999)


func _lay_month12_guide(force := false) -> void:
	if _guide_line == null or _player == null or _month12_waypoint.x < -90000.0:
		return
	if force or _month12_guide_from.x < -90000.0 \
			or _player.position.distance_to(_month12_guide_from) > MONTH12_GUIDE_REPATH:
		_month12_guide_from = _player.position
		_guide_line.set_path(_build_guide_path(_player.position, _month12_waypoint), true)
	else:
		_guide_line.set_origin(_player.position)


## 钉住的提示什么时候该收：数据里每条都带 dismissOn（first_move / node_completed:X /
## node_started:X / month_closed）。这里只认一句"发生了什么"，对上了就收。
func _notice_hint(kind: String, subject: String) -> void:
	if _gate_banner_hint.is_empty():
		return
	var rule := String(_gate_banner_hint.get("dismissOn", ""))
	if rule.is_empty():
		return
	var hit := rule == kind
	if rule.contains(":"):
		hit = rule == "%s:%s" % [kind, subject]
	if hit:
		_hide_gate_banner(String(_gate_banner_hint.get("id", "")))


## 节点一换就通知两条：旧节点完成、新节点开始。
func _track_month_node() -> void:
	if _month_runner == null or not is_instance_valid(_month_runner):
		return
	var node_id := String((_month_runner.get("current") as Dictionary).get("id", ""))
	if node_id == _last_month_node_id:
		return
	if not _last_month_node_id.is_empty():
		_notice_hint("node_completed", _last_month_node_id)
	_last_month_node_id = node_id
	if not node_id.is_empty():
		_notice_hint("node_started", node_id)


func _update_month12_waypoint() -> void:
	# 走位期间室内预览还开着（上一屏是在室内演的），人就动不了、也永远到不了落点。
	# 放在这里而不是 walk_to 里：那条路另一条线还在改，这个守卫每帧跑一遍更稳。
	if _month12_phase in ["node_walk", "sleep_walk"] and _interior_preview != null and _interior_preview.is_open():
		_interior_preview.dismiss()
		_active_zone = {}
		_nearby_npc = {}
		_restore_month12_scene_npcs()
	_track_month_node()
	if _month12_waypoint.x < -90000.0:
		# 这一拍没有落点（"先看手机"这道门槛就是这种状态）：把上一段留下的黄线收掉。
		# 不收的话，上个月末"回宿舍"那条线会一直拖在脚下，玩家读成"现在就该去宿舍"，
		# 而任务卡说的是右下角那颗手机——地上和纸上指两个方向，就是刚才那个 bug。
		_hide_month12_guide()
		return
	if _guide_line == null or _player == null:
		return
	_lay_month12_guide()
	# 手机/手册打开时，走位计时真正暂停；关掉后从原处继续。
	if _month12_phase in ["node_walk", "sleep_walk"] and _month12_reading():
		if _walk_pause_started_msec == 0:
			_walk_pause_started_msec = Time.get_ticks_msec()
		return
	if _walk_pause_started_msec != 0:
		_walk_started_msec += Time.get_ticks_msec() - _walk_pause_started_msec
		_walk_pause_started_msec = 0
	# 剧情走位没有超时、没有自动开场；下面两段只留给月末回宿舍。
	if _month12_phase == "sleep_walk" and not _month12_reading() \
			and not _walk_skip_offered \
			and _player != null and _player.position.distance_to(_month12_waypoint) > 70.0 \
			and Time.get_ticks_msec() - _walk_started_msec > 30000:
		_walk_skip_offered = true
		# 与"先看手机"同一种待遇：这一刻玩家不动就走不下去，
		# 不能靠一条三秒就消失的提示去赌他看见。
		_show_gate_banner("宿舍在等你", "按 E 直接到门口，或者点这条",
			Callable(self, "_skip_walk_to_dorm"))
	if _month12_phase == "sleep_walk" and not _month12_reading() \
			and _player != null and _player.position.distance_to(_month12_waypoint) > 70.0 \
			and Time.get_ticks_msec() - _walk_started_msec > 60000:
		if _player != null:
			_player.position = _month12_waypoint
		_do_sleep()
		return
	if _month12_reading():
		return
	if _player.position.distance_to(_month12_waypoint) > 70.0:
		return
	match _month12_phase:
		"tour":
			_present_month12_stop()
		"e02_walk":
			_present_month12_e02()
		"node_walk":
			if _month_runner != null:
				_month_runner.on_walk_arrived()
		"sleep_walk":
			_do_sleep()
		_:
			pass


func _month12_reading() -> bool:
	if _month12_handbook != null and is_instance_valid(_month12_handbook) and _month12_handbook.is_open():
		return true
	if _month_phone_panel != null and is_instance_valid(_month_phone_panel) and _month_phone_panel.is_open():
		return true
	return false


func _walk_fallback_enabled() -> bool:
	if _month_runner == null or not is_instance_valid(_month_runner):
		return false
	return bool(_month_runner.current.get("walkFallback", false))


func _schedule_hud_tour() -> void:
	await get_tree().create_timer(0.4).timeout
	_start_hud_tour()


func _start_hud_tour() -> void:
	if _hud_tour_done or _hud_tour_active or _hud_tour == null or _town_ui_v2 == null:
		return
	if _story_event_panel != null and _story_event_panel.is_open():
		return
	var job := _hud_control("_job_label")
	var task := _hud_control("_task_panel")
	if not job.has_area() or not task.has_area():
		# 这两块还没摆出来（HUD 刚重排过，显示时机变了）。以前这里直接 return，
		# 于是流程永远停在"HUD 引导"这一步、第 1 月开局就出不来。改成稍后重试；
		# 实在等不到就跳过这四步讲解，也不能把主线堵在这儿。
		_hud_tour_retries += 1
		if _hud_tour_retries > 40:
			_hud_tour_retries = 0
			_on_hud_tour_finished()
			return
		_schedule_hud_tour()
		return
	_hud_tour_retries = 0
	var steps: Array = [
		{
			"rect": job,
			"title": "左上 · 你的岗位",
			"body": "这一行写着你现在的岗位，转正、晋升会换在这上面。点它就能翻开你的档案——评估、能力、这一路的记录都在里面。",
			"place": "below",
		},
		{
			"rect": task,
			"title": "右上 · 当前要做的事",
			"body": "任务卡写着当前目的地。按 WASD／方向键，或拖左下角摇杆；沿黄线到终点，剧情会自动继续。",
			"place": "left",
		},
	]
	_hud_tour_active = true
	_hud_tour.start(steps)


func _hud_control(var_name: String) -> Rect2:
	var control = _town_ui_v2.get(var_name) if _town_ui_v2 != null else null
	if control is Control and (control as Control).is_visible_in_tree():
		return (control as Control).get_global_rect()
	return Rect2()


## ---------------------------------------------------------------- B 方案：按月播节点

## 节点上的落点：开场这类"切场"直接摆过去；要走过去的写 walk（E04）。
const MONTH_NODE_POINTS := {
	"M02_OPEN": Vector2(1008, 240),
	"E04": Vector2(416, 241),
	# 第 2 月那一眼：走到书院牌楼斜对面那块空地，门就立在那儿（和 STORY_DOOR_POSITIONS 同一个点）。
	"M02_LIBRARY": Vector2(1424, 720),
	# 第 3 月客户会谈：从上一屏走到 C 区水巷门口再开屏（E10 在数据里是 walk）。
	"E10": Vector2(1424, 273),
	# 第 4 月复盘会：通知出现后走到 A 区复盘会议室（E07 在数据里是 walk）。
	"E07": Vector2(416, 241),
	# 第 5 月客户 Demo：深夜之后走到观澜会展码头（M05_DEMO 在数据里是 walk）。
	"M05_DEMO": Vector2(702, 833),
	# 第 5 月彩排：周四下午还在自己工位（同一张桌子，不切场，只是把落点写实）。
	"M05_PREP": Vector2(1008, 240),
	# 第 6 月会前：走到心湖北岸那面记忆墙前挑三件。
	"M06_WALL": Vector2(860, 770),
	# 第 6 月答辩：走到 A 区小会议室。
	"M06_DEFENSE": Vector2(416, 241),
	# 第 7 月事故复盘：走到 A 区会议室（E19 在数据里是 walk）。
	"E19": Vector2(416, 241),
	# 第 8 月白板室：从工位走到 A 区门口再开屏（M08_OPEN 在数据里是 walk）。
	"M08_OPEN": Vector2(416, 241),
	# 第 10 月公告栏：走到 A 区门口看那张 A4。
	"E31": Vector2(416, 241),
	# 第 11 月木栈道：走到心湖北岸听老周谈口径。
	"E32": Vector2(860, 770),
}

## 地点默认落点：同一句地点的戏都落到这里；没登记的再回所在区门口。
const LOCATION_POINTS := {
	"B 区工位": Vector2(1008, 240),
	"B 区工位 · 夜": Vector2(1008, 240),
	"B 区楼层门口": Vector2(959, 194),
	"B 区 · 科技丘": Vector2(1008, 240),
	"树影书院 · 长桌": Vector2(1424, 720),
	"树影书院 · 阅览室": Vector2(1424, 720),
	"心湖北岸记忆墙": Vector2(860, 770),
	"A 区总部白板室": Vector2(416, 241),
	"A 区合规复盘室": Vector2(416, 241),
	"A 区会议室": Vector2(416, 241),
	"A 区小会议桌": Vector2(416, 241),
	"A 区大会议室": Vector2(416, 241),
	"A 区大会议室门外": Vector2(416, 241),
	"A 区公告栏": Vector2(416, 241),
	"C 区 创意水巷 · 客户展厅": Vector2(1424, 273),
	"C 区 展厅门口": Vector2(1424, 273),
	"C 区水巷外摆": Vector2(1424, 273),
	"观澜会展码头": Vector2(702, 833),
}


## 跳月看片（按 F8 / 命令行 --v12m-month=N，2026-10-28）：
## 直接开第 N 月，并把第 1..N-1 月那些"上一月的账"一次补齐——条件台词、
## 老地方的门、能力五格都在位，才看得出那一个月真玩起来是什么样子。
## 玩家包里 F8 什么都不做，命令行参数也不在发布档里。
func debug_jump_to_month(month_value: int, path_letter := "A") -> void:
	if month_value < 1 or month_value > 12:
		return
	# 先把眼前这一屏收干净：剧情面板、手册、活动面板、月末卡、档案页。
	if _story_event_panel != null and _story_event_panel.is_open():
		_story_event_panel.dismiss()
	for panel in [_month12_handbook, _month12_activity_panel, _month12_close_panel, _month12_place_panel, _month12_start_panel]:
		if panel != null and is_instance_valid(panel) and panel.has_method("close"):
			panel.call("close")
	_month12_start_next = Callable()
	if _town_ui_v2 != null and _town_ui_v2.is_open():
		_town_ui_v2.close_view()
	if _month_runner != null and is_instance_valid(_month_runner):
		_month_runner.stop()
	# 上一次的门拆掉重建：跳进来的这一眼，门上该是金的还是灰的由补出来的账说话。
	for value in _month12_place_portals.values():
		if is_instance_valid(value):
			(value as Node).queue_free()
	_month12_place_portals.clear()
	_month12_unlocked_places.clear()
	_month12_flags.clear()
	_ability_points.clear()
	# 四维锚点跟着清一遍：不清的话，连跳两次同一月会把账叠上去，判定就越跳越松。
	for dim in _dim_anchors.keys():
		_dim_anchors[dim] = []
	_month12_places_open = false
	_month12_activity_taken = false
	_month12_activity_generic = false
	_month12_visit_node = {}
	_month12_visit_id = ""
	_month12_tour_index = 0
	_phone_gate_waiting = false
	_phone_gate_read = false
	# 跳月是把这一拍整个重来：钉着的门槛横幅也要跟着收，不然会挂到下一个月头上。
	_hide_gate_banner()
	_retire_story_door()
	if month_value == 1:
		# 第一个月是手写的那套开场流程，跳回去等于重开这一局。
		_begin_new_run()
		_month12_month = 1
		_start_month_opening()
		return
	var seed := MonthJump.apply(self, month_value, path_letter)
	# 补完账就知道：这条线在第七月交了接，第八到十二月本来没有内容。
	if month_value > 7 and bool(_month12_flags.get("probation_ended", false)):
		print("跳月收回第七月：%s 路线在第六月末判为未转正/违纪解除，第八月起不开放" % path_letter)
		month_value = 7
	print("跳月 %d（%s 路线）补了：旗标 %d 个 / 老地方 %d 处 / 能力点 %s / 点亮到顶 %s / 四维锚点 %d 条 / 转正结论 %s" % [
		month_value, path_letter, int(seed["flags"]), int(seed["places"]),
		JSON.stringify(seed["points"]), JSON.stringify(seed["peaks"]),
		int(seed["anchors"]), String(seed.get("probation", "本月不判"))])
	for entry in (seed["missing"] as Array):
		print("  补不出来：%s" % String(entry))
	_month12_month = month_value
	# 起账交给 _start_month_nodes（它已经会调 _begin_month_ledger），这里不重复起一遍，
	# 否则心情白加一格、行动点也被发了两次。
	# 之前开过的门重新立起来（"门开过就一直在那儿"）。
	for activity_id in _month12_unlocked_places.keys():
		_ensure_month12_place(String(activity_id))
	if not _month12_unlocked_places.is_empty():
		_month12_places_open = true
		_refresh_month12_place_seals()
	push_date(month_value, "early", "morning")
	_start_month_nodes(month_value)
	if _jump_panel != null and is_instance_valid(_jump_panel):
		_jump_panel.hide()


## 每月一句话，只给跳月面板上的按钮当标签（不是玩家可见文案）。
const JUMP_MONTH_TAGS := ["入职", "选型", "客户", "评测", "告警", "转正", "复盘", "技术债",
	"署名", "带新人", "口径", "答辩"]

## 跳月面板上的四条路线（只给调试看片用）。
## A/C 是真按选项走出来的账；P/R 是看片强制的两个结局——不这么给，
## "未转正"和"违纪解除"那两屏要真玩六个小时才看得到一次。
const JUMP_PATHS := [
	{"letter": "A", "name": "常规"},
	{"letter": "C", "name": "越线"},
	{"letter": "P", "name": "未转正"},
	{"letter": "R", "name": "违纪解除"},
]


## 路线按钮的选中态与那句说明：选哪条，下面那行就写清它会把结论判成什么。
const JUMP_PATH_NOTES := {
	"A": "每月都按第一条选：第六月末判出来通常是转正。",
	"C": "每条都按第三条选：第三月那句超出授权的承诺会落进记录，第六月末先判违纪解除。",
	"P": "看片强制未转正：第七月给交接清单与短收束，第八月起不开。",
	"R": "看片强制违纪解除：第七月给解除理由三行与短收束，第八月起不开。",
}


func _refresh_jump_routes() -> void:
	if _jump_panel == null or not is_instance_valid(_jump_panel):
		return
	if _jump_route_caption != null and is_instance_valid(_jump_route_caption):
		_jump_route_caption.text = "这一局走哪条路：%s（%s）" % [
			_jump_path, String(JUMP_PATH_NOTES.get(_jump_path, "每月按第一条选"))]
	for entry in JUMP_PATHS:
		var button := _jump_panel.find_child("JumpRoute" + String(entry["letter"]), true, false) as Button
		if button == null:
			continue
		var box := button.get_theme_stylebox("normal") as StyleBoxFlat
		if box == null:
			continue
		var picked := String(entry["letter"]) == _jump_path
		box.border_color = Color("ffd24a") if picked else Color("8a7a5f")
		box.bg_color = Color(0.28, 0.24, 0.17) if picked else Color(0.19, 0.17, 0.14)


func _toggle_jump_panel() -> void:
	if _jump_panel == null or not is_instance_valid(_jump_panel):
		_build_jump_panel()
	if _jump_panel.visible:
		_jump_panel.hide()
		return
	_jump_panel.show()


## 十二格跳月面板：点哪个月，就直接从那个月的第一屏开始（前几个月的账自动补齐）。
func _build_jump_panel() -> void:
	_jump_panel = CanvasLayer.new()
	_jump_panel.name = "MonthJumpPanel"
	_jump_panel.layer = 200
	add_child(_jump_panel)
	var viewport_size := get_viewport().get_visible_rect().size
	var root := Panel.new()
	root.size = Vector2(556, 500)
	root.position = Vector2(
		maxf(20.0, (viewport_size.x - root.size.x) * 0.5),
		maxf(20.0, (viewport_size.y - root.size.y) * 0.5))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.075, 0.97)
	style.border_color = Color("d4ad61")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	root.add_theme_stylebox_override("panel", style)
	_jump_panel.add_child(root)
	var title := Label.new()
	title.text = "跳到第几月"
	title.position = Vector2(22, 16)
	title.size = Vector2(300, 34)
	title.add_theme_font_override("font", CHINESE_FONT)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("f5dfae"))
	root.add_child(title)
	var hint := Label.new()
	hint.text = "点一个月，直接从那个月的第一屏开始；前面几个月的账会自动补齐。Esc 关掉。"
	hint.position = Vector2(22, 52)
	hint.size = Vector2(512, 30)
	hint.add_theme_font_override("font", CHINESE_FONT)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("c9b894"))
	root.add_child(hint)
	# 路线先能在这块面板上点：判定和两个结局都跟着路线走，藏在命令行里等于看不到。
	var route_caption := Label.new()
	route_caption.text = "这一局走哪条路"
	route_caption.position = Vector2(22, 386)
	route_caption.size = Vector2(150, 26)
	route_caption.add_theme_font_override("font", CHINESE_FONT)
	route_caption.add_theme_font_size_override("font_size", 17)
	route_caption.add_theme_color_override("font_color", Color("f5dfae"))
	root.add_child(route_caption)
	for index in JUMP_PATHS.size():
		var entry: Dictionary = JUMP_PATHS[index]
		var route_button := Button.new()
		route_button.text = String(entry["letter"]) + " · " + String(entry["name"])
		route_button.position = Vector2(176 + (index % 2) * 186, 384 + (index / 2) * 42)
		route_button.size = Vector2(178, 36)
		route_button.add_theme_font_override("font", CHINESE_FONT)
		route_button.add_theme_font_size_override("font_size", 16)
		var route_box := StyleBoxFlat.new()
		route_box.bg_color = Color(0.19, 0.17, 0.14)
		route_box.border_color = Color("8a7a5f")
		route_box.set_border_width_all(1)
		route_box.set_corner_radius_all(8)
		route_button.add_theme_stylebox_override("normal", route_box)
		var route_hover := route_box.duplicate()
		route_hover.bg_color = Color(0.28, 0.24, 0.17)
		route_hover.border_color = Color("ffd24a")
		route_button.add_theme_stylebox_override("hover", route_hover)
		route_button.add_theme_color_override("font_color", Color("f3e7c9"))
		var letter := String(entry["letter"])
		route_button.pressed.connect(func() -> void:
			_jump_path = letter
			_refresh_jump_routes())
		route_button.name = "JumpRoute" + letter
		root.add_child(route_button)
	_jump_route_caption = route_caption
	_refresh_jump_routes()
	for index in 12:
		var month_value := index + 1
		var button := Button.new()
		button.text = "第 %d 月\n%s" % [month_value, String(JUMP_MONTH_TAGS[index])]
		button.position = Vector2(22 + (index % 4) * 129, 96 + (index / 4) * 96)
		button.size = Vector2(121, 84)
		button.add_theme_font_override("font", CHINESE_FONT)
		button.add_theme_font_size_override("font_size", 19)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.19, 0.17, 0.14)
		box.border_color = Color("8a7a5f")
		box.set_border_width_all(1)
		box.set_corner_radius_all(8)
		box.content_margin_left = 4.0
		box.content_margin_right = 4.0
		button.add_theme_stylebox_override("normal", box)
		var hover := box.duplicate()
		hover.bg_color = Color(0.28, 0.24, 0.17)
		hover.border_color = Color("ffd24a")
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_color_override("font_color", Color("f3e7c9"))
		button.pressed.connect(func() -> void: debug_jump_to_month(month_value, _jump_path))
		root.add_child(button)
	_jump_panel.hide()


func _start_month_nodes(month_value: int) -> void:
	# 新手月从镇上开始：上一个月的收尾提示和室内预览都不该带进下个月。
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	if _toast_panel != null:
		_toast_panel.queue_free()
		_toast_panel = null
	if _interior_preview != null and _interior_preview.is_open():
		# 室内预览可能是上个月留下的（_exit_zone 在区域已清空时会提前返回），直接收掉。
		_interior_preview.dismiss()
		_active_zone = {}
		_nearby_npc = {}
		_restore_month12_scene_npcs()
	# 上个月那扇剧情门不带进下个月：这一眼没看也就过去了，下个月有下个月的门。
	_retire_story_door()
	_month12_visit_node = {}
	_month12_visit_id = ""
	if _month_runner == null or not is_instance_valid(_month_runner):
		_month_runner = MONTH_NODE_RUNNER.new()
		_month_runner.name = "MonthNodeRunner"
		_month_runner.town = self
		add_child(_month_runner)
	var month_nodes := _load_month_nodes(month_value)
	if month_nodes.is_empty():
		# 这个月还没填表：按"制作中"收着，别把玩家卡住。
		_month12_phase = "done"
		_town_ui_v2.set_task_card("第 %d 月完成" % (month_value - 1), "第 %d 月制作中" % month_value)
		return
	_month12_month = month_value
	_begin_month_ledger(month_value)
	_month12_phase = "month_start"
	var first_story: Dictionary = {}
	var today_lines: Array = []
	for value in month_nodes:
		var node := value as Dictionary
		if String(node.get("nodeType", "main_story")) != "main_story":
			continue
		if first_story.is_empty():
			first_story = node
		# "今天"三行挂在本月第一屏上（4.17）：有就拿来当月初卡的正文，
		# 免得一翻月就有块剧情面板砸下来，连"今天几号、去哪儿"都没交代。
		if today_lines.is_empty():
			var card := node.get("todayCard", {}) as Dictionary
			var lines := card.get("lines", []) as Array
			if not lines.is_empty():
				today_lines = lines.duplicate()
	var destination := String(first_story.get("location", "本月第一站"))
	var first_task := String(first_story.get("title", "看看本月安排"))
	var intro := "日子往前走了一段，你回到熟悉的工作节奏。桌上有一项新安排，等你准备好再开始。"
	var allow_direct := false
	_show_month_start(month_value, destination, first_task, intro, today_lines, allow_direct, func():
		_begin_month_nodes_after_start_card(month_value, month_nodes)
	)


## 月初卡点"继续"之后、本月节点表启动之前：第 2 月在这里插心情讲解卡。
## 罐子在这一拍刚刚亮（_begin_month_ledger），而首月组内小工具已经可能掉过一格——
## 玩家带着"这是什么"的疑问进门，卡就在疑问最新鲜的时候答。E04 的三个选项都不显示
## 心情代价，所以先讲机制不会把技术选型变成"保一格 vs 拿 S+2"的算术题。
func _begin_month_nodes_after_start_card(month_value: int, month_nodes: Array) -> void:
	if month_value == 2:
		if _show_hud_button_tutorial("mood", func(): _actually_start_month_nodes(month_value, month_nodes)):
			return
	_actually_start_month_nodes(month_value, month_nodes)


func _actually_start_month_nodes(month_value: int, month_nodes: Array) -> void:
	_month12_phase = "month_nodes"
	if _month_runner != null and is_instance_valid(_month_runner):
		_month_runner.start(month_value, month_nodes, Callable(_on_month_nodes_finished))


func _load_month_nodes(month_value: int) -> Array:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH_OPENING_PATH))
	if not parsed is Dictionary:
		return []
	var out: Array = []
	for node in ((parsed as Dictionary).get("nodes", []) as Array):
		if int((node as Dictionary).get("month", 0)) == month_value:
			out.append((node as Dictionary).duplicate(true))
	out.sort_custom(func(a, b): return int((a as Dictionary).get("order", 0)) < int((b as Dictionary).get("order", 0)))
	return out


func _on_month_nodes_finished(finished_month: int) -> void:
	_month12_phase = "done"
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	_town_ui_v2.set_task_card("第 %d 月完成" % finished_month, "第 %d 月制作中" % (finished_month + 1))
	_town_ui_v2.set_task_note("下个月再开始")
	_set_objective("第 %d 月完成" % finished_month, "第 %d 月还在制作中" % (finished_month + 1), "", "", false)
	_save_month12_progress()
	_show_reminder_toast("第 %d 月完成" % finished_month, "选择与行动已保存")


func runner_has_flag(flag: String) -> bool:
	return bool(_month12_flags.get(flag, false))


func runner_present_story(node: Dictionary, quiet := false) -> void:
	# 这一屏不是一块面板，是一扇门：走到门口按 E 进去，进了屋才有那一行（4.15.2）。
	var visit_id := String(node.get("enterPlace", ""))
	if not visit_id.is_empty():
		_arm_month12_place_visit(node, visit_id)
		return
	# 走到就收线：不然相位停在 node_walk，黄线还挂着，下一屏永远轮不到。
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	# 上一屏如果被直接收掉（探针/退出）没走到 outcome，钩子不能留给下一屏。
	_pending_story_hooks.clear()
	_pending_unlock_places.clear()
	# 直接开屏也是"已经到场"：把节点播放器的等走位状态清掉，
	# 否则一个没有落点的 walk 节点会把等待状态留到下一屏。
	if _month_runner != null:
		_month_runner.waiting_walk = false
	_month12_skip_walk = false
	_walk_skip_offered = false
	_walk_pause_started_msec = 0
	if _month12_phase == "node_walk":
		_month12_phase = "month_nodes"
	_runner_place_player(node, false)
	# 落点常常正好压在门口，摆过去之后室内预览可能刚弹出来：再收一次。
	if _interior_preview != null and _interior_preview.is_open():
		_interior_preview.dismiss()
		_active_zone = {}
		_nearby_npc = {}
		_restore_month12_scene_npcs()
	# 第 12 月的晋升结果在开口之前就该定下来：结果那一屏要按它分版。
	# 没提名的人也得判一次（算法册：本次未晋升），不然"这张纸放哪儿"那一屏永远不出现。
	var story_id := String(node.get("id", ""))
	if story_id in ["M12_RESULT", "M12_FEEDBACK"] and not _month12_flags.has("m12_promotion_status"):
		_evaluate_promotion()
	var data := _runner_story_data(node)
	_maybe_append_departure(node, data)
	_apply_node_flags(node)
	_fire_hints("node_started:%s" % String(node.get("id", "")))
	_story_event = data
	_town_ui_v2.set_task_card(String(data.get("title", "")), String(data.get("location", "")))
	# 副行跟着这一屏的时段与地点走（首月开局那块就是这个口径）。
	# 不写的话，上个月自由安排留下的"这个月安排完了"会一直挂到本月第一屏上。
	# 节点自带副行就照它写（4.20 那张"本月卡副行"表），没有才回落到"白天/夜 · 地点"。
	var node_note := String(data.get("note", ""))
	if node_note.is_empty():
		node_note = "%s · %s" % [
			"夜" if String(data.get("timeBand", "morning")) == "night" else "白天",
			String(data.get("location", "")),
		]
	_town_ui_v2.set_task_note(node_note)
	# 时间带不一样才播那道光；同带直接开面板。
	var time_band := String(data.get("timeBand", "morning"))
	var band := "夜晚" if time_band == "night" else "白天"
	# 记下这一屏演在哪儿、人落在哪：下一屏要是同地点且人没挪窝，就接着问，不重新开场。
	_last_story_scene = _story_scene_key(node)
	_last_story_point = _player.position
	# 跨旬也要过一下：以前只看昼夜，第 6 月从「上旬·上午」直接跳到「中旬·午后」，
	# 日期牌变了、画面没动，玩家只会觉得"怎么突然就到湖边了"。
	var phase_value := String(data.get("phase", ""))
	var xun_now := _xun_text(phase_value)
	if not _date_band.is_empty() and (int(data.get("month", _month12_month)) != _date_month \
			or band != _date_band or (not xun_now.is_empty() and xun_now != _date_xun)):
		_date_then(int(data.get("month", _month12_month)), String(data.get("phase", "early")), time_band,
			func(): _story_event_panel.present(data, quiet), -1, String(data.get("gapText", "")))
		return
	_story_event_panel.present(data, quiet)


## 一屏剧情"在哪儿演的"：区域码 + 地点名，两个都算上，避免 A 区两间会议室混成一处。
func _story_scene_key(node: Dictionary) -> String:
	return "%s|%s" % [String(node.get("locationId", "")), String(node.get("location", ""))]


## 节点 → 剧情面板要的那份数据：补上月份抬头、日期牌口径和空选项数组。
## 面板和"进门那一屏"共用这一份，两边不能一个改了另一个忘了。
func _runner_story_data(node: Dictionary) -> Dictionary:
	var data := node.duplicate(true)
	var month_value := int(data.get("month", _month12_month))
	data["id"] = "M12_%s" % String(data.get("id", ""))
	data["month"] = month_value
	data["day"] = int(data.get("day", 1))
	data["hour"] = int(data.get("hour", 9))
	data["actTitle"] = "第 %d 月" % month_value
	# 十二个月这条线：日期牌只写月 + 旬 + 时段，不摆具体日子和星期。
	data["dateStyle"] = "xun"
	data["situation"] = String(data.get("situation", "weak"))
	data["durationMinutes"] = int(data.get("durationMinutes", 45))
	if not data.has("choices"):
		data["choices"] = []
	# 接上月的条件旁白：拍上写了 when.flag 的，只有那个旗标成立才留。
	# 这样"按第四月 E05 只显示一版"这类话能长在数据里，面板不用懂旗标。
	data["beats"] = _filter_conditional_beats(data.get("beats", []) as Array)
	# 判定结果要塞进台词：面板不懂旗标，这里按账本把占位展开（4.21）。
	data["beats"] = _expand_beat_placeholders(data["beats"] as Array)
	data["choices"] = _expand_choice_placeholders(data.get("choices", []) as Array)
	# 便签不够三张时，{笔记二}/{笔记三} 会展开成空串——空按钮直接丢掉。
	var kept: Array = []
	for value in (data["choices"] as Array):
		if String((value as Dictionary).get("text", "")).strip_edges().is_empty():
			continue
		kept.append(value)
	data["choices"] = kept
	# 第 6 月那面墙：把玩家真实攒下的便签摊出来。
	# 以前只有一句「你从墙上取下三张」，墙上写了什么、挑的是哪几张全没有，
	# 答辩里老周那句「你带了这张」也就没有指代。
	if String(node.get("id", "")) == "M06_WALL":
		data["beats"] = _inject_wall_notes(data["beats"] as Array)
	# 第 12 月回放：六面墙挂的是这一路真写下来的便签，不是一句旁白带过。
	if String(node.get("id", "")) == "M12_REPLAY":
		data["beats"] = _inject_replay_notes(data["beats"] as Array)
	return data


## 回放那六面墙按月份分段，每一面挂那段里玩家真记下的便签（最多三条）。
const REPLAY_WALLS := [
	{"title": "进入行业", "from": 1, "to": 2},
	{"title": "真实需求与成本压力", "from": 3, "to": 4},
	{"title": "事故与责任", "from": 5, "to": 6},
	{"title": "重构与传承", "from": 7, "to": 8},
	{"title": "边界与署名", "from": 9, "to": 10},
	{"title": "提名与新局", "from": 11, "to": 12},
]
const REPLAY_WALL_ORDINALS := ["第一面", "第二面", "第三面", "第四面", "第五面", "第六面"]


func _inject_replay_notes(beats: Array) -> Array:
	var all := _read_memos_all()
	var extra: Array = []
	for i in REPLAY_WALLS.size():
		var wall: Dictionary = REPLAY_WALLS[i]
		var picked: Array = []
		for value in all:
			var month := int((value as Dictionary).get("month", 0))
			if month >= int(wall.get("from", 0)) and month <= int(wall.get("to", 0)):
				picked.append(value)
		var line := "%s，「%s」：" % [REPLAY_WALL_ORDINALS[i], String(wall.get("title", ""))]
		if picked.is_empty():
			line += "空着——那段时间你没往上贴东西。"
		else:
			var parts: Array = []
			for k in mini(picked.size(), 3):
				var item := picked[k] as Dictionary
				parts.append("%s那张「%s」" % [
					_cn_month(int(item.get("month", 0))),
					String(item.get("text", "")).trim_suffix("。")])
			line += "、".join(PackedStringArray(parts)) + "。"
		extra.append({"type": "narration", "text": line})
	var out: Array = []
	var placed := false
	for value in beats:
		out.append(value)
		var beat := value as Dictionary
		if not placed and String(beat.get("text", "")).begins_with("六面墙，按这半年一次排下来"):
			for line in extra:
				out.append(line)
			placed = true
	if not placed:
		for line in extra:
			out.append(line)
	return out


## 全部便签，按落盘顺序（老的在前）。回放要按月份分段，不能只取最近几条。
func _read_memos_all() -> Array:
	var collected: Array = []
	if not FileAccess.file_exists(MONTH12_MEMO_PATH):
		return collected
	var file := FileAccess.open(MONTH12_MEMO_PATH, FileAccess.READ)
	if file == null:
		return collected
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed = JSON.parse_string(line)
		if not (parsed is Dictionary):
			continue
		var item := parsed as Dictionary
		var text := String(item.get("text", ""))
		if text.is_empty():
			continue
		collected.append({"month": int(item.get("month", 0)), "text": text})
	file.close()
	return collected


## 把这一路真正记下来的便签，插在"墙上贴着这半年记下的事"那句之后。
## 一条都没有就明说墙上空着——不拿旁白凑数，也不假装玩家记过。
func _inject_wall_notes(beats: Array) -> Array:
	var notes := _read_recent_memos(4)
	if not notes.is_empty():
		_month12_flags["m06_has_notes"] = true
	var extra: Array = []
	if notes.is_empty():
		extra.append({"type": "narration", "text": "墙上空着好几块——这半年，你没往上贴过东西。"})
	else:
		for value in notes:
			var item := value as Dictionary
			extra.append({"type": "narration",
				"text": "%s那张：「%s」" % [_cn_month(int(item.get("month", 0))), String(item.get("text", ""))]})
	var out: Array = []
	var placed := false
	for value in beats:
		var beat := value as Dictionary
		# 墙上不够三张就别硬说"取下三张"——按实际有几张说。
		if not notes.is_empty() and notes.size() < 3 				and String(beat.get("text", "")).begins_with("你挑了一张当主讲"):
			out.append({"type": "narration",
				"text": "你把墙上那几张都折进兜里。剩下的空位还留在那儿。"})
			continue
		out.append(value)
		if not placed and String(beat.get("text", "")).begins_with("墙上贴着这半年记下的事"):
			for line in extra:
				out.append(line)
			placed = true
	if not placed:
		for line in extra:
			out.append(line)
	return out


## 读心湖那面墙的数据源，取最近的几条（新的在前）。
func _read_recent_memos(limit: int) -> Array:
	var collected: Array = []
	if not FileAccess.file_exists(MONTH12_MEMO_PATH):
		return collected
	var file := FileAccess.open(MONTH12_MEMO_PATH, FileAccess.READ)
	if file == null:
		return collected
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed = JSON.parse_string(line)
		if not (parsed is Dictionary):
			continue
		var item := parsed as Dictionary
		var text := String(item.get("text", ""))
		if text.is_empty():
			continue
		collected.append({"month": int(item.get("month", 0)), "text": text})
	file.close()
	collected.reverse()
	return collected.slice(0, limit)


## 把一句文案里的 {红线条文} {红线那月} {差的那一维} 换成这一局的真值。
func _expand_story_text(text: String) -> String:
	if not text.contains("{"):
		return text
	var out := text
	var clause := String(_month12_flags.get("m06_redline_clause", ""))
	if out.contains("{红线条文}"):
		out = out.replace("{红线条文}", clause if not clause.is_empty() else "入职那天当众讲过的那一条")
	if out.contains("{红线那月}"):
		out = out.replace("{红线那月}", _cn_month(int(_month12_flags.get("m06_redline_month", 0))))
	if out.contains("{差的那一维}"):
		out = out.replace("{差的那一维}", _weakest_dimension_name())
	# 第 6 月挑主讲那张：{笔记一/二/三} 是墙上最近的几张便签，{主笔记} 是玩家挑中的那张。
	var note_keys := ["{笔记一}", "{笔记二}", "{笔记三}"]
	if out.contains("{笔记一}") or out.contains("{笔记二}") or out.contains("{笔记三}") or out.contains("{主笔记}"):
		var notes := _read_recent_memos(3)
		for i in note_keys.size():
			var note_text := "" if i >= notes.size() else String((notes[i] as Dictionary).get("text", ""))
			out = out.replace(note_keys[i], note_text)
		if out.contains("{主笔记}"):
			out = out.replace("{主笔记}", _picked_main_note(notes))
	return out


## 玩家在墙上挑中的那张主便签：看三个旗标哪个亮，取对应位次的那张。
## 没挑过就返回空串，调用方把那句退回通用说法。
func _picked_main_note(notes: Array) -> String:
	for i in notes.size():
		if bool(_month12_flags.get("m06_main_%d" % (i + 1), false)):
			# 便签本身自带句号，模板后面还会补一个——这里先去掉，免得出现「。。」
			return String((notes[i] as Dictionary).get("text", "")).trim_suffix("。")
	return ""


func _expand_beat_placeholders(beats: Array) -> Array:
	var out: Array = []
	for value in beats:
		if not (value is Dictionary):
			out.append(value)
			continue
		var beat := Dictionary(value).duplicate(true)
		beat["text"] = _expand_story_text(String(beat.get("text", "")))
		out.append(beat)
	return out


func _expand_choice_placeholders(choices: Array) -> Array:
	var out: Array = []
	for value in choices:
		if not (value is Dictionary):
			out.append(value)
			continue
		var choice := Dictionary(value).duplicate(true)
		for key in ["text", "outcome"]:
			if choice.has(key):
				choice[key] = _expand_story_text(String(choice.get(key, "")))
		out.append(choice)
	return out


const CN_MONTHS := ["", "第一月", "第二月", "第三月", "第四月", "第五月", "第六月",
	"第七月", "第八月", "第九月", "第十月", "第十一月", "第十二月"]


func _cn_month(month_value: int) -> String:
	if month_value < 1 or month_value > 12:
		return "前面那个月"
	return CN_MONTHS[month_value]


## 差的那一维：取四维里最低那一档的名字（名字读 rubrics，不在代码里写死）。
func _weakest_dimension_name() -> String:
	_rubric_section("m6")  # 保证 rubrics 已读进来（维度名字在它里面）
	var score = _month12_flags.get("m06_dim_score", {})
	if not (score is Dictionary) or (score as Dictionary).is_empty():
		return "那一维"
	var worst := ""
	var worst_value := 99
	for dim in (score as Dictionary).keys():
		if int((score as Dictionary)[dim]) < worst_value:
			worst_value = int((score as Dictionary)[dim])
			worst = String(dim)
	var named := ""
	var sections = _rubrics.get("dimensions", {})
	if sections is Dictionary and (sections as Dictionary).has(worst):
		named = String(((sections as Dictionary)[worst] as Dictionary).get("name", ""))
	return named if not named.is_empty() else "那一维"


## 逐拍过滤：没有 when 的拍原样留；有 when 的按条件求值，不成立就把这一拍藏掉。
func _filter_conditional_beats(beats: Array) -> Array:
	var kept: Array = []
	for value in beats:
		if not (value is Dictionary):
			kept.append(value)
			continue
		var beat := value as Dictionary
		var when = beat.get("when")
		if when is Dictionary and not _condition_passes(when as Dictionary):
			continue
		kept.append(beat)
	return kept


## 条件求值：flag / notFlag / anyOf / allOf / noneOf / equals。
## 剧情拍和月末卡共用这一条——以前月末卡只认 flag，"两件事同时发生才显示"那类规则落不进去。
func _condition_passes(when: Dictionary) -> bool:
	var flag := String(when.get("flag", ""))
	if not flag.is_empty() and not bool(_month12_flags.get(flag, false)):
		return false
	var not_flag := String(when.get("notFlag", ""))
	if not not_flag.is_empty() and bool(_month12_flags.get(not_flag, false)):
		return false
	# anyOf：一组旗标里命中任意一条才留。
	var any_of: Array = when.get("anyOf", []) as Array
	if not any_of.is_empty() and not _any_flag(any_of):
		return false
	# allOf：一组旗标全成立才留（第 8 月"重构 + 上报"同时选了才改派接口负责人）。
	var all_of: Array = when.get("allOf", []) as Array
	if not all_of.is_empty() and not _all_flags(all_of):
		return false
	# noneOf：一条都没命中才留。
	var none_of: Array = when.get("noneOf", []) as Array
	if not none_of.is_empty() and _any_flag(none_of):
		return false
	# 按旗标的值分支（如首月 e02 = A/B/C）：只有存的就是这一版才留这句。
	if when.has("equals"):
		var eq_flag := String(when.get("eqFlag", "e02"))
		if String(_month12_flags.get(eq_flag, "")) != String(when.get("equals", "")):
			return false
	return true


## 一组旗标是不是全都成立。
func _all_flags(flags: Array) -> bool:
	for value in flags:
		if not bool(_month12_flags.get(String(value), false)):
			return false
	return true


## 一组旗标里有没有任意一条成立。
func _any_flag(flags: Array) -> bool:
	for value in flags:
		if bool(_month12_flags.get(String(value), false)):
			return true
	return false


## 节点读完要落的旗标（"这一拍你看过了"）：选择给的旗标走选项，这种走这里。
func _apply_node_flags(node: Dictionary) -> void:
	for value in (node.get("setsFlags", []) as Array):
		_month12_flags[String(value)] = true


## 把一条选项的能力锚点记进四维证据（同维取最高，不累加）。
func _collect_competency(choice: Dictionary) -> void:
	for entry in (choice.get("competency", []) as Array):
		if not (entry is Dictionary):
			continue
		var dim := String((entry as Dictionary).get("dimension", ""))
		if not _dim_anchors.has(dim):
			continue
		var anchor := int((entry as Dictionary).get("anchor", 0))
		var bucket: Array = _dim_anchors[dim]
		bucket.append(anchor)
		_dim_anchors[dim] = bucket


## 判定门槛的唯一出处是 rubrics.json；读不到或缺字段时一律往轻的那边退，
## 绝不在代码里补一个数（4.21）。
func _rubric_section(key: String) -> Dictionary:
	if _rubrics.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH12_RUBRICS_PATH))
		if parsed is Dictionary:
			_rubrics = parsed as Dictionary
		else:
			push_error("读不到 %s，判定按最轻处理" % MONTH12_RUBRICS_PATH)
	var section = _rubrics.get(key, {})
	return section as Dictionary if section is Dictionary else {}


func _rubric_int(cfg: Dictionary, key: String) -> int:
	if not cfg.has(key):
		push_error("rubrics.json 缺字段 %s，这一条判定作废（按最轻处理）" % key)
		return 0
	return int(cfg[key])


func _rubric_list(cfg: Dictionary, key: String) -> Array:
	var value = cfg.get(key, [])
	return value as Array if value is Array else []


## 四维各取最高一档 + 每维记录条数。判定读它，界面不显示它。
func _dim_evidence() -> Dictionary:
	var score := {}
	var counts := {}
	var total := 0
	for dim in ["S", "O", "N", "D"]:
		var records: Array = _dim_anchors.get(dim, []) as Array
		var best := 0
		for value in records:
			best = maxi(best, int(value))
		score[dim] = best
		counts[dim] = records.size()
		total += best
	return {"score": score, "counts": counts, "total": total}


## 第 6 月末一次定（rubrics.json 的 m6）：先红线，再举证，最后比分数。
## 没有「延期复核」这一档——试用期不能延长，这个年度只出一次结论。
## 判定只写旗标，不改任何数值；第七月那几屏按旗标分版。
func _evaluate_probation() -> String:
	var m6 := _rubric_section("m6")
	var clauses: Dictionary = m6.get("redlineClauses", {}) as Dictionary
	for flag in clauses.keys():
		if bool(_month12_flags.get(String(flag), false)):
			return _finish_probation("terminated", String(flag), {}, 0)
	var evidence := _dim_evidence()
	var score: Dictionary = evidence["score"]
	var counts: Dictionary = evidence["counts"]
	var total := int(evidence["total"])
	var floor_cfg: Dictionary = m6.get("evidenceFloor", {}) as Dictionary
	var observed := 0
	for dim in ["S", "O", "N", "D"]:
		if int(counts[dim]) >= _rubric_int(floor_cfg, "minRecordsPerDimension"):
			observed += 1
	if observed < _rubric_int(floor_cfg, "minObservedDimensions"):
		# 举不出证就不能说不符合录用条件：按转正处理，缺口留给报告。
		return _finish_probation("confirmed", "", score, total)
	var bad: Dictionary = m6.get("notConfirmed", {}) as Dictionary
	var good: Dictionary = m6.get("confirmed", {}) as Dictionary
	var weak := 0
	for dim in ["S", "O", "N", "D"]:
		if int(score[dim]) < _rubric_int(bad, "anyBelow"):
			return _finish_probation("not_confirmed", "", score, total)
		if int(score[dim]) < _rubric_int(good, "minEach"):
			weak += 1
	if weak >= _rubric_int(bad, "dimensionsBelow") or total < _rubric_int(bad, "totalBelow"):
		return _finish_probation("not_confirmed", "", score, total)
	return _finish_probation("confirmed", "", score, total)


## 把转正结论落成一组布尔旗标（when.flag 只认真值），顺带记下弱维和解除理由。
func _finish_probation(status: String, redline: String, score: Dictionary, total: int) -> String:
	_month12_flags["m06_probation_status"] = status
	_month12_flags["probation_confirmed"] = status == "confirmed"
	_month12_flags["probation_not_confirmed"] = status == "not_confirmed"
	_month12_flags["probation_terminated"] = status == "terminated"
	_month12_flags["probation_ended"] = status != "confirmed"
	if not score.is_empty():
		_month12_flags["m06_dim_score"] = score
		_month12_flags["m06_dim_total"] = total
		for dim in score.keys():
			var good_each := int((_rubric_section("m6").get("confirmed", {}) as Dictionary).get("minEach", 0))
			_month12_flags["probation_weak_" + String(dim)] = good_each > 0 and int(score[dim]) < good_each
	if not redline.is_empty():
		var clauses: Dictionary = _rubric_section("m6").get("redlineClauses", {}) as Dictionary
		_month12_flags["m06_redline_flag"] = redline
		_month12_flags["m06_redline_clause"] = String(clauses.get(redline, ""))
		# 「m05_e17_blame_network」→ 第 5 月：解除理由那一行要说清是哪个月的事。
		_month12_flags["m06_redline_month"] = int(redline.substr(1, 2)) if redline.length() > 3 else 0
	_month12_flags["employment_arc"] = "ended" if status != "confirmed" else "active"
	print("[判定] %s｜四维 %s 总分 %d" % [status, JSON.stringify(score), total])
	return status


## 第 12 月的晋升：按算法册的规则表判（rubrics.json 的 m12），不用隐藏总分。
## 没提名的人也要跑一次，不然「这次没晋升」那一屏永远出不来。
func _evaluate_promotion() -> String:
	var m12 := _rubric_section("m12")
	if bool(_month12_flags.get("m12_not_nominated", false)):
		return _finish_promotion("not_promoted", "未提名")
	for flag in _rubric_list(m12, "vetoFlags"):
		if bool(_month12_flags.get(String(flag), false)):
			return _finish_promotion("not_passed", String(flag))
	var need: Dictionary = m12.get("needAny", {}) as Dictionary
	for key in need.keys():
		var met := false
		for flag in _rubric_list(need, String(key)):
			if bool(_month12_flags.get(String(flag), false)):
				met = true
		if not met:
			return _finish_promotion("not_passed", String(key))
	var floor_cfg: Dictionary = m12.get("evidenceFloor", {}) as Dictionary
	var strong_anchor := _rubric_int(floor_cfg, "strongAnchor")
	var min_records := _rubric_int(floor_cfg, "minRecordsPerDimension")
	var strong_dims := 0
	for dim in ["S", "O", "N", "D"]:
		var strong := 0
		for value in (_dim_anchors.get(dim, []) as Array):
			if int(value) >= strong_anchor:
				strong += 1
		if strong >= min_records:
			strong_dims += 1
	if strong_dims < _rubric_int(floor_cfg, "minStrongDimensions"):
		return _finish_promotion("not_passed", "证据")
	return _finish_promotion("promoted", "")


## 晋升结论落旗标：只有 promoted 才算晋升，其余都算「这次没有」。
func _finish_promotion(status: String, reason: String) -> String:
	_month12_flags["m12_promotion_status"] = status
	_month12_flags["m12_promotion_reason"] = reason
	_month12_flags["m12_not_passed"] = status != "promoted"
	print("[晋升] %s%s" % [status, ("（缺：" + reason + "）" if not reason.is_empty() else "")])
	return status


## 收尾那句"按谁谁的安排，去哪儿吧"：下一屏在别处、这一屏又没有选项时才补。
## 谁 = 这一屏最后说话的人；地点 = 下一屏的落点。纯剧情屏才有，带选择的等选项落地后再说。
func _maybe_append_departure(node: Dictionary, data: Dictionary) -> void:
	var choices: Array = data.get("choices", []) as Array
	# 探针用：把"为什么这一屏没补收尾句"打到标准输出，玩家跑的时候不打。
	var dbg := _debug_departure
	var nxt: Dictionary = {}
	if _month_runner == null or not is_instance_valid(_month_runner):
		if dbg:
			print("[跳过] %s | 没有播放器" % String(node.get("id", "")))
		return
	nxt = _month_runner.call("peek_next")
	if nxt.is_empty():
		if dbg:
			print("[跳过] %s | 这个月后面没有节点了" % String(node.get("id", "")))
		return
	# 作者写死的离屏一句优先：册子定稿的台词从 departNote 进，同一区、同一张桌子也照样补。
	var authored := String(node.get("departNote", ""))
	if not authored.is_empty():
		if dbg:
			print("[补] %s -> %s | 作者写的离屏句" % [String(node.get("id", "")), String(nxt.get("id", ""))])
		_write_departure_tail(data, authored, choices)
		return
	var next_loc := String(nxt.get("location", ""))
	var same_zone := String(nxt.get("locationId", "")) == String(data.get("locationId", ""))
	if next_loc.is_empty() or String(data.get("location", "")).is_empty():
		if dbg:
			print("[跳过] %s -> %s | %s" % [String(node.get("id", "")), String(nxt.get("id", "")),
				"下一屏没写地点" if next_loc.is_empty() else "这一屏没写地点"])
		return
	# 同一区里换屏是最容易"断"的地方：第 2 月连着四屏都在同一张桌子上演，
	# 按册子"同区可以省"就不补了，结果玩家看到的是文字突然换成另一件事。
	# 补法：换时段就说清"什么时候接着来"，同地点同时段仍然不补（那是一问一答的连续体）。
	if same_zone:
		var next_band := String(nxt.get("timeBand", ""))
		var this_band := String(data.get("timeBand", ""))
		if next_band.is_empty() or next_band == this_band:
			if dbg:
				print("[跳过] %s -> %s | 同区且时段没变，按册子可以省" % [
					String(node.get("id", "")), String(nxt.get("id", ""))])
			return
		var when_word := "天黑了"
		if next_band == "afternoon":
			when_word = "过了中午"
		elif next_band != "night":
			when_word = "天亮了"
		var guide_now := _departure_guide(node, data)
		var join_now := " "
		if next_loc.length() > 0 and next_loc.unicode_at(0) > 127:
			join_now = ""
		var same_spot := String(nxt.get("location", "")) == String(data.get("location", ""))
		var bridge := ""
		if same_spot:
			bridge = "%s，还在这%s%s。按%s的安排，接着办。" % [when_word, join_now, next_loc, guide_now]
		else:
			bridge = "%s。按%s的安排，去%s%s。" % [when_word, guide_now, join_now, next_loc]
		if dbg:
			print("[补] %s -> %s | 同区换时段 | %s" % [
				String(node.get("id", "")), String(nxt.get("id", "")), bridge])
		_write_departure_tail(data, bridge, choices)
		return
	# 回忆/蒙太奇那种屏不算"去某个地方"，不补这句。
	if bool(nxt.get("montage", false)) or bool(node.get("noDeparture", false)):
		if dbg:
			print("[跳过] %s -> %s | %s" % [String(node.get("id", "")), String(nxt.get("id", "")),
				"下一屏是回忆/蒙太奇" if bool(nxt.get("montage", false)) else "这一屏标了 noDeparture"])
		return
	var guide := String(node.get("guideBy", ""))
	# 没有落点的屏（手机、手册）只有在明确写了"谁安排的"时才补。
	if guide.is_empty() and String(data.get("location", "")).is_empty():
		return
	if guide.is_empty():
		for value in (data.get("beats", []) as Array):
			if String((value as Dictionary).get("type", "")) == "say":
				guide = String((value as Dictionary).get("speaker", ""))
	if guide.is_empty():
		guide = "组里"
	var beats: Array = data.get("beats", [])
	# 地点以拉丁字母开头（"A 区…"）时中间留一个空格，中文直接连写。
	var join := " "
	if next_loc.length() > 0 and next_loc.unicode_at(0) > 127:
		join = ""
	# 回工位/回楼下这类返程不写"按谁安排"，就是往回走。
	var home := String(nxt.get("locationId", "")) == "B" and (next_loc.contains("工位") or next_loc.contains("楼层"))
	var tail_text := ""
	if home:
		tail_text = "回%s%s吧。" % [join, next_loc]
	else:
		# 名字是拉丁字母（HRBP）时两侧留空格，中文名字直接连写。
		var guide_txt := guide
		if guide.length() > 0 and guide.unicode_at(0) < 128:
			guide_txt = " " + guide + " "
		tail_text = "按%s的安排，去%s%s吧。" % [guide_txt, join, next_loc]
	if dbg:
		print("[补] %s -> %s | 安排人=%s | %s" % [String(node.get("id", "")), String(nxt.get("id", "")), guide, tail_text])
	_write_departure_tail(data, tail_text, choices)


## 谁安排的：节点写了 guideBy 就照它，没有就取这一屏最后一个开口的人，都没有才是"组里"。
func _departure_guide(node: Dictionary, data: Dictionary) -> String:
	var guide := String(node.get("guideBy", ""))
	if not guide.is_empty():
		return guide
	for value in (data.get("beats", []) as Array):
		if String((value as Dictionary).get("type", "")) == "say":
			guide = String((value as Dictionary).get("speaker", ""))
	return guide if not guide.is_empty() else "组里"


## 收尾句写回这一屏：纯剧情屏补在最后一拍后面；带选项的屏接在每个结果句后面，
## 选完就知道下一步去哪儿。
func _write_departure_tail(data: Dictionary, tail_text: String, choices: Array) -> void:
	if not choices.is_empty():
		for value in choices:
			var ch := value as Dictionary
			var outcome := String(ch.get("outcome", ""))
			if outcome.is_empty() or tail_text in outcome:
				continue
			ch["outcome"] = outcome + tail_text
		data["choices"] = choices
		return
	var beats: Array = data.get("beats", [])
	beats.append({"type": "narration", "text": tail_text})
	data["beats"] = beats


func runner_walk_to(node: Dictionary) -> void:
	var point: Vector2 = _month_node_point(node)
	if point.x < -90000.0:
		push_error("剧情节点 %s 没有落点；不允许直接开场" % String(node.get("id", "")))
		return
	# 同一地点、人还没挪窝：这一屏是接着上一屏往下问的（第 12 月那九问就顺在这），
	# 不重新铺黄线、不重播入场卡。走出去过就不算，得重新到场。
	if not _last_story_scene.is_empty() and _story_scene_key(node) == _last_story_scene \
			and _player.position.distance_to(_last_story_point) <= SAME_SCENE_KEEP:
		runner_present_story(node, true)
		return
	# 上一屏是在屋里演的（第 2 月图书馆那一眼）：屋还开着人就动不了，
	# _physics_process 会在室内预览那里提前返回，走位永远到不了终点。
	if _interior_preview != null and _interior_preview.is_open():
		_interior_preview.dismiss()
		_active_zone = {}
		_nearby_npc = {}
		_restore_month12_scene_npcs()
	# 出发前先把旬/昼夜翻过去。日期牌原先只在到达后（runner_present_story）才翻，
	# 玩家一路走的是上一旬，到地方旬卡"啪"一下跳过去，看起来像走到一半时间变了（2026-10-30）。
	_walk_date_first(node, func(): _begin_month_walk(node, point))


## 非走位节点（手册、手机、活动、月末卡）也要在打开界面前对齐日期牌。
## main_story 不走这里，避免没有合法落点时先翻日期；它由 runner_walk_to 负责。
func runner_prepare_node_date(node: Dictionary, then: Callable) -> void:
	var time_band := String(node.get("timeBand", "morning"))
	var band := "夜晚" if time_band == "night" else "白天"
	var month_now := int(node.get("month", _month12_month))
	var xun_now := _xun_text(String(node.get("phase", "")))
	if _date_band.is_empty() or month_now != _date_month \
			or band != _date_band or (not xun_now.is_empty() and xun_now != _date_xun):
		_date_then(month_now, String(node.get("phase", "early")), time_band, then, -1, String(node.get("gapText", "")))
		return
	then.call()


## 跨旬优先：这一屏的旬或昼夜与当前牌面不一致，就先播日期过场，播完再铺黄线。
## 只在这一屏真的换了旬/昼时才动，同旬同昼直接走，不多插一拍。
## 走位途中换昼夜，灯要跟着走完这段路：3.2 秒慢慢暗，不是一迈步就整屏变蓝。
func _walk_date_first(node: Dictionary, then: Callable) -> void:
	var time_band := String(node.get("timeBand", "morning"))
	var band := "夜晚" if time_band == "night" else "白天"
	var month_now := int(node.get("month", _month12_month))
	var xun_now := _xun_text(String(node.get("phase", "")))
	if _date_band.is_empty() or (month_now == _date_month and band == _date_band \
			and (xun_now.is_empty() or xun_now == _date_xun)):
		then.call()
		return
	# 只有真的换了昼夜才预留下一次换灯时长；同旬只换时段时不要留下这个值，
	# 否则会漏给下一次不相干的昼夜切换。
	_band_fade_seconds = BAND_FADE_WALK if band != _date_band else 0.0
	_date_then(month_now, String(node.get("phase", "early")), time_band, then, -1, String(node.get("gapText", "")))


func _xun_text(phase_value: String) -> String:
	if phase_value == "early":
		return "上旬"
	if phase_value == "mid":
		return "中旬"
	if phase_value == "late":
		return "下旬"
	return ""


## 真正开始走：记落点、换任务卡、铺黄线。抽出来是为了让日期过场先播完再铺线。
func _begin_month_walk(node: Dictionary, point: Vector2) -> void:
	_month12_waypoint = _snap_month12_point(point)
	_walk_started_msec = Time.get_ticks_msec()
	_walk_skip_offered = false
	_walk_pause_started_msec = 0
	_month12_phase = "node_walk"
	_town_ui_v2.set_task_card(String(node.get("title", "")), String(node.get("location", "")))
	# 走过去的路上要知道"去干嘛"：节点写了 walkNote 就照它写，没写才回落到"跟着黄线走"。
	var walk_note := String(node.get("walkNote", ""))
	if walk_note.is_empty():
		# 没写心里话也得说出去哪儿：兜底至少带上目的地，不留"跟着黄线走"这种没信息的话。
		var where := String(node.get("location", "")).replace(" 创意水巷", "")
		walk_note = ("跟着黄线去 %s" % where) if not where.is_empty() else "跟着黄线走"
	_town_ui_v2.set_task_note(walk_note)
	if _guide_line != null and _player != null:
		_guide_line.set_path(_build_guide_path(_player.position, _month12_waypoint))


## 这一屏的落点：先在表里查（少数地点要专门指定），查不到就用它所在区的入口。
## 每个月第一屏都写成"走过去"，靠的就是这条兜底，不用往表里一条条加。
func _month_node_point(node: Dictionary) -> Vector2:
	var explicit: Vector2 = MONTH_NODE_POINTS.get(String(node.get("id", "")), Vector2(-99999, -99999))
	if explicit.x > -90000.0:
		return explicit
	var by_location: Vector2 = LOCATION_POINTS.get(String(node.get("location", "")), Vector2(-99999, -99999))
	if by_location.x > -90000.0:
		return by_location
	var zone := _zone_by_code(String(node.get("locationId", "")))
	if zone.is_empty():
		return Vector2(-99999, -99999)
	return zone.get("entrance", Vector2(-99999, -99999))


## 目的地跟前的一段：八个方向各试一下，挑第一个"站得住、也走得到"的点。
func _approach_point(target: Vector2, distance := 240.0) -> Vector2:
	for i in 8:
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 8.0)
		var candidate := _snap_month12_point(target + dir * distance)
		if candidate.distance_to(target) < 80.0:
			continue
		if not _walk_grid.route(candidate, target).is_empty():
			return candidate
	return _snap_month12_point(target)


## 切场：开场这类不用玩家走的节点，把人直接摆到落点。
func _runner_place_player(node: Dictionary, force: bool) -> void:
	# 先查手工落点；没登记的，回它所在区的门口——不能停在上一场的地方。
	var point: Vector2 = _month_node_point(node)
	if point.x < -90000.0 or _player == null:
		return
	if bool(node.get("walk", false)) and not force:
		return
	_player.position = _snap_month12_point(point)


func runner_unlock_handbook(node: Dictionary) -> void:
	var pages: Array = node.get("pages", [])
	for page in pages:
		_month12_flags["handbook_page_%s" % String((page as Dictionary).get("pageId", ""))] = true
	# 记下这一批的第一页：翻开时直接落到它上面（首月是 1.1，剧情刚讲过"那三问"）。
	if not pages.is_empty():
		_handbook_pending_page = String(Dictionary(pages[0]).get("pageId", ""))
	if _town_ui_v2 != null:
		_town_ui_v2.set_manual_visible(true)
		# 红点=手册有新页。silent 那条（4.20 手册第二章会前给）只亮红点、不弹提示条，
		# 不 silent 的红点加提示条两条都给。两边都靠 _open_month12_handbook 翻开时灭掉——
		# 以前只在 silent 分支点亮、而且全项目没有一处熄灭，红点从第三月起就焊死在按钮上。
		_town_ui_v2.set_manual_red_dot(true)
		if bool(node.get("silent", false)):
			return
	var sub := "第一章后几页散开了，右下角能翻"
	if _mood_meter_just_lit:
		# 不另开一次停顿：顶上那罐亮起来这件事，搭在这条本来就要弹的提示上。
		sub = "多了几页；顶上那罐是心情，它记着你还能撑多久"
		_mood_meter_just_lit = false
	_show_reminder_toast("手册有新页", sub)


func runner_deliver_phone(node: Dictionary) -> bool:
	# 返回 true = 这批消息是前置，播放器停在这儿等玩家看完；false = 照旧直接下一屏。
	var messages: Array = []
	for item in (node.get("messages", []) as Array):
		# 一条消息可以只在某个旗标成立时才发（月末那句按当月选择变文案），
		# 但整批仍然只算一批：手机每月上限 2 批，不因为多写了两版就变成三批。
		var when = (item as Dictionary).get("when")
		if when is Dictionary:
			var flag := String((when as Dictionary).get("flag", ""))
			if not flag.is_empty() and not bool(call("runner_has_flag", flag)):
				continue
			# 反向条件：旗标成立就不发（第 10 月老周那句只在"第 9 月帮过小赵"时才发）。
			var not_flag := String((when as Dictionary).get("notFlag", ""))
			if not not_flag.is_empty() and bool(call("runner_has_flag", not_flag)):
				continue
		# 消息也能点亮能力第 5 格：第 10 月老周那句"小赵敢开口了"就是原则被人拿去用了。
		for peak in (item as Dictionary).get("abilityPeak", []) as Array:
			_light_ability_peak(String(peak))
		var msg_text := String((item as Dictionary).get("text", ""))
		messages.append({"speaker": "npc", "text": msg_text})
	if messages.is_empty():
		return false
	_month_phone_messages = messages
	_month_phone_unread = true
	_month_phone_replied = false
	# 联系人跟着这批消息走：谁发的就显示谁，勾头像也换。
	# 名字和身份先查通讯录（小赵这种平时不在表里的人靠它补上），节点里写了就以节点为准。
	var sender_id := String(node.get("senderId", ""))
	var sender := _phone_contact_info(sender_id)
	var sender_name := String(sender.get("name", node.get("senderName", "王哥")))
	var sender_role := String(sender.get("role", node.get("senderRole", "技术导师")))
	_month_phone_contact = {"id": sender_id, "name": sender_name, "role": sender_role}
	# 聊天里的时间话：带月份，跨月也看得出先后。
	var date_text := _phone_date_text(node)
	_month_phone_date_text = date_text
	# 流水按解析后的名字记：有的节点只写了 senderId，没有 senderName
	# （第 5 月那条提醒就是），按节点字段记会往历史里塞空名字。
	# 每条都带上这批的时间话：剧情里再弹手机时，历史气泡才能按批次分开，不再一屏全是"刚刚"。
	for msg in messages:
		_phone_log.append({
			"speaker": sender_name,
			"text": String((msg as Dictionary).get("text", "")),
			"time": date_text,
		})
	_month_phone_reply_options = (node.get("replyOptions", []) as Array).duplicate(true)
	# 往通讯录里对应那位的会话追加：谁发的就落在谁那一行，红点也只亮他那一行。
	# 聊天里报"第 3 月 · 周三上午"（带月份，跨月也看得出先后），列表那格只报"第 3 月"。
	var batch_key := String(node.get("batchId", String(node.get("id", ""))))
	_phone_thread_push(
		sender_id,
		sender_name,
		sender_role,
		messages,
		_month_phone_reply_options,
		date_text,
		_phone_date_short(node),
		batch_key,
		_phone_time_key(node)
	)
	if _town_ui_v2 != null:
		_town_ui_v2.set_phone_visible(true)
		_sync_phone_alert()
	# 普通批次：一条会自己溜走的提示就够。前置那批（requireRead）不在这儿弹，
	# 由下面那条钉住的横幅来说，免得两条叠在顶上说同一件事。
	if not bool(node.get("requireRead", false)):
		_show_reminder_toast("手机有消息", "右下角手机带红点，点开查看；不回也没关系")
	# 一条消息点亮多处入口（第 7 月小赵那句"周末打球不"一次开草坪 + 训练谷）。
	# 这种钩子只立门、不弹讲解卡——卡是"有人当面指到那地方"才弹，消息带的是"顺带开两处"。
	for hook in (node.get("placeHooks", []) as Array):
		_light_places_by_hook(String(hook))
	# 这批消息是下一屏的前提（第 3 月：不看王哥那两条就不知道为什么要去见客户）：
	# 玩家没点开收件箱之前，节点播放器停在这儿。
	if bool(node.get("requireRead", false)):
		_phone_gate_waiting = true
		_phone_gate_read = false
		if _town_ui_v2 != null:
			_town_ui_v2.set_task_card("先看手机", "右下角那颗，红点亮着")
			_town_ui_v2.set_task_note("点开看完这两条，再往下走")
		# 这条不自动消失：门槛挡住的是整个月的推进，玩家没注意就走了 = 卡住。
		# 点横幅任意处直接打开手机；不想看就点右边的叉。
		_show_gate_banner("先看手机", "王哥这两条是下一屏的前提，点开看完再往下走",
			Callable(self, "_open_ui_phone"))
		return true
	return false


## 按钩子把所有对得上的去处门立起来、撕条；一次可亮多扇。
func _light_places_by_hook(hook: String) -> void:
	var lit := 0
	for value in _month12_places:
		if not (value is Dictionary):
			continue
		var act := value as Dictionary
		if String(act.get("unlockHook", "")) != hook:
			continue
		var id := String(act.get("id", ""))
		if _month12_place_portals.has(id):
			continue
		_ensure_month12_place(id)
		lit += 1
	if lit > 0:
		_month12_places_open = true
		_refresh_month12_place_seals()
		_show_reminder_toast("地图上多了 %d 个圈" % lit, "有空自己去走走，不花这个月的格子")


func runner_open_close(node: Dictionary) -> void:
	var lines: Array = []
	for card in (node.get("cards", []) as Array):
		var when = (card as Dictionary).get("when", {})
		# 月末卡和剧情拍共用一套条件；这里原先只认 flag，"没去过就不显示这行"落不了地。
		if when is Dictionary and not _condition_passes(when as Dictionary):
			continue
		lines.append(String((card as Dictionary).get("text", "")))
	var text := "
".join(lines) if not lines.is_empty() else String(node.get("defaultText", ""))
	_month_close_text_override = text
	_month_close_phase = String(node.get("phase", "mid"))
	_start_month12_close()


func _runner_record_choice(choice_id: String) -> void:
	if _month_runner == null:
		return
	var node: Dictionary = _month_runner.current
	for choice in (node.get("choices", []) as Array):
		if String((choice as Dictionary).get("id", "")) != choice_id:
			continue
		for flag in ((choice as Dictionary).get("flags", []) as Array):
			_month12_flags[String(flag)] = true
		_collect_competency(choice as Dictionary)
		# 这一选点亮某能力的第 5 格（熊熊有招）：E19 把话说清后产品来问对接，就是这种时刻。
		for ability in ((choice as Dictionary).get("abilityPeak", []) as Array):
			_light_ability_peak(String(ability))
		# 这一选攒到的能力点：档案页那五排格子跟着长（没连后端也算得出来）。
		var ability_before := ability_display_levels()
		_record_ability_tags((choice as Dictionary).get("abilityTags"))
		# 主线那一笔也记进同一本账：这个月心情为什么掉了，月末卡要说得出来。
		var mood_before := _mood
		var delta := int(((choice as Dictionary).get("stateDelta", {}) as Dictionary).get("H", 0))
		if delta != 0:
			_mood = clampi(_mood + delta, 0, _mood_max)
			_refresh_mood_hud()
			_record_ledger(String(node.get("title", "这一件事")), 0, _mood - mood_before)
		# 长了什么、熬掉了什么，合成一句人话；两件事分两条提示会互相顶掉。
		_announce_choice_aftermath(ability_before, (choice as Dictionary).get("abilityTags"), _mood - mood_before)
		ApiClient.record_event("m02_choice", {
			"node": String(node.get("id", "")),
			"choiceId": choice_id,
			"delta": (choice as Dictionary).get("stateDelta", {}),
			"moodBefore": mood_before,
			"moodAfter": _mood,
		})
		return


## 点亮某能力的第 5 格（熊熊有招）：只由剧情这一幕点亮，不靠攒点。
## 落 peak_<能力> 旗标（后端/档案据此把那一格画满），并当场给一句可见反馈。
const ABILITY_PEAK_NAMES := {
	"technical": "技术", "collaboration": "协作", "expression": "表达",
	"integrity": "原则", "resilience": "抗压",
}


func _light_ability_peak(ability: String) -> void:
	if ability.is_empty() or not ABILITY_PEAK_NAMES.has(ability):
		return
	if bool(_month12_flags.get("peak_" + ability, false)):
		return
	_month12_flags["peak_" + ability] = true
	ApiClient.record_event("ability_peak", {"ability": ability, "month": _month12_month})
	_show_reminder_toast("熊熊有招", "你的「%s」被人真的拿去用了。" % ABILITY_PEAK_NAMES[ability])


## 攒点那一本：一次给 1–2 点，攒到 2/5/9 才往上长一格，最多加到第 4 格。
## 档位与后端 _ability_tier 同一套数（开发文档 4.19），改这里要一起改那边。
const ABILITY_KEYS := ["technical", "collaboration", "expression", "integrity", "resilience"]
const ABILITY_START := {
	"technical": 1, "collaboration": 1, "expression": 1, "integrity": 2, "resilience": 1,
}


func _record_ability_tags(raw) -> void:
	if not (raw is Dictionary):
		return
	for key in (raw as Dictionary).keys():
		var name := String(key)
		if not ABILITY_PEAK_NAMES.has(name):
			continue
		_ability_points[name] = int(_ability_points.get(name, 0)) + int((raw as Dictionary)[key])


## 攒了能力点 / 熬掉心情之后说一句人话。只形容程度，不报数；
## 不许冒出"档""阈值""读数"这类系统词，也不提"档案里的格子"——
## 玩家刚做完一个选择，屏幕上只该告诉他这件事让他长了什么、付出了什么。
## 跨没跨格按 `ability_display_levels()` 的真实读数比，不是按点数猜。
## 点亮到第 5 格另有那句"被人真的拿去用了"（_light_ability_peak），不并到这里。
func _announce_choice_aftermath(before: Array[int], raw, mood_delta: int) -> void:
	var up: Array = []
	var soft: Array = []
	if raw is Dictionary:
		var after := ability_display_levels()
		for index in ABILITY_KEYS.size():
			var name := String(ABILITY_KEYS[index])
			if int((raw as Dictionary).get(name, 0)) <= 0:
				continue
			var label := "「%s」" % String(ABILITY_PEAK_NAMES[name])
			if int(after[index]) > int(before[index]):
				up.append(label)
			else:
				soft.append(label)
	var lines: Array = []
	if not up.is_empty():
		lines.append("%s长进了一块" % "".join(up))
	if not soft.is_empty():
		lines.append("%s长了一点" % "".join(soft))
	var cost := false
	if int(mood_delta) < 0:
		cost = true
		lines.append("人也熬得够呛")
	if lines.is_empty():
		return
	_show_reminder_toast("这一选有代价" if cost else "这一选没白费", "；".join(lines) + "。")


## 档案页那五排格子的读数：起点 + 攒点长出来的格（封顶 4），
## 被剧情点亮的那一行直接画满到 5。连上后端时取两边更大的那个——
## 这一年的点数只有加没有减，所以取大不会把已经长出来的格子写回去。
## 档案页「留下的材料」：只列这一年真的做出过、而且有旗标记着的。
## 现在只有两样有旗标：第 1 月的组内小工具、第 12 月的交接文档。
## 评测表和署名纪要还没有旗标——等那几屏补上再往这里加，别先编一个名字挂上去。
func month12_material_lines() -> Array:
	var lines: Array = []
	if bool(_month12_flags.get("m01_activity_tool", false)):
		lines.append("组内小工具")
	if bool(_month12_flags.get("m12_handoff_documents", false)) \
			or bool(_month12_flags.get("m12_handoff_full", false)) \
			or bool(_month12_flags.get("m12_handoff_partial", false)):
		lines.append("交接文档")
	return lines


func ability_display_levels() -> Array[int]:
	var server: Dictionary = (ApiClient.server_state() as Dictionary).get("abilityLevels", {})
	var out: Array[int] = []
	for name in ABILITY_KEYS:
		var points := int(_ability_points.get(name, 0))
		var tier := 0
		if points >= 9:
			tier = 3
		elif points >= 5:
			tier = 2
		elif points >= 2:
			tier = 1
		var level := clampi(int(ABILITY_START[name]) + tier, 1, 4)
		if bool(_month12_flags.get("peak_" + name, false)):
			level = 5
		out.append(maxi(level, clampi(int(server.get(name, 0)), 0, 5)))
	return out


func _on_story_choice_confirmed(event_id: String, choice_id: String, duration_minutes: int) -> void:
	if _month_runner != null and _month_runner.active:
		_runner_record_choice(String(choice_id))
		return
	if _month12_active:
		_month12_e02_choice = String(choice_id)
		_month12_flags["e02"] = String(choice_id)
		# 首月那一屏是手写的流程，不在节点播放器里，能力账得在这儿自己补上，
		# 不然 E02 的三个选择在档案页一格都不长（2026-10-28 查出来的漏）。
		for choice in ((_month_opening_events.get("E02", {}) as Dictionary).get("choices", []) as Array):
			if String((choice as Dictionary).get("id", "")) == String(choice_id):
				var e02_ability_before := ability_display_levels()
				_record_ability_tags((choice as Dictionary).get("abilityTags"))
				_announce_choice_aftermath(e02_ability_before, (choice as Dictionary).get("abilityTags"), 0)
				_collect_competency(choice as Dictionary)
				for ability in ((choice as Dictionary).get("abilityPeak", []) as Array):
					_light_ability_peak(String(ability))
		ApiClient.record_event("m01_e02_choice", {"choiceId": String(choice_id)})
		return
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
	if _month_runner != null and _month_runner.active:
		# 这一屏里有解锁钩子：先把讲解卡排在前面，卡关掉再让节点播放器往下走。
		# 这一屏读完了：提示条里挂"某屏看完"的那些此刻该弹。
		var done_node: Dictionary = _month_runner.current
		_fire_hints("node_completed:%s" % String(done_node.get("id", "")))
		# unlockAfter 指向这一屏的去处：和挂 hook 的那几处一样，读完这一屏才立门弹卡。
		_queue_unlock_after_cards(String(done_node.get("id", "")))
		if not _pending_story_hooks.is_empty() or not _pending_unlock_places.is_empty():
			_open_hook_cards(Callable(_month_runner, "on_panel_closed"))
			return
		# 节点上写着 sleepHome：这一屏读完不是往下翻，是先回宿舍睡一觉（第 2 月那一周）。
		# 跨旬那一觉还会带 gapText（"两周后"），黑场里把这段时间说出来。
		if bool(done_node.get("sleepHome", false)):
			_start_sleep_walk(_month12_month, Callable(_month_runner, "on_panel_closed"),
				String(done_node.get("wakePhase", "early")), String(done_node.get("gapText", "")))
			return
		# 通宵那一屏（第 5 月）：人没走，黑一下到天亮，不走位、不进宿舍。
		if bool(done_node.get("allNighter", false)):
			_do_all_nighter(_month12_month, Callable(_month_runner, "on_panel_closed"))
			return
		_month_runner.on_panel_closed()
		return
	if _month12_active:
		_advance_month12_story()
		return
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

# ---------------------------------------------------------------- 剧情带路立门（4.15.2）

## 某一句台词挂了钩子 → 在这个地方立一扇门。首月之外唯一的立门入口。
## 两种钩子：
##   ① 去处钩子（activities.json 里写了同一个 unlockHook）：门当拍亮，读完这一屏弹讲解卡；
##   ② 看一眼的钩子（door_library）：只在门口立一扇门 + 一行提示，不弹卡、不结算。
func _on_story_beat_reached(_event_id: String, _beat_index: int, beat: Dictionary) -> void:
	# 这一拍点亮某能力的第 5 格（熊熊有招）：有人真的拿你的东西去用了。
	for ability in (beat.get("abilityPeak", []) as Array):
		_light_ability_peak(String(ability))
	_record_ability_tags(beat.get("abilityTags"))
	var hook := String(beat.get("hook", ""))
	if hook.is_empty():
		return
	_fire_hints("hook:%s" % hook)
	var place := _month12_place_by_hook(hook)
	if not place.is_empty():
		if bool(_month12_flags.get("hook_%s" % hook, false)):
			return
		_month12_flags["hook_%s" % hook] = true
		_ensure_month12_place(String(place.get("id", "")))
		_month12_places_open = true
		_refresh_month12_place_seals()
		_pending_story_hooks.append(hook)
		return
	if _story_door != null:
		return
	_open_story_door(hook)


## 去处钩子按 activities.json 的 unlockHook 认领；没有对应去处的钩子不是去处。
func _month12_place_by_hook(hook: String) -> Dictionary:
	_load_month12_places()
	for value in _month12_places:
		if value is Dictionary and String((value as Dictionary).get("unlockHook", "")) == hook:
			return value
	return {}


## 门立在图书馆门口，不花点、不结算，进去就是看一眼。
## 钩子决定落点：台词先响，门才立——所以坐标表按钩子查，不靠节点里再写一遍。
## 这一拍不弹提示：玩家正在读评审室那一屏，门的事等他自己走到楼下再说。
func _open_story_door(hook := "") -> void:
	if _story_door != null:
		return
	var spot: Vector2 = STORY_DOOR_POSITIONS.get(hook, Vector2.ZERO)
	if spot == Vector2.ZERO:
		var zone := _zone_by_code("D")
		if zone.is_empty():
			return
		spot = zone.get("entrance", Vector2.ZERO)
	_story_door_hook = hook
	_story_door = TOWN_PORTAL.new()
	_story_door.name = "StoryDoor"
	_story_door.position = _snap_month12_point(spot)
	_story_door.z_index = 44
	add_child(_story_door)
	_story_door.set_sealed(false)


## 收掉剧情门：这一眼看完（或者翻到下个月）就不该再留一扇空门在镇上。
func _retire_story_door() -> void:
	_story_door_hook = ""
	if _story_door == null:
		return
	if is_instance_valid(_story_door):
		_story_door.queue_free()
	_story_door = null


## ---------- 剧情那一眼：走到门口 → 按 E 进门 → 屋里那一行 ----------

## 播放器走到这一屏不弹面板，改成把玩家放到门口、黄线收在门上，等他按 E。
## 这一屏不扣点、不占格、不进档案：册子里那句"自己去翻"就是它全部的作用。
func _arm_month12_place_visit(node: Dictionary, visit_id: String) -> void:
	_month12_visit_node = node
	_month12_visit_id = visit_id
	_month12_phase = "month_nodes"
	if _month_runner != null:
		_month_runner.waiting_walk = false
	var place := _month12_visit_place()
	if place.is_empty():
		# 数据没写 visit 块：这一屏退回普通面板，别把整月卡在这一拍。
		_month12_visit_node = {}
		_month12_visit_id = ""
		runner_present_story(node)
		return
	if _story_door == null:
		_open_story_door(String(node.get("doorHook", "")))
	if _story_door != null:
		_month12_waypoint = _story_door.position
		_month12_guide_from = Vector2(-99999, -99999)
	else:
		_month12_waypoint = Vector2(-99999, -99999)
	_runner_place_player(node, false)
	_town_ui_v2.set_task_card(String(place.get("name", "去看一眼")), String(place.get("location", "")))
	_town_ui_v2.set_task_note("走到门口，按 E 进去")
	# 提示条那句由节点自己写：镇上的区域名还是老部门名（regions.json 里 F=运营部），
	# 拿它报地点会变成"门在运营部"，和第 5 月这次去的会展码头对不上。
	var door_hint := String(place.get("doorHint", ""))
	if door_hint.is_empty():
		door_hint = "门在那边"
	_show_reminder_toast(door_hint, "跟着黄线走，到门口按 E 进去")
	# 剧情第一次把玩家带到一个新地方：先给一张讲解卡（解锁卡同一套），
	# 说明这地方是干什么的、这一趟是谁点的。黄线已经铺好，卡上不重复"带我去"。
	var has_card: bool = not (place.get("card", {}) as Dictionary).is_empty()
	if has_card and _month12_place_panel != null and not bool(_month12_flags.get("seen_card_" + _month12_visit_id, false)):
		_month12_flags["seen_card_" + _month12_visit_id] = true
		_month12_place_panel.call_deferred("show_unlock", place, false)


## 这一眼用的"去处"长在节点上，不进 activities.json：
## 它不是自由活动——没有点数、没有讲解卡，也不该在首月跟着那三扇门一起开。
func _month12_visit_place() -> Dictionary:
	if _month12_visit_id.is_empty():
		return {}
	var visit: Dictionary = _month12_visit_node.get("visit", {})
	if visit.is_empty():
		return {}
	return {
		"id": _month12_visit_id,
		"name": String(visit.get("name", "去看一眼")),
		"locationId": String(_month12_visit_node.get("locationId", "")),
		"location": String(_month12_visit_node.get("location", "")),
		# 不写 scene：进门用的就是这个区自己的内景图，和剧情面板那张舞台图同一批美术，
		# 进门前后不会换一间屋子。
		"scene": String(visit.get("scene", "")),
		"object": String(visit.get("object", "")),
		"rowNote": String(visit.get("rowNote", "")),
		"placeLine": String(visit.get("placeLine", "")),
		# 走到门口时提示条上那句"门在哪儿"：由节点写，不拿区域名兜底。
		"doorHint": String(visit.get("doorHint", "")),
		# 剧情第一次带你去这个地方时的那张讲解卡（和自由活动的去处同一套卡）。
		"card": visit.get("card", {}),
		"peek": true,
	}


## ---------- 心情 / 行动点：这两本账的真值 ----------

## 全年参数只读一次：hInit / hMax / apByMonth 都在 manifest.json 里。
func _load_month12_ledger_rules() -> void:
	if not _ap_by_month.is_empty():
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH12_MANIFEST_PATH))
	if not parsed is Dictionary:
		return
	var manifest := parsed as Dictionary
	_mood_max = maxi(1, int(manifest.get("hMax", 6)))
	_mood_h_init = int(manifest.get("hInit", 6))
	var ap := manifest.get("apByMonth", {}) as Dictionary
	for key in ap.keys():
		_ap_by_month[int(String(key))] = int(ap[key])


## 月初起账：心情回 1 点封顶（第一个月直接用 hInit，不再 +1），
## 行动点按这个月的额度发，上个月的余量一律作废——不跨月是全年规则。
func _begin_month_ledger(month_value: int) -> void:
	_load_month12_ledger_rules()
	if _mood_h_init < 0:
		_mood_h_init = _mood_max
	if month_value <= 1:
		_mood = clampi(_mood_h_init, 0, _mood_max)
	else:
		_mood = mini(_mood_max, _mood + 1)
	# 续玩：这个月的心情按存档接回，别再加一次月初 +1。
	if _resume_mood >= 0:
		_mood = clampi(_resume_mood, 0, _mood_max)
		_resume_mood = -1
	_mood_month_start = _mood
	# 读数第 2 月登场：那个月第一次出现"选它会累"（评审室那一档 −1），
	# 有了后果再给读数，顺序不能反。
	var show_meter := month_value >= 2
	if show_meter and not _mood_meter_lit:
		_mood_meter_just_lit = true
	_mood_meter_lit = show_meter
	if _town_ui_v2 != null:
		_town_ui_v2.set_energy_visible(show_meter)
	_ap_total = int(_ap_by_month.get(month_value, 0))
	_month12_ap_left = _ap_total
	_month_ledger = []
	_hint_at_portal = false
	_fire_hints("month_started")
	_refresh_mood_hud()
	# 月首这一刻落一次盘并打上"整月起点"标记：开机续玩就从这个点接。
	_save_month12_progress(true)


## 一处活动对心情做了多少：hCost 是额外消耗，H≤2 时翻倍（行动点不翻）；
## stateDelta.H 是这一处给回的。返回净变化，账本上写"心情 +1 / -2"就用它。
func _apply_activity_mood(activity: Dictionary) -> int:
	var cost := maxi(0, int(activity.get("hCost", 0)))
	if _mood <= 2 and cost > 0:
		cost *= 2
	var gain := int((activity.get("stateDelta", {}) as Dictionary).get("H", 0))
	var before := _mood
	_mood_before_settle = before
	_mood = clampi(_mood - cost + gain, 0, _mood_max)
	_refresh_mood_hud()
	return _mood - before


## 这一处会不会把人缓过来：只看它给不给回心情。H=0 那一格只留这种去处能按。
func _restores_mood(activity: Dictionary) -> bool:
	return int((activity.get("stateDelta", {}) as Dictionary).get("H", 0)) > 0


func _record_ledger(what: String, ap_spent: int, mood_delta: int) -> void:
	if what.is_empty():
		return
	_month_ledger.append({"what": what, "ap": ap_spent, "mood": mood_delta})


## 月末卡上那一行账：安排了哪几件、行动点花掉多少、心情从几到几。
## 一笔都没做的时候不写空话——有的月份本来就没有个人时间。
func _month_ledger_line() -> String:
	var spent := 0
	for entry in _month_ledger:
		spent += int((entry as Dictionary).get("ap", 0))
	if _month_ledger.is_empty():
		if _ap_total <= 0:
			return "这个月没有个人时间"
		return "这个月没安排自己的时间 · 行动点 %d/%d 没用" % [_ap_total, _ap_total]
	var parts: Array = []
	for entry in _month_ledger:
		var mood_delta := int((entry as Dictionary).get("mood", 0))
		var what := String((entry as Dictionary).get("what", ""))
		parts.append(what + ("（心情 %+d）" % mood_delta if mood_delta != 0 else ""))
	return "这个月安排了 %d 件：%s · 行动点用掉 %d · 心情 %d → %d" % [
		_month_ledger.size(), "、".join(parts), spent, _mood_month_start, _mood,
	]


## 心情变了就重画那罐蜂蜜：读数必须跟着账走，不能停在开局那个数。
## 只刷蜂蜜那一行（update_card=false）：十二个月流程里卡片由剧情写，
## 这里再刷一次 WorldClock 的主线，会把「自由安排 · 还剩 N 格」打回「新员工手册」。
func _refresh_mood_hud() -> void:
	if _town_ui_v2 != null and _month12_active:
		_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), _mood, _mood_max, "心情", false)


## 在屋里点了那一行：旁白就在室内这一屏演完。
## 演完不自己往下走——面板的 outcome 会交回节点播放器，下一屏顺手把室内收掉。
func _present_month12_place_visit() -> void:
	var node := _month12_visit_node
	_month12_visit_node = {}
	_month12_visit_id = ""
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	if _activity_panel != null:
		_activity_panel.hide_panel()
	_retire_story_door()
	_apply_node_flags(node)
	_story_event = _runner_story_data(node)
	# 屋里这一眼也是剧情的一屏：收尾那句"去哪儿"同样要补，不然出屋就不知道往哪走。
	_maybe_append_departure(node, _story_event)
	_town_ui_v2.set_task_card(String(_story_event.get("title", "")), String(_story_event.get("location", "")))
	_story_event_panel.present(_story_event)

