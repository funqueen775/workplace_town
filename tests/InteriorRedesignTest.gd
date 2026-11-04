extends Node

const PREVIEW := preload("res://scripts/InteriorPreview.gd")
const ACTION_WINDOW := preload("res://scripts/ActionWindow.gd")
const TOWN := preload("res://scripts/WorkplaceTown.gd")
const NARRATION_PANEL := preload("res://scripts/WeekendScenePanel.gd")
const ZONES := {"A":"市场部", "B":"研发部", "C":"销售部", "D":"人事部", "E":"财务部", "F":"运营部", "G":"行政部", "H":"生产部"}

var _selected_id := ""

func _ready() -> void:
	var actions := ACTION_WINDOW.new()
	add_child(actions)
	if not actions.start_after_event("E01"):
		_fail("没有打开活动窗口")
		return
	var preview := PREVIEW.new()
	preview.activity_selected.connect(func(activity: Dictionary): _selected_id = String(activity.get("id", "")))
	add_child(preview)
	await get_tree().process_frame
	for code in ZONES:
		var map_path := "res://assets/八大区域地图重制版/%s_%s.png" % [code, ZONES[code]]
		preview.present({"code":code, "name":ZONES[code]}, map_path)
		preview.enable_exploration()
		var activities := actions.configured_activities_for_region(code)
		preview.set_activities(activities, true, actions.remaining)
		await get_tree().process_frame
		var scene := preview.get("_scene") as Control
		var room := scene.get_child(0) as TextureRect
		if room.texture == null or room.texture.get_size().y != 851:
			_fail("%s 区没有加载重制地图" % code)
			return
		var player := preview.get("_player") as Node2D
		if player.position.y != preview.ROAD_Y:
			_fail("%s 区玩家没有站在横路上" % code)
			return
		var npc := preview.get("_npc") as Node2D
		if npc == null:
			_fail("%s 区没有 NPC" % code)
			return
		player.position = npc.position
		preview._process(0.0)
		if not (preview.get("_talk_button") as Button).visible or npc.position.x > 700:
			_fail("%s 区左侧 NPC 无法交流" % code)
			return
		preview.interact_with_npc()
		if not (preview.get("_dialog") as Panel).visible:
			_fail("%s 区 NPC 对话没有打开" % code)
			return
		preview.call("_close_dialog")
		player.position = Vector2(930, preview.ROAD_Y)
		var cards := preview.get("_activity_buttons") as Array
		var board := preview.get("_activity_board") as TextureRect
		if board == null or board.visible != (not activities.is_empty()) or (not activities.is_empty() and board.texture == null):
			_fail("%s 区活动底板显示状态不正确" % code)
			return
		if not board.size.is_equal_approx(preview.ACTIVITY_BOARD_SIZE):
			_fail("%s 区活动底板尺寸不正确" % code)
			return
		for index in 2:
			var card := cards[index] as TextureButton
			if card.visible != (index < activities.size()):
				_fail("%s 区活动卡数量不正确" % code)
				return
			if card.visible and (card.texture_normal == null or card.position.x < board.position.x or card.position.y < board.position.y or card.position.x + card.size.x > board.position.x + board.size.x or card.position.y + card.size.y > board.position.y + board.size.y):
				_fail("%s 区活动卡没有显示在右侧" % code)
				return
			if card.visible and not preview.ACTIVITY_CARDS.values().has(card.texture_normal.resource_path):
				_fail("%s 区第 %d 张卡没有使用现有美术资源" % [code, index + 1])
				return
			if card.visible:
				card.pressed.emit()
				if _selected_id != String(activities[index]["id"]):
					_fail("%s 区第 %d 张卡跳转到错误活动" % [code, index + 1])
					return
		if code == "C":
			cards[0].mouse_entered.emit()
			await get_tree().create_timer(0.15).timeout
			if cards[0].scale.x <= 1.02 or cards[0].modulate.r <= 1.1:
				_fail("活动卡鼠标悬停没有高亮")
				return
			cards[0].mouse_exited.emit()
			await get_tree().create_timer(0.15).timeout
			if not cards[0].scale.is_equal_approx(Vector2.ONE):
				_fail("鼠标移开后活动卡没有复原")
				return
			preview.set_touch_vector(Vector2(0, 1))
			preview._process(0.5)
			if player.position.y != preview.ROAD_Y:
				_fail("玩家能离开横向道路")
				return
			preview.set_touch_vector(Vector2.ZERO)
			cards[0].pressed.emit()
			if _selected_id != String(activities[0]["id"]):
				_fail("活动卡没有接入对应活动 ID")
				return
		var screenshot_dir := OS.get_environment("TOWN_INTERIOR_SCREENSHOT_DIR")
		if not screenshot_dir.is_empty() and DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute(screenshot_dir)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(screenshot_dir.path_join("%s.png" % code))
	var overflow_preview := PREVIEW.new()
	add_child(overflow_preview)
	await get_tree().process_frame
	overflow_preview.present({"code": "D", "name": ZONES["D"]}, "res://assets/八大区域地图重制版/D_人事部.png")
	overflow_preview.set_activities([
		{"id": "m1_rooftop"},
		{"id": "m9_library"},
		{"id": "m11_reproduce"},
	], true, 1)
	var overflow_cards := overflow_preview.get("_activity_buttons") as Array
	for index in 3:
		var card := overflow_cards[index] as TextureButton
		if not card.visible or card.position.x < overflow_preview.ACTIVITY_BOARD_POSITION.x \
				or card.position.x + card.size.x > overflow_preview.ACTIVITY_BOARD_POSITION.x + overflow_preview.ACTIVITY_BOARD_SIZE.x \
				or card.position.y + card.size.y > overflow_preview.ACTIVITY_BOARD_POSITION.y + overflow_preview.ACTIVITY_BOARD_SIZE.y:
			_fail("人事部第三项活动没有在底板内显示")
			return
	var town := TOWN.new()
	var rooftop_image := String(town.call("_month12_activity_scene", {
		"id": "m1_rooftop",
		"scene": "res://assets/活动场景/D_人事部_书院露台吹风.png",
	}))
	if rooftop_image != "res://assets/活动场景/D_人事部_书院露台吹风.png":
		_fail("露台活动没有优先使用专属场景图")
		return
	town.free()
	var activities_file := FileAccess.open("res://data/story/v12m/activities.json", FileAccess.READ)
	if activities_file == null:
		_fail("活动配置文件无法读取")
		return
	var activity_data := JSON.parse_string(activities_file.get_as_text()) as Dictionary
	var configured_activities := activity_data.get("activities", []) as Array
	if configured_activities.size() != 12:
		_fail("活动配置不是 12 项")
		return
	for activity_value in configured_activities:
		var activity := activity_value as Dictionary
		var scene_path := String(activity.get("scene", ""))
		if not scene_path.begins_with("res://assets/活动场景/") or not FileAccess.file_exists(scene_path):
			_fail("活动 %s 没有有效的新场景图：%s" % [activity.get("id", "?"), scene_path])
			return
		for beat_value in activity.get("previewBeats", []) as Array:
			var beat := beat_value as Dictionary
			var beat_image := String(beat.get("image", ""))
			if not beat_image.begins_with("res://assets/活动场景/") or not FileAccess.file_exists(beat_image):
				_fail("活动 %s 的旁白分镜缺少新场景图：%s" % [activity.get("id", "?"), beat_image])
				return
	var boardgame := configured_activities.filter(func(item: Dictionary) -> bool: return String(item.get("id", "")) == "m11_boardgame")
	if boardgame.size() != 1 or (boardgame[0] as Dictionary).get("previewBeats", []).size() != 2:
		_fail("烧烤后桌游没有配置两段背景和旁白")
		return
	var narration := NARRATION_PANEL.new()
	add_child(narration)
	await get_tree().process_frame
	var boardgame_activity := boardgame[0] as Dictionary
	var beats := boardgame_activity.get("previewBeats", []) as Array
	narration.present({"title": "烧烤后桌游", "image": String((beats[0] as Dictionary).get("image", "")), "lines": beats})
	var narration_image := narration.get("_image_rect") as TextureRect
	if narration_image.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		_fail("活动背景没有按比例裁切铺满画面")
		return
	if narration_image.texture == null:
		_fail("未导入的活动 PNG 没有加载成旁白背景")
		return
	narration._advance()
	narration._advance()
	if narration_image.texture == null:
		_fail("旁白推进后没有加载下一张活动背景")
		return
	print("INTERIOR_REDESIGN_PASS maps=8 cards=12 npcs=8 movement=horizontal activity_signal=true")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("INTERIOR_REDESIGN_FAIL " + message)
	get_tree().quit(1)
