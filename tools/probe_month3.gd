extends Node

## 第 3 月节点探针：直接从第 3 月开跑，看节点是不是一根线走通。
## 重点看 F 段：水巷讲解卡 → 2 格 → 第一次给结果、第二次只给一句。
## 用法：<godot> --path <proj> --headless res://tools/probe_month3.tscn

var _town: Node
var _last := ""
var _activity_checked := false
var _shot_open := false
var _shot_choice := false
var _shot_card := false
var _shot_confirm := false
var _shot_revisit := false
var _dbg := false


func _ready() -> void:
	print("BOOT")
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.4).timeout
	print("TOWN_READY phase=", _town.get("_month12_phase"))
	var panel = _town.get("_story_event_panel")
	if panel != null and bool(panel.call("is_open")):
		panel.call("dismiss")
	await get_tree().create_timer(0.4).timeout
	print("START_MONTH3")
	# 探针直接从第 3 月开跑，左上角日期不会自己跳；先把它摆到第 3 月，
	# 否则截图里任务卡写着第 3 月、日期栏还停在第 1 月。
	_town.call("push_date", 3, "early", "morning")
	_town.call("_start_month_nodes", 3)
	print("STARTED")
	for i in 900:
		await get_tree().create_timer(0.05).timeout
		var runner = _town.get("_month_runner")
		var current: Dictionary = runner.get("current") if runner != null else {}
		var nid := String(current.get("id", ""))
		if nid != _last:
			_last = nid
			print("NODE %s (%s)" % [nid, String(current.get("nodeType", ""))])
			if nid == "M03_OPEN" and not _shot_open:
				_shot_open = true
				await get_tree().create_timer(0.9).timeout
				await _shot("m3_open_card")
		if String(_town.get("_month12_phase")) == "done":
			print("MONTH3_DONE")
			break
		if String(_town.get("_month12_phase")) == "close":
			_town.call("_on_month12_close_finished")
			await get_tree().create_timer(0.5).timeout
			continue
		# 讲解卡（水巷）：截一张，然后替玩家点「带我去」。
		var place_panel = _town.get("_month12_place_panel")
		if nid == "M03_ACTIVITY" and not _dbg:
			_dbg = true
			print("DBG place_open=%s story_open=%s phase=%s checked=%s type=%s wait=%s wp=%s" % [
				place_panel != null and bool(place_panel.call("is_open")),
				panel != null and bool(panel.call("is_open")),
				_town.get("_month12_phase"), _activity_checked,
				String(current.get("nodeType", "")), runner.get("waiting_walk"),
				_town.get("_month12_waypoint")])
		if place_panel != null and bool(place_panel.call("is_open")):
			if not _shot_card:
				_shot_card = true
				await get_tree().create_timer(0.5).timeout
				await _shot("m3_place_card")
				print("UNLOCK_CARD shown hooks=%s" % [JSON.stringify(_town.get("_pending_story_hooks"))])
			# 走「带我去」：门开完这个月之后，黄线应该直接铺到水巷门口。
			place_panel.call("_on_go_there", "C")
			await get_tree().create_timer(0.35).timeout
			continue
		if panel != null and bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				if nid == "E10" and not _shot_choice:
					_shot_choice = true
					await get_tree().create_timer(0.5).timeout
					await _shot("m3_e10_choices")
					continue
				panel.call("_on_choice_picked", "M12_E10" if nid == "E10" else "M12_E12", "A", 40)
			else:
				panel.call("_advance")
			continue
		if nid == "":
			continue
		var waypoint: Vector2 = _town.get("_month12_waypoint")
		if bool(runner.get("waiting_walk")) and waypoint.x > -90000.0:
			_town.get("_player").position = waypoint
			continue
		if String(current.get("nodeType", "")) == "activity" and not _activity_checked:
			_activity_checked = true
			print("ACTIVITY_OPEN generic=%s slots=%s total=%s ap=%s portals=%s" % [
				_town.get("_month12_activity_generic"),
				_town.get("_month12_slots_left"),
				_town.get("_month12_slots_total"),
				_town.get("_month12_ap_left"),
				(_town.get("_month12_place_portals") as Dictionary).keys()])
			var portals: Dictionary = _town.get("_month12_place_portals")
			var water := portals.get("m3_waterway") as Node2D
			print("DOOR m3_waterway exists=%s sealed=%s" % [water != null, water.sealed if water != null else true])
			print("NAV hook_zone=%s waypoint=%s door=%s" % [
				_town.get("_hook_nav_zone"), _town.get("_month12_waypoint"),
				water.position if water != null else Vector2.ZERO])
			# 走到水巷门口截一张：门亮着 + 屏幕下方那颗 E 写着去处名。
			if water != null:
				_town.get("_player").position = water.position + Vector2(0, 70)
				await get_tree().create_timer(0.45).timeout
				await _shot("m3_waterway_door")
			var place: Dictionary = _town.call("_month12_place_by_id", "m3_waterway")
			# 走真路：门口按 E → 水巷室内 → 右侧列表 → 确认页 → 结果页。
			_town.set("_month12_nearby_place", "m3_waterway")
			_town.call("_enter_month12_place")
			await get_tree().create_timer(0.7).timeout
			await _shot("m3_place_list")
			_town.call("_on_activity_selected", place)
			await get_tree().create_timer(0.4).timeout
			if not _shot_confirm:
				_shot_confirm = true
				await _shot("m3_place_confirm")
			_town.call("_on_month12_place_confirmed", "m3_waterway")
			await get_tree().create_timer(0.4).timeout
			print("FIRST_DONE slots=%s ap=%s visited=%s" % [
				_town.get("_month12_slots_left"), _town.get("_month12_ap_left"),
				_town.call("_month12_activity_visited", "m3_waterway")])
			var scene = _town.get("_weekend_scene_panel")
			if scene != null and bool(scene.call("is_open")):
				print("FIRST_LINES %s" % [scene.get("_lines")])
				scene.call("_finish")
			await get_tree().create_timer(0.5).timeout
			# 第二次：同一个地方，只给一句环境话；不扣点、不占格。
			_town.set("_month12_nearby_place", "m3_waterway")
			_town.call("_enter_month12_place")
			await get_tree().create_timer(0.6).timeout
			await _shot("m3_place_list_again")
			_town.call("_on_activity_selected", place)
			await get_tree().create_timer(0.4).timeout
			print("SECOND_DONE slots=%s ap=%s" % [
				_town.get("_month12_slots_left"), _town.get("_month12_ap_left")])
			scene = _town.get("_weekend_scene_panel")
			if scene != null and bool(scene.call("is_open")):
				print("SECOND_LINES %s" % [scene.get("_lines")])
				if not _shot_revisit:
					_shot_revisit = true
					await _shot("m3_place_revisit")
				scene.call("_finish")
			await get_tree().create_timer(0.5).timeout
			# 第二格：换个地方，第一次结算；两格用完自动翻月。
			var tool: Dictionary = _town.call("_month12_place_by_id", "m1_tool")
			_town.call("_on_activity_selected", tool)
			await get_tree().create_timer(0.4).timeout
			await _shot("m3_place_confirm_tool")
			_town.call("_on_month12_place_confirmed", "m1_tool")
			await get_tree().create_timer(0.4).timeout
			print("THIRD_DONE slots=%s ap=%s visited=%s" % [
				_town.get("_month12_slots_left"), _town.get("_month12_ap_left"),
				_town.call("_month12_activity_visited", "m1_tool")])
			scene = _town.get("_weekend_scene_panel")
			if scene != null and bool(scene.call("is_open")):
				print("THIRD_LINES %s" % [scene.get("_lines")])
				scene.call("_finish")
			await get_tree().create_timer(0.7).timeout
			continue
	print("PROBE_ENDED phase=%s month=%s flags=%s" % [
		_town.get("_month12_phase"), _town.get("_month12_month"),
		JSON.stringify(_town.get("_month12_flags"))])
	get_tree().quit(0)


func _shot(name: String) -> void:
	# --headless 的哑渲染器不发 frame_post_draw：在这里等会永远等下去。
	if DisplayServer.get_name() == "headless":
		print("shot skipped (headless) %s" % name)
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://test_artifacts/v12m_month3/%s.png" % name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/v12m_month3"))
	print("shot %s -> %s" % [name, image.save_png(path)])
