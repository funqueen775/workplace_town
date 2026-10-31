#!/usr/bin/env python3
"""第 11 月对白重写：提名名额、18% 与 41% 的口径、指标复盘。只改说法。

    python tools/patch_voice_m11.py            # 只看差异
    python tools/patch_voice_m11.py --apply    # 写回 events.json
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


M11_OPEN = [
    n("午休，王哥端着饭回来，坐在你旁边。他把筷子放下，先看了一眼手机上的排期。"),
    s("王哥", "十二月的答辩，组里只有一个提名名额。"),
    s("王哥", "你和孙哥，我这边只能报一个。"),
    n("他停了一下，等你开口。"),
    s("王哥", "我会看最近几个月你做的事，也看材料能不能讲清楚。"),
    s("王哥", "上旬末前把材料给我。数字和口径都写上。", emphasis=["上旬末前"], goalLine=True),
    n("两周前那条告警单在本月初到了：新规则在边界输入上触发，回滚单上留着许棠的提交记录和你的确认记录。陈工要求补根因、测试范围和复查日期。", when={"flag": "m10_alert_due"}),
    n("这条告警作为实际发生过的事进材料，不改 18% 和 41% 的统计口径。", when={"flag": "m10_alert_due"}),
]

M11_MATERIAL = [
    n("你写的是「试点内效果提升 18%」。那份口径说明，是从你交接文档里那一段扩出来的。"),
    n("文档里现在写着「整体提升 41%」。"),
    n("旁边多了一行小字：「含试点外推」。"),
    n("版本记录显示，改动人是老周，时间是上周，夜里。"),
    n("你打开口径说明。第六条写着：「外推系数由业务侧确认。」"),
    n("你按材料所附公式重算了三遍，得出 41%。18% 是 40 人试点内的实测结果；41% 是纳入试点外人群后得到的外推估算。", emphasis=["18% 是 40 人试点内的实测结果"]),
    n("算式能复算，不等于分母、适用范围和外推系数已经核实、已经获业务确认。材料把实测值和估算值并列写成「整体提升」，口径和确认状态一句没写。"),
    n("你没有马上回他。光标还停在 41% 后面。"),
    n("上个月在书院长桌上写的那份记录还留着。翻回去看，试点范围当时是怎么圈的，上面写清楚了。", when={"flag": "m09_longtable"}),
    n("你先不改数字，给老周发了条消息，约在心湖木栈道当面核对 18% 的试点范围和 41% 的外推口径，把原始表和口径说明都带上。"),
]

E32 = [
    n("老周昨天发消息约的午后，心湖木栈道，谈材料里那两个数。你带着原始表和口径说明过去，他已经坐在那儿了，手机放在膝盖上。"),
    s("老周", "你那 18%，是试点里的四十个人。"),
    s("老周", "四十个人之外的结果也不是没用，只是没人给他们做过同一套验证。"),
    s("老周", "你要写 18%，这页可能没人往下看。"),
    s("老周", "我不是让你改数。你得想清楚，谁会看这份材料。"),
    n("湖对岸有人在打电话，声音传不过来。老周看着那边，没催你。"),
]

E41 = [
    n("下旬。栈道那回逐行核对的原始表还在桌上，18% 的圈定范围和 41% 的外推口径，老周都记在本子里带走了。"),
    n("下午，指标复盘会在 A 区会议室。你把书院复现时发现的缺失条件带过去，投影里的增长和转化都在往上走。"),
    s("小林", "增长、转化，这两个数都挺好看。"),
    s("陈工", "所以呢？哪些人还是没被帮到？"),
    n("两个人中间隔着一张空表。"),
    n("会上每个人都说支持把表填上。"),
    n("有人说「先把能看的数补齐」。你听见这句话，想起 Demo 那次。", when={"flag": "m05_e17_blame_network"}),
]

M11_NOMINATION = [
    n("回到工位。散会后，王哥把材料还给你。", when={"flag": "m12_not_nominated"}),
    s("王哥", "我报了孙哥。这个名额得有人解释材料里的数。你当时没告诉我，你打算怎么解释。", when={"flag": "m12_not_nominated"}),
    n("十二月那一栏写着：绩效反馈面谈。", when={"flag": "m12_not_nominated"}),
    n("王哥把你的名字报了上去。", when={"notFlag": "m12_not_nominated"}),
    n("十二月那一栏写着：A 区大会议室，答辩。", when={"notFlag": "m12_not_nominated"}),
]

BEATS = {
    "M11_OPEN": M11_OPEN,
    "M11_MATERIAL": M11_MATERIAL,
    "E32": E32,
    "E41": E41,
    "M11_NOMINATION": M11_NOMINATION,
}

CHOICES = {
    "E32": {
        "A": (None, "材料退回来一次，要求解释为什么要拆开写。你把 18% 的试点范围、41% 的估算范围和外推步骤逐条讲清，并标明待核实项。周五王哥还是把你的名字报了上去，只提醒你想好怎么答口径。", None),
        "B": (None, "入口受理了，系统给了一个编号。材料不会因此自动改；要不要加一行页脚说明，得等处理结果。", None),
        "C": (None, "王哥报了孙哥。散会后他把材料还给你：“我没报你，不是因为这个数。我不知道你打算怎么解释它。”", None),
    },
    "E41": {
        "A": (None, "报表很好读，投诉人群仍然没有单独的复核口径。", None),
        "B": (None, "指标变慢了，表也变长了。陈工让大家先按新口径跑一个月，再复盘。", None),
        "C": (None, "没有一个数字能概括所有人。小林把分组表留在共享盘，等下一轮数据补全。", None),
    },
}

MESSAGES = {
    "M11_PHONE_XZ": {"m11_xz": "那个数我们一起算的。你写「我们」行不行？我不想一个人扛。"},
    "M11_PHONE_CG": {"m11_cg_2": "去年有人念了十四页，没人听完。"},
}
CARDS = {
    "M11_CLOSE": {
        "m11_metric_corrected_named": "你把试点和外推分开写了。",
        "m11_metric_anonymous_report": "你通过内网留了反馈。",
        "m11_metric_submitted_unchecked": "材料按原样交了。",
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