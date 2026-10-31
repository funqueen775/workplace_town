extends Node

## 月末回宿舍：走位超过 30 秒仍没到，顶上该钉出「宿舍在等你」，按一下就站到门口。
## 不跑整月，只把那一刻的状态摆出来，让 _update_month12_waypoint 自己判。
## 用法：<godot> --path <proj> res://tools/dorm_banner_probe.tscn

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(4.0)
	# 摆出"正在回宿舍、还没到、已经走了 31 秒"的样子（十二个月流程要开着，否则每帧的走位判定不跑）
	_town.set("_month12_active", true)
	_town.set("_month12_phase", "sleep_walk")
	_town.set("_walk_started_msec", Time.get_ticks_msec() - 31000)
	_town.set("_walk_skip_offered", false)
	_town.set("_month12_waypoint", Vector2(1200, 900))
	var player: Node2D = _town.get("_player")
	if player != null:
		player.position = Vector2(455, 500)
	await _wait(0.2)
	print("DORM 状态：active=%s phase=%s reading=%s pause=%s skip=%s 用了=%d ms" % [
		bool(_town.get("_month12_active")), String(_town.get("_month12_phase")),
		bool(_town.call("_month12_reading")), int(_town.get("_walk_pause_started_msec")),
		bool(_town.get("_walk_skip_offered")),
		Time.get_ticks_msec() - int(_town.get("_walk_started_msec")),
	])
	# 手动跑一帧判定：探针里不一定有 _process 驱动
	_town.call("_update_month12_waypoint")
	await _wait(0.4)
	var banner = _town.get("_gate_banner")
	print("DORM 30 秒后：横幅=%s" % ("在" if (banner != null and is_instance_valid(banner)) else "无"))
	# 点它 = 直接到门口
	_town.call("_skip_walk_to_dorm")
	await _wait(0.3)
	var after = _town.get("_gate_banner")
	print("DORM 点过之后：横幅=%s 人在=%s" % [
		"在" if (after != null and is_instance_valid(after)) else "无",
		str((player.position as Vector2).round()) if player != null else "-",
	])
	print("DORM_DONE")
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
