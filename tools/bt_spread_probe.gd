extends Node

## 大五那五条到底会不会变长短：用真实数据算四种打法（每屏全选 A / B / C / 轮换），
## 直接调报告自己那个结算函数，把档位、事件数、场合数、收缩后的一致性打到控制台。
## 用法：<godot> --headless --path <proj> res://tools/bt_spread_probe.tscn

const EVENTS_PATH := "res://data/story/v12m/events.json"
const REPORT_BUILDER := "res://scripts/v12m/Month12Report.gd"


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	var nodes: Array = (parsed as Dictionary).get("nodes", []) as Array
	var policies := {"每屏全选 A": 0, "每屏全选 B": 1, "每屏全选 C": 2, "轮换": -1}
	var builder = load(REPORT_BUILDER).new()
	for policy_name in policies.keys():
		var pick := int(policies[policy_name])
		var signals := _collect(nodes, pick)
		print("== ", policy_name, "｜信号 ", signals.size(), " 条")
		var result: Dictionary = builder.call("_personality", signals)
		for value in (result.get("rows", []) as Array):
			var row := Dictionary(value)
			print("   ", String(row.get("name", "")),
				"｜", String(row.get("level", "")),
				"｜", String(row.get("levelWord", "")),
				"｜事件 ", int(row.get("events", 0)),
				"｜场合 ", int(row.get("contextTypes", 0)),
				"｜原始 ", String.num(float(row.get("score", 0.0)), 2),
				"｜收缩后 ", String.num(float(row.get("estimate", 0.0)), 2),
				"｜一致性 ", String(row.get("consistency", "")))
	_check_with_prior(nodes)
	print("BT_SPREAD_DONE")
	get_tree().quit(0)


class FakeTown extends Node:
	## 只给报告装配器要的那几个字段，方便单测自评这一路。
	var _self_ratings := {}
	var _rubrics := {}
	var _evidence_log := []
	var _month12_flags := {}


## 自评当先验之后：开局把每维说到极端，看融合与"点名不一致"那一句出不出来。
func _check_with_prior(nodes: Array) -> void:
	var town := FakeTown.new()
	town._self_ratings = {"E": 5, "A": 5, "C": 5, "N": 5, "O": 5}
	var builder = load(REPORT_BUILDER).new()
	builder.set("_town", town)
	var signals := _collect(nodes, 1)
	var result: Dictionary = builder.call("_personality", signals)
	print("== 开局全说「非常符合」+ 每屏选第二手")
	for value in (result.get("rows", []) as Array):
		var row := Dictionary(value)
		print("   ", String(row.get("name", "")),
			"｜行为 ", String.num(float(row.get("score", 0.0)), 2),
			"｜自评 ", String.num(float(row.get("prior", 0.0)), 2),
			"｜合起来 ", String.num(float(row.get("estimate", 0.0)), 2),
			"｜", String(row.get("levelWord", "")))
		for line in (row.get("lines", []) as Array):
			if String(line).contains("登记"):
				print("      ↳ ", String(line))
	town.free()


## 按打法走一遍全年主线：只取选项上标的信号，自由活动不参与本对比。
func _collect(nodes: Array, pick: int) -> Array:
	var out: Array = []
	var turn := 0
	for value in nodes:
		var node := Dictionary(value)
		var choices := (node.get("choices", []) as Array)
		if choices.is_empty():
			continue
		var index := pick
		if pick < 0:
			index = turn % choices.size()
			turn += 1
		if index >= choices.size():
			index = choices.size() - 1
		var chosen := Dictionary(choices[index])
		for sig in (chosen.get("btSignals", []) as Array):
			var item := Dictionary(sig)
			out.append({
				"trait": String(item.get("trait", "")),
				"dir": int(item.get("dir", 0)),
				"strength": String(item.get("strength", "M")),
				"context": String(item.get("context", "")),
				"eventId": String(node.get("id", "")),
				"source": "main",
				"month": int(node.get("month", 0)),
			})
	return out
