extends Node
## 验续玩：开机后打印落在哪个月、心情几、什么阶段。
## 续玩默认关（存档功能未上线），要验这条路得加 `-- --v12m-resume`，否则一律第 1 月。

func _ready() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(4.2).timeout
	print("[续玩] 月份=", town.get("_month12_month"),
		" 心情=", town.get("_mood"), "/", town.get("_mood_max"),
		" phase=", town.get("_month12_phase"))
	get_tree().quit()
