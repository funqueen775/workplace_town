extends Node

## 验证黄线会不会跟着人实时改道：把玩家放到三个不同位置，
## 每次等他站定后量一遍"这条线有没有踩在不能走的地方"，并拍一张图。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/guide_live_shot.tscn

const SHOT_DIR := "res://test_artifacts/v12m_guide"

var _town: Node
var _ui: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.4)
	var panel = _town.get("_story_event_panel")
	for i in 400:
		await _wait(0.05)
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if panel != null and bool(panel.call("is_open")):
			panel.call("_advance")
			continue
		if String(_town.get("_month12_phase")) == "tour":
			break
	var player: Node2D = _town.get("_player")
	var goal: Vector2 = _town.get("_month12_waypoint")
	print("GOAL %s" % goal)
	# 三个站位：都从"真的能站"的候选里挑（把玩家硬塞进草坪会得到一条本来就无解的线，
	# 那是测试的问题，不是线的问题）。
	var candidates: Array = [
		player.position,
		player.position + Vector2(150, 96),
		player.position + Vector2(-120, 150),
		player.position + Vector2(60, 210),
		player.position + Vector2(-210, 40),
	]
	var chosen: Array = []
	for spot in candidates:
		if chosen.size() >= 3:
			break
		if bool(_town.call("_is_walkable_position", spot)):
			chosen.append(spot)
	print("站位候选可用 %d 个" % chosen.size())
	for index in chosen.size():
		var spot: Vector2 = chosen[index]
		player.position = spot
		for f in 12:
			await _wait(0.05)
		await _report("站位 %d %s" % [index + 1, spot])
		await _shot("live_%02d" % (index + 1))
	print("GUIDE_LIVE_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _report(tag: String) -> void:
	var line: Node = _town.get("_guide_line")
	var points: PackedVector2Array = line.get("_points")
	var bad := 0
	var sampled := 0
	for i in points.size() - 1:
		for step in 6:
			var p: Vector2 = points[i].lerp(points[i + 1], float(step) / 6.0)
			sampled += 1
			if not bool(_town.call("_is_walkable_position", p)):
				bad += 1
	var player: Node2D = _town.get("_player")
	var head_off: float = points[0].distance_to(player.position) if points.size() > 0 else 9999.0
	var grid = _town.get("_walk_grid")
	var grid_ready := bool(grid.call("is_ready")) if grid != null else false
	print("%s 拐点 %d 个，线上采 %d 点，不在可走区 %d 个；线头离玩家 %.1f；遮罩寻路可用=%s" % [
		tag, points.size(), sampled, bad, head_off, grid_ready])


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
