extends Node

## 整局里选一次：屏幕上到底出现的是"某某说了什么"，还是"你的选择被记录下来了"。
## 用法：<godot> --path . --resolution 1600x900 res://tools/choice_echo_probe.tscn -- --no-resume

var _town: Node
var _panel: Node
var _done := false
var _picked := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/choice_echo"))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	_town.call("debug_jump_to_month", 2, "A")
	await _wait(2.2)
	var start = _town.get("_month12_start_panel")
	if start != null and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await _wait(1.0)

	for i in 2000:
		await _wait(0.05)
		var phase := String(_town.get("_month12_phase"))
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var stage := String(_panel.call("current_stage"))
			if stage == "choices" and not _picked:
				_picked = true
				var ev: Dictionary = _panel.get("_event")
				var first := String(((ev.get("choices", []) as Array)[0] as Dictionary).get("id", "A"))
				print("[echo] 点选项前 stage=", stage, " 选项=", first)
				_panel.call("_on_choice_picked", String(ev.get("id", "")), first, 45)
				await _wait(1.2)
				print("[echo] 选完之后 stage=", _panel.call("current_stage"))
				print("[echo] 屏幕上那句回应＝", _panel.call("_outcome_text", first))
				await _shot("选完之后的回应")
				continue
			if stage == "outcome":
				continue
			if stage != "interaction" and stage != "handbook":
				_panel.call("_advance")
			continue
		if _picked:
			print("[echo] 画面已经往下走了，停手")
			break
		if phase == "activity":
			break

	print("CHOICE_ECHO_DONE")
	_done = true
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://test_artifacts/choice_echo/" + name + ".png"))
	print("[shot] ", name)


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
