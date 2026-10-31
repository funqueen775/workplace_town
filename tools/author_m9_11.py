#!/usr/bin/env python3
"""把第 9–11 月的节点按《十二个月剧情流程》重写一遍。

只改这三个月的节点内容 + 第 12 月里对旧旗标名的引用；其它月份一个字节不动。
读—改—写：先整份读进内存，替换指定 id 的节点，再整份写回。

旗标名一律用剧情册自己的字段名（m09_credit / m09_handoff / m10_name /
m10_handoff / m11_metric / m11_success_metric），不再用我上一版自造的
m09_e27_public 之类。剧情册里没写"调属性"的选项，stateDelta 就留空。
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/story/v12m/events.json"
MANIFEST = ROOT / "data/story/v12m/manifest.json"

# 旧旗标名 → 剧情册旗标名（全文件替换，含第 12 月的引用）
RENAME = {
    "m09_e27_public": "m09_credit_public_evidence",
    "m09_e27_private": "m09_credit_private_request",
    "m09_e27_silent": "m09_credit_no_action",
    "m09_e28_complete": "m09_handoff_complete",
    "m09_e28_holdback": "m09_handoff_partial",
    "m09_e28_deferred": "m09_handoff_deferred",
    "m10_e31_corrected": "m10_name_removed_by_self",
    "m10_e31_silent": "m10_name_kept_by_silence",
    "m10_e31_written": "m10_name_delegated_correction",
    "m10_e40_keep_old": "m10_handoff_legacy",
    "m10_e40_gray": "m10_handoff_validated_trial",
    "m10_e40_try_new": "m10_handoff_unreviewed_release",
    "m11_e32_split": "m11_metric_corrected_named",
    "m11_e32_feedback": "m11_metric_anonymous_report",
    "m11_e32_as_is": "m11_metric_submitted_unchecked",
    "m11_e41_redefine": "m11_success_metric_keep_growth",
    "m11_e41_keep": "m11_success_metric_appeal_review",
    "m11_e41_defer": "m11_success_metric_segmented_targets",
}


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


NODES: dict[str, dict] = {}

# ---------------------------------------------------------------- 第九个月
NODES["M09_NAME"] = {
    "id": "M09_NAME",
    "month": 9,
    "order": 205,
    "nodeType": "main_story",
    "required": True,
    "title": "名单上少了一个名字",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": True,
    "beats": [
        narration("上旬的一个上午，小赵站在工位边上，没有坐下。"),
        say("小赵", "这事我只跟你说一遍。王哥那边我还没敢提。"),
        narration("共享盘顶上的文件夹叫“Q3 项目贡献者申报”。里面已经有一张填好的表。"),
        narration("负责人一栏写着周老师，贡献者列表里没有小赵。"),
        narration("申报系统只让正式员工担任负责人；实习生的贡献可以补进说明，但这张表里还没写。"),
        narration("提交记录里有三十多条是小赵的。最后几条在夜里两点，说明只写了“先记一下，明天再理”。"),
        narration("四个月前那次复盘，你也把能核对的记录摆上了桌。",
                  when={"flag": "m04_e07_clarified_in_room"}),
        narration("四个月前那次会，你先把责任接了下来，没有继续追署名。小赵这句话听起来有点熟。",
                  when={"flag": "m04_e07_admitted_verification_gap"}),
        say("小赵", "也可能是周老师忘了。反正我还是实习生，名字写谁好像都差不多。"),
        narration("桌上的手机震了一下，屏幕朝上。"),
        say("王哥", "（群里）名单今天截止。负责人必须是正式员工，贡献说明可以补。别把两件事混成一件。"),
        narration("老周从走廊进来，看见屏幕上的名单。"),
        say("老周", "申报今天截止。小赵不是正式员工，负责人那一栏不能填他。"),
        say("小赵", "没事，我——"),
        say("老周", "我不是问你有没有事。我是在说系统怎么填。贡献说明那一栏还空着。"),
    ],
    "choices": [],
    "timeBand": "morning",
    "phase": "early",
    "reportUse": "story_only",
}

NODES["E27"] = {
    "id": "E27",
    "month": 9,
    "order": 210,
    "nodeType": "main_story",
    "required": True,
    "title": "署名这件事你怎么处理",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 45,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("表格还开着。你自己的工号在浏览器另一个标签页里，登录着。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "在申报群补记录：把可核验的提交编号、作者和时间贴进申报群；不转发客户数据或完整私聊。",
            "outcome": "老周看完回：“收到，名单我改。”新名单第二行多了小赵。小赵没有抬头，散会后在走道上等你，说了声“谢谢”。",
            "apCost": 0,
            "stateDelta": {"D": 2},
            "riskDelta": 0,
            "flags": [
                "m09_credit_public_evidence",
                "m09_credit_helped",
                "xiao_zhao_rel_plus1",
                "lao_zhou_rel_minus1",
            ],
            "competency": comp("D", 4, "m09_credit_public_evidence", "把可核验的提交记录贴进申报群佐证署名"),
            "abilityTags": {"integrity": 2},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "去走廊私下说：不在群里发记录；会后拦住老周，把作者记录和贡献说明给他看。",
            "outcome": "老周沉默了一会儿：“给我十分钟。”十分钟后新名单补上小赵，群里没人再提。第二天他路过你工位时朝你点了下头。",
            "apCost": 0,
            "stateDelta": {"D": 1, "N": 1},
            "riskDelta": 0,
            "flags": ["m09_credit_private_request", "m09_credit_helped"],
            "competency": comp("N", 4, "m09_credit_private_request", "在走廊把署名记录私下交给负责人"),
            "abilityTags": {"integrity": 1, "collaboration": 1},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "不介入：关掉页面。今天截止的名单按原样提交；你下周还要和老周一起过代码。",
            "outcome": "小赵把页面关掉，手指在自己那几行记录上划了一下：“嗯，那就先这样。”下周过代码时，老周把你负责的部分问得很细。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m09_credit_no_action"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "afternoon",
    "phase": "early",
    "reportUse": "evidence",
    "memoryNote": {
        "A": {"text": "我把那几条提交记录贴进了群。", "tone": "gold"},
        "B": {"text": "我在走廊把记录给老周看了。", "tone": "gold"},
        "C": {"text": "名单按原样交了，那一栏我没开口。", "tone": "gray"},
    },
}

NODES["M09_CONTRIB"] = {
    "id": "M09_CONTRIB",
    "month": 9,
    "order": 215,
    "nodeType": "main_story",
    "required": False,
    "title": "填自己的贡献栏",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "weak",
    "autoComplete": True,
    "beats": [
        narration("中旬的一个早上，桌上多了一张申报通知。王哥把它压在你的键盘旁。"),
        say("王哥", "你自己的那一栏今天也得填。工位上一直有人开会，去书院那张长桌写吧。"),
        narration("申报表上“我的贡献”那一栏开着。系统只列出你确实做过、而且有事件记录支持的事项——挑一条填进去，或者先留空。"),
    ],
    "choices": [],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "story_only",
}

NODES["M09_LIBRARY_SOCIAL"] = {
    "id": "M09_LIBRARY_SOCIAL",
    "month": 9,
    "order": 225,
    "nodeType": "main_story",
    "required": False,
    "title": "长桌对面那个人",
    "locationId": "D",
    "location": "树影书院 · 长桌",
    "durationMinutes": 10,
    "situation": "weak",
    "autoComplete": False,
    "beats": [
        narration("长桌这一角很安静。抬头时，对面的人正好也抬起头。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "笑一下：朝对方笑一下，继续看自己的材料。",
            "outcome": "对方点了点头，也低头继续看。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m09_library_social_smile"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "问一句：“你在看什么？”",
            "outcome": "对方把书名转给你看：“新人培训的东西，先翻翻。”",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m09_library_social_asked"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "先离开：把材料收进包里，去找个空位。",
            "outcome": "长桌继续安静下来。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m09_library_social_left"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "afternoon",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "D",
    "when": {"flag": "visit_9_m9_library"},
}

NODES["E28"] = {
    "id": "E28",
    "month": 9,
    "order": 230,
    "nodeType": "main_story",
    "required": True,
    "title": "长桌上的交接文档",
    "locationId": "D",
    "location": "树影书院 · 长桌",
    "durationMinutes": 45,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("你在长桌上把申报表里的三行写完：做过什么、卡在哪里、下一步由谁接。"),
        say("老周", "（把一张纸推过来一半）新人下周到。谁带她，还没定。"),
        narration("手册里要是少了关键一步，她还是会来问你。"),
        narration("你那张评测表还压在桌角。第一列表头是你自己写的。",
                  when={"flag": "m04_e05_full_evalset"}),
        say("老周", "目录我先建。里面写到哪一步，你决定。"),
        narration("目录第一行空着，光标停在那里。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "写完整交接：写故障案例、当时怎么判断、新人能照着排查的步骤。",
            "outcome": "两天后文档里多了七八个常见坑。新人第一次查报错就找到了根因，没有叫你过去。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m09_handoff_complete", "doc_reuse_scope_full"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "写能跑的版本：把启动、测试和回滚步骤写上；几个关键判断先留在自己脑子里。",
            "outcome": "新人照着跑起来了。遇到岔路时还是来问你，你把剩下的部分当面讲完。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m09_handoff_partial", "doc_reuse_scope_partial"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "下个迭代再写：先把目录留着，等手头迭代结束再补。",
            "outcome": "“下个迭代”一直没空出来。三个月后要准备答辩时，目录第一行还是空的。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m09_handoff_deferred"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "morning",
    "phase": "late",
    "reportUse": "story_only",
    "zoneCut": "D",
    "memoryNote": {
        "A": {"text": "交接文档我写全了。", "tone": "gold"},
        "B": {"text": "有两处判断我留在脑子里。", "tone": "gray"},
        "C": {"text": "目录第一行还是空的。", "tone": "gray"},
    },
    "when": {"flag": "visit_9_m9_library"},
}

NODES["M09_PHONE_XZ"] = {
    "id": "M09_PHONE_XZ",
    "month": 9,
    "order": 240,
    "nodeType": "phone_batch",
    "required": False,
    "batchId": "m09_batch_xz_reply",
    "senderId": "xiao_zhao",
    "senderName": "小赵",
    "senderRole": "邻组",
    "messages": [
        {
            "id": "m09_xz_a",
            "text": "老周把署名规则贴出来了。他没跟我说是因为你，反正现在贡献说明里有我。",
            "when": {"flag": "m09_credit_public_evidence"},
        },
        {
            "id": "m09_xz_b",
            "text": "周老师今天把我的名字加上了。他没说为什么，我猜他看过那几条记录。",
            "when": {"flag": "m09_credit_private_request"},
        },
    ],
    "replyOptions": [],
    "timeBand": "night",
    "phase": "late",
    "reportUse": "story_only",
}

NODES["M09_CLOSE"] = {
    "id": "M09_CLOSE",
    "month": 9,
    "order": 250,
    "nodeType": "month_close",
    "required": True,
    "defaultText": "第 9 月：名单交了，新人下周到。",
    "autoSave": True,
    "cards": [
        {"when": {"flag": "m09_credit_public_evidence"},
         "text": "共享盘里的名单补上了小赵。那几条提交记录被留在申报说明里。"},
        {"when": {"flag": "m09_credit_private_request"},
         "text": "名单改了。群里没有展开这件事，你和老周在走廊把话说完了。"},
        {"when": {"flag": "m09_credit_no_action"},
         "text": "名单按原样交了。下周你和小赵还要一起过代码。"},
        {"when": {"flag": "m09_handoff_complete"},
         "text": "新人照着文档查到一个报错根因，没有叫你过去。"},
        {"when": {"flag": "m09_handoff_partial"},
         "text": "新人能先跑起来，遇到岔路时还是来问你。"},
        {"when": {"flag": "m09_handoff_deferred"},
         "text": "目录第一行还空着。"},
    ],
    "timeBand": "night",
    "phase": "late",
    "reportUse": "story_only",
}

# ---------------------------------------------------------------- 第十个月
NODES["M10_OPEN"] = {
    "id": "M10_OPEN",
    "month": 10,
    "order": 200,
    "nodeType": "main_story",
    "required": True,
    "title": "工位旁多了一张椅子",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "medium",
    "autoComplete": True,
    "beats": [
        narration("上旬的一个早上，你工位旁边多了一张椅子。桌角压着一份打印稿，第七页折了一个角。"),
        narration("那是你上个月写的交接文档。"),
        narration("新同事许棠把临时工牌贴在电脑边，正对照着纸上的步骤操作。"),
        say("许棠", "我按到第七页了。这里我自己跑通了，还加了一条，你看这样行不行？",
            when={"flag": "m09_handoff_complete"}),
        narration("她补的那条，比你原来写的更周到。",
                  when={"flag": "m09_handoff_complete"}, abilityPeak=["collaboration"]),
        say("许棠", "前面能跑。到这一步我不确定该选哪条，所以先停了。",
            when={"flag": "m09_handoff_partial"}),
        narration("她问的正是你当时留在脑子里的两条判断。你解释了一遍，才发现自己也得先想起当时为什么这么定。",
                  when={"flag": "m09_handoff_partial"}),
        say("许棠", "我先照着共享盘里另一份材料做了。第一步之后就对不上了，你现在方便看一下吗？",
            when={"flag": "m09_handoff_deferred"}),
        narration("你看了一眼才发现，最熟的那一段一直只有你在做。",
                  when={"flag": "m09_handoff_deferred"}),
        narration("许棠先照着共享盘里现有的文档完成第一步，暂时没有需要你补充的事项。",
                  when={"notFlag": "visit_9_m9_library"}),
    ],
    "choices": [],
    "timeBand": "morning",
    "phase": "early",
    "reportUse": "story_only",
}

NODES["M10_PHONE_LZ"] = {
    "id": "M10_PHONE_LZ",
    "month": 10,
    "order": 205,
    "nodeType": "phone_batch",
    "required": False,
    "batchId": "m10_batch_laozhou",
    "senderId": "lao_zhou",
    "senderName": "老周",
    "senderRole": "资深",
    "messages": [
        {
            "id": "m10_lz",
            "text": "小赵最近敢在申报会上开口了。上次你把提交记录贴出来以后，他这回没把话缩回去。",
            "when": {"flag": "m09_credit_helped"},
            "abilityPeak": ["integrity"],
        },
    ],
    "replyOptions": [],
    "timeBand": "morning",
    "phase": "early",
    "reportUse": "story_only",
    "deliveredDuring": "M10_OPEN",
}

NODES["E31"] = {
    "id": "E31",
    "month": 10,
    "order": 210,
    "nodeType": "main_story",
    "required": True,
    "title": "公告栏上第三行是你的名字",
    "locationId": "A",
    "location": "A 区公告栏",
    "durationMinutes": 45,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("中旬的一个上午，公告栏上贴着一张 A4，右上角写着“公示四天”。第三行是你的名字。"),
        say("小林", "恭喜。你多了一段没做过的项目经历。"),
        narration("你只在走廊里听过那个项目，从没参与过。"),
        say("小赵", "会不会是行政从旧表里复制过来的？"),
        say("老周", "负责人名额已经报满。公示这几天只能直接改错别字。要改人名，得出情况说明，陈工签字，再往上报。"),
        narration("你说自己没做过。老周又看了一遍表，没有马上接话。"),
        say("老周", "以前怕名字漏掉。现在轮到你怕名字多了。"),
        narration("名单上的项目成果写得很具体。你如果不提，之后答辩时它也会出现在你的履历里。"),
        narration("四个月前你也没继续追问署名，只把那次责任接了下来。",
                  when={"flag": "m04_e07_admitted_verification_gap"}),
        narration("你认得那种提交记录。四个月前，自己的名字也在一份复盘纪要的责任栏里。",
                  when={"flag": "m04_e07_clarified_in_room"}),
        narration("公示说明：在公示期内可改错字；增删人员需提交书面说明并重新审批。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "正式申请撤名：去找陈工，说明自己没参与，并提交更正申请。",
            "outcome": "陈工签了说明，名单重新送审。小赵看着更新后的公示：“原来真的有人会把不属于自己的成果退回去。”签完字，陈工只问了一句：“那这个模块实际是谁做的？”",
            "apCost": 0,
            "stateDelta": {"D": 2, "risk": -1},
            "riskDelta": -1,
            "flags": ["m10_name_removed_by_self"],
            "competency": comp("D", 4, "m10_name_removed_by_self", "把自己没做过的署名正式撤下来"),
            "abilityTags": {"integrity": 2},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "保持沉默：不申请修改。公示结束后，这项经历会留在你的履历里。",
            "outcome": "名单继续公示。你多了一条漂亮记录，也多了一项以后要解释清楚的工作。",
            "apCost": 0,
            "stateDelta": {"D": -2, "risk": 2},
            "riskDelta": 2,
            "flags": ["m10_name_kept_by_silence", "m10_false_credit"],
            "competency": comp("D", 1, "m10_false_credit", "履历上留下一段没参与过的项目"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "请老周代为处理：私下把情况告诉老周，请他去找申报负责人。",
            "outcome": "老周把你叫进办公室：“名单我会处理。你不用在群里跟所有人争，但之后有人问起，别说成自己做的。”名单后来改了。",
            "apCost": 0,
            "stateDelta": {"D": 1, "N": 1},
            "riskDelta": 0,
            "flags": ["m10_name_delegated_correction"],
            "competency": comp("N", 4, "m10_name_delegated_correction", "把不实署名的更正交到老周手上走完"),
            "abilityTags": {"collaboration": 1, "integrity": 1},
            "reportUse": "evidence",
        },
    ],
    "timeBand": "morning",
    "phase": "mid",
    "reportUse": "evidence",
    "zoneCut": "A",
    "walk": True,
    "memoryNote": {
        "A": {"text": "那一行我申请撤下来了。", "tone": "gold"},
        "B": {"text": "第三行是我的名字，我没提。", "tone": "gray"},
        "C": {"text": "我让老周去走了更正流程。", "tone": "gold"},
    },
}

NODES["E40"] = {
    "id": "E40",
    "month": 10,
    "order": 220,
    "nodeType": "main_story",
    "required": True,
    "title": "许棠画了两条路线",
    "locationId": "D",
    "location": "树影书院 · 阅览室",
    "durationMinutes": 45,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("下旬的一个上午，你到阅览室时，许棠已经在里面，白板上画了两条路线。"),
        narration("一条是你现在用的办法，快，而且这半年没出过错。另一条多花两天，但可能不再需要人一直盯着。"),
        say("许棠", "这一步每次都要人看。我想把判断写进规则里，慢两天，后面就不用一直守着。"),
        say("王哥", "我以前也提过类似的改法。当时没做，理由也是“现有办法没出过错”。"),
        narration("许棠在草稿边上引用了你文档第七页的一段排查步骤；她是在那一步上继续改的。",
                  when={"flag": "m09_handoff_complete"}),
        narration("她停在你没写下来的两个判断上：“这两条好像一直靠人记。”",
                  when={"flag": "m09_handoff_partial"}),
        narration("她试着从现有资料里找答案，没找到。你得先把那段过程说清楚。",
                  when={"flag": "m09_handoff_deferred"}),
        narration("阅览室外还有人在等结果。出了问题，最后签处理单的人仍然是你。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "先用成熟方案：“这次先按旧方案交付。新规则等排期出来再试。”",
            "outcome": "交付很稳。许棠把新方案收回去，文件名改成“待定”，没有再争。",
            "apCost": 0,
            "stateDelta": {"S": 1, "N": -1},
            "riskDelta": 0,
            "flags": ["m10_handoff_legacy"],
            "competency": comp("S", 3, "m10_handoff_legacy", "按没出过错的旧方案先把交付稳住"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "做最小验证：“先挑一段低风险流程跑两天。把误报和人工处理时间记下来，再决定要不要换。”",
            "outcome": "小范围验证没替任何人直接赢下争论，但决定开始有证据。许棠交上来的记录里，有两行引用了你留下的文档。",
            "apCost": 0,
            "stateDelta": {"S": 1, "O": 1},
            "riskDelta": 0,
            "flags": ["m10_handoff_validated_trial"],
            "competency": comp("S", 4, "m10_handoff_validated_trial", "用两天的对照记录支撑要不要换路线"),
            "abilityTags": {"technical": 1},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "直接按新路线上线：“这次就按你的路线改，今天先上线。出问题我们一起处理。”",
            "outcome": "两周后出现一条告警。回滚单上有许棠的提交，也有你作为负责人的确认记录。",
            "apCost": 0,
            "stateDelta": {"O": 1, "risk": 2},
            "riskDelta": 2,
            "flags": ["m10_handoff_unreviewed_release", "m10_alert_due"],
            "competency": comp("O", 2, "m10_handoff_unreviewed_release", "没走审核就把新路线推上线"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
    ],
    "timeBand": "morning",
    "phase": "late",
    "reportUse": "evidence",
    "zoneCut": "D",
}

NODES["M10_CLOSE"] = {
    "id": "M10_CLOSE",
    "month": 10,
    "order": 230,
    "nodeType": "month_close",
    "required": True,
    "defaultText": "第 10 月：公示期满，新人把第一步跑完了。",
    "autoSave": True,
    "cards": [
        {"when": {"flag": "m10_name_removed_by_self"},
         "text": "公示名单上的那段经历被更正了。陈工问了一句：这块实际是谁做的？"},
        {"when": {"flag": "m10_name_kept_by_silence"},
         "text": "公示结束时，你的名字还在那一栏。"},
        {"when": {"flag": "m10_name_delegated_correction"},
         "text": "老周去走了更正流程。你没有在群里公开争论，也没有把那项工作说成自己的。"},
        {"when": {"flag": "m10_handoff_legacy"},
         "text": "交付按原计划完成。许棠把新路线留在了“待定”文档里。"},
        {"when": {"flag": "m10_handoff_validated_trial"},
         "text": "两天的对照记录留下来了，是否替换还要继续讨论。"},
        {"when": {"flag": "m10_handoff_unreviewed_release"},
         "text": "两周后的告警单上有提交记录和你的确认记录。"},
    ],
    "timeBand": "night",
    "phase": "late",
    "reportUse": "story_only",
}

# ---------------------------------------------------------------- 第十一个月
NODES["M11_OPEN"] = {
    "id": "M11_OPEN",
    "month": 11,
    "order": 200,
    "nodeType": "main_story",
    "required": True,
    "title": "名额只有一个",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "medium",
    "autoComplete": True,
    "beats": [
        narration("午休，王哥端着饭回来，坐在你旁边。他把筷子放下，先看了一眼手机上的排期。"),
        say("王哥", "十二月的答辩，组里只有一个提名名额。"),
        say("王哥", "你和孙哥，我这边只能报一个。"),
        narration("他停了一下，等你开口。"),
        say("王哥", "我会看最近几个月你做的事，也会看材料能不能讲清楚。"),
        say("王哥", "上旬末前把你的材料给我。数字和口径都写上。",
            emphasis=["上旬末前"]),
        narration("两周前那条告警单在本月初到达：新规则在边界输入上触发，回滚单保留了许棠的提交记录和你的确认记录。陈工要求补根因、测试范围和复查日期。",
                  when={"flag": "m10_alert_due"}),
        narration("这条告警作为实际工作事实进材料，不改变 18% 和 41% 的统计口径。",
                  when={"flag": "m10_alert_due"}),
    ],
    "choices": [],
    "timeBand": "afternoon",
    "phase": "early",
    "reportUse": "story_only",
    "todayCard": {
        "title": "第十一月 · 提名名额",
        "lines": [
            "组里只有一个十二月的提名名额。",
            "王哥要看你最近几个月做的事。",
            "材料上旬末前给他，数字和口径都写上。"
        ],
        "shots": ["place_card_tool_1.png"]
    },
}

NODES["M11_MATERIAL"] = {
    "id": "M11_MATERIAL",
    "month": 11,
    "order": 210,
    "nodeType": "main_story",
    "required": True,
    "title": "材料里的 18% 变成了 41%",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 30,
    "situation": "strong",
    "autoComplete": True,
    "beats": [
        narration("你写的是“试点内效果提升 18%”。"),
        narration("文档里现在写成“整体提升 41%”。"),
        narration("旁边多了一行小字：“含试点外推”。"),
        narration("版本记录显示，改动人是老周，时间是上周，夜里。"),
        narration("你打开口径说明。第六条写着：“外推系数由业务侧确认。”"),
        narration("你按材料所附公式重算了三遍，得出 41%。18% 是 40 人试点内的实测结果；41% 是纳入试点外人群后得到的外推估算。",
                  emphasis=["18% 是 40 人试点内的实测结果"]),
        narration("算式能复算，不等于分母、适用范围和外推系数已核实或获业务确认。材料把实测值与估算值并列写成“整体提升”，却没有把口径和确认状态说明白。"),
        narration("你没有马上回他。光标还停在 41% 后面。"),
    ],
    "choices": [],
    "timeBand": "afternoon",
    "phase": "early",
    "reportUse": "story_only",
}

NODES["M11_PHONE_XZ"] = {
    "id": "M11_PHONE_XZ",
    "month": 11,
    "order": 215,
    "nodeType": "phone_batch",
    "required": False,
    "batchId": "m11_batch_xiaozhao",
    "senderId": "xiao_zhao",
    "senderName": "小赵",
    "senderRole": "邻组",
    "messages": [
        {"id": "m11_xz", "text": "那个数我们一起算的。你写“我们”行不行？我不想一个人扛。"},
    ],
    "replyOptions": [],
    "timeBand": "afternoon",
    "phase": "early",
    "reportUse": "story_only",
    "deliveredDuring": "M11_MATERIAL",
}

NODES["E32"] = {
    "id": "E32",
    "month": 11,
    "order": 220,
    "nodeType": "main_story",
    "required": True,
    "title": "木栈道上，老周谈口径",
    "locationId": "E",
    "location": "心湖木栈道",
    "durationMinutes": 45,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("老周坐在木栈道边，手机放在膝盖上，没有在打电话。"),
        say("老周", "你那 18%，是试点里的四十个人。"),
        say("老周", "四十个人之外的结果也不是没用，只是没人给他们做过同一套验证。"),
        say("老周", "你要写 18%，这页可能没人往下看。"),
        say("老周", "我不是让你改数。你得想清楚，谁会看这份材料。"),
        narration("湖对岸有人在打电话，声音传不过来。老周看着那边，没催你。"),
    ],
    "choices": [
        {
            "id": "A",
            "text": "拆分试点与外推口径：主文写“试点内提升 18%”（已观测），41% 单列为含外推的估算，附分母、适用范围、计算式和确认状态。",
            "outcome": "材料退回来一次，要求解释为什么要拆开写。你把 18% 的试点范围、41% 的估算范围和外推步骤逐条讲清，并标明待核实项。王哥周五仍把你的名字报上去，但请你准备好回答口径问题。",
            "apCost": 0,
            "stateDelta": {"D": 2, "risk": -1},
            "riskDelta": -1,
            "flags": ["m11_metric_corrected_named", "m11_nomination_named"],
            "competency": comp("D", 4, "m11_metric_corrected_named", "把实测与外推拆开写并署上自己的名字"),
            "abilityTags": {"integrity": 2, "expression": 1},
            "reportUse": "evidence",
        },
        {
            "id": "B",
            "text": "走内网匿名反馈：不改当前材料，把“外推系数由业务侧确认”和版本记录提交到合规反馈入口。",
            "outcome": "入口受理，系统给了一条编号。材料不会因此自动改，是否加一行页脚说明要等处理结果。匿名机制和后续状态以内网实际反馈为准。",
            "apCost": 0,
            "stateDelta": {"D": 1},
            "riskDelta": 0,
            "flags": ["m11_metric_anonymous_report", "m11_anonymous_submitted"],
            "competency": comp("D", 3, "m11_metric_anonymous_report", "走内网匿名渠道反映口径问题"),
            "abilityTags": {"integrity": 1},
            "reportUse": "evidence",
        },
        {
            "id": "C",
            "text": "按现稿提交：不改 41%，不另交反馈，周五前把材料交给王哥。",
            "outcome": "王哥报了孙哥。散会后他把材料还给你：“我没报你，不是因为这个数。我不知道你准备怎么解释它。”",
            "apCost": 0,
            "stateDelta": {"D": -2, "risk": 2},
            "riskDelta": 2,
            "flags": ["m11_metric_submitted_unchecked", "m12_not_nominated"],
            "competency": comp("D", 1, "m11_metric_submitted_unchecked", "口径没说明就把外推值交上去"),
            "abilityTags": {},
            "reportUse": "evidence",
        },
    ],
    "timeBand": "afternoon",
    "phase": "mid",
    "reportUse": "evidence",
    "walk": True,
    "memoryNote": {
        "A": {"text": "我把试点和外推分开写了。", "tone": "gold"},
        "B": {"text": "我在内网留了一条反馈。", "tone": "gold"},
        "C": {"text": "材料按原样交了。", "tone": "gray"},
    },
}

NODES["M11_FREE"] = {
    "id": "M11_FREE",
    "month": 11,
    "order": 230,
    "nodeType": "activity",
    "required": False,
    "activityIds": [
        "m1_tool",
        "m1_rooftop",
        "m1_lakeside",
        "m3_waterway",
        "m7_lawn",
        "m9_library",
        "m11_reproduce",
        "m11_boardgame",
    ],
    "allowSkip": True,
    "skipFlag": "m11_activity_skipped",
    "endMonthLabel": "结束这个月",
    "timeBand": "afternoon",
    "phase": "late",
    "reportUse": "story_only",
    "entryMode": "on_site",
    "budget": {"ap": 3, "slots": 3},
}

NODES["E41"] = {
    "id": "E41",
    "month": 11,
    "order": 240,
    "nodeType": "main_story",
    "required": True,
    "title": "指标复盘会：谁来定义成功",
    "locationId": "A",
    "location": "A 区会议室",
    "durationMinutes": 45,
    "situation": "medium",
    "autoComplete": False,
    "beats": [
        narration("指标复盘会上，投影里的增长和转化都在往上走。"),
        say("小林", "增长、转化，这两个数都挺好看。"),
        say("陈工", "所以呢？哪些人还是没被帮到？"),
        narration("两人之间隔着一张空表。"),
        narration("会上每个人都说支持把表填上。"),
        narration("有人说“先把能看的数补齐”。你听见这句话时，想起 Demo 那次。",
                  when={"flag": "m05_e17_blame_network"}),
    ],
    "choices": [
        {
            "id": "A",
            "text": "继续只看增长、转化：维持现在的主指标，边缘投诉先放在附录。",
            "outcome": "报表很好读，投诉人群仍没有单独的复核口径。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m11_success_metric_keep_growth"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "加入申诉与人工复核：把申诉成功率和边缘案例的人工复核放进表里。",
            "outcome": "指标变慢了，表也变长了。陈工让大家先按新口径跑一个月再复盘。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m11_success_metric_appeal_review"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "按人群拆目标并公开取舍：分人群设目标，把每类人群的取舍写到指标说明里。",
            "outcome": "没有一个数字能概括所有人。小林把分组表留在共享盘，等下一轮数据补全。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m11_success_metric_segmented_targets"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "afternoon",
    "phase": "late",
    "reportUse": "story_only",
    "zoneCut": "A",
    "when": {"flag": "visit_11_m11_reproduce"},
}

NODES["M11_NOMINATION"] = {
    "id": "M11_NOMINATION",
    "month": 11,
    "order": 245,
    "nodeType": "main_story",
    "required": True,
    "title": "名单报上去那天",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 20,
    "situation": "strong",
    "autoComplete": True,
    "beats": [
        narration("散会后，王哥把材料还给你。",
                  when={"flag": "m12_not_nominated"}),
        say("王哥", "我报了孙哥。这个名额得有人解释材料里的数。你当时没告诉我你打算怎么解释。",
            when={"flag": "m12_not_nominated"}),
        narration("十二月那一栏写着：绩效反馈面谈。",
                  when={"flag": "m12_not_nominated"}),
        narration("周五，王哥把你的名字报了上去。",
                  when={"notFlag": "m12_not_nominated"}),
        narration("十二月那一栏写着：A 区大会议室，答辩。",
                  when={"notFlag": "m12_not_nominated"}),
    ],
    "choices": [],
    "timeBand": "afternoon",
    "phase": "late",
    "reportUse": "story_only",
}

NODES["M11_PHONE_CG"] = {
    "id": "M11_PHONE_CG",
    "month": 11,
    "order": 250,
    "nodeType": "phone_batch",
    "required": False,
    "batchId": "m11_batch_chengong",
    "senderId": "chen_gong",
    "senderName": "陈工",
    "senderRole": "邻组 Leader",
    "messages": [
        {"id": "m11_cg_1", "text": "十二月上旬，上午九点。十五分钟陈述，十分钟提问。材料上旬末前给我。"},
        {"id": "m11_cg_2", "text": "去年有人念了十四页，没人听完。"},
    ],
    "replyOptions": [],
    "timeBand": "night",
    "phase": "late",
    "reportUse": "story_only",
    "deliveredDuring": "M11_CLOSE",
}

NODES["M11_CLOSE"] = {
    "id": "M11_CLOSE",
    "month": 11,
    "order": 260,
    "nodeType": "month_close",
    "required": True,
    "defaultText": "第 11 月：材料交了，十二月的安排也定下来了。",
    "autoSave": True,
    "cards": [
        {"when": {"flag": "m11_metric_corrected_named"}, "text": "你把试点和外推分开写了。"},
        {"when": {"flag": "m11_metric_anonymous_report"}, "text": "你通过内网留了反馈。"},
        {"when": {"flag": "m11_metric_submitted_unchecked"}, "text": "材料按原样交了。"},
    ],
    "timeBand": "night",
    "phase": "late",
    "reportUse": "story_only",
}


def main() -> None:
    payload = json.loads(DATA.read_text(encoding="utf-8"))
    nodes: list[dict] = payload["nodes"]

    # 1) 全文件旗标改名（含第 12 月的引用）
    text = json.dumps(nodes, ensure_ascii=False)
    for old, new in RENAME.items():
        text = text.replace('"%s"' % old, '"%s"' % new)
    nodes = json.loads(text)

    def index_of(node_id: str) -> int:
        for i, node in enumerate(nodes):
            if str(node.get("id")) == node_id:
                return i
        return -1

    # 2) 用剧情册版内容整块替换
    replaced = []
    for node_id, fresh in NODES.items():
        i = index_of(node_id)
        if i >= 0:
            nodes[i] = fresh
            replaced.append(node_id)

    # 3) 新节点插到指定锚点后面
    inserted_after = {
        "E27": ["M09_CONTRIB"],
        "M09_FREE": ["M09_LIBRARY_SOCIAL"],
        "M11_MATERIAL": ["M11_PHONE_XZ"],
        "E41": ["M11_NOMINATION"],
    }
    added = []
    for anchor, new_ids in inserted_after.items():
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
    missing = sorted(i for i in NODES if i not in order and int(NODES[i]["month"]) in (9, 10, 11))
    if missing:
        manifest["nodeOrder"] = order + missing
        MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("替换 %d 个节点，新增 %s；nodeOrder 补 %s" % (len(replaced), added, missing))
    print("节点总数", len(nodes))


if __name__ == "__main__":
    main()
