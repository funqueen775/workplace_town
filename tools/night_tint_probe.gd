extends Control

## 夜晚到底暗不暗：把日期推到「夜晚」，量一下全屏夜色那块的实际颜色。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/night_tint_probe.tscn

var _town: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_run()


func _run() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	var panel = _town.get("_story_event_panel")
	for i in 400:
		await _wait(0.05)
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if panel != null and bool(panel.call("is_open")):
			panel.call("_advance")
			continue
		if String(_town.get("_month12_phase")) == "tour":
			break
	await _wait(0.6)
	print("开局读数 %s / 夜色 %s" % [_date_text(), _tint()])
	for step in [
		{"args": [2, "early", "night"], "tag": "01_month_to_night"},
		{"args": [2, "mid", "morning"], "tag": "02_xun_to_day"},
		{"args": [2, "late", "night"], "tag": "03_xun_to_night"},
	]:
		_town.callv("push_date", step["args"] as Array)
		await _settle()
		print("%s 读数 %s / 夜色 %s" % [step["tag"], _date_text(), _tint()])
		await _shot(String(step["tag"]))
	# 屋里亮不亮：夜里进 B 区室内，再把昼夜推回白天，看屋内那层夜色跟不跟。
	_enter_b_interior()
	await _wait(0.8)
	print("夜里进屋 %s / 屋内夜色 %s" % [_date_text(), _interior_shade()])
	await _shot("04_interior_night")
	_town.call("push_date", 3, "early", "morning")
	await _settle()
	print("推回白天 %s / 屋内夜色 %s / 夜色 %s" % [_date_text(), _interior_shade(), _tint()])
	await _shot("05_interior_day")
	print("NIGHT_PROBE_DONE")
	get_tree().quit(0)


func _enter_b_interior() -> void:
	var zone: Dictionary = _town.call("_zone_by_code", "B")
	_town.call("_enter_month12_interior", zone, "")


## 过场播完 + 一帧余量：光色是在格子翻过去那一刻才落的，急不得。
func _settle() -> void:
	for i in 60:
		if not bool(_town.call("wipe_playing")):
			break
		await _wait(0.1)
	await _wait(0.9)


func _date_text() -> String:
	var ui = _town.get("_town_ui_v2")
	if ui == null:
		return "无 HUD"
	return "%s-%s-%s" % [ui.get("_date_month_cell").text, ui.get("_date_xun_cell").text, ui.get("_date_band_cell").text]


func _tint() -> String:
	var tint: ColorRect = _town.get("_environment_tint")
	return "null" if tint == null else str(tint.color)


func _interior_shade() -> String:
	var preview = _town.get("_interior_preview")
	if preview == null or not bool(preview.call("is_open")):
		return "没在屋里"
	var shade: ColorRect = preview.get("_shade")
	return "null" if shade == null else str(shade.color)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://test_artifacts/night_tint/%s.png" % name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/night_tint"))
	print("shot %s -> %s" % [name, image.save_png(path)])
