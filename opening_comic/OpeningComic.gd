extends Control
class_name OpeningComic

## 《熊心壮职》开场自动漫画（Godot 4.3+）
## 直接实例化 OpeningComic.tscn 即可播放。
## 播放完毕会发出 comic_finished，交给外部切换到入职问卷。

signal comic_finished

@export_range(0.3, 5.0, 0.05) var seconds_per_panel: float = 1.45
@export_range(0.0, 5.0, 0.05) var page_pause: float = 1.75
@export_range(0.0, 5.0, 0.05) var ending_pause: float = 0.85
@export var auto_start: bool = true
@export_file("*.tscn") var next_scene_path: String = ""

const PAGE_ASPECT := 1.5
const PAGE_MARGIN := 36.0
const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

const PAGE_1 := [
	{
		"image": "assets/p1_01.webp",
		"rect": Rect2(0.004, 0.004, 0.992, 0.308),
	},
	{
		"image": "assets/p1_02.webp",
		"rect": Rect2(0.004, 0.324, 0.372, 0.318),
	},
	{
		"image": "assets/p1_03.webp",
		"rect": Rect2(0.377, 0.324, 0.347, 0.318),
		"caption": "还是第一版\n比较好。",
		"caption_rect": Rect2(0.52, 0.05, 0.44, 0.42),
		"caption_kind": "speech",
	},
	{
		"image": "assets/p1_04.webp",
		"rect": Rect2(0.727, 0.324, 0.269, 0.318),
		"caption": "你已经记不清，\n这是第几次修改。",
		"caption_rect": Rect2(0.04, 0.04, 0.72, 0.38),
	},
	{
		"image": "assets/p1_05.webp",
		"rect": Rect2(0.004, 0.647, 0.390, 0.348),
		"caption": "嗡——",
		"caption_rect": Rect2(0.67, 0.24, 0.28, 0.24),
		"caption_kind": "sfx",
	},
	{
		"image": "assets/p1_06.webp",
		"rect": Rect2(0.397, 0.647, 0.599, 0.348),
		"caption": "就在你认真考虑，\n要不要改行卖蜂蜜的时候……",
		"caption_rect": Rect2(0.49, 0.59, 0.48, 0.36),
	},
]

const PAGE_2 := [
	{
		"image": "assets/p2_01.webp",
		"rect": Rect2(0.004, 0.004, 0.320, 0.324),
		"caption": "这班上得不对劲？\n来换一种熊生。\n不会也没关系，小熊都是慢慢长大的。",
		"caption_rect": Rect2(0.31, 0.13, 0.57, 0.67),
		"caption_kind": "phone",
	},
	{
		"image": "assets/p2_02.webp",
		"rect": Rect2(0.328, 0.004, 0.327, 0.324),
	},
	{
		"image": "assets/p2_03.webp",
		"rect": Rect2(0.660, 0.004, 0.336, 0.324),
		"caption": "你回头看了一眼文件山。",
		"caption_rect": Rect2(0.48, 0.03, 0.50, 0.32),
	},
	{
		"image": "assets/p2_04.webp",
		"rect": Rect2(0.004, 0.337, 0.464, 0.268),
		"caption": "看起来不太正经。\n但你现在的工作，\n也没有正经到哪里去。",
		"caption_rect": Rect2(0.02, 0.03, 0.53, 0.45),
	},
	{
		"image": "assets/p2_05.webp",
		"rect": Rect2(0.472, 0.337, 0.524, 0.268),
	},
	{
		"image": "assets/p2_06.webp",
		"rect": Rect2(0.004, 0.613, 0.992, 0.383),
	},
]

var _base_dir: String
var _page_holder: Control
var _panels: Array[Control] = []
var _timer: Timer
var _skip_button: Button
var _continue_hint: Label
var _page_index := 0
var _panel_index := -1
var _phase := "idle"
var _running := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_base_dir = get_script().resource_path.get_base_dir()
	_build_interface()
	resized.connect(_layout_page)
	call_deferred("_layout_page")
	if auto_start:
		call_deferred("play")


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("24160f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_page_holder = Control.new()
	_page_holder.name = "ComicPage"
	_page_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_page_holder.gui_input.connect(_on_page_gui_input)
	add_child(_page_holder)

	_skip_button = Button.new()
	_skip_button.text = "跳过"
	_skip_button.custom_minimum_size = Vector2(94, 42)
	_skip_button.size = _skip_button.custom_minimum_size
	_skip_button.add_theme_font_size_override("font_size", 18)
	_skip_button.add_theme_font_override("font", CJK_FONT)
	_skip_button.pressed.connect(skip)
	add_child(_skip_button)

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	_continue_hint = Label.new()
	_continue_hint.text = "点击继续"
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_continue_hint.add_theme_font_size_override("font_size", 18)
	_continue_hint.add_theme_font_override("font", CJK_FONT)
	_continue_hint.add_theme_color_override("font_color", Color("fff2d4", 0.78))
	_continue_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_continue_hint.position = Vector2(-152, -46)
	_continue_hint.size = Vector2(128, 30)
	_continue_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_hint.visible = false
	add_child(_continue_hint)


func _layout_page() -> void:
	if _page_holder == null:
		return
	var available := size - Vector2(PAGE_MARGIN * 2.0, PAGE_MARGIN * 2.0)
	if available.x <= 0.0 or available.y <= 0.0:
		return
	var target := available
	if target.x / target.y > PAGE_ASPECT:
		target.x = target.y * PAGE_ASPECT
	else:
		target.y = target.x / PAGE_ASPECT
	_page_holder.position = (size - target) * 0.5
	_page_holder.size = target

	_skip_button.position = Vector2(size.x - _skip_button.size.x - 18.0, 12.0)

	for panel in _panels:
		var normalized_rect: Rect2 = panel.get_meta("normalized_rect")
		panel.position = normalized_rect.position * target
		panel.size = normalized_rect.size * target
		panel.pivot_offset = panel.size * 0.5
		var caption := panel.get_node_or_null("Caption") as Label
		if caption:
			var ratio: float = caption.get_meta("font_ratio", 0.085)
			caption.add_theme_font_size_override("font_size", int(clampf(panel.size.y * ratio, 13.0, 30.0)))


func _show_page(index: int) -> void:
	for child in _page_holder.get_children():
		child.queue_free()
	_panels.clear()
	_page_index = index
	_panel_index = -1
	var page_data: Array = PAGE_1 if index == 0 else PAGE_2
	for entry in page_data:
		var panel := _make_panel(entry)
		_page_holder.add_child(panel)
		_panels.append(panel)
	_layout_page()


func _make_panel(entry: Dictionary) -> Control:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.97, 0.97)
	panel.set_meta("normalized_rect", entry["rect"])
	panel.add_theme_stylebox_override("panel", _panel_style())

	var texture_rect := TextureRect.new()
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture = load(_base_dir.path_join(entry["image"]))
	panel.add_child(texture_rect)

	if entry.has("caption"):
		var caption := _make_caption(entry)
		panel.add_child(caption)
	return panel


func _make_caption(entry: Dictionary) -> Label:
	var caption := Label.new()
	caption.name = "Caption"
	caption.text = entry["caption"]
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect: Rect2 = entry["caption_rect"]
	caption.anchor_left = rect.position.x
	caption.anchor_top = rect.position.y
	caption.anchor_right = rect.end.x
	caption.anchor_bottom = rect.end.y
	caption.offset_left = 0.0
	caption.offset_top = 0.0
	caption.offset_right = 0.0
	caption.offset_bottom = 0.0
	caption.add_theme_color_override("font_color", Color("4b2c1d"))
	caption.add_theme_font_override("font", CJK_FONT)

	var kind: String = entry.get("caption_kind", "box")
	match kind:
		"phone":
			caption.rotation = deg_to_rad(-7.0)
			caption.set_meta("font_ratio", 0.072)
		"sfx":
			caption.add_theme_font_size_override("font_size", 30)
			caption.set_meta("font_ratio", 0.12)
		"speech":
			caption.add_theme_stylebox_override("normal", _caption_style(18.0))
			caption.set_meta("font_ratio", 0.085)
		_:
			caption.add_theme_stylebox_override("normal", _caption_style(7.0))
			caption.set_meta("font_ratio", 0.078)
	return caption


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ead4b3")
	style.border_color = Color("4f2b1a")
	style.set_border_width_all(4)
	return style


func _caption_style(radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff9eaf2")
	style.border_color = Color("58321f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func play() -> void:
	_timer.stop()
	_running = true
	_phase = "revealing"
	_continue_hint.hide()
	_skip_button.show()
	_skip_button.disabled = false
	_skip_button.text = "跳过"
	_show_page(0)
	_timer.start(0.35)


func skip() -> void:
	if not _running:
		return
	_timer.stop()
	_show_page(1)
	for panel in _panels:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	_panel_index = _panels.size() - 1
	_finish()


func _on_timer_timeout() -> void:
	match _phase:
		"revealing":
			_reveal_next_panel()
		"page_pause":
			_show_page(1)
			_phase = "revealing"
			_timer.start(0.25)
		"ending_pause":
			_finish()


func _reveal_next_panel() -> void:
	_panel_index += 1
	if _panel_index >= _panels.size():
		return
	var panel := _panels[_panel_index]
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.36)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.36)

	if _panel_index == _panels.size() - 1:
		if _page_index == 0:
			_phase = "page_pause"
			_timer.start(page_pause)
		else:
			_phase = "ending_pause"
			_timer.start(ending_pause)
	else:
		_timer.start(seconds_per_panel)


func _on_page_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _running:
			_accelerate()
		elif _phase == "finished":
			_continue_to_login()
	elif event is InputEventScreenTouch and event.pressed:
		if _running:
			_accelerate()
		elif _phase == "finished":
			_continue_to_login()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		if _running:
			_accelerate()
		elif _phase == "finished":
			_continue_to_login()


func _accelerate() -> void:
	_timer.stop()
	match _phase:
		"revealing":
			_reveal_next_panel()
		"page_pause":
			_show_page(1)
			_phase = "revealing"
			_timer.start(0.1)
		"ending_pause":
			_finish()


func _finish() -> void:
	if not _running:
		return
	_running = false
	_phase = "finished"
	_timer.stop()
	_skip_button.hide()
	_continue_hint.show()


func _continue_to_login() -> void:
	if _phase != "finished":
		return
	_phase = "leaving"
	_continue_hint.hide()
	comic_finished.emit()
	if not next_scene_path.is_empty():
		get_tree().change_scene_to_file(next_scene_path)
