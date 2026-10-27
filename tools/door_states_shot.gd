extends Control

## 门的两种状态样张：灰（不开放）/ 亮（能进）/ 亮+走近高亮，铺在一张素底上。
## 用法：<godot> --path <proj> --resolution 1280x520 res://tools/door_states_shot.tscn

const SHOT := "res://test_artifacts/v12m_doors/door_states_sheet.png"
const PORTAL := preload("res://scripts/TownPortal.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("e8dcb8")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var defs := [
		[200.0, true, false, "不开放（灰，不转不动）"],
		[640.0, false, false, "能进（金色，转）"],
		[1080.0, false, true, "走近（更亮一圈）"],
	]
	for d in defs:
		var door := PORTAL.new()
		door.position = Vector2(float(d[0]), 220.0)
		add_child(door)
		door.set_sealed(bool(d[1]))
		door.set_highlighted(bool(d[2]))
		var label := Label.new()
		label.text = String(d[3])
		label.position = Vector2(float(d[0]) - 130.0, 360.0)
		label.size = Vector2(260.0, 40.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Color("4a2b1a"))
		add_child(label)
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("sheet -> %s" % image.save_png(ProjectSettings.globalize_path(SHOT)))
	get_tree().quit(0)
