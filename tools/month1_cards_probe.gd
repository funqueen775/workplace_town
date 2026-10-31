extends Node

## 首月实机走一遍：手机、手册第一次亮出来之后，点它到底出不出讲解卡。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/month1_cards_probe.tscn

const WAIT_PER_STEP := 0.05

var _dir := "E:/03_Projects/bear/workplace_town/test_artifacts/month1_cards"
var _town: Node
var _ui: Node
var _done := false

## 手机：idle → clicked（点了圆钮）→ card（卡出来了）→ done
var _phone_stage := "idle"
var _manual_stage := "idle"
var _log: Array = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	_ui = _town.get("_town_ui_v2")
	var panel = _town.get("_story_event_panel")
	panel.reduced_motion = true
	# 月首卡：替玩家点"开始这一天"。
	_town.call("_on_month_start_continued")
	await _wait(0.6)

	for i in 1600:
		await _wait(WAIT_PER_STEP)
		var phase := String(_town.get("_month12_phase"))
		if int(_town.get("_month12_month")) >= 2:
			_note("已经进第 2 月，停手")
			break
		# 地点解锁卡先收掉：手机讲解卡是排在它后面弹的，不先收就看不见。
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			await _wait(0.35)
			unlock.call("_on_unlock_ok", "")
			continue
		await _handle_phone()
		await _handle_manual()
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(panel.call("is_open")):
			var stage := String(panel.get("_stage"))
			if stage == "choices":
				var ev: Dictionary = panel.get("_event")
				_note("三选一 %s｜选完会显示：%s" % [
					String(ev.get("id", "")), String(panel.call("_outcome_text", "A"))])
				panel.call("_on_choice_picked", String(ev.get("id", "")), "A", 45)
			elif stage != "interaction" and stage != "handbook":
				panel.call("_advance")
			continue
		if phase == "activity":
			_town.call("_on_end_month_pressed")
			continue
		if phase == "close":
			_town.call("_on_month12_close_finished")
			continue

	print("---- 首月卡片核对 ----")
	for line in _log:
		print("  ", line)
	print("PROBE_DONE ", _dir)
	_done = true
	get_tree().quit(0)


func _handle_phone() -> void:
	if _phone_stage != "idle":
		return
	var drawer = _town.get("_month_phone_panel")
	var button: Button = _ui.get("_phone_button")
	var card_up := drawer != null and bool((drawer.get("_card") as Control).visible)
	if card_up:
		_phone_stage = "card"
		_note("手机讲解卡自己弹了｜此刻右下角手机图标可见=%s｜卡上「稍后」还在=%s" % [
			button != null and button.visible,
			bool((drawer.get("_tutorial_later_button") as Button).visible)])
		await _wait(0.6)
		await _shot("手机_卡先于图标")
		drawer.call("open_phone")
		await _wait(0.9)
		var now: Button = _ui.get("_phone_button")
		_note("点了「打开手机」 → 收件箱开=%s 图标这时才出现=%s" % [
			bool(drawer.get("_phone_open")), now != null and now.visible])
		await _shot("手机_图标这时才出现")
		drawer.call("close_phone")
		_phone_stage = "done"
		return
	if button != null and button.visible:
		# 图标先亮了而卡不在：说明还是旧接法。
		_phone_stage = "done"
		_note("手机图标先亮了、卡不在前面（旧接法）")
		await _shot("手机_亮时没弹")


func _handle_manual() -> void:
	var button: Button = _ui.get("_manual_button")
	if _manual_stage == "idle":
		if button == null or not button.visible:
			return
		_manual_stage = "appeared"
		_note("手册亮了——先不点，看卡是不是自己就在")
		await _wait(0.8)
		var card = _town.get("_hud_button_tutorial")
		var shown := card != null and is_instance_valid(card) and bool(card.call("is_open"))
		_note("亮出来那一刻：讲解卡自己弹了=%s 手册页已开=%s" % [shown, _handbook_open()])
		await _shot("手册_亮的那一刻")
		_manual_stage = "card" if shown else "done"
		return
	if _manual_stage == "card":
		var card = _town.get("_hud_button_tutorial")
		if card == null or not is_instance_valid(card) or not bool(card.call("is_open")):
			_manual_stage = "done"
			return
		card.call("_on_open_pressed")
		await _wait(0.7)
		_note("点了卡上「打开手册」 → 手册页开=%s" % _handbook_open())
		await _shot("手册_打开后")
		if _handbook_open():
			var hb = _town.get("_month12_handbook")
			hb.call("close")
			await _wait(0.5)
		_manual_stage = "done"


func _handbook_open() -> bool:
	var hb = _town.get("_month12_handbook")
	return hb != null and is_instance_valid(hb) and bool(hb.call("is_open"))


func _note(text: String) -> void:
	_log.append("phase=%s｜%s" % [String(_town.get("_month12_phase")), text])
	print("[m1] ", _log[-1])


func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	if _done:
		return
	print("---- 首月卡片核对（超时收尾）----")
	for line in _log:
		print("  ", line)
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _dir + "/" + name + ".png"
	image.save_png(path)
	print("[shot] ", path)
