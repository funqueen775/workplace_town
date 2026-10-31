#!/usr/bin/env python3
"""第 7 月补「反馈纸放哪儿」+ 第 12 月按剧情册补齐（门外四句 / 未提名面谈 / 结果反馈纸 / 那把椅子三选 / 告别三档）。

读—改—写，只碰这两个月的节点。旗标名一律用剧情册自己的字段。
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/story/v12m/events.json"
MANIFEST = ROOT / "data/story/v12m/manifest.json"


def narration(text: str, **extra) -> dict:
    beat = {"type": "narration", "text": text}
    beat.update(extra)
    return beat


def say(speaker: str, text: str, **extra) -> dict:
    beat = {"type": "say", "speaker": speaker, "text": text}
    beat.update(extra)
    return beat


def comp(dim: str, anchor: int, code: str, result: str) -> list[dict]:
    return [{"dimension": dim, "anchor": anchor, "behaviorCode": code, "result": result}]


def note(text: str, tone: str = "gold") -> dict:
    return {"text": text, "tone": tone}


NODES: dict[str, dict] = {}

# ------------------------------------------------------------------ 第 7 月
# B 段「延期分支｜王哥的反馈纸」：剧情册是两版选择（折起来 / 夹进第三章），
# 只在延期那一版出现；夹进第三章那张纸要在第 12 月前一晚被回收，所以旗标得写死。
NODES["M07_PAPER"] = {
    "id": "M07_PAPER",
    "month": 7,
    "order": 207,
    "nodeType": "main_story",
    "required": True,
    "title": "这张纸你放哪儿",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("王哥把纸放在键盘旁边。上面没有分数，只列了四项，每项一两句话。"),
        say("王哥", "先看需要补的那一项。别拿它当整个人的结论。"),
        narration("技能、产出、人脉、状态四项，每项只写一条反馈，没有数字。"),
        say("王哥", "纸你自己留着。"),
        say("王哥", "材料我放你桌上了。哪一项不清楚，去问陈工，别自己猜。"),
        say("陈工", "（路过）需要补的那段写清楚，复核我会参加。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "折起来放桌角：折好，放在键盘旁。",
            "outcome": "纸角压住了一张还没归档的工单。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m07_review_note_desk"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "夹进第三章：翻开刚解锁的手册，把纸夹在第三章后面。",
            "outcome": "纸页比手册薄，合上后还是能看出一点折痕。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m07_review_note_manual"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "early",
    "reportUse": "story_only",
    "memoryNote": {
        "A": note("那张纸压在桌角。", "gray"),
        "B": note("那张纸夹在手册第三章。", "gold"),
    },
    "when": {"flag": "m07_probation_deferred"},
}

# E19 补齐剧情册里"通过 / 延期"两版陈工的话，和"没读第三章"那一版旁白。
_E19_EXTRA = [
    narration("你先看时间线，再看自己的名字在哪一格。",
              when={"notFlag": "handbook_page_3.3"}),
    say("陈工", "这条规则你一直在维护。你按提交、审核、上线的顺序讲。",
        when={"notFlag": "m07_probation_deferred"}),
    say("陈工", "这次先把整条链听完。王哥，你现在谁在盯回滚？",
        when={"flag": "m07_probation_deferred"}),
    say("王哥", "我和测试先盯着。",
        when={"flag": "m07_probation_deferred"}),
    say("陈工", "好。你也把自己提交的那一段补清楚。",
        when={"flag": "m07_probation_deferred"}),
]

# ------------------------------------------------------------------ 第 12 月
NODES["M12_OPEN"] = {
    "id": "M12_OPEN",
    "month": 12,
    "order": 200,
    "nodeType": "main_story",
    "required": True,
    "title": "前一晚",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "strong",
    "autoComplete": True,
    "beats": [
        narration("楼层已经空了，只有你这排灯还亮着。"),
        narration("桌上有电脑、手册，还有一只待归档的纸箱，里面装着这一年的项目材料。"),
        narration("明天九点，A 区大会议室。评委会问你这一年负责过什么。"),
        narration("手册就放在桌面上。这一次，你需要把它翻开。"),
        narration("3.3 下面那行铅笔字比正文小：“等你要用的时候，补来不及了。”"),
        narration("铅笔字底下压着一个纸角——是第七月那张反馈纸，你当时把它夹进了第三章。",
                  when={"flag": "m07_review_note_manual"}),
    ],
    "choices": [],
    "timeBand": "night",
    "phase": "early",
    "reportUse": "story_only",
    "todayCard": {
        "title": "第十二月 · 前一晚",
        "lines": [
            "明天上午答辩，今晚楼层是空的。",
            "桌上有手册和一只待归档的纸箱。",
            "评委要问你这一年负责过什么。"
        ],
        "shots": ["place_card_tool_1.png"]
    },
}

NODES["M12_DOOR"] = {
    "id": "M12_DOOR",
    "month": 12,
    "order": 210,
    "nodeType": "main_story",
    "required": True,
    "title": "门外",
    "locationId": "A",
    "location": "A 区大会议室门外",
    "durationMinutes": 15,
    "situation": "strong",
    "autoComplete": True,
    "beats": [
        narration("走廊里，门关着。王哥、小林、小赵、老周分散站着，依次跟你说一句。",
                  when={"notFlag": "m12_not_nominated"}),
        say("王哥", "别说自己从没犯过错。讲清楚哪一步出了问题，后来怎么补的。",
            when={"notFlag": "m12_not_nominated"}),
        say("王哥", "我把你报上去了。该讲清楚的，今天你自己讲。",
            when={"notFlag": "m12_not_nominated"}),
        say("小林", "技术别讲太满。他们真听懂了，会继续往下问。",
            when={"notFlag": "m12_not_nominated"}),
        say("小赵", "我把你第一年的架构图扫描进去了。看着有点……勇敢。",
            when={"notFlag": "m12_not_nominated"}, abilityPeak=["technical"]),
        say("小赵", "合规那件我也放进去了。具体怎么处理，让他们看记录。",
            when={"notFlag": "m12_not_nominated", "flag": "m08_e25_reported"}),
        say("老周", "十点前先把材料放好。门开了就进去。",
            when={"notFlag": "m12_not_nominated"}),
        narration("门把手亮了一下。", when={"notFlag": "m12_not_nominated"}),
    ],
    "choices": [],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "A",
}

NODES["M12_FEEDBACK"] = {
    "id": "M12_FEEDBACK",
    "month": 12,
    "order": 212,
    "nodeType": "main_story",
    "required": True,
    "title": "小会议桌",
    "locationId": "A",
    "location": "A 区小会议桌",
    "durationMinutes": 20,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        narration("门里有人在准备材料。陈工把你叫到小会议桌旁，桌上只有两把椅子。"),
        say("陈工", "这次名单没有报你。我们还是把材料过一遍，看看下一次窗口还缺什么。"),
        say("陈工", "你先挑一项最想问清楚的。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "问具体差距：“哪一项材料最影响这次提名？我想知道下一次该补什么。”",
            "outcome": "陈工打开评审清单，指出一项已有记录不足的地方。",
            "apCost": 0,
            "stateDelta": {"D": 1},
            "riskDelta": 0,
            "flags": ["m12_not_nominated_criteria_requested"],
            "competency": comp("D", 3, "m12_not_nominated_criteria_requested", "把自己差的这一项问到具体"),
            "abilityTags": {"expression": 1},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "说明下一步：“我先把贡献记录和交接材料补齐，下一次再申请。”",
            "outcome": "陈工：“可以。补好以后先给王哥看，别等到截止前。”",
            "apCost": 0,
            "stateDelta": {"O": 1},
            "riskDelta": 0,
            "flags": ["m12_not_nominated_next_plan"],
            "competency": comp("O", 3, "m12_not_nominated_next_plan", "给出下一步补材料的计划"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "暂时不追问：“好，我知道了。”",
            "outcome": "陈工把清单合上：“有问题再来找我。”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_not_nominated_no_question"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "evidence",
    "zoneCut": "A",
    "memoryNote": {
        "A": note("我问清了下一次该补哪一项。"),
        "B": note("我跟陈工说了下一步怎么补。"),
        "C": note("那天我没多问。", "gray"),
    },
    "when": {"flag": "m12_not_nominated"},
}

# 答辩那一整段：未获提名的玩家跳过（剧情册 B 段【分支】）。
_E50_GATE = {"when": {"notFlag": "m12_not_nominated"}}

NODES["E50_slide"] = {
    "id": "E50_slide",
    "month": 12,
    "order": 221,
    "nodeType": "main_story",
    "required": True,
    "title": "先讲哪一页",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 45,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        narration("投影第一张是你第二个月的技术选型记录。标题和图表按当时的选择显示。"),
        narration("中间是技术委员会负责人，左边跨部门评委，右边记录评委。王哥不坐评委席——他是提名主管。"),
        say("大领导", "你最想让我们记住哪一部分？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "先讲一次失败：先讲一次没做好的事、当时的判断和后来怎么补。",
            "outcome": "评委按时间线追问，材料里没有的部分不会自动替玩家补成成功。",
            "apCost": 0,
            "stateDelta": {"D": 1},
            "riskDelta": 0,
            "flags": ["m12_slide_order_failure"],
            "competency": comp("D", 4, "m12_slide_order_failure", "第一页讲的是一次失败和后来怎么补"),
            "abilityTags": {"expression": 1},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "先讲数据：从有来源的结果数字开始。",
            "outcome": "大领导继续问分母、时间范围和团队贡献。",
            "apCost": 0,
            "stateDelta": {"O": 1},
            "riskDelta": 0,
            "flags": ["m12_slide_order_data"],
            "competency": comp("O", 4, "m12_slide_order_data", "第一页讲有来源的数据"),
            "abilityTags": {"expression": 1},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "先讲团队接手：讲团队后来如何继续用这套东西。",
            "outcome": "评委追问你本人做了哪一段。",
            "apCost": 0,
            "stateDelta": {"N": 1},
            "riskDelta": 0,
            "flags": ["m12_slide_order_handoff"],
            "competency": comp("N", 4, "m12_slide_order_handoff", "第一页讲团队怎么接手"),
            "abilityTags": {"expression": 1},
            "reportUse": "evidence",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "evidence",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["E50_ownership"] = {
    "id": "E50_ownership",
    "month": 12,
    "order": 222,
    "nodeType": "main_story",
    "required": True,
    "title": "哪一段是你负责的",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 45,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        narration("你讲到接口、评测和召回率。左边的评委抬手打断了你。"),
        say("跨部门评委", "这些细节先放一下。这个项目如果不做，会造成什么实际问题？"),
        narration("他不是来确认你会不会写代码。他要知道这件事值不值得交给更高一级的人负责。"),
        say("大领导", "这个项目里，哪一部分是你自己做的？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "把团队工作分开：“路由和评测是我负责的。接口由王哥搭，产品口径是小林确认的。”",
            "outcome": "评委点头：“清楚。你负责的部分，我们就按这部分问。”",
            "apCost": 0,
            "stateDelta": {"D": 2},
            "riskDelta": 0,
            "flags": ["m12_ownership_precise"],
            "competency": comp("D", 4, "m12_ownership_precise", "把每一段的归属讲清"),
            "abilityTags": {"expression": 2},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "承认说不清：“我现在讲不清每一段是谁改的。材料里的分工记录不够。”",
            "outcome": "记录评委记下一行；不把诚实承认写成虚构的完整归属。",
            "apCost": 0,
            "stateDelta": {"D": 1},
            "riskDelta": 0,
            "flags": ["m12_ownership_unverified"],
            "competency": comp("D", 3, "m12_ownership_unverified", "说不清就承认记录不够"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "把团队成果全算自己：“我们做的就是我做的。”",
            "outcome": "右边评委抬头：“名单上还有两个人。上周最后改这个模块的是谁？”",
            "apCost": 0,
            "stateDelta": {"D": -2, "risk": 1},
            "riskDelta": 1,
            "flags": ["m12_ownership_overclaim"],
            "competency": comp("D", 1, "m12_ownership_overclaim", "把团队成果全算成自己的"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "evidence",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["E50_recovery"] = {
    "id": "E50_recovery",
    "month": 12,
    "order": 223,
    "nodeType": "main_story",
    "required": True,
    "title": "这一句还能不能收回来",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        say("大领导", "刚才那句，你再说一遍？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "收回说法：“我刚才说大了。这是团队成果，我负责的是路由和评测。”",
            "outcome": "大领导：“这句比刚才那句有用。”",
            "apCost": 0,
            "stateDelta": {"D": 1},
            "riskDelta": 0,
            "flags": ["m12_ownership_recovery_admitted"],
            "competency": comp("D", 3, "m12_ownership_recovery_admitted", "当场合回说大的那一句"),
            "abilityTags": {"expression": 1},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "继续坚持：“我参与最深，其他部分我也跟过。”",
            "outcome": "会议室安静了两秒。记录评委把笔放下。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_ownership_recovery_held"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "把责任推给同事：“这块是他改的，我不管那一段。”",
            "outcome": "大领导：“那你今天讲的这一页，和你申请的级别有什么关系？”",
            "apCost": 0,
            "stateDelta": {"N": -1},
            "riskDelta": 0,
            "flags": ["m12_ownership_recovery_shifted"],
            "competency": comp("N", 1, "m12_ownership_recovery_shifted", "把归属推给不在场的同事"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "A",
    "when": {"flag": "m12_ownership_overclaim"},
}

NODES["E50_metric_l1"] = {
    "id": "E50_metric_l1",
    "month": 12,
    "order": 224,
    "nodeType": "main_story",
    "required": True,
    "title": "这个数降了多少、基数是什么",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        narration("系统从你确实有的材料里挑出一项关键数据，把来源、样本、时间窗和归属一起投在屏幕上。"),
        say("大领导", "你材料里的这个数，降了多少？基数是什么？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "给出有来源的口径：按屏幕证据说数值、样本量、时间范围和自己负责的部分。",
            "outcome": "评委把数和来源一起记下。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l1_specified"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "说没核算过：“这部分我没有做过独立核算，不能把估算当实测。”",
            "outcome": "记录评委备注“未核算”；不自动判答辩失败。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l1_unknown"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "含糊报数：“大概三成吧，整体看起来少了不少。”",
            "outcome": "跨部门评委：“大概是哪一段时间？你有底表吗？”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l1_vague"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["E50_metric_l2"] = {
    "id": "E50_metric_l2",
    "month": 12,
    "order": 225,
    "nodeType": "main_story",
    "required": True,
    "title": "对比的是哪一段",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        say("跨部门评委", "对比的是哪一段？中间还有别的改动吗？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "给出时间窗：指出比较期间、版本和同期改动；记录缺失就把缺失说出来。",
            "outcome": "评委翻到对应版本记录。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l2_windowed"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "承认没留对照：“这段没有完整对照。我只能说明上线前后观察到的变化。”",
            "outcome": "记录评委写下“缺少对照期间”。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l2_limitation"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "用趋势代替口径：“反正每周都在往下走。”",
            "outcome": "跨部门评委：“我听懂趋势了，没听懂你比的是哪几周。”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l2_trend_only"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["E50_metric_l3"] = {
    "id": "E50_metric_l3",
    "month": 12,
    "order": 226,
    "nodeType": "main_story",
    "required": True,
    "title": "你不做，它自己会降吗",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        say("大领导", "如果你不做这件事，它自己会降吗？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "讲清因果证据：说明有没有对照、排除了哪些同期变化。",
            "outcome": "大领导：“有这条记录，下次把对照补上。”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l3_causal_scope"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "承认没验证反事实：“我没做过反事实验证。能确认的是这段时间的观察，不是一定由我造成。”",
            "outcome": "大领导：“好，这一栏就按你实际测过的范围记。”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l3_admitted_limit"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "把前后变化当因果：“上线后确实降了，所以应该是这次改动带来的。”",
            "outcome": "大领导追问还有什么同期变化；拿不出材料，就记成“因果未证实”。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_metric_l3_unsupported_cause", "m12_cause_check_hint"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["E50_nextlevel"] = {
    "id": "E50_nextlevel",
    "month": 12,
    "order": 227,
    "nodeType": "main_story",
    "required": True,
    "title": "升到下一级你想承担什么",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        say("跨部门评委", "如果升到下一级，你打算承担什么？如果还是现在这些活，为什么要升你？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "说清更大范围：“我想接跨三条线的项目。我还没独立扛过这么大的范围，先从其中一条线开始负责。”",
            "outcome": "评委点头，要求把目标写进下一年度计划。",
            "apCost": 0,
            "stateDelta": {"O": 1},
            "riskDelta": 0,
            "flags": ["m12_next_level_expanded_scope"],
            "competency": comp("O", 4, "m12_next_level_expanded_scope", "说清更大范围并承担其中一条线"),
            "abilityTags": {"expression": 1},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "说当前交付：“我想先把现有项目文档补齐，让别人能接手。”",
            "outcome": "大领导：“这是当前职责的一部分。再说一项更大的责任。”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_next_level_current_scope"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "还没想好：“我还没想清楚具体接哪一块。”",
            "outcome": "记录评委抬头：“那你希望下一年先试哪种责任？”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_next_level_undecided"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "evidence",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["E50_selfreview"] = {
    "id": "E50_selfreview",
    "month": 12,
    "order": 228,
    "nodeType": "main_story",
    "required": True,
    "title": "你觉得自己还缺什么",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": False,
    "beats": [
        say("记录评委", "你觉得自己还缺什么？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "缺少更高一级经验：“我还没独立带过跨部门的事。下一年想负责一次，把沟通和交付都跑完整。”",
            "outcome": "记录评委慢慢写下一行。",
            "apCost": 0,
            "stateDelta": {"D": 1},
            "riskDelta": 0,
            "flags": ["m12_self_review_next_level_gap"],
            "competency": comp("D", 4, "m12_self_review_next_level_gap", "自评点到更高一级的经验缺口"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "说一项具体执行问题：“我评审时容易急，代码风格也需要统一。我已经开始用清单补这两项。”",
            "outcome": "大领导：“有改进动作，就把时间和结果也记下来。”",
            "apCost": 0,
            "stateDelta": {"S": 1},
            "riskDelta": 0,
            "flags": ["m12_self_review_actionable_gap"],
            "competency": comp("S", 4, "m12_self_review_actionable_gap", "给出一项带改进动作的具体短板"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "说暂时没发现明显短板：“我现在没发现特别大的短板。如果你们看到具体问题，我愿意拿例子回去补。”",
            "outcome": "记录评委：“好，等材料出来我们再对一次。”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_self_review_open_to_feedback"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "evidence",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["E50_picture"] = {
    "id": "E50_picture",
    "month": 12,
    "order": 229,
    "nodeType": "main_story",
    "required": True,
    "title": "哪张图会不一样",
    "locationId": "A",
    "location": "A 区大会议室",
    "durationMinutes": 15,
    "situation": "strong",
    "autoComplete": True,
    "beats": [
        narration("若前面所有回答都能和材料对上，评委仍会抽查一项——不因“答得太顺”直接判异常。"),
        say("大领导", "如果让你重做一次，哪张图会不一样？"),
        narration("投影停在第二个月那张自研 / 开源白板上。具体画面按当时的选择显示。"),
        narration("履历上那段没参与过的项目又被翻出来一次。你当场说清了它是怎么上去的。",
                  when={"flag": "m10_false_credit"}),
    ],
    "choices": [],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "A",
    **_E50_GATE,
}

NODES["M12_RESULT"] = {
    "id": "M12_RESULT",
    "month": 12,
    "order": 230,
    "nodeType": "main_story",
    "required": True,
    "title": "当天下午的结果",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "strong",
    "autoComplete": True,
    "beats": [
        narration("王哥在工位边停下来。", when={"notFlag": "m12_not_passed"}),
        say("王哥", "过了。级别升一档，明天生效。", when={"notFlag": "m12_not_passed"}),
        narration("级别那一栏按 L1–L7 更新，没有同时再显示别的口径。",
                  when={"notFlag": "m12_not_passed"}),
        narration("桌上有一张反馈纸，只显示需要补强的一项及证据。",
                  when={"flag": "m12_not_passed"}),
        say("王哥", "这次卡住你的不是技能，是产出。四件交付里能拿给别人用的有两件。下一次提名再看能不能补上。",
            when={"flag": "m12_not_passed"}),
        narration("本次没晋升不等于淘汰：不扣钱，职级不变。"),
    ],
    "choices": [],
    "timeBand": "afternoon",
    "phase": "mid",
    "reportUse": "story_only",
    "when": {"notFlag": "m12_not_nominated"},
}

NODES["M12_PAPER"] = {
    "id": "M12_PAPER",
    "month": 12,
    "order": 232,
    "nodeType": "main_story",
    "required": True,
    "title": "这张纸你放哪儿",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 15,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("反馈纸上是那一项需要补强的，和一条能核对的证据。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "折起来放桌角：把纸折好，放在键盘旁。",
            "outcome": "纸角压住一张待归档的工单。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_feedback_note_desk"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "夹进第三章：把反馈纸夹进手册第三章。",
            "outcome": "纸页露出一角，和第七个月那张纸叠在一起。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_feedback_note_manual"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "afternoon",
    "phase": "mid",
    "reportUse": "story_only",
    "memoryNote": {
        "A": note("反馈纸压在桌角。", "gray"),
        "B": note("反馈纸夹进了第三章。"),
    },
    "when": {"flag": "m12_not_passed"},
}

NODES["M12_CHAIR"] = {
    "id": "M12_CHAIR",
    "month": 12,
    "order": 240,
    "nodeType": "main_story",
    "required": True,
    "title": "那把椅子",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("你工位对面多了一把椅子。许棠坐在那里，屏幕上是第二个月那张架构图。"),
        say("许棠", "当初为什么选这条路线？"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "从头讲清：把当时的限制、试过的路线和踩过的坑都讲一遍。",
            "outcome": "你讲到一半发现自己也忘了当时为什么这样选，翻出第八个月的技术债清单才接上。许棠记了几页，也指出其中一条你当年想错了。",
            "apCost": 0,
            "stateDelta": {"N": 1, "O": 1},
            "riskDelta": 0,
            "flags": ["m12_handoff_full"],
            "competency": comp("N", 4, "m12_handoff_full", "把当年的判断从头讲给接手的人"),
            "abilityTags": {"collaboration": 1},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "只给文档：把共享盘链接发给她，告诉她先看哪两篇。",
            "outcome": "第三天她没有再问。过一阵，她把文档里缺的两步补进了交接页。",
            "apCost": 0,
            "stateDelta": {"O": 1},
            "riskDelta": 0,
            "flags": ["m12_handoff_documents"],
            "competency": comp("O", 3, "m12_handoff_documents", "只交文档、由接手人自己补齐"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "讲一半：讲操作步骤，但把关键判断留在自己手里。",
            "outcome": "许棠照着做了两次。第二次走偏的正是你没讲的那一步，她回来问你。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m12_handoff_partial"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "late",
    "reportUse": "evidence",
    "memoryNote": {
        "A": note("那次选型我从头讲给了许棠。"),
        "B": note("我只把文档发给了她。"),
        "C": note("关键那一步我没讲。", "gray"),
    },
}

NODES["M12_REPLAY"] = {
    "id": "M12_REPLAY",
    "month": 12,
    "order": 250,
    "nodeType": "main_story",
    "required": True,
    "title": "六幕，你都走过来了",
    "locationId": "E",
    "location": "心湖北岸记忆墙",
    "durationMinutes": 20,
    "situation": "weak",
    "autoComplete": True,
    "beats": [
        narration("从工位一路走到心湖北岸，风把楼道里的空调味吹掉了。最后半天，墙前没有别人。"),
        narration("六面墙，按这半年一次排下来：进入行业、真实需求与成本压力、事故与责任、重构与传承、边界与署名、提名与新局。"),
        narration("每一幕只挂你真实记下来的那张便签。一张都没有的幕保持空白，不用别的图补。"),
        narration("右上角写着“跳过”。跳过不扣任何东西。"),
    ],
    "choices": [],
    "timeBand": "afternoon",
    "phase": "late",
    "reportUse": "story_only",
}

NODES["M12_FAREWELL"] = {
    "id": "M12_FAREWELL",
    "month": 12,
    "order": 260,
    "nodeType": "main_story",
    "required": True,
    "title": "楼层门口",
    "locationId": "B",
    "location": "B 区楼层门口",
    "durationMinutes": 20,
    "situation": "weak",
    "autoComplete": True,
    "beats": [
        say("王哥", "以后遇到卡点，还可以来找我。"),
        say("小林", "下次排需求，我们再一起对。"),
        say("小赵", "你上次替我补了贡献记录，我记着。",
            when={"flag": "m09_credit_helped"}),
        say("小赵", "等我把这块接稳，请你吃饭。",
            when={"notFlag": "m09_credit_helped"}),
        say("老周", "这条路你走得比我当年顺一点。"),
    ],
    "choices": [],
    "timeBand": "afternoon",
    "phase": "late",
    "reportUse": "story_only",
}

NODES["M12_CLOSE"] = {
    "id": "M12_CLOSE",
    "month": 12,
    "order": 270,
    "nodeType": "month_close",
    "required": True,
    "defaultText": "第 12 月：一年过完了，纸箱封上了。",
    "autoSave": True,
    "cards": [
        {"when": {"flag": "m11_metric_corrected_named"},
         "text": "年度报告里，18% 和 41% 分开标着口径。"},
        {"when": {"flag": "m11_metric_submitted_unchecked"},
         "text": "年度报告用的还是那份没拆开写的材料。"},
        {"when": {"flag": "m09_handoff_complete"},
         "text": "交接文档还在被用，许棠在上面加了东西。"},
        {"when": {"flag": "m09_handoff_deferred"},
         "text": "目录第一行今年没填上；明年新人来问的时候，得由你当面讲。"},
        {"when": {"flag": "m12_not_passed"},
         "text": "这一次没晋升。反馈纸只写了需要补的那一项。"},
        {"when": {"notFlag": "m12_not_passed"},
         "text": "级别那一栏动了一格，明天生效。"},
    ],
    "timeBand": "night",
    "phase": "late",
    "reportUse": "story_only",
}


def main() -> None:
    payload = json.loads(DATA.read_text(encoding="utf-8"))
    nodes: list[dict] = payload["nodes"]

    def index_of(node_id: str) -> int:
        for i, node in enumerate(nodes):
            if str(node.get("id")) == node_id:
                return i
        return -1

    # E19：把剧情册里"没读第三章"那一版和通过/延期两版陈工的话补进对应位置
    e19 = index_of("E19")
    if e19 >= 0:
        beats = nodes[e19].get("beats", [])
        rebuilt: list[dict] = []
        for beat in beats:
            text = str(beat.get("text", ""))
            if text.startswith("你想起手册里那句"):
                rebuilt.append(_E19_EXTRA[0])
            rebuilt.append(beat)
            if text.startswith("这条规则最近一次改动记录在你的维护分支里"):
                rebuilt.extend(_E19_EXTRA[1:])
        nodes[e19]["beats"] = rebuilt

    replaced = []
    for node_id, fresh in NODES.items():
        i = index_of(node_id)
        if i >= 0:
            nodes[i] = fresh
            replaced.append(node_id)

    added = []
    insert_after = {"M07_RESULT": ["M07_PAPER"], "M12_DOOR": ["M12_FEEDBACK"],
                    "E50_selfreview": ["E50_picture"], "M12_RESULT": ["M12_PAPER"]}
    for anchor, new_ids in insert_after.items():
        i = index_of(anchor)
        if i < 0:
            continue
        for offset, new_id in enumerate(new_ids, start=1):
            if index_of(new_id) >= 0:
                continue
            nodes.insert(i + offset, NODES[new_id])
            added.append(new_id)
    for node_id, fresh in NODES.items():
        if node_id not in replaced and node_id not in added:
            nodes.append(fresh)
            added.append(node_id)

    payload["nodes"] = nodes
    DATA.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    order = [str(x) for x in manifest.get("nodeOrder", [])]
    missing = sorted(i for i in NODES if i not in order and i not in ("E19",))
    if missing:
        manifest["nodeOrder"] = order + missing
        MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("替换 %d；新增 %s；nodeOrder 补 %s" % (len(replaced), added, missing))


if __name__ == "__main__":
    main()
