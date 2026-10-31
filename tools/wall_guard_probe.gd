extends Node

## 记忆墙的月号闸门：灌一条十二个月里不可能存在的记录（第 42 月），墙必须不收。
## 用法：<godot> --headless --path <proj> res://tools/wall_guard_probe.tscn

func _ready() -> void:
	var wall: CanvasLayer = load("res://scripts/MemoryWallPanel.gd").new() as CanvasLayer
	add_child(wall)
	await get_tree().process_frame
	wall.call("show_records", [
		{"eventId": "legacy", "month": 42, "phase": "early", "text": "第 42 月 · 吹哨两难", "tone": "gray", "worldMinute": 1},
		{"eventId": "E02", "month": 1, "phase": "mid", "text": "会上那三句是我讲的。", "tone": "gold", "worldMinute": 2},
	])
	await get_tree().process_frame
	var kept: Array = wall.get("_notes")
	print("GUARD 收下的便签数=", kept.size(), " 第一条=", String(Dictionary(kept[0]).get("eventId", "-")) if kept.size() > 0 else "-")
	print("GUARD 结论=", "通过（越界被挡）" if kept.size() == 1 else "失败（越界混进来了）")
	get_tree().quit(0 if kept.size() == 1 else 1)
