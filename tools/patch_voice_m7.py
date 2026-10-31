#!/usr/bin/env python3
"""第 7 月对白重写：转正结果、事故复盘、交接。{红线条文} 这类占位符原样保留。

    python tools/patch_voice_m7.py            # 只看差异
    python tools/patch_voice_m7.py --apply    # 写回 events.json
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


M07_RESULT = [
    n("上个月答辩的评定结果，今天登记进系统。王哥在工位边把它念给你听。"),
    n("门禁权限页多了一行字：「转正状态：已确认」。职级那一栏没变。", when={"flag": "probation_confirmed"}),
    s("王哥", "过了。HR 上午通知的。", when={"flag": "probation_confirmed"}),
    s("王哥", "陈工让我转一句：转正不代表什么都会了。你手上那套东西，组里现在真只有你最熟，找时间把接手文档补齐。", emphasis=["找时间把接手文档补齐"], when={"flag": "probation_confirmed"}),
    n("系统状态更新成「解除劳动合同」。下面附三行：违反的是「{红线条文}」；记录落在{红线那月}；经办人 HR，日期就是今天。", when={"flag": "probation_terminated"}),
    s("王哥", "这次跟分数没关系。那条线入职那天当众讲过，纸上是哪一条、哪个月、哪件事，都写着。", when={"flag": "probation_terminated"}),
    n("系统状态更新成「未转正」。HR 把一份交接清单放在桌上，附一句书面理由：岗位标准里差的是「{差的那一维}」，依据是记录里那几条，不是谁的印象。", when={"flag": "probation_not_confirmed"}),
    s("王哥", "先把你手上的模块交清楚。哪些做完了、哪些还没确认、下一步谁接，都写在这张表里。", when={"flag": "probation_not_confirmed"}),
    s("陈工", "昨天客户 Demo 出了一条越过需求的回复，线上已经回滚。周五下午去 A 区会议室复盘，带上规则提交、审核和发布记录，按时间线把你负责的那部分讲清楚。", when={"flag": "probation_confirmed"}),
]

M07_PAPER = [
    n("王哥把纸放在键盘旁边。上面没有分数，只列了四项，每项一两句话。"),
    n("这张纸的抬头不一样：解除通知三行——条文、记录、经办人。", when={"flag": "probation_terminated"}),
    s("王哥", "先看要补的那一项。别拿它当整个人的结论。"),
    n("四项按技能判断、独立交付、协作与交接、署名与证据给，每项只写一条反馈，没有数字。"),
    s("王哥", "纸你自己留着。"),
    s("王哥", "交接清单我放你桌上了。哪一项说不清，去问陈工，别自己猜。"),
    s("陈工", "（路过）清单逐项对完再走。做完的、没确认的、谁接手，都写在这张表上。"),
]

E19 = [
    n("你按通知来到 A 区会议室。长桌上已经投出从需求提交到客户 Demo 回滚的时间线；陈工坐在最里面，王哥在你旁边，老周靠着窗。", goalLine=True),
    n("产品侧只来了一个人，大家都叫他小许。"),
    s("小许", "客户说机器人答应免单。需求里写的是安抚，没有人批过免单。"),
    s("陈工", "日志里有规则提交和审核记录。按时间线看。"),
    s("老周", "需求、规则、审核、发布，先把这几步对上。"),
    n("投影停在规则上线那一行。提交记录和审核记录都在，右侧还有客户看到的回复。"),
    n("你先看时间线，再看自己的名字落在哪一格。", when={"notFlag": "handbook_page_3.3"}),
    n("你想起手册里那句话：临近评估再补记录，容易漏。", when={"flag": "handbook_page_3.3"}),
    s("王哥", "先说记录里能确认的。判断等会儿再下。"),
    s("小许", "这条规则最近一次改动，记录在你的维护分支里。你怎么看？"),
    s("陈工", "这条规则你一直在维护。按提交、审核、上线的顺序讲。"),
]

M07_HANDOVER = [
    n("中旬。复核那场会开完没几天，交接排上了日程。"),
    n("回到工位，接手的人已经在桌边等你。"),
    n("你和接手的同事逐项对过文档、待办和访问权限。"),
    n("交接完成，转正主线在这里结束；这一年的记录只收已经发生的事。"),
    n("依据和条文都写在纸上。这段工作关系到这里为止。", when={"flag": "probation_terminated"}),
    n("差在哪一项写在纸上。这个月的活交完，后面的窗口再看。", when={"flag": "probation_not_confirmed"}),
]

M07_CLOSURE = [
    n("下午，HR 把那份材料推过来。不是评定表，也没有分数。"),
    n("左边一栏是这一年做过、并且留下记录的事；右边一栏是差的那一项；最下面一行是下一步。"),
    n("条文那一行写着：{红线条文}。记录落在{红线那月}。", when={"flag": "probation_terminated"}),
    n("差的那一栏写着「{差的那一维}」——依据是记录里的那几条。", when={"flag": "probation_not_confirmed"}),
    s("王哥", "这份你带走。下一次窗口要补什么，照着最下面那一行来。"),
    n("第十二月末那份完整年度报告，只对走完十二个月的人开放；这一份收在这里，只写已经发生的事。"),
]

M07_SPORTS_INVITE = [
    n("小赵从工位那边探过头，手上拎着一个布袋。"),
    s("小赵", "周末打球，就我们几个。老周也去。走走走，我带你认一次路。"),
    n("他往心湖对面指了指。那片谷口周末会摆出一张记分牌。", hook="unlock_sports"),
]

BEATS = {
    "M07_RESULT": M07_RESULT,
    "M07_PAPER": M07_PAPER,
    "E19": E19,
    "M07_HANDOVER": M07_HANDOVER,
    "M07_CLOSURE": M07_CLOSURE,
    "M07_SPORTS_INVITE": M07_SPORTS_INVITE,
}

CHOICES = {
    "M07_PAPER": {
        "A": ("折好，放在键盘旁边", "纸角压住了一张还没归档的工单。", None),
        "B": ("夹进手册第三章", "纸比手册薄，合上以后还是能看出一点折痕。", None),
    },
    "E19": {
        "A": (None, "陈工把投影停在规则提交那一处：“先按记录修。产品那边的需求版本也一起附上。”会后，产品同事没再跟你闲聊。", ["先按记录修"]),
        "B": (None, "老周点头：“先把门堵上。谁哪一步漏了，明天接着看。”", None),
        "C": (None, "会议很快转成排查模型输出。王哥合上日志，没有再补充。", None),
    },
}

PROMPTS = {"E19": "这条规则，你怎么接？"}
MESSAGES = {
    "M07_PHONE_XZ": {"m07_xz_1": "周末打球不？就我们几个。就在松风那边，谷里那块记分牌。"},
    "M07_PHONE_LZ": {
        "m07_lz_log": "会上你把日志摊开了。后面有人一直说「模型不可控」，你没再接。我本来想补一句，最后没说。",
        "m07_lz_own": "你把审核那段说成自己的了。该你负责的部分，你没往外推。",
        "m07_lz_blamed": "产品那边问了你后续怎么联系。回滚之后，他们还得跟你对接。",
    },
}
CARDS = {
    "M07_CLOSE": {
        "m07_e19_log_evidence": "你把提交和审核的时间线摊开了；产品那边暂时有点僵。",
        "m07_e19_own_review_gap": "你先把自己审核那一环讲清了，后面的事接着查。",
        "m07_e19_blamed_model": "你先按模型异常解释了。会散了，事情没散。",
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

    for node_id, prompt in PROMPTS.items():
        by_id[node_id]["prompt"] = prompt
        changes.append(f"{node_id}: prompt")

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