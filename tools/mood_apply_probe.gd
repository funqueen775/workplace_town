extends Node

## 节点级扣心情这条线通不通：直接喂一个夜间节点给城镇，看心情掉不掉、账记不记。
## 用法：<godot> --path . --headless res://tools/mood_apply_probe.tscn -- --no-resume

var _done := false


func _ready() -> void:
	_watchdog()
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	print("[mood] 起手心情=", town.get("_mood"), "/", town.get("_mood_max"))
	town.call("_apply_node_mood", {"title": "夜里加班", "stateDelta": {"H": -1}})
	print("[mood] 扣一格之后=", town.get("_mood"))
	town.call("_apply_node_mood", {"title": "白天那屏", "stateDelta": {}})
	print("[mood] 没写 stateDelta 的节点之后=", town.get("_mood"))
	town.call("_apply_node_mood", {"title": "夜里加班", "stateDelta": {"H": -1}})
	town.call("_apply_node_mood", {"title": "夜里加班", "stateDelta": {"H": -1}})
	town.call("_apply_node_mood", {"title": "夜里加班", "stateDelta": {"H": -1}})
	town.call("_apply_node_mood", {"title": "夜里加班", "stateDelta": {"H": -1}})
	print("[mood] 连扣到底=", town.get("_mood"), "（不能是负数）")
	var ledger = town.get("_month_ledger")
	print("[mood] 本月账里记了几笔=", (ledger as Array).size())
	print("MOOD_APPLY_DONE")
	_done = true
	get_tree().quit(0)


func _watchdog() -> void:
	await get_tree().create_timer(40.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
