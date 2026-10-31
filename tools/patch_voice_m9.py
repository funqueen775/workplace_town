#!/usr/bin/env python3
"""第 9 月对白重写：署名名单、贡献栏、交接文档。只改说法。

    python tools/patch_voice_m9.py            # 只看差异
    python tools/patch_voice_m9.py --apply    # 写回 events.json
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


M09_NAME = [
    n("上旬的一个上午，小赵站在工位边上，没坐下。"),
    s("小赵", "这事我只跟你说一遍。王哥那边我还没敢提。"),
    n("共享盘最上面那个文件夹叫「Q3 项目贡献者申报」。里面已经有一张填好的表。"),
    n("负责人一栏写着周老师，贡献者列表里没有小赵。"),
    n("申报系统只让正式员工当负责人。实习生的贡献可以补进说明，但这张表里还没写。"),
    n("提交记录里有三十多条是小赵的。最后几条在夜里两点，说明只写了「先记一下，明天再理」。"),
    n("训练谷那一局他赢了你。说好的，输赢不算考核，也没人把它记进任何一份名单。", when={"flag": "m07_valley_first"}),
    n("四个月前那次复盘，你也把能核对的记录摆上了桌。", when={"flag": "m04_e07_clarified_in_room"}),
    n("四个月前那次会，你先把责任接了下来，没再追署名。小赵这句话听着有点熟。", when={"flag": "m04_e07_admitted_verification_gap"}),
    s("小赵", "也可能是周老师忘了。反正我还是实习生，名字写谁好像都差不多。"),
    n("桌上的手机震了一下，屏幕朝上。"),
    s("王哥", "（群里）名单今天截止。负责人必须是正式员工，贡献说明可以补。别把两件事混成一件。"),
    n("老周从走廊进来，看见屏幕上的名单。"),
    s("老周", "申报今天截止。小赵不是正式员工，负责人那一栏不能填他。"),
    s("小赵", "没事，我——"),
    s("老周", "我不是问你有没有事。我在说系统怎么填。贡献说明那一栏还空着。"),
]

M09_CONTRIB = [
    n("中旬的一个早上，桌上多了一张申报通知。王哥把它压在你键盘旁边。"),
    s("王哥", "你自己那一栏今天也得填。工位上一直有人开会，去书院那张长桌写吧。"),
    n("申报表上「我的贡献」那一栏开着。系统只列出你确实做过、而且有事件记录支持的事——挑一条填进去，或者先留空。"),
]

M09_LIBRARY_SOCIAL = [
    n("长桌这一角很安静。抬头的时候，对面的人正好也抬起头。"),
]

E28 = [
    n("下旬。申报那三行还差最后一句。"),
    n("你在长桌上把申报表里的三行写完：做过什么，卡在哪里，下一步谁接。"),
    s("老周", "（把一张纸推过来一半）新人下周到。谁带她，还没定。"),
    n("手册里要是少了关键一步，她还是会来问你。"),
    n("你那张评测表还压在桌角，第一列表头是你自己写的。", when={"flag": "m04_e05_full_evalset"}),
    s("老周", "目录我先建。里面写到哪一步，你定。"),
    n("目录第一行空着，光标停在那儿。"),
]

BEATS = {
    "M09_NAME": M09_NAME,
    "M09_CONTRIB": M09_CONTRIB,
    "M09_LIBRARY_SOCIAL": M09_LIBRARY_SOCIAL,
    "E28": E28,
}

CHOICES = {
    "E27": {
        "A": (None, "老周看完回了一句：“收到，名单我改。”新名单第二行多了小赵。小赵没抬头。散会后他在走道上等你，说了声「谢谢」。", None),
        "B": (None, "老周沉默了一会儿：“给我十分钟。”十分钟后新名单补上了小赵，群里没人再提。第二天他路过你工位，朝你点了下头。", None),
        "C": (None, "小赵把页面关掉，手指在自己那几行记录上划了一下：“嗯，那就先这样。”下周过代码时，老周把你负责的部分问得很细。", None),
    },
    "M09_LIBRARY_SOCIAL": {
        "A": ("朝对方笑一下，继续看自己的材料", "对方点了下头，也低头继续看。", None),
        "B": ("问一句：你在看什么？", "对方把书转过来给你看封面：“新人培训的东西，先翻翻。”", None),
        "C": ("把材料收进包里，换个位子", "长桌继续安静下来。", None),
    },
    "E28": {
        "A": ("写全：故障案例、当时怎么判断、新人照着就能排查的步骤", "两天后文档里多了七八个常见坑。新人第一次查报错就找到了根因，没叫你过去。", None),
        "B": ("写个能跑的版本：启动、测试、回滚写上，关键判断先留在自己脑子里", "新人照着跑起来了。遇到岔路还是来问你，你把剩下的部分当面讲完。", None),
        "C": ("下个迭代再写：目录先留着", "“下个迭代”一直没空出来。三个月后准备答辩的时候，目录第一行还是空的。", None),
    },
}

MESSAGES = {
    "M09_OPEN": {
        "m09_lin_1": "共享盘顶上那个申报文件夹，你看到了吧？",
        "m09_lin_2": "去年我也被写进一个没做过的模块，懒得追。今年最好先对一下记录。",
    },
    "M09_PHONE_XZ": {
        "m09_xz_a": "老周把署名规则贴出来了。他没说是因为你，反正现在贡献说明里有我。",
        "m09_xz_b": "周老师今天把我的名字加上了。他没说为什么，我猜他看过那几条记录。",
    },
}
CARDS = {
    "M09_CLOSE": {
        "m09_credit_public_evidence": "共享盘里的名单补上了小赵。那几条提交记录留在申报说明里。",
        "m09_credit_private_request": "名单改了。群里没展开这件事，你和老周在走廊把话说完了。",
        "m09_credit_no_action": "名单按原样交了。下周你和小赵还得一起过代码。",
        "m09_handoff_complete": "新人照着文档查到一个报错根因，没叫你过去。",
        "m09_handoff_partial": "新人能先跑起来，遇到岔路还是来问你。",
        "m09_handoff_deferred": "目录第一行还空着。",
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