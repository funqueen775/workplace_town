extends Node

## 带巡每站「屏末交代」的实拍核对：把第 1 站和第 5 站的面板直接打开，推到最后一拍，各存一张图。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/tour_handoff_shot.tscn

var _town: Node
var _out := "E:/03_Projects/bear/workplace_town/test_artifacts/tour_handoff"
## 默认拍第 1 站和第 5 站；想拍别的站：-- --stops=4 或 -- --stops=2,3（站号从 1 数）。
var _wanted := [0, 4]


func _ready() -> void:
	_watchdog()
	_read_stop_args()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	var panel: Node = _town.get("_story_event_panel")
	panel.set("reduced_motion", true)
	DirAccess.make_dir_recursive_absolute(_out)
	# 月初卡先收掉：真玩法里它是点"开始这一天"才走的，这里不点会让两张卡叠在一起。
	_town.call("_on_month_start_continued")
	await _wait(1.0)
	for index in _wanted:
		_clear_stray_cards()
		_town.set("_month12_tour_index", index)
		_town.call("_present_month12_stop")
		await _wait(0.8)
		for step in 20:
			var ev: Dictionary = panel.get("_event")
			var beats: Array = ev.get("beats", [])
			if int(panel.get("_beat_index")) >= beats.size() - 1:
				break
			panel.call("_advance")
			await _wait(0.3)
		await _wait(1.0)
		var beats_now: Array = (panel.get("_event") as Dictionary).get("beats", [])
		var last: Dictionary = beats_now[beats_now.size() - 1]
		var path := "%s/stop_%d.png" % [_out, index + 1]
		get_viewport().get_texture().get_image().save_png(path)
		print("[shot] 第 %d 站末句 = %s：%s → %s" % [
			index + 1, String(last.get("speaker", "")), String(last.get("text", "")), path])
		panel.call("_advance")
		await _wait(0.6)
	get_tree().quit(0)


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	print("WATCHDOG forced quit")
	get_tree().quit(1)


## 命令行挑站点：-- --stops=4 / -- --stops=2,3；不给就拍首末两站。
func _read_stop_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--stops="):
			continue
		var picked: Array = []
		for part in arg.trim_prefix("--stops=").split(",", false):
			picked.append(max(0, int(part) - 1))
		if not picked.is_empty():
			_wanted = picked


## 上一站关屏时会把地点解锁卡顶出来；下一站开拍前先替玩家点掉，免得两张卡叠一层。
func _clear_stray_cards() -> void:
	var place: Node = _town.get("_month12_place_panel")
	if place != null and is_instance_valid(place) and bool(place.call("is_open")):
		place.call("_on_unlock_ok", "")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
