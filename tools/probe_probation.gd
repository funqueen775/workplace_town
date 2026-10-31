extends Node
## 判定两条路都验一遍：好路径 → 通过；差路径 → 延期，第七月收尾。
func _ready() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.4).timeout
	# ① 好路径
	town.set("_dim_anchors", {"S": [4], "O": [3], "N": [4], "D": [4]})
	print("[判定] 好路径 → ", town.call("_evaluate_probation"))
	# ② 差路径
	town.set("_dim_anchors", {"S": [2], "O": [2], "N": [1], "D": [2]})
	var flags: Dictionary = town.get("_month12_flags")
	flags.erase("m06_probation_status")
	print("[判定] 差路径 → ", town.call("_evaluate_probation"),
		" · 延期旗标=", bool((town.get("_month12_flags") as Dictionary).get("m07_probation_deferred", false)))
	# ③ 延期收尾
	town.set("_month12_month", 7)
	town.call("_end_year_early")
	print("[判定] 收尾后 phase=", town.get("_month12_phase"),
		" 任务卡=", town.get("_town_ui_v2").get("_task_title").text,
		" 副行=", town.get("_town_ui_v2").get("_task_note").text)
	get_tree().quit()
