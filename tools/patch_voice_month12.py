#!/usr/bin/env python3
"""第 12 月对白重写：答辩、结果、交接、六面墙。只改说法。

顺手修一处：M12_RESULT 最后那句「没晋升不等于淘汰」原来无条件显示，
晋升成功的人也会读到，改成只在 m12_not_passed 时出现。

    python tools/patch_voice_m12.py            # 只看差异
    python tools/patch_voice_m12.py --apply    # 写回 events.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/story/v12m/events.json"


def n(text: str, **extra) -> dict:
    beat = {"type": "narration", "text": text}
    beat.update(extra)
    return beat


def s(speaker: str, text: str, **extra) -> dict:
    beat = {"type": "say", "speaker": speaker, "text": text}
    beat.update(extra)
    return beat


M12_OPEN = [
    n("楼层已经空了，只有你这排灯还亮着。"),
    n("桌上有电脑、手册，还有一只待归档的纸箱，里面装着这一年的项目材料。"),
    n("明天九点，A 区大会议室。评委会问你，这一年你负责过什么。"),
    n("手册就放在桌面上。这一次，你得把它翻开。"),
    n("3.3 底下那行铅笔字比正文小：「等你要用的时候，补来不及了。」"),
    n("铅笔字底下压着一个纸角——是第七月那张反馈纸，你当时把它夹进了第三章。", when={"flag": "m07_review_note_manual"}),
]

M12_DOOR = [
    n("第二天上午，A 区大会议室门外。走廊里，门关着。王哥、小林、小赵、老周分散站着，每人跟你说一句。"),
    s("王哥", "别说自己从没犯过错。讲清楚哪一步出了问题，后来怎么补的。"),
    s("王哥", "我把你报上去了。该讲清楚的，今天你自己讲。"),
    s("小林", "技术别讲太满。他们真听懂了，会接着往下问。"),
    s("小赵", "我把你第一年的架构图扫描进去了。看着有点……勇敢。", abilityPeak=["technical"]),
    s("小赵", "合规那件我也放进去了。怎么处理的，让他们看记录。", when={"flag": "m08_e25_reported"}),
    s("老周", "十点前把材料放好。门开了就进去。"),
    n("门把手亮了一下。"),
]

M12_FEEDBACK = [
    n("门里有人在准备材料。陈工把你叫到小会议桌旁，桌上只有两把椅子。"),
    s("陈工", "这次名单没报你。材料还是过一遍，看看下一次窗口还缺什么。"),
    s("陈工", "你先挑一项最想问清楚的。"),
]

E50_slide = [
    n("投影第一张是你第二个月的技术选型记录，图上还是当时那两条路。"),
    n("中间是技术委员会负责人，左边跨部门评委，右边记录评委。王哥不坐评委席——他是提名主管。"),
    s("大领导", "你最想让我们记住哪一部分？"),
]

E50_ownership = [
    n("你讲到接口、评测和召回率。左边的评委抬手打断。"),
    s("跨部门评委", "这些细节先放一下。这个项目如果不做，会造成什么实际问题？"),
    n("他不是来确认你会不会写代码。他要知道，这件事值不值得交给一个更高一级的人。"),
    s("大领导", "这个项目里，哪一部分是你自己做的？"),
]

E50_recovery = [
    n("你答完，他把笔放下。"),
    s("大领导", "刚才那句，你再说一遍？"),
]

E50_metric_l1 = [
    n("你把上一条答完，屏幕已经翻到下一页。"),
    n("系统从你确实有的材料里挑出一项关键数据，把来源、样本、时间窗和归属一起投在屏幕上。"),
    s("大领导", "你材料里的这个数，降了多少？基数是什么？"),
]

E50_metric_l2 = [
    n("你报了一个区间，评委在那行下面画了道线。"),
    s("跨部门评委", "对比的是哪一段？中间还有别的改动吗？"),
]

E50_metric_l3 = [
    n("上一个数你没绕，直接说了不知道的那部分。"),
    s("大领导", "如果你不做这件事，它自己会降吗？"),
]

E50_nextlevel = [
    n("追问没有停，但语气松了一点。"),
    s("跨部门评委", "如果升到下一级，你打算承担什么？还是现在这些活，那为什么要升你？"),
]

E50_selfreview = [
    n("他合上材料，第一次抬头看你。"),
    s("记录评委", "你觉得自己还缺什么？"),
]

E50_picture = [
    n("话说到这儿，评审席那排人一起翻回第一页。"),
    n("前面答得再顺，最后还是要抽一项。"),
    s("大领导", "如果让你重做一次，哪张图会不一样？"),
    n("投影停在第二个月那张自研 / 开源白板上。"),
    n("履历上那段没参与过的项目又被翻出来一次。你当场说清了它是怎么上去的。", when={"flag": "m10_false_credit"}),
]

M12_RESULT = [
    n("王哥在工位边停下来。", when={"notFlag": "m12_not_passed"}),
    s("王哥", "过了。级别升一档，明天生效。", when={"notFlag": "m12_not_passed"}),
    n("级别那一栏按 L1–L7 更新，没有同时再显示别的口径。", when={"notFlag": "m12_not_passed"}),
    n("桌上有一张反馈纸，只写了需要补强的一项，和一条证据。", when={"flag": "m12_not_passed"}),
    s("王哥", "这次卡住你的不是技能，是产出。四件交付里，能拿给别人用的有两件。下一次提名，再看能不能补上。", when={"flag": "m12_not_passed"}),
    n("这次没晋升不等于淘汰：不扣钱，职级不变。", when={"flag": "m12_not_passed"}),
]

M12_PAPER = [
    n("反馈纸上写着那一项需要补强的，还有一条能核对的证据。"),
]

M12_CHAIR = [
    n("下旬。答辩那天的反馈纸还在桌上。"),
    n("你工位对面多了一把椅子。许棠坐在那里，屏幕上是第二个月那张架构图。"),
    s("许棠", "当初为什么选这条路线？"),
]

M12_REPLAY = [
    n("从工位一路走到心湖北岸，风把楼道里的空调味吹掉了。最后半天，墙前没有别人。"),
    n("六面墙，按这半年一次排下来：进入行业、真实需求与成本压力、事故与责任、重构与传承、边界与署名、提名与新局。"),
    n("挂上去的都是你当时真写下来的，没有补写，也没有替你先想好。"),
    n("右上角写着「跳过」。跳过不扣任何东西。"),
]

M12_FAREWELL = [
    n("回到楼下，四个人在楼层门口等你。"),
    s("王哥", "以后遇到卡点，还可以来找我。"),
    s("小林", "下次排需求，我们再一起对。"),
    s("小赵", "你上次替我补了贡献记录，我记着。", when={"flag": "m09_credit_helped"}),
    s("小赵", "等我把这块接稳，请你吃饭。", when={"notFlag": "m09_credit_helped"}),
    s("老周", "这条路你走得比我当年顺一点。"),
]

BEATS = {
    "M12_OPEN": M12_OPEN,
    "M12_DOOR": M12_DOOR,
    "M12_FEEDBACK": M12_FEEDBACK,
    "E50_slide": E50_slide,
    "E50_ownership": E50_ownership,
    "E50_recovery": E50_recovery,
    "E50_metric_l1": E50_metric_l1,
    "E50_metric_l2": E50_metric_l2,
    "E50_metric_l3": E50_metric_l3,
    "E50_nextlevel": E50_nextlevel,
    "E50_selfreview": E50_selfreview,
    "E50_picture": E50_picture,
    "M12_RESULT": M12_RESULT,
    "M12_PAPER": M12_PAPER,
    "M12_CHAIR": M12_CHAIR,
    "M12_REPLAY": M12_REPLAY,
    "M12_FAREWELL": M12_FAREWELL,
}

CHOICES = {
    "M12_FEEDBACK": {
        "A": (None, "陈工翻开评审清单，指着一项：“这里只有结论，没有过程。下一次要补的是过程。”", None),
        "B": (None, "陈工说：“可以。补好以后先给王哥看，别等到截止前。”", None),
        "C": (None, "陈工把清单合上：“有问题再来找我。”", None),
    },
    "E50_slide": {
        "A": (None, "评委按时间线追问下去。材料里没写的地方，他们没替你补成成功。", None),
        "B": (None, "大领导接着问分母、时间范围，还有团队各自做了什么。", None),
        "C": (None, "评委追问你本人做了哪一段。", None),
    },
    "E50_ownership": {
        "A": (None, "评委点头：“清楚。你负责的那部分，我们就按这部分问。”", None),
        "B": (None, "记录评委记下一行，抬头说：“记录不够就写记录不够，这个答案我们收下。”", None),
        "C": (None, "右边评委抬头：“名单上还有两个人。上周最后改这个模块的是谁？”", None),
    },
    "E50_recovery": {
        "A": (None, "大领导：“这句比刚才那句有用。”", None),
        "B": (None, "会议室安静了两秒。记录评委把笔放下了。", None),
        "C": (None, "大领导：“那你今天讲的这一页，跟你申请的级别有什么关系？”", None),
    },
    "E50_metric_l1": {
        "A": (None, "评委把数和来源一起记下。", None),
        "B": (None, "记录评委在备注里写了两个字：未核算。", None),
        "C": (None, "跨部门评委：“大概是哪一段时间？你有底表吗？”", None),
    },
    "E50_metric_l2": {
        "A": (None, "评委翻到对应的版本记录。", None),
        "B": (None, "记录评委写下：缺少对照期间。", None),
        "C": (None, "跨部门评委：“我听懂趋势了，没听懂你比的是哪几周。”", None),
    },
    "E50_metric_l3": {
        "A": (None, "大领导：“有这条记录，下次把对照补上。”", None),
        "B": (None, "大领导：“好，这一栏就按你实际测过的范围记。”", None),
        "C": (None, "大领导追问还有什么同期变化；你拿不出材料，他让记录写成「因果未证实」。", None),
    },
    "E50_nextlevel": {
        "A": (None, "评委点头，要求把目标写进下一年度的计划。", None),
        "B": (None, "大领导：“这是你现在就该做的。再说一项更大的责任。”", None),
        "C": (None, "记录评委抬头：“那你希望下一年先试哪种责任？”", None),
    },
    "E50_selfreview": {
        "A": (None, "记录评委慢慢写下一行。", None),
        "B": (None, "大领导：“有改进动作，就把时间和结果也记下来。”", None),
        "C": (None, "记录评委：“好，等材料出来我们再对一次。”", None),
    },
    "M12_PAPER": {
        "A": ("折好，放在键盘旁边", "纸角压住一张待归档的工单。", None),
        "B": ("夹进手册第三章", "纸页露出一角，和第七个月那张纸叠在一起。", None),
    },
    "M12_CHAIR": {
        "A": (None, "你讲到一半，自己也忘了当时为什么这么选，翻出第八个月的技术债清单才接上。许棠记了几页，也指出其中一条你当年想错了。", None),
        "B": (None, "第三天她没再来问。过了一阵，她把文档里缺的两步补进了交接页。", None),
        "C": (None, "许棠照着做了两次。第二次走偏的正是你没讲的那一步，她回来找你。", None),
    },
}

MESSAGES = {
    "M12_PHONE_LZ": {"m12_zhou_1": "答辩那十分钟，你没绕开问题。材料留一份给组里，明年新人要用。"},
}
CARDS = {
    "M12_CLOSE": {
        "m11_metric_corrected_named": "年度报告里，18% 和 41% 分开标着口径。",
        "m11_metric_submitted_unchecked": "年度报告用的还是那份没拆开写的材料。",
        "m09_handoff_complete": "交接文档还在被人用，许棠在上面加了东西。",
        "m09_handoff_deferred": "目录第一行今年没填上；明年新人来问，得由你当面讲。",
        "m12_not_passed": "这一次没晋升。反馈纸只写了需要补的那一项。",
    }
}


def apply(nodes: list[dict]) -> list[str]:
    by_id = {str(node.get("id")): node for node in nodes}
    changes: list[str] = []

    for node_id, beats in BEATS.items():
        node = by_id[node_id]
        changes.append(f"{node_id}: beats {len(node.get('beats', []))} -> {len(beats)}")
        node["beats"] = beats

    for node_id, table in CHOICES.items():
        node = by_id[node_id]
        for choice in node.get("choices", []):
            cid = str(choice.get("id"))
            if cid not in table:
                continue
            text, outcome, emphasis = table[cid]
            if text:
                choice["text"] = text
            choice["outcome"] = outcome
            if emphasis:
                choice["emphasis"] = emphasis
            elif "emphasis" in choice:
                del choice["emphasis"]
        changes.append(f"{node_id}: {len(table)} 个选项")

    for node_id, table in MESSAGES.items():
        node = by_id[node_id]
        for message in node.get("messages", []):
            mid = str(message.get("id", ""))
            if mid in table:
                message["text"] = table[mid]
        changes.append(f"{node_id}: 消息")

    for node_id, table in CARDS.items():
        node = by_id[node_id]
        for card in node.get("cards", []):
            flag = str((card.get("when") or {}).get("flag", ""))
            if flag in table:
                card["text"] = table[flag]
        changes.append(f"{node_id}: 月末卡 {len(table)} 条")

    return changes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    data = json.loads(DATA.read_text(encoding="utf-8"))
    for line in apply(data["nodes"]):
        print(line)

    if not args.apply:
        print("\n（预演，未写回。加 --apply 写入）")
        return 0

    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"\n已写回 {DATA}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())