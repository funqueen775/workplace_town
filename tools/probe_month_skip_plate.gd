extends Node
## 验「翻月过场被点掉之后，日期牌上的月份还对不对」：
## 跳月 → 过场刚起来就 request_skip（等于玩家点了一下）→ 打印牌面与日期记录；
## 再跳一次不点，做对照。

func _ready() -> void:
	var town = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.5).timeout
	print("[起点] ", _line(town))
	town.call("debug_jump_to_month", 4)
	await get_tree().create_timer(0.15).timeout
	print("[跳到第4月，过场 0.15s] ", _line(town))
	var wipe = town.get("_wipe")
	wipe.call("request_skip")
	await get_tree().create_timer(0.6).timeout
	print("[点掉之后 0.6s] ", _line(town))
	await get_tree().create_timer(2.0).timeout
	print("[点掉之后 2.6s] ", _line(town))
	town.call("debug_jump_to_month", 5)
	await get_tree().create_timer(3.0).timeout
	print("[跳到第5月，不点，3s] ", _line(town))
	get_tree().quit()


func _line(town) -> String:
	var ui = town.get("_town_ui_v2")
	var plate := "（无面板）"
	if ui != null:
		plate = "%s·%s·%s" % [
			ui.call("date_month_cell").text,
			ui.call("date_xun_cell").text,
			ui.call("date_band_cell").text,
		]
	return "剧情月=%s phase=%s 日期记录=%s/%s/%s 牌面=%s 过场中=%s" % [
		town.get("_month12_month"), town.get("_month12_phase"),
		town.get("_date_month"), town.get("_date_xun"), town.get("_date_band"),
		plate, str(town.call("wipe_playing")),
	]