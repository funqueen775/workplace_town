extends Node
## 十二个月首月全流程探针：不靠人操作，按阶段把 A→G 跑一遍。
## 用法：<godot> --path <PROJ> --headless res://tools/probe_month_opening.tscn

var _town: Node
var _panel
var _generic_queue: Array = []


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.2).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	print("START phase=%s" % _town.get("_month12_phase"))
	var last_phase := ""
	for i in 20000:
		await get_tree().create_timer(0.03).timeout
		var phase := String(_town.get("_month12_phase"))
		if phase != last_phase:
			print("PHASE %s" % phase)
			last_phase = phase
		# 一路跑到第 12 月收束才算完。
		if phase == "done" and int(_town.get("_month12_month")) >= 12:
			break
		# 四角导览：替玩家点下一步
		var start_card = _town.get("_month12_start_panel")
		if start_card != null and bool(start_card.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.2).timeout
			continue
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		# 手机讲解卡：替玩家点「稍后」，避免挡着后续流程
		var tutorial = _town.get("_month_phone_tutorial")
		if tutorial != null and bool(tutorial.get("_card").visible):
			tutorial.call("close_tutorial")
			await get_tree().create_timer(0.3).timeout
			continue
		# 地点讲解卡（第 3 月水巷）：替玩家点「知道了」，卡关掉节点才继续。
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			await get_tree().create_timer(0.3).timeout
			continue
		# 走到点位：直接把人挪过去，等 _update_month12_waypoint 触发
		if phase == "tour" or phase == "e02_walk" or phase == "node_walk" or phase == "sleep_walk":
			var waypoint: Vector2 = _town.get("_month12_waypoint")
			if waypoint.x > -90000.0:
				_town.get("_player").position = waypoint
			continue
		# 剧情那一眼（第 2 月的图书馆）：替他走到门口、按 E、点屋里那一行。
		var visit_id := String(_town.get("_month12_visit_id"))
		if not visit_id.is_empty():
			print("VISIT %s door=%s" % [visit_id, _town.get("_story_door")])
			var door = _town.get("_story_door")
			if door != null:
				_town.get("_player").position = (door as Node2D).position
			await get_tree().create_timer(0.12).timeout
			_town.call("_begin_interaction")
			await get_tree().create_timer(0.25).timeout
			var place: Dictionary = _town.call("_month12_visit_place")
			if not place.is_empty():
				_town.call("_on_activity_selected", place)
			continue
		# 面板推进 / 选择
		if _panel != null and _panel.is_open():
			var stage := String(_panel.get("_stage"))
			if phase == "tour_panel" and i % 40 == 0:
				print("  TOUR_PANEL open=%s stage=%s beat=%s" % [_panel.is_open(), stage, _panel.get("_beat_index")])
			if stage == "choices":
				var event_data: Dictionary = _panel.get("_event")
				_panel.call("_on_choice_picked", String(event_data.get("id", "M12_E02")), "A", 45)
			elif stage == "interaction" or stage == "handbook":
				pass
			else:
				_panel.call("_advance")
			continue
		# 手册：打开后合上
		if phase == "handbook":
			var handbook = _town.get("_month12_handbook")
			if handbook != null and handbook.is_open():
				handbook.call("close")
			continue
		# 自由安排：F 段到访制。首月一格做完就翻月；通用月份按格数一处一处做。
		if phase == "activity":
			if bool(_town.get("_month12_activity_generic")):
				# 每个活动节点开局（格子满）重建一遍去处，别拿上个月的队列尾巴。
				if int(_town.get("_month12_slots_left")) == int(_town.get("_month12_slots_total")):
					_generic_queue = ["m1_tool", "m1_rooftop", "m1_lakeside"]
				var slots: int = int(_town.get("_month12_slots_left"))
				# 格子用完会自动翻月；还剩格子又没处可去时替玩家点"结束这个月"。
				if slots <= 0 or _generic_queue.is_empty():
					_town.call("_on_end_month_pressed")
					continue
				_town.call("_on_month12_place_confirmed", String(_generic_queue.pop_front()))
				_town.call("_on_weekend_scene_finished")
				continue
			_town.call("_on_month12_place_confirmed", "m1_tool")
			_town.call("_on_weekend_scene_finished")
			continue
		# 月末：继续
		if phase == "close":
			_town.call("_on_month12_close_finished")
			continue
	var e02 := String(_town.get("_month12_e02_choice"))
	var flags: Dictionary = _town.get("_month12_flags")
	var save_text := FileAccess.get_file_as_string("user://workplace_town_month12.json")
	print("RESULT phase=%s e02=%s flags=%s save=%s" % [
		_town.get("_month12_phase"), e02, JSON.stringify(flags), save_text.strip_edges().replace("\n", " ")])
	get_tree().quit()