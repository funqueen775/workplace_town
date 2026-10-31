# -*- coding: utf-8 -*-
"""把第 3 月铺进 v12m 数据：11 个节点 + 水巷活动 + 方经理进演员表。

跑法：python tools/author_month3.py
"""
from __future__ import annotations

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
EV = ROOT / "data/story/v12m/events.json"
AC = ROOT / "data/story/v12m/activities.json"
MF = ROOT / "data/story/v12m/manifest.json"


def load(path: pathlib.Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save(path: pathlib.Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    ev, ac, mf = load(EV), load(AC), load(MF)
    if any(n["id"] == "M03_OPEN" for n in ev["nodes"]):
        print("第 3 月已经铺过了，不动")
        return 0

    nodes: list[dict] = []

    nodes.append({
        "id": "M03_PHONE_1", "month": 3, "order": 195, "nodeType": "phone_batch",
        "required": False, "batchId": "m03_batch_wang", "senderId": "wang_ge",
        "senderName": "王哥", "senderRole": "技术导师",
        "messages": [
            {"id": "m03_wang_1", "text": "周三上午十点，客户到展厅谈合同。陈工今天盯回滚，来不了——你替我去，小林带你。"},
            {"id": "m03_wang_2", "text": "他们要的是定心丸，不是学术报告。"},
        ],
        "replyOptions": [{"id": "ack", "text": "知道了，我提前到。"}],
        "timeBand": "morning", "phase": "early", "reportUse": "story_only",
        "deliveredDuring": "M03_OPEN", "day": 1, "hour": 8,
    })

    nodes.append({
        "id": "M03_OPEN", "month": 3, "order": 200, "nodeType": "main_story",
        "required": True, "title": "客户来访", "locationId": "B", "location": "B 区工位",
        "durationMinutes": 20, "situation": "weak", "autoComplete": True,
        "beats": [
            {"type": "narration", "text": "小林的消息先进来，比王哥早。"},
            {"type": "narration", "text": "合同草稿在打印机上，你抽了两遍才抽齐。"},
            {"type": "narration", "text": "周三上午十点，C 区水巷，客户展厅。目标行跟着亮起来。"},
        ],
        "choices": [],
        "timeBand": "morning", "phase": "early", "reportUse": "story_only",
        "todayCard": {
            "title": "第三月 · 客户来访",
            "lines": [
                "王哥一早就发消息：十点，C 区展厅，你替我去。",
                "客户要的是定心丸，不是学术报告。",
                "带上合同草稿，别的现场再说。",
            ],
            "shots": ["place_card_waterway_1.png"],
        },
        "day": 1, "hour": 9,
    })

    nodes.append({
        "id": "E10", "month": 3, "order": 210, "nodeType": "main_story",
        "required": True, "title": "保证不胡说", "locationId": "C",
        "location": "C 区 创意水巷 · 客户展厅", "durationMinutes": 90,
        "situation": "medium", "walk": True,
        "beats": [
            {"type": "narration", "text": "展厅里，客户坐在右边，小林坐在左边。王哥没来。"},
            {"type": "say", "speaker": "方经理", "text": "禾丰仓配，方经理。合同我带了。"},
            {"type": "say", "speaker": "方经理", "text": "合同里加一句，保证百分之百不胡说。",
             "emphasis": ["保证百分之百不胡说"]},
            {"type": "say", "speaker": "方经理", "text": "别跟我讲概率。我只问，出了问题谁负责？"},
            {"type": "phone_cinematic", "speaker": "王哥",
             "text": "你可以把概率压下去，别把概率写成誓言。"},
            {"type": "narration", "text": "小林把笔放到合同旁边，没有替你回答。"},
            {"type": "say", "speaker": "小林",
             "text": "你现在说做不到，这单可能就没了。你现在说做得到，以后可能是我们没了。",
             "emphasis": ["以后可能是我们没了"]},
            {"type": "say", "speaker": "方经理", "text": "所以，能不能写？"},
        ],
        "prompt": "怎么答？",
        "choices": [
            {
                "id": "A", "text": "如实说边界，给具体兜底",
                "outcome": "你说：出错率压到千分之三以下；真出事，二十四小时内人工复核、逐条改口，当月不算完成。"
                           "方经理沉默了一会儿：那把兜底写具体。别再给我讲概念。",
                "emphasis": ["那把兜底写具体"],
                "apCost": 0, "stateDelta": {"D": 2}, "riskDelta": 0,
                "flags": ["m03_e10_truth_with_fallback", "m03_scope_narrowed"],
                "competency": [{"dimension": "D", "anchor": 4,
                                "behaviorCode": "m03_boundary_with_fallback",
                                "result": "把边界说清并给出可执行的兜底"}],
                "abilityTags": {"integrity": 2},
                "reportUse": "evidence",
            },
            {
                "id": "B", "text": "签“尽商业上合理努力”",
                "outcome": "小林把“保证”改成“尽商业上合理努力”。双方都知道这句话有多软。",
                "emphasis": ["双方都知道这句话有多软"],
                "apCost": 0, "stateDelta": {"O": 1, "D": -1}, "riskDelta": 1,
                "flags": ["m03_e10_soft_clause"],
                "competency": [{"dimension": "D", "anchor": 2,
                                "behaviorCode": "m03_soft_clause_signed",
                                "result": "签下不用保证结果的软条款"}],
                "abilityTags": {"expression": 2},
                "reportUse": "evidence",
            },
            {
                "id": "C", "text": "先答应，先把单子拿下",
                "outcome": "方经理终于点头。小林在桌下踢了你一下，你没看懂她是在庆祝还是提醒。",
                "emphasis": ["你没看懂她是在庆祝还是提醒"],
                "apCost": 0, "stateDelta": {"O": 2, "D": -2}, "riskDelta": 2,
                "flags": ["m03_e10_overpromise"],
                "competency": [{"dimension": "D", "anchor": 1,
                                "behaviorCode": "m03_overpromise_accepted",
                                "result": "先答应客户，承诺边界没定"}],
                "abilityTags": {"collaboration": 1},
                "reportUse": "evidence",
            },
        ],
        "timeBand": "morning", "phase": "early", "reportUse": "evidence",
        "zoneCut": "C", "whenText": "周三上午", "day": 3, "hour": 10,
    })

    nodes.append({
        "id": "M03_WRAP", "month": 3, "order": 215, "nodeType": "main_story",
        "required": True, "title": "散会", "locationId": "C", "location": "C 区 展厅门口",
        "durationMinutes": 15, "situation": "weak", "autoComplete": True,
        "beats": [
            {"type": "narration", "text": "散会时王哥在门口等着。", "emphasis": ["王哥在门口等着"]},
            {"type": "say", "speaker": "王哥",
             "text": "会后把三样东西写出来发我：哪些还没定，谁负责，什么时候再确认。"},
            {"type": "say", "speaker": "王哥", "text": "周四之前发我。写不全，这个会就白开了。"},
            {"type": "say", "speaker": "小林", "text": "以后见客户基本都在这儿。旁边那家咖啡还行。",
             "hook": "unlock_waterway"},
        ],
        "choices": [],
        "timeBand": "morning", "phase": "early", "reportUse": "story_only",
        "day": 3, "hour": 11,
    })

    nodes.append({
        "id": "M03_ACTIVITY", "month": 3, "order": 220, "nodeType": "activity",
        "required": False,
        "activityIds": ["m1_tool", "m1_rooftop", "m1_lakeside", "m3_waterway"],
        "allowSkip": True, "skipFlag": "m03_activity_skipped", "endMonthLabel": "结束这个月",
        "timeBand": "afternoon", "phase": "mid", "reportUse": "story_only",
        "entryMode": "on_site", "budget": {"ap": 2, "slots": 2}, "day": 3, "hour": 14,
    })

    nodes.append({
        "id": "M03_BRIDGE", "month": 3, "order": 230, "nodeType": "main_story",
        "required": True, "title": "补会后记录", "locationId": "B", "location": "B 区工位",
        "durationMinutes": 30, "situation": "weak", "autoComplete": True,
        "beats": [
            {"type": "narration", "text": "回到工位。王哥要的三样东西里，有一项是“这类问题以前出过几次”。"},
            {"type": "narration", "text": "你在组里的《常见问题》文档里搜了十分钟。最后更新停在一月。"},
            {"type": "narration", "text": "你在群里问：“这个数谁有？” 半小时过去，没人回。"},
            {"type": "narration", "text": "你把会后清单里的那一格空着，先把文档开在屏幕上。"},
        ],
        "choices": [],
        "timeBand": "afternoon", "phase": "late", "reportUse": "story_only",
        "day": 3, "hour": 18,
    })

    nodes.append({
        "id": "M03_MID", "month": 3, "order": 235, "nodeType": "main_story",
        "required": True, "title": "中旬", "locationId": "B", "location": "B 区工位",
        "durationMinutes": 5, "situation": "weak", "autoComplete": True,
        "beats": [
            {"type": "narration", "text": "兜底条款跑了两周，没出事，也没人提起。"},
        ],
        "choices": [],
        "timeBand": "afternoon", "phase": "mid", "reportUse": "story_only",
        "day": 12, "hour": 10,
    })

    nodes.append({
        "id": "E12", "month": 3, "order": 238, "nodeType": "main_story",
        "required": True, "title": "它记不住中间那段", "locationId": "B",
        "location": "B 区工位", "durationMinutes": 20, "situation": "weak",
        "autoComplete": True,
        "beats": [
            {"type": "narration", "text": "你又打开那份《常见问题》。结论还在，怎么得出结论的过程不在。"},
            {"type": "phone_cinematic", "speaker": "小赵",
             "text": "找到了。规则写在半年前一张群聊截图里，发消息的人已经离职了。我把截图发你。"},
            {"type": "narration", "text": "你修了三周的问题没有复发。它只是从来没真正被修过。",
             "emphasis": ["从来没真正被修过"]},
            {"type": "phone_cinematic", "speaker": "小赵",
             "text": "我们是不是该把这些东西从大家脑子里捞出来？"},
        ],
        "prompt": "这份没人接得住的旧记录，怎么办？",
        "choices": [
            {"id": "A", "text": "建一个团队共用的知识库",
             "outcome": "小赵新建了目录，第一篇文档的标题是“别再从群聊考古”。",
             "emphasis": ["别再从群聊考古"], "apCost": 0,
             "flags": ["m03_e12_team_knowledge_base"], "abilityTags": {"collaboration": 2}},
            {"id": "B", "text": "只给自己的模块加分段索引",
             "outcome": "你的模块安静下来，别人的模块还在继续猜谜。",
             "emphasis": ["别人的模块还在继续猜谜"], "apCost": 0,
             "flags": ["m03_e12_own_module_index"], "abilityTags": {"technical": 1}},
            {"id": "C", "text": "在文档里加一行加粗提示",
             "outcome": "问题被一行加粗文字按回水下。",
             "emphasis": ["按回水下"], "apCost": 0,
             "flags": ["m03_e12_bold_note", "m03_e12_future_recurrence"],
             "abilityTags": {"expression": 1}},
        ],
        "timeBand": "night", "phase": "late", "reportUse": "story_only",
        "day": 25, "hour": 23,
    })

    phone_variants = [
        ("m03_e10_truth_with_fallback", "A", "m03_wrap_a",
         "客户那边居然签了。你怎么想到当面把话说开？"),
        ("m03_e10_soft_clause", "B", "m03_wrap_b",
         "“尽商业上合理努力”……我查了半天才知道这词什么意思。"),
        ("m03_e10_overpromise", "C", "m03_wrap_c",
         "听说小林回来脸色不太对。今天回去会不会不太好？"),
    ]
    for offset, (flag, letter, message_id, text) in enumerate(phone_variants):
        nodes.append({
            "id": "M03_PHONE_%s" % letter, "month": 3, "order": 240 + offset,
            "nodeType": "phone_batch", "required": False,
            "batchId": "m03_batch_xiaozhao_%s" % letter.lower(),
            "senderId": "xiao_zhao", "senderName": "小赵", "senderRole": "同事",
            "messages": [{"id": message_id, "text": text}],
            "when": {"flag": flag},
            "timeBand": "night", "phase": "late", "reportUse": "story_only",
            "deliveredDuring": "M03_CLOSE", "day": 26, "hour": 20,
        })

    nodes.append({
        "id": "M03_CLOSE", "month": 3, "order": 250, "nodeType": "month_close",
        "required": True, "defaultText": "客户走了，会议记录里没写你的名字。",
        "autoSave": True,
        "cards": [
            {"when": {"flag": "m03_e10_truth_with_fallback"},
             "text": "第 3 月：你把边界说清楚了，客户让你把兜底写具体。"},
            {"when": {"flag": "m03_e10_soft_clause"},
             "text": "第 3 月：合同换成了一句更软的承诺，双方都知道它有多软。"},
            {"when": {"flag": "m03_e10_overpromise"},
             "text": "第 3 月：客户点了头。小林没说这件事算不算过去。"},
        ],
        "timeBand": "night", "phase": "late", "reportUse": "story_only",
        "day": 28, "hour": 22,
    })

    ev["nodes"].extend(nodes)

    if not any(npc.get("id") == "fang_manager" for npc in mf["npcs"]):
        mf["npcs"].append({"id": "fang_manager", "name": "方经理",
                           "role": "客户 · 禾丰仓配", "inRelationSystem": False})

    if 3 not in mf["authoredMonths"]:
        mf["authoredMonths"].append(3)
        mf["authoredMonths"].sort()
    mf["nodeOrder"] = mf["nodeOrder"] + [node["id"] for node in nodes]

    if not any(item.get("id") == "m3_waterway" for item in ac["activities"]):
        ac["activities"].append({
            "id": "m3_waterway", "name": "水巷外摆", "locationId": "C",
            "location": "C 区水巷外摆",
            "scene": "res://assets/场景内部图/创意水巷.png",
            "description": "在吧台前坐一会儿。",
            "apCost": 1, "slots": 1,
            "outcome": "凳子有点晃，咖啡一般，但话比咖啡多。",
            "mode": "solo", "portal": {"zoneId": "C"}, "hCost": 0,
            "placeLine": "坐一下午，不加分，也不掉东西。",
            "card": {
                "title": "水巷外摆",
                "lines": ["谈完客户的人都在这排坐着。",
                          "坐一下午不加分，也不掉东西。",
                          "去坐吧台前那把高脚凳。"],
                "shots": ["place_card_waterway_1.png"],
                "pages": 1,
            },
            "unlockAfter": "M03_WRAP", "gatedBy": "month_required",
            "object": "吧台前那把高脚凳",
            "againLine": "凳子有点晃，咖啡还是那个味。",
        })

    save(EV, ev)
    save(AC, ac)
    save(MF, mf)
    print("已写入节点 %d 个；authoredMonths=%s" % (len(nodes), mf["authoredMonths"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
