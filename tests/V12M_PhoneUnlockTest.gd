extends Control

const PHONE_PANEL := preload("res://scripts/v12m/PhoneInboxPanel.gd")
const BG_TEXTURE := preload("res://assets/场景内部图/熊起东方总部.png")

var _panel: CanvasLayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.name = "OfficeBackground"
	bg.texture = BG_TEXTURE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.modulate = Color(0.82, 0.78, 0.72, 1)
	add_child(bg)

	var dim := ColorRect.new()
	dim.name = "StageDim"
	dim.color = Color(0.02, 0.02, 0.04, 0.42)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = PHONE_PANEL.new()
	add_child(_panel)
	await get_tree().process_frame
	_panel.call("open_tutorial")
