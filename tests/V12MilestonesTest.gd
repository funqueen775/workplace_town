extends Node

const MAIN_SCENE := preload("res://Main.tscn")


func _ready() -> void:
	ApiClient.set("_mode", "mock")
	WorldClock.reset_story()
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	await get_tree().process_frame
	var events := WorldClock.story_events()
	for index in 6:
		WorldClock.complete_main_event(String(events[index]["id"]))
	WorldClock.jump_to_next_main_event()
	town.call("_on_story_outcome_acknowledged", "E07", "option_a", 45)
	await get_tree().process_frame
	var assessment: AssessmentPanel = town.get("_assessment_panel")
	if not assessment.visible or assessment.get("_month") != 6:
		_fail("E07 后没有打开第 6 月检查点")
		return
	await _capture("assessment")
	assessment.call("_on_assessment_failed", "测试：后端暂不可用")
	if not assessment.get("_continue_unconfirmed_button").visible:
		_fail("后端握手失败后没有显示继续流程入口")
		return
	assessment.call("_on_continue_unconfirmed_pressed")
	await get_tree().process_frame
	var overlay = town.get("_training_overlay")
	if overlay == null or overlay.get_child_count() != 1:
		_fail("第 6 月检查点后没有进入训练谷")
		return
	var battle = overlay.get_child(0).get_child(0)
	if battle.get("model") == null:
		_fail("训练谷战斗没有初始化")
		return
	var effects = battle.get("battle_fx")
	var attack: Button = battle.get("attack_button")
	battle.get("map_background").visible = false
	battle.get("table_background").visible = true
	battle.get("battle_layer").visible = true
	battle.get("dialogue_layer").visible = false
	attack.visible = true
	for target in [battle.get("song_portrait"), battle.get("pool_row"), battle.get("card_row")]:
		target.visible = true
		effects.focus(target, "", 14)
		await get_tree().process_frame
		var relative_transform: Transform2D = effects.get_global_transform().affine_inverse() * target.get_global_transform()
		var target_center: Vector2 = relative_transform * (target.size * 0.5)
		var target_frame: Panel = effects.get("focus_frame")
		if (target_frame.position + target_frame.size * 0.5).distance_to(target_center) > 1.0:
			_fail("训练谷亮框未对准教学目标：" + target.name)
			return
	battle.call("_tutorial_attack_button")
	await get_tree().process_frame
	var frame: Panel = effects.get("focus_frame")
	var expected_center := attack.position + attack.size * 0.5
	var actual_center := frame.position + frame.size * 0.5
	if actual_center.distance_to(expected_center) > 1.0 or frame.size.distance_to(attack.size + Vector2(28, 28)) > 1.0:
		_fail("训练谷亮框未对准攻击按钮：%s / %s" % [actual_center, expected_center])
		return
	await _capture("training_focus")
	effects.clear_focus()
	battle.training_completed.emit()
	await get_tree().process_frame
	if town.get("_training_overlay") != null or String(WorldClock.next_main_event().get("id", "")) != "E08":
		_fail("训练胜利后未返回 E08")
		return
	for month in [12, 18, 24, 30, 36, 42]:
		town.get("_assessment_seen_months").append(month)
	var achievement_targets := {"E08": "C1", "E12": "C2", "E22": "C3", "E38": "C4", "E34": "C5"}
	for event in events:
		var event_id := String(event["id"])
		if achievement_targets.has(event_id):
			town.call("_on_story_outcome_acknowledged", event_id, "option_a", 45)
			await get_tree().process_frame
			var achievement = town.get("_achievement_panel")
			if not achievement.visible or String(achievement.get("_node").get("id", "")) != achievement_targets[event_id]:
				_fail("成就节点没有按文档顺序出现：" + event_id)
				return
			if event_id == "E38" or event_id == "E34":
				achievement.call("_select", "option_a")
			achievement.call("_on_continue")
			await get_tree().process_frame
		else:
			WorldClock.complete_main_event(event_id)
		if event_id == "E34":
			break
	if town.get("_achievement_seen_ids").size() != 5:
		_fail("五个成就节点没有全部记录")
		return

	for event in events:
		if String(event["id"]) != "E35":
			WorldClock.complete_main_event(String(event["id"]))
	WorldClock.jump_to_next_main_event()
	town.call("_on_story_outcome_acknowledged", "E35", "option_a", 45)
	await get_tree().process_frame
	var finale = town.get("_finale")
	if finale == null or not finale.visible:
		_fail("E35 后没有打开终局答辩")
		return
	finale.call("_on_report_pressed")
	await get_tree().process_frame
	var report = get_tree().root.get_children().filter(func(child): return child.get_script() == preload("res://scripts/ReportPanel.gd"))
	if report.is_empty() or not report[0].visible or report[0].layer <= finale.layer:
		_fail("报告页没有显示在终局答辩之上")
		return
	await _capture("report")
	var fixture = JSON.parse_string(FileAccess.get_file_as_string("res://contracts/fixtures/report-ready.json"))
	if not (fixture is Dictionary):
		_fail("报告契约样例无法读取")
		return
	report[0].render(fixture)
	await _capture("report_fixture")
	print("V12_MILESTONES_PASS month6 training E08 finale report")
	get_tree().quit(0)


func _capture(name: String) -> void:
	var directory := OS.get_environment("TOWN_UI_SCREENSHOT_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(name + ".png"))


func _fail(message: String) -> void:
	push_error("V12_MILESTONES_FAIL " + message)
	get_tree().quit(1)
