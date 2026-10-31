extends Node

## 只拍第 5 月那张会展码头的讲解卡：把节点里的 visit 块拼成去处，直接喂给解锁卡面板。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/m05_card_shot.tscn

func _ready() -> void:
	_watchdog()
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.6).timeout
	var start_panel = town.get("_month12_start_panel")
	if start_panel != null and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await get_tree().create_timer(0.8).timeout
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	var demo := {}
	for node in ((parsed as Dictionary).get("nodes", []) as Array):
		if String((node as Dictionary).get("id", "")) == "M05_DEMO":
			demo = node as Dictionary
	var visit: Dictionary = demo.get("visit", {})
	var place := {
		"id": "m5_expo",
		"name": String(visit.get("name", "")),
		"locationId": String(demo.get("locationId", "")),
		"location": String(demo.get("location", "")),
		"object": String(visit.get("object", "")),
		"placeLine": String(visit.get("placeLine", "")),
		"doorHint": String(visit.get("doorHint", "")),
		"card": visit.get("card", {}),
		"peek": true,
	}
	var panel = town.get("_month12_place_panel")
	panel.call("show_unlock", place, false)
	await get_tree().create_timer(1.2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var dir := ProjectSettings.globalize_path("res://test_artifacts/m05_flow")
		DirAccess.make_dir_recursive_absolute(dir)
		get_viewport().get_texture().get_image().save_png("%s/05_card.png" % dir)
		print("[card] 截图 → ", dir)
	get_tree().quit(0)


func _watchdog() -> void:
	await get_tree().create_timer(60.0).timeout
	print("WATCHDOG forced quit")
	get_tree().quit(1)
