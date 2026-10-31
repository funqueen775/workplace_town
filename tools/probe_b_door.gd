extends Node

## B 区一区一门核对：先解锁"组内小工具"，再解锁"把活往前赶"，
## 镇上应该只有一扇门；进门后的列表应该列出两件事。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/probe_b_door.tscn

const SHOT_DIR := "res://test_artifacts/b_door"

var _town: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(4.0)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel):
		start_panel.call("close")
	await _wait(0.8)
	_town.call("_ensure_month12_place", "m1_tool")
	await _wait(0.6)
	_town.call("_ensure_month12_place", "m_grind")
	await _wait(0.8)

	var portals: Dictionary = _town.get("_month12_place_portals")
	var unlocked: Dictionary = _town.get("_month12_unlocked_places")
	print("[door] 门数量=%d 登记=%s" % [portals.size(), str(portals.keys())])
	print("[door] 已解锁去处=%s" % str(unlocked.keys()))
	var door: Node2D = portals.get("m1_tool")
	if door != null:
		_town.get("_player").position = door.position + Vector2(0, 150)
	await _wait(2.0)
	await _shot("b_door_one")

	var zone: Dictionary = _town.call("_zone_by_code", "B")
	_town.call("_enter_month12_interior", zone, "")
	_town.call("_show_month12_place_list", "B")
	await _wait(1.2)
	await _shot("b_inside_list")
	print("B_DOOR_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	image.save_png(path)
	print("[door] shot ", path)
