#!/usr/bin/env python3
"""第 4 月对白重写：只改说法，不动 41 条 / 18% / 118 条这些事实与选项数值。

    python tools/patch_voice_m4.py            # 只看差异
    python tools/patch_voice_m4.py --apply    # 写回 events.json
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


M04_OPEN = [
    n("上个月合同签了。你讲清了边界，兜底那几行写进了合同。", when={"flag": "m03_e10_truth_with_fallback"}),
    n("上个月合同签了。最后落在纸上的，是「尽商业上合理努力」。", when={"flag": "m03_e10_soft_clause"}),
    n("合同按客户的原话签了。你先应下了，后面的事后面再说。", when={"flag": "m03_e10_overpromise"}),
    n("上个月的合同签完了。那套拣货问答月底上了线。", when={"noneOf": ["m03_e10_truth_with_fallback", "m03_e10_soft_clause", "m03_e10_overpromise"]}),
    n("上线那天下午，你守在工位上盯日志，一条报错都没有。"),
    n("第二天开始有零星的反馈。两个星期后，共享表上多了 41 条工单。"),
    n("第四个月，上旬，早上。你到工位的时候，表已经被人打开了。"),
    n("小赵把你第一个月写的那个检查脚本挂在表下面，批注只有四个字：先用这个。", when={"flag": "m01_activity_tool"}),
    n("41 条里，物流占 33 条，写着「不像我们说话的方式」的 6 条，剩下 2 条没人能复现。"),
    n("还是那两条。上个月你在《常见问题》里加过一行加粗的提示——结论写上了，怎么得出的没写。", when={"flag": "m03_e12_bold_note"}),
    s("王哥", "我试了四十分钟，也没复现出来。"),
    s("王哥", "现在全靠人试。灵活是灵活，谁觉得自己测得准，就按谁的算。", emphasis=["谁觉得自己测得准，就按谁的算"]),
    n("这条链是你在第二个月那张方案里定下来的。那天夜里提交，本地测试来回跑了四遍，全绿。"),
    n("建评测集要两周。这两周里还压着客户上个月在展厅提的第二期需求，看板右下角写着负责人：小林。"),
    s("王哥", "需求可以欠，测试也可以欠。反正债主迟早会来。", emphasis=["反正债主迟早会来"]),
    n("手册第一章第三条写着：模型的行为不能靠感觉验收，要留下能复现的记录——输入、期望、实际差在哪。这 41 条里，没有一条带着这样的记录。"),
    n("那一页底下有一行铅笔字：「我觉得比之前好」。你也这么写过一次。", when={"flag": "handbook_page_1.3"}),
    n("王哥把看板转过来。评测集和客户第二期，占着同一格。"),
    s("王哥", "就一件事——这些毛病是零散的，还是我们根本没测过。", emphasis=["还是我们根本没测过"], goalLine=True),
]

E05 = [
    n("你把话说完了。王哥没评价，把看板转过来。"),
    n("看板上两格亮着：评测集，客户第二期。它们占的是同两周。"),
    s("王哥", "两条都不能拖，可这两周只有你一个人。先做哪条，你说。"),
]

M04_NOTICE = [
    n("中旬，周一早上。桌上多了一张打印纸。"),
    n("表挂在共享表最上面。第二期移到下月，看板上登记的调整人是王哥。", when={"flag": "m04_e05_full_evalset"}),
    n("陈工把需求数往前推了一格。评测表还是空的，表头都没填。", when={"flag": "m04_e05_no_evalset"}),
    n("表只盖住物流那一类，另外两类没人能证明什么；第二期只做了一半。", when={"flag": "m04_e05_partial_evalset"}),
    {"type": "card", "text": "【通知】周五 10:00 · A 区复盘会议室 · 上线两周失败率复盘。主持：陈工。材料：无。"},
    s("王哥", "我到时候只讲一句时间点的话。别的你自己讲。", emphasis=["别的你自己讲"]),
    n("通知压在键盘边：陈工主持，A 区复盘会议室。按通知的时间过去。"),
]

E07 = [
    n("复盘会议室里坐了九个人。陈工打开投影，站在最靠门那一侧。"),
    n("投影停在一条红曲线上：工单失败率 18%（初算，口径未核）。", emphasis=["18%（初算，口径未核）"]),
    n("曲线旁边并排放着一张表，表头是你手写的字。", when={"flag": "m04_e05_full_evalset"}),
    n("桌上没有能对上的表。这条曲线是隔壁组从工单里一条条数出来的。", when={"flag": "m04_e05_no_evalset"}),
    n("你的表只盖住物流那一类，剩下半页写着「待补」，是你的字。", when={"flag": "m04_e05_partial_evalset"}),
    s("小林", "接口昨天还能用。今天算法侧一更新，整条链就断了。"),
    s("陈工", "算法侧，谁说的？"),
    s("小林", "我只说时间点对得上。那次提交的编号，是我贴在周报上的。"),
    s("王哥", "时间点不是证据。", emphasis=["时间点不是证据"]),
    n("王哥低头在本子上写了一行，没看你。"),
    s("老周", "（画外音，隔壁组）十分钟，我要结论，不要阵营。"),
    s("小林", "那次提交你最清楚。你说吧。"),
    n("监控截图就在你手边。小林没看它，她在看你。"),
]

M04_LATE = [
    n("下旬，夜里。工位上还亮着几盏灯。王哥走过来，在你桌边站住。"),
    s("王哥", "纪要我看过了。"),
    n("他没提「责任人」那一栏是你自己填的。", when={"flag": "m04_e07_clarified_in_room"}),
    n("「待定项」后面那三个名字，他一个也没念。", when={"flag": "m04_e07_process_review"}),
    n("那天你认下来的那一段，他也没提。", when={"flag": "m04_e07_admitted_verification_gap"}),
    s("王哥", "上旬问你的那件事，现在能说了吗？"),
    n("能。118 条里 9 条复现不了，剩下的能指出坏在哪一类、坏在哪一步。", when={"flag": "m04_e05_full_evalset"}),
    n("说不出来。7 条待复现，每条都只能再找个人试一遍。", when={"flag": "m04_e05_no_evalset"}),
    n("物流那一类能说清，另外两类说不了。表上那半页还写着「待补」。", when={"flag": "m04_e05_partial_evalset"}),
    s("王哥", "表留着。以后谁再问，先看表。", when={"flag": "m04_e05_full_evalset"}),
    s("王哥", "下次先有那张表，再答我。", when={"flag": "m04_e05_no_evalset"}),
    s("王哥", "把那半页补上，别让它空着。", when={"flag": "m04_e05_partial_evalset"}),
    n("他把中旬那张打印纸的边角按平，走了。"),
]

BEATS = {
    "M04_OPEN": M04_OPEN,
    "E05": E05,
    "M04_NOTICE": M04_NOTICE,
    "E07": E07,
    "M04_LATE": M04_LATE,
}

CHOICES = {
    "E05": {
        "A": (
            "建完整的评测集（第二期延到下月，请王哥确认排期）",
            "两周里你把 41 条整理、扩成 118 条测试记录，其中 9 条还是复现不了。第二周开始有人来借这张表——第一次不是来找你要代码。王哥说：“客户那边我去沟通，第二期延到下月，排期我来改。”",
            ["第一次不是来找你要代码"],
        ),
        "B": (
            None,
            "这单按期交了，陈工在群里回了个「好」。那张表还空着，连表头都没填。第三周新增的工单里又有 5 条复现不了，加上原来那 2 条，一共 7 条。",
            ["那张表还空着"],
        ),
        "C": (
            None,
            "200 条用例里有 60 条是你一行行补出来的。灰度第三天，物流类最常见的问题被盖住了，另外两类还是没有结论。",
            ["另外两类还是没有结论"],
        ),
    },
    "E07": {
        "A": (
            None,
            "会议室安静了两秒，陈工把截图上的时间念了出来。散会后你自己发了纪要，「责任人」那一栏填了你的名字——没人让你填。",
            ["没人让你填"],
        ),
        "B": (
            None,
            "老周合上笔：“今天先写流程责任，个人责任会后谈。”两小时后纪要发出，「待定项」后面有三个人的名字。",
            ["先写流程责任"],
        ),
        "C": (
            None,
            "会七分钟就散了。小林在群里发了句「辛苦了」，没有 @ 你。第二天陈工让你讲那段链路，你讲了十一分钟，没人打断，也没人接话。",
            ["也没人接话"],
        ),
    },
}

PROMPTS = {"E05": "这两周，先做哪一件？"}
DEPART_NOTES = {"M04_LATE": "月末最后一夜。灯还亮着，这一页翻过去了。"}
MESSAGES = {
    "M04_PHONE": {
        "m04_lin_a1": "你那张表至少能看出坏在哪一段。",
        "m04_lin_a2": "时间点是隔壁组数工单数出来的。我以为你自己会讲。",
        "m04_lin_c1": "你那张表至少能看出坏在哪一段。",
        "m04_lin_c2": "时间点是隔壁组数工单数出来的。我以为你自己会讲。",
        "m04_lin_b1": "曲线是人家数出来的。你连一张表都没有。",
        "m04_lin_b2": "行，现在也不用讲。下周再说。",
    }
}
CARDS = {
    "M04_CLOSE": {
        "m04_e07_clarified_in_room": "第 4 月：这件事你站住了。",
        "m04_e07_process_review": "第 4 月：你守住了一点东西，和老周近了一些。",
        "m04_e07_admitted_verification_gap": "第 4 月：有个地方你自己知道让了一步，撑得有点勉强。",
        "m04_e05_full_evalset": "那张表你还在填。",
        "m04_e05_no_evalset": "那张表你没建。",
        "m04_e05_partial_evalset": "那张表只填了一半。",
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