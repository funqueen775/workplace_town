extends Node

## 逐月扫一遍自由活动：这一月的池子里每一条，门立了没、解锁了没、在哪个区。
## 用法：<godot> --path . --headless res://tools/place_sweep_probe.tscn -- --no-resume

var _town: Node
var _done := false


func _ready() -> void:
	_watchdog()
	for month in [1, 3, 5, 7, 9, 11]:
		_town = load("res://Main.tscn").instantiate()
		add_child(_town)
		await get_tree().create_timer(2.6).timeout
		_town.call("debug_jump_to_month", month)
		await get_tree().create_timer(1.4).timeout
		var start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(1.0).timeout
		var opened: Dictionary = _town.get("_month12_place_portals")
		var unlocked: Dictionary = _town.get("_month12_unlocked_places")
		var places: Array = _town.get("_month12_places")
		var by_id := {}
		for value in places:
			by_id[String(Dictionary(value).get("id", ""))] = Dictionary(value)
		print("=== 第 ", month, " 月  门 ", opened.size(), " 扇  已解锁 ", unlocked.size(), " 处 ===")
		for aid in by_id:
			var act: Dictionary = by_id[aid]
			var has_door := opened.has(aid)
			var is_open := bool(unlocked.get(aid, false))
			if not has_door and not is_open:
				continue
			var zone_name := String(act.get("name", ""))
			var place_name := String(act.get("locationId", ""))
			var door_text := "有门" if has_door else "无门"
			var lock_text := "已解锁" if is_open else "未解锁"
			print("   %s | %s | %s | %s | %s" % [aid, zone_name, place_name, door_text, lock_text])
		var missing := 0
		for aid in opened:
			if not bool(unlocked.get(aid, false)):
				missing += 1
		print("   小结：立了门却没解锁的 ", missing, " 扇；解锁了却没门的 ", _open_without_door(unlocked, opened), " 处")
		_town.queue_free()
		await get_tree().create_timer(0.4).timeout
	print("PLACE_SWEEP_DONE")
	_done = true
	get_tree().quit(0)


func _open_without_door(unlocked: Dictionary, opened: Dictionary) -> int:
	var n := 0
	for aid in unlocked:
		if bool(unlocked[aid]) and not opened.has(aid):
			n += 1
	return n


func _watchdog() -> void:
	await get_tree().create_timer(240.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
