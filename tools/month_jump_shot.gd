extends Node

## 跳月看片批量截图（2026-10-28）：把第 2..12 月逐月跳进去、自己播一遍，
## 每月留下几张关键屏——开场、每一次三选一、自由活动时镇上的门、月末卡、档案页那五排格子。
##
## 用法（要有真窗口，headless 截不出图）：
##   Godot --path . res://tools/month_jump_shot.tscn -- --months=2,7,12 --path=B
##   --months 不写就是 2..12 全跑；--path 不写就是 A 路线。

const MAIN_SCENE := "res://Main.tscn"

var _town: Node
var _dir := ""
var _months: Array[int] = []
var _seed_path := "A"
var _last_node := ""
var _taken := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var text := String(arg)
		if text.begins_with("--months="):
			for part in text.get_slice("=", 1).split(","):
				if part.is_valid_int():
					_months.append(int(part))
		elif text.begins_with("--path="):
			_seed_path = text.get_slice("=", 1).to_upper()
	if _months.is_empty():
		for m in range(2, 13):
			_months.append(m)
	_dir = ProjectSettings.globalize_path("res://test_artifacts/v12m_jump")
	DirAccess.make_dir_recursive_absolute(_dir)
	DirAccess.make_dir_recursive_absolute(_dir + "/web")
	print("JUMP_SHOTS start months=%s path=%s dir=%s" % [_months, _seed_path, _dir])
	_town = load(MAIN_SCENE).instantiate()
	add_child(_town)
	await get_tree().create_timer(3.4).timeout
	for month_value in _months:
		await _play_month(month_value)
	print("JUMP_SHOTS_DONE")
	get_tree().quit(0)


func _play_month(month_value: int) -> void:
	var tag := "m%02d" % month_value
	print("== 第 %d 月" % month_value)
	_town.call("debug_jump_to_month", month_value, _seed_path)
	await get_tree().create_timer(2.4).timeout
	# 月首卡会挡在剧情前面：先关掉它再往下走（2026-10-29 新增）。
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await get_tree().create_timer(0.8).timeout
	await _shot(tag + "_01_开场")
	var _dbg_tick := 0
	for step in 700:
		await get_tree().create_timer(0.06).timeout
		_dbg_tick += 1
		if _dbg_tick % 25 == 0:
			var dbg_runner = _town.get("_month_runner")
			print("  · 相位=%s 节点=%s 等走位=%s 面板=%s 玩家=%s" % [
				String(_town.get("_month12_phase")),
				String((dbg_runner.get("current") as Dictionary).get("id", "")) if dbg_runner != null else "-",
				str(bool(dbg_runner.get("waiting_walk"))) if dbg_runner != null else "-",
				str(bool(_town.get("_story_event_panel").call("is_open"))) if _town.get("_story_event_panel") != null else "-",
				_town.get("_player").position])
		var phase := String(_town.get("_month12_phase"))
		if phase == "close":
			await get_tree().create_timer(0.5).timeout
			await _shot(tag + "_90_月末卡")
			var close_panel = _town.get("_month12_close_panel")
			if close_panel != null and is_instance_valid(close_panel):
				close_panel.call("close")
			_town.set("_month12_phase", "done")
			break
		if phase == "done":
			break
		if phase == "activity":
			if _once(tag + "_activity"):
				await get_tree().create_timer(0.6).timeout
				await _shot(tag + "_70_自由活动")
			_town.call("_on_end_month_pressed")
			continue
		var panel = _town.get("_story_event_panel")
		if panel != null and bool(panel.call("is_open")):
			var runner = _town.get("_month_runner")
			var node_id := String((runner.get("current") as Dictionary).get("id", "")) if runner != null else ""
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				if _once(tag + "_%s_选择" % node_id):
					await get_tree().create_timer(0.4).timeout
					await _shot(tag + "_50_%s_三选一" % node_id)
				panel.call("_on_choice_picked", node_id, _seed_path, 45)
			else:
				if node_id != _last_node and _once(tag + "_%s_正文" % node_id):
					_last_node = node_id
					await get_tree().create_timer(0.4).timeout
					await _shot(tag + "_40_%s_剧情" % node_id)
				panel.call("_advance")
			continue
		var runner2 = _town.get("_month_runner")
		var waypoint: Vector2 = _town.get("_month12_waypoint")
		if runner2 != null and bool(runner2.get("waiting_walk")) and waypoint.x > -90000.0:
			var walker: Node2D = _town.get("_player")
			if _once(tag + "_pos_" + String((runner2.get("current") as Dictionary).get("id", ""))):
				print("走位 %s：任务卡副行「%s」· 玩家在 %s，落点 %s，直线距离 %.0f" % [
					String((runner2.get("current") as Dictionary).get("id", "")),
					String((_town.get("_town_ui_v2").get("_task_note") as Label).text),
					walker.position, waypoint, walker.position.distance_to(waypoint)])
			if _once(tag + "_walk_%s" % String((runner2.get("current") as Dictionary).get("id", ""))):
				walker.position = waypoint - Vector2(240, 0)
				await get_tree().create_timer(0.5).timeout
				await _shot(tag + "_30_跟着走_%s" % String((runner2.get("current") as Dictionary).get("id", "")))
			# 一步步走过去（不瞬移），让游戏的到达判定和读秒兜底都真跑一遍
			if walker.position.distance_to(waypoint) > 24.0:
				walker.position += (waypoint - walker.position).normalized() * 24.0
			else:
				walker.position = waypoint
			continue
	await get_tree().create_timer(0.6).timeout
	# 月末卡是排过一场"天黑"过场才开的，队列里可能还压着一次开卡：
	# 先把欠着的过场清掉，否则收完它又自己开回来，把档案页挡住。
	_town.set("_date_wait_panel", [])
	_town.set("_date_then_queue", [])
	var tail_panel = _town.get("_month12_close_panel")
	if tail_panel != null and is_instance_valid(tail_panel):
		var tail_root: Control = tail_panel.get("_root")
		if tail_root != null and tail_root.visible:
			await _shot(tag + "_90_月末卡")
		tail_panel.call("close")
	_town.set("_month12_phase", "done")
	print("第 %d 月月末读数：能力 %s 攒点 %s 点亮到顶 %s" % [
		month_value, JSON.stringify(_town.call("ability_display_levels")),
		JSON.stringify(_town.get("_ability_points")),
		JSON.stringify(_flags_named("peak_"))])
	_town.call("_open_ui_profile")
	await get_tree().create_timer(0.7).timeout
	await _shot(tag + "_95_档案五格")
	var ui = _town.get("_town_ui_v2")
	if ui != null and is_instance_valid(ui):
		ui.call("close_view")


## 把某前缀的旗标名捞出来（只为把"点亮到顶的是哪几格"打印清楚）。
func _flags_named(prefix: String) -> Array[String]:
	var out: Array[String] = []
	for key in (_town.get("_month12_flags") as Dictionary).keys():
		var name := String(key)
		if name.begins_with(prefix):
			out.append(name.trim_prefix(prefix))
	return out


func _once(key: String) -> bool:
	if _taken.has(key):
		return false
	_taken[key] = true
	return true


func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("跳过截图（headless 出不了图）：%s" % name)
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("shot %s -> %s" % [name, image.save_png("%s/%s.png" % [_dir, name])])
	# 顺手压一张小的（900 宽 JPEG）：画廊里嵌得下，原图 still 在 PNG 里。
	var small := image.duplicate()
	small.resize(900, int(900.0 * float(small.get_height()) / float(small.get_width())), Image.INTERPOLATE_LANCZOS)
	small.save_jpg("%s/web/%s.jpg" % [_dir, name], 0.62)

