# -*- coding: utf-8 -*-
"""第 4 月照附录 A：开场按上月 E10 分支、补日期行、复盘会的证据旁白与顺序。"""
import json

EV = r'E:\03_Projects\bear\workplace_town\data\story\v12m\events.json'
raw = open(EV, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
doc = json.loads(raw.replace('\r\n', '\n'))
by = {str(n.get('id')): n for n in doc['nodes']}


def nar(text, when=None):
    b = {'type': 'narration', 'text': text}
    if when:
        b['when'] = when
    return b


E10_FLAGS = ['m03_e10_truth_with_fallback', 'm03_e10_soft_clause', 'm03_e10_overpromise']

open_node = by['M04_OPEN']
beats = open_node['beats']
# 开场第一句按上月会上怎么答分三版；都不命中时留一句中性话，不至于空屏
if '上个月合同签了' in str(beats[0].get('text', '')) and not beats[0].get('when'):
    beats[0:1] = [
        nar('上个月合同签了。你讲清了边界，兜底那几行写进了合同。那套拣货问答月底上了线。两周过去，共享表上多了 41 条工单。',
            {'flag': 'm03_e10_truth_with_fallback'}),
        nar('上个月合同签了。最后签的是「尽商业上合理努力」。那套拣货问答月底上了线。两周过去，共享表上多了 41 条工单。',
            {'flag': 'm03_e10_soft_clause'}),
        nar('上个月合同签了。你先应下了，合同按客户的原话写的。那套拣货问答月底上了线。两周过去，共享表上多了 41 条工单。',
            {'flag': 'm03_e10_overpromise'}),
        nar('那套拣货问答上个月底上了线。两周过去，共享表上多了 41 条工单。', {'noneOf': E10_FLAGS}),
        nar('第 4 月 · 上旬，B 区工位，周一早上九点。'),
    ]

# 手册回响那一拍挪到"王哥把看板转过来"之前（册子里的位置）
idx_echo = next((i for i, b in enumerate(beats) if '手册第一章第三条' in str(b.get('text', ''))), -1)
idx_board = next((i for i, b in enumerate(beats) if '王哥把看板转过来' in str(b.get('text', ''))), -1)
if idx_echo > idx_board >= 0:
    echo = beats.pop(idx_echo)
    beats.insert(idx_board, echo)

# 复盘会：补三条"证据镜头"旁白，并把小林那句挪到截图之前
e07 = by['E07']
eb = e07['beats']
if not any('表头是你手写的字' in str(b.get('text', '')) for b in eb):
    eb[2:2] = [
        nar('曲线旁边并排放着一张表，表头是你手写的字。', {'flag': 'm04_e05_full_evalset'}),
        nar('桌上没有能对上的表。这条曲线是隔壁组从工单里数出来的。', {'flag': 'm04_e05_no_evalset'}),
        nar('你的表只盖住物流那一类。剩下那半边写着「待补」，是你的字。', {'flag': 'm04_e05_partial_evalset'}),
    ]
i_xiao = next((i for i, b in enumerate(eb) if '那次提交你最清楚' in str(b.get('text', ''))), -1)
i_shot = next((i for i, b in enumerate(eb) if '监控截图就在你手边' in str(b.get('text', ''))), -1)
if i_xiao > i_shot >= 0:
    line = eb.pop(i_xiao)
    eb.insert(i_shot, line)

open(EV, 'w', encoding='utf-8', newline='').write(
    json.dumps(doc, ensure_ascii=False, indent=2).replace('\n', nl) + nl)
print('第 4 月已按附录 A 对齐')
