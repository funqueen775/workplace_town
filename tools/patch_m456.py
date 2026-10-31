# -*- coding: utf-8 -*-
"""第 4–6 月照剧情册补漏（只做还缺的那几处，不碰另一条线刚写好的内容）。

4 月：手册回响那一拍、两周之后的三条分支、复盘会漏掉的两拍
5 月：月末那条考评提醒（册子要求普通新存档也必须收到，本月第二批）
6 月：答辩第三拍的问句分支——带进去的三张里有没有"受挫/未完成"那张
引擎：拍条件补 anyOf / noneOf（一个分支要看四个旗标里有没有任意一个）
"""
import json

ROOT = r'E:\03_Projects\bear\workplace_town'
EV = ROOT + r'\data\story\v12m\events.json'
MF = ROOT + r'\data\story\v12m\manifest.json'
GD = ROOT + r'\scripts\WorkplaceTown.gd'

# ---------------------------------------------------------------- 1) 引擎
graw = open(GD, encoding='utf-8', newline='').read()
gnl = '\r\n' if '\r\n' in graw else '\n'
g = graw.replace('\r\n', '\n')
old = '''			var not_flag := String(w.get("notFlag", ""))
			if not not_flag.is_empty() and bool(_month12_flags.get(not_flag, false)):
				continue'''
new = '''			var not_flag := String(w.get("notFlag", ""))
			if not not_flag.is_empty() and bool(_month12_flags.get(not_flag, false)):
				continue
			# anyOf：一组旗标里命中任意一条才留；noneOf：一条都没命中才留。
			# 答辩那一问要看"带进去的三张里有没有受挫那张"——那是好几个旗标里的任意一个。
			any_of: Array = w.get("anyOf", []) as Array
			if not any_of.is_empty() and not _any_flag(any_of):
				continue
			none_of: Array = w.get("noneOf", []) as Array
			if not none_of.is_empty() and _any_flag(none_of):
				continue'''
assert old in g, 'engine anchor'
g = g.replace(old, new, 1)
assert 'func _any_flag' not in g, 'engine helper already there'
g = g.replace('func runner_walk_to(node: Dictionary) -> void:',
  '''## 一组旗标里有没有任意一条成立。
func _any_flag(flags: Array) -> bool:
	for value in flags:
		if bool(_month12_flags.get(String(value), false)):
			return true
	return false


func runner_walk_to(node: Dictionary) -> void:''', 1)
open(GD, 'w', encoding='utf-8', newline='').write(g.replace('\n', gnl))

# ---------------------------------------------------------------- 2) 数据
raw = open(EV, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
doc = json.loads(raw.replace('\r\n', '\n'))
nodes = doc['nodes']
by_id = {str(n.get('id')): n for n in nodes}


def nar(text, when=None):
    b = {'type': 'narration', 'text': text}
    if when:
        b['when'] = when
    return b


def say(who, text, when=None):
    b = {'type': 'say', 'speaker': who, 'text': text}
    if when:
        b['when'] = when
    return b


# ---- 4 月：手册回响（只在读过第一章第三条的人那里出现）
m4 = by_id['M04_OPEN']
assert not any(str(b.get('text', '')).startswith('手册第一章第三条') for b in m4['beats']), '4月回响已存在'
m4['beats'].append(nar('手册第一章第三条下有行铅笔字：「我觉得比之前好」，我写过一次。',
                       {'flag': 'handbook_page_1.3'}))

# ---- 4 月：两周之后按 E05 选择只显示一版
notice = by_id['M04_NOTICE']
notice['beats'][0:1] = [
    nar('两周。你把 41 条工单整理并扩展成 118 条测试记录，其中 9 条仍无法复现。'
        '小林负责的第二期移到了下月，看板上登记的排期调整人是王哥。',
        {'flag': 'm04_e05_full_evalset'}),
    nar('两周。这单按时交了，陈工把需求数往前推了一格。评测表还没填表头。',
        {'flag': 'm04_e05_no_evalset'}),
    nar('两周。你那张表盖住了物流那一类，另外两类仍没人能证明什么，第二期也留了一半。',
        {'flag': 'm04_e05_partial_evalset'}),
]

# ---- 4 月：复盘会漏掉的两拍（王哥低头写一行；小林把话头交回玩家）
e07 = by_id['E07']
texts = [str(b.get('text', '')) for b in e07['beats']]
assert not any('低头在本子上' in t for t in texts), 'E07 第一拍已存在'
at = texts.index('时间点不是证据。') + 1
e07['beats'][at:at] = [nar('王哥低头在本子上写了一行，没有看你。')]
e07['beats'].append(say('小林', '那次提交你最清楚。你说吧。'))

# ---- 5 月：月末考评提醒（本月第二批真消息；发件人用最近关系的同事，不设好感门槛）
assert 'M05_REMINDER' not in by_id, '考评提醒已存在'
nodes.append({
    'id': 'M05_REMINDER', 'month': 5, 'order': 245, 'nodeType': 'phone_batch',
    'required': False, 'senderId': 'xiao_zhao', 'timeBand': 'afternoon', 'phase': 'late',
    'reportUse': 'story_only',
    'messages': [{'text': '下个月考评。材料先自己过一遍，真被问住了就往我这边看一眼。'}],
})

# ---- 6 月：答辩第三拍的问句分支（带没带受挫那张，问的是两句话）
SETBACKS = ['m05_night_hotfix_unlogged', 'm05_night_waited',
            'm05_e17_blame_network', 'm05_e17_continue']
d3 = by_id['M06_DEF3']
if not any('你带了这张' in str(b.get('text', '')) for b in d3['beats']):
    for b in d3['beats']:
        if '就没有一件没做成的' in str(b.get('text', '')):
            b['when'] = {'noneOf': SETBACKS}
    d3['beats'].insert(0, say('老周', '你带了这张。后来怎么收的？', {'anyOf': SETBACKS}))

open(EV, 'w', encoding='utf-8', newline='').write(
    json.dumps(doc, ensure_ascii=False, indent=2).replace('\n', nl) + nl)

# ---- manifest.nodeOrder
mraw = open(MF, encoding='utf-8', newline='').read()
mnl = '\r\n' if '\r\n' in mraw else '\n'
mf = json.loads(mraw.replace('\r\n', '\n'))
if 'M05_REMINDER' not in mf['nodeOrder']:
    mf['nodeOrder'].insert(mf['nodeOrder'].index('M05_PHONE') + 1, 'M05_REMINDER')
open(MF, 'w', encoding='utf-8', newline='').write(
    json.dumps(mf, ensure_ascii=False, indent=2).replace('\n', mnl) + mnl)
print('4–6 月补漏完成')
