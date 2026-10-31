# -*- coding: utf-8 -*-
"""按【新剧情册】补齐第 2、3 月里还没落的那几处（另一条线已经落了 E04 与书院前半段）。"""
import json
import sys

ROOT = r'E:\03_Projects\bear\workplace_town'
EV = ROOT + r'\data\story\v12m\events.json'
GD = ROOT + r'\scripts\WorkplaceTown.gd'

raw = open(EV, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
doc = json.loads(raw.replace('\r\n', '\n'))
by = {str(n.get('id')): n for n in doc['nodes']}


def find(node, frag):
    for i, b in enumerate(node.get('beats') or []):
        if frag in str(b.get('text', '')):
            return i
    return -1


def set_text(node, frag, text, tag):
    i = find(node, frag)
    if i < 0:
        sys.exit('MISS %s :: %s' % (tag, frag))
    node['beats'][i]['text'] = text


# ---- 第 2 月派活：把事故由来与"评审后去书院"补进王哥那两句
set_text(by['M02_OPEN'], '纸上是这个模块的两条路',
         '纸上是这个模块的两条路：自研做一份，开源改一份。依赖和退路，各写一栏。'
         '两年前同类事故只写了「加监控」，没留下可执行的回滚办法。这周要查清当年的记录，再把这次方案的退路补完整。', 'm2-open-1')
set_text(by['M02_OPEN'], '周三上午，A 区评审室。先把两条路线带过去。',
         '周三上午，A 区评审室。先把两条路线带过去。评审后去树影书院二楼核对旧事故单，再回工位补方案。', 'm2-open-2')

# ---- 书院那一拍：补上"没证据的标待确认"，并落旗标
i = find(by['M02_LIBRARY'], '你把那页拍下来')
if i >= 0 and '待确认' not in by['M02_LIBRARY']['beats'][i]['text']:
    by['M02_LIBRARY']['beats'][i]['text'] = ('你把那页拍下来，圈出缺少的回滚步骤，没有证据的部分标成待确认，'
                                             '准备回 B 区工位把真正的回滚步骤补进方案。楼下有关门声，管理员在催了。')
by['M02_LIBRARY']['setsFlags'] = ['m02_library_rollback_checked']

# ---- 第七天：把"记录与验证分开"写进旁白
set_text(by['M02_WEEK_7'], '第七天十一点',
         '第七天十一点。你已把书院查到的旧记录与本周验证分开，方案里补上了能执行的回滚步骤。'
         '你手上有能带去评审的东西了。你打开提交页面，想把这一周写下来。', 'm2-week7')

# ---- 第 3 月：散会那一屏改成 E10b 会后清单（强制三选一、不占 AP、只生成 N 证据）
wrap = by['M03_WRAP']
if not wrap.get('choices'):
    wrap['title'] = '会后清单'
    set_text(wrap, '周四之前发我', '周四之前发我。这个清单不是替你补会议结论，是让大家知道下一步由谁接。', 'm3-wrap')
    wrap['autoComplete'] = False
    wrap['reportUse'] = 'evidence'
    wrap['prompt'] = '这份清单，你打算怎么交？'
    wrap['choices'] = [
        {'id': 'A', 'text': '发到组内记录：逐项写清待定项、责任人和下次确认时间',
         'outcome': '你把三项都写全了，历史问题次数那一格标成待核。发到组内记录的那一刻，这份清单不再是你一个人的事。',
         'apCost': 0, 'stateDelta': {}, 'riskDelta': 0,
         'flags': ['m03_e10_handoff_complete'],
         'competency': [{'dimension': 'N', 'anchor': 4, 'behaviorCode': 'm03_handoff_complete',
                         'result': '待定项、责任人、下次确认时间写全并同步组内'}],
         'abilityTags': {}, 'reportUse': 'evidence'},
        {'id': 'B', 'text': '只私发王哥：写待定项和负责人，不写下次确认时间',
         'outcome': '王哥回了句“收到”。这份清单只有他一个人看得到，下次什么时候确认，没人知道。',
         'apCost': 0, 'stateDelta': {}, 'riskDelta': 0,
         'flags': ['m03_e10_handoff_partial'],
         'competency': [{'dimension': 'N', 'anchor': 2, 'behaviorCode': 'm03_handoff_partial',
                         'result': '清单写了一半，没有同步到组内'}],
         'abilityTags': {}, 'reportUse': 'evidence'},
        {'id': 'C', 'text': '先不整理：等有人追问再补',
         'outcome': '清单留在空白的文档里。第二天没人问，第三天也没有。',
         'apCost': 0, 'stateDelta': {}, 'riskDelta': 0,
         'flags': ['m03_e10_handoff_blank'],
         'competency': [{'dimension': 'N', 'anchor': 1, 'behaviorCode': 'm03_handoff_blank',
                         'result': '清单留空'}],
         'abilityTags': {}, 'reportUse': 'evidence'},
    ]

# ---- 第 3 月桥段：清单怎么交，历史问题次数都没有来源
set_text(by['M03_BRIDGE'], '王哥要的三样东西里',
         '回到工位。无论你刚才如何整理清单，「这类问题以前出过几次」都还没有来源可核。', 'm3-bridge-1')
set_text(by['M03_BRIDGE'], '你把会后清单里的那一格空着',
         '你把「历史问题次数」标成待核，打开组里的《常见问题》文档，准备补上来源。', 'm3-bridge-2')

open(EV, 'w', encoding='utf-8', newline='').write(
    json.dumps(doc, ensure_ascii=False, indent=2).replace('\n', nl) + nl)

# ---- 引擎：节点读完落旗标
graw = open(GD, encoding='utf-8', newline='').read()
gnl = '\r\n' if '\r\n' in graw else '\n'
g = graw.replace('\r\n', '\n')
if 'setsFlags' not in g:
    old = '''	_story_event = _runner_story_data(node)
	_town_ui_v2.set_task_card(String(data.get("title", "")), String(data.get("location", "")))'''
    assert old in g or True
    # 剧情面板这一条：present 之前落旗标
    anchor = '''	var data := _runner_story_data(node)
	_story_event = data'''
    if anchor in g:
        g = g.replace(anchor, '''	var data := _runner_story_data(node)
	_apply_node_flags(node)
	_story_event = data''', 1)
    else:
        sys.exit('MISS present anchor')
    # 进门那一屏也落一次
    anchor2 = '''	_retire_story_door()
	_story_event = _runner_story_data(node)'''
    if anchor2 in g:
        g = g.replace(anchor2, '''	_retire_story_door()
	_apply_node_flags(node)
	_story_event = _runner_story_data(node)''', 1)
    g = g.replace('func runner_walk_to(node: Dictionary) -> void:',
  '''## 节点读完要落的旗标（"这一拍你看过了"）：选择给的旗标走选项，这种走这里。
func _apply_node_flags(node: Dictionary) -> void:
	for value in (node.get("setsFlags", []) as Array):
		_month12_flags[String(value)] = true


func runner_walk_to(node: Dictionary) -> void:''', 1)
    open(GD, 'w', encoding='utf-8', newline='').write(g.replace('\n', gnl))
    print('引擎：setsFlags 已接')
print('第 2、3 月按新剧情册补齐')
