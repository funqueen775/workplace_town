extends Node

const MAIN_SCENE := preload("res://Main.tscn")
const INTERIOR_PREVIEW := preload("res://scripts/InteriorPreview.gd")

var _interior_exit_received := false


func _ready() -> void:
	WorldClock.reset_story()
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	await get_tree().process_frame
	var portal := town.find_child("TownPortalB", true, false)
	if portal == null:
		_fail("B 区没有生成动态传送门")
		return
	if town.get("_zone_button") != null:
		_fail("主世界仍保留按 E 进入区域的按钮")
		return
	var zone_b := _find_zone(town.ZONES, "B")
	var mask := town.get("_walkability_image") as Image
	if mask == null or mask.is_empty() or mask.get_size() != Vector2i(1920, 1080):
		_fail("地图通行遮罩没有作为资源加载")
		return
	for zone in town.ZONES:
		var reachable := false
		for offset_x in range(-64, 65, 8):
			for offset_y in range(-64, 65, 8):
				var candidate: Vector2 = zone["entrance"] + Vector2(offset_x, offset_y)
				if candidate.distance_to(zone["entrance"]) <= town.ENTRANCE_DISTANCE and town.call("_is_walkable_position", candidate):
					reachable = true
					break
			if reachable:
				break
		if not reachable:
			_fail("%s 区入口周围没有可站立的道路" % zone["code"])
			return
	var player := town.get("_player") as CharacterBody2D
	player.position = zone_b["entrance"]
	town.call("_update_zone_state")
	await get_tree().process_frame
	if String((town.get("_active_zone") as Dictionary).get("code", "")) != "B":
		_fail("靠近传送门没有自动进入 B 区")
		return
	town.call("_exit_zone")
	await get_tree().process_frame
	if not (town.get("_active_zone") as Dictionary).is_empty():
		_fail("离开室内后未回到主世界")
		return
	if not bool(town.call("_is_safe_portal_exit", player.position)):
		_fail("离开后没有落在可走道路与传送门感应区之外")
		return
	var preview := INTERIOR_PREVIEW.new()
	add_child(preview)
	preview.exit_requested.connect(_on_interior_exit)
	preview.present(zone_b, town.INTERIOR_ASSETS["B"])
	preview.enable_exploration()
	var scene := preview.get("_scene") as Control
	if scene == null or not is_equal_approx(scene.position.x + scene.size.x * scene.scale.x * 0.5, preview.get("_root").size.x * 0.5):
		_fail("室内场景没有在视口居中")
		return
	if not preview.is_door_prompt_active() or preview.get("_door_prompt").text != "返回小镇  →":
		_fail("室内右侧没有显示返回小镇的出口")
		return
	var interior_player := preview.get("_player") as Node2D
	if not (preview.get("_door_prompt") as Button).disabled:
		_fail("玩家尚未靠近右侧出口时就能点击返回")
		return
	preview.set_touch_vector(Vector2(0, 1))
	preview._process(0.5)
	if interior_player.position.y != preview.ROAD_Y:
		_fail("室内角色能离开横向道路")
		return
	preview.set_touch_vector(Vector2.ZERO)
	interior_player.position = Vector2(1760, preview.ROAD_Y)
	preview._process(0.0)
	if not _interior_exit_received:
		_fail("走到室内道路右端没有自动返回主世界")
		return
	print("PORTAL_TRANSITION_PASS auto_enter=true auto_exit=true exit_outside=true")
	get_tree().quit(0)


func _find_zone(zones: Array, code: String) -> Dictionary:
	for zone in zones:
		if String(zone.get("code", "")) == code:
			return zone
	return {}


func _on_interior_exit() -> void:
	_interior_exit_received = true


func _fail(message: String) -> void:
	push_error("PORTAL_TRANSITION_FAIL " + message)
	get_tree().quit(1)
