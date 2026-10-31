extends Node

## 记忆墙按局分：新开局要把上一局（含旧 48 个月回填）的便签清掉，
## 本局贴的张张带编号，外局的读不上来；日期写"第 N 月 · 上/中/下旬"。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/wall_per_run_probe.tscn

const MEMO := "user://workplace_town_memos.jsonl"

var _done := false


func _ready() -> void:
	_watchdog()
	_pollute()
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await _wait(3.0)
	print("[wall] 开局前文件在吗=", FileAccess.file_exists(MEMO))
	print("[wall] 本局编号=", int(town.get("_run_stamp")), " 开局后文件在吗=", FileAccess.file_exists(MEMO))

	# 本局贴两张。
	town.call("_on_memo_recorded", "E02", {"month": 1, "phase": "early", "text": "第一条", "tone": "gold", "worldMinute": 10})
	town.call("_on_memo_recorded", "E41", {"month": 11, "phase": "mid", "text": "第十一条", "tone": "gray", "worldMinute": 20})
	# 混一张外局的进去，墙不该读它。
	_append({"eventId": "OUTSIDE", "month": 37, "phase": "early", "text": "外局的", "tone": "gold",
		"worldMinute": 1, "runStamp": 999999})

	var wall = town.get("_memory_wall")
	town.call("_open_memory_wall")
	await _wait(0.8)
	var notes: Array = wall.get("_notes")
	print("[wall] 墙上张数=", notes.size(), "（应为 2：本局两张，外局那张不该进来）")
	for row in notes:
		print("   · ", wall.call("_date_text", row), " ｜", String(Dictionary(row).get("text", "")))
	await _shot("记忆墙_本局")
	town.call("_on_memory_wall_closed")

	# 续玩：存档里的编号要原样接回来，不能重发（重发等于把这一局的墙清了）。
	town.call("_save_month12_progress", true)
	var stamp := int(town.get("_run_stamp"))
	town.set("_run_stamp", 0)
	town.call("_adopt_run_stamp", stamp)
	print("[wall] 续玩接回编号=", int(town.get("_run_stamp")), " 与原来一致=", int(town.get("_run_stamp")) == stamp)
	# 老存档没编号：第一次续玩该重发并清墙。
	town.call("_adopt_run_stamp", 0)
	print("[wall] 老存档无编号 → 重发=", int(town.get("_run_stamp")) != 0, " 文件已清=", not FileAccess.file_exists(MEMO))
	print("PROBE_DONE")
	_done = true
	get_tree().quit(0)


func _pollute() -> void:
	var file := FileAccess.open(MEMO, FileAccess.WRITE)
	if file == null:
		print("[wall] 写不了测试文件")
		return
	for row in [
		{"eventId": "OLD_A", "month": 37, "text": "旧 48 个月的", "tone": "gold", "worldMinute": 1},
		{"eventId": "OLD_B", "month": 48, "text": "旧 48 个月的", "tone": "gray", "worldMinute": 2},
	]:
		file.store_line(JSON.stringify(row))
	file.close()


func _append(row: Dictionary) -> void:
	var file := FileAccess.open(MEMO, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(MEMO, FileAccess.WRITE)
	file.seek_end()
	file.store_line(JSON.stringify(row))
	file.close()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://test_artifacts/wall_per_run/" + name + ".png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/wall_per_run"))
	image.save_png(path)
	print("[shot] ", path)


func _watchdog() -> void:
	await get_tree().create_timer(60.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
