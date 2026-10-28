extends Node

## 第 3 月节点探针：直接从第 3 月开跑，看节点是不是一根线走通。
## 用法：<godot> --path <proj> --headless res://tools/probe_month3.tscn

var _town: Node
var _last := ""


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.4).timeout
	var panel = _town.get("_story_event_panel")
	if panel != null and bool(panel.call("is_open")):
		panel.call("close")
	await get_tree().create_timer(0.4).timeout
	_town.call("_start_month_nodes", 3)
	for i in 900:
		await get_tree().create_timer(0.05).timeout
		var runner = _town.get("_month_runner")
		var current: Dictionary = runner.get("current") if runner != null else {}
		var nid := String(current.get("id", ""))
		if nid != _last:
			_last = nid
			print("NODE %s (%s)" % [nid, String(current.get("nodeType", ""))])
		if String(_town.get("_month12_phase")) == "done":
			print("MONTH3_DONE")
			break
		if panel != null and bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				panel.call("_on_choice_picked", "M12_E10" if nid == "E10" else "M12_E12", "A", 40)
			else:
				panel.call("_advance")
			continue
		if nid == "" :
			continue
		var waypoint: Vector2 = _town.get("_month12_waypoint")
		if bool(runner.get("waiting_walk")) and waypoint.x > -90000.0:
			_town.get("_player").position = waypoint
			continue
		if String(current.get("nodeType", "")) == "activity":
			print("STOP_AT_ACTIVITY %s" % nid)
			break
	print("PROBE_ENDED")
	get_tree().quit(0)
