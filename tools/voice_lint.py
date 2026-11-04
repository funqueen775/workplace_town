#!/usr/bin/env python3
"""对白节奏体检：只读，不算分，只把「读起来像机器」的量化特征摆出来。

对着《对白与文风》§2 的三条：句子有长短、一个 beat 不超过三句、不许连续三句都是
四到八字的电报。外加一张禁用句式黑名单。

    python tools/voice_lint.py                          # 体检 data/story/v12m/events.json
    python tools/voice_lint.py --path X.json            # 体检别的文件（做改前/改后对比）
    python tools/voice_lint.py --strict                 # 命中黑名单或长串短句时非零退出

说明：好坏没法机检。这里只筛「五六个字断一下」这类可数的毛病；主语、语序、人物声线
仍然要人读。lint 过了不等于写得好，lint 不过基本就是没写好。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
DEFAULT = ROOT / "data/story/v12m/events.json"

SHORT = 8  # 八字以内算短句
MAX_SENTENCES = 3  # 一个 beat 最多三句
SHORT_RUN = 3  # 连续三句短句算电报

## 禁用句式：读起来最像机器的那几种（《对白与文风》§4）。
## 只收「几乎不可能出现在正常口语里」的模式；「X 是 Y」这种判断句太常见，
## 会淹掉真问题，交给人工读，不进 lint。
BLACKLIST = [
    (r"到这儿[，,。]?\s*$", "段末收口「到这儿」"),
    (r"有收获了", "段末拔高「有收获了」"),
    (r"(依赖|退路|名单|纪要|表|曲线|材料)[^，。]{0,6}[，,]\s*(各|都|一律)[^，。]{0,8}[。]", "名词句 + 清单式罗列"),
    (r"你听出来了吧", "旁白替玩家解释潜台词"),
    (r"你意识到", "旁白替玩家下结论"),
    (r"按当时的选择显示|以外网?实际反馈为准|不自动判", "设计说明漏进玩家文本"),
]

SPLIT = re.compile(r"[。！？；…]+")


def sentences(text: str) -> list[str]:
    return [s.strip("，、, 　\"“”「」") for s in SPLIT.split(text) if s.strip("，、, 　\"“”「」")]


def iter_texts(node: dict):
    for beat in node.get("beats") or []:
        if beat.get("text"):
            yield "beat", str(beat["text"])
    for stop in node.get("stops") or []:
        for beat in stop.get("beats") or []:
            if beat.get("text"):
                yield f"stop:{stop.get('id')}", str(beat["text"])
    for choice in node.get("choices") or []:
        if choice.get("text"):
            yield "choice", str(choice["text"])
        if choice.get("outcome"):
            yield "outcome", str(choice["outcome"])
    if node.get("departNote"):
        yield "departNote", str(node["departNote"])
    for line in (node.get("todayCard") or {}).get("lines") or []:
        yield "todayCard", str(line)


def audit(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = []
    total_sent = total_short = 0
    black_hits = []
    for node in data.get("nodes") or []:
        node_sent = node_short = 0
        worst_run = 0
        long_beat = 0
        for where, text in iter_texts(node):
            sents = sentences(text)
            if not sents:
                continue
            node_sent += len(sents)
            run = 0
            for s in sents:
                if len(s) <= SHORT:
                    node_short += 1
                    run += 1
                    worst_run = max(worst_run, run)
                else:
                    run = 0
            if len(sents) > MAX_SENTENCES:
                long_beat += 1
            for pattern, label in BLACKLIST:
                if re.search(pattern, text):
                    black_hits.append((str(node.get("id")), where, label, text))
        total_sent += node_sent
        total_short += node_short
        rows.append({
            "id": str(node.get("id")),
            "month": int(node.get("month", 0)),
            "sents": node_sent,
            "short": node_short,
            "ratio": (node_short / node_sent) if node_sent else 0.0,
            "run": worst_run,
            "long_beat": long_beat,
        })
    rows.sort(key=lambda r: (-r["ratio"], r["month"]))
    return {
        "rows": rows,
        "sents": total_sent,
        "short": total_short,
        "ratio": (total_short / total_sent) if total_sent else 0.0,
        "black": black_hits,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", type=Path, default=DEFAULT)
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--top", type=int, default=12, help="列前 N 个短句最多的节点")
    args = parser.parse_args()

    result = audit(args.path)
    print(f"对白体检：{args.path}")
    print(f"句子 {result['sents']} 句，八字以内 {result['short']} 句，占比 {result['ratio']:.1%}")
    print(f"禁用句式命中 {len(result['black'])} 处\n")
    print(f"{'节点':<16}{'月':>3}{'句':>5}{'短':>5}{'占比':>7}{'连短':>5}{'超三句':>7}")
    for row in result["rows"][: args.top]:
        print(f"{row['id']:<16}{row['month']:>3}{row['sents']:>5}{row['short']:>5}"
              f"{row['ratio']:>6.0%}{row['run']:>5}{row['long_beat']:>7}")

    if result["black"]:
        print("\n禁用句式：")
        for node_id, where, label, text in result["black"]:
            print(f"  {node_id} {where}｜{label}｜{text}")

    bad = [r for r in result["rows"] if r["run"] >= SHORT_RUN]
    if bad:
        print("\n连续三句以上都是短句（读起来像电报）：")
        for row in bad:
            print(f"  {row['id']}（第 {row['month']} 月）最长连短 {row['run']} 句")

    if args.strict and (result["black"] or bad):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())