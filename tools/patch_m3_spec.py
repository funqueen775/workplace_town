# -*- coding: utf-8 -*-
"""第 3 月照 4.20 补齐：手册第二章（会前红点、不弹窗）、月末中性句、本月卡副行。"""
import json
import sys

ROOT = r'E:\03_Projects\bear\workplace_town'
HB = ROOT + r'\data\story\employee_handbook_12m.json'
EV = ROOT + r'\data\story\v12m\events.json'
MF = ROOT + r'\data\story\v12m\manifest.json'
GD = ROOT + r'\scripts\WorkplaceTown.gd'
UI = ROOT + r'\scripts\TownUiV2.gd'

# ---------------------------------------------------------------- 1) 手册第二章（条文照旧手册源文）
hb = json.load(open(HB, encoding='utf-8'))
ids = {str(c['id']) for c in hb['chapters']}
if '2.1' not in ids:
    def page(pid, title, body, pencil='', lead='', margin=''):
        clause = {'id': pid, 'title': title, 'body': body}
        if pencil:
            clause['pencil'] = pencil
        return {'id': pid, 'index': len(hb['chapters']) + 1, 'title': title,
                'subtitle': '第二章 · 协作流程', 'lead': lead,
                'clauses': [clause], 'margin': margin}
    hb['chapters'].append(page('2.1', '拿不准就同步，别猜',
        '不确定的事，不要自己猜着做超过半天。半天的成本是四小时，猜错的成本是别人的两天。',
        lead='这一章最短。吃亏的人最多。'))
    hb['chapters'].append(page('2.2', '周报只写结论',
        '三行以内：做完了什么、卡在哪里、下周需要什么支持。过程留给自己。'))
    hb['chapters'].append(page('2.3', '开会没结论，也要留下三样东西',
        '待定的事项要写清楚：待定项、责任人、下次确认时间。没有这三样，这个会就白开了。'))
    hb['chapters'].append(page('2.4', '署名',
        '谁做的写谁的。你不需要请示别人可否给自己署名，也不需要替别人署名。',
        pencil='我犹豫过一次。犹豫就是答案。'))
    hb['chapters'].append(page('2.5', '该找谁',
        '陈工（邻组 Leader）：问他结论和成本，一句话说完。王哥（你的带教人）：问他「为什么」。'
        '他不怕你问，怕你不问。'))
    open(HB, 'w', encoding='utf-8').write(json.dumps(hb, ensure_ascii=False, indent=2) + '\n')
    print('手册第二章 5 页已补')

# ---------------------------------------------------------------- 2) 第 3 月节点
raw = open(EV, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
doc = json.loads(raw.replace('\r\n', '\n'))
by = {str(n.get('id')): n for n in doc['nodes']}

# 会前那一屏：手册第二章开红点，不弹窗（silent）
if 'M03_HANDBOOK' not in by:
    doc['nodes'].append({
        'id': 'M03_HANDBOOK', 'month': 3, 'order': 205, 'nodeType': 'handbook',
        'required': False, 'chapterId': 'ch2', 'sourceChapterId': 'process',
        'silent': True, 'timeBand': 'morning', 'phase': 'early', 'reportUse': 'story_only',
        'pages': [{'pageId': p, 'title': t, 'bodyKey': 'process.' + p}
                  for p, t in [('2.1', '拿不准就同步，别猜'), ('2.2', '周报只写结论'),
                               ('2.3', '开会没结论，也要留下三样东西'),
                               ('2.4', '署名'), ('2.5', '该找谁')]],
    })

# 本月卡副行（4.20 那张表）：挂在节点上，播放时直接写
notes = {
    'M03_OPEN': '上旬 · 还有两天',
    'M03_HANDBOOK': '上旬 · 会前',
    'M03_WRAP': '还剩 2 点 · 去亮着的地方',
    'M03_BRIDGE': '上旬 · 收工前',
    'M03_MID': '还有两周，日子照过',
    'E12': '下旬 · 收尾',
}
for nid, note in notes.items():
    if nid in by:
        by[nid]['note'] = note

# 月末卡：什么都没留下时那句中性话
close = by['M03_CLOSE']
if not any(isinstance(c.get('when'), dict) and 'noneOf' in c['when'] for c in (close.get('cards') or [])):
    close['cards'].append({'when': {'noneOf': ['m03_e10_truth_with_fallback',
                                               'm03_e10_soft_clause',
                                               'm03_e10_overpromise']},
                           'text': '客户走了，会议记录里没写你的名字。'})

open(EV, 'w', encoding='utf-8', newline='').write(
    json.dumps(doc, ensure_ascii=False, indent=2).replace('\n', nl) + nl)

# manifest 顺序
mraw = open(MF, encoding='utf-8', newline='').read()
mnl = '\r\n' if '\r\n' in mraw else '\n'
mf = json.loads(mraw.replace('\r\n', '\n'))
if 'M03_HANDBOOK' not in mf['nodeOrder']:
    mf['nodeOrder'].insert(mf['nodeOrder'].index('M03_OPEN') + 1, 'M03_HANDBOOK')
open(MF, 'w', encoding='utf-8', newline='').write(
    json.dumps(mf, ensure_ascii=False, indent=2).replace('\n', mnl) + mnl)

# ---------------------------------------------------------------- 3) 引擎：silent 手册 + 节点自带副行
graw = open(GD, encoding='utf-8', newline='').read()
gnl = '\r\n' if '\r\n' in graw else '\n'
g = graw.replace('\r\n', '\n')
old = '''	if _town_ui_v2 != null:
		_town_ui_v2.set_manual_visible(true)
	var sub := "第一章后几页散开了，右下角能翻"'''
new = '''	if _town_ui_v2 != null:
		_town_ui_v2.set_manual_visible(true)
		if bool(node.get("silent", false)):
			# 4.20：手册第二章会前给，只亮红点、不弹提示条。
			_town_ui_v2.set_manual_red_dot(true)
			return
	var sub := "第一章后几页散开了，右下角能翻"'''
assert old in g, 'handbook anchor'
g = g.replace(old, new, 1)

old2 = '''	_town_ui_v2.set_task_note("%s · %s" % [
		"夜" if String(data.get("timeBand", "morning")) == "night" else "白天",
		String(data.get("location", "")),
	])'''
new2 = '''	# 节点自带副行就照它写（4.20 那张"本月卡副行"表），没有才回落到"白天/夜 · 地点"。
	var node_note := String(data.get("note", ""))
	if node_note.is_empty():
		node_note = "%s · %s" % [
			"夜" if String(data.get("timeBand", "morning")) == "night" else "白天",
			String(data.get("location", "")),
		]
	_town_ui_v2.set_task_note(node_note)'''
assert old2 in g, 'note anchor'
g = g.replace(old2, new2, 1)
open(GD, 'w', encoding='utf-8', newline='').write(g.replace('\n', gnl))

# ---------------------------------------------------------------- 4) 界面：手册按钮的小红点
ui = open(UI, encoding='utf-8', newline='').read()
unl = '\r\n' if '\r\n' in ui else '\n'
u = ui.replace('\r\n', '\n')
if 'set_manual_red_dot' not in u:
    u = u.replace('''func set_manual_visible(value: bool) -> void:''',
'''## 手册按钮上的红点：第 3 月会前"有页了，但不弹窗"就是这么给的。
func set_manual_red_dot(value: bool) -> void:
	if _manual_button == null:
		return
	if _manual_dot == null and value:
		_manual_dot = Panel.new()
		_manual_dot.name = "ManualRedDot"
		_manual_dot.position = Vector2(76, 6)
		_manual_dot.size = Vector2(22, 22)
		_manual_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("e5503f")
		style.border_color = Color("fff3dc")
		style.set_border_width_all(2)
		style.set_corner_radius_all(11)
		_manual_dot.add_theme_stylebox_override("panel", style)
		_manual_button.add_child(_manual_dot)
	if _manual_dot != null:
		_manual_dot.visible = value


func set_manual_visible(value: bool) -> void:''', 1)
    u = u.replace('var _manual_button: Button', 'var _manual_button: Button\nvar _manual_dot: Panel', 1)
    open(UI, 'w', encoding='utf-8', newline='').write(u.replace('\n', unl))
    print('手册红点已接')
print('第 3 月补完')
