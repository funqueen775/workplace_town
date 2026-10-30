extends Node

const MAIN_SCENE := preload("res://Main.tscn")


func _ready() -> void:
	WorldClock.reset_story()
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	await get_tree().process_frame
	var town_ui = town.get("_town_ui_v2")
	var profile_snapshot: Dictionary = town_ui.call("_profile_snapshot")
	if String(profile_snapshot.get("role", "")) != "实习开发师" or int(profile_snapshot.get("next_review", 0)) != 6:
		_fail("初始档案应显示实习生及第6月首次晋升检查")
		return
	if profile_snapshot.get("abilities", []) != [3, 3, 3, 3, 3]:
		_fail("新员工能力应从后端基准值3开始")
		return
	var npcs: Array = town.get("_npc_instances")
	if npcs.is_empty():
		_fail("地图中没有可交流的NPC")
		return
	var first_npc: Dictionary = npcs[0]
	var first_character: Node2D = first_npc["character"]
	town.get("_player").position = first_character.position
	town.call("_update_nearby_npc")
	if (town.get("_nearby_npc") as Dictionary).is_empty():
		_fail("靠近地图NPC后未识别可交流对象")
		return
	for button in town.find_children("*", "Button", true, false):
		if (button as Button).text.contains("交流"):
			_fail("主题图仍创建右下角交流按钮")
			return
	if town.find_child("DormRoom", true, false) != null:
		_fail("V1.2开局不应创建旧宿舍节点")
		return
	var first := WorldClock.next_main_event()
	if String(first.get("id", "")) != "E01" or WorldClock.running:
		_fail("开局必须停在E01并等待玩家前往目标区域")
		return
	var zone_b := _find_zone(town.ZONES, "B")
	town.set("_nearby_zone", zone_b)
	town.call("_enter_nearby_zone")
	await get_tree().process_frame
	var panel = town.get("_story_event_panel")
	if panel == null or not panel.is_open():
		_fail("进入B区后没有打开E01")
		return
	if int(town.get("_tutorial_step")) != 2:
		_fail("进入E01后教学没有推进到剧情选择步骤")
		return
	town.call("_on_story_outcome_acknowledged", "E01", "option_a", 45)
	await get_tree().process_frame
	var action = town.get("_action_window")
	if action == null or not action.active or action.remaining != 3:
		_fail("E01结算后没有进入3点行动力窗口")
		return
	if int(town.get("_tutorial_step")) != 3:
		_fail("E01结算后教学没有推进到行动力步骤")
		return
	if String(WorldClock.next_main_event().get("id", "")) != "E02":
		_fail("E01后下一事件必须是E02")
		return
	var activities: Array = action.activities_for_region("C")
	action.spend_on_activity(activities[0] as Dictionary)
	await get_tree().process_frame
	var honey_icons: Array = town_ui.get("_honey_icons")
	var empty_honey = preload("res://assets/ui/rework_v1/hud/components/06_蜂蜜罐_空.png")
	if town_ui.get("_energy_label").text != "精力  2/3" or honey_icons[2].texture != empty_honey:
		_fail("首次消耗行动力后顶部蜂蜜未同步减少")
		return
	if int(town.get("_tutorial_step")) != 4:
		_fail("首次消耗行动力后教学没有推进到耗尽步骤")
		return
	for index in 2:
		action.spend_on_activity(activities[index % 2] as Dictionary)
	await get_tree().process_frame
	if action.active or action.remaining != 0:
		_fail("行动力未正确耗尽")
		return
	if town_ui.get("_energy_label").text != "精力  0/3" or honey_icons.any(func(icon): return icon.texture != empty_honey):
		_fail("行动力耗尽后顶部蜂蜜未显示0/3")
		return
	if String(WorldClock.next_main_event().get("id", "")) != "E02" or WorldClock.running:
		_fail("行动力耗尽后应停在E02并恢复路线引导")
		return
	var saved_clock := WorldClock.save_progress()
	var saved_action: Dictionary = action.save_progress()
	WorldClock.jump_to_month(3)
	if int(WorldClock.snapshot().get("month", 0)) != 2:
		_fail("月历跳月不能跨过未完成的E02主线")
		return
	WorldClock.load_progress(saved_clock)
	action.load_progress(saved_action)
	if action.remaining != 0 or int(WorldClock.snapshot().get("worldMinute", -1)) != int(saved_clock.get("worldMinute", -2)):
		_fail("存档状态还原失败")
		return
	town.call("_open_ui_phone")
	await _capture_view("phone")
	if not town_ui.is_open():
		_fail("小熊手机未打开")
		return
	town_ui.set("_phone_tab", "memories")
	town.call("_open_ui_phone")
	await _capture_view("memories")
	town_ui.close_view()
	town.call("_open_ui_calendar")
	await _capture_view("calendar")
	if not town_ui.is_open():
		_fail("职业月历未打开")
		return
	town_ui.set("_calendar_year", 2)
	town_ui.open_view("calendar", {"month": int(WorldClock.snapshot().get("month", 1)), "target_month": 26, "events": WorldClock.story_events()})
	await _capture_view("calendar_year3")
	town_ui.open_view("settings")
	await _capture_view("settings")
	if not town_ui.is_open():
		_fail("游戏设置未打开")
		return
	print("V12_CORE_FLOW_PASS dorm=false E01_window=3 next=E02")
	get_tree().quit(0)


func _capture_view(name: String) -> void:
	await get_tree().process_frame
	var directory := OS.get_environment("TOWN_UI_SCREENSHOT_DIR")
	if not directory.is_empty():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join(name + ".png"))


func _find_zone(zones: Array, code: String) -> Dictionary:
	for zone in zones:
		if String(zone.get("code", "")) == code:
			return zone
	return {}


func _fail(message: String) -> void:
	push_error("V12_CORE_FLOW_FAIL " + message)
	get_tree().quit(1)
