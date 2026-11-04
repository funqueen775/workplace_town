extends Node

const MAIN_SCENE := preload("res://Main.tscn")
const MONTH_REPORT := preload("res://scripts/v12m/Month12Report.gd")
const REPORT_BACKGROUND := preload("res://assets/报告页/drawing-帮我做一个测评报告页的底图-我们里面要添加如图所示的元素-后面两张是我们测评游戏里面的角色-可以-1.png")


func _ready() -> void:
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	for frame in 15:
		await get_tree().process_frame
	if not bool(town.get("_month12_active")):
		_fail("十二个月流程未激活")
		return
	var open_zones: Dictionary = town.get("_month12_open_zones")
	if open_zones.keys().size() != 2 or not open_zones.has("A") or not open_zones.has("B"):
		_fail("开局应只开放市场部和研发部")
		return
	var initial_doors: Dictionary = town.get("_month12_place_portals")
	if not initial_doors.has("zone_A") or not initial_doors.has("zone_B") or initial_doors.keys().size() != 2:
		_fail("开局应有市场部和研发部入口，且没有活动区域入口")
		return
	var tour: Array = town.get("MONTH12_TOUR")
	var tour_route: Array = []
	for stop in tour:
		tour_route.append(String((stop as Dictionary).get("zone", "")))
	if tour_route != ["B", "A", "C", "G", "B"]:
		_fail("首月带巡不符合五站路线")
		return
	var activities: Array = town.get("_month12_places")
	for value in activities:
		var activity := value as Dictionary
		var code := String(activity.get("locationId", ""))
		if code in ["A", "B"] or String((activity.get("portal", {}) as Dictionary).get("zoneId", "")) != code:
			_fail("自由活动只能挂在 C-H 的正式区域门")
			return
	for code in ["C", "D", "G"]:
		town.call("_open_month12_zone", code)
	town.call("_open_month12_places")
	var unlocked: Dictionary = town.get("_month12_unlocked_places")
	if unlocked.keys().size() != 3 or not unlocked.has("m1_tool") or not unlocked.has("m1_rooftop") or not unlocked.has("m1_lakeside"):
		_fail("E02 后应只开放 C/D/G 三项首月活动")
		return
	var d_portal: Node2D
	for activity_id in (town.get("_month12_place_portals") as Dictionary):
		var activity: Dictionary = town.call("_month12_place_by_id", String(activity_id))
		if String(activity.get("locationId", "")) == "D":
			d_portal = (town.get("_month12_place_portals") as Dictionary)[activity_id] as Node2D
			break
	if d_portal == null:
		_fail("人事部活动入口没有生成")
		return
	var d_portal_was_sealed := bool(d_portal.get("sealed"))
	var portal_count_before_story_visit := (town.get("_month12_place_portals") as Dictionary).size()
	town.call("_open_story_door", "door_library")
	if town.get("_story_door") != d_portal or not bool(town.get("_story_door_reused")) \
			or (town.get("_month12_place_portals") as Dictionary).size() != portal_count_before_story_visit:
		_fail("旧档案架剧情门没有复用附近的人事部入口：story=%s reused=%s distance=%.1f portals=%d/%d" % [
			str(town.get("_story_door") == d_portal), str(town.get("_story_door_reused")),
			(d_portal.position.distance_to(Vector2(1424, 720)) if d_portal != null else -1.0),
			(town.get("_month12_place_portals") as Dictionary).size(), portal_count_before_story_visit,
		])
		return
	town.call("_retire_story_door")
	if not is_instance_valid(d_portal) or bool(d_portal.get("sealed")) != d_portal_was_sealed:
		_fail("收起剧情门时没有保留并恢复人事部入口状态")
		return
	var saved_runner = town.get("_month_runner")
	var saved_visit_id := String(town.get("_month12_visit_id"))
	var saved_generic := bool(town.get("_month12_activity_generic"))
	var saved_taken := bool(town.get("_month12_activity_taken"))
	town.set("_month_runner", null)
	town.set("_month12_visit_id", "")
	town.set("_month12_activity_generic", false)
	town.set("_month12_activity_taken", false)
	town.call("_on_activity_selected", town.call("_month12_place_by_id", "m1_rooftop"))
	if not bool(town.get("_month12_place_panel").call("is_open")) \
			or bool(town.get("_weekend_scene_panel").call("is_open")):
		_fail("点击活动卡应先显示确认页，不应预先播放活动旁白")
		return
	town.get("_month12_place_panel").call("close")
	var activity_cards: Node = town.get("_activity_cards")
	activity_cards.call("open", "人事部", [
		{"id": "sample_one", "title": "露台吹风", "note": "暂时歇一会儿。"},
		{"id": "sample_two", "title": "同事交流", "note": "聊聊最近的工作。"},
	], "本月还剩 1 格")
	var activity_hint := activity_cards.find_child("ActivityHint", true, false) as Label
	if activity_hint == null or not activity_hint.text.contains("露台吹风") \
			or not activity_hint.text.contains("NPC") or not activity_hint.text.contains("先看说明"):
		_fail("活动列表没有说明本区域可做的活动和确认流程")
		return
	activity_cards.call("close")
	town.set("_month_runner", saved_runner)
	town.set("_month12_visit_id", saved_visit_id)
	town.set("_month12_activity_generic", saved_generic)
	town.set("_month12_activity_taken", saved_taken)
	town.call("_open_month12_zone", "F")
	if not bool((town.get("_month12_open_zones") as Dictionary).get("F", false)) or unlocked.has("m5_stage"):
		_fail("Demo 前应能进运营部，但演示复盘尚未开放")
		return
	town.call("_queue_unlock_after_cards", "M05_DEMO")
	if not unlocked.has("m5_stage") or not unlocked.has("m5_umbrella"):
		_fail("Demo 后应开放运营部两项活动")
		return
	if bool((town.get("_month12_open_zones") as Dictionary).get("E", false)) or unlocked.has("m7_lawn"):
		_fail("小赵邀请前不应开放财务部活动")
		return
	town.call("_open_month12_zone", "E")
	town.call("_queue_unlock_after_cards", "M07_SPORTS_INVITE")
	if not unlocked.has("m7_lawn") or not unlocked.has("m_grind"):
		_fail("第 7 月邀请后应开放团队运动和资料赶工")
		return
	if bool((town.get("_month12_open_zones") as Dictionary).get("H", false)) or unlocked.has("m11_boardgame"):
		_fail("第 11 月说明名额前不应开放生产部")
		return
	town.call("_open_month12_zone", "H")
	town.call("_queue_unlock_after_cards", "M11_OPEN")
	if not unlocked.has("m11_boardgame"):
		_fail("第 11 月说明名额后应开放桌游交流")
		return
	var doors: Dictionary = town.get("_month12_place_portals")
	for code in ["C", "D", "E", "F", "G", "H"]:
		var count := 0
		for activity_id in doors.keys():
			var activity: Dictionary = town.call("_month12_place_by_id", String(activity_id))
			if String(activity.get("locationId", "")) == code:
				count += 1
		if count != 1:
			_fail("开放后每个活动区域只能有一扇入口：%s" % code)
			return
	var zones: Array = town.get("ZONES")
	if zones.size() != 8:
		_fail("区域数量不是八个")
		return
	var zone: Dictionary = zones[0]
	town.call("_enter_month12_interior", zone)
	await get_tree().process_frame
	var interior: Node = town.get("_interior_preview")
	if interior == null or not interior.call("is_open"):
		_fail("十二个月入口没有打开部门室内")
		return
	var scene: Control = interior.get("_scene")
	var room: TextureRect = scene.get_child(0) as TextureRect
	var player: Node2D = interior.get("_player")
	if room.texture == null or room.texture.get_size().y != 851 or player.position.y != 700.0:
		_fail("部门室内没有使用原八区地图和横路")
		return
	if not interior.get("_horizontal_only") or not interior.get("_door_x_threshold") == 1600.0:
		_fail("右侧出口没有按原流程限制距离")
		return
	town.call("_exit_zone")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/manifest.json"))
	for month in [3, 5, 7, 9, 11]:
		if int((manifest.get("apByMonth", {}) as Dictionary).get(str(month), 0)) != 3:
			_fail("自由安排月份没有三点行动力")
			return
	town.set("_month12_month", 3)
	town.call("runner_open_activity", {"budget": {"ap": 3, "slots": 3}, "activityIds": ["m1_rooftop"]})
	if int(town.get("_month12_ap_left")) != 3 or int(town.get("_month12_slots_left")) != 3:
		_fail("自由安排没有发放三点行动力")
		return
	var hud: Node = town.get("_town_ui_v2")
	var energy_label: Label = hud.get("_energy_label")
	if energy_label.text != "行动力  3/3":
		_fail("顶部没有显示行动力 3/3")
		return
	var handoff_hint := hud.find_child("ActivityHandoffHint", true, false) as Label
	if handoff_hint == null or not handoff_hint.visible or not handoff_hint.text.contains("人事部") \
			or not handoff_hint.text.contains("书院露台吹风"):
		_fail("活动交接没有在行动力下方指明区域和活动")
		return
	var energy_panel: Control = hud.get("_energy_panel")
	if handoff_hint.position.y < energy_panel.position.y + energy_panel.size.y:
		_fail("活动交接提示没有放在行动力条下方")
		return
	town.set("_month12_month", 11)
	town.set("_month12_ap_left", 1)
	town.call("_on_month12_place_confirmed", "m11_reproduce")
	if int(town.get("_month12_ap_left")) != 1 or bool((town.get("_month12_flags") as Dictionary).get("visit_11_m11_reproduce", false)):
		_fail("两点活动不能在只剩一点行动力时结算")
		return
	town.set("_month12_month", 7)
	(town.get("_month12_flags") as Dictionary)["probation_ended"] = true
	town.call("_continue_after_month_close", 7)
	await get_tree().process_frame
	var report: CanvasLayer = town.get("_report_panel")
	if report == null or not report.visible or REPORT_BACKGROUND.get_size().x < 100:
		_fail("第 7 月提前结束没有进入原报告页")
		return
	var early_data: Dictionary = MONTH_REPORT.new().build(town)
	if String(early_data.get("pageTitle", "")) != "截至第 7 月的报告":
		_fail("提前结束报告不应写成完整年度")
		return
	report.call("close")
	town.set("_month12_month", 12)
	town.call("_continue_after_month_close", 12)
	await get_tree().process_frame
	if not report.visible:
		_fail("第 12 月结束没有进入原报告页")
		return
	report.call("close")
	town.set("_month12_month", 1)
	town.set("_month12_phase", "tour_panel")
	town.call("_sync_skip_controls")
	var tour_skip := hud.get("_skip_tour_button") as Button
	var month_skip := hud.get("_skip_month_button") as Button
	if tour_skip == null or not tour_skip.visible or month_skip == null or not month_skip.visible:
		_fail("首月带巡时没有显示对应的跳过入口")
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if month_skip.position.y > 30.0 or month_skip.position.x + month_skip.size.x > viewport_size.x:
		_fail("跳过本月按钮没有放在页面右上角")
		return
	tour_skip.pressed.emit()
	var skip_dialog: Node = hud.get("_skip_confirmation")
	var skip_warning := skip_dialog.find_child("WarningText", true, false) as Label if skip_dialog != null else null
	if skip_dialog == null or not skip_dialog.visible or skip_warning == null or not skip_warning.text.contains("五站"):
		_fail("跳过带巡没有显示确认说明")
		return
	(skip_dialog.find_child("ConfirmButton", true, false) as Button).pressed.emit()
	town.call("_sync_skip_controls")
	if not bool((town.get("_month12_flags") as Dictionary).get("m01_tour_skipped", false)) \
			or not bool((hud.get("_phone_button") as Button).visible) or String(town.get("_month12_phase")) != "handbook":
		_fail("跳过带巡后没有交付手机并衔接手册")
		return
	if tour_skip.visible:
		_fail("离开带巡后跳过带巡按钮仍可见")
		return
	town.set("_month12_month", 7)
	town.set("_month12_phase", "month_nodes")
	(town.get("_month12_flags") as Dictionary)["probation_ended"] = true
	town.call("_sync_skip_controls")
	if not month_skip.visible:
		_fail("第七月仍应显示全局跳过本月入口")
		return
	month_skip.pressed.emit()
	skip_dialog = hud.get("_skip_confirmation")
	var skip_detail := skip_dialog.find_child("DetailText", true, false) as Label if skip_dialog != null else null
	if skip_dialog == null or not skip_dialog.visible or skip_detail == null or not skip_detail.text.contains("未经历的内容"):
		_fail("跳过本月没有说明记录规则")
		return
	(skip_dialog.find_child("ConfirmButton", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	if not report.visible or not bool((town.get("_month12_flags") as Dictionary).get("m07_story_skipped", false)):
		_fail("第七月跳过没有保留提前结束报告逻辑")
		return
	town.set("_month12_month", 12)
	town.set("_month12_phase", "month_nodes")
	town.call("_sync_skip_controls")
	if month_skip.visible:
		_fail("第十二月没有下个月，跳过本月按钮应隐藏")
		return
	print("TWELVE_MONTH_INTEGRATION_PASS months=12 interiors=8 report=original")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("TWELVE_MONTH_INTEGRATION_FAIL " + message)
	get_tree().quit(1)
