extends Node

## 屏末交代探针：跳第 2 月，把工位那一屏推到最后一拍，截下"谁安排的、去哪儿、去做什么"那句。

var _town: Node
var _dir := ""


func _ready() -> void:
	_dir = ProjectSettings.globalize_path("res://test_artifacts/last_beat")
	DirAccess.make_dir_recursive_absolute(_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.6).timeout
	_town.call("debug_jump_to_month", 2, "A")
	await get_tree().create_timer(2.4).timeout
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await get_tree().create_timer(1.2).timeout
	var panel = _town.get("_story_event_panel")
	var runner = _town.get("_month_runner")
	var beats: Array = (runner.get("current") as Dictionary).get("beats", []) as Array
	print("节点 ", String((runner.get("current") as Dictionary).get("id", "")), " 共 ", beats.size(), " 拍")
	for i in beats.size():
		if panel != null and bool(panel.call("is_open")):
			panel.call("_advance")
		await get_tree().create_timer(0.25).timeout
	print("最后一拍文案：", String((beats[beats.size() - 1] as Dictionary).get("text", "")))
	await get_tree().create_timer(0.8).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		print("shot ->", image.save_png("%s/last_beat.png" % _dir))
	print("LAST_BEAT_DONE")
	get_tree().quit(0)
