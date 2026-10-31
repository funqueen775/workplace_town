#!/usr/bin/env python3
"""第 1–2 月对白重写：把人机味的高频句式改成有人说话的样子。

只改玩家读到的句子（beats.text / choices.text / outcome / prompt / departNote /
todayCard.lines / month_close cards），节点 ID、旗标、数值、选项语义、地点、
时间一律不动。事实仍以《剧情册》第 1–2 月为准。

注意：文件名里的 m12 是「第 1、2 月」，不是第 12 月；第 12 月用 patch_voice_month12.py。

    python tools/patch_voice_m12.py            # 只看差异
    python tools/patch_voice_m12.py --apply    # 写回 events.json

改完必跑：
    python tools/v12m_validate.py
    python tools/voice_lint.py
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


# ---------------------------------------------------------------- 第 1 月

E01 = [
    n("入职第一天，上午九点。B 区训练室门口贴着一张纸，「新同事说明会」几个字是手写的，胶带贴歪了一边。"),
    n("你推门进去，里面坐了七八个人，前排还空着两个位子。陈工站在投影旁边，话正说到一半。"),
    s("陈工", "……所以第一件事，写你做过的事，别写你想做的事。"),
    s("陈工", "一份文档，谁做的，名字就写谁的。这个我不用年年讲。", emphasis=["名字就写谁的"]),
    s("陈工", "还有三条，是线，不是分数。"),
    s("陈工", "没授权的承诺，不许给客户。现场出了问题，不许说成网络波动。绕过审批改了线上，当天就得把记录补上。"),
    s("陈工", "今天讲过的，后面就按今天说的算。手册在桌上，提交之前看那三问。我十点还有个会，王哥，你带他们认认路。"),
    n("他合上笔记本，先出门了。你旁边那个人往这边侧了侧身。"),
    s("小赵", "他每年都这么开场，一个字不差。你好，我是小赵，工位在你旁边。"),
    s("王哥", "王哥，技术导师。走吧，我带你看看你以后待的地方。"),
]

E01_TOUR_STOPS = {
    "b_desk": [
        s("王哥", "这是你的工位。包先放着，一会儿回来再收拾。"),
        s("小赵", "我就在你旁边，有事喊我。喊两声他就该皱眉了。"),
        s("王哥", "好了，工位认过了。走，去 A 区总部。"),
    ],
    "a_gate": [
        s("王哥", "这栋楼是 A 区总部。跨组开会、找人签字，都来这儿。"),
        s("王哥", "记住一条：找人先发消息，别在走廊上喊名字。"),
        s("王哥", "工作手机给你。陈工刚发来一条。"),
        n("手机在手里震了一下，屏幕边缘亮起一个红点。"),
        s("王哥", "想点开就点开，不回也没关系。下一站是水道，走过去五分钟。"),
    ],
    "waterway": [
        s("王哥", "中午别在一楼吃。"),
        s("小赵", "为什么？"),
        s("王哥", "一楼那几张桌子坐的都是来查数据的人。你吃口饭，能被问走三个需求。"),
        s("小赵", "我吃过三次，三次都被拉住问。"),
        s("王哥", "水道就是条过路，没什么好看的。走，去心湖步道。"),
    ],
    "lakeside": [
        s("王哥", "想一个人待着就来这儿。我第一年在这条步道上吃了两个月外卖。"),
        s("小赵", "我也常来。下回一起。"),
        s("王哥", "湖也看了，回工位吧。你桌上还有本手册等着。"),
    ],
    "b_return": [
        n("回到 B 区，王哥用下巴指了指你桌上的手册。"),
        s("王哥", "转完了。手册先看第一章，看不完也别急着翻第二章。我三点还有个会，你自己坐会儿。"),
    ],
}

E02_BEATS = [
    n("中旬，第二次跨组周会，A 区那间会议室。你到得早，坐在靠墙那一排。"),
    n("白板上贴着这周的排期表。你从上往下看了两遍，没找到自己的名字。", emphasis=["没找到自己的名字"]),
    s("同事", "数据清洗这块，谁这周能顺手接一下？"),
    n("没人接话。陈工抬头看了你一眼，又转回白板。"),
    s("陈工", "小王，这块你跟进一下。"),
    n("王哥把椅子往你这边挪了半寸，声音压得很低。"),
    s("王哥", "上周那份方案，是你整理的吧？"),
    s("王哥", "他刚照着讲了一遍。纪要我看了，上面没你的名字，跟进人写的是我。"),
    s("王哥", "你打算怎么办？"),
]

E02_CHOICES = {
    "A": (
        "当场把话说明白",
        "陈工停了一下，说：“行，你把那段依赖关系讲清楚。”你讲到第三页，他没再打断。散会前，纪要里补上了你的名字。",
        ["补上了你的名字"],
    ),
    "B": (
        "散会后补一份带署名的记录",
        "散会以后，你把方案重新发了一遍，作者栏写了名字，抄送全组。陈工回了两个字：“收到。”没人解释谁该讲，但版本记录留下了你的名字。",
        ["版本记录留下了你的名字"],
    ),
    "C": (
        "先把手头的活交掉",
        "你把手头的活按时交了。纪要上，跟进人还是王哥；那份方案没有进这一周的纪要。",
        ["没有进这一周的纪要"],
    ),
}

M01_CLOSE_CARDS = {
    "m01_e02_spoke_in_meeting": "第 1 月：你在会上把那份方案讲清楚了。",
    "m01_e02_sent_signed_document": "第 1 月：那份方案的文档里，有了你的名字。",
    "m01_e02_deferred": "第 1 月：你先把手上的活交了。",
}

# ---------------------------------------------------------------- 第 2 月

M02_OPEN = [
    n("上个月剩下的那几天，你把开发环境装好了。手册翻到第一章，后来就没再翻。"),
    n("昨晚十一点，王哥发了封邮件，附件里两份说明：一份自研，一份开源。", goalLine=True),
    n("第二个月，上旬，早上九点。你刚坐下，椅子还没调到合适的高度。"),
    n("王哥端着杯子过来，把一张打印纸压在键盘边上。"),
    s("王哥", "手册在手边吧？这周给你两件事。"),
    s("王哥", "纸上是这个模块的两条路：自研一份，开源一份。你把依赖写一栏，退路写一栏。"),
    s("王哥", "两年前出过一回同类的事。当时的单子只写了「加监控」，没留下能执行的回滚办法。这次你把当年的记录查清楚，把这条路的退路补完整。"),
    s("王哥", "这活是禾丰那套拣货问答的。入职会上点了名，客户记住了。", emphasis=["客户记住了"]),
    s("王哥", "周三上午，A 区评审室，先把两张图带过去。评审完去树影书院二楼核对旧事故单，镇子东南角那栋。回来再补方案。"),
    s("王哥", "别问我倾向哪个。我两个都骂过。"),
    n("他走的时候把纸抽了回去，纸角留下一道折痕。你只来得及看清抬头那行小字：禾丰仓配 · 拣货问答 · 编排层。", emphasis=["禾丰仓配 · 拣货问答 · 编排层"]),
    s("小赵", "我桌上也有一张。你说他是在考我们，还是这周真缺人？"),
    n("纸还压在键盘边。按王哥说的，周三上午带着两张图去 A 区评审室。"),
]

E04 = [
    n("评审室的白板上，左边写着「自研」，右边写着「开源」，中间空着一大块。"),
    n("最后一排坐着两个生面孔。陈工没介绍，只说了句：“一起听听。”"),
    n("陈工比你们先到，正在看手机。王哥后脚进门，顺手把门带上了。"),
    s("陈工", "功能不用讲。我要看三样：依赖什么，维护谁来做，出了事怎么退回去。"),
    s("陈工", "上次那份方案，你在会上说清楚了。这次你讲，王哥补。", when={"flag": "m01_e02_spoke_in_meeting"}),
    s("陈工", "你署名发来的那版我看过了。这次你讲，王哥补充。", when={"flag": "m01_e02_sent_signed_document"}),
    s("陈工", "小王，你先讲。", when={"flag": "m01_e02_deferred"}),
    s("陈工", "退回上一版那一条，写在第二栏。别写「加监控」——那不叫退路。", emphasis=["别写「加监控」"], hook="door_library"),
    s("陈工", "两年前那次，单子上就三个字：加监控。后来谁都没退路可走。你要判断哪条更好收拾，先去树影书院二楼把当年的单子翻出来，再回来把结论补进方案。"),
    n("他把白板笔递给你，笔帽已经拧开了。"),
    s("王哥", "自研，你能自己说了算；开源，省时间，但后面是别人在维护。各有各的麻烦。"),
    s("陈工", "别说哪条听起来高级。告诉我，哪条真出了事，收拾得更快。"),
    s("王哥", "周三先把两张图交了，剩下的这周补验证。我不盯过程。"),
    n("笔在你手里。先定一条验证的路子，评审完去树影书院二楼查旧单的回滚记录，回来把退路写进方案。"),
]

E04_CHOICES = {
    "A": (
        None,
        "两台终端并排摆在桌上。两条路线各跑出一轮结果，陈工追问了一处差异，你拿记录答上来了。散会后你去树影书院二楼翻旧单，确认当年有没有真正的回滚方案，再把结论补进这周方案。",
        ["你拿记录答上来了"],
    ),
    "B": (
        None,
        "流程第三天就跑通了，快是真的快。王哥看了回滚清单，说：“这部分还得补。”散会后你去树影书院二楼查了当年的回滚记录，把退路补全。",
        ["这部分还得补"],
    ),
    "C": (
        None,
        "王哥讲了旧单里那次「加监控」是怎么处理的。你把他的口述和这次验证分开记，散会后去树影书院二楼核对原记录，再把结论补进方案。",
        ["把结论补进方案"],
    ),
}

M02_LIBRARY = [
    n("你按陈工给的线索穿过半个镇子，走到东南角那栋树影书院。公司的旧事故单都装订在二楼，凭工牌进。这趟要弄明白一件事：两年前那次故障，到底有没有能照着做的回滚步骤。"),
    n("二楼的灯是感应的。你往前走一步，前面才亮一排。"),
    n("旧单按季度装订。最上面那本的封皮上，写着两年前的冬天。"),
    n("你要找的那一栏写着「已处理」，处理方式只有三个字：加监控。", emphasis=["加监控"]),
    n("后面夹着一页回滚记录。按下那一栏是空的，值班表那一格也是空的。", emphasis=["按下那一栏是空的"]),
    n("你把那页拍下来，把缺的回滚步骤圈出来，没证据的地方标成待确认。楼下有人关门——管理员在催了。"),
    n("按陈工说的，回 B 区把能执行的退路补进方案。"),
]

M02_NIGHT_1 = [
    n("第三天夜里。上午在评审室定了路线，下午去书院翻了旧单。"),
    n("自研那套先跑通了，开源那套卡在配置里。你把报错一条条抄下来，准备明早再试。", when={"flag": "m02_e04_two_prototypes"}),
    n("开源那条流程第三天就跑通了。还没验证的部分，你单独列成一张清单，准备评审时说明。", when={"flag": "m02_e04_open_first"}),
    n("旧单里那个回滚问题，你照着自己的理解做了个小验证，没直接抄结论。", when={"flag": "m02_e04_ask_old_scars"}),
    n("退路那一栏，你补上了能照着做的那一段，剩下两处标着待确认。", emphasis=["能照着做"]),
    n("眼睛有点酸。你看了眼时间，收东西回宿舍。"),
]

M02_DAY_2 = [
    n("第四天早上，回到工位。那两把借来的椅子还在，你顺手推回了隔壁。"),
    n("你又跑了一遍。两条路线的结果对上了，就差最后一步。", emphasis=["就差最后一步"]),
]

M02_NIGHT_2 = [
    n("第四天夜里，这一层只剩两盏灯，你那盏还亮着。"),
    n("再抬头，窗外已经黑透了。剩下那一段还没跑完。"),
]

M02_WEEK_7 = [
    n("第七天早上。这周该验的都验完了。书院翻到的旧记录、你自己跑出来的结果，两份分开记着；方案里补上了能照着做的回滚步骤。"),
    n("东西齐了，可以交了。"),
]

E03 = [
    n("B 区只剩两盏灯，一盏在你这里。王哥的椅子推进了桌下，桌上那盆假绿植没人管。"),
    n("代码跑通了。本地检查全绿，测试来回跑了四遍。提交页面上有一栏，叫「改动说明」。"),
    n("本地的工作记录里有一行小字：这次改动，约 63% 由生成式工具先起草。这一行只有你看得到。", emphasis=["63% 由生成式工具先起草"]),
    {"type": "phone_cinematic", "speaker": "小赵", "text": "还没走？食堂阿姨下班了。我给她带了个包子，她说不用。"},
    n("你看了眼手机，没有回。对话框里「正在输入」亮了三次，最后灭了。"),
    n("手册第一章第二条底下那行铅笔字，你又想起来了：「这条，我第一年没当回事。」", when={"flag": "handbook_page_1.2"}),
    n("手册第一章第二条你翻过一眼，没细看。这会儿你想起，那页底下好像有一行铅笔写的字。", when={"notFlag": "handbook_page_1.2"}),
    n("没有人催你，也没有人看着这一栏。要删掉，按一次退格就够了。"),
]

E03_CHOICES = {
    "A": (
        None,
        "第二天的评审上，那一栏被念了出来。大家问了十五分钟你标着「还没把握」的部分，王哥替你答了两句，剩下的你自己答。",
        ["剩下的你自己答"],
    ),
    "B": (
        None,
        "提交十分钟就过了，没人问工具的事。你合上电脑，楼下便利店的灯还亮着。这一晚像是什么也没发生。",
        ["像是什么也没发生"],
    ),
    "C": (
        None,
        "没有人追问。第二天那句说明还挂在记录里，谁都能读到，却看不出具体哪一段用了工具。",
        ["看不出具体哪一段"],
    ),
}

M02_CLOSE_CARDS = {
    "m02_e04_two_prototypes": "第 2 月，你把两条路线都跑了一遍，拿到了实测结果。",
    "m02_e04_open_first": "第 2 月，你先让开源跑起来，快是快了，维护和回滚的账还留着。",
    "m02_e04_ask_old_scars": "第 2 月，你问过王哥以前踩过的坑，又自己补了验证。",
    "m02_e03_disclosed_precisely": "提交说明里写清了工具做过什么，也写了你还没把握的地方。",
    "m02_e03_undisclosed": "这次评审没人问工具参与。那一栏，你删掉了。",
    "m02_e03_vague": "你写了「部分参考了公开资料」，但没说明具体范围。",
}

BEATS = {
    "E01": E01,
    "E02": E02_BEATS,
    "M02_OPEN": M02_OPEN,
    "E04": E04,
    "M02_LIBRARY": M02_LIBRARY,
    "M02_NIGHT_1": M02_NIGHT_1,
    "M02_DAY_2": M02_DAY_2,
    "M02_NIGHT_2": M02_NIGHT_2,
    "M02_WEEK_7": M02_WEEK_7,
    "E03": E03,
}

CHOICES = {"E02": E02_CHOICES, "E04": E04_CHOICES, "E03": E03_CHOICES}
PROMPTS = {"E02": "王哥在等你开口。", "E04": "这件事，你打算从哪儿开始？", "E03": "这一栏，你打算怎么写？"}
DEPART_NOTES = {
    "M02_NIGHT_1": "退路那栏今晚填不完。明早回来，开源那块还得自己再跑一遍。",
    "M02_DAY_2": "天暗得比想的快，人还在这张桌子前。这一版跑完就收。",
    "M02_NIGHT_2": "明天再来补。今晚先回去睡。",
    "M02_WEEK_7": "东西备齐了，可以交了。提交页面上还空着一栏，那一栏没人替你填。",
}
CLOSE_CARDS = {"M01_CLOSE": M01_CLOSE_CARDS, "M02_CLOSE": M02_CLOSE_CARDS}


def apply(nodes: list[dict]) -> list[str]:
    by_id = {str(node.get("id")): node for node in nodes}
    changes: list[str] = []

    for node_id, beats in BEATS.items():
        node = by_id[node_id]
        changes.append(f"{node_id}: beats {len(node.get('beats', []))} -> {len(beats)}")
        node["beats"] = beats

    tour = by_id["E01_TOUR"]
    for stop in tour.get("stops", []):
        new_beats = E01_TOUR_STOPS.get(str(stop.get("id")))
        if new_beats is None:
            continue
        changes.append(f"E01_TOUR[{stop.get('id')}]: beats {len(stop.get('beats', []))} -> {len(new_beats)}")
        stop["beats"] = new_beats

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
            choice["emphasis"] = emphasis
        changes.append(f"{node_id}: {len(table)} 个选项的结果重写")

    for node_id, prompt in PROMPTS.items():
        by_id[node_id]["prompt"] = prompt
        changes.append(f"{node_id}: prompt")

    for node_id, note in DEPART_NOTES.items():
        by_id[node_id]["departNote"] = note
        changes.append(f"{node_id}: departNote")

    for node_id, table in CLOSE_CARDS.items():
        node = by_id[node_id]
        for card in node.get("cards", []):
            flag = str((card.get("when") or {}).get("flag", ""))
            if flag in table:
                card["text"] = table[flag]
        changes.append(f"{node_id}: 月末卡 {len(table)} 条")

    return changes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="写回 events.json")
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