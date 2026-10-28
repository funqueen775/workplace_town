"""把跳月截图压成一小批内联用的 JPEG（画廊片段要塞进 1MB 以内）。

用法：python tools/jump_gallery_build.py
输出：test_artifacts/v12m_jump/gallery.html（内嵌 base64，平板可直接看）
"""
from __future__ import annotations

import base64
import io
import sys
from pathlib import Path

try:
    from PIL import Image
except Exception as exc:  # noqa: BLE001
    print("没装 Pillow，压不了图：", exc)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "test_artifacts" / "v12m_jump" / "web"
OUT = ROOT / "test_artifacts" / "v12m_jump" / "gallery.html"

# (文件, 标题, 一句话说明)
PICKS = [
    ("m02_01_开场.jpg", "第 2 月 · 开场", "翻月卡 + 本月主线卡，直接跳到这一天的样子"),
    ("m03_50_E10_三选一.jpg", "第 3 月 · 客户那一问", "三个选择摆在下面，画线那个词是能点的行话"),
    ("m04_01_开场.jpg", "第 4 月 · 开场", "安静月：没有门，只有一件事要办"),
    ("m05_70_自由活动.jpg", "第 5 月 · 自己安排", "门口亮了、任务卡写还剩几格，去不去都算过"),
    ("m06_50_M06_DEF1_三选一.jpg", "第 6 月 · 转正答辩", "第一次评估：一问一屏，答辩不挂能力点"),
    ("m07_50_E19_三选一.jpg", "第 7 月 · 事故复盘", "选 A 或 B 就把「表达」点亮到第 5 格（熊熊有招）"),
    ("m07_95_档案五格.jpg", "第 7 月 · 档案页", "表达五格满，其余按攒点长——原则到第 4 格停住"),
    ("m09_01_开场.jpg", "第 9 月 · 开场", "这一月的三个选择决定第 10 月谁能来问你"),
    ("m10_40_M10_OPEN_剧情.jpg", "第 10 月 · 那张新椅子", "许棠照你的交接文档做事，还补了一条——协作亮到顶"),
    ("m10_95_档案五格.jpg", "第 10 月 · 档案页", "表达 / 协作 / 原则三格到顶，技术还停在第 2 格"),
    ("m11_70_自由活动.jpg", "第 11 月 · 自己安排", "旧门一直开着，这一月还能再去三处"),
    ("m12_40_M12_OPEN_剧情.jpg", "第 12 月 · 前一晚", "小赵把你的架构图扫进答辩材料——技术亮到顶"),
    ("m12_95_档案五格.jpg", "第 12 月 · 档案页", "四格到顶、抗压一格全年不亮（它的意思就是没人来问这个）"),
]


def shrink(name: str, width: int = 760, quality: int = 50) -> bytes:
    src = WEB / name
    if not src.exists():
        print("缺图：", src)
        return b""
    with Image.open(src) as im:
        im = im.convert("RGB")
        im.thumbnail((width, width * 9 // 16 * 2), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, format="JPEG", quality=quality, optimize=True)
        return buf.getvalue()


def main() -> None:
    cells = []
    total = 0
    for name, title, note in PICKS:
        blob = shrink(name)
        if not blob:
            continue
        total += len(blob)
        b64 = base64.b64encode(blob).decode("ascii")
        cells.append(
            '<figure style="margin:0 0 18px 0"><figcaption style="font:600 15px/1.5 '
            'system-ui,-apple-system,\"Microsoft YaHei\",sans-serif;color:#2f2a24;margin:0 0 4px 0">'
            f'{title}</figcaption><img alt="{title}" src="data:image/jpeg;base64,{b64}" '
            'style="width:100%;height:auto;border-radius:10px;border:1px solid #d9cdb8;display:block">'
            '<p style="font:13px/1.6 system-ui,-apple-system,\"Microsoft YaHei\",sans-serif;'
            f'color:#6a5f52;margin:6px 0 0 0">{note}</p></figure>'
        )
    grid = (
        '<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));'
        'gap:18px;max-width:1180px">' + "".join(cells) + "</div>"
    )
    OUT.write_text(grid, encoding="utf-8")
    print(f"图片 {len(cells)} 张，原始 {total/1024:.0f}KB，base64 后 {total*4/3/1024:.0f}KB -> {OUT}")


if __name__ == "__main__":
    main()
