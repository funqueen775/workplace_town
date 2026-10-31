# -*- coding: utf-8 -*-
"""提示条消费器：让 hints.json 真的能弹。
   第 1–2 月那几条先标 legacy（流程里已经写死了，避免弹两遍）；第 3 月起由数据驱动。"""
import json
import sys

ROOT = r'E:\03_Projects\bear\workplace_town'
GD = ROOT + r'\scripts\WorkplaceTown.gd'
HP = ROOT + r'\data\story\v12m\hints.json'

raw = open(GD, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
g = raw.replace('\r\n', '\n')


def rep(old, new, tag):
    global g
    if old not in g:
        sys.exit('MISS ' + tag)
    g = g.replace(old, new, 1)


# 1) 路径常量 + 状态
rep('const MONTH12_PLACES_PATH := "res://data/story/v12m/activities.json"',
    'const MONTH12_PLACES_PATH := "res://data/story/v12m/activities.json"\n'
    '## 提示条表：一个月在哪些时刻该说什么，全在这份文件里（4.20 起由它驱动）。\n'
    'const MONTH12_HINTS_PATH := "res://data/story/v12m/hints.json"', 'path')

rep('var _month12_visit_id := ""',
    'var _month12_visit_id := ""\n'
    '## 提示条：表只读一次；_hint_fired 记已经弹过的（once）。\n'
    'var _hints: Array = []\n'
    'var _hint_fired: Dictionary = {}\n'
    '## 上一帧脚边有没有门：只在"刚走到门口"那一刻弹一次 portal_reached。\n'
    'var _hint_at_portal := false', 'state')

# 2) 消费器本体（放在提示条 toast 函数后面）
anchor = 'func _show_reminder_toast(title: String, sub: String) -> void:'
if anchor not in g:
    sys.exit('MISS toast')
consumer = '''## ---------- 提示条：hints.json 的消费器 ----------
## 表里一条提示 = 某个月 + 某个时机 + 一句话。时机由流程在发生的地方叫一声。
## once：同一条只弹一次（记在 _hint_fired，不进存档）。
func _load_hints() -> void:
	if not _hints.is_empty():
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MONTH12_HINTS_PATH))
	if parsed is Dictionary:
		_hints = (parsed as Dictionary).get("hints", []) as Array


func _fire_hints(trigger: String) -> void:
	if not _month12_active:
		return
	_load_hints()
	var month := _month12_month
	for value in _hints:
		if not (value is Dictionary):
			continue
		var hint := value as Dictionary
		if int(hint.get("month", 0)) != month:
			continue
		if String(hint.get("trigger", "")) != trigger:
			continue
		# 第 1–2 月那几条已经写死在流程里了，别弹两遍。
		if bool(hint.get("legacy", false)):
			continue
		var hint_id := String(hint.get("id", ""))
		if bool(hint.get("once", true)) and bool(_hint_fired.get(hint_id, false)):
			continue
		_hint_fired[hint_id] = true
		_show_hint(hint)


func _show_hint(hint: Dictionary) -> void:
	var anchor := String(hint.get("anchor", "shell_toast"))
	var title := String(hint.get("title", ""))
	var sub := String(hint.get("sub", hint.get("text", "")))
	if anchor == "objective":
		# 目标行/本月卡那一行：不弹窗，直接写上去。
		if _town_ui_v2 != null:
			_town_ui_v2.set_task_note(sub)
		return
	_show_reminder_toast(title, sub)


'''
g = g.replace(anchor, consumer + anchor, 1)

# 3) 触发点：翻月 / 开屏 / 读完一屏 / 钩子 / 门亮 / 自由安排开合 / 到门口
rep('''	_ap_total = int(_ap_by_month.get(month_value, 0))
	_month12_ap_left = _ap_total
	_month_ledger = []''',
    '''	_ap_total = int(_ap_by_month.get(month_value, 0))
	_month12_ap_left = _ap_total
	_month_ledger = []
	_hint_at_portal = false
	_fire_hints("month_started")''', 'month_started')

rep('''	var data := _runner_story_data(node)
	_apply_node_flags(node)''',
    '''	var data := _runner_story_data(node)
	_apply_node_flags(node)
	_fire_hints("node_started:%s" % String(node.get("id", "")))''', 'node_started')

rep('''		if not _pending_story_hooks.is_empty():
			_open_hook_cards(Callable(_month_runner, "on_panel_closed"))
			return''',
    '''		_fire_hints("node_completed:%s" % String((_month_runner.current as Dictionary).get("id", ""))) \\
			if _month_runner.current is Dictionary else null
		if not _pending_story_hooks.is_empty():
			_open_hook_cards(Callable(_month_runner, "on_panel_closed"))
			return''', 'node_completed')

rep('''	var hook := String(beat.get("hook", ""))
	if hook.is_empty():
		return''',
    '''	var hook := String(beat.get("hook", ""))
	if hook.is_empty():
		return
	_fire_hints("hook:%s" % hook)''', 'hook')

rep('''	door.position = _month12_place_position_of(activity)
	door.z_index = 44
	add_child(door)
	_month12_place_portals[activity_id] = door''',
    '''	door.position = _month12_place_position_of(activity)
	door.z_index = 44
	add_child(door)
	_month12_place_portals[activity_id] = door
	_fire_hints("place_unlocked")''', 'place_unlocked')

rep('''	_show_end_month_button(true)
	_apply_hook_navigation()''',
    '''	_show_end_month_button(true)
	_apply_hook_navigation()
	_fire_hints("activity_open")''', 'activity_open')

rep('''	_record_ledger(String(activity.get("name", "自由活动")), ap_spent, _apply_activity_mood(activity))''',
    '''	_record_ledger(String(activity.get("name", "自由活动")), ap_spent, _apply_activity_mood(activity))
	_fire_hints("activity_done")''', 'activity_done')

rep('''	if _month12_activity_generic and _month12_slots_left > 0:
		# 翻月时还有格子没花：引擎记一笔跳过，月底的档案里看得出这个月没安排。
		_month12_flags["m%02d_activity_skipped" % _month12_month] = true''',
    '''	if _month12_activity_generic and _month12_slots_left > 0:
		# 翻月时还有格子没花：引擎记一笔跳过，月底的档案里看得出这个月没安排。
		_month12_flags["m%02d_activity_skipped" % _month12_month] = true
		_fire_hints("activity_skipped")''', 'activity_skipped')

rep('''	_interaction_button.text = "按 E 进去 · %s" % String(activity.get("name", ""))
	_interaction_button.show()''',
    '''	_interaction_button.text = "按 E 进去 · %s" % String(activity.get("name", ""))
	_interaction_button.show()
	if not _hint_at_portal:
		_hint_at_portal = true
		_fire_hints("portal_reached")''', 'portal_reached')

rep('''	if _month12_nearby_place.is_empty():
		_interaction_button.hide()
		return''',
    '''	if _month12_nearby_place.is_empty():
		_hint_at_portal = false
		_interaction_button.hide()
		return''', 'portal_reset')

open(GD, 'w', encoding='utf-8', newline='').write(g.replace('\n', nl))

# 4) 数据：老九条标 legacy；补第 3 月五条（4.20 那张表）
h = json.load(open(HP, encoding='utf-8'))
for hint in h['hints']:
    hint['legacy'] = True
have = {str(x.get('id')) for x in h['hints']}
new_hints = [
    {'id': 'm03_month', 'month': 3, 'anchor': 'shell_toast', 'trigger': 'node_started:M03_OPEN',
     'title': '周三十点，C 区展厅', 'sub': '跟着黄线走，别让客户等', 'autoDismissMs': 3200, 'once': True},
    {'id': 'm03_handbook', 'month': 3, 'anchor': 'shell_toast', 'trigger': 'node_started:M03_HANDBOOK',
     'title': '手册第二章开了', 'sub': '会前翻一眼 2.3，会上要用', 'autoDismissMs': 3200, 'once': True},
    {'id': 'm03_waterway', 'month': 3, 'anchor': 'shell_toast', 'trigger': 'hook:unlock_waterway',
     'title': '水巷门口亮了', 'sub': '巷子开着，午后归你', 'autoDismissMs': 3200, 'once': True},
    {'id': 'm03_afternoon', 'month': 3, 'anchor': 'shell_toast', 'trigger': 'node_started:M03_ACTIVITY',
     'title': '午后，时间归你', 'sub': '本月两格，用完再说', 'autoDismissMs': 3200, 'once': True},
    {'id': 'm03_end', 'month': 3, 'anchor': 'shell_toast', 'trigger': 'node_completed:E12',
     'title': '这个月安排完了', 'sub': '可以结束这个月', 'autoDismissMs': 2600, 'once': True},
]
for hint in new_hints:
    if hint['id'] not in have:
        h['hints'].append(hint)
open(HP, 'w', encoding='utf-8').write(json.dumps(h, ensure_ascii=False, indent=2) + '\n')
print('提示条消费器 + 第 3 月五条已接')
