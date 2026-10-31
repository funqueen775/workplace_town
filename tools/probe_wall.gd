extends Node
## 验第 6 月那面墙与"挑主讲那张"：
## ① 墙上列出真实便签 ② 挑的选项文案是便签内容 ③ 便签不够时空白选项消失 ④ 答辩引用挑中的那张
## 用法：<godot> --headless --path . res://tools/probe_wall.tscn

var _by := {}

func _ready() -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	for value in ((raw as Dictionary).get("nodes", []) as Array):
		_by[String((value as Dictionary).get("id", ""))] = value
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	print("[路径] user:// -> ", ProjectSettings.globalize_path("user://"))
	# 新开一局会清空记忆墙，所以等启动完再写三条假的。
	var f := FileAccess.open("user://workplace_town_memos.jsonl", FileAccess.WRITE)
	if f != null:
		for row in [
			{"month": 2, "text": "两条路我都跑过才选的。"},
			{"month": 3, "text": "客户问能不能写，我说能做的写、做不到的写明兜底。"},
			{"month": 5, "text": "凌晨两点，我走了紧急通道，工单第二天补。"},
		]:
			f.store_line(JSON.stringify(row, ""))
		f.close()
	print("[探针] 便签条数 = ", (town.call("_read_recent_memos", 4) as Array).size())
	_dump(town, "M06_WALL", "墙")
	_dump(town, "M06_PICK", "挑选")
	# 假设玩家挑了第一张，看答辩那句
	var flags: Dictionary = town.get("_month12_flags")
	flags["m06_main_1"] = true
	flags["m05_night_waited"] = true
	_dump(town, "M06_DEF3", "答辩")
	_dump(town, "M12_REPLAY", "回放")
	get_tree().quit()


func _dump(town: Node, node_id: String, title: String) -> void:
	var data: Dictionary = town.call("_runner_story_data", _by.get(node_id, {}))
	print("== ", title, "（", node_id, "）拍 ", (data.get("beats", []) as Array).size(),
		" / 选项 ", (data.get("choices", []) as Array).size())
	for beat in (data.get("beats", []) as Array):
		var t := String((beat as Dictionary).get("text", ""))
		if node_id in ["M06_DEF3", "M12_REPLAY"] or t.contains("第") or t.contains("空着"):
			print("   · ", t.left(70))
	for c in (data.get("choices", []) as Array):
		print("   [", String((c as Dictionary).get("id", "")), "] ", String((c as Dictionary).get("text", "")).left(56))
