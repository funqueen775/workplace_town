#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 12 张自由活动面板图拆成可复用的零件（2026-10-31）。

为什么要拆：美术给的 `assets/01_带缩略图面板/*.png` 是整卡，区名、活动名、
一句话、消耗数字全烙在图上。可图上的区名走的是一套八部门口径（E=财务部、
F=运营部、G=行政部、H=生产部），而游戏里 E–H 是心湖步道 / 松风训练谷 /
慢生活园这些地点，不是部门；活动名也有对不上的（图上"小馆咖啡聊天"，
数据里"销售部外摆"）。整卡直接上界面，玩家看到的字就和 JSON 里的账打架。

所以这里只取图上不会错的两样——缩略图和蜂蜜罐图标——其余文字一律由
ActivityCardList 按 activities.json 现画。图重画了跑一遍这个脚本就行。

用法：python tools/v12m_cut_activity_cards.py
输出：assets/ui/activity_cards/thumb_<KEY>.png + honey_jar.png
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "assets" / "01_带缩略图面板"
OUT_DIR = ROOT / "assets" / "ui" / "activity_cards"

# 12 张图共用同一套版式（画布 1200×340，卡身 (15,15)-(1183,321)），
# 下面两个框是在 C_COFFEE 上按像素描出来的，其余 11 张逐一对过。
# 缩略图那圈描边的上沿在 y=104——再往上就是绿区名牌的底，别把牌子切进来。
THUMB_BOX = (62, 102, 457, 292)  # 左侧缩略图（含它自己那圈圆角描边）
JAR_BOX = (1018, 138, 1095, 232)  # 右侧消耗栏里的蜂蜜罐


def card_key(path: Path) -> str:
    """文件名 `<区>_<活动>_<中文名>_面板.png` → `<区>_<活动>`。"""
    parts = path.stem.split("_")
    if len(parts) < 2:
        raise ValueError(f"文件名对不上版式：{path.name}")
    return f"{parts[0]}_{parts[1]}"


def main() -> int:
    if not SRC_DIR.is_dir():
        print(f"[跳过] 找不到素材目录：{SRC_DIR}")
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    written = 0
    for src in sorted(SRC_DIR.glob("*.png")):
        with Image.open(src) as im:
            if im.size != (1200, 340):
                print(f"[警告] {src.name} 尺寸是 {im.size}，不是 1200×340，跳过")
                continue
            key = card_key(src)
            out = OUT_DIR / f"thumb_{key}.png"
            im.convert("RGBA").crop(THUMB_BOX).save(out)
            written += 1
            print(f"[缩略图] {key:<10} -> {out.relative_to(ROOT).as_posix()}")

    first = sorted(SRC_DIR.glob("*.png"))
    if first:
        with Image.open(first[0]) as im:
            jar = OUT_DIR / "honey_jar.png"
            im.convert("RGBA").crop(JAR_BOX).save(jar)
            print(f"[图标]   honey_jar -> {jar.relative_to(ROOT).as_posix()}")

    if written == 0:
        print("[失败] 一张都没切出来")
        return 1
    print(f"\n完成：{written} 张缩略图 + 1 个消耗图标 -> {OUT_DIR.relative_to(ROOT).as_posix()}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
