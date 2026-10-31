extends Node

## 首月心情罐露出核对：第 1 月全程盯着 _energy_panel.visible，每站截一张图。
## 目的：确认"某一站看到罐子"到底是第 1 月漏了，还是已经进了第 2 月。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/probe_mood_first_month.tscn

const SHOT_DIR := "res://test_artifacts/mood_first_month"

var _town: Node
var _ui: Node
var _rows: Array = []
var _seen_visible := false
var _first_visible_at := ""
var _stops_seen := 0
var _done := false
var _last_phase := ""


func _ready() -> void:
	_watchdog()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	_ui = _town.get("_town_ui_v2")
	var panel = _town.get("_story_event_panel")
	panel.reduced_motion = true
	_town.call("_on_month_start_continued")
	await _wait(0.8)
	_check("开局")
	await _shot("stop_0_open")

	for i in 8000:
		await _wait(0.05)
		_check_visible_only()
		var phase := String(_town.get("_month12_phase"))
		if phase != _last_phase:
			_last_phase = phase
			print("[mood] 相位 -> %s（第 %d 月，站 %d）" % [
				phase, int(_town.get("_month12_month")), int(_town.get("_month12_tour_index")) + 1])
		var index := int(_town.get("_month12_tour_index"))
		if phase == "tour":
			var now := index + 1
			if now > _stops_seen:
				_stops_seen = now
				await _wait(0.5)
				_check("第 %d 站" % now)
				await _shot("stop_%d" % now)
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		var place = _town.get("_month12_place_panel")
		if place != null and is_instance_valid(place) and bool(place.call("is_open")):
			place.call("_on_unlock_ok", "")
			await _wait(0.4)
			continue
		if phase == "tour_panel" and not bool(panel.call("is_open")):
			_town.call("_advance_month12_story")
			await _wait(0.3)
			continue
		if phase == "e02_panel" and not bool(panel.call("is_open")):
			_town.call("_advance_month12_story")
			await _wait(0.3)
			continue
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if int(_town.get("_month12_month")) >= 2:
			_check("翻到第 2 月")
			await _shot("month2_start")
			break
		if bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				var ev: Dictionary = panel.get("_event")
				panel.call("_on_choice_picked", String(ev.get("id", "")), "A", 45)
			elif stage != "interaction" and stage != "handbook":
				panel.call("_advance")
			continue
		if phase == "activity":
			_check("自由活动")
			await _shot("activity")
			_town.call("_on_end_month_pressed")
			continue
		if phase == "close":
			_town.call("_on_month12_close_finished")
			continue

	print("---- 首月心情罐核对 ----")
	for row in _rows:
		print("  ", row)
	print("首次可见=", _first_visible_at if not _first_visible_at.is_empty() else "整个第 1 月都没露")
	_done = true
	get_tree().quit(0)


func _check(tag: String) -> void:
	if _ui == null:
		return
	var meter: Control = _ui.get("_energy_panel")
	if meter == null:
		return
	var line := "%s · 第 %d 月 · 相位 %s · 罐子可见=%s" % [
		tag, int(_town.get("_month12_month")), String(_town.get("_month12_phase")), str(meter.visible)]
	_rows.append(line)
	print("[mood] ", line)


func _check_visible_only() -> void:
	if _ui == null or _seen_visible:
		return
	var meter: Control = _ui.get("_energy_panel")
	if meter == null or not meter.visible:
		return
	_seen_visible = true
	_first_visible_at = "第 %d 月 · 相位 %s" % [
		int(_town.get("_month12_month")), String(_town.get("_month12_phase"))]
	print("[mood] 第一次看见罐子：", _first_visible_at)


func _watchdog() -> void:
	await get_tree().create_timer(180.0).timeout
	if _done:
		return
	print("WATCHDOG 收尾")
	for row in _rows:
		print("  ", row)
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	image.save_png(path)
	print("[mood] shot ", path)
