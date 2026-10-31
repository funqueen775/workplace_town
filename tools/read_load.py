#!/usr/bin/env python3
"""阅读负担体检：只读，只报可疑，不判对错。

对应《阅读负担与交互》§6：
  1. 每屏拍数与字数（>6 拍标可疑）
  2. 选项结果句超长（>60 字）
  3. 同月跨屏 4-gram 重复句对（复述嫌疑）
  4. 整屏没有一个 say（可能缺人）

    python tools/read_load.py                 # 全年
    python tools/read_load.py --month 2       # 只看第 2 月
    python tools/read_load.py --path X.json   # 改前/改后对比
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
DEFAULT = ROOT / "data/story/v12m/events.json"

BEAT_SOFT = 6
OUTCOME_SOFT = 60
DUP_N = 4


def sentences(text: str) -> list[str]:
    out, buf = [], []
    for ch in text:
        if ch in "。！？；":
            s = "".join(buf).strip()
            if len(s) >= 6:
                out.append(s)
            buf = []
        else:
            buf.append(ch)
    s = "".join(buf).strip()
    if len(s) >= 6:
        out.append(s)
    return out


def grams(text: str, n: int = DUP_N) -> set[str]:
    return {text[i:i + n] for i in range(max(0, len(text) - n + 1))}


def load(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return data["nodes"]


def report(nodes: list[dict], months: set[int] | None) -> None:
    rows = []
    for node in nodes:
        month = int(node.get("month", 0))
        if months and month not in months:
            continue
        beats = node.get("beats") or []
        chars = sum(len(b.get("text", "")) for b in beats)
        says = sum(1 for b in beats if b.get("type") == "say")
        outs = [len(c.get("outcome", "")) for c in (node.get("choices") or [])]
        rows.append({
            "id": node["id"], "month": month, "beats": len(beats),
            "chars": chars, "says": says, "outcomes": outs,
        })
    rows.sort(key=lambda r: (r["month"], -r["beats"]))

    by_month = defaultdict(lambda: {"nodes": 0, "beats": 0, "chars": 0, "outcomes": 0})
    print("月份  屏  拍   正文字  结果字")
    for r in rows:
        m = by_month[r["month"]]
        m["nodes"] += 1
        m["beats"] += r["beats"]
        m["chars"] += r["chars"]
        m["outcomes"] += sum(r["outcomes"])
    total = {"nodes": 0, "beats": 0, "chars": 0, "outcomes": 0}
    for month in sorted(by_month):
        m = by_month[month]
        for k in total:
            total[k] += m[k]
        print("%4d %3d %4d %7d %6d" % (month, m["nodes"], m["beats"], m["chars"], m["outcomes"]))
    print("合计 %3d %4d %7d %6d（屏均 %.1f 拍 / %.0f 字）" % (
        total["nodes"], total["beats"], total["chars"], total["outcomes"],
        total["beats"] / max(1, total["nodes"]), total["chars"] / max(1, total["nodes"])))

    print("\n[拍数 > %d]" % BEAT_SOFT)
    for r in rows:
        if r["beats"] > BEAT_SOFT:
            print("  %-16s 第%2d月 %2d 拍 %4d 字" % (r["id"], r["month"], r["beats"], r["chars"]))

    print("\n[结果句 > %d 字]" % OUTCOME_SOFT)
    hit = False
    for r in rows:
        for i, n in enumerate(r["outcomes"]):
            if n > OUTCOME_SOFT:
                print("  %-16s 选项%d %d 字" % (r["id"], i, n))
                hit = True
    if not hit:
        print("  无")

    print("\n[同月复述嫌疑：跨屏共享 4-gram ≥3]" % ())
    per_month = defaultdict(list)
    for node in nodes:
        month = int(node.get("month", 0))
        if months and month not in months:
            continue
        text = "".join(b.get("text", "") for b in (node.get("beats") or []))
        per_month[month].append((node["id"], text, grams(text)))
    flagged = False
    for month in sorted(per_month):
        items = per_month[month]
        for i in range(len(items)):
            for j in range(i + 1, len(items)):
                shared = items[i][2] & items[j][2]
                if len(shared) >= 3:
                    sample = "".join(sorted(shared))[:10]
                    print("  第%2d月 %-16s ↔ %-16s 共享 %2d 个 4-gram（%s…）"
                          % (month, items[i][0], items[j][0], len(shared), sample))
                    flagged = True
    if not flagged:
        print("  无")

    print("\n[整屏没有人物台词]")
    hit = False
    for r in rows:
        if r["says"] == 0:
            print("  %-16s 第%2d月 %2d 拍 %4d 字" % (r["id"], r["month"], r["beats"], r["chars"]))
            hit = True
    if not hit:
        print("  无")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--path", default=str(DEFAULT))
    ap.add_argument("--month", type=int)
    args = ap.parse_args()
    path = Path(args.path)
    if not path.is_absolute():
        path = (ROOT / path).resolve()
    nodes = load(path)
    print("阅读负担体检：%s\n" % path)
    report(nodes, {args.month} if args.month else None)
    return 0


if __name__ == "__main__":
    sys.exit(main())