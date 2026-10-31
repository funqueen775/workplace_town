#!/usr/bin/env python3
"""第 5 月剧情补桥（2026-10-30 实机反馈驱动）。

玩家原话：
  ①「第一幕那个什么演讲我都不知道要干什么」——路演袋只写了"主讲，你"，没说这场要
    干什么、要讲多久、客户会怎么问，也没说接下来几天要做什么。
  ②「怎么去了那个地方突然就上旬到中旬了」——周一上午 → 周四深夜之间没有任何过渡，
    上旬→中旬又落在"走到码头门口"这一刻，玩家只会觉得日历自己跳了。
  ③「去下面那个地方的讲解卡也没有」——观澜会展码头是第一次出现的地方，
    没有卡、没有黄线、没有"来这儿干什么"。

改法（只动数据，不改判定）：
  M05_OPEN   补"这场是干什么的 / 为什么是你 / 这四天怎么排"，末句给去向（周四下午彩排）
  M05_PREP   新增「彩排」：王哥当客户把话说死，为深夜那条告警和台上那一问铺因果
  M05_NIGHT  开头补两拍承接（彩排没走 → 两点零七分告警）
  M05_DAWN   新增「第二天早上」：旬从这里翻（上旬→中旬有戏承接，不再发生在门口）
  M05_DEMO   改成 enterPlace（走黄线 → 讲解卡 → 按 E 进主厅 → 台上那一屏）
  manifest   nodeOrder 登记两个新节点

用法：python tools/patch_m5_story.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
EVENTS = ROOT / "data/story/v12m/events.json"
MANIFEST = ROOT / "data/story/v12m/manifest.json"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def dump(path: Path, data: dict) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def find(nodes: list, node_id: str) -> dict:
    for node in nodes:
        if isinstance(node, dict) and node.get("id") == node_id:
            return node
    raise SystemExit("找不到节点：%s" % node_id)


def nav(text: str, **extra) -> dict:
    beat = {"type": "narration", "text": text}
    beat.update(extra)
    return beat


def say(speaker: str, text: str, **extra) -> dict:
    beat = {"type": "say", "speaker": speaker, "text": text}
    beat.update(extra)
    return beat


def build_open() -> dict:
    return {
        "beats": [
            nav(
                "上个月复盘会，纪要里“责任人”那一栏，是你自己填的。",
                when={"flag": "m04_e07_clarified_in_room"},
            ),
            nav(
                "上个月复盘会的纪要，“待定项”后面写了三个人的名字。",
                when={"flag": "m04_e07_process_review"},
            ),
            nav(
                "上个月你认了那句没核清，散会没人接话。",
                when={"flag": "m04_e07_admitted_verification_gap"},
            ),
            nav("禾丰那套还在跑，18% 那条曲线被人截成图，在组里传了两轮。"),
            nav("第 5 月 · 上旬，B 区工位，周一早上。"),
            nav("键盘边上放着一个牛皮纸袋，是小赵替人放上来的。"),
            nav(
                "袋里有张路演流程单：“周五 14:00 · 会展码头 · 客户现场”。最后一行被马克笔加粗：主讲，你。",
                emphasis=["主讲，你"],
            ),
            nav(
                "背面还有一行小字，写的是这场到底要干什么：十分钟，把拣货问答那套从头点到尾；"
                "客户会随手指一处，问“这里错了怎么办”。",
            ),
            nav(
                "小林写了两行，字很小：“屏幕是展厅的，接口自己想办法。麦在你手上，我在台下。”",
            ),
            nav("袋里还有一个转接头。上次那个。"),
            nav(
                "名单是王哥报的。他说，讲自己写的那一段的人，只有你。",
            ),
            nav("你把日子算了一遍：今天周一，周五下午两点。中间只剩四天。"),
            nav(
                "王哥（手机 09:12）：周四下午三点，我坐台下当客户，你先给我讲一遍。"
                "讲不顺的地方，那时候还改得动。",
            ),
            nav(
                "四天：周四下午彩排，周五 14:00 到会展码头。先把那十分钟排出来。",
                goalLine=True,
            ),
        ],
        "todayCard": {
            "title": "第五月 · 客户 Demo",
            "lines": [
                "主讲是你：十分钟，把拣货问答从头点到尾",
                "周四下午三点，王哥当客户，先彩排一遍",
                "周五 14:00 会展码头 · 屏幕不是我们的",
            ],
            "shots": ["place_card_expo_1.png"],
        },
        "departNote": "周五下午两点，会展码头。在那之前，周四下午先彩排一遍。",
        "walkNote": "回工位，看那个牛皮纸袋",
    }


def build_prep() -> dict:
    return {
        "id": "M05_PREP",
        "month": 5,
        "order": 205,
        "nodeType": "main_story",
        "required": True,
        "title": "彩排",
        "locationId": "B",
        "location": "B 区工位",
        "durationMinutes": 60,
        "situation": "medium",
        "autoComplete": True,
        "beats": [
            nav("周一到周三，那十分钟你改了四版。删掉的比留下的多。"),
            nav("周四下午三点，王哥搬了把椅子坐在你侧面，小林举着手机计时。"),
            say("王哥", "从头讲。我随时打断。"),
            nav("你讲到第三页，他抬手。"),
            say("王哥", "“这里错了怎么办”——你刚才绕过去了。", emphasis=["绕过去了"]),
            nav("你停了两秒。这条线这几天确实不太稳，监控上偶尔跳一下。"),
            say("王哥", "不稳就说稳了？换一句。"),
            nav("你把那句改成：这一类会挂，挂了走备用流程。他点了下头，让你接着讲。"),
            nav("第五遍讲完，小林把计时器按停：九分四十。"),
            nav("收电脑的时候，你瞥见监控面板上那条演示线路又跳了一下。"),
            say("王哥", "今晚别关灯。周五之前，最怕它半夜自己动。", emphasis=["半夜自己动"]),
            nav("天暗下来的时候，整层只剩你这一排灯还亮着。"),
            nav(
                "你没走。先把这条线压住——明天下午两点，台上不能出事。",
                goalLine=True,
            ),
        ],
        "choices": [],
        "timeBand": "afternoon",
        "phase": "early",
        "reportUse": "story_only",
        "todayCard": {
            "title": "第五月 · 彩排",
            "lines": [
                "王哥当客户，把你问住了一次",
                "那问“这里错了怎么办”，台上得当场答",
                "今晚别关灯，这条线要盯住",
            ],
            "shots": ["place_card_tool_1.png"],
        },
        "walk": True,
        "walkNote": "回工位，王哥在等彩排",
    }


def build_dawn() -> dict:
    return {
        "id": "M05_DAWN",
        "month": 5,
        "order": 215,
        "nodeType": "main_story",
        "required": True,
        "title": "第二天早上",
        "locationId": "B",
        "location": "B 区 · 科技丘",
        "durationMinutes": 30,
        "situation": "weak",
        "autoComplete": True,
        "beats": [
            nav("你处理完的时候，天已经蒙蒙亮。趴在桌上又睡了三个小时，醒来是八点四十。"),
            nav("日历翻过去了。上旬过完了，今天是中旬第一天，周五。"),
            nav("王哥（手机 08:52）：记录我看了。今天你只管讲，线上我来盯。"),
            nav(
                "你的审批记录里还空着一段。你没敢往上翻。",
                when={"flag": "m05_night_hotfix_unlogged"},
            ),
            nav(
                "错误回复多留了三个半小时。这个数字，你今天得带进会场。",
                when={"flag": "m05_night_waited"},
            ),
            nav(
                "工单号还在手机里，03:01 填完的那张。你把它翻出来存进了备忘录。",
                when={"flag": "m05_night_incident_recorded"},
            ),
            nav("十一点半，你出门。会展码头在镇子最南边，坐车过去还要一段。"),
            nav(
                "十二点五十到码头，一点半进主厅。两点，麦在你手上。",
                goalLine=True,
            ),
        ],
        "choices": [],
        "timeBand": "morning",
        "phase": "mid",
        "reportUse": "story_only",
        "todayCard": {
            "title": "第五月 · 客户 Demo",
            "lines": [
                "八点四十醒，十一点半出门",
                "会展码头在镇子最南边",
                "两点上台 · 麦在你手上",
            ],
            "shots": ["place_card_expo_1.png"],
        },
        "walkNote": "出门，去南边的会展码头",
    }


EXPO_VISIT = {
    "name": "观澜会展码头",
    "object": "主厅那块大屏",
    "rowNote": "两点上台，屏幕不是我们的",
    "placeLine": "客户现场，第二组上台，主讲是你。",
    "card": {
        "title": "观澜会展码头",
        "lines": [
            "客户现场。镇子最南边，出门过码头广场。",
            "周五下午两点，第二组上台。屏幕是展厅的，接口自己带。",
            "去主厅那块大屏底下——麦在讲台边上。",
        ],
        "shots": ["place_card_expo_1.png"],
        "pages": 1,
    },
}


def main() -> int:
    data = load(EVENTS)
    nodes = data["nodes"]

    # ---- M05_OPEN：把"演讲要干什么"写进第一屏 ----
    open_node = find(nodes, "M05_OPEN")
    open_node.update(build_open())

    # ---- M05_PREP：周一 → 周四深夜之间的那一场戏 ----
    if find_optional(nodes, "M05_PREP") is None:
        open_index = nodes.index(open_node)
        nodes.insert(open_index + 1, build_prep())
    else:
        find(nodes, "M05_PREP").update(build_prep())

    # ---- M05_NIGHT：开头两拍承接彩排 ----
    night = find(nodes, "M05_NIGHT")
    rest = [
        beat
        for beat in night["beats"]
        if not String_starts(beat, "彩排完你没回去")
        and not String_starts(beat, "告警叠了四张，指向同一条线路——就是下午")
        and not String_starts(beat, "整层楼只剩一排灯亮着")
    ]
    night["beats"] = [
        nav("彩排完你没回去。外套垫在键盘上，睡到两点零七分，手机在耳边震。"),
        nav(
            "告警叠了四张，指向同一条线路——就是下午你讲了五遍的那条。明天下午两点，客户会看到它。"
        ),
    ] + rest

    # ---- M05_DAWN：旬在"过夜"这一拍翻，不再落在门口 ----
    if find_optional(nodes, "M05_DAWN") is None:
        night_index = nodes.index(night)
        nodes.insert(night_index + 1, build_dawn())
    else:
        find(nodes, "M05_DAWN").update(build_dawn())

    # ---- M05_DEMO：第一次去的地方，给讲解卡 + 黄线 + 按 E 进主厅 ----
    demo = find(nodes, "M05_DEMO")
    demo["enterPlace"] = "m5_expo"
    demo["doorHook"] = "door_expo"
    demo["visit"] = EXPO_VISIT
    demo["beats"][0] = nav(
        "两点差十分，主厅。展厅比想象的大，屏幕不是我们的。你们排第二组，"
        "前一组讲了二十分钟愿景，界面一次没打开。"
    )
    demo["walkNote"] = "去南边的会展码头"

    dump(EVENTS, data)

    # ---- manifest：nodeOrder 登记 ----
    manifest = load(MANIFEST)
    order = manifest["nodeOrder"]
    if "M05_PREP" not in order:
        order.insert(order.index("M05_OPEN") + 1, "M05_PREP")
    if "M05_DAWN" not in order:
        order.insert(order.index("M05_NIGHT") + 1, "M05_DAWN")
    dump(MANIFEST, manifest)

    print("第 5 月补桥完成：M05_OPEN %d 拍 / M05_PREP / M05_NIGHT %d 拍 / M05_DAWN / M05_DEMO(enterPlace)"
          % (len(open_node["beats"]), len(night["beats"])))
    return 0


def find_optional(nodes: list, node_id: str) -> dict | None:
    for node in nodes:
        if isinstance(node, dict) and node.get("id") == node_id:
            return node
    return None


def String_starts(beat, prefix: str) -> bool:
    return isinstance(beat, dict) and str(beat.get("text", "")).startswith(prefix)


if __name__ == "__main__":
    raise SystemExit(main())
