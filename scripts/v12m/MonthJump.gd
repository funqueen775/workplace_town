class_name MonthJump
extends RefCounted

## 跳月看片用的「补账器」（2026-10-28）。
##
## 直接开第 N 月时，第 1..N-1 月那些"上一月的账"是空的：条件台词全不出现、
## 老地方的门没立过、能力五格停在入职那天。这一份把账一次补齐，
## 让跳进去的那一眼和真玩到那个月看到的是同一个镇子。
##
## 补什么（都能在数据里追回来）：
##   选项旗标   —— 每月每个三选一按挑定的那条路（默认 A）落它的 flags
##   手册       —— 每月手册节点列出的页都算读过（「你想起手册那句」要它）
##   老地方     —— 每月自由活动节点列出的去处都算去过：落 visit_ 旗标、
##                 它的 rewardFlag、它的 hook，并把门留在镇上（"门开过就一直在"）
##   能力账     —— 选项与剧情拍上的 abilityTags 累计，abilityPeak 点亮第 5 格
##   四维锚点   —— 选项的 competency 一并补上，第七月那一屏才有真结论可看
##
## 第六月的转正结论是判出来的，不是补出来的：跳到第七月及以后会真跑一次判定。
## 另外两个看片专用路线：--v12m-path=P 强制"未转正"那一版，=R 强制"违纪解除"那一版
## （这两条停在第七月，本来就没有第八到第十二月可跳）。
##
## 不补什么：提名与晋升结果（m12_not_nominated / m12_not_passed）——那是第十一、十二月
## 当场选出来的，跳月看片要按真选择走。
##
## 只在调试里用：按 F8 或命令行 --v12m-month=N，玩家包里撞不到这两个入口。

const EVENTS_PATH := "res://data/story/v12m/events.json"
const ACTIVITIES_PATH := "res://data/story/v12m/activities.json"

## 城镇在运行时自己会写的那几类旗标前缀（数据表里查不到写的人，但不是缺陷）。
const RUNTIME_PREFIXES := ["handbook_page_", "visit_", "hook_", "peak_"]
const RUNTIME_FLAGS := ["handbook_read", "m01_activity_skipped", "activity", "e02", "m01_handbook_read"]


## 把 1..target_month-1 的账写进城镇，返回一份"补了什么"的清单。
static func apply(town: Node, target_month: int, path_letter := "A") -> Dictionary:
	var nodes := _array_of(EVENTS_PATH)
	var activities := _activities_by_id()
	var flags: Dictionary = town.get("_month12_flags")
	var unlocked: Dictionary = town.get("_month12_unlocked_places")
	var points: Dictionary = town.get("_ability_points")
	var report := {
		"month": target_month, "path": path_letter,
		"flags": 0, "places": 0, "points": {}, "peaks": [], "anchors": 0, "missing": []
	}
	var written := _all_written_flags(nodes)

	for value in nodes:
		if not (value is Dictionary):
			continue
		var node := Dictionary(value)
		var month := int(node.get("month", 0))
		if month <= 0 or month >= target_month:
			continue
		var type := String(node.get("nodeType", "main_story"))

		if type == "handbook":
			_mark(flags, "handbook_read", report)
			for page in (node.get("pages", []) as Array):
				var page_id := String((page as Dictionary).get("pageId", ""))
				if not page_id.is_empty():
					_mark(flags, "handbook_page_" + page_id, report)

		if type == "activity":
			for raw_id in (node.get("activityIds", []) as Array):
				var activity_id := String(raw_id)
				if activity_id.is_empty():
					continue
				_mark(flags, "visit_%d_%s" % [month, activity_id], report)
				unlocked[activity_id] = true
				report["places"] = int(report["places"]) + 1
				var activity: Dictionary = activities.get(activity_id, {})
				var reward := String(activity.get("rewardFlag", ""))
				if not reward.is_empty():
					_mark(flags, reward, report)
				var hook := String(activity.get("unlockHook", ""))
				if not hook.is_empty():
					_mark(flags, "hook_" + hook, report)

		for beat in (node.get("beats", []) as Array):
			var b := Dictionary(beat)
			for ability in (b.get("abilityPeak", []) as Array):
				_light_peak(flags, String(ability), report)
			_merge_tags(points, b.get("abilityTags"), report)

		var picked := _pick_choice(node, path_letter)
		if picked.is_empty():
			continue
		for flag in (picked.get("flags", []) as Array):
			_mark(flags, String(flag), report)
		for ability in (picked.get("abilityPeak", []) as Array):
			_light_peak(flags, String(ability), report)
		_merge_tags(points, picked.get("abilityTags"), report)
		_merge_anchors(town, picked, report)

	# 第 1 月「手册读没读」是一对互斥旗标，看片默认给"读了"那一版（有铅笔字的那句）。
	if target_month > 2:
		_mark(flags, "m01_handbook_read", report)

	# 跳到第七月及以后：转正结论是判出来的，不是补出来的。
	# 补完四维锚点就真跑一次判定，这样"结果那一屏"和真玩到第七月看到的是同一个结论。
	if target_month >= 7 and not flags.has("m06_probation_status"):
		report["probation"] = String(town.call("_evaluate_probation"))
	if path_letter == "P":
		# 看片专用：强制未转正那一版（第八到第十二月本来就不会开，只在第七月有用）。
		town.call("_finish_probation", "not_confirmed", "", {}, 0)
		report["probation"] = "not_confirmed（看片强制）"
	elif path_letter == "R":
		# 看片专用：强制违纪解除那一版，顺带给一条真红线让台词有得展开。
		_mark(flags, "m03_e10_overpromise", report)
		town.call("_finish_probation", "terminated", "m03_e10_overpromise", {}, 0)
		report["probation"] = "terminated（看片强制）"

	# 只被读、没人写的条件句：跳月补不出来，报在终端上——那是真缺陷，不是工具的锅。
	for entry in _orphans(nodes, written, target_month):
		(report["missing"] as Array).append(entry)
	return report


## 三选一里挑哪一条：优先点名那条，没有就取第一条。
static func _pick_choice(node: Dictionary, path_letter: String) -> Dictionary:
	var choices: Array = node.get("choices", []) as Array
	if choices.is_empty():
		return {}
	for value in choices:
		var choice := Dictionary(value)
		if String(choice.get("id", "")) == path_letter:
			return choice
	return Dictionary(choices[0])


static func _mark(flags: Dictionary, key: String, report: Dictionary) -> void:
	if key.is_empty() or bool(flags.get(key, false)):
		return
	flags[key] = true
	report["flags"] = int(report["flags"]) + 1


static func _merge_tags(points: Dictionary, raw, report: Dictionary) -> void:
	if not (raw is Dictionary):
		return
	for key in (raw as Dictionary).keys():
		var name := String(key)
		points[name] = int(points.get(name, 0)) + int((raw as Dictionary)[key])
		(report["points"] as Dictionary)[name] = int(points[name])


## 四维锚点也要补上：转正判定读的就是这一堆（各维取最高那档）。
static func _merge_anchors(town: Node, picked: Dictionary, report: Dictionary) -> void:
	var anchors: Dictionary = town.get("_dim_anchors")
	for entry in (picked.get("competency", []) as Array):
		if not (entry is Dictionary):
			continue
		var dim := String((entry as Dictionary).get("dimension", ""))
		if not anchors.has(dim):
			continue
		var bucket: Array = anchors[dim]
		bucket.append(int((entry as Dictionary).get("anchor", 0)))
		anchors[dim] = bucket
		report["anchors"] = int(report["anchors"]) + 1


static func _light_peak(flags: Dictionary, ability: String, report: Dictionary) -> void:
	if ability.is_empty():
		return
	flags["peak_" + ability] = true
	if not (report["peaks"] as Array).has(ability):
		(report["peaks"] as Array).append(ability)


## 全表里"有人写"的旗标：数据里的选项/拍子 + 城镇运行时自己写的那几类。
static func _all_written_flags(nodes: Array) -> Dictionary:
	var out := {}
	for value in nodes:
		if not (value is Dictionary):
			continue
		var node := Dictionary(value)
		for choice in (node.get("choices", []) as Array):
			for flag in ((choice as Dictionary).get("flags", []) as Array):
				out[String(flag)] = true
		for beat in (node.get("beats", []) as Array):
			for flag in ((beat as Dictionary).get("flags", []) as Array):
				out[String(flag)] = true
	for name in RUNTIME_FLAGS:
		out[name] = true
	return out


static func _written(written: Dictionary, flag: String) -> bool:
	if written.has(flag):
		return true
	for prefix in RUNTIME_PREFIXES:
		if flag.begins_with(prefix):
			return true
	return false


## 目标月之前（含目标月）出现过的每一个 when.flag，谁没人写就列出来。
static func _orphans(nodes: Array, written: Dictionary, target_month: int) -> Array:
	var out: Array = []
	var seen := {}
	for value in nodes:
		if not (value is Dictionary):
			continue
		var node := Dictionary(value)
		var month := int(node.get("month", 0))
		if month <= 0 or month > target_month:
			continue
		var reads: Array = []
		_collect_conditions(node, reads)
		for flag in reads:
			var name := String(flag)
			if _written(written, name) or seen.has(name):
				continue
			seen[name] = true
			out.append("%s（第 %d 月 %s 要读它，可全年没人写）" % [name, month, String(node.get("id", ""))])
	return out


## 递归收一个节点里所有 when.flag（节点、拍子、选项、消息、卡片都算）。
static func _collect_conditions(node, out: Array) -> void:
	if node is Dictionary:
		var when = (node as Dictionary).get("when")
		if when is Dictionary and not String((when as Dictionary).get("flag", "")).is_empty():
			out.append(String((when as Dictionary).get("flag", "")))
		for key in (node as Dictionary).keys():
			_collect_conditions((node as Dictionary)[key], out)
	elif node is Array:
		for item in (node as Array):
			_collect_conditions(item, out)


static func _array_of(path: String) -> Array:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return (parsed as Dictionary).get("nodes", []) as Array
	return parsed as Array if parsed is Array else []


static func _activities_by_id() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ACTIVITIES_PATH))
	var out := {}
	var items: Array = []
	if parsed is Dictionary:
		items = (parsed as Dictionary).get("activities", []) as Array
	elif parsed is Array:
		items = parsed as Array
	for value in items:
		if value is Dictionary:
			out[String((value as Dictionary).get("id", ""))] = value
	return out
