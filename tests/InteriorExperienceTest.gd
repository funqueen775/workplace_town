extends Node

const MAIN_SCENE := preload("res://Main.tscn")

func _ready() -> void:
	WorldClock.running = true
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	await get_tree().process_frame
	await get_tree().process_frame
	var camera := town.get("_camera") as Camera2D
	var world_player := town.get("_player") as Node2D
	if world_player == null or world_player.get_child(2) != town.get("_player_sprite") or not (world_player.get_child(2) as Node2D).scale.is_equal_approx(Vector2.ONE * 0.25):
		_fail("主题图玩家尺寸被改变")
		return
	for npc in town.get("_npc_instances"):
		if not (npc["character"] as Node2D).scale.is_equal_approx(Vector2.ONE):
			_fail("主题图 NPC 尺寸被改变")
			return
	var expected_outdoor_zoom: float = float(town.get("_cover_zoom")) * float(town.OUTDOOR_EXPLORATION_ZOOM)
	if camera == null or absf(camera.zoom.x - expected_outdoor_zoom) > 0.01:
		_fail("室外探索镜头未使用近景缩放")
		return
	for zone: Dictionary in town.ZONES:
		town.set("_nearby_zone", zone)
		town.call("_enter_nearby_zone")
		await get_tree().process_frame
		var interior = town.get("_interior_preview")
		if interior == null or interior.get("_scene") == null:
			_fail("%s 区未创建新场景" % zone.get("code", "?"))
			return
		var code := String(zone.get("code", ""))
		if (town.get("_memory_wall_button") as Button).visible or (town.get("_standing_button") as Button).visible:
			_fail("%s 区仍显示遮挡活动卡的功能按钮" % code)
			return
		var task_panel := (town.get("_town_ui_v2") as Node).get("_task_panel") as Control
		if task_panel.visible == (code in ["C", "D", "E", "F", "G", "H"]):
			_fail("%s 区主线面板显示状态不正确" % code)
			return
		if interior.get("_npc") == null:
			_fail("%s 区没有 NPC" % code)
			return
		if not (interior.get("_player") as Node2D).scale.is_equal_approx(Vector2.ONE * (10.0 / 3.0)):
			_fail("%s 区玩家没有放大一倍" % code)
			return
		if interior.get("_npc") != null and not (interior.get("_npc") as Node2D).scale.is_equal_approx(Vector2.ONE * (10.0 / 3.0)):
			_fail("%s 区 NPC 没有放大一倍" % code)
			return
		var room := interior.get("_scene").get_child(0) as TextureRect
		if room == null or room.texture == null or room.texture.get_size().y != 851:
			_fail("%s 区没有使用重制地图" % code)
			return
		var cards := interior.get("_activity_buttons") as Array
		if code in ["C", "D", "E", "F", "G", "H"]:
			if not cards[0].visible or not cards[1].visible or cards[0].texture_normal == null or cards[1].texture_normal == null:
				_fail("%s 区没有显示两张活动美术面板" % code)
				return
		else:
			if cards[0].visible or cards[1].visible:
				_fail("%s 区不应显示未配置的活动" % code)
				return
		var status := town.get("_zone_status") as Control
		if status == null or status.visible:
			_fail("%s 区室内仍显示小镇左上角 HUD" % zone.get("code", "?"))
			return
		if String(zone.get("code", "")) == "A" and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var interior_image := get_viewport().get_texture().get_image()
			interior_image.save_png(ProjectSettings.globalize_path("res://test_artifacts/interior_a_npc.png"))
		town.call("_exit_zone")
		await get_tree().process_frame
		if not (town.get("_memory_wall_button") as Button).visible or not (town.get("_standing_button") as Button).visible:
			_fail("离开 %s 区后功能按钮没有恢复" % code)
			return
		if not task_panel.visible:
			_fail("离开 %s 区后主线面板没有恢复" % code)
			return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path("res://test_artifacts/interior_experience.png"))
	print("INTERIOR_EXPERIENCE_PASS zones=8 maps=8 activity_cards=12 hud_hidden=true")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("INTERIOR_EXPERIENCE_FAIL " + message)
	get_tree().quit(1)
