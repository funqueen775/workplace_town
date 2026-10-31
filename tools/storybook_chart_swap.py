"""把重新生成的六张分支图换回剧情册.docx 里已嵌入的那六张（只替换字节并按新宽高改尺寸）。"""
import shutil
import sys
import time
from pathlib import Path

from PIL import Image
from docx import Document
from docx.oxml.ns import qn

DOCX = Path(r"E:\03_Projects\bear\剧情册.docx")
CHARTS = Path(r"E:\03_Projects\bear\workplace_town\test_artifacts\storybook_charts")
BAK_DIR = CHARTS.parent.parent

FILES = [
    "chart1_m1_m2.png",
    "chart2_m3.png",
    "chart3_m4_m5.png",
    "chart4_m6.png",
    "chart5_m7_m8.png",
    "chart6_m9_m12.png",
]

CAPTION_FIX = [
    ("图 4｜第 6 月：一场答辩，三种第七月", "图 4｜第 6 月：一次判定，两条路 + 一条线"),
]

W_EXT = qn("wp:extent")
A_EXT = qn("a:ext")
A_BLIP = qn("a:blip")
R_EMBED = qn("r:embed")


def main():
    apply = "--apply" in sys.argv
    doc = Document(str(DOCX))

    for old, new in CAPTION_FIX:
        hits = []
        for p in doc.element.body.iter(qn("w:p")):
            text = "".join(t.text or "" for t in p.iter(qn("w:t")))
            if old in text:
                hits.append(p)
        if len(hits) != 1:
            raise SystemExit(f"[中止] 图注应 1 处，实际 {len(hits)}：{old}")
        if apply:
            for t in hits[0].iter(qn("w:t")):
                if old in (t.text or ""):
                    t.text = t.text.replace(old, new)
        print(f"  图注  {new}")

    picture_paras = [p for p in doc.element.body.iter(qn("w:p"))
                     if any(True for _ in p.iter(A_BLIP))]
    if len(picture_paras) != len(FILES):
        raise SystemExit(f"[中止] 找到 {len(picture_paras)} 张图，应为 {len(FILES)} 张")

    for para, filename in zip(picture_paras, FILES):
        image_path = CHARTS / filename
        if not image_path.exists():
            raise SystemExit(f"[中止] 缺图：{image_path}")
        blip = next(para.iter(A_BLIP))
        part = doc.part.related_parts[blip.get(R_EMBED)]
        with Image.open(image_path) as im:
            w, h = im.size
        ext = next(iter(para.iter(W_EXT)), None)
        if ext is None:
            raise SystemExit(f"[中止] {filename} 找不到 wp:extent")
        cx = int(ext.get("cx"))
        cy = int(round(cx * h / w))
        print(f"  {filename}  {w}x{h} → 显示 {cx} x {cy}")
        if apply:
            part._blob = image_path.read_bytes()
            ext.set("cy", str(cy))
            for aext in para.iter(A_EXT):
                if aext.get("cx") is not None:
                    aext.set("cx", str(cx))
                    aext.set("cy", str(cy))
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    bak = BAK_DIR / f"storybook_backup_{stamp}.docx"
    shutil.copy2(DOCX, bak)
    print(f"备份 -> {bak}")
    doc.save(str(DOCX))
    print(f"已写回 {DOCX}")


if __name__ == "__main__":
    main()
