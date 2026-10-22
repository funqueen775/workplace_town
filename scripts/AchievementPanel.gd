extends CanvasLayer

signal continued(node_id: String, choice_id: String)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

var _node: Dictionary = {}
var _choice_id := ""
var _choices: VBoxContainer
var _title: Label
var _body: Label
var _continue: Button


func _ready() -> void:
	layer = 205
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.05, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_top = -235
	panel.offset_right = 420
	panel.offset_bottom = 235
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4eee0")
	style.border_color = Color("9d7946")
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	_title = _label("", 29)
	content.add_child(_title)
	_body = _label("", 20)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_body)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 8)
	content.add_child(_choices)
	_continue = Button.new()
	_continue.text = "继续"
	_continue.custom_minimum_size = Vector2(160, 46)
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue.add_theme_font_override("font", FONT)
	_continue.pressed.connect(_on_continue)
	content.add_child(_continue)


func open(node: Dictionary) -> void:
	_node = node
	_choice_id = ""
	_title.text = String(node.get("title", ""))
	_body.text = String(node.get("text", ""))
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	var options: Array = node.get("choices", [])
	for index in options.size():
		var choice_id := "option_" + String.chr(97 + index)
		var button := Button.new()
		button.text = "%s  %s" % [String.chr(65 + index), String(options[index])]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 42
		button.add_theme_font_override("font", FONT)
		button.pressed.connect(_select.bind(choice_id))
		_choices.add_child(button)
	_continue.disabled = not options.is_empty()
	visible = true


func _select(choice_id: String) -> void:
	_choice_id = choice_id
	_continue.disabled = false
	for child in _choices.get_children():
		child.modulate = Color("b47c2f") if child == _choices.get_child(choice_id.unicode_at(7) - 97) else Color.WHITE


func _on_continue() -> void:
	visible = false
	continued.emit(String(_node.get("id", "")), _choice_id)


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("3b2e22"))
	return label
