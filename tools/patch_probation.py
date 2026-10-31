# -*- coding: utf-8 -*-
"""第 6 月答辩判定 + 延期者提前结束在岗主线。"""
import json
import sys

ROOT = r'E:\03_Projects\bear\workplace_town'
GD = ROOT + r'\scripts\WorkplaceTown.gd'
EV = ROOT + r'\data\story\v12m\events.json'
MF = ROOT + r'\data\story\v12m\manifest.json'

graw = open(GD, encoding='utf-8', newline='').read()
gnl = '\r\n' if '\r\n' in graw else '\n'
g = graw.replace('\r\n', '\n')


def rep(old, new, tag):
    global g
    if old not in g:
        sys.exit('MISS ' + tag)
    g = g.replace(old, new, 1)


# 1) 记证据：每一次选择把它的能力锚点收进来（取各维最高）。
rep('var _walk_skip_offered := false',
    'var _walk_skip_offered := false\n'
    '## 四维证据：答辩判定用。每次选完把这条选项的能力锚点收进来，取各维最高那档。\n'
    'var _dim_anchors := {"S": [], "O": [], "N": [], "D": []}', 'state')

rep('''		for flag in ((choice as Dictionary).get("flags", []) as Array):
			_month12_flags[String(flag)] = true
		# 这一选点亮某能力的第 5 格''',
    '''		for flag in ((choice as Dictionary).get("flags", []) as Array):
			_month12_flags[String(flag)] = true
		_collect_competency(choice as Dictionary)
		# 这一选点亮某能力的第 5 格''', 'collect-runner')

# 首月那条路径也收
rep('''		for choice in ((_month_opening_events.get("E02", {}) as Dictionary).get("choices", []) as Array):
			if String((choice as Dictionary).get("id", "")) == String(choice_id):
				_record_ability_tags((choice as Dictionary).get("abilityTags"))''',
    '''		for choice in ((_month_opening_events.get("E02", {}) as Dictionary).get("choices", []) as Array):
			if String((choice as Dictionary).get("id", "")) == String(choice_id):
				_record_ability_tags((choice as Dictionary).get("abilityTags"))
				_collect_competency(choice as Dictionary)''', 'collect-month1')

# 2) 判定本身
rep('''func runner_walk_to(node: Dictionary) -> void:''',
    '''## 把一条选项的能力锚点记进四维证据（同维取最高，不累加）。
func _collect_competency(choice: Dictionary) -> void:
	for entry in (choice.get("competency", []) as Array):
		if not (entry is Dictionary):
			continue
		var dim := String((entry as Dictionary).get("dimension", ""))
		if not _dim_anchors.has(dim):
			continue
		var anchor := int((entry as Dictionary).get("anchor", 0))
		var bucket: Array = _dim_anchors[dim]
		bucket.append(anchor)
		_dim_anchors[dim] = bucket


## 第 6 月答辩判定（rubrics.json 的 m6 门槛）：
## 四维各取最高档 → 每维≥3 且总分≥14 = 直接通过；
## 其余（延期区间、差一维、证据不足）一律按延期复核处理。
## 判定只写旗标，不改任何数值；第 7 月那一屏自己按旗标分版。
func _evaluate_probation() -> String:
	var dims := ["S", "O", "N", "D"]
	var score := {}
	var total := 0
	for dim in dims:
		var best := 0
		for value in (_dim_anchors.get(dim, []) as Array):
			best = maxi(best, int(value))
		score[dim] = best
		total += best
	var all_sufficient := true
	for dim in dims:
		if int(score[dim]) < 3:
			all_sufficient = false
	_month12_flags["m06_dim_score"] = score
	_month12_flags["m06_dim_total"] = total
	var status := "confirmed" if all_sufficient and total >= 14 else "deferred"
	_month12_flags["m06_probation_status"] = status
	_month12_flags["m07_probation_deferred"] = status == "deferred"
	print("[判定] 四维 %s 总分 %d → %s" % [JSON.stringify(score), total, status])
	return status


func runner_walk_to(node: Dictionary) -> void:''', 'evaluate')

# 3) 第 6 月收尾时判、第 7 月收尾时若延期就结束在岗主线
rep('''	# 最后一个月不睡：那天之后是年度报告，不是下个月。
	if finished_month >= 12:''',
    '''	# 第 6 月过完就判：通过 / 延期复核。
	if finished_month == 6 and not _month12_flags.has("m06_probation_status"):
		_evaluate_probation()
	# 延期的人在七月做完交接就结束在岗主线：不进 E19、不进第 8 月。
	if finished_month == 7 and bool(_month12_flags.get("m07_probation_deferred", false)):
		_end_year_early()
		return
	# 最后一个月不睡：那天之后是年度报告，不是下个月。
	if finished_month >= 12:''', 'judge')

rep('''## 月末不回工位直接翻月：先走回宿舍，进门熄灯，睡完才开下个月。''',
    '''## 延期转正：交接完就收在这里。年度记录只收已经发生的事。
func _end_year_early() -> void:
	_month12_phase = "done"
	_month12_waypoint = Vector2(-99999, -99999)
	if _guide_line != null:
		_guide_line.clear()
	if _town_ui_v2 != null:
		_town_ui_v2.set_task_card("本年度到此为止", "延期复核")
		_town_ui_v2.set_task_note("已交接 · 记录收在这里")
	_set_objective("第 7 月", "本年度到此为止", "交接完成", "复核通过后再继续", false)
	_save_month12_progress()
	_show_reminder_toast("交接完成", "这个年度的记录收在这里；复核通过再接着往下走")


## 月末不回工位直接翻月：先走回宿舍，进门熄灯，睡完才开下个月。''', 'end-early')

open(GD, 'w', encoding='utf-8', newline='').write(g.replace('\n', gnl))

# 4) 数据：延期分支的交接那一屏
raw = open(EV, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
doc = json.loads(raw.replace('\r\n', '\n'))
by = {str(n.get('id')): n for n in doc['nodes']}
if 'M07_HANDOVER' not in by:
    doc['nodes'].append({
        'id': 'M07_HANDOVER', 'month': 7, 'order': 215, 'nodeType': 'main_story',
        'required': True, 'when': {'flag': 'm07_probation_deferred'},
        'title': '交接', 'locationId': 'B', 'location': 'B 区工位',
        'durationMinutes': 40, 'situation': 'weak', 'timeBand': 'afternoon', 'phase': 'mid',
        'reportUse': 'story_only', 'autoComplete': True, 'choices': [],
        'beats': [
            {'type': 'narration', 'text': '你和接手同事逐项对过文档、待办和访问权限。'},
            {'type': 'narration', 'text': '交接完成后，转正主线在这里结束；这个年度的记录只收已经发生的事。'},
            {'type': 'narration', 'text': '复核通过之前，后面的活不会派到你手上。'},
        ],
    })
open(EV, 'w', encoding='utf-8', newline='').write(
    json.dumps(doc, ensure_ascii=False, indent=2).replace('\n', nl) + nl)

mraw = open(MF, encoding='utf-8', newline='').read()
mnl = '\r\n' if '\r\n' in mraw else '\n'
mf = json.loads(mraw.replace('\r\n', '\n'))
if 'M07_HANDOVER' not in mf['nodeOrder']:
    mf['nodeOrder'].insert(mf['nodeOrder'].index('M07_PAPER') + 1, 'M07_HANDOVER')
open(MF, 'w', encoding='utf-8', newline='').write(
    json.dumps(mf, ensure_ascii=False, indent=2).replace('\n', mnl) + mnl)
print('判定 + 延期提前结束已接')
