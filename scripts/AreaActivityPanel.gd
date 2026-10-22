class_name AreaActivityPanel
extends CanvasLayer

signal activity_selected(activity: Dictionary)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

var _root: Panel
var _title: Label
var _points: Label
var _rows: VBoxContainer
var _zone_id := ""
var _activities: Array = []
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 120
	_build_ui()
	hide_panel()


func show_for_region(region_id: String, activities: Array, remaining: int, maximum: int) -> void:
	_zone_id = region_id
	_activities = activities.duplicate(true)
	_title.text = "%s区可进行的活动" % region_id
	_points.text = "剩余行动力 %d/%d" % [remaining, maximum]
	_rebuild_rows()
	_root.show()


func refresh_points(remaining: int, maximum: int) -> void:
	_points.text = "剩余行动力 %d/%d" % [remaining, maximum]
	for button in _buttons:
		button.disabled = remaining <= 0


func hide_panel() -> void:
	if _root != null:
		_root.hide()


func _build_ui() -> void:
	_root = Panel.new()
	_root.name = "AreaActivityPanel"
	_root.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_root.position = Vector2(-410, 330)
	_root.size = Vector2(380, 420)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.075, 0.065, 0.96)
	style.border_color = Color("d4ad61")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_root.add_theme_stylebox_override("panel", style)
	add_child(_root)

	_title = Label.new()
	_title.position = Vector2(20, 18)
	_title.size = Vector2(340, 38)
	_title.add_theme_font_override("font", FONT)
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color("f5dfae"))
	_root.add_child(_title)

	_points = Label.new()
	_points.position = Vector2(20, 58)
	_points.size = Vector2(340, 30)
	_points.add_theme_font_override("font", FONT)
	_points.add_theme_font_size_override("font_size", 18)
	_points.add_theme_color_override("font_color", Color("ffbd4a"))
	_root.add_child(_points)

	var rule := HSeparator.new()
	rule.position = Vector2(20, 96)
	rule.size = Vector2(340, 2)
	_root.add_child(rule)

	_rows = VBoxContainer.new()
	_rows.position = Vector2(20, 116)
	_rows.size = Vector2(340, 280)
	_rows.add_theme_constant_override("separation", 16)
	_root.add_child(_rows)


func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	_buttons.clear()
	for value in _activities:
		if not (value is Dictionary):
			continue
		var activity := value as Dictionary
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(340, 112)
		row.add_theme_constant_override("separation", 12)
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(112, 96)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview.texture = _load_texture(String(activity.get("image", "")))
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(preview)
		var button := Button.new()
		button.custom_minimum_size = Vector2(216, 96)
		button.text = "%s\n消耗 1 点行动力" % String(activity.get("title", "活动"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_override("font", FONT)
		button.add_theme_font_size_override("font_size", 20)
		button.tooltip_text = "进入对应活动场景"
		button.pressed.connect(func(): activity_selected.emit(activity.duplicate(true)))
		row.add_child(button)
		_rows.add_child(row)
		_buttons.append(button)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var resource := load(path) as Texture2D
	if resource != null:
		return resource
	var image := Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image != null else null
