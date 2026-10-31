extends Node

## 查「两扇门挨在一起」这件事：把某个月镇上已经立起来的去处门全打出来，
## 再把镜头摆到指定坐标拍一张，肉眼对一下用户截图里那两圈黄光是谁。
## 用法：<godot> --path <proj> --resolution 1280x800 res://tools/portal_pair_probe.tscn -- --v12m-month=11 --at=840,860

func _ready() -> void:
	_watchdog()
	var month := 11
	var at := Vector2(840, 860)
	var lit_ids: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--v12m-month="):
			month = int(arg.substr(13))
		elif arg.begins_with("--at="):
			var parts := arg.substr(5).split(",")
			if parts.size() == 2:
				at = Vector2(float(parts[0]), float(parts[1]))
		elif arg.begins_with("--lit="):
			# 点亮指定的门（模拟自由活动期的黄光），如 --lit=m1_lakeside,m7_valley
			for piece in arg.substr(6).split(","):
				if not piece.is_empty():
					lit_ids.append(piece)
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(4.0).timeout
	var start_panel = town.get("_month12_start_panel")
	if start_panel != null and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await get_tree().create_timer(0.8).timeout
	town.call("debug_jump_to_month", month, "A")
	await get_tree().create_timer(2.5).timeout
	# 跳月会把"月初那一张"重新打开，先关掉，不然镜头全被卡挡住。
	var month_card = town.get("_month12_start_panel")
	if month_card != null and bool(month_card.call("is_open")):
		month_card.emit_signal("continued")
		await get_tree().create_timer(1.0).timeout
	# 把这一月能立起来的门都立起来（跳月已经补了前几个月的账，这里只兜一层）。
	var places: Array = town.get("_month12_places")
	for value in places:
		if value is Dictionary:
			town.call("_ensure_month12_place", String((value as Dictionary).get("id", "")))
	await get_tree().create_timer(0.6).timeout
	if not lit_ids.is_empty():
		# 模拟自由活动窗口：门只在 places_open 且窗口开着时才是黄光。
		town.set("_month12_places_open", true)
		town.set("_month12_phase", "month_nodes")
		for lit_id in lit_ids:
			var unlocked: Dictionary = town.get("_month12_unlocked_places")
			unlocked[String(lit_id)] = true
		town.call("_refresh_month12_place_seals")
		await get_tree().create_timer(0.4).timeout

	var portals: Dictionary = town.get("_month12_place_portals")
	print("---- 门 %d 扇（第 %d 月补账后） ----" % [portals.size(), month])
	var rows: Array = []
	for key in portals.keys():
		var door: Node2D = portals[key] as Node2D
		if door == null or not is_instance_valid(door):
			continue
		var place: Dictionary = town.call("_month12_place_by_id", String(key))
		rows.append([String(key), String(place.get("name", "")), door.position])
	rows.sort_custom(func(a, b): return (a[2] as Vector2).y < (b[2] as Vector2).y)
	for row in rows:
		print("  %-14s %-10s (%.0f, %.0f)" % [row[0], row[1], (row[2] as Vector2).x, (row[2] as Vector2).y])
	print("---- 相距 < 260 的门对 ----")
	for i in rows.size():
		for j in range(i + 1, rows.size()):
			var d: float = (rows[i][2] as Vector2).distance_to(rows[j][2] as Vector2)
			if d < 260.0:
				print("  %s(%.0f,%.0f)  ×  %s(%.0f,%.0f)   = %.0f px" % [
					rows[i][0], (rows[i][2] as Vector2).x, (rows[i][2] as Vector2).y,
					rows[j][0], (rows[j][2] as Vector2).x, (rows[j][2] as Vector2).y, d])

	var player = town.get("_player")
	# 复刻 _show_month12_place_list 的筛选：进门后这个区清单里会有谁。
	var unlocked: Dictionary = town.get("_month12_unlocked_places")
	var all_places: Array = town.get("_month12_places")
	for zone_code in ["E"]:
		var names: Array = []
		for value in all_places:
			if not (value is Dictionary):
				continue
			var act := value as Dictionary
			if String(act.get("locationId", "")) != zone_code:
				continue
			var pid := String(act.get("id", ""))
			if town.get("_month12_place_portals").has(pid) or unlocked.has(pid):
				names.append("%s(%s)" % [act.get("name", ""), pid])
		print("---- 进 %s 区清单能列出的去处 ----\n  %s" % [zone_code, " / ".join(names)])
	if player != null:
		player.position = at
	await get_tree().create_timer(1.2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var dir := ProjectSettings.globalize_path("res://test_artifacts/portal_pair")
		DirAccess.make_dir_recursive_absolute(dir)
		var path := "%s/m%02d_at_%d_%d.png" % [dir, month, int(at.x), int(at.y)]
		get_viewport().get_texture().get_image().save_png(path)
		print("[shot] ", path)
	get_tree().quit(0)


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	print("WATCHDOG forced quit")
	get_tree().quit(1)
