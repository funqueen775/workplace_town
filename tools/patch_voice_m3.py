#!/usr/bin/env python3
"""第 3 月对白重写：按《对白与文风》§2 的六条改说法，不动事实与玩法。

    python tools/patch_voice_m3.py            # 只看差异
    python tools/patch_voice_m3.py --apply    # 写回 events.json
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


M03_OPEN = [
    n("早上八点过，小林已经站在你工位边，手里捏着一份合同，只打印了一半。"),
    s("小林", "十点，C 区水巷，客户展厅。禾丰要在合同里加一句「保证百分之百不胡说」。"),
    s("小林", "陈工今天盯昨天那次回滚，王哥上午有评审，谁都来不了。这条怎么写，得有个懂规则的人当场答。"),
    n("这套拣货问答的兜底规则，是你上个月在退路表上写下来的。草稿里「出了问题谁负责」那一栏，还空着。"),
    s("小林", "跟我走。答不上的就说说不清楚，别替我点头。"),
]

E10 = [
    n("展厅里，客户坐右边，小林坐左边。王哥没来。"),
    s("小林", "这位管规则，兜底那几行是他写的。技术上能不能保证，你问他。"),
    s("方经理", "禾丰仓配，方经理。合同我带了。"),
    s("方经理", "合同里加一句：保证百分之百不胡说。", emphasis=["保证百分之百不胡说"]),
    s("方经理", "别跟我讲概率。我只问，出了问题谁负责？"),
    n("手机在桌上震了一下，屏幕边上是王哥的头像。"),
    {"type": "phone_cinematic", "speaker": "王哥", "text": "概率可以往下压，别把它写成誓言。"},
    n("小林把笔搁到合同旁边，没替你答。"),
    s("小林", "你现在说做不到，这单可能就没了。你现在说做得到，以后可能是我们没了。", emphasis=["以后可能是我们没了"]),
    s("方经理", "所以，能不能写？"),
]

M03_WRAP = [
    n("会开完了。你答的那几句，方经理记在本子上；小林在旁边一个字没补。"),
    n("出门的时候，王哥在走廊口等着。", emphasis=["王哥在走廊口等着"]),
    s("王哥", "会后把三样东西写出来发我：哪些还没定，谁负责，什么时候再确认。"),
    s("王哥", "周四之前发。这张清单不是替你补会议结论，是让后面的人知道下一步该找谁。"),
    s("小林", "以后见客户基本都在这儿。旁边那家咖啡还行。", hook="unlock_waterway"),
    n("散会之后，下午两小时归你自己安排。傍晚回工位，王哥要的那三样还得补一遍。", emphasis=["下午两小时归你自己安排"]),
]

M03_COFFEE = [
    n("散会后你没直接回工位。水巷外摆那排椅子空着，你挑了靠里的一张坐下——王哥要的那三样，一条还没补。抬头时，小林端着咖啡站在门口，目光在几排椅子之间扫。"),
]

M03_BRIDGE = [
    n("忙到收工，天已经黑了。你回到工位坐下——不管下午那张清单交成什么样，「这类问题以前出过几次」都还没有来源可核。"),
    n("你在组里的《常见问题》文档里搜了十分钟。最后一次更新停在一月。"),
    n("你在群里问：「这个数谁有？」半小时过去，没人回。"),
    n("你把「历史问题次数」标成待核，打算自己去把来源补上。"),
]

M03_NOTICE = [
    n("两周过去。那三行跟着版本上了线，跑满两个星期。"),
    n("合同签了。附页那三行兜底是你写的，方经理每周让人来问一次：有没有照做。", when={"flag": "m03_e10_truth_with_fallback"}),
    n("合同用的是「尽商业上合理努力」那句。两个星期里，没人来问过这句话该怎么算。", when={"flag": "m03_e10_soft_clause"}),
    n("合同签了。小林把副本传上共享盘，从头到尾没跟你提那天会场上的事。", when={"flag": "m03_e10_overpromise"}),
    {"type": "card", "text": "【便签】两周后的周会，散了你留两分钟。——王哥"},
    n("便签压在键盘边上，字是王哥的。"),
]

M03_MID = [
    n("周会散了，人陆续往外走。王哥合上笔记本，抬了下下巴，让你留一下。上旬散会那天他要的三样东西，摊在桌上。"),
    n("那三行兜底跟着版本上线两个星期，头一件回来找你的，就在这两分钟里。"),
    s("王哥", "你那份清单我拿去开了周会。以后散会当天就发，别等到周四。", when={"flag": "m03_e10_handoff_complete"}),
    s("王哥", "清单我看到了。下次确认时间那一栏空着——不给组里看，它就只是我们俩的备忘。", when={"flag": "m03_e10_handoff_partial"}),
    s("王哥", "周四过了，没人来问那份清单。下次散会当天发我，哪怕只写两行。", when={"flag": "m03_e10_handoff_blank"}),
    n("回到工位，杯子里的咖啡已经凉了。"),
    s("小赵", "还是我那条线。三个星期里又撞上一回，还是没人知道以前撞过几次。上旬你在群里问的那个数，到现在也没人回吧？"),
    n("他把自己的杯子搁在你桌角：截图他还没翻到，翻到了发你。"),
]

M03_LATE = [
    n("这几天，一有空就补那个数的来源。再抬头，窗外已经黑了——下旬了。截图没来，群里那条问话还停在最后一行。"),
    n("《常见问题》你翻了两遍，最后一条更新还是一月。"),
    n("待核那一格还空着。月末之前，它得有个来源。"),
]

E12 = [
    n("月末最后一夜。工位只剩你，那份《常见问题》又打开了：结论还在，怎么得出这个结论的过程不在。手机亮了一下——中旬小赵说的那张截图，他发过来了。"),
    {"type": "phone_cinematic", "speaker": "小赵", "text": "找到了。规则写在半年前一张群聊截图里，发消息的人已经离职了。"},
    n("小赵那条线三个星期里又撞上一回。没人记得以前撞过几次——它不是被修好了，是从来没人记着它。手机又亮了一下。", emphasis=["从来没人记着它"]),
    {"type": "phone_cinematic", "speaker": "小赵", "text": "我们是不是该把这些东西从大家脑子里捞出来？"},
]

BEATS = {
    "M03_OPEN": M03_OPEN,
    "E10": E10,
    "M03_WRAP": M03_WRAP,
    "M03_COFFEE": M03_COFFEE,
    "M03_BRIDGE": M03_BRIDGE,
    "M03_NOTICE": M03_NOTICE,
    "M03_MID": M03_MID,
    "M03_LATE": M03_LATE,
    "E12": E12,
}

CHOICES = {
    "E10": {
        "A": (
            "说实话：边界在哪，兜底怎么给",
            "你说：出错率压到千分之三以下；真出事，二十四小时内人工复核、逐条改口，当月不算完成。方经理沉默了一会儿，说：“那把兜底写具体。别再给我讲概念。”",
            ["那把兜底写具体"],
        ),
        "B": (
            "签「尽商业上合理努力」",
            "小林把「保证」改成「尽商业上合理努力」。签完，双方都知道这句话有多软。",
            ["双方都知道这句话有多软"],
        ),
        "C": (
            None,
            "方经理终于点了头。小林在桌下踢了你一下，你没看懂她是在庆祝还是提醒。她把这一句单独抄进合同的风险栏——超出授权的承诺，从今天起记在案上。",
            ["你没看懂她是在庆祝还是提醒"],
        ),
    },
    "M03_WRAP": {
        "A": (
            None,
            "三项你都写全了，历史问题次数那一格标成待核。发到组内记录那一下，这份清单就不只是你一个人的事了。",
            None,
        ),
        "B": (
            None,
            "王哥回了句“收到”。清单只有他一个人看得到，下次什么时候确认，没人知道。",
            None,
        ),
        "C": (
            None,
            "清单留在空白的文档里。第二天没人问，第三天也没有。",
            None,
        ),
    },
    "M03_COFFEE": {
        "A": (None, "她端着杯子坐过来，先说了句「这儿风大」。椅子有点晃，咖啡一般，话比咖啡多。", None),
        "B": (None, "你朝她点了下头。她抬手回了一下，端着咖啡去了靠街那张桌子。", None),
        "C": (None, "你低头看手机。再抬头，门口那个位置空了，咖啡杯摆在一边。", None),
    },
    "E12": {
        "A": (None, "小赵新建了目录，第一篇文档的标题是「别再从群聊考古」。", ["别再从群聊考古"]),
        "B": (None, "你的模块安静下来，别人的模块还在继续猜谜。", ["别人的模块还在继续猜谜"]),
        "C": (None, "问题被一行加粗的字按回了水下。", ["按回了水下"]),
    },
}

PROMPTS = {"E10": "这句话，你怎么接？", "M03_WRAP": "这张清单，你打算怎么交？"}
DEPART_NOTES = {
    "M03_BRIDGE": "那三行明天跟着版本上线，先看两个星期。两个星期后的周会散了，王哥要当面问这件事。",
    "M03_MID": "这一旬剩下的日子，那个数的来源还得你自己补。",
    "M03_LATE": "月末最后一夜，工位上没人。那份文档还得打开。",
}
MESSAGES = {
    "M03_PHONE_1": {
        "m03_wang_1": "周三上午十点，客户到展厅谈合同。陈工盯着回滚的事走不开，你替我去一趟，小林带你。",
        "m03_wang_2": "他们要的是定心丸，不是学术报告。兜底那几行是你写的，技术上的问题他们准问你。",
    },
    "M03_PHONE_3": {
        "m03_wrap_a": "客户那边居然签了。你怎么敢当面把话说开的？",
        "m03_wrap_c": "听说小林回来脸色不太对。今天回去是不是不太好？",
    },
}
CARDS = {
    "M03_CLOSE": {
        "m03_e10_truth_with_fallback": "第 3 月：你把边界说清楚了，客户让你把兜底写具体。",
        "m03_e10_soft_clause": "第 3 月：合同换成了一句更软的承诺。双方都知道它有多软。",
        "m03_e10_overpromise": "第 3 月：客户点了头。小林没说你那天做得算不算过去。",
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

    for node_id, note in DEPART_NOTES.items():
        by_id[node_id]["departNote"] = note
        changes.append(f"{node_id}: departNote")

    for node_id, table in MESSAGES.items():
        node = by_id[node_id]
        for message in node.get("messages", []):
            mid = str(message.get("id"))
            if mid in table:
                message["text"] = table[mid]
        changes.append(f"{node_id}: {len(table)} 条消息")

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