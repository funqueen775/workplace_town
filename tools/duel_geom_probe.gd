extends Node

## 量一下十二个月那条线开出来的对局到底摆在哪儿：
## 视口多大、缩放多少、对局页自己的矩形在哪、镇上的界面为什么压在它上面。
## 用法：<godot> --path . --resolution 1600x900 res://tools/duel_geom_probe.tscn

var _town: Node
var _done := false


func _ready() -> void:
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.0).timeout
	var start: Variant = _town.get("_month12_start_panel")
	if start != null and is_instance_valid(start) and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await get_tree().create_timer(1.0).timeout
	_town.call("debug_jump_to_month", 7)
	await get_tree().create_timer(1.6).timeout
	for i in 20:
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.6).timeout
			break
		await get_tree().create_timer(0.3).timeout
	var places: Array = _town.get("_month12_places")
	var valley: Dictionary = {}
	for value in places:
		if String(Dictionary(value).get("id", "")) == "m7_valley":
			valley = Dictionary(value)
	print("窗口=", get_window().size, " 视口=", get_viewport().get_visible_rect().size,
		" 视口原点=", get_viewport().get_visible_rect().position,
		" 画布变换=", get_viewport().get_canvas_transform(),
		" 拉伸=", ProjectSettings.get_setting("display/window/stretch_mode"),
		" 基准=", ProjectSettings.get_setting("display/window/size/viewport_width"),
		"x", ProjectSettings.get_setting("display/window/size/viewport_height"))
	_town.call("_open_month12_duel", valley)
	await get_tree().create_timer(1.6).timeout
	var overlay: Node = _town.get("_training_overlay")
	if overlay == null:
		print("没开起来")
		_done = true
		get_tree().quit(1)
		return
	print("overlay 层=", (overlay as CanvasLayer).layer)
	_walk(overlay, 1)
	print("--- 镇上的界面都在哪些层 ---")
	_layers(_town)
	get_viewport().get_texture().get_image().save_png("res://test_artifacts/duel/几何_对局.png")
	print("GEOM_DONE")
	_done = true
	get_tree().quit(0)


func _walk(node: Node, depth: int) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			var gr := c.get_global_rect()
			if depth <= 4:
				print("  ".repeat(depth), c.name, " ", c.get_class(),
					" pos=", c.position, " size=", c.size, " scale=", c.scale,
					" 全局=", gr.position, "x", gr.size)
		if child.get_child_count() > 0 and depth < 5:
			_walk(child, depth + 1)


func _layers(root: Node) -> void:
	var seen := {}
	_collect_layers(root, seen)
	var keys: Array = seen.keys()
	keys.sort()
	for k in keys:
		print("   层 ", k, " → ", seen[k])


func _collect_layers(node: Node, seen: Dictionary) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			var layer := (child as CanvasLayer).layer
			var names: Array = seen.get(layer, [])
			names.append(child.name)
			seen[layer] = names
		_collect_layers(child, seen)


func _watchdog() -> void:
	await get_tree().create_timer(180.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
