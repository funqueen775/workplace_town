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
## 卡住检测：同一个相位+节点连着几十拍没动，就替他放行并大声记一笔。
var _last_sig := ""
var _stall := 0


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
	_last_sig = ""
	_stall = 0
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
			print("  · 相位=%s 节点=%s 等走位=%s 面板=%s 手机门=%s/%s 在读=%s 玩家=%s" % [
				String(_town.get("_month12_phase")),
				String((dbg_runner.get("current") as Dictionary).get("id", "")) if dbg_runner != null else "-",
				str(bool(dbg_runner.get("waiting_walk"))) if dbg_runner != null else "-",
				str(bool(_town.get("_story_event_panel").call("is_open"))) if _town.get("_story_event_panel") != null else "-",
				str(bool(_town.get("_phone_gate_waiting"))),
				str(bool(_town.get("_phone_gate_read"))),
				str(bool(_town.call("_month12_reading"))),
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
		# 手机前置那一屏（requireRead）：真人会点收件箱，自动播也要替他点一下，
		# 否则整月卡在第一屏，看片看不出后面的节奏。
		# 收手机必须走面板自己的 close_phone：它的 phone_closed 信号才会把播放器接回正轨。
		# 直接叫城镇那个回调等于"手机还开着人已经走了"——_month12_reading() 恒真，
		# 下一屏的黄线永远走不到终点，整月就卡在 node_walk（2026-10-30 第 3 月就是这么卡的）。
		if bool(_town.get("_phone_gate_waiting")):
					# 面板这时可能还没被城镇建出来（消息批次才刚投完），先替他建好并接上信号。
					var inbox = _town.get("_month_phone_panel")
					if inbox == null or not is_instance_valid(inbox):
						inbox = _town.call("_ensure_month_phone_panel")
					# 讲解卡不是这一屏要看的东西：划掉它，不然 _show_month_phone_drawer 只会一遍遍弹卡，
					# 而 close_phone() 因为手机根本没开直接返回，"在读"永远是真的。
					if not bool(inbox.get("_tutorial_completed")):
						inbox.set("_tutorial_completed", true)
					if bool(inbox.call("is_open")):
						inbox.call("close_tutorial")
						inbox.call("close_phone")
						await get_tree().create_timer(0.6).timeout
					if not bool(_town.get("_phone_gate_read")):
						_town.call("_open_ui_phone")
						await get_tree().create_timer(0.5).timeout
					# 收手机走面板自己的 close_phone：它的 phone_closed 信号才会把播放器接回正轨。
					# 直接叫城镇那个回调等于"手机还开着人已经走了"——_month12_reading() 恒真，
					# 下一屏的黄线永远走不到终点，整月卡在 node_walk（2026-10-30 第 3 月就是这么卡的）。
					inbox.call("close_phone")
					await get_tree().create_timer(0.7).timeout
					# 信号没接上（面板压根没真开起来）时兜底放行，不死在这一屏。
					if bool(_town.get("_phone_gate_waiting")) and bool(_town.get("_phone_gate_read")):
						_town.set("_phone_gate_waiting", false)
						_town.set("_phone_gate_read", false)
						var gate_runner = _town.get("_month_runner")
						if gate_runner != null and is_instance_valid(gate_runner):
							gate_runner.call("on_panel_closed")
					continue
		if phase == "activity":
			if _once(tag + "_activity"):
				await get_tree().create_timer(0.6).timeout
				await _shot(tag + "_70_自由活动")
			_town.call("_on_end_month_pressed")
			continue
		# 卡住兜底：这个工具的目的是把整月的节奏看完，不是原样守住游戏里的坑——
		# 坑由这行警告记进日志，放行动作只做"真人做得出来"的那几样。
		var stall_runner = _town.get("_month_runner")
		var stall_id := "-"
		var stall_walk := false
		if stall_runner != null:
			stall_id = String((stall_runner.get("current") as Dictionary).get("id", ""))
			stall_walk = bool(stall_runner.get("waiting_walk"))
		var sig := phase + "|" + stall_id + "|" + str(stall_walk)
		if sig == _last_sig:
			_stall += 1
		else:
			_last_sig = sig
			_stall = 0
		if _stall >= 45:
			_stall = 0
			print("  ！卡住：%s 连着 %.1f 秒没动，替他放行（这一处要单独查）" % [sig, 45 * 0.06])
			var hb = _town.get("_month12_handbook")
			if hb != null and is_instance_valid(hb) and bool(hb.call("is_open")):
				hb.call("close")
			var inbox2 = _town.get("_month_phone_panel")
			if inbox2 != null and is_instance_valid(inbox2):
				inbox2.call("close_tutorial")
				inbox2.call("close_phone")
			if stall_runner != null and is_instance_valid(stall_runner):
				if bool(stall_runner.get("waiting_walk")):
					var here: Vector2 = _town.get("_month12_waypoint")
					if here.x > -90000.0:
						_town.get("_player").position = here
					stall_runner.call("on_walk_arrived")
				else:
					stall_runner.call("on_panel_closed")
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

