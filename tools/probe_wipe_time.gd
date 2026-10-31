extends Control

## 时间过场到底多长：不截图，一档一档播完再量，量的是玩家等的秒数。
## 截图那张（shot_date_transitions）存盘会卡帧，量出来的数会虚高半秒。
## 用法：V12M_WIPE_TIME=1 <godot> --path <PROJ> res://tools/probe_wipe_time.tscn

func _ready() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	var wipe = town.get("_wipe")
	if wipe == null:
		print("[probe] 没有过场层")
		get_tree().quit()
		return
	wipe.quality = 0
	wipe.style = 0
	print("[probe] TIME_SCALE=", wipe.get_script().get_script_constant_map().get("TIME_SCALE"))
	# 面板必须真关掉：只是藏起来的话，派读数会被"等面板关掉"那道门禁攒住。
	var panel = town.get("_story_event_panel")
	if panel != null:
		panel.call("dismiss")
		panel.visible = false
	var tour = town.get("_hud_tour")
	if tour != null:
		tour.visible = false
	await get_tree().create_timer(0.6).timeout
	# 每一档播两遍：第一遍常有排队/首帧开销，第二遍才是玩家连续看到的那个长度。
	for step in [
		["上旬→中旬（跨旬）", [1, "mid", "morning", -1]],
		["中旬→下旬（跨旬·镜像）", [1, "late", "morning", -1]],
		["白天→夜晚（昼夜光带）", [1, "late", "night", -1]],
		["第 1 月→第 2 月（翻月）", [2, "early", "morning", 2]],
	]:
		for round in 2:
			var started := Time.get_ticks_msec()
			town.callv("push_date", step[1] as Array)
			for i in 200:
				await get_tree().create_timer(0.02).timeout
				if not bool(town.call("wipe_playing")):
					break
			print("[probe] %-22s 第 %d 遍 = %.2f 秒" % [
				String(step[0]), round + 1, float(Time.get_ticks_msec() - started) / 1000.0,
			])
	get_tree().quit()
