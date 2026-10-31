extends Node

## 解锁卡机制的最小核对（不跑整月）：把"该弹卡的那一刻"直接喂给城镇，看门立没立、卡弹没弹。
##   ① 挂 hook 的那一拍（水巷外摆）
##   ② 靠 unlockAfter 的四屏（草坪／书院／桌游角／复现论文）
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/unlock_card_direct_probe.tscn

var _town: Node


func _ready() -> void:
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	var panel = _town.get("_month12_start_panel")
	if panel != null and is_instance_valid(panel) and bool(panel.call("is_open")):
		panel.emit_signal("continued")
		await _wait(1.0)
	await _check_hook()
	await _check_unlock_after("M07_RESULT", "m7_lawn")
	await _check_unlock_after("M09_NAME", "m9_library")
	await _check_unlock_after("M11_OPEN", "m11_boardgame")
	await _check_unlock_after("M11_MATERIAL", "m11_reproduce")
	print("[direct] 复核完毕")
	get_tree().quit(0)


func _check_hook() -> void:
	var beat := {
		"type": "say", "speaker": "小林",
		"text": "以后见客户基本都在这儿。旁边那家咖啡还行。",
		"hook": "unlock_waterway",
	}
	_town.call("_on_story_beat_reached", "M03_WRAP", 3, beat)
	await _wait(0.3)
	_town.call("_open_hook_cards", Callable())
	await _wait(0.7)
	print("[direct] hook 路径：门=", (_town.get("_month12_place_portals") as Dictionary).keys(),
		" 卡弹了=", _card_open())
	await _shoot("hook_waterway")
	_dismiss()
	await _wait(0.4)


func _check_unlock_after(node_id: String, place_id: String) -> void:
	_town.call("_queue_unlock_after_cards", node_id)
	await _wait(0.2)
	var queued := (_town.get("_pending_unlock_places") as Array).size()
	_town.call("_open_hook_cards", Callable())
	await _wait(0.7)
	var has_door := (_town.get("_month12_place_portals") as Dictionary).has(place_id)
	print("[direct] %s 解锁 %s：排队=%d 门=%s 卡弹了=%s" % [
		node_id, place_id, queued, str(has_door), str(_card_open())])
	await _shoot("after_%s" % node_id)
	_dismiss()
	await _wait(0.4)


func _card_open() -> bool:
	var place = _town.get("_month12_place_panel")
	return place != null and is_instance_valid(place) and bool(place.call("is_open"))


func _dismiss() -> void:
	var place = _town.get("_month12_place_panel")
	if place != null and is_instance_valid(place) and bool(place.call("is_open")):
		place.call("_on_unlock_ok", "")


func _shoot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://test_artifacts/unlock_cards")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
