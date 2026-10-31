extends Node
## 验开机那一刻的 HUD：日期牌 / 心情罐 / 手机钮 / 任务卡，和剧情真正所在的月份对不对得上。
##
## 用法（在 workplace_town 下）：
##   godot --headless --path . res://tools/probe_resume_hud.tscn
##     → 进游戏该是从第 1 月开始：剧情月份=1、牌面第一月、心情罐=false、手机=false
##   godot --headless --path . res://tools/probe_resume_hud.tscn -- --v12m-resume
##     → 走续玩半成品：接存档那一月，牌面必须也是那一月（不是第一月）

func _ready() -> void:
	var town = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(4.2).timeout
	var ui = town.get("_town_ui_v2")
	var plate := "（无面板）"
	var mood := "?"
	var phone := "?"
	var manual := "?"
	var task := "?"
	if ui != null:
		plate = "%s · %s · %s" % [
			ui.call("date_month_cell").text,
			ui.call("date_xun_cell").text,
			ui.call("date_band_cell").text,
		]
		var energy = ui.get("_energy_panel")
		if energy != null:
			mood = str(energy.visible)
		var phone_button = ui.get("_phone_button")
		if phone_button != null:
			phone = str(phone_button.visible)
		var manual_button = ui.get("_manual_button")
		if manual_button != null:
			manual = str(manual_button.visible)
		var title = ui.get("_task_title")
		var note = ui.get("_task_note")
		if title != null and note != null:
			task = "%s / %s" % [title.text, note.text]
	print("[HUD] 剧情月份=", town.get("_month12_month"),
		" phase=", town.get("_month12_phase"),
		" 日期记录=", town.get("_date_month"), "/", town.get("_date_xun"), "/", town.get("_date_band"),
		" 日期牌=", plate,
		" 心情罐=", mood,
		" 手机=", phone,
		" 手册=", manual,
		" 任务卡=", task)
	get_tree().quit()