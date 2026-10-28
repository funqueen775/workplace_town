# -*- coding: utf-8 -*-
"""第 3 月第一次校验的五处修正。

1. 月末小赵那条按选择变文案：三个节点合成一个节点，三条消息各挂一个 when，
   整月仍然只算两批（手机上限）。
2. 水巷那扇门改为挂在散会那句台词的钩子上。
3. 补记录那一拍挪回上旬（夜里），否则"上旬末 → 中旬"被校验器判时间倒流。
4. 第 2 月两处时间倒流是并行改动刚带进来的，机械修正旬位。
"""
from __future__ import annotations

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
EV = ROOT / "data/story/v12m/events.json"
AC = ROOT / "data/story/v12m/activities.json"
MF = ROOT / "data/story/v12m/manifest.json"


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def save(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    ev, ac, mf = load(EV), load(AC), load(MF)
    nodes = ev["nodes"]
    by_id = {n["id"]: n for n in nodes}

    variants = [
        ("M03_PHONE_A", "m03_e10_truth_with_fallback", "m03_wrap_a",
         "客户那边居然签了。你怎么想到当面把话说开？"),
        ("M03_PHONE_B", "m03_e10_soft_clause", "m03_wrap_b",
         "“尽商业上合理努力”……我查了半天才知道这词什么意思。"),
        ("M03_PHONE_C", "m03_e10_overpromise", "m03_wrap_c",
         "听说小林回来脸色不太对。今天回去会不会不太好？"),
    ]
    if all(vid in by_id for vid, *_ in variants):
        anchor = by_id["M03_PHONE_A"]
        merged = {
            "id": "M03_PHONE_3", "month": 3, "order": 240, "nodeType": "phone_batch",
            "required": False, "batchId": "m03_batch_xiaozhao",
            "senderId": "xiao_zhao", "senderName": "小赵", "senderRole": "同事",
            "messages": [
                {"id": mid, "text": text, "when": {"flag": flag}}
                for _, flag, mid, text in variants
            ],
            "timeBand": anchor["timeBand"], "phase": anchor["phase"],
            "reportUse": "story_only", "deliveredDuring": "M03_CLOSE",
            "day": anchor["day"], "hour": anchor["hour"],
        }
        ev["nodes"] = [n for n in nodes if n["id"] not in {v[0] for v in variants}]
        ev["nodes"].append(merged)
        by_id = {n["id"]: n for n in ev["nodes"]}
        order = [nid for nid in mf["nodeOrder"] if nid not in {v[0] for v in variants}]
        order.append("M03_PHONE_3")
        mf["nodeOrder"] = order
        print("月末消息合成一个节点，三条消息各挂一个旗标")

    water = next((a for a in ac["activities"] if a.get("id") == "m3_waterway"), None)
    if water is not None:
        water.pop("unlockAfter", None)
        water["unlockHook"] = "unlock_waterway"
        print("水巷改为挂在散会台词的钩子上")

    bridge = by_id.get("M03_BRIDGE")
    if bridge is not None and bridge.get("phase") == "late":
        bridge["phase"] = "early"
        bridge["timeBand"] = "night"
        print("补记录那一拍改回上旬（夜里）")

    week7 = by_id.get("M02_WEEK_7")
    if week7 is not None and week7.get("phase") == "early":
        week7["phase"] = "mid"
        print("第 2 月 WEEK_7 旬位修正：早 → 中")

    handbook2 = by_id.get("M02_HANDBOOK_2")
    if handbook2 is not None and handbook2.get("phase") == "early":
        handbook2["phase"] = "late"
        print("第 2 月手册页旬位修正：早 → 下")

    save(EV, ev)
    save(AC, ac)
    save(MF, mf)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
