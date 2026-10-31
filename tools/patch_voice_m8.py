#!/usr/bin/env python3
"""第 8 月对白重写：白板室选路线、滥用事故上报。只改说法。

    python tools/patch_voice_m8.py            # 只看差异
    python tools/patch_voice_m8.py --apply    # 写回 events.json
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


M08_OPEN = [
    n("白板室在 A 区最里头，平时锁着，开会才开门。"),
    n("你推门进去的时候，白板上已经画了两列：三个月，半年。"),
    n("王哥和老周都站在前面，没人回头。"),
    s("老周", "来了？先找地方坐。"),
    n("你手里拿着那份打印出来的接口清单。清单是上个月复盘表上的待办，你一条一条抄下来的。"),
    n("上个月你多赶出来的那段进度，白板上已经有人接着往下写了。", when={"flag": "extra_push"}),
    n("昨天下班前，王哥把一张便签贴在你显示器边上：上午白板室，带上第五月那本接口账。", goalLine=True),
]

E23 = [
    n("桌上摊着接口清单，还有这半年没收口的事项。白板上有些行，能在你以前做过的选择里找到来处。"),
    n("回显区只贴你确实做过的那几行。"),
    s("王哥", "大重构估三个月。这三个月新需求得少接，先把旧接口理顺。"),
    s("老周", "小修能先撑半年。但半年是计划，不是保证。"),
    s("王哥", "这条链上你做得最多。先说你倾向哪条，排期我和陈工来签。", emphasis=["先说你倾向"]),
    n("王哥没有替你选。他把笔递过来。"),
]

M08_BRIDGE = [
    n("回到工位。第二天，你按清单回查旧接口，在一串调用记录里发现一个不该存在的入口。", when={"flag": "m08_e23_refactor"}),
    n("回到工位。第八天，安全组把一条线索转给你。记录显示，这种用法已经持续了两周。", when={"flag": "m08_e23_patch"}),
    n("回到工位。老周发来一张供应商演示页截图，标题写着「我们的助手」。他问：“这段对外演示，谁批过？”", when={"flag": "m08_e23_vendor"}),
    n("下班前，安全组回了一行：明天上午十点，A 区合规复盘室，把你查到的东西带过去。"),
]

E25 = [
    n("合规复盘室在 A 区那一层，平时借给安全组用。你把打印出来的材料摊在桌上。"),
    n("截图里是一段按步骤写的诈骗话术，语气跟普通客服回复差不多。"),
    s("产品同事", "客户说机器人答应免单。需求里只写了安抚，没有人批过这个额度。"),
    s("陈工", "安全组接到举报了。有人在论坛上教别人用这套助手写话术、绕过滤规则。"),
    s("老周", "截图和调用记录先留好。接下来是报上去，还是先在组里处理？"),
    n("你看到的是同一个助手。上一次它在客户面前给了错误承诺；这一次，截图已经不在客户现场。"),
]

BEATS = {
    "M08_OPEN": M08_OPEN,
    "E23": E23,
    "M08_BRIDGE": M08_BRIDGE,
    "E25": E25,
}

CHOICES = {
    "E23": {
        "A": (None, "老周在白板上签了排期：“三个月后，我们看事故曲线有没有下来。”这周还得挪时间清接口，身体负担 +1。", None),
        "B": (None, "版本很快发出去了。白板上的债没少，只是换了颜色。", None),
        "C": (None, "进度表上多了一个负责人。王哥把接口清单收回去：“后面要改规则，先确认谁拿着源文件。”", None),
    },
    "E25": {
        "A": (None, "安全工单生成了事故编号，合规流程启动。陈工把处理人和复查时间写进工单，你看见了自己的名字。", ["合规流程启动"]),
        "B": (None, "过滤规则当天上线。第二天，类似的内容换了个写法，又出现了。", None),
        "C": (None, "截图被放回受限文件夹。举报工单还挂着，没人能说问题已经停了。", None),
    },
}

MESSAGES = {
    "M08_PHONE": {"m08_echo": "今天那件事，不是你一个人弄出来的，但你手上也有一段。回去看看墙上贴的那些记录。"},
}
CARDS = {
    "M08_CLOSE": {
        "m08_e23_refactor": "你给旧接口选了大重构那三个月。",
        "m08_e23_patch": "你选了先撑半年的小修。",
        "m08_e23_vendor": "你把一段接口维护外包了出去。",
        "m08_e25_reported": "这次滥用，你当天就报了上去。",
        "m08_e25_observe": "这次滥用你先观察，没报。",
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