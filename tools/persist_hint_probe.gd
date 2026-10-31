extends Node

## 数据里 persist=true 的提示（"跟着王哥走"这条带着 dismissOn: first_move）
## 现在该钉住不消失，玩家一动就自己收。
## 用法：<godot> --path <proj> res://tools/persist_hint_probe.tscn

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	_town.call("debug_jump_to_month", 1, "A")
	await _wait(2.6)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
	await _wait(2.2)
	_report("月首卡收掉之后")
	# 造一次"玩家按了方向键"
	_town.call("_notice_hint", "first_move", "")
	await _wait(0.4)
	_report("玩家一动之后")
	print("PERSIST_DONE")
	get_tree().quit(0)


func _report(tag: String) -> void:
	var banner = _town.get("_gate_banner")
	var hint: Dictionary = _town.get("_gate_banner_hint")
	print("PROBE[%s] 横幅=%s 是哪条=%s 收条件=%s" % [
		tag, "在" if (banner != null and is_instance_valid(banner)) else "无",
		String(hint.get("id", "-")), String(hint.get("dismissOn", "-")),
	])


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
