extends Node

const STARTUP_SCENE := preload("res://Startup.tscn")

func _ready() -> void:
	var startup := STARTUP_SCENE.instantiate()
	add_child(startup)
	await get_tree().process_frame
	await get_tree().process_frame

	var title := startup.get_node_or_null("TitleStage") as Control
	if title == null or title.get_node_or_null("StartGame") == null or title.get_node_or_null("Settings") == null or title.get_node_or_null("ExitGame") == null:
		_fail("标题页没有正确显示")
		return

	startup.call("_start_game_flow")
	await get_tree().process_frame
	await get_tree().process_frame
	var comic := startup.get_node_or_null("OpeningComic")
	if comic == null:
		_fail("开始游戏后没有显示开场漫画")
		return
	comic.call("skip")
	await get_tree().process_frame
	if not _has_text(comic, "点击继续"):
		_fail("跳过漫画后没有等待用户继续")
		return
	comic.call("_continue_to_login")
	await get_tree().process_frame
	await get_tree().process_frame
	if not _has_text(startup, "认识职场小镇"):
		_fail("漫画结束后没有进入小镇导览")
		return

	startup.call("_skip_intro")
	await get_tree().process_frame
	if not _has_text(startup, "选择你的形象"):
		_fail("跳过导览后没有进入形象选择")
		return

	startup.call("_start_scenarios")
	await get_tree().process_frame
	if not _has_text(startup, "入职预演"):
		_fail("导览后没有进入入职情景题")
		return

	print("STARTUP_FLOW_PASS title=true comic=true intro=true avatar=true scenarios=true")
	get_tree().quit(0)

func _has_text(root: Node, value: String) -> bool:
	if root is Label and (root as Label).text.contains(value):
		return true
	if root is Button and (root as Button).text.contains(value):
		return true
	for child in root.get_children():
		if _has_text(child, value):
			return true
	return false

func _fail(message: String) -> void:
	push_error("STARTUP_FLOW_FAIL " + message)
	get_tree().quit(1)
