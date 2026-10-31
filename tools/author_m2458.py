#!/usr/bin/env python3
"""第 2、4、5、8 月的剧情册对齐修补。

改四类问题：
  1) 条件拍引用了全年没人写的旗标（手册读没读、第 3 月 E10 的旗标名打错）
  2) 剧情册写了、数据里丢掉的记录字段（生命 / CFC / 关系 / 册子里的规范旗标名）
  3) 剧情册要求的跨月回响（E12.C 在第四月、E23.A+E25.A 才改派接口负责人）
  4) 第 5 月水巷那一眼的三选一（只记记忆标签，不给数值）
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/story/v12m/events.json"
MANIFEST = ROOT / "data/story/v12m/manifest.json"


def flags_of(node_id: str, choice_id: str) -> dict[str, list[str]]:
    return {node_id: [choice_id]}


# 1) 旗标名改对：条件拍引用的必须是引擎或某个选项真会写的名字
FIX_REF = {
    "m01_handbook_read": "handbook_page_1.2",
    "m03_e05_soft_clause": "m03_e10_soft_clause",
}

# 2) 每个选项要补记的字段（剧情册 02 表里写了、数据里没落的那些）
EXTRA_FLAGS = {
    "E05": {
        "A": ["life_minus1", "cfc_plus2", "client_phase2_deferred", "schedule_owner_wang_ge"],
        "B": ["cfc_minus2"],
        "C": [],
    },
    "E07": {
        "A": ["xiao_lin_rel_minus1"],
        "B": [],
        "C": ["xiao_lin_rel_minus2"],
    },
    "M05_NIGHT": {
        "A": ["incident_recorded"],
        "B": ["incident_unlogged"],
        "C": ["incident_waited"],
    },
    "M05_DEMO": {
        "A": ["e17_admitted_error"],
        "B": ["e17_blame_network"],
        "C": ["e17_continue"],
    },
}

# 3) 跨月回响：E12.C（只在文档里加了一行加粗提示）在第四月以"资料缺口"回来
E12_ECHO = {
    "type": "narration",
    "text": "还是那两条没人能复现。你上个月在那份《常见问题》里加过一行加粗提示——结论写上了，怎么得出的没写。",
    "when": {"flag": "m03_e12_bold_note"},
}

# 4) 第 5 月水巷那一眼：三种回应只记标签，不给好感或属性
M05_COFFEE = {
    "id": "M05_COFFEE",
    "month": 5,
    "order": 242,
    "nodeType": "main_story",
    "required": False,
    "title": "门口那个人",
    "locationId": "C",
    "location": "C 区水巷外摆",
    "durationMinutes": 10,
    "situation": "weak",
    "autoComplete": False,
    "beats": [
        {"type": "narration", "text": "你坐下，抬头看见一位认识的同事端着咖啡站在门口。对方还没看见你。"},
    ],
    "choices": [
        {
            "id": "A",
            "text": "招呼他坐过来",
            "outcome": "外摆的椅子有点晃，咖啡一般，但话比咖啡多。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m05_coffee_social_invited"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "B",
            "text": "点点头",
            "outcome": "对方点头坐下，聊了两句别的组的事。椅子还是有点晃。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m05_coffee_social_nodded"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
        {
            "id": "C",
            "text": "低头看手机",
            "outcome": "那一格空着，咖啡喝完你就回去了。",
            "apCost": 0,
            "stateDelta": {},
            "riskDelta": 0,
            "flags": ["m05_coffee_social_avoided"],
            "abilityTags": {},
            "reportUse": "story_only",
        },
    ],
    "timeBand": "afternoon",
    "phase": "mid",
    "reportUse": "story_only",
    "zoneCut": "C",
    "when": {"flag": "visit_5_m3_waterway"},
}

# 5) 第 8 月：只有"选大重构"和"当场上报"同时发生，才改派接口负责人、排期顺延 7 天
M08_COMBINED_CARD = {
    "when": {"allOf": ["m08_e23_refactor", "m08_e25_reported"]},
    "text": "两件事叠在一处：接口负责人改派了，重构排期往后顺延 7 天。",
}


def main() -> None:
    payload = json.loads(DATA.read_text(encoding="utf-8"))
    nodes: list[dict] = payload["nodes"]
    by_id = {str(n.get("id")): n for n in nodes}
    log: list[str] = []

    # 1) 条件拍里的旗标名
    text = json.dumps(nodes, ensure_ascii=False)
    for old, new in FIX_REF.items():
        text = text.replace('"%s"' % old, '"%s"' % new)
    nodes = json.loads(text)
    by_id = {str(n.get("id")): n for n in nodes}
    log.append("旗标名改对 %d 处" % len(FIX_REF))

    # 首月手册"没读"那一版：从"存在 unread 旗标"改成"没有 read 旗标"
    e03 = by_id.get("E03", {})
    for beat in e03.get("beats", []) or []:
        when = beat.get("when")
        if isinstance(when, dict) and when.get("flag") == "handbook_page_1.2":
            continue
        if isinstance(when, dict) and when.get("flag") == "m01_handbook_unread":
            beat["when"] = {"notFlag": "handbook_page_1.2"}
            log.append("E03 的「没细看」那一拍改成 notFlag")

    # 2) 补记字段
    for node_id, per_choice in EXTRA_FLAGS.items():
        node = by_id.get(node_id)
        if node is None:
            log.append(f"找不到节点 {node_id}")
            continue
        for choice in node.get("choices", []) or []:
            cid = str(choice.get("id"))
            for flag in per_choice.get(cid, []):
                flags = choice.setdefault("flags", [])
                if flag not in flags:
                    flags.append(flag)
        log.append(f"{node_id} 补齐记录字段")

    # 3) E12.C 的第四月回响：插在"剩下 2 条没人能复现"那句后面
    m04 = by_id.get("M04_OPEN")
    if m04 is not None and not any(str(b.get("text", "")).startswith(E12_ECHO["text"][:12]) for b in m04["beats"]):
        beats = m04["beats"]
        at = 1
        for i, beat in enumerate(beats):
            if "没人能复现" in str(beat.get("text", "")):
                at = i + 1
                break
        beats.insert(at, E12_ECHO)
        log.append("M04_OPEN 补 E12.C 回响")

    # 4) 水巷那一眼
    if "M05_COFFEE" not in by_id:
        i = nodes.index(by_id["M05_FREE"])
        nodes.insert(i + 1, M05_COFFEE)
        log.append("新增 M05_COFFEE（水巷三选一）")

    # 5) 第 8 月双条件卡
    m08 = by_id.get("M08_CLOSE")
    if m08 is not None and not any((c.get("when") or {}).get("allOf") for c in m08.get("cards", []) or []):
        m08["cards"].append(M08_COMBINED_CARD)
        log.append("M08_CLOSE 补「重构 + 上报」那张卡")

    payload["nodes"] = nodes
    DATA.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    order = [str(x) for x in manifest.get("nodeOrder", [])]
    if "M05_COFFEE" not in order:
        manifest["nodeOrder"] = order + ["M05_COFFEE"]
        MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for line in log:
        print("·", line)


if __name__ == "__main__":
    main()
