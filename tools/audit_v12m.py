# -*- coding: utf-8 -*-
"""十二个月数据体检：结构、引用、口径、消费者。只读，不改任何文件。"""
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(r'E:\03_Projects\bear\workplace_town')
D = ROOT / 'data' / 'story' / 'v12m'

nodes = json.loads((D / 'events.json').read_text(encoding='utf-8'))['nodes']
acts = json.loads((D / 'activities.json').read_text(encoding='utf-8'))['activities']
hints = json.loads((D / 'hints.json').read_text(encoding='utf-8'))['hints']
man = json.loads((D / 'manifest.json').read_text(encoding='utf-8'))
hb = json.loads((ROOT / 'data' / 'story' / 'employee_handbook_12m.json').read_text(encoding='utf-8'))

town = (ROOT / 'scripts' / 'WorkplaceTown.gd').read_text(encoding='utf-8')
points = set(re.findall(r'"(M\d{2}_\w+|E\d+)":\s*Vector2', town))
location_points = set(re.findall(r'^\s*"([^"]+)":\s*Vector2',
                                 town[town.find('const LOCATION_POINTS := {'):], re.MULTILINE))
door_hooks = set(re.findall(r'"(door_\w+)":\s*Vector2', town))

act_by = {a['id']: a for a in acts}
node_ids = {str(n.get('id')) for n in nodes}
hb_pages = {c['id'] for c in hb['chapters']}
by_month = defaultdict(list)
for n in nodes:
    by_month[int(n.get('month', 0))].append(n)

problems = []


def bad(msg):
    problems.append(msg)


# 1) 手册节点解锁的页，十二个月那份手册里到底有没有
for n in nodes:
    if str(n.get('nodeType')) != 'handbook':
        continue
    for p in n.get('pages', []):
        pid = str(p.get('pageId'))
        if pid not in hb_pages:
            bad(f'{n["id"]}（第{n["month"]}月）解锁手册页 {pid}「{p.get("title")}」，'
                f'但 employee_handbook_12m.json 里没有这一页（现有 {sorted(hb_pages)}）→ 玩家点开“有新页”是空的')

# 1b) 手册每一页都要有考场：examAt 必须指向真实节点；被王哥划掉的页（struck）不考，可以不填。
#     这条是“别再往手册里塞通用职场常识”的闸门：没有一句剧情用得上的条款，进不了这本册子。
by_node_id = {str(n.get('id')): n for n in nodes}
unlocked_pages = {str(p.get('pageId')) for n in nodes if str(n.get('nodeType')) == 'handbook'
                  for p in (n.get('pages') or [])}
for ch in hb['chapters']:
    if str(ch['id']) not in unlocked_pages:
        bad(f'手册页 {ch["id"]}「{ch.get("title")}」没有任何手册节点解锁它 → 玩家一辈子翻不到')
    for cl in ch.get('clauses', []):
        pid = str(cl.get('id'))
        if bool(cl.get('struck')):
            continue
        exam = [str(x) for x in (cl.get('examAt') or [])]
        if not exam:
            bad(f'手册 {pid}「{cl.get("title")}」没写 examAt：这一页全年没有考点，玩家读完用不上')
        for nid in exam:
            if nid not in by_node_id:
                bad(f'手册 {pid} 的 examAt 指向不存在的节点 {nid}')

# 1c) 剧情里引号引用的手册原话，必须能在标题／正文／铅笔字里逐字找到。
#     以前 E19 写“手册里那句：临近评估再补记录”，手册里根本没有这句 —— 玩家按台词去翻，翻不到。
hb_quotable = []
for ch in hb['chapters']:
    hb_quotable.append(str(ch.get('title', '')))
    for cl in ch.get('clauses', []):
        hb_quotable.extend([str(cl.get('title', '')), str(cl.get('body', '')), str(cl.get('pencil', ''))])
hb_text = '\n'.join(hb_quotable)
QUOTE = re.compile(r'[「“]([^」”]{4,40})[」”]')


def _walk_strings(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for value in obj.values():
            yield from _walk_strings(value)
    elif isinstance(obj, list):
        for value in obj:
            yield from _walk_strings(value)


for n in nodes:
    for text in _walk_strings(n):
        if '手册' not in text:
            continue
        for quote in QUOTE.findall(text):
            if quote not in hb_text:
                bad(f'{n["id"]} 引用了手册原话「{quote}」，但手册里找不到这句（引用要逐字）')

# 2) 活动节点引用的去处存不存在；去处所在区当月能不能走到
for n in nodes:
    if str(n.get('nodeType')) != 'activity':
        continue
    for aid in n.get('activityIds', []):
        if str(aid) not in act_by:
            bad(f'{n["id"]} 引用不存在的去处 {aid}')

# 3) 去处的解锁条件：unlockHook 要有台词拍挂；unlockAfter 要指向真实节点
hooks_in_beats = set()
for n in nodes:
    for b in list(n.get('beats', []) or []):
        if b.get('hook'):
            hooks_in_beats.add(str(b['hook']))
    for st in n.get('stops', []) or []:
        for b in st.get('beats', []) or []:
            if b.get('hook'):
                hooks_in_beats.add(str(b['hook']))
    # 一条消息可以一次点亮多处（第 7 月小赵那句"周末打球不"开草坪 + 训练谷）
    for h in n.get('placeHooks', []) or []:
        hooks_in_beats.add(str(h))
hint_hooks = {str(h.get('trigger', '')).replace('hook:', '') for h in hints if str(h.get('trigger', '')).startswith('hook:')}
for a in acts:
    uh = str(a.get('unlockHook', ''))
    if uh and uh not in hooks_in_beats:
        bad(f'去处 {a["id"]} 等不到解锁台词：没有哪个 beat 挂 hook="{uh}"')
    if uh and uh not in door_hooks and uh not in hooks_in_beats:
        pass
    ua = str(a.get('unlockAfter', ''))
    if ua and ua not in node_ids:
        bad(f'去处 {a["id"]} 的 unlockAfter="{ua}" 不是任何节点 id')

# 4) 台词挂的钩子有没有人接（提示 / 去处 / 剧情门表）
unclaimed = sorted(hooks_in_beats - hint_hooks - {str(a.get('unlockHook')) for a in acts} - door_hooks)
for h in unclaimed:
    bad(f'beat 挂了 hook="{h}" 但没人接（提示、去处、剧情门表里都没有）')

# 5) walk 节点要有落点，否则等于不 walk
for n in nodes:
    if n.get('walk') and str(n.get('id')) not in points:
        location = str(n.get('location', ''))
        if location in location_points:
            continue
        bad(f'{n["id"]}（第{n["month"]}月）写了 walk 但没有可解析落点 → 会直接开面板，玩家不用走')

# 6) 场景图 / 内景图在不在盘上
for a in acts:
    sc = str(a.get('scene', ''))
    if sc and not (ROOT / sc.replace('res://', '')).exists():
        bad(f'去处 {a["id"]} 的场景图找不到：{sc}')

# 7) 区号合法性
for n in nodes:
    loc = str(n.get('locationId', ''))
    if loc and loc not in list('ABCDEFGH'):
        bad(f'{n["id"]} 的 locationId="{loc}" 不是 A–H')

# 8) 选项：0 或 3 个、id 顺序、apCost、stateDelta 键、旗标唯一
seen_flags = defaultdict(list)
for n in nodes:
    ch = n.get('choices')
    if ch is None:
        continue
    if len(ch) not in (0, 3):
        bad(f'{n["id"]} 有 {len(ch)} 个选项（只允许 0 或 3）')
    ids = [str(c.get('id')) for c in ch]
    if ids and ids != ['A', 'B', 'C']:
        bad(f'{n["id"]} 选项 id 不是 A/B/C 顺序：{ids}')
    for c in ch:
        for f in c.get('flags', []) or []:
            seen_flags[str(f)].append(f'{n["id"]}:{c.get("id")}')
        for k in (c.get('stateDelta', {}) or {}).keys():
            # 文档 5.数据契约：stateDelta 只允许 S/O/N/D/H/risk（risk 是合法键，别报）
            if str(k) not in ('S', 'O', 'N', 'D', 'H', 'risk'):
                bad(f'{n["id"]}:{c.get("id")} stateDelta 出现未知维度 {k}')
        if int(c.get('apCost', 0)) not in (0, 1):
            bad(f'{n["id"]}:{c.get("id")} apCost={c.get("apCost")}')
for f, where in seen_flags.items():
    if len(where) > 1:
        bad(f'旗标 {f} 被 {len(where)} 个选项重复设置：{where}')

# 9) 心情账：全年有没有任何一处活动扣心情（翻倍那条有没有东西可咬）
costed = [a['id'] for a in acts if int(a.get('hCost', 0)) > 0]
high = [f'{n["id"]}:{c.get("id")}' for n in nodes for c in (n.get('choices') or [])
        if int((c.get('stateDelta', {}) or {}).get('H', 0)) < 0]
print(f'[口径] 去处里 hCost>0 的：{costed or "一个都没有"}')
print(f'[口径] 主线选项会扣心情的：{high or "一个都没有"}')

# 10) 每月行动点额度：manifest vs 活动节点 budget
for m, budget in sorted({int(k): v for k, v in man['apByMonth'].items()}.items()):
    act_nodes = [n for n in by_month[m] if str(n.get('nodeType')) == 'activity']
    if not act_nodes:
        bad(f'第 {m} 月 manifest 给了 {budget} 点，但没有活动节点')
    for n in act_nodes:
        got = int((n.get('budget') or {}).get('ap', -1))
        if got != budget:
            bad(f'第 {m} 月活动节点 {n["id"]} 的 budget.ap={got}，与 manifest 的 {budget} 不一致')
for n in nodes:
    if str(n.get('nodeType')) == 'activity' and int(n.get('month', 0)) not in {int(k) for k in man['apByMonth']}:
        bad(f'{n["id"]} 在没有行动点额度的月份开了活动节点')

# 11) 手机批次上限
for m, cap in sorted({int(k): v for k, v in man['phoneBatchCapByMonth'].items()}.items()):
    got = len([n for n in by_month[m] if str(n.get('nodeType')) == 'phone_batch'])
    if got > cap:
        bad(f'第 {m} 月有 {got} 批手机消息，上限 {cap}')

# 12) 每月的"必玩做完"至少要有一个带选择的节点，否则月历上的必玩是空的
for m in sorted(by_month):
    req = [n for n in by_month[m] if n.get('required') and str(n.get('nodeType')) == 'main_story']
    if not req:
        bad(f'第 {m} 月没有任何必玩主线节点')

# 13) order 唯一 + 与 manifest.nodeOrder 一致
for m in sorted(by_month):
    seen = defaultdict(list)
    for n in by_month[m]:
        seen[int(n.get('order', 0))].append(str(n.get('id')))
    for o, ids in seen.items():
        if len(ids) > 1:
            bad(f'第 {m} 月 order={o} 被多个节点占用：{ids}')
    order = [str(x) for x in man['nodeOrder']]
    missing = [str(n['id']) for n in by_month[m] if str(n['id']) not in order]
    if missing:
        bad(f'第 {m} 月这些节点没进 manifest.nodeOrder：{missing}')

# 14) 带巡每站「屏末交代」：除最后一站外，最后一句必须是王哥说的，并且点出下一站。
#     玩家读完这一屏要立刻知道跟着谁、往哪儿走——最后一句含糊，黄线就没人跟。
tour = next((n for n in nodes if str(n.get('id')) == 'E01_TOUR'), None)
if tour is None:
    bad('events.json 里没有 E01_TOUR（王哥带巡）节点')
else:
    stops = tour.get('stops') or []
    if not stops:
        bad('E01_TOUR 没有任何 stops')
    for i, st in enumerate(stops):
        label = str(st.get('label', st.get('id', '')))
        beats = st.get('beats') or []
        if not beats:
            bad(f'带巡第 {i + 1} 站「{label}」一句台词都没有')
            continue
        last = beats[-1]
        if str(last.get('type')) != 'say' or str(last.get('speaker')) != '王哥':
            bad(f'带巡第 {i + 1} 站「{label}」最后一句不是王哥的话'
                f'（现在 {last.get("type")}/{last.get("speaker", "无")}）→ 玩家不知道下一步跟谁走')
            continue
        if i == len(stops) - 1:
            continue
        nxt = str(stops[i + 1].get('label', ''))
        text = str(last.get('text', ''))
        if nxt and nxt not in text and '下一个地方' not in text and '回工位' not in text:
            bad(f'带巡第 {i + 1} 站「{label}」最后一句没交代替下一站（{nxt}）：{text}')

# 14b) 代码里的路线（MONTH12_TOUR）与数据里的 stops 必须同序同 id ——
#      运行期是拿代码的站点去数据里找台词的，"下一站"名字全押在两边顺序一致上。
tour_code = re.search(r'const MONTH12_TOUR := \[(.*?)\n\]', town, re.S)
if tour_code is None:
    bad('WorkplaceTown.gd 里找不到 MONTH12_TOUR 路线表')
elif tour is not None:
    code_ids = re.findall(r'"id":\s*"(\w+)"', tour_code.group(1))
    data_ids = [str(st.get('id', '')) for st in (tour.get('stops') or [])]
    if code_ids != data_ids:
        bad(f'带巡路线与台词不同步：代码 MONTH12_TOUR={code_ids}，events.json stops={data_ids}')

print()
if problems:
    print(f'发现 {len(problems)} 条问题：')
    for p in problems:
        print('  •', p)
else:
    print('静态体检没发现问题。')
