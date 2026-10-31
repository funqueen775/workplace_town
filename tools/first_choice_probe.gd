extends Node

## 玩家遇到的第一个三选一（第 1 月 E02）：选完之后屏幕上到底有什么。
## 用法：<godot> --path . --resolution 1600x900 res://tools/first_choice_probe.tscn -- --no-resume

var _town: Node
var _panel: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/first_choice"))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	_town.call("_on_month_start_continued")
	await _wait(0.8)

	for i in 3000:
		await _wait(0.05)
		var phase := String(_town.get("_month12_phase"))
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			continue
		var drawer = _town.get("_month_phone_panel")
		if drawer != null and bool((drawer.get("_card") as Control).visible):
			drawer.call("open_phone")
			await _wait(0.4)
			drawer.call("close_phone")
			continue
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var stage := String(_panel.call("current_stage"))
			if stage == "choices":
				var ev: Dictionary = _panel.get("_event")
				var first := String(((ev.get("choices", []) as Array)[0] as Dictionary).get("id", "A"))
				print("[first] 这是 ", ev.get("id"), " 的三选一，屏幕上有 ", (ev.get("choices", []) as Array).size(), " 个选项")
				await _shot("01_选之前")
				_panel.call("_on_choice_picked", String(ev.get("id", "")), first, 45)
				await _wait(1.3)
				print("[first] 选完之后 stage=", _panel.call("current_stage"))
				print("[first] 屏幕上那句话＝", _panel.call("_outcome_text", first))
				await _shot("02_选之后的回应")
				print("FIRST_CHOICE_DONE")
				_done = true
				get_tree().quit(0)
				return
			if stage != "interaction" and stage != "handbook":
				_panel.call("_advance")
			continue

	print("FIRST_CHOICE_DONE（没走到三选一）")
	_done = true
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://test_artifacts/first_choice/" + name + ".png"))


func _watchdog() -> void:
	await get_tree().create_timer(120.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
