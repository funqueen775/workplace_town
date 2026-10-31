extends Control
## 心情 / 行动点这两本账的验证书：把数字逼到边界上，看文案、压灰、月末那行账会不会跟着变。
##
## 用法：
##   <godot> --path <PROJ> --resolution 1600x900 res://tools/shot_ledger.tscn -- --dir E:/.../ledger

var _dir := "user://ledger"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	img.save_png(path)
	print("[shot] ", path)


func _state(town: Node, label: String) -> void:
	print("[ledger] %-18s 心情 %d/%d · 本月行动点 %d/%d · 已记 %d 笔" % [
		label, int(town.get("_mood")), int(town.get("_mood_max")),
		int(town.get("_month12_ap_left")), int(town.get("_ap_total")),
		(town.get("_month_ledger") as Array).size(),
	])


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	panel.call("dismiss")
	panel.visible = false
	var tour = town.get("_hud_tour")
	if tour != null:
		tour.visible = false
	await get_tree().create_timer(0.5).timeout
	# ① 开局：第一个月直接用 hInit，不再 +1。
	_state(town, "第 1 月月初")
	await _shot("01_首月_读数不登场")

	# ② 逼到很累：确认页那句"加倍消耗"必须读的是真心情，不是写死的 3。
	town.set("_mood", 1)
	# ③ 顺手把 HUD 刷新走一遍（平时由结算触发）
	town.call("_refresh_mood_hud")
	var tool: Dictionary = town.call("_month12_place_by_id", "m1_tool")
	var rooftop: Dictionary = town.call("_month12_place_by_id", "m1_rooftop")
	var visit = town.get("_month12_place_panel")
	visit.call("show_confirm", rooftop, 1)
	await get_tree().create_timer(0.5).timeout
	await _shot("02_确认页_心情1")
	print("[ledger] 小工具 hCost=", tool.get("hCost"), " 天台 hCost=", rooftop.get("hCost"),
		" 天台给回=", (rooftop.get("stateDelta", {}) as Dictionary).get("H", 0))

	# ④ 心情 0：不做事的去处压灰，能缓过来的那处还能按。
	visit.call("close")
	await get_tree().create_timer(0.35).timeout
	town.set("_mood", 0)
	town.call("_show_month12_place_list", "B")
	await get_tree().create_timer(0.4).timeout
	await _shot("03_列表_只能缓一缓")
	print("[ledger] 天台算不算缓一缓=", bool(town.call("_restores_mood", rooftop)),
		" 小工具算不算=", bool(town.call("_restores_mood", tool)))

	# ⑤ 结算一笔：天台给回 1 点，账本上要有这一笔。
	town.set("_mood", 2)
	town.set("_month12_activity_taken", false)
	town.call("_on_month12_place_confirmed", "m1_rooftop")
	await get_tree().create_timer(0.6).timeout
	_state(town, "做完天台")
	if visit != null:
		visit.call("close")
	var scene = town.get("_weekend_scene_panel")
	if scene != null:
		for i in 8:
			if not bool(scene.call("is_open")):
				break
			scene.call("_advance")
			await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(0.3).timeout

	# ⑥ 月末卡上那行账。
	print("[ledger] 月末卡那行 = ", String(town.call("_month_ledger_line")))
	town.call("_after_month12_night_card")
	await get_tree().create_timer(1.0).timeout
	await _shot("04_月末卡_带账")

	# ⑦ 翻月：月初回 1 点封顶；第 2 月没有个人时间，行动点应当是 0。
	town.call("_start_month_nodes", 2)
	await get_tree().create_timer(1.2).timeout
	_state(town, "第 2 月月初")

	# ⑦b 读数登场那一屏 + 第 2 月新解锁的那页手册（1.3；心情那本账不在手册里了）
	await _shot("05_第2月_读数登场")
	town.call("_open_month12_handbook")
	await get_tree().create_timer(0.6).timeout
	var book = town.get("_month12_handbook")
	if book != null:
		book.call("_select_chapter", "1.3")
		await get_tree().create_timer(0.7).timeout
		await _shot("06_手册_1.3")
		book.call("close")
		await get_tree().create_timer(0.3).timeout

	# ⑧ 主线那一笔：E04 选 A 是 S+2 / H-1，心情要真的掉。
	# 把播放器当前这一屏摆成 E04，走的就是玩家点选项那条真路径。
	var runner = town.get("_month_runner")
	for value in (town.call("_load_month_nodes", 2) as Array):
		if String((value as Dictionary).get("id", "")) == "E04":
			runner.current = value
			break
	var before := int(town.get("_mood"))
	town.call("_runner_record_choice", "A")
	print("[ledger] E04 选 A 前后心情：", before, " → ", int(town.get("_mood")))
	_state(town, "记完这一笔")
	# ⑧b 埋点：结算与月末收束到底发出去了什么（ApiClient 本地队列里最后几条）
	var queue: Array = ApiClient.get("_queue")
	for entry in queue.slice(maxi(0, queue.size() - 3)):
		print("[event] ", JSON.stringify(entry))
	# ⑨ 顺手验一眼地名牌：十二个月这条线不该再挂旧 48 个月那批（市场部 / 行政部…）。
	var zones: Array = town.get("ZONES")
	for zone in zones:
		if String((zone as Dictionary).get("code", "")) == "G":
			(town.get("_player") as Node2D).position = ((zone as Dictionary)["rect"] as Rect2).get_center()
			break
	await get_tree().create_timer(0.8).timeout
	var shown := 0
	for marker in (town.get("_location_markers") as Array):
		if (marker as CanvasItem).visible:
			shown += 1
	var names: Array = []
	for marker in (town.get("_location_markers") as Array):
		if (marker as CanvasItem).visible:
			names.append(marker.name)
	# ⑩ 心情读数什么时候登场：首月不亮，第 2 月月初亮。
	var hud = town.get("_town_ui_v2")
	var jar = hud.get("_energy_panel")
	print("[ledger] 读数登场节奏：首月亮过吗=", bool(town.get("_mood_meter_lit")),
		" 现在(第 2 月)=", (jar as Control).visible)
	# ⑪ 睡觉兜底：心情 1、这个月还剩一格没花 → 那格自动拿去睡觉，回 1 点。
	town.set("_mood", 1)
	town.set("_month12_activity_generic", false)
	town.set("_month12_activity_taken", false)
	town.set("_month_ledger", [])
	town.call("_settle_sleep_backup")
	print("[ledger] 睡觉兜底：心情 1 + 剩 1 格 → ", int(town.get("_mood")),
		" · 账本 ", JSON.stringify(town.get("_month_ledger")))
	# ⑫ 不该咬的时候别咬：心情 3 时同样的剩格不该变成睡觉。
	town.set("_mood", 3)
	town.set("_month_ledger", [])
	town.call("_settle_sleep_backup")
	print("[ledger] 心情 3 + 剩 1 格 → ", int(town.get("_mood")),
		" · 账本 ", JSON.stringify(town.get("_month_ledger")))

	print("[ledger] 站在 G 区里 · month12=", bool(town.get("_month12_active")),
		" · 挂出来的旧地名牌 = ", shown, " ", str(names))
	await _shot("09_地名牌_不再打架")
	print("[done]")
	get_tree().quit()
