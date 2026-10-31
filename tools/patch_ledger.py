# -*- coding: utf-8 -*-
"""把心情 / 行动点两本账接进 WorkplaceTown.gd（可重跑：命中不到就报错退出）。"""
import sys

P = r'E:\03_Projects\bear\workplace_town\scripts\WorkplaceTown.gd'
s = open(P, encoding='utf-8', newline='').read().replace('\r\n', '\n')


def rep(old, new, tag=''):
    global s
    if old not in s:
        sys.exit('MISS anchor %s :: %s' % (tag, old[:70]))
    s = s.replace(old, new, 1)


# 1) manifest 路径
rep('const MONTH12_PLACES_PATH := "res://data/story/v12m/activities.json"',
    'const MONTH12_PLACES_PATH := "res://data/story/v12m/activities.json"\n'
    '## 全年参数（每月几格行动点、心情上限、月初回几点）只有这一份出处。\n'
    'const MONTH12_MANIFEST_PATH := "res://data/story/v12m/manifest.json"', 'manifest')

# 2) 账本状态
rep('var _month12_activity_generic := false\nvar _month12_ap_left := 0',
    'var _month12_activity_generic := false\n'
    '## ---------- 五本账里先做成真账的两本（4.15）----------\n'
    '## 心情 H：0–上限（manifest.hMax），月初回 1 点封顶；一处活动给回多少走 stateDelta.H，\n'
    '## 额外消耗走 hCost，且 H≤2 时消耗翻倍（行动点不翻）。\n'
    'var _mood := 6\n'
    'var _mood_max := 6\n'
    'var _mood_month_start := 6\n'
    '## 行动点：每月几格从 manifest.apByMonth 读（1/3/5/7/9/11 = 1/2/2/3/3/3），月底清零不跨月。\n'
    'var _ap_total := 0\n'
    '## 这个月做过的每一笔，月末卡当场结算给玩家看：{"what","ap","mood"}\n'
    'var _month_ledger: Array = []\n'
    'var _mood_h_init := -1\n'
    'var _ap_by_month := {}\n'
    'var _month12_ap_left := 0', 'state')

# 3) 首月开局起账 + 亮出心情那罐
rep('\t_load_month12_places()\n\t_refresh_objective_hint()',
    '\t_load_month12_places()\n\t_begin_month_ledger(1)\n\t_refresh_objective_hint()', 'm1-begin')
rep('\t\t_town_ui_v2.set_energy_visible(false)',
    '\t\t# 十二个月这条线：那罐蜂蜜是心情 H，不是体力。\n'
    '\t\t_town_ui_v2.set_energy_visible(true)', 'hud-visible')

# 4) HUD 读数：十二个月用心情
rep('\tvar remaining := _action_window.remaining if _action_window != null and not _action_window.current_window_id.is_empty() else 3\n'
    '\t_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), remaining, 3)',
    '\tvar remaining := _action_window.remaining if _action_window != null and not _action_window.current_window_id.is_empty() else 3\n'
    '\tif _month12_active:\n'
    '\t\t# 一罐一格，六格封顶：读数跟着账走。\n'
    '\t\t_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), _mood, _mood_max, "心情")\n'
    '\telse:\n'
    '\t\t_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), remaining, 3)', 'hud-refresh')

# 5) 翻月起新账
rep('\t_month12_month = month_value\n\t_month12_phase = "month_nodes"',
    '\t_month12_month = month_value\n\t_begin_month_ledger(month_value)\n\t_month12_phase = "month_nodes"', 'month-begin')

# 6) 通用月份：节点没写预算就回落到全年那本账
rep('\t_month12_ap_left = maxi(0, int(budget.get("ap", _month12_slots_total)))',
    '\t# 节点没写预算就用全年那本账：每月几格只有一个出处，不靠节点里各写一遍。\n'
    '\t_month12_ap_left = maxi(0, int(budget.get("ap", _ap_total if _ap_total > 0 else _month12_slots_total)))', 'budget')

# 7) 确认页代价行读真心情
rep('_month12_place_panel.show_confirm(month12_place, 3, _month12_slots_left)',
    '_month12_place_panel.show_confirm(month12_place, _mood, _month12_slots_left)', 'confirm-slots')
rep('_month12_place_panel.show_confirm(month12_place, 3)',
    '_month12_place_panel.show_confirm(month12_place, _mood)', 'confirm-m1')

# 8) 结算：记一笔心情（行动点那行原本就在，不动）
rep('\telse:\n\t\t_month12_activity_taken = true\n\t_month12_nearby_place = ""',
    '\telse:\n\t\t_month12_activity_taken = true\n'
    '\t# 心情这一笔：做完这件事是松了一点还是更累了一点，当场记进账本。\n'
    '\t_record_ledger(String(activity.get("name", "自由活动")), int(activity.get("apCost", 1)), _apply_activity_mood(activity))\n'
    '\t_month12_nearby_place = ""', 'mood-record')

# 9) 主线选项也动心情（E04 选 A 是 S+2 / H-1 这种）
rep('\t\tfor flag in ((choice as Dictionary).get("flags", []) as Array):\n\t\t\t_month12_flags[String(flag)] = true',
    '\t\tfor flag in ((choice as Dictionary).get("flags", []) as Array):\n\t\t\t_month12_flags[String(flag)] = true\n'
    '\t\t# 主线那一笔也记进同一本账：这个月心情为什么掉了，月末卡要说得出来。\n'
    '\t\tvar delta := int(((choice as Dictionary).get("stateDelta", {}) as Dictionary).get("H", 0))\n'
    '\t\tif delta != 0:\n'
    '\t\t\tvar before := _mood\n'
    '\t\t\t_mood = clampi(_mood + delta, 0, _mood_max)\n'
    '\t\t\t_refresh_mood_hud()\n'
    '\t\t\t_record_ledger(String(node.get("title", "这一件事")), 0, _mood - before)', 'choice-mood')

# 10) 月末卡写账
rep('\t_month12_close_panel.open(card, _month12_month)',
    '\t_month12_close_panel.open(card, _month12_month, _month_ledger_line())', 'close-line')

# 11) 存盘带上两本账
rep('\t\t"unlockedPlaces": _month12_unlocked_places.keys(),\n\t\t"flags": _month12_flags,\n\t}',
    '\t\t"unlockedPlaces": _month12_unlocked_places.keys(),\n\t\t"flags": _month12_flags,\n'
    '\t\t"mood": _mood,\n\t\t"moodMax": _mood_max,\n\t\t"apLeftThisMonth": _month12_ap_left,\n'
    '\t\t"monthLedger": _month_ledger,\n\t}', 'save')

# 12) 心情见底那一格：不做事的去处压灰（强制休息，但不挡主线）
rep('\t\trows.append({\n\t\t\t"id": String(act.get("id", "")),\n\t\t\t"title": String(act.get("name", "自由活动")),\n\t\t\t"image": thumb,\n\t\t\t"note": _month12_place_row_note(act),\n\t\t})',
    '\t\tvar row := {\n\t\t\t"id": String(act.get("id", "")),\n\t\t\t"title": String(act.get("name", "自由活动")),\n'
    '\t\t\t"image": thumb,\n\t\t\t"note": _month12_place_row_note(act),\n\t\t}\n'
    '\t\tif _mood <= 0 and _restores_mood(act):\n\t\t\t# H=0：这一格只能用来缓过来（4.15 第 2 本账最后一句）。\n'
    '\t\t\tpass\n'
    '\t\telif _mood <= 0:\n'
    '\t\t\trow["disabled"] = true\n'
    '\t\t\trow["note"] = "今天只能缓一缓"\n'
    '\t\trows.append(row)', 'forced-rest')

# 13) 账本本体
anchor = '## 在屋里点了那一行：旁白就在室内这一屏演完。'
if anchor not in s:
    sys.exit('MISS anchor ledger-block')
block = '''## ---------- 心情 / 行动点：这两本账的真值 ----------

## 全年参数只读一次：hInit / hMax / apByMonth 都在 manifest.json 里。
func _load_month12_ledger_rules() -> void:
	if not _ap_by_month.is_empty():
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH12_MANIFEST_PATH))
	if not parsed is Dictionary:
		return
	var manifest := parsed as Dictionary
	_mood_max = maxi(1, int(manifest.get("hMax", 6)))
	_mood_h_init = int(manifest.get("hInit", 6))
	var ap := manifest.get("apByMonth", {}) as Dictionary
	for key in ap.keys():
		_ap_by_month[int(String(key))] = int(ap[key])


## 月初起账：心情回 1 点封顶（第一个月直接用 hInit，不再 +1），
## 行动点按这个月的额度发，上个月的余量一律作废——不跨月是全年规则。
func _begin_month_ledger(month_value: int) -> void:
	_load_month12_ledger_rules()
	if _mood_h_init < 0:
		_mood_h_init = _mood_max
	if month_value <= 1:
		_mood = clampi(_mood_h_init, 0, _mood_max)
	else:
		_mood = mini(_mood_max, _mood + 1)
	_mood_month_start = _mood
	_ap_total = int(_ap_by_month.get(month_value, 0))
	_month12_ap_left = _ap_total
	_month_ledger = []
	_refresh_mood_hud()


## 一处活动对心情做了多少：hCost 是额外消耗，H≤2 时翻倍（行动点不翻）；
## stateDelta.H 是这一处给回的。返回净变化，账本上写"心情 +1 / -2"就用它。
func _apply_activity_mood(activity: Dictionary) -> int:
	var cost := maxi(0, int(activity.get("hCost", 0)))
	if _mood <= 2 and cost > 0:
		cost *= 2
	var gain := int((activity.get("stateDelta", {}) as Dictionary).get("H", 0))
	var before := _mood
	_mood = clampi(_mood - cost + gain, 0, _mood_max)
	_refresh_mood_hud()
	return _mood - before


## 这一处会不会把人缓过来：只看它给不给回心情。H=0 那一格只留这种去处能按。
func _restores_mood(activity: Dictionary) -> bool:
	return int((activity.get("stateDelta", {}) as Dictionary).get("H", 0)) > 0


func _record_ledger(what: String, ap_spent: int, mood_delta: int) -> void:
	if what.is_empty():
		return
	_month_ledger.append({"what": what, "ap": ap_spent, "mood": mood_delta})


## 月末卡上那一行账：安排了哪几件、行动点花掉多少、心情从几到几。
## 一笔都没做的时候不写空话——有的月份本来就没有个人时间。
func _month_ledger_line() -> String:
	var spent := 0
	for entry in _month_ledger:
		spent += int((entry as Dictionary).get("ap", 0))
	if _month_ledger.is_empty():
		if _ap_total <= 0:
			return "这个月没有个人时间"
		return "这个月没安排自己的时间 · 行动点 %d/%d 没用" % [_ap_total, _ap_total]
	var parts: Array = []
	for entry in _month_ledger:
		var mood_delta := int((entry as Dictionary).get("mood", 0))
		var what := String((entry as Dictionary).get("what", ""))
		parts.append(what + ("（心情 %+d）" % mood_delta if mood_delta != 0 else ""))
	return "这个月安排了 %d 件：%s · 行动点用掉 %d · 心情 %d → %d" % [
		_month_ledger.size(), "、".join(parts), spent, _mood_month_start, _mood,
	]


## 心情变了就重画那罐蜂蜜：读数必须跟着账走，不能停在开局那个数。
func _refresh_mood_hud() -> void:
	if _town_ui_v2 != null and _month12_active:
		_town_ui_v2.refresh(WorldClock.snapshot(), WorldClock.next_main_event(), _mood, _mood_max, "心情")


'''
s = s.replace(anchor, block + anchor, 1)

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n'))
print('ledger wired into WorkplaceTown.gd')
