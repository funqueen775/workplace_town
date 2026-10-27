extends Node

## 门的状态探针：把首月跑一遍，每次阶段变化就报一遍三扇门现在是亮还是灰，
## 并在带巡第一站（剧情正把人往门口带）和自由安排（门该全亮）各拍一张。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/door_state_probe.tscn

const SHOT_DIR := "res://test_artifacts/v12m_doors"

var _town: Node
var _last_phase := ""
var _shot_a := false
var _shot_b := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	# 上一轮跑完会留存档，带着存档进来会直接从月中接着演，探针就量不到开头那几扇门。
	for save_name in ["workplace_town_month12.json", "town_progress_v1.json"]:
		var save_path := "user://%s" % save_name
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	var panel = _town.get("_story_event_panel")
	for i in 1400:
		await _wait(0.05)
		var phase := String(_town.get("_month12_phase"))
		if phase != _last_phase:
			_last_phase = phase
			_report(phase)
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if phase == "tour" and not _shot_a:
			_shot_a = true
			await _shot("door_at_story_stop")
		if phase == "activity" and not _shot_b:
			_shot_b = true
			_town.call("_open_month12_places")
			await _wait(0.6)
			await _shot("door_all_open")
			continue
		if panel != null and bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				panel.call("_on_choice_picked", "M12_E02", "A", 45)
			else:
				panel.call("_advance")
			continue
		if phase == "handbook":
			var handbook = _town.get("_month12_handbook")
			if handbook != null and handbook.is_open():
				handbook.call("close")
			continue
		var waypoint: Vector2 = _town.get("_month12_waypoint")
		if (phase == "tour" or phase == "e02_walk") and waypoint.x > -90000.0:
			_town.get("_player").position = waypoint
			continue
		if phase == "done":
			break
	print("DOOR_PROBE_DONE")
	get_tree().quit(0)


func _report(phase: String) -> void:
	var portals: Dictionary = _town.get("_month12_place_portals")
	var lines := []
	for id in portals:
		lines.append("%s=%s" % [id, "灰" if bool((portals[id] as Node2D).sealed) else "亮"])
	print("PHASE %-12s 门：%s" % [phase, " ".join(lines) if not lines.is_empty() else "还没立"])


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
