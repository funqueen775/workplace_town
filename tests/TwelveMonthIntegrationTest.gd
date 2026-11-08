extends Node

const MAIN_SCENE := preload("res://Main.tscn")
const MONTH_REPORT := preload("res://scripts/v12m/Month12Report.gd")
const REPORT_BACKGROUND := preload("res://assets/报告页/drawing-帮我做一个测评报告页的底图-我们里面要添加如图所示的元素-后面两张是我们测评游戏里面的角色-可以-1.png")
const HEART_FULL := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/关系_实心爱心.png")
const HEART_EMPTY := preload("res://assets/ui/rework_v1/profile/components/03_人际关系/关系_空爱心.png")


func _ready() -> void:
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	for frame in 15:
		await get_tree().process_frame
	if not bool(town.get("_month12_active")):
		_fail("十二个月流程未激活")
		return
	var initial_hud: Node = town.get("_town_ui_v2")
	var initial_mood_panel: Control = initial_hud.get("_mood_panel")
	if initial_mood_panel.visible or bool(town.call("_is_mood_meter_unlocked", 1)):
		_fail("第一月不应显示或解锁心情面板")
		return
	if not bool(town.call("_is_mood_meter_unlocked", 2)):
		_fail("心情面板应从第二月开始解锁")
		return
	initial_hud.call("set_mood_visible", true)
	if not initial_mood_panel.visible:
		_fail("心情面板解锁后没有显示")
		return
	initial_hud.call("set_mood_visible", false)
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
	var event_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	var demo_node: Dictionary = {}
	for event_value in event_data.get("nodes", []):
		if String((event_value as Dictionary).get("id", "")) == "M05_DEMO":
			demo_node = event_value
			break
	if demo_node.is_empty():
		_fail("缺少第五个月客户 Demo 剧情节点")
		return
	town.call("_arm_month12_place_visit", demo_node, "m5_expo")
	var story_visit_panel: Node = town.get("_month12_place_panel")
	if story_visit_panel.call("is_open"):
		story_visit_panel.call("close")
	town.set("_month12_month", 5)
	town.set("_month12_nearby_place", "m5_expo")
	town.call("_enter_month12_place")
	var activity_panel: Node = town.get("_activity_panel")
	var visit_rows: Array = activity_panel.get("_activities")
	if not bool(town.get("_interior_preview").call("is_open")) or not bool(activity_panel.get("_root").visible) \
			or visit_rows.size() != 1 or String((visit_rows[0] as Dictionary).get("id", "")) != "m5_expo":
		_fail("第五个月进入运营部后没有显示客户 Demo 剧情入口")
		return
	var activity_root := activity_panel.get("_root") as Control
	var panel_floor := get_viewport().get_visible_rect().size.y - activity_root.size.y - 14.0
	if activity_root.position.y > maxf(120.0, panel_floor - 70.0):
		_fail("第五个月活动面板没有上移，仍可能与右下角 HUD 重叠")
		return
	town.call("_on_activity_selected", town.call("_month12_visit_place"))
	if not String(town.get("_month12_visit_id")).is_empty() or String(town.get("_story_event").get("id", "")) != "M12_M05_DEMO":
		_fail("第五个月点击运营部剧情入口后没有继续播放客户 Demo")
		return
	var story_panel: Node = town.get("_story_event_panel")
	if story_panel.call("is_open"):
		story_panel.call("dismiss")
	town.call("_exit_zone")
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
	for month in [3, 5, 9, 11]:
		if int((manifest.get("apByMonth", {}) as Dictionary).get(str(month), 0)) != 1:
			_fail("普通自由安排月份应只有一点行动力")
			return
	if int((manifest.get("apByMonth", {}) as Dictionary).get("7", 0)) != 3:
		_fail("第七月熊熊有招应保留三点行动力")
		return
	var valley: Dictionary = town.call("_month12_place_by_id", "m7_valley")
	if int(valley.get("apCost", 0)) != 3 or int(valley.get("slots", 0)) != 1:
		_fail("熊熊有招应消耗 3 点行动力、占用 1 个活动名额")
		return
	town.set("_month12_month", 3)
	town.call("runner_open_activity", {"budget": {"ap": 1, "slots": 1}, "activityIds": ["m1_rooftop"]})
	if int(town.get("_month12_ap_left")) != 1 or int(town.get("_month12_slots_left")) != 1:
		_fail("普通自由安排应只发放一点行动力和一个活动名额")
		return
	var hud: Node = town.get("_town_ui_v2")
	var mood_panel: Control = hud.get("_mood_panel")
	var energy_label: Label = hud.get("_energy_label")
	if energy_label.text != "行动力  1/1":
		_fail("普通自由安排没有正确显示一点行动力")
		return
	var energy_panel: Control = hud.get("_energy_panel")
	var place_panel: Node = town.get("_month12_place_panel")
	if energy_panel.visible or not place_panel.call("is_open"):
		_fail("行动力说明卡关闭前应先隐藏行动力")
		return
	var intro_labels: Array[Node] = place_panel.find_children("*", "Label", true, false)
	var intro_text := ""
	for label in intro_labels:
		intro_text += (label as Label).text + "\n"
	if not intro_text.contains("行动力说明") or not intro_text.contains("用完后才能继续主线") \
			or not intro_text.contains("不必跟路线") or not intro_text.contains("A、B区"):
		_fail("首次行动力说明没有讲清用途、推进条件和区域选择")
		return
	place_panel.call("close")
	town.call("_on_place_unlock_dismissed", "action_points_intro")
	if not place_panel.call("is_open") or energy_panel.visible:
		_fail("行动力说明关闭后应继续展示区域活动卡，并保持行动力隐藏")
		return
	place_panel.call("close")
	town.call("_on_place_unlock_dismissed", "m1_rooftop")
	var handoff_guide: Panel = hud.find_child("ActivityGuideBanner", true, false) as Panel
	var guide_title: Label = hud.get("_activity_guide_title")
	var guide_note: Label = hud.get("_activity_guide_note")
	if not energy_panel.visible or handoff_guide == null or not handoff_guide.visible \
			or not guide_note.text.contains("人事部") or not guide_note.text.contains("书院露台吹风") \
			or not guide_note.text.contains("行政部") or not guide_note.text.contains("夜间值守与资料整理") \
			or not guide_note.text.contains("销售部") or not guide_note.text.contains("湖边散步"):
		_fail("说明卡关闭后应列出当前可参加的活动")
		return
	if handoff_guide.position.y < energy_panel.position.y + energy_panel.size.y \
		or not guide_title.text.contains("剩余 1 点"):
		_fail("行动指引没有显示在行动力下方或剩余点数不正确")
		return
	if int(town.get("_month12_waypoint").x) > -90000 or String(hud.get("_task_note").text).contains("跟着黄线"):
		_fail("自由活动不应锁定单一路线目标")
		return
	hud.call("set_activity_scene_mode", true)
	if handoff_guide.visible:
		_fail("进入小场景后应隐藏顶部活动指引牌")
		return
	hud.call("set_activity_scene_mode", false)
	if not handoff_guide.visible:
		_fail("返回小镇后应恢复顶部活动指引牌")
		return
	hud.call("refresh", WorldClock.snapshot(), {}, 1, 1, "行动力", false)
	var honey_icons: Array = hud.get("_honey_icons")
	var visible_honey_count := 0
	for icon in honey_icons:
		if (icon as Control).visible:
			visible_honey_count += 1
	if visible_honey_count != 1:
		_fail("1/1行动力应只显示一只蜜罐")
		return
	var mood_hearts: Array = hud.get("_mood_hearts")
	if mood_panel.position.y + mood_panel.size.y > energy_panel.position.y:
		_fail("心情爱心条应位于行动力条上方")
		return
	hud.call("set_mood", 4, 6)
	var full_heart_count := 0
	var empty_heart_count := 0
	for heart in mood_hearts:
		var texture := (heart as TextureRect).texture
		if texture == HEART_FULL:
			full_heart_count += 1
		elif texture == HEART_EMPTY:
			empty_heart_count += 1
	if full_heart_count != 4 or empty_heart_count != 2:
		_fail("心情 4/6 应显示四颗实心爱心和两颗空心爱心")
		return
	town.call("_begin_month_nodes_after_start_card", 2, [])
	var mood_tutorial: Node = town.get("_hud_button_tutorial")
	var mood_tutorial_title := mood_tutorial.get("_title") as Label if mood_tutorial != null else null
	if mood_tutorial == null or not mood_tutorial.call("is_open") \
			or mood_tutorial_title == null or mood_tutorial_title.text != "心情":
		_fail("第二月月初继续后应先显示心情讲解卡")
		return
	(mood_tutorial.get("_root") as Control).hide()
	hud.call("refresh", WorldClock.snapshot(), {}, 3, 3, "行动力", false)
	town.call("_on_end_month_pressed")
	if String(town.get("_month12_phase")) != "activity":
		_fail("行动力仍可消耗时不应允许直接推进主线")
		return
	town.set("_month12_month", 7)
	town.set("_month12_ap_left", 1)
	town.call("_on_month12_place_confirmed", "m7_valley")
	if int(town.get("_month12_ap_left")) != 1 or bool((town.get("_month12_flags") as Dictionary).get("visit_7_m7_valley", false)):
		_fail("三点的熊熊有招不能在只剩一点行动力时结算")
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
	report.call("open_with", early_data)
	await get_tree().process_frame
	var report_root := report.find_child("ReportRoot", true, false) as Control
	var report_scroll := report.find_child("ReportScroll", true, false) as ScrollContainer
	var detail_actions := report.get("_detail_actions") as FlowContainer
	if report_scroll == null or report_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED \
			or detail_actions == null or detail_actions.get_child_count() < 9 or report_root == null \
			or report_root.get_global_rect().position.y < 0.0 \
			or report_root.get_global_rect().end.y > get_viewport().get_visible_rect().size.y:
		_fail("报告主页面应保持单屏，并提供完整内容入口按钮")
		return
	var requirements_button: Button
	for child in detail_actions.get_children():
		if child is Button and (child as Button).text == "下一级要求":
			requirements_button = child
			break
	if requirements_button == null:
		_fail("报告页缺少下一级要求入口")
		return
	requirements_button.pressed.emit()
	await get_tree().process_frame
	var detail_overlay := report.get("_detail_overlay") as Control
	var detail_content := report.get("_detail_content") as VBoxContainer
	var detail_close := report.find_child("ReportDetailClose", true, false) as Button
	if detail_overlay == null or not detail_overlay.visible or detail_content.get_child_count() < 5 \
			or detail_close == null or detail_close.position.x < (report.get("_detail_panel") as Control).size.x * 0.7:
		_fail("下一级要求应在独立弹窗完整展示，并在右上角提供关闭按钮")
		return
	detail_close.pressed.emit()
	if detail_overlay.visible:
		_fail("报告详情关闭按钮没有关闭弹窗")
		return
	for action_title in ["大五行为倾向", "方向倾向", "岗位能力证据", "自由活动回顾", "七行摘要", "证据与依据"]:
		var action_button: Button
		for child in detail_actions.get_children():
			if child is Button and (child as Button).text == action_title:
				action_button = child
				break
		if action_button == null:
			_fail("报告页缺少详情入口：%s" % action_title)
			return
		action_button.pressed.emit()
		await get_tree().process_frame
		if not detail_overlay.visible or detail_content.get_child_count() == 0:
			_fail("报告详情入口没有展示内容：%s" % action_title)
			return
		detail_close.pressed.emit()
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
