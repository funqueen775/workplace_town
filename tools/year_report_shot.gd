extends Node

## 第 12 月末那份报告，落在合并进来的那一页上（同一张底图、同一套字体）。
## 账是真的：把第 1–5 月每一屏第一手选择按游戏自己的记法记进账，再跑第 6 月判定。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/year_report_shot.tscn

const SHOT_DIR := "res://test_artifacts/year_report"
const EVENTS_PATH := "res://data/story/v12m/events.json"
const ACTIVITIES_PATH := "res://data/story/v12m/activities.json"

var _town: Node
var _pick_turn := -1
## 命令行加 `-- --bt-pick=1` 指定"每一屏都选第几手"，用来拍不同打法下的样子。
var _force_pick := -1
var _tag := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--bt-pick="):
			_force_pick = int(String(arg).get_slice("=", 1))
			_tag = "_第%d手" % (_force_pick + 1)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	_fill_ledger()
	_town.call("debug_jump_to_month", 12, "A")
	await _wait(2.6)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await _wait(1.4)
	var flags: Dictionary = _town.get("_month12_flags")
	flags["m12_promotion_status"] = "not_promoted"
	flags["m12_promotion_reason"] = "下一级要求里的跨情境闭环还没有被记录覆盖"
	# 让"下一级要求"那一块两种状态都出现：这两条是第 12 月真会落的旗标。
	flags["m12_ownership_precise"] = true
	flags["m12_metric_l2_windowed"] = true
	_town.set("_month12_flags", flags)
	_fill_activity_log()
	# 跳月探针不走开局那一屏，自评直接塞进去：故意把情绪稳定说成"不太符合"，
	# 好让报告里"你选的档位"和"记录里看到的"两种关系都出现一次。
	_town.set("_self_ratings", {"E": 5, "A": 5, "C": 5, "N": 2, "O": 4})
	_town.call("_open_month12_report")
	await _wait(1.0)
	_dump_report()
	await _shot("01_报告页")
	var page = _town.get("_report_panel")
	if page != null:
		var scroll: ScrollContainer = _first_scroll(page as Node) as ScrollContainer
		if scroll != null:
			# 折叠关着时先看到页面末尾（下一级要求 / 方向倾向），再展开文字版看依据。
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
			await _wait(0.5)
			await _shot("02_要求覆盖与方向")
			var toggle: Button = (page as Node).find_child("TwelveExpand", true, false) as Button
			if toggle != null:
				toggle.emit_signal("pressed")
				await _wait(0.5)
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value * 0.45)
			await _wait(0.5)
			await _shot("03_文字版展开")
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
			await _wait(0.5)
			await _shot("04_依据展开")
	print("YEAR_REPORT_DONE")
	get_tree().quit(0)


## 把报告每一句打到控制台：标点重复、占位没填上这类毛病，看字比看截图快。
func _dump_report() -> void:
	var builder = load("res://scripts/v12m/Month12Report.gd").new()
	var data: Dictionary = builder.call("build", _town)
	print("REPORT_HEADLINE ", String(data.get("headline", "")))
	for value in (data.get("personality", {}) as Dictionary).get("rows", []) as Array:
		var row := Dictionary(value)
		for line in (row.get("lines", []) as Array):
			print("REPORT_BT ", String(line))
	for value in (data.get("sections", []) as Array):
		var block := Dictionary(value)
		for line in (block.get("lines", []) as Array):
			print("REPORT_%s	%s" % [String(block.get("id", "")), String(line)])


func _fill_ledger() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var nodes: Array = (parsed as Dictionary).get("nodes", []) if parsed is Dictionary else []
	for value in nodes:
		var node := Dictionary(value)
		var month := int(node.get("month", 0))
		if month < 1 or month > 11:
			continue
		var choices := (node.get("choices", []) as Array)
		if choices.is_empty():
			continue
		_town.set("_month12_month", month)
		# 别永远选 A：轮着选，样张才能看出哪一维够、哪一维不够。
		_pick_turn += 1
		var index := _pick_turn % choices.size()
		if _force_pick >= 0 and _force_pick < choices.size():
			index = _force_pick
		var picked := Dictionary(choices[index])
		_town.call("_collect_competency", picked, String(node.get("id", "")), String(picked.get("id", "A")))
		var flags: Dictionary = _town.get("_month12_flags")
		for flag in (picked.get("flags", []) as Array):
			flags[String(flag)] = true
		_town.set("_month12_flags", flags)
	_town.set("_month12_month", 6)
	_town.call("_evaluate_probation")


## 自由活动那本账：用 activities.json 里真有的项目名补三个月的安排，
## 让报告里"花在了哪些地方""哪几个月没安排"这两句走真实分支，而不是永远走空。
func _fill_activity_log() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ACTIVITIES_PATH))
	var items: Array = (parsed as Dictionary).get("activities", []) if parsed is Dictionary else []
	var names: Array = []
	for value in items:
		var title := String(Dictionary(value).get("name", "")).strip_edges()
		if not title.is_empty() and not names.has(title):
			names.append(title)
	var log: Array = []
	var cursor := 0
	for month in [2, 5, 8]:
		if cursor + 1 >= names.size():
			break
		log.append({
			"month": month,
			"entries": [
				{"what": String(names[cursor]), "ap": 1, "mood": 0},
				{"what": String(names[cursor + 1]), "ap": 1, "mood": 0},
			],
		})
		cursor += 2
	_town.set("_year_activity_log", log)
	# 活动那本账直接塞的话，信号也得照游戏自己的记法补进 B_t 流水。
	for value in items:
		var activity := Dictionary(value)
		_town.call("_append_bt_signals", activity.get("btSignals"), String(activity.get("id", "")), "", "activity")


func _first_scroll(node: Node) -> Variant:
	if node is ScrollContainer:
		return node
	for child in node.get_children():
		var hit: Variant = _first_scroll(child)
		if hit != null:
			return hit
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("SHOT ", shot_name, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + _tag + ".png")))
