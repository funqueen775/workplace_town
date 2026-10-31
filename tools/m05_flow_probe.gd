extends Node

## 第 5 月整月走一遍，把每一屏的「日期读数」打出来核对（2026-10-30 实机反馈驱动）。
##
## 要核的是三件事：
##   ① 周一早上看路演袋 → 周四下午彩排 → 周四深夜告警：三屏之间有没有承接（节点顺序对不对）；
##   ② 深夜那屏左上角那格写的是「夜晚」，不是「上午」；
##   ③ 上旬→中旬翻在「第二天早上」那一屏，翻完之后那一格换成「白天」、画面也不再压暗；
##      走到会展码头那屏，日期读数不再自己跳。
##
## 用法：<godot> --path <proj> --headless res://tools/m05_flow_probe.tscn -- --v12m-month=5

var _town: Node
var _panel
var _seen := {}
var _log: Array = []


func _ready() -> void:
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(4.0).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	for tick in 2500:
		await get_tree().create_timer(0.04).timeout
		var month := int(_town.get("_month12_month"))
		var phase := String(_town.get("_month12_phase"))
		if month > 5 or phase == "done":
			break
		var start_card = _town.get("_month12_start_panel")
		if start_card != null and bool(start_card.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.2).timeout
			continue
		var tutorial = _town.get("_month_phone_tutorial")
		if tutorial != null and bool(tutorial.get("_card").visible):
			tutorial.call("close_tutorial")
			continue
		if bool(_town.get("_phone_gate_waiting")) and not bool(_town.get("_phone_gate_read")):
			_town.call("_open_ui_phone")
			continue
		var inbox = _town.get("_month_phone_panel")
		if inbox != null and bool(inbox.call("is_open")):
			if bool(inbox.get("_phone_open")):
				inbox.call("close_phone")
			else:
				inbox.call("open_phone")
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			_shot_row("讲解卡（会展码头）")
			unlock.call("_on_unlock_ok", "")
			await get_tree().create_timer(0.2).timeout
			continue
		var visit_id := String(_town.get("_month12_visit_id"))
		if not visit_id.is_empty():
			_shot_row("到了剧情门口 · visit=%s" % visit_id)
			var visit_door = _town.get("_story_door")
			if visit_door != null:
				_town.get("_player").position = (visit_door as Node2D).position
			await get_tree().create_timer(0.12).timeout
			_town.call("_begin_interaction")
			await get_tree().create_timer(0.25).timeout
			var place: Dictionary = _town.call("_month12_visit_place")
			if not place.is_empty():
				_town.call("_on_activity_selected", place)
			continue
		if phase in ["node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var event: Dictionary = _panel.get("_event")
			var eid := str(event.get("id", "")).replace("M12_", "")
			if not _seen.has(eid):
				_seen[eid] = true
				_shot_row("屏 %s 《%s》" % [eid, String(event.get("title", ""))])
			var stage := String(_panel.get("_stage"))
			if stage == "choices":
				_panel.call("_on_choice_picked", str(event.get("id", "")), "A", 45)
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
			# 自由安排这一屏不再往下走：本探针只核到 Demo 为止，直接收掉这个月。
			print("---- 第 5 月核对结果 ----")
			for line in _log:
				print(line)
			get_tree().quit(0)
			return
		if phase == "close":
			var close_panel = _town.get("_month12_close_panel")
			if close_panel != null and bool(close_panel.call("is_open")):
				close_panel.call("dismiss")
			continue
	print("---- 第 5 月核对结果（跑到月末/第六月） ----")
	for line in _log:
		print(line)
	get_tree().quit(0)


## 记一行：节点名 + 日期三格的真值 + 左上角格子上的字 + 画面压暗程度。
func _shot_row(tag: String) -> void:
	var ui = _town.get("_town_ui_v2")
	var xun_cell: Label = ui.call("date_xun_cell")
	var band_cell: Label = ui.call("date_band_cell")
	var tint = _town.get("_environment_tint")
	var alpha := -1.0
	if tint != null and tint is ColorRect:
		alpha = (tint as ColorRect).color.a
	var line := "%s ｜ 真值 月%d %s/%s ｜ 格子 xun=%s band=%s ｜ 压暗=%.2f" % [
		tag,
		int(_town.get("_date_month")),
		String(_town.get("_date_xun")),
		String(_town.get("_date_band")),
		xun_cell.text if xun_cell != null else "-",
		band_cell.text if band_cell != null else "-",
		alpha,
	]
	_log.append(line)
	print(line)
	_shoot(tag)


var _shot_dir := ""


## 带窗口跑的时候顺手存一张：日期牌、入场卡、讲解卡都在图里，比读数直观。
func _shoot(tag: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _shot_dir.is_empty():
		_shot_dir = ProjectSettings.globalize_path("res://test_artifacts/m05_flow")
		DirAccess.make_dir_recursive_absolute(_shot_dir)
	await RenderingServer.frame_post_draw
	var safe := ""
	for index in tag.length():
		var ch := tag.substr(index, 1)
		safe += ch if ch.is_valid_identifier() or (ch >= "0" and ch <= "9") or (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or ch == "_" else "_"
	if safe.length() > 40:
		safe = safe.substr(0, 40)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shot_dir, safe])


func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	print("WATCHDOG forced quit")
	for line in _log:
		print(line)
	get_tree().quit(1)
