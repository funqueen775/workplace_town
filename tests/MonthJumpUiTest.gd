extends Node

const MAIN_SCENE := preload("res://Main.tscn")


func _ready() -> void:
	WorldClock.reset_story()
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	await get_tree().process_frame
	var ui = town.get("_town_ui_v2")
	ui.open_view("task", {"event": WorldClock.next_main_event(), "snapshot": WorldClock.snapshot(), "energy": 3})
	await _capture("task_open")
	if _has_texture(ui, ui.TASK_LOCK_ICON) or _has_text(ui, "已开放"):
		_fail("已开放任务仍显示锁或状态标签")
		return
	var story := ui.find_child("TaskStoryText", true, false) as RichTextLabel
	if story == null or story.size.x > 345 or story.position.y + story.size.y > 730:
		_fail("剧情简介超出底框")
		return
	var next_event: Dictionary = WorldClock.story_events()[1]
	ui.open_view("task", {"event": next_event, "snapshot": WorldClock.snapshot(), "energy": 3})
	await get_tree().process_frame
	if not _has_texture(ui, ui.TASK_LOCK_ICON) or not _has_text(ui, "尚未开放"):
		_fail("未开放任务丢失锁定状态")
		return
	town.call("_open_ui_calendar")
	await _capture("calendar")
	var tab_size := Vector2.ZERO
	for year in 4:
		var tab := _find_button(ui, "第 %d 年" % (year + 1))
		if tab == null or (tab_size != Vector2.ZERO and tab.size != tab_size):
			_fail("年份按钮尺寸不一致")
			return
		tab_size = tab.size
	var next := _find_button(ui, "进入下个月")
	if next == null or next.disabled:
		_fail("下一月按钮不可用")
		return
	next.pressed.emit()
	await get_tree().process_frame
	var dialog := _find_confirmation(town)
	var warning := dialog.find_child("WarningText", true, false) as Label if dialog != null else null
	if warning == null or not warning.text.contains("晋升") or not warning.text.contains("测评报告"):
		_fail("跳月确认弹窗未显示完整风险")
		return
	var art := dialog.find_child("MonthJumpArt", true, false) as NinePatchRect
	if art == null or warning.get_theme_font("font") != ui.FONT:
		_fail("确认弹窗未使用项目美术或字体")
		return
	await _capture("month_jump_confirmation")
	_find_button(dialog, "继续完成任务").pressed.emit()
	await get_tree().process_frame
	if int(WorldClock.snapshot()["month"]) != 1 or not WorldClock.skipped_main_event_ids().is_empty():
		_fail("取消跳月仍改变了进度")
		return
	next.pressed.emit()
	await get_tree().process_frame
	dialog = _find_confirmation(town)
	if dialog == null:
		_fail("第二次跳月未弹窗")
		return
	_find_button(dialog, "确认跳过").pressed.emit()
	await get_tree().process_frame
	if int(WorldClock.snapshot()["month"]) != 2 or not WorldClock.skipped_main_event_ids().has("E01") or ui.is_open():
		_fail("确认后未进入下个月并跳过旧主线")
		return
	var saved := WorldClock.save_progress()
	WorldClock.load_progress(saved)
	if int(WorldClock.snapshot()["month"]) != 2 or WorldClock.next_main_event().get("id", "") != "E02":
		_fail("跳月存档恢复失败")
		return
	WorldClock.advance_minutes(60)
	if int(WorldClock.snapshot()["month"]) != 2:
		_fail("已跳过事件阻塞时间推进")
		return
	town.call("_open_ui_calendar")
	await get_tree().process_frame
	var year_four := _find_button(ui, "第 4 年")
	if year_four == null:
		_fail("第4年按钮不存在")
		return
	year_four.pressed.emit()
	await get_tree().process_frame
	var month_48 := _find_month_button(ui, "第 48 月")
	if month_48 == null:
		_fail("第48月卡片不存在")
		return
	month_48.pressed.emit()
	await get_tree().process_frame
	var advance := _find_button(ui, "推进至第 48 月")
	if advance == null or advance.disabled:
		_fail("推进至选定月份按钮不可用")
		return
	advance.pressed.emit()
	await get_tree().process_frame
	dialog = _find_confirmation(town)
	if dialog == null:
		_fail("跨年跳月未弹窗")
		return
	_find_button(dialog, "确认跳过").pressed.emit()
	await get_tree().process_frame
	if int(WorldClock.snapshot()["month"]) != 48 or WorldClock.next_main_event().get("id", "") != "E35":
		_fail("跨年跳月未停在终局主线")
		return
	print("MONTH_JUMP_UI_PASS task calendar confirmation save finale")
	get_tree().quit(0)


func _find_button(root: Node, value: String) -> Button:
	for child in root.get_children():
		if child is Button and child.text == value and not child.is_queued_for_deletion():
			return child
		var found := _find_button(child, value)
		if found != null:
			return found
	return null


func _find_month_button(root: Node, value: String) -> Button:
	for child in root.get_children():
		if child is Button and not child.is_queued_for_deletion():
			for label in child.get_children():
				if label is Label and label.text == value:
					return child
		var found := _find_month_button(child, value)
		if found != null:
			return found
	return null


func _find_label(root: Node, value: String) -> Label:
	for child in root.get_children():
		if child is Label and child.text.contains(value) and not child.is_queued_for_deletion():
			return child
		var found := _find_label(child, value)
		if found != null:
			return found
	return null


func _has_text(root: Node, value: String) -> bool:
	for child in root.get_children():
		if child is Label and child.text == value and not child.is_queued_for_deletion():
			return true
		if _has_text(child, value):
			return true
	return false


func _has_texture(root: Node, texture: Texture2D) -> bool:
	for child in root.get_children():
		if child is TextureRect and child.texture == texture and not child.is_queued_for_deletion():
			return true
		if _has_texture(child, texture):
			return true
	return false


func _find_confirmation(root: Node) -> Node:
	return root.get_node_or_null("MonthJumpDialog")


func _capture(name: String) -> void:
	await get_tree().process_frame
	var directory := OS.get_environment("TOWN_UI_SCREENSHOT_DIR")
	if not directory.is_empty():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join(name + ".png"))


func _fail(message: String) -> void:
	push_error("MONTH_JUMP_UI_FAIL " + message)
	get_tree().quit(1)
