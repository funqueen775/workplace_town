extends Node

## 只测结果页那一句话：选项自己带的"谁说了什么"到底读不读得到。
## 不建城镇（城镇脚本此刻可能被另一条线改着），只把面板单独拉起来。
## 用法：<godot> --headless --path . res://tools/outcome_text_probe.tscn

const PANEL := preload("res://scripts/StoryEventPanel.gd")
const PICK := ["E50_recovery", "E50_metric_l1", "M05_OPEN", "E41", "M12_RESULT", "E32"]


func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/events.json"))
	var nodes: Array = (parsed as Dictionary).get("nodes", [])
	var by_id := {}
	for value in nodes:
		by_id[String(Dictionary(value).get("id", ""))] = Dictionary(value)
	var fallbacks := 0
	var checked := 0
	for id in PICK:
		var node: Dictionary = by_id.get(id, {})
		if node.is_empty():
			print("[out] ", id, " 不在表里")
			continue
		var panel = PANEL.new()
		add_child(panel)
		panel.reduced_motion = true
		panel.present(node)
		for choice in (node.get("choices", []) as Array):
			var cid := String(Dictionary(choice).get("id", ""))
			var text := String(panel.call("_outcome_text", cid))
			var written := String(Dictionary(choice).get("outcome", ""))
			checked += 1
			var hit := text == written and not written.is_empty()
			if not hit:
				fallbacks += 1
			print("[out] %-14s %s 读到真回应=%s ｜%s" % [id, cid, str(hit), _clip(text)])
		panel.dismiss()
		panel.queue_free()
	print("[out] 共查 %d 个选项，读不到真回应的 %d 个" % [checked, fallbacks])
	print("OUTCOME_PROBE_DONE")
	get_tree().quit(0 if fallbacks == 0 else 1)


func _clip(text: String) -> String:
	return text if text.length() <= 46 else text.substr(0, 46) + "…"
