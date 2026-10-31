#!/usr/bin/env python3
"""第 10 月对白重写：许棠入职、公示名单多了一个名字、两条路线。只改说法。

    python tools/patch_voice_m10.py            # 只看差异
    python tools/patch_voice_m10.py --apply    # 写回 events.json
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


M10_OPEN = [
    n("上旬的一个早上，你工位旁边多了一张椅子。桌角压着一份打印稿，第七页折了一个角。"),
    n("那是你上个月写的交接文档。"),
    n("新同事许棠把临时工牌贴在电脑边，正对照纸上的步骤操作。"),
    s("许棠", "我按到第七页了。这里我自己跑通了，还加了一条，你看这样行不行？", when={"flag": "m09_handoff_complete"}),
    n("她能一口气跑到第七页，是因为前面那几段你早就写完了。", when={"flag": "extra_push"}),
    n("她补的那条，比你原来写的还周到。", when={"flag": "m09_handoff_complete"}, abilityPeak=["collaboration"]),
    s("许棠", "前面能跑。到这一步我不确定该选哪条，就先停了。", when={"flag": "m09_handoff_partial"}),
    n("她问的正是你当时留在脑子里的那两条判断。你解释了一遍，才发现自己也得先想起当时为什么这么定。", when={"flag": "m09_handoff_partial"}),
    s("许棠", "我先照着共享盘里另一份材料做的。第一步之后就对不上了，你现在方便看一下吗？", when={"flag": "m09_handoff_deferred"}),
    n("你看了一眼才发现，最熟的那一段一直只有你在做。", when={"flag": "m09_handoff_deferred"}),
    n("许棠照着共享盘里现有的文档把第一步做完了，暂时没有要你补的。", when={"notFlag": "visit_9_m9_library"}),
    n("下午，行政发来通知：本月项目经历公示四天，A 区公告栏可以核对项目、人名和贡献。你想起自己以前没追问过署名，决定这次去看看申报表。"),
]

E31 = [
    n("中旬。公示期过半。"),
    n("按行政通知，你来到 A 区公告栏核对申报表。右上角写着「公示四天」，第三行是你的名字。"),
    s("小林", "恭喜。你多了一段没做过的项目经历。"),
    n("那个项目你只在走廊里听过，从没参与过。"),
    s("小赵", "会不会是行政从旧表里复制过来的？"),
    s("老周", "负责人名额已经报满了。公示这几天只能改错别字。要改人名，得出情况说明，陈工签字，再往上报。", goalLine=True),
    n("你说自己没做过。老周又看了一遍表，没马上接话。"),
    s("老周", "以前怕名字漏掉。现在轮到你怕名字多了。"),
    n("名单上的项目成果写得很具体。你如果不提，之后答辩时它也会出现在你的履历里。"),
    n("四个月前你也没继续追问署名，只把那次责任接了下来。", when={"flag": "m04_e07_admitted_verification_gap"}),
    n("你认得那种提交记录。四个月前，自己的名字也在一份复盘纪要的责任栏里。", when={"flag": "m04_e07_clarified_in_room"}),
    n("公示说明写着：公示期内可改错字；增删人员需提交书面说明并重新审批。"),
    n("公示期里，你也把交接文档交给许棠核对。她约你下旬到树影书院阅览室，带上第七页，把她仍靠经验判断的两步写成能复用的流程。"),
]

E40 = [
    n("下旬，许棠在群里发来一条消息：书院阅览室，她画了两条路线等你。你带着第七页文档过去的时候，她已经在白板上画开了。"),
    n("一条是你现在用的办法，快，而且这半年没出过错。另一条多花两天，但可能不用人一直盯着。"),
    s("许棠", "这一步每次都要人看。我想把判断写进规则里，慢两天，后面就不用一直守着。"),
    s("王哥", "我以前也提过类似的改法。当时没做，理由也是「现有办法没出过错」。"),
    n("许棠在草稿边上引用了你文档第七页的一段排查步骤；她是从那一步接着改的。", when={"flag": "m09_handoff_complete"}),
    n("她停在你没写下来的两个判断上：“这两条好像一直靠人记。”", when={"flag": "m09_handoff_partial"}),
    n("她试着从现有资料里找答案，没找到。你得先把那段过程说清楚。", when={"flag": "m09_handoff_deferred"}),
    n("阅览室外还有人等结果。出了问题，最后签处理单的人还是你。"),
]

BEATS = {
    "M10_OPEN": M10_OPEN,
    "E31": E31,
    "E40": E40,
}

CHOICES = {
    "E31": {
        "A": (None, "陈工签了说明，名单重新送审。小赵看着更新后的公示：“原来真有人会把不属于自己的成果退回去。”签完字，陈工只问了一句：“那这个模块实际是谁做的？”", None),
        "B": (None, "名单继续公示。你多了一条漂亮记录，也多了一项以后要解释清楚的工作。", None),
        "C": (None, "老周把你叫进办公室：“名单我会处理。你不用在群里跟所有人争，但之后有人问起，别说成自己做的。”后来名单改了。", None),
    },
    "E40": {
        "A": (None, "交付很稳。许棠把新方案收回去，文件名改成「待定」，没再争。", None),
        "B": (None, "小范围验证没替任何人赢下争论，但决定开始有证据了。许棠交上来的记录里，有两行引用了你留下的文档。", None),
        "C": (None, "两周后出现一条告警。回滚单上有许棠的提交，也有你作为负责人的确认记录。", None),
    },
}

MESSAGES = {
    "M10_PHONE_LZ": {"m10_lz": "小赵最近敢在申报会上开口了。上次你把提交记录贴出来以后，他这回没把话缩回去。"},
}
CARDS = {
    "M10_CLOSE": {
        "m10_name_removed_by_self": "公示名单上的那段经历被更正了。陈工问了一句：这块实际是谁做的？",
        "m10_name_kept_by_silence": "公示结束时，你的名字还在那一栏。",
        "m10_name_delegated_correction": "老周去走了更正流程。你没有在群里公开争论，也没有把那项工作说成自己的。",
        "m10_handoff_legacy": "交付按原计划完成。许棠把新路线留在了「待定」文档里。",
        "m10_handoff_validated_trial": "两天的对照记录留下来了，换不换还要接着谈。",
        "m10_handoff_unreviewed_release": "两周后的告警单上，有提交记录，也有你的确认记录。",
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