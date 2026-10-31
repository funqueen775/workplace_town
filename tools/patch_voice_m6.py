#!/usr/bin/env python3
"""第 6 月对白重写：转正答辩这一月。只改说法，不动四栏、五问、旗标。

    python tools/patch_voice_m6.py            # 只看差异
    python tools/patch_voice_m6.py --apply    # 写回 events.json
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


M06_OPEN = [
    n("HR 把通知贴在工位隔板上，用一块卡通磁贴压着。日期、地点、十分钟，底下列着参加的人。"),
    n("陈工在第一行，老周在第二行。第三个名字你没见过。"),
    n("王哥不在名单里。", emphasis=["王哥不在名单里"]),
    n("回到工位，键盘下面压着一张表，纸角有王哥的字。"),
    s("王哥", "答辩填这个。我第一年也填过。"),
    n("表上四栏：负责过的模块、做成的事、踩过的坑、之后想做什么。最后一栏的右上角被人划掉过，纸面起了毛。"),
    n("表头印着一句：职级看的是你能独立负责什么。"),
    s("王哥", "别什么都往里塞。挑三件，讲透。", emphasis=["挑三件，讲透"]),
    s("王哥", "下午两点，去心湖北岸那面墙。这半年你记下的东西都贴在那儿——从里面挑三张，对得上这四栏的。"),
    s("王哥", "挑完回来写四页。中旬，上午十点，A 区小会议室，别迟到。"),
    n("他把表折了一下，压回你键盘底下。下午两点，心湖北岸。"),
]

M06_WALL = [
    n("下午两点，王哥在工位那头抬了抬下巴，起身往湖边去。你跟在他后面，木栈道晒得发烫。答辩表那四栏还在你兜里，最后一栏空着。"),
    n("墙上贴着这半年记下的事。有些是当天写的，有些隔了两天才补上，纸边已经卷了。"),
    s("王哥", "平时随手记的东西，到这时候才有用。"),
    n("你挑了一张当主讲，另外两张顺手带上。剩下的还留在墙上。"),
    s("小赵", "我写了三个，后来又删掉两个。怕讲不完。"),
    s("小赵", "你留了几个？"),
    n("便签挑好了，四栏只剩最后一行。填完这一栏，就回工位把四页写出来。"),
    n("你把表翻到最后一栏。「之后想做什么」，笔停了一下。"),
]

M06_WALL_OUT = [
    s("王哥", "走了。中旬那天十点答辩，今晚把四页写出来；写不出来，就带着带回来的这几张去。"),
    n("回去的时候天已经暗了。你在工位把三张便签摊开，一条一条往四栏里对。"),
    n("改到十一点，四页删成三页半。你在便签背面写了一行：中旬，上午十点，A 区小会议室。"),
    n("关灯。中旬那天要讲的，就是这些。"),
]

M06_DEF1 = [
    n("中旬那天九点五十，A 区小会议室门口。老周已经在了，手里也拿着一叠。他看了你一眼，没问这几页改到几点。"),
    s("HRBP", "你先在外面等一下。"),
    n("走廊不长。门里有人说话，听不清是谁。"),
    n("小赵靠着另一头的墙。他比你早进去，也晚一点出来。"),
    n("你们都没问对方答得怎么样。"),
    n("门里叫了你的名字。"),
    n("长桌一头坐着陈工，HRBP 在对面。王哥的位置空着。"),
    n("四页材料投到墙上。第一页很快过去，你把带来的三件事放在中间讲。"),
    n("桌上那几张便签没有投出来，只有你自己看得见。"),
    s("陈工", "上线以后，这块涨得挺明显。这里头，你具体做了哪一段？"),
]

M06_DEF2 = [
    n("你答完，陈工在本子上记了一行，没抬头。"),
    s("陈工", "这半年，有没有哪段时间比较难？"),
]

M06_DEF3 = [
    n("老周把那张便签翻到背面。"),
    s("老周", "你带了这张——{主笔记}。后来怎么收的？", when={"anyOf": ["m05_night_hotfix_unlogged", "m05_night_waited", "m05_e17_blame_network", "m05_e17_continue"]}),
    s("老周", "带过来的这几件，都是做成的。就没有一件没做成的？", when={"noneOf": ["m05_night_hotfix_unlogged", "m05_night_waited", "m05_e17_blame_network", "m05_e17_continue"]}),
]

M06_DEF4 = [
    n("对面的 HRBP 合上本子，跟旁边的人低声说了两句。"),
    s("HRBP", "我们的问题差不多了。你有什么想问我们的？"),
]

M06_DEF5 = [
    n("你的问题问完，对面几个人交换了一下眼神，才有人开口。"),
    s("陈工", "下半年那块，一直没人愿意接。你要问，就先想清楚它占你多少时间。", when={"flag": "m06_reverse_next"}),
    n("他把你的表翻到背面，写了两个字，没让你看。", when={"flag": "m06_reverse_next"}),
    s("老周", "这个问题，你自己也得先答一半。", when={"flag": "m06_reverse_team"}),
    s("老周", "那你觉得，你下半年该往哪儿使劲？", when={"flag": "m06_reverse_team"}),
    n("你答了一句。他没评价，只点了下头，把这一页翻过去。", when={"flag": "m06_reverse_team"}),
    s("HRBP", "行。以后有问题，随时来找我们。", when={"flag": "m06_reverse_none"}),
    n("陈工把那叠表收进文件夹，动作比刚才快了一点。", when={"flag": "m06_reverse_none"}),
    n("HRBP 把笔帽扣上，文件夹在桌上顿了顿。"),
]

M06_CORRIDOR = [
    n("门开了。陈工拿着那叠表出来。"),
    s("陈工", "材料我留着，你自己来取。"),
    n("他没说过没过。评定结果要留到下个月月初。"),
]

M06_WAIT = [
    n("等到天黑，回到工位。桌上没有评定表。"),
    n("你把四页材料收回文件夹。"),
    n("这半年做过的事，你挑了三件带进去。"),
    n("答辩结果还没到。"),
]

BEATS = {
    "M06_OPEN": M06_OPEN,
    "M06_WALL": M06_WALL,
    "M06_WALL_OUT": M06_WALL_OUT,
    "M06_DEF1": M06_DEF1,
    "M06_DEF2": M06_DEF2,
    "M06_DEF3": M06_DEF3,
    "M06_DEF4": M06_DEF4,
    "M06_DEF5": M06_DEF5,
    "M06_CORRIDOR": M06_CORRIDOR,
    "M06_WAIT": M06_WAIT,
}

CHOICES = {
    "M06_WALL": {
        "A": (None, "小赵凑过来看了一眼，点点头：“那至少知道该先找谁问了。”", None),
        "B": (None, "小赵看了一眼，没追问。", None),
        "C": (None, "小赵说：“这句我也差点写上去。”", None),
    },
    "M06_DEF1": {
        "A": (None, "陈工低头记了一行，接着问下一项。", None),
        "B": (None, "陈工停了一下：“那前半段是谁做的？”会议室里没人接话。", None),
        "C": (None, "HRBP 记下一行。散会的时候你听见她说：“这块下半年要再确认一下。”", None),
    },
    "M06_DEF2": {
        "A": (None, "HRBP 记了一笔。陈工说：“这件事下半年可以再聊。”", None),
        "B": (None, "老周补了一句：“他那几天确实弄到两点。”你没接话。", None),
        "C": (None, "陈工点点头，把这一页翻过去。", None),
    },
    "M06_DEF3": {
        "A": (None, "老周说：“下次把那张放前面。别等人问了才想起来。”", None),
        "B": (None, "老周没追问。散会后，那张便签还留在墙上。", None),
        "C": (None, "陈工在表上勾了一格，没当场评价。", None),
    },
    "M06_DEF4": {
        "A": (None, "陈工把笔放下，看了你两秒。", None),
        "B": (None, "老周笑了一下，没马上接话。", None),
        "C": (None, "HRBP 合上文件夹，等你往下说。", None),
    },
}

PROMPTS = {"M06_WALL": "最后一栏，你怎么落笔？"}
DEPART_NOTES = {
    "M06_WALL_OUT": "太晚了，先回去睡。中旬那天十点，A 区小会议室。",
    "M06_CORRIDOR": "先回工位。结果下个月初才到。",
    "M06_WAIT": "结果下个月初到。这一月的事，先放一放。",
}
MESSAGES = {
    "M06_PHONE": {"m06_chen_1": "明天十点，A 区小会议室。十分钟，不用做 PPT，四页以内。去年有人做了十二页。"},
}
CARDS = {
    "M06_CLOSE": {
        "m06_goal_written": "最后一栏你写了具体方向。",
        "m06_goal_crossed": "「之后想做什么」那一栏，你划掉了。",
        "m06_goal_uncertain": "你写下：还没想清楚，先把手上的做稳。",
        "m06_scope_overclaim": "答辩里，你把整段揽成了自己从头跟到尾。",
        "m06_reverse_next": "临走你问了转正之后接哪一块。",
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