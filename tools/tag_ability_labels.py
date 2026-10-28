# -*- coding: utf-8 -*-
"""给第 1、2 月的必玩选项补能力标签（第 3 月铺数据时已经带了）。

规则同步进校验器：三选一的必玩选项必须显式写能力标签，
允许写空——"这一选什么都不长"也是一个决定，但不能不填。
"""
from __future__ import annotations

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
EV = ROOT / "data/story/v12m/events.json"

ASSIGN = {
    ("E02", "A"): {"expression": 2},   # 会上把话说开
    ("E02", "B"): {"integrity": 2},    # 会后留下署名记录
    ("E02", "C"): {"resilience": 1},   # 憋着把这轮做完
    ("E04", "A"): {"technical": 2},    # 两条路线各写一版小样
    ("E04", "B"): {"technical": 1},    # 先跑通，但没补验证
    ("E04", "C"): {"collaboration": 2},  # 把事故单和陈工的经验捞出来用
    ("E03", "A"): {"integrity": 2},    # 工具参与写清楚
    ("E03", "B"): {},                  # 删掉说明：什么都不长，这是显式决定
    ("E03", "C"): {},                  # 含糊带过：同上
}


def main() -> int:
    ev = json.loads(EV.read_text(encoding="utf-8"))
    filled = 0
    for node in ev["nodes"]:
        for choice in node.get("choices", []) or []:
            key = (str(node["id"]), str(choice.get("id")))
            if key in ASSIGN and "abilityTags" not in choice:
                choice["abilityTags"] = ASSIGN[key]
                filled += 1
    EV.write_text(json.dumps(ev, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("补了 %d 个选项的能力标签" % filled)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
