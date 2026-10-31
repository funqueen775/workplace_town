extends Node

## 树缝卡死实拍：把玩家放到通行遮罩的死胡同里，按住方向不放，看他能不能自己挪出来。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/pin_escape_probe.tscn

## 遮罩上量出来的四处"站得进去、四周一步都判不过"的格子
const TRAPS := [Vector2(480, 984), Vector2(252, 936), Vector2(612, 936), Vector2(456, 720)]

var _town: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/pin_escape"))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	_clear_locks()
	await _wait(0.5)
	_clear_locks()
	var player: Node2D = _town.get("_player")
	# 情形一：人被摆在路外（树丛、草地、水面）—— 玩家截图里就是这种，四面都被遮罩挡
	var off := _find_off_track_spot()
	if off != Vector2.INF:
		player.position = off
		_clear_locks()
		Input.action_press("move_up")
		var off_from: Vector2 = off
		var off_trace := PackedStringArray()
		for i in 8:
			await _wait(0.2)
			off_trace.append(str(player.position.round()))
		Input.action_release("move_up")
		print("路外 %s → 按住上 1.6 秒：位移 %.0f · 落点合法=%s" % [
			off, player.position.distance_to(off_from),
			bool(_town.call("_is_walkable_position", player.position))])
		print("   轨迹 ", " ".join(off_trace))
	# 先确认正常路面没被改坏：在大路上按住右，一秒该跑两百多像素
	# （落点要先吸附成"真能站"的位置，否则测的是墙缝，不是走路规则）
	player.position = _town.call("_snap_month12_point", Vector2(1008, 240))
	_clear_locks()
	Input.action_press("move_right")
	var road_from: Vector2 = player.position
	var road_trace := PackedStringArray()
	for i in 5:
		await _wait(0.2)
		road_trace.append("%s|右遮罩%s" % [str(player.position.round()),
			"通" if bool(_town.call("_is_walkable_position", player.position + Vector2(9, 0))) else "挡"])
	Input.action_release("move_right")
	print("正常路面：按住右 1 秒位移 %.0f 像素 · 轨迹 %s" % [
		player.position.distance_to(road_from), " ".join(road_trace)])
	print("   起点遮罩=%s 网格吸附=%s" % [
		bool(_town.call("_is_walkable_position", road_from)), str(road_from.round())])
	print("   拦路检查：月首卡=%s 剧情卡=%s 导览=%s 过场锁=%s 室内=%s 活动区=%s 阶段=%s" % [
		str(_town.get("_month12_start_panel").call("is_open")),
		str(_town.get("_story_event_panel").call("is_open")),
		_town.get("_hud_tour_active"), _town.get("_date_cutscene_lock"),
		str(_town.get("_interior_preview").call("is_open")),
		str(_town.get("_active_zone")), str(_town.get("_month12_phase")),
	])
	for trap in TRAPS:
		player.position = trap
		_clear_locks()
		var pinned := bool(_town.call("_is_pinned_in", trap))
		Input.action_press("move_left")
		Input.action_press("move_up")
		var trace := PackedStringArray()
		for i in 10:
			await _wait(0.25)
			trace.append(str(player.position.round()))
		Input.action_release("move_left")
		Input.action_release("move_up")
		var moved: float = player.position.distance_to(trap)
		var walkable := bool(_town.call("_is_walkable_position", player.position))
		var still := bool(_town.call("_is_pinned_in", player.position))
		print("卡点 %s 八向全挡=%s → 按住左上 2.5 秒：位移 %.0f · 落点合法=%s · 仍八向全挡=%s" % [
			trap, pinned, moved, walkable, still])
		print("   轨迹 ", " ".join(trace))
		await _shot("pin_%d_%d" % [int(trap.x), int(trap.y)])
	print("PIN_PROBE_DONE")
	get_tree().quit(0)


## 开局那一串面板与过场会直接锁移动，探针要测的是走路规则，先把锁清掉。
func _clear_locks() -> void:
	_town.set("_date_cutscene_lock", false)
	_town.set("_hud_tour_active", false)
	_town.set("_tutorial_complete", true)
	_town.set("_month12_waypoint", Vector2(-99999, -99999))
	for key in ["_story_event_panel", "_month12_start_panel", "_interior_preview", "_memory_wall"]:
		var node = _town.get(key)
		if node == null:
			continue
		if node is CanvasItem:
			(node as CanvasItem).hide()
		for method in ["close", "dismiss", "hide_panel"]:
			if node.has_method(method):
				node.call(method)


## 找一个"站不住但离路面不远"的点：模拟玩家踩进树丛/草地后的位置。
func _find_off_track_spot() -> Vector2:
	for y in range(600, 1040, 12):
		for x in range(120, 900, 12):
			var at := Vector2(x, y)
			if bool(_town.call("_is_walkable_position", at)):
				continue
			if bool(_town.call("_is_walkable_position", at + Vector2(0, -30))):
				return at
	return Vector2.INF


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://test_artifacts/pin_escape/%s.png" % name)
	print("shot %s -> %s" % [name, image.save_png(path)])
