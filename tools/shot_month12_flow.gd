extends Control
## 12 个月首月关键屏截图：带巡黄线 / A 区对话 / 手机红点 / 手册 1.1-1.2 /
## E02 选择 / 自由安排 / 月末回顾。用法同 shot_month_opening。

var _dir := "user://month12_flow"
var _shot_flags := {}


func _once(key: String) -> bool:
	if _shot_flags.has(key):
		return false
	_shot_flags[key] = true
	return true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	img.save_png(path)
	print("[shot] ", path)



## 按按钮上的字找按钮：月末卡上的「打开档案」没有对外接口，截图工具自己找。
func _find_button(node: Node, label: String) -> Button:
	for child in node.get_children():
		if child is Button and (child as Button).text == label:
			return child
		var found := _find_button(child, label)
		if found != null:
			return found
	return null

func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	var last_phase := ""
	var place_shot := 0

	# 月末现在会先播一段换月过场，循环预算得留够，否则跑到 30_close 就断了。
	for i in 1500:
		await get_tree().create_timer(0.05).timeout
		var phase := String(town.get("_month12_phase"))
		if phase != last_phase:
			last_phase = phase
			# 关键阶段各停一拍截图
			match phase:
				"e01_panel":
					await get_tree().create_timer(0.5).timeout
					if not FileAccess.file_exists(_dir + "/19_e01_opening.png"):
						await _shot("19_e01_opening")
				"tour":
					var player: Node2D = town.get("_player")
					if player.position.distance_to(Vector2(700, 500)) > 4.0 and bool(town.get("_hud_tour_done")):
						player.position = Vector2(700, 500)
						await get_tree().create_timer(0.5).timeout
						if not FileAccess.file_exists(_dir + "/20_tour_line.png"):
							await _shot("20_tour_line")
				"handbook":
					await get_tree().create_timer(0.5).timeout
					await _shot("24_handbook_11")
					var handbook = town.get("_month12_handbook")
					if handbook != null:
						handbook.call("_select_chapter", "1.2")
						await get_tree().create_timer(0.3).timeout
						await _shot("25_handbook_12")
				"activity":
					await get_tree().create_timer(0.5).timeout
					await _shot("28_activity")
				"close":
					# 月末卡现在要等入夜那道光刷完才开，多等一拍再截，否则截到的是过场。
					await get_tree().create_timer(2.0).timeout
					await _shot("30_close")
		var tutorial = town.get("_month_phone_tutorial")
		if tutorial != null and bool(tutorial.get("_card").visible) and not FileAccess.file_exists(_dir + "/23_phone_tutorial.png"):
			# 手机讲解卡：先截图，再走「打开手机」这条线进真手机
			await get_tree().create_timer(0.4).timeout
			await _shot("23_phone_tutorial")
			tutorial.call("open_phone")
			await get_tree().create_timer(0.7).timeout
			await _shot("22_phone")
			var drawer = town.get("_month_phone_panel")
			if drawer != null:
				drawer.call("close_phone")
			else:
				town.get("_town_ui_v2").call("close_view")
			await get_tree().create_timer(0.3).timeout
			continue
		if phase == "done":
			if _once("31_done_shot"):
				await get_tree().create_timer(0.4).timeout
				await _shot("31_done")
			# 第 1、2 月收束后会直接进下一个月；跑到第 3 月也收束才算完。
			if int(town.get("_month12_month")) >= 3:
				break
			continue
		var place_panel = town.get("_month12_place_panel")
		if place_panel != null and bool(place_panel.call("is_open")):
			# 解锁讲解卡：截一张就走，别让它盖住后面的画面。
			place_shot += 1
			await get_tree().create_timer(0.35).timeout
			await _shot("21a_place_card_%d" % place_shot)
			# 走玩家点「知道了」那条路：面板自己发 unlock_dismissed，城镇再放行下一屏。
			place_panel.call("_on_unlock_ok", "")
			if place_shot == 1:
				# 卡合上这一拍玩家正站在这扇门前面——顺手截一张"门立着、封条贴着"。
				await get_tree().create_timer(0.35).timeout
				await _shot("21d_door_sealed")
			continue
		if bool(town.get("_hud_tour_active")):
			town.get("_hud_tour").call("advance")
			continue
		if phase == "tour" or phase == "e02_walk" or phase == "node_walk":
			var waypoint: Vector2 = town.get("_month12_waypoint")
			if waypoint.x > -90000.0:
				# 先把这一段的路画下来，再把人瞬移到点上看下一段。
				var leg := "20_line_%s%d" % [phase, int(town.get("_month12_tour_index"))]
				if _once(leg):
					await get_tree().create_timer(0.35).timeout
					await _shot(leg)
				town.get("_player").position = waypoint
			continue
		if panel != null and panel.is_open():
			var stage := String(panel.get("_stage"))
			if phase == "e01_panel":
				# 说明会的三个关键拍：陈工交代跟谁走 / 小赵自报 / 王哥自报。
				var e01_beat := int(panel.beat_index())
				if e01_beat == 1 and _once("19a_chen_boss"):
					await get_tree().create_timer(0.2).timeout
					await _shot("19a_chen_boss")
				elif e01_beat == 3 and _once("19e_emphasis"):
					await get_tree().create_timer(0.2).timeout
					await _shot("19e_emphasis")
				elif e01_beat == 7 and _once("19b_chen_group"):
					await get_tree().create_timer(0.2).timeout
					await _shot("19b_chen_group")
				elif e01_beat == 9 and _once("19c_intro_xiaozhao"):
					await get_tree().create_timer(0.2).timeout
					await _shot("19c_intro_xiaozhao")
				elif e01_beat == 10 and _once("19d_intro_wang"):
					await get_tree().create_timer(0.2).timeout
					await _shot("19d_intro_wang")
			if phase == "e02_panel" and int(panel.beat_index()) == 0 and _once("26a_e02_narration"):
				await get_tree().create_timer(0.2).timeout
				await _shot("26a_e02_narration")
			if phase == "tour_panel" and int(town.get("_month12_tour_index")) == 0:
				# A 区停靠点：0 引路 / 1 这栋楼的功能 / 2 王哥递手机 / 3 红点。
				var tour_beat := int(panel.beat_index())
				if tour_beat == 1 and _once("21b_a_gate_function"):
					await get_tree().create_timer(0.2).timeout
					await _shot("21b_a_gate_function")
				elif tour_beat == 2 and _once("21c_phone_handoff"):
					await get_tree().create_timer(0.2).timeout
					await _shot("21c_phone_handoff")
			if phase == "tour_panel" and int(town.get("_month12_tour_index")) == 0 \
					and not FileAccess.file_exists(_dir + "/21_tour_a.png") and stage in ["narration", "say"]:
				await get_tree().create_timer(0.2).timeout
				await _shot("21_tour_a")
			if stage in ["narration", "say"] and String((panel.get("_event") as Dictionary).get("id", "")) == "M12_M02_OPEN" 					and not FileAccess.file_exists(_dir + "/33_m02_open.png"):
				await get_tree().create_timer(0.25).timeout
				await _shot("33_m02_open")
			if stage in ["narration", "say"] and String((panel.get("_event") as Dictionary).get("id", "")) == "M12_M03_OPEN" 					and not FileAccess.file_exists(_dir + "/37_m03_open.png"):
				await get_tree().create_timer(0.25).timeout
				await _shot("37_m03_open")
			if stage == "choices":
				var event_id := String((panel.get("_event") as Dictionary).get("id", ""))
				if event_id == "M12_M02_OPEN" and not FileAccess.file_exists(_dir + "/33_m02_open.png"):
					await get_tree().create_timer(0.25).timeout
					await _shot("33_m02_open")
				elif event_id == "M12_E04":
					await get_tree().create_timer(0.25).timeout
					await _shot("34_e04_choices")
					panel.call("_on_choice_picked", event_id, "A", 45)
					await get_tree().create_timer(0.5).timeout
					await _shot("34b_e04_outcome")
				elif event_id == "M12_E10":
					await get_tree().create_timer(0.25).timeout
					await _shot("38_e10_choices")
					panel.call("_on_choice_picked", event_id, "A", 45)
					await get_tree().create_timer(0.5).timeout
					await _shot("38b_e10_outcome")
				elif event_id == "M12_E12":
					await get_tree().create_timer(0.25).timeout
					await _shot("39_e12_choices")
					panel.call("_on_choice_picked", event_id, "A", 45)
					await get_tree().create_timer(0.5).timeout
					await _shot("39b_e12_outcome")
				elif event_id == "M12_E03":
					await get_tree().create_timer(0.25).timeout
					await _shot("35_e03_choices")
					panel.call("_on_choice_picked", event_id, "A", 45)
					await get_tree().create_timer(0.5).timeout
					await _shot("35b_e03_outcome")
				else:
					await get_tree().create_timer(0.2).timeout
					await _shot("26_e02_choices")
					panel.call("_on_choice_picked", event_id, "A", 45)
					await get_tree().create_timer(0.4).timeout
					await _shot("27_e02_outcome")
			else:
				panel.call("_advance")
			continue
		if phase == "handbook":
			var hb = town.get("_month12_handbook")
			if hb != null and hb.is_open():
				hb.call("close")
			continue
		if phase == "activity":
			# 到访制：封条已撕。走到门前按 E → 进室内 → 右边列活动 → 点一项才给确认页。
			var portals: Dictionary = town.get("_month12_place_portals")
			if portals.is_empty():
				continue
			if not FileAccess.file_exists(_dir + "/28_doors.png"):
				await _shot("28_doors")
				var first := portals.values()[0] as Node2D
				town.get("_player").position = first.position + Vector2(0, 40)
				await get_tree().create_timer(0.3).timeout
				town.call("_begin_interaction")
				await get_tree().create_timer(0.7).timeout
				await _shot("28b_inside_list")
				town.call("_on_activity_selected", {"id": "m1_rooftop", "title": "天台休息"})
				await get_tree().create_timer(0.5).timeout
				await _shot("29_place_confirm")
				town.call("_on_month12_place_confirmed", "m1_rooftop")
				await get_tree().create_timer(1.0).timeout
				await _shot("29b_place_outcome")
				var weekend = town.get("_weekend_scene_panel")
				if weekend != null:
					weekend.visible = false
				# 湖边那张图地板位置不一样，真机走一眼确认下移后的框没把人放到水裡。
				var lake_zone: Dictionary = town.call("_zone_by_code", "E")
				if not lake_zone.is_empty():
					town.call("_enter_month12_interior", lake_zone, "res://assets/weekend_scenes/lakeside_day.png")
					await get_tree().create_timer(0.6).timeout
					await _shot("29c_lakeside_inside")
					town.call("_exit_zone")
				town.call("_start_month12_close")
			continue
		if phase == "close":
			# 卡还没开（在等过场）就别替玩家点继续，否则月末卡会被跳过去。
			var close_panel = town.get("_month12_close_panel")
			if close_panel != null and bool(close_panel.get("_root").visible):
				if int(town.get("_month12_month")) == 2 and not FileAccess.file_exists(_dir + "/36_m02_close.png"):
					await get_tree().create_timer(0.4).timeout
					await _shot("36_m02_close")
				if int(town.get("_month12_month")) >= 3 and not FileAccess.file_exists(_dir + "/40_m03_close.png"):
					await get_tree().create_timer(0.4).timeout
					await _shot("40_m03_close")
				if int(town.get("_month12_month")) <= 1 and not FileAccess.file_exists(_dir + "/30b_archive_page.png"):
					await get_tree().create_timer(0.4).timeout
					var archive_btn := _find_button(close_panel, "打开档案")
					if archive_btn != null:
						archive_btn.pressed.emit()
						await get_tree().create_timer(0.6).timeout
						await _shot("30b_archive_page")
						town.get("_town_ui_v2").call("close_view")
						await get_tree().create_timer(0.4).timeout
						await _shot("30c_close_back")
				town.call("_on_month12_close_finished")
			continue
	print("SHOTS DONE, phase=", town.get("_month12_phase"))
	get_tree().quit()