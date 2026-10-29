extends Node

## F9 跳月面板探针：按真按键开面板、点其中一格，验"点哪个月就到哪个月"。

var _town: Node
var _dir := ""


func _ready() -> void:
	_dir = ProjectSettings.globalize_path("res://test_artifacts/jump_panel")
	DirAccess.make_dir_recursive_absolute(_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.6).timeout
	await _press(KEY_F9)
	var panel = _town.get("_jump_panel")
	print("面板开了吗：", panel != null and is_instance_valid(panel) and bool(panel.visible))
	await _shot("panel_open")
	var button := _find_button(panel, "第 5 月")
	if button != null:
		button.emit_signal("pressed")
		await get_tree().create_timer(3.0).timeout
		print("点了第 5 月 → 现在在第 ", int(_town.get("_month12_month")), " 月；面板还开着吗：", bool(panel.visible))
		await _shot("after_jump")
	else:
		print("找不到第 5 月那颗按钮")
	print("JUMP_PANEL_DONE")
	get_tree().quit(0)


func _find_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	for child in root.get_children():
		if child is Button and String(child.text).begins_with(text):
			return child as Button
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _press(keycode: int) -> void:
	var down := InputEventKey.new()
	down.keycode = keycode
	down.physical_keycode = keycode
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.keycode = keycode
	up.physical_keycode = keycode
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().create_timer(0.6).timeout


func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("跳过截图（headless 出不了图）：", name)
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("shot ->", image.save_png("%s/%s.png" % [_dir, name]))
