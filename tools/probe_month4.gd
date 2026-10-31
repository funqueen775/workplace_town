extends Node

## 第 4 月节点探针：直接从第 4 月开跑，截关键屏。安静月——没有门、没有个人时间。
## 用法：<godot> --path <proj> res://tools/probe_month4.tscn

var _town: Node
var _last := ""
var _shots := {}


func _ready() -> void:
	print("BOOT")
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.4).timeout
	var panel = _town.get("_story_event_panel")
	if panel != null and bool(panel.call("is_open")):
		panel.call("dismiss")
	await get_tree().create_timer(0.4).timeout
	_town.call("push_date", 4, "early", "morning")
	_town.call("_start_month_nodes", 4)
	for i in 900:
		await get_tree().create_timer(0.05).timeout
		var runner = _town.get("_month_runner")
		var current: Dictionary = runner.get("current") if runner != null else {}
		var nid := String(current.get("id", ""))
		if nid != _last:
			_last = nid
			print("NODE %s (%s)" % [nid, String(current.get("nodeType", ""))])
		if String(_town.get("_month12_phase")) == "done":
			print("MONTH4_DONE")
			break
		if String(_town.get("_month12_phase")) == "close":
			var cp = _town.get("_month12_close_panel")
			if cp != null and bool(cp.get("_root").visible) and _once("m4_close"):
				await get_tree().create_timer(0.4).timeout
				await _shot("m4_close")
			_town.call("_on_month12_close_finished")
			await get_tree().create_timer(0.4).timeout
			continue
		if panel != null and bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				if _once("m4_" + nid + "_choices"):
					await get_tree().create_timer(0.4).timeout
					await _shot("m4_" + nid + "_choices")
				panel.call("_on_choice_picked", "M12_" + nid, "A", 45)
				await get_tree().create_timer(0.4).timeout
				if _once("m4_" + nid + "_outcome"):
					await _shot("m4_" + nid + "_outcome")
			else:
				if nid == "M04_NOTICE" and _once("m4_notice"):
					await get_tree().create_timer(0.4).timeout
					await _shot("m4_notice")
				panel.call("_advance")
			continue
		var wp: Vector2 = _town.get("_month12_waypoint")
		if runner != null and bool(runner.get("waiting_walk")) and wp.x > -90000.0:
			if _once("m4_walk_" + nid):
				_town.get("_player").position = wp - Vector2(220, 0)
				await get_tree().create_timer(0.4).timeout
				await _shot("m4_walk_" + nid)
			_town.get("_player").position = wp
			continue
	print("PROBE_ENDED phase=%s month=%s flags=%s" % [
		_town.get("_month12_phase"), _town.get("_month12_month"),
		JSON.stringify(_town.get("_month12_flags"))])
	get_tree().quit(0)


func _once(key: String) -> bool:
	if _shots.has(key):
		return false
	_shots[key] = true
	return true


func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("shot skipped (headless) %s" % name)
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://test_artifacts/v12m_month4")
	DirAccess.make_dir_recursive_absolute(dir)
	print("shot %s -> %s" % [name, image.save_png(dir + "/" + name + ".png")])
