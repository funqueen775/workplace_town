extends Node
## 逐屏清单探针：跳进第 N 月（可指定 A/B/C 路线），把每一屏的节点 id 按顺序打出来。
## 用法：<godot> --path <PROJ> --headless res://tools/probe_nodes_played.tscn -- --from=9 --path-letter=C
## 目的：确认剧情册那些"只在某分支出现"的屏（未提名面谈、答辩那一串、条件回响）真的被播出来了，
##       而不是数据里写了、运行时被整段跳过。驱动方式与 probe_year 完全一致，只是多打了清单。

var _town: Node
var _panel
var _seen := []
var _last_id := ""
var _choice_letter := "A"
var _close_texts := {}
var _start_clicked := false


func _ready() -> void:
	var from_month := 1
	var settle := []
	for arg in OS.get_cmdline_user_args():
		var text := String(arg)
		if text.begins_with("--from="):
			from_month = clampi(int(text.get_slice("=", 1)), 1, 12)
		elif text.begins_with("--path-letter="):
			_choice_letter = text.get_slice("=", 1).to_upper()
		elif text.begins_with("--settle="):
			# 系统判出来的那几个旗标（延期转正 / 晋升没过）没有生产者，
			# 探针手动替它落一下，才能看见挂在它后面的那两屏。
			settle.append(text.get_slice("=", 1))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.5).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	_town.call("debug_jump_to_month", from_month, _choice_letter)
	var flags: Dictionary = _town.get("_month12_flags")
	for flag in settle:
		flags[String(flag)] = true
		print("[补] 手工落旗标 ", flag)
	for tick in 9000:
		await get_tree().create_timer(0.04).timeout
		var month := int(_town.get("_month12_month"))
		var start_panel = _town.get("_month12_start_panel")
		if start_panel != null and bool(start_panel.call("is_open")):
			if not _start_clicked:
				_start_clicked = true
				start_panel.emit_signal("continued")
			continue
		_start_clicked = false
		var phase := String(_town.get("_month12_phase"))
		var override_text := String(_town.get("_month_close_text_override"))
		if override_text != "" and not _close_texts.has(str(month)):
			_close_texts[str(month)] = override_text.replace("\n", " ／ ")
		if month >= 12 and phase == "done":
			break
		var visit_id := String(_town.get("_month12_visit_id"))
		if not visit_id.is_empty():
			var door = _town.get("_story_door")
			if door != null:
				_town.get("_player").position = (door as Node2D).position
			await get_tree().create_timer(0.12).timeout
			_town.call("_begin_interaction")
			await get_tree().create_timer(0.25).timeout
			var place: Dictionary = _town.call("_month12_visit_place")
			if not place.is_empty():
				_town.call("_on_activity_selected", place)
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			print("   [讲解卡] 弹出，替玩家点掉")
			unlock.call("_on_unlock_ok", "")
			continue
		if phase in ["tour", "e02_walk", "node_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var event: Dictionary = _panel.get("_event")
			var eid := str(event.get("id", ""))
			if eid != _last_id:
				_last_id = eid
				var beats: Array = event.get("beats", []) as Array
				var choices: Array = event.get("choices", []) as Array
				_seen.append("m%d:%s" % [month, eid])
				print("[屏] m%d %-16s 拍=%d 选项=%d" % [month, eid, beats.size(), choices.size()])
			var stage := String(_panel.get("_stage"))
			if stage == "choices":
				_panel.call("_on_choice_picked", eid, _choice_letter, 45)
			elif stage == "interaction" or stage == "handbook":
				pass
			else:
				_panel.call("_advance")
			continue
		if phase == "handbook":
			var book = _town.get("_month12_handbook")
			if book != null and bool(book.call("is_open")):
				book.call("close")
			continue
		if phase == "activity":
			await _do_activity_month(month)
			continue
		if phase == "close":
			# 月末卡的文案在卡一开就被引擎清掉了；这里打探针自己攒下的那一份。
			print("[月末卡] m%d ｜ %s" % [month, _close_texts.get(str(month), "(没抓到)")])
			_town.call("_on_month12_close_finished")
			continue
	print("[清单] 共 %d 屏：%s" % [_seen.size(), ", ".join(_seen)])
	var lit: Array = []
	for key in (_town.get("_month12_flags") as Dictionary).keys():
		if String(key).begins_with("peak_") or String(key).begins_with("visit_"):
			lit.append(String(key))
	lit.sort()
	print("[点亮/到访] %s" % JSON.stringify(lit))
	get_tree().quit()


## 通用月份：把这个月列出的去处一处一处做完；没有可去的就点"结束这个月"。
func _do_activity_month(month: int) -> void:
	var runner = _town.get("_month_runner")
	var node: Dictionary = runner.current if runner != null else {}
	var ids: Array = node.get("activityIds", []) as Array
	var slots: int = int(_town.get("_month12_slots_left"))
	var pending: Array = []
	for value in ids:
		var aid := String(value)
		if bool(_town.call("_month12_activity_visited", aid)):
			continue
		pending.append(aid)
	if slots <= 0 or pending.is_empty():
		_town.call("_on_end_month_pressed")
		return
	_town.call("_on_month12_place_confirmed", String(pending[0]))
	await get_tree().create_timer(0.25).timeout
	var scene = _town.get("_weekend_scene_panel")
	if scene != null and bool(scene.call("is_open")):
		scene.call("_advance")
