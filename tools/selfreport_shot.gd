extends Node

## 拍开局那一套：两道预演之后接的登记表五题（同一张卡、老周念题、五档按钮）。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/selfreport_shot.tscn

const SHOT_DIR := "res://test_artifacts/selfreport"

var _flow: Node
var _sc: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_flow = load("res://Startup.tscn").instantiate()
	add_child(_flow)
	await _wait(2.2)
	_flow.call("_start_scenarios")
	await _wait(0.8)
	_sc = _find_scenarios(_flow)
	if _sc == null:
		print("NO_SCENARIOS")
		get_tree().quit(1)
		return
	print("登记题数 ", (_sc.get("_registry_pages") as Array).size())
	await _shot("01_预演那屏")
	_sc.set("_page", 2)
	_sc.call("_rebuild")
	await _wait(0.5)
	await _shot("02_登记表第一题")
	_sc.call("_choose_answer", 1)
	await _wait(0.5)
	await _shot("03_勾了不太符合")
	print("SELFREPORT_SHOT_DONE")
	get_tree().quit(0)


func _find_scenarios(node: Node) -> Node:
	for child in node.get_children():
		if child.get_script() != null and String(child.get_script().resource_path).contains("StartupScenarios"):
			return child
		var hit := _find_scenarios(child)
		if hit != null:
			return hit
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("SHOT ", shot_name, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")))
