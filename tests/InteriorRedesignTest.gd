extends Node

const PREVIEW := preload("res://scripts/InteriorPreview.gd")
const ACTION_WINDOW := preload("res://scripts/ActionWindow.gd")
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
		if board.position.x < scene.size.x * 0.5 or board.position.x + board.size.x > scene.size.x - 30.0 or board.position.y < 0.0 or board.position.y + board.size.y > scene.size.y - 30.0:
			_fail("%s 区活动底板超出场景边界" % code)
			return
		for index in 2:
			var card := cards[index] as TextureButton
			if card.visible != (index < activities.size()):
				_fail("%s 区活动卡数量不正确" % code)
				return
			if card.visible and (card.texture_normal == null or card.position.x < scene.size.x * 0.5):
				_fail("%s 区活动卡没有显示在右侧" % code)
				return
			if card.visible and (card.position.x < board.position.x or card.position.y < board.position.y or card.position.x + card.size.x > board.position.x + board.size.x or card.position.y + card.size.y > board.position.y + board.size.y):
				_fail("%s 区第 %d 张卡超出活动底板" % [code, index + 1])
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
	print("INTERIOR_REDESIGN_PASS maps=8 cards=12 npcs=8 movement=horizontal activity_signal=true")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("INTERIOR_REDESIGN_FAIL " + message)
	get_tree().quit(1)
