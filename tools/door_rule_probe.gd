extends Node

## 门的状态规则表直测：不跑整月流程，直接立三扇门，然后把阶段一格一格拨过去，
## 看每扇门该亮还是该灰。跑整月流程会被别处正在改的流程代码带偏，这个不会。
## 用法：<godot> --path <proj> --headless res://tools/door_rule_probe.tscn

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	_town.set("_month12_active", true)
	_town.call("_unlock_month12_place", "unlock_a")
	_town.call("_unlock_month12_place", "unlock_lake")
	_town.call("_unlock_month12_place", "unlock_b")
	var portals: Dictionary = _town.get("_month12_place_portals")
	for id in portals:
		print("DOOR %s @ %s" % [id, (portals[id] as Node2D).position])
	var stops: Array = load("res://scripts/WorkplaceTown.gd").get_script_constant_map()["MONTH12_TOUR"]
	for index in stops.size():
		print("STOP %d @ %s" % [index, (stops[index] as Dictionary)["pos"]])
	var cases := [
		["带巡第 1 站（A 区，剧情正要去）", "tour", 0, false],
		["带巡第 2 站（心湖，剧情正要去）", "tour", 1, false],
		["带巡第 3 站（工位，剧情正要去）", "tour", 2, false],
		["手册（就在工位这一站读）", "handbook", 2, false],
		["周会路上（剧情要去 A 区那张桌）", "e02_walk", 2, false],
		["自由安排（必玩做完了）", "activity", 2, true],
	]
	for c in cases:
		_town.set("_month12_phase", String(c[1]))
		_town.set("_month12_tour_index", int(c[2]))
		_town.set("_month12_places_open", bool(c[3]))
		_town.set("_month12_e02_choice", "" if String(c[1]) != "activity" else "A")
		_town.call("_refresh_month12_place_seals")
		await _wait(0.05)
		print("CASE %-28s %s" % [String(c[0]), _states()])
	# 两张实拍：灰门（心湖，剧情这个月不去）和亮门（A 区，剧情正要去）。
	# 先把开场那块剧情面板收掉、把人放回小镇上，不然拍到的永远是室内。
	var panel = _town.get("_story_event_panel")
	if panel != null and panel.has_method("close"):
		panel.call("close")
	_town.set("_month12_active", false)
	_town.set("_month12_phase", "tour")
	_town.set("_month12_tour_index", 0)
	_town.set("_month12_places_open", false)
	_town.set("_month12_e02_choice", "")
	_town.call("_refresh_month12_place_seals")
	var player: Node2D = _town.get("_player")
	player.position = Vector2(860, 830)
	await _wait(0.6)
	await _shot("door_grey_lake")
	player.position = Vector2(464, 330)
	await _wait(0.6)
	await _shot("door_bright_story")
	print("DOOR_RULE_DONE")
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://test_artifacts/v12m_doors/%s.png" % name)
	print("shot %s -> %s" % [name, image.save_png(path)])


func _states() -> String:
	var portals: Dictionary = _town.get("_month12_place_portals")
	var out := []
	for id in ["m1_rooftop", "m1_lakeside", "m1_tool"]:
		var door := portals.get(id) as Node2D
		out.append("%s=%s" % [id, "灰" if door != null and bool(door.sealed) else "亮"])
	return " ".join(out)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
