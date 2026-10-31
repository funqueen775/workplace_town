extends Node

## 「门色」和「能不能按 E」必须说同一句话。
## 全年跑采样太稀（一贴到门口下一帧就进剧情了），所以这里直接摆状态：
## 逐个相位把玩家放到门口、重算一次封条和 E 提示，读出来配成一张表。
## 用法：<godot> --path <proj> --headless res://tools/prompt_state_check.tscn

const DOOR_ID := "m1_tool"
const STATES := [
	{"phase": "activity", "slots": 1, "tag": "自由活动·还有格子"},
	{"phase": "activity", "slots": 0, "tag": "自由活动·格子用完（再访）"},
	{"phase": "month_nodes", "slots": 1, "tag": "自由月份·节点间（runner 判为可走）"},
	{"phase": "node_walk", "slots": 1, "tag": "剧情走位中"},
	{"phase": "tour", "slots": 1, "tag": "首月带巡"},
	{"phase": "e02_walk", "slots": 1, "tag": "首月去周会桌"},
	{"phase": "sleep_walk", "slots": 0, "tag": "回宿舍"}, 
	{"phase": "close", "slots": 0, "tag": "月末卡"},
]

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	for key in ["_month12_start_panel", "_story_event_panel"]:
		var node = _town.get(key)
		if node == null:
			continue
		for method in ["close", "dismiss", "hide_panel"]:
			if node.has_method(method):
				node.call(method)
		if node is CanvasItem:
			(node as CanvasItem).hide()
	await _wait(0.3)
	_town.set("_hud_tour_active", false)
	_town.set("_date_cutscene_lock", false)
	_town.set("_month12_active", true)
	_town.set("_month12_places_open", true)
	_town.call("_load_month12_places")
	for id in ["m1_rooftop", "m1_lakeside", "m1_tool"]:
		_town.call("_ensure_month12_place", id)
	await _wait(0.2)
	var doors: Dictionary = _town.get("_month12_place_portals")
	var door: Node2D = doors.get(DOOR_ID)
	var player: Node2D = _town.get("_player")
	var button = _town.get("_interaction_button")
	var rows: Array = []
	for state in STATES:
		_town.set("_month12_phase", String(state["phase"]))
		_town.set("_month12_slots_left", int(state["slots"]))
		_town.set("_month12_waypoint", door.position)
		player.position = door.position
		_town.call("_refresh_month12_place_seals")
		await _wait(0.5)
		# 这 0.5 秒里游戏自己的每帧逻辑会动玩家（走到落点就演下一屏），
		# 所以在读数之前把相位、黄线、站位重新摆一次，别拿被游戏改过的现场当样本。
		_town.set("_month12_phase", String(state["phase"]))
		_town.set("_month12_waypoint", door.position)
		player.position = door.position
		_town.call("_refresh_month12_place_seals")
		_town.call("_update_month12_place_prompt")
		# 不再 await：带巡相位每帧都会因为"到点了"把玩家挪去下一站，
		# 只要让出一次帧就测不到这一帧的现场。
		var sealed := bool(door.sealed)
		var visible := bool(button.visible)
		# 按 E 到底有没有任何回应：按钮亮着=能进；按钮不亮时看是否给了那句解释。
		var explained := false
		if not visible:
			explained = bool(_town.call("_explain_dead_portal"))
		var verdict := "一致"
		if not sealed and not visible and not explained:
			verdict = "★矛盾：门金着，按 E 既进不去也没人解释"
		elif sealed and visible:
			verdict = "★矛盾：门是灰的，E 却亮着"
		elif not sealed and not visible and explained:
			verdict = "可接受：门金着，按 E 回一句"
		print("[相位表] %-22s 门=%s  E按钮=%s  按E有回应=%s  %s%s" % [
			String(state["tag"]), "灰" if sealed else "金",
			"亮" if visible else "不亮",
			"有（解释）" if explained else ("有（能进）" if visible else "没有"),
			verdict,
			"" if not visible else "（%s）" % String(button.text)])
		rows.append(verdict)
	# 收尾：把状态还原，免得存档被写脏（这一局只是探针，不写盘，但保持干净）
	_town.set("_month12_waypoint", Vector2(-99999, -99999))
	print("STATE_TABLE_DONE 矛盾数=", rows.count("★矛盾：门金着，按 E 既进不去也没人解释") + rows.count("★矛盾：门是灰的，E 却亮着"),
		" 可接受=", rows.count("可接受：门金着，按 E 回一句"))
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
