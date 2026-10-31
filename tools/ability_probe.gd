extends Node

## 只问一件事：开局档案那一屏，五格到底是几。打印真值，不改任何东西。

const MAIN_SCENE := preload("res://Main.tscn")


func _ready() -> void:
	print("user_data_dir = ", OS.get_user_data_dir())
	var town: Node = MAIN_SCENE.instantiate()
	add_child(town)
	print("第 0 帧 flags 里的 peak_ = ", _peaks(town), " 月=", int(town.get("_month12_month")))
	await get_tree().process_frame
	print("第 1 帧 flags 里的 peak_ = ", _peaks(town), " 月=", int(town.get("_month12_month")))
	for i in 30:
		await get_tree().process_frame
	print("第 31 帧 flags 里的 peak_ = ", _peaks(town), " 月=", int(town.get("_month12_month")))
	var ui: Node = town.get("_town_ui_v2")
	var snapshot: Dictionary = ui.call("_profile_snapshot")
	print("档案 abilities = ", str(snapshot.get("abilities", [])))
	print("城镇 ability_display_levels = ", str(town.call("ability_display_levels")))
	print("本地攒点 = ", str(town.get("_ability_points")))
	print("flags 里的 peak_ =", _peaks(town))
	town.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _peaks(town: Node) -> String:
	var flags: Dictionary = town.get("_month12_flags")
	var out: Array = []
	for key in flags.keys():
		if String(key).begins_with("peak_"):
			out.append(String(key))
	return ", ".join(out) if not out.is_empty() else "无"
