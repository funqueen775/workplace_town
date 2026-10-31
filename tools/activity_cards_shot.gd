extends Node

## 进区之后的卡片列表长什么样：C 区一张、E 区两张（一张有卡面一张没有）。
## 用法：<godot> --path . --resolution 1600x900 res://tools/activity_cards_shot.tscn -- --no-resume

var _town: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/activity_cards"))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.2).timeout
	# 月首卡还开着会盖住卡片：先替玩家点"开始这一天"。
	var start = _town.get("_month12_start_panel")
	for i in 60:
		await get_tree().create_timer(0.1).timeout
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.8).timeout
			break
	var unlocked: Dictionary = _town.get("_month12_unlocked_places")
	for id in ["m3_waterway", "m7_lawn", "m7_valley"]:
		unlocked[id] = true
	var places: Array = _town.get("_month12_places")
	print("[cards] 活动数=", places.size())
	for zone in ["C", "E"]:
		_town.call("_show_month12_place_list", zone)
		await get_tree().create_timer(0.6).timeout
		var cards = _town.get("_activity_cards")
		print("[cards] ", zone, " 区 卡片列表开着=", bool(cards.call("is_open")))
		await _shot("列表_%s区" % zone)
		if bool(cards.call("is_open")):
			cards.call("close")
		await get_tree().create_timer(0.3).timeout
	print("CARDS_SHOT_DONE")
	_done = true
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://test_artifacts/activity_cards/" + name + ".png"))


func _watchdog() -> void:
	await get_tree().create_timer(60.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
