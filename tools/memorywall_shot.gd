extends Control

## 心湖记忆墙开窗自检：连拍 空墙 / 满墙 / 点开一张 三张图。
## 造句子用的是事件目录里真实的 memoryNote / outcome 文案，
## 但**只走 show_records()，不碰磁盘** —— 玩家的真实存档一个字节都不动。
const SHOT_DIR := "res://test_artifacts/memorywall_shots"

var _wall


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_wall = load("res://scripts/MemoryWallPanel.gd").new()
	add_child(_wall)
	await _wait(0.5)

	_wall.show_records([])
	await _wait(0.4)
	await _shot("00_empty")

	_wall.show_records(_sample())
	await _wait(0.5)
	await _shot("01_wall")

	# 点开第 7 张（金便签）：它旁边那张是默认选中的灰便签，
	# 同一屏里能同时看到"被拿起来的那张"和"还贴在墙上的那张"。
	_wall._select(6)
	await _wait(0.4)
	await _shot("02_review")

	get_tree().quit()


## 便签一律取十二个月那份事件表里的真数据（data/story/v12m/events.json）：
## 事件名、月份、选项文案、结果、便签原文、金/灰，全都不是手写的。
## 以前这里读的是旧 48 个月目录（WorldClock.MAIN_EVENTS），实拍里于是冒出
## 「第 42 月 · 吹哨两难」这种十二个月里根本不存在的条目 —— 预览给人看的
## 必须是玩家真会见到的东西。
func _sample() -> Array:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	var nodes: Array = (raw as Dictionary).get("nodes", []) if raw is Dictionary else []
	var records: Array = []
	var minute := 0
	var last_tone := ""
	for value in nodes:
		var node := Dictionary(value)
		var notes: Dictionary = node.get("memoryNote", {})
		if notes.is_empty():
			continue
		var month := int(node.get("month", 0))
		if month < 1 or month > 12:
			continue
		# 一墙要有金有灰才看得出两种纸：这一条优先挑跟上一张不同色的选项。
		var pick_id := ""
		for key in notes.keys():
			var candidate := String(Dictionary(notes[key]).get("tone", "gold"))
			if pick_id.is_empty() or (candidate != last_tone and String(Dictionary(notes[pick_id]).get("tone", "gold")) == last_tone):
				pick_id = String(key)
		if pick_id.is_empty():
			continue
		var note := Dictionary(notes[pick_id])
		var choice_text := ""
		var outcome := ""
		for item in node.get("choices", []) as Array:
			var choice := Dictionary(item)
			if String(choice.get("id", "")) == pick_id:
				choice_text = String(choice.get("text", ""))
				outcome = String(choice.get("outcome", ""))
				break
		minute += 60 * 24 * 4
		records.append({
			"eventId": String(node.get("id", "")),
			"eventTitle": String(node.get("title", "")),
			"month": month,
			"phase": String(node.get("phase", "")),
			"choiceId": pick_id,
			"choiceText": choice_text,
			"text": String(note.get("text", "")),
			"tone": String(note.get("tone", "gold")),
			"outcome": outcome,
			"worldMinute": minute,
		})
		last_tone = String(note.get("tone", "gold"))
		if records.size() >= 9:
			break
	return records


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/wall_%s.png" % [SHOT_DIR, name])
	var error := image.save_png(path)
	print("shot %s -> %s (%s)" % [name, path, error])
