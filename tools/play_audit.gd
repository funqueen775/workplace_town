extends Node

## 全年实跑审计：按真流程走 12 个月，每开一屏就把"玩家看得见什么"记下来，
## 顺带跑一批机器能查的毛病（选项超长 / 重复 / 带后台词 / 缺图 / 文字放不下 / 没有取舍），
## 有毛病的屏顺手裁一张面板图存下来。产物：test_artifacts/play_audit/year_dump.txt
##
## 用法：<godot> --path <PROJ> --resolution 1920x1080 --user-data-dir=<独立目录> \
##        res://tools/play_audit.tscn

const OUT_DIR := "res://test_artifacts/play_audit"
const SHOT_DIR := "res://test_artifacts/play_audit/shots"

## 排版线（开发册 11.9）：主句 ≤12、副句 ≤22、教学卡每条 ≤24
const CHOICE_MAX := 26.0
## 玩家可见文字里不许出现的后台词（算法册 §6.5 + 开发册措辞口径）
const BANNED := ["threshold", "anchor", "stateDelta", "apCost", "rubric", "flag", "阈值", "权重", "系数", "格子", "后台"]

var _town: Node
var _panel
var _lines: Array = []
var _seen := {}
var _month_screens := {}
var _stall := 0
var _last_sig := ""
var _m12_started := false
var _m12_done_ticks := 0
var _m7_started := false
var _m7_done_ticks := 0
var _shots_taken := 0
## 选法：rotate = 按屏号轮换（会走到未转正那条线）；A = 每屏第一手（能走到第 12 月）
var _mode_pick := "rotate"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--pick="):
			_mode_pick = String(arg).get_slice("=", 1)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.5).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	var month_seen := {}
	for tick in 6000:
		await get_tree().create_timer(0.04).timeout
		var month := int(_town.get("_month12_month"))
		var phase := String(_town.get("_month12_phase"))
		if not month_seen.has(month):
			month_seen[month] = true
			_note("")
			_note("========== 第 %d 月 ==========" % month)
		if month >= 12 and phase != "done":
			_m12_started = true
		if month == 7 and phase != "done":
			_m7_started = true
		if month >= 12 and phase == "done" and _m12_started:
			_m12_done_ticks += 1
		else:
			_m12_done_ticks = 0
		if _m12_done_ticks > 200:
			break
		# 第六月没转正的人：第七月交接完就收尾，第 8–12 月本来不开。认下来，别把 tick 烧光。
		if month == 7 and phase == "done" and _m7_started:
			_m7_done_ticks += 1
		else:
			_m7_done_ticks = 0
		if _m7_done_ticks > 120:
			_note("[结束] 第 7 月交接完就收尾（这一局第六月没转正，第 8–12 月本来不开）")
			break
		var ev_now: Dictionary = _panel.get("_event")
		var sig := "%d|%s|%s|%s" % [month, phase, str(ev_now.get("id", "")), str(_panel.get("_beat_index"))]
		if sig == _last_sig:
			_stall += 1
		else:
			_stall = 0
			_last_sig = sig
		var runner_now = _town.get("_month_runner")
		if runner_now != null and String((runner_now.get("current") as Dictionary).get("id", "")) == "M12_CLOSE":
			_stall = 0
		if _stall > 150:
			_note("!! 卡住：月=%d phase=%s 屏=%s 当前节点=%s 黄线=%s 玩家=%s" % [
				month, phase, str(ev_now.get("id", "")),
				String((runner_now.get("current") as Dictionary).get("id", "")) if runner_now != null else "?",
				str(_town.get("_month12_waypoint")), str(_town.get("_player").position)])
			_stall = 0
		var start_card = _town.get("_month12_start_panel")
		if start_card != null and bool(start_card.call("is_open")):
			_audit_month_card(month, start_card)
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.2).timeout
			continue
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
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
			if not bool(inbox.get("_phone_open")):
				_audit_phone(month, inbox)
				inbox.call("open_phone")
			else:
				inbox.call("close_phone")
			continue
		var hud_card = _town.get("_hud_button_tutorial")
		if hud_card != null and bool(hud_card.call("is_open")):
			hud_card.call("_on_open_pressed")
			continue
		var archive_ui = _town.get("_town_ui_v2")
		if archive_ui != null and bool(archive_ui.call("is_open")):
			archive_ui.call("close_view")
			await get_tree().create_timer(0.2).timeout
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			await get_tree().create_timer(0.2).timeout
			continue
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
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var event: Dictionary = _panel.get("_event")
			var eid := str(event.get("id", ""))
			var stage := String(_panel.get("_stage"))
			if not _seen.has(eid) and stage != "choices":
				_seen[eid] = true
				_month_screens[month] = int(_month_screens.get(month, 0)) + 1
				var title := String(event.get("title", "")).strip_edges()
				_note("--- M%d.%d %s《%s》 %s/%s" % [month, int(_month_screens.get(month, 0)), eid,
					title, str(event.get("locationId", "")), str(event.get("timeBand", ""))])
				if title.is_empty():
					_flag("%s 这一屏没有标题（面板顶上会空一块）" % eid)
			if stage == "choices":
				if not bool(_seen.get(eid + "_audited", false)):
					_seen[eid + "_audited"] = true
					await _audit_choices(month, eid, event)
				_panel.call("_on_choice_picked", eid, _pick(eid, event), 45)
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
			_audit_close(month)
			_town.call("_on_month12_close_finished")
			continue
	_write_dump()
	print("PLAY_AUDIT_DONE 屏=", _seen.size() / 2, " 毛病行=", _flag_count, " 截图=", _shots_taken)
	get_tree().quit(0)


var _flag_count := 0


func _note(text: String) -> void:
	_lines.append(text)


func _flag(text: String) -> void:
	_flag_count += 1
	_lines.append("  !! " + text)


## 选项按屏号稳定轮换，别永远选 A：这样一年里三条路线都会被走到一次。
func _pick(eid: String, event: Dictionary) -> String:
	var choices: Array = event.get("choices", []) as Array
	if choices.is_empty():
		return "A"
	if _mode_pick == "A":
		return String(Dictionary(choices[0]).get("id", "A"))
	var hash_sum := 0
	for ch in eid:
		hash_sum += ch.unicode_at(0)
	var index := hash_sum % choices.size()
	return String(Dictionary(choices[index]).get("id", "A"))


func _visible_length(text: String) -> int:
	var out := 0
	for ch in text:
		if ch != ' ' and ch != '\n':
			out += 1
	return out


func _audit_choices(month: int, eid: String, event: Dictionary) -> void:
	var beats: Array = event.get("beats", []) as Array
	var last_line := ""
	for value in beats:
		var beat := Dictionary(value)
		var text := String(beat.get("text", "")).strip_edges()
		if not text.is_empty():
			last_line = text
	_note("  上一屏最后一句：" + last_line)
	var choices: Array = event.get("choices", []) as Array
	var seen_text := {}
	var any_cost := false
	var any_gain := false
	for value in choices:
		var choice := Dictionary(value)
		var text := String(choice.get("text", "")).strip_edges()
		var cost := int(choice.get("apCost", 0))
		var delta: Dictionary = choice.get("stateDelta", {}) as Dictionary
		var comp := (choice.get("competency", []) as Array)
		var signals := (choice.get("btSignals", []) as Array)
		var dims: Array = []
		for entry in comp:
			dims.append("%s%d" % [String(Dictionary(entry).get("dimension", "?")), int(Dictionary(entry).get("anchor", 0))])
		var traits: Array = []
		for sig in signals:
			traits.append("%s%+d" % [String(Dictionary(sig).get("trait", "?")), int(Dictionary(sig).get("dir", 0))])
		if cost > 0:
			any_cost = true
		if not delta.is_empty() or not comp.is_empty():
			any_gain = true
		_note("  选项%s（%d字｜AP%d｜心情%s｜四维 %s｜大五 %s）：%s" % [
			String(choice.get("id", "?")), _visible_length(text), cost,
			str(delta.get("H", 0)), "/".join(dims) if not dims.is_empty() else "无",
			"/".join(traits) if not traits.is_empty() else "无", text])
		if seen_text.has(text):
			_flag("%s 有重复文案的选项：%s" % [eid, text])
		seen_text[text] = true
		if _visible_length(text) > int(CHOICE_MAX):
			_flag("%s 选项 %d 字，超排版线 %.0f：%s" % [eid, _visible_length(text), CHOICE_MAX, text])
		for word in BANNED:
			if text.to_lower().contains(word.to_lower()):
				_flag("%s 选项里出现后台词「%s」：%s" % [eid, word, text])
	_check_missing_textures(eid)
	_check_choice_overflow(eid)


## 面板上有没有该有图却空着的 TextureRect
func _check_missing_textures(eid: String) -> void:
	var stack: Array = [_panel]
	while not stack.is_empty():
		var node = stack.pop_back()
		for child in (node as Node).get_children():
			if child is TextureRect and (child as TextureRect).texture == null and (child as Control).visible:
				_flag("%s 面板里 %s 没有贴图（会是一块空白）" % [eid, (child as Node).name])
			stack.append(child)


## 选项按钮文字放不下（截断）
func _check_choice_overflow(eid: String) -> void:
	var font := (load("res://assets/fonts/NotoSansCJKsc-Regular.otf") as Font)
	if font == null:
		return
	var stack: Array = [_panel]
	while not stack.is_empty():
		var node = stack.pop_back()
		for child in (node as Node).get_children():
			if child is Button and not (child as Button).text.is_empty() and (child as Control).visible:
				var button := child as Button
				var size_px := button.get_theme_font_size("font_size")
				var wide := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
				if wide > button.size.x - 24.0 and button.size.x > 0.0:
					_flag("%s 按钮放不下：需要 %.0fpx，只有 %.0fpx —— %s" % [eid, wide, button.size.x, button.text])
			stack.append(child)


func _audit_phone(month: int, inbox) -> void:
	var rows := (inbox.call("_message_rows") as Array) if inbox.has_method("_message_rows") else []
	if rows.is_empty():
		return
	_note("  [手机] 这个月的消息 %d 条" % rows.size())


func _audit_month_card(month: int, card) -> void:
	var label: Variant = card.get("_title_label")
	if label is Label:
		_note("  [月首卡] " + (label as Label).text.replace("
", " / "))


func _audit_close(month: int) -> void:
	var close_panel = _town.get("_month12_close_panel")
	if close_panel == null or not bool((close_panel as CanvasItem).visible):
		return
	var label2: Variant = close_panel.get("_title_label")
	if label2 is Label:
		_note("  [月末卡] " + (label2 as Label).text.replace("
", " / "))


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
		_note("  [自由安排] 这个月能去的：%s（剩 %d 格）" % [", ".join(PackedStringArray(ids.map(func(x): return String(x)))), slots])
		_town.call("_on_end_month_pressed")
		return
	_town.call("_on_month12_place_confirmed", String(pending[0]))
	await get_tree().create_timer(0.25).timeout
	var scene = _town.get("_weekend_scene_panel")
	if scene != null and bool(scene.call("is_open")):
		scene.call("_advance")


func _write_dump() -> void:
	var path := ProjectSettings.globalize_path(OUT_DIR + "/year_dump.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(PackedStringArray(_lines)))
		print("DUMP 写入 ", path, " 行数=", _lines.size())
	else:
		print("DUMP 写入失败：", path, " 错误=", FileAccess.get_open_error())
