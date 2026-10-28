extends Node

## F8 跳月键位探针：不靠直接调函数，而是往输入队列里塞一次真按键，
## 验玩家按得动的那个入口（_unhandled_input）确实通。

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.4).timeout
	print("开局在第 %d 月" % int(_town.get("_month12_month")))
	await _press(KEY_F8, false)
	print("按一次 F8 → 第 %d 月（翻月过场 %s）" % [
		int(_town.get("_month12_month")), "在播" if bool(_town.call("wipe_playing")) else "播完"])
	await _press(KEY_F8, false)
	print("再按一次 F8 → 第 %d 月" % int(_town.get("_month12_month")))
	await _press(KEY_F8, true)
	print("Shift+F8 → 第 %d 月" % int(_town.get("_month12_month")))
	var levels: Array = _town.call("ability_display_levels")
	print("档案五格读数：%s" % JSON.stringify(levels))
	print("KEY_PROBE_DONE")
	get_tree().quit(0)


func _press(keycode: int, shift: bool) -> void:
	var down := InputEventKey.new()
	down.keycode = keycode
	down.physical_keycode = keycode
	down.pressed = true
	down.shift_pressed = shift
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.keycode = keycode
	up.physical_keycode = keycode
	up.pressed = false
	up.shift_pressed = shift
	Input.parse_input_event(up)
	await get_tree().create_timer(2.6).timeout
