extends Node

## 同区连屏的衔接核对：第 2 月那四屏都在 B 区工位那张桌子上演（第三天夜里 → 第四天 → 第七天夜里 → 改动说明那一栏），
## 以前屏末一句都没有，玩家看到的就是"文字突然换成另一件事"。
## 现在看：每一屏的最后一拍有没有把玩家交到下一屏手上、屏幕上的时段读数跟不跟得上。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/same_scene_bridge_probe.tscn -- --month=2 --screens=M02_NIGHT_1,M02_DAY_2,M02_WEEK_7

var _town: Node
var _month := 2
var _screens := ["M02_NIGHT_1", "M02_DAY_2", "M02_WEEK_7"]


func _ready() -> void:
	_watchdog()
	_read_args()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.4)
	_town.call("debug_jump_to_month", _month, "A")
	await _wait(2.2)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await _wait(1.0)
	var runner = _town.get("_month_runner")
	var nodes: Array = _town.call("_load_month_nodes", _month) as Array
	var by_id := {}
	for i in nodes.size():
		by_id[String((nodes[i] as Dictionary).get("id", ""))] = i
	runner.set("nodes", nodes)
	runner.set("month", _month)
	runner.set("active", true)
	runner.set("current", {})
	var panel = _town.get("_story_event_panel")
	panel.set("reduced_motion", true)

	for screen_id in _screens:
		var pos := int(by_id.get(String(screen_id), -1))
		if pos < 0:
			print("[bridge] 找不到节点 ", screen_id)
			continue
		var node: Dictionary = (nodes[pos] as Dictionary).duplicate(true)
		# 播放器往后看一眼才知道"下一屏在哪儿、什么时候"。
		runner.set("index", pos + 1)
		runner.set("waiting_walk", false)
		var ui: Node = _town.get("_town_ui_v2")
		var band := ""
		var xun := ""
		if ui != null and is_instance_valid(ui):
			band = String((ui.call("date_band_cell") as Control).text)
			xun = String((ui.call("date_xun_cell") as Control).text)
		_town.call("runner_present_story", node)
		# 跨旬卡带 gapText 时先亮「两周后」再换字，整段 2.6 秒左右；
		# 固定等 1.6 秒会读到换到一半的旧旬，所以等过场真的播完再读，
		# 顺手把卡上先后出现过的大字记下来（gapText 那一拍就在这里面）。
		var cards: Array[String] = []
		await _wait(0.3)
		for i in 200:
			await get_tree().create_timer(0.05).timeout
			var wipe = _town.get("_wipe")
			if wipe != null:
				var big: Label = wipe.get("_big")
				if big != null and not String(big.text).is_empty() \
						and (cards.is_empty() or cards[cards.size() - 1] != String(big.text)):
					cards.append(String(big.text))
			if not bool(_town.call("wipe_playing")):
				break
		await _wait(0.2)
		var ev: Dictionary = _town.get("_story_event")
		var beats: Array = ev.get("beats", [])
		var last := ""
		if not beats.is_empty():
			last = String((beats[beats.size() - 1] as Dictionary).get("text", ""))
		var band_now := ""
		if ui != null and is_instance_valid(ui):
			band_now = String((ui.call("date_band_cell") as Control).text)
		var clock := String(panel.call("clock_text"))
		print("[bridge] %s | 数据时段=%s | 屏上读数 %s→%s %s | 卡上时间戳=%s | 卡上大字=%s | 末句=%s" % [
			screen_id, String(node.get("timeBand", "")), band, band_now, xun, clock,
			" → ".join(cards), last])
		panel.call("dismiss")
		await _wait(0.6)

	print("[bridge] 核对完毕")
	get_tree().quit(0)


func _read_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--month="):
			_month = int(arg.trim_prefix("--month="))
		elif arg.begins_with("--screens="):
			_screens = arg.trim_prefix("--screens=").split(",", false)


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
