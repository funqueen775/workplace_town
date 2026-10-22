extends CanvasLayer
## 周末活动 · 到达演出面板（2026-09-18 晚新链路，弹丸论外式）：
## 玩家按计划走到目的区进门 → 全屏场景图 + 底部对话框逐字演出「做了什么、什么感受」。
## 交互：点击 / E / 空格 / 回车逐条推进；正在打字时先一键补全，再点才翻页；
## 最后一条演完自动收起并 emit finished，由 WorkplaceTown 结算行动力。
## 区域活动是旁白分镜：使用旁白框，不展示说话人姓名或角色立绘。
## 红线：不引用 autoload（探针直接 new）；文案零数字流水（手账红线同源）。

signal finished

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const NARRATION_DIALOG := preload("res://assets/对话框/旁白对话框_空白.png")
const NARRATION_FRAME_REGION := Rect2(24, 176, 2136, 352)
## 打字机节奏与 StoryEventPanel 保持一致（0.022s × 2 字符/拍）。
const TYPE_INTERVAL := 0.022
## 区域活动与剧情旁白共用美术素材。
const COLOR_TEXT := Color("56301e")
const COLOR_SUB := Color("9b6a48")
## 对话框字号：1080p 下 32px 才有 galgame 台词的分量。
const DIALOG_FONT_SIZE := 32

var _config: Dictionary = {}
var _lines: Array = []
var _line_index := -1
var _active := false

var _root: Control
var _image_rect: TextureRect
var _title_label: Label
var _dialog_label: Label
var _hint_label: Label
var _typewriter_full := ""
var _typewriter_shown := 0
var _typewriter_timer: Timer


func _ready() -> void:
	layer = 160
	visible = false
	_build_ui()


## config: {title: String, image: String(res 路径), lines: Array, who: String}
## lines 每行可为字符串（沿用默认 image）或 {text, image}（推进到该行时换图）。
func present(config: Dictionary) -> void:
	_config = config
	var lines = config.get("lines", [])
	_lines = lines if lines is Array else []
	_line_index = -1
	_active = true
	_title_label.text = String(config.get("title", ""))
	_image_rect.texture = null
	_apply_image(String(config.get("image", "")))
	visible = true
	_advance()


## 换背景图：优先走导入纹理，没导入（.import 缺失）直接读盘兜底。
func _apply_image(path: String) -> void:
	if path.is_empty():
		return
	var tex = null
	# 先查 exists 再 load（2026-09-18 深夜）：新图没有 .import 时 load() 会打
	# 「No loader found」的 USER ERROR 进日志；exists 对未导入资源返回 false，
	# 直接走读盘兜底，日志干净。
	if ResourceLoader.exists(path):
		tex = load(path)
	if not (tex is Texture2D):
		# 兜底：新图还没被编辑器导入时直接读盘，
		# headless 探针与本机文件锁环境下也能出图；导入完成后走压缩纹理。
		var img := Image.load_from_file(path)
		if img != null:
			tex = ImageTexture.create_from_image(img)
	if tex is Texture2D:
		_image_rect.texture = tex


func is_open() -> bool:
	return _active


func _finish() -> void:
	_active = false
	visible = false
	_image_rect.texture = null
	finished.emit()


## ---------- 推进 ----------

func _advance() -> void:
	if not _active:
		return
	# 正在打字 → 先一键补全（galgame 惯例：第一下补全，第二下翻页）。
	if _typewriter_shown < _typewriter_full.length():
		_typewriter_shown = _typewriter_full.length()
		_dialog_label.text = _typewriter_full
		_typewriter_timer.stop()
		return
	_line_index += 1
	if _line_index >= _lines.size():
		_finish()
		return
	var entry = _lines[_line_index]
	if entry is Dictionary:
		_apply_image(String(entry.get("image", "")))
	_start_typewriter(_line_text(_line_index))


## 单行文案：行可为字符串或 {text, image}；{who} → 同行者显示名，拿不到名字兜底「同伴」。
func _line_text(index: int) -> String:
	var entry = _lines[index]
	var text := String(entry.get("text", "")) if entry is Dictionary else String(entry)
	var who := String(_config.get("who", ""))
	if who.is_empty():
		who = "同伴"
	return text.replace("{who}", who)


func _start_typewriter(text: String) -> void:
	_typewriter_full = text
	_typewriter_shown = 0
	_dialog_label.text = ""
	_typewriter_timer.start()


func _tick_typewriter() -> void:
	if not _active:
		_typewriter_timer.stop()
		return
	_typewriter_shown = mini(_typewriter_shown + 2, _typewriter_full.length())
	_dialog_label.text = _typewriter_full.substr(0, _typewriter_shown)
	if _typewriter_shown >= _typewriter_full.length():
		_typewriter_timer.stop()


## ---------- 输入 ----------

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
			_advance()
			get_viewport().set_input_as_handled()


## ---------- UI ----------

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_root_input)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	_image_rect = TextureRect.new()
	_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_image_rect)

	_title_label = Label.new()
	_title_label.visible = false
	_root.add_child(_title_label)

	var dialog_panel := TextureRect.new()
	var cropped := AtlasTexture.new()
	cropped.atlas = NARRATION_DIALOG
	cropped.region = NARRATION_FRAME_REGION
	dialog_panel.texture = cropped
	dialog_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialog_panel.stretch_mode = TextureRect.STRETCH_SCALE
	dialog_panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	dialog_panel.anchor_left = 0.5
	dialog_panel.anchor_right = 0.5
	dialog_panel.anchor_top = 1.0
	dialog_panel.anchor_bottom = 1.0
	dialog_panel.offset_left = -720.0
	dialog_panel.offset_right = 720.0
	dialog_panel.offset_top = -335.0
	dialog_panel.offset_bottom = -65.0
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dialog_panel)

	_dialog_label = Label.new()
	_dialog_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialog_label.offset_left = 95.0
	_dialog_label.offset_right = -95.0
	_dialog_label.offset_top = 58.0
	_dialog_label.offset_bottom = -68.0
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_dialog_label.add_theme_font_override("font", FONT)
	_dialog_label.add_theme_font_size_override("font_size", DIALOG_FONT_SIZE)
	_dialog_label.add_theme_color_override("font_color", COLOR_TEXT)
	_dialog_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.add_child(_dialog_label)

	_hint_label = Label.new()
	_hint_label.text = "点击继续"
	_hint_label.anchor_left = 1.0
	_hint_label.anchor_right = 1.0
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.offset_left = -215.0
	_hint_label.offset_right = -75.0
	_hint_label.offset_top = -68.0
	_hint_label.offset_bottom = -38.0
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_override("font", FONT)
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", COLOR_SUB)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel.add_child(_hint_label)

	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = TYPE_INTERVAL
	_typewriter_timer.timeout.connect(_tick_typewriter)
	add_child(_typewriter_timer)


func _on_root_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()
