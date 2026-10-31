#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""check_departure.py —— 全年「换区不必交待去向」审计。

口径：按 (month, order) 排出主流程，凡是相邻两个**有地点**的节点之间的区变了，
就检查这一段最后的台词有没有点出下一个地点。
跨月的首个场景单独归一类（中间有换月过场卡，优先级低）。

用法：
    python tools/check_departure.py            # 只列「没交代」的
    python tools/check_departure.py --all      # 全部（含已交代的）
    python tools/check_departure.py --json     # 机器可读
"""

import argparse
import json
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EVENTS = os.path.join(ROOT, "data", "story", "v12m", "events.json")

# 地点 -> 玩家听得懂的说法（任一命中即算交待了去向）
# 注意：别把「工位」「会议室」这种泛词单独放进来，太容易误判成已交待。
PLACE_TERMS = {
    "A 区总部": ["A 区", "总部", "工作区"],
    "A 总部 · 跨组周会": ["跨组周会", "周会", "A 区", "总部"],
    "A 区评审室": ["评审室", "A 区"],
    "A 区复盘会议室": ["复盘会议室", "复盘会", "复盘室", "A 区"],
    "A 区小会议室": ["小会议室", "A 区"],
    "A 区小会议室门外": ["小会议室门外", "小会议室", "A 区", "外面"],
    "A 区会议室": ["A 区会议室", "会议室", "A 区"],
    "A 区总部白板室": ["白板室", "A 区", "总部"],
    "A 区合规复盘室": ["合规复盘室", "复盘室", "合规"],
    "A 区公告栏": ["公告栏", "A 区"],
    "A 区大会议室门外": ["大会议室门外", "大会议室", "会议门外", "A 区"],
    "A 区小会议桌": ["小会议桌", "A 区"],
    "A 区大会议室": ["大会议室", "答辩", "A 区"],
    "B 区训练室门口": ["训练室", "B 区"],
    "B 区工位": ["回工位", "工位", "B 区"],
    "B 区工位 · 夜": ["工位", "B 区"],
    "B 区 · 科技丘": ["科技丘", "B 区"],
    "B 区楼层门口": ["楼层门口", "B 区", "楼下"],
    "C 区 创意水巷 · 客户展厅": ["客户展厅", "水巷", "展厅", "C 区"],
    "C 区 展厅门口": ["展厅", "水巷", "C 区", "门口"],
    "C 区水巷外摆": ["水巷", "咖啡", "C 区"],
    "D 区 树影书院二楼": ["书院二楼", "树影书院", "书院", "二楼", "D 区"],
    "树影书院 · 长桌": ["长桌", "树影书院", "书院", "D 区"],
    "树影书院 · 阅览室": ["阅览室", "树影书院", "书院", "D 区"],
    "心湖北岸记忆墙": ["记忆墙", "北岸", "心湖"],
    "心湖木栈道": ["木栈道", "湖", "心湖"],
    "观澜会展码头": ["码头", "会展", "观澜"],
}


def last_lines(node, n=2):
    """源节点收尾：最后 n 拍台词 + 各选项 outcome 首句。"""
    out = []
    beats = node.get("beats") or []
    for tail in beats[-n:]:
        txt = tail.get("text") or ""
        if txt:
            out.append(("beat", tail.get("speaker") or "旁白", txt))
    for ch in node.get("choices") or []:
        for key in ("outcome", "result", "text"):
            v = ch.get(key)
            if isinstance(v, str) and v:
                out.append(("choice", ch.get("label") or "", v))
                break
            if isinstance(v, list) and v:
                first = v[0]
                t = first.get("text") if isinstance(first, dict) else str(first)
                if t:
                    out.append(("choice", ch.get("label") or "", t))
                break
    return out


def first_lines(node, n=1):
    """目标节点开场第一句，用来认「到了之后有人接一句」。"""
    out = []
    for head in (node.get("beats") or [])[:n]:
        txt = head.get("text") or ""
        if txt:
            out.append(("beat", head.get("speaker") or "旁白", txt))
    return out


def zone_words(location):
    """目标地点在台词里可能被怎么称呼。表里没有的用去掉区名前缀后的核心词兜底。"""
    if not location:
        return []
    words = list(PLACE_TERMS.get(location) or [])
    if words:
        return words
    core = location
    for pref in ("A 区", "B 区", "C 区", "D 区", "E 区", "F 区", "A 总部"):
        core = core.replace(pref, "")
    core = core.replace(" ", "").lstrip("·")
    return [core] if core else [location]


def norm_loc(loc):
    """「B 区工位 · 夜」和「B 区工位」是同一个地方，只差昼夜。"""
    s = (loc or "").replace("· 夜", "").replace("·夜", "")
    return " ".join(s.split()).strip()


# 回工位属于默认动作，玩家不难判断，单列一类、不计缺口
HOME_LOCS = {"B 区工位", "B 区工位 · 夜"}

# 人工判过、不需要再补台词的节点对（换区但去向另有渠道说清）
KNOWN_OK = {
    ("M05_NIGHT", "M05_DEMO"): "上一幕 M05_OPEN 末拍与今日卡已写明「下午到会展码头」",
    ("M05_DEMO", "M05_COFFEE"): "咖啡邀约是玩家主动发起的可选活动，不是被叫去",
    ("M09_CONTRIB", "M09_LIBRARY_SOCIAL"): "去书院由玩家主动触发（visit_9_m9_library）",
    ("M12_FEEDBACK", "E50_slide"): "两条分支互斥（m12_not_nominated），玩家不会从反馈桌走到答辩席",
    ("M05_PREP", "M05_NIGHT"): "同一晚同一处（工位熬夜彩排），地点标注不同但人没挪窝",
}


def ui_hints(node):
    """界面上另外两条渠道：走位提示与今日卡。"""
    lines = []
    wn = node.get("walkNote")
    if wn:
        lines.append(("walkNote", wn))
    for l in ((node.get("todayCard") or {}).get("lines") or []):
        lines.append(("todayCard", l))
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--all", action="store_true", help="连已交待的一起列")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--by", choices=["place", "zone"], default="place",
                    help="place=按具体地点比（默认，能抓同区换房间）；zone=只按区分")
    ap.add_argument("--month", type=int, default=0, help="只看某个月，并打印该月完整链路")
    args = ap.parse_args()

    data = json.load(open(EVENTS, encoding="utf-8"))
    nodes = [n for n in data["nodes"]]
    nodes = sorted(nodes, key=lambda n: (n.get("month") or 0, n.get("order") or 0))

    def key_of(n):
        if args.by == "zone":
            return n.get("locationId")
        return norm_loc(n.get("location")) or n.get("locationId")

    rows = []
    prev = None          # 上一个有地点的节点
    mid = []             # prev 之后到当前之前的所有节点
    for n in nodes:
        if not n.get("locationId"):
            if prev:
                mid.append(n)
            continue
        if prev is not None and key_of(prev) != key_of(n):
            same_month = (prev.get("month") == n.get("month"))
            same_zone = (prev.get("locationId") == n.get("locationId"))
            # 候选交代句：prev 的末句 + 中间节点的末句 + 目标首句
            cands = last_lines(prev) + [x for m in mid for x in last_lines(m, 1)] + first_lines(n)
            words = zone_words(n.get("location"))
            hit = None
            for kind, speaker, text in reversed(cands):
                for w in words:
                    if w in text:
                        hit = (speaker, text, w)
                        break
                if hit:
                    break
            known = KNOWN_OK.get((prev["id"], n["id"]))
            ui = None
            for _k, tx in ui_hints(n):
                for w in words:
                    if w in tx:
                        ui = (w, tx)
                        break
                if ui:
                    break
            home = n.get("location") in HOME_LOCS
            rows.append({
                "from": prev["id"],
                "from_month": prev.get("month"),
                "from_loc": prev.get("location"),
                "to": n["id"],
                "to_month": n.get("month"),
                "to_loc": n.get("location"),
                "same_month": same_month,
                "cross_month": not same_month,
                "same_zone": same_zone,
                "home": home,
                "ui": ui,
                "ok": bool(hit),
                "hit": hit,
                "known": known,
                "tail": cands[-1] if cands else None,
                "via": [m["id"] for m in mid],
            })
        prev = n
        mid = []

    def pri(r):
        if r["home"]:
            return 4          # 回工位，默认动作
        if r["same_month"] and not r["same_zone"]:
            return 1          # 同月跨区：一定要说
        if r["same_month"] and r["same_zone"]:
            return 2          # 同月同区换房间
        return 3              # 跨月，有换月过场卡

    bad = [r for r in rows if not r["ok"] and not r["known"]]
    n_known = len([r for r in rows if not r["ok"] and r["known"]])
    if args.month:
        bad = [r for r in bad if r["from_month"] == args.month or r["to_month"] == args.month]

    if args.json:
        print(json.dumps({"missing": bad, "all": rows}, ensure_ascii=False, indent=1))
        return

    if args.month:
        print("=" * 78)
        print("第 %d 月场景链路" % args.month)
        print("=" * 78)
        for n in nodes:
            if n.get("month") != args.month:
                continue
            loc = n.get("location") or "(不占地点)"
            lines = last_lines(n, 1)
            tail = lines[-1][2] if lines else ""
            print("  %-16s %-22s %s" % (n["id"], loc, tail[:46]))
        print()

    p1 = [r for r in bad if pri(r) == 1]
    p2 = [r for r in bad if pri(r) == 2]
    p3 = [r for r in bad if pri(r) == 3]
    p4 = [r for r in bad if pri(r) == 4]
    print("=" * 78)
    print("比对粒度：%s；场景转换 %d 处，没有交待去向 %d 处"
          % ("具体地点" if args.by == "place" else "只按区", len(rows), len(bad)))
    print("  （另有 %d 处经人工判定无需补台词，见 KNOWN_OK）" % n_known)
    print("  P1 同月·跨区          : %d" % len(p1))
    print("  P2 同月·同区换房间    : %d" % len(p2))
    print("  P3 跨月首个场景       : %d" % len(p3))
    print("  P4 回工位（一般不用管）: %d" % len(p4))
    print("=" * 78)

    def show(r):
        tag = {1: "P1", 2: "P2", 3: "P3", 4: "P4"}[pri(r)]
        print("\n【%s】%s(%s月 %s)  →  %s(%s月 %s)" % (
            tag, r["from"], r["from_month"], r["from_loc"],
            r["to"], r["to_month"], r["to_loc"]))
        if r["via"]:
            print("   中间夹着：%s" % " → ".join(r["via"]))
        print("   要的点（任一即可）：%s" % "/".join(zone_words(r["to_loc"])))
        kind, speaker, text = r["tail"]
        print("   末句（%s·%s）：%s" % (kind, speaker, text))
        if r["ui"]:
            print("   界面另有提示（命中「%s」）：%s" % (r["ui"][0], r["ui"][1]))
        if r["known"]:
            print("   ○ 已确认为无需补台词：%s" % r["known"])
        if r["ok"]:
            sp, tx, w = r["hit"]
            print("   ✔ 台词已交代（命中「%s」）：%s：%s" % (w, sp, tx))

    for group, title in ((p1, "P1 同月·跨区 —— 一定要说"),
                         (p2, "P2 同月·同区换房间 —— 说清楚是哪间"),
                         (p3, "P3 跨月首个场景 —— 有换月过场卡，视需要"),
                         (p4, "P4 回工位 —— 通常不用管")):
        if not group:
            continue
        print("\n" + "-" * 78)
        print(title)
        for r in group:
            show(r)
    return


if __name__ == "__main__":
    main()
